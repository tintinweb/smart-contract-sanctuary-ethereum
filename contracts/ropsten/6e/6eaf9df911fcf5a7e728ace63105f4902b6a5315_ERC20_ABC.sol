/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
contract ERC20_ABC
{
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowance;

    event Transfer(address indexed from,address indexed to, uint256 tak);
    event approval(address indexed from,address indexed to, uint256 take);

    string public TokenName;
    string public TokenSymbol;
    uint256 public TotalSupply;
    address admin;
    constructor()
    {
    TokenName= "ArbiTechSolutions";
    TokenSymbol="RBT";
    TotalSupply= 5000000000000 *10**18;
    balances[msg.sender]=TotalSupply;
    admin=msg.sender;
    }

    modifier checkadmin()
    {
        require (msg.sender==admin);
        _;
    }

    function transfer(address receiver , uint256 trantoken) public returns(bool)
    {
    require(trantoken<= balances[msg.sender]);
    balances[msg.sender] -= trantoken;
    balances[receiver] += trantoken;
    emit Transfer(msg.sender,receiver,trantoken);
    return true;
    }

    function balanceof(address Totalbal) public view returns (uint256)
    {
        return balances[Totalbal];
    }

    function mint (uint256 tokens) public checkadmin
    {
       TotalSupply += tokens;
       balances[msg.sender] += tokens;
    }

     
    function burn (uint256 tokens) public checkadmin
    {
       require(tokens<=balances[msg.sender]);
       TotalSupply -= tokens;
       balances[msg.sender] -= tokens;
    }

    function aproved(address spender, uint256 value) public returns(bool){
        allowance[msg.sender][spender]= value;
        emit approval(msg.sender, spender, value);
        return true;
    }

    function transferfrom(address owner, address recetoken,uint256 value) public returns(bool){
        uint256 _allowance= allowance[owner][msg.sender];
        require(balances[owner]>=value && _allowance >= value);
        balances[owner]-=value;
        balances[recetoken]+=value;
        allowance[owner][msg.sender]-=value;
        emit Transfer(owner,recetoken,value);
        return true;
    }

    function remaing(address owner, address spender)public view returns (uint256)
    {
        return allowance[owner][spender];
    }
}