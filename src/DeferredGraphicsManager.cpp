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

#include <string>

#include <OgreDepthBuffer.h>
#include "graphics/DeferredGraphicsManager.h"


using namespace ZGame;

DeferredGraphicsManager::DeferredGraphicsManager()
    :
    _MRTTGBuffer(0),
    _mrttViewport(0)
{
}

DeferredGraphicsManager::~DeferredGraphicsManager()
{
}

void
    DeferredGraphicsManager::_setupRenderTexture(Ogre::RenderTexture* renderTexture)
{
    renderTexture->setAutoUpdated(false);
    renderTexture->setDepthBufferPool(Ogre::DepthBuffer::POOL_DEFAULT);
}

void
    DeferredGraphicsManager::initialize(Ogre::Camera* cam,
    int GBufferWidth, int GBufferHeight)
{
	int numOfMips = 0;
    _normalDepthTex = Ogre::TextureManager::getSingleton().createManual("GBUFFER_NORMALDEPTH", 
        "PROJECT_ZOMBIE", Ogre::TEX_TYPE_2D, GBufferWidth, GBufferHeight, numOfMips, Ogre::PF_FLOAT16_RGBA,
        Ogre::TU_RENDERTARGET, 0, false);
	int mips = _normalDepthTex->getNumMipmaps();
	std::cout << "Number of mips in normal depth texture: " << mips << std::endl;
    //Setup the gbufer render texture.
    Ogre::RenderTexture* renderTexture = _normalDepthTex->getBuffer()->getRenderTarget();
    _setupRenderTexture(renderTexture);
	/*
    _gBuffer1Tex = Ogre::TextureManager::getSingleton().createManual("GBUFFER_BUFFER1",
		"PROJECT_ZOMBIE", Ogre::TEX_TYPE_2D, GBufferWidth, GBufferHeight, numOfMips, Ogre::PF_FLOAT16_RGBA, 
        Ogre::TU_RENDERTARGET);
    renderTexture = _gBuffer1Tex->getBuffer()->getRenderTarget();
    _setupRenderTexture(renderTexture);
	*/
    //Setup MRTT
 //   _gBufferMRTT = Ogre::Root::getSingleton().getRenderSystem()->createMultiRenderTarget("GBUFFER_MRT");
 //   _gBufferMRTT->bindSurface(0, _normalDepthTex->getBuffer()->getRenderTarget());
 //   _gBufferMRTT->bindSurface(1, _gBuffer1Tex->getBuffer()->getRenderTarget());
 //   _gBufferMRTT->setAutoUpdated(false);
	//_gBufferMRTT->setDepthBufferPool(Ogre::DepthBuffer::POOL_DEFAULT);
	////Ogre::DepthBuffer* dbuffer = _gBufferMRTT->getDepthBuffer();

 //   Ogre::Viewport* mrttVp = _gBufferMRTT->addViewport(cam);
 //   mrttVp->setClearEveryFrame(false);
	//mrttVp->setBackgroundColour(Ogre::ColourValue::White);
	//
 //   mrttVp->setDepthClear(0.0f);
 //   mrttVp->setBackgroundColour(Ogre::ColourValue::Black);
 //   mrttVp->setVisibilityMask(0xf);
 //   mrttVp->setOverlaysEnabled(false);
 //   mrttVp->setSkiesEnabled(false);
 //   mrttVp->setMaterialScheme("gbuffer");

	//For a single gBuffer texture.
	Ogre::Viewport* mrttVp = _normalDepthTex->getBuffer()->getRenderTarget()->addViewport(cam);
    mrttVp->setClearEveryFrame(false);
    mrttVp->setDepthClear(0.0f);
    mrttVp->setBackgroundColour(Ogre::ColourValue::Black);
    mrttVp->setVisibilityMask(0xf);
    mrttVp->setOverlaysEnabled(false);
    mrttVp->setSkiesEnabled(false);
    mrttVp->setMaterialScheme("gbuffer");



    _lightBufferTex = Ogre::TextureManager::getSingleton().createManual("LIGHTBUFFER",
		"PROJECT_ZOMBIE", Ogre::TEX_TYPE_2D, GBufferWidth, GBufferHeight, 0, Ogre::PF_FLOAT16_RGBA,
        Ogre::TU_RENDERTARGET, 0, false);

	//Setup the light buffer render texture.
    Ogre::RenderTexture* lightBufferRT = _lightBufferTex->getBuffer()->getRenderTarget();
    //lightBufferRT->setDepthBufferPool(Ogre::DepthBuffer::POOL_DEFAULT);
    //Ogre::LogManager::getSingleton().logMessage("Pool ID for light" + lightBufferRT->getDepthBuffer()->getPoolId());
    
    lightBufferRT->addViewport(cam);
    lightBufferRT->getViewport(0)->setClearEveryFrame(false);
    lightBufferRT->getViewport(0)->setBackgroundColour(Ogre::ColourValue::Black);
    lightBufferRT->getViewport(0)->setDepthClear(0.0);
	lightBufferRT->getViewport(0)->setOverlaysEnabled(false);
    lightBufferRT->getViewport(0)->setSkiesEnabled(false);
    lightBufferRT->getViewport(0)->setVisibilityMask(0xf0);
	
    lightBufferRT->setAutoUpdated(false);
	

    //Now associate GBUFFER_NORMALDEPTH texture to the material PRJZ/LightBuffer. 
    Ogre::MaterialPtr mat = static_cast<Ogre::MaterialPtr>(
        Ogre::MaterialManager::getSingleton().getByName("PRJZ/LightBuffer"));
    if(mat.isNull())
        OGRE_EXCEPT(Ogre::Exception::ERR_INVALIDPARAMS, "Material pointer for PRJZ/LightBuffer is not valid", "DeferredGraphicsManager::initialize");
    mat->getTechnique(0)->getPass(0)->getTextureUnitState("gBuffer")->setTextureName(_normalDepthTex->getName());
	
    //directional sun light
    mat = static_cast<Ogre::MaterialPtr>(
        Ogre::MaterialManager::getSingleton().getByName("PRJZ/DirectionLightBuffer"));
    if(mat.isNull())
        OGRE_EXCEPT(Ogre::Exception::ERR_INVALIDPARAMS, "Material pointer for PRJZ/DirectionLightBuffer is not valid",
        "DeferredGraphicsManager::initialize");
    mat->getTechnique(0)->getPass(0)->getTextureUnitState("gBuffer")->setTextureName(_normalDepthTex->getName());

    
    mat = static_cast<Ogre::MaterialPtr>(
        Ogre::MaterialManager::getSingleton().getByName("PRJZ/Minecraft2"));
    if(mat.isNull())
        OGRE_EXCEPT(Ogre::Exception::ERR_INVALIDPARAMS, "Material pointer for PRJZ/Minecraft is not valid", "DeferredGraphicsManager::initialize");
    //mat->getTechnique(0)->getPass(0)->getTextureUnitState(3)->setTextuxreName(_gBuffer1Tex->getName()); //Disable this fore now and use scripted texture attachment becaues MRTT is not working. We will read diffuse texture in deferred pass.
    //mat->getTechnique(0)->getPass(0)->getTextureUnitState(4)->setTextureName(_normalDepthTex->getName());
    //mat->getTechnique(0)->getPass(0)->getTextureUnitState(5)->setTextureName(_lightBufferTex->getName());
	mat->getTechnique(0)->getPass(0)->getTextureUnitState("gBuffer")->setTextureName(_normalDepthTex->getName());
	mat->getTechnique(0)->getPass(0)->getTextureUnitState("lBuffer")->setTextureName(_lightBufferTex->getName());

    //now map it to PRJZ/MinecraftCharacter
    mat = static_cast<Ogre::MaterialPtr>(
        Ogre::MaterialManager::getSingleton().getByName("PRJZ/MinecraftCharacter"));
    if(mat.isNull())
        OGRE_EXCEPT(Ogre::Exception::ERR_INVALIDPARAMS, "Material pointer for PRJZ/MinecraftCharacter is not valid", "DeferredGraphicsManager::initialize");
    //mat->getTechnique(0)->getPass(0)->getTextureUnitState(3)->setTextureName(_gBuffer1Tex->getName());
    mat->getTechnique(0)->getPass(0)->getTextureUnitState(4)->setTextureName(_normalDepthTex->getName());
    mat->getTechnique(0)->getPass(0)->getTextureUnitState(5)->setTextureName(_lightBufferTex->getName());


    std::vector<Ogre::String> materialNames;

    materialNames.push_back("PRJZ/HWBasic");
	materialNames.push_back("preview_cubemap");
	materialNames.push_back("preview_diffusenormalspecular");
	materialNames.push_back("preview2_diffusenormalspecular");
	materialNames.push_back("preview3_diffusenormalspecular");

    _attachDeferredTexturesToMaterials(materialNames);

    Ogre::LogManager::getSingleton().getDefaultLog()->logMessage("Pool ID for light"
    		+ lightBufferRT->getDepthBufferPool(),
    				Ogre::LML_NORMAL);
}

