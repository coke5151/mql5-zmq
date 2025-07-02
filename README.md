# mql5-zmq

ZMQ binding for MQL5 language (64bit MT5)

- [mql5-zmq](#mql5-zmq)
  - [Introduction](#introduction)
  - [Why This Fork](#why-this-fork)
  - [Major Fixes](#major-fixes)
    - [1. MQL5 ZeroMQ Type Conversion Errors (17 compilation errors fixed)](#1-mql5-zeromq-type-conversion-errors-17-compilation-errors-fixed)
    - [2. MQL5 Property Compatibility Issues](#2-mql5-property-compatibility-issues)
    - [Fix Strategy](#fix-strategy)
  - [Files and Installation](#files-and-installation)
  - [About string encoding](#about-string-encoding)
  - [Notes on context creation](#notes-on-context-creation)
  - [Usage](#usage)
  - [Changes](#changes)
    - [Fork Changes (2025)](#fork-changes-2025)
    - [Original Project Changes](#original-project-changes)

## Introduction
This is a complete binding of the [ZeroMQ](http://zeromq.org/) library
for the MQL5 language provided by MetaTrader5.

Traders with programming abilities have always wanted a messaging solution like
ZeroMQ, simple and powerful, far better than the PIPE trick as suggested by the
official articles. However, bindings for MQL were either outdated or not
complete (mostly toy projects and only basic features are implemented). This
binding is based on latest 4.2 version of the library, and provides all
functionalities as specified in the API documentation.

This fork focuses exclusively on MQL5 support to ensure maximum compatibility
and stability. While the original project attempted to maintain compatibility
between MQL4/5, this approach led to various compatibility issues due to the
differences in type systems and runtime environments.

## Why This Fork
This fork was created to address critical compilation errors and compatibility
issues that prevented the original mql5-zmq library from working with modern
MQL5 environments. The original project had 17 compilation errors related to
type conversion issues and deprecated MQL5 properties.

## Major Fixes
### 1. MQL5 ZeroMQ Type Conversion Errors (17 compilation errors fixed)

**Root Cause**: MQL5's strict type system doesn't allow implicit conversion between `char[]` and `uchar[]` arrays.

**Fixed Files and Changes**:

- **Include/Mql/Lang/Native.mqh**
  - Added `StringFromUtf8(const char &utf8[])` overload function
  - Added `StringToUtf8(const string str, char &utf8[], bool ending = true)` overload function
  - These overloads handle type conversion between `char[]` and `uchar[]`

- **Include/Zmq/Z85.mqh**
  - Fixed `encode(string data)` function: changed `char[]` to `uchar[]`
  - Fixed `generateKeyPair()` function: added proper type conversion logic
  - Fixed `derivePublic()` function: added `char[]` to `uchar[]` conversion

- **Include/Zmq/SocketOptions.mqh**
  - Fixed `getStringOption()` function: changed `char[]` to `uchar[]`
  - Fixed `setStringOption()` function: changed `char[]` to `uchar[]`

- **Include/Zmq/Socket.mqh**
  - Fixed `monitor()` function: changed `uchar[]` to `char[]` to match libzmq function signature
  - Other address handling functions maintain `char[]` usage

- **Include/Zmq/ZmqMsg.mqh**
  - Fixed `meta()` function: changed `uchar[]` to `char[]` to match `zmq_msg_gets` function signature

- **Include/Zmq/Zmq.mqh**
  - File encoding issues: completely recreated due to character spacing problems
  - Fixed `has()` function: changed `uchar[]` to `char[]` to match `zmq_has` function signature

### 2. MQL5 Property Compatibility Issues

**Problem**: `#property show_inputs` has been removed in newer MQL5 versions.

**Fixed Files**:
- Scripts/ZeroMQ/ZeroMQGuideExamples/Chapter1/WeatherUpdateClient.mq5
- Scripts/ZeroMQ/ZeroMQGuideExamples/Chapter3/RTReqBroker.mq5
- Scripts/ZeroMQ/ZeroMQGuideExamples/Chapter3/RTReqWorker.mq5

**Fix**: Removed deprecated `#property show_inputs` declarations.

### Fix Strategy

- **Systematic Approach**: Started from the foundation (`Native.mqh`) and worked up through dependent files
- **Type Consistency**: Ensured all libzmq function calls use correct parameter types
- **Backward Compatibility**: Added function overloads instead of directly modifying existing functions
- **Encoding Standardization**: Recreated files with encoding issues

## Files and Installation
This binding contains three sets of files:

1. The binding itself is in the `Include/Zmq` directory. *Note* that there is a
   `Mql` directory in `Include`, which is part of
   the [mql4-lib](https://github.com/dingmaotu/mql4-lib). Previous `Common.mqh`
   and `GlobalHandle.mqh` are actually from this library. At release 1.4, this
   becomes a direct reference, with mql4-lib content copied here verbatim. It is
   recommended you install the full mql4-lib, as it contains a lot other
   features. But for those who want to use mql-zmq alone, it is OK to deploy
   only the small subset included here.

2. The testing scripts and zmq guide examples are in `Scripts` directory. All
   script files are designed for MQL5 (.mq5 extension) and MetaTrader5.

3. Precompiled 64bit DLLs (`Library/MT5`) of ZeroMQ (4.2.0) and libsodium
   (1.0.11) are provided for MetaTrader5. Copy the DLLs to the `Library` folder
   of your MetaTrader5 terminal. **The DLLs require that you have the latest
   Visual C++ runtime (2015)**.

   *Note* that these DLLs are compiled from official sources, without any
   modification. You can compile your own if you don't trust these binaries. The
   `libsodium.dll` is copied from the official binary release. If you want to
   support security mechanisms other than `curve`, or you want to use transports
   like OpenPGM, you need to compile your own DLL.

## About string encoding
MQL strings are Win32 UNICODE strings (basically 2-byte UTF-16). In this binding
all strings are converted to utf-8 strings before sending to the dll layer. The
ZmqMsg supports a constructor from MQL strings, the default is _NOT_
null-terminated.

## Notes on context creation
In the official guide:

> You should create and use exactly one context in your process. Technically,
> the context is the container for all sockets in a single process, and acts as
> the transport for inproc sockets, which are the fastest way to connect threads
> in one process. If at runtime a process has two contexts, these are like
> separate ZeroMQ instances.

In MetaTrader, every Script and Expert Advsior has its own thread, but they all
share a process, that is the Terminal. So it is advised to use a single global
context on all your MQL programs. The `shared` parameter of `Context` is used
for sychronization of context creation and destruction. It is better named
globally, and in a manner not easily recognized by humans, for example:
`__3kewducdxhkd__`

## Usage
You can find a simple test script in `Scripts/Test`, and you can find examples
of the official guide in Scripts/ZeroMQGuideExamples. I intend to translate all
examples to this binding, but now only the hello world example is provided. I
will gradually add those examples. Of course forking this binding if you are
interested and welcome to send pull requests.

Here is a sample from `HelloWorldServer.mq4`:

```c++
#include <Zmq/Zmq.mqh>
//+------------------------------------------------------------------+
//| Hello World server in MQL                                        |
//| Binds REP socket to tcp://*:5555                                 |
//| Expects "Hello" from client, replies with "World"                |
//+------------------------------------------------------------------+
void OnStart()
{
    Context context("helloworld");
    Socket socket(context,ZMQ_REP);

    socket.bind("tcp://*:5555");

    while(true)
    {
        ZmqMsg request;

        // Wait for next request from client

        // MetaTrader note: this will block the script thread
        // and if you try to terminate this script, MetaTrader
        // will hang (and crash if you force closing it)
        socket.recv(request);
        Print("Receive Hello");

        Sleep(1000);

        ZmqMsg reply("World");
        // Send reply back to client
        socket.send(reply);
      }
}
```

## Changes
### Fork Changes (2025)

* **2025-01-XX**: **Major Fork Release**: Complete MQL5 compatibility fixes
  - Fixed 17 compilation errors related to `char[]`/`uchar[]` type conversion issues
  - Added proper function overloads in `Native.mqh` for type conversion handling
  - Fixed all ZeroMQ binding files (`Z85.mqh`, `SocketOptions.mqh`, `Socket.mqh`, `ZmqMsg.mqh`, `Zmq.mqh`)
  - Removed deprecated `#property show_inputs` from example scripts
  - Recreated `Zmq.mqh` to fix file encoding issues
  - Focused exclusively on MQL5 support for maximum stability
  - All ZeroMQ functionality now works correctly (version detection, Z85 encoding, atomic counters, Context management, Curve encryption)

### Original Project Changes

* 2017-10-28: Released 1.5: Important: API change for `Socket.send`; Remove
  PollItem duplicate API (#11); Fix compiler warning (#10) and compile failure
  (#12); Add RTReq example from ZMQ Guide Chapter 3.
* 2017-08-18: Released 1.4: Fix ZmqMsg setData bug; Change License to Apache
  2.0; Include mql4-lib dependencies directly.
* 2017-07-18: Released 1.3: Refactored poll support; Add Chapter 2 examples from
  the official ZMQ guide.
* 2017-06-08: Released 1.2: Fix GlobalHandle bug; Add rebuild method to ZmqMsg;
  Complete all examples in ZMQ Guide Chapter 1.
* 2017-05-26: Released 1.1: add the ability to share a ZMQ context globally in a terminal
* 2016-12-27: Released 1.0.