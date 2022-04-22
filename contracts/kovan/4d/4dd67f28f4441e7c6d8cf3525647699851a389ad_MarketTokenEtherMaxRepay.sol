/**
 *Submitted for verification at Etherscan.io on 2022-04-22
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.9.2 https://hardhat.org

// File contracts/market/MarketTokenInterface.sol


pragma solidity ^0.8.0;

interface MarketTokenInterface {
    function isMarketToken() external view returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function underlying() external view returns (address);
    function reserveFactorMantissa() external view returns (uint256);
    function accrualBlockTimestamp() external view returns (uint256);
    function borrowIndex() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function totalReserves() external view returns (uint256);
    function accountTokens(address account) external view returns (uint256);
    function accountBorrows(address account) external view returns (uint256,uint256);
    function protocolSeizeShareMantissa() external view returns (uint256);
    function comptroller() external view returns (address);
    function interestRateModel() external view returns (address);
    function admin() external view returns (address);
    function pendingAdmin() external view returns (address);

    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerSecond() external view returns (uint);
    function supplyRatePerSecond() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);

    function _setPendingAdmin(address payable newPendingAdmin) external  returns (uint);
    function _acceptAdmin() external  returns (uint);
    function _setComptroller(address newComptroller) external returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) external  returns (uint);
    function _reduceReserves(uint reduceAmount) external  returns (uint);
    function _setInterestRateModel(address newInterestRateModel) external  returns (uint);



    
}

interface MarketTokenEtherInterface is MarketTokenInterface{

    function mint() external payable returns (uint);
    function redeem(uint redeemTokens) external payable returns (uint);
    function redeemUnderlying(uint redeemAmount) external payable returns (uint);
    function borrow(uint borrowAmount) external payable returns (uint);
    function repayBorrow() external payable returns (uint);
    function repayBorrowBehalf(address borrower) external payable returns (uint);
    function liquidateBorrow(address borrower, address marketTokenCollateral) external payable returns (uint);

    function _addReserves() external payable returns (uint);

}

interface MarketTokenERC20Interface is MarketTokenInterface{

    function mint(uint mintAmount) external  returns (uint);
    function redeem(uint redeemTokens) external  returns (uint);
    function redeemUnderlying(uint redeemAmount) external  returns (uint);
    function borrow(uint borrowAmount) external  returns (uint);
    function repayBorrow(uint repayAmount) external  returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external  returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, address marketTokenCollateral) external returns (uint);
    function sweepToken(address token) external ;

    function _addReserves(uint addAmount) external returns (uint);

}


// File contracts/market/MarketTokenEtherMaxRepay.sol


pragma solidity ^0.8.0;

contract MarketTokenEtherMaxRepay {

    MarketTokenEtherInterface public etherMarket;

    constructor(MarketTokenEtherInterface _etherMarket)  {
        etherMarket = _etherMarket;
    }

    function repayBehalf(address borrower) public payable {
        repayBehalfExplicit(borrower, etherMarket);
    }

    function repayBehalfExplicit(address borrower, MarketTokenEtherInterface _etherMarket) public payable {
        uint received = msg.value;
        uint borrows = etherMarket.borrowBalanceCurrent(borrower);
        if (received > borrows) {
            _etherMarket.repayBorrowBehalf{value:borrows}(borrower);
            payable(msg.sender).transfer(received - borrows);
        } else {
            _etherMarket.repayBorrowBehalf{value:received}(borrower);
        }
    }  



}