void
    DeferredGraphicsManager::_attachDeferredTexturesToMaterials(std::vector<Ogre::String> materialNames)
{
    for(const Ogre::String &materialName : materialNames)
    {
    	Ogre::MaterialPtr mat = static_cast<Ogre::MaterialPtr>(
    			Ogre::MaterialManager::getSingleton().getByName(materialName));
    	if (mat.isNull())
    	{
    		Ogre::String errorMessage("Material for ");
    		errorMessage += materialName + " is not valid";
    		OGRE_EXCEPT(Ogre::Exception::ERR_INVALIDPARAMS,
    				errorMessage,
    				"DeferredGraphicsManager::initialize");
    	}
    	Ogre::Pass* pass0 = mat->getTechnique("lighting")->getPass(0);

    	pass0->getTextureUnitState("gBuffer")->setTextureName(_normalDepthTex->getName());
    	pass0->getTextureUnitState("lBuffer")->setTextureName(_lightBufferTex->getName());

    }
    /*
	for(auto iter = materialNames.cbegin(); iter != materialNames.cend(); ++iter)
    {
        Ogre::MaterialPtr mat = static_cast<Ogre::MaterialPtr>(
            Ogre::MaterialManager::getSingleton().getByName(*iter));
        Ogre::String errorMessage("Material for ");
        errorMessage += *iter + " is not valid";
        if(mat.isNull())
            OGRE_EXCEPT(Ogre::Exception::ERR_INVALIDPARAMS, errorMessage, "DeferredGraphicsManager::initialize");
		mat->getTechnique("lighting")->getPass(0)
				->getTextureUnitState("gBuffer")
				->setTextureName(_normalDepthTex->getName());
		mat->getTechnique("lighting")->getPass(0)
				->getTextureUnitState("lBuffer")
				->setTextureName(_lightBufferTex->getName());
    }
    */
}

