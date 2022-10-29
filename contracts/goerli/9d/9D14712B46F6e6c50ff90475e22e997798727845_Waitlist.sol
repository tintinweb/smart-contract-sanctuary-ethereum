// SPDX-License-Identifier: MIT

// Pragma
pragma solidity ^0.8.7;

// Imports

// Error codes

// Interfaces, Libraries, Contracts
// NatSpec
/**@title A waitlist form contract
 * @author Mike Padial
 * @notice This contract is for creating a waitlist contract
 * @dev This implements VRF as our library
 */

contract Waitlist {
    // Type Declarations
    struct List {
        /* Struct creates a new type called List */
        string title;
        uint256 maxParticipants;
        uint256 createDate;
        uint256 endDate; //save date as unix timestamp or use a string
    }

    // State Variables
    List[] public lists; /* Creates a List array called lists */
    address private immutable i_owner;

    // Functions

    constructor() {
        i_owner = msg.sender;
    }

    // Modifiers

    //    modifier onlyOwner { // Modifier allows function declaration
    //         // require(msg.sender == i_owner, "Sender is not owner!"); - Uses more gas than line below
    //         if(msg.sender != i_owner) { revert NotOwner(); }
    //         _; // Loads rest of the code, this can be before or after modifier code
    //     }

    function storeWaitlist(
        /* stores in lists array */
        // wallet address of contract deployer
        string memory _title,
        uint256 _maxParticipants,
        uint256 _createDate,
        uint256 _endDate
    ) public {
        // wallet address of participant
        lists.push(List(_title, _maxParticipants, _createDate, _endDate));
    }

    /* retrieve from lists array 
    Find a list in array index
    retrieve data from lists */
    function retrieveWaitlist(uint256 _index)
        public
        view
        returns (List memory)
    {
        return lists[_index];
    }

    function test() public pure returns (uint256) {
        return 0;
    }
}