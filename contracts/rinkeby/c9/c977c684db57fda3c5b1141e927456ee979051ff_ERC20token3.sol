/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
contract ERC20token3{
    string internal token3Name;
    string internal token3Symbol; 
    uint256 internal token3TotalSupply;//200
    uint256 internal  token3decimals; //10
    address internal owner;

    event Transfer(address from, address to, uint tokens);
    event Approval(address from,address to, uint tokens);

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allownce;

    constructor(){
        token3Name ="TOKEN3";
        token3Symbol = "TK3";
        token3TotalSupply=200;
        token3decimals = 10;
        token3TotalSupply = token3TotalSupply*(10**uint256(token3decimals));//200 * 10^8=;
        balances[msg.sender] += token3TotalSupply;
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY OWNERS CAN CALL!!");
        _;
    }
    
    function name()  public view returns(string memory) {
         return token3Name;
        }

    function symbol() public view returns(string memory) { 
        return token3Symbol;
        }

    function totalSupply()  public view returns(uint256) { 
        return token3TotalSupply;
        }

    function decimals()  public view returns(uint256) {
         return token3decimals;
         }

    function balanceOf(address tokenOwner)  public view returns(uint256){
         return balances[tokenOwner]; 
         }

    function transfer(address to, uint token)  public  returns(bool){
        require(balances[msg.sender] >= token, "YOU MUST HAVE A TOKEN TO PROCEES!!");
        balances[msg.sender] -= token;
        balances[to] += token;
        emit Transfer(msg.sender,to,token);
        return true;
    }
    function approve(address spender, uint tokens)  public returns(bool success) {
        require(balances[msg.sender]>= tokens,"YOU HAVENO SUFFICIENT TOKENS");
        allownce[msg.sender][spender] += tokens;
        emit Approval(msg.sender, spender,tokens);
        return true;

    }
    function allowance(address _owner, address spender)  public view returns(uint){
        return allownce[_owner][spender];
    }
    function transferFrom(address _owner, address to, uint tokens) public returns(bool success) {
        require(balances[_owner] >= tokens,"OWNER DON'T HAVE SUFFICIENT TOKENS!!");
        require(allownce[_owner][msg.sender] >= tokens,"SPENDER DONT HAVE SUFFICIENT APPROVED TOKENS!!");
        balances[_owner] -= tokens;
        balances[to] += tokens;
        allownce[_owner][msg.sender] -= tokens;
        emit Transfer(_owner,to,tokens);
        return true;
        
    }
    
}