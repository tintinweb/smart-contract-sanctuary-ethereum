// SPDX-License-Identifier: GPL-3.0 License

pragma solidity >=0.8.0;

import "./BLXMMultiOwnable.sol";
import "./interfaces/IBLXMTreasury.sol";

import "./interfaces/IERC20.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/BLXMLibrary.sol";


contract BLXMTreasury is BLXMMultiOwnable, IBLXMTreasury {

    address public override BLXM;
    address public override SSC;

    mapping(address => bool) public override whitelist;

    uint public override totalBlxm;
    uint public override totalRewards;
    mapping(address => uint) public override balanceOf;


    modifier onlySsc() {
        require(msg.sender == SSC, 'NOT_SSC');
        _;
    }

    function initialize(address _BLXM, address _SSC) public initializer {
        __BLXMMultiOwnable_init();
        
        SSC = _SSC;
        BLXM = _BLXM;
    }

    function addRewards(uint amount) external override onlySsc {
        require(amount != 0, 'INSUFFICIENT_AMOUNT');
        totalRewards += amount;
    }

    function addBlxmTokens(uint amount, address to) external override onlySsc {
        BLXMLibrary.validateAddress(to);
        balanceOf[to] += amount;
        totalBlxm += amount;
    }

    function retrieveBlxmTokens(address from, uint amount, uint rewardAmount, address to) external override onlySsc {
        BLXMLibrary.validateAddress(from);
        BLXMLibrary.validateAddress(to);

        uint _balance = balanceOf[from];
        require(_balance >= amount, 'INSUFFICIENT_BALANCE');
        uint _totalBlxm = totalBlxm;
        require(_totalBlxm >= amount, 'INSUFFICIENT_BLXM');
        uint _totalRewards = totalRewards;
        require(totalRewards >= rewardAmount, 'INSUFFICIENT_REWARDS');
        uint totalTransfer = rewardAmount + amount;
        require(IERC20(BLXM).balanceOf(address(this)) >= totalTransfer, 'INSUFFICIENT_CONTRACT_BALANCE');

        totalBlxm = _totalBlxm - amount;
        balanceOf[from] = _balance - amount;
        totalRewards = _totalRewards - rewardAmount;
        TransferHelper.safeTransfer(BLXM, to, totalTransfer);
    }

    function addWhitelist(address wallet) external override onlyOwner {
        BLXMLibrary.validateAddress(wallet);
        require(!whitelist[wallet], 'IS_WHITELIST');
        whitelist[wallet] = true;
        emit Whitelist(msg.sender, true, wallet);
    }

    function removeWhitelist(address wallet) external override onlyOwner {
        BLXMLibrary.validateAddress(wallet);
        require(whitelist[wallet], 'NOT_WHITELIST');
        whitelist[wallet] = false;
        emit Whitelist(msg.sender, false, wallet);
    }

    function sendTokensToWhitelistedWallet(uint amount, address to) external override onlyOwner {
        require(whitelist[to], 'NOT_IN_WHITELIST');
        require(IERC20(BLXM).balanceOf(address(this)) >= amount, 'NOT_ENOUGH_AMOUNT');

        TransferHelper.safeTransfer(BLXM, to, amount);
        emit SendTokensToWhitelistedWallet(msg.sender, amount, to);
    }

    /**
    * This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./libraries/BLXMLibrary.sol";


abstract contract BLXMMultiOwnable is Initializable {
    
    // member address => permission
    mapping(address => bool) public members;

    event OwnershipChanged(address indexed executeOwner, address indexed targetOwner, bool permission);

    modifier onlyOwner() {
        require(members[msg.sender], "NOT_OWNER");
        _;
    }

    function __BLXMMultiOwnable_init() internal onlyInitializing {
        _changeOwnership(msg.sender, true);
    }

    function addOwnership(address newOwner) public virtual onlyOwner {
        BLXMLibrary.validateAddress(newOwner);
        _changeOwnership(newOwner, true);
    }

    function removeOwnership(address owner) public virtual onlyOwner {
        BLXMLibrary.validateAddress(owner);
        _changeOwnership(owner, false);
    }

    function _changeOwnership(address owner, bool permission) internal virtual {
        members[owner] = permission;
        emit OwnershipChanged(msg.sender, owner, permission);
    }

    /**
    * This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IBLXMTreasury {

    event SendTokensToWhitelistedWallet(address indexed sender, uint amount, address indexed receiver);
    event Whitelist(address indexed sender, bool permission, address indexed wallet);


    function BLXM() external returns (address blxm);
    function SSC() external returns (address ssc);

    function addWhitelist(address wallet) external;
    function removeWhitelist(address wallet) external;
    function whitelist(address wallet) external returns (bool permission);

    function totalBlxm() external view returns (uint totalBlxm);
    function totalRewards() external view returns (uint totalRewards);
    function balanceOf(address investor) external view returns (uint balance);

    function addRewards(uint amount) external;

    function addBlxmTokens(uint amount, address to) external;
    function retrieveBlxmTokens(address from, uint amount, uint rewardAmount, address to) external;

    function sendTokensToWhitelistedWallet(uint amount, address to) external;
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

// helper methods for interacting with BEP20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferCurrency(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: CURRENCY_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


library BLXMLibrary {

    function validateAddress(address _address) internal pure {
        // reduce contract size
        require(_address != address(0), "ZERO_ADDRESS");
    }

    function currentHour() internal view returns(uint32) {
        return uint32(block.timestamp / 1 hours);
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