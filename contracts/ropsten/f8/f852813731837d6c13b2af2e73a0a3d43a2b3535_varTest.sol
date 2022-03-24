/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

pragma solidity ^0.4.24;

contract varTest {
    address public var1;
    uint256 public var2;
    bool public var3;
    bool private var4;
    mapping (address => uint256) public var5;
    uint256[] public var6;
    string public var7;
    struct struct1 {
        uint256 svar1;
        address svar2;
        uint8 svar3;
    }
    struct1 public var8;

    function varTest() {
        var1 = address(this);
        var2 = 0x233;
        var3 = true;
        var4 = false;
        var5[address(0x5678)] = 0x666;
        var6.push(0x7777);
        var7 = "hhhh";
        var8.svar1 = 0x1234;
        var8.svar2 = address(0x4321);
        var8.svar3 = 8;
    }

    function setVar1(address _v) public {
        var1 = _v;
    }
    function setVar2(uint _v) public {
        var2 = _v;
    }
    function setVar3(bool _v) public {
        var3 = _v;
    }
    function setVar4(bool _v) public {
        var4 = _v;
    }
    function setVar5(address _k, uint _v) public {
        var5[_k] = _v;
    }
    function setVar6(uint _v) public {
        var6.push(_v);
    }
    function setVar7(string _v) public {
        var7 = _v;
    }
    function setVar8(uint _v1, address _v2, uint8 _v3) public {
        var8.svar1 = _v1;
        var8.svar2 = _v2;
        var8.svar3 = _v3;
    }
}