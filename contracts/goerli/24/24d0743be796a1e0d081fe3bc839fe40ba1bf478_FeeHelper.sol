// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED
// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.

pragma solidity 0.8.3;

import "./Ownable.sol";

interface IFeeHelper {
    function getFee() view external returns(uint256);
    
    function getFeeDenominator() view external returns(uint256);
    
    function setFee(uint _fee) external;
    
    function getFeeAddress() view external returns(address);
    
    function setFeeAddress(address payable _feeAddress) external;
}

contract FeeHelper is Ownable{
    
    struct Settings {
        uint256 FEE; 
        uint256 DENOMINATOR;
        address payable FEE_ADDRESS;
    }
    
    Settings public SETTINGS;
    
    constructor() {
        SETTINGS.FEE = 100;
        SETTINGS.DENOMINATOR = 10000;
        SETTINGS.FEE_ADDRESS = payable(msg.sender);
    }
    
    function getFee() view external returns(uint256) {
        return SETTINGS.FEE;
    }

    function getFeeDenominator() view external returns(uint256) {
        return SETTINGS.DENOMINATOR;
    }
    
    function setFee(uint _fee) external onlyOwner {
        SETTINGS.FEE = _fee;
    }
    
    function getFeeAddress() view external returns(address) {
        return SETTINGS.FEE_ADDRESS;
    }
    
    function setFeeAddress(address payable _feeAddress) external onlyOwner {
        SETTINGS.FEE_ADDRESS = _feeAddress;
    }
}