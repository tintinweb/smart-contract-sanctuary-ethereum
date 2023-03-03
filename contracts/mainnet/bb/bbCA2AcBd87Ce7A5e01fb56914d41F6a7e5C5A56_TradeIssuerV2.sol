/**
 *     SPDX-License-Identifier: Apache License 2.0
 *
 *     Copyright 2018 Set Labs Inc.
 *     Copyright 2022 Smash Works Inc.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 *     NOTICE
 *
 *     This is a modified code from Set Labs Inc. found at
 *
 *     https://github.com/SetProtocol/set-protocol-contracts
 *
 *     All changes made by Smash Works Inc. are described and documented at
 *
 *     https://docs.arch.finance/chambers
 *
 *
 *             %@@@@@
 *          @@@@@@@@@@@
 *        #@@@@@     @@@           @@                   @@
 *       @@@@@@       @@@         @@@@                  @@
 *      @@@@@@         @@        @@  @@    @@@@@ @@@@@  @@@*@@
 *     [email protected]@@@@          @@@      @@@@@@@@   @@    @@     @@  @@
 *     @@@@@(       (((((      @@@    @@@  @@    @@@@@  @@  @@
 *    @@@@@@   (((((((
 *    @@@@@#(((((((
 *    @@@@@(((((
 *      @@@((
 */
pragma solidity ^0.8.17.0;

interface IChamber {
    /*//////////////////////////////////////////////////////////////
                                 ENUMS
    //////////////////////////////////////////////////////////////*/

    enum ChamberState {
        LOCKED,
        UNLOCKED
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ManagerAdded(address indexed _manager);

    event ManagerRemoved(address indexed _manager);

    event ConstituentAdded(address indexed _constituent);

    event ConstituentRemoved(address indexed _constituent);

    event WizardAdded(address indexed _wizard);

    event WizardRemoved(address indexed _wizard);

    event AllowedContractAdded(address indexed _allowedContract);

    event AllowedContractRemoved(address indexed _allowedContract);

    /*//////////////////////////////////////////////////////////////
                               CHAMBER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function addConstituent(address _constituent) external;

    function removeConstituent(address _constituent) external;

    function isManager(address _manager) external view returns (bool);

    function isWizard(address _wizard) external view returns (bool);

    function isConstituent(address _constituent) external view returns (bool);

    function addManager(address _manager) external;

    function removeManager(address _manager) external;

    function addWizard(address _wizard) external;

    function removeWizard(address _wizard) external;

    function getConstituentsAddresses() external view returns (address[] memory);

    function getQuantities() external view returns (uint256[] memory);

    function getConstituentQuantity(address _constituent) external view returns (uint256);

    function getWizards() external view returns (address[] memory);

    function getManagers() external view returns (address[] memory);

    function getAllowedContracts() external view returns (address[] memory);

    function mint(address _recipient, uint256 _quantity) external;

    function burn(address _from, uint256 _quantity) external;

    function withdrawTo(address _constituent, address _recipient, uint256 _quantity) external;

    function updateQuantities() external;

    function lockChamber() external;

    function unlockChamber() external;

    function addAllowedContract(address target) external;

    function removeAllowedContract(address target) external;

    function isAllowedContract(address _target) external returns (bool);

    function executeTrade(
        address _sellToken,
        uint256 _sellQuantity,
        address _buyToken,
        uint256 _minBuyQuantity,
        bytes memory _data,
        address payable _target,
        address _allowanceTarget
    ) external returns (uint256 tokenAmountBought);
}

/**
 *     SPDX-License-Identifier: Apache License 2.0
 *
 *     Copyright 2018 Set Labs Inc.
 *     Copyright 2022 Smash Works Inc.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 *     NOTICE
 *
 *     This is a modified code from Set Labs Inc. found at
 *
 *     https://github.com/SetProtocol/set-protocol-contracts
 *
 *     All changes made by Smash Works Inc. are described and documented at
 *
 *     https://docs.arch.finance/chambers
 *
 *
 *             %@@@@@
 *          @@@@@@@@@@@
 *        #@@@@@     @@@           @@                   @@
 *       @@@@@@       @@@         @@@@                  @@
 *      @@@@@@         @@        @@  @@    @@@@@ @@@@@  @@@*@@
 *     [email protected]@@@@          @@@      @@@@@@@@   @@    @@     @@  @@
 *     @@@@@(       (((((      @@@    @@@  @@    @@@@@  @@  @@
 *    @@@@@@   (((((((
 *    @@@@@#(((((((
 *    @@@@@(((((
 *      @@@((
 */
pragma solidity ^0.8.17.0;

interface IChamberGod {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ChamberCreated(address indexed _chamber, address _owner, string _name, string _symbol);

