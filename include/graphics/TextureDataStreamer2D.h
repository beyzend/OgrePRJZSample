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
#include "utilities/PolyVoxArrayAccessor.h"
namespace ZGame
{
    namespace Graphics
    {
        class TextureDataStreamer2D
        {
        public:
            TextureDataStreamer2D(const Ogre::String &name,
                size_t numOfPagesPerAxis, size_t pageDim);
            TextureDataStreamer2D(Ogre::TexturePtr tex,
                size_t numOfPagesPerAxis, size_t pageDim);
            ~TextureDataStreamer2D();

            void
                pageIn(Utils::HeightValueArrayAccessor heightVals,
                Ogre::int32 pageX, Ogre::int32 pageY,
                Ogre::int32 volLocalX, Ogre::int32 volLocalY,
                Ogre::int32 camPageX, Ogre::int32 camPageY);
            
            Ogre::TexturePtr
                getTexture()
            {
                return _dataTex2D;
            }
        protected:
        private:
            Ogre::TexturePtr _dataTex2D;
            size_t _numOfPagesPerAxis;
            size_t _pageDim;
        };

    }
}