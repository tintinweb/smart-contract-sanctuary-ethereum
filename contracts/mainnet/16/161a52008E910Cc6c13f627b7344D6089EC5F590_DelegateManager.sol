// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Clones} from "../../lib/Clones.sol";
import {Address} from "../../lib/Address.sol";

import {IDelegate} from "./IDelegate.sol";
import {IDelegateDeployer} from "./IDelegateDeployer.sol";

contract DelegateDeployer is IDelegateDeployer {
    address private immutable _delegatePrototype;

    constructor(address delegatePrototype_) {
        require(delegatePrototype_ != address(0), "DF: zero delegate proto");
        _delegatePrototype = delegatePrototype_;
    }

    function predictDelegateDeploy(address account_) public view returns (address) {
        return Clones.predictDeterministicAddress(_delegatePrototype, _calcSalt(account_));
    }

    function deployDelegate(address account_) public returns (address) {
        address delegate = Clones.cloneDeterministic(_delegatePrototype, _calcSalt(account_));
        IDelegate(delegate).initialize();
        IDelegate(delegate).transferOwnership(account_);
        return delegate;
    }

    function isDelegateDeployed(address account_) public view returns (bool) {
        address delegate = predictDelegateDeploy(account_);
        return Address.isContract(delegate);
    }

    function _calcSalt(address account_) private pure returns (bytes32) {
        return bytes20(account_);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {IAccountWhitelist} from "../whitelist/IAccountWhitelist.sol";

import {Withdraw} from "../withdraw/IWithdrawable.sol";

import {IDelegate} from "./IDelegate.sol";
import {IDelegateManager} from "./IDelegateManager.sol";
import {DelegateDeployer} from "./DelegateDeployer.sol";

struct DelegateManagerConstructorParams {
    /**
     * @dev {IDelegate}-compatible contract address
     */
    address delegatePrototype;
    /**
     * @dev {IAccountWhitelist}-compatible contract address
     */
    address withdrawWhitelist;
}

/**
 * @dev Inherits {DelegateDeployer} to have access to delegates as their initializer
 */
contract DelegateManager is IDelegateManager, DelegateDeployer {
    address private immutable _withdrawWhitelist;

    // prettier-ignore
    constructor(DelegateManagerConstructorParams memory params_)
        DelegateDeployer(params_.delegatePrototype)
    {
        require(params_.withdrawWhitelist != address(0), "DF: zero withdraw whitelist");
        _withdrawWhitelist = params_.withdrawWhitelist;
    }

    modifier onlyWhitelistedWithdrawer() {
        require(
            IAccountWhitelist(_withdrawWhitelist).isAccountWhitelisted(msg.sender),
            "DF: withdrawer not whitelisted"
        );
        _;
    }

    modifier asDelegateOwner(address delegate_) {
        address savedOwner = IDelegate(delegate_).owner();
        IDelegate(delegate_).setOwner(address(this));
        _;
        IDelegate(delegate_).setOwner(savedOwner);
    }

    function withdraw(address account_, Withdraw[] calldata withdraws_) external onlyWhitelistedWithdrawer {
        address delegate = predictDelegateDeploy(account_);
        _withdraw(delegate, withdraws_);
    }

    function _withdraw(address delegate_, Withdraw[] calldata withdraws_) private asDelegateOwner(delegate_) {
        IDelegate(delegate_).withdraw(withdraws_);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {IOwnable} from "../../lib/IOwnable.sol";

import {ISimpleInitializable} from "../init/ISimpleInitializable.sol";

import {IWithdrawable} from "../withdraw/IWithdrawable.sol";

import {IOwnershipManageable} from "./IOwnershipManageable.sol";

// solhint-disable-next-line no-empty-blocks
interface IDelegate is ISimpleInitializable, IOwnable, IWithdrawable, IOwnershipManageable {

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

interface IDelegateDeployer {
    function predictDelegateDeploy(address account) external view returns (address);

    function deployDelegate(address account) external returns (address);

    function isDelegateDeployed(address account) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {Withdraw} from "../withdraw/IWithdrawable.sol";

import {IDelegateDeployer} from "./IDelegateDeployer.sol";

interface IDelegateManager is IDelegateDeployer {
    function withdraw(address account, Withdraw[] calldata withdraws) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

interface IOwnershipManageable {
    function setOwner(address newOwner) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

interface IInitializable {
    function initialized() external view returns (bool);

    function initializer() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {IInitializable} from "./IInitializable.sol";

interface ISimpleInitializable is IInitializable {
    function initialize() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

interface IAccountWhitelist {
    event AccountAdded(address account);
    event AccountRemoved(address account);

    function getWhitelistedAccounts() external view returns (address[] memory);

    function isAccountWhitelisted(address account) external view returns (bool);

    function addAccountToWhitelist(address account) external;

    function removeAccountFromWhitelist(address account) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

struct Withdraw {
    address token;
    uint256 amount;
    address to;
}

interface IWithdrawable {
    event Withdrawn(address token, uint256 amount, address to);

    function withdraw(Withdraw[] calldata withdraws) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {Address} implementation:
 * - bump `pragma solidity` (`^0.8.1` -> `^0.8.16`)
 * - shortify `require` messages (`Address:` -> `AD:` + others to avoid length warnings)
 * - disable some `solhint` rules for the file
 */

/* solhint-disable avoid-low-level-calls */

pragma solidity ^0.8.16;

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
        require(address(this).balance >= amount, "AD: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "AD: unable to send value");
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
        return functionCallWithValue(target, data, 0, "AD: low-level call fail");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "AD: low-level value call fail");
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
        require(address(this).balance >= value, "AD: not enough balance for call");
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
        return functionStaticCall(target, data, "AD: low-level static call fail");
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
        return functionDelegateCall(target, data, "AD: low-level delegate call fail");
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
                require(isContract(target), "AD: call to non-contract");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {Clones} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 * - shortify `require` messages (`ERC1167:` -> `CL:`)
 */

pragma solidity ^0.8.16;

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
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "CL: create failed");
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
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "CL: create2 failed");
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
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IOwnable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external;

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;
}