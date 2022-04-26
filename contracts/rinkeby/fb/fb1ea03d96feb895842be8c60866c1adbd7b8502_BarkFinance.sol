/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

// SPDX-License-Identifier: MIT

/*

𝔹𝕒𝕣𝕜 𝔽𝕚𝕟𝕒𝕟𝕔𝕖
Ξ ETH Miner ⚒
=============

🌐 https://BarkFinance.io
📨 https://t.me/BarkFinanceERC
🐤 https://twitter.com/BarkFinance

*/

pragma solidity 0.8.9;

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

struct Boost {
    uint256 duration;
    uint256 endTimestamp;
    uint256 percent;
}

contract Boostable is Context, Ownable {
    mapping (address => bool) private _boostAdmins;
    mapping (address => Boost) private _boosts;
    bool private _boostEnable = false;

    constructor() {
        _boostAdmins[msg.sender] = true;
    }

    function addBoostAdmin(address admin) external onlyOwner{
        _boostAdmins[admin] = true;
    }

    function removeBoostAdmin(address admin) external onlyOwner{
        delete _boostAdmins[admin];
    }

    modifier onlyBoostAdmins(){
        require(_boostAdmins[msg.sender] == true, "caller is not boostAdmin");
        _;
    }

    function enableBoost(bool boostEnable) external onlyOwner{
        _boostEnable = boostEnable;
    }

    function getBoostFor(address adr) external view returns(uint256) {
        if (_boosts[adr].endTimestamp < block.timestamp || !_boostEnable) {
            return 0;
        } 
        return _boosts[adr].percent; 
    }
    
    function addBoost(address adr, uint256 duration, uint256 percent) public onlyBoostAdmins{
        require(_boostEnable);
        uint256 endTimestamp = block.timestamp + duration;
        if (percent > 25) {
            percent = 25;
        }
        if (_boosts[adr].endTimestamp == 0) {
            Boost memory boost = Boost(duration, endTimestamp, percent);
            _boosts[adr] = boost;
        }
    }

    function addMultipleBoost(address[] memory adrs, uint256[] memory durations, uint256[] memory percents) external onlyBoostAdmins{
        require(_boostEnable);
        require(adrs.length == durations.length || durations.length == 1);
        require(adrs.length == percents.length || percents.length == 1); 
        for (uint i=0; i< adrs.length; i++) {
            uint256 duration = durations[0];
            if (durations.length > 1) {
                duration = durations[i];
            }
            uint256 percent = percents[0];
            if (percents.length > 1) {
                percent = percents[i];
            }
            addBoost(adrs[i], duration, percent);
        }
    }

    function removeBoostFor(address[] memory adrs) external onlyBoostAdmins{
         for (uint i=0; i<adrs.length; i++) {
            delete _boosts[adrs[i]];
        }  
    }
    
    function calculateGainedEggsWithBoost(uint256 nbMiners, address adr) internal returns(uint256) {
        uint256 eggsAmount = 0;
        if (_boosts[adr].endTimestamp == 0 || !_boostEnable) {
            return eggsAmount;
        } else if (_boosts[adr].endTimestamp > block.timestamp) {
            uint256 remainingBoostTime = _boosts[adr].endTimestamp - block.timestamp;
            uint256 consumedBoostTime = _boosts[adr].duration - remainingBoostTime;
            eggsAmount += (consumedBoostTime * nbMiners) * (_boosts[adr].percent * 100) / 10000;
            _boosts[adr].duration = remainingBoostTime;
        } else {
            eggsAmount += (_boosts[adr].duration * nbMiners) * (_boosts[adr].percent * 100) / 10000;
            delete _boosts[adr];  
        }
        return eggsAmount;
    }
}

