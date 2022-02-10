/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TestType {

    // 这是一个单行注释。

    /*
    这是一个
    多行注释。
    */
    
    // constructor([3,2,1], value: 100) --> getBalance: 100, getTestArr: 3,2,1
    uint[] public testarr;

    constructor(uint256[] memory item) payable {
       testarr = item;
    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    function getTestArr() public view returns (uint256[] memory) {
        return testarr;
    }

    // bool 
    // setBool(true) --> getBool(true, false) : true, false, true

    bool public testbool;

    function setBool(bool _setbool) public {
        testbool = _setbool;
    }

    function getBool(bool _true,bool _false) public view returns (bool , bool, bool) {
        return (_true, _false, testbool || _true);
    }

    // int,uint 
    // setIntUint(-57896044618658097711785492504343953926634992332820282019728792003956564819968, 115792089237316195423570985008687907853269984665640564039457584007913129639935) 
    // --> getIntUint(); -123321. 321123,-57896044618658097711785492504343953926634992332820282019728792003956564819968, 115792089237316195423570985008687907853269984665640564039457584007913129639935 : 
    int public testint;
    uint public testuint;

    function setIntUint(int _int, uint _uint) public {
        testint = _int;
        testuint = _uint;
    }

    function getIntUint(int _int, uint _uint) public view returns (int, uint, int, uint) {
        return (_int, _uint, testint, testuint);
    }

    //address
    // setAddr(0xbA2b06f246aB4682f3A15B2A5Dc0fe709a8d097f) value: 100 --> getAddr(): 0xbA2b06f246aB4682f3A15B2A5Dc0fe709a8d097f ,getBalance(): 200
    address public Addr;

    function setAddr(address _testAddr) public payable {
        Addr = _testAddr;
    }

    function getAddr() public view returns (address) {
        return Addr;
    }

    //bytes1234..32
    //setBytes3(0xffffff) --> getBytes3(0x01, 0x0002): 0x01, 0x0002, 0xffffff
    bytes3 public tBytes3; //"0x000000";

    function setBytes3(bytes3 _bytes3) public {
        tBytes3 = _bytes3;
    }

    function getBytes3(bytes1 _bytes1, bytes2 _bytes2) public view returns (bytes1, bytes2, bytes3) {
        return (_bytes1, _bytes2, tBytes3);
    }

    uint public a = 2.5e30;

    //string, bytes
    // setEmoji(😍😘🥰) --> getEmoji(😁😂🤣, "0xabcd", "chainIDE 永远嘀神")：😍😘🥰，😁😂🤣，"0xabcd", "chainIDE 永远嘀神"
    string public emoji = unicode"Hello 😃";

    bytes public foo = "foo\tf"; //ide:"0x666f6f5c66", remix: "0x666f6f0966"  asic: http://c.biancheng.net/c/ascii/  doc: https://learnblockchain.cn/docs/solidity/types.html#types

    string public foos = "foo\tf";

    bytes public fooss = hex"00112233" hex"44556677";

    string public foosss = hex"0011223344556677";

    function setEmoji(string memory _emoji) public {
        emoji = _emoji;
    }

    function getEmoji(string memory _emoji, bytes memory _foo, string memory _foos) public view returns (string memory, string memory, bytes memory, string memory) {
        return (emoji, _emoji, _foo, _foos);
    }

    //function-selector, address
    //f(): 0x26121ff0,  an address                  
    function f() public view returns (bytes4, address) {
    return (this.f.selector, this.f.address);
    }

    //array
    //setArr([1,2,3,4,5,6,7,8]) --> getArr(): [1,2,3,4,5,6,7,8]
    //setArr5([1,2,3,4,5] --> ) --> getArr5(): [1,2,3,4,5]
    //setArr55([[1,2,3,4,5],[1,2,3,4,5],[1,2,3,4,5],[1,2,3,4,5],[1,2,3,4,5]]) --> getArr55: [[1,2,3,4,5],[1,2,3,4,5],[1,2,3,4,5],[1,2,3,4,5],[1,2,3,4,5]]
    //setArr22([[[[3,4],[3,4]],[[3,4],[3,4]]], [[[3,4],[3,4]],[[3,4],[3,4]]]]) --> getArr22： remix 错误？
    uint[] public arr;

    function setArr(uint[] memory _arr) public {
        arr = _arr;
    }

    uint[5] public arr5;

    function setArr5(uint[5] memory _arr) public {
        arr5 = _arr;
    }

    uint[][5] public arr55;

    uint[2][2][2] public arr22;

    function setArr22(uint[2][2][2] memory _arr) public {
        arr22 = _arr;
    }

    function getArr22() public view returns (uint256[2][2][2] memory) {
        return arr22;
    }

    function setArr55(uint[][5] memory _arr) public {
        arr55 = _arr;
    }

    function getArr() public view returns (uint256[] memory) {
        return arr;
    }
    
    function getArr5() public view returns (uint256[5] memory) {
        return arr5;
    }

    function getArr55() public view returns (uint256[][5] memory) {
        return arr55;
    }

    //mapping
    // update(20220209) --> balances[your address]: 202202209
    mapping(address => uint) public balances;

    function update(uint newBalance) public {
        balances[msg.sender] = newBalance;
    }

    //struct
    //setTodo(["111", true, 0xbA2b06f246aB4682f3A15B2A5Dc0fe709a8d097f, "0x01", 1, -1, [1,2,3], [[1],[2]]]) --> getTodo: ["111", true, 0xbA2b06f246aB4682f3A15B2A5Dc0fe709a8d097f, "0x01", 1, -1, [1,2,3], [[1],[2]]]
    struct Todo {
        string text;
        bool completed;
        address player;
        bytes1 bt1;
        uint unsigned;
        int signed;
        uint[] arr;
        int[][2] uarr55;
    }

    Todo[] todo;

    function setTodo(Todo memory item) public {
        todo.push(item);
    }

    function getTodo() public view returns (Todo[] memory) {
        return todo;
    }

    //yul
    //asb(666) --> 666
    uint b = 1;
    function asb(uint x) public view returns (uint r) {
        assembly {
            // We ignore the storage slot offset, we know it is zero
            // in this special case.
            r := mul(x, sload(b.slot))
        }
    }
}