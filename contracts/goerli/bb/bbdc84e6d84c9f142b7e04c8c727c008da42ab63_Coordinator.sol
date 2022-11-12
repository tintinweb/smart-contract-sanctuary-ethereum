// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "./lib/StructsAndEnums.sol";
import {ICustomer, Customer} from "./utils/Customer.sol";
import {Clones} from "@oz/proxy/Clones.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";

/**
 * @title Coordinator
 * @author waint.eth
 * @notice This is the Coordinator for the CurrentSDK. What this contract allows you to do
 *      is register yourself as a customer and add assets to your customer profile. When you
 *      register as a customer a new Customer.sol contract is created and you must deposit
 *      funds into that. The coordinator can then be executed to mint and deliver assets
 *      to your users wallets from the SDK. The function will then add balance to your fees
 *      and automatically withdraw funds from your customer contract via the Bill method.
 *      Essentially what we're doing is obfuscating what would be user required transactions
 *      to your customer profile so we can provide a seemless experience for the end user and
 *      cover the costs of your transactions through your Customer contract.
 */
contract Coordinator is KeeperCompatibleInterface {
    using SafeTransferLib for address;

    // Event: New customer is registered
    event CustomerRegistered(address customer, address controller);

    // Event: Assets are added to a customer profile.
    event AddedAssetsToCustomer(
        address customer,
        address[] additionalContracts,
        address[] updatedContracts
    );
    
    // Event: Adding fees to a customer.
    event AddedFeesToCustomer(address customer, uint256 amount);

    // Assets are minted to recipients
    event MintedAssets(PackageItem[] packages, address[] recipients);

    // Funds are withdrawn from this contract
    event Withdraw(address withdrawAddress, uint256 amount);

    // The owner of this contract has changed
    event OwnerChange(address newOwner);

    // Address for the customer logic
    address public immutable customerLogic;

    // CurrentSDK Registrar address
    address public immutable REGISTRAR;

    // Owner for withdrawing funds
    address payable public OWNER;

    // Required deposit for customers
    uint256 public initialDeposit = 0.1 ether;

    // List of which customers have outstanding debt
    address[] public paymentsDue;

    // Mapping of customers
    mapping(address => CustomerStruct) public customers;

    // Mapping of assets
    mapping(address => AssetContract) public assets;

    /**
     * @notice Confirms equal length of assets and itemtypes
     *
     * @param assetContracts Array of asset contract addresses
     * @param itemTypes Array of itemtypes to assign to asset contracts
     *
     */
    modifier equalAssetsAndTypes(
        address[] calldata assetContracts,
        ItemType[] calldata itemTypes
    ) {
        require(
            assetContracts.length == itemTypes.length,
            "Missatch in asset addresses and itemtypes"
        );
        _;
    }

    /**
     * @notice Constructor, sets the customerLogic, REGISTRAR, and OWNER
     *
     * @param _registrar Address of the CurrentSDK REGISTRAR
     *
     */
    constructor(address _registrar) {
        customerLogic = address(new Customer(address(this)));
        REGISTRAR = _registrar;
        OWNER = payable(_registrar);
    }

    /**
     * @notice Registers a new customer. This function creates a cloned
     *      customer contract and pre-loads 0.1ether in it. This is to ensure
     *      funds for initial contract calls.
     *
     * @param assetController Controller address for the customer assets.
     *
     */
    function registerCustomer(address assetController)
        public
        payable
        returns (address customer)
    {
        require(
            msg.value >= initialDeposit,
            "Incorrect msg.value, send >0.1 ether"
        );

        // Clone the customer contract and initialize with assetController
        customer = Clones.clone(customerLogic);
        ICustomer(customer).initialize(assetController);

        // Send some eth to the customer to initialize it
        customer.call{value: msg.value}("");

        // Finish adding the customer object to the registry
        customers[customer].eligible = true;
        emit CustomerRegistered(customer, assetController);
    }

    /**
     * @notice Register assets to a customer. When assets are registered, each time
     *      a function interacts with them, the Customer contract will be billed accordingly.
     *
     * @param assetController Controller address for the customer assets.
     * @param customerInvoice Customer invoice address to add the assets to.
     * @param assetContractAddresses Addresses of your Asset contracts
     * @param assetContractItemTypes ItemTypes of your Asset contracts
     *
     */
    function registerAssets(
        address assetController,
        address customerInvoice,
        address[] calldata assetContractAddresses,
        ItemType[] calldata assetContractItemTypes
    )
        public
        payable
        equalAssetsAndTypes(assetContractAddresses, assetContractItemTypes)
    {
        // Check validity, must be owner and eligible to add assets
        require(
            ICustomer(customerInvoice).getOwner() == msg.sender,
            "Not Invoice Owner"
        );
        require(
            customers[customerInvoice].eligible,
            "Customer Invoice is not eligible."
        );

        // Loop through all the contracts
        uint256 len = assetContractAddresses.length;
        for (uint8 i = 0; i < len; i++) {
            // Make sure asset isnt already registered
            require(
                !assets[assetContractAddresses[i]].eligible,
                "Asset is already registered."
            );

            // Build the asset object and store it
            assets[assetContractAddresses[i]] = AssetContract({
                customer: customerInvoice, // Who gets billed
                executor: assetController, // Who controlls
                itemType: assetContractItemTypes[i], // What asset type
                eligible: true
            });

            // Set the address in the customers mapping
            customers[customerInvoice].assetContracts.push(
                assetContractAddresses[i]
            );
        }

        emit AddedAssetsToCustomer(
            customerInvoice,
            assetContractAddresses,
            customers[customerInvoice].assetContracts
        );
    }

    /**
     * @notice Register as a new customer with assets. Combination of the above
     *      two functions.
     *
     * @param assetController Controller address for the customer assets.
     * @param assetContractAddresses Addresses of your Asset contracts
     * @param assetContractItemTypes ItemTypes of your Asset contracts
     *
     */
    function registerWithAssets(
        address assetController,
        address[] calldata assetContractAddresses,
        ItemType[] calldata assetContractItemTypes
    ) external payable returns (address customer) {
        // Generate new customer contract
        customer = registerCustomer(assetController);

        // Register the assets
        registerAssets(
            assetController,
            customer,
            assetContractAddresses,
            assetContractItemTypes
        );
    }

    /**
     * @notice Distribute assets to the users.
     *      TODO: Build this out. This requires a bit more thought than just
     *      minting assets to a user from a defined interface, so that will
     *      be the next step, figuring out how to distribute assets easily.
     *
     * @param packages PackageItem assets to mint to the users
     * @param recipients Addresses of the users to distribute to
     *
     */
    function distributeAssets(
        PackageItem[] calldata packages,
        address[] calldata recipients
    ) public {}

    /**
     * @notice Mint the assets to the users.
     *
     * @param packages PackageItem assets to mint to the users
     * @param recipients Addresses of the users to distribute to
     *
     */
    function mintAssets(
        PackageItem[] calldata packages,
        address[] calldata recipients
    ) public {
        uint256 packLen = packages.length;
        require(
            packLen == recipients.length,
            "Packages and recipients mismatch."
        );
        // Loop through all the packages
        for (uint256 i = 0; i < packLen; i++) {
            // Mint the package to the user
            require(
                assets[packages[i].token].eligible,
                "Contract not registered."
            );
            require(
                assets[packages[i].token].executor == msg.sender,
                "Not the asset executor."
            );
            _mintPackage(packages[i], recipients[i]);
        }
        emit MintedAssets(packages, recipients);
    }

    /**
     * @notice Mint a single asset to a user
     *
     * @param package PackageItem asset to mint to the users
     * @param recipient Addresses of the user to distribute to
     *
     * @dev right now this function uses a specific mint function in the CurrentNFT
     *      and CurrentToken contracts. In the future we will allow customers to create
     *      new contracts from this factory contract. Those contracts will have defined
     *      functionality that we need for this. Additionally, we will build a common
     *      interface for customers to build their own custom logic to add in.
     *      TODO: I realized this is inside a for loop, thats wasting a ton of gas,
     *      especially the reading of the customer from storage. Might be able to do that
     *      outside the for loop, but have to think about potentially different assets
     *      having different owners in the minting call.
     */
    function _mintPackage(PackageItem calldata package, address recipient)
        internal
    {
        // Check how much gas the minting costs and add to the customer bill
        uint256 gas = gasleft();
        address assetLocation = package.token;

        // TODO: More asset types, right now its limited
        // NATIVE
        // ERC1155
        // NONE

        // ERC20
        if (package.itemType == ItemType.ERC20) {
            bool success = IERC20(assetLocation).mint(
                recipient,
                package.amount
            );
            require(success, "Mint failed");
        }
        // ERC721
        if (package.itemType == ItemType.ERC721) {
            bool success = IERC721(assetLocation).mint(
                recipient,
                package.identifier
            );
            require(success, "Mint failed");
        }

        // Pull down the customer struct to edit the details
        CustomerStruct storage c = customers[assets[package.token].customer];
        if (c.setToBill != true) {
            c.setToBill = true;
            paymentsDue.push(assets[package.token].customer);
        }

        // Check gas left and add it to the fees of the customer
        gas -= gasleft();
        customers[assets[assetLocation].customer].feesDue += gas;
    }

    /**
     * @notice Get the encoded customers contracts
     *
     * @param invoiceAddress Invoice address to pull asset list from
     *
     */
    function getCustomerContractsEncoded(address invoiceAddress)
        public
        view
        returns (bytes memory)
    {
        return abi.encode(customers[invoiceAddress].assetContracts);
    }

    /**
     * @notice Get the customers contracts
     *
     * @param invoiceAddress Invoice address to pull asset list from
     *
     * @dev TODO: Cleanup these
     */
    function getCustomerContracts(address invoiceAddress)
        public
        view
        returns (address[] memory)
    {
        return customers[invoiceAddress].assetContracts;
    }

    /**
     * @notice Check the eligibility of a customers invoice address
     *
     * @param invoiceAddress Invoice address to check
     *
     */
    function getEligibility(address invoiceAddress) public view returns (bool) {
        return customers[invoiceAddress].eligible;
    }

    /**
     * @notice Chainlink functionality for checking upkeep
     *
     * @param checkData bytes to check.
     *
     */
    function checkUpkeep(bytes memory checkData)
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // Return data for the perform upkeep function
        // Encoded paymentdsDue array and a bool whether to check or not.
        return
            paymentsDue.length > 0
                ? (true, abi.encode(paymentsDue))
                : (false, abi.encode(paymentsDue));

        // If payments due has addresses in it, return true and the list in perform data
        // If not we go no billing required
        // In this instance upkeep is going to be charging customers wallets
    }

    /**
     * @notice Chainlink functionality for performing upkeep
     *
     * @param performData encoded addresses to bill.
     *
     * @dev nervous about the cost of this function. Should be okay with 5mil gas
     */
    function performUpkeep(bytes memory performData) external override {
        // Decode customer list
        address[] memory billedCustomers = abi.decode(performData, (address[]));

        // Confirm they're equal and no extra customers snuck in between blocks
        if (keccak256(abi.encode(paymentsDue)) != keccak256(performData)) {
            billedCustomers = paymentsDue;
        }

        // delete the paymentsDue array in this transaction so any following get caught
        delete paymentsDue;

        // TODO:
        // If this function is close to running out of gas, we need to add the remaining
        // customers to  paymentsDue so we can get them next time
        // Assuming this is running a lot this should eventually even out.
        // Bill the customers
        for (uint256 index = 0; index < billedCustomers.length; index++) {
            _billCustomer(billedCustomers[index]);
        }
    }

    /**
     * @notice Bills the customers invoice address. Essentially transfers
     *      funds based on how much they used distributing assets
     *
     * @param customer Customer address to bill
     *
     */
    function _billCustomer(address customer) internal {
        // Bill them and confirm
        bool success = ICustomer(customer).bill(customers[customer].feesDue);

        if (success) {
            // Set feesDue to 0 and setToBill to false
            customers[customer].feesDue = 0;
            customers[customer].setToBill = false;
        } else {
            // If it failed, add them back to the paymentsDue array
            paymentsDue.push(customer);

            // TODO: Add some logic to lock an account if its balance is too in debt
        }
    }

    /**
     * @notice Add the ability to add funds to a customers fees from the Registrar account.
     *
     *
     * @param customer Customer address to bill
     *
     * @dev This will need to be looked at and edited later. This is specifically for txs that
     *      are generated through the SDK but arent the mint or distribute tasks. We'll need to
     *      come back to this to make sure it cant be manipulated and abused.
     */
    function addFeesToCustomer(address customer, uint256 amount) external {
        // TODO: Custom error
        require(msg.sender == REGISTRAR, "Not the registrar calling.");

        if (customers[customer].setToBill == false) {
            customers[customer].setToBill = true;
            paymentsDue.push(customer);
        }

        customers[customer].feesDue += amount;
        emit AddedFeesToCustomer(customer, amount);
    }

    /**
     * @notice Helper to get encoded paymentsDue
     */
    function getEncodedRequiredBills() public view returns (bytes memory) {
        return abi.encode(paymentsDue);
    }

    /**
     * @notice Set the owner of the contract for withdraw
     *
     *
     * @param newOwner address of the new owner of the contract
     *
     */
    function setOwner(address payable newOwner) public {
        require(msg.sender == OWNER, "Not the owner");
        OWNER = newOwner;
        emit OwnerChange(OWNER);
    }

    /**
     * @notice Withdraw funds from this contract
     *
     * @dev this contract should only hold funds from fees collected
     */
    function withdraw() public {
        emit Withdraw(OWNER, address(this).balance);
        address(OWNER).safeTransferETH(address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}
}

