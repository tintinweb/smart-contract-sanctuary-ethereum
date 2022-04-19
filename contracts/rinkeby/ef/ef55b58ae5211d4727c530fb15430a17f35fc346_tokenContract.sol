/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract tokenContract {
 

    string public constant name = "techAlchemySatya";
    string public constant symbol = "TAS";
    uint8 public constant decimals = 0;  
    address public  masterAccount;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_;

    using SafeMath for uint256;
    address del1;
    address del2;

   constructor(address delegateOne,address delegateTwo)  {  
    del1=delegateOne;
    del2=delegateTwo;
	totalSupply_ = 1000000;
    masterAccount=msg.sender;
	balances[masterAccount] = totalSupply_;
    }  

    function totalSupply() public view returns (uint256) {
	return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[masterAccount][delegate] = numTokens;
        emit Approval(masterAccount, delegate, numTokens);
        return true;
    }
 
    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address delegate , uint numTokens) public returns (bool) {    
        require(numTokens <= allowed[masterAccount][delegate]);
    
        balances[masterAccount] = balances[masterAccount].sub(numTokens);
        balances[delegate]=balances[delegate].add(numTokens);
        require(numTokens <= balances[delegate]);
        allowed[masterAccount][delegate] = allowed[masterAccount][delegate].sub(numTokens);
        balances[delegate]=balances[delegate].sub(numTokens);
        balances[msg.sender] = balances[msg.sender].add(numTokens);
        emit Transfer(delegate,msg.sender, numTokens);
        return true;
    }
    function distributeTokens(string [] calldata data )public  returns (bool)
    {
        string memory result=trimStringMirroringChars(data);
        uint len=bytes(result).length;
        if(len>=0 && len<=5)
        {
            approve(del1,100);
            transferFrom(del1,100);
        }
        else{
            approve(del2,1000);
            transferFrom(del2,1000);
        }
        return true;
    }

 function substring(string memory str, uint startIndex, uint endIndex) public pure returns (string memory ) 
 {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex-startIndex);
    for(uint i = startIndex; i < endIndex; i++) {
        result[i-startIndex] = strBytes[i];
    }
    return string(result);
 }
 function trimStringMirroringChars(string [] calldata data) public pure returns(string memory )
{
    string memory result = data[data.length-1];
    if(data.length==1) return result;
    uint i=data.length-1;
    
    while(i>0)
    {
        bytes memory a=bytes(result);
        bytes memory b=bytes(data[i-1]);
        uint k=0;

        while(k<b.length && a.length>k)
        {
            if(b[k]!=a[a.length-1-k])
        {
            break;
        }
        k++;
        }
        if(k==b.length && a.length==k) 
        {
            result="";
        }
        else if(k==a.length)
        {
            result=substring(data[i-1],k,b.length);
        }
        else if(k==b.length)
        {
            
            result=substring(result,0,a.length-k);
        }
        else
        {
            result=string(abi.encodePacked(substring(result,0,a.length-k),substring(data[i-1],k,b.length)));
        }
       i=i-1;
    }

    return result;
}

}
    
library SafeMath { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }

}