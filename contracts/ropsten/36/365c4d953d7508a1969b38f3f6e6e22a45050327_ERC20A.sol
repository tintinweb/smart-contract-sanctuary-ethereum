/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract ERC20A{
    string internal tName; ///PakistanRawalpindi
    string internal tSymbol; //PK
    uint256 internal tTotalSupply;//5000
    uint256 internal  tdecimals; //10
    address internal owner;

    event Transfer(address from, address to, uint tokens);
    event Approval(address from,address to, uint tokens);

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allownce;

    constructor(){
        tName ="Diamond";
        tSymbol = "DMD";
        tTotalSupply=9000;
        tdecimals = 10;
        tTotalSupply = tTotalSupply*(10**uint256(tdecimals));//6000 * 10^8=600000000000
        balances[msg.sender] += tTotalSupply;
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this method");
        _;
    }
    
    function name()  public view returns(string memory) {
         return tName;
        }
    function symbol() public view returns(string memory) { 
        return tSymbol;
        }
    function totalSupply()  public view returns(uint256) { 
        return tTotalSupply;
        }
    function decimals()  public view returns(uint256) {
         return tdecimals;
         }

    function balanceOf(address tokenOwner)  public view returns(uint256){
         return balances[tokenOwner]; 
         }

    function transfer(address to, uint token)  public  returns(bool){
        require(balances[msg.sender] >= token, "you should have some token");
        balances[msg.sender] -= token;
        balances[to] += token;
        emit Transfer(msg.sender,to,token);
        return true;
    }
    function approve(address spender, uint tokens)  public returns(bool success) {
        require(balances[msg.sender]>= tokens,"You have not sufficient tokens");
        allownce[msg.sender][spender] += tokens;
        emit Approval(msg.sender, spender,tokens);
        return true;

    }
    function allowance(address _owner, address spender)  public view returns(uint){
        return allownce[_owner][spender];
    }
    function transferFrom(address _owner, address to, uint tokens) public returns(bool success) {
        require(balances[_owner] >= tokens,"Owner has not sufficient tokens");
        require(allownce[_owner][msg.sender] >= tokens,"Spender has not sufficient approved tokens");
        balances[_owner] -= tokens;
        balances[to] += tokens;
        allownce[_owner][msg.sender] -= tokens;
        emit Transfer(_owner,to,tokens);
        return true;
        
    }

    
}