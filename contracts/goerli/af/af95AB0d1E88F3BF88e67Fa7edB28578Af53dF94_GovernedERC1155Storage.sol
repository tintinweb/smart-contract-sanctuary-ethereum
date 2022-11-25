// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { ERC2981 } from './ERC2981.sol';
import { Context } from './Context.sol';
import { Pausable } from './Pausable.sol';
import { StorageBase } from './StorageBase.sol';
import { NonReentrant } from './NonReentrant.sol';
import { GovernedContract } from './GovernedContract.sol';

import { Address } from './libraries/Address.sol';

import { IStorageBase } from './interfaces/IStorageBase.sol';
import { IGovernedERC1155 } from './interfaces/IGovernedERC1155.sol';
import { IGovernedContract } from './interfaces/IGovernedContract.sol';
import { IERC1155Receiver } from './interfaces/helpers/IERC1155Receiver.sol';
import { IGovernedERC1155Storage } from './interfaces/IGovernedERC1155Storage.sol';

contract GovernedERC1155Storage is StorageBase, IGovernedERC1155Storage {
    string private baseUri;
    mapping(uint256 => uint256) private totalSupplies; // token ID to totalSupply
    mapping(uint256 => mapping(address => uint256)) private balances; // token ID to users to balances
    mapping(address => mapping(address => bool)) private operatorApprovals; // owner to operator to approval

    constructor(string memory _baseUri) {
        baseUri = _baseUri;
    }

    /* View Functions */

    function getBaseUri() external view override returns (string memory) {
        return baseUri;
    }

    function getTotalSupply(uint256 _id) external view override returns (uint256) {
        return totalSupplies[_id];
    }

    function getBalance(uint256 _id, address _account) external view override returns (uint256) {
        return balances[_id][_account];
    }

    function getOperatorApproval(address _account, address _operator)
        external
        view
        override
        returns (bool)
    {
        return operatorApprovals[_account][_operator];
    }

    /* Mutative Functions */

    function setBaseUri(string calldata _newbaseUri) external override requireOwner {
        baseUri = _newbaseUri;
    }

    function setTotalSupply(uint256 _id, uint256 _newTotalSupply) external override requireOwner {
        totalSupplies[_id] = _newTotalSupply;
    }

    function setBalance(
        uint256 _id,
        address _account,
        uint256 _balance
    ) external override requireOwner {
        balances[_id][_account] = _balance;
    }

    function setOperatorApproval(
        address _account,
        address _operator,
        bool _approval
    ) external override requireOwner {
        operatorApprovals[_account][_operator] = _approval;
    }
}

