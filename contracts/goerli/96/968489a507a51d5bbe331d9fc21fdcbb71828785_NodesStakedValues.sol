// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/******************************************************************************\
* @author The Elixir Team
* @title Validator list placeholder for the Elixir AMM Protocol
/******************************************************************************/

contract NodesStakedValues {
    event LogValidatorNode(address user, bool state);
    event LogStrategyNode(address user, bool state);

    // a table of validators
    mapping(address => bool) public validatorNodeStakedEnough;
    mapping(address => bool) public strategyNodeStakedEnough;

    /**
     * @dev Setter function that acts as a placeholder to actuate values inside this smart-contract.
     * Changes in the amount staked will need to instantly change the values of theses mappings accordingly
     * (placeholder)
     * @param user the address of the Validator Node's address
     * @param state a boolean describing whether the user has staked enough in Elixir or not
     */
    function setStateValidatorNode(address user, bool state) public {
        validatorNodeStakedEnough[user] = state;
        emit LogValidatorNode(user, state);
    }

    /**
     * @dev Setter function that acts as a placeholder to actuate values inside this smart-contract.
     * Changes in the amount staked will need to instantly change the values of theses mappings accordingly
     * (placeholder)
     * @param user the address of the Strategy Node's address
     * @param state a boolean describing whether the user has staked enough in Elixir or not
     */
    function setStateStrategyNode(address user, bool state) public {
        strategyNodeStakedEnough[user] = state;
        emit LogStrategyNode(user, state);
    }
}