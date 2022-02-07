/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract VestingVault {

    address public beneficiary;

    uint256 public initialVestedAmount;

    uint256 public vestingEndTimestamp;

    uint256 public constant priceInterval = 0.2e18;

    uint256 public constant priceBatches = 15;

    address public constant deri = 0xA487bF43cF3b10dffc97A9A744cbB7036965d3b9;

    address public constant sushiV2Pair = 0xA3DfbF2933FF3d96177bde4928D0F5840eE55600;

    uint256 public blockTimestampLast;

    uint256 public price0CumulativeLast;

    uint256 public prepareWithdrawTimestamp;

    constructor (address beneficiary_, uint256 initialVestedAmount_, uint256 vestingEndTimestamp_) {
        beneficiary = beneficiary_;
        initialVestedAmount = initialVestedAmount_;
        vestingEndTimestamp = vestingEndTimestamp_;
    }

    // Beneficiary need to call prepareWithdraw before calling withdraw
    // This function will record the start timestamp/price0CumulativeLast for calculating TWAP price
    // To ensure a TWAP of at least 1 day, withdraw can only be called 1 day after calling this function
    function prepareWithdraw() external {
        require(msg.sender == beneficiary, 'prepareWithdraw: only beneficiary');

        (, , uint256 timestamp) = IUniswapV2Pair(sushiV2Pair).getReserves();
        blockTimestampLast = timestamp;
        price0CumulativeLast = IUniswapV2Pair(sushiV2Pair).price0CumulativeLast();
        prepareWithdrawTimestamp = block.timestamp;
    }

    // Convenient function for beneficiary to estimate the available withdraw amount
    // Logic is the same as getAvailableAmount, except using a spot price instead of TWAP for estimation
    function estimateAvailableAmount() external view returns (uint256) {
        uint256 balance = IERC20(deri).balanceOf(address(this));
        uint256 available;

        if (block.timestamp >= vestingEndTimestamp) {
            available = balance;
        } else {
            (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(sushiV2Pair).getReserves();
            uint256 price = reserve1 * 10**30 / reserve0;

            uint256 unlocked = price / priceInterval * initialVestedAmount / priceBatches;
            uint256 locked = unlocked >= initialVestedAmount ? 0 : initialVestedAmount - unlocked;
            available = balance > locked ? balance - locked : 0;
        }

        return available;
    }

    function getAvailableAmount() public view returns (uint256) {
        uint256 balance = IERC20(deri).balanceOf(address(this));
        uint256 available;

        if (block.timestamp >= vestingEndTimestamp) {
            available = balance;
        } else {
            require(
                prepareWithdrawTimestamp != 0 && block.timestamp >= prepareWithdrawTimestamp + 86400,
                'getAvailableAmount: not prepared, or wait at least 1 day after preparation'
            );

            (, , uint256 blockTimestampCurrent) = IUniswapV2Pair(sushiV2Pair).getReserves();
            uint256 price0CumulativeCurrent = IUniswapV2Pair(sushiV2Pair).price0CumulativeLast();

            // Revert if TWAP cannot be calculated
            // This could happen if there is no swap at all on Sushi after prepareWithdraw
            // Make a small swap on Sushi to update timestamp/price0CumulativeLast can solve this
            require(blockTimestampLast != blockTimestampCurrent, 'getAvailableAmount: cannot calculate TWAP');

            // TWAP price
            uint256 price = (price0CumulativeCurrent - price0CumulativeLast) * 10**30 / (blockTimestampCurrent - blockTimestampLast) / 2**112;

            // Amount is unlocked according to number of price intervals crossed
            // Please notice that a pre-unlocked amount may be re-locked again due to price drop,
            // if it is not withdrew when price is high
            uint256 unlocked = price / priceInterval * initialVestedAmount / priceBatches;
            uint256 locked = unlocked >= initialVestedAmount ? 0 : initialVestedAmount - unlocked;
            available = balance > locked ? balance - locked : 0;
        }

        return available;
    }

    function withdraw() external {
        require(msg.sender == beneficiary, 'prepareWithdraw: only beneficiary');
        uint256 available = getAvailableAmount();

        // Reset prepareWithdrawTimestamp
        prepareWithdrawTimestamp = 0;

        // Transfer available tokens
        if (available > 0) {
            IERC20(deri).transfer(beneficiary, available);
        }
    }

}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external;
}