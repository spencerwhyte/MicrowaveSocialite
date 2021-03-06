/*
 
     File: EAGLView.mm
 Abstract: n/a
  Version: 2.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 
 */

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "FFTView.h"
#import "BufferManager.h"


#define USE_DEPTH_BUFFER 1
#define SPECTRUM_BAR_WIDTH 4


#ifndef CLAMP
#define CLAMP(min,x,max) (x < min ? min : (x > max ? max : x))
#endif


// value, a, r, g, b
GLfloat colorLevels[] = {
    0., 1., 0., 0., 0.,
    .333, 1., .7, 0., 0.,
    .667, 1., 0., 0., 1.,
    1., 1., 0., 1., 1.,
};

#define kMinDrawSamples 64
#define kMaxDrawSamples 4096


typedef struct SpectrumLinkedTexture {
	GLuint							texName;
	struct SpectrumLinkedTexture	*nextTex;
} SpectrumLinkedTexture;


typedef enum aurioTouchDisplayMode {
	aurioTouchDisplayModeOscilloscopeWaveform,
	aurioTouchDisplayModeOscilloscopeFFT,
	aurioTouchDisplayModeSpectrum
} aurioTouchDisplayMode;



@interface FFTView () {
    
    /* The pixel dimensions of the backbuffer */
	GLint backingWidth;
	GLint backingHeight;
	
	EAGLContext *context;
	
	/* OpenGL names for the renderbuffer and framebuffers used to render to this view */
	GLuint viewRenderbuffer, viewFramebuffer;
	
	/* OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist) */
	GLuint depthRenderbuffer;
    
	NSTimer                     *animationTimer;
	NSTimeInterval              animationInterval;
	NSTimeInterval              animationStarted;
    
    BOOL                        applicationResignedActive;
    
	BOOL						initted_oscilloscope, initted_spectrum;
    
    BOOL hitTargetRecently;
	UInt32*						texBitBuffer;
	CGRect						spectrumRect;
	
	aurioTouchDisplayMode		displayMode;
    
	SpectrumLinkedTexture*		firstTex;
    
	UIEvent*					pinchEvent;
	CGFloat						lastPinchDist;
	Float32*					l_fftData;
	GLfloat*					oscilLine;
    
    AudioController*            audioController;
    
    
    CGFloat backgroundRed;
    CGFloat backgroundGreen;
    CGFloat backgroundBlue;
    
    CGFloat primaryRed;
    CGFloat primaryGreen;
    CGFloat primaryBlue;
    
    CGFloat thresholdRed;
    CGFloat thresholdGreen;
    CGFloat thresholdBlue;
    
}

- (BOOL)createFramebuffer;
- (void)destroyFramebuffer;
- (void)setupView;
- (void)drawView;
- (void)setAnimationInterval:(NSTimeInterval)interval;

@end

@implementation FFTView

@synthesize applicationResignedActive;

// You must implement this
+ (Class) layerClass
{
	return [CAEAGLLayer class];
}

//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame])) {
    
        
		// Get the layer
		CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
		
		eaglLayer.opaque = YES;
		
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSNumber numberWithBool:FALSE],
                                       kEAGLDrawablePropertyRetainedBacking,
                                       kEAGLColorFormatRGBA8,
                                       kEAGLDrawablePropertyColorFormat,
                                       nil];
		
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
		
		if(!context || ![EAGLContext setCurrentContext:context] || ![self createFramebuffer]) {
			return nil;
		}
        
        
        audioController = [[AudioController alloc] init];
        l_fftData = (Float32*) calloc([audioController getBufferManagerInstance]->GetFFTOutputBufferLength(), sizeof(Float32));
		
        oscilLine = (GLfloat*)malloc(kDefaultDrawSamples * 2 * sizeof(GLfloat));

		animationInterval = 1.0 / 60.0;
		      
		[self setupView];
		[self drawView];
        
        displayMode = aurioTouchDisplayModeOscilloscopeFFT;
        
        
        // Set up the view to refresh at 20 hz
        [self setAnimationInterval:1./20.];
        
        self.targetIndex = 0;
        
        self.isInDiscoverMode = YES;
        

        backgroundRed = 0;
        backgroundGreen = 0;
        backgroundBlue = 0;
        
        primaryRed = 0;
        primaryGreen = 1;
        primaryBlue = 0;
    
        thresholdRed = 1;
        thresholdGreen = 0;
        thresholdBlue = 0;
        
	}
	
	return self;
}

- (void)layoutSubviews
{
	[EAGLContext setCurrentContext:context];
	[self destroyFramebuffer];
	[self createFramebuffer];
	[self drawView];
}

