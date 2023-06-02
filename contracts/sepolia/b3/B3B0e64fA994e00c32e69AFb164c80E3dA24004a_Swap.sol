/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;


contract Swap { 

    IERC20 public immutable Token1;
    IERC20 public immutable Token2;
    IERC20 public immutable Token3;


    address public owner;

    mapping (address => uint) token1_bal;
    mapping (address => uint) token2_bal;

//invested amount by Liquidity Provider
    mapping (address => uint) invested_tok1;
    mapping (address => uint) invested_tok2;
    mapping (address => uint) invested_tok3;


    constructor(address _Token1, address _Token2, address _Token3) {
        
        Token1 = IERC20( _Token1);
        Token2 = IERC20(_Token2);
        Token3 = IERC20(_Token3);
        owner = msg.sender;
       
    }

    function Swap_token1(uint amount, uint option) public{

        if( option == 1){
        require( Token1.balanceOf(msg.sender) >= amount, "No balance");
        require( Token2.balanceOf(address(this)) >= amount, "No balance in contract");
        Token1.transferFrom( msg.sender, address(this), amount );
        Token2.transfer( msg.sender, amount );
        }
        else if(option == 2){
        require( Token1.balanceOf(msg.sender) >= amount, "No balance");
        require( Token3.balanceOf(address(this)) >= amount, "No balance in contract");
        Token1.transferFrom( msg.sender, address(this), amount );
        Token3.transfer( msg.sender, amount );  
        }


    }

    function Swap_token2(uint amount1, uint option1) public{

        if( option1 == 1){
        require( Token2.balanceOf(msg.sender) >= amount1, "No balance");
        require( Token1.balanceOf(address(this)) >= amount1, "No balance in contract");
        Token2.transferFrom( msg.sender, address(this), amount1 );
        Token1.transfer( msg.sender, amount1 );
        }
        else if(option1 == 2){
        require( Token2.balanceOf(msg.sender) >= amount1, "No balance");
        require( Token3.balanceOf(address(this)) >= amount1, "No balance in contract");
        Token2.transferFrom( msg.sender, address(this), amount1 );
        Token3.transfer( msg.sender, amount1 );   
        }
    }

    function Swap_token3(uint amount2, uint option2) public{

        if( option2 == 1){
        require( Token3.balanceOf(msg.sender) >= amount2, "No balance");
        require( Token1.balanceOf(address(this)) >= amount2, "No balance in contract");
        Token3.transferFrom( msg.sender, address(this), amount2 );
        Token1.transfer( msg.sender, amount2 );
        }
        else if(option2 == 2){
        require( Token3.balanceOf(msg.sender) >= amount2, "No balance");
        require( Token2.balanceOf(address(this)) >= amount2, "No balance in contract");
        Token3.transferFrom( msg.sender, address(this), amount2 );
        Token2.transfer( msg.sender, amount2 );   
        }
    }

    function invest( uint invest_amt, uint inv_opt) public{

        if(inv_opt == 1){
            require( Token1.balanceOf(msg.sender) >= invest_amt, "No balance");
            Token1.transferFrom( msg.sender, address(this), invest_amt );
            invested_tok1[msg.sender] += invest_amt;

        }
        else if(inv_opt == 2){
            require( Token2.balanceOf(msg.sender) >= invest_amt, "No balance");
            Token2.transferFrom( msg.sender, address(this), invest_amt );
            invested_tok2[msg.sender] += invest_amt;

        }
        else if(inv_opt == 3){
            require( Token3.balanceOf(msg.sender) >= invest_amt, "No balance");
            Token3.transferFrom( msg.sender, address(this), invest_amt );
            invested_tok3[msg.sender] += invest_amt;

        }

    }


}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function mint(uint total) external;

    function burn(address burner, uint amt) external;

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}