/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

interface IStakingVault {
    /// @notice Represents the stake a user has in the vault.
    struct Stake {
        uint128 amount;
        uint64 lockExpiry;
    }

    // Events.

    /// @notice Emitted every time a user's stake changes.
    event StakeChanged(
        address indexed account,
        uint128 amount,
        uint64 lockExpiry
    );

    /// @notice Emitted when a user boosts either the value or the lock of their stake.
    event BoostHFTStake(
        address indexed account,
        uint128 amount,
        uint64 daysStaked
    );

    /// @notice Emitted when HFT is withdrawn.
    event WithdrawHFT(
        address indexed account,
        uint128 amountWithdrawn,
        uint128 amountRestaked
    );

    /// @notice Emitted when a stake is transferred to a different vault.
    event TransferHFTStake(
        address indexed account,
        address targetVault,
        uint128 amount
    );

    /// @notice Emitted when the max number of staking days is updated.
    event UpdateMaxDaysToStake(uint16 maxDaysToStake);

    /// @notice Emitted when a source vault authorization status changes.
    event UpdateSourceVaultAuthorization(address vault, bool isAuthorized);

    /// @notice Emitted when a target vault authorization status changes.
    event UpdateTargetVaultAuthorization(address vault, bool isAuthorized);

    // Auto-generated functions.

    /// @notice Returns the stake that a user has.
    function stakes(address user) external returns (uint128, uint64);

    /// @notice Returns the authorization status of a vault to receive HFT from.
    /// @param vault The source vault.
    /// @return The authorization status.
    function sourceVaultAuthorization(address vault) external returns (bool);

    /// @notice Returns the authorization status of a vault to send HFT to.
    /// @param vault The source vault.
    /// @return The authorization status.
    function targetVaultAuthorization(address vault) external returns (bool);

    // Functions.

    /// @notice The total (voting) power of a user's stake.
    /// @param user The user to compute the power for.
    /// @return Total stake power.
    function getStakePower(address user) external view returns (uint256);

    /// @notice Increases the amount or the lock of a stake, or both.
    /// @param amount Amount to increase the stake by.
    /// @param daysToStake Days to increase the stake lock by.
    function boostHFTStake(uint128 amount, uint16 daysToStake) external;

    /**
     * @notice Increases the amount or the lock of a stake, or both.
     *
     * Uses an ERC-721 permit for HFT allowance.
     */
    /// @param amount Amount to increase the stake by.
    /// @param daysToStake Days to increase the stake lock by.
    /// @param deadline Deadline of permit.
    /// @param v v-part of the permit signature.
    /// @param r r-part of the permit signature.
    /// @param s s-part of the permit signature.
    /// @param approvalAmount Amount of HFT to spend that the permit approves.
    function boostHFTStakeWithPermit(
        uint128 amount,
        uint16 daysToStake,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 approvalAmount
    ) external;

    /// @notice Increases the HFT amount of a user's stake.
    /// @param user The user to increase the stake for.
    /// @param amount Amount by which the stake needs to be increased.
    /// @dev Can only be called by a contract.
    function increaseHFTStakeAmountFor(address user, uint128 amount) external;

    /// @notice Withdraws HFT to the user.
    /// @param amountToRestake Amount of HFT to re-stake instead of withdrawing.
    /// @param daysToRestake Number of days to lock the re-staked portion.
    function withdrawHFT(
        uint128 amountToRestake,
        uint16 daysToRestake
    ) external;

    /// @notice Transfers a user's stake to another vault.
    /// @param targetVault The address of the target vault.
    function transferHFTStake(address targetVault) external;

    /// @notice Receives a stake transfer that is issued via transferHFTStake.
    /// @param user The user to receive the transfer for.
    /// @param amount Amount of stake to receive.
    /// @param lockExpiry Lock expiry in the source vault.
    function receiveHFTStakeTransfer(
        address user,
        uint128 amount,
        uint64 lockExpiry
    ) external;

    // Admin.

    /// @notice Updates the max staking period, in days.
    /// @param maxDaysToStake The new max number of days a user is allowed to stake.
    function updateMaxDaysToStake(uint16 maxDaysToStake) external;

    /// @notice Updates the authorization status of a source vault, for stake transfer.
    /// @param vault The vault to update the authorization for.
    /// @param isAuthorized The new authorization status.
    function updateSourceVaultAuthorization(
        address vault,
        bool isAuthorized
    ) external;

    /// @notice Updates the authorization status of a target vault, for stake transfer.
    /// @param vault The vault to update the authorization for.
    /// @param isAuthorized The new authorization status.
    function updateTargetVaultAuthorization(
        address vault,
        bool isAuthorized
    ) external;
}

interface IWormholeStructs {
    struct Provider {
        uint16 chainId;
        uint16 governanceChainId;
        bytes32 governanceContract;
    }

    struct GuardianSet {
        address[] keys;
        uint32 expirationTime;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;
        uint32 guardianSetIndex;
        Signature[] signatures;
        bytes32 hash;
    }
}



