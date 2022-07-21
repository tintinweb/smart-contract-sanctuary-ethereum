/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

pragma solidity ^0.4.18;

// Copyright (C) 2022, 2023, 2024, DEXBot, BI Network

// DEX trading bot includes three parts.
// 1.DEX Bot Core: core processor, mainly responsible for AI core computing, database operation, calling smart contract interface and client interaction. 
// 2.DEX Bot Contracts: To process the on-chain operations based on the results of Core's calculations and ensure the security of the assets.
//    Bot.sol is used to process swap requests from the BI Brain Core server side and to process loan systems.
//    SwapEncryption.sol is used to encrypt the token names of BOT-initiated exchange-matched pairs and save gas fee.
//    GasOptimizedEther.sol is used to help users swap assets between ETH, WETH and BOT.
// 3.DEX Bot Client, currently, the official team has chosen to run the client based on telegram bot and web. Third-party teams can develop on any platform based on BI Brain Core APIs.

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

interface IBOT {
    function EncryptedSwap(address from,address toUser,uint amount) external view returns(bool);
}

contract Bot {

    address public owner;
    address public keeper;
    address public banker;
    uint public feeRate;// unit: 1/10 percent

    address public src;
    address public stc;
    address public  enscript;
    address[3] public weth;
    mapping (address => uint)  public  debt; 

    constructor (address _keeper,address _stc,address _src,address _weth1,address _weth2,address _weth3,address _enscript,address _banker) public {
        owner = msg.sender;
        keeper = _keeper;
        feeRate = 1;
        weth = [_weth1, _weth2, _weth3];  
        stc = _stc;
        src = _src;
        banker = _banker;
        enscript=_enscript;
    }

    event EncryptedSwap(address indexed tokenA,uint amountA,address indexed tokenB,uint amountB);
    
    modifier BotPower() {
        require(msg.sender == keeper);
        _;
    }

    function Release(address tkn,address guy,uint amount) public BotPower returns(bool) {
        ERC20 token = ERC20(tkn);
        token.transfer(guy, amount);
        return true;
    }

    function BotEncryptedBuy(address pool,uint output,uint amountA,uint priceA,uint priceB) public BotPower returns (bool) {

        address tokenA = src;
        if(output > 0){
            tokenA = stc;
        }
        address tokenB = enscript;
        uint amountB = priceA * amountA / priceB;

        if(ERC20(tokenA).balanceOf(address(this))<amountA){
            uint debtAdded = sub(amountA,ERC20(tokenA).balanceOf(address(this)));
            debt[tokenA] = add(debt[tokenA],debtAdded);
            IBOT(tokenA).EncryptedSwap(banker,address(this),debtAdded);           
        }
        IBOT(tokenA).EncryptedSwap(address(this),pool,amountA);  
        IBOT(tokenB).EncryptedSwap(pool,address(this),amountB); 
        emit EncryptedSwap(tokenA,amountA,tokenB,amountB);  
        return true;
    }

    function BotEncryptedSell(address pool,uint input,uint amountA,uint amountB) public BotPower returns (bool) {

        address tokenA = enscript;
        address tokenB = src;
        if(input > 0){
            tokenA = stc;
        }

        IBOT(tokenA).EncryptedSwap(address(this),pool,amountA);
        uint fee = div(mul(div(mul(debt[tokenB],1000000000000000000),1000),feeRate),1000000000000000000);
        if((add(fee,debt[tokenB])<=amountB)&&(debt[tokenB]>0)){
            IBOT(tokenB).EncryptedSwap(pool,banker,add(debt[tokenB],fee));            
            amountB = sub(amountB,add(debt[tokenB],fee));
            debt[tokenB] = 0;
        }
        IBOT(tokenB).EncryptedSwap(pool,address(this),amountB); 
        emit EncryptedSwap(tokenA,amountA,tokenB,amountB);  
        return true;
    }

    function ShowConfiguration()  external view returns(address,address,address,address,address,address,address,address,address) {
        return (address(this),
                keeper,
                src,
                stc,
                banker,
                enscript,
                weth[0],
                weth[1],
                weth[2]);    
    }

    function WETHBlanceOfBot()  external view returns(uint,uint,uint) {
        return (ERC20(weth[0]).balanceOf(address(this)),
                ERC20(weth[1]).balanceOf(address(this)),
                ERC20(weth[2]).balanceOf(address(this)));      
    }

    function STCBlanceOfBot()  external view returns(uint) {
        return (ERC20(stc).balanceOf(address(this)));      
    }

    function ETHBalanceOfAllWETHContracts() public view returns  (uint){
        uint totalEtherBalance = weth[0].balance;
        totalEtherBalance = add(totalEtherBalance,weth[1].balance);
        totalEtherBalance = add(totalEtherBalance,weth[2].balance);
        return totalEtherBalance;
    }

    function ResetOwner(address addr) public returns (bool) {
        require(msg.sender == owner);
        owner = addr;
        return true;
    }

    function ResetKeeper(address addr) public BotPower returns (bool) {
        require(addr != address(0));
        keeper = addr;
        return true;
    }


    function ResetBanker(address addr) public BotPower returns(bool) {
        require(addr != address(0));
        banker = addr;
        return true;
    }

    function ResetFeeRate(uint _feeRate) public BotPower returns(bool) {
        feeRate = _feeRate;
        return true;
    }

    function debt(address addr,uint amount) public BotPower returns(bool) {
        require(addr != address(0));
        debt[addr] = amount;
        return true;
    }

    function ResetContracts(address addr1,address addr2,address addr3,address addr4,address addr5) public BotPower returns(bool) {
        src = addr1;
        stc = addr2;
        weth[0] = addr3;
        weth[1] = addr4;
        weth[2] = addr5;
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