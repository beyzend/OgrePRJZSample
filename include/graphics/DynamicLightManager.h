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

namespace OgreBulletDynamics
{
    class RigidBody;
}

namespace ZGame
{
    namespace Graphics
    {
        class DynamicLightManager : public Ogre::SceneNode::Listener
        {
        public:
            DynamicLightManager();
            virtual ~DynamicLightManager();

            bool
                onInit(ZGame::ZInitPacket* initPacket);
            void
                initInstanceLights(Geometry::GeometryManager* geoMgr);
            void
                createLight(const Ogre::Vector3 &pos, 
                const Ogre::Vector3 &dir, 
                Ogre::Real speed,
                //Geometry::GeometryManager* geoMgr,
                World::PhysicsManager* phyMgr,
                bool physics = true);

            Ogre::SceneNode*
                createLight(bool physics = false);
                


            void
                undoLastLight();

            /**
            * This method will update the lights. Namely the custom parameters
            *will be updated.
            *
            **/
            void
                update(Ogre::Camera* cam, Ogre::Viewport* viewport);
                //update();
            Ogre::SceneNode*
                getLightRoot()
            {
                return _lgtRoot;
            }

            Ogre::SceneNode*
                getDebugRoot()
            {
                return _debugRoot;
            }

            Ogre::SceneNode*
                getStaticRoot()
            {
                return _staticRoot;
            }

            void
                updateDebugNodes();

        protected:
        private:
            typedef std::pair<Ogre::SceneNode*, OgreBulletDynamics::RigidBody*> LIGHTPAIR;
            Ogre::SceneNode* _lgtRoot;
            Ogre::SceneNode* _staticRoot;
            Ogre::SceneNode* _debugRoot;
            Ogre::SceneManager* _scnMgr;

            Ogre::InstanceManager* _instMgrGeometry;
            Ogre::InstanceManager* _instMgrDebug;

            size_t numCreated;
            std::vector<LIGHTPAIR*> _pairVec;
            Ogre::SceneNode* _lastLight;

            Ogre::vector<Ogre::SceneNode*>::type _instancedNodes;
            Ogre::vector<OgreBulletDynamics::RigidBody*>::type _bodyVec;
            Ogre::vector<Ogre::SceneNode*>::type _debugNodes;
            size_t _lightPoolSize;

            Ogre::Vector3 _defaultPosition;
			
            void
                _createInstancedLightPool();
            void
                _createLightPool(const Ogre::String &meshName);


        };
    }
}