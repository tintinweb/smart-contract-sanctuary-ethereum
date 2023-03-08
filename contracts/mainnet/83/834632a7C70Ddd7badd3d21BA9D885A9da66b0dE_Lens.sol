// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

/// @title Compound Math Library.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @dev Library to perform Compound's multiplication and division in an efficient way.
library CompoundMath {
    /// CONSTANTS ///

    uint256 internal constant MAX_UINT256 = 2**256 - 1;
    uint256 public constant SCALE = 1e36;
    uint256 public constant WAD = 1e18;

    /// INTERNAL ///

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Revert if x * y > type(uint256).max
            // <=> y > 0 and x > type(uint256).max / y
            if mul(y, gt(x, div(MAX_UINT256, y))) {
                revert(0, 0)
            }

            z := div(mul(x, y), WAD)
        }
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Revert if x * SCALE > type(uint256).max or y == 0
            // <=> x > type(uint256).max / SCALE or y == 0
            if iszero(mul(y, iszero(gt(x, div(MAX_UINT256, SCALE))))) {
                revert(0, 0)
            }

            z := div(div(mul(SCALE, x), y), WAD)
        }
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    /// @dev Returns max(x - y, 0).
    function zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := mul(gt(x, y), sub(x, y))
        }
    }

    /// @dev Returns x / y rounded up (x / y + boolAsInt(x % y > 0)).
    function divUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Revert if y = 0
            if iszero(y) {
                revert(0, 0)
            }

            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

