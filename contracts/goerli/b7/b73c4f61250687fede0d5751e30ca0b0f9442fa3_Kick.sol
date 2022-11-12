/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

interface Random {
    function getRandom(uint256 _modulus) external returns (uint256);
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract Kick is Ownable{

    struct User {
        uint256 goalScored;
        uint256 totalTries;
        uint256 goalMissed;
    }

    IERC20 public token;
    address public storeAddress;
    address private randomGeneratorAddress;

    uint256 public winningMultiple;
    uint256 public winningFactor;
    uint256 public rewardNumerator;
    uint256 public rewardDenominator;
    uint256 public maxBet;

    mapping (address => User) public userData;

    constructor () {}

    function getRandomNumber() public returns (bool) {
        Random random = Random(storeAddress);
        uint256 _randomNumber = random.getRandom(winningMultiple);
        if (_randomNumber <= winningFactor){
            return true;
        }else {
            return false;
        }
    }

    function kick(uint256 amount) public returns (bool) {
        require(token.balanceOf(msg.sender) >= amount, "You don't have enough tokens to play");
        require(amount <= maxBet, "You can't bet more than maxBet");
        require(token.allowance(msg.sender, address(this)) >= amount, "You need to approve the contract to spend your tokens");

        token.transferFrom(msg.sender, storeAddress, amount);
        bool _isWin = getRandomNumber();

        if (_isWin){
            userData[msg.sender].goalScored += 1;
            token.transferFrom(storeAddress, msg.sender, (amount* rewardNumerator) / rewardDenominator);
        }else {
            userData[msg.sender].goalMissed += 1;
        }

        userData[msg.sender].totalTries += 1;
        return _isWin;
    }

    // All onlyOwner functions here

    function setToken (address _token) public onlyOwner {
        token = IERC20(_token);
    }

    function setStoreAddress (address _storeAddress) public onlyOwner {
        storeAddress = _storeAddress;
    }

    function setWinningMultiple (uint256 _winningMultiple) public onlyOwner {
        winningMultiple = _winningMultiple;
    }

    function setWinningFactor (uint256 _winningFactor) public onlyOwner {
        winningFactor = _winningFactor;
    }

    function setRewardNumerator (uint256 _rewardNumerator) public onlyOwner {
        rewardNumerator = _rewardNumerator;
    }

    function setRewardDenominator (uint256 _rewardDenominator) public onlyOwner {
        rewardDenominator = _rewardDenominator;
    }

    function setMaxBet (uint256 _maxBet) public onlyOwner {
        maxBet = _maxBet;
    }

    function setRandomGeneratorAddress (address _randomGeneratorAddress) public onlyOwner {
        randomGeneratorAddress = _randomGeneratorAddress;
    }

    // Emergency functions

    // this function is to withdraw BNB sent to this address by mistake
    function withdrawEth () external onlyOwner returns (bool) {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{
            value: balance
        }("");
        return success;
    }

    // this function is to withdraw BEP20 tokens sent to this address by mistake
    function withdrawBEP20 (address _tokenAddress) external onlyOwner returns (bool) {
        IERC20 _token = IERC20 (_tokenAddress);
        uint256 balance = _token.balanceOf(address(this));
        bool success = _token.transfer(msg.sender, balance);
        return success;
    }
    
}