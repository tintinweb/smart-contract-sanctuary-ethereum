/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.5.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return sub(a, b, "SafeMath: subtraction overflow");}
}
contract GameTree {
    using SafeMath for uint256;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event lockwallet(address account, uint256 amount,uint256 releaseTime);
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    address public manager_A;
    address public manager_B;
    address public manager_C;
    mapping(address => LockDetails) private Locked_list;
    mapping(address => mapping(bytes32 => string)) user_dataList;
    
    address private admin;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    uint8 private isInit;

    struct LockDetails{
        uint256 lockedTokencnt;
        uint256 releaseTime;
    }
    
    //////////////////////////////////////// Mint handle //////////////////////////////////////////
    function token_mint(address account) public returns (bool){
        require(isInit == 0 , "Token already mint!");
        require(account != address(0), "ERC20: mint to the zero address");
        admin               = account;
        _name               = "Game tree Coin";
        _symbol             = "GTCOIN";
        _decimals           = 18;
        uint256 INIT_SUPPLY = 10000000000 * (10 ** uint256(_decimals));
        _totalSupply = INIT_SUPPLY;
        _balances[account] = INIT_SUPPLY;
        isInit = 1;
        emit Transfer(address(0), account, _totalSupply);
        return true;
    }
    //////////////////////////////////////// view handle //////////////////////////////////////////
    function Contadmin() public view returns (address) {return admin;}
    function totalSupply() public view returns (uint256) {return _totalSupply;}
    function name() public view returns (string memory) {return _name;}
    function symbol() public view returns (string memory) {return _symbol;}
    function decimals() public view returns (uint8) {return _decimals;}
    function getwithdrawablemax(address account) public view returns (uint256) {return Locked_list[account].lockedTokencnt;}
    function getLocked_list(address account) public view returns (uint256) {return Locked_list[account].releaseTime;}
    function balanceOf(address account) public view returns (uint256) {return _balances[account];}
    function allowance(address owner, address spender) public view returns (uint256) {return _allowances[owner][spender];}
    //////////////////////////////////////////////////////////////////////////////////
    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        _transfer(sender, recipient, amount);
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 LockhasTime = Locked_list[sender].releaseTime;
        uint256 LockhasMax = Locked_list[sender].lockedTokencnt;
        if( block.timestamp < LockhasTime){
            uint256 OK1 = _balances[sender].sub(LockhasMax, "ERC20: transfer amount exceeds allowance");
            require( OK1 >= amount , "Your Wallet has time lock");
        }
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function burn(uint256 amount) public returns (bool) {
        require(msg.sender== admin, "admin only function");
        require(amount >= _balances[msg.sender] , "burn amount must bigger than balance");
        _burn(msg.sender, amount);
        return true;
    }
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(msg.sender == admin, "Admin only can burn  8547");
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    //////////////////////////////////////// manager handle //////////////////////////////////////////
    function isManager() public view returns (bool) {
        bool ismanager = false;
        if(msg.sender == manager_A || msg.sender == manager_B || msg.sender == manager_C) ismanager = true;
        return ismanager;
    }
    function getManager() public view returns (address,address,address) {return (manager_A,manager_B,manager_C);}
    function _set_manager(address account ,uint8 whichone)internal{
        if( whichone==1) manager_A = account;
        if( whichone==2) manager_B = account;
        if( whichone==3) manager_C = account;
    }
    function set_manager(address account,uint8 whichone ) public{
        require(admin == msg.sender, "Admin only function");
        require(account != address(0), "ERC20: Cannot set manager to the zero address");
        _set_manager(account, whichone);
    }
    //////////////////////////////////////// Lock token handle //////////////////////////////////////////
    function Lock_wallet(address _adr, uint256 lockamount,uint256 releaseTime ) public returns (bool) {
        require(_adr != address(0), "ERC20: transfer to the zero address");
        require(msg.sender== admin || msg.sender== manager_A || msg.sender== manager_B || msg.sender== manager_C , "admin only function");
        require(releaseTime > block.timestamp , "Lock time must larger than now"); 
        _Lock_wallet(_adr,lockamount,releaseTime);
        return true;
    }
    function _Lock_wallet(address account, uint256 amount,uint256 releaseTime) internal {
        LockDetails memory eaLock = Locked_list[account];
        eaLock = LockDetails(amount, releaseTime);
        Locked_list[account] = eaLock;
        emit lockwallet(account, amount, releaseTime);
    }
    //////////////////////////////////////// StringData handle //////////////////////////////////////////
    function getStringData(bytes32 key) public view returns (string memory) {
        return user_dataList[msg.sender][key];
    }
    function setStringData(bytes32 key, string memory value) public {
        user_dataList[msg.sender][key] = value;
    }
}