/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
* @dev Contract that stores the IAS 2021 Batch names
* @author Balaji Shetty Pachai
* @notice Deployed and created the contract on 10/07/2022 at BIPARD, Gaya, Bihar, India
*/
contract IASBIPARD {

    struct IAS {
        address addr;
        string name;
        string batch;
        uint256 rank;
    }

    mapping(address=>bool) public isWhiteListed;
    IAS[] public attendedParticipants;

    address public owner;

    constructor(address[] memory whiteListedAddress) {
        for(uint256 i = 0; i < whiteListedAddress.length; i++) {
            isWhiteListed[whiteListedAddress[i]] = true;
        }
        owner = msg.sender;
    }
    // Accept any incoming amount
    receive () external payable {}

    function addToWhiteList(address[] memory whiteListedAddress) public {
        require(owner == msg.sender, "Only owner can call this");
        for(uint256 i = 0; i < whiteListedAddress.length; i++) {
            isWhiteListed[whiteListedAddress[i]] = true;
        }   
    }

    function enroll(string memory _name, string memory _batch, uint256 _rank) public {
        require(isWhiteListed[msg.sender], "You are not whitelisted");
        attendedParticipants.push(
            IAS({
            addr: msg.sender,
            name: _name,
            batch: _batch,
            rank: _rank
        })
        );
    }
}