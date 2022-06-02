/**
 *Submitted for verification at Etherscan.io on 2022-06-02
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

contract TestBala is Ownable {
    using SafeMath for uint256;
    IERC20 private usdt;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private collateral_;
    string private loancoin_;
    uint256 private loanToValue_;
    uint8 private interestRate_;
    string private loanduration_;
    string private paymentIntervals_;
    uint8 private noOfPayments_;
    uint8 private pendingRepayment_ = 0;
    address private to_;
    address private repayAccount_;
    uint8 private lendingStatus_ = 0;
    uint256 private dueAmount_ = 0;
    uint32 private loanLendDate;
    address private lendToken_;

    struct dudates {
        uint8 dues;
        uint32 date;
    }
    dudates [] private dues;
    mapping(uint8 => uint32) private due;

    constructor(
        uint256 _collateral,
        string memory _loancoin,
        uint256 _loanToValue,
        uint8 _interestRate,
        string memory _loanduration,
        string memory _paymentIntervals,
        uint8 _noOfPayments,
        uint256 _dueAmount,
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
        lendToken_ = _tokenAddress;

        loanLendDate = uint32(block.timestamp);
        uint32 duerepaydate = loanLendDate;
        for(uint8 i = 1; i <= _noOfPayments; i++){
            if(keccak256(abi.encodePacked(_paymentIntervals)) == keccak256(abi.encodePacked("daily"))){
                duerepaydate = duerepaydate + 1 days;
            }
            else if(keccak256(abi.encodePacked(_paymentIntervals)) == keccak256(abi.encodePacked("weekly"))){
                duerepaydate = duerepaydate + 7 days;
            }
            else if(keccak256(abi.encodePacked(_paymentIntervals)) == keccak256(abi.encodePacked("monthly"))){
                duerepaydate = duerepaydate + 30  days;
            }
            else if(keccak256(abi.encodePacked(_paymentIntervals)) == keccak256(abi.encodePacked("yearly"))){
                duerepaydate = duerepaydate + 365  days;
            }
            setDeutime(i, duerepaydate);
            dudates memory setdeue = dudates(i, duerepaydate);
            dues.push(setdeue);
        }
    }

  
    function collateral() public view returns(uint256){
        return collateral_;
    }

    function loanCoin() public view returns(string memory){
        return loancoin_;
    }

    function interestRateinPercentage() public view returns(uint8){
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

    function lendingStatus() public view returns(uint8){
        return lendingStatus_;
    }
    function lendingToken() public view returns(address){
        return lendToken_;
    }
    function TotalNumberOfRepayment() public view returns(uint8){
        return noOfPayments_;
    }

    function numberOfRepaymentRemainning() public view returns(uint8){
        return pendingRepayment_;
    }

    function dueAmount() public view returns(uint256) {
        return dueAmount_;
    }

    function lendDate() public view returns(uint32){
        return loanLendDate;
    }

    function setDeutime(uint8 i, uint32 duedate) private {
        due[i] = duedate;
    }

    function getDueDate(uint8 numberOfDue) public view returns(uint32){
        return due[numberOfDue];
    }

    function lend(address _to, uint256 _amount) external payable onlyOwner returns (bool) {
        _lend(_to, _amount);
        return true;
    }

    function repay(address _to, uint256 _amount, uint8 _numberofdue) external payable returns (bool) {
        _repay(_to, _amount, _numberofdue);
        return true;
    }

    function _lend(address to, uint256 amount) private {
        require(amount > 0, "Error : Loan amount shoud be > 0");
        require(lendingStatus_ == 0, "Error : Loan amount already lent");
        require(_msgSender() != address(0), "Error: Lend from the zero address");
        require(to != address(0), "Error: Lend to the zero address");
        require(to_ == to, "Error: Recepiant address not matched");
        require(collateral_ == amount, "Error: Collateral amount mismatched");
        require(usdt.balanceOf(_msgSender()) >= amount, "You have insufficient token to supply that amount");
        lendingStatus_ = 1;
        pendingRepayment_ = uint8(pendingRepayment_ + noOfPayments_);
        usdt.transferFrom(_msgSender(), to_, collateral_);
    }

    function _repay(address to, uint256 amount, uint8 numberofdue) private {
        require(due[numberofdue] <= block.timestamp, "Error : try to pay earlier");
        require(amount > 0, "Error : repay amount shoud be > 0");
        require(dueAmount_ == amount, "Error : due amount mismatched");
        require(pendingRepayment_ > 0, "Error: No pending payments");
        require(_msgSender() != address(0), "Error: Repay from the zero address");
        require(to != address(0), "Error: Repay to the zero address");
        require(repayAccount_ == to, "Error: Repay to the zero address");
        require(usdt.balanceOf(_msgSender()) >= amount, "You have insufficient token to supply that amount");
        pendingRepayment_ = uint8(pendingRepayment_ - 1);
        usdt.transferFrom(_msgSender(), to, amount);
    }

}