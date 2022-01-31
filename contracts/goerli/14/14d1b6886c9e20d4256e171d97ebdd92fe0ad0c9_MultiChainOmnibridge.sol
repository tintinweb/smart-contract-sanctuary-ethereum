/**
 *Submitted for verification at Etherscan.io on 2022-01-28
*/

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity ^0.7.0;

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

// File: contracts/upgradeability/EternalStorage.sol

pragma solidity 0.7.5;

/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract EternalStorage {
    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;
}

// File: contracts/upgradeable_contracts/Initializable.sol

pragma solidity 0.7.5;


contract Initializable is EternalStorage {
    bytes32 internal constant INITIALIZED = 0x0a6f646cd611241d8073675e00d1a1ff700fbf1b53fcf473de56d1e6e4b714ba; // keccak256(abi.encodePacked("isInitialized"))

    function setInitialize() internal {
        boolStorage[INITIALIZED] = true;
    }

    function isInitialized() public view returns (bool) {
        return boolStorage[INITIALIZED];
    }
}

// File: contracts/interfaces/IUpgradeabilityOwnerStorage.sol

pragma solidity 0.7.5;

interface IUpgradeabilityOwnerStorage {
    function upgradeabilityOwner() external view returns (address);
}

// File: contracts/upgradeable_contracts/Upgradeable.sol

pragma solidity 0.7.5;


contract Upgradeable {
    /**
     * @dev Throws if called by any account other than the upgradeability owner.
     */
    modifier onlyIfUpgradeabilityOwner() {
        _onlyIfUpgradeabilityOwner();
        _;
    }

    /**
     * @dev Internal function for reducing onlyIfUpgradeabilityOwner modifier bytecode overhead.
     */
    function _onlyIfUpgradeabilityOwner() internal view {
        require(msg.sender == IUpgradeabilityOwnerStorage(address(this)).upgradeabilityOwner());
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


pragma solidity ^0.7.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


pragma solidity ^0.7.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/upgradeable_contracts/Sacrifice.sol

pragma solidity 0.7.5;

contract Sacrifice {
    constructor(address payable _recipient) payable {
        selfdestruct(_recipient);
    }
}

// File: contracts/libraries/AddressHelper.sol

pragma solidity 0.7.5;


/**
 * @title AddressHelper
 * @dev Helper methods for Address type.
 */
library AddressHelper {
    /**
     * @dev Try to send native tokens to the address. If it fails, it will force the transfer by creating a selfdestruct contract
     * @param _receiver address that will receive the native tokens
     * @param _value the amount of native tokens to send
     */
    function safeSendValue(address payable _receiver, uint256 _value) internal {
        if (!(_receiver).send(_value)) {
            new Sacrifice{ value: _value }(_receiver);
        }
    }
}

// File: contracts/upgradeable_contracts/Claimable.sol

pragma solidity 0.7.5;



/**
 * @title Claimable
 * @dev Implementation of the claiming utils that can be useful for withdrawing accidentally sent tokens that are not used in bridge operations.
 */
contract Claimable {
    using SafeERC20 for IERC20;

    /**
     * Throws if a given address is equal to address(0)
     */
    modifier validAddress(address _to) {
        require(_to != address(0));
        _;
    }

    /**
     * @dev Withdraws the erc20 tokens or native coins from this contract.
     * Caller should additionally check that the claimed token is not a part of bridge operations (i.e. that token != erc20token()).
     * @param _token address of the claimed token or address(0) for native coins.
     * @param _to address of the tokens/coins receiver.
     */
    function claimValues(address _token, address _to) internal validAddress(_to) {
        if (_token == address(0)) {
            claimNativeCoins(_to);
        } else {
            claimErc20Tokens(_token, _to);
        }
    }

    /**
     * @dev Internal function for withdrawing all native coins from the contract.
     * @param _to address of the coins receiver.
     */
    function claimNativeCoins(address _to) internal {
        uint256 value = address(this).balance;
        AddressHelper.safeSendValue(payable(_to), value);
    }

    /**
     * @dev Internal function for withdrawing all tokens of some particular ERC20 contract from this contract.
     * @param _token address of the claimed ERC20 token.
     * @param _to address of the tokens receiver.
     */
    function claimErc20Tokens(address _token, address _to) internal {
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(_to, balance);
    }
}

// File: contracts/libraries/MultiChainHelper.sol

pragma solidity 0.7.5;

library MultiChainHelper {
    function currentChainID() internal pure returns (uint256 _currentChainID) {
        assembly {
            _currentChainID := chainid()
        }
    }

    function createSimpleKey(string memory _prefix, uint256 _chainID) internal pure returns (bytes32) {
        return createKey(_prefix, _chainID, new bytes(0));
    }

    function createAddressKey(
        string memory _prefix,
        uint256 _chainID,
        address _addr
    ) internal pure returns (bytes32) {
        return createKey(_prefix, _chainID, abi.encodePacked(_addr));
    }

    function createBytes32Key(
        string memory _prefix,
        uint256 _chainID,
        bytes32 _data
    ) internal pure returns (bytes32) {
        return createKey(_prefix, _chainID, abi.encodePacked(_data));
    }

    function createKey(
        string memory _prefix,
        uint256 _chainID,
        bytes memory _data
    ) internal pure returns (bytes32) {
        return
            _data.length > 0
                ? keccak256(abi.encodePacked(_prefix, _chainID, "#", _data))
                : keccak256(abi.encodePacked(_prefix, _chainID));
    }
}

// File: contracts/upgradeable_contracts/components/bridged/BridgedTokensRegistry.sol

pragma solidity 0.7.5;



/**
 * @title BridgedTokensRegistry
 * @dev Functionality for keeping track of registered bridged token pairs.
 */
contract BridgedTokensRegistry is EternalStorage {
    event NewTokenRegistered(uint256 indexed chainID, address indexed homeToken, address indexed foreignToken);

    /**
     * @dev Retrieves address of the home token contract associated with a specific foreign token contract on the other side.
     * @param _chainID foreign token contract network id.
     * @param _foreignToken address of the foreign token contract on the other side.
     * @return address of the home token contract.
     */
    function homeToken(uint256 _chainID, address _foreignToken) public view returns (address) {
        return addressStorage[MultiChainHelper.createAddressKey("homeTokenAddress", _chainID, _foreignToken)];
    }

    /**
     * @dev Retrieves address of the foreign token contract associated with a specific home token contract.
     * @param _chainID foreign token contract network id.
     * @param _homeToken address of the home token contract.
     * @return address of the foreign token contract.
     */
    function foreignToken(uint256 _chainID, address _homeToken) public view returns (address) {
        return addressStorage[MultiChainHelper.createAddressKey("foreignTokenAddress", _chainID, _homeToken)];
    }

    /**
     * @dev Internal function for updating a pair of addresses for the bridged token.
     * @param _homeToken address of the native token contract on the other side.
     * @param _foreignToken address of the created bridged token contract on this side.
     */
    function _setTokenAddressPair(
        uint256 _chainID,
        address _homeToken,
        address _foreignToken
    ) internal {
        addressStorage[MultiChainHelper.createAddressKey("homeTokenAddress", _chainID, _foreignToken)] = _homeToken;
        addressStorage[MultiChainHelper.createAddressKey("foreignTokenAddress", _chainID, _homeToken)] = _foreignToken;

        emit NewTokenRegistered(_chainID, _homeToken, _foreignToken);
    }
}

// File: contracts/libraries/Bytes.sol

pragma solidity 0.7.5;

/**
 * @title Bytes
 * @dev Helper methods to transform bytes to other solidity types.
 */
library Bytes {
    /**
     * @dev Truncate bytes array if its size is more than 20 bytes.
     * NOTE: This function does not perform any checks on the received parameter.
     * Make sure that the _bytes argument has a correct length, not less than 20 bytes.
     * A case when _bytes has length less than 20 will lead to the undefined behaviour,
     * since assembly will read data from memory that is not related to the _bytes argument.
     * @param _bytes to be converted to address type
     * @return addr address included in the firsts 20 bytes of the bytes array in parameter.
     */
    function bytesToAddress(bytes memory _bytes) internal pure returns (address addr) {
        assembly {
            addr := mload(add(_bytes, 20))
        }
    }
}

// File: contracts/upgradeable_contracts/ReentrancyGuard.sol

pragma solidity 0.7.5;

contract ReentrancyGuard {
    function lock() internal view returns (bool res) {
        assembly {
            // Even though this is not the same as boolStorage[keccak256(abi.encodePacked("lock"))],
            // since solidity mapping introduces another level of addressing, such slot change is safe
            // for temporary variables which are cleared at the end of the call execution.
            res := sload(0x6168652c307c1e813ca11cfb3a601f1cf3b22452021a5052d8b05f1f1f8a3e92) // keccak256(abi.encodePacked("lock"))
        }
    }

    function setLock(bool _lock) internal {
        assembly {
            // Even though this is not the same as boolStorage[keccak256(abi.encodePacked("lock"))],
            // since solidity mapping introduces another level of addressing, such slot change is safe
            // for temporary variables which are cleared at the end of the call execution.
            sstore(0x6168652c307c1e813ca11cfb3a601f1cf3b22452021a5052d8b05f1f1f8a3e92, _lock) // keccak256(abi.encodePacked("lock"))
        }
    }
}

// File: contracts/upgradeable_contracts/Ownable.sol

pragma solidity 0.7.5;



/**
 * @title Ownable
 * @dev This contract has an owner address providing basic authorization control
 */
contract Ownable is EternalStorage {
    bytes4 internal constant UPGRADEABILITY_OWNER = 0x6fde8202; // upgradeabilityOwner()

    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @dev Internal function for reducing onlyOwner modifier bytecode overhead.
     */
    function _onlyOwner() internal view {
        require(msg.sender == owner());
    }

    /**
     * @dev Throws if called through proxy by any account other than contract itself or an upgradeability owner.
     */
    modifier onlyRelevantSender() {
        (bool isProxy, bytes memory returnData) = address(this).staticcall(
            abi.encodeWithSelector(UPGRADEABILITY_OWNER)
        );
        require(
            !isProxy || // covers usage without calling through storage proxy
                (returnData.length == 32 && msg.sender == abi.decode(returnData, (address))) || // covers usage through regular proxy calls
                msg.sender == address(this) // covers calls through upgradeAndCall proxy method
        );
        _;
    }

    bytes32 internal constant OWNER = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0; // keccak256(abi.encodePacked("owner"))

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function owner() public view returns (address) {
        return addressStorage[OWNER];
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner the address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _setOwner(newOwner);
    }

    /**
     * @dev Sets a new owner address
     */
    function _setOwner(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner(), newOwner);
        addressStorage[OWNER] = newOwner;
    }
}

// File: contracts/interfaces/IAMB.sol

pragma solidity 0.7.5;

interface IAMB {
    event UserRequestForAffirmation(bytes32 indexed messageId, bytes encodedData);
    event UserRequestForSignature(bytes32 indexed messageId, bytes encodedData);
    event AffirmationCompleted(
        address indexed sender,
        address indexed executor,
        bytes32 indexed messageId,
        bool status
    );
    event RelayedMessage(address indexed sender, address indexed executor, bytes32 indexed messageId, bool status);

    function messageSender() external view returns (address);

    function maxGasPerTx() external view returns (uint256);

    function transactionHash() external view returns (bytes32);

    function messageId() external view returns (bytes32);

    function messageSourceChainId() external view returns (bytes32);

    function messageCallStatus(bytes32 _messageId) external view returns (bool);

    function failedMessageDataHash(bytes32 _messageId) external view returns (bytes32);

    function failedMessageReceiver(bytes32 _messageId) external view returns (address);

    function failedMessageSender(bytes32 _messageId) external view returns (address);

    function requireToPassMessage(
        address _contract,
        bytes calldata _data,
        uint256 _gas
    ) external returns (bytes32);

    function requireToConfirmMessage(
        address _contract,
        bytes calldata _data,
        uint256 _gas
    ) external returns (bytes32);

    function sourceChainId() external view returns (uint256);

    function destinationChainId() external view returns (uint256);
}

// File: contracts/upgradeable_contracts/BasicAMBMediator.sol

pragma solidity 0.7.5;





/**
 * @title BasicAMBMediator
 * @dev Basic storage and methods needed by mediators to interact with AMB bridge.
 */
abstract contract BasicAMBMediator is Ownable {
    /**
     * @dev Throws if caller on the other side is not an associated mediator.
     */
    modifier onlyMediator(uint256 _chainID) {
        _onlyMediator(_chainID);
        _;
    }

    /**
     * @dev Internal function for reducing onlyMediator modifier bytecode overhead.
     * @param _chainID specific network id.
     */
    function _onlyMediator(uint256 _chainID) internal view {
        IAMB bridge = bridgeContract(_chainID);
        require(msg.sender == address(bridge));
        require(bridge.messageSender() == mediatorContractOnOtherSide(_chainID));
    }

    /**
     * @dev Sets the AMB bridge contract address. Only the owner can call this method.
     * @param _chainID specific network id.
     * @param _bridgeContract the address of the bridge contract.
     */
    function setBridgeContract(uint256 _chainID, address _bridgeContract) external onlyOwner {
        _setBridgeContract(_chainID, _bridgeContract);
    }

    /**
     * @dev Sets the mediator contract address from the other network. Only the owner can call this method.
     * @param _chainID specific network id.
     * @param _mediatorContract the address of the mediator contract.
     */
    function setMediatorContractOnOtherSide(uint256 _chainID, address _mediatorContract) external onlyOwner {
        _setMediatorContractOnOtherSide(_chainID, _mediatorContract);
    }

    /**
     * @dev Sets the bridge contract and mediator contract addresses. Only the owner can call this method.
     * @param _chainID specific network id.
     * @param _bridgeContract the address of the bridge contract.
     * @param _mediatorContract the address of the mediator contract.
     */
    function setBridgeAndMediatorOnTheOtherSide(
        uint256 _chainID,
        address _bridgeContract,
        address _mediatorContract
    ) external onlyOwner {
        _setBridgeContract(_chainID, _bridgeContract);
        _setMediatorContractOnOtherSide(_chainID, _mediatorContract);
    }

    /**
     * @dev Tells if networks are supported by network id.
     * @param _chainID specific network id.
     * @return true - if supported, otherwise - false.
     */
    function isSupportedChain(uint256 _chainID) public view returns (bool) {
        return address(bridgeContract(_chainID)) != address(0) && mediatorContractOnOtherSide(_chainID) != address(0);
    }

    /**
     * @dev Get the AMB interface for the bridge contract address by network id.
     * @param _chainID specific network id.
     * @return AMB interface for the bridge contract address
     */
    function bridgeContract(uint256 _chainID) public view returns (IAMB) {
        return IAMB(addressStorage[MultiChainHelper.createSimpleKey("bridgeContract", _chainID)]);
    }

    /**
     * @dev Tells the mediator contract address from the other network by network id.
     * @param _chainID specific network id.
     * @return the address of the mediator contract.
     */
    function mediatorContractOnOtherSide(uint256 _chainID) public view virtual returns (address) {
        return addressStorage[MultiChainHelper.createSimpleKey("mediatorContract", _chainID)];
    }

    /**
     * @dev Stores a valid AMB bridge contract address.
     * @param _chainID specific network id.
     * @param _bridgeContract the address of the bridge contract.
     */
    function _setBridgeContract(uint256 _chainID, address _bridgeContract) internal {
        require(Address.isContract(_bridgeContract));
        addressStorage[MultiChainHelper.createSimpleKey("bridgeContract", _chainID)] = _bridgeContract;
    }

    /**
     * @dev Stores the mediator contract address from the other network.
     * @param _chainID specific network id.
     * @param _mediatorContract the address of the mediator contract.
     */
    function _setMediatorContractOnOtherSide(uint256 _chainID, address _mediatorContract) internal {
        addressStorage[MultiChainHelper.createSimpleKey("mediatorContract", _chainID)] = _mediatorContract;
    }

    /**
     * @dev Tells the id of the message originated on the other network by network id.
     * @param _chainID specific network id.
     * @return the id of the message originated on the other network.
     */
    function messageId(uint256 _chainID) internal view returns (bytes32) {
        return bridgeContract(_chainID).messageId();
    }

    /**
     * @dev Tells the maximum gas limit that a message can use on its execution by the AMB bridge on the other network by network id.
     * @param _chainID specific network id.
     * @return the maximum gas limit value.
     */
    function maxGasPerTx(uint256 _chainID) internal view returns (uint256) {
        return bridgeContract(_chainID).maxGasPerTx();
    }

    function _passMessage(uint256 _chainID, bytes memory _data) internal virtual returns (bytes32);
}

// File: contracts/upgradeable_contracts/components/common/TokensRelayer.sol

pragma solidity 0.7.5;








/**
 * @title TokensRelayer
 * @dev Functionality for bridging multiple tokens to the other side of the bridge.
 */
abstract contract TokensRelayer is BasicAMBMediator, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev Initiate the bridge operation for some amount of tokens from msg.sender.
     * The user should first call Approve method of the ERC20 token.
     * @param _chainID destination network id.
     * @param _token home token contract address.
     * @param _receiver address that will receive the native tokens on the other network.
     * @param _value amount of tokens to be transferred to the other network.
     */
    function relayTokens(
        uint256 _chainID,
        IERC20 _token,
        address _receiver,
        uint256 _value
    ) external {
        _relayTokens(_chainID, _token, _receiver, _value, new bytes(0));
    }

    /**
     * @dev Initiate the bridge operation for some amount of tokens from msg.sender to msg.sender on the other side.
     * The user should first call Approve method of the ERC20 token.
     * @param _chainID destination network id.
     * @param _token home token contract address.
     * @param _value amount of tokens to be transferred to the other network.
     */
    function relayTokens(
        uint256 _chainID,
        IERC20 _token,
        uint256 _value
    ) external {
        _relayTokens(_chainID, _token, msg.sender, _value, new bytes(0));
    }

    /**
     * @dev Initiate the bridge operation for some amount of tokens from msg.sender.
     * The user should first call Approve method of the ERC20 token.
     * @param _chainID destination network id.
     * @param _token home token contract address.
     * @param _receiver address that will receive the native tokens on the other network.
     * @param _value amount of tokens to be transferred to the other network.
     * @param _data additional transfer data to be used on the other side.
     */
    function relayTokensAndCall(
        uint256 _chainID,
        IERC20 _token,
        address _receiver,
        uint256 _value,
        bytes memory _data
    ) external {
        _relayTokens(_chainID, _token, _receiver, _value, _data);
    }

    /**
     * @dev Validates that the token amount is inside the limits, calls transferFrom to transfer the tokens to the contract
     * and invokes the method to burn/lock the tokens and unlock/mint the tokens on the other network.
     * The user should first call Approve method of the ERC20 token.
     * @param _chainID destination network id.
     * @param _token bridge token contract address.
     * @param _receiver address that will receive the native tokens on the other network.
     * @param _value amount of tokens to be transferred to the other network.
     * @param _data additional transfer data to be used on the other side.
     */
    function _relayTokens(
        uint256 _chainID,
        IERC20 _token,
        address _receiver,
        uint256 _value,
        bytes memory _data
    ) internal {
        // This lock is to prevent calling passMessage twice if a ERC20 token is used.
        // When transferFrom is called, after the transfer, the ERC20 token will call onTokenTransfer from this contract
        // which will call passMessage.
        require(!lock());

        uint256 balanceBefore = _token.balanceOf(address(this));
        setLock(true);
        _token.safeTransferFrom(msg.sender, address(this), _value);
        setLock(false);
        uint256 balanceDiff = _token.balanceOf(address(this)).sub(balanceBefore);
        require(balanceDiff <= _value);
        bridgeSpecificActionsOnTokenTransfer(_chainID, address(_token), msg.sender, _receiver, balanceDiff, _data);
    }

    function bridgeSpecificActionsOnTokenTransfer(
        uint256 _chainID,
        address _token,
        address _from,
        address _receiver,
        uint256 _value,
        bytes memory _data
    ) internal virtual;
}

