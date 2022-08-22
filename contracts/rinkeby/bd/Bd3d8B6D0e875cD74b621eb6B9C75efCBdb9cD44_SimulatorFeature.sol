// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../storage/LibAggregatorStorage.sol";
import "../../libs/FixinTokenSpender.sol";
import "./ISimulator.sol";


contract SimulatorFeature is ISimulator, FixinTokenSpender {

    uint256 public constant WETH_MARKET_ID = 999;
    address public immutable WETH;

    constructor(address weth) {
        WETH = weth;
    }

    function batchBuyWithETHSimulate(TradeDetails[] calldata tradeDetails) external payable override {
        // simulate trade and revert
        bytes memory error = abi.encodePacked(_simulateTrade(tradeDetails));
        assembly {
            revert(add(error, 0x20), mload(error))
        }
    }

    function batchBuyWithERC20sSimulate(
        IAggregator.ERC20Pair[] calldata erc20Pairs,
        TradeDetails[] calldata tradeDetails,
        address[] calldata dustTokens
    ) external payable override {
        // transfer ERC20 tokens from the sender to this contract
        _transferERC20Pairs(erc20Pairs);

        uint256 result = _simulateTrade(tradeDetails);

        // return dust tokens (if any)
        _returnDust(dustTokens);

        bytes memory error = abi.encodePacked(result);
        assembly {
            revert(add(error, 0x20), mload(error))
        }
    }

    function _simulateTrade(TradeDetails[] calldata tradeDetails) internal returns (uint256 result) {
        unchecked {
            LibAggregatorStorage.Storage storage stor = LibAggregatorStorage.getStorage();
            for (uint256 i = 0; i < tradeDetails.length; ++i) {
                bool success;
                TradeDetails calldata item = tradeDetails[i];

                if (item.marketId == WETH_MARKET_ID) {
                    (success, ) = WETH.call{value: item.value}(item.tradeData);
                } else {
                    LibAggregatorStorage.Market memory market = stor.markets[item.marketId];
                    if (market.isActive) {
                        (success,) = market.isLibrary ?
                            market.proxy.delegatecall(item.tradeData) :
                            market.proxy.call{value: item.value}(item.tradeData);
                    }
                }

                if (success) {
                    result |= 1 << i;
                }
            }
            return result;
        }
    }

    function _transferERC20Pairs(IAggregator.ERC20Pair[] calldata erc20Pairs) internal {
        // transfer ERC20 tokens from the sender to this contract
        if (erc20Pairs.length > 0) {
            assembly {
                let ptr := mload(0x40)
                let end := add(erc20Pairs.offset, mul(erc20Pairs.length, 0x40))

                // selector for transferFrom(address,address,uint256)
                mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), caller())
                mstore(add(ptr, 0x24), address())
                for { let offset := erc20Pairs.offset } lt(offset, end) { offset := add(offset, 0x40) } {
                    let amount := calldataload(add(offset, 0x20))
                    if gt(amount, 0) {
                        mstore(add(ptr, 0x44), amount)
                        let success := call(gas(), calldataload(offset), 0, ptr, 0x64, 0, 0)
                    }
                }
            }
        }
    }

    function _returnDust(address[] calldata tokens) internal {
        // return remaining tokens (if any)
        for (uint256 i; i < tokens.length; ) {
            _transferERC20WithoutCheck(tokens[i], msg.sender, IERC20(tokens[i]).balanceOf(address(this)));
            unchecked { ++i; }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


library LibAggregatorStorage {

    uint256 constant STORAGE_ID_AGGREGATOR = 0;

    struct Market {
        address proxy;
        bool isLibrary;
        bool isActive;
    }

    struct Storage {
        Market[] markets;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assembly { stor.slot := STORAGE_ID_AGGREGATOR }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


/// @dev Helpers for moving tokens around.
abstract contract FixinTokenSpender {

    // Mask of the lower 20 bytes of a bytes32.
    uint256 constant private ADDRESS_MASK = (1 << 160) - 1;

    /// @dev Transfers ERC20 tokens from `owner` to `to`.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _transferERC20From(address token, address owner, address to, uint256 amount) internal {
        uint256 success;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transferFrom(address,address,uint256)
            mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
            mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x44), amount)

            success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x64, ptr, 32)

            let rdsize := returndatasize()

            // Check for ERC20 success. ERC20 tokens should return a boolean,
            // but some don't. We accept 0-length return data as success, or at
            // least 32 bytes that starts with a 32-byte boolean true.
            success := and(
                success,                             // call itself succeeded
                or(
                    iszero(rdsize),                  // no return data, or
                    and(
                        iszero(lt(rdsize, 32)),      // at least 32 bytes
                        eq(mload(ptr), 1)            // starts with uint256(1)
                    )
                )
            )
        }
        require(success != 0, "_transferERC20/TRANSFER_FAILED");
    }

    /// @dev Transfers ERC20 tokens from ourselves to `to`.
    /// @param token The token to spend.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _transferERC20(address token, address to, uint256 amount) internal {
        uint256 success;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transfer(address,uint256)
            mstore(ptr, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x24), amount)

            success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x44, ptr, 32)

            let rdsize := returndatasize()

            // Check for ERC20 success. ERC20 tokens should return a boolean,
            // but some don't. We accept 0-length return data as success, or at
            // least 32 bytes that starts with a 32-byte boolean true.
            success := and(
                success,                             // call itself succeeded
                or(
                    iszero(rdsize),                  // no return data, or
                    and(
                        iszero(lt(rdsize, 32)),      // at least 32 bytes
                        eq(mload(ptr), 1)            // starts with uint256(1)
                    )
                )
            )
        }
        require(success != 0, "_transferERC20/TRANSFER_FAILED");
    }

    function _transferERC20FromWithoutCheck(address token, address owner, address to, uint256 amount) internal {
        assembly {
            if gt(amount, 0) {
                let ptr := mload(0x40) // free memory pointer

                // selector for transferFrom(address,address,uint256)
                mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
                mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
                mstore(add(ptr, 0x44), amount)

                let success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x64, 0, 0)
            }
        }
    }

    function _transferERC20WithoutCheck(address token, address to, uint256 amount) internal {
        assembly {
            if gt(amount, 0) {
                let ptr := mload(0x40) // free memory pointer

                // selector for transfer(address,uint256)
                mstore(ptr, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), and(to, ADDRESS_MASK))
                mstore(add(ptr, 0x24), amount)

                let success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x44, 0, 0)
            }
        }
    }

    /// @dev Transfers some amount of ETH to the given recipient and
    ///      reverts if the transfer fails.
    /// @param recipient The recipient of the ETH.
    /// @param amount The amount of ETH to transfer.
    function _transferEth(address recipient, uint256 amount) internal {
        assembly {
            if gt(amount, 0) {
                if iszero(call(gas(), recipient, amount, 0, 0, 0, 0)) {
                    // revert("_transferEth/TRANSFER_FAILED")
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(0x40, 0x0000001c5f7472616e736665724574682f5452414e534645525f4641494c4544)
                    mstore(0x60, 0)
                    revert(0, 0x64)
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../interfaces/IAggregator.sol";


interface ISimulator {

    struct TradeDetails {
        uint256 marketId;
        uint256 value;
        bytes tradeData;
    }

    function batchBuyWithETHSimulate(TradeDetails[] calldata tradeDetails) external payable;

    function batchBuyWithERC20sSimulate(
        IAggregator.ERC20Pair[] calldata erc20Pairs,
        TradeDetails[] calldata tradeDetails,
        address[] calldata dustTokens
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IAggregator {

    struct ERC20Pair {
        address token;
        uint256 amount;
    }

    function batchBuyWithETH(bytes calldata tradeBytes) external payable;

    function batchBuyWithERC20s(
        ERC20Pair[] calldata erc20Pairs,
        bytes calldata tradeBytes,
        address[] calldata dustTokens
    ) external payable;
}