/// @title PercentageMath.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Optimized version of Aave V3 math library PercentageMath to conduct percentage manipulations: https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/libraries/math/PercentageMath.sol
library PercentageMath {
    ///	CONSTANTS ///

    uint256 internal constant PERCENTAGE_FACTOR = 1e4; // 100.00%
    uint256 internal constant HALF_PERCENTAGE_FACTOR = 0.5e4; // 50.00%
    uint256 internal constant MAX_UINT256 = 2**256 - 1;
    uint256 internal constant MAX_UINT256_MINUS_HALF_PERCENTAGE = 2**256 - 1 - 0.5e4;

    /// INTERNAL ///

    /// @notice Executes a percentage addition (x * (1 + p)), rounded up.
    /// @param x The value to which to add the percentage.
    /// @param percentage The percentage of the value to add.
    /// @return y The result of the addition.
    function percentAdd(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
        // Must revert if
        // PERCENTAGE_FACTOR + percentage > type(uint256).max
        //     or x * (PERCENTAGE_FACTOR + percentage) + HALF_PERCENTAGE_FACTOR > type(uint256).max
        // <=> percentage > type(uint256).max - PERCENTAGE_FACTOR
        //     or x > (type(uint256).max - HALF_PERCENTAGE_FACTOR) / (PERCENTAGE_FACTOR + percentage)
        // Note: PERCENTAGE_FACTOR + percentage >= PERCENTAGE_FACTOR > 0
        assembly {
            y := add(PERCENTAGE_FACTOR, percentage) // Temporary assignment to save gas.

            if or(
                gt(percentage, sub(MAX_UINT256, PERCENTAGE_FACTOR)),
                gt(x, div(MAX_UINT256_MINUS_HALF_PERCENTAGE, y))
            ) {
                revert(0, 0)
            }

            y := div(add(mul(x, y), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
        }
    }

    /// @notice Executes a percentage subtraction (x * (1 - p)), rounded up.
    /// @param x The value to which to subtract the percentage.
    /// @param percentage The percentage of the value to subtract.
    /// @return y The result of the subtraction.
    function percentSub(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
        // Must revert if
        // percentage > PERCENTAGE_FACTOR
        //     or x * (PERCENTAGE_FACTOR - percentage) + HALF_PERCENTAGE_FACTOR > type(uint256).max
        // <=> percentage > PERCENTAGE_FACTOR
        //     or ((PERCENTAGE_FACTOR - percentage) > 0 and x > (type(uint256).max - HALF_PERCENTAGE_FACTOR) / (PERCENTAGE_FACTOR - percentage))
        assembly {
            y := sub(PERCENTAGE_FACTOR, percentage) // Temporary assignment to save gas.

            if or(gt(percentage, PERCENTAGE_FACTOR), mul(y, gt(x, div(MAX_UINT256_MINUS_HALF_PERCENTAGE, y)))) {
                revert(0, 0)
            }

            y := div(add(mul(x, y), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
        }
    }

    /// @notice Executes a percentage multiplication (x * p), rounded up.
    /// @param x The value to multiply by the percentage.
    /// @param percentage The percentage of the value to multiply.
    /// @return y The result of the multiplication.
    function percentMul(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
        // Must revert if
        // x * percentage + HALF_PERCENTAGE_FACTOR > type(uint256).max
        // <=> percentage > 0 and x > (type(uint256).max - HALF_PERCENTAGE_FACTOR) / percentage
        assembly {
            if mul(percentage, gt(x, div(MAX_UINT256_MINUS_HALF_PERCENTAGE, percentage))) {
                revert(0, 0)
            }

            y := div(add(mul(x, percentage), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
        }
    }

    /// @notice Executes a percentage division (x / p), rounded up.
    /// @param x The value to divide by the percentage.
    /// @param percentage The percentage of the value to divide.
    /// @return y The result of the division.
    function percentDiv(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
        // Must revert if
        // percentage == 0
        //     or x * PERCENTAGE_FACTOR + percentage / 2 > type(uint256).max
        // <=> percentage == 0
        //     or x > (type(uint256).max - percentage / 2) / PERCENTAGE_FACTOR
        assembly {
            y := div(percentage, 2) // Temporary assignment to save gas.

            if iszero(mul(percentage, iszero(gt(x, div(sub(MAX_UINT256, y), PERCENTAGE_FACTOR))))) {
                revert(0, 0)
            }

            y := div(add(mul(PERCENTAGE_FACTOR, x), y), percentage)
        }
    }

    /// @notice Executes a weighted average (x * (1 - p) + y * p), rounded up.
    /// @param x The first value, with a weight of 1 - percentage.
    /// @param y The second value, with a weight of percentage.
    /// @param percentage The weight of y, and complement of the weight of x.
    /// @return z The result of the weighted average.
    function weightedAvg(
        uint256 x,
        uint256 y,
        uint256 percentage
    ) internal pure returns (uint256 z) {
        // Must revert if
        //     percentage > PERCENTAGE_FACTOR
        // or if
        //     y * percentage + HALF_PERCENTAGE_FACTOR > type(uint256).max
        //     <=> percentage > 0 and y > (type(uint256).max - HALF_PERCENTAGE_FACTOR) / percentage
        // or if
        //     x * (PERCENTAGE_FACTOR - percentage) + y * percentage + HALF_PERCENTAGE_FACTOR > type(uint256).max
        //     <=> (PERCENTAGE_FACTOR - percentage) > 0 and x > (type(uint256).max - HALF_PERCENTAGE_FACTOR - y * percentage) / (PERCENTAGE_FACTOR - percentage)
        assembly {
            z := sub(PERCENTAGE_FACTOR, percentage) // Temporary assignment to save gas.
            if or(
                gt(percentage, PERCENTAGE_FACTOR),
                or(
                    mul(percentage, gt(y, div(MAX_UINT256_MINUS_HALF_PERCENTAGE, percentage))),
                    mul(z, gt(x, div(sub(MAX_UINT256_MINUS_HALF_PERCENTAGE, mul(y, percentage)), z)))
                )
            ) {
                revert(0, 0)
            }
            z := div(add(add(mul(x, z), mul(y, percentage)), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.0;

interface IInterestRatesManager {
    function updateP2PIndexes(address _marketAddress) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.0;

import "./IInterestRatesManager.sol";
import "./IPositionsManager.sol";
import "./IRewardsManager.sol";

import "../libraries/Types.sol";

// prettier-ignore
interface IMorpho {

    /// STORAGE ///

    function CTOKEN_DECIMALS() external view returns (uint8);
    function MAX_BASIS_POINTS() external view returns (uint16);
    function WAD() external view returns (uint256);
    function isClaimRewardsPaused() external view returns (bool);
    function defaultMaxGasForMatching() external view returns (Types.MaxGasForMatching memory);
    function maxSortedUsers() external view returns (uint256);
    function dustThreshold() external view returns (uint256);
    function supplyBalanceInOf(address, address) external view returns (Types.SupplyBalance memory);
    function borrowBalanceInOf(address, address) external view returns (Types.BorrowBalance memory);
    function enteredMarkets(address, uint256) external view returns (address);
    function deltas(address) external view returns (Types.Delta memory);
    function marketParameters(address) external view returns (Types.MarketParameters memory);
    function marketPauseStatus(address) external view returns (Types.MarketPauseStatus memory);
    function p2pDisabled(address) external view returns (bool);
    function p2pSupplyIndex(address) external view returns (uint256);
    function p2pBorrowIndex(address) external view returns (uint256);
    function lastPoolIndexes(address) external view returns (Types.LastPoolIndexes memory);
    function marketStatus(address) external view returns (Types.MarketStatus memory);
    function comptroller() external view returns (IComptroller);
    function interestRatesManager() external view returns (IInterestRatesManager);
    function rewardsManager() external view returns (IRewardsManager);
    function positionsManager() external view returns (IPositionsManager);
    function incentivesVault() external view returns (address);
    function treasuryVault() external view returns (address);
    function cEth() external view returns (address);
    function wEth() external view returns (address);

    /// GETTERS ///

    function getEnteredMarkets(address _user) external view returns (address[] memory);
    function getAllMarkets() external view returns (address[] memory);
    function getHead(address _poolToken, Types.PositionType _positionType) external view returns (address head);
    function getNext(address _poolToken, Types.PositionType _positionType, address _user) external view returns (address next);

    /// GOVERNANCE ///

    function setMaxSortedUsers(uint256 _newMaxSortedUsers) external;
    function setDefaultMaxGasForMatching(Types.MaxGasForMatching memory _maxGasForMatching) external;
    function setRewardsManager(address _rewardsManagerAddress) external;
    function setPositionsManager(IPositionsManager _positionsManager) external;
    function setInterestRatesManager(IInterestRatesManager _interestRatesManager) external;
    function setTreasuryVault(address _treasuryVault) external;
    function setDustThreshold(uint256 _dustThreshold) external;
    function setIsP2PDisabled(address _poolToken, bool _isP2PDisabled) external;
    function setReserveFactor(address _poolToken, uint256 _newReserveFactor) external;
    function setP2PIndexCursor(address _poolToken, uint16 _p2pIndexCursor) external;
    function setIsPausedForAllMarkets(bool _isPaused) external;
    function setIsClaimRewardsPaused(bool _isPaused) external;
    function setIsSupplyPaused(address _poolToken, bool _isPaused) external;
    function setIsBorrowPaused(address _poolToken, bool _isPaused) external;
    function setIsWithdrawPaused(address _poolToken, bool _isPaused) external;
    function setIsRepayPaused(address _poolToken, bool _isPaused) external;
    function setIsLiquidateCollateralPaused(address _poolToken, bool _isPaused) external;
    function setIsLiquidateBorrowPaused(address _poolToken, bool _isPaused) external;
    function claimToTreasury(address[] calldata _poolTokens, uint256[] calldata _amounts) external;
    function createMarket(address _poolToken, Types.MarketParameters calldata _params) external;

    /// USERS ///

    function supply(address _poolToken, uint256 _amount) external;
    function supply(address _poolToken, address _onBehalf, uint256 _amount) external;
    function supply(address _poolToken, address _onBehalf, uint256 _amount, uint256 _maxGasForMatching) external;
    function borrow(address _poolToken, uint256 _amount) external;
    function borrow(address _poolToken, uint256 _amount, uint256 _maxGasForMatching) external;
    function withdraw(address _poolToken, uint256 _amount) external;
    function withdraw(address _poolToken, uint256 _amount, address _receiver) external;
    function repay(address _poolToken, uint256 _amount) external;
    function repay(address _poolToken, address _onBehalf, uint256 _amount) external;
    function liquidate(address _poolTokenBorrowed, address _poolTokenCollateral, address _borrower, uint256 _amount) external;
    function claimRewards(address[] calldata _cTokenAddresses, bool _tradeForMorphoToken) external returns (uint256 claimedAmount);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.0;

interface IPositionsManager {
    function supplyLogic(
        address _poolToken,
        address _supplier,
        address _onBehalf,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) external;

    function borrowLogic(
        address _poolToken,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) external;

    function withdrawLogic(
        address _poolToken,
        uint256 _amount,
        address _supplier,
        address _receiver,
        uint256 _maxGasForMatching
    ) external;

    function repayLogic(
        address _poolToken,
        address _repayer,
        address _onBehalf,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) external;

    function liquidateLogic(
        address _poolTokenBorrowed,
        address _poolTokenCollateral,
        address _borrower,
        uint256 _amount
    ) external;

    function increaseP2PDeltasLogic(address _poolToken, uint256 _amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.0;

import "./compound/ICompound.sol";

interface IRewardsManager {
    function initialize(address _morpho) external;

    function claimRewards(address[] calldata, address) external returns (uint256);

    function userUnclaimedCompRewards(address) external view returns (uint256);

    function compSupplierIndex(address, address) external view returns (uint256);

    function compBorrowerIndex(address, address) external view returns (uint256);

    function getLocalCompSupplyState(address _cTokenAddress)
        external
        view
        returns (IComptroller.CompMarketState memory);

    function getLocalCompBorrowState(address _cTokenAddress)
        external
        view
        returns (IComptroller.CompMarketState memory);

    function accrueUserSupplyUnclaimedRewards(
        address,
        address,
        uint256
    ) external;

    function accrueUserBorrowUnclaimedRewards(
        address,
        address,
        uint256
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.0;

interface ICEth {
    function accrueInterest() external returns (uint256);

    function borrowRate() external returns (uint256);

    function borrowIndex() external returns (uint256);

    function borrowBalanceStored(address) external returns (uint256);

    function mint() external payable;

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transfer(address dst, uint256 amount) external returns (bool);

    function balanceOf(address) external returns (uint256);

    function balanceOfUnderlying(address account) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function repayBorrow() external payable;

    function borrowBalanceCurrent(address) external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);
}

interface IComptroller {
    struct CompMarketState {
        /// @notice The market's last updated compBorrowIndex or compSupplyIndex
        uint224 index;
        /// @notice The block number the index was last updated at
        uint32 block;
    }

    function liquidationIncentiveMantissa() external view returns (uint256);

    function closeFactorMantissa() external view returns (uint256);

    function admin() external view returns (address);

    function allMarkets(uint256) external view returns (ICToken);

    function oracle() external view returns (address);

    function borrowCaps(address) external view returns (uint256);

    function markets(address)
        external
        view
        returns (
            bool isListed,
            uint256 collateralFactorMantissa,
            bool isComped
        );

    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);

    function mintAllowed(
        address cToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintVerify(
        address cToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external;

    function redeemAllowed(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address cToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function borrowAllowed(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    function borrowVerify(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferAllowed(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferVerify(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getHypotheticalAccountLiquidity(
        address,
        address,
        uint256,
        uint256
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function checkMembership(address, address) external view returns (bool);

    function mintGuardianPaused(address) external view returns (bool);

    function borrowGuardianPaused(address) external view returns (bool);

    function seizeGuardianPaused() external view returns (bool);

    function claimComp(address holder) external;

    function claimComp(address holder, address[] memory cTokens) external;

    function compSpeeds(address) external view returns (uint256);

    function compSupplySpeeds(address) external view returns (uint256);

    function compBorrowSpeeds(address) external view returns (uint256);

    function compSupplyState(address) external view returns (CompMarketState memory);

    function compBorrowState(address) external view returns (CompMarketState memory);

    function getCompAddress() external view returns (address);

    function _setPriceOracle(address newOracle) external returns (uint256);

    function _setMintPaused(ICToken cToken, bool state) external returns (bool);

    function _setBorrowPaused(ICToken cToken, bool state) external returns (bool);

    function _setCollateralFactor(ICToken cToken, uint256 newCollateralFactorMantissa)
        external
        returns (uint256);

    function _setCompSpeeds(
        ICToken[] memory cTokens,
        uint256[] memory supplySpeeds,
        uint256[] memory borrowSpeeds
    ) external;
}

interface IInterestRateModel {
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);

    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);
}

interface ICToken {
    function isCToken() external returns (bool);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function borrowRate() external returns (uint256);

    function borrowIndex() external view returns (uint256);

    function borrow(uint256) external returns (uint256);

    function repayBorrow(uint256) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral
    ) external returns (uint256);

    function underlying() external view returns (address);

    function mint(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function accrueInterest() external returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function accrualBlockNumber() external view returns (uint256);

    function totalReserves() external view returns (uint256);

    function interestRateModel() external view returns (IInterestRateModel);

    function reserveFactorMantissa() external view returns (uint256);

    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint256);

    function _acceptAdmin() external returns (uint256);

    function _setComptroller(IComptroller newComptroller) external returns (uint256);

    function _setReserveFactor(uint256 newReserveFactorMantissa) external returns (uint256);

    function _reduceReserves(uint256 reduceAmount) external returns (uint256);

    function _setInterestRateModel(IInterestRateModel newInterestRateModel)
        external
        returns (uint256);
}

interface ICEther is ICToken {
    function mint() external payable;

    function repayBorrow() external payable;
}

interface ICompoundOracle {
    function getUnderlyingPrice(address) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "../libraries/InterestRatesModel.sol";

import "./LensStorage.sol";

/// @title IndexesLens.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Intermediary layer exposing endpoints to query live data related to the Morpho Protocol market indexes & rates.
abstract contract IndexesLens is LensStorage {
    using CompoundMath for uint256;

    /// EXTERNAL ///

    /// @notice Returns the updated peer-to-peer supply index.
    /// @param _poolToken The address of the market.
    /// @return p2pSupplyIndex The virtually updated peer-to-peer supply index.
    function getCurrentP2PSupplyIndex(address _poolToken)
        external
        view
        returns (uint256 p2pSupplyIndex)
    {
        (, Types.Indexes memory indexes) = _getIndexes(_poolToken, true);

        p2pSupplyIndex = indexes.p2pSupplyIndex;
    }

    /// @notice Returns the updated peer-to-peer borrow index.
    /// @param _poolToken The address of the market.
    /// @return p2pBorrowIndex The virtually updated peer-to-peer borrow index.
    function getCurrentP2PBorrowIndex(address _poolToken)
        external
        view
        returns (uint256 p2pBorrowIndex)
    {
        (, Types.Indexes memory indexes) = _getIndexes(_poolToken, true);

        p2pBorrowIndex = indexes.p2pBorrowIndex;
    }

    /// @notice Returns the most up-to-date or virtually updated peer-to-peer and pool indexes.
    /// @dev If not virtually updated, the indexes returned are those used by Morpho for non-updated markets during the liquidity check.
    /// @param _poolToken The address of the market.
    /// @param _updated Whether to compute virtually updated pool and peer-to-peer indexes.
    /// @return indexes The given market's virtually updated indexes.
    function getIndexes(address _poolToken, bool _updated)
        external
        view
        returns (Types.Indexes memory indexes)
    {
        (, indexes) = _getIndexes(_poolToken, _updated);
    }

    /// @notice Returns the virtually updated pool indexes of a given market.
    /// @dev Mimicks `CToken.accrueInterest`'s calculations, without writing to the storage.
    /// @param _poolToken The address of the market.
    /// @return poolSupplyIndex The supply index.
    /// @return poolBorrowIndex The borrow index.
    function getCurrentPoolIndexes(address _poolToken)
        external
        view
        returns (uint256 poolSupplyIndex, uint256 poolBorrowIndex)
    {
        (poolSupplyIndex, poolBorrowIndex, ) = _accruePoolInterests(ICToken(_poolToken));
    }

    /// INTERNAL ///

    struct PoolInterestsVars {
        uint256 cash;
        uint256 totalBorrows;
        uint256 totalReserves;
        uint256 reserveFactorMantissa;
    }

    /// @notice Returns the most up-to-date or virtually updated peer-to-peer and pool indexes.
    /// @dev If not virtually updated, the indexes returned are those used by Morpho for non-updated markets during the liquidity check.
    /// @param _poolToken The address of the market.
    /// @param _updated Whether to compute virtually updated pool and peer-to-peer indexes.
    /// @return delta The given market's deltas.
    /// @return indexes The given market's updated indexes.
    function _getIndexes(address _poolToken, bool _updated)
        internal
        view
        returns (Types.Delta memory delta, Types.Indexes memory indexes)
    {
        delta = morpho.deltas(_poolToken);
        Types.LastPoolIndexes memory lastPoolIndexes = morpho.lastPoolIndexes(_poolToken);

        if (!_updated) {
            indexes.poolSupplyIndex = ICToken(_poolToken).exchangeRateStored();
            indexes.poolBorrowIndex = ICToken(_poolToken).borrowIndex();
        } else {
            (indexes.poolSupplyIndex, indexes.poolBorrowIndex, ) = _accruePoolInterests(
                ICToken(_poolToken)
            );
        }

        (indexes.p2pSupplyIndex, indexes.p2pBorrowIndex, ) = _computeP2PIndexes(
            _poolToken,
            _updated,
            indexes.poolSupplyIndex,
            indexes.poolBorrowIndex,
            delta,
            lastPoolIndexes
        );
    }

    /// @notice Returns the virtually updated pool indexes of a given market.
    /// @dev Mimicks `CToken.accrueInterest`'s calculations, without writing to the storage.
    /// @param _poolToken The address of the market.
    /// @return poolSupplyIndex The supply index.
    /// @return poolBorrowIndex The borrow index.
    function _accruePoolInterests(ICToken _poolToken)
        internal
        view
        returns (
            uint256 poolSupplyIndex,
            uint256 poolBorrowIndex,
            PoolInterestsVars memory vars
        )
    {
        poolBorrowIndex = _poolToken.borrowIndex();
        vars.cash = _poolToken.getCash();
        vars.totalBorrows = _poolToken.totalBorrows();
        vars.totalReserves = _poolToken.totalReserves();
        vars.reserveFactorMantissa = _poolToken.reserveFactorMantissa();

        uint256 accrualBlockNumberPrior = _poolToken.accrualBlockNumber();
        if (block.number == accrualBlockNumberPrior) {
            poolSupplyIndex = _poolToken.exchangeRateStored();

            return (poolSupplyIndex, poolBorrowIndex, vars);
        }

        uint256 borrowRateMantissa = _poolToken.borrowRatePerBlock();
        require(borrowRateMantissa <= 0.0005e16, "borrow rate is absurdly high");

        uint256 simpleInterestFactor = borrowRateMantissa *
            (block.number - accrualBlockNumberPrior);
        uint256 interestAccumulated = simpleInterestFactor.mul(vars.totalBorrows);

        vars.totalBorrows += interestAccumulated;
        vars.totalReserves += vars.reserveFactorMantissa.mul(interestAccumulated);

        poolSupplyIndex = (vars.cash + vars.totalBorrows - vars.totalReserves).div(
            _poolToken.totalSupply()
        );
        poolBorrowIndex += simpleInterestFactor.mul(poolBorrowIndex);
    }

    /// @notice Returns the most up-to-date or virtually updated peer-to-peer  indexes.
    /// @dev If not virtually updated, the indexes returned are those used by Morpho for non-updated markets during the liquidity check.
    /// @param _poolToken The address of the market.
    /// @param _updated Whether to compute virtually updated peer-to-peer indexes.
    /// @param _poolSupplyIndex The underlying pool supply index.
    /// @param _poolBorrowIndex The underlying pool borrow index.
    /// @param _delta The given market's deltas.
    /// @param _lastPoolIndexes The last pool indexes stored on Morpho.
    /// @return _p2pSupplyIndex The given market's peer-to-peer supply index.
    /// @return _p2pBorrowIndex The given market's peer-to-peer borrow index.
    function _computeP2PIndexes(
        address _poolToken,
        bool _updated,
        uint256 _poolSupplyIndex,
        uint256 _poolBorrowIndex,
        Types.Delta memory _delta,
        Types.LastPoolIndexes memory _lastPoolIndexes
    )
        internal
        view
        returns (
            uint256 _p2pSupplyIndex,
            uint256 _p2pBorrowIndex,
            Types.MarketParameters memory marketParameters
        )
    {
        marketParameters = morpho.marketParameters(_poolToken);

        if (!_updated || block.number == _lastPoolIndexes.lastUpdateBlockNumber) {
            return (
                morpho.p2pSupplyIndex(_poolToken),
                morpho.p2pBorrowIndex(_poolToken),
                marketParameters
            );
        }

        InterestRatesModel.GrowthFactors memory growthFactors = InterestRatesModel
        .computeGrowthFactors(
            _poolSupplyIndex,
            _poolBorrowIndex,
            _lastPoolIndexes,
            marketParameters.p2pIndexCursor,
            marketParameters.reserveFactor
        );

        _p2pSupplyIndex = InterestRatesModel.computeP2PIndex(
            InterestRatesModel.P2PIndexComputeParams({
                poolGrowthFactor: growthFactors.poolSupplyGrowthFactor,
                p2pGrowthFactor: growthFactors.p2pSupplyGrowthFactor,
                lastPoolIndex: _lastPoolIndexes.lastSupplyPoolIndex,
                lastP2PIndex: morpho.p2pSupplyIndex(_poolToken),
                p2pDelta: _delta.p2pSupplyDelta,
                p2pAmount: _delta.p2pSupplyAmount
            })
        );
        _p2pBorrowIndex = InterestRatesModel.computeP2PIndex(
            InterestRatesModel.P2PIndexComputeParams({
                poolGrowthFactor: growthFactors.poolBorrowGrowthFactor,
                p2pGrowthFactor: growthFactors.p2pBorrowGrowthFactor,
                lastPoolIndex: _lastPoolIndexes.lastBorrowPoolIndex,
                lastP2PIndex: morpho.p2pBorrowIndex(_poolToken),
                p2pDelta: _delta.p2pBorrowDelta,
                p2pAmount: _delta.p2pBorrowAmount
            })
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "./RewardsLens.sol";

/// @title Lens.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice This contract exposes an API to query on-chain data related to the Morpho Protocol, its markets and its users.
contract Lens is RewardsLens {
    using CompoundMath for uint256;

    /// CONSTRUCTOR ///

    /// @notice Constructs the contract.
    /// @param _lensExtension The address of the Lens extension.
    constructor(address _lensExtension) LensStorage(_lensExtension) {}

    /// EXTERNAL ///

    /// @notice Computes and returns the total distribution of supply through Morpho, using virtually updated indexes.
    /// @return p2pSupplyAmount The total supplied amount matched peer-to-peer, subtracting the supply delta (in USD, 18 decimals).
    /// @return poolSupplyAmount The total supplied amount on the underlying pool, adding the supply delta (in USD, 18 decimals).
    /// @return totalSupplyAmount The total amount supplied through Morpho (in USD, 18 decimals).
    function getTotalSupply()
        external
        view
        returns (
            uint256 p2pSupplyAmount,
            uint256 poolSupplyAmount,
            uint256 totalSupplyAmount
        )
    {
        address[] memory markets = morpho.getAllMarkets();
        ICompoundOracle oracle = ICompoundOracle(comptroller.oracle());

        uint256 nbMarkets = markets.length;
        for (uint256 i; i < nbMarkets; ) {
            address _poolToken = markets[i];

            (uint256 marketP2PSupplyAmount, uint256 marketPoolSupplyAmount) = getTotalMarketSupply(
                _poolToken
            );

            uint256 underlyingPrice = oracle.getUnderlyingPrice(_poolToken);
            if (underlyingPrice == 0) revert CompoundOracleFailed();

            p2pSupplyAmount += marketP2PSupplyAmount.mul(underlyingPrice);
            poolSupplyAmount += marketPoolSupplyAmount.mul(underlyingPrice);

            unchecked {
                ++i;
            }
        }

        totalSupplyAmount = p2pSupplyAmount + poolSupplyAmount;
    }

    /// @notice Computes and returns the total distribution of borrows through Morpho, using virtually updated indexes.
    /// @return p2pBorrowAmount The total borrowed amount matched peer-to-peer, subtracting the borrow delta (in USD, 18 decimals).
    /// @return poolBorrowAmount The total borrowed amount on the underlying pool, adding the borrow delta (in USD, 18 decimals).
    /// @return totalBorrowAmount The total amount borrowed through Morpho (in USD, 18 decimals).
    function getTotalBorrow()
        external
        view
        returns (
            uint256 p2pBorrowAmount,
            uint256 poolBorrowAmount,
            uint256 totalBorrowAmount
        )
    {
        address[] memory markets = morpho.getAllMarkets();
        ICompoundOracle oracle = ICompoundOracle(comptroller.oracle());

        uint256 nbMarkets = markets.length;
        for (uint256 i; i < nbMarkets; ) {
            address _poolToken = markets[i];

            (uint256 marketP2PBorrowAmount, uint256 marketPoolBorrowAmount) = getTotalMarketBorrow(
                _poolToken
            );

            uint256 underlyingPrice = oracle.getUnderlyingPrice(_poolToken);
            if (underlyingPrice == 0) revert CompoundOracleFailed();

            p2pBorrowAmount += marketP2PBorrowAmount.mul(underlyingPrice);
            poolBorrowAmount += marketPoolBorrowAmount.mul(underlyingPrice);

            unchecked {
                ++i;
            }
        }

        totalBorrowAmount = p2pBorrowAmount + poolBorrowAmount;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "../interfaces/compound/ICompound.sol";
import "./interfaces/ILensExtension.sol";
import "../interfaces/IMorpho.sol";
import "./interfaces/ILens.sol";

import "@morpho-dao/morpho-utils/math/CompoundMath.sol";
import "../libraries/InterestRatesModel.sol";
import "@morpho-dao/morpho-utils/math/Math.sol";
import "@morpho-dao/morpho-utils/math/PercentageMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";

/// @title LensStorage.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Base layer to the Morpho Protocol Lens, managing the upgradeable storage layout.
abstract contract LensStorage is ILens, Initializable {
    /// CONSTANTS ///

    uint256 public constant MAX_BASIS_POINTS = 100_00; // 100% (in basis points).
    uint256 public constant WAD = 1e18;

    /// IMMUTABLES ///

    IMorpho public immutable morpho;
    IComptroller public immutable comptroller;
    IRewardsManager public immutable rewardsManager;
    ILensExtension internal immutable lensExtension;

    /// STORAGE ///

    address private deprecatedMorpho;
    address private deprecatedComptroller;
    address private deprecatedRewardsManager;

    /// CONSTRUCTOR ///

    /// @notice Constructs the contract.
    /// @param _lensExtension The address of the Lens extension.
    constructor(address _lensExtension) {
        lensExtension = ILensExtension(_lensExtension);
        morpho = IMorpho(lensExtension.morpho());
        comptroller = IComptroller(morpho.comptroller());
        rewardsManager = IRewardsManager(morpho.rewardsManager());
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "./RatesLens.sol";

/// @title MarketsLens.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Intermediary layer exposing endpoints to query live data related to the Morpho Protocol markets.
abstract contract MarketsLens is RatesLens {
    using CompoundMath for uint256;

    /// EXTERNAL ///

    /// @notice Checks if a market is created.
    /// @param _poolToken The address of the market to check.
    /// @return true if the market is created and not paused, otherwise false.
    function isMarketCreated(address _poolToken) external view returns (bool) {
        return morpho.marketStatus(_poolToken).isCreated;
    }

    /// @dev Deprecated.
    function isMarketCreatedAndNotPaused(address) external pure returns (bool) {
        return false;
    }

    /// @dev Deprecated.
    function isMarketCreatedAndNotPausedNorPartiallyPaused(address) external pure returns (bool) {
        return false;
    }

    /// @notice Returns all created markets.
    /// @return marketsCreated The list of market addresses.
    function getAllMarkets() external view returns (address[] memory marketsCreated) {
        return morpho.getAllMarkets();
    }

    /// @notice For a given market, returns the average supply/borrow rates and amounts of underlying asset supplied and borrowed through Morpho, on the underlying pool and matched peer-to-peer.
    /// @dev The returned values are not updated.
    /// @param _poolToken The address of the market of which to get main data.
    /// @return avgSupplyRatePerBlock The average supply rate experienced on the given market.
    /// @return avgBorrowRatePerBlock The average borrow rate experienced on the given market.
    /// @return p2pSupplyAmount The total supplied amount matched peer-to-peer, subtracting the supply delta (in underlying).
    /// @return p2pBorrowAmount The total borrowed amount matched peer-to-peer, subtracting the borrow delta (in underlying).
    /// @return poolSupplyAmount The total supplied amount on the underlying pool, adding the supply delta (in underlying).
    /// @return poolBorrowAmount The total borrowed amount on the underlying pool, adding the borrow delta (in underlying).
    function getMainMarketData(address _poolToken)
        external
        view
        returns (
            uint256 avgSupplyRatePerBlock,
            uint256 avgBorrowRatePerBlock,
            uint256 p2pSupplyAmount,
            uint256 p2pBorrowAmount,
            uint256 poolSupplyAmount,
            uint256 poolBorrowAmount
        )
    {
        (avgSupplyRatePerBlock, p2pSupplyAmount, poolSupplyAmount) = getAverageSupplyRatePerBlock(
            _poolToken
        );
        (avgBorrowRatePerBlock, p2pBorrowAmount, poolBorrowAmount) = getAverageBorrowRatePerBlock(
            _poolToken
        );
    }

    /// @notice Returns non-updated indexes, the block at which they were last updated and the total deltas of a given market.
    /// @param _poolToken The address of the market of which to get advanced data.
    /// @return indexes The given market's virtually updated indexes.
    /// @return lastUpdateBlockNumber The block number at which pool indexes were last updated.
    /// @return p2pSupplyDelta The total supply delta (in underlying).
    /// @return p2pBorrowDelta The total borrow delta (in underlying).
    function getAdvancedMarketData(address _poolToken)
        external
        view
        returns (
            Types.Indexes memory indexes,
            uint32 lastUpdateBlockNumber,
            uint256 p2pSupplyDelta,
            uint256 p2pBorrowDelta
        )
    {
        Types.Delta memory delta;
        (delta, indexes) = _getIndexes(_poolToken, false);

        p2pSupplyDelta = delta.p2pSupplyDelta.mul(indexes.poolSupplyIndex);
        p2pBorrowDelta = delta.p2pBorrowDelta.mul(indexes.poolBorrowIndex);

        lastUpdateBlockNumber = morpho.lastPoolIndexes(_poolToken).lastUpdateBlockNumber;
    }

    /// @notice Returns the given market's configuration.
    /// @return underlying The underlying token address.
    /// @return isCreated Whether the market is created or not.
    /// @return p2pDisabled Whether the peer-to-peer market is enabled or not.
    /// @return isPaused Deprecated.
    /// @return isPartiallyPaused Deprecated.
    /// @return reserveFactor The reserve factor applied to this market.
    /// @return p2pIndexCursor The p2p index cursor applied to this market.
    /// @return collateralFactor The pool collateral factor also used by Morpho.
    function getMarketConfiguration(address _poolToken)
        external
        view
        returns (
            address underlying,
            bool isCreated,
            bool p2pDisabled,
            bool isPaused,
            bool isPartiallyPaused,
            uint16 reserveFactor,
            uint16 p2pIndexCursor,
            uint256 collateralFactor
        )
    {
        underlying = _poolToken == morpho.cEth() ? morpho.wEth() : ICToken(_poolToken).underlying();

        isCreated = morpho.marketStatus(_poolToken).isCreated;
        p2pDisabled = morpho.p2pDisabled(_poolToken);
        isPaused = false;
        isPartiallyPaused = false;

        Types.MarketParameters memory marketParams = morpho.marketParameters(_poolToken);
        reserveFactor = marketParams.reserveFactor;
        p2pIndexCursor = marketParams.p2pIndexCursor;

        (, collateralFactor, ) = comptroller.markets(_poolToken);
    }

    /// @notice Returns the given market's pause statuses.
    /// @param _poolToken The address of the market of which to get pause statuses.
    /// @return The market status struct.
    function getMarketPauseStatus(address _poolToken)
        external
        view
        returns (Types.MarketPauseStatus memory)
    {
        return morpho.marketPauseStatus(_poolToken);
    }

    /// PUBLIC ///

    /// @notice Computes and returns the total distribution of supply for a given market, using virtually updated indexes.
    /// @param _poolToken The address of the market to check.
    /// @return p2pSupplyAmount The total supplied amount matched peer-to-peer, subtracting the supply delta (in underlying).
    /// @return poolSupplyAmount The total supplied amount on the underlying pool, adding the supply delta (in underlying).
    function getTotalMarketSupply(address _poolToken)
        public
        view
        returns (uint256 p2pSupplyAmount, uint256 poolSupplyAmount)
    {
        (Types.Delta memory delta, Types.Indexes memory indexes) = _getIndexes(_poolToken, true);

        (p2pSupplyAmount, poolSupplyAmount) = _getMarketSupply(
            _poolToken,
            indexes.p2pSupplyIndex,
            indexes.poolSupplyIndex,
            delta
        );
    }

    /// @notice Computes and returns the total distribution of borrows for a given market, using virtually updated indexes.
    /// @param _poolToken The address of the market to check.
    /// @return p2pBorrowAmount The total borrowed amount matched peer-to-peer, subtracting the borrow delta (in underlying).
    /// @return poolBorrowAmount The total borrowed amount on the underlying pool, adding the borrow delta (in underlying).
    function getTotalMarketBorrow(address _poolToken)
        public
        view
        returns (uint256 p2pBorrowAmount, uint256 poolBorrowAmount)
    {
        (Types.Delta memory delta, Types.Indexes memory indexes) = _getIndexes(_poolToken, true);

        (p2pBorrowAmount, poolBorrowAmount) = _getMarketBorrow(
            _poolToken,
            indexes.p2pBorrowIndex,
            indexes.poolBorrowIndex,
            delta
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "./UsersLens.sol";

/// @title RatesLens.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Intermediary layer exposing endpoints to query live data related to the Morpho Protocol users and their positions.
abstract contract RatesLens is UsersLens {
    using CompoundMath for uint256;
    using Math for uint256;

    /// ERRORS ///

    error BorrowRateFailed();

    /// EXTERNAL ///

    /// @notice Returns the supply rate per block experienced on a market after having supplied the given amount on behalf of the given user.
    /// @dev Note: the returned supply rate is a low estimate: when supplying through Morpho-Compound,
    /// a supplier could be matched more than once instantly or later and thus benefit from a higher supply rate.
    /// @param _poolToken The address of the market.
    /// @param _user The address of the user on behalf of whom to supply.
    /// @param _amount The amount to supply.
    /// @return nextSupplyRatePerBlock An approximation of the next supply rate per block experienced after having supplied (in wad).
    /// @return balanceOnPool The total balance supplied on pool after having supplied (in underlying).
    /// @return balanceInP2P The total balance matched peer-to-peer after having supplied (in underlying).
    /// @return totalBalance The total balance supplied through Morpho (in underlying).
    function getNextUserSupplyRatePerBlock(
        address _poolToken,
        address _user,
        uint256 _amount
    )
        external
        view
        returns (
            uint256 nextSupplyRatePerBlock,
            uint256 balanceOnPool,
            uint256 balanceInP2P,
            uint256 totalBalance
        )
    {
        (Types.Delta memory delta, Types.Indexes memory indexes) = _getIndexes(_poolToken, true);

        Types.SupplyBalance memory supplyBalance = morpho.supplyBalanceInOf(_poolToken, _user);

        uint256 repaidToPool;
        if (!morpho.p2pDisabled(_poolToken)) {
            if (delta.p2pBorrowDelta > 0) {
                uint256 matchedDelta = Math.min(
                    delta.p2pBorrowDelta.mul(indexes.poolBorrowIndex),
                    _amount
                );

                supplyBalance.inP2P += matchedDelta.div(indexes.p2pSupplyIndex);
                repaidToPool += matchedDelta;
                _amount -= matchedDelta;
            }

            if (_amount > 0) {
                address firstPoolBorrower = morpho.getHead(
                    _poolToken,
                    Types.PositionType.BORROWERS_ON_POOL
                );
                uint256 firstPoolBorrowerBalance = morpho
                .borrowBalanceInOf(_poolToken, firstPoolBorrower)
                .onPool;

                uint256 matchedP2P = Math.min(
                    firstPoolBorrowerBalance.mul(indexes.poolBorrowIndex),
                    _amount
                );

                supplyBalance.inP2P += matchedP2P.div(indexes.p2pSupplyIndex);
                repaidToPool += matchedP2P;
                _amount -= matchedP2P;
            }
        }

        if (_amount > 0) supplyBalance.onPool += _amount.div(indexes.poolSupplyIndex);

        balanceOnPool = supplyBalance.onPool.mul(indexes.poolSupplyIndex);
        balanceInP2P = supplyBalance.inP2P.mul(indexes.p2pSupplyIndex);

        (nextSupplyRatePerBlock, totalBalance) = _getUserSupplyRatePerBlock(
            _poolToken,
            balanceInP2P,
            balanceOnPool,
            _amount,
            repaidToPool
        );
    }

    /// @notice Returns the borrow rate per block experienced on a market after having supplied the given amount on behalf of the given user.
    /// @dev Note: the returned borrow rate is a high estimate: when borrowing through Morpho-Compound,
    /// a borrower could be matched more than once instantly or later and thus benefit from a lower borrow rate.
    /// @param _poolToken The address of the market.
    /// @param _user The address of the user on behalf of whom to borrow.
    /// @param _amount The amount to borrow.
    /// @return nextBorrowRatePerBlock An approximation of the next borrow rate per block experienced after having supplied (in wad).
    /// @return balanceOnPool The total balance supplied on pool after having supplied (in underlying).
    /// @return balanceInP2P The total balance matched peer-to-peer after having supplied (in underlying).
    /// @return totalBalance The total balance supplied through Morpho (in underlying).
    function getNextUserBorrowRatePerBlock(
        address _poolToken,
        address _user,
        uint256 _amount
    )
        external
        view
        returns (
            uint256 nextBorrowRatePerBlock,
            uint256 balanceOnPool,
            uint256 balanceInP2P,
            uint256 totalBalance
        )
    {
        (Types.Delta memory delta, Types.Indexes memory indexes) = _getIndexes(_poolToken, true);

        Types.BorrowBalance memory borrowBalance = morpho.borrowBalanceInOf(_poolToken, _user);

        uint256 withdrawnFromPool;
        if (!morpho.p2pDisabled(_poolToken)) {
            if (delta.p2pSupplyDelta > 0) {
                uint256 matchedDelta = Math.min(
                    delta.p2pSupplyDelta.mul(indexes.poolSupplyIndex),
                    _amount
                );

                borrowBalance.inP2P += matchedDelta.div(indexes.p2pBorrowIndex);
                withdrawnFromPool += matchedDelta;
                _amount -= matchedDelta;
            }

            if (_amount > 0) {
                address firstPoolSupplier = morpho.getHead(
                    _poolToken,
                    Types.PositionType.SUPPLIERS_ON_POOL
                );
                uint256 firstPoolSupplierBalance = morpho
                .supplyBalanceInOf(_poolToken, firstPoolSupplier)
                .onPool;

                uint256 matchedP2P = Math.min(
                    firstPoolSupplierBalance.mul(indexes.poolSupplyIndex),
                    _amount
                );

                borrowBalance.inP2P += matchedP2P.div(indexes.p2pBorrowIndex);
                withdrawnFromPool += matchedP2P;
                _amount -= matchedP2P;
            }
        }

        if (_amount > 0) borrowBalance.onPool += _amount.div(indexes.poolBorrowIndex);

        balanceOnPool = borrowBalance.onPool.mul(indexes.poolBorrowIndex);
        balanceInP2P = borrowBalance.inP2P.mul(indexes.p2pBorrowIndex);

        (nextBorrowRatePerBlock, totalBalance) = _getUserBorrowRatePerBlock(
            _poolToken,
            balanceInP2P,
            balanceOnPool,
            _amount,
            withdrawnFromPool
        );
    }

    /// @notice Returns the supply rate per block a given user is currently experiencing on a given market.
    /// @param _poolToken The address of the market.
    /// @param _user The user to compute the supply rate per block for.
    /// @return supplyRatePerBlock The supply rate per block the user is currently experiencing (in wad).
    function getCurrentUserSupplyRatePerBlock(address _poolToken, address _user)
        external
        view
        returns (uint256 supplyRatePerBlock)
    {
        (uint256 balanceOnPool, uint256 balanceInP2P, ) = getCurrentSupplyBalanceInOf(
            _poolToken,
            _user
        );

        (supplyRatePerBlock, ) = _getUserSupplyRatePerBlock(
            _poolToken,
            balanceInP2P,
            balanceOnPool,
            0,
            0
        );
    }

    /// @notice Returns the borrow rate per block a given user is currently experiencing on a given market.
    /// @param _poolToken The address of the market.
    /// @param _user The user to compute the borrow rate per block for.
    /// @return borrowRatePerBlock The borrow rate per block the user is currently experiencing (in wad).
    function getCurrentUserBorrowRatePerBlock(address _poolToken, address _user)
        external
        view
        returns (uint256 borrowRatePerBlock)
    {
        (uint256 balanceOnPool, uint256 balanceInP2P, ) = getCurrentBorrowBalanceInOf(
            _poolToken,
            _user
        );

        (borrowRatePerBlock, ) = _getUserBorrowRatePerBlock(
            _poolToken,
            balanceInP2P,
            balanceOnPool,
            0,
            0
        );
    }

    /// PUBLIC ///

    /// @notice Computes and returns the current supply rate per block experienced on average on a given market.
    /// @param _poolToken The market address.
    /// @return avgSupplyRatePerBlock The market's average supply rate per block (in wad).
    /// @return p2pSupplyAmount The total supplied amount matched peer-to-peer, subtracting the supply delta (in underlying).
    /// @return poolSupplyAmount The total supplied amount on the underlying pool, adding the supply delta (in underlying).
    function getAverageSupplyRatePerBlock(address _poolToken)
        public
        view
        returns (
            uint256 avgSupplyRatePerBlock,
            uint256 p2pSupplyAmount,
            uint256 poolSupplyAmount
        )
    {
        ICToken cToken = ICToken(_poolToken);

        uint256 poolSupplyRate = cToken.supplyRatePerBlock();
        uint256 poolBorrowRate = cToken.borrowRatePerBlock();

        (Types.Delta memory delta, Types.Indexes memory indexes) = _getIndexes(_poolToken, true);

        Types.MarketParameters memory marketParams = morpho.marketParameters(_poolToken);
        // Do not take delta into account as it's already taken into account in p2pSupplyAmount & poolSupplyAmount
        uint256 p2pSupplyRate = InterestRatesModel.computeP2PSupplyRatePerBlock(
            InterestRatesModel.P2PRateComputeParams({
                p2pRate: PercentageMath.weightedAvg(
                    poolSupplyRate,
                    poolBorrowRate,
                    marketParams.p2pIndexCursor
                ),
                poolRate: poolSupplyRate,
                poolIndex: indexes.poolSupplyIndex,
                p2pIndex: indexes.p2pSupplyIndex,
                p2pDelta: 0,
                p2pAmount: 0,
                reserveFactor: marketParams.reserveFactor
            })
        );

        (p2pSupplyAmount, poolSupplyAmount) = _getMarketSupply(
            _poolToken,
            indexes.p2pSupplyIndex,
            indexes.poolSupplyIndex,
            delta
        );

        (avgSupplyRatePerBlock, ) = _getWeightedRate(
            p2pSupplyRate,
            poolSupplyRate,
            p2pSupplyAmount,
            poolSupplyAmount
        );
    }

    /// @notice Computes and returns the current average borrow rate per block experienced on a given market.
    /// @param _poolToken The market address.
    /// @return avgBorrowRatePerBlock The market's average borrow rate per block (in wad).
    /// @return p2pBorrowAmount The total borrowed amount matched peer-to-peer, subtracting the borrow delta (in underlying).
    /// @return poolBorrowAmount The total borrowed amount on the underlying pool, adding the borrow delta (in underlying).
    function getAverageBorrowRatePerBlock(address _poolToken)
        public
        view
        returns (
            uint256 avgBorrowRatePerBlock,
            uint256 p2pBorrowAmount,
            uint256 poolBorrowAmount
        )
    {
        ICToken cToken = ICToken(_poolToken);

        uint256 poolSupplyRate = cToken.supplyRatePerBlock();
        uint256 poolBorrowRate = cToken.borrowRatePerBlock();

        (Types.Delta memory delta, Types.Indexes memory indexes) = _getIndexes(_poolToken, true);

        Types.MarketParameters memory marketParams = morpho.marketParameters(_poolToken);
        // Do not take delta into account as it's already taken into account in p2pBorrowAmount & poolBorrowAmount
        uint256 p2pBorrowRate = InterestRatesModel.computeP2PBorrowRatePerBlock(
            InterestRatesModel.P2PRateComputeParams({
                p2pRate: PercentageMath.weightedAvg(
                    poolSupplyRate,
                    poolBorrowRate,
                    marketParams.p2pIndexCursor
                ),
                poolRate: poolBorrowRate,
                poolIndex: indexes.poolBorrowIndex,
                p2pIndex: indexes.p2pBorrowIndex,
                p2pDelta: 0,
                p2pAmount: 0,
                reserveFactor: marketParams.reserveFactor
            })
        );

        (p2pBorrowAmount, poolBorrowAmount) = _getMarketBorrow(
            _poolToken,
            indexes.p2pBorrowIndex,
            indexes.poolBorrowIndex,
            delta
        );

        (avgBorrowRatePerBlock, ) = _getWeightedRate(
            p2pBorrowRate,
            poolBorrowRate,
            p2pBorrowAmount,
            poolBorrowAmount
        );
    }

    /// @notice Computes and returns peer-to-peer and pool rates for a specific market.
    /// @dev Note: prefer using getAverageSupplyRatePerBlock & getAverageBorrowRatePerBlock to get the actual experienced supply/borrow rate.
    /// @param _poolToken The market address.
    /// @return p2pSupplyRate The market's peer-to-peer supply rate per block (in wad).
    /// @return p2pBorrowRate The market's peer-to-peer borrow rate per block (in wad).
    /// @return poolSupplyRate The market's pool supply rate per block (in wad).
    /// @return poolBorrowRate The market's pool borrow rate per block (in wad).
    function getRatesPerBlock(address _poolToken)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return _getRatesPerBlock(_poolToken, 0, 0, 0, 0);
    }

    /// INTERNAL ///

    struct PoolRatesVars {
        Types.Delta delta;
        Types.LastPoolIndexes lastPoolIndexes;
        Types.Indexes indexes;
        Types.MarketParameters params;
    }

    /// @dev Computes and returns peer-to-peer and pool rates for a specific market.
    /// @param _poolToken The market address.
    /// @param _suppliedOnPool The amount hypothetically supplied to the underlying's pool (in underlying).
    /// @param _borrowedFromPool The amount hypothetically borrowed from the underlying's pool (in underlying).
    /// @param _repaidOnPool The amount hypothetically repaid to the underlying's pool (in underlying).
    /// @param _withdrawnFromPool The amount hypothetically withdrawn from the underlying's pool (in underlying).
    /// @return p2pSupplyRate The market's peer-to-peer supply rate per block (in wad).
    /// @return p2pBorrowRate The market's peer-to-peer borrow rate per block (in wad).
    /// @return poolSupplyRate The market's pool supply rate per block (in wad).
    /// @return poolBorrowRate The market's pool borrow rate per block (in wad).
    function _getRatesPerBlock(
        address _poolToken,
        uint256 _suppliedOnPool,
        uint256 _borrowedFromPool,
        uint256 _repaidOnPool,
        uint256 _withdrawnFromPool
    )
        internal
        view
        returns (
            uint256 p2pSupplyRate,
            uint256 p2pBorrowRate,
            uint256 poolSupplyRate,
            uint256 poolBorrowRate
        )
    {
        PoolRatesVars memory ratesVars;

        ratesVars.delta = morpho.deltas(_poolToken);
        ratesVars.lastPoolIndexes = morpho.lastPoolIndexes(_poolToken);

        bool updated = _suppliedOnPool > 0 ||
            _borrowedFromPool > 0 ||
            _repaidOnPool > 0 ||
            _withdrawnFromPool > 0;
        if (updated) {
            PoolInterestsVars memory interestsVars;
            (
                ratesVars.indexes.poolSupplyIndex,
                ratesVars.indexes.poolBorrowIndex,
                interestsVars
            ) = _accruePoolInterests(ICToken(_poolToken));

            interestsVars.cash =
                interestsVars.cash +
                _suppliedOnPool +
                _repaidOnPool -
                _borrowedFromPool -
                _withdrawnFromPool;
            interestsVars.totalBorrows =
                interestsVars.totalBorrows +
                _borrowedFromPool -
                _repaidOnPool;

            IInterestRateModel interestRateModel = ICToken(_poolToken).interestRateModel();

            poolSupplyRate = IInterestRateModel(interestRateModel).getSupplyRate(
                interestsVars.cash,
                interestsVars.totalBorrows,
                interestsVars.totalReserves,
                interestsVars.reserveFactorMantissa
            );

            (bool success, bytes memory result) = address(interestRateModel).staticcall(
                abi.encodeWithSelector(
                    IInterestRateModel.getBorrowRate.selector,
                    interestsVars.cash,
                    interestsVars.totalBorrows,
                    interestsVars.totalReserves
                )
            );
            if (!success) revert BorrowRateFailed();

            if (result.length > 32) (, poolBorrowRate) = abi.decode(result, (uint256, uint256));
            else poolBorrowRate = abi.decode(result, (uint256));
        } else {
            ratesVars.indexes.poolSupplyIndex = ICToken(_poolToken).exchangeRateStored();
            ratesVars.indexes.poolBorrowIndex = ICToken(_poolToken).borrowIndex();

            poolSupplyRate = ICToken(_poolToken).supplyRatePerBlock();
            poolBorrowRate = ICToken(_poolToken).borrowRatePerBlock();
        }

        (
            ratesVars.indexes.p2pSupplyIndex,
            ratesVars.indexes.p2pBorrowIndex,
            ratesVars.params
        ) = _computeP2PIndexes(
            _poolToken,
            updated,
            ratesVars.indexes.poolSupplyIndex,
            ratesVars.indexes.poolBorrowIndex,
            ratesVars.delta,
            ratesVars.lastPoolIndexes
        );

        uint256 p2pRate = PercentageMath.weightedAvg(
            poolSupplyRate,
            poolBorrowRate,
            ratesVars.params.p2pIndexCursor
        );

        p2pSupplyRate = InterestRatesModel.computeP2PSupplyRatePerBlock(
            InterestRatesModel.P2PRateComputeParams({
                p2pRate: p2pRate,
                poolRate: poolSupplyRate,
                poolIndex: ratesVars.indexes.poolSupplyIndex,
                p2pIndex: ratesVars.indexes.p2pSupplyIndex,
                p2pDelta: ratesVars.delta.p2pSupplyDelta,
                p2pAmount: ratesVars.delta.p2pSupplyAmount,
                reserveFactor: ratesVars.params.reserveFactor
            })
        );

        p2pBorrowRate = InterestRatesModel.computeP2PBorrowRatePerBlock(
            InterestRatesModel.P2PRateComputeParams({
                p2pRate: p2pRate,
                poolRate: poolBorrowRate,
                poolIndex: ratesVars.indexes.poolBorrowIndex,
                p2pIndex: ratesVars.indexes.p2pBorrowIndex,
                p2pDelta: ratesVars.delta.p2pBorrowDelta,
                p2pAmount: ratesVars.delta.p2pBorrowAmount,
                reserveFactor: ratesVars.params.reserveFactor
            })
        );
    }

    /// @dev Computes and returns the total distribution of supply for a given market, using virtually updated indexes.
    /// @param _poolToken The address of the market to check.
    /// @param _p2pSupplyIndex The given market's peer-to-peer supply index.
    /// @param _poolSupplyIndex The given market's pool supply index.
    /// @param _delta The given market's deltas.
    /// @return p2pSupplyAmount The total supplied amount matched peer-to-peer, subtracting the supply delta (in underlying).
    /// @return poolSupplyAmount The total supplied amount on the underlying pool, adding the supply delta (in underlying).
    function _getMarketSupply(
        address _poolToken,
        uint256 _p2pSupplyIndex,
        uint256 _poolSupplyIndex,
        Types.Delta memory _delta
    ) internal view returns (uint256 p2pSupplyAmount, uint256 poolSupplyAmount) {
        p2pSupplyAmount = _delta.p2pSupplyAmount.mul(_p2pSupplyIndex).zeroFloorSub(
            _delta.p2pSupplyDelta.mul(_poolSupplyIndex)
        );
        poolSupplyAmount = ICToken(_poolToken).balanceOf(address(morpho)).mul(_poolSupplyIndex);
    }

    /// @dev Computes and returns the total distribution of borrows for a given market, using virtually updated indexes.
    /// @param _poolToken The address of the market to check.
    /// @param _p2pBorrowIndex The given market's peer-to-peer borrow index.
    /// @param _poolBorrowIndex The given market's borrow index.
    /// @param _delta The given market's deltas.
    /// @return p2pBorrowAmount The total borrowed amount matched peer-to-peer, subtracting the borrow delta (in underlying).
    /// @return poolBorrowAmount The total borrowed amount on the underlying pool, adding the borrow delta (in underlying).
    function _getMarketBorrow(
        address _poolToken,
        uint256 _p2pBorrowIndex,
        uint256 _poolBorrowIndex,
        Types.Delta memory _delta
    ) internal view returns (uint256 p2pBorrowAmount, uint256 poolBorrowAmount) {
        p2pBorrowAmount = _delta.p2pBorrowAmount.mul(_p2pBorrowIndex).zeroFloorSub(
            _delta.p2pBorrowDelta.mul(_poolBorrowIndex)
        );
        poolBorrowAmount = ICToken(_poolToken)
        .borrowBalanceStored(address(morpho))
        .div(ICToken(_poolToken).borrowIndex())
        .mul(_poolBorrowIndex);
    }

    /// @dev Returns the supply rate per block experienced on a market based on a given position distribution.
    ///      The calculation takes into account the change in pool rates implied by an hypothetical supply and/or repay.
    /// @param _poolToken The address of the market.
    /// @param _balanceOnPool The amount of balance supplied on pool (in a unit common to `_balanceInP2P`).
    /// @param _balanceInP2P The amount of balance matched peer-to-peer (in a unit common to `_balanceOnPool`).
    /// @param _suppliedOnPool The amount hypothetically supplied on pool (in underlying).
    /// @param _repaidToPool The amount hypothetically repaid to the pool (in underlying).
    /// @return The supply rate per block experienced by the given position (in wad).
    /// @return The sum of peer-to-peer & pool balances.
    function _getUserSupplyRatePerBlock(
        address _poolToken,
        uint256 _balanceInP2P,
        uint256 _balanceOnPool,
        uint256 _suppliedOnPool,
        uint256 _repaidToPool
    ) internal view returns (uint256, uint256) {
        (uint256 p2pSupplyRate, , uint256 poolSupplyRate, ) = _getRatesPerBlock(
            _poolToken,
            _suppliedOnPool,
            0,
            0,
            _repaidToPool
        );

        return _getWeightedRate(p2pSupplyRate, poolSupplyRate, _balanceInP2P, _balanceOnPool);
    }

    /// @dev Returns the borrow rate per block experienced on a market based on a given position distribution.
    ///      The calculation takes into account the change in pool rates implied by an hypothetical borrow and/or withdraw.
    /// @param _poolToken The address of the market.
    /// @param _balanceOnPool The amount of balance supplied on pool (in a unit common to `_balanceInP2P`).
    /// @param _balanceInP2P The amount of balance matched peer-to-peer (in a unit common to `_balanceOnPool`).
    /// @param _borrowedFromPool The amount hypothetically borrowed from the pool (in underlying).
    /// @param _withdrawnFromPool The amount hypothetically withdrawn from the pool (in underlying).
    /// @return The borrow rate per block experienced by the given position (in wad).
    /// @return The sum of peer-to-peer & pool balances.
    function _getUserBorrowRatePerBlock(
        address _poolToken,
        uint256 _balanceInP2P,
        uint256 _balanceOnPool,
        uint256 _borrowedFromPool,
        uint256 _withdrawnFromPool
    ) internal view returns (uint256, uint256) {
        (, uint256 p2pBorrowRate, , uint256 poolBorrowRate) = _getRatesPerBlock(
            _poolToken,
            0,
            _borrowedFromPool,
            _withdrawnFromPool,
            0
        );

        return _getWeightedRate(p2pBorrowRate, poolBorrowRate, _balanceInP2P, _balanceOnPool);
    }

    /// @dev Returns the rate experienced based on a given pool & peer-to-peer distribution.
    /// @param _p2pRate The peer-to-peer rate (in a unit common to `_poolRate` & `weightedRate`).
    /// @param _poolRate The pool rate (in a unit common to `_p2pRate` & `weightedRate`).
    /// @param _balanceInP2P The amount of balance matched peer-to-peer (in a unit common to `_balanceOnPool`).
    /// @param _balanceOnPool The amount of balance supplied on pool (in a unit common to `_balanceInP2P`).
    /// @return weightedRate The rate experienced by the given distribution (in a unit common to `_p2pRate` & `_poolRate`).
    /// @return totalBalance The sum of peer-to-peer & pool balances.
    function _getWeightedRate(
        uint256 _p2pRate,
        uint256 _poolRate,
        uint256 _balanceInP2P,
        uint256 _balanceOnPool
    ) internal pure returns (uint256 weightedRate, uint256 totalBalance) {
        totalBalance = _balanceInP2P + _balanceOnPool;
        if (totalBalance == 0) return (weightedRate, totalBalance);

        if (_balanceInP2P > 0) weightedRate += _p2pRate.mul(_balanceInP2P.div(totalBalance));
        if (_balanceOnPool > 0) weightedRate += _poolRate.mul(_balanceOnPool.div(totalBalance));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "./MarketsLens.sol";

/// @title RewardsLens.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Intermediary layer serving as proxy to lighten the bytecode weight of the Lens.
abstract contract RewardsLens is MarketsLens {
    /// EXTERNAL ///

    /// @notice Returns the unclaimed COMP rewards for the given cToken addresses.
    /// @param _poolTokens The cToken addresses for which to compute the rewards.
    /// @param _user The address of the user.
    function getUserUnclaimedRewards(address[] calldata _poolTokens, address _user)
        external
        view
        returns (uint256)
    {
        return lensExtension.getUserUnclaimedRewards(_poolTokens, _user);
    }

    /// @notice Returns the accrued COMP rewards of a user since the last update.
    /// @param _supplier The address of the supplier.
    /// @param _poolToken The cToken address.
    /// @param _balance The user balance of tokens in the distribution.
    /// @return The accrued COMP rewards.
    function getAccruedSupplierComp(
        address _supplier,
        address _poolToken,
        uint256 _balance
    ) external view returns (uint256) {
        return lensExtension.getAccruedSupplierComp(_supplier, _poolToken, _balance);
    }

    /// @notice Returns the accrued COMP rewards of a user since the last update.
    /// @param _supplier The address of the supplier.
    /// @param _poolToken The cToken address.
    /// @return The accrued COMP rewards.
    function getAccruedSupplierComp(address _supplier, address _poolToken)
        external
        view
        returns (uint256)
    {
        return lensExtension.getAccruedSupplierComp(_supplier, _poolToken);
    }

    /// @notice Returns the accrued COMP rewards of a user since the last update.
    /// @param _borrower The address of the borrower.
    /// @param _poolToken The cToken address.
    /// @param _balance The user balance of tokens in the distribution.
    /// @return The accrued COMP rewards.
    function getAccruedBorrowerComp(
        address _borrower,
        address _poolToken,
        uint256 _balance
    ) external view returns (uint256) {
        return lensExtension.getAccruedBorrowerComp(_borrower, _poolToken, _balance);
    }

    /// @notice Returns the accrued COMP rewards of a user since the last update.
    /// @param _borrower The address of the borrower.
    /// @param _poolToken The cToken address.
    /// @return The accrued COMP rewards.
    function getAccruedBorrowerComp(address _borrower, address _poolToken)
        external
        view
        returns (uint256)
    {
        return lensExtension.getAccruedBorrowerComp(_borrower, _poolToken);
    }

    /// @notice Returns the updated COMP supply index.
    /// @param _poolToken The cToken address.
    /// @return The updated COMP supply index.
    function getCurrentCompSupplyIndex(address _poolToken) external view returns (uint256) {
        return lensExtension.getCurrentCompSupplyIndex(_poolToken);
    }

    /// @notice Returns the updated COMP borrow index.
    /// @param _poolToken The cToken address.
    /// @return The updated COMP borrow index.
    function getCurrentCompBorrowIndex(address _poolToken) external view returns (uint256) {
        return lensExtension.getCurrentCompBorrowIndex(_poolToken);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "./IndexesLens.sol";

/// @title UsersLens.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Intermediary layer exposing endpoints to query live data related to the Morpho Protocol users and their positions.
abstract contract UsersLens is IndexesLens {
    using CompoundMath for uint256;
    using Math for uint256;

    /// ERRORS ///

    /// @notice Thrown when the Compound's oracle failed.
    error CompoundOracleFailed();

    /// EXTERNAL ///

    /// @notice Returns all markets entered by a given user.
    /// @param _user The address of the user.
    /// @return enteredMarkets The list of markets entered by this user.
    function getEnteredMarkets(address _user)
        external
        view
        returns (address[] memory enteredMarkets)
    {
        return morpho.getEnteredMarkets(_user);
    }

    /// @notice Returns the maximum amount available to withdraw & borrow for a given user, on a given market.
    /// @param _user The user to determine the capacities for.
    /// @param _poolToken The address of the market.
    /// @return withdrawable The maximum withdrawable amount of underlying token allowed (in underlying).
    /// @return borrowable The maximum borrowable amount of underlying token allowed (in underlying).
    function getUserMaxCapacitiesForAsset(address _user, address _poolToken)
        external
        view
        returns (uint256 withdrawable, uint256 borrowable)
    {
        Types.LiquidityData memory data;
        Types.AssetLiquidityData memory assetData;
        ICompoundOracle oracle = ICompoundOracle(comptroller.oracle());
        address[] memory enteredMarkets = morpho.getEnteredMarkets(_user);

        for (uint256 i; i < enteredMarkets.length; ) {
            address poolTokenEntered = enteredMarkets[i];

            if (_poolToken != poolTokenEntered) {
                assetData = getUserLiquidityDataForAsset(_user, poolTokenEntered, false, oracle);

                data.maxDebtUsd += assetData.maxDebtUsd;
                data.debtUsd += assetData.debtUsd;
            }

            unchecked {
                ++i;
            }
        }

        assetData = getUserLiquidityDataForAsset(_user, _poolToken, true, oracle);

        data.maxDebtUsd += assetData.maxDebtUsd;
        data.debtUsd += assetData.debtUsd;

        // Not possible to withdraw nor borrow.
        if (data.maxDebtUsd < data.debtUsd) return (0, 0);

        uint256 poolTokenBalance = _poolToken == morpho.cEth()
            ? _poolToken.balance
            : ERC20(ICToken(_poolToken).underlying()).balanceOf(_poolToken);

        borrowable = Math.min(
            poolTokenBalance,
            (data.maxDebtUsd - data.debtUsd).div(assetData.underlyingPrice)
        );
        withdrawable = Math.min(
            poolTokenBalance,
            assetData.collateralUsd.div(assetData.underlyingPrice)
        );

        if (assetData.collateralFactor != 0) {
            withdrawable = Math.min(withdrawable, borrowable.div(assetData.collateralFactor));
        }
    }

    /// @dev Computes the maximum repayable amount for a potential liquidation.
    /// @param _user The potential liquidatee.
    /// @param _poolTokenBorrowed The address of the market to repay.
    /// @param _poolTokenCollateral The address of the market to seize.
    /// @param _updatedMarkets The list of markets of which to compute virtually updated pool and peer-to-peer indexes.
    function computeLiquidationRepayAmount(
        address _user,
        address _poolTokenBorrowed,
        address _poolTokenCollateral,
        address[] calldata _updatedMarkets
    ) external view returns (uint256 toRepay) {
        address[] memory updatedMarkets = new address[](_updatedMarkets.length + 2);

        for (uint256 i; i < _updatedMarkets.length; ) {
            updatedMarkets[i] = _updatedMarkets[i];

            unchecked {
                ++i;
            }
        }

        updatedMarkets[updatedMarkets.length - 2] = _poolTokenBorrowed;
        updatedMarkets[updatedMarkets.length - 1] = _poolTokenCollateral;
        if (!isLiquidatable(_user, _poolTokenBorrowed, updatedMarkets)) return 0;

        ICompoundOracle compoundOracle = ICompoundOracle(comptroller.oracle());

        (, , uint256 totalCollateralBalance) = getCurrentSupplyBalanceInOf(
            _poolTokenCollateral,
            _user
        );
        (, , uint256 totalBorrowBalance) = getCurrentBorrowBalanceInOf(_poolTokenBorrowed, _user);

        uint256 borrowedPrice = compoundOracle.getUnderlyingPrice(_poolTokenBorrowed);
        uint256 collateralPrice = compoundOracle.getUnderlyingPrice(_poolTokenCollateral);
        if (borrowedPrice == 0 || collateralPrice == 0) revert CompoundOracleFailed();

        uint256 maxROIRepay = totalCollateralBalance.mul(collateralPrice).div(borrowedPrice).div(
            comptroller.liquidationIncentiveMantissa()
        );

        uint256 maxRepayable = totalBorrowBalance.mul(comptroller.closeFactorMantissa());

        toRepay = maxROIRepay > maxRepayable ? maxRepayable : maxROIRepay;
    }

    /// @dev Computes the health factor of a given user, given a list of markets of which to compute virtually updated pool & peer-to-peer indexes.
    /// @param _user The user of whom to get the health factor.
    /// @param _updatedMarkets The list of markets of which to compute virtually updated pool and peer-to-peer indexes.
    /// @return The health factor of the given user (in wad).
    function getUserHealthFactor(address _user, address[] calldata _updatedMarkets)
        external
        view
        returns (uint256)
    {
        (, uint256 debtUsd, uint256 maxDebtUsd) = getUserBalanceStates(_user, _updatedMarkets);
        if (debtUsd == 0) return type(uint256).max;

        return maxDebtUsd.div(debtUsd);
    }

    /// @dev Returns the debt value, max debt value of a given user.
    /// @param _user The user to determine liquidity for.
    /// @param _poolToken The market to hypothetically withdraw/borrow in.
    /// @param _withdrawnAmount The amount to hypothetically withdraw from the given market (in underlying).
    /// @param _borrowedAmount The amount to hypothetically borrow from the given market (in underlying).
    /// @return debtUsd The current debt value of the user (in wad).
    /// @return maxDebtUsd The maximum debt value possible of the user (in wad).
    function getUserHypotheticalBalanceStates(
        address _user,
        address _poolToken,
        uint256 _withdrawnAmount,
        uint256 _borrowedAmount
    ) external view returns (uint256 debtUsd, uint256 maxDebtUsd) {
        ICompoundOracle oracle = ICompoundOracle(comptroller.oracle());
        address[] memory createdMarkets = morpho.getAllMarkets();

        uint256 nbCreatedMarkets = createdMarkets.length;
        for (uint256 i; i < nbCreatedMarkets; ++i) {
            address poolToken = createdMarkets[i];

            Types.AssetLiquidityData memory assetData = _poolToken == poolToken
                ? _getUserHypotheticalLiquidityDataForAsset(
                    _user,
                    poolToken,
                    true,
                    oracle,
                    _withdrawnAmount,
                    _borrowedAmount
                )
                : _getUserHypotheticalLiquidityDataForAsset(_user, poolToken, true, oracle, 0, 0);

            maxDebtUsd += assetData.maxDebtUsd;
            debtUsd += assetData.debtUsd;
        }
    }

    /// PUBLIC ///

    /// @notice Returns the collateral value, debt value and max debt value of a given user.
    /// @param _user The user to determine liquidity for.
    /// @param _updatedMarkets The list of markets of which to compute virtually updated pool and peer-to-peer indexes.
    /// @return collateralUsd The collateral value of the user (in wad).
    /// @return debtUsd The current debt value of the user (in wad).
    /// @return maxDebtUsd The maximum possible debt value of the user (in wad).
    function getUserBalanceStates(address _user, address[] calldata _updatedMarkets)
        public
        view
        returns (
            uint256 collateralUsd,
            uint256 debtUsd,
            uint256 maxDebtUsd
        )
    {
        ICompoundOracle oracle = ICompoundOracle(comptroller.oracle());
        address[] memory enteredMarkets = morpho.getEnteredMarkets(_user);

        uint256 nbUpdatedMarkets = _updatedMarkets.length;
        for (uint256 i; i < enteredMarkets.length; ) {
            address poolTokenEntered = enteredMarkets[i];

            bool shouldUpdateIndexes;
            for (uint256 j; j < nbUpdatedMarkets; ) {
                if (_updatedMarkets[j] == poolTokenEntered) {
                    shouldUpdateIndexes = true;
                    break;
                }

                unchecked {
                    ++j;
                }
            }

            Types.AssetLiquidityData memory assetData = getUserLiquidityDataForAsset(
                _user,
                poolTokenEntered,
                shouldUpdateIndexes,
                oracle
            );

            collateralUsd += assetData.collateralUsd;
            maxDebtUsd += assetData.maxDebtUsd;
            debtUsd += assetData.debtUsd;

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Returns the balance in underlying of a given user in a given market.
    /// @param _poolToken The address of the market.
    /// @param _user The user to determine balances of.
    /// @return balanceOnPool The balance on pool of the user (in underlying).
    /// @return balanceInP2P The balance in peer-to-peer of the user (in underlying).
    /// @return totalBalance The total balance of the user (in underlying).
    function getCurrentSupplyBalanceInOf(address _poolToken, address _user)
        public
        view
        returns (
            uint256 balanceOnPool,
            uint256 balanceInP2P,
            uint256 totalBalance
        )
    {
        (, Types.Indexes memory indexes) = _getIndexes(_poolToken, true);

        Types.SupplyBalance memory supplyBalance = morpho.supplyBalanceInOf(_poolToken, _user);

        balanceOnPool = supplyBalance.onPool.mul(indexes.poolSupplyIndex);
        balanceInP2P = supplyBalance.inP2P.mul(indexes.p2pSupplyIndex);

        totalBalance = balanceOnPool + balanceInP2P;
    }

    /// @notice Returns the borrow balance in underlying of a given user in a given market.
    /// @param _poolToken The address of the market.
    /// @param _user The user to determine balances of.
    /// @return balanceOnPool The balance on pool of the user (in underlying).
    /// @return balanceInP2P The balance in peer-to-peer of the user (in underlying).
    /// @return totalBalance The total balance of the user (in underlying).
    function getCurrentBorrowBalanceInOf(address _poolToken, address _user)
        public
        view
        returns (
            uint256 balanceOnPool,
            uint256 balanceInP2P,
            uint256 totalBalance
        )
    {
        (, Types.Indexes memory indexes) = _getIndexes(_poolToken, true);

        Types.BorrowBalance memory borrowBalance = morpho.borrowBalanceInOf(_poolToken, _user);

        balanceOnPool = borrowBalance.onPool.mul(indexes.poolBorrowIndex);
        balanceInP2P = borrowBalance.inP2P.mul(indexes.p2pBorrowIndex);

        totalBalance = balanceOnPool + balanceInP2P;
    }

    /// @notice Returns the data related to `_poolToken` for the `_user`, by optionally computing virtually updated pool and peer-to-peer indexes.
    /// @param _user The user to determine data for.
    /// @param _poolToken The address of the market.
    /// @param _getUpdatedIndexes Whether to compute virtually updated pool and peer-to-peer indexes.
    /// @param _oracle The oracle used.
    /// @return assetData The data related to this asset.
    function getUserLiquidityDataForAsset(
        address _user,
        address _poolToken,
        bool _getUpdatedIndexes,
        ICompoundOracle _oracle
    ) public view returns (Types.AssetLiquidityData memory) {
        return
            _getUserHypotheticalLiquidityDataForAsset(
                _user,
                _poolToken,
                _getUpdatedIndexes,
                _oracle,
                0,
                0
            );
    }

    /// @notice Returns whether a liquidation can be performed on a given user.
    /// @dev This function checks for the user's health factor, without treating borrow positions from deprecated market as instantly liquidatable.
    /// @param _user The address of the user to check.
    /// @param _updatedMarkets The list of markets of which to compute virtually updated pool and peer-to-peer indexes.
    /// @return whether or not the user is liquidatable.
    function isLiquidatable(address _user, address[] memory _updatedMarkets)
        public
        view
        returns (bool)
    {
        return _isLiquidatable(_user, address(0), _updatedMarkets);
    }

    /// @notice Returns whether a liquidation can be performed on a given user borrowing from a given market.
    /// @dev This function checks for the user's health factor as well as whether the given market is deprecated & the user is borrowing from it.
    /// @param _user The address of the user to check.
    /// @param _poolToken The address of the borrowed market to check.
    /// @param _updatedMarkets The list of markets of which to compute virtually updated pool and peer-to-peer indexes.
    /// @return whether or not the user is liquidatable.
    function isLiquidatable(
        address _user,
        address _poolToken,
        address[] memory _updatedMarkets
    ) public view returns (bool) {
        if (morpho.marketPauseStatus(_poolToken).isDeprecated)
            return _isLiquidatable(_user, _poolToken, _updatedMarkets);

        return isLiquidatable(_user, _updatedMarkets);
    }

    /// INTERNAL ///

    /// @dev Returns the supply balance of `_user` in the `_poolToken` market.
    /// @dev Note: Computes the result with the stored indexes, which are not always the most up to date ones.
    /// @param _user The address of the user.
    /// @param _poolToken The market where to get the supply amount.
    /// @return The supply balance of the user (in underlying).
    function _getUserSupplyBalanceInOf(
        address _poolToken,
        address _user,
        uint256 _p2pSupplyIndex,
        uint256 _poolSupplyIndex
    ) internal view returns (uint256) {
        Types.SupplyBalance memory supplyBalance = morpho.supplyBalanceInOf(_poolToken, _user);

        return
            supplyBalance.inP2P.mul(_p2pSupplyIndex) + supplyBalance.onPool.mul(_poolSupplyIndex);
    }

    /// @dev Returns the borrow balance of `_user` in the `_poolToken` market.
    /// @param _user The address of the user.
    /// @param _poolToken The market where to get the borrow amount.
    /// @return The borrow balance of the user (in underlying).
    function _getUserBorrowBalanceInOf(
        address _poolToken,
        address _user,
        uint256 _p2pBorrowIndex,
        uint256 _poolBorrowIndex
    ) internal view returns (uint256) {
        Types.BorrowBalance memory borrowBalance = morpho.borrowBalanceInOf(_poolToken, _user);

        return
            borrowBalance.inP2P.mul(_p2pBorrowIndex) + borrowBalance.onPool.mul(_poolBorrowIndex);
    }

    /// @dev Returns the data related to `_poolToken` for the `_user`, by optionally computing virtually updated pool and peer-to-peer indexes.
    /// @param _user The user to determine data for.
    /// @param _poolToken The address of the market.
    /// @param _getUpdatedIndexes Whether to compute virtually updated pool and peer-to-peer indexes.
    /// @param _oracle The oracle used.
    /// @param _withdrawnAmount The amount to hypothetically withdraw from the given market (in underlying).
    /// @param _borrowedAmount The amount to hypothetically borrow from the given market (in underlying).
    /// @return assetData The data related to this asset.
    function _getUserHypotheticalLiquidityDataForAsset(
        address _user,
        address _poolToken,
        bool _getUpdatedIndexes,
        ICompoundOracle _oracle,
        uint256 _withdrawnAmount,
        uint256 _borrowedAmount
    ) internal view returns (Types.AssetLiquidityData memory assetData) {
        assetData.underlyingPrice = _oracle.getUnderlyingPrice(_poolToken);
        if (assetData.underlyingPrice == 0) revert CompoundOracleFailed();

        (, assetData.collateralFactor, ) = comptroller.markets(_poolToken);

        (, Types.Indexes memory indexes) = _getIndexes(_poolToken, _getUpdatedIndexes);

        assetData.collateralUsd = _getUserSupplyBalanceInOf(
            _poolToken,
            _user,
            indexes.p2pSupplyIndex,
            indexes.poolSupplyIndex
        ).zeroFloorSub(_withdrawnAmount)
        .mul(assetData.underlyingPrice);

        assetData.debtUsd = (_getUserBorrowBalanceInOf(
            _poolToken,
            _user,
            indexes.p2pBorrowIndex,
            indexes.poolBorrowIndex
        ) + _borrowedAmount)
        .mul(assetData.underlyingPrice);

        assetData.maxDebtUsd = assetData.collateralUsd.mul(assetData.collateralFactor);
    }

    /// @dev Returns whether a liquidation can be performed on the given user.
    ///      This function checks for the user's health factor as well as whether the user is borrowing from the given deprecated market.
    /// @param _user The address of the user to check.
    /// @param _poolTokenDeprecated The address of the deprecated borrowed market to check.
    /// @param _updatedMarkets The list of markets of which to compute virtually updated pool and peer-to-peer indexes.
    /// @return whether or not the user is liquidatable.
    function _isLiquidatable(
        address _user,
        address _poolTokenDeprecated,
        address[] memory _updatedMarkets
    ) internal view returns (bool) {
        ICompoundOracle oracle = ICompoundOracle(comptroller.oracle());
        address[] memory enteredMarkets = morpho.getEnteredMarkets(_user);

        uint256 maxDebtUsd;
        uint256 debtUsd;

        uint256 nbUpdatedMarkets = _updatedMarkets.length;
        for (uint256 i; i < enteredMarkets.length; ) {
            address poolTokenEntered = enteredMarkets[i];

            bool shouldUpdateIndexes;
            for (uint256 j; j < nbUpdatedMarkets; ) {
                if (_updatedMarkets[j] == poolTokenEntered) {
                    shouldUpdateIndexes = true;
                    break;
                }

                unchecked {
                    ++j;
                }
            }

            Types.AssetLiquidityData memory assetData = getUserLiquidityDataForAsset(
                _user,
                poolTokenEntered,
                shouldUpdateIndexes,
                oracle
            );

            if (_poolTokenDeprecated == poolTokenEntered && assetData.debtUsd > 0) return true;

            maxDebtUsd += assetData.maxDebtUsd;
            debtUsd += assetData.debtUsd;

            unchecked {
                ++i;
            }
        }

        return debtUsd > maxDebtUsd;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.0;

import "../../interfaces/compound/ICompound.sol";
import "../../interfaces/IRewardsManager.sol";
import "../../interfaces/IMorpho.sol";

interface ILens {
    /// STORAGE ///

    function MAX_BASIS_POINTS() external view returns (uint256);

    function WAD() external view returns (uint256);

    function morpho() external view returns (IMorpho);

    function comptroller() external view returns (IComptroller);

    function rewardsManager() external view returns (IRewardsManager);

    /// GENERAL ///

    function getTotalSupply()
        external
        view
        returns (
            uint256 p2pSupplyAmount,
            uint256 poolSupplyAmount,
            uint256 totalSupplyAmount
        );

    function getTotalBorrow()
        external
        view
        returns (
            uint256 p2pBorrowAmount,
            uint256 poolBorrowAmount,
            uint256 totalBorrowAmount
        );

    /// MARKETS ///

    function isMarketCreated(address _poolToken) external view returns (bool);

    /// @dev Deprecated.
    function isMarketCreatedAndNotPaused(address _poolToken) external view returns (bool);

    /// @dev Deprecated.
    function isMarketCreatedAndNotPausedNorPartiallyPaused(address _poolToken)
        external
        view
        returns (bool);

    function getAllMarkets() external view returns (address[] memory marketsCreated_);

    function getMainMarketData(address _poolToken)
        external
        view
        returns (
            uint256 avgSupplyRatePerBlock,
            uint256 avgBorrowRatePerBlock,
            uint256 p2pSupplyAmount,
            uint256 p2pBorrowAmount,
            uint256 poolSupplyAmount,
            uint256 poolBorrowAmount
        );

    function getAdvancedMarketData(address _poolToken)
        external
        view
        returns (
            Types.Indexes memory indexes,
            uint32 lastUpdateBlockNumber,
            uint256 p2pSupplyDelta,
            uint256 p2pBorrowDelta
        );

    function getMarketConfiguration(address _poolToken)
        external
        view
        returns (
            address underlying,
            bool isCreated,
            bool p2pDisabled,
            bool isPaused,
            bool isPartiallyPaused,
            uint16 reserveFactor,
            uint16 p2pIndexCursor,
            uint256 collateralFactor
        );

    function getMarketPauseStatus(address _poolToken)
        external
        view
        returns (Types.MarketPauseStatus memory);

    function getTotalMarketSupply(address _poolToken)
        external
        view
        returns (uint256 p2pSupplyAmount, uint256 poolSupplyAmount);

    function getTotalMarketBorrow(address _poolToken)
        external
        view
        returns (uint256 p2pBorrowAmount, uint256 poolBorrowAmount);

    /// INDEXES ///

    function getCurrentP2PSupplyIndex(address _poolToken) external view returns (uint256);

    function getCurrentP2PBorrowIndex(address _poolToken) external view returns (uint256);

    function getCurrentPoolIndexes(address _poolToken)
        external
        view
        returns (uint256 currentPoolSupplyIndex, uint256 currentPoolBorrowIndex);

    function getIndexes(address _poolToken, bool _computeUpdatedIndexes)
        external
        view
        returns (Types.Indexes memory indexes);

    /// USERS ///

    function getEnteredMarkets(address _user)
        external
        view
        returns (address[] memory enteredMarkets);

    function getUserHealthFactor(address _user, address[] calldata _updatedMarkets)
        external
        view
        returns (uint256);

    function getUserBalanceStates(address _user, address[] calldata _updatedMarkets)
        external
        view
        returns (
            uint256 collateralValue,
            uint256 debtValue,
            uint256 maxDebtValue
        );

    function getCurrentSupplyBalanceInOf(address _poolToken, address _user)
        external
        view
        returns (
            uint256 balanceOnPool,
            uint256 balanceInP2P,
            uint256 totalBalance
        );

    function getCurrentBorrowBalanceInOf(address _poolToken, address _user)
        external
        view
        returns (
            uint256 balanceOnPool,
            uint256 balanceInP2P,
            uint256 totalBalance
        );

    function getUserMaxCapacitiesForAsset(address _user, address _poolToken)
        external
        view
        returns (uint256 withdrawable, uint256 borrowable);

    function getUserHypotheticalBalanceStates(
        address _user,
        address _poolToken,
        uint256 _withdrawnAmount,
        uint256 _borrowedAmount
    ) external view returns (uint256 debtValue, uint256 maxDebtValue);

    function getUserLiquidityDataForAsset(
        address _user,
        address _poolToken,
        bool _computeUpdatedIndexes,
        ICompoundOracle _oracle
    ) external view returns (Types.AssetLiquidityData memory assetData);

    function isLiquidatable(address _user, address[] memory _updatedMarkets)
        external
        view
        returns (bool);

    function isLiquidatable(
        address _user,
        address _poolToken,
        address[] memory _updatedMarkets
    ) external view returns (bool);

    function computeLiquidationRepayAmount(
        address _user,
        address _poolTokenBorrowed,
        address _poolTokenCollateral,
        address[] calldata _updatedMarkets
    ) external view returns (uint256 toRepay);

    /// RATES ///

    function getNextUserSupplyRatePerBlock(
        address _poolToken,
        address _user,
        uint256 _amount
    )
        external
        view
        returns (
            uint256 nextSupplyRatePerBlock,
            uint256 balanceOnPool,
            uint256 balanceInP2P,
            uint256 totalBalance
        );

    function getNextUserBorrowRatePerBlock(
        address _poolToken,
        address _user,
        uint256 _amount
    )
        external
        view
        returns (
            uint256 nextBorrowRatePerBlock,
            uint256 balanceOnPool,
            uint256 balanceInP2P,
            uint256 totalBalance
        );

    function getCurrentUserSupplyRatePerBlock(address _poolToken, address _user)
        external
        view
        returns (uint256);

    function getCurrentUserBorrowRatePerBlock(address _poolToken, address _user)
        external
        view
        returns (uint256);

    function getAverageSupplyRatePerBlock(address _poolToken)
        external
        view
        returns (
            uint256 avgSupplyRatePerBlock,
            uint256 p2pSupplyAmount,
            uint256 poolSupplyAmount
        );

    function getAverageBorrowRatePerBlock(address _poolToken)
        external
        view
        returns (
            uint256 avgBorrowRatePerBlock,
            uint256 p2pBorrowAmount,
            uint256 poolBorrowAmount
        );

    function getRatesPerBlock(address _poolToken)
        external
        view
        returns (
            uint256 p2pSupplyRate,
            uint256 p2pBorrowRate,
            uint256 poolSupplyRate,
            uint256 poolBorrowRate
        );

    /// REWARDS ///

    function getUserUnclaimedRewards(address[] calldata _poolTokens, address _user)
        external
        view
        returns (uint256 unclaimedRewards);

    function getAccruedSupplierComp(
        address _supplier,
        address _poolToken,
        uint256 _balance
    ) external view returns (uint256);

    function getAccruedBorrowerComp(
        address _borrower,
        address _poolToken,
        uint256 _balance
    ) external view returns (uint256);

    function getAccruedSupplierComp(address _supplier, address _poolToken)
        external
        view
        returns (uint256);

    function getAccruedBorrowerComp(address _borrower, address _poolToken)
        external
        view
        returns (uint256);

    function getCurrentCompSupplyIndex(address _poolToken) external view returns (uint256);

    function getCurrentCompBorrowIndex(address _poolToken) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.0;

import "../../interfaces/compound/ICompound.sol";
import "../../interfaces/IRewardsManager.sol";
import "../../interfaces/IMorpho.sol";

interface ILensExtension {
    function morpho() external view returns (IMorpho);

    function getUserUnclaimedRewards(address[] calldata _poolTokens, address _user)
        external
        view
        returns (uint256 unclaimedRewards);

    function getAccruedSupplierComp(
        address _supplier,
        address _poolToken,
        uint256 _balance
    ) external view returns (uint256);

    function getAccruedBorrowerComp(
        address _borrower,
        address _poolToken,
        uint256 _balance
    ) external view returns (uint256);

    function getAccruedSupplierComp(address _supplier, address _poolToken)
        external
        view
        returns (uint256);

    function getAccruedBorrowerComp(address _borrower, address _poolToken)
        external
        view
        returns (uint256);

    function getCurrentCompSupplyIndex(address _poolToken) external view returns (uint256);

    function getCurrentCompBorrowIndex(address _poolToken) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@morpho-dao/morpho-utils/math/PercentageMath.sol";
import "@morpho-dao/morpho-utils/math/CompoundMath.sol";
import "@morpho-dao/morpho-utils/math/Math.sol";
import "./Types.sol";

library InterestRatesModel {
    using PercentageMath for uint256;
    using CompoundMath for uint256;

    /// STRUCTS ///

    struct GrowthFactors {
        uint256 poolSupplyGrowthFactor; // The pool supply index growth factor (in wad).
        uint256 poolBorrowGrowthFactor; // The pool borrow index growth factor (in wad).
        uint256 p2pSupplyGrowthFactor; // Peer-to-peer supply index growth factor (in wad).
        uint256 p2pBorrowGrowthFactor; // Peer-to-peer borrow index growth factor (in wad).
    }

    struct P2PIndexComputeParams {
        uint256 poolGrowthFactor; // The pool index growth factor (in wad).
        uint256 p2pGrowthFactor; // Morpho's peer-to-peer median index growth factor (in wad).
        uint256 lastPoolIndex; // The last stored pool index (in wad).
        uint256 lastP2PIndex; // The last stored peer-to-peer index (in wad).
        uint256 p2pDelta; // The peer-to-peer delta for the given market (in pool unit).
        uint256 p2pAmount; // The peer-to-peer amount for the given market (in peer-to-peer unit).
    }

    struct P2PRateComputeParams {
        uint256 poolRate; // The pool rate per block (in wad).
        uint256 p2pRate; // The peer-to-peer rate per block (in wad).
        uint256 poolIndex; // The last stored pool index (in wad).
        uint256 p2pIndex; // The last stored peer-to-peer index (in wad).
        uint256 p2pDelta; // The peer-to-peer delta for the given market (in pool unit).
        uint256 p2pAmount; // The peer-to-peer amount for the given market (in peer-to-peer unit).
        uint16 reserveFactor; // The reserve factor of the given market (in bps).
    }

    /// @notice Computes and returns the new supply/borrow growth factors associated to the given market's pool & peer-to-peer indexes.
    /// @param _newPoolSupplyIndex The current pool supply index.
    /// @param _newPoolBorrowIndex The current pool borrow index.
    /// @param _lastPoolIndexes The last stored pool indexes.
    /// @param _p2pIndexCursor The peer-to-peer index cursor for the given market.
    /// @param _reserveFactor The reserve factor of the given market.
    /// @return growthFactors The market's indexes growth factors (in wad).
    function computeGrowthFactors(
        uint256 _newPoolSupplyIndex,
        uint256 _newPoolBorrowIndex,
        Types.LastPoolIndexes memory _lastPoolIndexes,
        uint256 _p2pIndexCursor,
        uint256 _reserveFactor
    ) internal pure returns (GrowthFactors memory growthFactors) {
        growthFactors.poolSupplyGrowthFactor = _newPoolSupplyIndex.div(
            _lastPoolIndexes.lastSupplyPoolIndex
        );
        growthFactors.poolBorrowGrowthFactor = _newPoolBorrowIndex.div(
            _lastPoolIndexes.lastBorrowPoolIndex
        );

        if (growthFactors.poolSupplyGrowthFactor <= growthFactors.poolBorrowGrowthFactor) {
            uint256 p2pGrowthFactor = PercentageMath.weightedAvg(
                growthFactors.poolSupplyGrowthFactor,
                growthFactors.poolBorrowGrowthFactor,
                _p2pIndexCursor
            );

            growthFactors.p2pSupplyGrowthFactor =
                p2pGrowthFactor -
                (p2pGrowthFactor - growthFactors.poolSupplyGrowthFactor).percentMul(_reserveFactor);
            growthFactors.p2pBorrowGrowthFactor =
                p2pGrowthFactor +
                (growthFactors.poolBorrowGrowthFactor - p2pGrowthFactor).percentMul(_reserveFactor);
        } else {
            // The case poolSupplyGrowthFactor > poolBorrowGrowthFactor happens because someone sent underlying tokens to the
            // cToken contract: the peer-to-peer growth factors are set to the pool borrow growth factor.
            growthFactors.p2pSupplyGrowthFactor = growthFactors.poolBorrowGrowthFactor;
            growthFactors.p2pBorrowGrowthFactor = growthFactors.poolBorrowGrowthFactor;
        }
    }

    /// @notice Computes and returns the new peer-to-peer supply/borrow index of a market given its parameters.
    /// @param _params The computation parameters.
    /// @return newP2PIndex The updated peer-to-peer index (in wad).
    function computeP2PIndex(P2PIndexComputeParams memory _params)
        internal
        pure
        returns (uint256 newP2PIndex)
    {
        if (_params.p2pAmount == 0 || _params.p2pDelta == 0) {
            newP2PIndex = _params.lastP2PIndex.mul(_params.p2pGrowthFactor);
        } else {
            uint256 shareOfTheDelta = Math.min(
                (_params.p2pDelta.mul(_params.lastPoolIndex)).div(
                    (_params.p2pAmount).mul(_params.lastP2PIndex)
                ),
                CompoundMath.WAD // To avoid shareOfTheDelta > 1 with rounding errors.
            );

            newP2PIndex = _params.lastP2PIndex.mul(
                (CompoundMath.WAD - shareOfTheDelta).mul(_params.p2pGrowthFactor) +
                    shareOfTheDelta.mul(_params.poolGrowthFactor)
            );
        }
    }

    /// @notice Computes and returns the peer-to-peer supply rate per block of a market given its parameters.
    /// @param _params The computation parameters.
    /// @return p2pSupplyRate The peer-to-peer supply rate per block (in wad).
    function computeP2PSupplyRatePerBlock(P2PRateComputeParams memory _params)
        internal
        pure
        returns (uint256 p2pSupplyRate)
    {
        p2pSupplyRate =
            _params.p2pRate -
            (_params.p2pRate - _params.poolRate).percentMul(_params.reserveFactor);

        if (_params.p2pDelta > 0 && _params.p2pAmount > 0) {
            uint256 shareOfTheDelta = Math.min(
                _params.p2pDelta.mul(_params.poolIndex).div(
                    _params.p2pAmount.mul(_params.p2pIndex)
                ),
                CompoundMath.WAD // To avoid shareOfTheDelta > 1 with rounding errors.
            );

            p2pSupplyRate =
                p2pSupplyRate.mul(CompoundMath.WAD - shareOfTheDelta) +
                _params.poolRate.mul(shareOfTheDelta);
        }
    }

    /// @notice Computes and returns the peer-to-peer borrow rate per block of a market given its parameters.
    /// @param _params The computation parameters.
    /// @return p2pBorrowRate The peer-to-peer borrow rate per block (in wad).
    function computeP2PBorrowRatePerBlock(P2PRateComputeParams memory _params)
        internal
        pure
        returns (uint256 p2pBorrowRate)
    {
        p2pBorrowRate =
            _params.p2pRate +
            (_params.poolRate - _params.p2pRate).percentMul(_params.reserveFactor);

        if (_params.p2pDelta > 0 && _params.p2pAmount > 0) {
            uint256 shareOfTheDelta = Math.min(
                _params.p2pDelta.mul(_params.poolIndex).div(
                    _params.p2pAmount.mul(_params.p2pIndex)
                ),
                CompoundMath.WAD // To avoid shareOfTheDelta > 1 with rounding errors.
            );

            p2pBorrowRate =
                p2pBorrowRate.mul(CompoundMath.WAD - shareOfTheDelta) +
                _params.poolRate.mul(shareOfTheDelta);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/// @title Types.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @dev Common types and structs used in Morpho contracts.
library Types {
    /// ENUMS ///

    enum PositionType {
        SUPPLIERS_IN_P2P,
        SUPPLIERS_ON_POOL,
        BORROWERS_IN_P2P,
        BORROWERS_ON_POOL
    }

    /// STRUCTS ///

    struct SupplyBalance {
        uint256 inP2P; // In peer-to-peer supply unit, a unit that grows in underlying value, to keep track of the interests earned by suppliers in peer-to-peer. Multiply by the peer-to-peer supply index to get the underlying amount.
        uint256 onPool; // In pool supply unit. Multiply by the pool supply index to get the underlying amount.
    }

    struct BorrowBalance {
        uint256 inP2P; // In peer-to-peer borrow unit, a unit that grows in underlying value, to keep track of the interests paid by borrowers in peer-to-peer. Multiply by the peer-to-peer borrow index to get the underlying amount.
        uint256 onPool; // In pool borrow unit, a unit that grows in value, to keep track of the debt increase when borrowers are on Compound. Multiply by the pool borrow index to get the underlying amount.
    }

    struct Indexes {
        uint256 p2pSupplyIndex; // The peer-to-peer supply index (in wad), used to multiply the peer-to-peer supply scaled balance and get the peer-to-peer supply balance (in underlying).
        uint256 p2pBorrowIndex; // The peer-to-peer borrow index (in wad), used to multiply the peer-to-peer borrow scaled balance and get the peer-to-peer borrow balance (in underlying).
        uint256 poolSupplyIndex; // The pool supply index (in wad), used to multiply the pool supply scaled balance and get the pool supply balance (in underlying).
        uint256 poolBorrowIndex; // The pool borrow index (in wad), used to multiply the pool borrow scaled balance and get the pool borrow balance (in underlying).
    }

    // Max gas to consume during the matching process for supply, borrow, withdraw and repay functions.
    struct MaxGasForMatching {
        uint64 supply;
        uint64 borrow;
        uint64 withdraw;
        uint64 repay;
    }

    struct Delta {
        uint256 p2pSupplyDelta; // Difference between the stored peer-to-peer supply amount and the real peer-to-peer supply amount (in pool supply unit).
        uint256 p2pBorrowDelta; // Difference between the stored peer-to-peer borrow amount and the real peer-to-peer borrow amount (in pool borrow unit).
        uint256 p2pSupplyAmount; // Sum of all stored peer-to-peer supply (in peer-to-peer supply unit).
        uint256 p2pBorrowAmount; // Sum of all stored peer-to-peer borrow (in peer-to-peer borrow unit).
    }

    struct AssetLiquidityData {
        uint256 collateralUsd; // The collateral value of the asset (in wad).
        uint256 maxDebtUsd; // The maximum possible debt value of the asset (in wad).
        uint256 debtUsd; // The debt value of the asset (in wad).
        uint256 underlyingPrice; // The price of the token.
        uint256 collateralFactor; // The liquidation threshold applied on this token (in wad).
    }

    struct LiquidityData {
        uint256 collateralUsd; // The collateral value (in wad).
        uint256 maxDebtUsd; // The maximum debt value allowed before being liquidatable (in wad).
        uint256 debtUsd; // The debt value (in wad).
    }

    // Variables are packed together to save gas (will not exceed their limit during Morpho's lifetime).
    struct LastPoolIndexes {
        uint32 lastUpdateBlockNumber; // The last time the local pool and peer-to-peer indexes were updated.
        uint112 lastSupplyPoolIndex; // Last pool supply index.
        uint112 lastBorrowPoolIndex; // Last pool borrow index.
    }

    struct MarketParameters {
        uint16 reserveFactor; // Proportion of the interest earned by users sent to the DAO for each market, in basis point (100% = 10 000). The value is set at market creation.
        uint16 p2pIndexCursor; // Position of the peer-to-peer rate in the pool's spread. Determine the weights of the weighted arithmetic average in the indexes computations ((1 - p2pIndexCursor) * r^S + p2pIndexCursor * r^B) (in basis point).
    }

    struct MarketStatus {
        bool isCreated; // Whether or not this market is created.
        bool isPaused; // Deprecated.
        bool isPartiallyPaused; // Deprecated.
    }

    struct MarketPauseStatus {
        bool isSupplyPaused; // Whether the supply is paused or not.
        bool isBorrowPaused; // Whether the borrow is paused or not
        bool isWithdrawPaused; // Whether the withdraw is paused or not. Note that a "withdraw" is still possible using a liquidation (if not paused).
        bool isRepayPaused; // Whether the repay is paused or not. Note that a "repay" is still possible using a liquidation (if not paused).
        bool isLiquidateCollateralPaused; // Whether the liquidation on this market as collateral is paused or not.
        bool isLiquidateBorrowPaused; // Whether the liquidatation on this market as borrow is paused or not.
        bool isDeprecated; // Whether a market is deprecated or not.
    }
}