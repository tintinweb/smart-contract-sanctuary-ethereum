/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

//SPDX-License-Identifier: MIT
pragma solidity >= 0.8.2 <0.9.0;
interface IERC20{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    
    function transfer(address _to, uint256 _amount) external returns(bool);
    function approve(address spender,uint256 _amount) external returns(bool);
    function transferFrom(address _from,address _to, uint256 _amount) external returns(bool);

    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
}

contract makeToken is IERC20{
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor(){
        name= "Alireza";
        symbol= "ATH";
        decimals= 10;
        _totalSupply= 1000000000;
        balances[msg.sender]= _totalSupply;
    }

    function totalSupply()public override view returns(uint256){
        return _totalSupply;
    }
    function balanceOf(address tokenOwner) public override view returns(uint256){
        return balances[tokenOwner];
    }
    
    function transfer(address receiver, uint256 numTokens) public override returns(bool){
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver,numTokens);
        return true;//numTokens: meghdarike mifrestim
    }

    function approve(address delegate,uint256 numTokens) public override returns(bool){
        allowed[msg.sender][delegate]= numTokens;// delegate: hamoon gharardade hooshmand hast ke ejaze midim andazeh numTokens kharj koneh.
        emit Approval(msg.sender,delegate,numTokens);
        return true;
    }
    function allowance(address owner,address delegate)public override view returns(uint){
        return allowed[owner][delegate];
    }
    function transferFrom(address owner,address buyer,uint256 numTokens)public override returns(bool){
     require(numTokens <= balances[owner]);
     require(numTokens <= allowed[owner][msg.sender]);
     balances[owner] = balances[owner].sub(numTokens); 
     allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
     balances[buyer]= balances[buyer].add(numTokens);
     emit Transfer(owner,buyer,numTokens);
     return true;  
    }
}



    library SafeMath{
        function sub(uint256 a,uint256 b) internal pure returns(uint256){
            assert(b <= a);
            return a - b;
        }
    
    function add(uint256 a, uint256 b) internal pure returns(uint256){
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}