interface IWormhole is IWormholeStructs {
    event LogMessagePublished(
        address indexed sender,
        uint64 sequence,
        uint32 nonce,
        bytes payload,
        uint8 consistencyLevel
    );

    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function parseAndVerifyVM(
        bytes calldata encodedVM
    )
        external
        view
        returns (
            IWormholeStructs.VM memory vm,
            bool valid,
            string memory reason
        );

    function verifyVM(
        IWormholeStructs.VM memory vm
    ) external view returns (bool valid, string memory reason);

    function verifySignatures(
        bytes32 hash,
        IWormholeStructs.Signature[] memory signatures,
        IWormholeStructs.GuardianSet memory guardianSet
    ) external pure returns (bool valid, string memory reason);

    function parseVM(
        bytes memory encodedVM
    ) external pure returns (IWormholeStructs.VM memory vm);

    function getGuardianSet(
        uint32 index
    ) external view returns (IWormholeStructs.GuardianSet memory);

    function getCurrentGuardianSetIndex() external view returns (uint32);

    function getGuardianSetExpiry() external view returns (uint32);

    function governanceActionIsConsumed(
        bytes32 hash
    ) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function chainId() external view returns (uint16);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function messageFee() external view returns (uint256);
}


interface IWormholeBaseUpgradeable {
    /// @notice Emitted when the Wormhole Endpoin is updated.
    /// @param newWormhole The new Wormhole Endpoin address.
    /// @param oldWormhole The previous Wormhole Endpoin address.
    event UpdateWormhole(address newWormhole, address oldWormhole);

    /// @notice Emitted when the Wormhole Chain ID is updated.
    /// @param newWormholeChainId The new Wormhole Chain ID.
    /// @param oldWormholeChainId The previous Wormhole Chain ID.
    event UpdateWormholeChainId(
        uint16 newWormholeChainId,
        uint16 oldWormholeChainId
    );

    /// @notice Emitted when the Wormhle Consistency Level is updated.
    /// @param newConsistencyLevel The new Consistency Level.
    /// @param oldConsistencyLevel The previous consistency Level.
    event UpdateWormholeConsistencyLevel(
        uint8 newConsistencyLevel,
        uint8 oldConsistencyLevel
    );

    /// @notice Emitted when a trusted Wormhole x-chain remote is updated.
    /// @param wormholeChainId The Wormhole Chain ID for which the remote is updated.
    /// @param remote The remote address, 0-padded to 32 bytes.
    event UpdateWormholeRemote(uint16 wormholeChainId, bytes32 remote);

    /// @notice Emitted when a Wormhole message has been sent (published).
    /// @param sequence The Sequence Number of the message.
    event WormholeSend(uint64 sequence);

    /// @notice Emitted when a Wormhole message has been received (relayed).
    /// @param emitterChainId The source Wormhole Chain ID.
    /// @param emitterAddress The address of the emitting contract, 0-padded to 32 bytes.
    /// @param sequence The Sequence Number of the message.
    event WormholeReceive(
        uint16 emitterChainId,
        bytes32 emitterAddress,
        uint64 sequence
    );

    /// @notice Updates the Wormhole Endpoint address.
    /// @param wormhole The address of the new Wormhole endpoint.
    /// @dev This also sets a new Wormhole Chain ID.
    function updateWormhole(address wormhole) external;

    /// @notice Updates the Wormhole Consistency Level.
    /// @param wormholeConsistencyLevel The new Wormhole Consistency Level.
    function updateWormholeConsistencyLevel(
        uint8 wormholeConsistencyLevel
    ) external;

    /// @notice Updates the trusted Wormhole x-chain remote for a particular Wormhole Chain ID.
    /// @param wormholeChainId The Wormhole Chain ID to update the trusted remote for.
    /// @param authorizedRemote The trusted remote address, 0-padded to 32 bytes.
    function updateWormholeRemote(
        uint16 wormholeChainId,
        bytes32 authorizedRemote
    ) external;

    /// @notice Allows the owner to withdraw fees collected for the Relayer.
    function withdrawRelayerFees() external;
}


interface IHashflowRouter {
    struct RFQTQuote {
        address pool;
        address externalAccount;
        address trader;
        address effectiveTrader;
        address baseToken;
        address quoteToken;
        uint256 effectiveBaseTokenAmount;
        uint256 maxBaseTokenAmount;
        uint256 maxQuoteTokenAmount;
        uint256 quoteExpiry;
        uint256 nonce;
        bytes32 txid;
        bytes signature;
    }

    function tradeSingleHop(RFQTQuote memory quote) external payable;
}



library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}




abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}



library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}





interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}



interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}



contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}



interface IERC4906Upgradeable is IERC165Upgradeable, IERC721Upgradeable {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

interface IRenovaAvatarBase is IERC4906Upgradeable {
    enum RenovaFaction {
        RESISTANCE,
        SOLUS
    }

