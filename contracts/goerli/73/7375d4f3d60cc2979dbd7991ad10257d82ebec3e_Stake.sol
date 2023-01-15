/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;
// import "./IERC20.sol";
// import "./Ownable.sol";
// import "./SafeMath.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
   
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    //returns owner
    function owner() public view virtual returns (address) {
        return _owner;
    }
    //check if caller is owner
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }
    //give ownership to null address after this no function with only owner will be accessible
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    //transfer ownership to someone else
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}
contract Stake is Ownable {
    
    
    IERC20 public tokenContract; //token contract
    
//    using SafeMath for uint256;
    
    bool isContractOpen;
    uint256 deployTimestamp;
    
    struct User {
        address userAddress;
        uint256 referralBalance;
        bool    isPrivateInvestor;
    }
    
    struct UserStake {
        address userAddress;
        uint256 amount;
        uint256 startTimeStamp;
        uint256 lockTime; // 12 months or 24 months in seconds;
        uint8 lockChoice;
        uint256 redemptionAllowedAfter;
        uint256 lastRewardTimeStamp;
        uint256 interestClaimed;
        address refereeAddress;
        bool    stakeOpen;
    }
    
    mapping (uint8=>uint256) lockTimes;                 //lock choic to locktime
    mapping (address=>User) usersList;                  //address of user to user struct
    mapping (uint256=>UserStake) stakesList;            //unique stake id to userstake struct
    mapping (address => uint256[]) userStakes;          //address of user to multiple stake id owned
    mapping (uint8=>uint256) interestRates;             //choice to interest 
    mapping (address=>uint256) userTotalStakeBalance;   //all stakes done for one user

    
    uint256 stakeCount; //unique stake id
    
    uint256 public totalTokensStaked; //total tokes staked till date
    
    uint256 thrityDaysInSeconds;
    uint256 THIRTY_DAYS_SECONDS;
    uint256 threeYearsInSeconds;
    uint256 thresHoldToMaintain;
    uint256 minStakeAmount;
    uint256 maxStakeAmount;
    
    bool emergencyWithdrwalEnabled;
    
    event InvestorListUpdated(address investorAddress,bool updateType);
    event ReferralClaimed(address indexed userAddress,uint256 amount);
    event ReferralAwarded(address indexed userAddress,uint256 amount);
    event RewardsClaimed(address indexed userAddress,uint256 amount);
    event Unstaked(address indexed userAddress,uint256 stakeId,uint256 amount);
    event StakeRedeemed(address indexed userAddress,uint256 stakeId,uint256 amount);
    event ContractStatusChanged(bool status,address indexed updatedBy);

    // constructor (IERC20 _tokenContractAddress) public {
    //     tokenContract = _tokenContractAddress;
    // }

    constructor(address _tokenContractAddress) {
        
        tokenContract = IERC20(_tokenContractAddress);
        
        lockTimes[0] = 3600; //need to replace with correct values later;
        lockTimes[1] = 7200;
        lockTimes[2] = 14400;
        
        interestRates[0] = 2;
        interestRates[1] = 3;
        interestRates[2] = 4;
        
        thrityDaysInSeconds =300;
        THIRTY_DAYS_SECONDS = 300;
        threeYearsInSeconds = 10000;
        thresHoldToMaintain = 4000000;
        minStakeAmount =0;
        maxStakeAmount = 4000000*(1 ether/1 wei);
        isContractOpen = true;
        deployTimestamp = block.timestamp;
        
        emergencyWithdrwalEnabled = false;
        
    }
    
    
    function updateContractStatus(bool _contractStatus) public onlyOwner{
        isContractOpen = _contractStatus;
        emit ContractStatusChanged(_contractStatus,msg.sender);
    }
    
    
    function enableEmergencyWithdrawl() public onlyOwner {
        emergencyWithdrwalEnabled = true;
    }
    
    /**
     * @dev updates a particular address as investor or not
     * 
     * Emits an {InvestorListUpdated} event indicating the update.
     *
     * Requirements:
     *
     * - `sender` must be admin.
     */
    
    function updateInvestorStatus(address _investorAddress,bool updateType) public onlyOwner {
        
        if(usersList[_investorAddress].userAddress == address(0)){
            usersList[_investorAddress] = User(_investorAddress,0,true);
        }
        usersList[_investorAddress].isPrivateInvestor = updateType;
        
        emit InvestorListUpdated(_investorAddress,updateType);
    }
    
    
    /**
     * @dev Transfers the referral balance amount to user
     * 
     * Emits an {ReferralClaimed} event indicating the update.
     *
     * Requirements:
     *
     * - `sender` must have referralBalance of more than 0.
     */
    function claimReferral() public {
        
        require(usersList[msg.sender].referralBalance > 0,'No referral balance');
        require(transferFunds(msg.sender,usersList[msg.sender].referralBalance));
        
        usersList[msg.sender].referralBalance = 0;
        
        emit ReferralClaimed(msg.sender,usersList[msg.sender].referralBalance);
    }
    
    event Staked(address indexed userAddress,uint256 stakeId,uint256 amount);
    function createStake(uint256 amount,uint8 lockChoice,address refereeAddress) public returns(uint256 stakeId){
        
        require(isContractOpen,"Staking is closed,please contact support");
        require(amount>minStakeAmount && amount<maxStakeAmount, "Error:: Amount out of bounds");
        //require(amount<maxStakeAmount);
        
        if(usersList[msg.sender].userAddress == address(0)){
            usersList[msg.sender] = User(msg.sender,0,false);
        }
        // Check if token owner has allowance for this contract.
        require(tokenContract.transferFrom(msg.sender,address(this),amount),'Token tranfer to contract not completed');
        stakesList[stakeCount++] = UserStake(msg.sender,amount,block.timestamp,lockTimes[lockChoice],lockChoice,block.timestamp+lockTimes[lockChoice],block.timestamp,0,refereeAddress,true);
        userStakes[msg.sender].push(stakeCount-1);
        userTotalStakeBalance[msg.sender] += amount;
        totalTokensStaked += amount;
        
        if(msg.sender != refereeAddress){
            awardReferral(refereeAddress,(amount*10)/100);
        }
        emit Staked(msg.sender,stakeCount-1,amount);
        return stakeCount-1;
    }
    
    function unStake(uint256 _stakeId) public returns (bool){
        
        require(stakesList[_stakeId].stakeOpen);
        require(!usersList[msg.sender].isPrivateInvestor);
        require(stakesList[_stakeId].userAddress == msg.sender);
        
        require(awardRewards(_stakeId));
        
        stakesList[_stakeId].stakeOpen = false;
        stakesList[_stakeId].lockTime = block.timestamp;
        stakesList[_stakeId].redemptionAllowedAfter += (block.timestamp +thrityDaysInSeconds);
        userTotalStakeBalance[msg.sender] -= (stakesList[_stakeId].amount);
        totalTokensStaked -= (stakesList[_stakeId].amount);
        emit Unstaked(stakesList[_stakeId].userAddress,_stakeId,stakesList[_stakeId].amount);
        return true;
    }
    
    
    function redeem(uint256 _stakeId) public returns (bool){
        
        require(stakesList[_stakeId].userAddress == msg.sender);
    
        require(block.timestamp>stakesList[_stakeId].redemptionAllowedAfter);
        
        if(stakesList[_stakeId].stakeOpen){
            require(awardRewards(_stakeId));
            userTotalStakeBalance[msg.sender] -= (stakesList[_stakeId].amount);
            totalTokensStaked -= (stakesList[_stakeId].amount);

        }
        
        stakesList[_stakeId].stakeOpen = false;
        
        require(transferFunds(stakesList[_stakeId].userAddress,stakesList[_stakeId].amount));
        
        emit StakeRedeemed(stakesList[_stakeId].userAddress,_stakeId,stakesList[_stakeId].amount);
        return true;
    }
    
    function claimRewards(uint256 _stakeId) public returns (bool){
        require(stakesList[_stakeId].stakeOpen);
        require(stakesList[_stakeId].userAddress == msg.sender);
        require(block.timestamp >stakesList[_stakeId].lastRewardTimeStamp+thrityDaysInSeconds);
        require(awardRewards(_stakeId));
        return true;
    }
    
    
    function userDetails(address _userAddress) public view returns (uint256[] memory,uint256,bool,uint256){
        return(userStakes[_userAddress],usersList[_userAddress].referralBalance,usersList[_userAddress].isPrivateInvestor,userTotalStakeBalance[_userAddress]);   
    }
    
    function getStakeDetails(uint256 _stakeId) public view returns(address userAddress,uint256 amount,uint256 startTimeStamp,uint256 lockChoice,uint256 lockTime,uint256 redemptionAllowedAfter,uint256 lastRewardTimeStamp,uint256 interestClaimed,address refereeAddress,bool stakeOpen){
        UserStake memory temp = stakesList[_stakeId];
        
        return (temp.userAddress,temp.amount,temp.startTimeStamp,temp.lockChoice,temp.lockTime,temp.redemptionAllowedAfter,temp.lastRewardTimeStamp,temp.interestClaimed,temp.refereeAddress,temp.stakeOpen);
    }
    
    
    function getPendingInterestDetails(uint256 _stakeId) public view returns(uint256 amount){
        
        UserStake memory temp = stakesList[_stakeId];
        //require(temp.lastRewardTimeStamp<temp.redemptionAllowedAfter);
        uint256 monthDiff;
        if(block.timestamp>stakesList[_stakeId].redemptionAllowedAfter){
            monthDiff = (block.timestamp-stakesList[_stakeId].redemptionAllowedAfter)/thrityDaysInSeconds;   
        }
        uint256 interesMonths = (block.timestamp-temp.lastRewardTimeStamp)/thrityDaysInSeconds-monthDiff;
        
        if(interesMonths>0){
            return (temp.amount*interesMonths*interestRates[temp.lockChoice])/100;
        }
        return 0;
        
    }
    
    
    function awardRewards(uint256 _stakeId) internal returns (bool){
        
        uint256 rewards = getPendingInterestDetails(_stakeId);
        if(rewards>0){
            stakesList[_stakeId].lastRewardTimeStamp = block.timestamp;
            require(transferFunds(stakesList[_stakeId].userAddress,rewards));
            emit RewardsClaimed(stakesList[_stakeId].userAddress,rewards);
        }
        return true;
    }
    
    function awardReferral(address _refereeAddress,uint256 amount) internal returns (bool){
        
        if(_refereeAddress == address(this))
        return false;
        if(userTotalStakeBalance[_refereeAddress] <= 0)
        return false;
        
        usersList[_refereeAddress].referralBalance +=(amount);
        
        emit ReferralAwarded(_refereeAddress,amount);
        return true;
    }
    
    function  transferFunds(address _transferTo,uint256 amount) internal returns (bool){
        
        require(tokenContract.balanceOf(address(this)) > amount,'Not enough balance in contract to make the transfer');
        require(tokenContract.transfer(_transferTo,amount));
        
        return true;
    }
    
    
    function redeemTokens(uint256 amount)public onlyOwner{
        
        uint256 tokenBalance = tokenContract.balanceOf(address(this));
        require(amount<=tokenBalance,"not enough balance");
        if(block.timestamp>deployTimestamp+threeYearsInSeconds){
            require(tokenContract.transfer(msg.sender,amount));
        }else{
            require(amount<=(tokenBalance-thresHoldToMaintain),"not enough balance to maintian threshold");
            require(tokenContract.transfer(msg.sender,amount));

        }
    }
    
    
    function emergencyWithdraw(uint256 _stakeId) public {
        require(stakesList[_stakeId].userAddress == msg.sender);
        require(emergencyWithdrwalEnabled,"Emergency withdraw not enabled");
        require(stakesList[_stakeId].stakeOpen,"Stake status should be open");
        
        stakesList[_stakeId].stakeOpen = false;
        
        require(transferFunds(stakesList[_stakeId].userAddress,stakesList[_stakeId].amount));
        
        emit StakeRedeemed(stakesList[_stakeId].userAddress,_stakeId,stakesList[_stakeId].amount);
    }
    
    
    function withdrawAdditionalFunds(uint256 amount) public onlyOwner {
        
        uint256 tokenBalance = tokenContract.balanceOf(address(this));
        require(amount< (tokenBalance-totalTokensStaked));
        require(transferFunds(owner(),amount));
        
    }
    
    
}