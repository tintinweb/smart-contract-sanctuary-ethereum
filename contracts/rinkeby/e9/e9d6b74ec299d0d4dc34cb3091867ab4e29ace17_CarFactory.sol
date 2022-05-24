// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title CarFactory
 * @author Jelo
 * @notice This is a contract that handles crucial changes in the car company.
 */
contract CarFactory {

    // -- States --
    address public owner;
    bool public isHacked;

     /**
     * @dev Makes a change to the car factory such as:
     *      Updating the owner of the car company.
    */
    function updateFactory() public {
        owner = msg.sender;
        isHacked = true;
    }
}