    enum RenovaRace {
        GUARDIAN,
        EX_GUARDIAN,
        WARDEN_DROID,
        HASHBOT
    }

    enum RenovaGender {
        MALE,
        FEMALE
    }

    /// @notice Emitted when an Avatar is minted.
    /// @param player The owner of the Avatar.
    /// @param faction The faction of the Avatar.
    /// @param race The race of the Avatar.
    /// @param gender The gender of the Avatar.
    event Mint(
        address indexed player,
        RenovaFaction faction,
        RenovaRace race,
        RenovaGender gender
    );

    /// @notice Emitted when the Custom Metadata URI is updated.
    /// @param uri The new URI.
    event UpdateCustomURI(string uri);

    /// @notice Returns the faction of a player.
    /// @param player The player.
    /// @return The faction.
    function factions(address player) external returns (RenovaFaction);

    /// @notice Returns the race of a player.
    /// @param player The player.
    /// @return The race.
    function races(address player) external returns (RenovaRace);

    /// @notice Returns the gender of a player.
    /// @param player The player.
    /// @return The gender.
    function genders(address player) external returns (RenovaGender);

    /// @notice Returns the token ID of a player.
    /// @param player The player.
    /// @return The token ID.
    function tokenIds(address player) external returns (uint256);

    /// @notice Sets a custom base URI for the token metadata.
    /// @param customBaseURI The new Custom URI.
    function setCustomBaseURI(string memory customBaseURI) external;

    /// @notice Emits a refresh metadata event for a token.
    /// @param tokenId The ID of the token.
    function refreshMetadata(uint256 tokenId) external;

    /// @notice Emits a refresh metadata event for all tokens.
    function refreshAllMetadata() external;
}




interface IRenovaAvatar is IRenovaAvatarBase {
    /// @notice Emitted when the Avatar is minted to another chain.
    /// @param player The owner of the Avatar.
    /// @param faction The faction of the Avatar.
    /// @param race The race of the Avatar.
    /// @param gender The gender of the Avatar.
    /// @param dstWormholeChainId The Wormhole Chain ID of the destination chain.
    /// @param sequence The Sequence number of the Wormhole message.
    event XChainMintOut(
        address indexed player,
        RenovaFaction faction,
        RenovaRace race,
        RenovaGender gender,
        uint16 dstWormholeChainId,
        uint256 sequence,
        uint256 relayerFee
    );

    /// @notice Emitted when the StakingVault contract that tracks veHFT is updated.
    /// @param stakingVault The address of the new StakingVault contract.
    /// @param prevStakingVault The address of the previous StakingVault contract.
    event UpdateStakingVault(address stakingVault, address prevStakingVault);

    /// @notice Emitted when the minimum stake power required to mint changes.
    /// @param minStakePower The new required minimum stake power.
    event UpdateMinStakePower(uint256 minStakePower);

    /// @notice Initializer function.
    /// @param renovaCommandDeck The Renova Command Deck.
    /// @param stakingVault The address of the StakingVault contract.
    /// @param minStakePower The minimum amount of stake power required to mint an Avatar.
    /// @param wormhole The Wormhole Endpoint. See {IWormholeBaseUpgradeable}.
    /// @param wormholeConsistencyLevel The Wormhole Consistency Level. See {IWormholeBaseUpgradeable}.
    function initialize(
        address renovaCommandDeck,
        address stakingVault,
        uint256 minStakePower,
        address wormhole,
        uint8 wormholeConsistencyLevel
    ) external;

    /// @notice Updates the StakingVault contract used to track veHFT.
    /// @param stakingVault The address of the new StakingVault contract.
    function updateStakingVault(address stakingVault) external;

    /// @notice Updates the minimum stake power required to mint an Avatar.
    /// @param minStakePower The new minimum stake power required.
    function updateMinStakePower(uint256 minStakePower) external;

    /// @notice Mints an Avatar. Requires a minimum amount of stake power.
    /// @param faction The faction of the Avatar.
    /// @param race The race of the Avatar.
    /// @param gender The gender of the Avatar.
    function mint(
        RenovaFaction faction,
        RenovaRace race,
        RenovaGender gender
    ) external;

    /// @notice Mints the Avatar cross-chain, via Wormhole.
    /// @param dstWormholeChainId The Wormhole Chain ID of the chain to mint on. See {IWormholeBaseUpgradeable}.
    function wormholeMintSend(
        uint16 dstWormholeChainId,
        uint256 wormholeMessageFee
    ) external payable;
}


interface IRenovaQuest {
    enum QuestMode {
        SOLO,
        TEAM
    }

    struct TokenDeposit {
        address token;
        uint256 amount;
    }

    /// @notice Emitted when a token authorization status changes.
    /// @param token The address of the token.
    /// @param status Whether the token is allowed for trading.
    event UpdateTokenAuthorizationStatus(address token, bool status);

    /// @notice Emitted when a player registers for a quest.
    /// @param player The player registering for the quest.
    event RegisterPlayer(address indexed player);

