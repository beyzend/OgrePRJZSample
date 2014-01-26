/*
* GraphicsController.cpp
*
*  Created on: Aug 20, 2010
*      Author: beyzend
*/

#include <boost/filesystem/operations.hpp>
#include <boost/filesystem/fstream.hpp>

#include <OgreCamera.h>
#include <OgreViewport.h>
#include <OgreDepthBuffer.h>
#include <OgreAutoParamDataSource.h>
#include <OgreRenderQueue.h>

#include "graphics/GraphicsOptions.h"
#include "graphics/HDRCompositor.h"
#include "graphics/GraphicsController.h"
#include "graphics/PreethamSH.h"
#include "graphics/SunSH.h"
#include "graphics/DeferredGraphicsManager.h"




using std::cout;
using std::endl;

using namespace ZGame;
using namespace Ogre;

/*
GraphicsController::GraphicsController() :_timeCount(0.0f),
    _vp(0),
    _radianOffset(Ogre::Math::PI / 128.0),
    _lightDir(Vector3(0.0, 1.0f, 0.0f)),
    //, _dynLightsManager(0)
    //,_deferredGfx(new ZGame::DeferredGraphicsManager())
	,_hdrLogic(0)
*/
GraphicsController::GraphicsController() :
		_radianOffset( Ogre::Math::PI / 128.0),
		_lightDir( Ogre::Vector3( 0.0f, 1.0f, 0.0f) ),
		_deferredGfx( new ZGame::DeferredGraphicsManager() )

{
	_deferredGfx = std::auto_ptr<DeferredGraphicsManager>( new DeferredGraphicsManager() );
}

GraphicsController::~GraphicsController()
{
    cout << "In graphicsController destructor." << endl;
}

bool
    GraphicsController::onInit(Ogre::SceneManager* scnMgr, Ogre::Viewport* viewport, Ogre::Camera* camera,
    		Ogre::int32 windowWidth, Ogre::int32 windowHeight)
{

    _cam = camera;
    _scnMgr = scnMgr;
    _vp = viewport;
    //_dynLightsManager = packet->workspaceCtrl->getZWorkspace()->getWorldController()->getDynamicLightManager();
    //generate random textures
    
    for(size_t i = 0; i < NUM_OF_BANDS * 4; i++)
    {
        _SHC_R[i] = 0.0f;
        _SHC_G[i] = 0.0f;
        _SHC_B[i] = 0.0f;
    }

    Ogre::LogManager* lm = Ogre::LogManager::getSingletonPtr();
    lm->logMessage(Ogre::LML_TRIVIAL, "In GraphicsController::onInit()");
    lm->logMessage(Ogre::LML_NORMAL, "Adding compositor bloom");

    //First build the lights.
    _lightDir.normalise();

	Vector3 lightdir(0.0, -0.5, 0.1);
		lightdir.normalise();
    lightdir *= -1;
    _scnMgr->setAmbientLight(Ogre::ColourValue(0.5f, 0.5f, 0.5f));
    light = _scnMgr->createLight("terrainLight");
	light->setType(Light::LT_DIRECTIONAL);
	light->setCastShadows(true);
	light->setShadowFarClipDistance(256);
    
	Ogre::ColourValue fadeColour(1.0, 1.0, 1.0);
    _scnMgr->setFog(Ogre::FOG_NONE);

    _initBackgroundHdr();
    _vp->setBackgroundColour(fadeColour);


    Ogre::CompositorManager& compMgr = Ogre::CompositorManager::getSingleton();
	_hdrLogic = new HDRLogic();
    compMgr.registerCompositorLogic("HDR", _hdrLogic);
    _ogreHdr = CompositorManager::getSingleton().addCompositor(_vp, "HDR", 0);
    Ogre::CompositorManager::getSingleton().setCompositorEnabled(_vp, "HDR", true);

    /*
	//setup the HDR options.
	auto sharedParams = Ogre::GpuProgramManager::getSingleton().getSharedParameters("HdrSharedParams");

	ZGame::Graphics::GraphicsOptions gfxOptions;

	sharedParams->setNamedConstant("MIDDLE_GREY", gfxOptions.hdr_middle_grey);
	sharedParams->setNamedConstant("BRIGHT_LIMITER", gfxOptions.hdr_bright_limiter);
	sharedParams->setNamedConstant("FUDGE", gfxOptions.hdr_fudge_factor);
	*/

    _deferredGfx->initialize(_cam, windowWidth, windowHeight);
    
    //addTextureDebugOverlay(_deferredGfx->getLightBufferTex()->getName(), 1);

    //Ogre::OverlayManager::getSingleton().getByName("PRJZ/DebugOverlay")->show();
	    
    //addTextureDebugOverlay(_deferredGfx->getGBuffer1Tex()->getName(), 0);
	//addTextureDebugOverlay(_rtLum4->getName(), 0);
	//addTextureDebugOverlay(_deferredGfx->getNormalDepthTex()->getName(), 0);
    //Overlay* debugOverlay = OverlayManager::getSingleton().getByName("PRJZ/DebugOverlay");
    //debugOverlay->show();
    //addTextureDebugOverlay(_deferredGfx->getLightBufferTex()->getName(), 0);
    //addTextureDebugOverlay(_ssaoBlurY->getName(), 0);
    //addTextureDebugOverlay(_ssaoTarget->getName(), 0);
    //addTextureDebugOverlay(_hfaoTarget->getName(), 0);
	//addTextureDebugOverlay(_hfaoBlurY->getName(), 0);
    //addTextureDebugOverlay(_wendlandFilter->getName(), 0);
    //addTextureDebugOverlay(_ssaoTarget->getName(), 0);
    //addTextureDebugOverlay(_bitwiseLookupTex->getName(), 0);
    //addTextureDebugOverlay(_hfaoBlurY, 0);

    //setup the texture data textures.

	 //setup lighting direction quad
    /*
    _directionLightQuad = new Ogre::Rectangle2D(true);
    _directionLightQuad->setCorners(-1, 1, 1, -1);
    _directionLightQuad->setBoundingBox(Ogre::AxisAlignedBox::BOX_INFINITE);
    //was 0xf0
    _directionLightQuad->setVisibilityFlags(0xf0); //FUCK: for mask see DynamicLightManager. We need to define these globally.
    _directionLightQuad->setCastShadows(false);
	_directionLightQuad->setRenderQueueGroup(Ogre::RENDER_QUEUE_6);
    _directionLightQuad->setVisible(true);
    _directionLightQuad->setMaterial("PRJZ/DirectionLightBuffer");

    _scnMgr->getRootSceneNode()->attachObject(_directionLightQuad);
	*/
    return true;
}

