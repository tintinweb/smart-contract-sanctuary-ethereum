/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.0;


//Interfaces to call outside contracts
interface IErc20 {
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint);
}

interface ICErc20 {
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint);   
    function mint(uint mintAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function underlying() external returns (address);
}

interface IComptroller{ 
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
}

contract Buster {
    
    address payable contractOwner;
    uint256 wethBalance;
    // KOVAN 0xd0A1E359811322d97991E03f863a0C30C2cF029C
    address private constant WETH = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;


    constructor() public { 
        contractOwner = msg.sender; 
    }

    //The function we call
    function Depsoit(uint256 _amount) public {
        //Only the creator of the contract can interact
        require(msg.sender == contractOwner, "OWNER ONLY");

        //For outside calls to DAI smart contract
        IErc20 weth = IErc20(WETH); 

        //Check we have some weth to invest
        uint256 wethHoldings = weth.balanceOf(msg.sender);
        require(wethHoldings >0, "NO WETH TO INVEST");

        weth.approve(address(this), _amount);
        weth.transfer(address(this), _amount); 
        wethBalance = wethBalance + _amount;

    }

    //Withdraw needed or else your Erc20 tokens stuck here forever
    function Withdraw() public  {

        require(msg.sender == contractOwner, "OWNER ONLY");

        IErc20 weth = IErc20(WETH); 
        weth.approve(contractOwner, wethBalance);
        weth.transfer(contractOwner, wethBalance);       
    }

    function ViewBalance() public view returns (uint256){
        return wethBalance;
    }

}