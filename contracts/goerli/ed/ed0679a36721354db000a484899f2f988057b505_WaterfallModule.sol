// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Clone} from "clones-with-immutable-args/Clone.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

/// @title WaterfallModule
/// @author 0xSplits
/// @notice A maximally-composable waterfall contract allowing multiple
/// recipients to receive preferential payments before residual funds flow to a
/// final address.
/// @dev /// Only one token can be waterfall'd for a given deployment. There is a
/// recovery method for non-target tokens sent by accident.
/// This contract uses token = address(0) to refer to ETH.
contract WaterfallModule is Clone {
    /// -----------------------------------------------------------------------
    /// libraries
    /// -----------------------------------------------------------------------

    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    /// -----------------------------------------------------------------------
    /// errors
    /// -----------------------------------------------------------------------

    /// Invalid token recovery; cannot recover the waterfall token
    error InvalidTokenRecovery_WaterfallToken();

    /// Invalid token recovery recipient; not a waterfall recipient
    error InvalidTokenRecovery_InvalidRecipient();

    /// -----------------------------------------------------------------------
    /// events
    /// -----------------------------------------------------------------------

    /// Emitted after each successful ETH transfer to proxy
    /// @param amount Amount of ETH received
    /// @dev embedded in & emitted from clone bytecode
    event ReceiveETH(uint256 amount);

    /// Emitted after funds are waterfall'd to recipients
    /// @param recipients Addresses receiving payouts
    /// @param payouts Amount of payout
    event WaterfallFunds(address[] recipients, uint256[] payouts);

    /// Emitted after non-waterfall'd tokens are recovered to a recipient
    /// @param nonWaterfallToken Recovered token (cannot be waterfall token)
    /// @param recipient Address receiving recovered token
    /// @param amount Amount of recovered token
    event RecoverNonWaterfallFunds(
        address nonWaterfallToken, address recipient, uint256 amount
    );

    /// -----------------------------------------------------------------------
    /// storage
    /// -----------------------------------------------------------------------

    address internal constant ETH_ADDRESS = address(0);
    uint256 internal constant ONE_WORD = 32;
    uint256 internal constant THRESHOLD_BITS = 96;
    uint256 internal constant ADDRESS_BITS = 160;
    uint256 internal constant ADDRESS_BITMASK = uint256(~0 >> THRESHOLD_BITS);

    // 20 = address (20 bytes)
    uint256 internal constant NUM_TRANCHES_OFFSET = 20;
    // 28 = NUM_TRANCHES_OFFSET (20) + uint64 (8 bytes)
    uint256 internal constant TRANCHES_OFFSET = 28;

    /// Address of ERC20 to waterfall (0x0 used for ETH)
    /// @dev equivalent to address public immutable token;
    function token() public pure returns (address) {
        return _getArgAddress(0);
    }

    /// Number of waterfall tranches
    /// @dev equivalent to uint64 internal immutable numTranches;
    /// clones-with-immutable-args limits uint256[] array length to uint64
    function numTranches() internal pure returns (uint256) {
        return uint256(_getArgUint64(NUM_TRANCHES_OFFSET));
    }

    /// Amount of distributed waterfall token
    uint256 public distributedFunds;

    /// -----------------------------------------------------------------------
    /// constructor
    /// -----------------------------------------------------------------------

    // solhint-disable-next-line no-empty-blocks
    /// clone implementation doesn't use constructor
    constructor() {}

    /// -----------------------------------------------------------------------
    /// functions
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// functions - public & external
    /// -----------------------------------------------------------------------

    /// emit event when receiving ETH
    /// @dev implemented w/i clone bytecode
    /* receive() external payable { */
    /*     emit ReceiveETH(msg.value); */
    /* } */

    /// Waterfalls target token inside the contract to next-in-line recipients
    function waterfallFunds() external payable {
        /// checks

        /// effects

        // load storage into memory

        address _token = token();
        uint256 _startingDistributedFunds = distributedFunds;
        uint256 _endingDistributedFunds;
        unchecked {
            // shouldn't overflow
            _endingDistributedFunds = _startingDistributedFunds
                +
                // recognizes 0x0 as ETH
                // shouldn't need to worry about re-entrancy from ERC20 view fn
                (
                    _token == ETH_ADDRESS
                        ? address(this).balance
                        : ERC20(_token).balanceOf(address(this))
                );
        }

        (address[] memory recipients, uint256[] memory thresholds) =
            getTranches();

        uint256 _firstPayoutTranche;
        uint256 _lastPayoutTranche;
        unchecked {
            // shouldn't underflow while numTranches() >= 2
            uint256 finalTranche = numTranches() - 1;
            // index inc shouldn't overflow
            for (; _firstPayoutTranche < finalTranche; ++_firstPayoutTranche) {
                if (
                    thresholds[_firstPayoutTranche] >= _startingDistributedFunds
                ) {
                    break;
                }
            }
            _lastPayoutTranche = _firstPayoutTranche;
            // index inc shouldn't overflow
            for (; _lastPayoutTranche < finalTranche; ++_lastPayoutTranche) {
                if (thresholds[_lastPayoutTranche] >= _endingDistributedFunds) {
                    break;
                }
            }
        }

        uint256 _payoutsLength;
        unchecked {
            // shouldn't underflow since _lastPayoutTranche >= _firstPayoutTranche
            _payoutsLength = _lastPayoutTranche - _firstPayoutTranche + 1;
        }
        address[] memory _payoutAddresses = new address[](_payoutsLength);
        uint256[] memory _payouts = new uint256[](_payoutsLength);

        // scope allows compiler to discard vars on stack to avoid stack-too-deep
        {
            uint256 _paidOut = _startingDistributedFunds;
            uint256 _index;
            uint256 _threshold;
            uint256 i = 0;
            uint256 loopLength;
            unchecked {
                // shouldn't underflow since _payoutsLength >= 1
                loopLength = _payoutsLength - 1;
            }
            for (; i < loopLength;) {
                unchecked {
                    // shouldn't overflow
                    _index = _firstPayoutTranche + i;

                    _payoutAddresses[i] = recipients[_index];
                    _threshold = thresholds[_index];
                    // shouldn't underflow since _paidOut begins < active
                    // tranche's threshold and is then set to each preceding
                    // threshold (which are monotonically increasing)
                    _payouts[i] = _threshold - _paidOut;
                    _paidOut = _threshold;

                    // shouldn't overflow
                    ++i;
                }
            }
            // i = _payoutsLength - 1, i.e. last payout
            unchecked {
                // shouldn't overflow
                _payoutAddresses[i] = recipients[_firstPayoutTranche + i];
                // shouldn't underflow since _paidOut = last tranche threshold,
                // which should be <= _endingDistributedFunds by construction
                _payouts[i] = _endingDistributedFunds - _paidOut;
            }

            distributedFunds = _endingDistributedFunds;
        }

        /// interactions

        // pay outs
        // earlier external calls may try to re-enter but will cause fn to revert
        // when later external calls fail (bc balance is emptied early)
        for (uint256 i = 0; i < _payoutsLength;) {
            if (_token == ETH_ADDRESS) {
                (_payoutAddresses[i]).safeTransferETH(_payouts[i]);
            } else {
                ERC20(_token).safeTransfer(_payoutAddresses[i], _payouts[i]);
            }
            unchecked {
                // shouldn't overflow
                ++i;
            }
        }

        emit WaterfallFunds(_payoutAddresses, _payouts);
    }

    /// Recover non-waterfall'd tokens to a recipient
    /// @param nonWaterfallToken Token to recover (cannot be waterfall token)
    /// @param recipient Address to receive recovered token
    function recoverNonWaterfallFunds(
        address nonWaterfallToken,
        address recipient
    )
        external
        payable
    {
        /// checks

        // revert if caller tries to recover waterfall token
        if (nonWaterfallToken == token()) {
            revert InvalidTokenRecovery_WaterfallToken();
        }

        // ensure txn recipient is a valid waterfall recipient
        (address[] memory recipients,) = getTranches();
        bool validRecipient = false;
        uint256 _numTranches = numTranches();
        for (uint256 i = 0; i < _numTranches;) {
            if (recipients[i] == recipient) {
                validRecipient = true;
                break;
            }
            unchecked {
                // shouldn't overflow
                ++i;
            }
        }
        if (!validRecipient) {
            revert InvalidTokenRecovery_InvalidRecipient();
        }

        /// effects

        /// interactions

        // recover non-target token
        uint256 amount;
        if (nonWaterfallToken == ETH_ADDRESS) {
            amount = address(this).balance;
            recipient.safeTransferETH(amount);
        } else {
            amount = ERC20(nonWaterfallToken).balanceOf(address(this));
            ERC20(nonWaterfallToken).safeTransfer(recipient, amount);
        }

        emit RecoverNonWaterfallFunds(nonWaterfallToken, recipient, amount);
    }

    /// -----------------------------------------------------------------------
    /// functions - view & pure
    /// -----------------------------------------------------------------------

    /// Return tranches in an unpacked form
    /// @return recipients Addresses to waterfall payments to
    /// @return thresholds Absolute payment thresholds for waterfall recipients
    function getTranches()
        public
        pure
        returns (address[] memory recipients, uint256[] memory thresholds)
    {
        uint256 numRecipients = numTranches();
        uint256 numThresholds;
        unchecked {
            // shouldn't underflow
            numThresholds = numRecipients - 1;
        }
        recipients = new address[](numRecipients);
        thresholds = new uint256[](numThresholds);

        uint256 i = 0;
        uint256 tranche;
        for (; i < numThresholds;) {
            tranche = _getTranche(i);
            recipients[i] = address(uint160(tranche));
            thresholds[i] = tranche >> ADDRESS_BITS;
            unchecked {
                ++i;
            }
        }
        // recipients has one more entry than thresholds
        recipients[i] = address(uint160(_getTranche(i)));
    }

    function _getTranche(uint256 i) internal pure returns (uint256) {
        unchecked {
            // shouldn't overflow
            return _getArgUint256(TRANCHES_OFFSET + i * ONE_WORD);
        }
    }
}

