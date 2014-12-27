tipboard-mobile-reviews
=======================

Ruby script for Tipboard dashboard which lets you fetch and display random app review for all three platforms: Android, iOS and Windows Phone.

#Requirements
- A configured and running instance of [Tipboard](tipboard.allegrogroup.com)
- Ruby 1.9.3
- The following gems: *rest_client*, *wombat*, *logging*
- An API key for [PlayStoreApi](http://www.playstoreapi.com/)

#Configuration
It's pretty straightforward. Just open the script and take a look. All of the parameters are pretty self-explanatory and don't require any description.

#Running the script
`ruby tipboard-mobile-reviews.rb`

#TODO
- fetch more data (stars, app icon, ...?)
- create a custom tile for Tipboard (could show stars, be formatted nicely, show app store icon, etc)
- better error handling
- improve the code? I'm new to Ruby :)

#License


>The MIT License (MIT)

>Copyright (c) 2014 Paweł Kwieciński <pawel@kwiecinski.me>
>
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

>The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

>THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
