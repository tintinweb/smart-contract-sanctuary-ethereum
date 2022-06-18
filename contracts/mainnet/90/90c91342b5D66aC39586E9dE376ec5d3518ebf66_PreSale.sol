/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

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

library SafeMath {

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
}

abstract contract Ownable {

    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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

contract PreSale is Ownable {

    using SafeMath for uint256;

    struct UserInfo {
        address buyer;
        uint256 ptokenAmount;
    }

    IERC20 public PTOKEN;
    uint256 public PTOKEN_DECIMALS = 9;
    IERC20 public DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address public Recipient;

    uint256 public tokenRatePerEth = 100; // 100 * (10 ** decimals) PTOKEN per DAI
    uint256 public minDAILimit = 100 ether;
    uint256 public maxDAILimit = 2000 ether;
    uint256 public softCap = 100000 ether;
    uint256 public hardCap = 200000 ether;
    uint256 public totalRaisedDAI = 0; // total DAI raised by sale
    uint256 public totaltokenSold = 0;
    uint256 public startTime;
    uint256 public endTime;
    bool public claimOpened;
    bool public contractPaused;

    mapping(address => uint256) private _totalPaid;
    mapping(address => UserInfo) public userinfo;
    event Deposited(uint amount);
    event Claimed(address receiver, uint amount);

    constructor(uint256 _startTime, uint256 _endTime) {
        require(_startTime > block.timestamp, 'past timestamp');
        require(_endTime > _startTime, 'wrong timestamp');
        startTime = _startTime;
        endTime = _endTime;
        Recipient = msg.sender;
    }

    modifier checkIfPaused() {
        require(contractPaused == false, "contract is paused");
        _;
    }

    function setPresaleToken(address tokenaddress) external onlyOwner {
        require( tokenaddress != address(0) );
        PTOKEN = IERC20(tokenaddress);
    }

    function setRecipient(address recipient) external onlyOwner {
        Recipient = recipient;
    }

    function setTokenRatePerEth(uint256 rate) external onlyOwner {
        tokenRatePerEth = rate;
    }

    function setMinDAILimit(uint256 amount) external onlyOwner {
        minDAILimit = amount;    
    }

    function setMaxDAILimit(uint256 amount) external onlyOwner {
        maxDAILimit = amount;    
    }
    
    function updateCap(uint256 _hardcap, uint256 _softcap) external onlyOwner {
        softCap = _softcap;
        hardCap = _hardcap;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        require(_startTime > block.timestamp, 'past timestamp');
        startTime = _startTime;
    }

    function setEndTime(uint256 _endTime) external onlyOwner {
        require(_endTime > startTime, 'should be bigger than start time');
        endTime = _endTime;
    }

    function openClaim(address tokenaddress) external onlyOwner {
        require(!claimOpened, 'Already opened');
        claimOpened = !claimOpened;
        require( tokenaddress != address(0) );
        PTOKEN = IERC20(tokenaddress);
    }

    function togglePause() external onlyOwner returns (bool){
        contractPaused = !contractPaused;
        return contractPaused;
    }

    function deposit(uint256 amount) public checkIfPaused {
        require(block.timestamp > startTime, 'not started');
        require(block.timestamp < endTime, 'ended');
        require(totalRaisedDAI <= hardCap, 'limited cap');
        require(
                _totalPaid[msg.sender].add(amount) <= maxDAILimit
                && _totalPaid[msg.sender].add(amount) >= minDAILimit,
                "Invalid Amount"
        );
        uint256 tokenAmount = getTokensPerEth(amount);
        
        if (userinfo[msg.sender].buyer == address(0)) {
            UserInfo memory l;
            l.buyer = msg.sender;
            l.ptokenAmount = tokenAmount;
            userinfo[msg.sender] = l;
        }
        else {
            userinfo[msg.sender].ptokenAmount += tokenAmount;
        }

        totalRaisedDAI = totalRaisedDAI.add(amount);
        totaltokenSold = totaltokenSold.add(tokenAmount);
        _totalPaid[msg.sender] = _totalPaid[msg.sender].add(amount);
        DAI.transferFrom(msg.sender, Recipient, amount);
        emit Deposited(amount);
    }

    function claim() public {
        UserInfo storage l = userinfo[msg.sender];
        require(l.buyer == msg.sender, "You are not allowed to claim");
        require(claimOpened, "Claim not open yet");
        uint amount = l.ptokenAmount;
        l.ptokenAmount = 0;
        require(amount <= PTOKEN.balanceOf(address(this)), "Insufficient balance");
        PTOKEN.transfer(msg.sender, amount);
        emit Claimed(msg.sender, amount);
    }

    function getUnsoldTokens(address token, address to) external onlyOwner {
        require(block.timestamp > endTime, "You cannot get tokens until the presale is closed.");
        if(token == address(0)) {
            payable(to).transfer(address(this).balance);
        } else {
            IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)) );
        }
    }

    function getAvailableAmount(address account) external view returns ( uint256 ) {
        return maxDAILimit.sub(_totalPaid[account]);
    }

    function getTokensPerEth(uint256 amount) internal view returns(uint256) {
        return amount.mul(tokenRatePerEth).div(10**(uint256(18).sub(PTOKEN_DECIMALS)));
    }
}