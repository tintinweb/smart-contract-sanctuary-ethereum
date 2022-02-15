/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: Unlicensed

contract Hello{
    //115792089237316195423570985008687907853269984665640564039457584007913129639935
    uint256 public constant MAX = ~uint256(0);

    uint256 public lL = ~uint256(0);
    
    uint256 public _tTotal = 1000000000000000 * 10**9;//1000000000000000000000000
    
    //115792089237316195423570985008687907853269984665640564000000000000000000000000
    uint256 public _rTotal = (MAX - (MAX % _tTotal));
    address public lala = 0x4Af08Dcf38614C475ADc2f97a3998af7C5421a5e;
    address public sec = address(0x4Af08Dcf38614C475ADc2f97a3998af7C5421a5e);

    string s = "fish";
    string public lalas = string(abi.encodePacked("ab"));

    string first=""; string second=""; string third="";

    event DataSet(uint time, address who);

    function setDatas(string memory a, string memory b, string memory c) public {
        first = a;
        second = b;
        third = c;
        emit DataSet(block.timestamp, msg.sender);
    }

    function aConcat() public view returns (string memory){
        return string(abi.encodePacked(first, second, third));
    }
}