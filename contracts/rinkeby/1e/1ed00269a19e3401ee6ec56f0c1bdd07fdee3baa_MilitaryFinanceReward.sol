/**
 *Submitted for verification at Etherscan.io on 2022-03-31
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

interface NFTAddress{
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
}

interface MIL {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract MilitaryFinanceReward is Ownable{
    using SafeMath for uint256;
    NFTAddress public NFT;
    MIL public mil;

    bool isActive = false;

    function setWithdrawActive() external onlyOwner{
        isActive = true;
    }

    constructor(NFTAddress _NFT, MIL _mil){
        NFT = _NFT;
        mil = _mil;
    }

    struct UserInfo{
        uint256 availableTokens;
        uint256 time;
        uint256 remainingTokens;
    }

    mapping(address => uint256) public totalTokens;
    mapping(address => UserInfo) public users;
    mapping(address => bool) private hasWithdrawn;

    function setTokenPerAddress(address _address, uint256 _amountOfTokens) external onlyOwner{
        totalTokens[_address] = _amountOfTokens;
    }

    uint256 vestingStartTime;
    uint256 vestingPeriod = 604800 seconds;
    uint256 tokensPerVesting = 20;
    uint256 tokensPerNFT = 10;

    function unstake(uint256 _amount) public{
        require(isActive == true, "Withrawal is paused!");
        require(NFT.balanceOf(msg.sender) > 0, "You don't have any NFT");
        require(block.timestamp > vestingStartTime + vestingPeriod, "Your vesting period is not over yet!");
        uint256 getTokens = tokenAmountPerVesting(msg.sender);
        require(_amount <= getTokens, "You can not unstake more than scheduled!");
        mil.transfer(msg.sender, _amount);
        totalTokens[msg.sender] -= _amount;
        hasWithdrawn[msg.sender] = true;
        
    }

    function setTotalTokens(address _user) private{
        uint256 tokens = calculateMIL(_user);
        totalTokens[_user] = tokens;


    }

    function tokenAmountPerVesting(address _user) public view returns(uint256){
        uint256 totalToken = calculateMIL(_user);
        uint256 tokenPercent = (totalToken.mul(10**18)).div(tokensPerVesting);
        return tokenPercent;
    }
    
    function startVestTime() external onlyOwner{
        vestingStartTime = block.timestamp;
    }

    function setVestingPeriod(uint256 _time) external onlyOwner{
        vestingPeriod = _time;
    }

    function setTokensPerVesting(uint256 _amountOfTokens) external onlyOwner{
        tokensPerVesting = _amountOfTokens;
    }

    function calculateMIL(address _user) private view returns(uint256){
        uint256 numberOfNFTs = NFT.balanceOf(_user);
        return tokensPerNFT.mul(numberOfNFTs)*10**18;
    }

    function getContractTokenBalance() external view onlyOwner returns(uint256){
        return mil.balanceOf(address(this));
    }

    function transferMILFromContract() external onlyOwner{
        require(mil.balanceOf(address(this)) > 0, "No more MIL tokens in DApp!");
        mil.transfer(owner(), mil.balanceOf(address(this)));
    }
}