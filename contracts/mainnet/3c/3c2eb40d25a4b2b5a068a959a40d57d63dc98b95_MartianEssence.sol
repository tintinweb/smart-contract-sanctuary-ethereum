/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

//SPDX-License-Identifier: Delayed Release MIT
pragma solidity ^0.8.0;

/*
    ERC20I (ERC20 0xInuarashi Edition)
    Minified and Gas Optimized
    From the efforts of the 0x Collective
    https://0xcollective.net
*/

contract ERC20I {
    // Token Params
    string public name;
    string public symbol;
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    // Decimals
    uint8 public constant decimals = 18;

    // Supply
    uint256 public totalSupply;
    
    // Mappings of Balances
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Internal Functions
    function _mint(address to_, uint256 amount_) internal {
        totalSupply += amount_;
        balanceOf[to_] += amount_;
        emit Transfer(address(0x0), to_, amount_);
    }
    function _burn(address from_, uint256 amount_) internal {
        balanceOf[from_] -= amount_;
        totalSupply -= amount_;
        emit Transfer(from_, address(0x0), amount_);
    }

    // Public Functions
    function approve(address spender_, uint256 amount_) public virtual returns (bool) {
        allowance[msg.sender][spender_] = amount_;
        emit Approval(msg.sender, spender_, amount_);
        return true;
    }
    function transfer(address to_, uint256 amount_) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount_;
        balanceOf[to_] += amount_;
        emit Transfer(msg.sender, to_, amount_);
        return true;
    }
    function transferFrom(address from_, address to_, uint256 amount_) public virtual returns (bool) {
        if (allowance[from_][msg.sender] != type(uint256).max) {
            allowance[from_][msg.sender] -= amount_; }
        balanceOf[from_] -= amount_;
        balanceOf[to_] += amount_;
        emit Transfer(from_, to_, amount_);
        return true;
    }

    // 0xInuarashi Custom Functions
    function multiTransfer(address[] memory to_, uint256[] memory amounts_) public virtual {
        require(to_.length == amounts_.length, "ERC20I: To and Amounts length Mismatch!");
        for (uint256 i = 0; i < to_.length; i++) {
            transfer(to_[i], amounts_[i]);
        }
    }
    function multiTransferFrom(address[] memory from_, address[] memory to_, uint256[] memory amounts_) public virtual {
        require(from_.length == to_.length && from_.length == amounts_.length, "ERC20I: From, To, and Amounts length Mismatch!");
        for (uint256 i = 0; i < from_.length; i++) {
            transferFrom(from_[i], to_[i], amounts_[i]);
        }
    }
}

abstract contract ERC20IBurnable is ERC20I {
    function burn(uint256 amount_) external virtual {
        _burn(msg.sender, amount_);
    }
    function burnFrom(address from_, uint256 amount_) public virtual {
        uint256 _currentAllowance = allowance[from_][msg.sender];
        require(_currentAllowance >= amount_, "ERC20IBurnable: Burn amount requested exceeds allowance!");

        if (allowance[from_][msg.sender] != type(uint256).max) {
            allowance[from_][msg.sender] -= amount_; }

        _burn(from_, amount_);
    }
}

abstract contract Ownable {
    address public owner;
    constructor() { 
        owner = msg.sender; 
    }
    modifier onlyOwner { 
        require(owner == msg.sender, "Ownable: caller is not the owner"); 
        _; 
    }
    function transferOwnership(address newOwner_) public virtual onlyOwner {
        owner = newOwner_; 
    }
}

interface iMES {
    struct Yield { uint40 yieldRate_; uint40 lastUpdatedTime_; uint176 pendingRewards_; }
    function raw_getTotalClaimableTokens(address address_) external view returns (uint256);
    function addressToYield(address address_) external view returns (Yield memory);
}

