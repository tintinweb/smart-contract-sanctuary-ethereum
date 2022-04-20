// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./bank.sol" as Bank;
import "./token.sol" as Token;
import "./usd.sol" as USD;
import "./usdmint.sol" as USDMint;
import "./usdstaking.sol" as USDStaking;
import "./reward.sol" as Reward;

interface IUSD {
    function setOwner(address to) external;

    function setMinerTo(address to) external;

    function setStakeTo(address to) external;

    function setRewardTo(address to) external;

    function depositAddress() external view returns (address);
}

interface IBank {
    function initalize(
        address _token,
        uint256 _base,
        uint256 _useAmount
    ) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
}

//一键部署合约
//切换主网需修改 router及usdt地址
//修改bank router及usdt地址
//修改usdmint router及usdt地址
contract DeploySwapUSD {
    address public bank;
    address public usd;
    address public usdMint;
    address public usdstaking;
    address public reward;
    address public usdDeposit;

    address public token;
    // address public routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // uniswapRouter
    // address public usdtAddress = 0x55d398326f99059fF775485246999027B3197955; // usdt
    address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // uniswapRouter
    address public usdtAddress = 0x99924AA7BBc915Cb2BEE65d72343734b370a06f1; // usdt

    constructor() {
        bank = address(new Bank.Bank(msg.sender));
        token = address(
            new Token.ERC20("TLUNA", "TLUNA", 18, msg.sender, bank)
        );

        IBank(bank).initalize(token, 1 * 10**18, 1000000 * 10**18);

        IUniswapV2Factory(IUniswapV2Router01(routerAddress).factory())
            .createPair(token, usdtAddress);

        usd = address(new USD.TokenUSD("TUSD", "TUSD", 18));
        usdDeposit = IUSD(usd).depositAddress();
        usdMint = address(new USDMint.UsdMinter(token, usd, usdDeposit));
        usdstaking = address(new USDStaking.UsdStaking(usd, usdDeposit));
        reward = address(new Reward.USDReward(usd, usdDeposit));

        // 设置usd铸造合约
        IUSD(usd).setMinerTo(usdMint);
        // 设置usd质押合约
        IUSD(usd).setStakeTo(usdstaking);
        // 设置usd奖励合约
        IUSD(usd).setRewardTo(reward);
        // #设置usd合约管理员
        IUSD(usd).setOwner(msg.sender);
    }
}