void
    GraphicsController::addTextureToDebugOverlay(Ogre::TexturePtr tex)
{
    addTextureDebugOverlay(tex->getName(), 0); //0 is wrong, should be current debug idx.
}

bool
    GraphicsController::onUpdateDeferredSystems()
{
  
    _deferredGfx->clear();

    _deferredGfx->getNormalDepthTex()->getBuffer()->getRenderTarget()->update(false);
    _deferredGfx->getLightBufferTex()->getBuffer()->getRenderTarget()->update(false);
	
	return true;
}



void
    GraphicsController::_initBackgroundHdr()
{
    Ogre::Rectangle2D* rect = new Ogre::Rectangle2D(false);
    rect->setCorners(-1.0f, 1.0f, 1.0f, -1.0f);
    rect->setMaterial("PRJZ/HDRBackground");
    rect->setRenderQueueGroup(Ogre::RENDER_QUEUE_BACKGROUND + 1);
    rect->setBoundingBox(Ogre::AxisAlignedBox(-100000.0*Ogre::Vector3::UNIT_SCALE, 100000.0*Ogre::Vector3::UNIT_SCALE));
    rect->setCastShadows(false);
    rect->setVisibilityFlags(0xf00000);
    Ogre::SceneNode* node = _scnMgr->getRootSceneNode()->createChildSceneNode("HdrBackground");
    node->attachObject(rect);
    node->setVisible(true);
}


bool
    GraphicsController::onUpdate(const Ogre::FrameEvent &evt)
{
    return onUpdate(evt.timeSinceLastFrame);
}