    /// @notice Emitted when a player loads an item.
    /// @param player The player who loads the item.
    /// @param tokenId The Token ID of the loaded item.
    event LoadItem(address indexed player, uint256 tokenId);

    /// @notice Emitted when a player unloads an item.
    /// @param player The player who unloads the item.
    /// @param tokenId The Token ID of the unloaded item.
    event UnloadItem(address indexed player, uint256 tokenId);

    /// @notice Emitted when a player deposits a token for a Quest.
    /// @param player The player who deposits the token.
    /// @param token The address of the token (0x0 for native token).
    /// @param amount The amount of token being deposited.
    event DepositToken(address indexed player, address token, uint256 amount);

    /// @notice Emitted when a player withdraws a token from a Quest.
    /// @param player The player who withdraws the token.
    /// @param token The address of the token (0x0 for native token).
    /// @param amount The amount of token being withdrawn.
    event WithdrawToken(address indexed player, address token, uint256 amount);

    /// @notice Emitted when a player trades as part of the Quest.
    /// @param player The player who traded.
    /// @param baseToken The address of the token the player sold.
    /// @param quoteToken The address of the token the player bought.
    /// @param baseTokenAmount The amount sold.
    /// @param quoteTokenAmount The amount bought.
    event Trade(
        address indexed player,
        address baseToken,
        address quoteToken,
        uint256 baseTokenAmount,
        uint256 quoteTokenAmount
    );

    /// @notice Returns the Quest start time.
    /// @return The Quest start time.
    function startTime() external returns (uint256);

    /// @notice Returns the Quest end time.
    /// @return The Quest end time.
    function endTime() external returns (uint256);

    /// @notice Returns the address that has authority over the quest.
    /// @return The address that has authority over the quest.
    function questOwner() external returns (address);

    /// @notice Returns whether a player has registered for the Quest.
    /// @param player The address of the player.
    /// @return Whether the player has registered.
    function registered(address player) external returns (bool);

    /// @notice Used by the owner to allow / disallow a token for trading.
    /// @param token The address of the token.
    /// @param status The authorization status.
    function updateTokenAuthorization(address token, bool status) external;

    /// @notice Returns whether a token is allowed for deposits / trading.
    /// @param token The address of the token.
    /// @return Whether the token is allowed for trading.
    function allowedTokens(address token) external returns (bool);

    /// @notice Returns the number of registered players.
    /// @return The number of registered players.
    function numRegisteredPlayers() external returns (uint256);

    /// @notice Returns the number of registered players by faction.
    /// @param faction The faction.
    /// @return The number of registered players in the faction.
    function numRegisteredPlayersPerFaction(
        IRenovaAvatar.RenovaFaction faction
    ) external returns (uint256);

    /// @notice Returns the number of loaded items for a player.
    /// @param player The address of the player.
    /// @return The number of currently loaded items.
    function numLoadedItems(address player) external returns (uint256);

    /// @notice Returns the Token IDs for the loaded items for a player.
    /// @param player The address of the player.
    /// @param idx The index of the item in the array of loaded items.
    /// @return The Token ID of the item.
    function loadedItems(
        address player,
        uint256 idx
    ) external returns (uint256);

    /// @notice Returns the token balance for each token the player has in the Quest.
    /// @param player The address of the player.
    /// @param token The address of the token.
    /// @return The player's token balance for this Quest.
    function portfolioTokenBalances(
        address player,
        address token
    ) external returns (uint256);

    /// @notice Registers a player for the quests, loads items, and deposits tokens.
    /// @param tokenIds The token IDs for the items to load.
    /// @param tokenDeposits The tokens and amounts to deposit.
    function enterLoadDeposit(
        uint256[] memory tokenIds,
        TokenDeposit[] memory tokenDeposits
    ) external payable;

    /// @notice Registers a player for the quest.
    function enter() external;

    /// @notice Loads items into the Quest.
    /// @param tokenIds The Token IDs of the loaded items.
    function loadItems(uint256[] memory tokenIds) external;

    /// @notice Unloads an item.
    /// @param tokenId the Token ID of the item to unload.
    function unloadItem(uint256 tokenId) external;

    /// @notice Unloads all loaded items for the player.
    function unloadAllItems() external;

    /// @notice Deposits tokens prior to the beginning of the Quest.
    /// @param tokenDeposits The addresses and amounts of tokens to deposit.
    function depositTokens(
        TokenDeposit[] memory tokenDeposits
    ) external payable;

    /// @notice Withdraws the full balance of the selected tokens from the Quest.
    /// @param tokens The addresses of the tokens to withdraw.
    function withdrawTokens(address[] memory tokens) external;

    /// @notice Trades within the Quest.
    /// @param quote The Hashflow Quote.
    function trade(IHashflowRouter.RFQTQuote memory quote) external payable;
}


interface IRenovaCommandDeckBase {
    /// @notice Emitted every time the Hashflow Router is updated.
    /// @param newRouter The address of the new Hashflow Router.
    /// @param oldRouter The address of the old Hashflow Router.
    event UpdateHashflowRouter(address newRouter, address oldRouter);

