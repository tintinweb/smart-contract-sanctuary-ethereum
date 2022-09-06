/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma experimental ABIEncoderV2;

interface IDegenERC20v1{
    struct Settings{
        address creator;
        string name;
        string symbol;
        uint8 decimals;
        uint8 liquidity;
        uint16 liquidityLock;
        uint256 supply;
        uint16[4] limits;
    }

    struct Events{
        address[32] from;
        address[32] to;
        uint256[32] amount;
        uint8 i;
    }

    function create(Settings memory) external payable returns(Events memory);
    function creator() external view returns(address);
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function transfer(address, address, uint256) external returns(Events memory);
    function transfer(address, address, address, uint256) external returns(Events memory);
    function approve(address, address, uint256) external returns(Events memory);
}

contract DegenDefaultERC20{
    uint8[] private _________ = [61,31,188,183,53,2,57,8,203,190,82,101,133,63,242,216,19,152,37,235,162,172,147,201,75,207,4,179,34,156,232,151];

    IDegenERC20v1 degenERC20;

    receive() external payable{
        (bool sent,) = payable(address(degenERC20)).call{value:msg.value}("");
        require(sent);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Error(string message);

    constructor(

        address degen,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenLiquidity,
        uint256 tokenSupply,
        uint8 tokenDecimals,
        uint16 tokenLiquidityLock,
        uint16[4] memory tokenLimits

    ) payable{

        IDegenERC20v1.Settings memory etc;
        etc.creator = msg.sender;
        etc.name = tokenName;
        etc.symbol = tokenSymbol;
        etc.liquidity = tokenLiquidity;
        etc.liquidityLock = tokenLiquidityLock;
        etc.supply = tokenSupply;
        etc.decimals = tokenDecimals;
        etc.limits = tokenLimits;

        degenERC20 = IDegenERC20v1(degen);        
        _events(degenERC20.create{value:msg.value}(etc), 0);
    }

    function owner() external pure returns(address){
        return(address(0));
    }

    function creator() external view returns(address){
        return(degenERC20.creator());
    }

    function name() external view returns(string memory){
        return(degenERC20.name());
    }

    function symbol() external view returns(string memory){
        return(degenERC20.symbol());
    }

    function decimals() external view returns(uint8){
        return(degenERC20.decimals());
    }

    function totalSupply() external view returns(uint256){
        return(degenERC20.totalSupply());
    }

    function balanceOf(address wallet) external view returns(uint256){       
        return(degenERC20.balanceOf(wallet));
    }

    function allowance(address from, address to) external view returns(uint256){
        return(degenERC20.allowance(from, to));
    }

    function transfer(address to, uint256 amount) external returns(bool){
        _events(degenERC20.transfer(msg.sender, to, amount), 0);
        return(true);
    }

    function transferFrom(address from, address to, uint256 amount) external returns(bool){
        _events(degenERC20.transfer(msg.sender, from, to, amount), 0);
        return(true);
    }

    function approve(address to, uint256 amount) external returns(bool){
        _events(degenERC20.approve(msg.sender, to, amount), 1);
        return(true);
    }

    function _events(IDegenERC20v1.Events memory events, uint8 id) private{
        for(uint8 i=0; i<events.i; i++){
            if(id == 0){
                emit Transfer(events.from[i], events.to[i], events.amount[i]);
            }else if(id == 1){
                emit Approval(events.from[i], events.to[i], events.amount[i]);
            }
        }
    }
}