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
*email:
**/

#pragma once

#include "ZPrerequisites.h"

namespace ZGame
{
	namespace Graphics
	{
		struct GraphicsOptions
		{
			Ogre::uint clockRate;
			Ogre::uint clockHour;
			Ogre::Vector4 hdr_bright_limiter;
			Ogre::Real hdr_fudge_factor;
			Ogre::Real hdr_middle_grey;

			GraphicsOptions() 
				: clockRate(0)
				, clockHour(13)
				, hdr_bright_limiter(0.7f, 0.7f, 0.7f, 0.7f)
				, hdr_fudge_factor(0.3f)
				, hdr_middle_grey(0.7f)
			{
			}

		};
	}
}