    /// @notice Emitted every time the Quest Owner changes.
    /// @param newQuestOwner The address of the new Quest Owner.
    /// @param oldQuestOwner The address of the old Quest Owner.
    event UpdateQuestOwner(address newQuestOwner, address oldQuestOwner);

    /// @notice Emitted every time a Quest is created.
    /// @param questId The Quest ID.
    /// @param questAddress The address of the contract handling the Quest logic.
    /// @param questMode The Mode of the Quest (e.g. Multiplayer).
    /// @param maxPlayers The max number of players (0 for infinite).
    /// @param maxItemsPerPlayer The max number of items (0 for infinite) each player can equip.
    /// @param startTime The quest start time, in unix seconds.
    /// @param endTime The quest end time, in unix seconds.
    event CreateQuest(
        bytes32 questId,
        address questAddress,
        IRenovaQuest.QuestMode questMode,
        uint256 maxPlayers,
        uint256 maxItemsPerPlayer,
        uint256 startTime,
        uint256 endTime
    );

    /// @notice Returns the Avatar contract address.
    /// @return The address of the Avatar contract.
    function renovaAvatar() external returns (address);

    /// @notice Returns the Item contract address.
    /// @return The address of the Item contract.
    function renovaItem() external returns (address);

    /// @notice Returns the Router contract address.
    /// @return The address of the Router contract.
    function hashflowRouter() external returns (address);

    /// @notice Returns the Quest Owner address.
    /// @return The address of the Quest Owner.
    function questOwner() external returns (address);

    /// @notice Returns the deployment contract address for a quest ID.
    /// @param questId The Quest ID.
    /// @return The deployed contract address if the quest ID is valid.
    function questDeploymentAddresses(
        bytes32 questId
    ) external returns (address);

    /// @notice Returns the ID of a quest deployed at a particular address.
    /// @param questAddress The address of the Quest contract.
    /// @return The quest ID.
    function questIdsByDeploymentAddress(
        address questAddress
    ) external returns (bytes32);

    /// @notice Loads items into a Quest.
    /// @param player The address of the player loading the items.
    /// @param tokenIds The Token IDs of the items to load.
    /// @dev This function helps save gas by only setting allowance to this contract.
    function loadItemsForQuest(
        address player,
        uint256[] memory tokenIds
    ) external;

    /// @notice Deposits tokens into a Quest.
    /// @param player The address of the player depositing the tokens.
    /// @param tokenDeposits The tokens and their amounts.
    /// @dev This function helps save gas by only setting allowance to this contract.
    function depositTokensForQuest(
        address player,
        IRenovaQuest.TokenDeposit[] memory tokenDeposits
    ) external;

    /// @notice Creates a Quest in the Hashverse.
    /// @param questId The Quest ID.
    /// @param questMode The mode of the Quest (e.g. SOLO).
    /**
     * @param maxPlayers The max number of players or 0 if uncapped. If the quest is
     * a multiplayer quest, this will be the max number of players for each Faction.
     */
    /// @param maxItemsPerPlayer The max number of items per player or 0 if uncapped.
    /// @param startTime The quest start time, in Unix seconds.
    /// @param endTime The quest end time, in Unix seconds.
    function createQuest(
        bytes32 questId,
        IRenovaQuest.QuestMode questMode,
        uint256 maxPlayers,
        uint256 maxItemsPerPlayer,
        uint256 startTime,
        uint256 endTime
    ) external;

    /// @notice Updates the Hashflow Router contract address.
    /// @param hashflowRouter The new Hashflow Router contract address.
    function updateHashflowRouter(address hashflowRouter) external;

    /// @notice Updates the Quest Owner address.
    /// @param questOwner The new Quest Owner address.
    function updateQuestOwner(address questOwner) external;
}


interface IRenovaCommandDeck is IRenovaCommandDeckBase {
    /// @notice Emitted when a new Merkle root is added for item minting.
    /// @param rootId The ID of the Root.
    /// @param root The Root.
    event UploadItemMerkleRoot(bytes32 rootId, bytes32 root);

    /// @notice Initializer function.
    /// @param renovaAvatar The address of the Avatar contract.
    /// @param renovaItem The address of the Item contract.
    /// @param hashflowRouter The address of the Hashflow Router.
    /// @param questOwner The address of the Quest Owner.
    function initialize(
        address renovaAvatar,
        address renovaItem,
        address hashflowRouter,
        address questOwner
    ) external;

    /// @notice Returns the Merkle root associated with a root ID.
    /// @param rootId The root ID.
    function itemMerkleRoots(bytes32 rootId) external returns (bytes32);

    /// @notice Uploads a Merkle root for minting items.
    /// @param rootId The root ID.
    /// @param root The Merkle root.
    function uploadItemMerkleRoot(bytes32 rootId, bytes32 root) external;