interface IERC20 {
    function mint(address to, uint256 amount) external returns (bool);
}

interface IERC721 {
    function mint(address to, uint256 identifier) external returns (bool);
}

pragma solidity ^0.8.0;

// Bringing the basic asset structs from my protocol:
// https://github.com/eucliss/Basin/blob/master/src/contracts/lib/StructsAndEnums.sol
// https://github.com/eucliss/Basin/

enum ItemType {
    NATIVE,
    ERC20,
    ERC721,
    ERC1155,
    NONE
}

struct PackageItem {
    ItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
}

struct CustomerStruct {
    uint256 feesDue;
    address gameContract;
    bool eligible;
    bool setToBill;
    address[] assetContracts;
}

struct AssetContract {
    address customer;
    address executor;
    ItemType itemType;
    bool eligible;
}

pragma solidity ^0.8.14;

import "@oz/proxy/utils/Initializable.sol";

// Customer interface
interface ICustomer {
    function initialize(address owner) external;

    function deposit() external payable;

    function bill(uint256 amount) external returns (bool success);

    function getOwner() external returns (address owner);
}

/**
 * @title Customer
 * @author waint.eth
 * @notice This contract is the Customer contract for the CurrentSDK Coordinator. New customers
 *      are registered and it creates a clone of this contract. This contract allows a customer
 *      to fund through the deposit function, and allows the Coordinator to bill them through
 *      the bill function for their usage on Coordinator or in the SDK. Customers must fund
 *      this contract in order to use the Coordinator and the functionality in the SDK.
 */
