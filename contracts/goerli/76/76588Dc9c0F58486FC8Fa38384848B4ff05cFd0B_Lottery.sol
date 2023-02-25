// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Lottery {
    //instantiate variables
    address public manager;
    address payable[] public players;

    constructor() {
        manager = msg.sender;
    }

    //set the manager to the person who creates the contract
    function lottery() public {
        manager = msg.sender;
    }

    //enter into the lottery
    function enter() public payable {
        //0.01 ETH to enter into the lottery
        require(msg.value > 0.01 ether);
        //add the person who sent ETH onto the players array
        players.push(payable(msg.sender));
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, players)
                )
            );
    }

    function pickWinner() public restricted {
        uint256 index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address payable[](0);
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
}