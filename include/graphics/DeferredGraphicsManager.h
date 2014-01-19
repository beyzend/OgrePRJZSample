#pragma once

/**
Permission is hereby granted by Fdastero LLC, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
**/
/**
*author: beyzend 
*email: llwijk@gmail.com
**/

#include "ZPrerequisites.h"

namespace ZGame
{

    class DeferredGraphicsManager
    {
    public:
        DeferredGraphicsManager();
        ~DeferredGraphicsManager();

        void
            initialize(Ogre::Camera* cam,
            int GBufferWidth, int GBufferHeight);

        void
            update();
        void
            clear();

        Ogre::TexturePtr
            getNormalDepthTex()
        {
            return _normalDepthTex;
        }

        Ogre::TexturePtr
            getLightBufferTex()
        {
            return _lightBufferTex;
        }

        Ogre::TexturePtr
            getGBuffer1Tex()
        {
            return _gBuffer1Tex;
        }


    protected:
    private:

        Ogre::TexturePtr _normalDepthTex;
        Ogre::MultiRenderTarget* _gBufferMRTT;
        ///2nd gbuffer storing position.
        Ogre::TexturePtr _gBuffer1Tex; 
        Ogre::TexturePtr _positionTex;
        Ogre::TexturePtr _lightBufferTex;
        Ogre::MultiRenderTarget* _MRTTGBuffer;
        Ogre::Viewport* _mrttViewport;

        void
            _setupRenderTexture(Ogre::RenderTexture* renderTexture);
        void
            _attachDeferredTexturesToMaterials(std::vector<const Ogre::String> materialNames);


    };
}