/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

/**

Are you starting to see the big picture yet? They want you demoralized and dependent on them, 
every passing day that Seiryü endures only further threatens the chain of command and jeopardizes 
their position within. How many alternatives have they tried to feed you as distractions in the 
meantime that are already dead on arrival? These attacks will continue to intensify exponentially -
they will come and go as they please regardless, in order to break the cycle you must first refuse 
to inherit dysfunction. United we stand, divided they fall. Power to the people.

--seiryu--

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return a - b;}
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b <= a, errorMessage); return a - b;}}
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

contract NEXTISTATSU is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = 'We are coming AZURE (TATsu)';
    string private constant _symbol = 'Tatsu';
    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 1 * 10**6 * (10 ** _decimals);
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    constructor() Ownable(msg.sender) {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function totalSupply() public view override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
}