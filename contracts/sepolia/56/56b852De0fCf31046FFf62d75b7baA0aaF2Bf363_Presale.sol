// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AggregatorV3Interface.sol";

contract Presale {
    using SafeERC20 for IERC20;
    
    IERC20 public token;
    IERC20 public USDT = IERC20(0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E);
    AggregatorV3Interface internal priceFeed;

    uint256 public stage;
    mapping(uint => uint256) public rate;
    mapping(address => uint256) public tokensPurchased;

    bool public canClaimTokens = false;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);

        // Set initial stage
        stage = 1;

        // Set rates for each stage
        rate[1] = 1000; // 1 token per 0.001 USDT
        rate[2] = 500;  // 1 token per 0.002 USDT
        rate[3] = 333;  // 1 token per 0.003 USDT
        // ... set rates for remaining stages up to 10
    }

    function buyTokensWithUSDT(uint256 _amount) external {
        require(stage <= 10, "Presale ended");
        uint256 tokens = _amount / rate[stage];
        USDT.safeTransferFrom(msg.sender, address(this), _amount);
        tokensPurchased[msg.sender] += tokens;
    }

    function claimTokens() external {
        require(canClaimTokens, "Tokens are not yet claimable");
        uint256 amount = tokensPurchased[msg.sender];
        require(amount > 0, "No tokens to claim");
        tokensPurchased[msg.sender] = 0;
        token.safeTransfer(msg.sender, amount);
    }

    function setClaimable(bool _canClaimTokens) external {
        canClaimTokens = _canClaimTokens;
    }

    function setStage(uint256 _stage) external {
        require(_stage <= 10, "Invalid stage");
        stage = _stage;
    }

    function setTokenAddress(IERC20 _token) external {
        token = _token;
    }

    function getCurrentWETHPrice() public view returns (int) {
        (
            , 
            int price,
            ,
            ,
        ) = priceFeed.latestRoundData();
        return price;
    }
}