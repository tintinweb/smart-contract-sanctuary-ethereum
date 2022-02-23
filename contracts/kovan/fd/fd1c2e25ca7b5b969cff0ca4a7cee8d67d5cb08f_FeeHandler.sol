// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./IFeeHandler.sol";
contract FeeHandler is IFeeHandler {
    /*
        Marketplace tax, 
        Hunting tax, 
        Buy tax, 
        Sell tax, 
        Damage for legions, 
        Summon fee, 
        14 Days Hunting Supplies Discounted Fee,
        28 Days Hunting Supplies Discounted Fee
    */
    uint[8] fees = [1500,250,200,800,100,20,12,16]; 
    address legion;
    modifier onlyLegion() {
        require(msg.sender == legion); _;
    }
    constructor() {
        legion = msg.sender;
    }
    function getFee(uint8 _index) external view override returns(uint) {
        return fees[_index];
    }
    function setFee(uint _fee, uint8 _index) external override onlyLegion {
        require(_index>=0 && _index<8, "Unknown fee type");
        fees[_index] = _fee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

interface IFeeHandler {
    function getFee(uint8 _index) external view returns(uint);
    function setFee(uint _fee, uint8 _index) external;
}