// File: contracts/upgradeable_contracts/VersionableBridge.sol

pragma solidity 0.7.5;

interface VersionableBridge {
    function getBridgeInterfacesVersion()
        external
        pure
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        );

    function getBridgeMode() external pure returns (bytes4);
}

// File: contracts/upgradeable_contracts/components/common/OmnibridgeInfo.sol

pragma solidity 0.7.5;


/**
 * @title OmnibridgeInfo
 * @dev Functionality for versioning Omnibridge mediator.
 */
contract OmnibridgeInfo is VersionableBridge {
    event TokensBridgingInitiated(
        uint256 chainID,
        address indexed token,
        address indexed sender,
        uint256 value,
        bytes32 indexed messageId
    );
    event TokensBridged(
        uint256 chainID,
        address indexed token,
        address indexed recipient,
        uint256 value,
        bytes32 indexed messageId
    );

    /**
     * @dev Tells the bridge interface version that this contract supports.
     * @return major value of the version
     * @return minor value of the version
     * @return patch value of the version
     */
    function getBridgeInterfacesVersion()
        external
        pure
        override
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        )
    {
        return (3, 3, 0);
    }

    /**
     * @dev Tells the bridge mode that this contract supports.
     * @return _data 4 bytes representing the bridge mode
     */
    function getBridgeMode() external pure override returns (bytes4 _data) {
        return 0xb1516c26; // bytes4(keccak256(abi.encodePacked("multi-erc-to-erc-amb")))
    }
}

// File: contracts/upgradeable_contracts/components/common/TokensBridgeLimits.sol

pragma solidity 0.7.5;




/**
 * @title TokensBridgeLimits
 * @dev Functionality for keeping track of bridging limits for multiple tokens.
 */
