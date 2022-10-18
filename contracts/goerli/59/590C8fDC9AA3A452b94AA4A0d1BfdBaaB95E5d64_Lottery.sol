// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

contract Lottery {
    address public owner;
    address payable[] public players;
    mapping(address => bool) public entry;
    address public lastWinner;

    constructor() {
        owner = msg.sender;
    }

    function enterLottery() public payable {
        require(msg.value >= 1000000000000000, "Entry price should be 0.01 exactly.");
        // require(entry[msg.sender] == false, "You can enter only once");
        entry[msg.sender] = true;
        players.push(payable(msg.sender));
        isActive();
    }
    //5000000000000000000

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function random() internal view returns (uint256) {
        return(uint256(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players))));
    }

    function isActive() internal {
        if(players.length == 2){
            resetEntry(false);
            uint256 index= random() % players.length;
            players[index].transfer(address(this).balance);
            lastWinner = players[index];
            players= new address payable[](0);
        }
    }

    function resetEntry(bool _false) internal {
        for (uint i=0; i< players.length; i++){
            entry[players[i]] = _false;
        }
    }
}