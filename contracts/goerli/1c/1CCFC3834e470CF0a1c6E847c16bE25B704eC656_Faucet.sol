// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.17;

import "github.com/Michealleverton/ownable.sol/blob/main/Ownable.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external view returns (bool);
    function balanceOf(address account) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Faucet is Ownable {
    IERC20 public token;

    uint256 public withdrawlAmount = 50 * (10**18);
    uint256 public lockTime = 1 minutes;

    event Deposit(
        address indexed from,
        uint256 indexed amount
    );

    event WithDrawl(
        address indexed to, 
        uint256 indexed amount
    );

    mapping(address => uint256) nextAccessTime;

    constructor() payable {
        token = IERC20(0x8C7190802Ae13025adE069D2a11Eb9dF2F52A071);
        owner = payable(msg.sender);
    }
 
    function requestTokens() public {
        require(msg.sender != address(0), "Request must not originate from a zero account");
        require(token.balanceOf(address(this)) >= withdrawlAmount, "Insufficient balance in faucet for withdrawl");
        require(block.timestamp >= nextAccessTime[msg.sender], "Insufficient time elapsed since last withdrawl");
        nextAccessTime[msg.sender] = block.timestamp + lockTime;
        token.transfer(msg.sender, withdrawlAmount);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function getBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function SetWithDrawlAmount(uint256 amount) public onlyOwner {
        withdrawlAmount = amount * (10**18);
    }

    function setLockTime(uint256 amount) public onlyOwner {
        lockTime = amount* 1 minutes;
    }

    function withdraw() external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
        emit WithDrawl(msg.sender, token.balanceOf(address(this)));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract Ownable {
    
    // All veriables will be here
    address owner;

    // constructor is run upon contract being deployed and is only run once
    constructor() {
        owner = msg.sender;
    }

    // Modifiers are used to store a specific parameters that will be called
    // multiple times in a contract. Allowing you to only have to write it once.
    modifier onlyOwner() {
        require(msg.sender == owner, "YOU MUST BE THE OWNER TO DO THAT. SORRY!");
        _;
    }
}