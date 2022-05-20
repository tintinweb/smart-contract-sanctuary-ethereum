//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract HireMe {
    event Hire(string email);
    bytes32 public magic;

    constructor(uint160 _magic) {
        magic = keccak256(abi.encodePacked(_magic));
    }
    
    /// @notice To apply to Blockchain Capital's research engineer role, please fill out the google form here: https://forms.gle/MTdV5PZmQB96KE1Y9. 
    /// Applicants that are able to solve the puzzle here by calling the hire() function 
    /// and passing in the SHA256 hash of their email address they used in the above google form as call data will take priority in the application process.
    /// SHA256 hashing tool: https://emn178.github.io/online-tools/sha256.html
    function hire(string calldata emailHash) public allow {
        emit Hire(emailHash);
    }

    modifier allow() {
        require(keccak256(abi.encodePacked((uint160(msg.sender) >> 144))) == magic, "nope :) try again");
        _;
    }

}