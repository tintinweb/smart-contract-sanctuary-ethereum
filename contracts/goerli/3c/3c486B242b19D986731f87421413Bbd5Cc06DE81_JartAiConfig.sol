// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IJartAiConfig {
    function mainPair() external view returns (address);

    function FEE_DENOMINATOR() external view returns (uint256);

    function isExcludedFromSwapFee(address) external view returns (bool);

    function marketingWallet() external view returns (address);

    function marketingFee() external view returns (uint256);

    function liquidityFee() external view returns (uint256);

    function minAmountForMarketing() external view returns (uint256);

    function minAmountForLiquidity() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import {IJartAiConfig} from "./IJartAiConfig.sol";

contract JartAiConfig is IJartAiConfig {
    mapping(address => bool) public isExcludedFromSwapFee;
    address public mainPair;
    address public marketingWallet;
    address public owner;

    // initial values, sniper protection
    uint256 public marketingFee = 45;
    uint256 public liquidityFee = 45;
    uint256 public constant FEE_DENOMINATOR = 100;

    uint256 public minAmountForMarketing;
    uint256 public minAmountForLiquidity;

    constructor() {
        owner = msg.sender;
        marketingWallet = msg.sender;

        isExcludedFromSwapFee[msg.sender] = true;
    }

    function setPair(address newPair) external onlyOwner {
        mainPair = newPair;
    }

    function setExcludeFromSwapFee(
        address[] calldata users,
        bool excludedFromSwapFee
    ) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            isExcludedFromSwapFee[users[i]] = excludedFromSwapFee;
        }
    }

    function setMarketingWallet(address wallet) external onlyOwner {
        marketingWallet = wallet;
        isExcludedFromSwapFee[marketingWallet] = true;
    }

    function setFees(uint256 _marketingFee, uint256 _liquidityFee)
        external
        onlyOwner
    {
        marketingFee = _marketingFee;
        liquidityFee = _liquidityFee;
    }

    function setMinAmounts(
        uint256 _minAmountForMarketing,
        uint256 _minAmountForLiquidity
    ) external onlyOwner {
        minAmountForMarketing = _minAmountForMarketing;
        minAmountForLiquidity = _minAmountForLiquidity;
    }

    // ACL

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}