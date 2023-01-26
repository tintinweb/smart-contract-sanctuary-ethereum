// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

import "@yield-protocol/utils-v2/contracts/cast/CastBytes32Bytes6.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC20Metadata.sol";
import "../../interfaces/IOracle.sol";

interface IRocketTokenRETH {
    // Calculate the amount of rETH backed by an amount of ETH
    function getRethValue(uint256 _ethAmount) external view returns (uint256);

    // Calculate the amount of ETH backing an amount of rETH
    function getEthValue(uint256 _rethAmount) external view returns (uint256);
}

contract RETHOracle is IOracle {
    using CastBytes32Bytes6 for bytes32;

    bytes6 immutable ethId;
    bytes6 immutable rEthId;
    IRocketTokenRETH immutable rEth;

    event SourceSet(bytes6 ethId, bytes6 rEthId, IRocketTokenRETH indexed rEth);

    constructor(
        bytes6 ethId_,
        bytes6 rEthId_,
        IRocketTokenRETH rEth_
    ) {
        ethId = ethId_;
        rEthId = rEthId_;
        rEth = rEth_;

        emit SourceSet(ethId, rEthId, rEth);
    }

    /**
     * @notice Doesn't refresh the price, but returns the latest value available without doing any transactional operations
     * @param base The asset in which the `amount` to be converted is represented
     * @param quote The asset in which the converted `value` will be represented
     * @param baseAmount The amount to be converted from `base` to `quote`
     * @return value The converted value of `amount` from `base` to `quote`
     * @return updateTime The timestamp when the conversion price was taken
     */
    function peek(
        bytes32 base,
        bytes32 quote,
        uint256 baseAmount
    ) external view returns (uint256 value, uint256 updateTime) {
        return _peek(base.b6(), quote.b6(), baseAmount);
    }

    /**
     * @notice Does whatever work or queries will yield the most up-to-date price, and returns it.
     * @param base The asset in which the `amount` to be converted is represented
     * @param quote The asset in which the converted `value` will be represented
     * @param baseAmount The amount to be converted from `base` to `quote`
     * @return value The converted value of `amount` from `base` to `quote`
     * @return updateTime The timestamp when the conversion price was taken
     */
    function get(
        bytes32 base,
        bytes32 quote,
        uint256 baseAmount
    ) external view returns (uint256 value, uint256 updateTime) {
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
            (base == rEthId && quote == ethId) ||
                (base == ethId && quote == rEthId),
            "Source not found"
        );

        if (base == rEthId) {
            quoteAmount = rEth.getEthValue(baseAmount);
        } else if (quote == rEthId) {
            quoteAmount = rEth.getRethValue(baseAmount);
        }

        updateTime = block.timestamp;
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