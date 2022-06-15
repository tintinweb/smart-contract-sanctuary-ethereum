/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

//SPDX-License-Identifier:Unlicensed
pragma solidity ^0.8.13;

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

interface IERC20 {

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function deposit(address _receiver,uint256 _numTokens) external payable ;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

abstract contract Context {

    function _msgSender() internal view returns(address){
        return(msg.sender);
    }

    function _msgData() internal pure returns(bytes memory){
        return(msg.data);
    }

}

abstract contract Pausable is Context {

    event Paused(address indexed account);
    event Unpaused(address indexed account);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view returns(bool){
        return _paused;
    }

    modifier whenNotPaused{
        require(!paused(),"Pasuable : Paused");
        _;
    }

    modifier whenPaused(){
        require(paused(),"Pasuable : Not Paused");
        _;
    }

    function _pause() internal whenNotPaused{
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal whenPaused{
        _paused = false;
        emit Unpaused(_msgSender());
    }

}

abstract contract Ownable is Context{

    address private _owner;

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
    }

    function owner() public view returns(address){
        return _owner;
    }

    modifier onlyOwner {
        require(_owner == _msgSender(),"Only allowed to Owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0),"ZEROADDRESS");
        require(newOwner != _owner, "Entering OLD_OWNER_ADDRESS");
        _owner = newOwner;
    }

    function renonceOwnerShip() public onlyOwner {
        _owner = address(0);
    }

}

contract GRATToken is Ownable, IERC20, Pausable{

    using SafeMath for uint256;

    string private name_;
    string private symbol_;
    uint256 private decimals_;
    uint256 private totalSupply_;

    mapping (address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    constructor () {
        name_ = "GRATToken";
        symbol_ = "GRAT";
        decimals_ = 18;
        totalSupply_ = 150000000*10**18;
        balances[msg.sender] = totalSupply_ ;
        emit Transfer(address(0), owner(), totalSupply_);
    }

    function name() public view returns(string memory){
        return name_;
    }

    function symbol() public view returns(string memory){
        return symbol_;
    }

    function decimals() public view returns(uint256){
        return decimals_;
    }

    function totalSupply() public view returns (uint256){
        return totalSupply_;
    }

    function transfer(address receiver, uint256 numTokens) public whenNotPaused returns (bool) {
        require(numTokens <= balances[msg.sender],"Number of Token is More than Balance");
        require(numTokens > 0, "INVALID_AMOUNT");
        require(receiver != address(0),"TRANSFERING_TO_ZEROADDRESS");

        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function balanceOf(address account) external view returns (uint256){
        return balances[account];
    }

    function approve(address delegate, uint256 numTokens) public returns (bool) {
        require(delegate != address(0),"APPROVING_TO_ZEROADDRESS");
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public whenNotPaused returns (bool) {
        require(numTokens <= balances[owner],"Number of Token is More than Balance");
        require(numTokens <= allowed[owner][msg.sender],"Number of Token is More than Approval");
        require(buyer != address(0),"TRANSFERING_TO_ZEROADDRESS");

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function mint(address account, uint256 amount) public onlyOwner whenNotPaused {
        require(account != address(0), "MINT_TO_ZEROADDRESS");
        require(amount > 0, "INVALID_AMOUNT");

        totalSupply_ = totalSupply_.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner whenNotPaused {
        require(account != address(0), "BURN_FROM_ZEROADDRESS");
        require(amount > 0, "INVALID_AMOUNT");

        balances[account] = balances[account].sub(amount, "Burn amount exceeds balance");
        totalSupply_ = totalSupply_.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function deposit(address _receiver, uint256 _numTokens) public payable whenNotPaused {
        balances[owner()] = balances[owner()].sub(_numTokens);
        balances[_receiver] = balances[_receiver].add(_numTokens);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

}