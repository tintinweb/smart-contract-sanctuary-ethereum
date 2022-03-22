/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: CryptoBrew LTD.
// MORE INFO: https://cryptobrew.info/
pragma solidity ^0.8.13;

// Address, Context, Ownable.
library Address {
    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount, "Exchange exceeds contract balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Transfer failed");}}
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);}
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;}}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);} 
    function owner() public view returns (address) {
        return _owner;}
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;}
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Access Denied.");
        _;}}
    
// Sale Contract Begins Here.
contract SaleContract is Context, Ownable {
    mapping(address => uint) private _contributions;
    using Address for address;
    address payable immutable _seedContract;
    address payable immutable _CB;
    uint private constant _bnb = (10 ** 18);
    uint private constant _cap = (100 * _bnb);
    bool _saleActive;

    // Initializes contract variables.
    constructor () {
        _seedContract = payable(address(this));
        _CB = payable(msg.sender);
        _saleActive = true;}

    // Emits contribution event to the blockchain when BNB is recieved.
    event ContributionReceived(address indexed from, uint value);

    // Checks if sale is still open.
    // If yes then sender becomes a contributor.
    // If no then transaction is reverted.
    receive() external payable {
        address contributor = msg.sender;
        uint amount = msg.value;
        if (_saleActive = true) {
            contribute(contributor, amount);}
        else { 
            revert("Sale cap reached");}}

    // Notes amount of BNB donated by each contributor.
    function contribute(address contributor, uint amount) internal returns (uint) {
        uint contractBalance = _seedContract.balance;
        require(contributor == tx.origin, "Contributor cannot be a smart contract");
        require(amount <= (_bnb * 2), "Max Contribution: 2 BNB");
        require(amount >= (_bnb / 10), "Min Contribution: 0.1 BNB");
        if (contractBalance >= _cap) {
            endSale();}
        _contributions[contributor] = (_contributions[contributor] + amount);
        emit ContributionReceived(contributor, amount);
        return _contributions[contributor];}

    // Prevents anyone else from contributing.
    function endSale() internal returns (bool) {
        _saleActive = false;
        return _saleActive;}

    // Incase any contributions need to be double checked & verified.
    function viewTotalContribution(address _contributor) external view onlyOwner returns (uint) {
        return _contributions[_contributor];}

    // Allows CryptoBrew to withdraw the funds.
    function withdrawFunds() external onlyOwner returns (bool) {
        require(_saleActive = false, "Seed Sale is still active");
        (bool success,) = payable(_CB).call{ value: _seedContract.balance }("");
        if (success) {
            return success;}
        else {
            revert("Failed");}}

    // Tamper protection.
    fallback() external payable {
        revert("Invalid call");}}