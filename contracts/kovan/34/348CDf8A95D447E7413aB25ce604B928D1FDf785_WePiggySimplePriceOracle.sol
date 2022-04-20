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


// File contracts/oracle/PriceOracle.sol


pragma solidity ^0.8.0;

interface PriceOracle {
    /**
      * @notice Get the underlying price of a marketToken asset
      * @param marketToken The marketToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(MarketTokenInterface marketToken) external view returns (uint);
}


// File contracts/oracle/WePiggySimplePriceOracle.sol


pragma solidity ^0.8.0;

contract WePiggySimplePriceOracle is PriceOracle{


    address public owner;
    mapping(address => address[]) public marketSources;


    constructor(){
        owner = msg.sender;
    }

    /**
      * @notice Get the underlying price of a marketToken asset
      * @param marketToken The marketToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(MarketTokenInterface marketToken) external override view returns (uint){

        uint256 price = 0;

        address[] memory sources = marketSources[address(marketToken)];
        for(uint i = 0 ; i < sources.length; i++){
            price = getSourceUnderlyingPrice(sources[i], address(marketToken));
            if(price > 0){
                return price;
            }
        }

        // price must bigger than 0
        require(price > 0, "price must bigger than zero");

        return 0;
    }


    function getSourceUnderlyingPrice(address source,address market) public view returns (uint){
        bytes memory payload = abi.encodeWithSignature("getUnderlyingPrice(address)", market);
        (bool success, bytes memory returndata) = source.staticcall(payload);
        if(success){
            return abi.decode(returndata, (uint));
        }
        return 0;
    }


    function _setOwner(address newOwner) public{
        require(msg.sender == owner,"only owner can call it");
        owner = newOwner;
    }

    function _setSources(address market,address[] memory _sources) public {
        require(msg.sender == owner,"only owner can call it");
        marketSources[market] = _sources;
    }


    function getMarketSources(address market) public view returns(address[] memory){
        return marketSources[market];
    }
 

}