/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/**
 * @title ABakery
 * @dev Purchase freshly baked Pastrys
 * @custom:dev-run-script ./scripts/deploy_a_bakery.ts
 */
contract ABakery {

    // Declare constants
    uint public constant PASTRY_PRICE = 10000 gwei;
    uint public constant NUMBER_OF_FLAVORS = 64;
    string public constant ABI_ADDRESS = "https://github.com/ensockerbagare/aBakery";

    // Declare state variables of the contract
    address internal owner;
    mapping (address => string) internal oven;
    string[NUMBER_OF_FLAVORS] internal flavors;
    string internal pastry_of_the_day;

    /**
     * @dev Create a new bakery
     */
    constructor() {
        owner = msg.sender;
    }

    // Check if given flavor is supported
    function _flavorExists(string calldata _flavor) private view returns(bool) {
        for (uint i = 0; i < flavors.length; i++) {
            // Solidity has no string compare, so test hash value (and pay a bit extra gas) 
            if (keccak256(abi.encodePacked(flavors[i])) == keccak256(abi.encodePacked(_flavor))) {
                return true;
            }
        }
        return false;
    }

    // Check if sender has an ordered Pastry in the oven
    function _isPastryInOven() private view returns (bool) {
        if(bytes(oven[msg.sender]).length > 0) {
            return true;
        } 
        return false;
    }

    /**
     * @dev Add a new flavor. Only the owner can add new pastry flavors
     * @param index The index to set flavor to
     * @param flavor The flavor to add
     */
    function addFlavor(uint index, string calldata flavor) public {
        require(msg.sender == owner, "Only the owner can add a new pastry flavor.");
        require(index < NUMBER_OF_FLAVORS, "To many flavors for the baker to handle.");
        flavors[index] = flavor;
    }

    /**
     * @dev Set the pastry of the day
     * @param pastry The pastry of the day
     */
    function setPastry(string calldata pastry) public {
        require(msg.sender == owner, "Only the owner can set the pastry of the day.");
        pastry_of_the_day = pastry;
    }

    /**
     * @dev Pickup any ordered pastry. This function is not executable via the etherscan contract viewer be must be called via the ABI.
     * @return The ordered pastry in the flavor of choice
     */
    function pickupOrderedPastry() public view returns (string memory) {
        require(_isPastryInOven(), "You haven't ordered any pastry (yet).");
        // A view function can not change state so that the customer can receive 
        // the ordered pastry indefinitely
        return oven[msg.sender];
    }

    /**
     * @dev Order a Pastry. The customer has send some gwei for this translation
     * @param flavor The flavor of choice
     */
    function orderPastry(string calldata flavor) public payable {
        require(_flavorExists(flavor), "Sorry, we don't have that flavor.");
        require(msg.value == PASTRY_PRICE, "A pastry cost 10000 gwei GoerliETH.");
        // Add the pastry into the oven using the customer's public address as the key
        oven[msg.sender] = string.concat(flavor, pastry_of_the_day);
    }
}