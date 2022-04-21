/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

pragma solidity ^0.8.13;
// SPDX-License-Identifier: MIT

contract OriginStampContract {

    address private owner;

    event Submitted(bytes32 indexed pHash);

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
	    owner = msg.sender;
	    emit OwnerSet(address(0), owner);
    }

    function submitHash(bytes32 pHash) public isOwner() {
        emit Submitted(pHash);
    }

    function getOwner() external view returns (address) {
            return owner;
    }
}