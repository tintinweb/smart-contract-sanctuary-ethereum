/**
 *Submitted for verification at Etherscan.io on 2022-10-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
* @dev Contract that stores the BAS 2021 Batch names
* @author Balaji Shetty Pachai
* @notice Deployed and created the contract on 10/08/2022 at BIPARD, Gaya, Bihar, India
*/
contract BAS_BIPARD {

    struct BAS {
        string name;
        string batch;
        uint256 rank;
    }

    BAS[] public attendedParticipants;

    address public owner;

    constructor() {
        owner = msg.sender;
    }
    // Accept any incoming amount
    receive () external payable {}

    function enroll(string memory _name, string memory _batch, uint256 _rank) public {
        require(owner == msg.sender, "Only owner can call this");
        attendedParticipants.push(
            BAS({
            name: _name,
            batch: _batch,
            rank: _rank
        })
        );
    }
}