- (BOOL)createFramebuffer
{
	glGenFramebuffersOES(1, &viewFramebuffer);
	glGenRenderbuffersOES(1, &viewRenderbuffer);
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(id<EAGLDrawable>)self.layer];
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
	
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
	if(USE_DEPTH_BUFFER) {
		glGenRenderbuffersOES(1, &depthRenderbuffer);
		glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
		glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
		glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
	}
	
	if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
		return NO;
	}
	
	return YES;
}


- (void)destroyFramebuffer
{
	glDeleteFramebuffersOES(1, &viewFramebuffer);
	viewFramebuffer = 0;
	glDeleteRenderbuffersOES(1, &viewRenderbuffer);
	viewRenderbuffer = 0;
	
	if(depthRenderbuffer) {
		glDeleteRenderbuffersOES(1, &depthRenderbuffer);
		depthRenderbuffer = 0;
	}
}


- (void)startAnimation
{
	animationTimer = [NSTimer scheduledTimerWithTimeInterval:animationInterval target:self selector:@selector(drawView) userInfo:nil repeats:YES];
	animationStarted = [NSDate timeIntervalSinceReferenceDate];
    [audioController startIOUnit];
}


- (void)stopAnimation
{
	[animationTimer invalidate];
	animationTimer = nil;
    [audioController stopIOUnit];
}


- (void)setAnimationInterval:(NSTimeInterval)interval
{
	animationInterval = interval;
	
	if(animationTimer) {
		[self stopAnimation];
		[self startAnimation];
	}
}


- (void)setupView
{
	// Sets up matrices and transforms for OpenGL ES
	glViewport(0, 0, backingWidth, backingHeight);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrthof(0, backingWidth, 0, backingHeight, -1.0f, 1.0f);
	glMatrixMode(GL_MODELVIEW);
	

	
	glEnableClientState(GL_VERTEX_ARRAY);
	
}


// Updates the OpenGL view when the timer fires
- (void)drawView
{
    // the NSTimer seems to fire one final time even though it's been invalidated
    // so just make sure and not draw if we're resigning active
    if (self.applicationResignedActive) return;
    
	// Make sure that you are drawing to the current context
	[EAGLContext setCurrentContext:context];
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	
	[self drawView:self forTime:([NSDate timeIntervalSinceReferenceDate] - animationStarted)];
	
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
}


- (void)setupViewForOscilloscope
{
	// Load our GL textures
	initted_oscilloscope = YES;
}


- (void)clearTextures
{
	bzero(texBitBuffer, sizeof(UInt32) * 512);
	SpectrumLinkedTexture *curTex;
	
	for (curTex = firstTex; curTex; curTex = curTex->nextTex)
	{
		glBindTexture(GL_TEXTURE_2D, curTex->texName);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 512, 0, GL_RGBA, GL_UNSIGNED_BYTE, texBitBuffer);
	}
}

- (void)setupViewForSpectrum
{
	glClearColor(backgroundRed, backgroundGreen, backgroundBlue, 0.0);

	
	spectrumRect = CGRectMake(10., 10., 460., 300.);
	
	// The bit buffer for the texture needs to be 512 pixels, because OpenGL textures are powers of
	// two in either dimensions. Our texture is drawing a strip of 300 vertical pixels on the screen,
	// so we need to step up to 512 (the nearest power of 2 greater than 300).
	texBitBuffer = (UInt32 *)(malloc(sizeof(UInt32) * 512));
	
	// Clears the view with black
    
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	
	NSUInteger texCount = ceil(CGRectGetWidth(spectrumRect) / (CGFloat)SPECTRUM_BAR_WIDTH);
	GLuint *texNames;
	
	texNames = (GLuint *)(malloc(sizeof(GLuint) * texCount));
	glGenTextures((int)texCount, texNames);
	
	unsigned int i;
	SpectrumLinkedTexture *curTex = NULL;
	firstTex = (SpectrumLinkedTexture *)(calloc(1, sizeof(SpectrumLinkedTexture)));
	firstTex->texName = texNames[0];
	curTex = firstTex;
	
	bzero(texBitBuffer, sizeof(UInt32) * 512);
	
	glBindTexture(GL_TEXTURE_2D, curTex->texName);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	
	for (i=1; i<texCount; i++)
	{
		curTex->nextTex = (SpectrumLinkedTexture *)(calloc(1, sizeof(SpectrumLinkedTexture)));
		curTex = curTex->nextTex;
		curTex->texName = texNames[i];
		
		glBindTexture(GL_TEXTURE_2D, curTex->texName);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	}
	
	// Enable use of the texture
	glEnable(GL_TEXTURE_2D);
	// Set a blending function to use
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	// Enable blending
	glEnable(GL_BLEND);
	
	initted_spectrum = YES;
	
	free(texNames);
}