void
    DeferredGraphicsManager::update()
{
	//_gBufferMRTT->update(true);
	//_gBuffer1Tex->getBuffer()->getRenderTarget()->update(true);
	
    
	_normalDepthTex->getBuffer()->getRenderTarget()->update(false);
    //_lightBufferTex->getBuffer()->getRenderTarget()->update(false);
}

void
    DeferredGraphicsManager::clear()
{
	//_gBufferMRTT->getViewport(0)->clear(Ogre::FBT_COLOUR | Ogre::FBT_DEPTH, Ogre::ColourValue::White);
    
	//_normalDepthTex->getBuffer()->getRenderTarget()->swapBuffers(true);
	_normalDepthTex->getBuffer()->getRenderTarget()->getViewport(0)->clear(Ogre::FBT_COLOUR | Ogre::FBT_DEPTH, Ogre::ColourValue::Black, 1.0, 0.0);

	//_gBuffer1Tex->getBuffer()->getRenderTarget()->getViewport(0)->clear();
	//_lightBufferTex->getBuffer()->getRenderTarget()->swapBuffers(true);
	_lightBufferTex->getBuffer()->getRenderTarget()->getViewport(0)->clear(Ogre::FBT_COLOUR | Ogre::FBT_DEPTH , Ogre::ColourValue(0, 0, 0, 0), 1.0, 0.0);// | Ogre::FBT_STENCIL);
}
