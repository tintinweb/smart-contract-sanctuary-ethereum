/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

// SPDX-License-Identifier: MIT
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}

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

contract KryptoniteMiner is Context, Ownable {
    using SafeMath for uint256;

    uint256 private constant Kryptonite_TO_LAUNCH_MINER = 1080000; //for final version should be seconds in a day

    uint256 private constant PSN = 10000;
    uint256 private constant PSNH = 5000;
    
    uint256 private constant developerFee = 2;
    uint256 private constant marketingTeamFee = 2;
    uint256 private constant webTeamFee = 1;
    uint256 private constant projectTeamFee = 1;

    bool private marketInitialized = false ;

    address payable private developerAddress;
    address payable private marketingTeamAddress;
    address payable private projectTeamAddress;
    address payable private webAuthAddress;
    
    mapping (address => uint256) private KryptoniteMiners;
    mapping (address => uint256) private ownedKryptonite;
    mapping (address => uint256) private lastOwnerHarvest;
    mapping (address => address) private ownerReferrals;

    uint256 private totalKryptonite;
    uint256 private constant TOTAL_KRYPTONITE_COUNT = 108000000000;
    uint256 private constant PERCENTAGE_DIVISOR = 100;
    
    constructor(address marketingAddress, address teamAddress, address webAddress) { 
        developerAddress = payable(msg.sender);
        marketingTeamAddress = payable(marketingAddress);
        projectTeamAddress = payable(teamAddress);
        webAuthAddress = payable(webAddress);
    }
    
    function harvestKryptonite(address referralAddress) public {
        require(marketInitialized);
        
        address sender = msg.sender;

        if (referralAddress == sender) {
            referralAddress = address(0);
        }
        
        address ownerReferralsSender = ownerReferrals[sender];

        if (ownerReferralsSender == address(0) && ownerReferralsSender != sender) {
            ownerReferralsSender = referralAddress;
            ownerReferrals[sender] = ownerReferralsSender;
        }
        
        uint256 KryptoniteUsed = getMyKryptonite(sender);
        uint256 newMiners = SafeMath.div(KryptoniteUsed, Kryptonite_TO_LAUNCH_MINER);

        KryptoniteMiners[sender] = SafeMath.add(KryptoniteMiners[sender], newMiners);
        ownedKryptonite[sender] = 0;
        lastOwnerHarvest[sender] = block.timestamp;
        
        //send referral Kryptonite
        ownedKryptonite[ownerReferralsSender] = SafeMath.add(ownedKryptonite[ownerReferralsSender], SafeMath.div(KryptoniteUsed, 8));
        
        //boost market to nerf miners hoarding
        totalKryptonite = SafeMath.add(totalKryptonite, SafeMath.div(KryptoniteUsed, 5));
    }
    
    function sellKryptonite() public {
        require(marketInitialized);

        address sender = msg.sender;

        uint256 hasKryptonite = getMyKryptonite(sender);
        uint256 value = calculateKryptoniteell(hasKryptonite);
        uint256 devFee = payFees(value);

        ownedKryptonite[sender] = 0;
        lastOwnerHarvest[sender] = block.timestamp;
        totalKryptonite = SafeMath.add(totalKryptonite, hasKryptonite);

        payable (sender).transfer(SafeMath.sub(value, devFee));
    }
    
    function getKryptoniteRewads(address myAddress) public view returns(uint256) {
        uint256 hasKryptonite = getMyKryptonite(myAddress);
        uint256 value = calculateKryptoniteell(hasKryptonite);
        return value;
    }
    
    function buyKryptonite(address referralAddress) public payable {
        require(marketInitialized);

        uint256 value = msg.value;
        uint256 KryptoniteBought = calculateKryptoniteBuy(value, SafeMath.sub(address(this).balance, value));

        KryptoniteBought = SafeMath.sub(KryptoniteBought, getDevFee(KryptoniteBought));
        KryptoniteBought = SafeMath.sub(KryptoniteBought, getMarketingFee(KryptoniteBought));
        KryptoniteBought = SafeMath.sub(KryptoniteBought, getWebAuthFee(KryptoniteBought));
        KryptoniteBought = SafeMath.sub(KryptoniteBought, getTeamFee(KryptoniteBought));

        payFees(value);

        address sender = msg.sender;
        ownedKryptonite[sender] = SafeMath.add(ownedKryptonite[sender], KryptoniteBought);
        harvestKryptonite(referralAddress);
    }

    function payFees(uint256 value) internal returns(uint256) {
        uint256 devFee = getDevFee(value);
        uint256 marketingFee = getMarketingFee(value);
        uint256 webAuthFee = getWebAuthFee(value);
        uint256 teamFee = getTeamFee(value);

        developerAddress.transfer(devFee);
        marketingTeamAddress.transfer(marketingFee);
        projectTeamAddress.transfer(webAuthFee);
        webAuthAddress.transfer(teamFee);

        return devFee;
    }

    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) private pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN, bs), SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN, rs), SafeMath.mul(PSNH, rt)), rt)));
    }
    
    function calculateKryptoniteell(uint256 Kryptonite) public view returns(uint256) {
        return calculateTrade(Kryptonite, totalKryptonite, address(this).balance);
    }
    
    function calculateKryptoniteBuy(uint256 ethCost, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(ethCost, contractBalance, totalKryptonite);
    }
    
    function calculateKryptoniteBuySimple(uint256 ethCost) public view returns(uint256) {
        return calculateKryptoniteBuy(ethCost, address(this).balance);
    }
    
    function getDevFee(uint256 amount) private pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, developerFee), PERCENTAGE_DIVISOR);
    }

    function getMarketingFee(uint256 amount) private pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, marketingTeamFee), PERCENTAGE_DIVISOR);
    }
    
    function getWebAuthFee(uint256 amount) private pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, webTeamFee), PERCENTAGE_DIVISOR);
    }

    function getTeamFee(uint256 amount) private pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, projectTeamFee), PERCENTAGE_DIVISOR);
    }

    function openMines() public payable onlyOwner {
        require(totalKryptonite == 0);
        marketInitialized = true;
        totalKryptonite = TOTAL_KRYPTONITE_COUNT;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyMiners(address myAddress) public view returns(uint256) {
        return KryptoniteMiners[myAddress];
    }
    
    function getMyKryptonite(address myAddress) public view returns(uint256) {
        return SafeMath.add(ownedKryptonite[myAddress], getKryptoniteSinceLastHarvest(myAddress));
    }
    
    function getKryptoniteSinceLastHarvest(address myAddress) public view returns(uint256) {
        uint256 secondsPassed = min(Kryptonite_TO_LAUNCH_MINER, SafeMath.sub(block.timestamp, lastOwnerHarvest[myAddress]));
        return SafeMath.mul(secondsPassed, KryptoniteMiners[myAddress]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}