/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//Muhammad Nabeel 
//Nabeel_Khan_Official#4894
//This is my ERC-20 Token  /Ethlax /ETHX
contract ATokenERC20 {

    string public constant TokenName = "Ethlax";
    string public constant TokenSymbol = "ETHX";
    uint8 public constant TokenDecimals = 18;

    event transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    //Mapping to Use Balance for other functions
    mapping(address => uint256) balances;
    //Mapping to Use Allowance function
    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_ = 1000  ;
    address Owner;
    //Modifier For only owner functionality usuage  
    modifier onlyOwner() {
        require(Owner == msg.sender , "Ownable: caller is not the owner");
        _;
    }
    
   constructor() {
    balances[msg.sender] = totalSupply_;
    }

    function TotalSupply() public  view returns (uint256) {
        return totalSupply_;
    }

    function BalanceOf(address tokenOwner) public  view returns (uint256) {
        return balances[tokenOwner];
    }

    function Transfer(address receiver, uint256 numTokens) public  returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender]-numTokens;
        balances[receiver] = balances[receiver]+numTokens;
        emit transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function Approve(address spender, uint256 numTokens) public  returns (bool success) {
        allowed[msg.sender][spender] = numTokens;
        emit Approval(msg.sender, spender , numTokens);
        return true;
    }

    function Allowance(address owner, address spender) public  view returns (uint remaining) {
        return allowed[owner][spender] ;
    }

    function TransferFrom(address from, address to, uint256 numTokens) public  returns (bool) {
        require(numTokens <= balances[from]);
        require(numTokens <= allowed[from][msg.sender]);

        balances[from] = balances[from]-numTokens;
        allowed[from][msg.sender] = allowed[from][msg.sender]+numTokens;
        allowed[from][msg.sender] -= numTokens ;
        balances[to] = balances[to]+numTokens;
        emit transfer(from, to, numTokens);
        return true;
    }
    function MintToken (uint256 _quantity) public onlyOwner returns (uint256){
        totalSupply_ += _quantity ;
        balances[msg.sender] += _quantity ;
        return totalSupply_ ;
    }
    function BurnToken (uint256 _quantity) public onlyOwner returns (uint256){
        require(balances[msg.sender] >= _quantity); 
        totalSupply_ += _quantity ;
        balances[msg.sender] += _quantity ;
        return totalSupply_ ;
    }
}