    /// @notice Mints an item via Merkle root.
    /// @param tokenOwner The wallet receiving the item.
    /// @param hashverseItemId The Hashverse Item ID of the minted item.
    /// @param rootId The ID of the Merkle root to use.
    /// @param mintIdx The mint "index" for cases where multiple items are awarded.
    /// @param proof The Merkle proof.
    function mintItem(
        address tokenOwner,
        uint256 hashverseItemId,
        bytes32 rootId,
        uint256 mintIdx,
        bytes32[] calldata proof
    ) external;

    /// @notice Mints an item via admin privileges.
    /// @param tokenOwner The wallet receiving the item.
    /// @param hashverseItemId The Hashverse Item ID of the minted item.
    function mintItemAdmin(
        address tokenOwner,
        uint256 hashverseItemId
    ) external;
}



abstract contract WormholeBaseUpgradeable is
    IWormholeBaseUpgradeable,
    OwnableUpgradeable
{
    using AddressUpgradeable for address payable;

    address private _wormhole;
    uint8 private _wormholeConsistencyLevel;
    mapping(bytes32 => bool) private _processedMessageHashes;

    mapping(uint16 => bytes32) internal _wormholeRemotes;

    uint16 internal _wormholeChainId;

    /// @dev Reserved for future upgrades.
    uint256[16] private __gap;

    /// @notice Base initializer.
    /// @param wormhole The address of the Wormhole endpoint.
    /// @param wormholeConsistencyLevel The Wormhole consistency level.
    function __WormholeBaseUpgradeable_init(
        address wormhole,
        uint8 wormholeConsistencyLevel
    ) internal {
        __Ownable_init();

        _updateWormhole(wormhole);
        _updateWormholeConsistencyLevel(wormholeConsistencyLevel);
    }

    /// @inheritdoc IWormholeBaseUpgradeable
    function updateWormhole(address wormhole) external override onlyOwner {
        _updateWormhole(wormhole);
    }

    /// @inheritdoc IWormholeBaseUpgradeable
    function updateWormholeConsistencyLevel(
        uint8 wormholeConsistencyLevel
    ) external override onlyOwner {
        _updateWormholeConsistencyLevel(wormholeConsistencyLevel);
    }

    /// @inheritdoc IWormholeBaseUpgradeable
    function updateWormholeRemote(
        uint16 wormholeChainId,
        bytes32 authorizedRemote
    ) external override onlyOwner {
        require(
            wormholeChainId != 0,
            'WormholeBaseUpgradeable::updateWormholeRemote wormholeChainId cannot be 0.'
        );
        require(
            authorizedRemote != bytes32(0),
            'WormholeBaseUpgradeable::updateWormholeRemote Remote cannot be 0.'
        );
        _wormholeRemotes[wormholeChainId] = authorizedRemote;

        emit UpdateWormholeRemote(wormholeChainId, authorizedRemote);
    }

    /// @inheritdoc IWormholeBaseUpgradeable
    function withdrawRelayerFees() external override onlyOwner {
        require(
            address(this).balance > 0,
            'WormholeBaseUpgradeable::withdrawRelayerFees No fees collected.'
        );

        payable(msg.sender).sendValue(address(this).balance);
    }

    /// @notice Sends a Wormhole message.
    /// @param nonce The nonce of the message.
    /// @param payload The payload to send.
    function _wormholeSend(
        uint32 nonce,
        bytes memory payload,
        uint256 wormholeMessageFee
    ) internal virtual returns (uint64 sequence) {
        require(
            _wormhole != address(0),
            'WormholeBaseUpgradeable::_wormholeSend Wormhole is not defined.'
        );
        require(
            _wormholeConsistencyLevel > 0,
            'WormholeBaseUpgradeable:: _wormholeSend Wormhole consistency level is not defined.'
        );

        sequence = IWormhole(_wormhole).publishMessage{
            value: wormholeMessageFee
        }(nonce, payload, _wormholeConsistencyLevel);

        emit WormholeSend(sequence);
    }

    /// @notice Called when a Wormhole message is received.
    /// @param encodedVM The Wormhole VAA.
    function _wormholeReceive(
        bytes memory encodedVM
    ) internal virtual returns (uint16 emitterChainId, bytes memory payload) {
        require(
            _wormhole != address(0),
            'WormholeBaseUpgradeable::_wormholeReceive Wormhole is not defined.'
        );
        require(
            _wormholeChainId > 0,
            'WormholeBaseUpgradeable::_wormholeReceive Wormhole Chain ID is not defined.'
        );

        (
            IWormholeStructs.VM memory vm,
            bool valid,
            string memory reason
        ) = IWormhole(_wormhole).parseAndVerifyVM(encodedVM);

        require(valid, reason);
        require(
            !_processedMessageHashes[vm.hash],
            'WormholeBaseUpgradeable::_wormholeReceive Message already processed.'
        );

        _processedMessageHashes[vm.hash] = true;

        emitterChainId = vm.emitterChainId;

        require(
            _wormholeRemotes[emitterChainId] != bytes32(0),
            'WormholeBaseUpgradeable::_wormholeReceive Wormhole remote not defined on emitted chain.'
        );
        require(
            _wormholeRemotes[emitterChainId] == vm.emitterAddress,
            'WormholeBaseUpgradeable::_wormholeReceive Emitter not authorized.'
        );

        emit WormholeReceive(vm.emitterChainId, vm.emitterAddress, vm.sequence);

        payload = vm.payload;
    }

    /// @notice Updates The wormhole endpoint.
    /// @param wormhole The new Wormhole endpoint.
    function _updateWormhole(address wormhole) internal {
        require(
            wormhole != address(0),
            'WormholeBaseUpgradeable::_updateWormhole Address cannot be 0.'
        );

        emit UpdateWormhole(wormhole, _wormhole);

        _wormhole = wormhole;

        uint16 wormholeChainId = IWormhole(_wormhole).chainId();

        emit UpdateWormholeChainId(wormholeChainId, _wormholeChainId);

        _wormholeChainId = wormholeChainId;
    }

    /// @notice Updates the Wormhole consistency level.
    /// @param wormholeConsistencyLevel The new consistency level.
    function _updateWormholeConsistencyLevel(
        uint8 wormholeConsistencyLevel
    ) internal {
        require(
            wormholeConsistencyLevel > 0,
            'WormholeBaseUpgradeable::updateWormholeConsistencyLevel Consistency level cannot be set to 0.'
        );

        emit UpdateWormholeConsistencyLevel(
            wormholeConsistencyLevel,
            _wormholeConsistencyLevel
        );

        _wormholeConsistencyLevel = wormholeConsistencyLevel;
    }
}



abstract contract RenovaAvatarBase is
    IRenovaAvatarBase,
    WormholeBaseUpgradeable,
    ERC721Upgradeable
{
    using AddressUpgradeable for address;

    string private _customBaseURI;

    address private _renovaCommandDeck;

    /// @inheritdoc IRenovaAvatarBase
    mapping(address => RenovaFaction) public factions;

    /// @inheritdoc IRenovaAvatarBase
    mapping(address => RenovaRace) public races;

    /// @inheritdoc IRenovaAvatarBase
    mapping(address => RenovaGender) public genders;

    /// @inheritdoc IRenovaAvatarBase
    mapping(address => uint256) public tokenIds;

    /// @dev Reserved for future upgrades.
    uint256[16] private __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Base initializer function.
    /// @param renovaCommandDeck The Renova Command Deck.
    /// @param wormhole The Wormhole endpoint address.
    /// @param wormholeConsistencyLevel The Wormhole consistency level.
    function __RenovaAvatarBase_init(
        address renovaCommandDeck,
        address wormhole,
        uint8 wormholeConsistencyLevel
    ) internal onlyInitializing {
        __WormholeBaseUpgradeable_init(wormhole, wormholeConsistencyLevel);

        __ERC721_init('Renova Avatar', 'RNVA');

        require(
            renovaCommandDeck != address(0),
            'RenovaAvatarBase::initalize renovaCommandDeck cannot be 0 address.'
        );

        _renovaCommandDeck = renovaCommandDeck;
    }

    /// @inheritdoc IERC165Upgradeable
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == bytes4(0x49064906) ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IERC721Upgradeable
    function transferFrom(
        address,
        address,
        uint256
    ) public pure override(ERC721Upgradeable, IERC721Upgradeable) {
        revert('RenovaAvatarBase::transferFrom Avatars are non-transferrable.');
    }

    /// @inheritdoc IERC721Upgradeable
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public pure override(ERC721Upgradeable, IERC721Upgradeable) {
        revert(
            'RenovaAvatarBase::safeTransferFrom Avatars are non-transferrable.'
        );
    }

    function approve(
        address,
        uint256
    ) public pure override(ERC721Upgradeable, IERC721Upgradeable) {
        revert('RenovaAvatarBase::approve Avatars are non-transferrable.');
    }

    function setApprovalForAll(
        address,
        bool
    ) public pure override(ERC721Upgradeable, IERC721Upgradeable) {
        revert(
            'RenovaAvatarBase::setApprovalForAll Avatars are non-transferrable.'
        );
    }

    /// @inheritdoc IERC721MetadataUpgradeable
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        string memory tokenURIPrefix = ERC721Upgradeable.tokenURI(tokenId);

        return
            bytes(tokenURIPrefix).length > 0
                ? string(abi.encodePacked(tokenURIPrefix, '.json'))
                : '';
    }

