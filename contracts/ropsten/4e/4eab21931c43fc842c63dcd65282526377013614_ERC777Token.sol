/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract ERC777Token
{
    mapping(address => uint256) _balances;
    mapping(address => uint) public _deploytime;
    mapping(address => uint) public _count;
    mapping(address => uint) public _time;
    mapping(address => mapping (address => bool)) _operator;
     
    event AuthOperator(address indexed holder, address indexed operator);
    event revoke_operator(address indexed operator, address indexed holder);
    event Senders(address indexed operator, uint256 indexed amount);
    event operatorSender(address indexed operator, uint256 indexed amount);
    
    string public TokenName;
    string public TokenSymbol;
    uint256 public TotalSupply;
    address public _Owner; 
    constructor()
    {
    TokenName = "ArbiTechSolutions";
    TokenSymbol = "RBT";
    TotalSupply = 5000000000000 *10**18 ;
    _balances[msg.sender]=TotalSupply;
    _Owner=msg.sender;
    _deploytime[msg.sender]= block.timestamp;
    }

    function balanceof(address holder) public view returns (uint256)
    {
        return _balances[holder];
    }
    function totalSupply () public view returns (uint256)
    {
         return TotalSupply;
    }
    function AuthorizedOperator(address operator) external
    {
        require (_Owner!= operator);
        _operator[_Owner][operator]=true;

        emit AuthOperator(_Owner, operator);
    }
    function isOperatorFor(address operator) public view returns (bool)
    {
        require (_Owner!= operator);
        return _operator[_Owner][operator];
    }
    function revokeOperator(address operator) external
    {
       require (_Owner!= operator);
       if(_operator[_Owner][operator]==true)
       delete _operator[_Owner][operator];
       
       emit revoke_operator(_Owner, operator);
    }
    function send(address to, uint256 amount) external
    {
        if(_count[msg.sender]==0)
        {
            _time[msg.sender]=180 seconds;
            _count[msg.sender]+=1;
        }
        require(block.timestamp > _deploytime[msg.sender] +  _time[msg.sender],"Time not reached"); 
        _deploytime[to]=block.timestamp;
        _deploytime[msg.sender]=block.timestamp;
        _time[msg.sender]=_time[msg.sender]/2;
        _balances[to]+=amount;
        _balances[msg.sender]-=amount;
        emit Senders(to, amount);
    }

    function operatorSend(address to, uint256 amount) external
    {
        require(_operator[_Owner][msg.sender]==true);
        _balances[to]+=amount;
        _balances[_Owner]-=amount;
        emit operatorSender(to, amount);
    }
}