bool
    GraphicsController::onUpdate(const Ogre::Real dt)
{
    using namespace Ogre;

    //pass int he Skylight SH coefficients
    //Compute theta and phi and get turbulence
    Vector3 xyz;

    Ogre::Quaternion quat(Ogre::Radian(_radianOffset * dt), Ogre::Vector3::UNIT_Z) ;
    _lightDir = quat * _lightDir;
    _lightDir.normalise();
    xyz = -_lightDir;


    Ogre::Radian theta = Math::ACos(xyz.y);
    Ogre::Radian phi = Math::ATan2(xyz.x, xyz.z);

    const Ogre::String shr("SHC_R_");
    const Ogre::String shg("SHC_G_");
    const Ogre::String shb("SHC_B_");

    //was 4.5
    Real turbulence = 3.0;

	Real ltDist = 500.0;
    if(xyz.y >= 0.0f)
    {
		light->setDirection(-xyz);

		CalculatePreethamSH(theta.valueRadians(),phi.valueRadians(),turbulence, NUM_OF_BANDS, true, _SHC_R, _SHC_G, _SHC_B, 1.0f);
        //CalculateSunSH(theta.valueRadians(), phi.valueRadians(), turbulence, NUM_OF_BANDS, _SHC_R, _SHC_G, _SHC_B, 1.0f);

		Ogre::MaterialPtr matPtr = static_cast<Ogre::MaterialPtr>(Ogre::MaterialManager::getSingleton().getByName("PRJZ/DirectionLightBuffer"));
		Ogre::Pass* pass = matPtr->getTechnique(0)->getPass(0);

		const Ogre::Matrix4& viewMat = _cam->getViewMatrix(true);
		Ogre::Vector4 xyz4(xyz.x, xyz.y, xyz.z, 0.0f);

		xyz4 = viewMat * xyz4;
		
		if(pass->getVertexProgramParameters()->_findNamedConstantDefinition("dirLightWorld"))
			pass->getVertexProgramParameters()->setNamedConstant("dirLightWorld", xyz4);

    }
    else
    {
        Ogre::Vector3 moonxyz = xyz * -1;

		light->setDirection(-moonxyz);

		Ogre::Radian theta = Math::ACos(moonxyz.y);
        Ogre::Radian phi = Math::ATan2(moonxyz.x, moonxyz.z);

        CalculatePreethamSH(theta.valueRadians(),phi.valueRadians(),turbulence, NUM_OF_BANDS, true, _SHC_R, _SHC_G, _SHC_B, 1.0f);
        //CalculateSunSH(theta.valueRadians(), phi.valueRadians(), turbulence, NUM_OF_BANDS, _SHC_R, _SHC_G, _SHC_B, 1.0f);

		const Ogre::Matrix4& viewMat = _cam->getViewMatrix(true);
		Ogre::Vector4 xyz4(moonxyz.x, moonxyz.y, moonxyz.z, 0.0f);

		xyz4 = viewMat * xyz4;
		
		Ogre::MaterialPtr matPtr = static_cast<Ogre::MaterialPtr>(Ogre::MaterialManager::getSingleton().getByName("PRJZ/DirectionLightBuffer"));
		Ogre::Pass* pass = matPtr->getTechnique(0)->getPass(0);
		if(pass->getVertexProgramParameters()->_findNamedConstantDefinition("dirLightWorld"))
			pass->getVertexProgramParameters()->setNamedConstant("dirLightWorld", xyz4);

    }

    std::vector<Ogre::String> materialNames;
    materialNames.push_back("PRJZ/Minecraft");
    materialNames.push_back("PRJZ/MinecraftCharacter");
	materialNames.push_back("PRJZ/Minecraft2");
    materialNames.push_back("preview_diffusenormalspecular");
	materialNames.push_back("preview2_diffusenormalspecular");
	materialNames.push_back("preview3_diffusenormalspecular");
	materialNames.push_back("preview_cubemap");
	materialNames.push_back("PRJZ/HWBasic");

	size_t idx = 0;

#define FULL_BAND 1
    for(size_t i=0; i < 9; ++i)
    {
        String namer = shr+StringConverter::toString(idx);
        String nameg = shg+StringConverter::toString(idx);
        String nameb = shb+StringConverter::toString(idx);

        _setSHParameterMultipleMaterials(i, namer, nameg, nameb, materialNames);
        idx++;
    }

#if FULL_BAND
        //Skip band 4th band (or 3rd degree).
        for(size_t i=16; i < 25; ++i)
        {
            String namer = shr+StringConverter::toString(idx);
            String nameg = shg+StringConverter::toString(idx);
            String nameb = shb+StringConverter::toString(idx);
            _setSHParameterMultipleMaterials(i, namer, nameg, nameb, materialNames);
            idx++;
        }
#endif

		materialNames.push_back("PRJZ/DirectionLightBuffer");

		for(const Ogre::String &materialName : materialNames)
        //for(auto iter = materialNames.cbegin(); iter != materialNames.cend(); ++iter)
        {
              Ogre::MaterialPtr matPtr = static_cast<Ogre::MaterialPtr>(Ogre::MaterialManager::getSingleton().getByName(materialName));
              Ogre::Pass* pass = matPtr->getTechnique(0)->getPass(0);
              if(pass->getFragmentProgramParameters()->_findNamedConstantDefinition("uLightY"))
                pass->getFragmentProgramParameters()->setNamedConstant("uLightY", xyz.y);
        }

    return true;
}