contract TokensBridgeLimits is EternalStorage, Ownable {
    using SafeMath for uint256;

    // token == 0x00..00 represents default limits (assuming decimals == 18) for all newly created tokens
    event DailyLimitChanged(address indexed token, uint256 newLimit);
    event ExecutionDailyLimitChanged(address indexed token, uint256 newLimit);

    /**
     * @dev Checks if specified token was already bridged at least once.
     * @param _token address of the token contract.
     * @return true, if token address is address(0) or token was already bridged.
     */
    function isTokenRegistered(address _token) public view returns (bool) {
        return minPerTx(_token) > 0;
    }

    /**
     * @dev Retrieves the total spent amount for particular token during specific day.
     * @param _token address of the token contract.
     * @param _day day number for which spent amount if requested.
     * @return amount of tokens sent through the bridge to the other side.
     */
    function totalSpentPerDay(address _token, uint256 _day) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("totalSpentPerDay", _token, _day))];
    }

    /**
     * @dev Retrieves the total executed amount for particular token during specific day.
     * @param _token address of the token contract.
     * @param _day day number for which spent amount if requested.
     * @return amount of tokens received from the bridge from the other side.
     */
    function totalExecutedPerDay(address _token, uint256 _day) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("totalExecutedPerDay", _token, _day))];
    }

    /**
     * @dev Retrieves current daily limit for a particular token contract.
     * @param _token address of the token contract.
     * @return daily limit on tokens that can be sent through the bridge per day.
     */
    function dailyLimit(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("dailyLimit", _token))];
    }

    /**
     * @dev Retrieves current execution daily limit for a particular token contract.
     * @param _token address of the token contract.
     * @return daily limit on tokens that can be received from the bridge on the other side per day.
     */
    function executionDailyLimit(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("executionDailyLimit", _token))];
    }

    /**
     * @dev Retrieves current maximum amount of tokens per one transfer for a particular token contract.
     * @param _token address of the token contract.
     * @return maximum amount on tokens that can be sent through the bridge in one transfer.
     */
    function maxPerTx(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("maxPerTx", _token))];
    }

    /**
     * @dev Retrieves current maximum execution amount of tokens per one transfer for a particular token contract.
     * @param _token address of the token contract.
     * @return maximum amount on tokens that can received from the bridge on the other side in one transaction.
     */
    function executionMaxPerTx(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("executionMaxPerTx", _token))];
    }

    /**
     * @dev Retrieves current minimum amount of tokens per one transfer for a particular token contract.
     * @param _token address of the token contract.
     * @return minimum amount on tokens that can be sent through the bridge in one transfer.
     */
    function minPerTx(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("minPerTx", _token))];
    }

    /**
     * @dev Checks that bridged amount of tokens conforms to the configured limits.
     * @param _token address of the token contract.
     * @param _amount amount of bridge tokens.
     * @return true, if specified amount can be bridged.
     */
    function withinLimit(address _token, uint256 _amount) public view returns (bool) {
        uint256 nextLimit = totalSpentPerDay(_token, getCurrentDay()).add(_amount);
        return
            dailyLimit(address(0)) > 0 &&
            dailyLimit(_token) >= nextLimit &&
            _amount <= maxPerTx(_token) &&
            _amount >= minPerTx(_token);
    }

    /**
     * @dev Checks that bridged amount of tokens conforms to the configured execution limits.
     * @param _token address of the token contract.
     * @param _amount amount of bridge tokens.
     * @return true, if specified amount can be processed and executed.
     */
    function withinExecutionLimit(address _token, uint256 _amount) public view returns (bool) {
        uint256 nextLimit = totalExecutedPerDay(_token, getCurrentDay()).add(_amount);
        return
            executionDailyLimit(address(0)) > 0 &&
            executionDailyLimit(_token) >= nextLimit &&
            _amount <= executionMaxPerTx(_token);
    }

    /**
     * @dev Returns current day number.
     * @return day number.
     */
    function getCurrentDay() public view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp / 1 days;
    }

    /**
     * @dev Updates daily limit for the particular token. Only owner can call this method.
     * @param _token address of the token contract, or address(0) for configuring the efault limit.
     * @param _dailyLimit daily allowed amount of bridged tokens, should be greater than maxPerTx.
     * 0 value is also allowed, will stop the bridge operations in outgoing direction.
     */
    function setDailyLimit(address _token, uint256 _dailyLimit) external onlyOwner {
        require(isTokenRegistered(_token));
        require(_dailyLimit > maxPerTx(_token) || _dailyLimit == 0);
        uintStorage[keccak256(abi.encodePacked("dailyLimit", _token))] = _dailyLimit;
        emit DailyLimitChanged(_token, _dailyLimit);
    }

    /**
     * @dev Updates execution daily limit for the particular token. Only owner can call this method.
     * @param _token address of the token contract, or address(0) for configuring the default limit.
     * @param _dailyLimit daily allowed amount of executed tokens, should be greater than executionMaxPerTx.
     * 0 value is also allowed, will stop the bridge operations in incoming direction.
     */
    function setExecutionDailyLimit(address _token, uint256 _dailyLimit) external onlyOwner {
        require(isTokenRegistered(_token));
        require(_dailyLimit > executionMaxPerTx(_token) || _dailyLimit == 0);
        uintStorage[keccak256(abi.encodePacked("executionDailyLimit", _token))] = _dailyLimit;
        emit ExecutionDailyLimitChanged(_token, _dailyLimit);
    }

    /**
     * @dev Updates execution maximum per transaction for the particular token. Only owner can call this method.
     * @param _token address of the token contract, or address(0) for configuring the default limit.
     * @param _maxPerTx maximum amount of executed tokens per one transaction, should be less than executionDailyLimit.
     * 0 value is also allowed, will stop the bridge operations in incoming direction.
     */
    function setExecutionMaxPerTx(address _token, uint256 _maxPerTx) external onlyOwner {
        require(isTokenRegistered(_token));
        require(_maxPerTx == 0 || (_maxPerTx > 0 && _maxPerTx < executionDailyLimit(_token)));
        uintStorage[keccak256(abi.encodePacked("executionMaxPerTx", _token))] = _maxPerTx;
    }

    /**
     * @dev Updates maximum per transaction for the particular token. Only owner can call this method.
     * @param _token address of the token contract, or address(0) for configuring the default limit.
     * @param _maxPerTx maximum amount of tokens per one transaction, should be less than dailyLimit, greater than minPerTx.
     * 0 value is also allowed, will stop the bridge operations in outgoing direction.
     */
    function setMaxPerTx(address _token, uint256 _maxPerTx) external onlyOwner {
        require(isTokenRegistered(_token));
        require(_maxPerTx == 0 || (_maxPerTx > minPerTx(_token) && _maxPerTx < dailyLimit(_token)));
        uintStorage[keccak256(abi.encodePacked("maxPerTx", _token))] = _maxPerTx;
    }

    /**
     * @dev Updates minimum per transaction for the particular token. Only owner can call this method.
     * @param _token address of the token contract, or address(0) for configuring the default limit.
     * @param _minPerTx minimum amount of tokens per one transaction, should be less than maxPerTx and dailyLimit.
     */
    function setMinPerTx(address _token, uint256 _minPerTx) external onlyOwner {
        require(isTokenRegistered(_token));
        require(_minPerTx > 0 && _minPerTx < dailyLimit(_token) && _minPerTx < maxPerTx(_token));
        uintStorage[keccak256(abi.encodePacked("minPerTx", _token))] = _minPerTx;
    }

    /**
     * @dev Retrieves maximum available bridge amount per one transaction taking into account maxPerTx() and dailyLimit() parameters.
     * @param _token address of the token contract, or address(0) for the default limit.
     * @return minimum of maxPerTx parameter and remaining daily quota.
     */
    function maxAvailablePerTx(address _token) public view returns (uint256) {
        uint256 _maxPerTx = maxPerTx(_token);
        uint256 _dailyLimit = dailyLimit(_token);
        uint256 _spent = totalSpentPerDay(_token, getCurrentDay());
        uint256 _remainingOutOfDaily = _dailyLimit > _spent ? _dailyLimit - _spent : 0;
        return _maxPerTx < _remainingOutOfDaily ? _maxPerTx : _remainingOutOfDaily;
    }

    /**
     * @dev Internal function for adding spent amount for some token.
     * @param _token address of the token contract.
     * @param _day day number, when tokens are processed.
     * @param _value amount of bridge tokens.
     */
    function addTotalSpentPerDay(
        address _token,
        uint256 _day,
        uint256 _value
    ) internal {
        uintStorage[keccak256(abi.encodePacked("totalSpentPerDay", _token, _day))] = totalSpentPerDay(_token, _day).add(
            _value
        );
    }

    /**
     * @dev Internal function for adding executed amount for some token.
     * @param _token address of the token contract.
     * @param _day day number, when tokens are processed.
     * @param _value amount of bridge tokens.
     */
    function addTotalExecutedPerDay(
        address _token,
        uint256 _day,
        uint256 _value
    ) internal {
        uintStorage[keccak256(abi.encodePacked("totalExecutedPerDay", _token, _day))] = totalExecutedPerDay(
            _token,
            _day
        ).add(_value);
    }

    /**
     * @dev Internal function for initializing limits for some token.
     * @param _token address of the token contract.
     * @param _limits [ 0 = dailyLimit, 1 = maxPerTx, 2 = minPerTx ].
     */
    function _setLimits(address _token, uint256[3] memory _limits) internal {
        require(
            _limits[2] > 0 && // minPerTx > 0
                _limits[1] > _limits[2] && // maxPerTx > minPerTx
                _limits[0] > _limits[1] // dailyLimit > maxPerTx
        );

        uintStorage[keccak256(abi.encodePacked("dailyLimit", _token))] = _limits[0];
        uintStorage[keccak256(abi.encodePacked("maxPerTx", _token))] = _limits[1];
        uintStorage[keccak256(abi.encodePacked("minPerTx", _token))] = _limits[2];

        emit DailyLimitChanged(_token, _limits[0]);
    }

    /**
     * @dev Internal function for initializing execution limits for some token.
     * @param _token address of the token contract.
     * @param _limits [ 0 = executionDailyLimit, 1 = executionMaxPerTx ].
     */
    function _setExecutionLimits(address _token, uint256[2] memory _limits) internal {
        require(_limits[1] < _limits[0]); // foreignMaxPerTx < foreignDailyLimit

        uintStorage[keccak256(abi.encodePacked("executionDailyLimit", _token))] = _limits[0];
        uintStorage[keccak256(abi.encodePacked("executionMaxPerTx", _token))] = _limits[1];

        emit ExecutionDailyLimitChanged(_token, _limits[0]);
    }

    /**
     * @dev Internal function for initializing limits for some token relative to its decimals parameter.
     * @param _token address of the token contract.
     * @param _decimals token decimals parameter.
     */
    function _initializeTokenBridgeLimits(address _token, uint256 _decimals) internal {
        uint256 factor;
        if (_decimals < 18) {
            factor = 10**(18 - _decimals);

            uint256 _minPerTx = minPerTx(address(0)).div(factor);
            uint256 _maxPerTx = maxPerTx(address(0)).div(factor);
            uint256 _dailyLimit = dailyLimit(address(0)).div(factor);
            uint256 _executionMaxPerTx = executionMaxPerTx(address(0)).div(factor);
            uint256 _executionDailyLimit = executionDailyLimit(address(0)).div(factor);

            // such situation can happen when calculated limits relative to the token decimals are too low
            // e.g. minPerTx(address(0)) == 10 ** 14, _decimals == 3. _minPerTx happens to be 0, which is not allowed.
            // in this case, limits are raised to the default values
            if (_minPerTx == 0) {
                // Numbers 1, 100, 10000 are chosen in a semi-random way,
                // so that any token with small decimals can still be bridged in some amounts.
                // It is possible to override limits for the particular token later if needed.
                _minPerTx = 1;
                if (_maxPerTx <= _minPerTx) {
                    _maxPerTx = 100;
                    _executionMaxPerTx = 100;
                    if (_dailyLimit <= _maxPerTx || _executionDailyLimit <= _executionMaxPerTx) {
                        _dailyLimit = 10000;
                        _executionDailyLimit = 10000;
                    }
                }
            }
            _setLimits(_token, [_dailyLimit, _maxPerTx, _minPerTx]);
            _setExecutionLimits(_token, [_executionDailyLimit, _executionMaxPerTx]);
        } else {
            factor = 10**(_decimals - 18);
            _setLimits(
                _token,
                [dailyLimit(address(0)).mul(factor), maxPerTx(address(0)).mul(factor), minPerTx(address(0)).mul(factor)]
            );
            _setExecutionLimits(
                _token,
                [executionDailyLimit(address(0)).mul(factor), executionMaxPerTx(address(0)).mul(factor)]
            );
        }
    }
}

