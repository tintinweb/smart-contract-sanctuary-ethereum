/**
 *Submitted for verification at Etherscan.io on 2022-03-03
*/

// hevm: flattened sources of src/DelphiFactoryV1.sol
// SPDX-License-Identifier: MIT AND AGPL-3.0-only AND GPL-3.0-or-later
pragma solidity >=0.8.0 >=0.8.0 <0.9.0 >=0.8.1 <0.9.0 >=0.8.6 <0.9.0;

////// lib/chainlink/contracts/src/v0.8//interfaces/AggregatorV3Interface.sol
/* pragma solidity ^0.8.0; */

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

////// lib/openzeppelin-contracts/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/* pragma solidity ^0.8.0; */

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

////// lib/openzeppelin-contracts/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

/* pragma solidity ^0.8.0; */

/* import "../utils/Context.sol"; */

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
}

////// lib/openzeppelin-contracts/contracts/utils/Address.sol
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

/* pragma solidity ^0.8.1; */

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

////// lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

/* pragma solidity ^0.8.0; */

/* import "../../utils/Address.sol"; */

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
        return !Address.isContract(address(this));
    }
}

////// lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

/* pragma solidity ^0.8.0; */

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

////// lib/solmate/src//utils/Bytes32AddressLib.sol
/* pragma solidity >=0.8.0; */

/// @notice Library for converting between addresses and bytes32 values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/Bytes32AddressLib.sol)
library Bytes32AddressLib {
    function fromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function fillLast12Bytes(address addressValue) internal pure returns (bytes32) {
        return bytes32(bytes20(addressValue));
    }
}

////// lib/solmate/src//utils/CREATE3.sol
/* pragma solidity >=0.8.0; */

/* import {Bytes32AddressLib} from "./Bytes32AddressLib.sol"; */

/// @notice Deploy to deterministic addresses without an initcode factor.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/CREATE3.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/create3/blob/master/contracts/Create3.sol)
library CREATE3 {
    using Bytes32AddressLib for bytes32;

    //--------------------------------------------------------------------------------//
    // Opcode     | Opcode + Arguments    | Description      | Stack View             //
    //--------------------------------------------------------------------------------//
    // 0x36       |  0x36                 | CALLDATASIZE     | size                   //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 size                 //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 0 size               //
    // 0x37       |  0x37                 | CALLDATACOPY     |                        //
    // 0x36       |  0x36                 | CALLDATASIZE     | size                   //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 size                 //
    // 0x34       |  0x34                 | CALLVALUE        | value 0 size           //
    // 0xf0       |  0xf0                 | CREATE           | newContract            //
    //--------------------------------------------------------------------------------//
    // Opcode     | Opcode + Arguments    | Description      | Stack View             //
    //--------------------------------------------------------------------------------//
    // 0x67       |  0x67XXXXXXXXXXXXXXXX | PUSH8 bytecode   | bytecode               //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 bytecode             //
    // 0x52       |  0x52                 | MSTORE           |                        //
    // 0x60       |  0x6008               | PUSH1 08         | 8                      //
    // 0x60       |  0x6018               | PUSH1 18         | 24 8                   //
    // 0xf3       |  0xf3                 | RETURN           |                        //
    //--------------------------------------------------------------------------------//
    bytes internal constant PROXY_BYTECODE = hex"67_36_3d_3d_37_36_3d_34_f0_3d_52_60_08_60_18_f3";

    bytes32 internal constant PROXY_BYTECODE_HASH = keccak256(PROXY_BYTECODE);

    function deploy(
        bytes32 salt,
        bytes memory creationCode,
        uint256 value
    ) internal returns (address deployed) {
        bytes memory proxyChildBytecode = PROXY_BYTECODE;

        address proxy;
        assembly {
        // Deploy a new contract with our pre-made bytecode via CREATE2.
        // We start 32 bytes into the code to avoid copying the byte length.
            proxy := create2(0, add(proxyChildBytecode, 32), mload(proxyChildBytecode), salt)
        }
        require(proxy != address(0), "DEPLOYMENT_FAILED");

        deployed = getDeployed(salt);
        (bool success, ) = proxy.call{value: value}(creationCode);
        require(success && deployed.code.length != 0, "INITIALIZATION_FAILED");
    }

    function getDeployed(bytes32 salt) internal view returns (address) {
        address proxy = keccak256(
            abi.encodePacked(
            // Prefix:
                bytes1(0xFF),
            // Creator:
                address(this),
            // Salt:
                salt,
            // Bytecode hash:
                PROXY_BYTECODE_HASH
            )
        ).fromLast20Bytes();

        return
        keccak256(
            abi.encodePacked(
            // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01)
            // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex)
                hex"d6_94",
                proxy,
                hex"01" // Nonce of the proxy contract (1)
            )
        ).fromLast20Bytes();
    }
}

////// src/math/BancorPower.sol
/* pragma solidity ^0.8.6; */

/* import "@openzeppelin/utils/math/SafeMath.sol"; */

/**
 * @title BancorPower, modified from the original "BancorFomula.sol"
 *        written by Bancor https://github.com/bancorprotocol/contracts
 *
 * @dev Changes include:
 *  1. Remove Bancor's specific functions and replace SafeMath with OpenZeppelin's.
 *  2. Change code from Contract to Library and change maxExpArray from being array
 *     with binary search inside `findPositionInMaxExpArray` to a simple linear search.
 *  3. Add requirement check that baseN >= baseD (this is always true for Bancor).
 * Licensed under Apache Lisense, Version 2.0.
 */
