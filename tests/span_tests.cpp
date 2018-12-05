#ifdef _MSC_VER
// blanket turn off warnings from CppCoreCheck from catch
// so people aren't annoyed by them when running the tool.
#pragma warning(disable : 26440 26426 26497) // from catch

#endif

#include <catch/catch.hpp> // for AssertionHandler, StringRef, CHECK, TEST_...

