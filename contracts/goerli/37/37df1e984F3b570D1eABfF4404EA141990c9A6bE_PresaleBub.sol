/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

/**
▄▄███▄▄·██████╗ ██╗   ██╗██████╗ 
██╔════╝██╔══██╗██║   ██║██╔══██╗
███████╗██████╔╝██║   ██║██████╔╝
╚════██║██╔══██╗██║   ██║██╔══██╗
███████║██████╔╝╚██████╔╝██████╔╝
╚═▀▀▀══╝╚═════╝  ╚═════╝ ╚═════╝ 
 */

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IBEP20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract PresaleBub {
    using SafeMath for uint256;

    IBEP20 public token;
    address payable public owner;

    uint256 public tokenPerEth;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public soldTokens;
    uint256 public amountRaisedEth;
    uint256 public totalSupply;
    uint256 public hardCap;
    uint256 public totalUsers;

    bool public claimEnable;
    
    mapping(address => uint256) public ethBalance;
    mapping(address => uint256) public claimableTokens;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "$BUB: Not an owner");
        _;
    }

    event BuyToken(address indexed _user, uint256 indexed _amount);
    event ClaimToken(address indexed _user, uint256 indexed _amount);

    constructor(address payable _owner, IBEP20 _token) {
        owner = _owner;
        token = _token;
        tokenPerEth = 40_000;
        minAmount = 0.005 ether;
        maxAmount = 5 ether;
        totalSupply = 20_000_000;
        hardCap = 500 ether;
        preSaleStartTime = block.timestamp;
        preSaleEndTime = preSaleStartTime + 10 days;
    }

    // to buy token during preSale time => for web3 use
    function buyToken() public payable {
        require(
            block.timestamp >= preSaleStartTime &&
                block.timestamp < preSaleEndTime,
            "$BUB: PreSale time not met"
        );
        require(
            ethBalance[msg.sender].add(msg.value) <= maxAmount,
            "$BUB: Amount exceeds max limit"
        );
        require(
            msg.value >= minAmount,
            "$BUB: Amount less than min amount"
        );
        require(
            amountRaisedEth.add(msg.value) <= hardCap,
            "$BUB: Hard cap"
        );
        if(ethBalance[msg.sender] == 0){
            totalUsers++;
        }
        uint256 numberOfTokens = ethToToken(msg.value);
        claimableTokens[msg.sender] = ethBalance[msg.sender].add(numberOfTokens);
        soldTokens = soldTokens.add(numberOfTokens);
        ethBalance[msg.sender] = ethBalance[msg.sender].add(msg.value);
        amountRaisedEth = amountRaisedEth.add(msg.value);
                
        emit BuyToken(msg.sender, numberOfTokens);
    }

    // to check number of token for given eth
    function ethToToken(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = _amount.mul(tokenPerEth);
        return numberOfTokens.mul(10 ** token.decimals()).div(1 ether);
    }

    // to claim token after preSale time => for web3 use
    function claimToken() public {
        require(claimEnable,"$BUB: wait for enable claim");
        require(claimableTokens[msg.sender] > 0,"$BUB: no claim able amount");
        uint256 numberOfTokens = claimableTokens[msg.sender];
        claimableTokens[msg.sender] = 0;
        token.transferFrom(owner, msg.sender, numberOfTokens);

        emit ClaimToken(msg.sender, numberOfTokens);
    }
    
    // to change Price of the token
    function changePrice(uint256 _price) external onlyOwner {
        tokenPerEth = _price;
    }

    // to change claim state of the token
    function setClaim(bool _value) external onlyOwner {
        claimEnable = _value;
    }

    // to change preSale amount limits
    function setPreSaletLimits(uint256 _minAmount, uint256 _maxAmount, uint256 _total, uint256 _cap)
        external
        onlyOwner
    {
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        totalSupply = _total;
        hardCap = _cap;
    }

    // to change preSale time duration
    function setPreSaleTime(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        preSaleStartTime = _startTime;
        preSaleEndTime = _endTime;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }
    
    // change tokens
    function changeToken(address _token) external onlyOwner{
        token = IBEP20(_token);
    }

    // to draw funds for liquidity
    function transferFunds(uint256 _value) external onlyOwner {
        owner.transfer(_value);
    }

    // to draw out tokens
    function transferTokens(uint256 _value) external onlyOwner {
        token.transfer(owner, _value);
    }

    // to get current UTC time
    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    function contractBalancebnb() external view returns (uint256) {
        return address(this).balance;
    }

    function getContractTokenApproval() external view returns (uint256) {
        return token.allowance(owner, address(this));
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}