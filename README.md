# Message Indicator

<p align="center">
  <img src="preview.jpg" height="300" >
</p>

### The Problem
I commonly open chats in Messages on my computer to make the 'unread' indicator go away.  However, if there's any delay in answering them back, it's quite common that I'll simply forget to respond to the text for a while.

### The Solution
I read about SIMBL, a plugin manager for Mac OS X, a while ago in pursuing a different project.  Effectively, it acts much like Cydia does for iOS, but for your Mac instead.  I used it to build a bundle that inserts itself into the Messages application, and adds a small gray indicator icon on chats in which you were not the last person to respond (it doesn't show up on group chats, as it quickly becomes unwieldy in large chats).  This makes it a lot easier to see the messages that you haven't responded back to.  I've only tested this on 10.12, but it should conceivably work on earlier versions.

### Installation:
1. Download [mySIMBL](https://github.com/w0lfschild/app_updates/raw/master/mySIMBL/mySIMBL_0.2.5.zip)
2. Download [Message Indicator](https://github.com/dado3212/message-indicator/raw/master/build/message-indicator.zip)
3. Unzip the downloaded .zip file
4. Open `message-indicator.bundle` with `mySIMBL.app`, or simply drag and drop it.
5. Restart Messages.
