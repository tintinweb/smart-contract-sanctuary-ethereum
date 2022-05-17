/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'add overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'sub underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'mul overflow');
    }
}

contract Coinic{

    // ::-:: coinic multisig wallet
    // ::-:: connect with brave wallet and sign
    // ::-:: ❝chain.devops❞

    address   public root;
    address[] public ownership;
    mapping(address => bool) isallottee;

    uint      public level;

    //new Allottee
    address   public whojoin;
    uint      public accept_join;
    address[] public accept_join_list;

    //delete Allottee
    address   public whodelete;
    uint      public accept_delete;
    address[] public accept_delete_list;

    using SafeMath for *;

    //deposit
    mapping(address => uint) public deposit_list;
    uint public contractbudget;

    //events
    event Deposit(uint timestamp, address EOA, uint amount);
    event Withdraw(uint timestamp, address EOA, uint amount);

    event WhoJoin(uint timestamp, address EOA);
    event WhoDelete(uint timestamp, address EOA);

    event Join(uint timestamp, address EOA);
    event Delete(uint timestamp, address EOA);
    
    constructor(){
        root = msg.sender;
        ownership.push(msg.sender);
        isallottee[msg.sender] = true;
        level = 1;
    }
    
    //set new allottee by root
    function set_new_allottee(address _newAllottee) OnlyRoot external{
        require(isallottee[_newAllottee] != true,'already be an owner');
        require(_newAllottee != address(0),'zero address not support');
        whojoin = _newAllottee;
        emit WhoJoin(block.timestamp, _newAllottee);
    }

    //set delete allottee by root
    function set_delete_allottee(address _deleteAllottee) OnlyRoot external{
        require(_deleteAllottee != root,'delete allottee must not the root');
        require(isallottee[_deleteAllottee] == true,'not an owner');
        require(_deleteAllottee != address(0),'zero address not support');
        whodelete = _deleteAllottee;
        emit WhoDelete(block.timestamp, _deleteAllottee);
    }

    //set new sign level by root
    function change_sign(uint _newsign) OnlyRoot external{
        require(_newsign != level,'already set');
        require(_newsign <= ownership.length,'new sign level must less or equal to the max owners');
        require(_newsign != 0,'not accept the zero as new sign level');
        level = _newsign;
    }

    //sign new allottee by Allottees
    function sign_new_allottee() OnlyAllottee external{
        require(whojoin != address(0),'require whojoin address');
        require(notsign_toadd(),'already sign');

        accept_join_list.push(msg.sender);
        accept_join++;

        if(accept_join == level){
            ownership.push(whojoin);
            isallottee[whojoin] = true;
            emit Join(block.timestamp, whojoin);

            whojoin = address(0);
            clear_toadd();
            accept_join = 0;
        }

        //@safe check
        if(accept_join > level){
            clear_toadd();
            accept_join = 0;
        }
    }

    //sign delete allottee by Allottees
    function sign_delete_allottee() OnlyAllottee external{
        require(whodelete != address(0),'require whodelete address');
        require(notsign_todelete(),'already sign');
        
        accept_delete_list.push(msg.sender);
        accept_delete++;

        if(accept_delete == level){
            uint index = find(whodelete);
            burn(index);
            isallottee[whodelete] = false;
            emit Delete(block.timestamp, whodelete);

            whodelete = address(0);
            clear_todelete();
            accept_delete = 0;
        }

        //@safe check
        if(accept_delete > level){
            clear_todelete();
            accept_delete = 0;
        } 
    }

    //receive funds from other smart contracts or miners
    fallback() external payable{deposit();}
    receive() external payable{deposit();}

    //deposit by EOAs
    function deposit() internal{
        require(msg.value > 0,'no deposit');
        deposit_list[msg.sender] = deposit_list[msg.sender].add(msg.value);
        contractbudget = contractbudget.add(msg.value);
        emit Deposit(block.timestamp, msg.sender, msg.value);
    }

    //withdraw by allottee
    function withdraw(uint amount) OnlyAllottee external{
        require(amount > 0,'no withdraw');
        require(amount <= address(this).balance,'lack of amount');
        contractbudget = contractbudget.sub(amount);
        bool sent = payable(msg.sender).send(amount);
        require(sent, "transaction has been failed");
        emit Withdraw(block.timestamp, msg.sender, amount);
    }

    //check allottee status
    function allottee_status(address user) external view returns(bool){
        return isallottee[user];
    }

    //internal - modifier namespace
    modifier OnlyAllottee(){
        bool satisfy = false;
        for(uint i=0;i<ownership.length;i++){
            if(isallottee[tx.origin] == true)
                satisfy = true;
        }
        require(satisfy,'not an allottee');
        _;
    }

    modifier OnlyRoot(){
        require(msg.sender == root,'only root');
        _;
    }

    //internal - internal task
    function notsign_toadd() internal view returns(bool){
        for(uint i=0;i<accept_join_list.length;i++){
            if(accept_join_list[i] == msg.sender){
                return false;
            }
        }
        return true;
    }

    function notsign_todelete() internal view returns(bool){
        for(uint i=0;i<accept_delete_list.length;i++){
            if(accept_delete_list[i] == msg.sender){
                return false;
            }
        }
        return true;
    }

    function clear_toadd() internal{
        for(uint256 i = 0; i < accept_join_list.length-1; i++){
            accept_join_list[i] = accept_join_list[i+1];      
        }
        accept_join_list.pop();
    }

    function clear_todelete() internal{
        for(uint256 i = 0; i < accept_delete_list.length-1; i++){
            accept_delete_list[i] = accept_delete_list[i+1];      
        }
        accept_delete_list.pop();
    }

    function find(address _item) internal view returns(uint index){
        for(uint i=0;i<ownership.length;i++){
            if(ownership[i] == _item){
                return i;
            }
        }
    }

    function burn(uint index) internal {
        require(index < ownership.length);
        ownership[index] = ownership[ownership.length-1];
        ownership.pop();
    }
}