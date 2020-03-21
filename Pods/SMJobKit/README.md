SMJobKit
========

Using SMJobBless and friends is rather ...painful.  SMJobKit does everything in its power to
alleviate that and get you back to writing awesome OS X apps.

SMJobKit is more than just a framework/library to link against.  It gives you:

* A Xcode target template for SMJobBless-ready launchd services, completely configured for proper
  code signing!
   
* A client abstraction that manages installing/upgrading your app's service(s).

* A service library that pulls in as little additional code as possible.  Less surface area for
  security vulnerabilities!


Project Configuration
---------------------

To get started, pull the SMJobKit project into your own project or workspace.  Have your application
depend on the SMJobKit framework, and hit build.  In addition to building the framework, this also
causes the Xcode template to install its self into `~/Library/Developer/Xcode/Templates`.

Next, you should set up your service helper/target: Add a new _SMJobKit Service_ target to the
project.  This is relatively configuration-heavy, so you should probably build it right away to make
sure everything is properly configured (and your code signing certificates are in order).  You may
want to review the [template's documentation](https://github.com/nevir/XMJobKit/tree/master/SMJobKit Service.xctemplate)
for an in-depth explanation of what it is doing for you.

Finally, you need to add a Copy Files build phase to your application target.  The destination
should be "Wrapper" with a subpath of `Contents/Library/LaunchServices`.  Add the service's built
product to the list.  Make sure you add a dependency on your service target!

And, hopefully, that's all you need to do in order to configure your project!


Client Abstraction
------------------

You'll want to create a subclass of `SMJClient` in your application, and override
`serviceIdentifier` at the very least.


Service Implementation
----------------------
