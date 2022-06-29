// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
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
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function mint(address to, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract MinerPresale is Ownable {
    address public miner;
    address[2] public srcTokenAddr;

    uint256 public totalParticipants;
    uint256 public tokenPrice; // Token price in usdt
    uint256 public maxSupply;
    uint256 public soldTokens;
    address public treasury;
    mapping(address => uint256) public userContribution;
    mapping(address => uint256) public userTokenBalance;

    mapping(address => bool) public whitelistedUser;

    constructor(
        address _minerToken,
        address _usdt,
        address _dai,
        uint256 _price,
        uint256 _maxSupply,
        address _treasury
    ) {
        miner = _minerToken;
        srcTokenAddr = [_usdt, _dai];
        tokenPrice = _price;
        maxSupply = _maxSupply;
        treasury = _treasury;
    }

    modifier isWhitelisted(address _user) {
        require(whitelistedUser[_user], "User is not whitelisted");
        _;
    }

    function whitelistUser(address[] memory _user, bool _status) external onlyOwner {
        for (uint256 i; i < _user.length; i++) {
            whitelistedUser[_user[i]] = _status;
        }
    }

    function buyMiner(uint256 _srcTokenInd, uint256 _amount) external isWhitelisted(msg.sender) {
        require(maxSupply >= soldTokens + _amount, "Max Limit Reached!");

        if (userContribution[msg.sender] == 0) {
            totalParticipants += 1;
        }
        uint256 _usdtPrice = (_amount * tokenPrice) / 10**IERC20(miner).decimals();
        IERC20(srcTokenAddr[_srcTokenInd]).transferFrom(msg.sender, treasury, _usdtPrice);
        IERC20(miner).transferFrom(owner(), msg.sender, _amount);

        soldTokens += _amount;
        userTokenBalance[msg.sender] += _amount;
        userContribution[msg.sender] += _usdtPrice;
    }

    function setMaxSupply(uint256 _max) external onlyOwner {
        maxSupply = _max;
    }

    function setTreaury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setTokenPrice(uint256 _price) external onlyOwner {
        tokenPrice = _price;
    }

    function updateminer(address _token) external onlyOwner {
        miner = _token;
    }

    function removeStuckEth(address payable _account, uint256 _amount) external onlyOwner {
        _account.transfer(_amount);
    }

    function updateSrcTokenAddress(address[2] memory _tokens) external onlyOwner {
        srcTokenAddr = _tokens;
    }

    function removeStuckTokens(
        address _token,
        address _account,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).transfer(_account, _amount);
    }
}