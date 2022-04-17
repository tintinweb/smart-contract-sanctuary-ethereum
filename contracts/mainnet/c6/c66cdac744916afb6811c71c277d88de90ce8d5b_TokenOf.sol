/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }   
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
}
contract TokenOf is Context, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    struct LockDetails{
        uint256 lockedTokencnt;
        uint256 releaseTime;
    }
    mapping (address => bool) public isManager;
    mapping(address => LockDetails) private Locked_list;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _admin;

    constructor (string memory name_, string memory symbol_) public {
        _admin = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        isManager[msg.sender]=true;
        _mint(msg.sender , 1000000000 * (10 ** uint256(_decimals) )) ;
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        require(msg.sender == _admin, "Admin only function");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function checkManage(address walletAddress) public view virtual returns (bool) {return isManager[walletAddress] == true ? true :false;}
    function setManage(address walletAddress , bool st) public returns (bool) {
        require(msg.sender == _admin , "Owner only function"); // internal owner
        isManager[walletAddress]=st;
        return true;
    }

    function checkadmin() public view virtual returns (address) {return _admin;}
    function moveadmintoother(address walletAddress) public returns (bool) {
        require(walletAddress != address(0), "ERC20: transfer from the zero address");
        require(msg.sender == _admin , "Owner only function"); // internal owner
        _admin = walletAddress;
        return true;
    }

    function Lock_wallet(address _adr, uint256 lockamount,uint256 releaseTime ) public returns (bool) {
        require(msg.sender==_admin || isManager[msg.sender] == true , "Admin or manager only function");
        _Lock_wallet(_adr,lockamount,releaseTime);
        return true;
    }
    function _Lock_wallet(address account, uint256 amount,uint256 releaseTime) internal {
        LockDetails memory eaLock = Locked_list[account];
        if( eaLock.releaseTime > 0 ){
            eaLock.lockedTokencnt = amount;
            eaLock.releaseTime = releaseTime;
        }else{
            eaLock = LockDetails(amount, releaseTime);
        }
        Locked_list[account] = eaLock;
    }
    function admin_mintMore(uint256 amount) public virtual returns (bool) {
        _mint(msg.sender, amount);
        return true;
    }
    function name() public view virtual returns (string memory) {return _name;}
    function symbol() public view virtual returns (string memory) {return _symbol;}
    function decimals() public view virtual returns (uint8) {return _decimals;}
    function totalSupply() public view virtual override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view virtual override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 LockhasTime = Locked_list[sender].releaseTime;
        uint256 LockhasMax = Locked_list[sender].lockedTokencnt;
        if( block.timestamp < LockhasTime){
            uint256 OK1 = _balances[sender].sub(LockhasMax, "ERC20: the amount to unlock is bigger then locked token count");
            require( OK1 >= amount , "Your Wallet has time lock");
        }

        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function getwithdrawablemax(address account) public view returns (uint256) {
        return Locked_list[account].lockedTokencnt;
    }
    function getLocked_list(address account) public view returns (uint256) {
        return Locked_list[account].releaseTime;
    }
    function getLockinfo(address userwallet) public view virtual returns (uint256[] memory) {
        uint256 LockhasTime = Locked_list[userwallet].releaseTime;
        uint256 LockhasMax = Locked_list[userwallet].lockedTokencnt;
        uint256[] memory rets = new uint256[](2);
        rets[0] = LockhasTime;
        rets[2] = LockhasMax;
        return rets;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {return _allowances[owner][spender];}
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _setupDecimals(uint8 decimals_) internal virtual {_decimals = decimals_;}
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}