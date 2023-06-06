/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.18;

/// @title NatSpec test contract
/// @author Slavaa00
/// @notice You can use this contract for only the most basic simulation
/// @dev All function calls are currently implemented without side effects
/// @custom:experimental This is an experimental contract.


contract Natspec {
    /**
    @notice
    Mints ERC-721's that represent project ownership and transfers. View
  */
    uint256 public a;
    /**
    @notice
    Distributes payouts for a project with the distribution limit of its current funding cycle.

    @dev
    Payouts are sent to the preprogrammed splits. Any leftover is sent to the project's owner. Anyone can distribute payouts on a project's behalf. The project can preconfigure a wildcard split that is used to send funds to msg.sender. This can be used to incentivize calling this function. All funds distributed outside of this contract or any feeless terminals incure the protocol fee.

    @param rings The ID of the project having its payouts distributed.
    

    @return netLeftoverDistributionAmount The amount that was sent to the project owner, as a fixed point number with the same amount of decimals as this terminal.
  */
    function age(uint256 rings) external returns (uint256) {
        return a + rings;
    }
}