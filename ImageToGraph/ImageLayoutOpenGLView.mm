//
//  MyOpenGLView.m
//  OpenGLTesting
//
//  Created by Matthew Bennett on 12/13/12.
//  Copyright (c) 2012 Matthew Bennett. All rights reserved.
//

#import "ImageLayoutOpenGLView.h"
#import <OpenGL/gl.h>
@implementation ImageLayoutOpenGLView

void glGenTextures(GLsizei s, GLuint *textures);

static GLuint createTexture(const void *image, int width, int height) {
    GLuint imageID;
    glPixelStorei(GL_UNPACK_ROW_LENGTH, width);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glGenTextures(1, &imageID);
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, imageID);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA, width, height,
                 0, GL_RGBA, GL_UNSIGNED_BYTE, image);
    return imageID;

}

static void drawAnObject(const void *image, int width, int height,
                         cholmod_dense *xcords, cholmod_dense *ycords) {
    float widthBound;
    float heightBound;
    GLuint imageID;
    
    if (width > height) {
        widthBound = 1;
        heightBound = (float)height/width;
    } else {
        heightBound = 1;
        widthBound = (float)width/height;
    }
    
    imageID = createTexture(image, width, height);
    glEnable(GL_TEXTURE_RECTANGLE_ARB);
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, imageID);
    
    glBegin(GL_QUADS);
    {
        float xPos, yPos;
        
        for(int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                int botLeft = x + (width+1)*y;
                //bottomleft
                glTexCoord2f(x, y);
                xPos = (((double *)xcords->x)[botLeft]/width)*widthBound*2;
                yPos = (((double *)ycords->x)[botLeft]/height)*heightBound*2;
                glVertex2f(-widthBound+xPos, heightBound-yPos);
                
                //bottomright
                glTexCoord2f(x+1, y);
                xPos = (((double *)xcords->x)[botLeft+1]/width)*widthBound*2;
                yPos = (((double *)ycords->x)[botLeft+1]/height)*heightBound*2;
                glVertex2f(-widthBound+xPos, heightBound-yPos);
                
                //topright
                glTexCoord2f(x+1, y+1);
                xPos = (((double *)xcords->x)[botLeft+width+2]/width)*widthBound*2;
                yPos = (((double *)ycords->x)[botLeft+width+2]/height)*heightBound*2;
                glVertex2f(-widthBound+xPos, heightBound-yPos);
                
                //topleft
                glTexCoord2f(x, y+1);
                xPos = (((double *)xcords->x)[botLeft+width+1]/width)*widthBound*2;
                yPos = (((double *)ycords->x)[botLeft+width+1]/height)*heightBound*2;
                glVertex2f(-widthBound+xPos, heightBound-yPos);
                
            }
            
        }
    }
    glEnd();

}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        width = 0;
        height = 0;
        xcords = NULL;
        ycords = NULL;
        // Initialization code here.
    }
    
    return self;
}

-(void)drawImageFromData:(NSData *)im withSize:(NSSize) size xCoords: (cholmod_dense *) x yCoords: (cholmod_dense *) y{
    cholmod_common common;
    cholmod_start(&common);
    
    image = [im copy];
    height = size.height;
    width = size.width;
    if (xcords) {
        cholmod_free_dense(&xcords, &common);
    }
    if (ycords) {
        cholmod_free_dense(&ycords, &common);
    }
    xcords = cholmod_copy_dense(x, &common);
    ycords = cholmod_copy_dense(y, &common);
    cholmod_finish(&common);
    self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    if (width > 0 && height > 0) {
    drawAnObject([image bytes], width, height, xcords, ycords);
    }
    glFlush();
}

@end
