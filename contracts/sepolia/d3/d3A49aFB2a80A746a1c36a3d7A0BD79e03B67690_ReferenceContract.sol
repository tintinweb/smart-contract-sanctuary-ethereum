// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

abstract contract ArrayStorage {
    uint256[] private array;

    function collide() external virtual;

    function getArray() external view returns (uint256[] memory) {
        return array;
    }
}

contract ReferenceContract {
    uint256[] private arr;
    function changeArr() public {
        arr = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
    }    
}

contract StorageCollider is ArrayStorage {
    address public referenceContractAddress;

    constructor(address _referenceAddress) {
        referenceContractAddress = _referenceAddress;
    }

    function collide() external override {
        (bool success, ) = referenceContractAddress.delegatecall(abi.encodeWithSignature("changeArr()"));
        require(success, "Delegate call failed!");
    }
}