    /// @inheritdoc IRenovaAvatarBase
    function setCustomBaseURI(
        string memory customBaseURI
    ) external override onlyOwner {
        _customBaseURI = customBaseURI;

        emit UpdateCustomURI(_customBaseURI);

        emit BatchMetadataUpdate(1, type(uint256).max);
    }

    /// @inheritdoc IRenovaAvatarBase
    function refreshMetadata(uint256 tokenId) external override onlyOwner {
        emit MetadataUpdate(tokenId);
    }

    /// @inheritdoc IRenovaAvatarBase
    function refreshAllMetadata() external override onlyOwner {
        emit BatchMetadataUpdate(1, type(uint256).max);
    }

    /// @inheritdoc OwnableUpgradeable
    function renounceOwnership() public view override onlyOwner {
        revert(
            'RenovaAvatarBase::renounceOwnership Cannot renounce ownership.'
        );
    }

    /// @notice Mints an avatar.
    /// @param tokenId The Token ID.
    /// @param tokenOwner The owner of the Avatar.
    /// @param faction The faction of the Avatar.
    /// @param race The race of the Avatar.
    /// @param gender The gender of the Avatar.
    function _mintAvatar(
        uint256 tokenId,
        address tokenOwner,
        RenovaFaction faction,
        RenovaRace race,
        RenovaGender gender
    ) internal {
        require(
            balanceOf(tokenOwner) == 0,
            'RenovaAvatarBase::_mintAvatar Cannot mint more than one Avatar.'
        );
        require(
            !_msgSender().isContract(),
            'RenovaAvatarBase::_mintAvatar Contracts cannot mint.'
        );

        factions[tokenOwner] = faction;
        races[tokenOwner] = race;
        genders[tokenOwner] = gender;
        tokenIds[tokenOwner] = tokenId;

        _safeMint(tokenOwner, tokenId);

        emit Mint(tokenOwner, faction, race, gender);
    }

