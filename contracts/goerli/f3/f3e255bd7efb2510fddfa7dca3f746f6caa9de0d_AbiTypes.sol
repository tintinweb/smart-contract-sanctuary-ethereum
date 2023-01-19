// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract AbiTypes {
    //////////////////////////////////////////////////////////////////////
    // Single params

    function staticUint(uint xIn) public pure returns (uint xOut) {
        return xIn;
    }

    function staticUint8(uint8 xIn) public pure returns (uint8 xOut){
        return xIn;
    }

    function staticUint32(uint32 xIn) public pure returns (uint32 xOut){
        return xIn;
    }

    function staticUint256(uint32 xIn) public pure returns (uint256 xOut){
        return xIn;
    }

    function staticUintArray(uint[3] calldata xIn) public pure returns (uint[3] calldata xOut){
        return xIn;
    }

    function staticUintNestedArray(uint[3][2] calldata xIn) public pure returns (uint[3][2] calldata xOut){
        return xIn;
    }

    function dynamicUintArray(uint[] calldata xIn) public pure returns (uint[] calldata xOut){
        return xIn;
    }

    function staticInt(int xIn) public pure returns (int xOut){
        return xIn;
    }

    function staticInt8(int8 xIn) public pure returns (int8 xOut){
        return xIn;
    }

    function staticInt32(int32 xIn) public pure returns (int32 xOut){
        return xIn;
    }

    function staticInt256(int32 xIn) public pure returns (int256 xOut){
        return xIn;
    }

    function staticIntArray(int[3] calldata xIn) public pure returns (int[3] calldata xOut){
        return xIn;
    }

    function dynamicIntArray(int[] calldata xIn) public pure returns (int[] calldata xOut){
        return xIn;
    }

    function staticAddress(address xIn) public pure returns (address xOut){
        return xIn;
    }

    function staticAddressArray(address[2] calldata xIn) public pure returns (address[2] calldata xOut){
        return xIn;
    }

    function dynamicAddressArray(address[] calldata xIn) public pure returns (address[] calldata xOut){
        return xIn;
    }

    function staticBoolean(bool xIn) public pure returns (bool xOut){
        return xIn;
    }

    function staticBooleanArray(bool[2] calldata xIn) public pure returns (bool[2] calldata xOut){
        return xIn;
    }

    function dynamicBooleanArray(bool[2] calldata xIn) public pure returns (bool[2] calldata xOut){
        return xIn;
    }

    function staticBytes8(bytes8 xIn) public pure returns (bytes8 xOut){
        return xIn;
    }

    function staticBytes16(bytes16 xIn) public pure returns (bytes16 xOut){
        return xIn;
    }

    function staticBytes8Array(bytes8[2] calldata xIn) public pure returns (bytes8[2] calldata xOut){
        return xIn;
    }

    function dynamicBytes(bytes calldata xIn) public pure returns (bytes calldata xOut){
        return xIn;
    }

    function dynamicBytesArray(bytes[] calldata xIn) public pure returns (bytes[] calldata xOut){
        return xIn;
    }

    function dynamicString(string calldata xIn) public pure returns (string calldata xOut){
        return xIn;
    }

    function dynamicStringArray(string[] calldata xIn) public pure returns (string[] calldata xOut){
        return xIn;
    }

    function dynamicStringNestedStaticArray(string[2][3] calldata xIn) public pure returns (string[2][3] calldata xOut){
        return xIn;
    }

    function dynamicStringNestedDynamicArray(string[][][] calldata xIn) public pure returns (string[][][] calldata xOut){
        return xIn;
    }

    //////////////////////////////////////////////////////////////////////
    // Multiple params

    function uintBoolAddress(uint xIn, bool yIn, address zIn) public pure returns (uint xOut){
        return xIn;
    }
    
    function uintBoolString(uint xIn, bool yIn, string calldata zIn) public pure returns (uint xOut){
        return xIn;
    }

    function uintArrayBoolString(uint[2] calldata xIn, bool yIn, string calldata zIn) public pure returns (uint[2] calldata xOut){
        return xIn;
    }

    function uintArrayBoolString2(uint[] calldata xIn, bool yIn, string calldata zIn) public pure returns (uint[] calldata xOut){
        return xIn;
    }

    function uintArrayBoolStringArray(uint[2] calldata xIn, bool yIn, string[3] calldata zIn) public pure returns (uint[2] calldata xOut){
        return xIn;
    }

    function uintArrayBoolStringArray2(uint[2] calldata xIn, bool yIn, string[] calldata zIn) public pure returns (uint[2] calldata xOut){
        return xIn;
    }

    //////////////////////////////////////////////////////////////////////
    // Tuple return type

    function uintBoolAddressReturn(uint xIn, bool yIn, address zIn) public pure returns (uint xOut, bool yOut, address zOut){
        return (xIn, yIn, zIn);
    }

    function uintBoolStringReturn(uint xIn, bool yIn, string calldata zIn) public pure returns (uint xOut, bool yOut, string calldata zOut){
        return (xIn, yIn, zIn);
    }

    function uintArrayBoolStringReturn(uint[2] calldata xIn, bool yIn, string calldata zIn) public pure returns (uint[2] calldata xOut, bool yOut, string calldata zOut) {
        return (xIn, yIn, zIn);
    }

    function uintArrayBoolString2Return(uint[] calldata xIn, bool yIn, string calldata zIn) public pure returns (uint[] calldata xOut, bool yOut, string calldata zOut) {
        return (xIn, yIn, zIn);
    }

    function uintArrayBoolStringArrayReturn(uint[2] calldata xIn, bool yIn, string[3] calldata zIn) public pure returns (uint[2] calldata xOut, bool yOut, string[3] calldata zOut) {
        return (xIn, yIn, zIn);
    }

    function uintArrayBoolStringArrayReturn(uint[2] calldata xIn, bool yIn, string[] calldata zIn) public pure returns (uint[2] calldata xOut, bool yOut, string[] calldata zOut) {
        return (xIn, yIn, zIn);
    }

    //////////////////////////////////////////////////////////////////////
    // Structs

    struct Foo {
        uint256 x;
        bool y;
        address z;
    }

    Foo public wagmi;

    function staticStruct(Foo calldata fooIn) public pure returns (Foo calldata fooOut){
        return fooIn;
    }

    struct Bar {
        Foo foo;
        Foo baz;
        uint8[2] x;
    }

    function staticStruct2(Bar calldata barIn) public pure returns (Bar calldata barOut){
        return barIn;
    }

    struct Baz {
        uint256[] x;
        bool y;
        string[] z;
    }

    function dynamicStruct(Baz calldata bazIn) public pure returns (Baz calldata bazOut){
        return bazIn;
    }

    struct Wagmi {
        Baz foo;
        uint256 a;
        string[] b;
    }

    function dynamicStruct2(Wagmi calldata wagmiIn) public pure returns (Wagmi calldata wagmiOut){
        return wagmiIn;
    }

    struct Gmi {
        Wagmi foo;
        Wagmi bar;
        uint256 c;
        string[] d;
    }

    function dynamicStruct3(Gmi calldata gmiIn) public pure returns (Gmi calldata gmiOut){
        return gmiIn;
    }

    function staticStructParams(Foo calldata fooIn, Bar calldata barIn) public pure returns (Foo calldata fooOut, Bar calldata barOut){
        return (fooIn, barIn);
    }

    function staticStructStaticArrayParams(Foo[2] calldata fooIn, Bar[3] calldata barIn, Foo calldata fooIn2) public pure returns (Foo[2] calldata fooOut, Bar[3] calldata barOut, Foo calldata fooOut2){
        return (fooIn, barIn, fooIn2);
    }

    function staticStructStaticNestedArrayParams(Foo[2][3] calldata fooIn, Bar[3][2] calldata barIn, Foo calldata fooIn2) public pure returns (Foo[2][3] calldata fooOut, Bar[3][2] calldata barOut, Foo calldata fooOut2){
        return (fooIn, barIn, fooIn2);
    }

    function staticStructDynamicArrayParams(Foo[] calldata fooIn, Bar[] calldata barIn, Foo calldata fooIn2) public pure returns (Foo[] calldata fooOut, Bar[] calldata barOut, Foo calldata fooOut2){
        return (fooIn, barIn, fooIn2);
    }

    function staticStructDynamicNestedArrayParams(Foo[][][] calldata fooIn, Bar[][][] calldata barIn, Foo calldata fooIn2) public pure returns (Foo[][][] calldata fooOut, Bar[][][] calldata barOut, Foo calldata fooOut2){
        return (fooIn, barIn, fooIn2);
    }

    function dynamicStructParams(Baz calldata bazIn, Gmi calldata gmiIn) public pure returns (Baz calldata bazOut, Gmi calldata gmiOut){
        return (bazIn, gmiIn);
    }

    function dynamicStructStaticArrayParams(Baz[2] calldata bazIn, Gmi[3] calldata gmiIn, Wagmi calldata wagmiIn) public pure returns (Baz[2] calldata bazOut, Gmi[3] calldata gmiOut, Wagmi calldata wagmiOut){
        return (bazIn, gmiIn, wagmiIn);
    }

    function dynamicStructDynamicArrayParams(Baz[] calldata bazIn, Gmi[] calldata gmiIn, Wagmi calldata wagmiIn) public pure returns (Baz[] calldata bazOut, Gmi[] calldata gmiOut, Wagmi calldata wagmiOut){
        return (bazIn, gmiIn, wagmiIn);
    }

    //////////////////////////////////////////////////////////////////
    // Events

    event Address(address indexed foo, uint indexed bar, string barry);
    event Uint32(uint32 indexed foo, uint32 indexed bar, address indexed baz, string barry);
    event Int32(int32 indexed foo, int32 indexed bar, string baz);
    event String(string indexed foo, string indexed bar, string baz);
    event Bytes32(bytes32 indexed foo, bytes32 indexed bar, string baz);
    event Uint(uint indexed foo, uint indexed bar, string baz);
    event Uint24StaticArray(uint24[2] indexed foo, uint24[2] indexed bar, string baz);
    event UintDynamicArray(uint[] indexed foo, uint[] indexed bar, string baz);
    event Boolean(bool indexed foo, bool indexed bar, string baz);

    function callEvents() public {
        uint[] memory array = new uint[](10);
        array[0] = 69;

        emit Address(msg.sender, 69420, "foobar");
        emit Uint32(69, 420, msg.sender, "foobar");
        emit Int32(-69, -420, "foobar");
        emit String("Hello World", "Foobar", "foobar");
        emit Bytes32("Hello World", "Foobar", "foobar");
        emit Uint(69420, 420, "foobar");
        emit Uint24StaticArray([69420, 69420], [69421, 42069], "foobar");
        emit Boolean(true, false, "foobar");
        emit UintDynamicArray(array, array, "foobar");
    }

    //////////////////////////////////////////////////////////////////
    // Errors

    error AddressError(address foo);
    error Uint32Error(uint32 foo);
    error Int32Error(int32 foo);
    error StringError(string foo);
    error Bytes32Error(bytes32 foo);
    error UintError(uint foo);
    error Uint24StaticArrayError(uint24[2] foo);
    error UintDynamicArrayError(uint[] foo);
    error BooleanError(bool foo);

    function revertAddress() public view {
        revert AddressError(msg.sender);
    }

    function revertUint32() public pure {
        revert Uint32Error(69);
    }

    function revertInt32() public pure {
        revert Int32Error(-69);
    }

    function revertString() public pure {
        revert StringError("foobar");
    }

    function revertBytes32() public pure {
        revert Bytes32Error("foobar");
    }

    function revertUint() public pure {
        revert UintError(69420);
    }

    function revertUint24StaticArray() public pure {
        revert Uint24StaticArrayError([69420, 420]);
    }

    function revertUintDynamicArray() public pure {
        uint[] memory array = new uint[](10);
        array[0] = 69;
        array[1] = 420;
        revert UintDynamicArrayError(array);
    }
    
    function revertBoolean() public pure {
        revert BooleanError(true);
    }
}