// SPDX-License-Identifier: BSD
pragma solidity ^0.8.4;

/// @title Clone
/// @author zefram.eth, Saw-mon & Natalie
/// @notice Provides helper functions for reading immutable args from calldata
contract Clone {
    uint256 private constant ONE_WORD = 0x20;

    /// @notice Reads an immutable arg with type address
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgAddress(uint256 argOffset)
        internal
        pure
        returns (address arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0x60, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint256
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint256(uint256 argOffset)
        internal
        pure
        returns (uint256 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @notice Reads a uint256 array stored in the immutable args.
    /// @param argOffset The offset of the arg in the packed data
    /// @param arrLen Number of elements in the array
    /// @return arr The array
    function _getArgUint256Array(uint256 argOffset, uint64 arrLen)
        internal
        pure
        returns (uint256[] memory arr)
    {
        uint256 offset = _getImmutableArgsOffset() + argOffset;
        arr = new uint256[](arrLen);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let i
            arrLen := mul(arrLen, ONE_WORD)
            for {} lt(i, arrLen) {} {
                let j := add(i, ONE_WORD)
                mstore(add(arr, j), calldataload(add(offset, i)))
                i := j
            }
        }
    }

    /// @notice Reads an immutable arg with type uint64
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint64(uint256 argOffset)
        internal
        pure
        returns (uint64 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xc0, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint8
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint8(uint256 argOffset)
        internal
        pure
        returns (uint8 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset :=
                sub(calldatasize(), shr(240, calldataload(sub(calldatasize(), 2))))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}