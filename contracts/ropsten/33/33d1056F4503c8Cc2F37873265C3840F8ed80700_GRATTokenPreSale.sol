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

contract GRATTokenPreSale is Pausable {

    using SafeMath for uint256;
    IERC20 token;

    address private _owner;
    uint256 private _rate;
    uint256 private _weiRaised;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor(uint256 rate_, address _wallet, IERC20 _token) {
        require(rate_ > 0,"INVALID_RATE");
        require(_wallet != address(0),"ZERO_ADDRESS_OF_WALLET");

        token = IERC20(_token);
        _rate = rate_;
        _owner = _wallet;
    }

    modifier onlyOwner {
        require(_owner == msg.sender,"Only allowed to Owner");
        _;
    }

    function owner() public view returns(address){
        return _owner;
    }

    function rate() public view returns(uint256){
        return _rate;
    }

    function weiRaised() public view returns(uint256){
        return _weiRaised;
    }

    function balanceOf(address _address) public view returns(uint256){
        return token.balanceOf(_address);
    }

    function transferOwnership(address newOwner) public onlyOwner whenNotPaused{
        require(newOwner != address(0),"ZEROADDRESS");
        require(newOwner != _owner, "Entering OLD_OWNER_ADDRESS");
        _owner = newOwner;
    }

    function updateRate(uint256 rate_) public whenNotPaused returns(bool) {
        _rate = rate_;
        return true;
    }

    function buyToken(address _receiver) public payable whenNotPaused{
        require(_receiver != address(0),"RECEIVER_IS_ZEROADDRESS");
        require(msg.value > 0,"INVALID_ETHER");

        uint256 _msgValue = msg.value;
        _transferFund(_msgValue);
        uint256 _tokenAmount = _getTokenAmount(_msgValue);
        _transfer(_receiver, _tokenAmount);
        _weiRaised = _weiRaised.add(_msgValue);
        emit TokenPurchase(msg.sender, _receiver, _msgValue, _tokenAmount);
    }

    function _transfer(address _receiver, uint256 _amount) internal {
        (bool suc, ) = address(token).call(abi.encodeWithSignature("deposit(address,uint256)", _receiver, _amount));
        require(suc, "failed");
    }

    function _getTokenAmount(uint256 _amount) internal view returns(uint256){
        return _amount.mul(_rate);
    }

    function _transferFund(uint256 _msgValue) internal returns(bool success){
        (success) = payable(_owner).send(_msgValue);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

}