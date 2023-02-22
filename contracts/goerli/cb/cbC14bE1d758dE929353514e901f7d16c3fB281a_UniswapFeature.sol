// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

interface IERC20TokenV06 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @dev send `value` token to `to` from `msg.sender`
    /// @param to The address of the recipient
    /// @param value The amount of token to be transferred
    /// @return True if transfer was successful
    function transfer(address to, uint256 value) external returns (bool);

    /// @dev send `value` token to `to` from `from` on the condition it is approved by `from`
    /// @param from The address of the sender
    /// @param to The address of the recipient
    /// @param value The amount of token to be transferred
    /// @return True if transfer was successful
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    /// @dev `msg.sender` approves `spender` to spend `value` tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @param value The amount of wei to be approved for transfer
    /// @return Always true if the call has enough gas to complete execution
    function approve(address spender, uint256 value) external returns (bool);

    /// @dev Query total supply of token
    /// @return Total supply of token
    function totalSupply() external view returns (uint256);

    /// @dev Get the balance of `owner`.
    /// @param owner The address from which the balance will be retrieved
    /// @return Balance of owner
    function balanceOf(address owner) external view returns (uint256);

    /// @dev Get the allowance for `spender` to spend from `owner`.
    /// @param owner The address of the account owning tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address owner, address spender) external view returns (uint256);

    /// @dev Get the number of decimals this token has.
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

import "./IERC20TokenV06.sol";

interface IEtherTokenV06 is IERC20TokenV06 {
    /// @dev Wrap ether.
    function deposit() external payable;

    /// @dev Unwrap ether.
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

library LibRichErrorsV06 {
    // bytes4(keccak256("Error(string)"))
    bytes4 internal constant STANDARD_ERROR_SELECTOR = 0x08c379a0;

    /// @dev ABI encode a standard, string revert error payload.
    ///      This is the same payload that would be included by a `revert(string)`
    ///      solidity statement. It has the function signature `Error(string)`.
    /// @param message The error string.
    /// @return The ABI encoded error.
    function StandardError(string memory message) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(STANDARD_ERROR_SELECTOR, bytes(message));
    }

    /// @dev Reverts an encoded rich revert reason `errorData`.
    /// @param errorData ABI encoded error data.
    function rrevert(bytes memory errorData) internal pure {
        assembly {
            revert(add(errorData, 0x20), mload(errorData))
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

interface IOwnableV06 {
    /// @dev Emitted by Ownable when ownership is transferred.
    /// @param previousOwner The previous owner of the contract.
    /// @param newOwner The new owner of the contract.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev Transfers ownership of the contract to a new address.
    /// @param newOwner The address that will become the owner.
    function transferOwnership(address newOwner) external;

    /// @dev The owner of this contract.
    /// @return ownerAddress The owner address.
    function owner() external view returns (address ownerAddress);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;

library LibCommonRichErrors {
    function OnlyCallableBySelfError(address sender) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("OnlyCallableBySelfError(address)")), sender);
    }

    function IllegalReentrancyError(bytes4 selector, uint256 reentrancyFlags) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("IllegalReentrancyError(bytes4,uint256)")),
                selector,
                reentrancyFlags
            );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;

library LibOwnableRichErrors {
    function OnlyOwnerError(address sender, address owner) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("OnlyOwnerError(address,address)")), sender, owner);
    }

    function TransferOwnerToZeroError() internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("TransferOwnerToZeroError()")));
    }

    function MigrateCallFailedError(address target, bytes memory resultData) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("MigrateCallFailedError(address,bytes)")), target, resultData);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

/// @dev Basic interface for a feature contract.
interface IFeature {
    /// @dev The name of this feature set.
    function FEATURE_NAME() external view returns (string memory name);

    /// @dev The version of this feature set.
    function FEATURE_VERSION() external view returns (uint256 version);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/interfaces/IOwnableV06.sol";

/// @dev Owner management and migration features.
interface IOwnableFeature is IOwnableV06 {
    /// @dev Emitted when `migrate()` is called.
    /// @param caller The caller of `migrate()`.
    /// @param migrator The migration contract.
    /// @param newOwner The address of the new owner.
    event Migrated(address caller, address migrator, address newOwner);

