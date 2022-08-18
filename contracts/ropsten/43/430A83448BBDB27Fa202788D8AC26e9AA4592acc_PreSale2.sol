/**
 *Submitted for verification at Etherscan.io on 2022-08-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


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

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

abstract contract Ownable is Context {

    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PreSale2 is Ownable {

    using SafeMath for uint256;

    struct UserInfo {
        address buyer;
        uint256 rctokenAmount;
    }
    // Avax Main Net
    // IERC20 public PTOKEN = IERC20(0xeE6cA573ba62f8E4f076D2Bb9DE62929d3730598);
    // IERC20 public RCTOKEN = IERC20(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664);

    // Ropsten Test Net
    IERC20 public PTOKEN = IERC20(0x227cD29aB03249f8f404bFA3775e8Ec4C3C005F1);
    IERC20 public RCTOKEN = IERC20(0xDDB43ebc3F34947C104A747a6150F4BbAA78a5eB);
    uint256 public RCTOKEN_DECIMAL = 6;
    address public Recipient = 0x6474F3960d51aE2cBE07ccf1630F1C6A3d96327E;

    uint256 public tokenPrice = 15;
    uint256 public minBuyLimit = 1 * 10 ** RCTOKEN_DECIMAL;
    uint256 public maxBuyLimit = 5000 * 10 ** RCTOKEN_DECIMAL;

    uint256 public softCap = 1000 * 10 ** RCTOKEN_DECIMAL;
    uint256 public hardCap = 150000 * 10 ** RCTOKEN_DECIMAL;

    uint256 public totalRaisedAmount = 0; // total USDC raised by sale
    uint256 public totaltokenSold = 0;

    uint256 public startTime = 1660672800;
    uint256 public endTime = 1660759200;

    bool public isPrivate = true;
    bool public contractPaused; // circuit breaker

    mapping(address => bool) public whiteListed;
    mapping(address => uint256) private _totalPaid;

    event Deposited(uint amount);
    event Claimed(address receiver, uint amount);

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

    function setTokenPrice(uint256 price) external onlyOwner {
        require(price != 0, "invalid token price");
        tokenPrice = price;
    }

    function setMinBuyLimit(uint256 amount) external onlyOwner {
        minBuyLimit = amount;    
    }

    function setMaxBuyLimit(uint256 amount) external onlyOwner {
        maxBuyLimit = amount;    
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

    function openPublic() external onlyOwner {
        require(block.timestamp > endTime, 'Presale not over yet');
        isPrivate = false;
        startTime = 1660766400;
        endTime = 1660939200;
        tokenPrice = 16;
    }

    function togglePause() external onlyOwner returns (bool){
        contractPaused = !contractPaused;
        return contractPaused;
    }

    function toggleSale() external onlyOwner returns (bool) {
        isPrivate = !isPrivate;
        return isPrivate;
    }

    function addMultipleAccountsToWhiteList(address[] calldata _accounts, bool _value) public onlyOwner {
        for(uint256 i = 0; i < _accounts.length; i++) {
            whiteListed[_accounts[i]] = _value;
        }
    }

    function deposit(uint256 amount) public checkIfPaused {
        require(block.timestamp > startTime, 'Sale has not started');
        require(block.timestamp < endTime, 'Sale has ended');
        require(
                _totalPaid[msg.sender].add(amount) <= maxBuyLimit
                && _totalPaid[msg.sender].add(amount) >= minBuyLimit,
                "Investment Amount Invalid."
        );
        
        if(isPrivate) {
            require(whiteListed[msg.sender], 'Private sale');
        }
        
        _totalPaid[msg.sender] = _totalPaid[msg.sender].add(amount);
        totalRaisedAmount = totalRaisedAmount.add(amount);
        uint256 tokenAmount = amount.div(tokenPrice);
        totaltokenSold = totaltokenSold.add(tokenAmount);
        IERC20(RCTOKEN).transferFrom(msg.sender, Recipient, amount);

        require(tokenAmount <= PTOKEN.balanceOf(address(this)), "Insufficient balance");
        PTOKEN.transfer(msg.sender, tokenAmount);
        emit Deposited(amount);
    }

    function getUnsoldTokens(address token, address to) external onlyOwner {
        require(block.timestamp > endTime, "You cannot get tokens until the presale is closed.");
        if(token == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        }
        IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)) );
    }

    function getUserRemainingAllocation(address account) external view returns ( uint256 ) {
        return maxBuyLimit.sub(_totalPaid[account]);
    }
}