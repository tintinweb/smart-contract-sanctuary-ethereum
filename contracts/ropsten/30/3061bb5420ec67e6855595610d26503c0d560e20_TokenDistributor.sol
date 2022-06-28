/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// File: contracts/multisender2.sol

pragma solidity ^0.5.2;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);}

contract Context {
    constructor () internal { }
    function _msgSender() internal view returns (address payable) {
        return msg.sender;}

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;}}
        
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");}
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");}
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");}
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;}}
        
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);}
    function owner() public view returns (address) {
        return _owner;}
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;}
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);}
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);}
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;}}

contract onlyOwner {
    address public owner;
    constructor() public {
        owner = msg.sender;}
    modifier isOwner {
        require(msg.sender == owner);
        _;}}


contract TokenDistributor is onlyOwner{
    IBEP20 token;
    event TransferredToken(address indexed to, uint256 value);
    address distTokens;
    constructor(address _contract) public{
        distTokens = _contract;
        token = IBEP20(_contract);}
    function setTokenContract(address _contract) isOwner public{
        distTokens = _contract;
        token = IBEP20(_contract);} 
    function getTokenContract() public view returns(address){
        return distTokens;}
    function multisend(address[] memory _user, uint256[] memory value) isOwner public returns(bool){
        for(uint i=0; i< _user.length; i++)
        token.transfer(_user[i], value[i]*10**18);
        return true;}}