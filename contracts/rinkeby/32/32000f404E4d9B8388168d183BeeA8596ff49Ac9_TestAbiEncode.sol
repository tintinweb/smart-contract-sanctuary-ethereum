/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
contract TestAbiEncode {

    function getAbiEncode(address _addr, uint256 _num) public view returns (bytes memory){
        return abi.encode(_addr, _num);
    }

    function getAbiEncodePacked(address _addr, uint256 _num) public view returns (bytes memory){
        return abi.encodePacked(_addr, _num);
    }

}