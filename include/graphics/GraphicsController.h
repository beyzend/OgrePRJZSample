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

#include <memory>

/**
* \file This file defines a controller for controlling application graphical state.
*/
#include <Ogre.h>
#include <OgreSceneManager.h>

#include "TutorialApplication.h"

class HDRLogic;

namespace ZGame
{

class DeferredGraphicsManager;


class GraphicsController
{
public:
    GraphicsController();
    virtual
    ~GraphicsController();

    static const size_t NUM_OF_BANDS = 5;

    bool
    onInit(Ogre::SceneManager* scnMgr, Ogre::Viewport* viewport, Ogre::Camera* camera,
    		Ogre::int32 windowWidth, Ogre::int32 windowHeight);
    bool
    onDestroy();
    bool
    onUpdate(const Ogre::FrameEvent &evt);
    bool
    onUpdate(const Ogre::Real dt);

    /**
    *This method is called to update the deferred shading system.
    **/
    bool
    onUpdateDeferredSystems();

    DeferredGraphicsManager*
    getDeferredGraphicsManager()
    {
        return _deferredGfx.get();
    }

    void
    addTextureToDebugOverlay(Ogre::TexturePtr tex);

protected:

private:
    void _initBackgroundHdr();

    void addTextureDebugOverlay(Ogre::TexturePtr tex, size_t);
    void addTextureDebugOverlay(const Ogre::String& texname, size_t i);
    void
    _attachTextureToMaterials(const Ogre::String &textureUnitName,
                              Ogre::TexturePtr texturePtr, const std::vector<Ogre::String> materialNames);
    void
    _setSHParameterMultipleMaterials(int paramIdx,
                                     const Ogre::String &namer, const Ogre::String &nameg,
                                     const Ogre::String &nameb,
                                     const std::vector<Ogre::String> &materialNames);

private:

    Ogre::CompositorInstance* _gBufferInstance = 0;
    //Ogre::CompositorInstance* _bloomInstance;
    Ogre::CompositorInstance* _ogreHdr;

    //Two targets for SSAO so we can ping pong blur.

    Ogre::Rectangle2D* _directionLightQuad = 0;

    //Ogre::TexturePtr _texData2d;

    //std::auto_ptr<HDRCompositor> _hdrCompositor;
    //std::auto_ptr<ListenerFactoryLogic> _logic;
    std::auto_ptr<DeferredGraphicsManager> _deferredGfx;
    Ogre::Camera* _deferredCam = 0;
    //Graphics::DynamicLightManager* _dynLightsManager;

    Ogre::SceneManager* _scnMgr = 0;
    Ogre::Viewport* _vp = 0;

    Ogre::Real _SHC_R[NUM_OF_BANDS*NUM_OF_BANDS]; //4 is because we have to use multiple of fours. WARNING, this only works of 3 or 4 bands only!!!
    Ogre::Real _SHC_G[NUM_OF_BANDS*NUM_OF_BANDS];
    Ogre::Real _SHC_B[NUM_OF_BANDS*NUM_OF_BANDS];
    Ogre::Real _timeCount = 0;

    Ogre::Light* light = 0;

    Ogre::Vector3 _lightDir;
    Ogre::Real _radianOffset;

    Ogre::Camera* _cam = 0;

    HDRLogic* _hdrLogic = 0;


};
}