    /// @dev Execute a migration function in the context of the ZeroEx contract.
    ///      The result of the function being called should be the magic bytes
    ///      0x2c64c5ef (`keccack('MIGRATE_SUCCESS')`). Only callable by the owner.
    ///      The owner will be temporarily set to `address(this)` inside the call.
    ///      Before returning, the owner will be set to `newOwner`.
    /// @param target The migrator contract address.
    /// @param newOwner The address of the new owner.
    /// @param data The call data.
    function migrate(address target, bytes calldata data, address newOwner) external;
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

/// @dev Basic registry management features.
interface ISimpleFunctionRegistryFeature {
    /// @dev A function implementation was updated via `extend()` or `rollback()`.
    /// @param selector The function selector.
    /// @param oldImpl The implementation contract address being replaced.
    /// @param newImpl The replacement implementation contract address.
    event ProxyFunctionUpdated(bytes4 indexed selector, address oldImpl, address newImpl);

    /// @dev Roll back to a prior implementation of a function.
    /// @param selector The function selector.
    /// @param targetImpl The address of an older implementation of the function.
    function rollback(bytes4 selector, address targetImpl) external;

    /// @dev Register or replace a function.
    /// @param selector The function selector.
    /// @param impl The implementation contract for the function.
    function extend(bytes4 selector, address impl) external;

    /// @dev Retrieve the length of the rollback history for a function.
    /// @param selector The function selector.
    /// @return rollbackLength The number of items in the rollback history for
    ///         the function.
    function getRollbackLength(bytes4 selector) external view returns (uint256 rollbackLength);

    /// @dev Retrieve an entry in the rollback history for a function.
    /// @param selector The function selector.
    /// @param idx The index in the rollback history.
    /// @return impl An implementation address for the function at
    ///         index `idx`.
    function getRollbackEntryAtIndex(bytes4 selector, uint256 idx) external view returns (address impl);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";

/// @dev VIP uniswap fill functions.
interface IUniswapFeature {
    /// @dev Efficiently sell directly to uniswap/sushiswap.
    /// @param tokens Sell path.
    /// @param sellAmount of `tokens[0]` Amount to sell.
    /// @param minBuyAmount Minimum amount of `tokens[-1]` to buy.
    /// @param isSushi Use sushiswap if true.
    /// @return buyAmount Amount of `tokens[-1]` bought.
    function sellToUniswap(
        IERC20TokenV06[] calldata tokens,
        uint256 sellAmount,
        uint256 minBuyAmount,
        bool isSushi
    ) external payable returns (uint256 buyAmount);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "../migrations/LibMigrate.sol";
import "../fixins/FixinCommon.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/IUniswapFeature.sol";

/// @dev VIP uniswap fill functions.
contract UniswapFeature is IFeature, IUniswapFeature, FixinCommon {
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "UniswapFeature";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 1, 2);
    /// @dev WETH contract.
    IEtherTokenV06 private immutable WETH;

    // 0xFF + address of the UniswapV2Factory contract.
    uint256 private constant FF_UNISWAP_FACTORY = 0xFF5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f0000000000000000000000;
    // 0xFF + address of the (Sushiswap) UniswapV2Factory contract.
    uint256 private constant FF_SUSHISWAP_FACTORY = 0xFFC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac0000000000000000000000;
    // Init code hash of the UniswapV2Pair contract.
    uint256 private constant UNISWAP_PAIR_INIT_CODE_HASH =
        0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;
    // Init code hash of the (Sushiswap) UniswapV2Pair contract.
    uint256 private constant SUSHISWAP_PAIR_INIT_CODE_HASH =
        0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303;
    // Mask of the lower 20 bytes of a bytes32.
    uint256 private constant ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    // ETH pseudo-token address.
    uint256 private constant ETH_TOKEN_ADDRESS_32 = 0x000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
    // Maximum token quantity that can be swapped against the UniswapV2Pair contract.
    uint256 private constant MAX_SWAP_AMOUNT = 2 ** 112;

