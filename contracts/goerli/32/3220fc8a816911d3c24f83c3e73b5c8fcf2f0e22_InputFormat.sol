/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

pragma solidity ^0.8.0;

contract InputFormat {
    string public str;
    address public addr;
    bytes32 public b32;

    function stringIn(string memory _str) external {
        str = _str;
    }

    function addressIn(address _addr) external {
        addr = _addr;
    }

    function bytes32In(bytes32 _b32) external {
        b32 = _b32;
    }
}