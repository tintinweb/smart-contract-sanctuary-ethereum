/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

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

    /*///////////////////////////////////////////////////////////////
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

pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                            COMMON BASE UNITS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant YAD = 1e8;
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant RAD = 1e45;

    /*///////////////////////////////////////////////////////////////
                         FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // If baseUnit is zero this will return zero instead of reverting.
            z := div(z, baseUnit)
        }
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * baseUnit in z for now.
            z := mul(x, baseUnit)

            // Equivalent to require(y != 0 && (x == 0 || (x * baseUnit) / x == baseUnit))
            if iszero(and(iszero(iszero(y)), or(iszero(x), eq(div(z, x), baseUnit)))) {
                revert(0, 0)
            }

            // We ensure y is not zero above, so there is never division by zero here.
            z := div(z, y)
        }
    }

    function fpow(
        uint256 x,
        uint256 n,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := baseUnit
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store baseUnit in z for now.
                    z := baseUnit
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, baseUnit)

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
                    x := div(xxRound, baseUnit)

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
                        z := div(zxRound, baseUnit)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z)
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z)
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z)
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z)
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z)
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z)
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

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

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

pragma solidity >=0.8.0;

// ██    ██ ███    ██ ██ ██████   ██████   ██████  ██
// ██    ██ ████   ██ ██ ██   ██ ██    ██ ██    ██ ██
// ██    ██ ██ ██  ██ ██ ██████  ██    ██ ██    ██ ██
// ██    ██ ██  ██ ██ ██ ██      ██    ██ ██    ██ ██
//  ██████  ██   ████ ██ ██       ██████   ██████  ███████
contract Unipool is ERC20("Unipool LP Token", "CLP", 18), ReentrancyGuardUpgradeable {

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event Mint(address indexed sender, uint256 baseAmount, uint256 quoteAmount);
    event Burn(address indexed sender, uint256 baseAmount, uint256 quoteAmount, address indexed to);

    event Swap(
        address indexed sender,
        uint256 baseAmountIn,
        uint256 quoteAmountIn,
        uint256 baseAmountOut,
        uint256 quoteAmountOut,
        address indexed to
    );

    event Sync(uint112 baseReserves, uint112 quoteReserves);

    /* -------------------------------------------------------------------------- */
    /*                                  CONSTANTS                                 */
    /* -------------------------------------------------------------------------- */

    // To avoid division by zero, there is a minimum number of liquidity tokens that always
    // exist (but are owned by account zero). That number is BIPS_DIVISOR, ten thousand.
    uint256 internal constant PRECISION = 112;
    uint256 internal constant BIPS_DIVISOR = 10_000;

    /* -------------------------------------------------------------------------- */
    /*                                MUTABLE STATE                               */
    /* -------------------------------------------------------------------------- */

    address public factory;
    address public base;
    address public quote;

    uint256 public swapFee;
    uint256 public basePriceCumulativeLast;
    uint256 public quotePriceCumulativeLast;

    uint112 private baseReserves;
    uint112 private quoteReserves;
    uint32  private lastUpdate;

    function getReserves() public view returns (uint112 _baseReserves, uint112 _quoteReserves, uint32 _lastUpdate) {
        (_baseReserves, _quoteReserves, _lastUpdate) = (baseReserves, quoteReserves, lastUpdate);
    }

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */

    error INITIALIZED();

    // called once by the factory at time of deployment
    function initialize(
        address _base,
        address _quote,
        uint256 _swapFee
    ) external initializer {
        if (swapFee > 0) revert INITIALIZED();
        (base, quote, swapFee) = (_base, _quote, _swapFee);
        _mint(address(0), BIPS_DIVISOR);

        __ReentrancyGuard_init();
    }

    error BALANCE_OVERFLOW();

    /// @notice update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 baseBalance,
        uint256 quoteBalance,
        uint112 _baseReserves,
        uint112 _quoteReserves
    ) private {
        unchecked {
            // 1) revert if both balances are greater than 2**112
            if (baseBalance > type(uint112).max || quoteBalance > type(uint112).max) revert BALANCE_OVERFLOW();
            // 2) store current time in memory (mod 2**32 to prevent DoS in 20 years)
            uint32 timestampAdjusted = uint32(block.timestamp % 2**32);
            // 3) store elapsed time since last update
            uint256 timeElapsed = timestampAdjusted - lastUpdate;
            // 4) if oracle info hasn"t been updated this block, and there's liquidity, update TWAP variables
            if (timeElapsed > 0 && _baseReserves != 0 && _quoteReserves != 0) {
                basePriceCumulativeLast += (uint(_quoteReserves) << PRECISION) / _baseReserves * timeElapsed;
                quotePriceCumulativeLast += (uint(_baseReserves) << PRECISION) / _quoteReserves * timeElapsed;
            }
            // 5) sync reserves (make them match balances)
            (baseReserves, quoteReserves, lastUpdate) = (uint112(baseBalance), uint112(quoteBalance), timestampAdjusted);
            // 6) emit event since mutable storage was updated
            emit Sync(baseReserves, quoteReserves);
        }
    }

    error INSUFFICIENT_LIQUIDITY_MINTED();

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external nonReentrant returns (uint256 liquidity) {
        // 1) store any variables used more than once in memory to avoid SLOAD"s
        (uint112 _baseReserves, uint112 _quoteReserves,) = getReserves();
        uint256 baseBalance = ERC20(base).balanceOf(address(this));
        uint256 quoteBalance = ERC20(quote).balanceOf(address(this));
        uint256 baseAmount = baseBalance - (_baseReserves);
        uint256 quoteAmount = quoteBalance - (_quoteReserves);
        uint256 _totalSupply = totalSupply;
        // 2) if lp token total supply is equal to BIPS_DIVISOR (1,000 wei),
        // amountOut (liquidity) is equal to the root of k minus BIPS_DIVISOR
        if (_totalSupply == BIPS_DIVISOR) liquidity = FixedPointMathLib.sqrt(baseAmount * quoteAmount) - BIPS_DIVISOR;
        else liquidity = min(uDiv(baseAmount * _totalSupply, _baseReserves), uDiv(quoteAmount * _totalSupply, _quoteReserves));
        // 3) revert if Lp tokens out is equal to zero
        if (liquidity == 0) revert INSUFFICIENT_LIQUIDITY_MINTED();
        // 4) mint liquidity providers LP tokens
        _mint(to, liquidity);
        // 5) update mutable storage (reserves + cumulative oracle prices)
        _update(baseBalance, quoteBalance, _baseReserves, _quoteReserves);
        // 6) emit event since mutable storage was updated
        emit Mint(msg.sender, baseAmount, quoteAmount);
    }

    error INSUFFICIENT_LIQUIDITY_BURNED();

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external nonReentrant returns (uint256 baseAmount, uint256 quoteAmount) {
        // 1) store any variables used more than once in memory to avoid SLOAD"s
        (uint112 _baseReserves, uint112 _quoteReserves,) = getReserves();
        address _base = base;
        address _quote = quote;
        uint256 baseBalance = ERC20(_base).balanceOf(address(this));
        uint256 quoteBalance = ERC20(_quote).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];
        uint256 _totalSupply = totalSupply;
        // 2) division was originally unchecked, using balances ensures pro-rata distribution
        baseAmount = uDiv(liquidity * baseBalance, _totalSupply);
        quoteAmount = uDiv(liquidity * quoteBalance, _totalSupply);
        // 3) revert if amountOuts are both equal to zero
        if (baseAmount == 0 && quoteAmount == 0) revert INSUFFICIENT_LIQUIDITY_BURNED();
        // 4) burn LP tokens from this contract"s balance
        _burn(address(this), liquidity);
        // 5) return liquidity providers underlying tokens
        TransferHelper.safeTransfer(_base, to, baseAmount);
        TransferHelper.safeTransfer(_quote, to, quoteAmount);
        // 6) update mutable storage (reserves + cumulative oracle prices)
        _update(ERC20(_base).balanceOf(address(this)), ERC20(_quote).balanceOf(address(this)), _baseReserves, _quoteReserves);
        // 7) emit event since mutable storage was updated
        emit Burn(msg.sender, baseAmount, quoteAmount, to);
    }

    error INSUFFICIENT_OUTPUT_AMOUNT();
    error INSUFFICIENT_LIQUIDITY();
    error INSUFFICIENT_INPUT_AMOUNT();
    error INSUFFICIENT_INVARIANT();

    /// @notice Optimistically swap tokens, will revert if K is not satisfied
    /// @param baseAmountOut - amount of base tokens user wants to receive
    /// @param quoteAmountOut - amount of quote tokens user wants to receive
    /// @param to - recipient of 'output' tokens
    /// @param data - arbitrary data used during flashswaps
    function swap(
        uint256 baseAmountOut,
        uint256 quoteAmountOut,
        address to,
        bytes calldata data
    ) external nonReentrant {
        // 1) revert if both amounts out are zero
        // 2) store reserves in memory to avoid SLOAD"s
        // 3) revert if both amounts out
        // 4) store any other variables used more than once in memory to avoid SLOAD"s
        if (baseAmountOut + quoteAmountOut == 0) revert INSUFFICIENT_OUTPUT_AMOUNT();
        (uint112 _baseReserves, uint112 _quoteReserves,) = getReserves();
        if (baseAmountOut > _baseReserves || quoteAmountOut >=_quoteReserves) revert INSUFFICIENT_LIQUIDITY();
        uint256 baseAmountIn;
        uint256 quoteAmountIn;
        uint256 baseBalance;
        uint256 quoteBalance;
        {
        address _base = base;
        address _quote = quote;
        // 1) optimistically transfer "to" base tokens
        // 2) optimistically transfer "to" quote tokens
        // 3) if data length is greater than 0, initiate flashswap
        // 4) store base token balance of contract in memory
        // 5) store quote token balance of contract in memory
        if (baseAmountOut > 0) TransferHelper.safeTransfer(_base, to, baseAmountOut);
        if (quoteAmountOut > 0) TransferHelper.safeTransfer(_quote, to, quoteAmountOut);
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, baseAmountOut, quoteAmountOut, data);
        baseBalance = ERC20(_base).balanceOf(address(this));
        quoteBalance = ERC20(_quote).balanceOf(address(this));
        }

        unchecked {
            // 1) calculate baseAmountIn by comparing contracts balance to last known reserve
            // 2) calculate quoteAmountIn by comparing contracts balance to last known reserve
            // 3) revert if user hasn't sent any tokens to the contract
            if (baseBalance > _baseReserves - baseAmountOut) baseAmountIn = baseBalance - (_baseReserves - baseAmountOut);
            if (quoteBalance > _quoteReserves - quoteAmountOut) quoteAmountIn = quoteBalance - (_quoteReserves - quoteAmountOut);
            if (baseAmountIn + quoteAmountIn == 0) revert INSUFFICIENT_INPUT_AMOUNT();
        }

        {
        // 1) store swap fee in memory to save SLOAD
        // 2) revert if current k adjusted for fees is less than old k
        // 3) update mutable storage (reserves + cumulative oracle prices)
        // 4) emit event since mutable storage was updated
        uint256 _swapFee = swapFee;
        uint256 baseBalanceAdjusted = baseBalance * BIPS_DIVISOR - baseAmountIn * _swapFee;
        uint256 quoteBalanceAdjusted = quoteBalance * BIPS_DIVISOR - quoteAmountIn * _swapFee;
        if (baseBalanceAdjusted * quoteBalanceAdjusted < uint(_baseReserves) * _quoteReserves * 1e8) revert INSUFFICIENT_INVARIANT();
        }
        _update(baseBalance, quoteBalance, _baseReserves, _quoteReserves);
        emit Swap(msg.sender, baseAmountIn, quoteAmountIn, baseAmountOut, quoteAmountOut, to);
    }

    // force balances to match reserves
    function skim(address to) external nonReentrant {
        // store any variables used more than once in memory to avoid SLOAD"s
        address _base = base;
        address _quote = quote;
        // transfer unaccounted reserves -> "to"
        TransferHelper.safeTransfer(_base, to, ERC20(_base).balanceOf(address(this)) - baseReserves);
        TransferHelper.safeTransfer(_quote, to, ERC20(_quote).balanceOf(address(this)) - quoteReserves);
    }

    // force reserves to match balances
    function sync() external nonReentrant {
        _update(
            ERC20(base).balanceOf(address(this)),
            ERC20(quote).balanceOf(address(this)),
            baseReserves,
            quoteReserves
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                              INTERNAL HELPERS                              */
    /* -------------------------------------------------------------------------- */

    // unchecked division
    function uDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {assembly {z := div(x, y)}}

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {z = x < y ? x : y;}
}

// naming left for old contract support
interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

pragma solidity >=0.8.0;
contract UnipoolFactory {

    mapping(address => mapping(address => address)) private _getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    address public implementation = address(new Unipool());

    error IDENTICAL_ADDRESSES();
    error PAIR_ALREADY_EXISTS();
    error ZERO_ADDRESS();

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        if (tokenA == tokenB) revert IDENTICAL_ADDRESSES();
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (token0 == address(0)) revert ZERO_ADDRESS();
        if (_getPair[token0][token1] != address(0)) revert PAIR_ALREADY_EXISTS(); // single check is sufficient

        pair = cloneDeterministic(implementation, keccak256(abi.encodePacked(token0, token1)));
        Unipool(pair).initialize(token0, token1, 25);

        _getPair[token0][token1] = pair;
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function getPair(address tokenA, address tokenB) external view returns (address) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        return _getPair[token0][token1];
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    /* -------------------------------------------------------------------------- */
    /*                                CLONE LOGIC                                 */
    /* -------------------------------------------------------------------------- */

    function cloneDeterministic(address impl, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, impl))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }
}