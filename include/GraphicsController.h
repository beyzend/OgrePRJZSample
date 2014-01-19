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



/**
* \file This file defines a controller for controlling application graphical state.
*/

#include <OgreSceneManager.h>

#include "ZPrerequisites.h"


#include "graphics/HDRCompositor.h"
#include "SkyX/SkyX.h"

#include "world/WorldClockController.h"
#include "graphics/GraphicsOptions.h"
#include "graphics/CSMGpuConstants.h"


class PSSMShadowListener : public Ogre::SceneManager::Listener
{
public:
	PSSMShadowListener(Ogre::SceneManager *sm, Ogre::Light *l, Ogre::ShadowCameraSetupPtr s, Ogre::Camera*cam);
	virtual ~PSSMShadowListener() {}
	//virtual void shadowTexturesUpdated(size_t numberOfShadowTextures);
	virtual void shadowTextureCasterPreViewProj(Ogre::Light* light, Ogre::Camera* camera);
	//virtual void shadowTextureReceiverPreViewProj(Ogre::Light* light, Ogre::Frustum* frustum);
	virtual bool sortLightsAffectingFrustum(Ogre::LightList& lightList);
private:
	Ogre::Light *light;
	Ogre::ShadowCameraSetupPtr setup;
	Ogre::Camera *view_camera;
	Ogre::SceneManager *sceneMgr;
	mutable int split_index;

};

namespace ZGame
{

    struct shadowListener : public Ogre::SceneManager::Listener
    {
        // this is a callback we'll be using to set up our shadow camera
        void
            shadowTextureCasterPreViewProj(Ogre::Light *light, Ogre::Camera *cam, size_t)
        {
            // basically, here we do some forceful camera near/far clip attenuation
            // yeah.  simplistic, but it works nicely.  this is the function I was talking
            // about you ignoring above in the Mgr declaration.
            float range = light->getAttenuationRange();
            cam->setNearClipDistance(0.01);
            cam->setFarClipDistance(range);
            // we just use a small near clip so that the light doesn't "miss" anything
            // that can shadow stuff.  and the far clip is equal to the lights' range.
            // (thus, if the light only covers 15 units of objects, it can only
            // shadow 15 units - the rest of it should be attenuated away, and not rendered)
        }

        // these are pure virtual but we don't need them...  so just make them empty
        // otherwise we get "cannot declare of type Mgr due to missing abstract
        // functions" and so on
        void
            shadowTexturesUpdated(size_t)
        {
        }
        void
            shadowTextureReceiverPreViewProj(Ogre::Light*, Ogre::Frustum*)
        {
        }
        void
            preFindVisibleObjects(Ogre::SceneManager*, Ogre::SceneManager::IlluminationRenderStage, Ogre::Viewport*)
        {
        }
        void
            postFindVisibleObjects(Ogre::SceneManager*, Ogre::SceneManager::IlluminationRenderStage, Ogre::Viewport*)
        {
        }
    };

    struct ssaoListener : public Ogre::CompositorInstance::Listener
    {
        Ogre::Camera* cam;
        Ogre::TexturePtr geomTex; 

        void setCamera(Ogre::Camera* cam)
        {
            this->cam = cam;
        }

        void setGeomTex(Ogre::TexturePtr tex)
        {
            geomTex = tex;
        }


        // this callback we will use to modify SSAO parameters
        void
            notifyMaterialRender(Ogre::uint32 pass_id, Ogre::MaterialPtr &mat)
        {
            if (pass_id == 42 ) // not SSAO, return
            {

            // this is the camera you're using

            // calculate the far-top-right corner in view-space
            Ogre::Vector3 farCorner = cam->getViewMatrix(true) * cam->getWorldSpaceCorners()[4];

            // get the pass
            Ogre::Pass *pass = mat->getBestTechnique()->getPass(0);

            // get the vertex shader parameters
            Ogre::GpuProgramParametersSharedPtr params = pass->getVertexProgramParameters();
            // set the camera's far-top-right corner
            if (params->_findNamedConstantDefinition("farCorner"))
                params->setNamedConstant("farCorner", farCorner);

            // get the fragment shader parameters
            params = pass->getFragmentProgramParameters();
            // set the projection matrix we need
            static const Ogre::Matrix4 CLIP_SPACE_TO_IMAGE_SPACE(0.5, 0, 0, 0.5, 0, -0.5, 0, 0.5, 0, 0, 1, 0, 0, 0, 0, 1);
            if (params->_findNamedConstantDefinition("ptMat"))
                params->setNamedConstant("ptMat", CLIP_SPACE_TO_IMAGE_SPACE * cam->getProjectionMatrixWithRSDepth());
            if (params->_findNamedConstantDefinition("far"))
                params->setNamedConstant("far", cam->getFarClipDistance());
            cout << "Setting geomTex: " << geomTex->getName() << endl;
            pass->getTextureUnitState(0)->setTextureName(geomTex->getName());
            }
            else if(pass_id == 43)
            {
                Ogre::Pass *pass = mat->getTechnique(0)->getPass(0);
                pass->getTextureUnitState(1)->setTextureName(geomTex->getName());
            }

        }
    } ;



