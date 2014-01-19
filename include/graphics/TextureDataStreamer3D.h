/**
Permission is hereby granted, free of charge, to any person obtaining a copy
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

#include <ZPrerequisites.h>

#include "world/WorldDefs.h"

namespace ZGame
{
    namespace Graphics
    {
        /**
        *This class handles streaming of data to a 3D texture. The input data class is hardcoded in the sense it's
        *a World::StatVolume, which is a PolyVox::SimpleVolume.
        *
        **/
        class TextureDataStreamer3D
        {
        public:
            TextureDataStreamer3D(const Ogre::String &name,
                size_t numOfPagesPerAxis, size_t height);
            ~TextureDataStreamer3D();

            /**
            * This class will page in data from StatVolume at the given pageX and pageY.
            **/
           void
                pageIn(const World::StatVolume* vol,
                Ogre::int32 pageX, Ogre::int32 pageY);
         

        protected:
        private:
            Ogre::TexturePtr _dataTex3D;
            size_t _numOfPagesPerAxis;
        };
    }
}