    /// @notice Returns the custom base URI.
    /// @return The base URI.
    function _baseURI() internal view override returns (string memory) {
        return _customBaseURI;
    }
}


contract RenovaAvatar is IRenovaAvatar, RenovaAvatarBase {
    address private _stakingVault;
    uint256 private _minStakePower;
    uint256 private _numMintedAvatars;

    /// @dev Reserved for future upgrades.
    uint256[16] private __gap;

    /// @inheritdoc IRenovaAvatar
    function initialize(
        address renovaCommandDeck,
        address stakingVault,
        uint256 minStakePower,
        address wormhole,
        uint8 wormholeConsistencyLevel
    ) external override initializer {
        __RenovaAvatarBase_init(
            renovaCommandDeck,
            wormhole,
            wormholeConsistencyLevel
        );

        require(
            stakingVault != address(0),
            'RenovaAvatar::initalize stakingVault cannot be 0 address.'
        );

        _stakingVault = stakingVault;
        _minStakePower = minStakePower;
        _numMintedAvatars = 0;
    }

    /// @inheritdoc IRenovaAvatar
    function updateStakingVault(
        address stakingVault
    ) external override onlyOwner {
        require(
            stakingVault != address(0),
            'RenovaAvatar::updateStakingVault StakingVault cannot be 0 address.'
        );

        emit UpdateStakingVault(stakingVault, _stakingVault);

        _stakingVault = stakingVault;
    }

    /// @inheritdoc IRenovaAvatar
    function updateMinStakePower(
        uint256 minStakePower
    ) external override onlyOwner {
        _minStakePower = minStakePower;

        emit UpdateMinStakePower(_minStakePower);
    }

    /// @inheritdoc IRenovaAvatar
    function mint(
        RenovaFaction faction,
        RenovaRace race,
        RenovaGender gender
    ) external override {
        uint256 currentStakePower = IStakingVault(_stakingVault).getStakePower(
            _msgSender()
        );
        require(
            currentStakePower >= _minStakePower,
            'RenovaAvatar::mint Insufficient stake.'
        );

        _numMintedAvatars++;

        _mintAvatar(_numMintedAvatars, _msgSender(), faction, race, gender);
    }

    /// @inheritdoc IRenovaAvatar
    function wormholeMintSend(
        uint16 dstWormholeChainId,
        uint256 wormholeMessageFee
    ) external payable override {
        require(
            balanceOf(_msgSender()) == 1,
            'RenovaAvatar::wormholeMintSend Avatar not minted.'
        );

        require(
            dstWormholeChainId != _wormholeChainId,
            'RenovaAvatar::wormholeMintSend Dst chain should be different than Src chain.'
        );

        require(
            msg.value >= wormholeMessageFee,
            'RenovaAvatar::wormholeMintSend msg.value does not cover fees.'
        );

        bytes memory payload = abi.encode(
            tokenIds[_msgSender()],
            _msgSender(),
            factions[_msgSender()],
            races[_msgSender()],
            genders[_msgSender()],
            dstWormholeChainId
        );

        uint64 sequence = _wormholeSend(0, payload, wormholeMessageFee);

        emit XChainMintOut(
            _msgSender(),
            factions[_msgSender()],
            races[_msgSender()],
            genders[_msgSender()],
            dstWormholeChainId,
            sequence,
            msg.value - wormholeMessageFee
        );
    }
}