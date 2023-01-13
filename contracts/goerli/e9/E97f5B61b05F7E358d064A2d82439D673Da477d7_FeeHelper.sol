// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.

pragma solidity 0.8.17;

import "./Ownable.sol";

contract FeeHelper is Ownable{
    
    struct Settings {
        uint256 GENERATOR_FEE;
        uint256 FEE; 
        uint256 DENOMINATOR;
        address payable FEE_ADDRESS;
    }
    
    Settings public SETTINGS;
    
    constructor() {
        SETTINGS.GENERATOR_FEE = 0;
        SETTINGS.FEE = 100;
        SETTINGS.DENOMINATOR = 10000;
        SETTINGS.FEE_ADDRESS = payable(msg.sender);
    }

    function getGeneratorFee() external view returns(uint256) {
        return SETTINGS.GENERATOR_FEE;
    }
    
    function getFee() external view returns(uint256) {
        return SETTINGS.FEE;
    }

    function getFeeDenominator() external view returns(uint256) {
        return SETTINGS.DENOMINATOR;
    }

    function setGeneratorFee(uint256 _fee) external onlyOwner {
        SETTINGS.GENERATOR_FEE = _fee;
    }
    
    function setFee(uint _fee) external onlyOwner {
        SETTINGS.FEE = _fee;
    }
    
    function getFeeAddress() external view returns(address) {
        return SETTINGS.FEE_ADDRESS;
    }
    
    function setFeeAddress(address payable _feeAddress) external onlyOwner {
        SETTINGS.FEE_ADDRESS = _feeAddress;
    }
}