// File: contracts/upgradeable_contracts/components/common/BridgeOperationsStorage.sol

pragma solidity 0.7.5;



/**
 * @title BridgeOperationsStorage
 * @dev Functionality for storing processed bridged operations.
 */
abstract contract BridgeOperationsStorage is EternalStorage {
    /**
     * @dev Stores the bridged token of a message sent to the AMB bridge.
     * @param _chainID network id of the specific bridge.
     * @param _messageId of the message sent to the bridge.
     * @param _token bridged token address.
     */
    function setMessageToken(
        uint256 _chainID,
        bytes32 _messageId,
        address _token
    ) internal {
        addressStorage[MultiChainHelper.createBytes32Key("messageToken", _chainID, _messageId)] = _token;
    }

    /**
     * @dev Tells the bridged token address of a message sent to the AMB bridge.
     * @param _chainID network id of the specific bridge.
     * @param _messageId of the message sent to the bridge.
     * @return address of a token contract.
     */
    function messageToken(uint256 _chainID, bytes32 _messageId) internal view returns (address) {
        return addressStorage[MultiChainHelper.createBytes32Key("messageToken", _chainID, _messageId)];
    }

    /**
     * @dev Stores the value of a message sent to the AMB bridge.
     * @param _chainID network id of the specific bridge.
     * @param _messageId of the message sent to the bridge.
     * @param _value amount of tokens bridged.
     */
    function setMessageValue(
        uint256 _chainID,
        bytes32 _messageId,
        uint256 _value
    ) internal {
        uintStorage[MultiChainHelper.createBytes32Key("messageValue", _chainID, _messageId)] = _value;
    }

    /**
     * @dev Tells the amount of tokens of a message sent to the AMB bridge.
     * @param _chainID network id of the specific bridge.
     * @param _messageId of the message sent to the bridge.
     * @return value representing amount of tokens.
     */
    function messageValue(uint256 _chainID, bytes32 _messageId) internal view returns (uint256) {
        return uintStorage[MultiChainHelper.createBytes32Key("messageValue", _chainID, _messageId)];
    }

    /**
     * @dev Stores the receiver of a message sent to the AMB bridge.
     * @param _chainID network id of the specific bridge.
     * @param _messageId of the message sent to the bridge.
     * @param _recipient receiver of the tokens bridged.
     */
    function setMessageRecipient(
        uint256 _chainID,
        bytes32 _messageId,
        address _recipient
    ) internal {
        addressStorage[MultiChainHelper.createBytes32Key("messageRecipient", _chainID, _messageId)] = _recipient;
    }

    /**
     * @dev Tells the receiver of a message sent to the AMB bridge.
     * @param _chainID network id of the specific bridge.
     * @param _messageId of the message sent to the bridge.
     * @return address of the receiver.
     */
    function messageRecipient(uint256 _chainID, bytes32 _messageId) internal view returns (address) {
        return addressStorage[MultiChainHelper.createBytes32Key("messageRecipient", _chainID, _messageId)];
    }
}

// File: contracts/upgradeable_contracts/components/common/FailedMessagesProcessor.sol

pragma solidity 0.7.5;



/**
 * @title FailedMessagesProcessor
 * @dev Functionality for fixing failed bridging operations.
 */
abstract contract FailedMessagesProcessor is BasicAMBMediator, BridgeOperationsStorage {
    event FailedMessageFixed(
        uint256 indexed chainID,
        bytes32 indexed messageId,
        address token,
        address recipient,
        uint256 value
    );

    /**
     * @dev Method to be called when a bridged message execution failed. It will generate a new message requesting to
     * fix/roll back the transferred assets on the other network.
     * @param _chainID required network id.
     * @param _messageId id of the message which execution failed.
     */
    function requestFailedMessageFix(uint256 _chainID, bytes32 _messageId) external {
        IAMB bridge = bridgeContract(_chainID);
        require(!bridge.messageCallStatus(_messageId));
        require(bridge.failedMessageReceiver(_messageId) == address(this));
        require(bridge.failedMessageSender(_messageId) == mediatorContractOnOtherSide(_chainID));

        bytes4 methodSelector = this.fixFailedMessage.selector;
        bytes memory data = abi.encodeWithSelector(methodSelector, MultiChainHelper.currentChainID(), _messageId);

        _passMessage(_chainID, data);
    }

    /**
     * @dev Handles the request to fix transferred assets which bridged message execution failed on the other network.
     * It uses the information stored by passMessage method when the assets were initially transferred
     * @param _chainID other network id.
     * @param _messageId id of the message which execution failed on the other network.
     */
    function fixFailedMessage(uint256 _chainID, bytes32 _messageId) public onlyMediator(_chainID) {
        require(!messageFixed(_chainID, _messageId));

        address token = messageToken(_chainID, _messageId);
        address recipient = messageRecipient(_chainID, _messageId);
        uint256 value = messageValue(_chainID, _messageId);

        setMessageFixed(_chainID, _messageId);
        executeActionOnFixedTokens(token, recipient, value);

        emit FailedMessageFixed(_chainID, _messageId, token, recipient, value);
    }

    /**
     * @dev Tells if a message sent to the AMB bridge has been fixed.
     * @param _chainID required network id.
     * @param _messageId of the message sent to the bridge.
     * @return bool indicating the status of the message.
     */
    function messageFixed(uint256 _chainID, bytes32 _messageId) public view returns (bool) {
        return boolStorage[MultiChainHelper.createBytes32Key("messageFixed", _chainID, _messageId)];
    }

    /**
     * @dev Sets that the message sent to the AMB bridge has been fixed.
     * @param _chainID required network id.
     * @param _messageId of the message sent to the bridge.
     */
    function setMessageFixed(uint256 _chainID, bytes32 _messageId) internal {
        boolStorage[MultiChainHelper.createBytes32Key("messageFixed", _chainID, _messageId)] = true;
    }

    function executeActionOnFixedTokens(
        address _token,
        address _recipient,
        uint256 _value
    ) internal virtual;
}

// File: contracts/upgradeable_contracts/components/native/MediatorBalanceStorage.sol

pragma solidity 0.7.5;



/**
 * @title MediatorBalanceStorage
 * @dev Functionality for storing expected mediator balance for native tokens.
 */
contract MediatorBalanceStorage is EternalStorage {
    /**
     * @dev Tells the expected token balance of the contract.
     * @param _token address of token contract.
     * @return the current tracked token balance of the contract.
     */
    function mediatorBalance(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("mediatorBalance", _token))];
    }

    /**
     * @dev Updates expected token balance of the contract.
     * @param _token address of token contract.
     * @param _balance the new token balance of the contract.
     */
    function _setMediatorBalance(address _token, uint256 _balance) internal {
        uintStorage[keccak256(abi.encodePacked("mediatorBalance", _token))] = _balance;
    }
}

// File: contracts/interfaces/IERC20Receiver.sol

pragma solidity 0.7.5;

interface IERC20Receiver {
    function onTokenBridged(
        address token,
        uint256 value,
        bytes calldata data
    ) external;
}

// File: contracts/libraries/TokenReader.sol

pragma solidity 0.7.5;

// solhint-disable
interface ITokenDetails {
    function name() external view;

    function NAME() external view;

    function symbol() external view;

    function SYMBOL() external view;

    function decimals() external view;

    function DECIMALS() external view;
}

// solhint-enable

/**
 * @title TokenReader
 * @dev Helper methods for reading name/symbol/decimals parameters from ERC20 token contracts.
 */
library TokenReader {
    /**
     * @dev Reads the name property of the provided token.
     * Either name() or NAME() method is used.
     * Both, string and bytes32 types are supported.
     * @param _token address of the token contract.
     * @return token name as a string or an empty string if none of the methods succeeded.
     */
    function readName(address _token) internal view returns (string memory) {
        (bool status, bytes memory data) = _token.staticcall(abi.encodeWithSelector(ITokenDetails.name.selector));
        if (!status) {
            (status, data) = _token.staticcall(abi.encodeWithSelector(ITokenDetails.NAME.selector));
            if (!status) {
                return "";
            }
        }
        return _convertToString(data);
    }

    /**
     * @dev Reads the symbol property of the provided token.
     * Either symbol() or SYMBOL() method is used.
     * Both, string and bytes32 types are supported.
     * @param _token address of the token contract.
     * @return token symbol as a string or an empty string if none of the methods succeeded.
     */
    function readSymbol(address _token) internal view returns (string memory) {
        (bool status, bytes memory data) = _token.staticcall(abi.encodeWithSelector(ITokenDetails.symbol.selector));
        if (!status) {
            (status, data) = _token.staticcall(abi.encodeWithSelector(ITokenDetails.SYMBOL.selector));
            if (!status) {
                return "";
            }
        }
        return _convertToString(data);
    }

    /**
     * @dev Reads the decimals property of the provided token.
     * Either decimals() or DECIMALS() method is used.
     * @param _token address of the token contract.
     * @return token decimals or 0 if none of the methods succeeded.
     */
    function readDecimals(address _token) internal view returns (uint8) {
        (bool status, bytes memory data) = _token.staticcall(abi.encodeWithSelector(ITokenDetails.decimals.selector));
        if (!status) {
            (status, data) = _token.staticcall(abi.encodeWithSelector(ITokenDetails.DECIMALS.selector));
            if (!status) {
                return 0;
            }
        }
        return abi.decode(data, (uint8));
    }

    /**
     * @dev Internal function for converting returned value of name()/symbol() from bytes32/string to string.
     * @param returnData data returned by the token contract.
     * @return string with value obtained from returnData.
     */
    function _convertToString(bytes memory returnData) private pure returns (string memory) {
        if (returnData.length > 32) {
            return abi.decode(returnData, (string));
        } else if (returnData.length == 32) {
            bytes32 data = abi.decode(returnData, (bytes32));
            string memory res = new string(32);
            assembly {
                let len := 0
                mstore(add(res, 32), data) // save value in result string

                // solhint-disable
                for {

                } gt(data, 0) {
                    len := add(len, 1)
                } {
                    // until string is empty
                    data := shl(8, data) // shift left by one symbol
                }
                // solhint-enable
                mstore(res, len) // save result string length
            }
            return res;
        } else {
            return "";
        }
    }
}

// File: contracts/upgradeable_contracts/BasicOmnibridge.sol

pragma solidity 0.7.5;















/**
 * @title BasicOmnibridge
 * @dev Common functionality for multi-token mediator intended to work on top of AMB bridge.
 */