    event WizardAdded(address indexed _wizard);

    event WizardRemoved(address indexed _wizard);

    event AllowedContractAdded(address indexed _allowedContract);

    event AllowedContractRemoved(address indexed _allowedContract);

    /*//////////////////////////////////////////////////////////////
                            CHAMBER GOD LOGIC
    //////////////////////////////////////////////////////////////*/

    function createChamber(
        string memory _name,
        string memory _symbol,
        address[] memory _constituents,
        uint256[] memory _quantities,
        address[] memory _wizards,
        address[] memory _managers
    ) external returns (address);

    function getWizards() external view returns (address[] memory);

    function getChambers() external view returns (address[] memory);

    function isWizard(address _wizard) external view returns (bool);

    function isChamber(address _chamber) external view returns (bool);

    function addWizard(address _wizard) external;

    function removeWizard(address _wizard) external;

    function getAllowedContracts() external view returns (address[] memory);

    function addAllowedContract(address _target) external;

    function removeAllowedContract(address _target) external;

    function isAllowedContract(address _target) external view returns (bool);
}

/**
 *     SPDX-License-Identifier: Apache License 2.0
 *
 *     Copyright 2018 Set Labs Inc.
 *     Copyright 2022 Smash Works Inc.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 *     NOTICE
 *
 *     This is a modified code from Set Labs Inc. found at
 *
 *     https://github.com/SetProtocol/set-protocol-contracts
 *
 *     All changes made by Smash Works Inc. are described and documented at
 *
 *     https://docs.arch.finance/chambers
 *
 *
 *             %@@@@@
 *          @@@@@@@@@@@
 *        #@@@@@     @@@           @@                   @@
 *       @@@@@@       @@@         @@@@                  @@
 *      @@@@@@         @@        @@  @@    @@@@@ @@@@@  @@@*@@
 *     [email protected]@@@@          @@@      @@@@@@@@   @@    @@     @@  @@
 *     @@@@@(       (((((      @@@    @@@  @@    @@@@@  @@  @@
 *    @@@@@@   (((((((
 *    @@@@@#(((((((
 *    @@@@@(((((
 *      @@@((
 */
pragma solidity ^0.8.17.0;

import {IChamber} from "./IChamber.sol";

interface IIssuerWizard {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ChamberTokenIssued(address indexed chamber, address indexed recipient, uint256 quantity);

    event ChamberTokenRedeemed(
        address indexed chamber, address indexed recipient, uint256 quantity
    );

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getConstituentsQuantitiesForIssuance(IChamber chamber, uint256 mintQuantity)
        external
        view
        returns (address[] memory, uint256[] memory);

    function getConstituentsQuantitiesForRedeem(IChamber chamber, uint256 redeemQuantity)
        external
        view
        returns (address[] memory, uint256[] memory);

    function issue(IChamber chamber, uint256 quantity) external;

    function redeem(IChamber _chamber, uint256 _quantity) external;
}

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

import {ERC20} from "./ERC20.sol";

import {SafeTransferLib} from "../utils/SafeTransferLib.sol";

/// @notice Minimalist and modern Wrapped Ether implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/WETH.sol)
/// @author Inspired by WETH9 (https://github.com/dapphub/ds-weth/blob/master/src/weth9.sol)
contract WETH is ERC20("Wrapped Ether", "WETH", 18) {
    using SafeTransferLib for address;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);

        msg.sender.safeTransferETH(amount);
    }

