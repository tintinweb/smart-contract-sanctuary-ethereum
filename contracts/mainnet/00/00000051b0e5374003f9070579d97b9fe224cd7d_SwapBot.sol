/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

pragma solidity ^0.4.18;

// Copyright (C) 2022, 2023, 2024, https://robot.bi

// DEX trading bot includes three parts.
// 1.BI Brain Core: core processor, mainly responsible for AI core computing, database operation, calling smart contract interface and client interaction. 
// 2.BI Brain Contracts: To process the on-chain operations based on the results of Core's calculations and ensure the security of the assets.
//    SwapBot.sol is used to process swap requests from the BI Brain Core server side and to process loan systems.
//    EncryptedSwap.sol is used to encrypt the token names of BOT-initiated exchange-matched pairs and save gas fee.
//    WrappedEtherGasOptimization.sol is used to help users swap assets between ETH, WETH and BOT.
//    BotShareToken.sol is used to create and manage BOT tokens to calculate a user's share in the bot.
// 3.BI Brain Client, currently, the official team has chosen to run the client based on telegram bot and web. Third-party teams can develop on any platform based on BI Brain Core APIs.

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
interface ERC20 {
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function totalSupply() external view returns (uint);
}

interface Swap {
    function EncryptedSwapExchange(address from,address toUser,uint amount) external view returns(bool);
}



