// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract Hodl {
    struct Bank {
        address payable owner;
        mapping(address => uint256) balance; // ERC20 mapping
        uint256 etherBalance; // ether balance
        uint256 unlockDate;
        uint256 createdAt;
    }
    mapping(address => Bank) bank;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function createBank(uint256 unlockDate) public payable returns (bool) {
        address myBankAddress = bank[msg.sender].owner;

        if (myBankAddress != address(0)) {
            return true;
        }

        // Store ether
        bank[msg.sender].owner = payable(msg.sender);
        bank[msg.sender].etherBalance = msg.value;
        bank[msg.sender].createdAt = block.timestamp;
        bank[msg.sender].unlockDate = unlockDate;

        // Emit event.
        emit CreateBank(msg.sender, block.timestamp, unlockDate, msg.value);

        return true;
    }

    function deposit() public payable {
        require(
            bank[msg.sender].owner != address(0),
            "HODL: Bank is not exist"
        );

        bank[msg.sender].etherBalance += msg.value;

        emit Received(msg.sender, msg.value);
    }

    function withdraw() public returns (uint256) {
        require(
            bank[msg.sender].owner != address(0),
            "HODL: Bank is not exist"
        );
        require(
            bank[msg.sender].etherBalance <= address(this).balance,
            "HODL: Ether balance is not enought"
        );

        Bank storage myBank = bank[msg.sender];
        uint256 tokenBalance = myBank.etherBalance;

        myBank.owner.transfer(tokenBalance);
        myBank.etherBalance = 0;

        emit Withdrew(msg.sender, tokenBalance);

        return tokenBalance;
    }

    function depositTokens(address tokenContract, uint256 amount) public {
        require(
            bank[msg.sender].owner != address(0),
            "HODL: Bank is not exist"
        );

        Bank storage myBank = bank[msg.sender];
        IERC20 token = IERC20(tokenContract);

        token.transferFrom(msg.sender, address(this), amount);
        myBank.balance[tokenContract] += amount;

        emit DepositTokens(tokenContract, msg.sender, amount);
    }

    function withdrawTokens(address tokenContract) public returns (uint256) {
        require(
            bank[msg.sender].owner != address(0),
            "HODL: Bank is not exist"
        );
        require(
            bank[msg.sender].etherBalance <= address(this).balance,
            "HODL: balance is not enought"
        );

        Bank storage myBank = bank[msg.sender];
        uint256 tokenBalance = myBank.balance[tokenContract];
        IERC20 token = IERC20(tokenContract);

        token.transfer(msg.sender, tokenBalance);
        myBank.balance[tokenContract] = 0;

        emit WithdrewTokens(tokenContract, msg.sender, tokenBalance);

        return tokenBalance;
    }

    function setUnlockDate(uint256 unlockDate) public {
        require(
            bank[msg.sender].owner != address(0),
            "HODL: Bank is not exist"
        );

        Bank storage myBank = bank[msg.sender];

        myBank.unlockDate = unlockDate;

        emit SetUnlockDate(msg.sender, unlockDate);
    }

    function getUnlockDate() public view returns (uint256) {
        require(
            bank[msg.sender].owner != address(0),
            "HODL: Bank is not exist"
        );

        Bank storage myBank = bank[msg.sender];

        return myBank.unlockDate;
    }

    function getBalance(address tokenContract) public view returns (uint256) {
        require(
            bank[msg.sender].owner != address(0),
            "HODL: Bank is not exist"
        );

        Bank storage myBank = bank[msg.sender];

        return myBank.balance[tokenContract];
    }

    fallback() external payable {
        emit Received(msg.sender, msg.value);
    }

    // keep all the ether sent to this address
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    event CreateBank(
        address from,
        uint256 createdAt,
        uint256 unlockDate,
        uint256 amount
    );

    event Received(address from, uint256 amount);
    event DepositTokens(address tokenContract, address from, uint256 amount);
    event Withdrew(address to, uint256 amount);
    event WithdrewTokens(address tokenContract, address to, uint256 amount);
    event SetUnlockDate(address from, uint256 unlockDate);
}