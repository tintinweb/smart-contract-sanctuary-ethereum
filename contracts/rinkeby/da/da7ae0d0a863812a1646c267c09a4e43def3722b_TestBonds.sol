/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

//SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

contract TestBonds{
    uint256 virtualReserves;
    uint256 halfLife;
    uint256 levelBips;
    mapping (address => string) mapToken;

     function modifyQuotePricing(
        address _token,
        uint256 _virtualReserves,
        uint256 _halfLife,
        uint256 _levelBips
    ) external { 
        virtualReserves = _virtualReserves;
        halfLife = _halfLife;
        levelBips = _levelBips;
        mapToken[_token] = "RanMert"; 
    }
    function viewMetrics() public view returns(uint256){
        return virtualReserves;
    }
}