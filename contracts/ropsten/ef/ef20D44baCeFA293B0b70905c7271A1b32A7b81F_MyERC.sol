/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

pragma solidity ^0.6.2;

// library Safemath{
//     function add(uint a, uint b) public pure returns(uint){
//         uint c = a+b;
//         return c;
//     }
//      function sub(uint a, uint b) public pure returns(uint){
//         return a-b;
//     }
// }

contract MyERC{
    // using Safemath for uint;
    string public _name; 
    string public _symbol="psk";
    uint public _decimals=18;
    uint256 totalSupply_ = 100000*10**18; //wei
    mapping (address => mapping(address => uint))  allowed;
    mapping(address => uint256) balances;

    event Approval(address,address, uint );
    event Transfer(address,address, uint );
   
    constructor() public {
    _name = "saravana";
    balances[msg.sender] = totalSupply_;
    }

    function name() public view returns(string memory){
        return _name;
    }
    function symbol() public view returns(string memory){
        return _symbol;
    }
    function decimals() public view returns(uint){
        return _decimals;
    }
    
    function totalSupply() public view returns(uint){
        return totalSupply_;
    }

    function approve(address _delegate,uint _tokens) public returns(bool)
    {
        allowed[msg.sender][_delegate]=_tokens;
        emit Approval(msg.sender,_delegate,_tokens);
        return true;
    }

    function allowence(address owner,address decimalsAdddress) public view returns(uint)
    {
        return allowed[owner][decimalsAdddress];
    }

    function balanceOf(address owner_address) public view returns(uint)
    {
        return balances[owner_address];
    }

    function transfer(address _toaddress,uint num_token) public  returns(bool)
    {
        require(balances[msg.sender]>=num_token,"No of token issue");
        balances[_toaddress]=balances[_toaddress]+num_token;
        balances[msg.sender]=balances[msg.sender]-num_token;
        emit Transfer(msg.sender,_toaddress,num_token);
        return true;
    }

    function transferFrom (address _ownerAddress,address buyer,uint num_tokens) public returns(bool)
    {
        require(balances[_ownerAddress]>=num_tokens);
        require(allowed[_ownerAddress][msg.sender]>=num_tokens);
        balances[buyer]=balances[buyer]+num_tokens;
        balances[_ownerAddress]=balances[_ownerAddress]-num_tokens;
        allowed[_ownerAddress][msg.sender]= allowed [_ownerAddress][msg.sender]-num_tokens;
        emit Transfer(_ownerAddress,msg.sender,num_tokens);
        return true;
    }

}