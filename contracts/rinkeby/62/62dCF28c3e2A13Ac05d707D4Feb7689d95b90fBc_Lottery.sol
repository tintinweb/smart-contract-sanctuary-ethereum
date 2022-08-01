/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Lottery {

    uint256 public Price =  0.001 ether; 
    address public manager;

    address [] public Players;
    mapping (address => uint256) public PlayerBalance;

    uint8 counter;

    address public win;

    constructor () {
        manager = msg.sender;
    }


    function Purchase () public payable {
        require(msg.value == Price, "Lottery Price is 0.001 ethers");
        require(PlayerBalance[msg.sender] <= 3, "You have purchaed max lottries");
        Players.push(msg.sender);
        PlayerBalance[msg.sender] += 1;
    }

    function Winner () public {
        if(msg.sender == manager){
            (bool Success, ) = win.call{value: address(this).balance}("");
            require(Success, "Failed");

            for(uint256 i = 0 ; i<Players.length ; i++){
                address player = Players[i];
                PlayerBalance[player] = 0;
            }
            Players = new address [] (0);
        }
        else {
            revert("You are not the manager");
        }
    }

    function random() public view returns(uint256){
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, Players.length)));
    }

    function generatewinner () public returns (address){
        uint256 r = random();
        uint256 index = r % Players.length;
        win = Players[index];
        return win;
    }


}