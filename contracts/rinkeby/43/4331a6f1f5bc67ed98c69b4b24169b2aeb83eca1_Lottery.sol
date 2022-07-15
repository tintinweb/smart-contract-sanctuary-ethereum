/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

pragma solidity >=0.7.3;

contract Lottery {
    address public manager;
    address[] public players;
 
    function initialize() public{
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value > .01 ether);

        players.push((msg.sender));
    }

    function random() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players)));
    }

    function pickWinner() public restricted {
        uint index = random() % players.length;
        payable(players[index]).transfer(address(this).balance);
        players = new address payable [](0);
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }    
}