library BancorPower {
    using SafeMath for uint256;

    string internal constant version = '0.3';
    uint256 private constant ONE = 1;
    uint32 private constant MAX_WEIGHT = 1000000;
    uint8 private constant MIN_PRECISION = 32;
    uint8 private constant MAX_PRECISION = 127;

    /**
        Auto-generated via 'PrintIntScalingFactors.py'
    */
    uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint256 private constant MAX_NUM = 0x200000000000000000000000000000000;

    /**
        Auto-generated via 'PrintLn2ScalingFactors.py'
    */
    uint256 private constant LN2_NUMERATOR   = 0x3f80fe03f80fe03f80fe03f80fe03f8;
    uint256 private constant LN2_DENOMINATOR = 0x5b9de1d10bf4103d647b0955897ba80;

    /**
        Auto-generated via 'PrintFunctionOptimalLog.py' and 'PrintFunctionOptimalExp.py'
    */
    uint256 private constant OPT_LOG_MAX_VAL = 0x15bf0a8b1457695355fb8ac404e7a79e3;
    uint256 private constant OPT_EXP_MAX_VAL = 0x800000000000000000000000000000000;

    /**
        General Description:
            Determine a value of precision.
            Calculate an integer approximation of (_baseN / _baseD) ^ (_expN / _expD) * 2 ^ precision.
            Return the result along with the precision used.
        Detailed Description:
            Instead of calculating "base ^ exp", we calculate "e ^ (log(base) * exp)".
            The value of "log(base)" is represented with an integer slightly smaller than "log(base) * 2 ^ precision".
            The larger "precision" is, the more accurately this value represents the real value.
            However, the larger "precision" is, the more bits are required in order to store this value.
            And the exponentiation function, which takes "x" and calculates "e ^ x", is limited to a maximum exponent (maximum value of "x").
            This maximum exponent depends on the "precision" used, and it is given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
            Hence we need to determine the highest precision which can be used for the given input, before calling the exponentiation function.
            This allows us to compute "base ^ exp" with maximum accuracy and without exceeding 256 bits in any of the intermediate computations.
            This functions assumes that "_expN < 2 ^ 256 / log(MAX_NUM - 1)", otherwise the multiplication should be replaced with a "safeMul".
    */
    function power(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) internal pure returns (uint256, uint8) {
        require(_baseN < MAX_NUM);
        require(_baseN >= _baseD);

        uint256 baseLog;
        uint256 base = _baseN * FIXED_1 / _baseD;
        if (base < OPT_LOG_MAX_VAL) {
            baseLog = optimalLog(base);
        }
        else {
            baseLog = generalLog(base);
        }

        uint256 baseLogTimesExp = baseLog * _expN / _expD;
        if (baseLogTimesExp < OPT_EXP_MAX_VAL) {
            return (optimalExp(baseLogTimesExp), MAX_PRECISION);
        }
        else {
            uint8 precision = findPositionInMaxExpArray(baseLogTimesExp);
            return (generalExp(baseLogTimesExp >> (MAX_PRECISION - precision), precision), precision);
        }
    }

    /**
    *   c >= 10^18
    *
     */
    function log(uint256 _c, uint256 _baseN, uint256 _baseD) internal pure returns (uint256) {
        // require(_baseN < MAX_NUM)
        require(_baseN >= _baseD);

        uint256 baseLog;
        uint256 base = _baseN * FIXED_1 / _baseD;
        if (base < OPT_LOG_MAX_VAL) {
            baseLog = optimalLog(base);
        } else {
            baseLog = generalLog(base);
        }

        return (baseLog * _c) / FIXED_1;
    }

    /**
        Compute log(x / FIXED_1) * FIXED_1.
        This functions assumes that "x >= FIXED_1", because the output would be negative otherwise.
    */
    function generalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        // If x >= 2, then we compute the integer part of log2(x), which is larger than 0.
        if (x >= FIXED_2) {
            uint8 count = floorLog2(x / FIXED_1);
            x >>= count; // now x < 2
            res = count * FIXED_1;
        }

        // If x > 1, then we compute the fraction part of log2(x), which is larger than 0.
        if (x > FIXED_1) {
            for (uint8 i = MAX_PRECISION; i > 0; --i) {
                x = (x * x) / FIXED_1; // now 1 < x < 4
                if (x >= FIXED_2) {
                    x >>= 1; // now 1 < x < 2
                    res += ONE << (i - 1);
                }
            }
        }

        return res * LN2_NUMERATOR / LN2_DENOMINATOR;
    }

    /**
        Compute the largest integer smaller than or equal to the binary logarithm of the input.
    */
    function floorLog2(uint256 _n) internal pure returns (uint8) {
        uint8 res = 0;

        if (_n < 256) {
            // At most 8 iterations
            while (_n > 1) {
                _n >>= 1;
                res += 1;
            }
        }
        else {
            // Exactly 8 iterations
            for (uint8 s = 128; s > 0; s >>= 1) {
                if (_n >= (ONE << s)) {
                    _n >>= s;
                    res |= s;
                }
            }
        }

        return res;
    }

    /**
        The global "maxExpArray" is sorted in descending order, and therefore the following statements are equivalent:
        - This function finds the position of [the smallest value in "maxExpArray" larger than or equal to "x"]
        - This function finds the highest position of [a value in "maxExpArray" larger than or equal to "x"]
    */
    function findPositionInMaxExpArray(uint256 _x) internal pure returns (uint8) {
        if (0x1c35fedd14ffffffffffffffffffffffff >= _x) return  32;
        if (0x1b0ce43b323fffffffffffffffffffffff >= _x) return  33;
        if (0x19f0028ec1ffffffffffffffffffffffff >= _x) return  34;
        if (0x18ded91f0e7fffffffffffffffffffffff >= _x) return  35;
        if (0x17d8ec7f0417ffffffffffffffffffffff >= _x) return  36;
        if (0x16ddc6556cdbffffffffffffffffffffff >= _x) return  37;
        if (0x15ecf52776a1ffffffffffffffffffffff >= _x) return  38;
        if (0x15060c256cb2ffffffffffffffffffffff >= _x) return  39;
        if (0x1428a2f98d72ffffffffffffffffffffff >= _x) return  40;
        if (0x13545598e5c23fffffffffffffffffffff >= _x) return  41;
        if (0x1288c4161ce1dfffffffffffffffffffff >= _x) return  42;
        if (0x11c592761c666fffffffffffffffffffff >= _x) return  43;
        if (0x110a688680a757ffffffffffffffffffff >= _x) return  44;
        if (0x1056f1b5bedf77ffffffffffffffffffff >= _x) return  45;
        if (0x0faadceceeff8bffffffffffffffffffff >= _x) return  46;
        if (0x0f05dc6b27edadffffffffffffffffffff >= _x) return  47;
        if (0x0e67a5a25da4107fffffffffffffffffff >= _x) return  48;
        if (0x0dcff115b14eedffffffffffffffffffff >= _x) return  49;
        if (0x0d3e7a392431239fffffffffffffffffff >= _x) return  50;
        if (0x0cb2ff529eb71e4fffffffffffffffffff >= _x) return  51;
        if (0x0c2d415c3db974afffffffffffffffffff >= _x) return  52;
        if (0x0bad03e7d883f69bffffffffffffffffff >= _x) return  53;
        if (0x0b320d03b2c343d5ffffffffffffffffff >= _x) return  54;
        if (0x0abc25204e02828dffffffffffffffffff >= _x) return  55;
        if (0x0a4b16f74ee4bb207fffffffffffffffff >= _x) return  56;
        if (0x09deaf736ac1f569ffffffffffffffffff >= _x) return  57;
        if (0x0976bd9952c7aa957fffffffffffffffff >= _x) return  58;
        if (0x09131271922eaa606fffffffffffffffff >= _x) return  59;
        if (0x08b380f3558668c46fffffffffffffffff >= _x) return  60;
        if (0x0857ddf0117efa215bffffffffffffffff >= _x) return  61;
        if (0x07ffffffffffffffffffffffffffffffff >= _x) return  62;
        if (0x07abbf6f6abb9d087fffffffffffffffff >= _x) return  63;
        if (0x075af62cbac95f7dfa7fffffffffffffff >= _x) return  64;
        if (0x070d7fb7452e187ac13fffffffffffffff >= _x) return  65;
        if (0x06c3390ecc8af379295fffffffffffffff >= _x) return  66;
        if (0x067c00a3b07ffc01fd6fffffffffffffff >= _x) return  67;
        if (0x0637b647c39cbb9d3d27ffffffffffffff >= _x) return  68;
        if (0x05f63b1fc104dbd39587ffffffffffffff >= _x) return  69;
        if (0x05b771955b36e12f7235ffffffffffffff >= _x) return  70;
        if (0x057b3d49dda84556d6f6ffffffffffffff >= _x) return  71;
        if (0x054183095b2c8ececf30ffffffffffffff >= _x) return  72;
        if (0x050a28be635ca2b888f77fffffffffffff >= _x) return  73;
        if (0x04d5156639708c9db33c3fffffffffffff >= _x) return  74;
        if (0x04a23105873875bd52dfdfffffffffffff >= _x) return  75;
        if (0x0471649d87199aa990756fffffffffffff >= _x) return  76;
        if (0x04429a21a029d4c1457cfbffffffffffff >= _x) return  77;
        if (0x0415bc6d6fb7dd71af2cb3ffffffffffff >= _x) return  78;
        if (0x03eab73b3bbfe282243ce1ffffffffffff >= _x) return  79;
        if (0x03c1771ac9fb6b4c18e229ffffffffffff >= _x) return  80;
        if (0x0399e96897690418f785257fffffffffff >= _x) return  81;
        if (0x0373fc456c53bb779bf0ea9fffffffffff >= _x) return  82;
        if (0x034f9e8e490c48e67e6ab8bfffffffffff >= _x) return  83;
        if (0x032cbfd4a7adc790560b3337ffffffffff >= _x) return  84;
        if (0x030b50570f6e5d2acca94613ffffffffff >= _x) return  85;
        if (0x02eb40f9f620fda6b56c2861ffffffffff >= _x) return  86;
        if (0x02cc8340ecb0d0f520a6af58ffffffffff >= _x) return  87;
        if (0x02af09481380a0a35cf1ba02ffffffffff >= _x) return  88;
        if (0x0292c5bdd3b92ec810287b1b3fffffffff >= _x) return  89;
        if (0x0277abdcdab07d5a77ac6d6b9fffffffff >= _x) return  90;
        if (0x025daf6654b1eaa55fd64df5efffffffff >= _x) return  91;
        if (0x0244c49c648baa98192dce88b7ffffffff >= _x) return  92;
        if (0x022ce03cd5619a311b2471268bffffffff >= _x) return  93;
        if (0x0215f77c045fbe885654a44a0fffffffff >= _x) return  94;
        if (0x01ffffffffffffffffffffffffffffffff >= _x) return  95;
        if (0x01eaefdbdaaee7421fc4d3ede5ffffffff >= _x) return  96;
        if (0x01d6bd8b2eb257df7e8ca57b09bfffffff >= _x) return  97;
        if (0x01c35fedd14b861eb0443f7f133fffffff >= _x) return  98;
        if (0x01b0ce43b322bcde4a56e8ada5afffffff >= _x) return  99;
        if (0x019f0028ec1fff007f5a195a39dfffffff >= _x) return 100;
        if (0x018ded91f0e72ee74f49b15ba527ffffff >= _x) return 101;
        if (0x017d8ec7f04136f4e5615fd41a63ffffff >= _x) return 102;
        if (0x016ddc6556cdb84bdc8d12d22e6fffffff >= _x) return 103;
        if (0x015ecf52776a1155b5bd8395814f7fffff >= _x) return 104;
        if (0x015060c256cb23b3b3cc3754cf40ffffff >= _x) return 105;
        if (0x01428a2f98d728ae223ddab715be3fffff >= _x) return 106;
        if (0x013545598e5c23276ccf0ede68034fffff >= _x) return 107;
        if (0x01288c4161ce1d6f54b7f61081194fffff >= _x) return 108;
        if (0x011c592761c666aa641d5a01a40f17ffff >= _x) return 109;
        if (0x0110a688680a7530515f3e6e6cfdcdffff >= _x) return 110;
        if (0x01056f1b5bedf75c6bcb2ce8aed428ffff >= _x) return 111;
        if (0x00faadceceeff8a0890f3875f008277fff >= _x) return 112;
        if (0x00f05dc6b27edad306388a600f6ba0bfff >= _x) return 113;
        if (0x00e67a5a25da41063de1495d5b18cdbfff >= _x) return 114;
        if (0x00dcff115b14eedde6fc3aa5353f2e4fff >= _x) return 115;
        if (0x00d3e7a3924312399f9aae2e0f868f8fff >= _x) return 116;
        if (0x00cb2ff529eb71e41582cccd5a1ee26fff >= _x) return 117;
        if (0x00c2d415c3db974ab32a51840c0b67edff >= _x) return 118;
        if (0x00bad03e7d883f69ad5b0a186184e06bff >= _x) return 119;
        if (0x00b320d03b2c343d4829abd6075f0cc5ff >= _x) return 120;
        if (0x00abc25204e02828d73c6e80bcdb1a95bf >= _x) return 121;
        if (0x00a4b16f74ee4bb2040a1ec6c15fbbf2df >= _x) return 122;
        if (0x009deaf736ac1f569deb1b5ae3f36c130f >= _x) return 123;
        if (0x00976bd9952c7aa957f5937d790ef65037 >= _x) return 124;
        if (0x009131271922eaa6064b73a22d0bd4f2bf >= _x) return 125;
        if (0x008b380f3558668c46c91c49a2f8e967b9 >= _x) return 126;
        if (0x00857ddf0117efa215952912839f6473e6 >= _x) return 127;
        require(false);
        return 0;
    }

    /**
        This function can be auto-generated by the script 'PrintFunctionGeneralExp.py'.
        It approximates "e ^ x" via maclaurin summation: "(x^0)/0! + (x^1)/1! + ... + (x^n)/n!".
        It returns "e ^ (x / 2 ^ precision) * 2 ^ precision", that is, the result is upshifted for accuracy.
        The global "maxExpArray" maps each "precision" to "((maximumExponent + 1) << (MAX_PRECISION - precision)) - 1".
        The maximum permitted value for "x" is therefore given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
    */
    function generalExp(uint256 _x, uint8 _precision) internal pure returns (uint256) {
        uint256 xi = _x;
        uint256 res = 0;

        xi = (xi * _x) >> _precision; res += xi * 0x3442c4e6074a82f1797f72ac0000000; // add x^02 * (33! / 02!)
        xi = (xi * _x) >> _precision; res += xi * 0x116b96f757c380fb287fd0e40000000; // add x^03 * (33! / 03!)
        xi = (xi * _x) >> _precision; res += xi * 0x045ae5bdd5f0e03eca1ff4390000000; // add x^04 * (33! / 04!)
        xi = (xi * _x) >> _precision; res += xi * 0x00defabf91302cd95b9ffda50000000; // add x^05 * (33! / 05!)
        xi = (xi * _x) >> _precision; res += xi * 0x002529ca9832b22439efff9b8000000; // add x^06 * (33! / 06!)
        xi = (xi * _x) >> _precision; res += xi * 0x00054f1cf12bd04e516b6da88000000; // add x^07 * (33! / 07!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000a9e39e257a09ca2d6db51000000; // add x^08 * (33! / 08!)
        xi = (xi * _x) >> _precision; res += xi * 0x000012e066e7b839fa050c309000000; // add x^09 * (33! / 09!)
        xi = (xi * _x) >> _precision; res += xi * 0x000001e33d7d926c329a1ad1a800000; // add x^10 * (33! / 10!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000002bee513bdb4a6b19b5f800000; // add x^11 * (33! / 11!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000003a9316fa79b88eccf2a00000; // add x^12 * (33! / 12!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000048177ebe1fa812375200000; // add x^13 * (33! / 13!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000005263fe90242dcbacf00000; // add x^14 * (33! / 14!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000057e22099c030d94100000; // add x^15 * (33! / 15!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000057e22099c030d9410000; // add x^16 * (33! / 16!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000052b6b54569976310000; // add x^17 * (33! / 17!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000004985f67696bf748000; // add x^18 * (33! / 18!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000003dea12ea99e498000; // add x^19 * (33! / 19!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000031880f2214b6e000; // add x^20 * (33! / 20!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000000025bcff56eb36000; // add x^21 * (33! / 21!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000000001b722e10ab1000; // add x^22 * (33! / 22!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000001317c70077000; // add x^23 * (33! / 23!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000cba84aafa00; // add x^24 * (33! / 24!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000082573a0a00; // add x^25 * (33! / 25!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000005035ad900; // add x^26 * (33! / 26!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000000000000002f881b00; // add x^27 * (33! / 27!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000001b29340; // add x^28 * (33! / 28!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000000000efc40; // add x^29 * (33! / 29!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000007fe0; // add x^30 * (33! / 30!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000420; // add x^31 * (33! / 31!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000021; // add x^32 * (33! / 32!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000001; // add x^33 * (33! / 33!)

        return res / 0x688589cc0e9505e2f2fee5580000000 + _x + (ONE << _precision); // divide by 33! and then add x^1 / 1! + x^0 / 0!
    }

    /**
        Return log(x / FIXED_1) * FIXED_1
        Input range: FIXED_1 <= x <= LOG_EXP_MAX_VAL - 1
        Auto-generated via 'PrintFunctionOptimalLog.py'
        Detailed description:
        - Rewrite the input as a product of natural exponents and a single residual r, such that 1 < r < 2
        - The natural logarithm of each (pre-calculated) exponent is the degree of the exponent
        - The natural logarithm of r is calculated via Taylor series for log(1 + x), where x = r - 1
        - The natural logarithm of the input is calculated by summing up the intermediate results above
        - For example: log(250) = log(e^4 * e^1 * e^0.5 * 1.021692859) = 4 + 1 + 0.5 + log(1 + 0.021692859)
    */
    function optimalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;
        uint256 w;

        if (x >= 0xd3094c70f034de4b96ff7d5b6f99fcd8) {res += 0x40000000000000000000000000000000; x = x * FIXED_1 / 0xd3094c70f034de4b96ff7d5b6f99fcd8;} // add 1 / 2^1
        if (x >= 0xa45af1e1f40c333b3de1db4dd55f29a7) {res += 0x20000000000000000000000000000000; x = x * FIXED_1 / 0xa45af1e1f40c333b3de1db4dd55f29a7;} // add 1 / 2^2
        if (x >= 0x910b022db7ae67ce76b441c27035c6a1) {res += 0x10000000000000000000000000000000; x = x * FIXED_1 / 0x910b022db7ae67ce76b441c27035c6a1;} // add 1 / 2^3
        if (x >= 0x88415abbe9a76bead8d00cf112e4d4a8) {res += 0x08000000000000000000000000000000; x = x * FIXED_1 / 0x88415abbe9a76bead8d00cf112e4d4a8;} // add 1 / 2^4
        if (x >= 0x84102b00893f64c705e841d5d4064bd3) {res += 0x04000000000000000000000000000000; x = x * FIXED_1 / 0x84102b00893f64c705e841d5d4064bd3;} // add 1 / 2^5
        if (x >= 0x8204055aaef1c8bd5c3259f4822735a2) {res += 0x02000000000000000000000000000000; x = x * FIXED_1 / 0x8204055aaef1c8bd5c3259f4822735a2;} // add 1 / 2^6
        if (x >= 0x810100ab00222d861931c15e39b44e99) {res += 0x01000000000000000000000000000000; x = x * FIXED_1 / 0x810100ab00222d861931c15e39b44e99;} // add 1 / 2^7
        if (x >= 0x808040155aabbbe9451521693554f733) {res += 0x00800000000000000000000000000000; x = x * FIXED_1 / 0x808040155aabbbe9451521693554f733;} // add 1 / 2^8

        z = y = x - FIXED_1;
        w = y * y / FIXED_1;
        res += z * (0x100000000000000000000000000000000 - y) / 0x100000000000000000000000000000000; z = z * w / FIXED_1; // add y^01 / 01 - y^02 / 02
        res += z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y) / 0x200000000000000000000000000000000; z = z * w / FIXED_1; // add y^03 / 03 - y^04 / 04
        res += z * (0x099999999999999999999999999999999 - y) / 0x300000000000000000000000000000000; z = z * w / FIXED_1; // add y^05 / 05 - y^06 / 06
        res += z * (0x092492492492492492492492492492492 - y) / 0x400000000000000000000000000000000; z = z * w / FIXED_1; // add y^07 / 07 - y^08 / 08
        res += z * (0x08e38e38e38e38e38e38e38e38e38e38e - y) / 0x500000000000000000000000000000000; z = z * w / FIXED_1; // add y^09 / 09 - y^10 / 10
        res += z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y) / 0x600000000000000000000000000000000; z = z * w / FIXED_1; // add y^11 / 11 - y^12 / 12
        res += z * (0x089d89d89d89d89d89d89d89d89d89d89 - y) / 0x700000000000000000000000000000000; z = z * w / FIXED_1; // add y^13 / 13 - y^14 / 14
        res += z * (0x088888888888888888888888888888888 - y) / 0x800000000000000000000000000000000;                      // add y^15 / 15 - y^16 / 16

        return res;
    }

    /**
        Return e ^ (x / FIXED_1) * FIXED_1
        Input range: 0 <= x <= OPT_EXP_MAX_VAL - 1
        Auto-generated via 'PrintFunctionOptimalExp.py'
        Detailed description:
        - Rewrite the input as a sum of binary exponents and a single residual r, as small as possible
        - The exponentiation of each binary exponent is given (pre-calculated)
        - The exponentiation of r is calculated via Taylor series for e^x, where x = r
        - The exponentiation of the input is calculated by multiplying the intermediate results above
        - For example: e^5.021692859 = e^(4 + 1 + 0.5 + 0.021692859) = e^4 * e^1 * e^0.5 * e^0.021692859
    */
    function optimalExp(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;

        z = y = x % 0x10000000000000000000000000000000; // get the input modulo 2^(-3)
        z = z * y / FIXED_1; res += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
        z = z * y / FIXED_1; res += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
        z = z * y / FIXED_1; res += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
        z = z * y / FIXED_1; res += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
        z = z * y / FIXED_1; res += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
        z = z * y / FIXED_1; res += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
        z = z * y / FIXED_1; res += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
        z = z * y / FIXED_1; res += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
        z = z * y / FIXED_1; res += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
        z = z * y / FIXED_1; res += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
        z = z * y / FIXED_1; res += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
        z = z * y / FIXED_1; res += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
        z = z * y / FIXED_1; res += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
        z = z * y / FIXED_1; res += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
        z = z * y / FIXED_1; res += z * 0x000000000001c638; // add y^16 * (20! / 16!)
        z = z * y / FIXED_1; res += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
        z = z * y / FIXED_1; res += z * 0x000000000000017c; // add y^18 * (20! / 18!)
        z = z * y / FIXED_1; res += z * 0x0000000000000014; // add y^19 * (20! / 19!)
        z = z * y / FIXED_1; res += z * 0x0000000000000001; // add y^20 * (20! / 20!)
        res = res / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

        if ((x & 0x010000000000000000000000000000000) != 0) res = res * 0x1c3d6a24ed82218787d624d3e5eba95f9 / 0x18ebef9eac820ae8682b9793ac6d1e776; // multiply by e^2^(-3)
        if ((x & 0x020000000000000000000000000000000) != 0) res = res * 0x18ebef9eac820ae8682b9793ac6d1e778 / 0x1368b2fc6f9609fe7aceb46aa619baed4; // multiply by e^2^(-2)
        if ((x & 0x040000000000000000000000000000000) != 0) res = res * 0x1368b2fc6f9609fe7aceb46aa619baed5 / 0x0bc5ab1b16779be3575bd8f0520a9f21f; // multiply by e^2^(-1)
        if ((x & 0x080000000000000000000000000000000) != 0) res = res * 0x0bc5ab1b16779be3575bd8f0520a9f21e / 0x0454aaa8efe072e7f6ddbab84b40a55c9; // multiply by e^2^(+0)
        if ((x & 0x100000000000000000000000000000000) != 0) res = res * 0x0454aaa8efe072e7f6ddbab84b40a55c5 / 0x00960aadc109e7a3bf4578099615711ea; // multiply by e^2^(+1)
        if ((x & 0x200000000000000000000000000000000) != 0) res = res * 0x00960aadc109e7a3bf4578099615711d7 / 0x0002bf84208204f5977f9a8cf01fdce3d; // multiply by e^2^(+2)
        if ((x & 0x400000000000000000000000000000000) != 0) res = res * 0x0002bf84208204f5977f9a8cf01fdc307 / 0x0000003c6ab775dd0b95b4cbee7e65d11; // multiply by e^2^(+3)

        return res;
    }
}