    receive() external payable virtual {
        deposit();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
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

/**
 *     SPDX-License-Identifier: Apache License 2.0
 *
 *     Copyright 2021 Index Cooperative
 *     Copyright 2023 Smash Works Inc.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 *     NOTICE
 *
 *     This is a modified code from Index Cooperative Inc. found at
 *
 *     https://github.com/IndexCoop/index-coop-smart-contracts
 *
 *     All changes made by Smash Works Inc. are described and documented at
 *
 *     https://docs.arch.finance/chambers
 *
 *
 *             %@@@@@
 *          @@@@@@@@@@@
 *        #@@@@@     @@@           @@                   @@
 *       @@@@@@       @@@         @@@@                  @@
 *      @@@@@@         @@        @@  @@    @@@@@ @@@@@  @@@*@@
 *     [email protected]@@@@          @@@      @@@@@@@@   @@    @@     @@  @@
 *     @@@@@(       (((((      @@@    @@@  @@    @@@@@  @@  @@
 *    @@@@@@   (((((((
 *    @@@@@#(((((((
 *    @@@@@(((((
 *      @@@((
 */

pragma solidity ^0.8.17.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IChamber} from "chambers/interfaces/IChamber.sol";
import {IChamberGod} from "chambers/interfaces/IChamberGod.sol";
import {IIssuerWizard} from "chambers/interfaces/IIssuerWizard.sol";
import {ITradeIssuerV2} from "./interfaces/ITradeIssuerV2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {WETH} from "solmate/tokens/WETH.sol";

contract TradeIssuerV2 is ITradeIssuerV2, Ownable, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                              LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using Address for address;
    using Address for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                  STORAGE
    //////////////////////////////////////////////////////////////*/

    EnumerableSet.AddressSet private allowedTargets;
    address public immutable wrappedNativeToken;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @param _wrappedNativeToken        Wrapped network native token
     */
    constructor(address _wrappedNativeToken) {
        wrappedNativeToken = _wrappedNativeToken;
    }

    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * Returns an array of the allowed targets for the trade issuer
     *
     * @return address[]     An address array containing the allowed targets
     */
    function getAllowedTargets() external view returns (address[] memory) {
        return allowedTargets.values();
    }

    /**
     * Checks if the address is an allowed target
     *
     * @param _target    The address to check
     *
     * @return bool      True if the address is a valid target
     */
    function isAllowedTarget(address _target) public view returns (bool) {
        return allowedTargets.contains(_target);
    }

    /**
     * Allows the trade issuer to perform low level calls to the specified target
     *
     * @param _target    The address of the target to allow
     */
    function addTarget(address _target) external onlyOwner nonReentrant {
        if (_target == address(0)) {
            revert InvalidTarget(_target);
        }
        if (isAllowedTarget(address(_target))) revert TargetAlreadyAllowed();

        if (!allowedTargets.add(_target)) revert CannotAllowTarget();

        emit AllowedTargetAdded(_target);
    }

    /**
     * Removes the ability to perform low level calls to the target
     *
     * @param _target    The address of the target to remove
     */
    function removeTarget(address _target) external onlyOwner nonReentrant {
        if (!isAllowedTarget(_target)) {
            revert InvalidTarget(_target);
        }

        if (!allowedTargets.remove(_target)) revert CannotRemoveTarget();

        emit AllowedTargetRemoved(_target);
    }

    /**
     * Transfer the total balance of the specified stucked token to the owner address
     *
     * @param _tokenToWithdraw     The ERC20 token address to withdraw
     */
    function transferERC20ToOwner(address _tokenToWithdraw) external onlyOwner nonReentrant {
        if (IERC20(_tokenToWithdraw).balanceOf(address(this)) < 1) revert ZeroBalanceAsset();

        IERC20(_tokenToWithdraw).safeTransfer(
            owner(), IERC20(_tokenToWithdraw).balanceOf(address(this))
        );
    }

