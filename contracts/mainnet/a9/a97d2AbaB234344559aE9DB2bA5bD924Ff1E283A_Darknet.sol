// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;


//An oracle that provides prices for different LSDs
//NOTE: This is the rate quoted by the LSDs contracts, no pricing of market impact and liquidity risk is calculated

interface IsfrxETH { function pricePerShare() external view returns (uint256); }
interface IrETH { function getExchangeRate() external view returns (uint256); }
interface IWStETH { function tokensPerStEth() external view returns (uint256); }
interface IcbETH { function exchangeRate() external view returns (uint256); }
interface IankrETH { function sharesToBonds(uint256) external view returns (uint256); }
interface IswETH { function swETHToETHRate() external view returns (uint256); }

contract Darknet {

    address public constant sfrxETHAddress = 0xac3E018457B222d93114458476f3E3416Abbe38F;
    address public constant rETHAddress = 0xae78736Cd615f374D3085123A210448E74Fc6393;
    address public constant wstETHAddress = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant cbETHAddress = 0xBe9895146f7AF43049ca1c1AE358B0541Ea49704;
    address public constant wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant ankrETHAddress = 0xE95A203B1a91a908F9B9CE46459d101078c2c3cb;
    address public constant swETHAddress = 0xf951E335afb289353dc249e82926178EaC7DEd78;

    constructor() {}

    function checkPrice(address lsd) public view returns (uint256) {
        if (lsd == wethAddress)    return 1e18;
        if (lsd == wstETHAddress)  return IWStETH(wstETHAddress).tokensPerStEth();
        if (lsd == sfrxETHAddress) return IsfrxETH(sfrxETHAddress).pricePerShare();
        if (lsd == rETHAddress)    return IrETH(rETHAddress).getExchangeRate();
        if (lsd == cbETHAddress)   return IcbETH(cbETHAddress).exchangeRate();
        if (lsd == ankrETHAddress) return IankrETH(ankrETHAddress).sharesToBonds(1e18);
        if (lsd == swETHAddress)   return IswETH(swETHAddress).swETHToETHRate();
        else revert();
    }

}