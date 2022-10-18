// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bytes{

    constructor() {}

    function addAdming(address admin) public pure returns(bytes memory){

        bytes memory txid= (abi.encodeWithSignature("addAdmin(address)", admin));
        return txid;

    }
    function removeAdming(address admin) public pure returns(bytes memory){

        bytes memory txid= (abi.encodeWithSignature("removeAdmin(address)", admin));
        return txid;

    }
    function transferOwnership(address owner) public pure returns(bytes memory){

        bytes memory txid= (abi.encodeWithSignature("transferOwnership(address)", owner));
        return txid;

    }

    function renounceOwnership() public pure returns(bytes memory){

        bytes memory txid= (abi.encodeWithSignature("renounceOwnership()"));
        return txid;

    }
}