    // bytes4(keccak256("executeCall(address,bytes)"))
    uint256 private constant ALLOWANCE_TARGET_EXECUTE_CALL_SELECTOR_32 =
        0xbca8c7b500000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("getReserves()"))
    uint256 private constant UNISWAP_PAIR_RESERVES_CALL_SELECTOR_32 =
        0x0902f1ac00000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("swap(uint256,uint256,address,bytes)"))
    uint256 private constant UNISWAP_PAIR_SWAP_CALL_SELECTOR_32 =
        0x022c0d9f00000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("transferFrom(address,address,uint256)"))
    uint256 private constant TRANSFER_FROM_CALL_SELECTOR_32 =
        0x23b872dd00000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("allowance(address,address)"))
    uint256 private constant ALLOWANCE_CALL_SELECTOR_32 =
        0xdd62ed3e00000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("withdraw(uint256)"))
    uint256 private constant WETH_WITHDRAW_CALL_SELECTOR_32 =
        0x2e1a7d4d00000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("deposit()"))
    uint256 private constant WETH_DEPOSIT_CALL_SELECTOR_32 =
        0xd0e30db000000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("transfer(address,uint256)"))
    uint256 private constant ERC20_TRANSFER_CALL_SELECTOR_32 =
        0xa9059cbb00000000000000000000000000000000000000000000000000000000;

    /// @dev Construct this contract.
    /// @param weth The WETH contract.
    constructor(IEtherTokenV06 weth) public {
        WETH = weth;
    }

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.sellToUniswap.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Efficiently sell directly to uniswap/sushiswap.
    /// @param tokens Sell path.
    /// @param sellAmount of `tokens[0]` Amount to sell.
    /// @param minBuyAmount Minimum amount of `tokens[-1]` to buy.
    /// @param isSushi Use sushiswap if true.
    /// @return buyAmount Amount of `tokens[-1]` bought.
    function sellToUniswap(
        IERC20TokenV06[] calldata tokens,
        uint256 sellAmount,
        uint256 minBuyAmount,
        bool isSushi
    ) external payable override returns (uint256 buyAmount) {
        require(tokens.length > 1, "UniswapFeature/InvalidTokensLength");
        {
            // Load immutables onto the stack.
            IEtherTokenV06 weth = WETH;

            // Store some vars in memory to get around stack limits.
            assembly {
                // calldataload(mload(0xA00)) == first element of `tokens` array
                mstore(0xA00, add(calldataload(0x04), 0x24))
                // mload(0xA20) == isSushi
                mstore(0xA20, isSushi)
                // mload(0xA40) == WETH
                mstore(0xA40, weth)
            }
        }

        assembly {
            // numPairs == tokens.length - 1
            let numPairs := sub(calldataload(add(calldataload(0x04), 0x4)), 1)
            // We use the previous buy amount as the sell amount for the next
            // pair in a path. So for the first swap we want to set it to `sellAmount`.
            buyAmount := sellAmount
            let buyToken
            let nextPair := 0

            for {
                let i := 0
            } lt(i, numPairs) {
                i := add(i, 1)
            } {
                // sellToken = tokens[i]
                let sellToken := loadTokenAddress(i)
                // buyToken = tokens[i+1]
                buyToken := loadTokenAddress(add(i, 1))
                // The canonical ordering of this token pair.
                let pairOrder := lt(normalizeToken(sellToken), normalizeToken(buyToken))

                // Compute the pair address if it hasn't already been computed
                // from the last iteration.
                let pair := nextPair
                if iszero(pair) {
                    pair := computePairAddress(sellToken, buyToken)
                    nextPair := 0
                }

                if iszero(i) {
                    // This is the first token in the path.
                    switch eq(sellToken, ETH_TOKEN_ADDRESS_32)
                    case 0 {
                        // Not selling ETH. Selling an ERC20 instead.
                        // Make sure ETH was not attached to the call.
                        if gt(callvalue(), 0) {
                            revert(0, 0)
                        }
                        // For the first pair we need to transfer sellTokens into the
                        // pair contract.
                        moveTakerTokensTo(sellToken, pair, sellAmount)
                    }
                    default {
                        // If selling ETH, we need to wrap it to WETH and transfer to the
                        // pair contract.
                        if iszero(eq(callvalue(), sellAmount)) {
                            revert(0, 0)
                        }
                        sellToken := mload(0xA40) // Re-assign to WETH
                        // Call `WETH.deposit{value: sellAmount}()`
                        mstore(0xB00, WETH_DEPOSIT_CALL_SELECTOR_32)
                        if iszero(call(gas(), sellToken, sellAmount, 0xB00, 0x4, 0x00, 0x0)) {
                            bubbleRevert()
                        }
                        // Call `WETH.transfer(pair, sellAmount)`
                        mstore(0xB00, ERC20_TRANSFER_CALL_SELECTOR_32)
                        mstore(0xB04, pair)
                        mstore(0xB24, sellAmount)
                        if iszero(call(gas(), sellToken, 0, 0xB00, 0x44, 0x00, 0x0)) {
                            bubbleRevert()
                        }
                    }
                    // No need to check results, if deposit/transfers failed the UniswapV2Pair will
                    // reject our trade (or it may succeed if somehow the reserve was out of sync)
                    // this is fine for the taker.
                }

                // Call pair.getReserves(), store the results at `0xC00`
                mstore(0xB00, UNISWAP_PAIR_RESERVES_CALL_SELECTOR_32)
                if iszero(staticcall(gas(), pair, 0xB00, 0x4, 0xC00, 0x40)) {
                    bubbleRevert()
                }
                // Revert if the pair contract does not return at least two words.
                if lt(returndatasize(), 0x40) {
                    revert(0, 0)
                }

                // Sell amount for this hop is the previous buy amount.
                let pairSellAmount := buyAmount
                // Compute the buy amount based on the pair reserves.
                {
                    let sellReserve
                    let buyReserve
                    switch iszero(pairOrder)
                    case 0 {
                        // Transpose if pair order is different.
                        sellReserve := mload(0xC00)
                        buyReserve := mload(0xC20)
                    }
                    default {
                        sellReserve := mload(0xC20)
                        buyReserve := mload(0xC00)
                    }
                    // Ensure that the sellAmount is < 2¹¹².
                    if gt(pairSellAmount, MAX_SWAP_AMOUNT) {
                        revert(0, 0)
                    }
                    // Pairs are in the range (0, 2¹¹²) so this shouldn't overflow.
                    // buyAmount = (pairSellAmount * 997 * buyReserve) /
                    //     (pairSellAmount * 997 + sellReserve * 1000);
                    let sellAmountWithFee := mul(pairSellAmount, 997)
                    buyAmount := div(mul(sellAmountWithFee, buyReserve), add(sellAmountWithFee, mul(sellReserve, 1000)))
                }

                let receiver
                // Is this the last pair contract?
                switch eq(add(i, 1), numPairs)
                case 0 {
                    // Not the last pair contract, so forward bought tokens to
                    // the next pair contract.
                    nextPair := computePairAddress(buyToken, loadTokenAddress(add(i, 2)))
                    receiver := nextPair
                }
                default {
                    // The last pair contract.
                    // Forward directly to taker UNLESS they want ETH back.
                    switch eq(buyToken, ETH_TOKEN_ADDRESS_32)
                    case 0 {
                        receiver := caller()
                    }
                    default {
                        receiver := address()
                    }
                }

                // Call pair.swap()
                mstore(0xB00, UNISWAP_PAIR_SWAP_CALL_SELECTOR_32)
                switch pairOrder
                case 0 {
                    mstore(0xB04, buyAmount)
                    mstore(0xB24, 0)
                }
                default {
                    mstore(0xB04, 0)
                    mstore(0xB24, buyAmount)
                }
                mstore(0xB44, receiver)
                mstore(0xB64, 0x80)
                mstore(0xB84, 0)
                if iszero(call(gas(), pair, 0, 0xB00, 0xA4, 0, 0)) {
                    bubbleRevert()
                }
            } // End for-loop.

            // If buying ETH, unwrap the WETH first
            if eq(buyToken, ETH_TOKEN_ADDRESS_32) {
                // Call `WETH.withdraw(buyAmount)`
                mstore(0xB00, WETH_WITHDRAW_CALL_SELECTOR_32)
                mstore(0xB04, buyAmount)
                if iszero(call(gas(), mload(0xA40), 0, 0xB00, 0x24, 0x00, 0x0)) {
                    bubbleRevert()
                }
                // Transfer ETH to the caller.
                if iszero(call(gas(), caller(), buyAmount, 0xB00, 0x0, 0x00, 0x0)) {
                    bubbleRevert()
                }
            }

            // Functions ///////////////////////////////////////////////////////

            // Load a token address from the `tokens` calldata argument.
            function loadTokenAddress(idx) -> addr {
                addr := and(ADDRESS_MASK, calldataload(add(mload(0xA00), mul(idx, 0x20))))
            }

            // Convert ETH pseudo-token addresses to WETH.
            function normalizeToken(token) -> normalized {
                normalized := token
                // Translate ETH pseudo-tokens to WETH.
                if eq(token, ETH_TOKEN_ADDRESS_32) {
                    normalized := mload(0xA40)
                }
            }

            // Compute the address of the UniswapV2Pair contract given two
            // tokens.
            function computePairAddress(tokenA, tokenB) -> pair {
                // Convert ETH pseudo-token addresses to WETH.
                tokenA := normalizeToken(tokenA)
                tokenB := normalizeToken(tokenB)
                // There is one contract for every combination of tokens,
                // which is deployed using CREATE2.
                // The derivation of this address is given by:
                //   address(keccak256(abi.encodePacked(
                //       bytes(0xFF),
                //       address(UNISWAP_FACTORY_ADDRESS),
                //       keccak256(abi.encodePacked(
                //           tokenA < tokenB ? tokenA : tokenB,
                //           tokenA < tokenB ? tokenB : tokenA,
                //       )),
                //       bytes32(UNISWAP_PAIR_INIT_CODE_HASH),
                //   )));

                // Compute the salt (the hash of the sorted tokens).
                // Tokens are written in reverse memory order to packed encode
                // them as two 20-byte values in a 40-byte chunk of memory
                // starting at 0xB0C.
                switch lt(tokenA, tokenB)
                case 0 {
                    mstore(0xB14, tokenA)
                    mstore(0xB00, tokenB)
                }
                default {
                    mstore(0xB14, tokenB)
                    mstore(0xB00, tokenA)
                }
                let salt := keccak256(0xB0C, 0x28)
                // Compute the pair address by hashing all the components together.
                switch mload(0xA20) // isSushi
                case 0 {
                    mstore(0xB00, FF_UNISWAP_FACTORY)
                    mstore(0xB15, salt)
                    mstore(0xB35, UNISWAP_PAIR_INIT_CODE_HASH)
                }
                default {
                    mstore(0xB00, FF_SUSHISWAP_FACTORY)
                    mstore(0xB15, salt)
                    mstore(0xB35, SUSHISWAP_PAIR_INIT_CODE_HASH)
                }
                pair := and(ADDRESS_MASK, keccak256(0xB00, 0x55))
            }

            // Revert with the return data from the most recent call.
            function bubbleRevert() {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            // Move `amount` tokens from the taker/caller to `to`.
            function moveTakerTokensTo(token, to, amount) {
                // Perform a `transferFrom()`
                mstore(0xB00, TRANSFER_FROM_CALL_SELECTOR_32)
                mstore(0xB04, caller())
                mstore(0xB24, to)
                mstore(0xB44, amount)

                let success := call(
                    gas(),
                    token,
                    0,
                    0xB00,
                    0x64,
                    0xC00,
                    // Copy only the first 32 bytes of return data. We
                    // only care about reading a boolean in the success
                    // case. We will use returndatacopy() in the failure case.
                    0x20
                )

                let rdsize := returndatasize()

                // Check for ERC20 success. ERC20 tokens should
                // return a boolean, but some return nothing or
                // extra data. We accept 0-length return data as
                // success, or at least 32 bytes that starts with
                // a 32-byte boolean true.
                success := and(
                    success, // call itself succeeded
                    or(
                        iszero(rdsize), // no return data, or
                        and(
                            iszero(lt(rdsize, 32)), // at least 32 bytes
                            eq(mload(0xC00), 1) // starts with uint256(1)
                        )
                    )
                )

                if iszero(success) {
                    // Revert with the data returned from the transferFrom call.
                    returndatacopy(0, 0, rdsize)
                    revert(0, rdsize)
                }
            }
        }

        // Revert if we bought too little.
        // TODO: replace with rich revert?
        require(buyAmount >= minBuyAmount, "UniswapFeature/UnderBought");
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../errors/LibCommonRichErrors.sol";
import "../errors/LibOwnableRichErrors.sol";
import "../features/interfaces/IOwnableFeature.sol";
import "../features/interfaces/ISimpleFunctionRegistryFeature.sol";

/// @dev Common feature utilities.
abstract contract FixinCommon {
    using LibRichErrorsV06 for bytes;

    /// @dev The implementation address of this feature.
    address internal immutable _implementation;

    /// @dev The caller must be this contract.
    modifier onlySelf() virtual {
        if (msg.sender != address(this)) {
            LibCommonRichErrors.OnlyCallableBySelfError(msg.sender).rrevert();
        }
        _;
    }

    /// @dev The caller of this function must be the owner.
    modifier onlyOwner() virtual {
        {
            address owner = IOwnableFeature(address(this)).owner();
            if (msg.sender != owner) {
                LibOwnableRichErrors.OnlyOwnerError(msg.sender, owner).rrevert();
            }
        }
        _;
    }

    constructor() internal {
        // Remember this feature's original address.
        _implementation = address(this);
    }

    /// @dev Registers a function implemented by this feature at `_implementation`.
    ///      Can and should only be called within a `migrate()`.
    /// @param selector The selector of the function whose implementation
    ///        is at `_implementation`.
    function _registerFeatureFunction(bytes4 selector) internal {
        ISimpleFunctionRegistryFeature(address(this)).extend(selector, _implementation);
    }

    /// @dev Encode a feature version as a `uint256`.
    /// @param major The major version number of the feature.
    /// @param minor The minor version number of the feature.
    /// @param revision The revision number of the feature.
    /// @return encodedVersion The encoded version number.
    function _encodeVersion(
        uint32 major,
        uint32 minor,
        uint32 revision
    ) internal pure returns (uint256 encodedVersion) {
        return (uint256(major) << 64) | (uint256(minor) << 32) | uint256(revision);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../errors/LibOwnableRichErrors.sol";

library LibMigrate {
    /// @dev Magic bytes returned by a migrator to indicate success.
    ///      This is `keccack('MIGRATE_SUCCESS')`.
    bytes4 internal constant MIGRATE_SUCCESS = 0x2c64c5ef;

    using LibRichErrorsV06 for bytes;

    /// @dev Perform a delegatecall and ensure it returns the magic bytes.
    /// @param target The call target.
    /// @param data The call data.
    function delegatecallMigrateFunction(address target, bytes memory data) internal {
        (bool success, bytes memory resultData) = target.delegatecall(data);
        if (!success || resultData.length != 32 || abi.decode(resultData, (bytes4)) != MIGRATE_SUCCESS) {
            LibOwnableRichErrors.MigrateCallFailedError(target, resultData).rrevert();
        }
    }
}