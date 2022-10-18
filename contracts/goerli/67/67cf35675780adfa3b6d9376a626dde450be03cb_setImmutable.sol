/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract setImmutable{
    address reserved;
    uint256 public number;
    address public immutable addressI;
    address public immutable addressL;

    constructor(address _stakingContract) public {
        addressI = _stakingContract;
        addressL = _stakingContract;
    }
     /**
     * @dev upgrades the implementation of the proxy
     *
     * requirements:
     *
     * - the caller must be the admin of the contract
     */
    function setNumber(uint256 _number) public {
        number = _number * 112;
    }

     function decimals() public view returns (uint256) {
        return number;
    }

     function getAddressI() public view returns (address) {
        return addressI;
    }

     function getAddressL() public view returns (address) {
        return addressL;
    }
}