////// src/math/Equation.sol
/* pragma solidity ^0.8.6; */

/* import "@openzeppelin/utils/math/SafeMath.sol"; */
/* import "./BancorPower.sol"; */

library Equation {
    using SafeMath for uint256;

    /// An expression tree is encoded as a set of nodes, with root node having index zero. Each node has 3 values:
    ///  1. opcode: the expression that the node represents. See table below.
    /// +--------+----------------------------------------+------+------------+
    /// | Opcode |              Description               | i.e. | # children |
    /// +--------+----------------------------------------+------+------------+
    /// |   00   | Integer Constant                       |   c  |      0     |
    /// |   01   | Variable                               |   X  |      0     |
    /// |   02   | Arithmetic Square Root                 |   √  |      1     |
    /// |   03   | Boolean Not Condition                  |   !  |      1     |
    /// |   04   | Arithmetic Addition                    |   +  |      2     |
    /// |   05   | Arithmetic Subtraction                 |   -  |      2     |
    /// |   06   | Arithmetic Multiplication              |   *  |      2     |
    /// |   07   | Arithmetic Division                    |   /  |      2     |
    /// |   08   | Arithmetic Exponentiation              |  **  |      2     |
    /// |   09   | Arithmetic Percentage* (see below)     |   %  |      2     |
    /// |   10   | Arithmetic Equal Comparison            |  ==  |      2     |
    /// |   11   | Arithmetic Non-Equal Comparison        |  !=  |      2     |
    /// |   12   | Arithmetic Less-Than Comparison        |  <   |      2     |
    /// |   13   | Arithmetic Greater-Than Comparison     |  >   |      2     |
    /// |   14   | Arithmetic Non-Greater-Than Comparison |  <=  |      2     |
    /// |   15   | Arithmetic Non-Less-Than Comparison    |  >=  |      2     |
    /// |   16   | Boolean And Condition                  |  &&  |      2     |
    /// |   17   | Boolean Or Condition                   |  ||  |      2     |
    /// |   18   | Ternary Operation                      |  ?:  |      3     |
    /// |   19   | Bancor's log** (see below)             |      |      3     |
    /// |   20   | Bancor's power*** (see below)          |      |      4     |
    /// +--------+----------------------------------------+------+------------+
    ///  2. children: the list of node indices of this node's sub-expressions. Different opcode nodes will have different
    ///     number of children.
    ///  3. value: the value inside the node. Currently this is only relevant for Integer Constant (Opcode 00).
    ///     3.1. MODIFICATION: value is also used for Variable (Opcode 01). Here it designates the index of the
    ///          variable's value inside of the passed "variables" array.
    /// (*) Arithmetic percentage is computed by multiplying the left-hand side value with the right-hand side,
    ///     and divide the result by 10^18, rounded down to uint256 integer.
    /// (**) Using BancorFormula, the opcode computes log of fractional numbers. However, this fraction's value must
    ///     be more than 1. (baseN / baseD >= 1). The opcode takes 3 childrens(c, baseN, baseD), and computes
    ///     (c * log(baseN / baseD)) limitation is in range of 1 <= baseN / baseD <= 58774717541114375398436826861112283890
    ///     (= 1e76/FIXED_1), where FIXED_1 defined in BancorPower.sol
    /// (***) Using BancorFomula, the opcode computes exponential of fractional numbers. The opcode takes 4 children
    ///     (c,baseN,baseD,expV), and computes (c * ((baseN / baseD) ^ (expV / 1e6))). See implementation for the
    ///     limitation of the each value's domain. The end result must be in uint256 range.
    struct Node {
        uint8 opcode;
        uint8 child0;
        uint8 child1;
        uint8 child2;
        uint8 child3;
        uint256 value;
    }

    enum ExprType { Invalid, Math, Boolean }

    uint8 constant OPCODE_CONST = 0;
    uint8 constant OPCODE_VAR = 1;
    uint8 constant OPCODE_SQRT = 2;
    uint8 constant OPCODE_NOT = 3;
    uint8 constant OPCODE_ADD = 4;
    uint8 constant OPCODE_SUB = 5;
    uint8 constant OPCODE_MUL = 6;
    uint8 constant OPCODE_DIV = 7;
    uint8 constant OPCODE_EXP = 8;
    uint8 constant OPCODE_PCT = 9;
    uint8 constant OPCODE_EQ =  10;
    uint8 constant OPCODE_NE = 11;
    uint8 constant OPCODE_LT = 12;
    uint8 constant OPCODE_GT = 13;
    uint8 constant OPCODE_LE = 14;
    uint8 constant OPCODE_GE = 15;
    uint8 constant OPCODE_AND = 16;
    uint8 constant OPCODE_OR = 17;
    uint8 constant OPCODE_IF = 18;
    uint8 constant OPCODE_BANCOR_LOG = 19;
    uint8 constant OPCODE_BANCOR_POWER = 20;
    uint8 constant OPCODE_INVALID = 21;

    /// @dev Initialize equation by array of opcodes/values in prefix order. Array
    /// is read as if it is the *pre-order* traversal of the expression tree.
    function init(Node[] storage self, uint256[] calldata _expressions) public {
        /// Init should only be called when the equation is not yet initialized.
        require(self.length == 0);
        /// Limit expression length to < 256 to make sure gas cost is managable.
        require(_expressions.length < 256);
        for (uint8 idx = 0; idx < _expressions.length; ++idx) {
            uint256 opcode = _expressions[idx];
            require(opcode < OPCODE_INVALID);
            Node memory node;
            node.opcode = uint8(opcode);
            /// Get the node's value. Only applicable on Integer Constant case.
            if (opcode == OPCODE_CONST) {
                node.value = _expressions[++idx];
            } else if (opcode == OPCODE_VAR) {
                node.value = _expressions[++idx];
            }
            self.push(node);
        }
        (uint8 lastNodeIndex,) = populateTree(self, 0);
        require(lastNodeIndex == self.length - 1);
    }

    /// Calculate the Y position from the X position for this equation.
    function calculate(Node[] storage self, uint256[] memory variables) public view returns (uint256) {
        return solveMath(self, 0, variables);
    }

    /// Return the number of children the given opcode node has.
    function getChildrenCount(uint8 opcode) private pure returns (uint8) {
        if (opcode <= OPCODE_VAR) {
            return 0;
        } else if (opcode <= OPCODE_NOT) {
            return 1;
        } else if (opcode <= OPCODE_OR) {
            return 2;
        } else if (opcode <= OPCODE_BANCOR_LOG) {
            return 3;
        } else if (opcode <= OPCODE_BANCOR_POWER) {
            return 4;
        }
        revert();
    }

    /// Check whether the given opcode and list of expression types match. Revert on failure.
    function checkExprType(uint8 opcode, ExprType[] memory types)
    private pure returns (ExprType)
    {
        if (opcode <= OPCODE_VAR) {
            return ExprType.Math;
        } else if (opcode == OPCODE_SQRT) {
            require(types[0] == ExprType.Math);
            return ExprType.Math;
        } else if (opcode == OPCODE_NOT) {
            require(types[0] == ExprType.Boolean);
            return ExprType.Boolean;
        } else if (opcode >= OPCODE_ADD && opcode <= OPCODE_PCT) {
            require(types[0] == ExprType.Math);
            require(types[1] == ExprType.Math);
            return ExprType.Math;
        } else if (opcode >= OPCODE_EQ && opcode <= OPCODE_GE) {
            require(types[0] == ExprType.Math);
            require(types[1] == ExprType.Math);
            return ExprType.Boolean;
        } else if (opcode >= OPCODE_AND && opcode <= OPCODE_OR) {
            require(types[0] == ExprType.Boolean);
            require(types[1] == ExprType.Boolean);
            return ExprType.Boolean;
        } else if (opcode == OPCODE_IF) {
            require(types[0] == ExprType.Boolean);
            require(types[1] != ExprType.Invalid);
            require(types[1] == types[2]);
            return types[1];
        } else if (opcode == OPCODE_BANCOR_LOG) {
            require(types[0] == ExprType.Math);
            require(types[1] == ExprType.Math);
            require(types[2] == ExprType.Math);
            return ExprType.Math;
        } else if (opcode == OPCODE_BANCOR_POWER) {
            require(types[0] == ExprType.Math);
            require(types[1] == ExprType.Math);
            require(types[2] == ExprType.Math);
            require(types[3] == ExprType.Math);
            return ExprType.Math;
        }
        revert();
    }

    /// Helper function to recursively populate node infoMaprmation following the given pre-order
    /// node list. It inspects the opcode and recursively call populateTree(s) accordingly.
    /// @param self storage pointer to equation data to build tree.
    /// @param currentNodeIndex the index of the current node to populate infoMap.
    /// @return An (uint8, bool). The first value represents the last  (highest/rightmost) node
    /// index of the current subtree. The second value indicates the type of this subtree.
    function populateTree(Node[] storage self, uint8 currentNodeIndex)
    private returns (uint8, ExprType)
    {
        require(currentNodeIndex < self.length);
        Node storage node = self[currentNodeIndex];
        uint8 opcode = node.opcode;
        uint8 childrenCount = getChildrenCount(opcode);
        ExprType[] memory childrenTypes = new ExprType[](childrenCount);
        uint8 lastNodeIdx = currentNodeIndex;
        for (uint8 idx = 0; idx < childrenCount; ++idx) {
            if (idx == 0) node.child0 = lastNodeIdx + 1;
            else if (idx == 1) node.child1 = lastNodeIdx + 1;
            else if (idx == 2) node.child2 = lastNodeIdx + 1;
            else if (idx == 3) node.child3 = lastNodeIdx + 1;
            else revert();
            (lastNodeIdx, childrenTypes[idx]) = populateTree(self, lastNodeIdx + 1);
        }
        ExprType exprType = checkExprType(opcode, childrenTypes);
        return (lastNodeIdx, exprType);
    }


    function solveMath(Node[] storage self, uint8 nodeIdx, uint256[] memory variables)
    private view returns (uint256)
    {
        Node storage node = self[nodeIdx];
        uint8 opcode = node.opcode;
        if (opcode == OPCODE_CONST) {
            return node.value;
        } else if (opcode == OPCODE_VAR) {
            return variables[node.value]; // for variables, set "value" to the index of the variable's value in uint256[] variables
        } else if (opcode == OPCODE_SQRT) {
            uint256 childValue = solveMath(self, node.child0, variables);
            uint256 temp = childValue.add(1).div(2);
            uint256 result = childValue;
            while (temp < result) {
                result = temp;
                temp = childValue.div(temp).add(temp).div(2);
            }
            return result;
        } else if (opcode >= OPCODE_ADD && opcode <= OPCODE_PCT) {
            uint256 leftValue = solveMath(self, node.child0, variables);
            uint256 rightValue = solveMath(self, node.child1, variables);
            if (opcode == OPCODE_ADD) {
                return leftValue.add(rightValue);
            } else if (opcode == OPCODE_SUB) {
                return leftValue.sub(rightValue);
            } else if (opcode == OPCODE_MUL) {
                return leftValue.mul(rightValue);
            } else if (opcode == OPCODE_DIV) {
                return leftValue.div(rightValue);
            } else if (opcode == OPCODE_EXP) {
                uint256 power = rightValue;
                uint256 expResult = 1;
                for (uint256 idx = 0; idx < power; ++idx) {
                    expResult = expResult.mul(leftValue);
                }
                return expResult;
            } else if (opcode == OPCODE_PCT) {
                return leftValue.mul(rightValue).div(1e18);
            }
        } else if (opcode == OPCODE_IF) {
            bool condValue = solveBool(self, node.child0, variables);
            if (condValue) return solveMath(self, node.child1, variables);
            else return solveMath(self, node.child2, variables);
        } else if (opcode == OPCODE_BANCOR_LOG) {
            uint256 multiplier = solveMath(self, node.child0, variables);
            uint256 baseN = solveMath(self, node.child1, variables);
            uint256 baseD = solveMath(self, node.child2, variables);
            return BancorPower.log(multiplier, baseN, baseD);
        } else if (opcode == OPCODE_BANCOR_POWER) {
            uint256 multiplier = solveMath(self, node.child0, variables);
            uint256 baseN = solveMath(self, node.child1, variables);
            uint256 baseD = solveMath(self, node.child2, variables);
            uint256 expV = solveMath(self, node.child3, variables);
            require(expV < 1 << 32);
            (uint256 expResult, uint8 precision) = BancorPower.power(baseN, baseD, uint32(expV), 1e6);
            return expResult.mul(multiplier) >> precision;
        }
        revert();
    }

    function solveBool(Node[] storage self, uint8 nodeIdx, uint256[] memory variables)
    private view returns (bool)
    {
        Node storage node = self[nodeIdx];
        uint8 opcode = node.opcode;
        if (opcode == OPCODE_NOT) {
            return !solveBool(self, node.child0, variables);
        } else if (opcode >= OPCODE_EQ && opcode <= OPCODE_GE) {
            uint256 leftValue = solveMath(self, node.child0, variables);
            uint256 rightValue = solveMath(self, node.child1, variables);
            if (opcode == OPCODE_EQ) {
                return leftValue == rightValue;
            } else if (opcode == OPCODE_NE) {
                return leftValue != rightValue;
            } else if (opcode == OPCODE_LT) {
                return leftValue < rightValue;
            } else if (opcode == OPCODE_GT) {
                return leftValue > rightValue;
            } else if (opcode == OPCODE_LE) {
                return leftValue <= rightValue;
            } else if (opcode == OPCODE_GE) {
                return leftValue >= rightValue;
            }
        } else if (opcode >= OPCODE_AND && opcode <= OPCODE_OR) {
            bool leftBoolValue = solveBool(self, node.child0, variables);
            if (opcode == OPCODE_AND) {
                if (leftBoolValue) return solveBool(self, node.child1, variables);
                else return false;
            } else if (opcode == OPCODE_OR) {
                if (leftBoolValue) return true;
                else return solveBool(self, node.child1, variables);
            }
        } else if (opcode == OPCODE_IF) {
            bool condValue = solveBool(self, node.child0, variables);
            if (condValue) return solveBool(self, node.child1, variables);
            else return solveBool(self, node.child2, variables);
        }
        revert();
    }
}

