/**
 *Submitted for verification at Etherscan.io on 2022-09-15
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
}

contract Token is IERC20  {
    
    address public  owner;
    string public name;
    string public symbol;
    uint8 public decimals; 
    uint public rate;
    uint public start = block.timestamp;
    uint public end = block.timestamp + 9 minutes;
    uint public startInvestor = start + 3 minutes;
    uint public startPrivate = startInvestor + 3 minutes;
    uint public startPublic = startPrivate + 3 minutes;
    uint public maximumSupply;
    uint public supplyInMarket;
                                 
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private  allowed;
    mapping(address => bool) public blacklist;

    constructor()  {
        name = "ZartajTESTING";
        symbol = "ZAR2";
        decimals = 18;
        maximumSupply = 10000000 * 10**18;
        owner= msg.sender;
            
        balances[address(this)] = maximumSupply;
        emit Transfer(address(0), address(this), maximumSupply);
    }

    //Modifiers
    
    modifier ownable()  {
        require (msg.sender== owner,"ONLY OWNER CAN PERFORM THIS ACTION");
        _;
    } 

    modifier checkBlacklist(address _who){
        require(!blacklist[_who], "THIS ADDRESS IS BLACKLISTED BY OWNER OF THIS CONTRACT");
        _;
    }

    //Read Only Functions

    //How much token is remaining for sale?
 
    function  remainingToken() public view ownable returns (uint remainingSupply)  {

        return (balances[address(this)]);
    }

    //Real time

    function presenTime () public view returns ( uint){
        return block.timestamp;
    }  
   
    //Total Supply
    
    function totalSupply() public override view returns (uint) {
        return maximumSupply ;
    }
     
    //Total Ether Contributed  
    
    function totalContribution() public ownable view returns(uint){
        return address(this).balance;
    }

    //Token balance of any address 

    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    //Check Allowance

    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    //Write Functions

    //Blacklisiting function

    function blackListing(address _who ) public  ownable {
        blacklist[_who] = true;

    }

    //Whitelisiting function

    function whitelisting(address _who) public  ownable {
        blacklist[_who] = false;
    }

    //Ether Transfer Function

    function transferFundsToOwner(address payable to) public ownable {
        require(presenTime()>end ,"THE ETHERS ARE ONLY TRANSFERABLE AFTER THE SALE IS OVER" );
        to.transfer(address(this).balance);
    }

    //remaining tokens transfer function

    function withdrawRemainingTokens(address  to) public ownable {
        require(presenTime()>end ,"THE REMAINING TOKENS ARE ONLY TRANSFERABLE AFTER THE SALE IS OVER" );
        transfer(to,balances[address(this)]);
    }

    //approve Function

    function approve(address spender, uint tokens) public checkBlacklist(msg.sender) override returns (bool success)  {
        allowed[msg.sender][spender] = tokens ;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    //transfer Function

    function transfer(address to, uint tokens) public checkBlacklist(msg.sender)  override returns (bool success) {
        require(balances[msg.sender] >= tokens , "NOT ENOUGH BALANCE");
        balances[msg.sender] = (balances[msg.sender] -= tokens);
        balances[to] = (balances[to] += tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    //transferFrom Function

    function transferFrom(address from, address to, uint tokens) public checkBlacklist(msg.sender) override returns (bool success) {
        require(allowed[from][msg.sender] >=tokens , "YOU ARE NOT ALLOWED TO SEND THE TOKENS");
        require(balances[from] >=tokens  , "YOU DON'T HAVE ENOUGH TOKENS");
        balances[from] = (balances[from] -= tokens);
        allowed[from][msg.sender] = (allowed[from][msg.sender] -= tokens );
        balances[to] = (balances[to]+= tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    // Burn Function

    function burn(uint amount) public {
        transfer(address(0),amount);
        supplyInMarket -= amount;

    }
   
    //BuyToken Function 

    function buyToken(uint amount,address to) private checkBlacklist(msg.sender){

        uint tokenToTransfer = (amount * 10**18) /rate ;
       
        balances[address(this)] = (balances[address(this)] -= tokenToTransfer );
        balances[to] = (balances[to] += tokenToTransfer);
        supplyInMarket += tokenToTransfer;
        emit Transfer(address(this), to, tokenToTransfer);
       
    }

    //receive Function
    
    receive() external payable{
                     
         if  (presenTime() <= startInvestor) {
           rate = 1e15;
           buyToken(msg.value,msg.sender);
         
        } else if (presenTime() <= startPrivate) {
           rate = 2e15; 
           buyToken(msg.value,msg.sender);
       
        } else if (presenTime() <= startPublic) {
            rate = 5e15;
            buyToken(msg.value,msg.sender);      
       
        } else {
          revert ("SALE IS CLOSED");
        }
          
    }

}