contract GovernedERC1155 is Pausable, NonReentrant, GovernedContract, ERC2981, IGovernedERC1155 {
    using Address for address;

    GovernedERC1155Storage public governedERC1155Storage;

    constructor(address _proxy, string memory _baseUri) GovernedContract(_proxy) {
        governedERC1155Storage = new GovernedERC1155Storage(_baseUri);
    }

    // This function is called in order to upgrade to a new ERC1155 implementation
    function _destroyERC1155(IGovernedContract _newImplementation) internal {
        governedERC1155Storage.setOwner(_newImplementation);
    }

    // This function (placeholder) would be called on the new implementation if necessary for the upgrade
    function _migrateERC1155(address _oldImplementation) internal {
        governedERC1155Storage = GovernedERC1155Storage(
            IGovernedERC1155(_oldImplementation).governedERC1155Storage()
        );
    }

    // function needed for the following mutative functions
    function isApprovedForAll(address account, address operator)
        public
        view
        override
        returns (bool)
    {
        return governedERC1155Storage.getOperatorApproval(account, operator);
    }

    /* External mutative functions */

    function implSafeTransferFrom(
        address caller,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external virtual override whenNotPaused noReentry requireProxy {
        require(
            caller == from || // caller is owner
                isApprovedForAll(from, caller), // caller is operator
            'GovernedERC1155::safeTransferFrom: caller is not owner nor approved'
        );
        _safeTransferFrom(caller, from, to, id, amount, data);
    }

    function implSafeBatchTransferFrom(
        address caller,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external virtual override whenNotPaused noReentry requireProxy {
        require(
            caller == from || // caller is owner
                isApprovedForAll(from, caller), // caller is operator
            'GovernedERC1155::safeBatchTransferFrom: caller is not owner nor approved'
        );
        _safeBatchTransferFrom(caller, from, to, ids, amounts, data);
    }

    function implSetApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) external override whenNotPaused requireProxy {
        require(
            owner != operator,
            'GovernedERC1155::setApprovalForAll: setting approval status for self'
        );
        governedERC1155Storage.setOperatorApproval(owner, operator, approved);
    }

    /* External View Functions */

    function baseUri() external view override returns (string memory) {
        return governedERC1155Storage.getBaseUri();
    }

    function totalSupply(uint256 id) external view override returns (uint256) {
        return governedERC1155Storage.getTotalSupply(id);
    }

    function balanceOf(address account, uint256 id) external view override returns (uint256) {
        return governedERC1155Storage.getBalance(id, account);
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        external
        view
        override
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            'GovernedERC1155::balanceOfBatch: accounts and ids length mismatch'
        );
        uint256[] memory batchBalances = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            batchBalances[i] = governedERC1155Storage.getBalance(ids[i], accounts[i]);
        }
        return batchBalances;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, IGovernedERC1155)
        returns (bool)
    {
        return
            interfaceId == type(IGovernedERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /* Reserved mutative function for contract owner */

    function setBaseUri(string calldata _newbaseUri) external override onlyOwner {
        governedERC1155Storage.setBaseUri(_newbaseUri);
    }

    /* Internal functions */

    function _safeTransferFrom(
        address caller,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) internal virtual {
        require(
            from != address(0),
            'GovernedERC1155::_safeTransferFrom: can not transfer from zero address'
        );
        require(
            to != address(0),
            'GovernedERC1155::_safeTransferFrom: can not transfer to zero address'
        );
        uint256 fromBalance = governedERC1155Storage.getBalance(id, from);
        require(
            fromBalance >= amount,
            'GovernedERC1155::_safeTransferFrom: insufficient balance for transfer'
        );
        governedERC1155Storage.setBalance(id, from, fromBalance - amount);
        governedERC1155Storage.setBalance(
            id,
            to,
            governedERC1155Storage.getBalance(id, to) + amount
        );

        _doSafeTransferAcceptanceCheck(caller, from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(
        address caller,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) internal virtual {
        require(
            from != address(0),
            'ERC1155GovernedERC1155Internal::_safeBatchTransferFrom: can not transfer from zero address'
        );
        require(
            to != address(0),
            'GovernedERC1155::_safeBatchTransferFrom: can not transfer to zero address'
        );
        require(
            ids.length == amounts.length,
            'GovernedERC1155::_safeBatchTransferFrom: ids and amounts length mismatch'
        );
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 fromBalance = governedERC1155Storage.getBalance(ids[i], from);
            uint256 toBalance = governedERC1155Storage.getBalance(ids[i], to);
            require(
                fromBalance >= amounts[i],
                'GovernedERC1155::_safeBatchTransferFrom: insufficient balance for transfer'
            );
            governedERC1155Storage.setBalance(ids[i], from, fromBalance - amounts[i]);
            governedERC1155Storage.setBalance(ids[i], to, toBalance + amounts[i]);
        }

        _doSafeBatchTransferAcceptanceCheck(caller, from, to, ids, amounts, data);
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) internal {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert(
                        'GovernedERC1155::_doSafeTransferAcceptanceCheck: ERC1155Receiver rejected tokens'
                    );
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert(
                    'GovernedERC1155::_doSafeTransferAcceptanceCheck: transfer to non ERC1155Receiver implementer'
                );
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) internal {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data)
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert(
                        'GovernedERC1155::_doSafeBatchTransferAcceptanceCheck: ERC1155Receiver rejected tokens'
                    );
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert(
                    'GovernedERC1155::_doSafeBatchTransferAcceptanceCheck: transfer to non ERC1155Receiver implementer'
                );
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        (bool success, ) = recipient.call{ value: amount }('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return
            functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        require(isContract(target), 'Address: call to non-contract');

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return functionStaticCall(target, data, 'Address: low-level static call failed');
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
        require(isContract(target), 'Address: static call to non-contract');

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
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
        require(isContract(target), 'Address: delegate call to non-contract');

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

pragma solidity 0.8.15;

import { IERC165 } from '../IERC165.sol';

interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { IGovernedContract } from './IGovernedContract.sol';

interface IStorageBase {
    function setOwner(IGovernedContract _newOwner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IGovernedERC1155Storage {
    function getBaseUri() external view returns (string memory);

    function getTotalSupply(uint256 _id) external view returns (uint256);

    function getBalance(uint256 _id, address _account) external view returns (uint256);

    function getOperatorApproval(address _account, address _operator) external view returns (bool);

    function setBaseUri(string calldata _newbaseUri) external;

    function setTotalSupply(uint256 _id, uint256 _totalSupply) external;

    function setBalance(
        uint256 _id,
        address _account,
        uint256 _balance
    ) external;

    function setOperatorApproval(
        address _account,
        address _operator,
        bool _approval
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { GovernedERC1155Storage } from '../GovernedERC1155.sol';

import { IERC165 } from './IERC165.sol';

interface IGovernedERC1155 is IERC165 {
    function governedERC1155Storage()
        external
        view
        returns (GovernedERC1155Storage governedERC1155Storage);

    function implSetApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function implSafeTransferFrom(
        address caller,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function implSafeBatchTransferFrom(
        address caller,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function baseUri() external view returns (string memory);

    function totalSupply(uint256 id) external view returns (uint256);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        external
        view
        returns (uint256[] memory);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function setBaseUri(string calldata _newbaseUri) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * Genesis version of GovernedContract interface.
 *
 * Base Consensus interface for upgradable contracts.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */

interface IGovernedContract {
    // Return actual proxy address for secure validation
    function proxy() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { IERC165 } from './IERC165.sol';

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * Base for contract storage (SC-14).
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */

contract StorageBase {
    address payable internal owner;

    modifier requireOwner() {
        require(msg.sender == address(owner), 'StorageBase: Not owner!');
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function setOwner(IGovernedContract _newOwner) external requireOwner {
        owner = payable(address(uint160(address(_newOwner))));
    }

    function kill() external requireOwner {
        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { Context } from './Context.sol';
import { Ownable } from './Ownable.sol';

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Context, Ownable {
    /**
     * @dev Emitted when pause() is called.
     * @param account of contract owner issuing the event.
     * @param unpauseBlock block number when contract will be unpaused.
     */
    event Paused(address account, uint256 unpauseBlock);

    /**
     * @dev Emitted when pause is lifted by unpause() by
     * @param account.
     */
    event Unpaused(address account);

    /**
     * @dev state variable
     */
    uint256 public blockNumberWhenToUnpause = 0;

    /**
     * @dev Modifier to make a function callable only when the contract is not
     *      paused. It checks whether the current block number
     *      has already reached blockNumberWhenToUnpause.
     */
    modifier whenNotPaused() {
        require(
            block.number >= blockNumberWhenToUnpause,
            'Pausable: Revert - Code execution is still paused'
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(
            block.number < blockNumberWhenToUnpause,
            'Pausable: Revert - Code execution is not paused'
        );
        _;
    }

    /**
     * @dev Triggers or extends pause state.
     *
     * Requirements:
     *
     * - @param blocks needs to be greater than 0.
     */
    function pause(uint256 blocks) external onlyOwner {
        require(
            blocks > 0,
            'Pausable: Revert - Pause did not activate. Please enter a positive integer.'
        );
        blockNumberWhenToUnpause = block.number + blocks;
        emit Paused(_msgSender(), blockNumberWhenToUnpause);
    }

    /**
     * @dev Returns to normal code execution.
     */
    function unpause() external onlyOwner {
        blockNumberWhenToUnpause = block.number;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of 'user permissions'.
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: Not owner');
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), 'Ownable: Zero address not allowed');
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * A little helper to protect contract from being re-entrant in state
 * modifying functions.
 */

contract NonReentrant {
    uint256 private entry_guard;

    modifier noReentry() {
        require(entry_guard == 0, 'NonReentrant: Reentry');
        entry_guard = 1;
        _;
        entry_guard = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * Genesis version of GovernedContract common base.
 *
 * Base Consensus interface for upgradable contracts.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */
contract GovernedContract {
    address public proxy;

    constructor(address _proxy) {
        proxy = _proxy;
    }

    modifier requireProxy() {
        require(msg.sender == proxy, 'Governed Contract: Not proxy');
        _;
    }

    function getProxy() internal view returns (address _proxy) {
        _proxy = proxy;
    }

    // solium-disable-next-line no-empty-blocks
    function _migrate(IGovernedContract) internal {}

    function _destroy(IGovernedContract _newImplementation) internal {
        selfdestruct(payable(address(uint160(address(_newImplementation)))));
    }

    function _callerAddress() internal view returns (address payable) {
        if (msg.sender == proxy) {
            // This is guarantee of the GovernedProxy
            // solium-disable-next-line security/no-tx-origin
            return payable(tx.origin);
        } else {
            return payable(msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { ERC165 } from './ERC165.sol';

import { IERC165 } from './interfaces/IERC165.sol';
import { IERC2981 } from './interfaces/IERC2981.sol';

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(
            feeNumerator <= _feeDenominator(),
            'ERC2981::_setDefaultRoyalty: royalty fee will exceed salePrice'
        );
        require(
            receiver != address(0),
            'ERC2981::_setDefaultRoyalty: zero address can not receive royalties'
        );

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(
            feeNumerator <= _feeDenominator(),
            'ERC2981::_setTokenRoyalty: royalty fee will exceed salePrice'
        );
        require(
            receiver != address(0),
            'ERC2981::_setTokenRoyalty: zero address can not receive royalties'
        );

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { IERC165 } from './interfaces/IERC165.sol';

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _txOrigin() internal view returns (address payable) {
        return payable(tx.origin);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}