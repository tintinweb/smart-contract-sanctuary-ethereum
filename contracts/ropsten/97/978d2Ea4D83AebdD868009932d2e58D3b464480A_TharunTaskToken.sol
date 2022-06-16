/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

pragma solidity 0.8.13;
//SPDX-License-Identifier:Unlicensed

abstract contract Context {

    function _msgSender() internal view returns(address){
        return msg.sender;
    }

    function _msgData() internal pure returns(bytes memory){
        return msg.data;
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

abstract contract Ownable is Pausable{

    address internal _owner;

    event TransferOwnerShip(address indexed _oldOwner, address indexed _newOwner);

    constructor(){
        _owner = _msgSender();
        emit TransferOwnerShip(address(0), _msgSender());
    }

    function owner() public view returns(address){
        return _owner;
    }

    modifier onlyOwner() {
        require(_msgSender() == owner(),"NOT AN OWNER");
        _;
    }

    function transferOwnerShip(address _newOwner) internal returns(bool){
        require(owner() != _newOwner,"NEWOWNER IS OLDOWNER");

        _owner = _newOwner;
        emit TransferOwnerShip(owner(), _newOwner);
        return true;
    }

    function renonceOwnerShip() public onlyOwner {
        _owner = address(0);
    }

}

interface IERC20{

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint256);
    function totalSupply() external view returns(uint256);
    function transfer(address _receiver, uint256 _numTokens) external returns(bool);
    function balanceOf(address _account) external view returns(uint256);
    function approve(address _spender, uint256 _numTokens) external returns(bool);
    function allowance(address _owner, address _spender) external view returns(uint256);
    function transferFrom(address _owner, address _buyer, uint256 _numTokens) external returns(bool);

    event Transfer(address indexed _owner, address indexed _buyer, uint256 indexed _numTokens);
    event TransferFrom(address indexed _owner, address indexed _spender, address indexed _buyer, uint256 _numTokens);

}

contract ERC20 is IERC20, Ownable{

    string internal _name = "Tharun";
    string internal _symbol = "VMT";
    uint256 internal _decimals = 8;
    uint256 internal _totalSupply = 100000000 * 10 ** 8;

    mapping (address => uint256) balances;
    mapping (address => mapping(address => uint256)) approval;

    constructor() {
        balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), owner(), _totalSupply);
    }

    function name() public view returns(string memory){
        return _name;
    }

    function symbol() public view returns(string memory){
        return _symbol;
    }

    function decimals() public view returns(uint256){
        return _decimals;
    }

    function totalSupply() public view returns(uint256){
        return _totalSupply;
    }

    function transfer(address _receiver, uint256 _numTokens) public returns(bool){
        require(balances[_msgSender()] > 0, "INSUFFICIENT TOKEN");
        require(_receiver != address(0), "ZERO_ADDRESS");
        require(_numTokens > 0, "INVALID_NUMTOKENS");

        balances[_msgSender()] = balances[_msgSender()] - _numTokens;
        balances[_receiver] = balances[_receiver] + _numTokens;

        emit Transfer(_msgSender(), _receiver, _numTokens);

        return true;
    }

    function balanceOf(address _account) public view returns(uint256){
        return balances[_account];
    }

    function approve(address _spender, uint256 _numTokens) public returns(bool){
        require(balances[_msgSender()] >= _numTokens, "INSUFFICIENT TOKENS TO APPROVE");
        require(_numTokens > 0, "INVALID NUMTOKENS");
        require(_spender != address(0), "SPENDER IS ZERO ADDRESS");

        approval[_msgSender()][_spender] = _numTokens;
        return true;
    }

    function allowance(address _owner, address _spender) public view returns(uint256){
        return approval[_owner][_spender];
    }

    function transferFrom(address _owner, address _buyer, uint256 _numTokens) public returns(bool){
        require(approval[_owner][_msgSender()] > 0, "INSUFFICIENT APPROVAL TOKENS");
        require(_buyer != address(0), "BUYER IS ZERO ADDRESS");
        require(_numTokens > 0 , "INVALID NUMTOKENS");

        approval[_owner][_msgSender()] = approval[_owner][_msgSender()] - _numTokens;
        balances[_owner] = balances[_owner] - _numTokens;
        balances[_buyer] = balances[_buyer] + _numTokens;

        emit TransferFrom(_owner, _msgSender(), _buyer, _numTokens);
        return true;
    }

}

contract TharunTaskToken is ERC20 {

    event Mint(address indexed _from, address indexed _to, uint256 indexed _numTokens);
    event Burn(address indexed _from, address indexed _to, uint256 indexed _numTokens);

    function mint(address _account, uint256 _numTokens) public onlyOwner returns(bool){
        require(_account != address(0), "MINTING OT ZEROADDRESS");
        require(_numTokens > 0 , "INVALID NUMTOKENS");

        balances[_account] = balances[_account] +_numTokens;
        _totalSupply = _totalSupply + _numTokens;

        emit Mint(address(0), _account, _numTokens);
        return true;
    }

    function burn(address _account, uint256 _numTokens) public onlyOwner returns(bool){
        require(_account != address(0), "MINTING TO ZEROADDRESS");
        require(_numTokens > 0 , "INVALID NUMTOKENS");
        require(_account == _msgSender(), " ONLY ALLOWED TO BURN OWN TOKENS");

        balances[_account] = balances[_account] - _numTokens;
        _totalSupply = _totalSupply - _numTokens;

        emit Burn(_account, address(0), _numTokens);
        return true;
    }

    function increaseAllowance(address _spender, uint256 _numTokens) public returns(bool){
        require(_spender != address(0), "INCREASING ALLOWANCE TO ZEROADDRESS");
        require(_numTokens > 0 , "INVALID NUMTOKENS");

        approval[_msgSender()][_spender] = approval[_msgSender()][_spender] + _numTokens;
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _numTokens) public returns(bool){
        require(_spender != address(0), "INCREASING ALLOWANCE TO ZEROADDRESS");
        require(_numTokens > 0 , "INVALID NUMTOKENS");

        approval[_msgSender()][_spender] = approval[_msgSender()][_spender] - _numTokens;
        return true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}