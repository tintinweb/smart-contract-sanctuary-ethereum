// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

import "@yield-protocol/utils-v2/contracts/cast/CastBytes32Bytes6.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC20Metadata.sol";
import "../../interfaces/IOracle.sol";

interface ICrabStrategy {
    function totalSupply() external view returns (uint256);

    /**
     * @notice get the vault composition of the strategy
     * @return operator
     * @return nft collateral id
     * @return collateral amount
     * @return short amount
     */
    function getVaultDetails()
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        );
}

/**
 * @title CrabOracle
 * @notice Oracle to fetch Crab-ETH exchange amounts
 */
contract CrabOracle is IOracle {
    using CastBytes32Bytes6 for bytes32;
    ICrabStrategy immutable crabStrategy;
    IOracle immutable uniswapV3Oracle;
    bytes6 immutable ethId;
    bytes6 immutable crabId;
    bytes6 immutable oSQTHId;

    event SourceSet(
        bytes6 crab_,
        bytes6 oSQTH_,
        bytes6 ethId_,
        ICrabStrategy indexed crabStrategy_,
        IOracle indexed uniswapV3Oracle_
    );

    /**
     * @notice Set crabstrategy & uniswap source
     */
    constructor(
        bytes6 crabId_,
        bytes6 oSQTHId_,
        bytes6 ethId_,
        ICrabStrategy crabStrategy_,
        IOracle uniswapV3Oracle_
    ) {
        crabId = crabId_;
        oSQTHId = oSQTHId_;
        ethId = ethId_;
        crabStrategy = crabStrategy_;
        uniswapV3Oracle = uniswapV3Oracle_;

        emit SourceSet(
            crabId_,
            oSQTHId_,
            ethId_,
            crabStrategy_,
            uniswapV3Oracle_
        );
    }

    /**
     * @notice Retrieve the value of the amount at the latest oracle price.
     * Only `crabId` and `ethId` are accepted as asset identifiers.
     */
    function peek(
        bytes32 base,
        bytes32 quote,
        uint256 baseAmount
    )
        external
        view
        virtual
        override
        returns (uint256 quoteAmount, uint256 updateTime)
    {
        return _peek(base.b6(), quote.b6(), baseAmount);
    }

    /**
     * @notice Retrieve the value of the amount at the latest oracle price. Same as `peek` for this oracle.
     * Only `crabId` and `ethId` are accepted as asset identifiers.
     */
    function get(
        bytes32 base,
        bytes32 quote,
        uint256 baseAmount
    )
        external
        virtual
        override
        returns (uint256 quoteAmount, uint256 updateTime)
    {
        return _peek(base.b6(), quote.b6(), baseAmount);
    }

    /**
     * @notice Retrieve the value of the amount at the latest oracle price.
     */
    function _peek(
        bytes6 base,
        bytes6 quote,
        uint256 baseAmount
    ) private view returns (uint256 quoteAmount, uint256 updateTime) {
        require(
            (base == crabId && quote == ethId) ||
                (base == ethId && quote == crabId),
            "Source not found"
        );

        if (base == crabId) {
            quoteAmount = (_getCrabPrice() * baseAmount) / 1e18; // 1e18 is used to Normalize
        } else if (quote == crabId) {
            quoteAmount = (baseAmount * 1e18) / _getCrabPrice(); // 1e18 is used to Normalize
        }

        updateTime = block.timestamp;
    }

    /// @notice Returns price of one crab token in terms of ETH
    /// @return crabPrice Price of one crab token in terms of ETH
    function _getCrabPrice() internal view returns (uint256 crabPrice) {
        // Get ETH collateral & oSQTH debt of the crab strategy
        (, , uint256 ethCollateral, uint256 oSQTHDebt) = crabStrategy
            .getVaultDetails();
        // Get oSQTH price from uniswapOracle
        (uint256 oSQTHPrice, uint256 lastUpdateTime) = uniswapV3Oracle.peek(
            oSQTHId,
            ethId,
            1e18
        );
        require(lastUpdateTime != 0, "Incomplete round");
        // Crab Price calculation
        // Crab at any point has a combination of ETH collateral and squeeth debt so you can calc crab/eth value with:
        // Crab net value in eth terms = Eth collateral - oSQTH/ETH price * (oSQTH debt)
        // Price of 1 crab in terms of ETH = Crab net value / totalSupply of Crab
        crabPrice =
            (ethCollateral * 1e18 - oSQTHPrice * oSQTHDebt) /
            crabStrategy.totalSupply();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library CastBytes32Bytes6 {
    function b6(bytes32 x) internal pure returns (bytes6 y){
        require (bytes32(y = bytes6(x)) == x, "Cast overflow");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @notice Doesn't refresh the price, but returns the latest value available without doing any transactional operations
     * @param base The asset in which the `amount` to be converted is represented
     * @param quote The asset in which the converted `value` will be represented
     * @param amount The amount to be converted from `base` to `quote`
     * @return value The converted value of `amount` from `base` to `quote`
     * @return updateTime The timestamp when the conversion price was taken
     */
    function peek(
        bytes32 base,
        bytes32 quote,
        uint256 amount
    ) external view returns (uint256 value, uint256 updateTime);

    /**
     * @notice Does whatever work or queries will yield the most up-to-date price, and returns it.
     * @param base The asset in which the `amount` to be converted is represented
     * @param quote The asset in which the converted `value` will be represented
     * @param amount The amount to be converted from `base` to `quote`
     * @return value The converted value of `amount` from `base` to `quote`
     * @return updateTime The timestamp when the conversion price was taken
     */
    function get(
        bytes32 base,
        bytes32 quote,
        uint256 amount
    ) external returns (uint256 value, uint256 updateTime);
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}