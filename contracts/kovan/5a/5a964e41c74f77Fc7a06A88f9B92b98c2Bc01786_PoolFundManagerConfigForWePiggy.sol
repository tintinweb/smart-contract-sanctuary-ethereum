/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File contracts/misc/isolation/PoolFundManagerInterface.sol


pragma solidity ^0.8.0;

interface PoolFundManagerInterface {

    function mint(address minter, uint amount) external payable;
    function redeem(address redeemer, uint amount) external ;
    function borrow(address borrower, uint amount) external;
    function repayBorrow(address borrower, uint amount) external payable;
    function liquidateBorrow(address borrower, uint amount) external payable;
}

interface PoolFundManagerConfigInterface{
    function minReserveRatio() external returns(uint);
    function maxReserveRatio() external returns(uint);
    function getMarketToken(address underlying) external view returns(address);
    function setMarketToken(address underlying, address market) external;
}


// File contracts/misc/isolation/PoolFundManagerConfigForWePiggy.sol


pragma solidity ^0.8.0;

contract PoolFundManagerConfigForWePiggy is PoolFundManagerConfigInterface {

    address public owner;

    uint256 public minReserveRatio = 10;
    uint256 public maxReserveRatio = 20;
    mapping(address => address) public underlyingMarket;

    event MinReserveRatioUpdated(uint256 indexed minReserveRatio);
    event MaxReserveRatioUpdated(uint256 indexed maxReserveRatio);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }


    /**
     * Update the minimum reservation reatio
     * @param _minReserveRatio the new value of the minimum reservation ratio
     */
    function updateMinReserveRatio(uint256 _minReserveRatio) external onlyOwner {
        if (_minReserveRatio == minReserveRatio)
            return;

        require(_minReserveRatio > 0 && _minReserveRatio < maxReserveRatio,
            "Invalid min reserve ratio.");
        minReserveRatio = _minReserveRatio;

        emit MinReserveRatioUpdated(_minReserveRatio);
    }

    /**
     * Update the maximum reservation reatio
     * @param _maxReserveRatio the new value of the maximum reservation ratio
     */
    function updateMaxReserveRatio(uint256 _maxReserveRatio) external onlyOwner {
        if (_maxReserveRatio == maxReserveRatio)
            return;

        require(_maxReserveRatio > minReserveRatio && _maxReserveRatio < 100,
            "Invalid max reserve ratio.");
        maxReserveRatio = _maxReserveRatio;

        emit MaxReserveRatioUpdated(_maxReserveRatio);
    }

    function getMarketToken(address underlying) external override view returns(address){
        return underlyingMarket[underlying];
    }

    function setMarketToken(address underlying, address market) external override onlyOwner{
        underlyingMarket[underlying] = market;
    }


}