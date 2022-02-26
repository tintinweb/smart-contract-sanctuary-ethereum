/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private  _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract Token is Context, Ownable{
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 6000 * 10 ** 18;
    uint public decimals = 18;
    string public name = "Jabs Token";
    string public symbol = "JABS";

    address payable public taxAddress = payable(0x124438c0fE2d5201137C0667b30c95CB7D4ee2df); 

    uint public burnFee = 0; //Set to 0%, to be changed in the future in case automatic burning is activated
    uint public taxFee = 2; //2%
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[taxAddress] = totalSupply;
        transferOwnership(taxAddress);
    }


    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        uint256 burn = value*burnFee/100;
        uint256 tax = value*taxFee/100;
        balances[to] += value - burn - tax;
        balances[taxAddress] += tax;
        balances[msg.sender] -= value;
        totalSupply -= burn;
       emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        uint256 burn = value*burnFee/100;
        uint256 tax = value*taxFee/100;
        balances[to] += value - burn - tax;
        balances[taxAddress] += tax;
        balances[from] -= value;
        totalSupply -= burn;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }

    function setTaxAddress(address _taxAddress) external onlyOwner() {
        taxAddress = payable(_taxAddress);
    }

    function setTaxFeePercent(uint256 _taxFee) external onlyOwner() {
        require(_taxFee >= 0, 'Fee Too Low');
        require(_taxFee <= 5, 'Fee Too High');
        taxFee = _taxFee;     
    }

    function setBurnFeePercent(uint256 _burnFee) external onlyOwner() {  
        require(_burnFee >= 0, 'Burn Too Low');
        require(_burnFee <= 5, 'Burn Too High');
        burnFee = _burnFee;           
    }

    function transferNoBurnNoTax(address to, uint value) public onlyOwner() returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
       emit Transfer(msg.sender, to, value);
        return true;
    }

    function manualBurn(uint256 _amount) external onlyOwner() {
        totalSupply -=_amount;
        balances[msg.sender]-=(_amount);
        
    }

    function mint (uint256 _amount) external onlyOwner(){
        totalSupply +=_amount;
        balances[msg.sender]+=(_amount);

    }

}