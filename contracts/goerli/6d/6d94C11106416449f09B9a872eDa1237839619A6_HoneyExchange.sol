// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract HoneyExchange {
    // Declare HoneyToken contract variable
    IERC20 private honeyToken;
    
    // Declare exchange rates for each option in wei
    uint256 public honeyPotPrice = 7500000000000000;
    uint256 public honeyJarPrice = 15000000000000000;
    uint256 public honeyStashPrice = 30000000000000000;
    
    // Declare exchange rate for HNY tokens in wei
    uint256 public exchangeRate = 150000000000000;
    
    // Set owner address
    address private owner;

    // Modifier to check that caller is owner
    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
    
    // Constructor function
    constructor(address honeyTokenAddress) {
        honeyToken = IERC20(honeyTokenAddress);
        owner = msg.sender;
    }
    
    // Buy Honey Pot option
    function buyHoneyPot() payable public {
        require(msg.value == honeyPotPrice, "Incorrect amount of ether sent");
        uint256 tokenAmount = honeyPotPrice * exchangeRate / 10**18;
        require(tokenAmount <= honeyToken.balanceOf(address(this)), "Contract does not have enough tokens");
        honeyToken.transfer(msg.sender, tokenAmount);
    }
    
    // Buy Honey Jar option
    function buyHoneyJar() payable public {
        require(msg.value == honeyJarPrice, "Incorrect amount of ether sent");
        uint256 tokenAmount = honeyJarPrice * exchangeRate / 10**18;
        require(tokenAmount <= honeyToken.balanceOf(address(this)), "Contract does not have enough tokens");
        honeyToken.transfer(msg.sender, tokenAmount);
    }
    
    // Buy Honey Stash option
    function buyHoneyStash() payable public {
        require(msg.value == honeyStashPrice, "Incorrect amount of ether sent");
        uint256 tokenAmount = honeyStashPrice * exchangeRate / 10**18;
        require(tokenAmount <= honeyToken.balanceOf(address(this)), "Contract does not have enough tokens");
        honeyToken.transfer(msg.sender, tokenAmount);
    }
    
    // Owner-only function to update exchange rates
    function setExchangeRate(uint256 newRate) public onlyOwner {
        exchangeRate = newRate;
    }
    
    // Owner-only function to update option prices
    function setOptionPrices(uint256 newPotPrice, uint256 newJarPrice, uint256 newStashPrice) public onlyOwner {
        honeyPotPrice = newPotPrice;
        honeyJarPrice = newJarPrice;
        honeyStashPrice = newStashPrice;
    }
    
    // Owner-only function to withdraw ether from contract
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}