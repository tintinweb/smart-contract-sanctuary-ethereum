/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

}


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    

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

contract Presale is Ownable {

    struct TokenDetails {
        uint256 depositLimit;
        uint256 price;
    }

    mapping (address => TokenDetails) public tokenDetails;
    mapping (address => uint256) public tokenClaimable;

    mapping (address => bool) public isValidToken;
    mapping (address => bool) public isWhitelisted;
    mapping (address => bool) public isBlacklisted;
    mapping (address => mapping (address => uint256)) public userTokenDepositAmount; 
    mapping (address => uint256) public userEthDepositAmount;

    address[] public depositers;

    uint256 public presaleStartTime;
    uint256 public presaleEndTime;

    uint256 public ethDepositLimit;
    uint256 public ethDepositPrice;
    
    bool public isPresaleActive = false;
    bool public isPresalePublic = true;

    bool lock_= false;

    modifier Lock {
        require(!lock_, "Process is locked");
        lock_ = true;
        _;
        lock_ = false;
    }

    event SetEthDepositPrice (uint256 _price);
    event SetPresaleStartTime (uint256 _startTime);
    event SetPresaleEndTime (uint256 _endTime);
    event SetEthDepositLimit (uint256 _limit);


    // deposit token using this function
    function depositToken (address _token, uint256 _amount) public Lock {
        require(isPresaleActive, "Presale is not active");
        require(isPresalePublic || isWhitelisted[msg.sender], "You are not whitelisted");
        require(!isBlacklisted[msg.sender], "You are blacklisted");
        require(block.timestamp >= presaleStartTime && block.timestamp <= presaleEndTime, "Presale is not active");
        
        require(isValidToken[_token], "Invalid token");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        require(userTokenDepositAmount[msg.sender][_token] + _amount <= tokenDetails[_token].depositLimit, "Deposit limit exceeded");

        if (tokenClaimable[msg.sender] == 0) depositers.push(msg.sender);

        userTokenDepositAmount[msg.sender][_token] += _amount;
        tokenClaimable[msg.sender] += ((_amount) * (tokenDetails[_token].price)) / (10 ** (IERC20(_token).decimals()));
        
    }

    // deposit eth using this function
    function depositEth () public payable Lock {
        require(isPresaleActive, "Presale is not active");
        require(isPresalePublic || isWhitelisted[msg.sender], "You are not whitelisted");
        require(!isBlacklisted[msg.sender], "You are blacklisted");
        require(block.timestamp >= presaleStartTime && block.timestamp <= presaleEndTime, "Presale is not active");
        
        require(msg.value > 0, "Invalid amount");
        require(userEthDepositAmount[msg.sender] + msg.value <= ethDepositLimit, "Deposit limit exceeded");

        if (tokenClaimable[msg.sender] == 0) depositers.push(msg.sender);
        userEthDepositAmount[msg.sender] += msg.value;
        tokenClaimable[msg.sender] += (msg.value * ethDepositPrice) / (10 ** 18);

        (bool success, ) = payable(address(this)).call{value: msg.value}("");
        success;
    }

    // read only functions

    // get all depositers and their claimable amount
    function getDepositors () public view returns (address[] memory, uint256[] memory) {
        address[] memory _depositers = new address[](depositers.length);
        uint256[] memory _claimable = new uint256[](depositers.length);

        for (uint256 i = 0; i < depositers.length; i++) {
            _depositers[i] = depositers[i];
            _claimable[i] = tokenClaimable[depositers[i]];
        }

        return (_depositers, _claimable);
    }

    // Only owner functions here

    // set presale start time
    function setPresaleStartTime (uint256 _startTime) public onlyOwner {
        presaleStartTime = _startTime;
        emit SetPresaleStartTime(_startTime);
    }

    // set presale end time
    function setPresaleEndTime (uint256 _endTime) public onlyOwner {
        presaleEndTime = _endTime;
        emit SetPresaleEndTime(_endTime);
    }

    // set presale status
    function setPresaleStatus (bool _status) public onlyOwner {
        isPresaleActive = _status;
    }

    // set presale public
    function setPresalePublic (bool _status) public onlyOwner {
        isPresalePublic = _status;
    }

    // set token details
    function setTokenDetails (address _token, uint256 _depositLimit, uint256 _price) public onlyOwner {
        tokenDetails[_token] = TokenDetails(_depositLimit, _price);
        isValidToken[_token] = true;
    }

    // whitelist user
    function whitelistUser (address _user) public onlyOwner {
        isWhitelisted[_user] = true;
    }

    // blacklist user
    function blacklistUser (address _user, bool _flag) public onlyOwner {
        isBlacklisted[_user] = _flag;
    }

    // whitelist users
    function whitelistUsers (address[] memory _users, bool _flag) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            isWhitelisted[_users[i]] = _flag;
        }
    }

    // blacklist users
    function blacklistUsers (address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            isBlacklisted[_users[i]] = true;
        }
    }

    // set eth deposit limit
    function setEthDepositLimit (uint256 _limit) public onlyOwner {
        ethDepositLimit = _limit;
        emit SetEthDepositLimit(_limit);
    }

    // set eth deposit price
    function setEthDepositPrice (uint256 _price) public onlyOwner {
        ethDepositPrice = _price;
        emit SetEthDepositPrice(_price);
    }

    // this function is to withdraw BNB
    function withdrawEth () external onlyOwner returns (bool) {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{
            value: balance
        }("");
        return success;
    }

    // this function is to withdraw tokens
    function withdrawBEP20 (address _tokenAddress) external onlyOwner returns (bool) {
        IERC20 token = IERC20 (_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        bool success = token.transfer(msg.sender, balance);
        return success;
    }

}