////// src/DelphiOracleV1.sol
/* pragma solidity ^0.8.6; */

/* import "@chainlink/interfaces/AggregatorV3Interface.sol"; */
/* import "@openzeppelin/proxy/utils/Initializable.sol"; */
/* import "./math/Equation.sol"; */

contract DelphiOracleV1 is Initializable {

    string public name;
    address public creator; // Gotta give oracle creators creds <3
    address public factory;
    AggregatorV3Interface[] public aggregators;
    Equation.Node[] public nodes;

    constructor () {
        // unused
    }

    // -----------------------------
    // PUBLIC FUNCTIONS
    // -----------------------------

    /**
     * Initialize the Oracle
     *
     * @param _name Name of the Oracle contract (For front-ends)
     * @param _creator Creator of the contract, passed by the factory
     * @param _oracles ChainLink aggregators to use in performOperation()
     * @param _expressions Equation OPCODEs & values
     */
    function init(
        string memory _name,
        address _creator,
        address[] memory _oracles,
        uint256[] calldata _expressions
    ) external initializer {
        // Set creator, factory & ChainLink aggregators
        creator = _creator;
        name = _name;
        factory = msg.sender;
        for (uint i = 0; i < _oracles.length; i++) {
            aggregators.push(AggregatorV3Interface(_oracles[i]));
        }

        // Set up equation for performOperation
        Equation.init(nodes, _expressions);
    }

    /**
     * Performs a special operation with data from available oracles
     */
    function getLatestValue() public view returns (int256) {
        uint256[] memory variables = new uint256[](aggregators.length);
        for (uint8 i = 0; i < aggregators.length; i++) {
            (,int256 value,,,) = aggregators[i].latestRoundData();
            variables[i] = uint256(value) * (10 ** (18 - aggregators[i].decimals())); // Scale all values to 1e18
        }
        return int256(Equation.calculate(nodes, variables));
    }

    /**
     * Get the latest value of the oracle (performOperation remap to work with AggregatorV3Interface)
     */
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        // TODO: Need to figure out what to set these to
        roundId = 0;
        startedAt = 0;
        updatedAt = 0;
        answeredInRound = 0;

        // Set oracle price to oracle operation
        answer = getLatestValue();
    }
}