contract SwapBot {

    address public owner;
    address public poolKeeper;
    address public secondKeeper;
    address public banker;
    uint public feeRate;// unit: 1/10 percent

    address public BOT;
    address public SRC;
    address public STC;
    address[3] public WETH;
    mapping (address => uint)  public  debt;
    uint bankorder;
    mapping (uint => mapping (address => uint))  public  staked;
    mapping (uint => mapping (address => uint))  public borrowed;   

    constructor (address _keeper,address _bot,address _stc,address _src,address _weth1,address _weth2,address _weth3,address _banker) public {
        owner = msg.sender;
        poolKeeper = _keeper;
        secondKeeper = _keeper; 
        feeRate = 1;
        WETH = [_weth1, _weth2, _weth3];  
        STC = _stc;
        BOT = _bot;
        SRC = _src;
        banker = _banker;
        bankorder = 0;
    }



    event  EncryptedSwap(address indexed tokenA,uint amountA,address indexed tokenB,uint amountB);
    event  Borrow(address indexed tokenA,uint amountA,address indexed tokenB,uint amountB);
    event  Clean(address indexed tokenA,uint amountA,address indexed tokenB,uint amountB);


    modifier keepPool() {
        require((msg.sender == poolKeeper)||(msg.sender == secondKeeper));
        _;
    }

    function PoolRelease(address tkn,address guy,uint amount) public keepPool returns(bool) {
        ERC20 token = ERC20(tkn);
        token.transfer(guy, amount);
        return true;
    }

    function BotEncryptedSwap(address tokenA,address tokenB,address AddressA,address AddressB,uint amountA,uint amountB) public returns (bool) {
        require((msg.sender == poolKeeper)||(msg.sender == secondKeeper));
        if(ERC20(tokenA).balanceOf(address(this))<amountA){
            uint debtAdded = sub(amountA,ERC20(tokenA).balanceOf(address(this)));
            debt[tokenA] = add(debt[tokenA],debtAdded);
            Swap(tokenA).EncryptedSwapExchange(AddressA,address(this),debtAdded);           
        }
        Swap(tokenA).EncryptedSwapExchange(address(this),AddressA,amountA);
        uint fee = div(mul(div(mul(debt[tokenB],1000000000000000000),1000),feeRate),1000000000000000000);
        if((add(fee,debt[tokenB])<=amountB)&&(debt[tokenB]>0)){
            Swap(tokenB).EncryptedSwapExchange(AddressB,banker,add(debt[tokenB],fee));            
            amountB = sub(amountB,add(debt[tokenB],fee));
            debt[tokenB] = 0;
        }
        Swap(tokenB).EncryptedSwapExchange(AddressB,address(this),amountB); 
        emit EncryptedSwap(tokenA,amountA,tokenB,amountB);  
        return true;
    }

    function borrow(address tokenA,address tokenB,address AddressA,address AddressB,uint amountA,uint amountB) public returns (bool) {
        require((msg.sender == poolKeeper)||(msg.sender == secondKeeper));
        if(ERC20(tokenA).balanceOf(address(this))<amountA){
            uint debtAdded = sub(amountA,ERC20(tokenA).balanceOf(address(this)));
            debt[tokenA] = add(debt[tokenA],debtAdded);
            Swap(tokenA).EncryptedSwapExchange(AddressA,address(this),debtAdded);           
        }
        Swap(tokenA).EncryptedSwapExchange(address(this),AddressA,amountA);
        uint fee = div(mul(div(mul(debt[tokenB],1000000000000000000),1000),feeRate),1000000000000000000);
        if((add(fee,debt[tokenB])<=amountB)&&(debt[tokenB]>0)){
            Swap(tokenB).EncryptedSwapExchange(AddressB,banker,add(debt[tokenB],fee));            
            amountB = sub(amountB,add(debt[tokenB],fee));
            debt[tokenB] = 0;
        }
        Swap(tokenB).EncryptedSwapExchange(AddressB,address(this),amountB); 
        emit Borrow(tokenA,amountA,tokenB,amountB);  
        return true;
    }

    function clean(address tokenA,address tokenB,address AddressA,address AddressB,uint amountA,uint amountB) public returns (bool) {
        require((msg.sender == poolKeeper)||(msg.sender == secondKeeper));
        if(ERC20(tokenA).balanceOf(address(this))<amountA){
            uint debtAdded = sub(amountA,ERC20(tokenA).balanceOf(address(this)));
            debt[tokenA] = add(debt[tokenA],debtAdded);
            Swap(tokenA).EncryptedSwapExchange(AddressA,address(this),debtAdded);           
        }
        Swap(tokenA).EncryptedSwapExchange(address(this),AddressA,amountA);
        uint fee = div(mul(div(mul(debt[tokenB],1000000000000000000),1000),feeRate),1000000000000000000);
        if((add(fee,debt[tokenB])<=amountB)&&(debt[tokenB]>0)){
            Swap(tokenB).EncryptedSwapExchange(AddressB,banker,add(debt[tokenB],fee));            
            amountB = sub(amountB,add(debt[tokenB],fee));
            debt[tokenB] = 0;
        }
        Swap(tokenB).EncryptedSwapExchange(AddressB,address(this),amountB); 
        emit Clean(tokenA,amountA,tokenB,amountB);  
        return true;
    }




    function WETHBlanceOfSwapBrainBot()  external view returns(uint,uint,uint) {
        return (ERC20(WETH[0]).balanceOf(address(this)),
                ERC20(WETH[1]).balanceOf(address(this)),
                ERC20(WETH[2]).balanceOf(address(this)));      
    }

    function STCBlanceOfSwapBrainBot()  external view returns(uint) {
        return (ERC20(STC).balanceOf(address(this)));      
    }

    function WETHBlanceOfBOTTokenContract()  external view returns(uint,uint,uint) {
        return (ERC20(WETH[0]).balanceOf(BOT),
                ERC20(WETH[1]).balanceOf(BOT),
                ERC20(WETH[2]).balanceOf(BOT));      
    }

    function BOTTotalSupply()  external view returns(uint) {
        return (ERC20(BOT).totalSupply());      
    }



    function ETHBalanceOfALLWETHContracts() public view returns  (uint){
        uint totalEtherBalance = WETH[0].balance;
        totalEtherBalance = add(totalEtherBalance,WETH[1].balance);
        totalEtherBalance = add(totalEtherBalance,WETH[2].balance);
        return totalEtherBalance;
    }

    function resetOwner(address _owner) public returns (bool) {
        require(msg.sender == owner);
        owner = _owner;
        return true;
    }

    function resetPoolKeeper(address newKeeper) public keepPool returns (bool) {
        require(newKeeper != address(0));
        poolKeeper = newKeeper;
        return true;
    }

    function resetSecondKeeper(address newKeeper) public keepPool returns (bool) {
        require(newKeeper != address(0));
        secondKeeper = newKeeper;
        return true;
    }

    function resetBanker(address addr) public keepPool returns(bool) {
        require(addr != address(0));
        banker = addr;
        return true;
    }

    function resetFeeRate(uint _feeRate) public keepPool returns(bool) {
        feeRate = _feeRate;
        return true;
    }



    function debt(address addr,uint amount) public keepPool returns(bool) {
        require(addr != address(0));
        debt[addr] = amount;
        return true;
    }

    function resetTokenContracts(address _bot,address _src,address _stc,address _weth1,address _weth2,address _weth3) public keepPool returns(bool) {
        BOT = _bot;
        SRC = _src;
        STC = _stc;
        WETH[0] = _weth1;
        WETH[1] = _weth2;
        WETH[2] = _weth3;
        return true;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;

        return c;
    }

}