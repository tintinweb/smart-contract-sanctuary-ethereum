/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.12;

contract Verify {

    address private owner;
    uint256 private number;

    /**
    * @notice Change owner
    * @dev Only owner can change the address
    * @param newOwner The new owner
    */
    function changeOwner(address newOwner) external {
        require(msg.sender == owner);
        owner = newOwner;
    }

    /**
    * @dev Get current owner
    */
    function currentOwner() external view returns (address) {
        return owner;
    }

    function setNumber(uint256 newNumber) external {
        require(msg.sender == owner);
        number = newNumber;
    }

}