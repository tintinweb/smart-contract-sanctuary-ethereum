/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// File: contracts/token.sol

   
//SPDX-License-Identifier: GPL-3.0
     
    pragma solidity >=0.5.0 <0.9.0;
    // ----------------------------------------------------------------------------
    // EIP-20: ERC-20 Token Standard
    // https://eips.ethereum.org/EIPS/eip-20
    // -----------------------------------------
     
    interface IERC20 {
        function totalSupply() external view returns (uint);
        function balanceOf(address tokenOwner) external view returns (uint balance);
        function transfer(address to, uint tokens) external returns (bool success);
        
        function allowance(address tokenOwner, address spender) external view returns (uint remaining);
        function approve(address spender, uint tokens) external returns (bool success);
        function transferFrom(address from, address to, uint tokens) external returns (bool success);
        
        event Transfer(address indexed from, address indexed to, uint tokens);
        event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    }
     
     
    contract Cryptos is IERC20{
        string public name = "GOQii";
        string public symbol = "GOQT";
        uint public decimals = 0; //18 is very common
        uint public override totalSupply;
        
        // address[] public accounts;
        
        address public founder;
        mapping(address => uint) public balances;
        // balances[0x1111...] = 100;
        
        mapping(address => mapping(address => uint)) allowed;
        // allowed[0x111][0x222] = 100;

        // mapping (uint256 => mapping (uint256 => Struct)) internal structs;

        // mapping (uint256 => uint256) public totalStructs;

        
        
        constructor(){
            totalSupply = 1000000;
            founder = msg.sender;
            balances[founder] = totalSupply;
            //  structs[0][0].accounts = msg.sender;
            //  totalStructs[0] = 1;
        }



        
        
        function balanceOf(address tokenOwner) public view override returns (uint balance){
            return balances[tokenOwner];
        }
        
        
        function transfer(address to, uint tokens) public override returns(bool success){
            require(balances[msg.sender] >= tokens);
            
            balances[to] += tokens;
            balances[msg.sender] -= tokens;
            emit Transfer(msg.sender, to, tokens);
            
            return true;
        }
        
        
        function allowance(address tokenOwner, address spender) view public override returns(uint){
            return allowed[tokenOwner][spender];
        }
        
        
        function approve(address spender, uint tokens) public override returns (bool success){
            require(balances[msg.sender] >= tokens);
            require(tokens > 0);
            
            allowed[msg.sender][spender] = tokens;
            
            emit Approval(msg.sender, spender, tokens);
            return true;
        }
        
        
        function transferFrom(address from, address to, uint tokens) public override returns (bool success){
             require(allowed[from][msg.sender] >= tokens);
             require(balances[from] >= tokens);
             
             balances[from] -= tokens;
             allowed[from][msg.sender] -= tokens;
             balances[to] += tokens;
     
             emit Transfer(from, to, tokens);
             
             return true;
         }

         function bulkAirdropERC20(IERC20 _token, address[]  calldata _to, uint256[] calldata _value) public {
            // require (_to.length == _value.length);
            for(uint i = 0; i<= _to.length ; i++){
                require (_token.transferFrom(msg.sender, _to[i], _value[i] ));
            }
        }
    
    }