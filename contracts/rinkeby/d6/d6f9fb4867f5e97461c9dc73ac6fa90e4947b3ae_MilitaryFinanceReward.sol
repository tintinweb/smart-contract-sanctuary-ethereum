/**
 *Submitted for verification at Etherscan.io on 2022-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

interface IERC721{
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract MilitaryFinanceReward is Ownable{
    using SafeMath for uint256;
    IERC721 public NFT;
    IERC20 public MIL;

    bool isActive = false;

    function setWithdrawState( bool _state) external onlyOwner{
        isActive = _state;
    }

    constructor(IERC721 _NFT, IERC20 _mil){
        NFT = _NFT;
        MIL = _mil;
    }
   
    uint256 public vestingCounter;
    mapping(address => uint256) public unstakeCounter;

    uint256 vestingStartTime;
    uint256 vestingPeriod = 15 seconds;
    uint256 tokensPerVesting = 0;
    uint256 tokensPerNFT = 100*10**18;
    mapping(address => uint256) public unstakedAmount;

    function unstake(uint256 _amount) public {
        require(unstakeCounter[msg.sender] < vestingCounter, "You've already withdrwan!");
        require(MIL.balanceOf(address(this)) > 0, "No more MIL tokens in DApp!");
        require(isActive == true, "Withrawal is paused!");
        require(NFT.balanceOf(msg.sender) > 0, "You don't have any NFT");
        require(block.timestamp > vestingStartTime + vestingPeriod, "Your vesting period is not over yet!");
        uint256 getTokens = tokenAmountPerVesting(msg.sender);
        require(_amount <= getTokens, "You can not unstake more or less than available!");

        MIL.transfer(msg.sender, _amount);
        unstakedAmount[msg.sender] += _amount;
        unstakeCounter[msg.sender] += 1;
    }

    function tokenAmountPerVesting(address _user) public view returns(uint256){
        uint256 tokens;
        if(block.timestamp> vestingStartTime+vestingPeriod){
            tokens = tokensPerVesting*NFT.balanceOf(_user)*(vestingCounter - unstakeCounter[_user]);
        }
        return tokens*10**18;
    }

    function remainingTokens(address _user) public view returns(uint256){
        uint256 numberOfNFTs = NFT.balanceOf(_user);
        return (tokensPerNFT.mul(numberOfNFTs)).sub(unstakedAmount[_user]);
    }
    
    function startVestTime() external onlyOwner{
        vestingStartTime = block.timestamp;
        vestingCounter += 1;
    }

    function setVestingPeriod(uint256 _time) external onlyOwner{
        vestingPeriod = _time;
    }

    function setTokensPerVesting(uint256 _amountOfTokens) external onlyOwner{
        tokensPerVesting = _amountOfTokens;
    }


    function getContractTokenBalance() external view onlyOwner returns(uint256){
        return MIL.balanceOf(address(this));
    }

    function transferMILFromContract() external onlyOwner{
        require(MIL.balanceOf(address(this)) > 0, "No more MIL tokens in DApp!");
        MIL.transfer(owner(), MIL.balanceOf(address(this)));
    }
}