abstract contract BasicOmnibridge is
    Initializable,
    Upgradeable,
    Claimable,
    OmnibridgeInfo,
    TokensRelayer,
    FailedMessagesProcessor,
    BridgedTokensRegistry,
    MediatorBalanceStorage,
    TokensBridgeLimits
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Workaround for storing variable up-to-32 bytes suffix
    uint256 private immutable SUFFIX_SIZE;
    bytes32 private immutable SUFFIX;

    // Since contract is intended to be deployed under EternalStorageProxy, only constant and immutable variables can be set here
    constructor(string memory _suffix) {
        require(bytes(_suffix).length <= 32);
        bytes32 suffix;
        assembly {
            suffix := mload(add(_suffix, 32))
        }
        SUFFIX = suffix;
        SUFFIX_SIZE = bytes(_suffix).length;
    }

    /**
     * @dev Handles the bridged tokens for the already registered token pair.
     * Checks that the value is inside the execution limits and invokes the Unlock accordingly.
     * @param _chainID network id on the other side.
     * @param _token address of the native ERC20 token on the other side.
     * @param _recipient address that will receive the tokens.
     * @param _value amount of tokens to be received.
     */
    function handleBridgedTokens(
        uint256 _chainID,
        address _token,
        address _recipient,
        uint256 _value
    ) external onlyMediator(_chainID) {
        address token = homeToken(_chainID, _token);

        require(isTokenRegistered(token));

        _handleTokens(_chainID, token, _recipient, _value);
    }

    /**
     * @dev Handles the bridged tokens for the already registered token pair.
     * Checks that the value is inside the execution limits and invokes the Unlock accordingly.
     * Executes a callback on the receiver.
     * @param _chainID network id on the other side.
     * @param _token address of the native ERC20 token on the other side.
     * @param _recipient address that will receive the tokens.
     * @param _value amount of tokens to be received.
     * @param _data additional transfer data passed from the other side.
     */
    function handleBridgedTokensAndCall(
        uint256 _chainID,
        address _token,
        address _recipient,
        uint256 _value,
        bytes memory _data
    ) external onlyMediator(_chainID) {
        address token = homeToken(_chainID, _token);

        require(isTokenRegistered(token));

        _handleTokens(_chainID, token, _recipient, _value);

        _receiverCallback(_recipient, token, _value, _data);
    }

    /**
     * @dev Unlock back the amount of tokens that were bridged to the other network but failed.
     * @param _token address that bridged token contract.
     * @param _recipient address that will receive the tokens.
     * @param _value amount of tokens to be received.
     */
    function executeActionOnFixedTokens(
        address _token,
        address _recipient,
        uint256 _value
    ) internal override {
        _releaseTokens(_token, _recipient, _value, _value);
    }

    /**
     * @dev Add some amount of tokens from msg.sender to mediator balance.
     * The user should first call Approve method of the ERC20 token.
     * @param _token token contract address.
     * @param _amount amount of tokens to be added.
     */
    function addMediatorBalance(address _token, uint256 _amount) external {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        _setMediatorBalance(_token, mediatorBalance(_token).add(_amount));
    }

    /**
     * @dev Used to set one token pairs for specific networks and initialize limits.
     * Only the owner can call this method.
     * @param _chainID specific network id.
     * @param _homeToken address of the token contract on this side.
     * @param _foreignToken address of the token contract on the other side.
     */
    function setTokensPair(
        uint256 _chainID,
        address _homeToken,
        address _foreignToken
    ) external onlyOwner {
        _setTokensPair(_chainID, _homeToken, _foreignToken);
    }

    /**
     * @dev Used to set many token pairs for single home token for specific networks and initialize limits.
     * Only the owner can call this method.
     * @param _chainIDs array of specific network ids.
     * @param _homeToken address of the token contract on this side.
     * @param _foreignTokens array of addresses of the token contracts on the other side.
     */
    function setTokensPairBatch(
        uint256[] memory _chainIDs,
        address _homeToken,
        address[] memory _foreignTokens
    ) external onlyOwner {
        require(_chainIDs.length == _foreignTokens.length, "Lengths mismatch.");

        for (uint256 i = 0; i < _chainIDs.length; i++) {
            _setTokensPair(_chainIDs[i], _homeToken, _foreignTokens[i]);
        }
    }

    /**
     * @dev Allows to send to the other network the amount of locked tokens that can be forced into the contract
     * without the invocation of the required methods. (e. g. regular transfer without a call to onTokenTransfer)
     * @param _chainID specific network id.
     * @param _token address of the token contract.
     * Before calling this method, it must be carefully investigated how imbalance happened
     * in order to avoid an attempt to steal the funds from a token with double addresses
     * (e.g. TUSD is accessible at both 0x8dd5fbCe2F6a956C3022bA3663759011Dd51e73E and 0x0000000000085d4780B73119b644AE5ecd22b376)
     * @param _receiver the address that will receive the tokens on the other network.
     */
    function fixMediatorBalance(
        uint256 _chainID,
        address _token,
        address _receiver
    ) external onlyIfUpgradeabilityOwner validAddress(_receiver) {
        uint256 diff = _unaccountedBalance(_token);
        require(diff > 0);
        uint256 available = maxAvailablePerTx(_token);
        require(available > 0);
        if (diff > available) {
            diff = available;
        }
        addTotalSpentPerDay(_token, getCurrentDay(), diff);

        bytes memory data = _prepareMessage(_token, _receiver, diff, new bytes(0));
        bytes32 _messageId = _passMessage(_chainID, data);
        _recordBridgeOperation(_chainID, _messageId, _token, _receiver, diff);
    }

    /**
     * @dev Claims stuck tokens. Only unsupported tokens can be claimed.
     * When dealing with already supported tokens, fixMediatorBalance can be used instead.
     * @param _token address of claimed token, address(0) for native
     * @param _to address of tokens receiver
     */
    function claimTokens(address _token, address _to) external onlyIfUpgradeabilityOwner {
        // Only unregistered tokens and native coins are allowed to be claimed with the use of this function
        require(_token == address(0) || !isTokenRegistered(_token));
        claimValues(_token, _to);
    }

    /**
     * @dev Internal function for setting token pair for further usage.
     * @param _chainID specific network id.
     * @param _homeToken address of the token contract on this side.
     * @param _foreignToken address of the token contract on the other side.
     */
    function _setTokensPair(
        uint256 _chainID,
        address _homeToken,
        address _foreignToken
    ) internal {
        require(!isTokenRegistered(_foreignToken));
        require(homeToken(_chainID, _foreignToken) == address(0));
        require(foreignToken(_chainID, _homeToken) == address(0));

        _setTokenAddressPair(_chainID, _homeToken, _foreignToken);

        if (!isTokenRegistered(_homeToken)) {
            _initializeTokenBridgeLimits(_homeToken, TokenReader.readDecimals(_homeToken));
        }
    }

    /**
     * @dev Internal function for recording bridge operation for further usage.
     * Recorded information is used for fixing failed requests on the other side.
     * @param _chainID network id on the other side.
     * @param _messageId id of the sent message.
     * @param _token bridged token address.
     * @param _sender address of the tokens sender.
     * @param _value bridged value.
     */
    function _recordBridgeOperation(
        uint256 _chainID,
        bytes32 _messageId,
        address _token,
        address _sender,
        uint256 _value
    ) internal {
        setMessageToken(_chainID, _messageId, _token);
        setMessageRecipient(_chainID, _messageId, _sender);
        setMessageValue(_chainID, _messageId, _value);

        emit TokensBridgingInitiated(_chainID, _token, _sender, _value, _messageId);
    }

    /**
     * @dev Constructs the message to be sent to the other side. Burns/locks bridged amount of tokens.
     * @param _token bridged token address.
     * @param _receiver address of the tokens receiver on the other side.
     * @param _value bridged value.
     * @param _data additional transfer data passed from the other side.
     */
    function _prepareMessage(
        address _token,
        address _receiver,
        uint256 _value,
        bytes memory _data
    ) internal returns (bytes memory) {
        bool withData = _data.length > 0 || msg.sig == this.relayTokensAndCall.selector;

        _setMediatorBalance(_token, mediatorBalance(_token).add(_value));

        return
            withData
                ? abi.encodeWithSelector(
                    this.handleBridgedTokensAndCall.selector,
                    MultiChainHelper.currentChainID(),
                    _token,
                    _receiver,
                    _value,
                    _data
                )
                : abi.encodeWithSelector(
                    this.handleBridgedTokens.selector,
                    MultiChainHelper.currentChainID(),
                    _token,
                    _receiver,
                    _value
                );
    }

    /**
     * Internal function for unlocking some amount of tokens.
     * @param _token address of the token contract.
     * @param _recipient address of the tokens receiver.
     * @param _value amount of tokens to unlock.
     * @param _balanceChange amount of balance to subtract from the mediator balance.
     */
    function _releaseTokens(
        address _token,
        address _recipient,
        uint256 _value,
        uint256 _balanceChange
    ) internal virtual {
        IERC20(_token).safeTransfer(_recipient, _value);
        _setMediatorBalance(_token, mediatorBalance(_token).sub(_balanceChange));
    }

    /**
     * Notifies receiving contract about the completed bridging operation.
     * @param _recipient address of the tokens receiver.
     * @param _token address of the bridged token.
     * @param _value amount of tokens transferred.
     * @param _data additional data passed to the callback.
     */
    function _receiverCallback(
        address _recipient,
        address _token,
        uint256 _value,
        bytes memory _data
    ) internal {
        if (Address.isContract(_recipient)) {
            _recipient.call(abi.encodeWithSelector(IERC20Receiver.onTokenBridged.selector, _token, _value, _data));
        }
    }

    /**
     * @dev Internal function for transforming the bridged token name. Appends a side-specific suffix.
     * @param _name bridged token from the other side.
     * @return token name for this side of the bridge.
     */
    function _transformName(string memory _name) internal view returns (string memory) {
        string memory result = string(abi.encodePacked(_name, SUFFIX));
        uint256 size = SUFFIX_SIZE;
        assembly {
            mstore(result, add(mload(_name), size))
        }
        return result;
    }

    /**
     * @dev Internal function for counting excess balance which is not tracked within the bridge.
     * Represents the amount of forced tokens on this contract.
     * @param _token address of the token contract.
     * @return amount of excess tokens.
     */
    function _unaccountedBalance(address _token) internal view virtual returns (uint256) {
        return IERC20(_token).balanceOf(address(this)).sub(mediatorBalance(_token));
    }

    function _handleTokens(
        uint256 _chainID,
        address _token,
        address _recipient,
        uint256 _value
    ) internal virtual;
}

// File: contracts/upgradeable_contracts/modules/OwnableModule.sol

pragma solidity 0.7.5;


/**
 * @title OwnableModule
 * @dev Common functionality for multi-token extension non-upgradeable module.
 */
contract OwnableModule {
    address public owner;

    /**
     * @dev Initializes this contract.
     * @param _owner address of the owner that is allowed to perform additional actions on the particular module.
     */
    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * @dev Throws if sender is not the owner of this contract.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Changes the owner of this contract.
     * @param _newOwner address of the new owner.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }
}

// File: contracts/upgradeable_contracts/modules/MediatorOwnableModule.sol

pragma solidity 0.7.5;



/**
 * @title MediatorOwnableModule
 * @dev Common functionality for non-upgradeable Omnibridge extension module.
 */
