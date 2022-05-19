//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract HireMe {
    event Hire(string who);
    bytes32 public magic;

    constructor(uint160 _magic) {
        magic = keccak256(abi.encodePacked(_magic));
    }
    
    /// @notice Calling this function and passing some contact information string
    /// will put you at the top of the list of candidates for BCAP engineering role. 
    /// Good luck :) 
    function hire(string calldata contactInfo) public allow {
        emit Hire(contactInfo);
    }

    modifier allow() {
        require(keccak256(abi.encodePacked((uint160(msg.sender) >> 144))) == magic, "nope :) try again");
        _;
    }

}