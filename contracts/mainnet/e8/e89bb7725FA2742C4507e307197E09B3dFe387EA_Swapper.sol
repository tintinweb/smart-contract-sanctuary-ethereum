/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Swapper {
    IERC20 USDC;
    bool swapIsActive;
    address owner;
    address deployer;
    uint256 exchangeRate;
    uint256 precision;
    uint256 minBuy;
    uint256 maxBuy;
    uint256 privateSaleTotal;
    uint256 totalSold;
    event SwapEvent(uint256 USDC_Amount, uint256 SUCG_Amount, address Caller_Address);

    constructor(address _usdcAddress) {
        USDC = IERC20(_usdcAddress);
        swapIsActive = true;
        owner = msg.sender;
        precision = 18; // decimals
        exchangeRate = 250000000000000000; // $0.25
        minBuy = 10000 * 10**precision; // $10k
        maxBuy = 1000000 * 10**precision; // $1m
        privateSaleTotal = 3880000 * 10**precision; // 4m tokens total (140k already distributed)
        deployer = 0x1030669B39de34D9785E38eA2714AD5A19b26407;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can access this function.");
        _;
    }

    modifier swapActive() {
        require(swapIsActive, "Swap is not active.");
        _;
    }

    modifier validSwap(uint256 _usdcAmount) {
        require(_usdcAmount >= minBuy && _usdcAmount <= maxBuy, "Minimum swap is $10k, maximum swap is $2m.");
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner public {
        owner = _newOwner;
    }

    function changeDeployer(address _newDeployer) onlyOwner public {
        deployer = _newDeployer;
    }

    function changeExchangeRate(uint256 _newExchangeRate) onlyOwner public {
        exchangeRate = _newExchangeRate;
    }

    function changeMinBuy(uint256 _newMinBuy) onlyOwner public {
        minBuy = _newMinBuy;
    }

    function changeMaxBuy(uint256 _newMaxBuy) onlyOwner public {
        maxBuy = _newMaxBuy;
    }

    function changePrivateSaleTotal(uint256 _newPrivateSaleTotal) onlyOwner public {
        privateSaleTotal = _newPrivateSaleTotal;
    }

    function toggleSwapActive() onlyOwner public returns (bool active) {
        swapIsActive = !swapIsActive;
        return swapIsActive;
    }

    function swap(uint256 _usdcAmount) swapActive validSwap(_usdcAmount)  public returns (bool success) {
        uint256 sucgSent = usdcToSUCGEstimate(_usdcAmount);
        require(sucgSent <= getRemainingInPrivateSale(), "Cannot buy more than allowed from the private sale.");
        totalSold += sucgSent;
        USDC.transferFrom(msg.sender, deployer, _usdcAmount);
        emit SwapEvent(_usdcAmount, sucgSent, msg.sender);
        return true;
    }

    // VIEWS
    function isSwapActive() public view returns (bool active) {
        return swapIsActive;
    }

    function usdcToSUCGEstimate(uint256 _usdcAmount) public view returns (uint256) {
        return ((_usdcAmount * 10**precision) / exchangeRate);
    }

    function getRemainingInPrivateSale() public view returns (uint256) {
        return privateSaleTotal - totalSold;
    }

    function getTotalInPrivateSale() public view returns (uint256) {
        return privateSaleTotal;
    }

    function getTotalSold() public view returns (uint256) {
        return totalSold;
    }
}

contract IERC20 {
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}
}