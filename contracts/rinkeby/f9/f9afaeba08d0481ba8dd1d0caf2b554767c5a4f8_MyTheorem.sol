//SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.4;

contract MyTheorem {
    string  theorem = "Stress levels are inversely proportional to division of time";
    string  author = "Skandesh";
    uint public date;
    
    function getTheoremDetails() public view returns (string memory, string memory, uint ){
        return (theorem, author, block.timestamp);
    }
}