    /**
     * Transfer all stucked Ether to the owner of the contract
     */
    function transferEthToOwner() external onlyOwner nonReentrant {
        if (address(this).balance < 1) revert ZeroBalanceAsset();
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * Mints the specified amount of chamber token and sends them to the msg.sender using an ERC20
     * token as input. Unspent baseToken is also transferred back to the sender.
     *
     * @param _chamber                      Chamber address.
     * @param _issuerWizard                 Issuer wizard that'll be called for mint.
     * @param _baseToken                    The token that will be used to get the underlying assets.
     * @param _maxPayAmount                 The maximum amount of the baseToken to be used for the mint.
     * @param _mintAmount                   Chamber tokens amount to mint.
     * @param _contractCallInstructions     Instruction array that will be executed in order to get
     *                                      the underlying assets.
     *
     * @return baseTokenUsed                Total amount of the base token used for the mint.
     *
     */
    function mintChamberFromToken(
        ContractCallInstruction[] memory _contractCallInstructions,
        IChamber _chamber,
        IIssuerWizard _issuerWizard,
        IERC20 _baseToken,
        uint256 _maxPayAmount,
        uint256 _mintAmount
    ) external nonReentrant returns (uint256 baseTokenUsed) {
        if (_mintAmount == 0) revert ZeroChamberAmount();

        _baseToken.safeTransferFrom(msg.sender, address(this), _maxPayAmount);

        baseTokenUsed = _mintChamber(
            _chamber, IERC20(_baseToken), _issuerWizard, _mintAmount, _contractCallInstructions
        );

        if (_maxPayAmount < baseTokenUsed) revert OversoldBaseToken();

        uint256 remainingBaseToken = _maxPayAmount - baseTokenUsed;

        _baseToken.safeTransfer(msg.sender, remainingBaseToken);

        IERC20(address(_chamber)).safeTransfer(msg.sender, _mintAmount);

        emit TradeIssuerTokenMinted(
            address(_chamber), msg.sender, address(_baseToken), baseTokenUsed, _mintAmount
        );

        return baseTokenUsed;
    }

    /**
     * Mints the specified amount of chamber token and sends them to the msg.sender using the network
     * native token as input. Unspent native token is also transferred back to the sender.
     *
     * @param _chamber                      Chamber address.
     * @param _issuerWizard                 Issuer wizard that'll be called for mint.
     * @param _mintAmount                   Chamber tokens amount to mint.
     * @param _contractCallInstructions     Instruction array that will be executed in order to get
     *                                      the underlying assets.
     *
     * @return wrappedNativeTokenUsed       Total amount of the wrapped native token used for the mint.
     *
     */
    function mintChamberFromNativeToken(
        ContractCallInstruction[] memory _contractCallInstructions,
        IChamber _chamber,
        IIssuerWizard _issuerWizard,
        uint256 _mintAmount
    ) external payable nonReentrant returns (uint256 wrappedNativeTokenUsed) {
        if (_mintAmount == 0) revert ZeroChamberAmount();
        if (msg.value == 0) revert ZeroNativeTokenSent();
        WETH(payable(wrappedNativeToken)).deposit{value: msg.value}();

        wrappedNativeTokenUsed = _mintChamber(
            _chamber,
            IERC20(wrappedNativeToken),
            _issuerWizard,
            _mintAmount,
            _contractCallInstructions
        );

        if (msg.value < wrappedNativeTokenUsed) revert OversoldBaseToken();

        uint256 remainingWrappedNativeToken = msg.value - wrappedNativeTokenUsed;

        WETH(payable(wrappedNativeToken)).withdraw(remainingWrappedNativeToken);
        payable(msg.sender).sendValue(remainingWrappedNativeToken);

        IERC20(address(_chamber)).safeTransfer(msg.sender, _mintAmount);

        emit TradeIssuerTokenMinted(
            address(_chamber),
            msg.sender,
            address(wrappedNativeToken),
            wrappedNativeTokenUsed,
            _mintAmount
        );

        return wrappedNativeTokenUsed;
    }

    /**
     * Redeems the specified amount of chamber token for the required baseToken and sends it to the
     * msg.sender.
     *
     * @param _chamber                      Chamber address.
     * @param _issuerWizard                 Issuer wizard that'll be called for redeem.
     * @param _baseToken                    The token that it will be sent to the msg.sender.
     * @param _minReceiveAmount             The minimum amount of the baseToken to be received.
     * @param _redeemAmount                 Chamber tokens amount to redeem.
     * @param _contractCallInstructions     Instruction array that will be executed in order to get
     *                                      the underlying assets.
     *
     * @return baseTokenReturned            Total baseToken amount sent to the msg.sender.
     *
     */
    function redeemChamberToToken(
        ContractCallInstruction[] memory _contractCallInstructions,
        IChamber _chamber,
        IIssuerWizard _issuerWizard,
        IERC20 _baseToken,
        uint256 _minReceiveAmount,
        uint256 _redeemAmount
    ) external nonReentrant returns (uint256 baseTokenReturned) {
        if (_redeemAmount == 0) revert ZeroChamberAmount();

        IERC20(address(_chamber)).safeTransferFrom(msg.sender, address(this), _redeemAmount);

        baseTokenReturned = _redeemChamber(
            _chamber, _baseToken, _issuerWizard, _redeemAmount, _contractCallInstructions
        );

        if (baseTokenReturned < _minReceiveAmount) {
            revert RedeemedForLessTokens();
        }

        _baseToken.safeTransfer(msg.sender, baseTokenReturned);

        emit TradeIssuerTokenRedeemed(
            address(_chamber), msg.sender, address(_baseToken), baseTokenReturned, _redeemAmount
        );

        return baseTokenReturned;
    }

    /**
     * Redeems the specified amount of chamber token for the network's native token and sends it to the
     * msg.sender.
     *
     * @param _chamber                      Chamber address.
     * @param _issuerWizard                 Issuer wizard that'll be called for redeem.
     * @param _minReceiveAmount             The minimum amount of the baseToken to be received.
     * @param _redeemAmount                 Chamber tokens amount to redeem.
     * @param _contractCallInstructions     Instruction array that will be executed in order to get
     *                                      the underlying assets.
     *
     * @return wrappedNativeTokenReturned   Total native token amount sent to the msg.sender.
     *
     */
    function redeemChamberToNativeToken(
        ContractCallInstruction[] memory _contractCallInstructions,
        IChamber _chamber,
        IIssuerWizard _issuerWizard,
        uint256 _minReceiveAmount,
        uint256 _redeemAmount
    ) external nonReentrant returns (uint256 wrappedNativeTokenReturned) {
        if (_redeemAmount == 0) revert ZeroChamberAmount();

        IERC20(address(_chamber)).safeTransferFrom(msg.sender, address(this), _redeemAmount);

        wrappedNativeTokenReturned = _redeemChamber(
            _chamber,
            IERC20(wrappedNativeToken),
            _issuerWizard,
            _redeemAmount,
            _contractCallInstructions
        );

        if (wrappedNativeTokenReturned < _minReceiveAmount) {
            revert RedeemedForLessTokens();
        }

        WETH(payable(wrappedNativeToken)).withdraw(wrappedNativeTokenReturned);
        payable(msg.sender).sendValue(wrappedNativeTokenReturned);

        emit TradeIssuerTokenRedeemed(
            address(_chamber),
            msg.sender,
            address(wrappedNativeToken),
            wrappedNativeTokenReturned,
            _redeemAmount
        );

        return wrappedNativeTokenReturned;
    }
    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * Internal function in charge of the generic mint. The main objective is to get the chamber tokens.
     *
     * @param _chamber                      Chamber address.
     * @param _baseToken                    The token that will be used to get the underlying assets.
     * @param _issuerWizard                 Issuer wizard that'll be called for mint.
     * @param _mintAmount                Chamber tokens amount to mint.
     * @param _contractCallInstructions     Instruction array that will be executed in order to get
     *                                      the underlying assets.
     *
     * @return baseTokenUsed                Total amount of the base token used for the mint.
     *
     */
    function _mintChamber(
        IChamber _chamber,
        IERC20 _baseToken,
        IIssuerWizard _issuerWizard,
        uint256 _mintAmount,
        ContractCallInstruction[] memory _contractCallInstructions
    ) internal returns (uint256 baseTokenUsed) {
        uint256 baseTokenBalanceBefore = _baseToken.balanceOf(address(this));

        _executeInstructions(_contractCallInstructions);

        _checkAndIncreaseAllowanceOfConstituents(_chamber, _issuerWizard, _mintAmount);

        _issuerWizard.issue(_chamber, _mintAmount);

        baseTokenUsed = baseTokenBalanceBefore - _baseToken.balanceOf(address(this));

        return baseTokenUsed;
    }

    /**
     * Internal function in charge of the generic redeem. The main objective is to get the base token
     * from the chamber token.
     *
     * @param _chamber                      Chamber address.
     * @param _baseToken                    The token that will be used to get the underlying assets.
     * @param _issuerWizard                 Issuer wizard that'll be called for redeem.
     * @param _redeemAmount                 Chamber tokens amount to redeem.
     * @param _contractCallInstructions     Instruction array that will be executed in order to get
     *                                      the _baseToken assets.
     *
     * @return totalBaseTokenReturned       Total amount of the base that will be sent to the msg.sender.
     *
     */
    function _redeemChamber(
        IChamber _chamber,
        IERC20 _baseToken,
        IIssuerWizard _issuerWizard,
        uint256 _redeemAmount,
        ContractCallInstruction[] memory _contractCallInstructions
    ) internal returns (uint256 totalBaseTokenReturned) {
        uint256 baseTokenBalanceBefore = _baseToken.balanceOf(address(this));

        _issuerWizard.redeem(_chamber, _redeemAmount);

        _executeInstructions(_contractCallInstructions);

        totalBaseTokenReturned = _baseToken.balanceOf(address(this)) - baseTokenBalanceBefore;

        return totalBaseTokenReturned;
    }

    /**
     * Executes the array of instructions and verifies that the correct amount of each token
     * from the instruction is purchased.
     *
     * @param _contractCallInstructions     Instruction array that will be executed in order to get
     *                                      the underlying assets.
     */
    function _executeInstructions(ContractCallInstruction[] memory _contractCallInstructions)
        internal
    {
        for (uint256 i = 0; i < _contractCallInstructions.length; i++) {
            ContractCallInstruction memory currentInstruction = _contractCallInstructions[i];

            uint256 buyTokenBalanceBefore = currentInstruction._buyToken.balanceOf(address(this));

            _checkAndIncreaseAllowance(
                address(currentInstruction._sellToken),
                currentInstruction._allowanceTarget,
                currentInstruction._sellAmount
            );

            _fillQuote(currentInstruction._target, currentInstruction._callData);

            uint256 buyTokenAmountBought =
                currentInstruction._buyToken.balanceOf(address(this)) - buyTokenBalanceBefore;
            if (currentInstruction._minBuyAmount > buyTokenAmountBought) {
                revert UnderboughtAsset(
                    currentInstruction._buyToken, currentInstruction._minBuyAmount
                );
            }
        }
    }

    /**
     * Execute a contract call
     *
     * @param _callData       CallData to be executed on a allowed Target
     *
     * @return response       Response from the low-level call
     */
    function _fillQuote(address _target, bytes memory _callData)
        internal
        returns (bytes memory response)
    {
        if (!isAllowedTarget(_target)) revert InvalidTarget(_target);
        response = _target.functionCall(_callData);
        if (response.length == 0) revert LowLevelFunctionCallFailed();
        return (response);
    }

    /**
     * Checks the allowance for issuance of a chamberToken, if allowance is not enough it's increased to max.
     *
     * @param _chamber          Chamber token address for mint.
     * @param _issuerWizard     Issuer wizard used at _chamber.
     * @param _mintAmount    Amount of the chamber token to mint.
     */
    function _checkAndIncreaseAllowanceOfConstituents(
        IChamber _chamber,
        IIssuerWizard _issuerWizard,
        uint256 _mintAmount
    ) internal {
        (address[] memory requiredConstituents, uint256[] memory requiredConstituentsQuantities) =
            _issuerWizard.getConstituentsQuantitiesForIssuance(_chamber, _mintAmount);

        for (uint256 i = 0; i < requiredConstituents.length; i++) {
            if (
                IERC20(requiredConstituents[i]).balanceOf(address(this))
                    < requiredConstituentsQuantities[i]
            ) {
                revert UnderboughtConstituent(
                    IERC20(requiredConstituents[i]), requiredConstituentsQuantities[i]
                );
            }
            _checkAndIncreaseAllowance(
                requiredConstituents[i], address(_issuerWizard), requiredConstituentsQuantities[i]
            );
        }
    }

    /**
     * For the specified token and amount, checks the allowance between the TraderIssuer and _target.
     * If not enough, it sets the maximum.
     *
     * @param _tokenAddress     Address of the token that will be used.
     * @param _target           Target address of the allowance.
     * @param _requiredAmount   Required allowance for the operation.
     */
    function _checkAndIncreaseAllowance(
        address _tokenAddress,
        address _target,
        uint256 _requiredAmount
    ) internal {
        if (_requiredAmount == 0) revert ZeroRequiredAmount();
        uint256 currentAllowance = IERC20(_tokenAddress).allowance(address(this), _target);
        if (currentAllowance < _requiredAmount) {
            IERC20(_tokenAddress).safeIncreaseAllowance(
                _target, type(uint256).max - currentAllowance
            );
        }
    }
}

/**
 *     SPDX-License-Identifier: Apache License 2.0
 *
 *     Copyright 2021 Index Cooperative
 *     Copyright 2023 Smash Works Inc.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 *     NOTICE
 *
 *     This is a modified code from Index Cooperative found at
 *
 *     https://github.com/IndexCoop/index-coop-smart-contracts
 *
 *     All changes made by Smash Works Inc. are described and documented at
 *
 *     https://docs.arch.finance/chambers
 *
 *
 *             %@@@@@
 *          @@@@@@@@@@@
 *        #@@@@@     @@@           @@                   @@
 *       @@@@@@       @@@         @@@@                  @@
 *      @@@@@@         @@        @@  @@    @@@@@ @@@@@  @@@*@@
 *     [email protected]@@@@          @@@      @@@@@@@@   @@    @@     @@  @@
 *     @@@@@(       (((((      @@@    @@@  @@    @@@@@  @@  @@
 *    @@@@@@   (((((((
 *    @@@@@#(((((((
 *    @@@@@(((((
 *      @@@((
 */

pragma solidity ^0.8.17.0;

import {IChamber} from "chambers/interfaces/IChamber.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IIssuerWizard} from "chambers/interfaces/IIssuerWizard.sol";

interface ITradeIssuerV2 {
    /*//////////////////////////////////////////////////////////////
                               STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct ContractCallInstruction {
        address payable _target;
        address _allowanceTarget;
        IERC20 _sellToken;
        uint256 _sellAmount;
        IERC20 _buyToken;
        uint256 _minBuyAmount;
        bytes _callData;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event AllowedTargetAdded(address indexed _target);

    event AllowedTargetRemoved(address indexed _targer);

    event TradeIssuerTokenMinted(
        address indexed chamber,
        address indexed recipient,
        address indexed inputToken,
        uint256 totalTokensUsed,
        uint256 mintAmount
    );

    event TradeIssuerTokenRedeemed(
        address indexed chamber,
        address indexed recipient,
        address indexed outputToken,
        uint256 totalTokensReturned,
        uint256 redeemAmount
    );

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error CannotAllowTarget();

    error CannotRemoveTarget();

    error InvalidTarget(address target);

    error LowLevelFunctionCallFailed();

    error OversoldBaseToken();

    error RedeemedForLessTokens();

    error TargetAlreadyAllowed();

    error UnderboughtAsset(IERC20 asset, uint256 buyAmount);

    error UnderboughtConstituent(IERC20 asset, uint256 buyAmount);

    error ZeroChamberAmount();

    error ZeroBalanceAsset();

    error ZeroNativeTokenSent();

    error ZeroRequiredAmount();

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getAllowedTargets() external returns (address[] memory);

    function isAllowedTarget(address _target) external returns (bool);

    function addTarget(address _target) external;

    function removeTarget(address _target) external;

    function transferERC20ToOwner(address _tokenToWithdraw) external;

    function transferEthToOwner() external;

    function mintChamberFromToken(
        ContractCallInstruction[] memory _contractCallInstructions,
        IChamber _chamber,
        IIssuerWizard _issuerWizard,
        IERC20 _baseToken,
        uint256 _maxPayAmount,
        uint256 _chamberAmount
    ) external returns (uint256 baseTokenUsed);

    function mintChamberFromNativeToken(
        ContractCallInstruction[] memory _contractCallInstructions,
        IChamber _chamber,
        IIssuerWizard _issuerWizard,
        uint256 _chamberAmount
    ) external payable returns (uint256 wrappedNativeTokenUsed);

    function redeemChamberToToken(
        ContractCallInstruction[] memory _contractCallInstructions,
        IChamber _chamber,
        IIssuerWizard _issuerWizard,
        IERC20 _baseToken,
        uint256 _minReceiveAmount,
        uint256 _chamberAmount
    ) external returns (uint256 baseTokenReturned);

    function redeemChamberToNativeToken(
        ContractCallInstruction[] memory _contractCallInstructions,
        IChamber _chamber,
        IIssuerWizard _issuerWizard,
        uint256 _minReceiveAmount,
        uint256 _chamberAmount
    ) external returns (uint256 wrappedNativeTokenReturned);
}