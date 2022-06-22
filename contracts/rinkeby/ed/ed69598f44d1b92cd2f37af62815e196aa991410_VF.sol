/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract VF {
    address vesting;
    address owner;

    constructor(address _v) {
        vesting = _v;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function setVestingContract(address _v) external onlyOwner {
        vesting = _v;
    }

    function transferOwnerShip(address _o) external onlyOwner {
        owner = _o;
    }

    function claimAndRevoke(address[] memory _arr) external onlyOwner {
        for (uint i; i < _arr.length;) {
            (bool success,) = vesting.call(abi.encodeWithSignature("claim(address)", _arr[i]));
            (bool success2,) = vesting.call(abi.encodeWithSignature("revoke(address)", _arr[i]));
            require(success && success2);
            unchecked {
                ++i;
            }
        }
    }

    function transferVestingOwnerShip(address _o) external onlyOwner {
        (bool success,) = vesting.call(abi.encodeWithSignature("transferOwnership(address)", _o));
        require(success);
    }
}