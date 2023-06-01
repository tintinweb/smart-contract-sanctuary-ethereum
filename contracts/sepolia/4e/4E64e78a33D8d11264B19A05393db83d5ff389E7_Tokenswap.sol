/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;


contract Tokenswap { 

    IERC20 public immutable ETHS;//Equivalent to eth

//Ethereum tokens
    IERC20 public immutable USDT;
    IERC20 public immutable DAI;

//TokenSwap token
    IERC20 public immutable TKSWAP;
    
//Amount invested by liquidity provider
    mapping ( address => uint256 ) public invested_amt;
    mapping ( address => uint256 ) public invested_amt_usdt;
    mapping ( address => uint256 ) public invested_amt_dai;

    address public owner;//Owner of the contract

   

    
    

    constructor(address _ETHS, address _USDT, address _DAI, address _TKSWAP) {
        
        ETHS = IERC20( _ETHS);
        USDT = IERC20(_USDT);
        DAI = IERC20(_DAI);
        TKSWAP = IERC20(_TKSWAP);
       
        owner = msg.sender;
       
    }

//Function to get Ethereum token for ETH
    function Swaptoken(uint tok1amt, uint tok) public {
        if( tok == 1){
            uint256 ethsbal = ETHS.balanceOf(msg.sender);
            uint256 usdtbal = USDT.balanceOf(address(this));

            require( (usdtbal >= tok1amt*1000000000000000000) && (ethsbal >= tok1amt*1000000000000000000) ,"Currently no balance!!");
            USDT.transferFrom(address(this),msg.sender,tok1amt*1000000000000000000);
            ETHS.transferFrom(msg.sender,address(this),tok1amt*1000000000000000000);

        }
        else{
             uint256 ethsbal = ETHS.balanceOf(msg.sender);
            uint256 daibal = DAI.balanceOf(address(this));

            require( (daibal >= tok1amt*1000000000000000000) && (ethsbal >= tok1amt*1000000000000000000) ,"Currently no balance!!");
            DAI.transferFrom(address(this), msg.sender, tok1amt*1000000000000000000);
            ETHS.transferFrom(msg.sender ,address(this), tok1amt*1000000000000000000);


        }
    }

//Function to get ETH for Ethereum token
     function Swapeth(uint ethamt, uint token) public {
        if( token == 1){
            uint256 ethsbal = ETHS.balanceOf(address(this));
            uint256 usdtbal = USDT.balanceOf(msg.sender);

            require( (usdtbal >= ethamt*1000000000000000000) && (ethsbal >= ethamt*1000000000000000000) ,"Currently no balance!!");
            USDT.transferFrom(msg.sender,address(this),ethamt*1000000000000000000);
            ETHS.transferFrom(address(this),msg.sender,ethamt*1000000000000000000);

        }
        else{
             uint256 ethsbal = ETHS.balanceOf(msg.sender);
            uint256 daibal = DAI.balanceOf(address(this));

            require( (daibal >= ethamt*1000000000000000000) && (ethsbal >= ethamt*1000000000000000000) ,"Currently no balance!!");
            DAI.transferFrom(msg.sender,address(this),ethamt*1000000000000000000);
            ETHS.transferFrom(address(this),msg.sender,ethamt*1000000000000000000);


        }
     }

//Function for Liquidity Provider to invest in TokenSwap
    function invest(uint investamt, uint investtok) public {
        if( investtok == 1 ){
            uint256 invest_usdt_bal = USDT.balanceOf(msg.sender);
            require( invest_usdt_bal >= investamt*1000000000000000000 );
            USDT.transferFrom(msg.sender,address(this),investamt*1000000000000000000);
            invested_amt_usdt[msg.sender] += investamt*1000000000000000000;
            TKSWAP.transferFrom(address(this),msg.sender,investamt*1000000000000000000*1/100);

        }

        else if( investtok == 2 ){
            uint256 invest_usdt_bal1 = USDT.balanceOf(msg.sender);
            require( invest_usdt_bal1 >= investamt*1000000000000000000 );
            DAI.transferFrom(msg.sender,address(this),investamt*1000000000000000000);
            invested_amt_dai[msg.sender] += investamt*1000000000000000000;
            TKSWAP.transferFrom(address(this),msg.sender,investamt*1000000000000000000*1/100);

        }
        else{
            uint256 invest_usdt_bal1 = USDT.balanceOf(msg.sender);
            require( invest_usdt_bal1 >= investamt*1000000000000000000 );
            ETHS.transferFrom(msg.sender,address(this),investamt*1000000000000000000);
            invested_amt[msg.sender] += investamt*1000000000000000000;
            TKSWAP.transferFrom(address(this),msg.sender,investamt*1000000000000000000*1/100);


        }
    }

//Function to get rewards of investment
 function Withdraw_reward( uint tks_amt ) public{
    uint256 reward_bal =  TKSWAP.balanceOf(msg.sender);
    uint256 rew_eth_bal = ETHS.balanceOf(address(this));
    require( (reward_bal >= tks_amt*1000000000000000000) && (rew_eth_bal >= tks_amt*1000000000000000000),"Not enough reweard!");
    TKSWAP.transferFrom(msg.sender , address(this),tks_amt*1000000000000000000);
    ETHS.transferFrom(address(this),msg.sender,tks_amt*1000000000000000000);


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