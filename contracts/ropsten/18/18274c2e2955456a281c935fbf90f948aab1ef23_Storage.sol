/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title BlockPMN
 * @dev Discover ways to increase your crypto savings
 */
contract Storage {
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
        uint256 APY;
    }

    mapping(uint256 => InvestmentPlatform) public investmentPlatforms;

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
        uint256 _APY
    ) public {
        investmentPlatforms[_id] = InvestmentPlatform(
            _name,
            _imageURL,
            _description,
            _APY
        );
    }
}