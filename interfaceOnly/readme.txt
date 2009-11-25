DUMMY Console interface

Where would you need it?
If you are loading a module (swf/swc) that require the use of Console, but you don't want to
embed the console inside that swf (because of size), you might as well use a dummy Console interfce (this) in these swfs.
When loaded into the main/shell swf which have the real console instantiated, Console would work as intended in the loaded swfs.
- Thats provided you set the applicationDomain to use the main swf's applicationDomain.
While using this class, all console related functions will silently fail to work.
//
Another use is when you have finished development and no longer need Console. 
Replacing the real console's C class with this one will save you some size (~35kb) on the final SWF.