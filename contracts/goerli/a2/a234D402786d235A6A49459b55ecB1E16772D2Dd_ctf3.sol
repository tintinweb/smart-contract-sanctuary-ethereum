// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
//import "hardhat/console.sol";

interface ICTF {
    function challengeFourSolved(address winner) external;
}

contract rescueMe {
    address public owner;
    address public ctfAddress;

    constructor(address _owner) payable {
        owner = _owner;
        ctfAddress = msg.sender;
    }

    function withdrawFunds(address goodGuy) public {
        require(tx.origin == owner, "Must be the owner to withdraw funds!");

        (bool success, ) = ctfAddress.call{value: address(this).balance}(
            abi.encodeWithSignature("claimWinnings(address)", goodGuy)
        );
        require(success, "Call failed!");
    }
}


contract ctf3 {
    address public owner;
    ICTF public ctfCoin;

    mapping(address => address) public activeGames;

    modifier isOwner() {
        require(msg.sender == owner, "Only the owner can call this!");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setCtfCoin(address _ctfCoin) isOwner external {
        ctfCoin = ICTF(_ctfCoin);
    }

    function startGame() payable public returns (address game) {
        require(msg.value == .1 ether, "Starting a game requires 1 ether!");
        game = address(new rescueMe{value: msg.value}(0x8f92dcb1426f922dEcAcc0d46e9818dE8D0B9C72));
        activeGames[tx.origin] = game;
    }

    function claimWinnings(address goodGuy) public payable {
        require(address(ctfCoin) != address(0), "Contract not initialized!");
        require(activeGames[goodGuy] == msg.sender, "Must be called from the game contract!");

        ctfCoin.challengeFourSolved(goodGuy);

        (bool success, ) = goodGuy.call{value: address(this).balance}("");
        require(success, "y");
    }

    function withdrawAll() public isOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }
}