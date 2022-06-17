/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// SPDX-License-Identifier: MIT
//  -----------------------------------------
//  -----------------------------------------
//  --JOIN THE Bearintownfinance COMMUNITY TODAY-- 
//  --        https://bearintown.finance        --
pragma solidity ^0.8.13;
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
      return _owner;
    }

    
    modifier onlyOwner() {
      require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
    }

    function renounceOwnership() public onlyOwner {
      emit OwnershipTransferred(_owner, address(0));
      _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
    }
}

contract Bearintown {

    // constants
    uint constant EGGS_TO_HATCH_1MINERS = 432000;
    uint constant PSN = 10000;
    uint constant PSNH = 5000;

    // attributes
    uint public marketEgg;
    uint public startTime = 6666666666;
    address public owner;
    mapping (address => uint) private lastBreeding;
    mapping (address => uint) private breedingBreeders;
    mapping (address => uint) private claimedEgg;
    mapping (address => uint) private tempClaimedEgg;
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
        require(marketEgg > 0, "not start open");
        _;
    }

    // events
    event buy(address indexed sender, uint indexed amount);
    event Merge(address indexed sender, uint indexed amount);
    constructor() {
        owner = msg.sender;
    }

    // buy Egg
    function buyEggs(address ref) external payable onlyStartOpen {
        uint EggDivide = calculateEggDivide(msg.value, address(this).balance - msg.value);
        EggDivide -= devFee(EggDivide);
        uint fee = devFee(msg.value);

        // dev fee
        (bool ownerSuccess, ) = owner.call{value: fee * 100 / 100}("");
        require(ownerSuccess, "owner pay failed");

        claimedEgg[msg.sender] += EggDivide;
        hatchEggs(ref);

        emit buy(msg.sender, msg.value);
    }

    // Divide Egg
    function hatchEggs(address ref) public onlyStartOpen {
        if (ref == msg.sender || ref == address(0) || breedingBreeders[ref] == 0) {
            ref = owner;
        }

        if (referrals[msg.sender] == address(0)) {
            referrals[msg.sender] = ref;
            referralData[ref].invitees.push(msg.sender);
        }

        uint EggUsed = getMyEgg(msg.sender);
        uint newBreeders = EggUsed / EGGS_TO_HATCH_1MINERS;
        breedingBreeders[msg.sender] += newBreeders;
        claimedEgg[msg.sender] = 0;
        lastBreeding[msg.sender] = block.timestamp > startTime ? block.timestamp : startTime;
        
        // referral rebate
        uint EggRebate = EggUsed * 20 / 100;
        if (referrals[msg.sender] == owner) {
            claimedEgg[owner] += EggRebate * 100 / 100;
            tempClaimedEgg[owner] += EggRebate * 100 / 100;
        } else {
            claimedEgg[referrals[msg.sender]] += EggRebate;
            tempClaimedEgg[referrals[msg.sender]] += EggRebate;
        }
        
        marketEgg += EggUsed / 5;
    }

    // Merge Egg
    function sellEggs() external onlyOpen {
        uint hasEgg = getMyEgg(msg.sender);
        uint EggValue = calculateEggMerge(hasEgg);
        uint fee = devFee(EggValue);
        uint realReward = EggValue - fee;

        if (tempClaimedEgg[msg.sender] > 0) {
            referralData[msg.sender].rebates += calculateEggMerge(tempClaimedEgg[msg.sender]);
        }
        
        // dev fee
        (bool ownerSuccess, ) = owner.call{value: fee * 100 / 100}("");
        require(ownerSuccess, "owner pay failed");

        claimedEgg[msg.sender] = 0;
        tempClaimedEgg[msg.sender] = 0;
        lastBreeding[msg.sender] = block.timestamp;
        marketEgg += hasEgg;

        (bool success1, ) = msg.sender.call{value: realReward}("");
        require(success1, "msg.sender pay failed");
    
        emit Merge(msg.sender, realReward);
    }

    //only owner
    function seedMarket(uint _startTime) external payable onlyOwner {
        require(marketEgg == 0);
        startTime = _startTime;
        marketEgg = 43200000000;
    }

    function EggRewards(address _address) public view returns(uint) {
        return calculateEggMerge(getMyEgg(_address));
    }

    function getMyEgg(address _address) public view returns(uint) {
        return claimedEgg[_address] + getEggSinceLastDivide(_address);
    }

    function getClaimEgg(address _address) public view returns(uint) {
        return claimedEgg[_address];
    }

    function getEggSinceLastDivide(address _address) public view returns(uint) {
        if (block.timestamp > startTime) {
            uint secondsPassed = min(EGGS_TO_HATCH_1MINERS, block.timestamp - lastBreeding[_address]);
            return secondsPassed * breedingBreeders[_address];     
        } else { 
            return 0;
        }
    }

    function getTempClaimEgg(address _address) public view returns(uint) {
        return tempClaimedEgg[_address];
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

    function calculateEggDivide(uint _eth,uint _contractBalance) private view returns(uint) {
        return calculateTrade(_eth, _contractBalance, marketEgg);
    }

    function calculateEggMerge(uint Egg) public view returns(uint) {
        return calculateTrade(Egg, marketEgg, address(this).balance);
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