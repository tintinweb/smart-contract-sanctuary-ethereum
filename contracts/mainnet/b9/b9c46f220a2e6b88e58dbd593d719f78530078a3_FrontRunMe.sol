/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.10;

contract FrontRunMe {
    event success();
    event fail();

    bytes32 public secretHash;

    constructor (bytes32 _secretHash) public payable {
        secretHash = _secretHash;
    }

    function take(string calldata _secret) external {
        if(keccak256(abi.encodePacked(_secret)) == secretHash) {
            uint256 _myBalance = address(this).balance;
            msg.sender.transfer(_myBalance);
            emit success();
        } else {
            emit fail();
        }
    }
}