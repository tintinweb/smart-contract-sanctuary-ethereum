/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    
    constructor()  {}

    function _msgSender() internal view returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Pausable is Context {
    
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract penkyStake is Pausable, Ownable {

    address public penkyToken;
    uint256 public APYpercent;
    uint256 public lastStakeID;
    uint256 public perYear = 365 ;
    uint256 public perDay = 1 days;

    struct UserInfo{
        address userAddress;
        uint256 amount;
        uint256 APYpercentage;//if 1% = 10 
        uint256 depositTime;
        uint256 lastClaimTime;
        uint256 rewardEndTime;
        uint256 rewardAmount;
        bool unStake;
    }

    struct StakeIDs{
        uint256[] userStakeID;
    }

    mapping (address => mapping ( uint256 => UserInfo )) public userDetails;
    mapping (address => StakeIDs ) internal userStake;

    event Deposit(address indexed caller, uint256 depositAmount, uint256 depositTime);
    event Withdraw(address indexed caller, uint256 withdrawAmount, uint256 withdrawTime);
    event ClaimAmount(address indexed caller, uint256 ClaimAmount, uint256 claimTime);

    constructor(address _penky, uint256 _APYpercent) {
        penkyToken = _penky;
        APYpercent = _APYpercent;
    }

    function pause() external onlyOwner{
        _pause();
    }

    function unpause() external onlyOwner{
        _unpause();
    }

    function deposit(uint256 _tokenAmount) external {
        lastStakeID++;
        UserInfo storage user = userDetails[_msgSender()][lastStakeID];
        
        user.userAddress = _msgSender();
        user.amount +=  _tokenAmount;
        user.depositTime = block.timestamp;
        user.lastClaimTime = block.timestamp;
        user.APYpercentage = APYpercent;
        user.rewardEndTime = block.timestamp + (perYear * perDay);
        userStake[_msgSender()].userStakeID.push(lastStakeID);

        IERC20(penkyToken).transferFrom(_msgSender(), address(this), _tokenAmount);

        emit Deposit(_msgSender(),_tokenAmount,block.timestamp);
    }

    function viewStakeID(address _account) external view returns(uint[] memory){
        return userStake[_account].userStakeID;
    }

    function withdraw(uint256 _stakeID) external {
        UserInfo storage user = userDetails[_msgSender()][_stakeID];
        require(!user.unStake,"user already unstaked");
        claimReward(_stakeID);
        user.unStake = true;

        IERC20(penkyToken).transfer(_msgSender(),user.amount);

        emit Withdraw(_msgSender(),user.amount,block.timestamp);
    }

    function claimReward(uint256 _stakeID) public {
        UserInfo storage user = userDetails[_msgSender()][_stakeID];
        require(!user.unStake,"user already claimed");
        uint reward = pendingReward(user.userAddress, _stakeID);
        user.lastClaimTime = block.timestamp;
        if(user.rewardEndTime < block.timestamp) { user.lastClaimTime = user.rewardEndTime; }
        IERC20(penkyToken).transfer(user.userAddress, reward);

        emit ClaimAmount(user.userAddress,reward,block.timestamp);
    }

    function pendingReward(address _account, uint256 _stakeID) public view returns(uint256 ) {
        UserInfo storage user = userDetails[_account][_stakeID];

        if(user.lastClaimTime == user.rewardEndTime || user.unStake){
            return 0;
        }
        uint endTime = block.timestamp;
        if(user.rewardEndTime < block.timestamp) {endTime = user.rewardEndTime; }

        uint stakeDays = endTime - user.lastClaimTime;
        uint percentage = user.APYpercentage * 1e18 / perYear / 1000;
        return user.amount * stakeDays * percentage / 1e18 / perDay;
    }

    function setPenkyToken(address _penky) external onlyOwner{
        penkyToken = _penky;
    }

    function setTime(uint _perYear, uint _perDays) external onlyOwner {
        perYear = _perYear;
        perDay = _perDays;
    }

    function setAPYpercentage(uint256 _APYpercent) external onlyOwner {
        APYpercent =  _APYpercent;
    }

    function recover(address _tokenAddress, address _to, uint256 _amount) external onlyOwner  {
        if(_tokenAddress == address(0x0)){
            payable(_to).transfer(_amount);
        }   else {
            IERC20(_tokenAddress).transfer(_to,_amount);
        }
    }

}