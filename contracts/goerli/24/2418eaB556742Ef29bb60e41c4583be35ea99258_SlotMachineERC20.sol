/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: MIT
// V13. Developed from v12. Fix bug in withdraw. Add in Account Balance Checking

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract SlotMachineERC20 {

    address owner;
    IERC20 public token;
    uint winChance = 45; // 45% win chance

    mapping(address => uint) balances; // combined balance of players and owner
    event FundsAdded(address indexed account, uint amount);

    constructor() {
        owner = msg.sender;
        token = IERC20(0xAB4147786d757aA235b4E8b18cdaed9B2CeaF624);   
    }

    // Add funds to the contract
    function addERC20(uint amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        balances[msg.sender] += amount;
        emit FundsAdded(msg.sender, amount);
    }

    // Play the slot machine
    function play(uint bidAmount) external {
        require(bidAmount > 0, "Bid amount must be greater than zero");
        require(balances[msg.sender] >= bidAmount, "Insufficient balance");

        // Generate a random number between 1 and 100
        uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100 + 1;

        // Determine if the player wins or loses
        if (randomNumber <= winChance) {
            balances[msg.sender] += bidAmount;
            balances[owner] -= bidAmount;
             emit BidSuccess(msg.sender, "You Win", bidAmount, balances[msg.sender]);
                     } 
        else {
            balances[msg.sender] -= bidAmount;
            balances[owner] += bidAmount;
            emit BidFailed(msg.sender, "You Lose", bidAmount, balances[msg.sender]);
        }
    }

    // Withdraw funds from the contract
    function withdraw() external {
        require(balances[msg.sender] > 0, "Insufficient balance");
        require(token.transfer(msg.sender, balances[msg.sender]), "Token transfer failed");
        balances[msg.sender] = 0;
    }

    function acctBalance(address useraddress ) public view returns (uint256) {
        require(balances[useraddress] > 0, "Error.  Insufficient balance or account not exist.");
        return balances[useraddress];
    }


    event BidSuccess(address indexed bidder, string result, uint256 winAmount, uint256 balances);
    event BidFailed (address indexed bidder, string result, uint256 amount, uint256 balances);

}