contract MartianEssence is ERC20IBurnable, Ownable {

    // Constructor and Treasury Mints
    constructor() ERC20I("Martian Essence", "MES") {

        // Treasury Mint. We will never use this, except to benefit the community.
        // This is 10M and is around 5% of the theoretical total supply.
        _mint(msg.sender, 10000000 ether);
    }

    // Interface with Old MES
    iMES public oMES = iMES(0x984b6968132DA160122ddfddcc4461C995741513);
    function setoMEs(address address_) external onlyOwner {
        oMES = iMES(address_);
    }

    // Times
    uint40 public yieldStartTime = 1638619200; // 2021-12-04_07-00-00 EST
    uint40 public yieldEndTime = 1956502800; // 2031-12-31_12-00-00 EST
    function setYieldEndTime(uint40 yieldEndTime_) external onlyOwner { 
        yieldEndTime = yieldEndTime_; }

    // Controllers
    mapping(address => bool) public mesControllers; 
    function setController(address address_, bool bool_) external onlyOwner {
        mesControllers[address_] = bool_; }
    modifier onlyControllers { 
        require(mesControllers[msg.sender], "You are not a controller!"); _; }

    // Yield Info
    uint256 public globalModulus = (10 ** 14);
    uint40 public halvingRate = 1; // This is not used

    struct Yield {
        uint40 yieldRate_;
        uint40 lastUpdatedTime_;
        uint176 pendingRewards_;
    }

    mapping(address => Yield) public addressToYield;

    function setHalvingRate(uint40 rate_) external onlyOwner {
        halvingRate = rate_; }

    // Events
    event Claim(address to_, uint256 amount_);

    // Administration
    function setYieldRate(address address_, uint256 yieldRate_) external onlyControllers {
        uint40 _yieldRate = uint40(yieldRate_ / globalModulus);
        addressToYield[address_].yieldRate_ = _yieldRate;
    }
    function addYieldRate(address address_, uint256 yieldRateAdd_) external onlyControllers {
        uint40 _yieldRateAdd = uint40(yieldRateAdd_ / globalModulus);
        addressToYield[address_].yieldRate_ += _yieldRateAdd;
    }
    function subYieldRate(address address_, uint256 yieldRateSub_) external onlyControllers {
        uint40 _yieldRateSub = uint40(yieldRateSub_ / globalModulus);
        addressToYield[address_].yieldRate_ -= _yieldRateSub;
    }

    // Credits System
    function deductCredits(address address_, uint256 amount_) external onlyControllers {
        uint40 _amount = uint40(amount_ / globalModulus);
        require(addressToYield[address_].pendingRewards_ >= _amount, "Not enough credits!");
        addressToYield[address_].pendingRewards_ -= _amount;
    }
    function addCredits(address address_, uint256 amount_) external onlyControllers {
        uint40 _amount = uint40(amount_ / globalModulus);
        addressToYield[address_].pendingRewards_ += _amount;
    }

    // ERC20 Burn (Stacked Functions!)
    function burn(address from_, uint256 amount_) external onlyControllers {
        _burn(from_, amount_);
    }

    // ERC20 Airdrop for Migration
    function airdropMigration(address[] calldata addresses_, uint256[] calldata amounts_) external onlyOwner {
        require(addresses_.length == amounts_.length,
            "Array length mismatch!");
        
        for (uint256 i = 0; i < addresses_.length; i++) {
            _mint(addresses_[i], amounts_[i]);
        }
    }

    // Migrator: Unstuck Addresses
    function migrateSetNewYieldInfos(address[] calldata addresses_, uint40[] calldata lastUpdatedTimes_,
    uint40[] calldata yieldRates_, uint176[] calldata pendingRewards_) external onlyOwner {
        require(addresses_.length == lastUpdatedTimes_.length
            && addresses_.length == yieldRates_.length
            && addresses_.length == pendingRewards_.length,
            "Array lengths mismatch!");
        
        for (uint256 i = 0; i < addresses_.length; i++) {
            addressToYield[addresses_[i]].lastUpdatedTime_ = lastUpdatedTimes_[i];
            addressToYield[addresses_[i]].yieldRate_ = yieldRates_[i];
            addressToYield[addresses_[i]].pendingRewards_ = pendingRewards_[i];
        }
    }

    // Internal View Functions
    function __getSmallerValueUint40(uint40 a, uint40 b) internal pure returns (uint40) {
        return a < b ? a : b;
    }
    function __getTimestamp() internal view returns (uint40) {
        return __getSmallerValueUint40(uint40(block.timestamp), yieldEndTime);
    }
    function __calculateYieldReward(address address_) internal view returns (uint176) {
        // ~0xInuarashi: The fixed calculation code...
        uint256 _totalYieldRate = uint256(addressToYield[address_].yieldRate_); 
        
        if (_totalYieldRate == 0) { return 0; }
        
        uint256 _time = uint256(__getSmallerValueUint40(uint40(block.timestamp), yieldEndTime));
        uint256 _lastUpdate = uint256(addressToYield[address_].lastUpdatedTime_);

        if (_lastUpdate > yieldStartTime) {
            return uint176( (_totalYieldRate * (_time - _lastUpdate) / 1 days) / halvingRate);
        } else {
            return 0;
        }
    }

    // Migration Logic
    bool public migrationEnabled = true;
    function setMigrationEnabled(bool bool_) external onlyOwner { migrationEnabled = bool_; }

    function __migrateRewards(address address_) internal {
        require(migrationEnabled,
            "Migration is not enabled!");
        
        uint40 _time = __getTimestamp();
        uint40 _lastUpdate = addressToYield[address_].lastUpdatedTime_;

        require(_lastUpdate == 0,
            "You have already migrated!");
        
        // Set the time. This starts the yield again.
        addressToYield[address_].lastUpdatedTime_ = _time;
        
        // Claim their rewards for them from the old contract
        uint176 _pendingRewards = uint176(oMES.raw_getTotalClaimableTokens(address_));

        if (_pendingRewards > 0) {
            addressToYield[address_].pendingRewards_ = _pendingRewards;
        }

        // Set their yield rate to the previous contract's yield rate
        uint40 _yieldRate = oMES.addressToYield(address_).yieldRate_;

        if (_yieldRate > 0) {
            addressToYield[address_].yieldRate_ = _yieldRate;
        }
    }

    function migrateRewards(address[] calldata addresses_) public {
        require(migrationEnabled,
            "Migration is not enabled!");
    
        for (uint256 i = 0; i < addresses_.length; i++) {
            __migrateRewards(addresses_[i]);
        }
    }

    // Internal Write Functions
    function __updateYieldReward(address address_) internal {
        uint40 _time = __getSmallerValueUint40(uint40(block.timestamp), yieldEndTime);
        uint40 _lastUpdate = addressToYield[address_].lastUpdatedTime_;

        if (_lastUpdate > 0) { 
            addressToYield[address_].pendingRewards_ += __calculateYieldReward(address_); 
        } else {
            // Migrate Rewards Logic if _lastUpdate is 0
            if (migrationEnabled) {
                __migrateRewards(address_);
            }
        }

        if (_lastUpdate != yieldEndTime) { 
            addressToYield[address_].lastUpdatedTime_ = _time; 
        }
    }

    function __claimYieldReward(address address_) internal {
        uint176 _pendingRewards = addressToYield[address_].pendingRewards_;

        if (_pendingRewards > 0) { 
            addressToYield[address_].pendingRewards_ = 0;

            uint256 _expandedReward = uint256(_pendingRewards * globalModulus);

            _mint(address_, _expandedReward);
            emit Claim(address_, _expandedReward);
        } 
    }

    // Public Write Functions
    function updateReward(address address_) public {
        __updateYieldReward(address_); 
    }
    function claimTokens(address address_) public {
        __updateYieldReward(address_);
        __claimYieldReward(address_);
    }

    // Public Write Multi-Functions
    function multiUpdateReward(address[] memory addresses_) public {
        for (uint256 i = 0; i < addresses_.length; i++) {
            updateReward(addresses_[i]);
        }
    }
    function multiClaimTokens(address[] memory addresses_) public {
        for (uint256 i = 0; i < addresses_.length; i++) {
            claimTokens(addresses_[i]);
        }
    }

    // Public View Functions
    function getStorageClaimableTokens(address address_) public view returns (uint256) {
        return uint256( uint256(addressToYield[address_].pendingRewards_) * globalModulus);
    }
    function getPendingClaimableTokens(address address_) public view returns (uint256) {
        return uint256( uint256(__calculateYieldReward(address_)) * globalModulus);
    }
    function getTotalClaimableTokens(address address_) public view returns (uint256) {
        return getStorageClaimableTokens(address_) + getPendingClaimableTokens(address_);
    }
    function getYieldRateOfAddress(address address_) public view returns (uint256) {
        return uint256( uint256(addressToYield[address_].yieldRate_) * globalModulus); 
    }
    function raw_getStorageClaimableTokens(address address_) public view returns (uint256) {
        return uint256(addressToYield[address_].pendingRewards_);
    }
    function raw_getPendingClaimableTokens(address address_) public view returns (uint256) {
        return uint256(__calculateYieldReward(address_));
    }
    function raw_getTotalClaimableTokens(address address_) public view returns (uint256) {
        return raw_getStorageClaimableTokens(address_) + raw_getPendingClaimableTokens(address_);
    }

}