    class DeferredGraphicsManager;

    class GraphicsController
    {
    public:
        GraphicsController();
        virtual
            ~GraphicsController();

        static const size_t NUM_OF_BANDS = 5;

        bool
            onInit(ZGame::ZInitPacket* packet);
        bool
            onDestroy();
        bool
            onUpdate(const Ogre::FrameEvent &evt);
        bool
            onUpdate(const Ogre::Real dt);

        bool
            onKeyUp(const OIS::KeyEvent &evt);
        bool
            onKeyDown(const OIS::KeyEvent &evt);
		Graphics::GraphicsOptions&
			getGraphicsOptions()
		{
			return _gfxOptions;
		}
			

        ///Call this managed to have GraphicsController unmanage skyx.
        SkyX::SkyX*
            getSkyX();

        /**
        * This method updates the "manual" compositors. 
        *By manual compositor we mean manual render targets that
        *act like compositors. ie. we're doing compositor like things
        *manually without using the compositor framework.
        **/
        bool
            onUpdateManualCompositors(Ogre::RenderWindow* window);
        bool
            onPostUpdateBuffers();
        /** 
        *This method is called to update the deferred shading system.
        **/
        bool
            onUpdateDeferredSystems();


        bool adjustShadow(const Ogre::StringVector &params);
        bool onRenderQueueStart(Ogre::uint8 queueGroupId,
            const Ogre::String& invocation, bool& skipThisInvocation);
        bool onRenderQueueEnd(Ogre::uint8 queueGroupId,
            const Ogre::String& invocation, bool& skipThisInvocation);

        HDRCompositor* 
            getHdrCompositor()
        {
            if(_hdrCompositor.get() == 0)
                OGRE_EXCEPT(Ogre::Exception::ERR_INTERNAL_ERROR,
                "hdr compositor is null", "GraphicsController::getHdrCompositor");
            return _hdrCompositor.get();
        }

        bool
            onFrameEnded(const Ogre::FrameEvent& evt);

        DeferredGraphicsManager*
            getDeferredGraphicsManager()
        {
            return _deferredGfx.get();
        }

        void
            addTextureToDebugOverlay(Ogre::TexturePtr tex);
        void
            setTextureDataHeightMap(Ogre::TexturePtr texHeightMap, int numOfPagesPerAxis);
        void
            setTextureDataBitVolume(Ogre::TexturePtr texBitVolume);

		World::WorldClockController*
			getWorldClockController()
		{
			return &_worldClockController;
		}

		void
			setTimeRate(Ogre::Real rate)
		{
			_radianOffset = rate;
		}

		void
			setSunDirection(Ogre::Vector3 dir)
		{
			_lightDir = dir;
		}

		void
			getStats(size_t &tris, size_t &batch)
		{
			tris = _trisCount;
			batch = _batchCount;
		}

    protected:

    private:

        void _initBackgroundHdr();

        void _initShadows();
		void _initShadows2();
        void _initSSAO(int width, int height);
        void _initHDR(Ogre::RenderWindow* windowm, Ogre::Camera* initialCam);
        void _parseHDRConfig();
        void _initSkyX();
        void _initHFAO(int width, int height);
        //This is a temp method to disable compositors before rendering of GUI.
        //We need to do this on a material level, by implementing a custom GEOM method
        //for GUI so we don't render them to compositors.
        //This problem is due to libRocket calling _render directly instead of adding
        //it to an RenderQueue.
        void _toggleAllCompositors(bool enable);

        void addTextureShadowDebugOverlay(size_t num);
        void addTextureDebugOverlay(Ogre::TexturePtr tex, size_t);
        void addTextureDebugOverlay(const Ogre::String& texname, size_t i);
        void
            _adjustShadow(Ogre::Degree degree = Ogre::Degree(10.0f),
            Ogre::Real lambda = 0.9f,
            Ogre::Real nearPlane = 0.5f, 
            Ogre::Real farPlane = 400.0f 
            );
        /** \brief A temp method for creating random textures**/
        void
            _createRandomTextures();
        /** \brief A method to create bitwise look up texture.**/
        void
            _createBitwiseLookupTable();
        void
            _writeDebugBuffer(Ogre::TexturePtr tex);

