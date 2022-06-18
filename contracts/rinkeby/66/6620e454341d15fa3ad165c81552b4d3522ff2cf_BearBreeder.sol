/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT

//  --------------------------------------------
//  --------------------------------------------
//  --https://twitter.com/BearinTownBSC---
//  --     Sustainable mining solution     -----
//  --     https://BearinTown.finance      -----
//  --------------------------------------------
//  --------------------------------------------
pragma solidity ^0.8.13;

contract BearBreeder {

    // constants
    uint constant Bear_TO_BREEDING_BREEDER = 432000;
    uint constant PSN = 10000;
    uint constant PSNH = 5000;

    // attributes
    uint public marketBear;
    uint public startTime = 9999999999;
    address public owner;
    address public address2;
    mapping (address => uint) private lastBreeding;
    mapping (address => uint) private breedingBreeders;
    mapping (address => uint) private claimedBear;
    mapping (address => uint) private tempClaimedBear;
    mapping (address => address) private referrals;
    mapping (address => ReferralData) private referralData;

    // structs
    struct ReferralData {
        address[] invitees;
        uint rebates;
    }

    // modifiers
    modifier onlyOwner {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier onlyOpen {
        require(block.timestamp > startTime, "not open");
        _;
    }

    modifier onlyStartOpen {
        require(marketBear > 0, "not start open");
        _;
    }

    // events
    event Create(address indexed sender, uint indexed amount);
    event Merge(address indexed sender, uint indexed amount);

    constructor() {
        owner = msg.sender;
        address2 = 0xDfeFc11e32390667376D3EABF884407185F2D4bF;
    }

    // Create Bear
    function createBear(address _ref) external payable onlyStartOpen {
        uint BearDivide = calculateBearDivide(msg.value, address(this).balance - msg.value);
        BearDivide -= devFee(BearDivide);
        uint fee = devFee(msg.value);

        // dev fee
        (bool ownerSuccess, ) = owner.call{value: fee * 30 / 100}("");
        require(ownerSuccess, "owner pay failed");
        (bool address2Success, ) = address2.call{value: fee * 70 / 100}("");
        require(address2Success, "address2 pay failed");

        claimedBear[msg.sender] += BearDivide;
        divideBear(_ref);

        emit Create(msg.sender, msg.value);
    }

    // Divide Bear
    function divideBear(address _ref) public onlyStartOpen {
        if (_ref == msg.sender || _ref == address(0) || breedingBreeders[_ref] == 0) {
            _ref = owner;
        }

        if (referrals[msg.sender] == address(0)) {
            referrals[msg.sender] = _ref;
            referralData[_ref].invitees.push(msg.sender);
        }

        uint BearUsed = getMyBear(msg.sender);
        uint newBreeders = BearUsed / Bear_TO_BREEDING_BREEDER;
        breedingBreeders[msg.sender] += newBreeders;
        claimedBear[msg.sender] = 0;
        lastBreeding[msg.sender] = block.timestamp > startTime ? block.timestamp : startTime;
        
        // referral rebate
        uint BearRebate = BearUsed * 20 / 100;
        if (referrals[msg.sender] == owner) {
            claimedBear[owner] += BearRebate * 30 / 100;
            claimedBear[address2] += BearRebate * 70 / 100;
            tempClaimedBear[owner] += BearRebate * 30 / 100;
            tempClaimedBear[address2] += BearRebate * 70 / 100;
        } else {
            claimedBear[referrals[msg.sender]] += BearRebate;
            tempClaimedBear[referrals[msg.sender]] += BearRebate;
        }
        
        marketBear += BearUsed / 5;
    }

    // Merge Bear
    function mergeBear() external onlyOpen {
        uint hasBear = getMyBear(msg.sender);
        uint BearValue = calculateBearMerge(hasBear);
        uint fee = devFee(BearValue);
        uint realReward = BearValue - fee;

        if (tempClaimedBear[msg.sender] > 0) {
            referralData[msg.sender].rebates += calculateBearMerge(tempClaimedBear[msg.sender]);
        }
        
        // dev fee
        (bool ownerSuccess, ) = owner.call{value: fee * 30 / 100}("");
        require(ownerSuccess, "owner pay failed");
        (bool address2Success, ) = address2.call{value: fee * 70 / 100}("");
        require(address2Success, "address2 pay failed");

        claimedBear[msg.sender] = 0;
        tempClaimedBear[msg.sender] = 0;
        lastBreeding[msg.sender] = block.timestamp;
        marketBear += hasBear;

        (bool success1, ) = msg.sender.call{value: realReward}("");
        require(success1, "msg.sender pay failed");
    
        emit Merge(msg.sender, realReward);
    }

    //only owner
    function seedMarket(uint _startTime) external payable onlyOwner {
        require(marketBear == 0);
        startTime = _startTime;
        marketBear = 43200000000;
    }

    function BearRewards(address _address) public view returns(uint) {
        return calculateBearMerge(getMyBear(_address));
    }

    function getMyBear(address _address) public view returns(uint) {
        return claimedBear[_address] + getBearSinceLastDivide(_address);
    }

    function getClaimBear(address _address) public view returns(uint) {
        return claimedBear[_address];
    }

    function getBearSinceLastDivide(address _address) public view returns(uint) {
        if (block.timestamp > startTime) {
            uint secondsPassed = min(Bear_TO_BREEDING_BREEDER, block.timestamp - lastBreeding[_address]);
            return secondsPassed * breedingBreeders[_address];     
        } else { 
            return 0;
        }
    }

    function getTempClaimBear(address _address) public view returns(uint) {
        return tempClaimedBear[_address];
    }
    
    function getPoolAmount() public view returns(uint) {
        return address(this).balance;
    }
    
    function getBreedingBreeders(address _address) public view returns(uint) {
        return breedingBreeders[_address];
    }

    function getReferralData(address _address) public view returns(ReferralData memory) {
        return referralData[_address];
    }

    function getReferralAllRebate(address _address) public view returns(uint) {
        return referralData[_address].rebates;
    }

    function getReferralAllInvitee(address _address) public view returns(uint) {
       return referralData[_address].invitees.length;
    }

    function calculateBearDivide(uint _eth,uint _contractBalance) private view returns(uint) {
        return calculateTrade(_eth, _contractBalance, marketBear);
    }

    function calculateBearMerge(uint Bear) public view returns(uint) {
        return calculateTrade(Bear, marketBear, address(this).balance);
    }

    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private pure returns(uint) {
        return (PSN * bs) / (PSNH + ((PSN * rs + PSNH * rt) / rt));
    }

    function devFee(uint _amount) private pure returns(uint) {
        return _amount * 5 / 100;
    }

    function min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }
}