contract MediatorOwnableModule is OwnableModule {
    address public mediator;

    /**
     * @dev Initializes this contract.
     * @param _mediator address of the deployed Omnibridge extension for which this module is deployed.
     * @param _owner address of the owner that is allowed to perform additional actions on the particular module.
     */
    constructor(address _mediator, address _owner) OwnableModule(_owner) {
        require(Address.isContract(_mediator));
        mediator = _mediator;
    }

    /**
     * @dev Throws if sender is not the Omnibridge extension.
     */
    modifier onlyMediator() {
        require(msg.sender == mediator);
        _;
    }
}

// File: contracts/upgradeable_contracts/modules/fee_manager/OmnibridgeFeeManager.sol

pragma solidity 0.7.5;





/**
 * @title OmnibridgeFeeManager
 * @dev Implements the logic to distribute fees from the Omnibridge mediator contract operations.
 * The fees are distributed in the form of ERC20/ERC677 tokens to the list of reward addresses.
 */
contract OmnibridgeFeeManager is MediatorOwnableModule {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // This is not a real fee value but a relative value used to calculate the fee percentage.
    // 1 ether = 100% of the value.
    uint256 internal constant MAX_FEE = 1 ether;
    uint256 internal constant MAX_REWARD_ACCOUNTS = 50;

    bytes32 public constant HOME_TO_FOREIGN_FEE = 0x741ede137d0537e88e0ea0ff25b1f22d837903dbbee8980b4a06e8523247ee26; // keccak256(abi.encodePacked("homeToForeignFee"))
    bytes32 public constant FOREIGN_TO_HOME_FEE = 0x03be2b2875cb41e0e77355e802a16769bb8dfcf825061cde185c73bf94f12625; // keccak256(abi.encodePacked("foreignToHomeFee"))

    // mapping feeType => token address => fee percentage
    mapping(bytes32 => mapping(address => uint256)) internal fees;
    address[] internal rewardAddresses;

    event FeeUpdated(bytes32 feeType, address indexed token, uint256 fee);

    /**
     * @dev Stores the initial parameters of the fee manager.
     * @param _mediator address of the mediator contract used together with this fee manager.
     * @param _owner address of the contract owner.
     * @param _rewardAddresses list of unique initial reward addresses, between whom fees will be distributed
     * @param _fees array with initial fees for both bridge directions.
     *   [ 0 = homeToForeignFee, 1 = foreignToHomeFee ]
     */
    constructor(
        address _mediator,
        address _owner,
        address[] memory _rewardAddresses,
        uint256[2] memory _fees
    ) MediatorOwnableModule(_mediator, _owner) {
        require(_rewardAddresses.length <= MAX_REWARD_ACCOUNTS);
        _setFee(HOME_TO_FOREIGN_FEE, address(0), _fees[0]);
        _setFee(FOREIGN_TO_HOME_FEE, address(0), _fees[1]);

        for (uint256 i = 0; i < _rewardAddresses.length; i++) {
            require(_isValidAddress(_rewardAddresses[i]));
            for (uint256 j = 0; j < i; j++) {
                require(_rewardAddresses[j] != _rewardAddresses[i]);
            }
        }
        rewardAddresses = _rewardAddresses;
    }

    /**
     * @dev Tells the module interface version that this contract supports.
     * @return major value of the version
     * @return minor value of the version
     * @return patch value of the version
     */
    function getModuleInterfacesVersion()
        external
        pure
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        )
    {
        return (1, 0, 0);
    }

    /**
     * @dev Throws if given fee amount is invalid.
     */
    modifier validFee(uint256 _fee) {
        require(_fee < MAX_FEE);
        /* solcov ignore next */
        _;
    }

    /**
     * @dev Throws if given fee type is unknown.
     */
    modifier validFeeType(bytes32 _feeType) {
        require(_feeType == HOME_TO_FOREIGN_FEE || _feeType == FOREIGN_TO_HOME_FEE);
        /* solcov ignore next */
        _;
    }

    /**
     * @dev Updates the value for the particular fee type.
     * Only the owner can call this method.
     * @param _feeType type of the updated fee, can be one of [HOME_TO_FOREIGN_FEE, FOREIGN_TO_HOME_FEE].
     * @param _token address of the token contract for which fee should apply, 0x00..00 describes the initial fee for newly created tokens.
     * @param _fee new fee value, in percentage (1 ether == 10**18 == 100%).
     */
    function setFee(
        bytes32 _feeType,
        address _token,
        uint256 _fee
    ) external validFeeType(_feeType) onlyOwner {
        _setFee(_feeType, _token, _fee);
    }

    /**
     * @dev Retrieves the value for the particular fee type.
     * @param _feeType type of the updated fee, can be one of [HOME_TO_FOREIGN_FEE, FOREIGN_TO_HOME_FEE].
     * @param _token address of the token contract for which fee should apply, 0x00..00 describes the initial fee for newly created tokens.
     * @return fee value associated with the requested fee type.
     */
    function getFee(bytes32 _feeType, address _token) public view validFeeType(_feeType) returns (uint256) {
        // use token-specific fee if one is registered
        uint256 _tokenFee = fees[_feeType][_token];
        if (_tokenFee > 0) {
            return _tokenFee - 1;
        }
        // use default fee otherwise
        return fees[_feeType][address(0)] - 1;
    }

    /**
     * @dev Calculates the amount of fee to pay for the value of the particular fee type.
     * @param _feeType type of the updated fee, can be one of [HOME_TO_FOREIGN_FEE, FOREIGN_TO_HOME_FEE].
     * @param _token address of the token contract for which fee should apply, 0x00..00 describes the initial fee for newly created tokens.
     * @param _value bridged value, for which fee should be evaluated.
     * @return amount of fee to be subtracted from the transferred value.
     */
    function calculateFee(
        bytes32 _feeType,
        address _token,
        uint256 _value
    ) public view returns (uint256) {
        if (rewardAddresses.length == 0) {
            return 0;
        }
        uint256 _fee = getFee(_feeType, _token);
        return _value.mul(_fee).div(MAX_FEE);
    }

    /**
     * @dev Adds a new address to the list of accounts to receive rewards for the operations.
     * Only the owner can call this method.
     * @param _addr new reward address.
     */
    function addRewardAddress(address _addr) external onlyOwner {
        require(_isValidAddress(_addr));
        require(!isRewardAddress(_addr));
        require(rewardAddresses.length < MAX_REWARD_ACCOUNTS);
        rewardAddresses.push(_addr);
    }

    /**
     * @dev Removes an address from the list of accounts to receive rewards for the operations.
     * Only the owner can call this method.
     * finds the element, swaps it with the last element, and then deletes it;
     * @param _addr to be removed.
     * return boolean whether the element was found and deleted
     */
    function removeRewardAddress(address _addr) external onlyOwner {
        uint256 numOfAccounts = rewardAddresses.length;
        for (uint256 i = 0; i < numOfAccounts; i++) {
            if (rewardAddresses[i] == _addr) {
                rewardAddresses[i] = rewardAddresses[numOfAccounts - 1];
                delete rewardAddresses[numOfAccounts - 1];
                rewardAddresses.pop();
                return;
            }
        }
        // If account is not found and removed, the transactions is reverted
        revert();
    }

    /**
     * @dev Tells the number of registered reward receivers.
     * @return amount of addresses.
     */
    function rewardAddressCount() external view returns (uint256) {
        return rewardAddresses.length;
    }

    /**
     * @dev Tells the list of registered reward receivers.
     * @return list with all registered reward receivers.
     */
    function rewardAddressList() external view returns (address[] memory) {
        return rewardAddresses;
    }

    /**
     * @dev Tells if a given address is part of the reward address list.
     * @param _addr address to check if it is part of the list.
     * @return true if the given address is in the list
     */
    function isRewardAddress(address _addr) public view returns (bool) {
        for (uint256 i = 0; i < rewardAddresses.length; i++) {
            if (rewardAddresses[i] == _addr) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Distributes the fee proportionally between registered reward addresses.
     * @param _token address of the token contract for which fee should be distributed.
     */
    function distributeFee(address _token) external onlyMediator {
        uint256 numOfAccounts = rewardAddresses.length;
        uint256 fee = IERC20(_token).balanceOf(address(this));
        uint256 feePerAccount = fee.div(numOfAccounts);
        uint256 randomAccountIndex;
        uint256 diff = fee.sub(feePerAccount.mul(numOfAccounts));
        if (diff > 0) {
            randomAccountIndex = random(numOfAccounts);
        }

        for (uint256 i = 0; i < numOfAccounts; i++) {
            uint256 feeToDistribute = feePerAccount;
            if (diff > 0 && randomAccountIndex == i) {
                feeToDistribute = feeToDistribute.add(diff);
            }
            IERC20(_token).safeTransfer(rewardAddresses[i], feeToDistribute);
        }
    }

    /**
     * @dev Calculates a random number based on the block number.
     * @param _count the max value for the random number.
     * @return a number between 0 and _count.
     */
    function random(uint256 _count) internal view returns (uint256) {
        return uint256(blockhash(block.number.sub(1))) % _count;
    }

    /**
     * @dev Internal function for updating the fee value for the given fee type.
     * @param _feeType type of the updated fee, can be one of [HOME_TO_FOREIGN_FEE, FOREIGN_TO_HOME_FEE].
     * @param _token address of the token contract for which fee should apply, 0x00..00 describes the initial fee for newly created tokens.
     * @param _fee new fee value, in percentage (1 ether == 10**18 == 100%).
     */
    function _setFee(
        bytes32 _feeType,
        address _token,
        uint256 _fee
    ) internal validFee(_fee) {
        fees[_feeType][_token] = 1 + _fee;
        emit FeeUpdated(_feeType, _token, _fee);
    }

    /**
     * @dev Checks if a given address can be a reward receiver.
     * @param _addr address of the proposed reward receiver.
     * @return true, if address is valid.
     */
    function _isValidAddress(address _addr) internal view returns (bool) {
        return _addr != address(0) && _addr != address(mediator);
    }
}

// File: contracts/upgradeable_contracts/modules/fee_manager/OmnibridgeFeeManagerConnector.sol

pragma solidity 0.7.5;




/**
 * @title OmnibridgeFeeManagerConnector
 * @dev Connectivity functionality for working with OmnibridgeFeeManager contract.
 */
abstract contract OmnibridgeFeeManagerConnector is Ownable {
    using SafeERC20 for IERC20;

    bytes32 internal constant FEE_MANAGER_CONTRACT = 0x779a349c5bee7817f04c960f525ee3e2f2516078c38c68a3149787976ee837e5; // keccak256(abi.encodePacked("feeManagerContract"))
    bytes32 internal constant HOME_TO_FOREIGN_FEE = 0x741ede137d0537e88e0ea0ff25b1f22d837903dbbee8980b4a06e8523247ee26; // keccak256(abi.encodePacked("homeToForeignFee"))
    bytes32 internal constant FOREIGN_TO_HOME_FEE = 0x03be2b2875cb41e0e77355e802a16769bb8dfcf825061cde185c73bf94f12625; // keccak256(abi.encodePacked("foreignToHomeFee"))

    event FeeDistributed(uint256 fee, address indexed token, bytes32 indexed messageId);
    event FeeDistributionFailed(address indexed token, uint256 fee);

    /**
     * @dev Updates an address of the used fee manager contract used for calculating and distributing fees.
     * @param _feeManager address of fee manager contract.
     */
    function setFeeManager(address _feeManager) external onlyOwner {
        _setFeeManager(_feeManager);
    }

    /**
     * @dev Retrieves an address of the fee manager contract.
     * @return address of the fee manager contract.
     */
    function feeManager() public view returns (OmnibridgeFeeManager) {
        return OmnibridgeFeeManager(addressStorage[FEE_MANAGER_CONTRACT]);
    }

    /**
     * @dev Internal function for updating an address of the used fee manager contract.
     * @param _feeManager address of fee manager contract.
     */
    function _setFeeManager(address _feeManager) internal {
        require(_feeManager == address(0) || Address.isContract(_feeManager));
        addressStorage[FEE_MANAGER_CONTRACT] = _feeManager;
    }

    /**
     * @dev Internal function for calculating and distributing fee through the separate fee manager contract.
     * @param _feeType type of the fee, can be one of [HOME_TO_FOREIGN_FEE, FOREIGN_TO_HOME_FEE].
     * @param _from address of the tokens sender, needed only if _feeType is HOME_TO_FOREIGN_FEE.
     * @param _token address of the token contract, for which fee should be processed.
     * @param _value amount of tokens bridged.
     * @return total amount of fee distributed.
     */
    function _distributeFee(
        bytes32 _feeType,
        address _from,
        address _token,
        uint256 _value
    ) internal returns (uint256) {
        OmnibridgeFeeManager manager = feeManager();
        if (address(manager) != address(0)) {
            // Next line disables fee collection in case sender is one of the reward addresses.
            // It is needed to allow a 100% withdrawal of tokens from the home side.
            // If fees are not disabled for reward receivers, small fraction of tokens will always
            // be redistributed between the same set of reward addresses, which is not the desired behaviour.
            if (_feeType == HOME_TO_FOREIGN_FEE && manager.isRewardAddress(_from)) {
                return 0;
            }
            uint256 fee = manager.calculateFee(_feeType, _token, _value);
            if (fee > 0) {
                if (_feeType == HOME_TO_FOREIGN_FEE) {
                    // for home -> foreign direction, fee is collected using transfer(address,uint256) method
                    // if transfer to the manager contract fails, the transaction is reverted
                    IERC20(_token).safeTransfer(address(manager), fee);
                } else {
                    // for foreign -> home direction,
                    // fee is collected using transfer(address,uint256) method for tokens,
                    // if transfer to the manager contract fails, the message still will be processed, but without fees
                    bytes4 selector = IERC20.transfer.selector;
                    (bool status, bytes memory returnData) = _token.call(
                        abi.encodeWithSelector(selector, manager, fee)
                    );
                    if (!status) {
                        emit FeeDistributionFailed(_token, fee);
                        return 0;
                    }
                    require(returnData.length == 0 || abi.decode(returnData, (bool)));
                }
                manager.distributeFee(_token);
            }
            return fee;
        }
        return 0;
    }
}

// File: contracts/upgradeable_contracts/modules/gas_limit/SelectorTokenGasLimitManager.sol

pragma solidity 0.7.5;




/**
 * @title SelectorTokenGasLimitManager
 * @dev Multi token mediator functionality for managing request gas limits.
 */
contract SelectorTokenGasLimitManager is OwnableModule {
    // chainID => bridge address
    mapping(uint256 => IAMB) internal bridges;
    mapping(uint256 => uint256) internal defaultGasLimits;
    mapping(uint256 => mapping(bytes4 => uint256)) internal selectorGasLimit;
    mapping(uint256 => mapping(bytes4 => mapping(address => uint256))) internal selectorTokenGasLimit;

    constructor(
        uint256[] memory _chainIDs,
        IAMB[] memory _bridges,
        address _owner,
        uint256[] memory _gasLimits
    ) OwnableModule(_owner) {
        require(_chainIDs.length == _bridges.length && _chainIDs.length == _gasLimits.length, "Lengths mismatch.");

        for (uint256 i = 0; i < _chainIDs.length; i++) {
            _setBridgeContract(_chainIDs[i], _bridges[i], _gasLimits[i]);
        }
    }

    /**
     * @dev Tells the module interface version that this contract supports.
     * @return major value of the version
     * @return minor value of the version
     * @return patch value of the version
     */
    function getModuleInterfacesVersion()
        external
        pure
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        )
    {
        return (1, 0, 0);
    }

    /**
     * @dev Throws if provided gas limit is greater then the maximum allowed gas limit in the AMB contract.
     * @param _gasLimit gas limit value to check.
     */
    modifier validGasLimit(uint256 _chainID, uint256 _gasLimit) {
        require(_gasLimit <= bridges[_chainID].maxGasPerTx());
        _;
    }

    /**
     * @dev Throws if one of the provided gas limits is greater then the maximum allowed gas limit in the AMB contract.
     * @param _length expected length of the _gasLimits array.
     * @param _gasLimits array of gas limit values to check, should contain exactly _length elements.
     */
    modifier validGasLimits(
        uint256 _chainID,
        uint256 _length,
        uint256[] calldata _gasLimits
    ) {
        require(_gasLimits.length == _length);
        uint256 maxGasLimit = bridges[_chainID].maxGasPerTx();
        for (uint256 i = 0; i < _length; i++) {
            require(_gasLimits[i] <= maxGasLimit);
        }
        _;
    }

    /**
     * @dev Sets the bridge contract and default gas limit for the specific network id.
     * Only the owner can call this method.
     * @param _chainID required network id.
     * @param _bridgeContract address of the bridge contract on the Home side.
     * @param _defaultGasLimit default gas limit
     */
    function setBridgeContract(
        uint256 _chainID,
        IAMB _bridgeContract,
        uint256 _defaultGasLimit
    ) external onlyOwner {
        _setBridgeContract(_chainID, _bridgeContract, _defaultGasLimit);
    }

    /**
     * @dev Sets the default gas limit to be used in the message execution by the AMB bridge on the other network.
     * This value can't exceed the parameter maxGasPerTx defined on the AMB bridge.
     * Only the owner can call this method.
     * @param _chainID required network id.
     * @param _gasLimit the gas limit for the message execution.
     */
    function setRequestGasLimit(uint256 _chainID, uint256 _gasLimit)
        external
        onlyOwner
        validGasLimit(_chainID, _gasLimit)
    {
        defaultGasLimits[_chainID] = _gasLimit;
    }

    /**
     * @dev Sets the selector-specific gas limit to be used in the message execution by the AMB bridge on the other network.
     * This value can't exceed the parameter maxGasPerTx defined on the AMB bridge.
     * Only the owner can call this method.
     * @param _chainID required network id.
     * @param _selector method selector of the outgoing message payload.
     * @param _gasLimit the gas limit for the message execution.
     */
    function setRequestGasLimit(
        uint256 _chainID,
        bytes4 _selector,
        uint256 _gasLimit
    ) external onlyOwner validGasLimit(_chainID, _gasLimit) {
        selectorGasLimit[_chainID][_selector] = _gasLimit;
    }

    /**
     * @dev Sets the token-specific gas limit to be used in the message execution by the AMB bridge on the other network.
     * This value can't exceed the parameter maxGasPerTx defined on the AMB bridge.
     * Only the owner can call this method.
     * @param _chainID required network id.
     * @param _selector method selector of the outgoing message payload.
     * @param _token address of the native token that is used in the first argument of handleBridgedTokens/handleNativeTokens.
     * @param _gasLimit the gas limit for the message execution.
     */
    function setRequestGasLimit(
        uint256 _chainID,
        bytes4 _selector,
        address _token,
        uint256 _gasLimit
    ) external onlyOwner validGasLimit(_chainID, _gasLimit) {
        selectorTokenGasLimit[_chainID][_selector][_token] = _gasLimit;
    }

    /**
     * @dev Tells if the manager supports the required network.
     * @param _chainID required network id.
     * @return true - if supports, otherwise false.
     */
    function isNetworkExists(uint256 _chainID) public view returns (bool) {
        return address(bridges[_chainID]) != address(0);
    }

    /**
     * @dev Returns bridge contract address by network id.
     * @param _chainID required network id.
     * @return the bridge contract.
     */
    function bridgeContract(uint256 _chainID) public view returns (IAMB) {
        return bridges[_chainID];
    }

    /**
     * @dev Tells the default gas limit to be used in the message execution by the AMB bridge on the other network.
     * @param _chainID required network id.
     * @return the gas limit for the message execution.
     */
    function requestGasLimit(uint256 _chainID) public view returns (uint256) {
        return defaultGasLimits[_chainID];
    }

    /**
     * @dev Tells the selector-specific gas limit to be used in the message execution by the AMB bridge on the other network.
     * @param _chainID required network id.
     * @param _selector method selector for the passed message.
     * @return the gas limit for the message execution.
     */
    function requestGasLimit(uint256 _chainID, bytes4 _selector) public view returns (uint256) {
        return selectorGasLimit[_chainID][_selector];
    }

    /**
     * @dev Tells the token-specific gas limit to be used in the message execution by the AMB bridge on the other network.
     * @param _chainID required network id.
     * @param _selector method selector for the passed message.
     * @param _token address of the native token that is used in the first argument of handleBridgedTokens.
     * @return the gas limit for the message execution.
     */
    function requestGasLimit(
        uint256 _chainID,
        bytes4 _selector,
        address _token
    ) public view returns (uint256) {
        return selectorTokenGasLimit[_chainID][_selector][_token];
    }

    /**
     * @dev Tells the gas limit to use for the message execution by the AMB bridge on the other network.
     * @param _chainID required network id.
     * @param _data calldata to be used on the other side of the bridge, when execution a message.
     * @return the gas limit for the message execution.
     */
    function requestGasLimit(uint256 _chainID, bytes memory _data) external view returns (uint256) {
        bytes4 selector;
        address token;
        assembly {
            // first 4 bytes of _data contain the selector of the function to be called on the other side of the bridge.
            // mload(add(_data, 4)) loads selector to the 28-31 bytes of the word.
            // shl(28 * 8, x) then used to correct the padding of the selector, putting it to 0-3 bytes of the word.
            selector := shl(224, mload(add(_data, 4)))
            // handleBridgedTokens/handleNativeTokens/... passes bridged token address as the first parameter.
            // it is located in the 4-35 bytes of the calldata.
            // 36 = bytes length padding (32) + selector length (4)
            token := mload(add(_data, 36))
        }
        uint256 gasLimit = selectorTokenGasLimit[_chainID][selector][token];
        if (gasLimit == 0) {
            gasLimit = selectorGasLimit[_chainID][selector];
            if (gasLimit == 0) {
                gasLimit = defaultGasLimits[_chainID];
            }
        }
        return gasLimit;
    }

    /**
     * @dev Sets the default values for different Omnibridge selectors.
     * @param _chainID required network id.
     * @param _gasLimits array with 3 gas limits for the following selectors of the outgoing messages:
     * - handleBridgedTokens, handleBridgedTokensAndCall
     * - fixFailedMessage
     * Only the owner can call this method.
     */
    function setCommonRequestGasLimits(uint256 _chainID, uint256[] calldata _gasLimits)
        external
        onlyOwner
        validGasLimits(_chainID, 3, _gasLimits)
    {
        require(_gasLimits[1] >= _gasLimits[0]);
        selectorGasLimit[_chainID][BasicOmnibridge.handleBridgedTokens.selector] = _gasLimits[0];
        selectorGasLimit[_chainID][BasicOmnibridge.handleBridgedTokensAndCall.selector] = _gasLimits[1];
        selectorGasLimit[_chainID][FailedMessagesProcessor.fixFailedMessage.selector] = _gasLimits[2];
    }

    /**
     * @dev Sets the request gas limits for some specific token native to the Home side of the bridge.
     * @param _chainID required network id.
     * @param _token address of the native token contract on the Home side.
     * @param _gasLimits array with 2 gas limits for the following selectors of the outgoing messages:
     * - handleBridgedTokens, handleBridgedTokensAndCall
     * Only the owner can call this method.
     */
    function setNativeTokenRequestGasLimits(
        uint256 _chainID,
        address _token,
        uint256[] calldata _gasLimits
    ) external onlyOwner validGasLimits(_chainID, 2, _gasLimits) {
        require(_gasLimits[1] >= _gasLimits[0]);
        selectorTokenGasLimit[_chainID][BasicOmnibridge.handleBridgedTokens.selector][_token] = _gasLimits[0];
        selectorTokenGasLimit[_chainID][BasicOmnibridge.handleBridgedTokensAndCall.selector][_token] = _gasLimits[1];
    }

    /**
     * @dev Internal function to add new bridges or change existing ones .
     * @param _chainID required network id.
     * @param _bridgeContract address of the bridge contract on the Home side.
     * @param _gasLimit default gas limit
     */
    function _setBridgeContract(
        uint256 _chainID,
        IAMB _bridgeContract,
        uint256 _gasLimit
    ) internal {
        require(_gasLimit <= _bridgeContract.maxGasPerTx());

        bridges[_chainID] = _bridgeContract;
        defaultGasLimits[_chainID] = _gasLimit;
    }
}

