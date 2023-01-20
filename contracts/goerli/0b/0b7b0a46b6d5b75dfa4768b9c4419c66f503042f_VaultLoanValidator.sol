// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "@solmate/auth/Owned.sol";
import "@solmate/utils/FixedPointMathLib.sol";
import "@openzeppelin/utils/structs/EnumerableSet.sol";
import "./Vault.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/loans/ILoan.sol";
import "../interfaces/IVaultLoanValidator.sol";
import "./utils/ValidatorHelpers.sol";

contract VaultLoanValidator is IVaultLoanValidator, Owned {
    using ValidatorHelpers for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using FixedPointMathLib for uint128;

    enum ValidatorType {
        NFT_PACKED_LIST,
        NFT_BIT_VECTOR,
        FULL_COLLECTION,
        ORACLE
    }

    struct GenericValidator {
        ValidatorType validatorType;
        bytes arguments;
    }

    struct CollectionMaxLTV {
        address collection;
        uint88 maxLTV;
    }

    struct BaseVaultParameters {
        uint64 maxDuration;
        uint16 managerPerformanceFeeBps;
    }

    address private _vaultFactory;

    mapping(address => bytes) private _vaultGenericValidators;

    mapping(address => BaseVaultParameters) private _baseVaultParameters;

    address[] private _collectionPackedList;
    bytes[] private _tokenIdPackedList;

    address[] private _collectionBitVector;
    bytes[] private _tokenIdBitVector;

    EnumerableSet.AddressSet private _fullCollections;

    IOracle private _oracle;
    uint128 private _delayTolerance = 12 hours;
    CollectionMaxLTV[] private _collectionMaxLTVArray;

    mapping(address => uint88) _collectionMaxLTV; // 10000 precision

    EnumerableSet.AddressSet private _acceptedLoans;

    error ValidatorWithNoLoansError();

    error VaultNotExistError(address _vault);

    error OracleNotSetError();

    error UnauthorizedError(address _authorized);

    error TokenListAlreadySetError();

    error InvalidManagerFeeError(uint16 _expected);

    error MaxDurationExceededError(uint64 _expected);

    error InvalidAssetError(address _expected);

    error ArrayLengthNotMatchedError();

    error TokenIdNotFoundError(uint256 _tokenId);

    error InvalidLTVError(uint88 _expected);

    error StaleOracleError(uint128 _updatedTimestamp, uint128 _delayTolerance);

    modifier onlyVaultFactory() {
        if (msg.sender != _vaultFactory) {
            revert UnauthorizedError(_vaultFactory);
        }
        _;
    }

    constructor(address vaultFactory, address[] memory acceptedLoans)
        Owned(msg.sender)
    {
        _vaultFactory = vaultFactory;
        uint256 total = acceptedLoans.length;
        if (total == 0) {
            revert ValidatorWithNoLoansError();
        }
        for (uint256 i; i < total; ) {
            _acceptedLoans.add(acceptedLoans[i]);
            unchecked {
                i++;
            }
        }
    }

    function addVault(address _vault, bytes calldata _validatorParameters)
        external
        onlyVaultFactory
    {
        _addVault(_vault, _validatorParameters);
    }

    function upgradeVault(
        address _vault,
        address,
        bytes calldata _parameters
    ) external onlyVaultFactory {
        _addVault(_vault, _parameters);
    }

    function getAcceptedLoans() external view returns (address[] memory) {
        return _acceptedLoans.values();
    }

    function isLoanAccepted(address _loanAddress) external view returns (bool) {
        return _acceptedLoans.contains(_loanAddress);
    }

    function validateOffer(ILoan.LoanOffer calldata _loanOffer) external view {
        address _vault = _loanOffer.vaultAddress;
        BaseVaultParameters storage baseParams = _baseVaultParameters[_vault];
        if (baseParams.maxDuration == 0) {
            revert VaultNotExistError(_vault);
        }

        if (
            _loanOffer.managerPerformanceFeeBps !=
            baseParams.managerPerformanceFeeBps
        ) {
            revert InvalidManagerFeeError(baseParams.managerPerformanceFeeBps);
        }
        if (_loanOffer.duration > baseParams.maxDuration) {
            revert MaxDurationExceededError(baseParams.maxDuration);
        }

        address asset = address(Vault(_vault).asset());
        if (asset != _loanOffer.principalAddress) {
            revert InvalidAssetError(asset);
        }

        _checkOfferGenericValidators(
            abi.decode(_vaultGenericValidators[_vault], (GenericValidator[])),
            _loanOffer
        );
    }

    function _checkOfferGenericValidators(
        GenericValidator[] memory _validators,
        ILoan.LoanOffer memory _loanOffer
    ) private view {
        uint256 totalValidators = _validators.length;
        for (uint256 i = 0; i < totalValidators; ) {
            ValidatorType thisType = _validators[i].validatorType;
            bytes memory encodedArguments = _validators[i].arguments;
            if (thisType == ValidatorType.NFT_PACKED_LIST) {
                (
                    uint64 bytesPerTokenId,
                    address[] memory collections,
                    bytes[] memory tokenIds
                ) = abi.decode(encodedArguments, (uint64, address[], bytes[]));
                _validateNFTPackedList(
                    bytesPerTokenId,
                    collections,
                    tokenIds,
                    _loanOffer.nftCollateralAddress,
                    _loanOffer.nftCollateralTokenId
                );
            } else if (thisType == ValidatorType.NFT_BIT_VECTOR) {
                (address[] memory collections, bytes[] memory tokenIds) = abi
                    .decode(encodedArguments, (address[], bytes[]));
                _validateNFTBitVector(
                    collections,
                    tokenIds,
                    _loanOffer.nftCollateralAddress,
                    _loanOffer.nftCollateralTokenId
                );
            } else if (thisType == ValidatorType.FULL_COLLECTION) {
                address[] memory collections = abi.decode(
                    encodedArguments,
                    (address[])
                );
                _validateNFTFullCollection(
                    collections,
                    _loanOffer.nftCollateralAddress,
                    _loanOffer.nftCollateralTokenId
                );
            } else if (thisType == ValidatorType.ORACLE) {
                CollectionMaxLTV[] memory collectionMaxLTV = abi.decode(
                    encodedArguments,
                    (CollectionMaxLTV[])
                );
                _validateMaxCollectionLTV(
                    collectionMaxLTV,
                    _loanOffer.nftCollateralAddress,
                    _loanOffer.nftCollateralTokenId,
                    _loanOffer.principalAddress,
                    _loanOffer.principalAmount
                );
            }
            unchecked {
                ++i;
            }
        }
    }

    function validateSell(
        ILoan.Loan memory _loan,
        ILoan.FullSaleOrder memory _order,
        address _sellerVault
    ) external view {
        address asset = address(Vault(_sellerVault).asset());
        if (asset != _order.order.asset) {
            revert InvalidAssetError(asset);
        }
    }

    function getMaxDuration(address _vault) external view returns (uint64) {
        BaseVaultParameters storage params = _baseVaultParameters[_vault];
        if (params.maxDuration == 0) {
            revert VaultNotExistError(_vault);
        }
        return params.maxDuration;
    }

    function getManagerPerformanceFeeBps(address _vault)
        external
        view
        returns (uint16)
    {
        BaseVaultParameters storage params = _baseVaultParameters[_vault];
        if (params.maxDuration == 0) {
            revert VaultNotExistError(_vault);
        }
        return params.managerPerformanceFeeBps;
    }

    function getGenericValidators(address _vault)
        external
        view
        returns (GenericValidator[] memory)
    {
        return
            abi.decode(_vaultGenericValidators[_vault], (GenericValidator[]));
    }

    function getOracleAddress() external view returns (address) {
        return address(_oracle);
    }

    function getDelayTolerance() external view returns (uint128) {
        return _delayTolerance;
    }

    function updateOracle(address _newOracle) external onlyOwner {
        _oracle = IOracle(_newOracle);
    }

    function updateDelayTolerance(uint128 _newDelayTolerance)
        external
        onlyOwner
    {
        _delayTolerance = _newDelayTolerance;
    }

    function _verifyValidators(GenericValidator[] memory validators)
        private
        pure
    {
        bool mutuallyExclusive = false;
        uint256 totalValidators = validators.length;
        for (uint256 i = 0; i < totalValidators; ) {
            ValidatorType thisType = validators[i].validatorType;
            bytes memory encodedArguments = validators[i].arguments;
            if (thisType == ValidatorType.NFT_PACKED_LIST) {
                (
                    uint64 bytesPerTokenId,
                    address[] memory collections,
                    bytes[] memory tokenIds
                ) = abi.decode(encodedArguments, (uint64, address[], bytes[]));
                if (bytesPerTokenId == 0) {
                    revert ValidatorHelpers.InvalidBytesPerTokenIdError(0);
                }
                if (collections.length != tokenIds.length) {
                    revert ArrayLengthNotMatchedError();
                }
                if (mutuallyExclusive) {
                    revert TokenListAlreadySetError();
                }
                mutuallyExclusive = true;
            } else if (thisType == ValidatorType.NFT_BIT_VECTOR) {
                (address[] memory collections, bytes[] memory tokenIds) = abi
                    .decode(encodedArguments, (address[], bytes[]));
                if (collections.length != tokenIds.length) {
                    revert ArrayLengthNotMatchedError();
                }
                if (mutuallyExclusive) {
                    revert TokenListAlreadySetError();
                }
                mutuallyExclusive = true;
            } else if (thisType == ValidatorType.FULL_COLLECTION) {
                if (mutuallyExclusive) {
                    revert TokenListAlreadySetError();
                }
                mutuallyExclusive = true;
            }
            unchecked {
                ++i;
            }
        }
    }

    function _validateNFTPackedList(
        uint64 bytesPerTokenId,
        address[] memory collections,
        bytes[] memory tokenIdLists,
        address _collateralAddress,
        uint256 _tokenId
    ) private pure {
        bool found = false;
        for (uint256 i = 0; i < collections.length; ) {
            if (collections[i] == _collateralAddress) {
                _tokenId.validateTokenIdPackedList(
                    bytesPerTokenId,
                    tokenIdLists[i]
                );
                found = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
        if (!found) {
            revert TokenIdNotFoundError(_tokenId);
        }
    }

    function _validateNFTBitVector(
        address[] memory collections,
        bytes[] memory tokenIdVectors,
        address _collateralAddress,
        uint256 _tokenId
    ) private pure {
        bool found = false;
        for (uint256 i = 0; i < collections.length; ) {
            if (collections[i] == _collateralAddress) {
                _tokenId.validateNFTBitVector(tokenIdVectors[i]);
                found = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
        if (!found) {
            revert TokenIdNotFoundError(_tokenId);
        }
    }

    function _validateNFTFullCollection(
        address[] memory collections,
        address _collateralAddress,
        uint256 _tokenId
    ) private pure {
        uint256 total = collections.length;
        bool found = false;
        for (uint256 i; i < total; ) {
            if (collections[i] == _collateralAddress) {
                found = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
        if (!found) {
            revert TokenIdNotFoundError(_tokenId);
        }
    }

    function _validateMaxCollectionLTV(
        CollectionMaxLTV[] memory collectionMaxLTVs,
        address _collateralAddress,
        uint256 _tokenId,
        address _token,
        uint88 _amount
    ) private view {
        if (address(_oracle) == address(0)) {
            revert OracleNotSetError();
        }
        IOracle.PriceUpdate memory priceUpdate = _oracle.getPrice(
            _collateralAddress,
            _tokenId,
            _token
        );

        uint88 maxLTV = 0;
        uint256 total = collectionMaxLTVs.length;
        for (uint256 i; i < total; ) {
            CollectionMaxLTV memory thisMaxLTV = collectionMaxLTVs[i];
            if (thisMaxLTV.collection == _collateralAddress) {
                maxLTV = thisMaxLTV.maxLTV;
            }
            unchecked {
                ++i;
            }
        }
        if (maxLTV == 0) {
            revert InvalidLTVError(maxLTV);
        }

        if (
            (priceUpdate.price <= 0) ||
            (_amount >= priceUpdate.price.mulDivDown(maxLTV, 10000))
        ) {
            revert InvalidLTVError(maxLTV);
        }
        if (block.timestamp - priceUpdate.updatedTimestamp >= _delayTolerance) {
            revert StaleOracleError(
                priceUpdate.updatedTimestamp,
                _delayTolerance
            );
        }
    }

    function _addVault(address _vault, bytes calldata _validatorParameters)
        private
    {
        (
            uint64 maxDuration,
            uint16 managerPerformanceFeeBps,
            GenericValidator[] memory validators
        ) = abi.decode(
                _validatorParameters,
                (uint64, uint16, GenericValidator[])
            );
        _baseVaultParameters[_vault] = BaseVaultParameters(
            maxDuration,
            managerPerformanceFeeBps
        );
        _verifyValidators(validators);
        _vaultGenericValidators[_vault] = abi.encode(validators);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "@openzeppelin/utils/structs/EnumerableSet.sol";
import "@solmate/mixins/ERC4626.sol";
import "@solmate/tokens/ERC721.sol";
import "@solmate/utils/FixedPointMathLib.sol";
import "@solmate/utils/ReentrancyGuard.sol";
import "@solmate/utils/SafeTransferLib.sol";
import "../interfaces/loans/ILoan.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IVaultFactory.sol";
import "./VaultLoanValidator.sol";

// TODO: When vault shut down, add redeem for user to get remaining (rounding)

contract Vault is ERC4626, ERC721TokenReceiver, IVault, ReentrancyGuard {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for ERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Parameters {
        uint64 maxDuration;
        address managerFeeRecipient;
        uint16 managerPerformanceFeeBps;
        address controller;
        uint48 redemptionTimeWindow;
        uint48 redemptionFrequency;
        uint256 maxCapacity;
        address[] originalAcceptedLoans;
        ERC20 asset;
        string name;
        string symbol;
    }

    // TODO: Update types
    uint256 public immutable override getStartTime;
    address public override getController;
    address public override getManagerFeeRecipient;
    uint16 public override getManagerPerformanceFeeBps;
    uint256 public override getFeesAccrued;
    uint256 public override getRedemptionFrequency;
    uint256 public override getRedemptionTimeWindowSize;
    uint256 public getMaxCapacity;
    bool public override isClosed;

    EnumerableSet.AddressSet private _acceptedLoans;

    uint256 public totalOutstanding;
    uint256 public totalPendingPool;
    mapping(uint256 => uint256) public pendingClaimPool;

    address private _vaultFactory;

    uint256 private _lastRedemptionPeriod;
    mapping(address => uint256) private _lastLoanIssued;

    uint256 private _totalAssetsPendingWithdrawal;
    mapping(uint256 => uint256) private _totalSharesSnapshot;
    mapping(uint256 => uint256) private _totalSharesPendingWithdrawal;
    mapping(uint256 => mapping(address => uint256))
        private _sharesPendingWithdrawal;

    event ClaimedManagerFees(uint256 _amount);

    event ProcessedRepayment(
        uint256 _loanId,
        uint256 _principal,
        uint256 _received,
        uint256 _protocolFee
    );

    event Claimed(address _user, uint256 _amount);

    event AcceptedLoan(address _loan);

    event RemovedLoan(address _loan);

    error UnauthorizedError(address _authorized);

    error OnlyLoanCallableError();

    error InvalidStateError();

    error OnlyManagerCallableError(address _expected);

    error MaxCapacityExceededError();

    error RemainingSharesError();

    error ZeroAssetsError();

    /// @notice Redemption Frequency must be higher than Max Duration + Liquidation Window
    constructor(Parameters memory parameters)
        ERC4626(parameters.asset, parameters.name, parameters.symbol)
    {
        getStartTime = block.timestamp;
        getManagerFeeRecipient = parameters.managerFeeRecipient;
        getController = parameters.controller;
        getManagerPerformanceFeeBps = parameters.managerPerformanceFeeBps;
        getRedemptionFrequency = parameters.redemptionFrequency;
        getRedemptionTimeWindowSize = parameters.redemptionTimeWindow;
        getMaxCapacity = parameters.maxCapacity;
        uint256 totalAcceptedLoans = parameters.originalAcceptedLoans.length;
        _vaultFactory = msg.sender;
        for (uint256 i = 0; i < totalAcceptedLoans; ) {
            address acceptedLoan = parameters.originalAcceptedLoans[i];
            _acceptedLoans.add(acceptedLoan);
            parameters.asset.safeApprove(acceptedLoan, type(uint256).max);
            unchecked {
                ++i;
            }
        }
    }

    modifier onlyLoanCallable() {
        if (!_acceptedLoans.contains(msg.sender)) {
            revert OnlyLoanCallableError();
        }
        _;
    }

    modifier onlyVaultFactory() {
        if (msg.sender != _vaultFactory) {
            revert UnauthorizedError(_vaultFactory);
        }
        _;
    }

    function addAcceptedLoans(address[] memory _loans)
        external
        onlyVaultFactory
    {
        uint256 total = _loans.length;
        for (uint256 i; i < total; ) {
            address thisLoan = _loans[i];
            if (!_acceptedLoans.contains(thisLoan)) {
                _acceptedLoans.add(thisLoan);
                asset.safeApprove(thisLoan, type(uint256).max);
            }
            unchecked {
                ++i;
            }
        }
    }

    function removeAcceptedLoan(address _loan) external onlyVaultFactory {
        _acceptedLoans.remove(_loan);
        asset.safeApprove(_loan, 0);
    }

    function closeVault(address _closer) external onlyVaultFactory {
        address controller = getController;
        if (_closer != controller) {
            revert UnauthorizedError(controller);
        }
        if (!_updateAndGetRedemptionState()) {
            revert InvalidStateError();
        }

        isClosed = true;
    }

    function withdrawRemainingFundsAndDestroy(address _claimer) external {
        address controller = getController;
        address recipient = getManagerFeeRecipient;
        if (_claimer != controller) {
            revert UnauthorizedError(controller);
        }

        if (totalSupply > 0) {
            revert RemainingSharesError();
        }
        asset.safeTransfer(recipient, totalAssets());
        selfdestruct(payable(recipient));
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override returns (uint256 shares) {
        if (!_updateAndGetRedemptionState()) {
            revert InvalidStateError();
        }
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        _afterWithdrawal(receiver, shares);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override returns (uint256 assets) {
        if (!_updateAndGetRedemptionState()) {
            revert InvalidStateError();
        }
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        if ((assets = previewRedeem(shares)) == 0) {
            revert ZeroAssetsError();
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        _afterWithdrawal(receiver, shares);
    }

    function deposit(uint256 assets, address receiver)
        public
        override
        returns (uint256 shares)
    {
        if (assets + totalAssets() > getMaxCapacity) {
            revert MaxCapacityExceededError();
        }
        if (_updateAndGetRedemptionState()) {
            revert InvalidStateError();
        }
        shares = ERC4626.deposit(assets, receiver);
    }

    function mint(uint256 shares, address receiver)
        public
        override
        returns (uint256 assets)
    {
        if (_updateAndGetRedemptionState()) {
            revert InvalidStateError();
        }
        assets = ERC4626.mint(shares, receiver);
        if (assets + totalAssets() > getMaxCapacity) {
            revert MaxCapacityExceededError();
        }
    }

    function claimManagerFees() external nonReentrant {
        address recipient = getManagerFeeRecipient;
        if (msg.sender != recipient) {
            revert OnlyManagerCallableError(recipient);
        }
        uint256 amount = getFeesAccrued;
        getFeesAccrued = 0;
        asset.safeTransfer(recipient, amount);

        emit ClaimedManagerFees(amount);
    }

    function processRepayment(
        uint256 _loanId,
        uint256 _principal,
        uint256 _received
    ) external onlyLoanCallable {
        _updateAndGetRedemptionState();
        IVaultFactory.ProtocolFeeData memory protocolFeeData = IVaultFactory(
            _vaultFactory
        ).getProtocolFeeData();
        uint256 fee;
        uint256 poolAmount;
        uint256 protocolFee;
        unchecked {
            if (_received > _principal) {
                fee = (_received - _principal).mulDivDown(
                    getManagerPerformanceFeeBps,
                    10000
                );
                if (protocolFeeData.feeBps > 0) {
                    protocolFee = (_received - _principal).mulDivDown(
                        protocolFeeData.feeBps,
                        10000
                    );
                    asset.safeTransfer(
                        protocolFeeData.protocolAddress,
                        protocolFee
                    );
                }
            } else {
                fee = 0;
                protocolFee = 0;
            }
            poolAmount = _received - fee - protocolFee;
        }
        getFeesAccrued += fee;
        if (
            isClosed ||
            (_loanId < _lastLoanIssued[msg.sender] &&
                _totalSharesPendingWithdrawal[_lastRedemptionPeriod] > 0)
        ) {
            uint256 claimedPool = poolAmount.mulDivDown(
                _totalSharesPendingWithdrawal[_lastRedemptionPeriod],
                _totalSharesSnapshot[_lastRedemptionPeriod]
            );
            pendingClaimPool[_lastRedemptionPeriod] += claimedPool;
            totalPendingPool += claimedPool;
        }

        totalOutstanding -= _principal;

        emit ProcessedRepayment(_loanId, _principal, _received, protocolFee);
    }

    function totalAssets() public view override returns (uint256) {
        return
            asset.balanceOf(address(this)) - totalPendingPool - getFeesAccrued;
    }

    function previewDeposit(uint256 assets)
        public
        view
        override
        returns (uint256)
    {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return
            supply == 0
                ? assets
                : assets.mulDivDown(supply, totalAssets() + totalOutstanding);
    }

    function previewMint(uint256 shares)
        public
        view
        override
        returns (uint256)
    {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return
            supply == 0
                ? shares
                : shares.mulDivUp(totalAssets() + totalOutstanding, supply);
    }

    function getClaimable(uint256 _redemptionPeriod, address _userAddress)
        external
        view
        override
        returns (uint256)
    {
        return _getClaimable(_redemptionPeriod, _userAddress);
    }

    function claim(uint256 _redemptionPeriod) external override nonReentrant {
        address user = msg.sender;
        uint256 totalClaimable = _getClaimable(_redemptionPeriod, user);
        _sharesPendingWithdrawal[_redemptionPeriod][user] = 0;
        totalPendingPool -= totalClaimable;
        pendingClaimPool[_redemptionPeriod] -= totalClaimable;
        asset.safeTransfer(user, totalClaimable);

        emit Claimed(user, totalClaimable);
    }

    function claimMultiplePeriods(uint256[] calldata _redemptionPeriods)
        external
        override
        nonReentrant
    {
        address user = msg.sender;
        uint256 periods = _redemptionPeriods.length;
        uint256 totalClaimable = 0;
        for (uint256 i = 0; i < periods; ) {
            uint256 redemptionPeriod = _redemptionPeriods[i];
            totalClaimable += _getClaimable(redemptionPeriod, user);
            _sharesPendingWithdrawal[redemptionPeriod][user] = 0;
            totalPendingPool -= totalClaimable;
            pendingClaimPool[redemptionPeriod] -= totalClaimable;
        }
        asset.safeTransfer(user, totalClaimable);
    }

    function getVaultState() external view returns (IVault.VaultState) {
        if (isClosed) {
            return IVault.VaultState.CLOSED;
        }
        uint256 _startTime = getStartTime;
        uint256 _redemptionFrequency = getRedemptionFrequency;
        uint256 _currentTimestamp = block.timestamp;
        uint256 _startLastRedemptionPeriod = ((_currentTimestamp - _startTime) /
            _redemptionFrequency) *
            _redemptionFrequency +
            _startTime;
        return
            (_currentTimestamp <
                _startLastRedemptionPeriod + getRedemptionTimeWindowSize) &&
                (_startLastRedemptionPeriod != _startTime)
                ? IVault.VaultState.PROCESSING_REDEMPTIONS
                : IVault.VaultState.ACTIVE;
    }

    function getLastRedemptionPeriod() external view returns (uint256) {
        if (isClosed) {
            return _lastRedemptionPeriod;
        }
        uint256 _startTime = getStartTime;
        uint256 _redemptionFrequency = getRedemptionFrequency;
        return
            ((block.timestamp - _startTime) / _redemptionFrequency) *
            _redemptionFrequency +
            _startTime;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata data
    ) external override onlyLoanCallable returns (bytes4) {
        uint88 amount = abi.decode(data, (uint88));
        totalOutstanding += amount;
        return ERC721TokenReceiver.onERC721Received.selector;
    }

    function _getClaimable(uint256 _redemptionPeriod, address _userAddress)
        private
        view
        returns (uint256)
    {
        return
            pendingClaimPool[_redemptionPeriod].mulDivDown(
                _sharesPendingWithdrawal[_redemptionPeriod][_userAddress],
                _totalSharesPendingWithdrawal[_redemptionPeriod]
            );
    }

    function _updateAndGetRedemptionState() private returns (bool) {
        if (isClosed) {
            return true;
        }
        uint256 _startTime = getStartTime;
        uint256 _redemptionFrequency = getRedemptionFrequency;
        uint256 _startLastRedemptionPeriod = ((block.timestamp - _startTime) /
            _redemptionFrequency) *
            _redemptionFrequency +
            _startTime;
        if (_startLastRedemptionPeriod != _lastRedemptionPeriod) {
            _totalSharesSnapshot[_startLastRedemptionPeriod] = totalSupply;
            _lastRedemptionPeriod = _startLastRedemptionPeriod;
            uint256 totalLoans = _acceptedLoans.length();
            for (uint256 i = 0; i < totalLoans; ) {
                address loanAddress = _acceptedLoans.at(i);
                _lastLoanIssued[loanAddress] =
                    ILoan(loanAddress).getTotalLoansIssued() +
                    1;
                unchecked {
                    ++i;
                }
            }
        }
        return
            (block.timestamp <
                _startLastRedemptionPeriod + getRedemptionTimeWindowSize) &&
            _startLastRedemptionPeriod != _startTime;
    }

    function _afterWithdrawal(address _receiver, uint256 _shares) private {
        uint256 totalAssetsSnapshot = totalAssets() +
            pendingClaimPool[_lastRedemptionPeriod];
        uint256 movedToPending = _shares.mulDivDown(
            totalAssetsSnapshot,
            _totalSharesSnapshot[_lastRedemptionPeriod]
        );
        totalPendingPool += movedToPending;
        pendingClaimPool[_lastRedemptionPeriod] += movedToPending;
        _totalSharesPendingWithdrawal[_lastRedemptionPeriod] += _shares;
        _sharesPendingWithdrawal[_lastRedemptionPeriod][_receiver] += _shares;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

/// @title Oracles
/// @author Florida St
/// @notice It retrieves prices for a given NFT in a specific currency.
interface IOracle {
    struct PriceUpdate {
        uint128 price;
        uint128 updatedTimestamp;
    }

    function getPrice(
        address _nftAddress,
        uint256 _tokenId,
        address _asset
    ) external view returns (PriceUpdate memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

/// @title Interface for Loans.
/// @author Florida St
/// @notice Loans define the terms / dynamics and are issued by vaults.
interface ILoan {
    enum LoanStatus {
        NOT_FOUND,
        OUTSTANDING,
        IN_LIQUIDATION
    }

    struct SaleOrder {
        uint256 loanId;
        address asset;
        uint88 amount;
    }

    struct SaleSide {
        address participant;
        uint256 orderId;
    }

    struct FullSaleOrder {
        SaleOrder order;
        SaleSide side;
    }

    /// @notice Created when a loan is issued.
    struct Loan {
        address borrower;
        address nftCollateralAddress;
        uint256 nftCollateralTokenId;
        address principalAddress;
        uint88 principalAmount;
        uint88 totalInterest;
        uint32 startTime;
        uint32 duration;
        uint16 managerPerformanceFeeBps;
    }

    /// @notice Borrowers receive offers that are then validated.
    struct LoanOffer {
        uint256 offerId;
        address vaultAddress;
        address borrower;
        address nftCollateralAddress;
        uint256 nftCollateralTokenId;
        address principalAddress;
        uint88 principalAmount;
        uint88 totalInterest;
        uint32 expirationTime;
        uint32 duration;
        uint16 managerPerformanceFeeBps;
    }

    function getTotalLoansIssued() external view returns (uint256);

    function setBaseURI(string memory _baseURI) external;

    /// @notice Called when the controller for the vault is a smart contract.
    function emitLoanFromContract(LoanOffer memory _loanOffer)
        external
        returns (uint256);

    /// @notice Called when the controller for the vault is an EOA.
    function emitLoanWithSignature(
        LoanOffer memory _loanOffer,
        bytes calldata _lenderOfferSignature
    ) external returns (uint256);

    function executeSale(
        SaleOrder calldata _order,
        SaleSide calldata _buyer,
        SaleSide calldata _seller,
        bytes calldata _buyerSignature,
        bytes calldata _sellerSignature
    ) external;

    /// @notice Called by the borrower when repaying the loan.
    function repayLoan(address _collateralTo, uint256 _loanId) external;

    /// @notice Starts the liquidation process. Can be called by anyone.
    function liquidateLoan(uint256 _loanId) external;

    /// @notice Called by the liquidation contract once a liquidation is done for accounting.
    function loanLiquidated(uint256 _loanId, uint256 _repayment) external;

    /// @notice Cancel offers (they are off chain)
    function cancelOffer(address _vaultAddress, uint256 _offerId) external;

    /// @notice Cancell all offers with offerId < _minOfferId
    function cancelAllOffers(address _vaultAddress, uint256 _minOfferId)
        external;

    /// @notice Cancel one order (off chain as well)
    function cancelOrder(uint256 _orderId) external;

    /// @notice Cancel multiple specific orders
    function cancelOrders(uint256[] calldata _orderIds) external;

    /// @notice Cancell all orders with orderId < _minOrderId
    function cancelAllOrders(uint256 _minOrderId) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "../interfaces/loans/ILoan.sol";

/// @title Vault Loan Validator
/// @author Florida St
/// @notice Validates a given offer complies with a Vault's constraints.
interface IVaultLoanValidator {
    function addVault(address _vault, bytes calldata _validatorParameters)
        external;

    function upgradeVault(
        address _vault,
        address _oldValidator,
        bytes calldata _newParameters
    ) external;

    function getAcceptedLoans() external view returns (address[] memory);

    function isLoanAccepted(address _loanAddress) external view returns (bool);

    function validateOffer(ILoan.LoanOffer calldata _loanOffer) external view;

    function validateSell(
        ILoan.Loan memory _loan,
        ILoan.FullSaleOrder memory _order,
        address _sellerVault
    ) external view;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// TODO: Give credit

library ValidatorHelpers {

    error InvalidBytesPerTokenIdError(uint64 _bytesPerTokenId);

    error TokenIdNotFoundError(uint256 _tokenId);

    error BitVectorLengthExceededError(uint256 _tokenId);

    function validateTokenIdPackedList(
        uint256 _tokenId,
        uint64 _bytesPerTokenId,
        bytes memory _tokenIdList
    ) internal pure {
        if (
            _bytesPerTokenId == 0 || _bytesPerTokenId > 32
        ) {
            revert InvalidBytesPerTokenIdError(_bytesPerTokenId);
        }

        // Masks the lower `bytesPerTokenId` bytes of a word
        // So if `bytesPerTokenId` == 1, then bitmask = 0xff
        //    if `bytesPerTokenId` == 2, then bitmask = 0xffff, etc.
        uint256 bitMask = ~(type(uint256).max << (_bytesPerTokenId << 3));
        assembly {
            // Binary search for given token id

            let left := 1
            // right = number of tokenIds in the list
            let right := div(mload(_tokenIdList), _bytesPerTokenId)

            // while(left < right)
            for {} lt(left, right) {} {
                // mid = (left + right) / 2
                let mid := shr(1, add(left, right))
                // more or less equivalent to:
                // value = list[index]
                let offset := add(_tokenIdList, mul(mid, _bytesPerTokenId))
                let value := and(mload(offset), bitMask)
                // if (value < tokenId) {
                //     left = mid + 1;
                //     continue;
                // }
                if lt(value, _tokenId) {
                    left := add(mid, 1)
                    continue
                }
                // if (value > tokenId) {
                //     right = mid;
                //     continue;
                // }
                if gt(value, _tokenId) {
                    right := mid
                    continue
                }
                // if (value == tokenId) { return; }
                stop()
            }
            // At this point left == right; check if list[left] == tokenId
            let offset := add(_tokenIdList, mul(left, _bytesPerTokenId))
            let value := and(mload(offset), bitMask)
            if eq(value, _tokenId) {
                stop()
            }
        }
        revert TokenIdNotFoundError(_tokenId);
    }

    function validateNFTBitVector(uint256 _tokenId, bytes memory _bitVector)
        internal 
        pure
    {
        // tokenId < propertyData.length * 8
        if (_tokenId >= _bitVector.length << 3) {
            revert BitVectorLengthExceededError(_tokenId);
        }
        // Bit corresponding to tokenId must be set
        if (!(uint8(_bitVector[_tokenId >> 3]) & (0x80 >> (_tokenId & 7)) != 0)) {
           revert TokenIdNotFoundError(_tokenId);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";
import {SafeTransferLib} from "../utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "../utils/FixedPointMathLib.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
abstract contract ERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "./loans/ILoan.sol";

/// @title Vault
/// @author Florida St
/// @notice Each vault is created and managed by an underwriter, takes capital
///         from LPs, and issues loans to borrowers.
interface IVault {
    enum VaultState {
        ACTIVE,
        PROCESSING_REDEMPTIONS,
        CLOSED
    }

    /// @notice Called by the underwriter to shutdown a vault
    function closeVault(address _closer) external;

    /// @notice Whether this vault is still active
    function isClosed() external returns (bool);

    /// @notice Vault's deployment time
    function getStartTime() external returns (uint256);

    /// @notice The vault's underwriter address
    function getManagerFeeRecipient() external returns (address);

    /// @notice Fees accrued by the underwriter (gains * performance fee)
    function getFeesAccrued() external returns (uint256);

    /// @notice Address of the controller (can be a contract or EOA)
    function getController() external returns (address);

    function getManagerPerformanceFeeBps() external returns (uint16);

    /// @notice Size for each redepmtion window
    function getRedemptionTimeWindowSize() external returns (uint256);

    /// @notice Frequency for redemptions
    function getRedemptionFrequency() external returns (uint256);

    /// @notice Add accepted loans when upgrading the validator
    function addAcceptedLoans(address[] memory _loans) external;

    /// @notice Only used for emergency. It shouldn't be necessary to get rid of
    ///         previous loans.
    function removeAcceptedLoan(address _loan) external;

    /// @notice Call when a loan is repaid or liquidated
    function processRepayment(
        uint256 _loanId,
        uint256 _principal,
        uint256 _received
    ) external;

    /// @notice Returns the beginning of the last redemption window
    function getLastRedemptionPeriod() external view returns (uint256);

    /// @notice Returns the vault state
    function getVaultState() external view returns (IVault.VaultState);

    /// @notice Return how much is claimable by an address for a given redemption period
    function getClaimable(uint256 _redemptionPeriod, address _userAddress)
        external
        view
        returns (uint256);

    /// @notice Claim assets for `msg.sender` for a given redemption period
    function claim(uint256 _redemptionPeriod) external;

    /// @notice Claim assets for `msg.sender` for multiple redemption periods
    function claimMultiplePeriods(uint256[] calldata _redemptionPeriods)
        external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "../lib/Vault.sol";

/// @title Vault Factory
/// @author Florida St
/// @notice Deploys and keeps track of existing vaults
interface IVaultFactory {
    struct ProtocolFeeData {
        address protocolAddress;
        uint16 feeBps;
    }

    function vaultExists(address _maybeVault) external returns (bool);

    function deploy(
        Vault.Parameters calldata _vaultParameters,
        bytes calldata _validatorParameters
    ) external returns (address);

    function closeVault(address _vault) external;

    function getVaultLoanValidator() external view returns (address);

    function getProtocolFeeData() external returns (ProtocolFeeData memory);

    function setProtocolFeeData(ProtocolFeeData calldata _data) external;

    function upgradeVaultLoanValidator(
        address _vaultAddress,
        bytes calldata _newParameters
    ) external;

    function getVaultLoanValidator(address _vault)
        external
        view
        returns (address);

    function removeAcceptedLoan(address _vault, address _loan) external;
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