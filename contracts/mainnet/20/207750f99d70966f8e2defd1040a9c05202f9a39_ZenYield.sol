/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///////////////////////////////////////
//   ____       __  ___     __   __  //
//  /_  / ___ __\ \/ (_)__ / /__/ /  //
//   / /_/ -_) _ \  / / -_) / _  /   //
//  /___/\__/_//_/_/_/\__/_/\_,_/    //
//               by 0xInuarashi.eth  //
///////////////////////////////////////

abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

interface iZen {
    function mintAsController(address to_, uint256 amount_) external;
}

interface iZenApe {
    function balanceOf(address address_) external view returns (uint256);
}

contract ZenYield is Ownable {
    
    // Interfaces
    iZen public Zen = iZen(0x0fAD2A1F9aB421C1740c0456ec62c155518824aF); 
    function setZen(address address_) external onlyOwner { 
        Zen = iZen(address_); 
    }

    iZenApe public ZenApe = iZenApe(0x838804a3dd7c717396a68F94E736eAf76b911632);
    function setZenApe(address address_) external onlyOwner {
        ZenApe = iZenApe(address_);
    }

    // Times
    uint40 public yieldStartTime = 1651327200; // Apr 30 2022 14:00:00 GMT+0000
    uint40 public yieldEndTime = 1682863200; // Apr 30 2023 14:00:00 GMT+0000
    function setYieldEndTime(uint40 yieldEndTime_) external onlyOwner { 
        yieldEndTime = yieldEndTime_; }

    // Yield Info
    uint256 public globalModulus = 10e14; // Round up 14 Decimals
    uint256 public yieldRatePerToken = 5 ether / globalModulus; // 5 Zen per Day
    struct Yield { uint40 lastUpdateTime; uint216 pendingRewards; }
    mapping(address => Yield) public addressToYield;

    // Events
    event Claim(address to_, uint256 amount_, uint256 time_);
    event CreditsDeducted(address from_, uint256 amount_);
    event CreditsAdded(address to_, uint256 amount_);

    // Internal Calculators
    function _getSmallerValueUint40(uint40 a, uint40 b) internal pure returns (uint40) {
        return a < b ? a : b;
    }
    function _getTimestamp() internal view returns (uint40) {
        return _getSmallerValueUint40( uint40(block.timestamp), yieldEndTime );
    }
    function _getYieldRate(address address_) internal view returns (uint40) {
        return uint40(ZenApe.balanceOf(address_) * yieldRatePerToken);
    }

    // Internal Accountants
    function _getPendingRewards(address address_) internal view returns (uint216) {
        uint256 _totalYieldRate = uint256(_getYieldRate(address_));
        if (_totalYieldRate == 0) return 0;
        uint256 _time = uint256(_getTimestamp());
        uint256 _lastUpdate = uint256(addressToYield[address_].lastUpdateTime);

        if (_lastUpdate > yieldStartTime) {
            return uint216( (_totalYieldRate * (_time - _lastUpdate) / 1 days) );
        } 
        // Has ZenApe before Zen Token
        else if (_lastUpdate == 0 && _totalYieldRate > 0) {
            return uint216( (_totalYieldRate * (_time - yieldStartTime) / 1 days) );
        } else { return 0; }
    }
    function _updateReward(address address_) internal {
        uint40 _lastUpdate = addressToYield[address_].lastUpdateTime;

        if (_lastUpdate > 0) {
            addressToYield[address_].pendingRewards += _getPendingRewards(address_);
        }
        // Has ZenApe before Zen Token
        else if (_lastUpdate == 0 && ZenApe.balanceOf(address_) != 0) {
            addressToYield[address_].pendingRewards += _getPendingRewards(address_);
        }
        
        if (_lastUpdate != yieldEndTime) {
            addressToYield[address_].lastUpdateTime = _getTimestamp();
        }
    }
    function _claimReward(address address_) internal {
        // This does not update before claim. So, in internal flows, update first.
        uint216 _pendingRewards = addressToYield[address_].pendingRewards;
        
        if (_pendingRewards > 0) {
            uint256 _expandedReward = uint256(_pendingRewards * globalModulus);

            addressToYield[address_].pendingRewards = 0;

            Zen.mintAsController(address_, _expandedReward);
        }
    }

    // ZenApe Functions
    function updateReward(address from_, address to_, uint256 tokenId_) public {
        require(msg.sender == address(ZenApe), 
            "You are not ZenApe!");
        
        _updateReward(from_);
        _updateReward(to_);
    }
    
    // Public Functions
    function updateRewardFor(address address_) public {
        _updateReward(address_);
    }
    function claimReward(address address_) public {
        _updateReward(address_);
        _claimReward(address_);
    }

    // View Functions
    function getYieldRateOfAddress(address address_) public view returns (uint256) {
        return uint256( uint256(_getYieldRate(address_)) * globalModulus);
    }
    function getStorageClaimableTokens(address address_) public view returns (uint256) {
        return uint256( uint256(
            addressToYield[address_].pendingRewards) * globalModulus);
    }
    function getPendingClaimableTokens(address address_) public view returns (uint256) {
        return uint256( uint256(_getPendingRewards(address_)) * globalModulus );
    }
    function getTotalClaimableTokens(address address_) public view returns (uint256) {
        return getStorageClaimableTokens(address_) 
            + getPendingClaimableTokens(address_);
    }
    function raw_getStorageClaimableTokens(address address_) public view 
    returns (uint256) {
        return uint256(addressToYield[address_].pendingRewards);
    }
    function raw_getPendingClaimableTokens(address address_) public view
    returns (uint256) {
        return uint256(_getPendingRewards(address_));
    }
    function raw_getTotalClaimableTokens(address address_) public view
    returns (uint256) {
        return raw_getStorageClaimableTokens(address_) 
            + raw_getPendingClaimableTokens(address_);
    }
}