// File: contracts/upgradeable_contracts/modules/gas_limit/SelectorTokenGasLimitConnector.sol

pragma solidity 0.7.5;




/**
 * @title SelectorTokenGasLimitConnector
 * @dev Connectivity functionality that is required for using gas limit manager.
 */
abstract contract SelectorTokenGasLimitConnector is Ownable, BasicAMBMediator {
    bytes32 internal constant GAS_LIMIT_MANAGER_CONTRACT =
        0x5f5bc4e0b888be22a35f2166061a04607296c26861006b9b8e089a172696a822; // keccak256(abi.encodePacked("gasLimitManagerContract"))

    /**
     * @dev Updates an address of the used gas limit manager contract.
     * @param _manager address of gas limit manager contract.
     */
    function setGasLimitManager(address _manager) external onlyOwner {
        _setGasLimitManager(_manager);
    }

    /**
     * @dev Retrieves an address of the gas limit manager contract.
     * @return address of the gas limit manager contract.
     */
    function gasLimitManager() public view returns (SelectorTokenGasLimitManager) {
        return SelectorTokenGasLimitManager(addressStorage[GAS_LIMIT_MANAGER_CONTRACT]);
    }

    /**
     * @dev Internal function for updating an address of the used gas limit manager contract.
     * @param _manager address of gas limit manager contract.
     */
    function _setGasLimitManager(address _manager) internal {
        require(_manager == address(0) || Address.isContract(_manager));
        addressStorage[GAS_LIMIT_MANAGER_CONTRACT] = _manager;
    }

    /**
     * @dev Tells the gas limit to use for the message execution by the AMB bridge on the other network.
     * @param _chainID required network id.
     * @param _data calldata to be used on the other side of the bridge, when execution a message.
     * @return the gas limit for the message execution.
     */
    function _chooseRequestGasLimit(uint256 _chainID, bytes memory _data) internal view returns (uint256) {
        SelectorTokenGasLimitManager manager = gasLimitManager();
        if (address(manager) == address(0)) {
            return bridgeContract(_chainID).maxGasPerTx();
        } else {
            require(manager.isNetworkExists(_chainID), "Network does not exist.");
            return manager.requestGasLimit(_chainID, _data);
        }
    }
}