void
    GraphicsController::_setSHParameterMultipleMaterials(int paramIdx,
    const Ogre::String &namer, const Ogre::String &nameg, const Ogre::String &nameb,
    const std::vector<Ogre::String> &materialNames)
{
    //for(auto iter = materialNames.cbegin(); iter != materialNames.cend(); ++iter)
	for(const Ogre::String &materialName : materialNames)
	{
        Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(materialName);
        //No checking
        Ogre::Pass* pass = mat->getTechnique(0)->getPass(0);

        Ogre::GpuProgramParametersSharedPtr params = pass->getFragmentProgramParameters();
        if(params->_findNamedConstantDefinition(namer))
            params->setNamedConstant(namer,_SHC_R[paramIdx]);
        if(params->_findNamedConstantDefinition(nameg))
            params->setNamedConstant(nameg,_SHC_G[paramIdx]);
        if(params->_findNamedConstantDefinition(nameb))
            params->setNamedConstant(nameb,_SHC_B[paramIdx]); 
    }
}

bool
    GraphicsController::onDestroy()
{
    _deferredGfx.reset(0);
    Ogre::CompositorManager::getSingleton().removeCompositor(_vp, "ssao");
    return true;
}

void
    GraphicsController::_attachTextureToMaterials(const Ogre::String &textureUnitName, Ogre::TexturePtr texturePtr, 
    const std::vector<Ogre::String> materialNames)
{
    //for(auto iter = materialNames.cbegin(); iter != materialNames.cend(); ++iter)
	for(const Ogre::String &materialName : materialNames)
	{
        Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(materialName);
        Ogre::String errorMessage("This material ");
        errorMessage += materialName + " was not found.";
        if(mat.isNull())
        {
            OGRE_EXCEPT(Ogre::Exception::ERR_INVALIDPARAMS, errorMessage, "GraphicsController::_attachTextureToMaterials");
        }
        Ogre::TextureUnitState* txUnit = mat->getTechnique(0)->getPass(0)->getTextureUnitState(textureUnitName);
        if(!txUnit)
            OGRE_EXCEPT(Ogre::Exception::ERR_ITEM_NOT_FOUND, textureUnitName + " was not found", "GraphicsController::_attachTextureToMaterials");
        txUnit->setTextureName(texturePtr->getName());
    }
}




void GraphicsController::addTextureDebugOverlay(Ogre::TexturePtr tex, size_t i)
{
    addTextureDebugOverlay(tex->getName(), i);
}
void GraphicsController::addTextureDebugOverlay(const Ogre::String& texname, size_t i)
{
    using namespace Ogre;
    Overlay* debugOverlay = OverlayManager::getSingleton().getByName("PRJZ/DebugOverlay");

	MaterialPtr debugMat = MaterialManager::getSingleton().getByName("PRJZ/BasicTexture", "PROJECT_ZOMBIE");
	if(debugMat.isNull())
		OGRE_EXCEPT(Ogre::Exception::ERR_INVALIDPARAMS, "PRJZ/BasicTexture material was not found.", "GraphicsController::addTextureDebugOverlay");
    debugMat->getTechnique(0)->getPass(0)->setLightingEnabled(false);
    TextureUnitState *t = debugMat->getTechnique(0)->getPass(0)->createTextureUnitState(texname);
    t->setTextureAddressingMode(TextureUnitState::TAM_CLAMP);

    Ogre::TexturePtr tex = Ogre::TextureManager::getSingleton().getByName(texname);
    Ogre::Real tWidth = tex->getWidth();
    Ogre::Real tHeight = tex->getHeight();

    //ratio 
    Ogre::Real ratio = tHeight / tWidth;
    OverlayContainer* debugPanel = (OverlayContainer*)
        (OverlayManager::getSingleton().createOverlayElement("Panel", "Ogre/DebugTexPanel" + StringConverter::toString(i)));
    debugPanel->_setPosition(0.0, 0.0);
    debugPanel->_setDimensions(0.5f, 0.5f * ratio);
    debugPanel->setMaterialName(debugMat->getName());
    debugOverlay->add2D(debugPanel);
}

