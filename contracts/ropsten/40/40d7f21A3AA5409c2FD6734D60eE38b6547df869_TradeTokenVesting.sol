/**
 *Submitted for verification at Etherscan.io on 2022-04-08
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

interface IBEP20 {

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
        require(newOwner != address(0),"Entered newOwner address is ZeroAddress");
        require(newOwner != _owner, "Dont enter the Old owner address");
        _owner = newOwner;
    }

    function renonceOwnerShip() public onlyOwner {
        _owner = address(0);
    }

}

contract TradeTokenVesting is Ownable,Pausable{

    using SafeMath for uint256;

    IBEP20 private TradeToken;

    uint256 private tokensToVest = 0;
    uint256 private vestingId = 0;
    uint256 private day = 1 days;
    
    struct Vesting {
        uint userId;
        uint256 releaseTime;
        uint256 amount;
        address beneficiary;
        bool released;
        uint256 completedDues;
        uint256[] dueId;
    }  

    mapping(uint256 => Vesting) public vestings;/* This mapping is used for viewing user details. */
    mapping(address => bool) public isExist; /* This mapping is used for Avoiding double register. */
    mapping(uint256 => uint256) public vestingBalance;/* This Mapping is used for user vesting balance. */

    constructor(IBEP20 _token) {
        require(address(_token) != address(0x0), "StreetHeat token address is not valid");
        TradeToken = _token;
    }

    function token() public view returns (IBEP20) {
        return TradeToken;
    }

    function addVesting(address _beneficiary, uint256 _releaseTime, uint256 _amount, uint[] memory _due ) public whenNotPaused onlyOwner {
        require(vestingId < 4,"4 Member Limit Reached!!!");
        require(_beneficiary != address(0x0),"INVALID_BENEFICIARY");
        require(isExist[_beneficiary] != true,"Exist User in vesting");

        vestingId++;
        Vesting memory vesting;

        vesting = Vesting({
            userId : vestingId,
            releaseTime : block.timestamp + _releaseTime * day,
            amount : _amount,
            beneficiary : _beneficiary,
            released : false,
            completedDues : 0,
            dueId : _due
        });
       
        tokensToVest = tokensToVest.add(_amount);
        isExist[_beneficiary] = true;
        vestingBalance[vestingId] = _amount;
        vestings[vestingId] = vesting;
    }

    function viewAllocatedDues(uint256 _vestingId) public view returns(uint[] memory _view){
        Vesting memory vesting = vestings[_vestingId];
        return vesting.dueId;
    }

    function release(uint256 _vestingId) public whenNotPaused returns(bool){
        Vesting storage vesting = vestings[_vestingId];
    
        require(vesting.beneficiary != address(0x0),"INVALID_VESTING_ID");
        require(vesting.beneficiary == msg.sender,"Only beneficiary allowed");
        require(block.timestamp >= vesting.releaseTime, "NOT_VESTED");
        require(vesting.released != true,"Already released");
        require(vesting.amount <= TradeToken.balanceOf(address(this)), "INSUFFICIENT_BALANCE");

        uint256 percentage = vesting.dueId[vesting.completedDues];
        uint256 value = vesting.amount * percentage / 100;
        TradeToken.transfer(msg.sender,value);
        tokensToVest = tokensToVest.sub(value);
        vestingBalance[vesting.userId] = vestingBalance[vesting.userId].sub(value);
        
        vesting.completedDues++;

        if(vesting.completedDues < vesting.dueId.length){
            vesting.releaseTime += 30 days;
        }

        if(vesting.completedDues == vesting.dueId.length){
            vesting.released = true;
        }

        return true;

    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

}