////// src/DelphiFactoryV1.sol
/* pragma solidity ^0.8.6; */

/* import "@openzeppelin/access/Ownable.sol"; */
/* import "@chainlink/interfaces/AggregatorV3Interface.sol"; */
/* import "solmate/utils/CREATE3.sol"; */
/* import "./DelphiOracleV1.sol"; */

/*

          ______          \'/
      .-'` .    `'-.    -= * =-
    .'  '    .---.  '.    /.\
   /  '    .'     `'. \
  ;  '    /          \|
 :  '  _ ;            `
;  :  /(\ \
|  .       '.
|  ' /     --'
|  .   '.__\
;  :       /
 ;  .     |            ,
  ;  .    \           /|
   \  .    '.       .'/
    '.  '  . `'---'`.'
      `'-..._____.-`

    Delphi Oracle Factory

*/
contract DelphiFactoryV1 is Ownable {

    address[] public oracles;
    mapping(address => bool) public endorsed;
    mapping(address => bool) public linkAggregators;

    event OracleCreation(string _name, address _address);
    event AllowAggregator(address _aggregator, bool _isAllowed);
    event Endorsement(address _oracle, bool _isEndorsed);

    constructor(address[] memory _aggregators) {
        // For ease of deployment, fill the link oracles with your deployment script
        for (uint8 i = 0; i < _aggregators.length; i++) {
            linkAggregators[_aggregators[i]] = true;
            emit AllowAggregator(_aggregators[i], true);
        }
    }

    // -----------------------------
    // PUBLIC FUNCTIONS
    // -----------------------------

    /**
     * Create an oracle that performs an arbitrary mathematical operation
     * on one or more ChainLink aggregator feeds.
     *
     * @param _name Name of the Oracle contract (For front-ends)
     * @param _aggregators ChainLink aggregators used in oracle
     * @param _expressions Equation OPCODEs & values
     */
    function createOracle(
        string memory _name,
        address[] memory _aggregators,
        uint256[] calldata _expressions
    ) external returns (address deployed) {
        // Check that all oracles are whitelisted
        for (uint8 i = 0; i < _aggregators.length; i++) {
            require(linkAggregators[_aggregators[i]] == true, "Error: ORACLE_NOT_ALLOWED");
        }

        // Deploy new synth oracle
        deployed = CREATE3.deploy(
            keccak256(abi.encodePacked(_aggregators, _expressions)), // Use aggregators and expression as CREATE2 salt to prevent duplicate oracles that perform the same equation on the same oracles
            type(DelphiOracleV1).creationCode,
            0
        );

        // Initialize new oracle
        DelphiOracleV1(deployed).init(_name, msg.sender, _aggregators, _expressions);

        // Add oracle to factory's collection
        oracles.push(deployed);

        // Emit OracleCreation event
        emit OracleCreation(_name, deployed);
    }

    /**
     * Get all oracles created by this factory, endorsed or non-endorsed
     *
     * @param _isEndorsed Endorsed=true|Non-endorsed=false
     * @return _oracles All endorsed/non-endorsed oracles
     */
    function getOracles(bool _isEndorsed) external view returns (address[] memory _oracles) {
        uint8 index = 0;
        for (uint i = 0; i < oracles.length; i++) {
            if (endorsed[oracles[i]] == _isEndorsed) {
                _oracles[index++] = oracles[i];
            }
        }
        return _oracles;
    }

    // -----------------------------
    // ADMIN FUNCTIONS
    // -----------------------------

    /**
     * Allow/disallow an aggregator for use in new oracles
     *
     * @param _aggregator ChainLink Aggregator to allow/disallow
     * @param _allow Allowed=true|Disallowed=false
     */
    function setAllowAggregator(address _aggregator, bool _allow) external onlyOwner {
        linkAggregators[_aggregator] = _allow;
        emit AllowAggregator(_aggregator, _allow);
    }

    /**
     * Endorse an oracle. This functionality exists so that protocols can
     * audit and endorse community made Delphi oracles, separating them from
     * other oracles made by the factory.
     *
     * @param _oracle ChainLink Aggregator to endorse
     * @param _endorsed Endorsed=true|Remove=false
     */
    function setEndorsed(address _oracle, bool _endorsed) external onlyOwner {
        endorsed[_oracle] = _endorsed;
        emit Endorsement(_oracle, _endorsed);
    }
}