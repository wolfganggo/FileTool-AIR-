# FileTool-AIR-
FileConverter is a tool that is best built with Adobe FlashBuilder but it can also be compiled with the command line version of the Flex compiler.
The program uses Adobe AIR what is a stand-alone container for Adobe Flash, thus both must be installed to run the program.
The program was first created as a simple tool to convert PNG images to ASCII files, so they can be included in source files. Later the tool was extended to be able to browse any files very effective and to do some not so common editing operations. The tool displays images, movies, plays sound files and displays all other files as text. In binary display mode all files are shown as hex dump. Double click on images opens an image window with ability to zoom and pan and to walk through the images in the current directory. Alternatively a thumbnail window can be opened first. Double click on all other files opens the text editor that has nine clipboard memories. Another text editor can edit the files binary, where also the null character has a text representation. In this editor the user can for example search and replace all '\r\n\n' with a single '\n'. The program has also a simple edit mode for wave files.
The second tool FileViewAndroid tries to put some of the features of FileConverter onto an Android device. FileViewAndroid can show the content of any file as text (except images) or as hex dump. Images can be shown as thumbnails and in full view mode. The gestures did not work in Flex, so only click, double click and long click can be used. Double click in the middle of an image zooms in, simple click zooms out. Long click in the middle shows file info, click in the outer region pans (when zoomed) or steps forward and backward. The showing of movies with Flash Player does not work due to a bug in Flex, that Adobe didn't fix. In the file list double click opens a text editor, shows images or steps into a directory. Long click opens a context menu. Write access works only on the internal memory and on USB sticks, but not on an inserted SD card due to the limitations in Android. Compiler: Flex SDK 4.6.0  OS: Mac + Win all current versions for FileConverter, Android 4.4 or higher for FileViewAndroid.