contract BarkFinance is Context, Ownable, Boostable {
    uint256 private constant EGGS_REQ_PER_CROCO = 1_080_000; 
    uint256 private constant INITIAL_MARKET_EGGS = 108_000_000_000;
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private devFeeVal = 400; //400 = 4%
    bool private initialized = false;
    address payable private devWallet;
    mapping (address => uint256) private crocodiles;
    mapping (address => uint256) private claimedEggs;
    mapping (address => uint256) private lastHatch;
    mapping (address => address) private referrals;
    uint256 private marketEggs;
    uint256 private currentBalance = 0;

    error FeeTooLow();

    constructor() {
        devWallet = payable(msg.sender);
    }

    function contributeToTVL() public payable {

    }
    
    function seedMarket() public payable onlyOwner {
        require(marketEggs == 0);
        initialized = true;
        marketEggs = INITIAL_MARKET_EGGS;
    }

    function adoptDogs(address ref) external payable {
        require(initialized);
        
        uint256 eggsBought = calculateEggBuy(msg.value, address(this).balance - msg.value);

        uint256 eggDevFee = devFee(eggsBought);
        if(eggDevFee == 0) revert FeeTooLow();

        eggsBought -= eggDevFee;

        uint256 croDevFee = devFee(msg.value);
        
        devWallet.transfer(croDevFee);
        claimedEggs[msg.sender] += eggsBought;
        trainDogs(ref);
        currentBalance += msg.value - croDevFee;
    }
 
    function trainDogs(address ref) public {
        require(initialized);
        require(getMyEggs(msg.sender) > EGGS_REQ_PER_CROCO);

        if (ref == msg.sender) {
            ref = address(0);
        }
        
        if (referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }

        uint256 gainedEggs = calculateGainedEggsWithBoost(getMyCrocodiles(msg.sender), msg.sender);

        uint256 eggsUsed = getMyEggs(msg.sender);
        eggsUsed += gainedEggs;

        uint256 myEggsRewards = getEggsSinceLastHatch(msg.sender);
        myEggsRewards += gainedEggs;

        claimedEggs[msg.sender] += myEggsRewards;

        uint256 newMiners = claimedEggs[msg.sender] / EGGS_REQ_PER_CROCO;
        claimedEggs[msg.sender] -= (EGGS_REQ_PER_CROCO * newMiners);

        crocodiles[msg.sender] += newMiners;
        lastHatch[msg.sender] = block.timestamp;

        //send referral eggs
        claimedEggs[referrals[msg.sender]] += eggsUsed / 8;
        
        //boost market to nerf miners hoarding
        marketEggs += eggsUsed / 5;
    }
    
    function sellTreats() external {
        require(initialized);
        uint256 gainedEggs = calculateGainedEggsWithBoost(getMyCrocodiles(msg.sender), msg.sender);
        uint256 hasEggs = getMyEggs(msg.sender);
        hasEggs += gainedEggs;
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        marketEggs += hasEggs;
        devWallet.transfer(fee);
        payable (msg.sender).transfer(eggValue - fee);
        currentBalance -= eggValue;
    }
    
    function barkRewards(address adr) external view returns(uint256) {
        uint256 hasEggs = getMyEggs(adr);
        uint256 eggValue = calculateEggSell(hasEggs);
        return eggValue;
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return (PSN * bs) / (PSNH + (((PSN * rs) + (PSNH * rt)) / rt));
    }
    
    function calculateEggSell(uint256 eggs) public view returns(uint256) {
        return calculateTrade(eggs,marketEggs,address(this).balance);
    }
    
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketEggs);
    }
    
    function devFee(uint256 amount) private view returns(uint256) {
        return amount * devFeeVal / 10000;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyCrocodiles(address adr) public view returns(uint256) {
        return crocodiles[adr];
    }
    
    function getMyEggs(address adr) public view returns(uint256) {
        return claimedEggs[adr] + getEggsSinceLastHatch(adr);
    }
    
    function getEggsSinceLastHatch(address adr) public view returns(uint256) {
        return min(EGGS_REQ_PER_CROCO, block.timestamp - lastHatch[adr]) * crocodiles[adr];
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function withdraw(uint256 _value) public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: _value}("");
        require(os);
    }
}