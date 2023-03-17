/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

// SPDX-License-Identifier: MIT

/**
Welcome to the Reserved Parking!
An exclusive Club for OGs on the Blockchain!
Choose which of 5 levels you want to Park on and enjoy the benefits of our multi-tier protocol!
Show off your best wheels while hanging out in the members arena!

https://twitter.com/Reserve_Parking
*/

pragma solidity ^0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Pausable is Context {
    
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
 
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

interface Token {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (uint256);    
}

contract L2Parking is Pausable, Ownable, ReentrancyGuard {

    Token ParkToken;

    uint256 public planDuration = 129600;

    uint256 _planExpired = 360000000;

    uint8 public interestRate = 2;
    uint256 public planExpired;
    uint8 public totalStakers;

    struct StakeInfo {        
        uint256 startTS;
        uint256 endTS;        
        uint256 amount; 
        uint256 claimed;       
    }
    
    event Staked(address indexed from, uint256 amount);
    event Claimed(address indexed from, uint256 amount);
    
    mapping(address => StakeInfo) public stakeInfos;
    mapping(address => bool) public addressStaked;


    constructor(Token _tokenAddress) {
        require(address(_tokenAddress) != address(0),"Token Address cannot be address 0");                
        ParkToken = _tokenAddress;        
        planExpired = block.timestamp + _planExpired;
        totalStakers = 0;
    }    

    function transferToken(address to,uint256 amount) external onlyOwner{
        require(ParkToken.transfer(to, amount), "Token transfer failed!");  
    }

    function claimReward() external returns (bool){
        require(addressStaked[_msgSender()] == true, "You have not Parked!");
        require(stakeInfos[_msgSender()].endTS < block.timestamp, "Parking in progress!");
        require(stakeInfos[_msgSender()].claimed == 0, "Already Claimed!");

        uint256 stakeAmount = stakeInfos[_msgSender()].amount;
        uint256 totalTokens = stakeAmount + (stakeAmount * interestRate / 100);
        stakeInfos[_msgSender()].claimed == totalTokens;
        ParkToken.transfer(_msgSender(), totalTokens);

        emit Claimed(_msgSender(), totalTokens);

        return true;
    }

    function getTokenExpiry() external view returns (uint256) {
        require(addressStaked[_msgSender()] == true, "You have not Parked!");
        return stakeInfos[_msgSender()].endTS;
    }

    function stakePark(uint256 stakeAmount) external payable whenNotPaused {
        require(stakeAmount >0, "Park in the right slot!");
        require(block.timestamp < planExpired , "Slot Expired!");
        require(addressStaked[_msgSender()] == false, "You have already Parked!");
        require(ParkToken.balanceOf(_msgSender()) >= stakeAmount, "Insufficient Park Balance");
        
           ParkToken.transferFrom(_msgSender(), address(this), stakeAmount);
            totalStakers++;
            addressStaked[_msgSender()] = true;

            stakeInfos[_msgSender()] = StakeInfo({                
                startTS: block.timestamp,
                endTS: block.timestamp + planDuration,
                amount: stakeAmount,
                claimed: 0
            });
        
        emit Staked(_msgSender(), stakeAmount);
    }    


    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}