/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: GPL-3.0
//SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;
contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 100000000 * 10 ** 18;
    string public name = "Cascade";
    string public symbol = "CSD";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
       emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}




contract Project {
    enum State{
        collecting,
        expired
    }
    constructor 
    (address payable ProjectCreator,string memory ProjectTitle,string memory ProjectDescription
    ,uint ProjectObjective) 
    
    {
        _creator=ProjectCreator;
        _title=ProjectTitle;
        _description=ProjectDescription;
        _objective=ProjectObjective;
        _actualState= State.collecting;
        _totalCollected=0;
        _totalInvestors=0;
    }
    uint _totalCollected;
    string _title;
    string _description;
    uint _objective;
    uint _totalAmount;
    uint _totalInvestors;
    address payable _creator;
    State _actualState;
    mapping(address => uint) InvestorStats;
    mapping(address => uint) balance;
    event newInvestor(address investor,uint amount);
    event Finished(uint,uint);
    function getTitle() public view returns (string memory){
            return _title;

                                                         }
    function getDescription() public view returns (string memory){
            return _description;

                                                         }
    function getObjective() public view returns (uint){
            return _objective;

                                                         }
    function getTotalCollected() public view returns (uint){
            return _totalAmount;

                                                }
    function getCreator() public view returns (address){
            return _creator;

                                                }

    modifier ComproveState{
        require(_actualState==State.collecting);
        _;
    }
    modifier isntCreator{
        require(msg.sender!=_creator);
        _;
    }

    function invest(uint amount) public ComproveState isntCreator {
        require(amount>0);
        balance[msg.sender]-=amount;
        balance[_creator]+=amount;
        emit newInvestor(msg.sender,amount);
        _totalCollected+=amount;
        _totalInvestors++;
    }
    function comproveIfDone()public returns (bool) {
        bool temp;
        if(_totalCollected>=_objective){
            _actualState=State.expired;
            emit Finished(_totalCollected,_totalInvestors);
            
            temp=true;
                                       }
        else{ temp=false;}
        return temp;
    }


}