        void
            _attachTextureToMaterials(const Ogre::String &textureUnitName,
            Ogre::TexturePtr texturePtr, std::vector<const Ogre::String> materialNames);
        void
            _setSHParameterMultipleMaterials(int paramIdx, 
                const Ogre::String &namer, const Ogre::String &nameg,
                const Ogre::String &nameb,
                const std::vector<const Ogre::String> &materialNames);

        ///This method will initialize the texture array for our terrain.   
		void
			_initTerrainTextureArray();
		void
			_getTextureNames(const Ogre::String directoryName,
			Ogre::StringVector &textureNames);
		Ogre::TexturePtr
			_loadTextureArray(Ogre::StringVector &textureNames
			, const Ogre::String textureName, bool gamma, int numOfMips);

		
		
			
    private:

        Ogre::CompositorInstance* _gBufferInstance;
        Ogre::CompositorInstance* _ssaoInstance;
        Ogre::CompositorInstance* _bloomInstance;
        Ogre::CompositorInstance* _ogreHdr;

        //Two targets for SSAO so we can ping pong blur.
        Ogre::TexturePtr _ssaoTarget;
        Ogre::TexturePtr _ssaoBlurX;
        Ogre::TexturePtr _ssaoBlurY;
        Ogre::Rectangle2D* _ssaoQuad;
        Ogre::SceneNode* _ssaoTempNode;
        Ogre::MaterialPtr _ssaoMat;
        Ogre::MaterialPtr _ssaoBlurXMat;
        Ogre::MaterialPtr _ssaoBlurYMat;
        Ogre::MaterialPtr _ssaoBlendMat;


        Ogre::Rectangle2D* _directionLightQuad;


        Ogre::Camera* _ssaoCam;
        Ogre::TexturePtr _texData2d;
        //Targets for height fake ambient occlusion
        Ogre::TexturePtr _hfaoTarget;
        Ogre::TexturePtr _hfaoBlurX;
        Ogre::TexturePtr _hfaoBlurY;
        //Ogre::TexturePtr _wendlandFilter;
        Ogre::MaterialPtr _hfaoMat;
        Ogre::MaterialPtr _hfaoBlurXMat;
        Ogre::MaterialPtr _hfaoBlurYMat;
        Ogre::MaterialPtr _hfaoBlendMat;


        //Ogre::MaterialPtr _wendlandFilterMat;
        Ogre::Camera* _hfaoCam;

        Ogre::TexturePtr _randDirTex;
        Ogre::TexturePtr _jitterPatternTex;
        Ogre::TexturePtr _bitwiseLookupTex;

        shadowListener _shadowListener;
        ssaoListener _ssaoListener;
        std::auto_ptr<HDRCompositor> _hdrCompositor;
        std::auto_ptr<ListenerFactoryLogic> _logic;
        std::auto_ptr<DeferredGraphicsManager> _deferredGfx;
        Ogre::Camera* _deferredCam;
        Graphics::DynamicLightManager* _dynLightsManager;



        Ogre::Rectangle2D* _clearHack;
        Ogre::SceneNode* _clearHackNode;

        bool _compositorState[3];
        bool _stateOnce;
        Ogre::SceneManager* _scnMgr;
        Ogre::Viewport* _vp;
        size_t _WHICH_TONEMAPPER;
        size_t _WHICH_STARTYPE;
        size_t _WHICH_GLARETYPE;
        size_t _ADAPT_SCALE;
        bool _IS_AUTO_KEY;
        float _AUTO_KEY;
        float _GLARE_STRENGTH;
        float _STAR_STRENGTH;
        Ogre::ShadowCameraSetupPtr _pssmSetup;
        std::auto_ptr<SkyX::SkyX> _skyX;
        Ogre::Real _SHC_R[NUM_OF_BANDS*NUM_OF_BANDS]; //4 is because we have to use multiple of fours. WARNING, this only works of 3 or 4 bands only!!!
        Ogre::Real _SHC_G[NUM_OF_BANDS*NUM_OF_BANDS];
        Ogre::Real _SHC_B[NUM_OF_BANDS*NUM_OF_BANDS];
        Ogre::Real _timeCount;

        std::vector<Ogre::String> _compositorNames;
        std::vector<Ogre::String> _postEfxNames;
        Ogre::String _currentCompositor;
        Ogre::String _currentPostEfx;

        Ogre::Light* light;

        Ogre::Vector3 _lightDir;
        Ogre::Real _radianOffset;

        Ogre::Camera* _cam;
        int _blocksInView;

		ZGame::World::WorldClockController _worldClockController;

		Graphics::GraphicsOptions _gfxOptions;

		HDRLogic* _hdrLogic;

		Ogre::CSMGpuConstants *mGpuConstants;

		size_t _trisCount;
		size_t _batchCount;

    };
}
