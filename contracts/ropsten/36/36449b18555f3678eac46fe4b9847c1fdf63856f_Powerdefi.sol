/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function allowance(address owner, address spender) external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
   
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Powerdefi is Ownable {
    using SafeMath for uint256;
    IERC20 public usdt;
    uint private collateral_;
    string private loancoin_;
    uint private loanToValue_;
    uint private interestRate_;
    string private loanduration_;
    string private paymentIntervals_;
    uint private noOfPayments_;
    uint private pendingRepayment_ = 0;
    address private to_;
    address private repayAccount_;
    uint private lendingStatus_ = 0;
    uint private dueAmount_ = 0;
    
   
    constructor(
        uint _collateral,
        string memory _loancoin,
        uint _loanToValue,
        uint _interestRate,
        string memory _loanduration,
        string memory _paymentIntervals,
        uint _noOfPayments,
        uint _dueAmount,
        address _to,
        address _repayAccount,
        address _tokenAddress
    ) {
        collateral_ = _collateral;
        loancoin_ = _loancoin;
        loanToValue_ = _loanToValue;
        interestRate_ = _interestRate;
        loanduration_ = _loanduration;
        paymentIntervals_ = _paymentIntervals;
        noOfPayments_ = _noOfPayments;
        to_ = _to;
        repayAccount_ = _repayAccount;
        dueAmount_ = _dueAmount;
        usdt = IERC20(_tokenAddress);
        
    }

    function collateral() public view returns(uint){
        return collateral_;
    }

    function loanCoin() public view returns(string memory){
        return loancoin_;
    }

    function interestRate() public view returns(uint){
        return interestRate_;
    }

    function loanduration() public view returns(string memory){
        return loanduration_;
    }

    function paymentIntervals() public view returns(string memory){
        return paymentIntervals_;
    }

    function loanReceiver() public view returns(address){
        return to_;
    }

    function loanRepayAccount() public view returns(address){
        return repayAccount_;
    }

    function lendingStatus() public view returns(uint){
        return lendingStatus_;
    }

    function TotalNumberOfRepayment() public view returns(uint){
        return noOfPayments_;
    }

    function numberOfRepaymentRemainning() public view returns(uint){
        return pendingRepayment_;
    }

    function dueAmount() public view returns(uint) {
        return dueAmount_;
    }



    function lend(address to, uint256 amount) external payable onlyOwner returns (bool) {
        require(lendingStatus_ == 0, "Error : Loan amount already lent");
        require(_msgSender() != address(0), "Error: Lend from the zero address");
        require(to != address(0), "Error: Lend to the zero address");
        require(to_ == to, "Error: Recepiant address not matched");
        require(collateral_ == amount, "Error: Collateral amount mismatched");
        require(usdt.balanceOf(_msgSender()) >= amount, "You have insufficient token to supply that amount");
        lendingStatus_ = 1;
        pendingRepayment_ = pendingRepayment_.add(noOfPayments_);
        usdt.transferFrom(_msgSender(), to_, collateral_);
        return true;
    }

    function repay(address to, uint256 amount) external payable returns (bool) {
        require(pendingRepayment_ > 0, "Error: No pending payments");
        require(_msgSender() != address(0), "Error: Repay from the zero address");
        require(to != address(0), "Error: Repay to the zero address");
        require(repayAccount_ == to, "Error: Repay to the zero address");
        require(usdt.balanceOf(_msgSender()) >= amount, "You have insufficient token to supply that amount");
        pendingRepayment_ = pendingRepayment_.sub(1);
        usdt.transferFrom(_msgSender(), to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        usdt.approve(spender, amount);
        return true;
    }
}