contract Customer is ICustomer, Initializable {
    // @notice event for when a deposit occurs and who sent it.
    event DepositSuccessful(address sender, uint256 amount);

    // Immutable address for the coordinator
    address public immutable coordinator;

    // Address of who owns this contract
    address public owner;

    // balance of this contract
    // @dev I dont think this is necessary, may come back after hackathon.
    uint256 public balance = 0;

    /**
     * @notice Constructor sets the immutable coordinator address.
     */
    constructor(address _coordinator) {
        coordinator = _coordinator;
    }

    /**
     * @notice Initialization function
     *
     * @param _owner Owner of the contract, this is set from Coordinator.sol
     *
     */
    function initialize(address _owner) public override initializer {
        owner = _owner;
    }

    /**
     * @notice Deposit function for depositing ether into this contract.
     *
     */
    function deposit() public payable override {
        // Maybe want to expand to other ERCs?
        balance += msg.value;
        emit DepositSuccessful(msg.sender, msg.value);
    }

    /**
     * @notice Billing function for Coordinator to withdraw funds for usage.
     *
     * @param amount how much needs to be withdrawn from this contract.
     *
     */
    function bill(uint256 amount) external override returns (bool success) {
        require(msg.sender == coordinator, "NOT COORDINATOR");
        if (amount > balance) {
            return false;
        } else {
            // No re-entry cause we know what coordinator does on recieve.
            (success, ) = address(coordinator).call{value: amount}("");
            if (success) {
                balance -= amount;
            }
            return true;
        }
    }

    /**
     * @notice Gets the owner of this contract.
     *
     * @dev probably can be deleted...
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    /**
     * @dev just in case someone sends to the address instead of using deposit.
     */
    receive() external payable {
        require(msg.value > 0, "NO ETH SENT");
        deposit();
    }
}