- (void)drawOscilloscope
{
    glClearColor(backgroundRed, backgroundGreen, backgroundBlue, 0.0);

	// Clear the view
	glClear(GL_COLOR_BUFFER_BIT);
	
	glBlendFunc(GL_SRC_ALPHA, GL_ONE);
	
	glColor4f(1., 1., 1., 1.);
	
	glPushMatrix();
	
	glEnable(GL_TEXTURE_2D);
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	
    BOOL shouldDrawTargetFound = NO;
		
    BufferManager* bufferManager = [audioController getBufferManagerInstance];
    Float32** drawBuffers = bufferManager->GetDrawBuffers();
	if (displayMode == aurioTouchDisplayModeOscilloscopeFFT)
	{
		if (bufferManager->HasNewFFTData())
		{

			bufferManager->GetFFTOutput(l_fftData);
            self.recentMaxIndex = bufferManager->recentMaxIndex;
            
            NSLog(@"recentMaxIndex: %d", self.recentMaxIndex);
            NSLog(@"targetIndex: %d", self.targetIndex);
            
            if(fabs((float)(self.targetIndex - self.recentMaxIndex)) <= 2.0 || (self.targetIndex == 0 && self.recentMaxIndex!=0)){
                if(hitTargetRecently){
                    shouldDrawTargetFound = YES;
                    NSLog(@"Recent");
                }
                hitTargetRecently = YES;
            }else{
                hitTargetRecently = NO;
            }
            int y, maxY;
			maxY = bufferManager->GetCurrentDrawBufferLength();
            int fftLength = bufferManager->GetFFTOutputBufferLength();
            
			for (y=0; y<maxY; y++)
			{
				CGFloat yFract = (CGFloat)y / (CGFloat)(maxY - 1);
				CGFloat fftIdx = yFract * ((CGFloat)fftLength - 1);
				
				double fftIdx_i, fftIdx_f;
				fftIdx_f = modf(fftIdx, &fftIdx_i);
				
				CGFloat fft_l_fl, fft_r_fl;
				CGFloat interpVal;
				
                int lowerIndex = (int) fftIdx_i;
                int upperIndex = (int) fftIdx_i + 1;
                upperIndex = (upperIndex == fftLength) ? fftLength - 1 : upperIndex;
                
				fft_l_fl = (CGFloat)(l_fftData[lowerIndex] + 80) / 64.;
				fft_r_fl = (CGFloat)(l_fftData[upperIndex] + 80) / 64.;
				interpVal = fft_l_fl * (1. - fftIdx_f) + fft_r_fl * fftIdx_f;
				
				drawBuffers[0][y] = CLAMP(0., interpVal, 1.);
			}
			[self cycleOscilloscopeLines];
		}
	}
	
	GLfloat *oscilLine_ptr;
	GLfloat max = kDefaultDrawSamples; //bufferManager->GetCurrentDrawBufferLength();
	Float32 *drawBuffer_ptr;
		
	glPushMatrix();
	
	// Translate to the left side and vertical center of the screen, and scale so that the screen coordinates
	// go from 0 to 1 along the X, and -1 to 1 along the Y
	glTranslatef(0, 0, 0.);
	glScalef(self.frame.size.width, self.frame.size.height, 1.);
	
	// Set up some GL state for our oscilloscope lines
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	glDisable(GL_LINE_SMOOTH);
	glLineWidth(2.);
	
	UInt32 drawBuffer_i;
	// Draw a line for each stored line in our buffer (the lines are stored and fade over time)
	for (drawBuffer_i=0; drawBuffer_i<kNumDrawBuffers; drawBuffer_i++)
	{
		if (!drawBuffers[drawBuffer_i]) continue;
		
		oscilLine_ptr = oscilLine;
		drawBuffer_ptr = drawBuffers[drawBuffer_i];
		
		GLfloat i;
		// Fill our vertex array with points
		for (i=0.; i<max; i=i+1.)
		{
			*oscilLine_ptr++ = i/max;
			*oscilLine_ptr++ = (Float32)(*drawBuffer_ptr++);
		}
		
		// If we're drawing the newest line, draw it in solid green. Otherwise, draw it in a faded green.
		if (drawBuffer_i == 0)
			glColor4f(primaryRed, primaryGreen, primaryBlue, 1.);
		else
			glColor4f(primaryRed, primaryGreen, primaryBlue, (.24 * (1. - ((GLfloat)drawBuffer_i / (GLfloat)kNumDrawBuffers))));
		
		// Set up vertex pointer,
		glVertexPointer(2, GL_FLOAT, 0, oscilLine);
		
		// and draw the line.
		glDrawArrays(GL_LINE_STRIP, 0, bufferManager->GetCurrentDrawBufferLength());
		
	}
    
    if(self.targetIndex != 0){
        if(shouldDrawTargetFound){
            // Inform the delegate
            if(self.targetDelegate){
                [self.targetDelegate didHitTargetFrequencyIndex:self.targetIndex];
            }
            glColor4f(primaryRed, primaryGreen, primaryBlue, 1.);
        }else{
            glColor4f(thresholdRed, thresholdGreen, thresholdBlue, 1.);
        }
        
        GLfloat totalWidth = 2048.0;
        GLfloat offset = self.targetIndex/totalWidth;
        GLfloat offsetLeft  = offset - 0.025;
        GLfloat offsetRight = offset + 0.025;
        GLfloat target[] = {offsetLeft, 0.2,     offsetRight, 0.2,     offsetRight, 1,    offsetLeft, 1};
        glVertexPointer(2, GL_FLOAT, 0, target);
        glDrawArrays(GL_LINE_LOOP, 0, 4);
        
    }
    if(self.isInDiscoverMode){
        if (self.recentMaxIndex != 0){ // We have found a peak
            self.targetIndex = self.recentMaxIndex;
                    	//[self stopAnimation];
        }
    }
    
    glColor4f(thresholdRed, thresholdGreen, thresholdBlue, 1.);
    GLfloat threshold[] = {0, 0.2,     1, 0.2, 0, 0.2,     1, 0.2, };
    glVertexPointer(2, GL_FLOAT, 0, threshold);
    glDrawArrays(GL_LINE_LOOP, 0, 4);
    
     
	glPopMatrix();
	glPopMatrix();
}

