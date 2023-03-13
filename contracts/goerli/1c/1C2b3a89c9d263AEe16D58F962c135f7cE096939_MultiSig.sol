/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
contract MultiSig {
    address payable public wallet1;
    address payable public wallet2;
    address payable public wallet3;
    uint public constant MIN_SIGNATURES = 2;
    uint public contractBalance;
    mapping(address => bool) public isOwner;
    uint public signaturesCount;
    bool public gameEnded;
    constructor(address payable _wallet1, address payable _wallet2, address payable _wallet3) {
        wallet1 = _wallet1;
        wallet2 = _wallet2;
        wallet3 = _wallet3;
        isOwner[_wallet1] = true;
        isOwner[_wallet2] = true;
    }
    function deposit() public payable {
        require(msg.sender == wallet1 || msg.sender == wallet2, "Only wallet1 and wallet2 can deposit.");
        require(msg.value > 0, "Deposit amount must be greater than 0.");
        contractBalance += msg.value;
        wallet3.transfer(msg.value);
    }
    function endGame() public {
        require(isOwner[msg.sender], "Unauthorized user.");
        gameEnded = true;
    }
    function withdraw(address payable winner) public {
        require(isOwner[msg.sender], "Unauthorized user.");
        require(gameEnded, "Game has not ended yet.");
        require(winner == wallet1 || winner == wallet2, "Invalid winner address.");
        signaturesCount++;
        if (signaturesCount >= MIN_SIGNATURES) {
            uint amount = contractBalance;
            contractBalance = 0;
            signaturesCount = 0;
            winner.transfer(amount);
            gameEnded = false;
        }
    }
    function getBalance() public view returns (uint) {
        return contractBalance;
    }
    function isContractActive() public view returns (bool) {
        return (signaturesCount < MIN_SIGNATURES) && !gameEnded;
    }
}