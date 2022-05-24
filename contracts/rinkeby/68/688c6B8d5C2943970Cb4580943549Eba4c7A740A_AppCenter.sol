//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./core/Core.sol";

contract AppCenter is Core {
    constructor(address[] memory owners_) Core("AppCenterV1", owners_) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./WhitelistedContracts.sol";
import "../interface/ICoreCell.sol";
import "../interface/ICore.sol";
import "../lib/Role.sol";
import "../lib/Utils.sol";

/**
 * @author Mac Lisowski
 */
contract Core is WhitelistedContracts, ICore {
    using Address for address;

    // --- EVENTS --- //
    event RoleGranted(address grantedBy, address who);
    event RoleRevoked(address revokedBy, address who);
    event PausedContract(address whoPaused, address contractAddress);
    event UnpausedContract(address whoUnpaused, address contractAddress);

    // --- ERRORS --- //
    error NotEnoughOwners();
    error Unauthorized();
    error RoleAlreadyGranted();
    error RoleNotGranted();
    error AddressNotContract();

    // --- PROPERTIES --- //
    string private _name;
    mapping(bytes32 => address[]) internal _userPermissions;

    constructor(string memory name_, address[] memory owners_) {
        if (owners_.length < 1) {
            revert NotEnoughOwners();
        }

        _grantRoleToMany(Role.OWNER, owners_);
        _name = name_;
    }

    // -- PUBLIC / EXTERNAL -- //

    /**
     * @dev Returns name of the contract
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Checks if address has OWNER role
     *
     * Returns bool
     */
    function isOwner(address address_) override external view returns (bool) {
        return _hasAccess(Role.OWNER, address_);
    }

    /**
     * @dev Gets list of owners addresses
     *
     * Returns array of addresses.
     */
    function getOwners() override external view returns (address[] memory) {
        return _userPermissions[Role.OWNER];
    }

    /**
     * @dev Returns true if {who_} has assigned {role_}
     */
    function hasAccess(bytes32 role_, address who_) override external view returns (bool) {
        return _hasAccess(role_, who_);
    }

    /**
     * @dev Grants {role_} for {who_}
     * Throws revert if Unauthorized or if {role_} is already granted
     * Only owners can call this method
     */
    function grantRole(bytes32 role_, address who_) override external {
        if (!_hasAccess(Role.OWNER, msg.sender))
            revert Unauthorized();

        _grantRole(role_, who_);
    }

    /**
     * @dev Revoke {role_} for {who_}
     * Throws revert if Unauthorized or if {role_} is not assigned to {who_}
     * Only owners can call this method
     */
    function revokeRole(bytes32 role_, address who_) override external {
        if (!_hasAccess(Role.OWNER, msg.sender))
            revert Unauthorized();

        _revokeRole(role_, who_);
    }

    /**
     * @dev Pause {contract_} which is whitelisted at Core to be part of the system
     */
    function pauseContract(address contract_) override external {
        if (!_hasAccess(Role.OWNER, msg.sender))
            revert Unauthorized();

        _pauseContract(contract_);
    }

    /**
     * @dev Unpause {contract_} which is whitelisted at Core to be part of the system
     */
    function unpauseContract(address contract_) override external {
        if (!_hasAccess(Role.OWNER, msg.sender))
            revert Unauthorized();

        _unpauseContract(contract_);
    }

    /**
     * @dev addWhitelistedContract registers {contract_} at given key {name_}
     * It allows for communication between Core and CoreCell contracts
     */
    function addWhitelistedContract(address contract_, string calldata name_) override external {
        if (!_hasAccess(Role.OWNER, msg.sender))
            revert Unauthorized();

        if(!contract_.isContract())
            revert AddressNotContract();

        _addWhitelistedContract(contract_, name_);
    }

    /**
     * @dev removeWhitelistedContract removes {contract_} at given key {name_}
     * When removed from whitelisted, communication between {contract_} and Core will be not possible
     */
    function removeWhitelistedContract(address contract_, string calldata name_) override external {
        if (!_hasAccess(Role.OWNER, msg.sender))
            revert Unauthorized();

        if(!contract_.isContract())
            revert AddressNotContract();

        _removeWhitelistedContract(contract_, name_);
    }

    // -- PRIVATE / INTERNAL -- //
    function _grantRoleToMany(bytes32 role_, address[] memory who_) private {
        uint i = 0;

        for(; i < who_.length;) {
            _grantRole(role_, who_[i]);
            unchecked { i++; }
        }
    }

    function _grantRole(bytes32 role_, address who_) private {
        if (_hasAccess(role_, who_))
            revert RoleAlreadyGranted();

        _userPermissions[role_].push(who_);

        emit RoleGranted(msg.sender, who_);
    }

    function _revokeRole(bytes32 role_, address who_) private {
        if (!_hasAccess(role_, who_))
            revert RoleNotGranted();

        address[] memory newRolePermissions = Utils.RemoveFromAddressArray(_userPermissions[role_], who_);
        _userPermissions[role_] = newRolePermissions;

        emit RoleRevoked(msg.sender, who_);
    }

    function _hasAccess(bytes32 role_, address who_) private view returns (bool) {
        if (_userPermissions[role_].length > 0 ) {
            uint i = 0;
            for(; i < _userPermissions[role_].length;) {
                if (_userPermissions[role_][i] == who_) {
                    return true;
                }
                unchecked { i++; }
            }
        }

        return false;
    }

    function _pauseContract(address contract_) private {
        if (!_isWhitelisted(contract_))
            revert NotWhitelisted();

        ICoreCell CoreCell = ICoreCell(contract_);

        if(CoreCell.pause() == true)
            emit PausedContract(msg.sender, contract_);
    }

    function _unpauseContract(address contract_) private {
        if (!_isWhitelisted(contract_))
            revert NotWhitelisted();

        ICoreCell CoreCell = ICoreCell(contract_);
        require(CoreCell.unpause() == true, "Unable to unpause contract");

        if(CoreCell.unpause() == true)
            emit UnpausedContract(msg.sender, contract_);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "../interface/IWhitelistedContracts.sol";

/**
 * @author Mac Lisowski
 */
contract WhitelistedContracts is IWhitelistedContracts {
    using Address for address;

    // --- ERRORS --- //
    error NotWhitelisted();

    // --- PROPERTIES --- //
    address[] internal whitelistedContracts;
    mapping(string => address) whitelistedNames;

    // --- PRIVATE/INTERNAL --- //
    function _addWhitelistedContract(address contractAddress, string calldata name_) internal {
        require(_getWhitelistedByName(name_) == address(0) && _isWhitelisted(contractAddress) != true, "Contract already whitelisted");

        whitelistedNames[name_] = contractAddress;
        whitelistedContracts.push(contractAddress);
    }

    function _removeWhitelistedContract(address contractAddress, string calldata name_) internal {
        require(_getWhitelistedByName(name_) == contractAddress && _isWhitelisted(contractAddress) == true, "Contract is not whitelisted");

        (address foundContract, uint key) = _getFromWhitelistedContracts(contractAddress);

        if (foundContract != address(0)) {
            delete whitelistedContracts[key];
            delete whitelistedNames[name_];
        }
    }

    function _getWhitelistedByName(string calldata name_) internal view returns (address) {
        return whitelistedNames[name_];
    }

    function getWhitelistedByName(string calldata name_) override external view returns (address) {
        return _getWhitelistedByName(name_);
    }

    function getWhitelistedContracts() public view returns (address[] memory) {
        return whitelistedContracts;
    }

    function _isWhitelisted(address contractAddress) internal view returns (bool) {
        (address foundContract, uint key) = _getFromWhitelistedContracts(contractAddress);

        if (foundContract != address(0)) {
            return true;
        }

        return false;
    }

    function _getFromWhitelistedContracts(address contractAddress) internal view returns (address, uint) {
        uint i = 0;
        for(; i < whitelistedContracts.length;) {
            if (whitelistedContracts[i] == contractAddress) {
                return (whitelistedContracts[i], i);
            }
            unchecked { i++; }
        }

        return (address(0), 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICoreCell {
    function pause() external returns (bool);
    function unpause() external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @author Mac Lisowski
 */
interface ICore {
    function getOwners() external view returns (address[] memory);
    function isOwner(address _address) external view returns (bool);
    function hasAccess(bytes32 role_, address who_) external view returns (bool);
    function grantRole(bytes32 role_, address who_) external;
    function revokeRole(bytes32 role_, address who_) external;
    function pauseContract(address contract_) external;
    function unpauseContract(address contract_) external;
    function addWhitelistedContract(address contract_, string memory name_) external;
    function removeWhitelistedContract(address contract_, string memory name_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Role {
    bytes32 public constant NONE = keccak256("");
    bytes32 public constant OWNER = keccak256("OWNER");
    bytes32 public constant TREASURY_MANAGER = keccak256("TREASURY_MANAGER");

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Utils {
    function RemoveFromAddressArray(address[] storage array_, address toRemove_) public returns (address[] memory) {
        uint256 i = 0;
        for(; i < array_.length;) {
            if (array_[i] == toRemove_) {
                array_[i] = array_[array_.length - 1];
                array_.pop();
                break;
            }
            unchecked { i++; }
        }

        return array_;
    }

    function RemoveFromUint256Array(uint256[] storage array_, uint256 toRemove_) public returns (uint256[] memory) {
        uint256 i = 0;
        for(; i < array_.length;) {
            if (array_[i] == toRemove_) {
                array_[i] = array_[array_.length - 1];
                array_.pop();
                break;
            }
            unchecked { i++; }
        }

        return array_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @author Mac Lisowski
 */
interface IWhitelistedContracts {
    function getWhitelistedByName(string calldata name_) external view returns (address);
}