- (void)cycleSpectrum
{
	SpectrumLinkedTexture *newFirst;
	newFirst = (SpectrumLinkedTexture *)calloc(1, sizeof(SpectrumLinkedTexture));
	newFirst->nextTex = firstTex;
	firstTex = newFirst;
	
	SpectrumLinkedTexture *thisTex = firstTex;
	do {
		if (!(thisTex->nextTex->nextTex))
		{
			firstTex->texName = thisTex->nextTex->texName;
			free(thisTex->nextTex);
			thisTex->nextTex = NULL;
		}
		thisTex = thisTex->nextTex;
	} while (thisTex);
}

double linearInterp(double valA, double valB, double fract)
{
	return valA + ((valB - valA) * fract);
}


- (void)renderFFTToTex
{
	[self cycleSpectrum];
	
	UInt32 *texBitBuffer_ptr = texBitBuffer;
	
	static int numLevels = sizeof(colorLevels) / sizeof(GLfloat) / 5;
	
	int y, maxY;
	maxY = CGRectGetHeight(spectrumRect);
    BufferManager* bufferManager = [audioController getBufferManagerInstance];
    int fftLength = bufferManager->GetFFTOutputBufferLength();
	for (y=0; y<maxY; y++)
	{
		CGFloat yFract = (CGFloat)y / (CGFloat)(maxY - 1);
		CGFloat fftIdx = yFract * ((CGFloat)fftLength-1);
        
		double fftIdx_i, fftIdx_f;
		fftIdx_f = modf(fftIdx, &fftIdx_i);
		
		CGFloat fft_l_fl, fft_r_fl;
		CGFloat interpVal;
		
		int lowerIndex = (int)(fftIdx_i);
        int upperIndex = (int)(fftIdx_i + 1);
        upperIndex = (upperIndex == fftLength) ? fftLength - 1 : upperIndex;
        
		fft_l_fl = (CGFloat)(l_fftData[lowerIndex] + 80) / 64.;
		fft_r_fl = (CGFloat)(l_fftData[upperIndex] + 80) / 64.;
		interpVal = fft_l_fl * (1. - fftIdx_f) + fft_r_fl * fftIdx_f;
		
		interpVal = sqrt(CLAMP(0., interpVal, 1.));
        
		UInt32 newPx = 0xFF000000;
		
		int level_i;
		const GLfloat *thisLevel = colorLevels;
		const GLfloat *nextLevel = colorLevels + 5;
		for (level_i=0; level_i<(numLevels-1); level_i++)
		{
			if ( (*thisLevel <= interpVal) && (*nextLevel >= interpVal) )
			{
				double fract = (interpVal - *thisLevel) / (*nextLevel - *thisLevel);
				newPx =
				((UInt8)(255. * linearInterp(thisLevel[1], nextLevel[1], fract)) << 24)
				|
				((UInt8)(255. * linearInterp(thisLevel[2], nextLevel[2], fract)) << 16)
				|
				((UInt8)(255. * linearInterp(thisLevel[3], nextLevel[3], fract)) << 8)
				|
				(UInt8)(255. * linearInterp(thisLevel[4], nextLevel[4], fract))
				;
				break;
			}
			
			thisLevel+=5;
			nextLevel+=5;
		}
		
		*texBitBuffer_ptr++ = newPx;
	}
	
	glBindTexture(GL_TEXTURE_2D, firstTex->texName);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 512, 0, GL_RGBA, GL_UNSIGNED_BYTE, texBitBuffer);
}

