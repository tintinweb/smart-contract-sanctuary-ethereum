/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title BlockPMN
 * @dev Discover ways to increase your crypto savings
 */
contract BlockPMN {
    struct BusinessModel {
        string name;
        uint256 yield;
        uint256 risk;
    }

    mapping(uint256 => BusinessModel) public businessModels;

    struct InvestmentPlatform {
        string name;
        string imageURL;
        string description;
        string platformURL;
        uint256 APY;
    }

    mapping(uint256 => InvestmentPlatform) public investmentPlatforms;

    constructor() {
        // Define business models
        storeBusinessModel(0, "Flexible savings", 3, 3);
        storeBusinessModel(1, "Locked savings", 7, 5);
        storeBusinessModel(2, "Locked staking", 7, 5);
        storeBusinessModel(3, "Liquidity pools", 9, 7);
        storeBusinessModel(4, "Dual investment", 5, 1);

        // Define investment options
        storeInvestmentPlatform(
            0,
            "Flexible savings",
            "https://public.bnbstatic.com/image/cms/blog/20200820/07154abb-2591-42bd-9c90-d239bcef9b94.png",
            "Good flexibility but a lower interest rate",
            "https://www.binance.com/en/savings#lending-demandDeposits",
            2000
        );
        storeInvestmentPlatform(
            1,
            "Locked savings",
            "https://public.bnbstatic.com/image/cms/blog/20200820/07154abb-2591-42bd-9c90-d239bcef9b94.png",
            "Less flexibility but a higher interest rate",
            "https://www.binance.com/en/savings/#lending-fixeddeposits",
            2500
        );
        storeInvestmentPlatform(
            2,
            "Locked staking",
            "https://public.bnbstatic.com/image/cms/blog/20220524/344f1fb1-7233-4864-bba6-c62fbaacfb9d.png",
            "You are holding Proof-of-Stake (PoS) coins",
            "https://www.binance.com/en/staking",
            2986
        );
        storeInvestmentPlatform(
            3,
            "Liquidity pools",
            "https://public.bnbstatic.com/image/cms/blog/20210111/49b0a2af-c76b-40f9-a3e3-0ab610c7a4e2.png",
            "Decentralised finance (DeFi) investment",
            "https://www.binance.com/en/swap/liquidity",
            5549
        );
        storeInvestmentPlatform(
            4,
            "Dual investment",
            "https://public.bnbstatic.com/image/cms/blog/20200820/07154abb-2591-42bd-9c90-d239bcef9b94.png",
            "Optimize yield while minimizing risk",
            "https://www.binance.com/en/dual-investment",
            539
        );
    }

    /**
     * @dev Store a business model
     */
    function storeBusinessModel(
        uint256 _id,
        string memory _name,
        uint256 _yield,
        uint256 _risk
    ) public {
        businessModels[_id] = BusinessModel(_name, _yield, _risk);
    }

    /**
     * @dev Store an investment platform
     */
    function storeInvestmentPlatform(
        uint256 _id,
        string memory _name,
        string memory _imageURL,
        string memory _description,
        string memory _platformURL,
        uint256 _APY
    ) public {
        investmentPlatforms[_id] = InvestmentPlatform(
            _name,
            _imageURL,
            _description,
            _platformURL,
            _APY
        );
    }
}