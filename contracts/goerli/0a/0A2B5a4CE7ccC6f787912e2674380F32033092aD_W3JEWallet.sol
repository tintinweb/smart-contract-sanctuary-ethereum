// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

///////////////////////////////////
// | |     / /__  /    / / ____/ //
// | | /| / / /_ <__  / / __/    //
// | |/ |/ /___/ / /_/ / /___    //
// |__/|__//____/\____/_____/    //
///////////////////////////////////

interface IW3JEAccessControl {
    function signer() external returns(address);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account) external returns(bool);

    function setSigner(address value) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./IW3JEAccessControl.sol";

///////////////////////////////////
// | |     / /__  /    / / ____/ //
// | | /| / / /_ <__  / / __/    //
// | |/ |/ /___/ / /_/ / /___    //
// |__/|__//____/\____/_____/    //
///////////////////////////////////

abstract contract W3JEAccessControled {
    bytes32 public constant ADMIN = "ADMIN";
    IW3JEAccessControl public ac;

    modifier onlyAdmin() {
        require(ac.hasRole(ADMIN, msg.sender), "not admin.");
        _;
    }

    function getSigner() internal virtual returns (address) {
        return ac.signer();
    }

    modifier onlyOwnerOrAdmin() {
        if(address(ac) != address(0)) {
            require(msg.sender == owner() || ac.hasRole(ADMIN, msg.sender), "not owner and admin.");
        } else {
            require(msg.sender == owner(), "not owner.");
        }
        _;
    }

    function owner() public view virtual returns(address);

    function setAc(address value) external onlyOwnerOrAdmin {
        _setAc(value);
    }
    
    function _setAc(address value) internal virtual {
        ac = IW3JEAccessControl(value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

///////////////////////////////////
// | |     / /__  /    / / ____/ //
// | | /| / / /_ <__  / / __/    //
// | |/ |/ /___/ / /_/ / /___    //
// |__/|__//____/\____/_____/    //
///////////////////////////////////

interface IW3JEWallet {
    function account() external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

library Contributors {
    struct Contributor {
        address payable payee;
        uint16 weight;
    }

    struct Set {
        Contributor[] _values;
        mapping(address => uint256) _indexes;
    }

    function add(Set storage set, Contributor memory contributor)
        internal
        returns (bool)
    {
        if (!contains(set, contributor.payee)) {
            set._values.push(contributor);
            set._indexes[contributor.payee] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function update(Set storage set, Contributor memory contributor)
        internal
        returns (bool)
    {
        if (contains(set, contributor.payee)) {
            uint256 idx = set._indexes[contributor.payee];
            set._values[idx - 1].weight = contributor.weight;
            return true;
        } else {
            return false;
        }
    }

    function remove(Set storage set, address contributorAddress)
        internal
        returns (bool)
    {
        uint256 valueIndex = set._indexes[contributorAddress];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                Contributor storage lastValue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue.payee] = valueIndex;
            }

            set._values.pop();
            delete set._indexes[contributorAddress];

            return true;
        } else {
            return false;
        }
    }

    function contains(Set storage set, address contributorAddress)
        internal
        view
        returns (bool)
    {
        return
            set._indexes[contributorAddress] != 0;
    }

    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    function at(Set storage set, uint256 index)
        internal
        view
        returns (Contributor memory)
    {
        return set._values[index];
    }

    function values(Set storage set)
        internal
        view
        returns (Contributor[] memory)
    {
        return set._values;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./IW3JEWallet.sol";
import "./libs/Contributors.sol";
import "../AccessControl/W3JEAccessControled.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

///////////////////////////////////
// | |     / /__  /    / / ____/ //
// | | /| / / /_ <__  / / __/    //
// | |/ |/ /___/ / /_/ / /___    //
// |__/|__//____/\____/_____/    //
///////////////////////////////////

contract W3JEWallet is W3JEAccessControled, IW3JEWallet, Ownable {
    using Contributors for Contributors.Set;
    using Address for address payable;
    Contributors.Set private _contributors;

    function addContributor(Contributors.Contributor memory contributor)
        public
        onlyAdmin
    {
        _contributors.add(contributor);
    }

    function updateContributor(Contributors.Contributor memory contributor)
        public
        onlyAdmin
    {
        _contributors.update(contributor);
    }

    function removeContributor(address payable contributorAddress)
        public
        onlyAdmin
    {
        _contributors.remove(contributorAddress);
    }

    function getContributors()
        public
        view
        returns (Contributors.Contributor[] memory)
    {
        return _contributors.values();
    }

    function account() external payable {
        uint256 total = 0;
        for (uint256 i = 0; i < _contributors.length(); i++) {
            total += _contributors.at(i).weight;
        }

        uint256 value = msg.value;
        uint256 rest = value;
        for (uint256 i = 0; i < _contributors.length(); i++) {
            if (i + 1 == _contributors.length()) {
                _contributors.at(i).payee.sendValue(rest);
            } else {
                uint256 amount = (value * _contributors.at(i).weight) / total;
                _contributors.at(i).payee.sendValue(amount);
                rest -= amount;
            }
        }
    }

    function withdraw() public payable onlyAdmin {
        payable(owner()).sendValue(address(this).balance);
    }

    // ==================================================================
    // Ownable
    // ==================================================================
    function owner() public view virtual override(Ownable, W3JEAccessControled) returns (address) {
        return Ownable.owner();
    }
}