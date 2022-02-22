/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

pragma solidity ^0.8.7;

contract Dervied {

    struct AA {
        uint[] a;
        uint b;
    }

    mapping(address => AA) public aa;

    function add() external {
        aa[msg.sender].a.push(0x01);
        aa[msg.sender].b = 0x02;
    }

    function get() view public returns(AA memory) {
        return aa[msg.sender];
    }

    function getA() view public returns(uint[] memory) {
        return aa[msg.sender].a;
    }

}