/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.13;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns(uint256){
        uint256 c = a + b;
        require(c >= a,"Addition OverFlow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256){
        return sub(a,b,"Subraction OverFlow");
    }

    function sub(uint256 a,uint256 b, string memory ERROR_msg) internal pure returns(uint256){
        require(a>=b, ERROR_msg);
        uint256 c = a - b;
        return c;
    }
}

interface IERC201 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
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

    event Paused(address account);
    event Unpaused(address account);

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

    address private owner;

    constructor () {
        address msgSender = _msgSender();
        owner = msgSender;
    }

    function Owner() public view returns(address){
        return owner;
    }

    modifier OnlyOwner {
        require(owner == _msgSender(),"Only allowed to Owner");
        _;
    }

    function _transferOwnership(address newOwner) public OnlyOwner {
        require(newOwner != address(0),"Entered newOwner address is ZeroAddress");
        require(newOwner != owner, "Dont enter the Old owner address");
        owner = newOwner;
    }

    function renonceOwnerShip() public OnlyOwner {
        owner = address(0);
    }

}

contract StreetHeat is Ownable, IERC201, Pausable{

    using SafeMath for uint256;

    string private name_;

    string private symbol_;

    uint256 private decimal_;

    uint256 private totalSupply_;

    mapping (address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    constructor () {
        name_ = "StreetHeat";
        symbol_ = "STHT";
        decimal_ = 18;
        totalSupply_ = 300000000000*10**18;
        balances[msg.sender] = totalSupply_ ;
    }

    function name() public view returns(string memory){
        return name_;
    }

    function symbol() public view returns(string memory){
        return symbol_;
    }

    function decimal() public view returns(uint256){
        return decimal_;
    }

    function totalSupply() public view override returns (uint256){
        return totalSupply_;
    }

    function transfer(address receiver, uint256 numTokens) public override whenNotPaused returns (bool) {
        require(numTokens <= balances[msg.sender]);
        require(numTokens > 0, "Invalid Number of Token");

        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function balanceOf(address account) external view override returns (uint256){
        return balances[account];
    }

    function approve(address delegate, uint256 numTokens) public whenNotPaused override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public whenNotPaused override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function Mint(address account, uint256 amount) public OnlyOwner whenNotPaused virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        require(amount > 0, "Invalid amount");

        totalSupply_ = totalSupply_.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function Burn(address account, uint256 amount) public OnlyOwner whenNotPaused virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        require(amount > 0, "Invalid amount");

        balances[account] = balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        totalSupply_ = totalSupply_.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function pause() public OnlyOwner {
        _pause();
    }

    function unpause() public OnlyOwner {
        _unpause();
    }
 
}