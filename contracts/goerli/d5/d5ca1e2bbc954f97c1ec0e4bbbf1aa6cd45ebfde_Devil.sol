/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Devil is IERC20 {
    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;
    uint256 public totalSupply;

    string public name;
    string public symbol;
    string private _name;
    string private _symbol;
    uint public decimals;

    constructor(string memory name_, string memory symbol_, uint256 _initialSupply, uint _decimals) public IERC20 () {
        name = name_;
        symbol = symbol_;
        totalSupply = _initialSupply;
        decimals = _decimals;
        _mint(msg.sender, _initialSupply);
       }

    function transfer (address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
       emit Transfer(owner, to, amount);
        return true;
    }

    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");


        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

}