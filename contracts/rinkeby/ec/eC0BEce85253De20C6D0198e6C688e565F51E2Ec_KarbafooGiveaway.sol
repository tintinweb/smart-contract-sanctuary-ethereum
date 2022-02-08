// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.6;

contract KarbafooGiveaway {
    string public lastWinner = '';
    string[] public lastList;
    function g(string[] memory candidates_) public returns (string memory){
        uint winner = uint(keccak256(abi.encodePacked(block.difficulty, block.number, tx.gasprice, block.timestamp))) % candidates_.length;
    
        lastList = candidates_;
        lastWinner = candidates_[winner];
        return lastWinner;
    }

    function getLastList() public view returns (string[] memory){
        return lastList;
    }
}