// File: contracts/upgradeable_contracts/MultiChainOmnibridge.sol

pragma solidity 0.7.5;




/**
 * @title MultiChainOmnibridge
 * @dev implementation for multi-chain multi-token mediator intended to work on top of AMB bridge.
 * It is designed to be used as an implementation contract of EternalStorageProxy contract.
 */
contract MultiChainOmnibridge is BasicOmnibridge, SelectorTokenGasLimitConnector, OmnibridgeFeeManagerConnector {
    using SafeMath for uint256;

    constructor(string memory _suffix) BasicOmnibridge(_suffix) {}

    /**
     * @dev Stores the initial parameters of the mediator.
     * @param _chainIDs array of the specific network ids.
     * @param _bridgeContracts array of the addresses of the AMB bridge contracts.
     * @param _mediatorContracts array of the addresses of the mediator contracts on the other network.
     * @param _dailyLimitMaxPerTxMinPerTxArray array with limit values for the assets to be bridged to the other network.
     *   [ 0 = dailyLimit, 1 = maxPerTx, 2 = minPerTx ]
     * @param _executionDailyLimitExecutionMaxPerTxArray array with limit values for the assets bridged from the other network.
     *   [ 0 = executionDailyLimit, 1 = executionMaxPerTx ]
     * @param _gasLimitManager the gas limit manager contract address.
     * @param _owner address of the owner of the mediator contract.
     * @param _feeManager address of the OmnibridgeFeeManager contract that will be used for fee distribution.
     */
    function initialize(
        uint256[] memory _chainIDs,
        address[] memory _bridgeContracts,
        address[] memory _mediatorContracts,
        uint256[3] calldata _dailyLimitMaxPerTxMinPerTxArray, // [ 0 = _dailyLimit, 1 = _maxPerTx, 2 = _minPerTx ]
        uint256[2] calldata _executionDailyLimitExecutionMaxPerTxArray, // [ 0 = _executionDailyLimit, 1 = _executionMaxPerTx ]
        address _gasLimitManager,
        address _owner,
        address _feeManager
    ) external onlyRelevantSender returns (bool) {
        require(!isInitialized());

        require(
            _chainIDs.length == _bridgeContracts.length && _chainIDs.length == _mediatorContracts.length,
            "Lengths mismatch."
        );

        for (uint256 i = 0; i < _chainIDs.length; i++) {
            _setBridgeContract(_chainIDs[i], _bridgeContracts[i]);
            _setMediatorContractOnOtherSide(_chainIDs[i], _mediatorContracts[i]);
        }

        _setLimits(address(0), _dailyLimitMaxPerTxMinPerTxArray);
        _setExecutionLimits(address(0), _executionDailyLimitExecutionMaxPerTxArray);
        _setGasLimitManager(_gasLimitManager);
        _setOwner(_owner);
        _setFeeManager(_feeManager);

        setInitialize();

        return isInitialized();
    }

    /**
     * One-time function to be used together with upgradeToAndCall method.
     * Sets the token factory contract. Resumes token bridging in the home to foreign direction.
     * @param _gasLimitManager address of the deployed SelectorTokenGasLimitManager contract.
     * @param _dailyLimit default daily limits used before stopping the bridge operation.
     */
    function upgradeToReverseMode(address _gasLimitManager, uint256 _dailyLimit) external {
        require(msg.sender == address(this));

        _setGasLimitManager(_gasLimitManager);

        uintStorage[keccak256(abi.encodePacked("dailyLimit", address(0)))] = _dailyLimit;

        emit DailyLimitChanged(address(0), _dailyLimit);
    }

    /**
     * @dev Alias for homeToken for interface compatibility with the prior version of the Home mediator.
     * @param _chainID specific network id.
     * @param _foreignToken address of the native token contract on the other side.
     * @return address of the deployed bridged token contract.
     */
    function homeTokenAddress(uint256 _chainID, address _foreignToken) public view returns (address) {
        return homeToken(_chainID, _foreignToken);
    }

    /**
     * @dev Alias for foreignToken for interface compatibility with the prior version of the Home mediator.
     * @param _chainID specific network id.
     * @param _homeToken address of the created bridged token contract on this side.
     * @return address of the native token contract on the other side of the bridge.
     */
    function foreignTokenAddress(uint256 _chainID, address _homeToken) public view returns (address) {
        return foreignToken(_chainID, _homeToken);
    }

    /**
     * @dev Handles the bridged tokens.
     * Checks that the value is inside the execution limits and invokes the Mint or Unlock accordingly.
     * @param _chainID specific network id.
     * @param _token token contract address on this side of the bridge.
     * @param _recipient address that will receive the tokens.
     * @param _value amount of tokens to be received.
     */
    function _handleTokens(
        uint256 _chainID,
        address _token,
        address _recipient,
        uint256 _value
    ) internal override {
        // prohibit withdrawal of tokens during other bridge operations (e.g. relayTokens)
        // such reentrant withdrawal can lead to an incorrect balanceDiff calculation
        require(!lock());

        require(withinExecutionLimit(_token, _value));
        addTotalExecutedPerDay(_token, getCurrentDay(), _value);

        uint256 valueToBridge = _value;
        uint256 fee = _distributeFee(FOREIGN_TO_HOME_FEE, address(0), _token, valueToBridge);
        bytes32 _messageId = messageId(_chainID);
        if (fee > 0) {
            emit FeeDistributed(fee, _token, _messageId);
            valueToBridge = valueToBridge.sub(fee);
        }

        _releaseTokens(_token, _recipient, valueToBridge, _value);

        emit TokensBridged(_chainID, _token, _recipient, valueToBridge, _messageId);
    }

    /**
     * @dev Executes action on deposit of bridged tokens.
     * @param _chainID network id on the other side.
     * @param _token address of the token contract.
     * @param _from address of tokens sender.
     * @param _receiver address of tokens receiver on the other side.
     * @param _value requested amount of bridged tokens.
     * @param _data additional transfer data to be used on the other side.
     */
    function bridgeSpecificActionsOnTokenTransfer(
        uint256 _chainID,
        address _token,
        address _from,
        address _receiver,
        uint256 _value,
        bytes memory _data
    ) internal override {
        require(isSupportedChain(_chainID), "Unsupported chain.");
        require(_receiver != address(0) && _receiver != mediatorContractOnOtherSide(_chainID));
        require(foreignToken(_chainID, _token) != address(0));

        if (!isTokenRegistered(_token)) {
            _initializeTokenBridgeLimits(_token, TokenReader.readDecimals(_token));
        }

        require(withinLimit(_token, _value));
        addTotalSpentPerDay(_token, getCurrentDay(), _value);

        uint256 fee = _distributeFee(HOME_TO_FOREIGN_FEE, _from, _token, _value);
        uint256 valueToBridge = _value.sub(fee);

        bytes memory data = _prepareMessage(_token, _receiver, valueToBridge, _data);

        // Address of the home token is used here for determining lane permissions.
        bytes32 _messageId = _passMessage(_chainID, data);
        _recordBridgeOperation(_chainID, _messageId, _token, _from, valueToBridge);
        if (fee > 0) {
            emit FeeDistributed(fee, _token, _messageId);
        }
    }

    /**
     * @dev Internal function for sending an AMB message to the mediator on the other side.
     * @param _chainID destination network id.
     * @param _data data to be sent to the other side of the bridge.
     * @return id of the sent message.
     */
    function _passMessage(uint256 _chainID, bytes memory _data) internal override returns (bytes32) {
        return
            bridgeContract(_chainID).requireToPassMessage(
                mediatorContractOnOtherSide(_chainID),
                _data,
                _chooseRequestGasLimit(_chainID, _data)
            );
    }
}