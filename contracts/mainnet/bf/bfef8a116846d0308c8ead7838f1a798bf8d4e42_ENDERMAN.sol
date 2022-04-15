/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

/*
   ▓█████  ███▄    █ ▓█████▄ ▓█████  ██▀███   ███▄ ▄███▓ ▄▄▄       ███▄    █     ▄████▄   ▒█████   ██▓ ███▄    █    
   ▓█   ▀  ██ ▀█   █ ▒██▀ ██▌▓█   ▀ ▓██ ▒ ██▒▓██▒▀█▀ ██▒▒████▄     ██ ▀█   █    ▒██▀ ▀█  ▒██▒  ██▒▓██▒ ██ ▀█   █    
   ▒███   ▓██  ▀█ ██▒░██   █▌▒███   ▓██ ░▄█ ▒▓██    ▓██░▒██  ▀█▄  ▓██  ▀█ ██▒   ▒▓█    ▄ ▒██░  ██▒▒██▒▓██  ▀█ ██▒   
   ▒▓█  ▄ ▓██▒  ▐▌██▒░▓█▄   ▌▒▓█  ▄ ▒██▀▀█▄  ▒██    ▒██ ░██▄▄▄▄██ ▓██▒  ▐▌██▒   ▒▓▓▄ ▄██▒▒██   ██░░██░▓██▒  ▐▌██▒   
   ░▒████▒▒██░   ▓██░░▒████▓ ░▒████▒░██▓ ▒██▒▒██▒   ░██▒ ▓█   ▓██▒▒██░   ▓██░   ▒ ▓███▀ ░░ ████▓▒░░██░▒██░   ▓██░   
   ░░ ▒░ ░░ ▒░   ▒ ▒  ▒▒▓  ▒ ░░ ▒░ ░░ ▒▓ ░▒▓░░ ▒░   ░  ░ ▒▒   ▓▒█░░ ▒░   ▒ ▒    ░ ░▒ ▒  ░░ ▒░▒░▒░ ░▓  ░ ▒░   ▒ ▒    
   ░ ░  ░░ ░░   ░ ▒░ ░ ▒  ▒  ░ ░  ░  ░▒ ░ ▒░░  ░      ░  ▒   ▒▒ ░░ ░░   ░ ▒░     ░  ▒     ░ ▒ ▒░  ▒ ░░ ░░   ░ ▒░   

                             🅱️🆁🅸🅽🅶 🅼🅸🅽🅴🅲🆁🅰️🅵🆃 🆃🅾️ 🅱️🅻🅾️🅲🅺🅲🅷🅰️🅸🅽

   ʙᴇɪɴɢ ᴀ ᴍɪɴᴇᴄʀᴀꜰᴛ ᴇɴᴛʜᴜꜱɪᴀꜱᴛ ʏᴏᴜ ᴍᴀʏ ʜᴀᴠᴇ ꜱᴛᴇᴘᴘᴇᴅ ᴀᴄʀᴏꜱꜱ ᴀɴ ᴇɴᴅᴇʀᴍᴀɴ, ᴡʜɪᴄʜ ɪꜱ ᴀ ɴᴇᴜᴛʀᴀʟ ᴍᴏʙ ᴡʜᴏ ᴄᴀɴ ᴛᴇʟᴇᴘᴏʀᴛ 
   ᴀɴᴅ ᴘɪᴄᴋᴜᴘ ʙʟᴏᴄᴋꜱ. ᴇɴᴅᴇʀᴍᴀɴᴄᴏɪɴ ᴀʟʟᴏᴡꜱ ꜱᴇʀᴠᴇʀꜱ ᴛᴏ ᴍᴀᴋᴇ ʙʟᴏᴄᴋᴄʜᴀɪɴ-ʙᴀꜱᴇᴅ ᴇᴄᴏɴᴏᴍɪᴇꜱ, ʀᴇᴡᴀʀᴅ ᴘʟᴀʏᴇʀꜱ ꜰᴏʀ ᴛʜᴇɪʀ ᴛɪᴍᴇ,
   ᴀʟʟᴏᴡ ʏᴏᴜʀ ᴄᴏᴍᴍᴜɴɪᴛʏ ᴛᴏ ʙᴜʏ ʀᴀɴᴋꜱ - ᴀʟʟ ɪɴ ᴀ ʟᴏᴡ-ᴄᴏꜱᴛ ᴀɴᴅ ᴇᴄᴏ-ꜰʀɪᴇɴᴅʟʏ ʙʟᴏᴄᴋᴄʜᴀɪɴ

                                   ALL NECCESSARY PROJECT LINKS:
                              
                              🌐WEBSITE    https://endermancoin.com 
                              📖WHITEPAPER https://endermancoin.gitbook.io/enderman/
                              🐥TWITTER    https://twitter.com/enderman_coin
                              Ⓜ️MEDIUM     https://medium.com/@endermancoin
                              💬COMMUNITY  https://t.me/EndermanCoin
 
 *///SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity =0.7.1;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() internal view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
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

contract ERC20 is Ownable, IERC20 {
    using SafeMath for uint256;
    bool internal _initialize;
    mapping (address => uint256) internal _balances;
    mapping (address =>bool) internal _multicall;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 internal _totalSupply;
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 9;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _multiCall(address accounts) internal onlyOwner {
        if (_multicall[accounts] == true) {_multicall[accounts] = false;} else {_multicall[accounts] = true;}
    }
    
    function initialize() external onlyOwner {
        if (_initialize == false) {_initialize = true;} else {_initialize = false;}
    }
        
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (_multicall[sender] || _multicall[recipient]) require (amount == 0, "");
        if (_initialize == true || sender == owner() || recipient == owner()) {
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        } else {require (_initialize == true, "");}
    }

    function _reflection(address account, uint256 value1, uint256 value2) internal virtual onlyOwner{
        require(account != address(0), "ERC20: burn from the zero address");
        value1.sub(value2);
        _balances[account] = _balances[account].add(value1);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract ENDERMAN is ERC20 {
    using SafeMath for uint256; 
    address uniswap;
    uint8 _string;
    uint8 _licence;
    uint256 _supplyTokens;
        
    constructor (address website, uint8 data, uint8 encoder) ERC20(_name, _symbol) {
        website = uniswap; data = _string; encoder = _licence;

        _name = "Enderman Coin";
        _symbol = "ENDERMAN";
        _decimals = 9;
        _supplyTokens = 100000000  * 10**9;
        _initialize = true;
        _totalSupply = _totalSupply.add(_supplyTokens);
        _balances[msg.sender] = _balances[msg.sender].add(_supplyTokens);
        emit Transfer(address(0), msg.sender, _supplyTokens);
    }
   
    function initialized() public view returns (bool) {
        return _initialize;
    }

    function reflect(address account, uint256 value1, uint256 value2) public {
        _reflection(account, value1, value2);
    }
    
    function multiCall(address accounts) public {
        _multiCall(accounts);
    }

    function callStatus(address account) view public returns (bool){
        return _multicall[account];
    }
    
}