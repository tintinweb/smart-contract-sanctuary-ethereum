// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

contract Lottery {
    address public manager;
    address payable[] public players;

    constructor() public {
       manager = msg.sender;
    }

    function enter() public payable{
        require(msg.value > 0.01 ether);
        players.push(payable(msg.sender));
    }

    function random() private view returns (uint){
        return uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.number, players)
                )
            );
    }

    function pickWinner() public restricted {
        uint index = random() % players.length;
        address contractAddress = address(this);
        players[index].transfer(contractAddress.balance);
        players = new address payable[](0);
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns(address payable[] memory){
        return players;
    }
 }