- (void)drawView:(id)sender forTime:(NSTimeInterval)time
{
    if (![audioController audioChainIsBeingReconstructed])  //hold off on drawing until the audio chain has been reconstructed
    {
        if (displayMode == aurioTouchDisplayModeOscilloscopeFFT)
        {
            if (!initted_oscilloscope) [self setupViewForOscilloscope];
            [self drawOscilloscope];
        }
    }
}

CGPathRef CreateRoundedRectPath(CGRect RECT, CGFloat cornerRadius)
{
	CGMutablePathRef		path;
	path = CGPathCreateMutable();
	
	double		maxRad = MAX(CGRectGetHeight(RECT) / 2., CGRectGetWidth(RECT) / 2.);
	
	if (cornerRadius > maxRad) cornerRadius = maxRad;
	
	CGPoint		bl, tl, tr, br;
	
	bl = tl = tr = br = RECT.origin;
	tl.y += RECT.size.height;
	tr.y += RECT.size.height;
	tr.x += RECT.size.width;
	br.x += RECT.size.width;
	
	CGPathMoveToPoint(path, NULL, bl.x + cornerRadius, bl.y);
	CGPathAddArcToPoint(path, NULL, bl.x, bl.y, bl.x, bl.y + cornerRadius, cornerRadius);
	CGPathAddLineToPoint(path, NULL, tl.x, tl.y - cornerRadius);
	CGPathAddArcToPoint(path, NULL, tl.x, tl.y, tl.x + cornerRadius, tl.y, cornerRadius);
	CGPathAddLineToPoint(path, NULL, tr.x - cornerRadius, tr.y);
	CGPathAddArcToPoint(path, NULL, tr.x, tr.y, tr.x, tr.y - cornerRadius, cornerRadius);
	CGPathAddLineToPoint(path, NULL, br.x, br.y + cornerRadius);
	CGPathAddArcToPoint(path, NULL, br.x, br.y, br.x - cornerRadius, br.y, cornerRadius);
	
	CGPathCloseSubpath(path);
	
	CGPathRef				ret;
	ret = CGPathCreateCopy(path);
	CGPathRelease(path);
	return ret;
}


- (void)cycleOscilloscopeLines
{
    BufferManager* bufferManager = [audioController getBufferManagerInstance];
    
	// Cycle the lines in our draw buffer so that they age and fade. The oldest line is discarded.
    Float32** drawBuffers = bufferManager->GetDrawBuffers();
	for (int drawBuffer_i=(kNumDrawBuffers - 2); drawBuffer_i>=0; drawBuffer_i--)
		memmove(drawBuffers[drawBuffer_i + 1], drawBuffers[drawBuffer_i], bufferManager->GetCurrentDrawBufferLength());
}

// Stop animating and release resources when they are no longer needed.
- (void)dealloc
{
	[self stopAnimation];
	
	if([EAGLContext currentContext] == context) {
		[EAGLContext setCurrentContext:nil];
	}

	context = nil;
    
    free(oscilLine);
}

-(void)setBackgroundColor:(UIColor *)backgroundColor{
    
}

-(void)setFFTBackgroundColor:(UIColor *)color{
    CGFloat alpha;
    [color getRed:&backgroundRed green:&backgroundGreen blue:&backgroundBlue alpha:&alpha];
}

-(void)setFFTPrimaryColor:(UIColor *)color{
    CGFloat alpha;
    [color getRed:&primaryRed green:&primaryGreen blue:&primaryBlue alpha:&alpha];
}

-(void)setFFTThresholdColor:(UIColor *)color{
    CGFloat alpha;
    [color getRed:&thresholdRed green:&thresholdGreen blue:&thresholdBlue alpha:&alpha];
}

@end
