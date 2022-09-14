/**
 *Submitted for verification at Etherscan.io on 2022-09-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface  IERC20 {
    function allowance(address tokenOwner, address spender) external  view returns (uint remaining);
    function balanceOf(address tokenOwner) external  view returns (uint balance);
    function totalSupply() external view  returns  (uint);
    function transferFrom(address from, address to, uint tokens) external  returns (bool success);
    function transfer(address to, uint tokens) external  returns (bool success);
    function approve(address spender, uint tokens) external  returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Supply(address indexed to, uint indexed amount, uint remainingSupply);
}

contract Token is IERC20  {
    
    string public name;
    string public symbol;
    uint8 public decimals; 
    address public owner;
    uint public rate;
    uint public time = block.timestamp; 
    uint public start = block.timestamp;
    uint public end = block.timestamp + 24 days;
    uint public startInvestor = start + 3 minutes;
    uint public startPrivate = startInvestor + 3 minutes;
    uint public startPublic = startPrivate + 6 minutes;
    uint public maximumSupply;
    
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private  allowed;
    mapping(address => bool) public blacklist;

    constructor()  {
        name = "Zartaj";
        symbol = "ZAR";
        decimals = 18;
        maximumSupply = 10000000 * 10**18;
        owner= msg.sender;
        
        balances[address(this)] = maximumSupply;
        emit Transfer(address(0), address(msg.sender), maximumSupply);
    }
    
       modifier ownable ()  {
        require (msg.sender== owner,"only owner can perform this");
        _;
    }

    modifier checkBlacklist (address _who){
        require(!blacklist[_who], "THIS ADDRESS IS BLACKLISTED BY OWNER OF THIS CONTRACT");
        _;
    }

    
    function  remainingToken() public view ownable returns (uint remainingSupply)  {

        return (balances[address(this)]);
    }

 
    function blackListing(address _who ) public  ownable {
        blacklist[_who] = true;

    }

    function whitelisting(address _who) public  ownable {
        blacklist[_who] = false;
    }

 

    function totalSupply() public override view returns (uint) {
        return maximumSupply ;
    }

    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public checkBlacklist(msg.sender) override returns (bool success)  {
        allowed[msg.sender][spender] = tokens * 10**18;
        emit Approval(msg.sender, spender, tokens * 10**18);
        return true;
    }

    function transfer(address to, uint tokens) public checkBlacklist(msg.sender) override returns (bool success) {
        balances[address(this)] = (balances[address(this)] -= tokens * 10**18);
        balances[to] = (balances[to] += tokens * 10**18);
        emit Transfer(msg.sender, to, tokens * 10**18);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public checkBlacklist(msg.sender) override returns (bool success) {
        require(balances[from] >=tokens * 10**18 , "You don't have enough tokens");
        require(allowed[from][msg.sender] >=tokens * 10**18 , "You are not allowwed to send tokens");
        balances[from] = (balances[from] -= tokens * 10**18);
        allowed[from][msg.sender] = (allowed[from][msg.sender] -= tokens * 10**18);
        balances[to] = (balances[to]+= tokens * 10**18);
        emit Transfer(from, to, tokens * 10**18);
        return true;
    }

   

    function burn (uint amount) public {
        require(balances[msg.sender] >= amount * 10**18, "not enough balance to burn");
        balances[msg.sender] -= amount * 10**18;
        emit Supply(msg.sender, amount * 10**18, remainingToken());
    }
   
    function buyToken (uint amount,address to) private checkBlacklist(msg.sender){
     
       uint tokenToTransfer = amount/rate;
       
       transfer(to, tokenToTransfer);
       
    }

    function presenTime () public view returns ( uint){
        return block.timestamp;
    }

     
    
    
    receive ()external payable{
                     
      if  (presenTime() <= startInvestor) {
         rate = 1e15;
         buyToken(msg.value,msg.sender);
         
      }   else if (presenTime() <= startPrivate) {
         rate = 2e15; 
         buyToken(msg.value,msg.sender);
       

      }   else if (presenTime() <= startPublic) {
          rate = 5e15;
          buyToken(msg.value,msg.sender);      
       
      }   else {
         revert ("sale is closed");
      }
          
    }


}