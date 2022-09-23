/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts/proxy/beacon/[email protected]

// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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


// File contracts/interface/IConfigV1.sol

pragma solidity ^0.8.0;

interface IConfigV1 {
  function USDTToken() external view returns (address);

  function CLIPToken() external view returns (address);

  function stakeAddr() external view returns (address);

  function isStake() external view returns (bool);

  function stakeCoinAddr() external view returns (address);

  function collectFactoryAddr() external view returns (address);

  function packageFactoryAddr() external view returns (address);

  // 兼容normal and upgradeable.
  function supportsInterface(bytes4 interfaceId) external view returns (bool);

  function setStakeCoinAddr(address addr) external;

  function setStakeAddr(address _stakeAddr) external;

  function setStakeStatus(bool _status) external;

  function setFee(uint256 _fee) external;

  function getFee() external view returns (uint256);

  function setPlatform(address _platformAddress) external;

  function getPlatform() external view returns (address);

  function setPackageFactory(address _to) external;

  function setCollectFactory(address _to) external;

  function addExecutor(address _to) external;

  function getExecutor() external view returns (address);

  // role
  function isAdmin(address addr) external view returns (bool yes);

  function hasRole(bytes32 role, address addr) external view returns (bool yes);
}


// File contracts/library/DefineRole.sol

pragma solidity ^0.8.0;

library DefineRole {
  //////////////////// constant
  bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

  // const, keccak256("ADMIN_ROLE");
  bytes32 internal constant ADMIN_ROLE =
    0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775;
  // 0x0000000000000000000000000000000000000000000000000000000000000000

  // keccak256("CREATER_ROLE")
  bytes32 internal constant CREATER_ROLE =
    0x1ac401dd2c6f22b9676f8528d637846252ce7c4e00341d11c712c96f29bc47b3;

  // keccak256("HUNTER_ROLE")
  bytes32 internal constant HUNTER_ROLE =
    0xbc7cd1906cf807c8f89dc868f0a8d55007c0e0aaaf7b083aeb000f5f5fc79d15;

  // keccak256("beacon.BEACON_UPGRADER")
  bytes32 internal constant BEACON_UPGRADER =
    0xfc89e8fcf76a4f1903edd1402e5aaf523e5c7aea361001808058bfbc1d541ed0;
}


// File contracts/base/BaseVerifyV1.sol

pragma solidity ^0.8.0;



abstract contract BaseVerifyV1 is Context {
  //////////////////// constant
  bytes32 private constant DEFAULT_ADMIN_ROLE = 0x00;

  //////////////////// storage
  IConfigV1 public config;

  constructor(address addr) {
    config = IConfigV1(addr);
    require(
      config.supportsInterface(type(IConfigV1).interfaceId),
      'not support addr'
    );
  }

  modifier IsAdmin() {
    require(config.isAdmin(_msgSender()), 'not admin');
    _;
  }

  modifier onlyRole(bytes32 role) {
    require(
      config.hasRole(role, _msgSender()) ||
        config.hasRole(DefineRole.DEFAULT_ADMIN_ROLE, _msgSender()),
      'not has role'
    );
    _;
  }
}


// File contracts/proxy/BFBeacon.sol

pragma solidity ^0.8.0;


contract BFBeacon is IBeacon, BaseVerifyV1 {
  address private _implementation;

  /**
   * @dev Emitted when the implementation returned by the beacon is changed.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
   * beacon.
   */
  constructor(address implementationAddr, address configAddr)
    BaseVerifyV1(configAddr)
  {
    _setImplementation(implementationAddr);
  }

  modifier IsBeaconUpgrader() {
    require(
      config.hasRole(DefineRole.BEACON_UPGRADER, _msgSender()),
      'not beacon upgrader'
    );
    _;
  }

  /**
   * @dev Returns the current implementation address.
   */
  function implementation() public view virtual override returns (address) {
    return _implementation;
  }

  /**
   * @dev Upgrades the beacon to a new implementation.
   *
   * Emits an {Upgraded} event.
   *
   * Requirements:
   *
   * - msg.sender must be the owner of the contract.
   * - `newImplementation` must be a contract.
   */
  function upgradeTo(address newImplementation)
    public
    virtual
    IsBeaconUpgrader
  {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation contract address for this beacon
   *
   * Requirements:
   *
   * - `newImplementation` must be a contract.
   */
  function _setImplementation(address newImplementation) private {
    require(
      Address.isContract(newImplementation),
      'UpgradeableBeacon: implementation is not a contract'
    );
    _implementation = newImplementation;
  }
}