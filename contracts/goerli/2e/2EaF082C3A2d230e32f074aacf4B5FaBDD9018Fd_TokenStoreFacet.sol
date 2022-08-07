/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract ERC1155Vault is IERC1155Receiver {

    event ERC1155Transferred(address tokenContract, address to, uint256 tokenId, uint256 amount);
    event ERC1155ApprovedForAll(address tokenContract, address operator, bool approved);

    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }

    function onERC1155Received(
        address /* operator */,
        address /* from */,
        uint256 /* id */,
        uint256 /* value */,
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address /* operator */,
        address /* from */,
        uint256[] calldata /* ids */,
        uint256[] calldata /* values */,
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    /* solhint-disable func-name-mixedcase */
    function _ERC1155Transfer(
        address tokenContract,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        require(tokenContract != address(0), "E1V: zero address");
        require(to != address(0), "E1V: zero target");

        IERC1155(tokenContract).safeTransferFrom(address(this), to, tokenId, amount, "");
        emit ERC1155Transferred(tokenContract, to, tokenId, amount);
    }

    function _ERC1155SetApprovalForAll(
        address tokenContract,
        address operator,
        bool approved
    ) internal {
        require(tokenContract != address(0), "E1V: zero address");
        require(operator != address(0), "E1V: zero operator");

        IERC1155(tokenContract).setApprovalForAll(operator, approved);
        emit ERC1155ApprovedForAll(tokenContract, operator, approved);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../ERC1155Vault.sol";
import "./AdminRoleEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract ERC1155VaultEnabled is AdminRoleEnabled, ERC1155Vault {

    /* solhint-disable func-name-mixedcase */
    function ERC1155Transfer(
        uint256 adminTaskId,
        address tokenContract,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _ERC1155Transfer(tokenContract, to, tokenId, amount);
        _finalizeTask(adminTaskId, "");
    }

    function ERC1155SetApprovalForAll(
        uint256 adminTaskId,
        address tokenContract,
        address operator,
        bool approved
    ) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _ERC1155SetApprovalForAll(tokenContract, operator, approved);
        _finalizeTask(adminTaskId, "");
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./TaskManaged.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract AdminRoleEnabled is TaskManaged {

    uint public constant MAX_NR_OF_ADMINS = 10;
    uint public constant MIN_NR_OF_ADMINS = 4;

    mapping (address => bool) private _admins;
    uint internal _nrOfAdmins;

    event AdminAdded(address account);
    event AdminRemoved(address account);

    modifier onlyAdmin() {
        require(_isAdmin(msg.sender), "ARE: not admin");
        _;
    }

    constructor() {
        _nrOfAdmins = 0;
    }

    function isAdmin(address account) external view
      onlyAdmin
      returns (bool)
    {
        return _isAdmin(account);
    }

    function getNrAdmins() external view
      onlyAdmin
      returns (uint)
    {
        return _nrOfAdmins;
    }

    function addAdmin(uint256 adminTaskId, address toBeAdded) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _addAdmin(toBeAdded);
        _finalizeTask(adminTaskId, "");
    }

    function replaceAdmin(uint256 adminTaskId, address toBeRemoved, address toBeReplaced) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        if (_nrOfAdmins == MAX_NR_OF_ADMINS) {
            _removeAdmin(toBeRemoved);
            _addAdmin(toBeReplaced);
        } else {
            _addAdmin(toBeReplaced);
            _removeAdmin(toBeRemoved);
        }
        _finalizeTask(adminTaskId, "");
    }

    function removeAdmin(uint256 adminTaskId, address toBeRemoved) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _removeAdmin(toBeRemoved);
        _finalizeTask(adminTaskId, "");
    }

    function _isAdmin(address account) internal view returns (bool) {
        return _admins[account];
    }

    function _addAdmin(address account) internal {
        require(account != address(0), "ARE: zero account");
        require(!_admins[account], "ARE: is admin");
        require((_nrOfAdmins + 1) <= MAX_NR_OF_ADMINS, "ARE: exceeds max");
        _admins[account] = true;
        _nrOfAdmins += 1;
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        require(account != address(0), "ARE: zero account");
        require(_admins[account], "ARE: not admin");
        require((_nrOfAdmins - 1) >= MIN_NR_OF_ADMINS, "ARE: below min");
        _admins[account] = false;
        _nrOfAdmins -= 1;
        emit AdminRemoved(account);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract TaskManaged {

    struct Task {
        uint256 id;
        string uri;
        bool administrative;
        uint nrApprovals;
        bool finalized;
    }
    mapping (uint256 => Task) private _tasks;
    mapping (uint256 => mapping(address => bool)) private _taskApprovals;
    uint256 private _taskIdCounter;

    event TaskCreated(uint256 indexed taskId, string uri, bool administrative);
    event TaskApproved(uint256 taskId);
    event TaskApprovalWithdrawn(uint256 taskId);
    event TaskFinalized(uint256 taskId, string reason);

    modifier taskMustExist(uint256 taskId) {
        require(_taskExists(taskId), "TaskManaged: task does not exist");
        _;
    }

    modifier taskMustBeAdministrative(uint256 taskId) {
        require(_isTaskAdministrative(taskId), "TaskManaged: invalid task type");
        _;
    }

    modifier taskMustNotBeAdministrative(uint256 taskId) {
        require(!_isTaskAdministrative(taskId), "TaskManaged: invalid task type");
        _;
    }

    modifier taskMustBeApproved(uint256 taskId) {
        require(_isTaskApproved(taskId), "TaskManaged: task is not approved");
        _;
    }

    modifier taskMustNotBeFinalized(uint256 taskId) {
        require(!_isTaskFinalized(taskId), "TaskManaged: task is finalized");
        _;
    }

    constructor() {
        _taskIdCounter = 1;
    }

    function _getRequiredNrApprovals(uint256 taskId) internal view virtual returns (uint);

    function _taskExists(uint256 taskId) internal view virtual returns (bool) {
        return _tasks[taskId].id > 0;
    }

    function _isTaskAdministrative(uint256 taskId) internal view virtual returns (bool) {
        require(_taskExists(taskId), "TaskManaged: task does not exist");
        return _tasks[taskId].administrative;
    }

    function _isTaskApproved(uint256 taskId) internal view virtual returns (bool) {
        require(_taskExists(taskId), "TaskManaged: task does not exist");
        return _tasks[taskId].nrApprovals >= _getRequiredNrApprovals(taskId);
    }

    function _isTaskFinalized(uint256 taskId) internal view virtual returns (bool) {
        require(_taskExists(taskId), "TaskManaged: task does not exist");
        return _tasks[taskId].finalized;
    }

    function _getTaskURI(uint256 taskId) internal view virtual returns (string memory) {
        require(_taskExists(taskId), "TaskManaged: task does not exist");
        return _tasks[taskId].uri;
    }

    function _getTaskNrApprovals(uint256 taskId) internal view virtual returns (uint) {
        require(_taskExists(taskId), "TaskManaged: task does not exist");
        return _tasks[taskId].nrApprovals;
    }

    function _createTask(
        string memory taskURI,
        bool isAdministrative
    ) internal virtual returns (uint256) {
        uint256 taskId = _taskIdCounter;
        _taskIdCounter++;
        Task memory task = Task(taskId, taskURI, isAdministrative, 0, false);
        _tasks[taskId] = task;
        emit TaskCreated(taskId, taskURI, isAdministrative);
        return taskId;
    }

    function _approveTask(address doer, uint256 taskId) internal virtual {
        require(_taskExists(taskId), "TaskManaged: task does not exist");
        require(!_taskApprovals[taskId][doer], "TaskManaged: task is already approved");
        _taskApprovals[taskId][doer] = true;
        _tasks[taskId].nrApprovals += 1;
        emit TaskApproved(taskId);
    }

    function _withdrawTaskApproval(address doer, uint256 taskId) internal virtual {
        require(_taskExists(taskId), "TaskManaged: task does not exist");
        require(_taskApprovals[taskId][doer], "TaskManaged: task is not approved");
        _taskApprovals[taskId][doer] = false;
        _tasks[taskId].nrApprovals -= 1;
        emit TaskApprovalWithdrawn(taskId);
    }

    function _finalizeTask(uint256 taskId, string memory reason) internal virtual {
        require(_taskExists(taskId), "TaskManaged: task does not exist");
        _tasks[taskId].finalized = true;
        emit TaskFinalized(taskId, reason);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../abstract/task-manager/AdminTaskManaged.sol";
import "../../abstract/task-manager/ERC1155VaultEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TestERC1155VaultEnabled is ERC1155VaultEnabled, AdminTaskManaged {

    constructor(address[] memory initialAdmins) {
        require(initialAdmins.length >= MIN_NR_OF_ADMINS, "TestERC1155VaultEnabled: not enough initial admins");
        for (uint i = 0; i < initialAdmins.length; i++) {
            _addAdmin(initialAdmins[i]);
        }
    }

    /* solhint-disable func-name-mixedcase */
    function testonly_createNonAdministrativeTask(string memory taskURI) external {
        _createTask(taskURI, false);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./AdminRoleEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract AdminTaskManaged is AdminRoleEnabled {

    function createAdminTask(string memory taskURI) external
      onlyAdmin
    {
        _createTask(taskURI, true);
    }

    function approveAdminTask(uint256 adminTaskId) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
    {
        _approveTask(msg.sender, adminTaskId);
    }

    function withdrawAdminTaskApproval(uint256 adminTaskId) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
    {
        _withdrawTaskApproval(msg.sender, adminTaskId);
    }

    function finalizeAdminTask(uint256 adminTaskId, string memory reason) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
    {
        _finalizeTask(adminTaskId, reason);
    }

    function _getRequiredNrApprovals(uint256 taskId)
      internal view virtual override (TaskManaged) returns (uint) {
        require(_taskExists(taskId), "ATM: non-exsiting task");
        return (1 + _nrOfAdmins / 2);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../abstract/task-manager/AdminTaskManaged.sol";
import "../../abstract/task-manager/FinalizerRoleEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TestFinalizerRoleEnabled is FinalizerRoleEnabled, AdminTaskManaged {

    constructor(address[] memory initialAdmins, address[] memory initialFinalizers) {
        require(initialAdmins.length >= MIN_NR_OF_ADMINS, "TestFinalizerRoleEnabled: not enough initial admins");
        for (uint i = 0; i < initialAdmins.length; i++) {
            _addAdmin(initialAdmins[i]);
        }
        for (uint i = 0; i < initialFinalizers.length; i++) {
            _addFinalizer(initialFinalizers[i]);
        }
    }

    /* solhint-disable func-name-mixedcase */
    function testonly_createNonAdministrativeTask(string memory taskURI) external {
        _createTask(taskURI, false);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./AdminRoleEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract FinalizerRoleEnabled is AdminRoleEnabled {

    mapping (address => bool) private _finalizers;

    uint internal _nrOfFinalizers;

    event FinalizerAdded(address account);
    event FinalizerRemoved(address account);

    modifier onlyFinalizer() {
        require(_isFinalizer(msg.sender), "FinalizerRoleEnabled: not a finalizer account");
        _;
    }

    constructor() {
        _nrOfFinalizers = 0;
    }

    function isFinalizer(address account) external view
      onlyAdmin
      returns (bool)
    {
        return _isFinalizer(account);
    }

    function addFinalizer(uint256 adminTaskId, address account) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _addFinalizer(account);
        _finalizeTask(adminTaskId, "");
    }

    function removeFinalizer(uint256 adminTaskId, address account) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _removeFinalizer(account);
        _finalizeTask(adminTaskId, "");
    }

    function _isFinalizer(address account) internal view returns (bool) {
        return _finalizers[account];
    }

    function _addFinalizer(address account) internal {
        require(account != address(0), "FRE: zero account");
        require(!_finalizers[account], "FRE: is finalizer");
        _finalizers[account] = true;
        _nrOfFinalizers += 1;
        emit FinalizerAdded(account);
    }

    function _removeFinalizer(address account) internal {
        require(account != address(0), "FRE: zero account");
        require(_finalizers[account], "FRE: not finalizer");
        _finalizers[account] = false;
        _nrOfFinalizers -= 1;
        emit FinalizerRemoved(account);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./interfaces/ITaskExecutor.sol";
import "./abstract/task-manager/AdminTaskManaged.sol";
import "./abstract/task-manager/CreatorRoleEnabled.sol";
import "./abstract/task-manager/ApproverRoleEnabled.sol";
import "./abstract/task-manager/ExecutorRoleEnabled.sol";
import "./abstract/task-manager/FinalizerRoleEnabled.sol";
import "./abstract/task-manager/ETHVaultEnabled.sol";
import "./abstract/task-manager/ERC20VaultEnabled.sol";
import "./abstract/task-manager/ERC721VaultEnabled.sol";
import "./abstract/task-manager/ERC1155VaultEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TaskManager is
  ITaskExecutor,
  AdminTaskManaged,
  CreatorRoleEnabled,
  ApproverRoleEnabled,
  ExecutorRoleEnabled,
  FinalizerRoleEnabled,
  ETHVaultEnabled,
  ERC20VaultEnabled,
  ERC721VaultEnabled,
  ERC1155VaultEnabled,
  ERC165
{
    modifier onlyPrivileged() {
        require(
            _isAdmin(msg.sender) ||
            _isCreator(msg.sender) ||
            _isApprover(msg.sender) ||
            _isExecutor(msg.sender),
            "TaskManager: not a privileged account"
        );
        _;
    }

    constructor(
      address[] memory initialAdmins,
      address[] memory initialCreators,
      address[] memory initialApprovers,
      address[] memory initialExecutors,
      bool enableDeposit
    ) {
        require(initialAdmins.length >= MIN_NR_OF_ADMINS, "TaskManager: not enough initial admins");
        for (uint i = 0; i < initialAdmins.length; i++) {
            _addAdmin(initialAdmins[i]);
        }
        require(initialCreators.length >= 1, "TaskManager: not enough initial creators");
        for (uint i = 0; i < initialCreators.length; i++) {
            _addCreator(initialCreators[i]);
        }
        require(initialApprovers.length >= 3, "TaskManager: not enough initial approvers");
        for (uint i = 0; i < initialApprovers.length; i++) {
            _addApprover(initialApprovers[i]);
        }
        require(initialExecutors.length >= 1, "TaskManager: not enough initial executors");
        for (uint i = 0; i < initialExecutors.length; i++) {
            _addExecutor(initialExecutors[i]);
        }
        _setEnableDeposit(enableDeposit);
    }

    function supportsInterface(bytes4 interfaceId)
      public view virtual override(ERC1155Vault, ERC165) returns (bool)
    {
        return interfaceId == type(ITaskExecutor).interfaceId ||
               interfaceId == type(IERC1155Receiver).interfaceId ||
               interfaceId == type(IERC721Receiver).interfaceId;
    }

    function stats() external view onlyAdmin returns (uint, uint, uint, uint, uint) {
        return (_nrOfAdmins, _nrOfCreators, _nrOfApprovers, _nrOfExecutors, _nrOfFinalizers);
    }

    function isFinalized(uint256 taskId) external view
      onlyPrivileged
      taskMustExist(taskId)
      returns (bool)
    {
        if (_isTaskAdministrative(taskId)) {
            require(_isAdmin(msg.sender), "TaskManager: not an admin account");
        }
        return _isTaskFinalized(taskId);
    }

    function getTaskURI(uint256 taskId) external view
      onlyPrivileged
      taskMustExist(taskId)
      returns (string memory)
    {
        if (_isTaskAdministrative(taskId)) {
            require(_isAdmin(msg.sender), "TaskManager: not an admin account");
        }
        return _getTaskURI(taskId);
    }

    function getNrOfApprovals(uint256 taskId) external view
      onlyPrivileged
      taskMustExist(taskId)
      returns (uint)
    {
        if (_isTaskAdministrative(taskId)) {
            require(_isAdmin(msg.sender), "TaskManager: not an admin account");
        }
        return _getTaskNrApprovals(taskId);
    }

    function createTask(string memory taskURI) external
      onlyCreator
    {
        _createTask(taskURI, false);
    }

    function finalizeTask(uint256 taskId, string memory reason) external
      onlyCreatorOrAdmin
      taskMustExist(taskId)
      taskMustNotBeAdministrative(taskId)
      taskMustNotBeFinalized(taskId)
    {
        _finalizeTask(taskId, reason);
    }

    function approveTask(uint256 taskId) external
      onlyApprover
      taskMustExist(taskId)
      taskMustNotBeAdministrative(taskId)
      taskMustNotBeFinalized(taskId)
    {
        _approveTask(msg.sender, taskId);
    }

    function withdrawTaskApproval(uint256 taskId) external
      onlyApprover
      taskMustExist(taskId)
      taskMustNotBeAdministrative(taskId)
      taskMustNotBeFinalized(taskId)
    {
        _withdrawTaskApproval(msg.sender, taskId);
    }

    function executeTask(address origin, uint256 taskId) external virtual override
      onlyFinalizer
      mustBeExecutor(origin)
      taskMustExist(taskId)
      taskMustNotBeAdministrative(taskId)
      taskMustBeApproved(taskId)
      taskMustNotBeFinalized(taskId)
    {
        _finalizeTask(taskId, "");
        emit TaskExecuted(msg.sender, origin, taskId);
    }

    function executeAdminTask(address origin, uint256 taskId) external virtual override
      onlyFinalizer
      mustBeExecutor(origin)
      taskMustExist(taskId)
      taskMustBeAdministrative(taskId)
      taskMustBeApproved(taskId)
      taskMustNotBeFinalized(taskId)
    {
        _finalizeTask(taskId, "");
        emit TaskExecuted(msg.sender, origin, taskId);
    }

    function _getRequiredNrApprovals(uint256 taskId)
      internal view virtual override(AdminTaskManaged, TaskManaged) returns (uint) {
        require(_taskExists(taskId), "TaskManager: task does not exist");
        if (_isTaskAdministrative(taskId)) {
            return (1 + _nrOfAdmins / 2);
        } else {
            return (1 + _nrOfApprovers / 2);
        }
    }

    receive() external payable {
        require(_isDepositEnabled(), "TaskManager: cannot accept ether");
    }

    fallback() external payable {
        revert("TaskManager: fallback always fails");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface ITaskExecutor {

    event TaskExecuted(address finalizer, address executor, uint256 taskId);

    function executeTask(address executor, uint256 taskId) external;

    function executeAdminTask(address executor, uint256 taskId) external;
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./AdminRoleEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract CreatorRoleEnabled is AdminRoleEnabled {

    mapping (address => bool) private _creators;

    uint internal _nrOfCreators;

    event CreatorAdded(address account);
    event CreatorRemoved(address account);

    modifier onlyCreator() {
        require(_isCreator(msg.sender), "CRE: not creator");
        _;
    }

    modifier onlyCreatorOrAdmin() {
        require(_isCreator(msg.sender) || _isAdmin(msg.sender),
                "CRE: not creator nor admin");
        _;
    }

    constructor() {
        _nrOfCreators = 0;
    }

    function isCreator(address account) external view
      onlyAdmin
      returns (bool)
    {
        return _isCreator(account);
    }

    function addCreator(uint256 adminTaskId, address account) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _addCreator(account);
        _finalizeTask(adminTaskId, "");
    }

    function removeCreator(uint256 adminTaskId, address account) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _removeCreator(account);
        _finalizeTask(adminTaskId, "");
    }

    function _isCreator(address account) internal view returns (bool) {
        return _creators[account];
    }

    function _addCreator(address account) internal {
        require(account != address(0), "CRE: zero account");
        require(!_creators[account], "CRE: is creator");
        _creators[account] = true;
        _nrOfCreators += 1;
        emit CreatorAdded(account);
    }

    function _removeCreator(address account) internal {
        require(account != address(0), "CRE: zero account");
        require(_creators[account], "CRE: not creator");
        _creators[account] = false;
        _nrOfCreators -= 1;
        emit CreatorRemoved(account);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./AdminRoleEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract ApproverRoleEnabled is AdminRoleEnabled {

    mapping (address => bool) private _approvers;

    uint internal _nrOfApprovers;

    event ApproverAdded(address account);
    event ApproverRemoved(address account);

    modifier onlyApprover() {
        require(_isApprover(msg.sender), "ApRE: not approver");
        _;
    }

    constructor() {
        _nrOfApprovers = 0;
    }

    function isApprover(address account) external view
      onlyAdmin
      returns (bool)
    {
        return _isApprover(account);
    }

    function addApprover(uint256 adminTaskId, address account) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _addApprover(account);
        _finalizeTask(adminTaskId, "");
    }

    function removeApprover(uint256 adminTaskId, address account) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _removeApprover(account);
        _finalizeTask(adminTaskId, "");
    }

    function _isApprover(address account) internal view returns (bool) {
        return _approvers[account];
    }

    function _addApprover(address account) internal {
        require(account != address(0), "ApRE: zero account");
        require(!_approvers[account], "ApRE: is approver");
        _approvers[account] = true;
        _nrOfApprovers += 1;
        emit ApproverAdded(account);
    }

    function _removeApprover(address account) internal {
        require(account != address(0), "ApRE: zero account");
        require(_approvers[account], "ApRE: not approver");
        _approvers[account] = false;
        _nrOfApprovers -= 1;
        emit ApproverRemoved(account);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./AdminRoleEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract ExecutorRoleEnabled is AdminRoleEnabled {

    mapping (address => bool) private _executors;

    uint internal _nrOfExecutors;

    event ExecutorAdded(address account);
    event ExecutorRemoved(address account);

    modifier mustBeExecutor(address account) {
        require(_isExecutor(account), "ERE: not executor");
        _;
    }

    constructor() {
        _nrOfExecutors = 0;
    }

    function isExecutor(address account) external view
      onlyAdmin
      returns (bool)
    {
        return _isExecutor(account);
    }

    function addExecutor(uint256 adminTaskId, address account) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _addExecutor(account);
        _finalizeTask(adminTaskId, "");
    }

    function removeExecutor(uint256 adminTaskId, address account) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _removeExecutor(account);
        _finalizeTask(adminTaskId, "");
    }

    function _isExecutor(address account) internal view returns (bool) {
        return _executors[account];
    }

    function _addExecutor(address account) internal {
        require(account != address(0), "ERE: zero account");
        require(!_executors[account], "ERE: is executor");
        _executors[account] = true;
        _nrOfExecutors += 1;
        emit ExecutorAdded(account);
    }

    function _removeExecutor(address account) internal {
        require(account != address(0), "ERE: zero account");
        require(_executors[account], "ERE: not executor");
        _executors[account] = false;
        _nrOfExecutors -= 1;
        emit ExecutorRemoved(account);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../ETHVault.sol";
import "./AdminRoleEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract ETHVaultEnabled is AdminRoleEnabled, ETHVault {

    function isDepositEnabled() external view onlyAdmin returns (bool) {
        return _isDepositEnabled();
    }

    function setEnableDeposit(
        uint256 adminTaskId,
        bool enableDeposit
    ) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        require(_isDepositEnabled() != enableDeposit, "EVE: the same value");
        _setEnableDeposit(enableDeposit);
        _finalizeTask(adminTaskId, "");
    }

    /* solhint-disable func-name-mixedcase */
    function ETHTransfer(
        uint256 adminTaskId,
        address to,
        uint256 amount
    ) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _ETHTransfer(to, amount);
        _finalizeTask(adminTaskId, "");
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../ERC20Vault.sol";
import "./AdminRoleEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract ERC20VaultEnabled is AdminRoleEnabled, ERC20Vault {

    /* solhint-disable func-name-mixedcase */
    function ERC20Transfer(
        uint256 adminTaskId,
        address tokenContract,
        address to,
        uint256 amount
    ) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _ERC20Transfer(tokenContract, to, amount);
        _finalizeTask(adminTaskId, "");
    }

    function ERC20Approve(
        uint256 adminTaskId,
        address tokenContract,
        address spender,
        uint256 amount
    ) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _ERC20Approve(tokenContract, spender, amount);
        _finalizeTask(adminTaskId, "");
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../ERC721Vault.sol";
import "./AdminRoleEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract ERC721VaultEnabled is AdminRoleEnabled, ERC721Vault {

    /* solhint-disable func-name-mixedcase */
    function ERC721Transfer(
        uint256 adminTaskId,
        address tokenContract,
        address to,
        uint256 tokenId
    ) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _ERC721Transfer(tokenContract, to, tokenId);
        _finalizeTask(adminTaskId, "");
    }

    function ERC721Approve(
        uint256 adminTaskId,
        address tokenContract,
        address operator,
        uint256 tokenId
    ) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _ERC721Approve(tokenContract, operator, tokenId);
        _finalizeTask(adminTaskId, "");
    }

    function ERC721SetApprovalForAll(
        uint256 adminTaskId,
        address tokenContract,
        address operator,
        bool approved
    ) external
      onlyAdmin
      taskMustExist(adminTaskId)
      taskMustBeAdministrative(adminTaskId)
      taskMustNotBeFinalized(adminTaskId)
      taskMustBeApproved(adminTaskId)
    {
        _ERC721SetApprovalForAll(tokenContract, operator, approved);
        _finalizeTask(adminTaskId, "");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk

abstract contract ETHVault {

    bool private _enableDeposit;

    event DepositEnabled();
    event DepositDisabled();
    event ETHTransferred(address to, uint256 amount);

    constructor() {
        _enableDeposit = false;
    }

    function _isDepositEnabled() internal view returns (bool) {
        return _enableDeposit;
    }

    function _setEnableDeposit(bool enableDeposit) internal {
        _enableDeposit = enableDeposit;
        if (_enableDeposit) {
            emit DepositEnabled();
        } else {
            emit DepositDisabled();
        }
    }

    /* solhint-disable func-name-mixedcase */
    function _ETHTransfer(
        address to,
        uint256 amount
    ) internal {
        require(to != address(0), "EV: zero target");
        require(amount > 0, "EV: zero amount");
        require(amount <= address(this).balance, "EV: more than balance");

        /* solhint-disable avoid-low-level-calls */
        (bool success, ) = to.call{value: amount}(new bytes(0));
        /* solhint-enable avoid-low-level-calls */
        require(success, "EV: failed to transfer");
        emit ETHTransferred(to, amount);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract ERC20Vault {

    event ERC20Transferred(address tokenContract, address to, uint256 amount);
    event ERC20Approved(address tokenContract, address spender, uint256 amount);

    /* solhint-disable func-name-mixedcase */
    function _ERC20Transfer(
        address tokenContract,
        address to,
        uint256 amount
    ) internal {
        require(tokenContract != address(0), "E2V: zero address");
        require(to != address(0), "E2V: zero target");
        require(amount > 0, "E2V: zero amount");
        require(amount <= IERC20(tokenContract).balanceOf(address(this)),
                                "E2V: more than balance");

        IERC20(tokenContract).transfer(to, amount);
        emit ERC20Transferred(tokenContract, to, amount);
    }

    function _ERC20Approve(
        address tokenContract,
        address spender,
        uint256 amount
    ) internal {
        require(tokenContract != address(0), "E2V: zero address");
        require(spender != address(0), "E2V: zero spender");

        IERC20(tokenContract).approve(spender, amount);
        emit ERC20Approved(tokenContract, spender, amount);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract ERC721Vault is IERC721Receiver {

    event ERC721Transferred(address tokenContract, address to, uint256 tokenId);
    event ERC721Approved(address tokenContract, address to, uint256 tokenId);
    event ERC721ApprovedForAll(address tokenContract, address operator, bool approved);

    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 /* tokenId */,
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    /* solhint-disable func-name-mixedcase */
    function _ERC721Transfer(
        address tokenContract,
        address to,
        uint256 tokenId
    ) internal {
        require(tokenContract != address(0), "E7V: zero address");
        require(to != address(0), "E7V: zero target");

        IERC721(tokenContract).safeTransferFrom(address(this), to, tokenId, "");
        emit ERC721Transferred(tokenContract, to, tokenId);
    }

    // operator can be the zero address.
    function _ERC721Approve(
        address tokenContract,
        address operator,
        uint256 tokenId
    ) internal {
        require(tokenContract != address(0), "E7V: zero address");

        IERC721(tokenContract).approve(operator, tokenId);
        emit ERC721Approved(tokenContract, operator, tokenId);
    }

    function _ERC721SetApprovalForAll(
        address tokenContract,
        address operator,
        bool approved
    ) internal {
        require(tokenContract != address(0), "E7V: zero address");
        require(operator != address(0), "E7V: zero operator");

        IERC721(tokenContract).setApprovalForAll(operator, approved);
        emit ERC721ApprovedForAll(tokenContract, operator, approved);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../arteq-tech/contracts/TaskManager.sol";

/// @notice Use at your own risk
/* solhint-disable contract-name-camelcase */
contract arteQTaskManager is TaskManager {

    /* solhint-disable no-empty-blocks */
    constructor(
        address[] memory initialAdmins,
        address[] memory initialCreators,
        address[] memory initialApprovers,
        address[] memory initialExecutors,
        bool enableDeposit
    ) TaskManager(
        initialAdmins,
        initialCreators,
        initialApprovers,
        initialExecutors,
        enableDeposit
    ) {}
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../abstract/task-manager/AdminTaskManaged.sol";
import "../../abstract/task-manager/ERC721VaultEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TestERC721VaultEnabled is ERC721VaultEnabled, AdminTaskManaged {

    constructor(address[] memory initialAdmins) {
        require(initialAdmins.length >= MIN_NR_OF_ADMINS, "TestERC721VaultEnabled: not enough initial admins");
        for (uint i = 0; i < initialAdmins.length; i++) {
            _addAdmin(initialAdmins[i]);
        }
    }

    /* solhint-disable func-name-mixedcase */
    function testonly_createNonAdministrativeTask(string memory taskURI) external {
        _createTask(taskURI, false);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../abstract/task-manager/AdminTaskManaged.sol";
import "../../abstract/task-manager/ExecutorRoleEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TestExecutorRoleEnabled is ExecutorRoleEnabled, AdminTaskManaged {

    constructor(address[] memory initialAdmins, address[] memory initialExecutors) {
        require(initialAdmins.length >= MIN_NR_OF_ADMINS, "TestExecutorRoleEnabled: not enough initial admins");
        for (uint i = 0; i < initialAdmins.length; i++) {
            _addAdmin(initialAdmins[i]);
        }
        for (uint i = 0; i < initialExecutors.length; i++) {
            _addExecutor(initialExecutors[i]);
        }
    }

    /* solhint-disable func-name-mixedcase */
    function testonly_createNonAdministrativeTask(string memory taskURI) external {
        _createTask(taskURI, false);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../abstract/task-manager/AdminTaskManaged.sol";
import "../../abstract/task-manager/ETHVaultEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TestETHVaultEnabled is ETHVaultEnabled, AdminTaskManaged {

    constructor(address[] memory initialAdmins) {
        require(initialAdmins.length >= MIN_NR_OF_ADMINS, "TestETHVaultEnabled: not enough initial admins");
        for (uint i = 0; i < initialAdmins.length; i++) {
            _addAdmin(initialAdmins[i]);
        }
        _setEnableDeposit(false);
    }

    /* solhint-disable func-name-mixedcase */
    function testonly_createNonAdministrativeTask(string memory taskURI) external {
        _createTask(taskURI, false);
    }

    receive() external payable {
        require(_isDepositEnabled(), "TestETHVaultEnabled: cannot accept ether");
    }

    fallback() external payable {
        revert("TestETHVaultEnabled: fallback always fails");
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../ETHVault.sol";
import "./TaskExecutor.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract TaskManagedETHVaultEnabled is TaskExecutor, ETHVault {

    function isDepositEnabled() external view returns (bool) {
        return _isDepositEnabled();
    }

    function setEnableDeposit(
        uint256 taskId,
        bool enableDeposit
    ) external
      tryExecuteTaskAfterwards(taskId)
    {
        require(_isDepositEnabled() != enableDeposit, "TMEV: the same value");
        _setEnableDeposit(enableDeposit);
    }

    /* solhint-disable func-name-mixedcase */
    function ETHTransfer(
        uint256 taskId,
        address to,
        uint256 amount
    ) external
      tryExecuteTaskAfterwards(taskId)
    {
        _ETHTransfer(to, amount);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "../../interfaces/ITaskExecutor.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract TaskExecutor {

    address private _taskManager;

    event TaskManagerChanged(address newTaskManager);

    modifier tryExecuteTaskAfterwards(uint256 taskId) {
        require(_taskManager != address(0), "TE: no task manager");
        _;
        ITaskExecutor(_taskManager).executeTask(msg.sender, taskId);
    }

    function getTaskManager() external view returns (address) {
        return _getTaskManager();
    }

    function setTaskManager(
        uint256 adminTaskId,
        address newTaskManager
    ) external {
        address oldTaskManager = _taskManager;
        _setTaskManager(newTaskManager);
        if (oldTaskManager != address(0)) {
            ITaskExecutor(oldTaskManager).executeAdminTask(msg.sender, adminTaskId);
        }
    }

    function _getTaskManager() internal view returns (address) {
        return _taskManager;
    }

    function _setTaskManager(address newTaskManager) internal {
        require(newTaskManager != address(0), "TE: zero address");
        require(IERC165(newTaskManager).supportsInterface(type(ITaskExecutor).interfaceId),
            "TE: invalid contract");
        _taskManager = newTaskManager;
        emit TaskManagerChanged(_taskManager);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../abstract/task-managed/TaskManagedETHVaultEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TestTaskManagedETHVaultEnabled is TaskManagedETHVaultEnabled {

    constructor(address taskManager) {
        _setTaskManager(taskManager);
        _setEnableDeposit(false);
    }

    receive() external payable {
        require(_isDepositEnabled(), "TestTaskManagedETHVaultEnabled: cannot accept ether");
    }

    fallback() external payable {
        revert("TestTaskManagedETHVaultEnabled: fallback always fails");
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../abstract/task-managed/TaskExecutor.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TestTaskExecutor is TaskExecutor {

    constructor(address taskManager) {
        _setTaskManager(taskManager);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../ERC721Vault.sol";
import "./TaskExecutor.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract TaskManagedERC721VaultEnabled is TaskExecutor, ERC721Vault {

    /* solhint-disable func-name-mixedcase */
    function ERC721Transfer(
        uint256 taskId,
        address tokenContract,
        address to,
        uint256 tokenId
    ) external
      tryExecuteTaskAfterwards(taskId)
    {
        _ERC721Transfer(tokenContract, to, tokenId);
    }

    function ERC721Approve(
        uint256 taskId,
        address tokenContract,
        address operator,
        uint256 tokenId
    ) external
      tryExecuteTaskAfterwards(taskId)
    {
        _ERC721Approve(tokenContract, operator, tokenId);
    }

    function ERC721SetApprovalForAll(
        uint256 taskId,
        address tokenContract,
        address operator,
        bool approved
    ) external
      tryExecuteTaskAfterwards(taskId)
    {
        _ERC721SetApprovalForAll(tokenContract, operator, approved);
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../../arteq-tech/contracts/abstract/task-managed/AccountLocker.sol";
import "../../arteq-tech/contracts/abstract/task-managed/BatchTransferEnabled.sol";
import "../../arteq-tech/contracts/abstract/task-managed/TaskManagedERC20VaultEnabled.sol";
import "../../arteq-tech/contracts/abstract/task-managed/TaskManagedERC721VaultEnabled.sol";
import "../../arteq-tech/contracts/abstract/task-managed/TaskManagedERC1155VaultEnabled.sol";

/// @notice Use at your own risk
/* solhint-disable reason-string */
contract ARTEQ is
  ERC20,
  AccountLocker,
  BatchTransferEnabled,
  TaskManagedERC20VaultEnabled,
  TaskManagedERC721VaultEnabled,
  TaskManagedERC1155VaultEnabled
{
    constructor(address taskManager)
      ERC20("arteQ NFT Investment Fund", "ARTEQ")
    {
        require(taskManager != address(0), "ARTEQ: zero address set for task manager");
        _setTaskManager(taskManager);
        _mint(_getTaskManager(), 10 * 10 ** 9); // 10 billion tokens
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function _beforeTokenTransfer(
        address from,
        address /*to*/,
        uint256 /*amount*/
    ) internal virtual override {
        require(!_isLocked(from), "ARTEQ: account cannot transfer tokens");
    }

    function _batchTransferSingle(
        address source,
        address to,
        uint256 amount
    ) internal virtual override {
        _transfer(source, to, amount);
    }

    receive() external payable {
        revert("ARTEQ: cannot accept ether");
    }

    fallback() external payable {
        revert("ARTEQ: cannot accept ether");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./TaskExecutor.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract AccountLocker is TaskExecutor {

    mapping (address => uint256) private _lockedAccounts;

    event LockTsChanged(address account, uint256 lockTimestamp);

    function updateLockTs(
        uint256 taskId,
        address[] memory accounts,
        uint256[] memory lockTss
    ) external
      tryExecuteTaskAfterwards(taskId)
    {
        require(accounts.length == lockTss.length, "AL: wrong lengths");
        require(accounts.length > 0, "AL: empty inputs");
        for (uint256 i = 0; i < accounts.length; i++) {
            _updateLockTs(accounts[i], lockTss[i]);
        }
    }

    function _getLockTs(address account) internal view returns (uint256) {
        return _lockedAccounts[account];
    }

    function _updateLockTs(address account, uint256 lockTs) internal {
        uint256 oldLockTs = _lockedAccounts[account];
        _lockedAccounts[account] = lockTs;
        if (oldLockTs != lockTs) {
            emit LockTsChanged(account, lockTs);
        }
    }

    function _isLocked(address account) internal view returns (bool) {
        uint256 lockTs = _getLockTs(account);
        /* solhint-disable not-rely-on-time */
        return lockTs > 0 && block.timestamp <= lockTs;
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./AccountLocker.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract BatchTransferEnabled is AccountLocker {

    function doBatchTransferWithLock(
        uint256 taskId,
        address[] memory tos,
        uint256[] memory amounts,
        uint256[] memory lockTss
    ) external
      tryExecuteTaskAfterwards(taskId)
    {
        _doBatchTransferWithLock(tos, amounts, lockTss);
    }

    function _batchTransferSingle(address source, address to, uint256 amount) internal virtual;

    function _doBatchTransferWithLock(
        address[] memory tos,
        uint256[] memory amounts,
        uint256[] memory lockTss
    ) private {
        require(_getTaskManager() != address(0), "BTE: no source");
        require(tos.length == amounts.length, "BTE: wrong lengths");
        require(tos.length == lockTss.length, "BTE: wrong lengths");
        require(tos.length > 0, "BTE: empty inputs");
        for (uint256 i = 0; i < tos.length; i++) {
            require(tos[i] != address(0), "BTE: zero address");
            require(tos[i] != _getTaskManager(), "BTE: invalid target");
            if (amounts[i] > 0) {
                _batchTransferSingle(_getTaskManager(), tos[i], amounts[i]);
            }
            if (lockTss[i] > 0) {
                _updateLockTs(tos[i], lockTss[i]);
            }
        }
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../ERC20Vault.sol";
import "./TaskExecutor.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract TaskManagedERC20VaultEnabled is TaskExecutor, ERC20Vault {

    /* solhint-disable func-name-mixedcase */
    function ERC20Transfer(
        uint256 taskId,
        address tokenContract,
        address to,
        uint256 amount
    ) external
      tryExecuteTaskAfterwards(taskId)
    {
        _ERC20Transfer(tokenContract, to, amount);
    }

    function ERC20Approve(
        uint256 taskId,
        address tokenContract,
        address spender,
        uint256 amount
    ) external
      tryExecuteTaskAfterwards(taskId)
    {
        _ERC20Approve(tokenContract, spender, amount);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../ERC1155Vault.sol";
import "./TaskExecutor.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract TaskManagedERC1155VaultEnabled is TaskExecutor, ERC1155Vault {

    /* solhint-disable func-name-mixedcase */
    function ERC1155Transfer(
        uint256 taskId,
        address tokenContract,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external
      tryExecuteTaskAfterwards(taskId)
    {
        _ERC1155Transfer(tokenContract, to, tokenId, amount);
    }

    function ERC1155SetApprovalForAll(
        uint256 taskId,
        address tokenContract,
        address operator,
        bool approved
    ) external
      tryExecuteTaskAfterwards(taskId)
    {
        _ERC1155SetApprovalForAll(tokenContract, operator, approved);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../abstract/task-managed/TaskManagedERC1155VaultEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TestTaskManagedERC1155VaultEnabled is TaskManagedERC1155VaultEnabled {

    constructor(address taskManager) {
        _setTaskManager(taskManager);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../abstract/task-managed/TaskManagedERC20VaultEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TestTaskManagedERC20VaultEnabled is TaskManagedERC20VaultEnabled {

    constructor(address taskManager) {
        _setTaskManager(taskManager);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../abstract/task-manager/AdminTaskManaged.sol";
import "../../abstract/task-manager/ERC20VaultEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TestERC20VaultEnabled is ERC20VaultEnabled, AdminTaskManaged {

    constructor(address[] memory initialAdmins) {
        require(initialAdmins.length >= MIN_NR_OF_ADMINS, "TestERC20VaultEnabled: not enough initial admins");
        for (uint i = 0; i < initialAdmins.length; i++) {
            _addAdmin(initialAdmins[i]);
        }
    }

    /* solhint-disable func-name-mixedcase */
    function testonly_createNonAdministrativeTask(string memory taskURI) external {
        _createTask(taskURI, false);
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../IUniswapV2Pair.sol";
import "./PaymentHandlerStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library PaymentHandlerInternal {

    bytes32 constant public WEI_PAYMENT_METHOD_HASH = keccak256(abi.encode("WEI"));

    event WeiPayment(address payer, address dest, uint256 amountWei);
    event ERC20Payment(
        string paymentMethodName,
        address payer,
        address dest,
        uint256 amountWei,
        uint256 amountTokens
    );
    event TransferTo(address to, uint256 amount, string data);
    event TransferETH20To(string paymentMethodName, address to, uint256 amount, string data);

    function _getPaymentSettings() internal view returns (address, address) {
        return (__s().payoutAddress, __s().wethAddress);
    }

    function _setPaymentSettings(
        address payoutAddress,
        address wethAddress
    ) internal {
        __s().payoutAddress = payoutAddress;
        __s().wethAddress = wethAddress;
    }

    function _getERC20PaymentMethods() internal view returns (string[] memory) {
        return __s().erc20PaymentMethodNames;
    }

    function _getERC20PaymentMethodInfo(
        string memory paymentMethodName
    ) internal view returns (address, address, bool) {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(_paymentMethodExists(nameHash), "PH:NEM");
        return (
            __s().erc20PaymentMethods[nameHash].addr,
            __s().erc20PaymentMethods[nameHash].wethPair,
            __s().erc20PaymentMethods[nameHash].enabled
        );
    }

    function _addOrUpdateERC20PaymentMethod(
        string memory paymentMethodName,
        address addr,
        address wethPair
    ) internal {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        __s().erc20PaymentMethods[nameHash].addr = addr;
        __s().erc20PaymentMethods[nameHash].wethPair = wethPair;
        address token0 = IUniswapV2Pair(wethPair).token0();
        address token1 = IUniswapV2Pair(wethPair).token1();
        require(token0 == __s().wethAddress || token1 == __s().wethAddress, "PH:IPC");
        bool reverseIndices = (token1 == __s().wethAddress);
        __s().erc20PaymentMethods[nameHash].reverseIndices = reverseIndices;
        __s().erc20PaymentMethodNames.push(paymentMethodName);
    }

    function _enableERC20TokenPayment(
        string memory paymentMethodName,
        bool enabled
    ) internal {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(_paymentMethodExists(nameHash), "PH:NEM");
        __s().erc20PaymentMethods[nameHash].enabled = enabled;
    }

    function _transferTo(
        string memory paymentMethodName,
        address to,
        uint256 amount,
        string memory data
    ) internal {
        require(to != address(0), "PH:TTZ");
        require(amount > 0, "PH:ZAM");
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(nameHash == WEI_PAYMENT_METHOD_HASH || _paymentMethodExists(nameHash), "PH:MNS");
        if (nameHash == WEI_PAYMENT_METHOD_HASH) {
            require(amount <= address(this).balance, "PH:MTB");
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = to.call{value: amount}(new bytes(0));
            /* solhint-enable avoid-low-level-calls */
            require(success, "PH:TF");
            emit TransferTo(to, amount, data);
        } else {
            PaymentHandlerStorage.ERC20PaymentMethodInfo memory paymentMethod =
                __s().erc20PaymentMethods[nameHash];
            require(
                amount <= IERC20(paymentMethod.addr).balanceOf(address(this)),
                "PH:MTB"
            );
            IERC20(paymentMethod.addr).transfer(to, amount);
            emit TransferETH20To(paymentMethodName, to, amount, data);
        }
    }

    function _handlePayment(
        uint256 nrOfItems1, uint256 priceWeiPerItem1,
        uint256 nrOfItems2, uint256 priceWeiPerItem2,
        string memory paymentMethodName
    ) internal {
        uint256 totalWei =
            nrOfItems1 * priceWeiPerItem1 +
            nrOfItems2 * priceWeiPerItem2;
        if (totalWei == 0) {
            return;
        }
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(nameHash == WEI_PAYMENT_METHOD_HASH ||
                _paymentMethodExists(nameHash), "PH:MNS");
        if (nameHash == WEI_PAYMENT_METHOD_HASH) {
            _handleWeiPayment(totalWei);
        } else {
            _handleERC20Payment(totalWei, paymentMethodName);
        }
    }

    function _paymentMethodExists(bytes32 paymentMethodNameHash) private view returns (bool) {
        return __s().erc20PaymentMethods[paymentMethodNameHash].addr != address(0) &&
               __s().erc20PaymentMethods[paymentMethodNameHash].wethPair != address(0) &&
               __s().erc20PaymentMethods[paymentMethodNameHash].enabled;
    }

    function _handleWeiPayment(
        uint256 priceWeiToPay
    ) private {
        require(msg.value >= priceWeiToPay, "PH:IF");
        uint256 remainder = msg.value - priceWeiToPay;
        if (__s().payoutAddress != address(0)) {
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = __s().payoutAddress.call{value: priceWeiToPay}(new bytes(0));
            /* solhint-enable avoid-low-level-calls */
            require(success, "PH:TF");
            emit WeiPayment(msg.sender, __s().payoutAddress, priceWeiToPay);
        } else {
            emit WeiPayment(msg.sender, address(this), priceWeiToPay);
        }
        if (remainder > 0) {
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = msg.sender.call{value: remainder}(new bytes(0));
            /* solhint-enable avoid-low-level-calls */
            require(success, "PH:RTF");
        }
    }

    function _handleERC20Payment(
        uint256 priceWeiToPay,
        string memory paymentMethodName
    ) private {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        PaymentHandlerStorage.ERC20PaymentMethodInfo memory paymentMethod =
            __s().erc20PaymentMethods[nameHash];
        (uint112 amount0, uint112 amount1,) = IUniswapV2Pair(paymentMethod.wethPair).getReserves();
        uint256 reserveWei = amount0;
        uint256 reserveTokens = amount1;
        if (paymentMethod.reverseIndices) {
            reserveWei = amount1;
            reserveTokens = amount0;
        }
        require(reserveWei > 0, "PH:NWR");
        uint256 amountTokens = (priceWeiToPay * reserveTokens) / reserveWei;
        address dest = address(this);
        if (__s().payoutAddress != address(0)) {
            dest = __s().payoutAddress;
        }
        // this contract must have already been approved by the msg.sender
        IERC20(paymentMethod.addr).transferFrom(msg.sender, dest, amountTokens);
        emit ERC20Payment(paymentMethodName, msg.sender, dest, priceWeiToPay, amountTokens);
    }

    function __s() private pure returns (PaymentHandlerStorage.Layout storage) {
        return PaymentHandlerStorage.layout();
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library PaymentHandlerStorage {

    struct ERC20PaymentMethodInfo {
        address addr;
        // Uniswap V2 Pair
        address wethPair;
        bool reverseIndices;
        bool enabled;
    }

    struct Layout {
        address payoutAddress;
        address wethAddress;
        string[] erc20PaymentMethodNames;
        mapping(bytes32 => ERC20PaymentMethodInfo) erc20PaymentMethods;
        mapping(uint256 => uint256) extra;
    }

    // Storage Slot: a0efacd423120980dd05e5b29c20ccdcbe1b82d6c1e2453fa01907429f24d423
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-io.collections.v2.payment-handler.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../../arteq-tech/contracts/diamond/IDiamondFacet.sol";
import "../../../arteq-tech/contracts/security/role-manager/RoleManagerLib.sol";
import "../arteQCollectionV2Config.sol";
import "./PaymentHandlerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract PaymentHandlerFacet is IDiamondFacet {

    modifier onlyAdmin() {
        RoleManagerLib._checkRole(arteQCollectionV2Config.ROLE_ADMIN);
        _;
    }

    function getFacetName()
      external pure override returns (string memory) {
        return "payment-handler";
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getFacetVersion()
      external pure override returns (string memory) {
        return "0.0.1";
    }

    function getFacetPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](7);
        pi[0] = "getPaymentSettings()";
        pi[1] = "setPaymentSettings(address,address)";
        pi[2] = "getERC20PaymentMethods()";
        pi[3] = "getERC20PaymentMethodInfo(string)";
        pi[4] = "addOrUpdateERC20PaymentMethod(string,address,address)";
        pi[5] = "enableERC20TokenPayment(string,bool)";
        pi[6] = "transferTo(string,address,uint256,string)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId;
    }

    function getPaymentSettings() external view returns (address, address) {
        return PaymentHandlerInternal._getPaymentSettings();
    }

    function setPaymentSettings(
        address wethAddress,
        address payoutAddress
    ) external onlyAdmin {
        PaymentHandlerInternal._setPaymentSettings(
            wethAddress,
            payoutAddress
        );
    }

    function getERC20PaymentMethods() external view returns (string[] memory) {
        return PaymentHandlerInternal._getERC20PaymentMethods();
    }

    function getERC20PaymentMethodInfo(
        string memory paymentMethodName
    ) external view returns (address, address, bool) {
        return PaymentHandlerInternal._getERC20PaymentMethodInfo(paymentMethodName);
    }

    function addOrUpdateERC20PaymentMethod(
        string memory paymentMethodName,
        address addr,
        address wethPair
    ) external onlyAdmin {
        PaymentHandlerInternal._addOrUpdateERC20PaymentMethod(
            paymentMethodName,
            addr,
            wethPair
        );
    }

    function enableERC20TokenPayment(
        string memory paymentMethodName,
        bool enabled
    ) external onlyAdmin {
        PaymentHandlerInternal._enableERC20TokenPayment(
            paymentMethodName,
            enabled
        );
    }

    function transferTo(
        string memory paymentMethodName,
        address to,
        uint256 amount,
        string memory data
    ) external onlyAdmin {
        PaymentHandlerInternal._transferTo(
            paymentMethodName,
            to,
            amount,
            data
        );
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IDiamondFacet is IERC165 {

    // NOTE: The override MUST remain 'pure'.
    function getFacetName() external pure returns (string memory);

    // NOTE: The override MUST remain 'pure'.
    function getFacetVersion() external pure returns (string memory);

    // NOTE: The override MUST remain 'pure'.
    function getFacetPI() external pure returns (string[] memory);
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./RoleManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library RoleManagerLib {

    function _checkRole(uint256 role) internal view {
        RoleManagerInternal._checkRole(role);
    }

    function _hasRole(uint256 role) internal view returns (bool) {
        return RoleManagerInternal._hasRole(role);
    }

    function _grantRole(
        address account,
        uint256 role
    ) internal {
        RoleManagerInternal._grantRole(account, role);
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk

/* solhint-disable contract-name-camelcase */
library arteQCollectionV2Config {

    uint256 constant public ROLE_ADMIN = uint256(keccak256(bytes("ROLE_ADMIN")));

    uint256 constant public ROLE_TOKEN_MANAGER = uint256(keccak256(bytes("ROLE_TOKEN_MANAGER")));
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./RoleManagerStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library RoleManagerInternal {

    event RoleGrant(uint256 role, address account);
    event RoleRevoke(uint256 role, address account);

    function _checkRole(uint256 role) internal view {
        require(__s().roles[role][msg.sender], "RM:MR");
    }

    function _hasRole(uint256 role) internal view returns (bool) {
        return __s().roles[role][msg.sender];
    }

    function _hasRole2(
        address account,
        uint256 role
    ) internal view returns (bool) {
        return __s().roles[role][account];
    }

    function _grantRole(
        address account,
        uint256 role
    ) internal {
        require(!__s().roles[role][account], "RM:AHR");
        __s().roles[role][account] = true;
        emit RoleGrant(role, account);
    }

    function _revokeRole(
        address account,
        uint256 role
    ) internal {
        require(__s().roles[role][account], "RM:DNHR");
        __s().roles[role][account] = false;
        emit RoleRevoke(role, account);
    }

    function __s() private pure returns (RoleManagerStorage.Layout storage) {
        return RoleManagerStorage.layout();
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library RoleManagerStorage {

    struct Layout {
        mapping (uint256 => mapping(address => bool)) roles;
        mapping(uint256 => uint256) extra;
    }

    // Storage Slot: d6cfccebecf684bbc10a5019ad1aed91fbc4f7461f5cd03e8c71240be4ca6bea
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-tech.contracts.security.role-manager.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../../arteq-tech/contracts/diamond/IDiamondFacet.sol";
import "../../../arteq-tech/contracts/security/role-manager/RoleManagerLib.sol";
import "../arteQCollectionV2Config.sol";
import "./WhitelistManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract WhitelistManagerFacet is IDiamondFacet {

    modifier onlyAdmin() {
        RoleManagerLib._checkRole(arteQCollectionV2Config.ROLE_ADMIN);
        _;
    }

    function getFacetName()
      external pure override returns (string memory) {
        return "whitelist-manager";
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getFacetVersion()
      external pure override returns (string memory) {
        return "0.0.1";
    }

    function getFacetPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](5);
        pi[0] = "getWhitelistingSettings()";
        pi[1] = "setWhitelistingSettings(bool,uint256,uint256,uint256)";
        pi[2] = "whitelistMe(uint256,string)";
        pi[3] = "whitelistAccounts(address[],uint256[])";
        pi[4] = "getWhitelistEntry(address)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId;
    }

    function getWhitelistingSettings()
      external view returns (bool, uint256, uint256, uint256) {
        return WhitelistManagerInternal._getWhitelistingSettings();
    }

    function setWhitelistingSettings(
        bool whitelistingAllowed,
        uint256 whitelistingFeeWei,
        uint256 whitelistingPriceWeiPerToken,
        uint256 maxNrOfWhitelistedTokensPerAccount
    ) external onlyAdmin {
        WhitelistManagerInternal._setWhitelistingSettings(
            whitelistingAllowed,
            whitelistingFeeWei,
            whitelistingPriceWeiPerToken,
            maxNrOfWhitelistedTokensPerAccount
        );
    }

    // Send 0 for nrOfTokens to de-list the address
    function whitelistMe(
        uint256 nrOfTokens,
        string memory paymentMethodName
    ) external payable {
        WhitelistManagerInternal._whitelistMe(
            nrOfTokens,
            paymentMethodName
        );
    }

    // Send 0 for nrOfTokens to de-list an address
    function whitelistAccounts(
        address[] memory accounts,
        uint256[] memory nrOfTokensArray
    ) external onlyAdmin {
        WhitelistManagerInternal._whitelistAccounts(
            accounts,
            nrOfTokensArray
        );
    }

    function getWhitelistEntry(address account) external view returns (uint256) {
        return WhitelistManagerInternal._getWhitelistEntry(account);
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../payment-handler/PaymentHandlerLib.sol";
import "./WhitelistManagerStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library WhitelistManagerInternal {

    event Whitelist(address account, uint256 nrOfTokens);

    function _getWhitelistingSettings()
      internal view returns (bool, uint256, uint256, uint256) {
        return (
            __s().whitelistingAllowed,
            __s().whitelistingFeeWei,
            __s().whitelistingPriceWeiPerToken,
            __s().maxNrOfWhitelistedTokensPerAccount
        );
    }

    function _setWhitelistingSettings(
        bool whitelistingAllowed,
        uint256 whitelistingFeeWei,
        uint256 whitelistingPriceWeiPerToken,
        uint256 maxNrOfWhitelistedTokensPerAccount
    ) internal {
        __s().whitelistingAllowed = whitelistingAllowed;
        __s().whitelistingFeeWei = whitelistingFeeWei;
        __s().whitelistingPriceWeiPerToken = whitelistingPriceWeiPerToken;
        __s().maxNrOfWhitelistedTokensPerAccount = maxNrOfWhitelistedTokensPerAccount;
    }

    // Send 0 for nrOfTokens to de-list the address
    function _whitelistMe(
        uint256 nrOfTokens,
        string memory paymentMethodName
    ) internal {
        require(__s().whitelistingAllowed, "WM:NA");
        PaymentHandlerLib._handlePayment(
            1, __s().whitelistingFeeWei,
            nrOfTokens, __s().whitelistingPriceWeiPerToken,
            paymentMethodName
        );
        _whitelist(msg.sender, nrOfTokens);
    }

    // Send 0 for nrOfTokens to de-list an address
    function _whitelistAccounts(
        address[] memory accounts,
        uint256[] memory nrOfTokensArray
    ) internal {
        require(__s().whitelistingAllowed, "WM:NA");
        require(accounts.length == nrOfTokensArray.length, "WM:IL");
        for (uint256 i = 0; i < accounts.length; i++) {
            _whitelist(accounts[i], nrOfTokensArray[i]);
        }
    }

    function _getWhitelistEntry(address account) internal view returns (uint256) {
        return __s().whitelistEntries[account];
    }

    function _whitelist(
        address account,
        uint256 nrOfTokens
    ) private {
        require(__s().maxNrOfWhitelistedTokensPerAccount == 0 ||
                nrOfTokens <= __s().maxNrOfWhitelistedTokensPerAccount,
                "WM:EMAX");
        __s().whitelistEntries[account] = nrOfTokens;
        emit Whitelist(account, nrOfTokens);
    }

    function __s() private pure returns (WhitelistManagerStorage.Layout storage) {
        return WhitelistManagerStorage.layout();
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./PaymentHandlerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library PaymentHandlerLib {

    function _handlePayment(
        uint256 nrOfItems1, uint256 priceWeiPerItem1,
        uint256 nrOfItems2, uint256 priceWeiPerItem2,
        string memory paymentMethodName
    ) internal {
        PaymentHandlerInternal._handlePayment(
            nrOfItems1, priceWeiPerItem1,
            nrOfItems2, priceWeiPerItem2,
            paymentMethodName
        );
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library WhitelistManagerStorage {

    struct Layout {
        bool whitelistingAllowed;
        uint256 whitelistingFeeWei;
        uint256 whitelistingPriceWeiPerToken;
        uint256 maxNrOfWhitelistedTokensPerAccount;
        mapping(address => uint256) whitelistEntries;
    }

    // Storage Slot: 71e0208316fc901686daf4f3337ab9e0c066ba9c3c2727e9209867af42765c4e
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-io.collections.v2.whitelist-manager.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../erc721/ERC721Lib.sol";
import "../minter/MinterLib.sol";
import "../whitelist-manager/WhitelistManagerLib.sol";
import "../payment-handler/PaymentHandlerLib.sol";
import "./ReserveManagerStorage.sol";

// TODO(kam): return number of reserved tokens

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library ReserveManagerInternal {

    event ReserveToken(address account, uint256 tokenId);

    function _initReserveManager() internal {
        // We always keep the token #0 reserved for the contract
        __s().reservedTokenIdCounter = 1;
    }

    function _getReservationSettings()
      internal view returns (bool, bool, uint256, uint256) {
        return (
            __s().reservationAllowed,
            __s().reservationAllowedWithoutWhitelisting,
            __s().reservationFeeWei,
            __s().reservePriceWeiPerToken
        );
    }

    function _setReservationAllowed(
        bool reservationAllowed,
        bool reservationAllowedWithoutWhitelisting,
        uint256 reservationFeeWei,
        uint256 reservePriceWeiPerToken
    ) internal {
        __s().reservationAllowed = reservationAllowed;
        __s().reservationAllowedWithoutWhitelisting = reservationAllowedWithoutWhitelisting;
        __s().reservationFeeWei = reservationFeeWei;
        __s().reservePriceWeiPerToken = reservePriceWeiPerToken;
    }

    function _reserveForAccount(
        address account,
        uint256 nrOfTokens,
        string memory paymentMethodName
    ) internal {
        require(__s().reservationAllowed, "RM:NA");
        if (!__s().reservationAllowedWithoutWhitelisting) {
            uint256 nrOfWhitelistedTokens = WhitelistManagerLib._getWhitelistEntry(account);
            uint256 nrOfReservedTokens = __s().nrOfReservedTokens[account];
            require(nrOfReservedTokens < nrOfWhitelistedTokens, "RM:EMAX");
            require(nrOfTokens <= (nrOfWhitelistedTokens - nrOfReservedTokens), "RM:EMAX2");
        }
        PaymentHandlerLib._handlePayment(
            1, __s().reservationFeeWei,
            nrOfTokens, __s().reservePriceWeiPerToken,
            paymentMethodName
        );
        _reserve(account, nrOfTokens);
    }

    // NOTE: This is always allowed
    function _reserveForAccounts(
        address[] memory accounts,
        uint256[] memory nrOfTokensArray
    ) internal {
        require(accounts.length == nrOfTokensArray.length, "RM:II");
        for (uint256 i = 0; i < accounts.length; i++) {
            _reserve(accounts[i], nrOfTokensArray[i]);
        }
    }

    function _reserve(
        address account,
        uint256 nrOfTokens
    ) private {
        require(account != address(this), "RM:IA");
        for (uint256 i = 0; i < nrOfTokens; i++) {
            bool found = false;
            while (__s().reservedTokenIdCounter < MinterLib._getTokenIdCounter()) {
                if (ERC721Lib._ownerOf(__s().reservedTokenIdCounter) == address(this)) {
                    found = true;
                    break;
                }
                __s().reservedTokenIdCounter += 1;
            }
            if (found) {
                ERC721Lib._transfer(address(this), account, __s().reservedTokenIdCounter);
                emit ReserveToken(account, __s().reservedTokenIdCounter);
            } else {
                MinterLib._justMintTo(account);
                emit ReserveToken(account, MinterLib._getTokenIdCounter() - 1);
            }
            __s().reservedTokenIdCounter += 1;
        }
        __s().nrOfReservedTokens[account] += nrOfTokens;
    }

    function __s() private pure returns (ReserveManagerStorage.Layout storage) {
        return ReserveManagerStorage.layout();
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./ERC721Internal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library ERC721Lib {

    function _setName(string memory name) internal {
        ERC721Internal._setName(name);
    }

    function _setSymbol(string memory symbol) internal {
        ERC721Internal._setSymbol(symbol);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return ERC721Internal._exists(tokenId);
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        return ERC721Internal._ownerOf(tokenId);
    }

    function _burn(uint256 tokenId) internal {
        ERC721Internal._burn(tokenId);
    }

    function _safeMint(address account, uint256 tokenId) internal {
        // TODO(kam): We don't have any safe mint in ERC721Internal
        ERC721Internal._mint(account, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        ERC721Internal._transfer(from, to, tokenId);
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./MinterInternal.sol";

library MinterLib {

    function _justMintTo(
        address owner
    ) internal returns (uint256) {
        return MinterInternal._justMintTo(owner);
    }

    function _getTokenIdCounter() internal view returns (uint256) {
        return MinterInternal._getTokenIdCounter();
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./WhitelistManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library WhitelistManagerLib {

    function _getWhitelistEntry(address account) internal view returns (uint256) {
        return WhitelistManagerInternal._getWhitelistEntry(account);
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library ReserveManagerStorage {

    struct Layout {
        bool reservationAllowed;
        bool reservationAllowedWithoutWhitelisting;
        uint256 reservationFeeWei;
        uint256 reservePriceWeiPerToken;
        uint256 reservedTokenIdCounter;
        mapping(address => uint256) nrOfReservedTokens;
        mapping(uint256 => uint256) extra;
    }

    // Storage Slot: 3aad2c382efb31a6bafea258059f50695b79a079bf36fa54252ddf5a4f956c74
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-io.collections.v2.reserve-manager.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../token-store/TokenStoreLib.sol";
import "../minter/MinterLib.sol";
import "../reserve-manager/ReserveManagerLib.sol";
import "./ERC721Storage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library ERC721Internal {

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function _setERC721Settings(
        string memory name_,
        string memory symbol_
    ) internal {
        _setName(name_);
        _setSymbol(symbol_);
        if (!_exists(0)) {
            MinterLib._justMintTo(address(this));
            ReserveManagerLib._initReserveManager();
        }
    }

    function _getName() internal view returns (string memory) {
        return __s().name;
    }

    function _setName(string memory name) internal {
        __s().name = name;
    }

    function _getSymbol() internal view returns (string memory) {
        return __s().symbol;
    }

    function _setSymbol(string memory symbol) internal {
        __s().symbol = symbol;
    }

    function _balanceOf(address owner) internal view returns (uint256) {
        require(owner != address(0), "ERC721I:ZA");
        return __s().balances[owner];
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        address owner = __s().owners[tokenId];
        require(owner != address(0), "ERC721I:NET");
        return owner;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return __s().owners[tokenId] != address(0);
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721I:MZA");
        require(!_exists(tokenId), "ERC721I:TAM");
        __s().balances[to] += 1;
        __s().owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        TokenStoreLib._addToRelatedTokens(to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner = _ownerOf(tokenId);
        // Clear approvals
        delete __s().tokenApprovals[tokenId];
        __s().balances[owner] -= 1;
        delete __s().owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(_ownerOf(tokenId) == from, "ERC721I:IO");
        require(to != address(0), "ERC721I:ZA");
        _unsafeTransfer(from, to, tokenId);
    }

    function _transferFromMe(
        address to,
        uint256 tokenId
    ) internal {
        require(_ownerOf(tokenId) == address(this), "ERC721I:IO");
        require(to != address(0), "ERC721I:ZA");
        _unsafeTransfer(address(this), to, tokenId);
    }

    function _unsafeTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        // Clear approvals from the previous owner
        delete __s().tokenApprovals[tokenId];
        __s().balances[from] -= 1;
        __s().balances[to] += 1;
        __s().owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
        TokenStoreLib._addToRelatedTokens(to, tokenId);
    }

    function _getApproved(uint256 tokenId) internal view returns (address) {
        require(_ownerOf(tokenId) != address(0), "ERC721I:NET");
        return __s().tokenApprovals[tokenId];
    }

    function _isApprovedForAll(address owner, address operator) internal view returns (bool) {
        return __s().operatorApprovals[owner][operator];
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view returns (bool) {
        address owner = _ownerOf(tokenId);
        return (
            spender == owner ||
            __s().operatorApprovals[owner][spender] ||
            __s().tokenApprovals[tokenId] == spender
        );
    }

    function _approve(address to, uint256 tokenId) internal {
        __s().tokenApprovals[tokenId] = to;
        emit Approval(_ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator, "ERC721I:ATC");
        __s().operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function __s() private pure returns (ERC721Storage.Layout storage) {
        return ERC721Storage.layout();
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./TokenStoreInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library TokenStoreLib {

    function _getTokenURI(uint256 tokenId)
      internal view returns (string memory) {
        return TokenStoreInternal._getTokenURI(tokenId);
    }

    function _setTokenURI(
        uint256 tokenId,
        string memory tokenURI_
    ) internal {
        TokenStoreInternal._setTokenURI(tokenId, tokenURI_);
    }

    function _setTokenData(uint256 tokenId, string memory data) internal {
        TokenStoreInternal._setTokenData(tokenId, data);
    }

    function _addToRelatedTokens(address account, uint256 tokenId) internal {
        TokenStoreInternal._addToRelatedTokens(account, tokenId);
    }

    function _deleteTokenInfo(
        uint256 tokenId
    ) internal {
        TokenStoreInternal._deleteTokenInfo(tokenId);
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./ReserveManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library ReserveManagerLib {

    function _initReserveManager() internal {
        ReserveManagerInternal._initReserveManager();
    }

    function _reserveForAccount(
        address account,
        uint256 nrOfTokens,
        string memory paymentMethodName
    ) internal {
        ReserveManagerInternal._reserveForAccount(
            account,
            nrOfTokens,
            paymentMethodName
        );
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library ERC721Storage {

    // Members are copied from:
    //   https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
    struct Layout {
        // Token name
        string name;
        // Token symbol
        string symbol;
        // Mapping from token ID to owner address
        mapping(uint256 => address) owners;
        // Mapping owner address to token count
        mapping(address => uint256) balances;
        // Mapping from token ID to approved address
        mapping(uint256 => address) tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    // Storage Slot: 388c7adf3256757f43699890c2802d6747128681a3873e143cc5c0e8e176c131
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-io.collections.v2.erc721.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../erc721/ERC721Lib.sol";
import "./TokenStoreStorage.sol";

// TODO(kam): add mapping from token to id

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library TokenStoreInternal {

    event TokenURIChange(uint256 tokenId, string tokenURI);
    event TokenDataChange(uint256 tokenId, string data);

    // TODO(kam): allow transfer of token id #0

    function _getTokenStoreSettings() internal view returns (string memory, string memory) {
        return (__s().baseTokenURI, __s().defaultTokenURI);
    }

    function _setTokenStoreSettings(
        string memory baseTokenURI,
        string memory defaultTokenURI
    ) internal {
        __s().baseTokenURI = baseTokenURI;
        __s().defaultTokenURI = defaultTokenURI;
    }

    function _getTokenURI(uint256 tokenId)
      internal view returns (string memory) {
        require(ERC721Lib._exists(tokenId), "TSI:NET");
        string memory vTokenURI = __s().tokenInfos[tokenId].uri;
        if (bytes(vTokenURI).length == 0) {
            return __s().defaultTokenURI;
        }
        if (bytes(__s().baseTokenURI).length == 0) {
            return vTokenURI;
        }
        return string(abi.encodePacked(__s().baseTokenURI, vTokenURI));
    }

    function _setTokenURI(
        uint256 tokenId,
        string memory tokenURI_
    ) internal {
        require(ERC721Lib._exists(tokenId), "TSI:NET");
        __s().tokenInfos[tokenId].uri = tokenURI_;
        emit TokenURIChange(tokenId, tokenURI_);
    }

    function _getTokenData(uint256 tokenId)
      internal view returns (string memory) {
        require(ERC721Lib._exists(tokenId), "TSI:NET");
        return __s().tokenInfos[tokenId].data;
    }

    function _setTokenData(
        uint256 tokenId,
        string memory data
    ) internal {
        require(ERC721Lib._exists(tokenId), "TSF:NET");
        __s().tokenInfos[tokenId].data = data;
        emit TokenDataChange(tokenId, data);
    }

    function _getRelatedTokens(address account) internal view returns (uint256[] memory) {
        return __s().relatedTokens[account];
    }

    function _addToRelatedTokens(address account, uint256 tokenId) internal {
        __s().relatedTokens[account].push(tokenId);
    }

    function _ownedTokens(address account)
      internal view returns (uint256[] memory) {
        uint256 length = 0;
        if (account != address(0)) {
            for (uint256 i = 0; i < _getRelatedTokens(account).length; i++) {
                uint256 tokenId = _getRelatedTokens(account)[i];
                if (ERC721Lib._exists(tokenId) && ERC721Lib._ownerOf(tokenId) == account) {
                    length += 1;
                }
            }
        }
        uint256[] memory tokens = new uint256[](length);
        if (account != address(0)) {
            uint256 index = 0;
            for (uint256 i = 0; i < _getRelatedTokens(account).length; i++) {
                uint256 tokenId = _getRelatedTokens(account)[i];
                if (ERC721Lib._exists(tokenId) && ERC721Lib._ownerOf(tokenId) == account) {
                    tokens[index] = tokenId;
                    index += 1;
                }
            }
        }
        return tokens;
    }

    function _deleteTokenInfo(
        uint256 tokenId
    ) internal {
        if (bytes(__s().tokenInfos[tokenId].uri).length != 0) {
            delete __s().tokenInfos[tokenId];
        }
    }

    function __s() private pure returns (TokenStoreStorage.Layout storage) {
        return TokenStoreStorage.layout();
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library TokenStoreStorage {

    struct TokenInfo {
        string uri;
        string data;
    }

    struct Layout {
        string baseTokenURI;
        string defaultTokenURI;
        mapping(uint256 => TokenInfo) tokenInfos;
        mapping(address => uint256[]) relatedTokens;
        mapping(uint256 => uint256) extra;
    }

    // Storage Slot: d48663c606213181d5dca65ab84ecc64807614baa9429ee057d88699409df195
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-io.collections.v2.token-store.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../token-store/TokenStoreLib.sol";
import "../royalty-manager/RoyaltyManagerLib.sol";
import "../payment-handler/PaymentHandlerLib.sol";
import "./MinterStorage.sol";

// TODO(kam): return number of minted tokens

library MinterInternal {

    event PreMint(uint256 nrOfTokens);

    function _getMintSettings()
      internal view returns (bool, bool, uint256, uint256, uint256) {
        return (
            __s().publicMinting,
            __s().directMintingAllowed,
            __s().mintFeeWei,
            __s().mintPriceWeiPerToken,
            __s().maxTokenId
        );
    }

    function _setMintSettings(
        bool publicMinting,
        bool directMintingAllowed,
        uint256 mintFeeWei,
        uint256 mintPriceWeiPerToken,
        uint256 maxTokenId
    ) internal {
        __s().publicMinting = publicMinting;
        __s().directMintingAllowed = directMintingAllowed;
        __s().mintFeeWei = mintFeeWei;
        __s().mintPriceWeiPerToken = mintPriceWeiPerToken;
        __s().maxTokenId = maxTokenId;
    }

    function _burn(uint256 tokenId) internal {
        ERC721Lib._burn(tokenId);
        TokenStoreLib._deleteTokenInfo(tokenId);
    }

    function _getTokenIdCounter() internal view returns (uint256) {
        return __s().tokenIdCounter;
    }

    function _justMintTo(
        address owner
    ) internal returns (uint256) {
        uint256 tokenId = __s().tokenIdCounter;
        require(__s().maxTokenId == 0 ||
                tokenId <= __s().maxTokenId, "M:MAX");
        __s().tokenIdCounter += 1;
        if (owner == address(this)) {
            ERC721Lib._safeMint(msg.sender, tokenId);
            ERC721Lib._transfer(msg.sender, address(this), tokenId);
        } else {
            ERC721Lib._safeMint(address(this), tokenId);
            ERC721Lib._transfer(address(this), owner, tokenId);
        }
        return tokenId;
    }

    function _preMint(uint256 nrOfTokens) internal {
        require(nrOfTokens > 0, "M:ZT");
        for (uint256 i = 0; i < nrOfTokens; i++) {
            _justMintTo(address(this));
        }
        emit PreMint(nrOfTokens);
    }

    function _mint(
        address owner,
        string[] memory uris,
        string[] memory datas,
        address[] memory royaltyWallets,
        uint256[] memory royaltyPercentages,
        bool handlePayment,
        string memory paymentMethodName
    ) internal {
        require(__s().directMintingAllowed, "M:DMNA");
        require(uris.length > 0, "M:NTM");
        require(datas.length == 0 ||
                uris.length == datas.length, "M:IL");
        require(royaltyWallets.length == 0 ||
                uris.length == royaltyWallets.length, "M:IL2");
        require(royaltyPercentages.length == 0 ||
                uris.length == royaltyPercentages.length, "M:IL3");
        if (handlePayment) {
            PaymentHandlerLib._handlePayment(
                1, __s().mintFeeWei,
                uris.length, __s().mintPriceWeiPerToken,
                paymentMethodName
            );
        }
        for (uint256 i = 0; i < uris.length; i++) {
            uint256 tokenId = _mintTo(owner, uris[i]);
            // Both royalty wallet and percentage must have sane values otherwise
            // the operator can always call other methods to set them.
            if (
                royaltyWallets.length > 0 &&
                royaltyPercentages.length > 0 &&
                royaltyWallets[i] != address(0) &&
                royaltyPercentages[i] > 0
            ) {
                RoyaltyManagerLib._setTokenRoyaltyInfo(tokenId, royaltyWallets[i], royaltyPercentages[i]);
            }
            if (datas.length > 0) {
                TokenStoreLib._setTokenData(tokenId, datas[i]);
            }
        }
    }

    // TODO(kam): This function can be moved to TokenStroe facet
    function _updateTokens(
        uint256[] memory tokenIds,
        string[] memory uris,
        string[] memory datas
    ) internal {
        require(tokenIds.length > 0, "M:NTU");
        require(tokenIds.length == uris.length, "M:IL");
        require(tokenIds.length == datas.length, "M:IL2");
        for (uint256 i = 0; i < uris.length; i++) {
            TokenStoreLib._setTokenURI(tokenIds[i], uris[i]);
            TokenStoreLib._setTokenData(tokenIds[i], datas[i]);
        }
    }

    function _mintTo(
        address owner,
        string memory uri
    ) private returns (uint256) {
        uint256 tokenId = _justMintTo(owner);
        TokenStoreLib._setTokenURI(tokenId, uri);
        return tokenId;
    }

    function __s() private pure returns (MinterStorage.Layout storage) {
        return MinterStorage.layout();
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./RoyaltyManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library RoyaltyManagerLib {

    function _setTokenRoyaltyInfo(
        uint256 tokenId,
        address royaltyWallet,
        uint256 royaltyPercentage
    ) internal {
        RoyaltyManagerInternal._setTokenRoyaltyInfo(
            tokenId,
            royaltyWallet,
            royaltyPercentage
        );
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library MinterStorage {

    struct Layout {
        uint256 tokenIdCounter;
        bool publicMinting;
        bool directMintingAllowed;
        uint256 mintFeeWei;
        uint256 mintPriceWeiPerToken;
        uint256 maxTokenId;
        mapping(uint256 => uint256) extra;
    }

    // Storage Slot: 8605f7831093df2f7c7aac3d3c42e7477f4c86459f3bd04a98f554d64335de2a
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-io.collections.v2.minter.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../erc721/ERC721Lib.sol";
import "./RoyaltyManagerStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library RoyaltyManagerInternal {

    event TokenRoyaltyInfoChanged(uint256 tokenId, address royaltyWallet, uint256 royaltyPercentage);
    event TokenRoyaltyExempt(uint256 tokenId, bool exempt);

    function _getDefaultRoyaltySettings() internal view returns (address, uint256) {
        return (__s().defaultRoyaltyWallet, __s().defaultRoyaltyPercentage);
    }

    // Either set address to zero or set percentage to zero to disable
    // default royalties. Still, royalties set per token work.
    function _setDefaultRoyaltySettings(
        address newDefaultRoyaltyWallet,
        uint256 newDefaultRoyaltyPercentage
    ) internal {
        __s().defaultRoyaltyWallet = newDefaultRoyaltyWallet;
        require(
            newDefaultRoyaltyPercentage >= 0 &&
            newDefaultRoyaltyPercentage <= 100,
            "ROMI:WP"
        );
        __s().defaultRoyaltyPercentage = newDefaultRoyaltyPercentage;
    }

    function _getTokenRoyaltyInfo(uint256 tokenId)
      internal view returns (address, uint256, bool) {
        require(ERC721Lib._exists(tokenId), "ROMI:NET");
        return (
            __s().tokenRoyalties[tokenId].royaltyWallet,
            __s().tokenRoyalties[tokenId].royaltyPercentage,
            __s().tokenRoyalties[tokenId].exempt
        );
    }

    function _setTokenRoyaltyInfo(
        uint256 tokenId,
        address royaltyWallet,
        uint256 royaltyPercentage
    ) internal {
        require(ERC721Lib._exists(tokenId), "ROMI:NET");
        require(royaltyPercentage >= 0 && royaltyPercentage <= 100, "ROMI:WP");
        __s().tokenRoyalties[tokenId].royaltyWallet = royaltyWallet;
        __s().tokenRoyalties[tokenId].royaltyPercentage = royaltyPercentage;
        __s().tokenRoyalties[tokenId].exempt = false;
        emit TokenRoyaltyInfoChanged(tokenId, royaltyWallet, royaltyPercentage);
    }

    function _exemptTokenRoyalty(uint256 tokenId, bool exempt) internal {
        require(ERC721Lib._exists(tokenId), "ROMI:NET");
        __s().tokenRoyalties[tokenId].exempt = exempt;
        emit TokenRoyaltyExempt(tokenId, exempt);
    }

    function _getRoyaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) internal view returns (address, uint256) {
        require(ERC721Lib._exists(tokenId), "ROMI:NET");
        RoyaltyManagerStorage.TokenRoyaltyInfo memory tokenRoyaltyInfo = __s().tokenRoyalties[tokenId];
        if (tokenRoyaltyInfo.exempt) {
            return (address(0), 0);
        }
        address royaltyWallet = tokenRoyaltyInfo.royaltyWallet;
        uint256 royaltyPercentage = tokenRoyaltyInfo.royaltyPercentage;
        if (royaltyWallet == address(0) || royaltyPercentage == 0) {
            royaltyWallet = __s().defaultRoyaltyWallet;
            royaltyPercentage = __s().defaultRoyaltyPercentage;
        }
        if (royaltyWallet == address(0) || royaltyPercentage == 0) {
            return (address(0), 0);
        }
        uint256 royalty = (salePrice * royaltyPercentage) / 100;
        return (royaltyWallet, royalty);
    }

    function __s() private pure returns (RoyaltyManagerStorage.Layout storage) {
        return RoyaltyManagerStorage.layout();
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library RoyaltyManagerStorage {

    struct TokenRoyaltyInfo {
        address royaltyWallet;
        uint256 royaltyPercentage;
        bool exempt;
    }

    struct Layout {
        address defaultRoyaltyWallet;
        uint256 defaultRoyaltyPercentage;
        mapping(uint256 => TokenRoyaltyInfo) tokenRoyalties;
        mapping(uint256 => uint256) extra;
    }

    // Storage Slot: cfc77a8f0fe178bdc896b1d39fdc8403e4b8e4f59b0dc5da020d715bf2b8e0cd
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-io.collections.v2.royalty-manager.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../../arteq-tech/contracts/diamond/IDiamondFacet.sol";
import "../../../arteq-tech/contracts/security/role-manager/RoleManagerLib.sol";
import "../arteQCollectionV2Config.sol";
import "./ReserveManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract ReserveManagerFacet is IDiamondFacet {

    modifier onlyAdmin() {
        RoleManagerLib._checkRole(arteQCollectionV2Config.ROLE_ADMIN);
        _;
    }

    modifier onlyTokenManager() {
        RoleManagerLib._checkRole(arteQCollectionV2Config.ROLE_TOKEN_MANAGER);
        _;
    }

    function getFacetName()
      external pure override returns (string memory) {
        return "reserve-manager";
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getFacetVersion()
      external pure override returns (string memory) {
        return "0.0.1";
    }

    function getFacetPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](5);
        pi[0] = "initReserveManager()";
        pi[1] = "getReservationSettings();";
        pi[2] = "setReservationAllowed(bool,bool,uint256,uint256)";
        pi[3] = "reserveForMe(uint256,string)";
        pi[4] = "reserveForAccounts(address[],uint256[])";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId;
    }

    // TODO(kam): remove this function.
    function initReserveManager() external onlyAdmin {
        ReserveManagerInternal._initReserveManager();
    }

    function getReservationSettings()
      external view returns (bool, bool, uint256, uint256) {
        return ReserveManagerInternal._getReservationSettings();
    }

    // TODO(kam): correct the function name.
    function setReservationAllowed(
        bool reservationAllowed,
        bool reservationAllowedWithoutWhitelisting,
        uint256 reservationFeeWei,
        uint256 reservePriceWeiPerToken
    ) external onlyAdmin {
        ReserveManagerInternal._setReservationAllowed(
            reservationAllowed,
            reservationAllowedWithoutWhitelisting,
            reservationFeeWei,
            reservePriceWeiPerToken
        );
    }

    function reserveForMe(
        uint256 nrOfTokens,
        string memory paymentMethodName
    ) external payable {
        ReserveManagerInternal._reserveForAccount(
            msg.sender,
            nrOfTokens,
            paymentMethodName
        );
    }

    // This is always allowed
    function reserveForAccounts(
        address[] memory accounts,
        uint256[] memory nrOfTokensArray
    ) external onlyTokenManager {
        ReserveManagerInternal._reserveForAccounts(
            accounts,
            nrOfTokensArray
        );
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "../../../arteq-tech/contracts/diamond/IDiamondFacet.sol";
import "../../../arteq-tech/contracts/security/role-manager/RoleManagerLib.sol";
import "../arteQCollectionV2Config.sol";
import "./TokenStoreInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TokenStoreFacet is IDiamondFacet {

    modifier onlyAdmin() {
        RoleManagerLib._checkRole(arteQCollectionV2Config.ROLE_ADMIN);
        _;
    }

    modifier onlyTokenManager() {
        RoleManagerLib._checkRole(arteQCollectionV2Config.ROLE_TOKEN_MANAGER);
        _;
    }

    function getFacetName()
      external pure override returns (string memory) {
        return "token-store";
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getFacetVersion()
      external pure override returns (string memory) {
        return "0.0.1";
    }

    function getFacetPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](7);
        pi[0] = "getTokenStoreSettings()";
        pi[1] = "setTokenStoreSettings(string,string)";
        pi[2] = "getTokenData(uint256)";
        pi[3] = "setTokenData(uint256,string)";
        pi[4] = "getTokenURI(uint256)";
        pi[5] = "setTokenURI(uint256,string)";
        pi[6] = "ownedTokens(address)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId;
    }

    function getTokenStoreSettings()
      external view returns (string memory, string memory) {
        return TokenStoreInternal._getTokenStoreSettings();
    }

    function setTokenStoreSettings(
        string memory baseTokenURI,
        string memory defaultTokenURI
    ) external onlyAdmin {
        TokenStoreInternal._setTokenStoreSettings(
            baseTokenURI,
            defaultTokenURI
        );
    }

    function getTokenData(uint256 tokenId)
      external view returns (string memory) {
        return TokenStoreInternal._getTokenData(tokenId);
    }

    function setTokenData(
        uint256 tokenId,
        string memory data
    ) external onlyTokenManager {
        TokenStoreInternal._setTokenData(tokenId, data);
    }

    // TODO(kam): allow transfer of token id #0

    function getTokenURI(uint256 tokenId)
      public view returns (string memory) {
        return TokenStoreInternal._getTokenURI(tokenId);
    }

    function setTokenURI(
        uint256 tokenId,
        string memory tokenURI
    ) external onlyTokenManager {
        return TokenStoreInternal._setTokenURI(tokenId, tokenURI);
    }

    function ownedTokens(address account)
      external view returns (uint256[] memory tokens) {
        return TokenStoreInternal._ownedTokens(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "../../../arteq-tech/contracts/diamond/IDiamondFacet.sol";
import "../../../arteq-tech/contracts/security/role-manager/RoleManagerLib.sol";
import "../arteQCollectionV2Config.sol";
import "./RoyaltyManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract RoyaltyManagerFacet is IDiamondFacet {

    modifier onlyAdmin() {
        RoleManagerLib._checkRole(arteQCollectionV2Config.ROLE_ADMIN);
        _;
    }

    modifier onlyTokenManager() {
        RoleManagerLib._checkRole(arteQCollectionV2Config.ROLE_TOKEN_MANAGER);
        _;
    }

    function getFacetName()
      external pure override returns (string memory) {
        return "royalty-manager";
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getFacetVersion()
      external pure override returns (string memory) {
        return "0.0.1";
    }

    function getFacetPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](6);
        pi[0] = "getDefaultRoyaltySettings()";
        pi[1] = "setDefaultRoyaltySettings(address,uint256)";
        pi[2] = "getTokenRoyaltyInfo(uint256)";
        pi[3] = "setTokenRoyaltyInfo(uint256,address,uint256)";
        pi[4] = "exemptTokenRoyalty(uint256,bool)";
        pi[5] = "royaltyInfo(uint256,uint256)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId ||
               interfaceId == type(IERC2981).interfaceId;
    }

    function getDefaultRoyaltySettings() external view returns (address, uint256) {
        return RoyaltyManagerInternal._getDefaultRoyaltySettings();
    }

    // Either set address to zero or set percentage to zero to disable
    // default royalties. Still, royalties set per token work.
    function setDefaultRoyaltySettings(
        address newDefaultRoyaltyWallet,
        uint256 newDefaultRoyaltyPercentage
    ) external onlyAdmin {
        RoyaltyManagerInternal._setDefaultRoyaltySettings(
            newDefaultRoyaltyWallet,
            newDefaultRoyaltyPercentage
        );
    }

    function getTokenRoyaltyInfo(uint256 tokenId)
      external view returns (address, uint256, bool) {
        return RoyaltyManagerInternal._getTokenRoyaltyInfo(tokenId);
    }

    function setTokenRoyaltyInfo(
        uint256 tokenId,
        address royaltyWallet,
        uint256 royaltyPercentage
    ) external onlyTokenManager {
        RoyaltyManagerInternal._setTokenRoyaltyInfo(
            tokenId,
            royaltyWallet,
            royaltyPercentage
        );
    }

    function exemptTokenRoyalty(uint256 tokenId, bool exempt) external onlyTokenManager {
        RoyaltyManagerInternal._exemptTokenRoyalty(tokenId, exempt);
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address, uint256) {
        return RoyaltyManagerInternal._getRoyaltyInfo(tokenId, salePrice);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../../arteq-tech/contracts/diamond/IDiamondFacet.sol";
import "../../../arteq-tech/contracts/security/role-manager/RoleManagerLib.sol";
import "../arteQCollectionV2Config.sol";
import "./MinterInternal.sol";

contract MinterFacet is IDiamondFacet {

    modifier onlyAdmin() {
        RoleManagerLib._checkRole(arteQCollectionV2Config.ROLE_ADMIN);
        _;
    }

    modifier onlyTokenManager() {
        RoleManagerLib._checkRole(arteQCollectionV2Config.ROLE_TOKEN_MANAGER);
        _;
    }

    function getFacetName()
      external pure override returns (string memory) {
        return "minter";
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getFacetVersion()
      external pure override returns (string memory) {
        return "0.0.1";
    }

    function getFacetPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](7);
        pi[0] = "getMintSettings()";
        pi[1] = "setMintSettings(bool,bool,uint256,uint256,uint256)";
        pi[2] = "preMint(uint256)";
        pi[3] = "mint(string[],string[],address[],uint256[],string)";
        pi[4] = "mintTo(address,string[],string[],address[],uint256[])";
        pi[5] = "updateTokens(uint256[],string[],string[])";
        pi[6] = "burn(uint256)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId;
    }

    function getMintSettings() external view returns (bool, bool, uint256, uint256, uint256) {
        return MinterInternal._getMintSettings();
    }

    function setMintSettings(
        bool publicMinting,
        bool directMintingAllowed,
        uint256 mintFeeWei,
        uint256 mintPriceWeiPerToken,
        uint256 maxTokenId
    ) external onlyAdmin {
        MinterInternal._setMintSettings(
            publicMinting,
            directMintingAllowed,
            mintFeeWei,
            mintPriceWeiPerToken,
            maxTokenId
        );
    }

    function preMint(uint256 nrOfTokens) external onlyTokenManager {
        MinterInternal._preMint(nrOfTokens);
    }

    function mint(
        string[] memory uris,
        string[] memory datas,
        address[] memory royaltyWallets,
        uint256[] memory royaltyPercentages,
        string memory paymentMethodName
    ) external payable {
        (bool publicMinting,,,,)  = MinterInternal._getMintSettings();
        require(publicMinting, "M:NPM");
        MinterInternal._mint(
            msg.sender,
            uris,
            datas,
            royaltyWallets,
            royaltyPercentages,
            true,
            paymentMethodName
        );
    }

    function mintTo(
        address owner,
        string[] memory uris,
        string[] memory datas,
        address[] memory royaltyWallets,
        uint256[] memory royaltyPercentages
    ) external onlyTokenManager {
        MinterInternal._mint(
            owner,
            uris,
            datas,
            royaltyWallets,
            royaltyPercentages,
            false,
            ""
        );
    }

    function updateTokens(
        uint256[] memory tokenIds,
        string[] memory uris,
        string[] memory datas
    ) external onlyTokenManager {
        MinterInternal._updateTokens(
            tokenIds,
            uris,
            datas
        );
    }

    function burn(uint256 tokenId) external payable onlyTokenManager {
        MinterInternal._burn(tokenId);
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../token-store/TokenStoreLib.sol";
import "../royalty-manager/RoyaltyManagerLib.sol";
import "../reserve-manager/ReserveManagerLib.sol";
import "../payment-handler/PaymentHandlerLib.sol";
import "./CrossmintStorage.sol";

library CrossmintInternal {

    function _getCrossmintSettings() internal view returns (bool, address) {
        return (__s().crossmintEnabled, __s().crossmintTrustedAddress);
    }

    function _setCrossmintSettings(
        bool crossmintEnabled,
        address crossmintTrustedAddress
    ) internal {
        __s().crossmintEnabled = crossmintEnabled;
        __s().crossmintTrustedAddress = crossmintTrustedAddress;
    }

    function _crossmintReserve(address to, uint256 nrOfTokens) internal {
        // TODO(kam): check for enabled field
        require(msg.sender == __s().crossmintTrustedAddress, "C:IC");
        ReserveManagerLib._reserveForAccount(to, nrOfTokens, "WEI");
    }

    function __s() private pure returns (CrossmintStorage.Layout storage) {
        return CrossmintStorage.layout();
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library CrossmintStorage {

    struct Layout {
        bool crossmintEnabled;
        address crossmintTrustedAddress;
        mapping(uint256 => uint256) extra;
    }

    // Storage Slot: dc6802a7eb06f1e822e55f39c860c5b72181b9d10a4e7b7543bfe4856467c17a
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-io.collections.v2.crossmint.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "../../../arteq-tech/contracts/diamond/IDiamondFacet.sol";
import "../../../arteq-tech/contracts/security/role-manager/RoleManagerLib.sol";
import "../arteQCollectionV2Config.sol";
import "../token-store/TokenStoreLib.sol";
import "./ERC721Internal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract ERC721Facet is IDiamondFacet {

    using Address for address;

    modifier onlyAdmin() {
        RoleManagerLib._checkRole(arteQCollectionV2Config.ROLE_ADMIN);
        _;
    }

    function getFacetName()
      external pure override returns (string memory) {
        return "payment-handler";
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getFacetVersion()
      external pure override returns (string memory) {
        return "0.0.1";
    }

    function getFacetPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](16);
        pi[0] = "setERC721Settings(string,string)";
        pi[1] = "balanceOf(address)";
        pi[2] = "ownerOf(uint256)";
        pi[3] = "name()";
        pi[4] = "setName(string)";
        pi[5] = "symbol()";
        pi[6] = "setSymbol(string)";
        pi[7] = "tokenURI(uint256)";
        pi[8] = "approve(address,uint256)";
        pi[9] = "getApproved(uint256)";
        pi[10] = "setApprovalForAll(address,bool)";
        pi[11] = "isApprovedForAll(address,address)";
        pi[12] = "transferFromMe(address,uint256)";
        pi[13] = "transferFrom(address,address,uint256)";
        pi[14] = "safeTransferFrom(address,address,uint256)";
        pi[15] = "safeTransferFrom(address,address,uint256,bytes)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return
            interfaceId == type(IDiamondFacet).interfaceId ||
            interfaceId == type(IERC721).interfaceId;
    }

    function setERC721Settings(
        string memory name_,
        string memory symbol_
    ) external onlyAdmin {
        ERC721Internal._setERC721Settings(name_, symbol_);
    }

    // Most of the code is copied from:
    //   https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol

    function balanceOf(address owner) external view returns (uint256) {
        return ERC721Internal._balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return ERC721Internal._ownerOf(tokenId);
    }

    function name() external view returns (string memory) {
        return ERC721Internal._getName();
    }

    function setName(string memory name_) external onlyAdmin {
        ERC721Internal._setName(name_);
    }

    function symbol() external view returns (string memory) {
        return ERC721Internal._getSymbol();
    }

    function setSymbol(string memory symbol_) external onlyAdmin {
        ERC721Internal._setSymbol(symbol_);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(ERC721Internal._exists(tokenId), "ERC721F:NET");
        return TokenStoreLib._getTokenURI(tokenId);
    }

    function approve(address to, uint256 tokenId) external {
        address owner = ERC721Internal._ownerOf(tokenId);
        require(to != owner, "ERC721F:ATC");
        require(
            msg.sender == owner || ERC721Internal._isApprovedForAll(owner, msg.sender),
            "ERC721F:NO"
        );
        ERC721Internal._approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        return ERC721Internal._getApproved(tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        ERC721Internal._setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return ERC721Internal._isApprovedForAll(owner, operator);
    }

    function transferFromMe(
        address to,
        uint256 tokenId
    ) external onlyAdmin {
        ERC721Internal._transferFromMe(to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(ERC721Internal._isApprovedOrOwner(msg.sender, tokenId),
                "ERC721F:NO");
        ERC721Internal._transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public {
        require(ERC721Internal._isApprovedOrOwner(msg.sender, tokenId),
                "ERC721F:NO");
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        ERC721Internal._transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721F:BADTO");
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to)
              .onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721F:BADTO");
                } else {
                    /* solhint-disable no-inline-assembly */
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                    /* solhint-enable no-inline-assembly */
                }
            }
        } else {
            return true;
        }
    }
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

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

 /**
  * @author Modified by Kam Amini <[email protected]> <[email protected]>
  *
  * @notice Use at your own risk
  *
  * Note: The original contract has been modified to cover the needs as
  *       part of artèQ Investment Fund ecosystem
  *
  * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
  * the Metadata extension, but not including the Enumerable extension, which is available separately as
  * {ERC721Enumerable}.
  */

/* solhint-disable reason-string */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received},
     *   which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received},
     *   which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(address(0), to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address from, address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(from, to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /* solhint-disable no-inline-assembly */
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    /* solhint-disable no-empty-blocks */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721Receiver.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0
// Based on OpenZeppelin Contracts v4.3.2 (token/ERC1155/ERC1155.sol)

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

 /**
  * @author Modified by Kam Amini <[email protected]> <[email protected]>
  *
  * @notice Use at your own risk
  *
  * Note: The original contract has been modified to cover the needs as
  *       part of artèQ Investment Fund ecosystem
  */

/* solhint-disable reason-string */
abstract contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    // arteQ: we made this field public in order to distribute profits in the token contract
    mapping(uint256 => mapping(address => uint256)) public _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev See {_setURI}.
     */
    /* solhint-disable no-empty-blocks */
    constructor() {
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }


    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved "
        );
        _safeTransferFrom(_msgSender(), from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address /* from */,
        address /* to */,
        uint256[] memory /* ids */,
        uint256[] memory /* amounts */,
        bytes memory /* data */
    ) public virtual override {
        revert("ERC1155: not implemented");
    }

    function _safeTransferFrom(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        // arteQ: we have to read the returned amount again as it can change in the function
        uint256[] memory amounts = _asArray(amount, 2);
        _beforeTokenTransfer(operator, from, to, id, amounts, data);
        uint256 fromAmount = amounts[0];
        uint256 toAmount = amounts[1];

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= fromAmount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - fromAmount;
        }
        _balances[id][to] += toAmount;

        emit TransferSingle(operator, from, to, id, amount);
    }

    function _initialMint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, id, _asArray(amount, 2), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _beforeTokenTransfer(
        address /* operator */,
        address /* from */,
        address /* to */,
        uint256 /* id */,
        uint256[] memory /* amounts */,
        bytes memory /* data */
    ) internal virtual {}

    function _asArray(uint256 element, uint len) private pure returns (uint256[] memory) {
        if (len == 1) {
            uint256[] memory array = new uint256[](1);
            array[0] = element;
            return array;
        } else if (len == 2) {
            uint256[] memory array = new uint256[](2);
            array[0] = element;
            array[1] = element;
            return array;
        }
        revert("ERC1155: length must be 1 or 2");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IarteQTokens.sol";
import "./IarteQTaskFinalizer.sol";

/// @author Kam Amini <[email protected]> <[email protected]>
///
/// @title ARTEQ token; the main asset in artèQ Investment Fund ecosystem
///
/// @notice Use at your own risk
contract ARTEQ is Context, ERC165, IERC20Metadata {

    /* solhint-disable const-name-snakecase */
    uint256 public constant ARTEQTokenId = 1;

    address private _arteQTokensContract;

    address private _adminContract;

    modifier adminApprovalRequired(uint256 adminTaskId) {
        _;
        // This must succeed otherwise the tx gets reverted
        IarteQTaskFinalizer(_adminContract).finalizeTask(msg.sender, adminTaskId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IERC20Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    constructor(address arteQTokensContract, address adminContract) {
        _arteQTokensContract = arteQTokensContract;
        _adminContract = adminContract;
    }

    function name() external view virtual override returns (string memory) {
        return "arteQ Investment Fund Token";
    }

    function symbol() external view virtual override returns (string memory) {
        return "ARTEQ";
    }

    function decimals() external view virtual override returns (uint8) {
        return 0;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return IarteQTokens(_arteQTokensContract).compatTotalSupply(_msgSender(), ARTEQTokenId);
    }

    function balanceOf(address account) external view virtual override returns (uint256) {
        return IarteQTokens(_arteQTokensContract).compatBalanceOf(_msgSender(), account, ARTEQTokenId);
    }

    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        IarteQTokens(_arteQTokensContract).compatTransfer(_msgSender(), recipient, ARTEQTokenId, amount);
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        IarteQTokens(_arteQTokensContract).compatTransferFrom(_msgSender(), sender, recipient, ARTEQTokenId, amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return IarteQTokens(_arteQTokensContract).compatAllowance(_msgSender(), owner, spender);
    }

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        IarteQTokens(_arteQTokensContract).compatApprove(_msgSender(), spender, amount);
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    // If this contract gets a balance in some ERC20 contract after it's finished, then we can rescue it.
    function rescueTokens(uint256 adminTaskId, IERC20 foreignToken, address to)
      external adminApprovalRequired(adminTaskId) {
        foreignToken.transfer(to, foreignToken.balanceOf(address(this)));
    }

    // If this contract gets a balance in some ERC721 contract after it's finished, then we can rescue it.
    function approveNFTRescue(uint256 adminTaskId, IERC721 foreignNFT, address to)
      external adminApprovalRequired(adminTaskId) {
        foreignNFT.setApprovalForAll(to, true);
    }

    receive() external payable {
        revert("ARTEQ: cannot accept ether");
    }

    fallback() external payable {
        revert("ARTEQ: cannot accept ether");
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]> <[email protected]>
///
/// @title An interface which allows ERC-20 tokens to interact with the
/// main ERC-1155 contract
///
/// @notice Use at your own risk
interface IarteQTokens {
    function compatBalanceOf(address origin, address account, uint256 tokenId) external view returns (uint256);
    function compatTotalSupply(address origin, uint256 tokenId) external view returns (uint256);
    function compatTransfer(address origin, address to, uint256 tokenId, uint256 amount) external;
    function compatTransferFrom(address origin, address from, address to, uint256 tokenId, uint256 amount) external;
    function compatAllowance(address origin, address account, address operator) external view returns (uint256);
    function compatApprove(address origin, address operator, uint256 amount) external;
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]> <[email protected]>
///
/// @title The interface for finalizing tasks. Mainly used by artèQ contracts to
///
/// perform administrative tasks in conjuction with admin contract.
interface IarteQTaskFinalizer {

    event TaskFinalized(address finalizer, address origin, uint256 taskId);

    function finalizeTask(address origin, uint256 taskId) external;
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ERC1155Supply.sol";
import "./IarteQTokens.sol";
import "./IarteQTaskFinalizer.sol";

/// @author Kam Amini <[email protected]> <[email protected]>
///
/// @title This contract keeps track of the tokens used in artèQ Investment
/// Fund ecosystem. It also contains the logic used for profit distribution.
///
/// @notice Use at your own risk

/* solhint-disable contract-name-camelcase */
/* solhint-disable not-rely-on-time */
/* solhint-disable reason-string */
contract arteQTokens is ERC1155Supply, IarteQTokens {

    /// The main artèQ token
    uint256 public constant ARTEQ = 1;

    /// The governance token of artèQ Investment Fund
    /* solhint-disable const-name-snakecase */
    uint256 public constant gARTEQ = 2;

    // The mapping from token IDs to their respective Metadata URIs
    mapping (uint256 => string) private _tokenMetadataURIs;

    // The admin smart contract
    address private _adminContract;

    // Treasury account responsible for asset-token ratio appreciation.
    address private _treasuryAccount;

    // This can be a Uniswap V1/V2 exchange (pool) account created for ARTEQ token,
    // or any other exchange account. Treasury contract uses these pools to buy
    // back or sell tokens. In case of buy backs, the tokens must be delivered to
    // treasury account from these contracts. Otherwise, the profit distribution
    // logic doesn't get triggered.
    address private _exchange1Account;
    address private _exchange2Account;
    address private _exchange3Account;
    address private _exchange4Account;
    address private _exchange5Account;

    // All the profits accumulated since the deployment of the contract. This is
    // used as a marker to facilitate the caluclation of every eligible account's
    // share from the profits in a given time range.
    uint256 private _allTimeProfit;

    // The actual number of profit tokens transferred to accounts
    uint256 private _profitTokensTransferredToAccounts;

    // The percentage of the bought back tokens which is considered as profit for gARTEQ owners
    // Default value is 20% and only admin contract can change that.
    uint private _profitPercentage;

    // In order to caluclate the share of each elgiible account from the profits,
    // and more importantly, in order to do this efficiently (less gas usage),
    // we need this mapping to remember the "all time profit" when an account
    // is modified (receives tokens or sends tokens).
    mapping (address => uint256) private _profitMarkers;

    // A timestamp indicating when the ramp-up phase gets expired.
    uint256 private _rampUpPhaseExpireTimestamp;

    // Indicates until when the address cannot send any tokens
    mapping (address => uint256) private _lockedUntilTimestamps;

    /// Emitted when the admin contract is changed.
    event AdminContractChanged(address newContract);

    /// Emitted when the treasury account is changed.
    event TreasuryAccountChanged(address newAccount);

    /// Emitted when the exchange account is changed.
    event Exchange1AccountChanged(address newAccount);
    event Exchange2AccountChanged(address newAccount);
    event Exchange3AccountChanged(address newAccount);
    event Exchange4AccountChanged(address newAccount);
    event Exchange5AccountChanged(address newAccount);

    /// Emitted when the profit percentage is changed.
    event ProfitPercentageChanged(uint newPercentage);

    /// Emitted when a token distribution occurs during the ramp-up phase
    event RampUpPhaseTokensDistributed(address to, uint256 amount, uint256 lockedUntilTimestamp);

    /// Emitted when some buy back tokens are received by the treasury account.
    event ProfitTokensCollected(uint256 amount);

    /// Emitted when a share holder receives its tokens from the buy back profits.
    event ProfitTokensDistributed(address to, uint256 amount);

    // Emitted when profits are caluclated because of a manual buy back event
    event ManualBuyBackWithdrawalFromTreasury(uint256 amount);

    modifier adminApprovalRequired(uint256 adminTaskId) {
        _;
        // This must succeed otherwise the tx gets reverted
        IarteQTaskFinalizer(_adminContract).finalizeTask(msg.sender, adminTaskId);
    }

    modifier validToken(uint256 tokenId) {
        require(tokenId == ARTEQ || tokenId == gARTEQ, "arteQTokens: non-existing token");
        _;
    }

    modifier onlyRampUpPhase() {
        require(block.timestamp < _rampUpPhaseExpireTimestamp, "arteQTokens: ramp up phase is finished");
        _;
    }

    constructor(address adminContract) {
        _adminContract = adminContract;

        /// Must be set later
        _treasuryAccount = address(0);

        /// Must be set later
        _exchange1Account = address(0);
        _exchange2Account = address(0);
        _exchange3Account = address(0);
        _exchange4Account = address(0);
        _exchange5Account = address(0);

        string memory arteQURI = "ipfs://QmfBtH8BSztaYn3QFnz2qvu2ehZgy8AZsNMJDkgr3pdqT8";
        string memory gArteQURI = "ipfs://QmRAXmU9AymDgtphh37hqx5R2QXSS2ngchQRDFtg6XSD7w";
        _tokenMetadataURIs[ARTEQ] = arteQURI;
        emit URI(arteQURI, ARTEQ);
        _tokenMetadataURIs[gARTEQ] = gArteQURI;
        emit URI(gArteQURI, gARTEQ);

        /// 10 billion
        _initialMint(_adminContract, ARTEQ, 10 ** 10, "");
        /// 1 million
        _initialMint(_adminContract, gARTEQ, 10 ** 6, "");

        /// Obviously, no profit at the time of deployment
        _allTimeProfit = 0;

        _profitPercentage = 20;

        /// Tuesday, February 1, 2022 12:00:00 AM
        _rampUpPhaseExpireTimestamp = 1643673600;
    }

    /// See {ERC1155-uri}
    function uri(uint256 tokenId) external view virtual override validToken(tokenId) returns (string memory) {
        return _tokenMetadataURIs[tokenId];
    }

    function setURI(
        uint256 adminTaskId,
        uint256 tokenId,
        string memory newUri
    ) external adminApprovalRequired(adminTaskId) validToken(tokenId) {
        _tokenMetadataURIs[tokenId] = newUri;
        emit URI(newUri, tokenId);
    }

    /// Returns the set treasury account
    /// @return The set treasury account
    function getTreasuryAccount() external view returns (address) {
        return _treasuryAccount;
    }

    /// Sets a new treasury account. Just after deployment, treasury account is set to zero address but once
    /// set to a non-zero address, it cannot be changed back to zero address again.
    ///
    /// @param adminTaskId the task which must have been approved by multiple admins
    /// @param newAccount new treasury address
    function setTreasuryAccount(uint256 adminTaskId, address newAccount) external adminApprovalRequired(adminTaskId) {
        require(newAccount != address(0), "arteQTokens: zero address for treasury account");
        _treasuryAccount = newAccount;
        emit TreasuryAccountChanged(newAccount);
    }

    /// Returns the 1st exchange account
    /// @return The 1st exchnage account
    function getExchange1Account() external view returns (address) {
        return _exchange1Account;
    }

    /// Returns the 2nd exchange account
    /// @return The 2nd exchnage account
    function getExchange2Account() external view returns (address) {
        return _exchange2Account;
    }

    /// Returns the 3rd exchange account
    /// @return The 3rd exchnage account
    function getExchange3Account() external view returns (address) {
        return _exchange3Account;
    }

    /// Returns the 4th exchange account
    /// @return The 4th exchnage account
    function getExchange4Account() external view returns (address) {
        return _exchange4Account;
    }

    /// Returns the 5th exchange account
    /// @return The 5th exchnage account
    function getExchange5Account() external view returns (address) {
        return _exchange5Account;
    }

    /// Sets a new exchange account. Just after deployment, exchange account is set to zero address but once
    /// set to a non-zero address, it cannot be changed back to zero address again.
    ///
    /// @param adminTaskId the task which must have been approved by multiple admins
    /// @param newAccount new exchange address
    function setExchange1Account(uint256 adminTaskId, address newAccount) external adminApprovalRequired(adminTaskId) {
        require(newAccount != address(0), "arteQTokens: zero address for exchange account");
        _exchange1Account = newAccount;
        emit Exchange1AccountChanged(newAccount);
    }

    /// Sets a new exchange account. Just after deployment, exchange account is set to zero address but once
    /// set to a non-zero address, it cannot be changed back to zero address again.
    ///
    /// @param adminTaskId the task which must have been approved by multiple admins
    /// @param newAccount new exchange address
    function setExchange2Account(uint256 adminTaskId, address newAccount) external adminApprovalRequired(adminTaskId) {
        require(newAccount != address(0), "arteQTokens: zero address for exchange account");
        _exchange2Account = newAccount;
        emit Exchange2AccountChanged(newAccount);
    }

    /// Sets a new exchange account. Just after deployment, exchange account is set to zero address but once
    /// set to a non-zero address, it cannot be changed back to zero address again.
    ///
    /// @param adminTaskId the task which must have been approved by multiple admins
    /// @param newAccount new exchange address
    function setExchange3Account(uint256 adminTaskId, address newAccount) external adminApprovalRequired(adminTaskId) {
        require(newAccount != address(0), "arteQTokens: zero address for exchange account");
        _exchange3Account = newAccount;
        emit Exchange3AccountChanged(newAccount);
    }

    /// Sets a new exchange account. Just after deployment, exchange account is set to zero address but once
    /// set to a non-zero address, it cannot be changed back to zero address again.
    ///
    /// @param adminTaskId the task which must have been approved by multiple admins
    /// @param newAccount new exchange address
    function setExchange4Account(uint256 adminTaskId, address newAccount) external adminApprovalRequired(adminTaskId) {
        require(newAccount != address(0), "arteQTokens: zero address for exchange account");
        _exchange4Account = newAccount;
        emit Exchange4AccountChanged(newAccount);
    }

    /// Sets a new exchange account. Just after deployment, exchange account is set to zero address but once
    /// set to a non-zero address, it cannot be changed back to zero address again.
    ///
    /// @param adminTaskId the task which must have been approved by multiple admins
    /// @param newAccount new exchange address
    function setExchange5Account(uint256 adminTaskId, address newAccount) external adminApprovalRequired(adminTaskId) {
        require(newAccount != address(0), "arteQTokens: zero address for exchange account");
        _exchange5Account = newAccount;
        emit Exchange5AccountChanged(newAccount);
    }

    /// Returns the profit percentage
    /// @return The set treasury account
    function getProfitPercentage() external view returns (uint) {
        return _profitPercentage;
    }

    /// Sets a new profit percentage. This is the percentage of bought-back tokens which is considered
    /// as profit for gARTEQ owners. The value can be between 10% and 50%.
    ///
    /// @param adminTaskId the task which must have been approved by multiple admins
    /// @param newPercentage new exchange address
    function setProfitPercentage(uint256 adminTaskId, uint newPercentage) external adminApprovalRequired(adminTaskId) {
        require(newPercentage >= 10 && newPercentage <= 50, "arteQTokens: invalid value for profit percentage");
        _profitPercentage = newPercentage;
        emit ProfitPercentageChanged(newPercentage);
    }

    /// Transfer from admin contract
    function transferFromAdminContract(
        uint256 adminTaskId,
        address to,
        uint256 id,
        uint256 amount
    ) external adminApprovalRequired(adminTaskId) {
        _safeTransferFrom(_msgSender(), _adminContract, to, id, amount, "");
    }

    /// A token distribution mechanism, only valid in ramp-up phase, valid till the end of Jan 2022.
    function rampUpPhaseDistributeToken(
        uint256 adminTaskId,
        address[] memory tos,
        uint256[] memory amounts,
        uint256[] memory lockedUntilTimestamps
    ) external adminApprovalRequired(adminTaskId) onlyRampUpPhase {
        require(tos.length == amounts.length, "arteQTokens: inputs have incorrect lengths");
        for (uint256 i = 0; i < tos.length; i++) {
            require(tos[i] != _treasuryAccount, "arteQTokens: cannot transfer to treasury account");
            require(tos[i] != _adminContract, "arteQTokens: cannot transfer to admin contract");
            _safeTransferFrom(_msgSender(), _adminContract, tos[i], ARTEQ, amounts[i], "");
            if (lockedUntilTimestamps[i] > 0) {
                _lockedUntilTimestamps[tos[i]] = lockedUntilTimestamps[i];
            }
            emit RampUpPhaseTokensDistributed(tos[i], amounts[i], lockedUntilTimestamps[i]);
        }
    }

    function balanceOf(address account, uint256 tokenId)
      public view virtual override validToken(tokenId) returns (uint256) {
        if (tokenId == gARTEQ) {
            return super.balanceOf(account, tokenId);
        }
        return super.balanceOf(account, tokenId) + _calcUnrealizedProfitTokens(account);
    }

    function allTimeProfit() external view returns (uint256) {
        return _allTimeProfit;
    }

    function totalCirculatingGovernanceTokens() external view returns (uint256) {
        return totalSupply(gARTEQ) - balanceOf(_adminContract, gARTEQ);
    }

    function profitTokensTransferredToAccounts() external view returns (uint256) {
        return _profitTokensTransferredToAccounts;
    }

    function compatBalanceOf(address /* origin */, address account, uint256 tokenId)
      external view virtual override returns (uint256) {
        return balanceOf(account, tokenId);
    }

    function compatTotalSupply(address /* origin */, uint256 tokenId) external view virtual override returns (uint256) {
        return totalSupply(tokenId);
    }

    function compatTransfer(address origin, address to, uint256 tokenId, uint256 amount) external virtual override {
        address from = origin;
        _safeTransferFrom(origin, from, to, tokenId, amount, "");
    }

    function compatTransferFrom(address origin, address from, address to, uint256 tokenId, uint256 amount)
      external virtual override {
        require(
            from == origin || isApprovedForAll(from, origin),
            "arteQTokens: caller is not owner nor approved "
        );
        _safeTransferFrom(origin, from, to, tokenId, amount, "");
    }

    function compatAllowance(address /* origin */, address account, address operator)
      external view virtual override returns (uint256) {
        if (isApprovedForAll(account, operator)) {
            return 2 ** 256 - 1;
        }
        return 0;
    }

    function compatApprove(address origin, address operator, uint256 amount) external virtual override {
        _setApprovalForAll(origin, operator, amount > 0);
    }

    // If this contract gets a balance in some ERC20 contract after it's finished, then we can rescue it.
    function rescueTokens(uint256 adminTaskId, IERC20 foreignToken, address to)
      external adminApprovalRequired(adminTaskId) {
        foreignToken.transfer(to, foreignToken.balanceOf(address(this)));
    }

    // If this contract gets a balance in some ERC721 contract after it's finished, then we can rescue it.
    function approveNFTRescue(uint256 adminTaskId, IERC721 foreignNFT, address to)
      external adminApprovalRequired(adminTaskId) {
        foreignNFT.setApprovalForAll(to, true);
    }

    // In case of any manual buy back event which is not processed through DEX contracts, this function
    // helps admins distribute the profits. This function must be called only when the bought back tokens
    // have been successfully transferred to treasury account.
    function processManualBuyBackEvent(uint256 adminTaskId, uint256 boughtBackTokensAmount)
      external adminApprovalRequired(adminTaskId) {
        uint256 profit = (boughtBackTokensAmount * _profitPercentage) / 100;
        if (profit > 0) {
            _balances[ARTEQ][_treasuryAccount] -= profit;
            emit ManualBuyBackWithdrawalFromTreasury(profit);
            _allTimeProfit += profit;
            emit ProfitTokensCollected(profit);
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        // We have to call the super function in order to have the total supply correct.
        // It is actually needed by the first two _initialMint calls only. After that, it is
        // a no-op function.
        super._beforeTokenTransfer(operator, from, to, id, amounts, data);

        // this is one of the two first _initialMint calls
        if (from == address(0)) {
            return;
        }

        // This is a buy-back callback from exchange account
        if ((
                from == _exchange1Account ||
                from == _exchange2Account ||
                from == _exchange3Account ||
                from == _exchange4Account ||
                from == _exchange5Account
        ) && to == _treasuryAccount) {
            require(amounts.length == 2 && id == ARTEQ, "arteQTokens: invalid transfer from exchange");
            uint256 profit = (amounts[0] * _profitPercentage) / 100;
            amounts[1] = amounts[0] - profit;
            if (profit > 0) {
                _allTimeProfit += profit;
                emit ProfitTokensCollected(profit);
            }
            return;
        }

        // Ensures that the locked accounts cannot send their ARTEQ tokens
        if (id == ARTEQ) {
            require(_lockedUntilTimestamps[from] == 0 || block.timestamp > _lockedUntilTimestamps[from],
                    "arteQTokens: account cannot send tokens");
        }

        // Realize/Transfer the accumulated profit of 'from' account and make it spendable
        if (from != _adminContract &&
            from != _treasuryAccount &&
            from != _exchange1Account &&
            from != _exchange2Account &&
            from != _exchange3Account &&
            from != _exchange4Account &&
            from != _exchange5Account) {
            _realizeAccountProfitTokens(from);
        }

        // Realize/Transfer the accumulated profit of 'to' account and make it spendable
        if (to != _adminContract &&
            to != _treasuryAccount &&
            to != _exchange1Account &&
            to != _exchange2Account &&
            to != _exchange3Account &&
            to != _exchange4Account &&
            to != _exchange5Account) {
            _realizeAccountProfitTokens(to);
        }
    }

    function _calcUnrealizedProfitTokens(address account) internal view returns (uint256) {
        if (account == _adminContract ||
            account == _treasuryAccount ||
            account == _exchange1Account ||
            account == _exchange2Account ||
            account == _exchange3Account ||
            account == _exchange4Account ||
            account == _exchange5Account) {
            return 0;
        }
        uint256 profitDifference = _allTimeProfit - _profitMarkers[account];
        uint256 totalGovTokens = totalSupply(gARTEQ) - balanceOf(_adminContract, gARTEQ);
        if (totalGovTokens == 0) {
            return 0;
        }
        uint256 tokensToTransfer = (profitDifference * balanceOf(account, gARTEQ)) / totalGovTokens;
        return tokensToTransfer;
    }

    // This function actually transfers the unrealized accumulated profit tokens of an account
    // and make them spendable by that account. The balance should not differ after the
    // trasnfer as the balance already includes the unrealized tokens.
    function _realizeAccountProfitTokens(address account) internal {
        bool updateProfitMarker = true;
        // If 'account' has some governance tokens then calculate the accumulated profit since the last distribution
        if (balanceOf(account, gARTEQ) > 0) {
            uint256 tokensToTransfer = _calcUnrealizedProfitTokens(account);
            // If the profit is too small and no token can be transferred, then don't update the profit marker and
            // let the account wait for the next round of profit distribution
            if (tokensToTransfer == 0) {
                updateProfitMarker = false;
            } else {
                _balances[ARTEQ][account] += tokensToTransfer;
                _profitTokensTransferredToAccounts += tokensToTransfer;
                emit ProfitTokensDistributed(account, tokensToTransfer);
            }
        }
        if (updateProfitMarker) {
            _profitMarkers[account] = _allTimeProfit;
        }
    }

    receive() external payable {
        revert("arteQTokens: cannot accept ether");
    }

    fallback() external payable {
        revert("arteQTokens: cannot accept ether");
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0
// Based on OpenZeppelin Contracts v4.3.2 (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity 0.8.1;

import "./ERC1155.sol";

/**
 * @author Modified by Kam Amini <[email protected]> <[email protected]>
 *
 * @notice Use at your own risk
 *
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 *
  * Note: The original contract has been modified to cover the needs as
  *       part of artèQ Investment Fund ecosystem
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, id, amounts, data);

        if (from == address(0)) {
            _totalSupply[id] += amounts[0];
        }

        if (to == address(0)) {
            _totalSupply[id] -= amounts[0];
        }
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "../../arteq-tech/contracts/vaults/VaultsConfig.sol";
import "../../arteq-tech/contracts/diamond/Diamond.sol";
import "./arteQCollectionV2Config.sol";

/// @author Kam Amini <[email protected]> <[email protected]>
///
/// @notice Use at your own risk

/* solhint-disable contract-name-camelcase */
contract arteQCollectionV2 is Diamond {

    string private _detailsURI;

    modifier onlyAdmin {
        RoleManagerLib._checkRole(arteQCollectionV2Config.ROLE_ADMIN);
        _;
    }

    constructor(
        address taskManager,
        address appRegistry,
        string memory detailsURI,
        address[] memory admins,
        address[] memory tokenManagers,
        address[] memory vaultAdmins,
        address[] memory diamondAdmins
    ) Diamond(
        taskManager,
        diamondAdmins,
        "arteq-collection-v2",
        appRegistry
    ) {
        // Admin role
        for (uint i = 0; i < admins.length; i++) {
            RoleManagerLib._grantRole(admins[i], arteQCollectionV2Config.ROLE_ADMIN);
        }
        // Token Manager role
        for (uint i = 0; i < tokenManagers.length; i++) {
            RoleManagerLib._grantRole(tokenManagers[i],arteQCollectionV2Config.ROLE_TOKEN_MANAGER);
        }
        // Vault Admin role
        for (uint i = 0; i < vaultAdmins.length; i++) {
            RoleManagerLib._grantRole(vaultAdmins[i], VaultsConfig.ROLE_VAULT_ADMIN);
        }
        _detailsURI = detailsURI;
    }

    function supportsInterface(bytes4 interfaceId)
      public view override returns (bool) {
        // For the sake of OpenSea's collection detection and caching mechanism
        if (interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function getDetailsURI() external view returns (string memory) {
        return _detailsURI;
    }

    function setDetailsURI(string memory newValue) external onlyAdmin {
        _detailsURI = newValue;
    }

    /* solhint-disable no-complex-fallback */
    fallback() external payable {
        address facet = _findFacet(msg.sig);
        /* solhint-disable no-inline-assembly */
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
        /* solhint-enable no-inline-assembly */
    }

    /* solhint-disable no-empty-blocks */
    receive() external payable {
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library VaultsConfig {

    uint256 public constant ROLE_VAULT_ADMIN = uint256(keccak256(bytes("ROLE_VAULT_ADMIN")));
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../app-registry/IAppRegistry.sol";
import "../security/task-executor/TaskExecutorBase.sol";
import "../security/task-executor/TaskExecutorLib.sol";
import "../security/role-manager/RoleManagerBase.sol";
import "../security/role-manager/RoleManagerLib.sol";
import "./IDiamond.sol";
import "./IDiamondFacet.sol";
import "./DiamondConfig.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract Diamond is
  IDiamond,
  TaskExecutorBase,
  RoleManagerBase
{
    event FacetAdd(address facet);
    event FacetDelete(address facet);
    event Freeze();
    event AppInstall(address appRegistry, string name, string version);
    event AppRegistrySet(address appRegistry);
    event FuncSigOverride(string funcSig, address facet);

    string private _name;
    address private _appRegistry;
    bool internal _frozen;
    address[] internal _facets;
    mapping(address => uint256) private _facetArrayIndex;
    mapping(address => bool) private _deletedFacets;
    mapping(bytes4 => address) private _selectorToFacetMap;

    modifier onlyDiamondAdmin() {
        RoleManagerLib._checkRole(DiamondConfig.ROLE_DIAMOND_ADMIN);
        _;
    }

    constructor(
        address taskManager,
        address[] memory diamondAdmins,
        string memory name,
        address appRegistry
    ) {
        // The diamond is not frozen by default.
        _frozen = false;
        TaskExecutorLib._setTaskManager(taskManager);
        for(uint i = 0; i < diamondAdmins.length; i++) {
            RoleManagerLib._grantRole(diamondAdmins[i], DiamondConfig.ROLE_DIAMOND_ADMIN);
        }
        _name = name;
        _appRegistry = appRegistry;
        emit AppRegistrySet(_appRegistry);
    }

    function supportsInterface(bytes4 interfaceId)
      public view override virtual returns (bool) {
        // Querying for IDiamondFacet must always return false
        if (interfaceId == type(IDiamondFacet).interfaceId) {
            return false;
        }
        // Always return true
        if (interfaceId == type(IERC165).interfaceId) {
            return true;
        }
        for (uint256 i = 0; i < _facets.length; i++) {
            address facet = _facets[i];
            if (!_deletedFacets[facet] &&
                IDiamondFacet(facet).supportsInterface(interfaceId)) {
                return true;
            }
        }
        return false;
    }

    function getDiamondName() external view virtual override returns (string memory) {
        return _name;
    }

    function getDiamondVersion() external view virtual override returns (string memory) {
        return "1.1.0";
    }

    function getAppRegistry() external view onlyDiamondAdmin returns (address) {
        return _appRegistry;
    }

    function setAppRegistry(address appRegistry) external onlyDiamondAdmin {
        require(!_frozen, "DMND:FRZN");
        if (appRegistry != address(0)) {
            require(
                IERC165(appRegistry).supportsInterface(type(IAppRegistry).interfaceId),
                "DMND:IAR"
            );
        }
        _appRegistry = appRegistry;
        emit AppRegistrySet(_appRegistry);
    }

    function isFrozen() external view returns (bool) {
        return _frozen;
    }

    function freeze() external onlyDiamondAdmin {
        require(!_frozen, "DMND:FRZN");
        _frozen = true;
        emit Freeze();
    }

    function getFacets() external view override onlyDiamondAdmin returns (address[] memory) {
        return __getFacets();
    }

    function addFacets(address[] memory facets) external onlyDiamondAdmin {
        require(!_frozen, "DMND:FRZN");
        require(facets.length > 0, "DMND:ZL");
        for (uint256 i = 0; i < facets.length; i++) {
            __addFacet(facets[i]);
        }
    }

    function deleteFacets(address[] memory facets) external onlyDiamondAdmin {
        require(!_frozen, "DMND:FRZN");
        require(facets.length > 0, "DMND:ZL");
        for (uint256 i = 0; i < facets.length; i++) {
            __deleteFacet(facets[i]);
        }
    }

    function deleteAllFacets() external onlyDiamondAdmin {
        require(!_frozen, "DMND:FRZN");
        for (uint256 i = 0; i < _facets.length; i++) {
            __deleteFacet(_facets[i]);
        }
    }

    function installApp(
        string memory appName,
        string memory appVersion,
        bool deleteCurrentFacets
    ) external onlyDiamondAdmin {
        require(!_frozen, "DMND:FRZN");
        require(_appRegistry != address(0), "DMND:ZAR");
        if (deleteCurrentFacets) {
            for (uint256 i = 0; i < _facets.length; i++) {
                __deleteFacet(_facets[i]);
            }
        }
        address[] memory appFacets =
            IAppRegistry(_appRegistry).getAppFacets(appName, appVersion);
        for (uint256 i = 0; i < appFacets.length; i++) {
            __addFacet(appFacets[i]);
        }
        if (appFacets.length > 0) {
            emit AppInstall(_appRegistry, appName, appVersion);
        }
    }

    // WARN: Never use this function directly. The proper way is to add a facet
    //       as a whole.
    function overrideFuncSigs(
        string[] memory funcSigs,
        address[] memory facets
    ) external onlyDiamondAdmin {
        require(!_frozen, "DMND:FRZN");
        __overrideFuncSigs(funcSigs, facets);
    }

    function _findFacet(bytes4 selector) internal view returns (address) {
        address facet = _selectorToFacetMap[selector];
        require(facet != address(0), "DMND:FNF");
        require(!_deletedFacets[facet], "DMND:FREM");
        return facet;
    }

    function __getFacets() private view returns (address[] memory) {
        uint256 count = 0;
        {
            for (uint256 i = 0; i < _facets.length; i++) {
                if (!_deletedFacets[_facets[i]]) {
                    count += 1;
                }
            }
        }
        address[] memory facets = new address[](count);
        {
            uint256 index = 0;
            for (uint256 i = 0; i < _facets.length; i++) {
                if (!_deletedFacets[_facets[i]]) {
                    facets[index] = _facets[i];
                    index += 1;
                }
            }
        }
        return facets;
    }

    function __addFacet(address facet) private {
        require(facet != address(0), "DMND:ZF");
        require(
            IDiamondFacet(facet).supportsInterface(type(IDiamondFacet).interfaceId),
            "DMND:IF"
        );
        string[] memory funcSigs = IDiamondFacet(facet).getFacetPI();
        for (uint256 i = 0; i < funcSigs.length; i++) {
            string memory funcSig = funcSigs[i];
            bytes4 selector = __getSelector(funcSig);
            _selectorToFacetMap[selector] = facet;
        }
        _deletedFacets[facet] = false;
        // update facets array
        if (_facetArrayIndex[facet] == 0) {
            _facets.push(facet);
            _facetArrayIndex[facet] = _facets.length;
        }
        emit FacetAdd(facet);
    }

    function __deleteFacet(address facet) private {
        require(facet != address(0), "DMND:ZF");
        _deletedFacets[facet] = true;
        emit FacetDelete(facet);
    }

    function __overrideFuncSigs(
        string[] memory funcSigs,
        address[] memory facets
    ) private {
        require(funcSigs.length > 0, "DMND:ZL");
        require(funcSigs.length == facets.length, "DMND:IL");
        for (uint i = 0; i < funcSigs.length; i++) {
            string memory funcSig = funcSigs[i];
            address facet = facets[i];
            bytes4 selector = __getSelector(funcSig);
            _selectorToFacetMap[selector] = facet;
            // WARN: Undeleting an already deleted facet may result in unwanted
            //       consequences. Make sure to set address(0) for all other
            //       function signatures in such facet.
            _deletedFacets[facet] = false;
            emit FuncSigOverride(funcSig, facet);
        }
    }

    function __getSelector(string memory funcSig) private pure returns (bytes4) {
        bytes memory funcSigBytes = bytes(funcSig);
        for (uint256 i = 0; i < funcSigBytes.length; i++) {
            bytes1 b = funcSigBytes[i];
            if (
                !(b >= 0x30 && b <= 0x39) && // [0-9]
                !(b >= 0x41 && b <= 0x5a) && // [A-Z]
                !(b >= 0x61 && b <= 0x7a) && // [a-z]
                 b != 0x24 && // $
                 b != 0x5f && // _
                 b != 0x2c && // ,
                 b != 0x28 && // (
                 b != 0x29 && // )
                 b != 0x5b && // [
                 b != 0x5d    // ]
            ) {
                revert("DMND:IFS");
            }
        }
        return bytes4(keccak256(bytes(funcSig)));
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

// import "../task-executor/TaskExecutorLib.sol";
// import "./RoleManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IAppRegistry {

    function getAppFacets(
        string memory appName,
        string memory appVersion
    ) external view returns (address[] memory);
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./TaskExecutorInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TaskExecutorBase {

    function getTaskManager() external view returns (address) {
        return TaskExecutorInternal._getTaskManager();
    }

    function setTaskManager(
        uint256 adminTaskId,
        address newTaskManager
    ) external {
        address oldTaskManager = TaskExecutorInternal._getTaskManager();
        TaskExecutorInternal._setTaskManager(newTaskManager);
        if (oldTaskManager != address(0)) {
            ITaskExecutor(oldTaskManager).executeAdminTask(msg.sender, adminTaskId);
        }
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./TaskExecutorInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library TaskExecutorLib {

    function _setTaskManager(address newTaskManager) internal {
        TaskExecutorInternal._setTaskManager(newTaskManager);
    }

    function _executeTask(uint256 taskId) internal {
        TaskExecutorInternal._executeTask(taskId);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../task-executor/TaskExecutorLib.sol";
import "./RoleManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract RoleManagerBase {

    function hasRole(
        address account,
        uint256 role
    ) external view returns (bool) {
        return RoleManagerInternal._hasRole2(account, role);
    }

    function grantRole(
        uint256 taskId,
        address account,
        uint256 role
    ) external {
        RoleManagerInternal._grantRole(account, role);
        TaskExecutorLib._executeTask(taskId);
    }

    function revokeRole(
        uint256 taskId,
        address account,
        uint256 role
    ) external {
        RoleManagerInternal._revokeRole(account, role);
        TaskExecutorLib._executeTask(taskId);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IDiamond is IERC165 {

    function getDiamondName() external view returns (string memory);

    function getDiamondVersion() external view returns (string memory);

    function getFacets() external view returns (address[] memory);
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library DiamondConfig {

    uint256 public constant ROLE_DIAMOND_ADMIN = uint256(keccak256(bytes("ROLE_DIAMOND_ADMIN")));
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "../../interfaces/ITaskExecutor.sol";
import "./TaskExecutorStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library TaskExecutorInternal {

    event TaskManagerChanged(address newTaskManager);

    function _getTaskManager() internal view returns (address) {
        return __s().taskManager;
    }

    function _setTaskManager(address newTaskManager) internal {
        require(newTaskManager != address(0), "TE:ZA");
        require(IERC165(newTaskManager).supportsInterface(type(ITaskExecutor).interfaceId),
            "TE:IC");
        __s().taskManager = newTaskManager;
        emit TaskManagerChanged(__s().taskManager);
    }

    function _executeTask(uint256 taskId) internal {
        require(__s().taskManager != address(0), "TE:NTM");
        ITaskExecutor(__s().taskManager).executeTask(msg.sender, taskId);
    }

    function __s() private pure returns (TaskExecutorStorage.Layout storage) {
        return TaskExecutorStorage.layout();
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library TaskExecutorStorage {

    struct Layout {
        address taskManager;
        mapping(uint256 => uint256) extra;
    }

    // Storage Slot: de1b6f91cd9572e4381a8b8d203bdc268664230f56599f11d2ca9df8d397fb6f
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-tech.contracts.security.task-executor.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "../../arteq-tech/contracts/vaults/VaultsConfig.sol";
import "../../arteq-tech/contracts/diamond/Diamond.sol";
import "./minter/MinterLib.sol";
import "./arteQCollectionV2Config.sol";

/// @author Kam Amini <[email protected]> <[email protected]>
///
/// @notice Use at your own risk

/* solhint-disable contract-name-camelcase */
contract TestCollectionV2Diamond is Diamond {

    string private _detailsURI;

    constructor(
        address taskManager,
        address appRegistry,
        address[] memory admins,
        address[] memory tokenManagers,
        address[] memory vaultAdmins,
        address[] memory diamondAdmins
    ) Diamond(
        taskManager,
        diamondAdmins,
        "test-arteq-collection-v2",
        appRegistry
    ) {
        // Admin role
        for (uint i = 0; i < admins.length; i++) {
            RoleManagerLib._grantRole(admins[i], arteQCollectionV2Config.ROLE_ADMIN);
        }
        // Token Manager role
        for (uint i = 0; i < tokenManagers.length; i++) {
            RoleManagerLib._grantRole(tokenManagers[i], arteQCollectionV2Config.ROLE_TOKEN_MANAGER);
        }
        // Vault Admin role
        for (uint i = 0; i < vaultAdmins.length; i++) {
            RoleManagerLib._grantRole(vaultAdmins[i], VaultsConfig.ROLE_VAULT_ADMIN);
        }
        MinterLib._justMintTo(address(this)); // mint and reserve token #0
    }

    /* solhint-disable no-complex-fallback */
    fallback() external payable {
        address facet = _findFacet(msg.sig);
        /* solhint-disable no-inline-assembly */
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
        /* solhint-enable no-inline-assembly */
    }

    /* solhint-disable no-empty-blocks */
    receive() external payable {
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../diamond/IDiamondFacet.sol";
import "../../security/role-manager/RoleManagerLib.sol";
import "../VaultsConfig.sol";
import "./ETHVaultInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract ETHVaultFacet is IDiamondFacet {

    modifier onlyVaultAdmin {
        RoleManagerLib._checkRole(VaultsConfig.ROLE_VAULT_ADMIN);
        _;
    }

    function getFacetName() external pure override returns (string memory) {
        return "eth-vault";
    }

    function getFacetVersion() external pure override returns (string memory) {
        return "0.0.1";
    }

    function getFacetPI() external pure override returns (string[] memory) {
        string[] memory pi = new string[](3);
        pi[0] = "isDepositEnabled()";
        pi[1] = "setEnableDeposit(bool)";
        pi[2] = "ETHTransfer(address,uint256)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external view override virtual returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId;
    }

    function isDepositEnabled() external view returns (bool) {
        return ETHVaultInternal._isDepositEnabled();
    }

    function setEnableDeposit(bool enableDeposit) external onlyVaultAdmin {
        ETHVaultInternal._setEnableDeposit(enableDeposit);
    }

    /* solhint-disable func-name-mixedcase */
    function ETHTransfer(
        address to,
        uint256 amount
    ) external onlyVaultAdmin {
        ETHVaultInternal._ETHTransfer(to, amount);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./ETHVaultStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library ETHVaultInternal {

    event DepositEnabled();
    event DepositDisabled();
    event ETHTransfer(address to, uint256 amount);

    function _isDepositEnabled() internal view returns (bool) {
        return __s().enableDeposit;
    }

    function _setEnableDeposit(bool enableDeposit) internal {
        __s().enableDeposit = enableDeposit;
        if (__s().enableDeposit) {
            emit DepositEnabled();
        } else {
            emit DepositDisabled();
        }
    }

    /* solhint-disable func-name-mixedcase */
    function _ETHTransfer(
        address to,
        uint256 amount
    ) internal {
        require(to != address(0), "EV: zero target");
        require(amount > 0, "EV: zero amount");
        require(amount <= address(this).balance, "EV: more than balance");
        /* solhint-disable avoid-low-level-calls */
        (bool success, ) = to.call{value: amount}(new bytes(0));
        /* solhint-enable avoid-low-level-calls */
        require(success, "EV: failed to transfer");
        emit ETHTransfer(to, amount);
    }

    function __s() private pure returns (ETHVaultStorage.Layout storage) {
        return ETHVaultStorage.layout();
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library ETHVaultStorage {

    struct Layout {
        bool enableDeposit;
        mapping(uint256 => uint256) extra;
    }

    // Storage Slot: 869b0c6ceb849a78cd5ea3c21e183f2a9d8e7750ceef39ea4c088b64edb7ee6c
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-tech.contracts.vaults.eth.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../security/task-executor/TaskExecutorLib.sol";
import "../../security/task-executor/TaskExecutorBase.sol";
import "../../security/role-manager/RoleManagerLib.sol";
import "../../security/role-manager/RoleManagerBase.sol";
import "./ETHVaultFacet.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract ETHVaultMock is
  TaskExecutorBase,
  RoleManagerBase,
  ETHVaultFacet
{
    constructor(address taskManager) {
        TaskExecutorLib._setTaskManager(taskManager);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../diamond/IDiamondFacet.sol";
import "./RoleManagerBase.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract RoleManagerFacet is RoleManagerBase, IDiamondFacet {

    function getFacetName() external pure override returns (string memory) {
        return "role-manager";
    }

    function getFacetVersion() external pure override returns (string memory) {
        return "0.0.1";
    }

    function getFacetPI() external pure override returns (string[] memory) {
        string[] memory pi = new string[](3);
        pi[0] = "hasRole(address,uint256)";
        pi[1] = "grantRole(uint256,address,uint256)";
        pi[2] = "revokeRole(uint256,address,uint256)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external view override virtual returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId;
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./TaskExecutorInternal.sol";
import "./TaskExecutorFacet.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TaskExecutorMock is TaskExecutorFacet {

    constructor(address taskManager) {
        TaskExecutorInternal._setTaskManager(taskManager);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../diamond/IDiamondFacet.sol";
import "./TaskExecutorBase.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TaskExecutorFacet is TaskExecutorBase, IDiamondFacet {

    function getFacetName() external pure override returns (string memory) {
        return "task-executor";
    }

    function getFacetVersion() external pure override returns (string memory) {
        return "0.0.1";
    }

    function getFacetPI() external pure override returns (string[] memory) {
        string[] memory pi = new string[](2);
        pi[0] = "getTaskManager()";
        pi[1] = "setTaskManager(uint256,address)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external view override virtual returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId;
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interfaces/ITaskExecutor.sol";
import "./interfaces/IPassedProposalExecutor.sol";

// TOOD(kam): add trasnfer and approve from IERC20 interface (treasury, trading, governance)
// TODO(kam): rescue functions
// TODO(kam): ENS
// TODO(kam): treasury can send ETH to NFT buyer wallets
// TODO(kam): treasury must be able to provide liquidity
// TODO(kam): treasury must be able to buy back tokens
// TODO(kam): treasury must be able to sell tokens
// TODO(kam): admin contract
// TODO(kam): must ignore DAO contract if the address is not set
// TODO(kam): once DAO address is set, it can be changed but it cannot be zero address anymore
// TODO(kam): must be able to transfer NFTs
// TODO(kam): a buyer wallet can register an NFT and retrieve the spent ETH amount
// TODO(kam): auction interactions
// TODO(kam): must accept ETH
// TODO(kam): lock tokens, NFTs, or even ETH
// TODO(kam): on polygon, it cannot add/remove liquidity or swap tokens. Only possible in ETH.
// TODO(kam): main token contract address must be changeable as well as pair and router contract
// TODO(kam): impl ERC1155Receiver (important!)

// TODO(kam): remove the following line
/* solhint-disable no-empty-blocks */
contract Treasury {

    // Admin task manager contract
    address private _adminTaskManagerContract;

    // Passed Proposals Archive contract (TODO(kam): add docs)
    address private _passedProposalArchiveContract;

    address private _uniswapV2Router;

    struct ERC20Token {
        address contractAddress;
        address uniswapV2Pair;
    }
    mapping (address => ERC20Token) private _managingERC20Tokens;

    event NativeTransfer(
        uint256 adminTaskId,
        uint256 votingProposalId,
        address target,
        uint256 amount,
        string purpose
    );
    event ERC20Transfer(
        uint256 adminTaskId,
        uint256 votingProposalId,
        address erc20Contract,
        address target,
        uint256 amount,
        string purpose
    );
    event ERC721Transfer(
        uint256 adminTaskId,
        uint256 votingProposalId,
        address erc721Contract,
        address target,
        uint256 tokenId,
        string purpose
    );
    event ERC1155Transfer(
        uint256 adminTaskId,
        uint256 votingProposalId,
        address erc1155Contract,
        address target,
        uint256 tokenId,
        uint256 amount,
        string purpose
    );

    modifier adminApprovalRequired(uint256 adminTaskId) {
        _;
        _executeAdminTask(msg.sender, adminTaskId);
    }

    modifier votingOrAdminApprovalRequired(uint256 adminTaskId, uint256 passedProposalId) {
        _;
        // One of these must succeed otherwise the tx gets reverted
        if (_passedProposalArchiveContract != address(0) && passedProposalId > 0) {
            IPassedProposalExecutor(_passedProposalArchiveContract)
                .executeProposal(msg.sender, passedProposalId);
        } else {
            _executeAdminTask(msg.sender, adminTaskId);
        }
    }

    constructor(
        address adminTaskManagerContract,
        address uniswapV2Router
    ) {
        _adminTaskManagerContract = adminTaskManagerContract;
        _uniswapV2Router = uniswapV2Router;
        _passedProposalArchiveContract = address(0);
    }

    function getAdminTaskManagerContract() external view returns (address) {
        return _adminTaskManagerContract;
    }

    // TODO(kam): maybe add a function to change the admin contract

    function getUniswapV2Router() external view returns (address) {
        return _uniswapV2Router;
    }

    function getPassedProposalArchiveContract() external view returns (address) {
        return _passedProposalArchiveContract;
    }

    function setPassedProposalArchiveContract(
        uint256 adminTaskId,
        address passedProposalArchiveContract
    ) external
      adminApprovalRequired(adminTaskId)
    {
        require(passedProposalArchiveContract != address(0),
                "Treasury: zero address for vote archive contract");
        _passedProposalArchiveContract = passedProposalArchiveContract;
    }

    function getManagingERC20TokenInfo(address contractAddress) external view returns (ERC20Token memory) {
        // TODO(kam): check existance
        return _managingERC20Tokens[contractAddress];
    }

    // TODO(kam): create a function to add a new managing erc20 token
    // TODO(kam): create a function to remove a new managing erc20 token
    // TODO(kam): maybe create a function to change a new managing erc20 token

    function safeNativeTransferTo(
        uint256 adminTaskId,
        uint256 votingProposalId,
        address target,
        uint256 amount,
        string memory /*purpose*/
    ) external
      votingOrAdminApprovalRequired(adminTaskId, votingProposalId)
    {
        /* solhint-disable avoid-low-level-calls */
        (bool success, ) = target.call{value: amount}(new bytes(0));
        /* solhint-enable avoid-low-level-calls */
        require(success, "Treasury: failed to send the amount");
        // TODO(kam): emit NativeTransfer(...);
    }

    function safeERC20TransferTo(
        uint256 adminTaskId,
        uint256 votingProposalId,
        address target,
        address erc20Contract,
        string memory purpose
    ) external
      votingOrAdminApprovalRequired(adminTaskId, votingProposalId)
    {
        // TODO
    }

    function safeERC721TransferTo(
        uint256 adminTaskId,
        uint256 votingProposalId,
        address target,
        address erc721Contract,
        uint256 tokenId,
        string memory purpose
    ) external
      votingOrAdminApprovalRequired(adminTaskId, votingProposalId)
    {
        // TODO
    }

    function approveERC20AllowanceForRouter(
        uint256 adminTaskId,
        uint256 votingProposalId,
        address erc20ContractAddress
    ) external
      votingOrAdminApprovalRequired(adminTaskId, votingProposalId)
    {
        // TODO
    }

    /*
        function addLiquidityETH(
          address token,
          uint amountTokenDesired,
          uint amountTokenMin,
          uint amountETHMin,
          address to,
          uint deadline
        ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
     */
    function addERC20TokenLiquidity(
        uint256 adminTaskId,
        uint256 votingProposalId,
        address erc20ContractAddress,
        uint256 amount,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountMin,
        uint256 deadline
    ) external
      votingOrAdminApprovalRequired(adminTaskId, votingProposalId)
    {
        // TODO
    }

    /*
        function removeLiquidityETH(
          address token,
          uint liquidity,
          uint amountTokenMin,
          uint amountETHMin,
          address to,
          uint deadline
        ) external returns (uint amountToken, uint amountETH);
    */
    function removeERC20TokenLiquidity(
        uint256 adminTaskId,
        uint256 votingProposalId,
        address erc20ContractAddress,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountWeiMin,
        uint256 deadline
    ) external
      votingOrAdminApprovalRequired(adminTaskId, votingProposalId)
    {
        // TODO
    }

    /*
        function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
          external
          payable
          returns (uint[] memory amounts);
     */
    function buyERC20Token(
        uint256 adminTaskId,
        uint256 votingProposalId,
        address erc20ContractAddress
        // TODO(kam): ...
    ) external
      votingOrAdminApprovalRequired(adminTaskId, votingProposalId)
    {
        // TODO
    }

    /*
        function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path,
        address to, uint deadline)
          external
          returns (uint[] memory amounts);
    */
    function sellToken(
        uint256 adminTaskId,
        uint256 votingProposalId,
        address erc20ContractAddress
        // TODO(kam): ...
    ) external
      votingOrAdminApprovalRequired(adminTaskId, votingProposalId)
    {
        // TODO
    }

    function _executeAdminTask(address executor, uint256 adminTaskId) internal virtual {
        ITaskExecutor(_adminTaskManagerContract).executeTask(executor, adminTaskId);
    }

    receive() external payable {
        // accept native coin deposits into this account
    }

    fallback() external payable {
        // accept native coin deposits into this account
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IPassedProposalExecutor {

    event ProposalExecuted(uint256 proposalId);

    function executeProposal(address executor, uint256 proposalId) external;
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./interfaces/ITaskExecutor.sol";
import "./interfaces/IPassedProposalExecutor.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk

// TODO(kam): remove the following line
/* solhint-disable no-empty-blocks */
contract PassedProposalArchive is IPassedProposalExecutor {

    string private _name;
    address private _adminTaskManagerContract;

    mapping (address => bool) private _submitters;
    mapping (address => bool) private _copiers;

    struct PassedProposal {
        // the proposal ID in this contract
        uint256 proposalId;
        // reference of the proposal in the origin DAO's voting system
        string votingRef;
        // an URI describing the proposal
        string uri;
        // the name of the archive ontract which this proposal is copied from
        string copiedFrom;
        // the source proposal ID in the contract which this proposal is copied from
        uint256 origProposalId;
    }
    mapping (uint256 => PassedProposal) private _passedProposals;
    mapping (bytes32 => PassedProposal) private _copiedPassedProposals;
    uint256 private _proposalIdCounter;

    // =======================================================================================
    // ===================================== Events ==========================================
    // =======================================================================================

    event SubmitterAdded(
        uint256 adminTaskId,
        address account
    );
    event SubmitterRemoved(
        uint256 adminTaskId,
        address account
    );
    event CopierAdded(
        uint256 adminTaskId,
        address account
    );
    event CopierRemoved(
        uint256 adminTaskId,
        address account
    );
    event PassedProposalAdded(
        uint256 indexed proposalId,
        string indexed votingRef,
        string uri
    );
    event PassedProposalCopied(
        uint256 indexed proposalId,
        string votingRef,
        string uri,
        string indexed copiedFrom,
        uint256 indexed origProposalId
    );

    // =======================================================================================
    // ================================== Constructor  =======================================
    // =======================================================================================

    constructor(string memory name, address adminTaskManagerContract) {
        // TODO(kam): check length of name
        require(adminTaskManagerContract != address(0),
                "PassedProposalArchive: zero address");
        _name = name;
        _adminTaskManagerContract = adminTaskManagerContract;
        _proposalIdCounter = 1;
    }

    // =======================================================================================
    // ==================================== Modifiers ========================================
    // =======================================================================================

    modifier onlySubmitter {
        require(_submitters[msg.sender], "PassedProposalArchive: not a submitter");
        _;
    }

    modifier onlyCopier {
        require(_copiers[msg.sender], "PassedProposalArchive: not a copier");
        _;
    }

    modifier onlyExecutor {
        // TODO(kam)
        _;
    }

    modifier adminApprovalRequired(uint256 adminTaskId) {
        _;
        _executeAdminTask(msg.sender, adminTaskId);
    }

    // =======================================================================================
    // =============================== General View Methods ==================================
    // =======================================================================================

    function getName() external view returns (string memory) {
        return _name;
    }

    // =======================================================================================
    // ================================ Submitter Methods ====================================
    // =======================================================================================

    function isSubmitter(address account) external view returns (bool) {
        return _submitters[account];
    }

    function addSubmitter(uint256 adminTaskId, address account) external adminApprovalRequired(adminTaskId) {
        require(!_submitters[account], "PassedProposalArchive: already a submitter");
        _submitters[account] = true;
        emit SubmitterAdded(adminTaskId, account);
    }

    function removeSubmitter(uint256 adminTaskId, address account) external adminApprovalRequired(adminTaskId) {
        require(_submitters[account], "PassedProposalArchive: not a submitter");
        _submitters[account] = false;
        emit SubmitterRemoved(adminTaskId, account);
    }

    // =======================================================================================
    // ================================== Copier Methods =====================================
    // =======================================================================================

    function isCopier(address account) external view returns (bool) {
        return _copiers[account];
    }

    function addCopier(uint256 adminTaskId, address account) external adminApprovalRequired(adminTaskId) {
        require(!_copiers[account], "PassedProposalArchive: already a copier");
        _copiers[account] = true;
        emit CopierAdded(adminTaskId, account);
    }

    function removeCopier(uint256 adminTaskId, address account) external adminApprovalRequired(adminTaskId) {
        require(_copiers[account], "PassedProposalArchive: not a copier");
        _copiers[account] = false;
        emit CopierRemoved(adminTaskId, account);
    }

    // =======================================================================================
    // ================================= Proposal Methods ====================================
    // =======================================================================================

    function getPassedProposal(uint256 proposalId) external view returns (PassedProposal memory) {
        require(_passedProposals[proposalId].proposalId > 0, "PassedProposalArchive: proposal does not exist");
        return _passedProposals[proposalId];
    }

    function getCopiedPassedProposal(
        string memory copiedFrom,
        uint256 origProposalId
    ) external view returns (PassedProposal memory) {
        bytes32 hash = keccak256(abi.encodePacked(copiedFrom, origProposalId));
        require(_copiedPassedProposals[hash].proposalId > 0, "PassedProposalArchive: proposal does not exist");
        return _copiedPassedProposals[hash];
    }

    function submitPassedProposal(
        string memory votingRef,
        string memory uri
    ) external
      onlySubmitter
    {
        _passedProposals[_proposalIdCounter] = PassedProposal(_proposalIdCounter, votingRef, uri, "", 0);
        emit PassedProposalAdded(_proposalIdCounter, votingRef, uri);
        _proposalIdCounter += 1;
    }

    function copyPassedProposal(
        string memory copiedFrom,
        uint256 origProposalId,
        string memory votingRef,
        string memory uri
    ) external
      onlyCopier
    {
        bytes32 hash = keccak256(abi.encodePacked(copiedFrom, origProposalId));
        require(_copiedPassedProposals[hash].proposalId == 0, "PassedProposalArchive: proposal exists");
        PassedProposal memory pp = PassedProposal(
            _proposalIdCounter,
            votingRef,
            uri,
            copiedFrom,
            origProposalId
        );
        _passedProposals[_proposalIdCounter] = pp;
        _copiedPassedProposals[hash] = pp;
        emit PassedProposalCopied(_proposalIdCounter, votingRef, uri, copiedFrom, origProposalId);
        _proposalIdCounter += 1;
    }

    function executeProposal(address executor, uint256 proposalId) external virtual override onlyExecutor {
        // TODO(kam)
    }

    // =======================================================================================
    // ================================== Private Methods ====================================
    // =======================================================================================

    function _executeAdminTask(address /*executor*/, uint256 adminTaskId) internal virtual {
        ITaskExecutor(_adminTaskManagerContract).executeTask(msg.sender, adminTaskId);
    }

    // =======================================================================================
    // ================================= Fallback Methods ====================================
    // =======================================================================================

    receive() external payable {
        // TODO(kam): must revert
    }

    fallback() external payable {
        // TODO(kam): must revert
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @notice Use at your own risk
contract TestERC20 is ERC20 {

    /* solhint-disable no-empty-blocks */
    constructor() ERC20("Test ERC20", "TestERC20") {}
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TestERC20 is ERC20 {

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../abstract/task-managed/BatchTransferEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TestBatchTransferEnabled is BatchTransferEnabled, ERC20 {

    constructor(
        address taskManager,
        string memory name,
        string memory symbol,
        uint256 initialSupply
    )
      ERC20(name, symbol)
    {
        _setTaskManager(taskManager);
        _mint(_getTaskManager(), initialSupply);
    }

    /* solhint-disable func-name-mixedcase */
    function testonly_getLockTs(address account) external view returns (uint256) {
        return _getLockTs(account);
    }

    function _beforeTokenTransfer(
        address from,
        address /*to*/,
        uint256 /*amount*/
    ) internal virtual override {
        require(!_isLocked(from), "TestBatchTransferEnabled: account is locked");
    }

    function _batchTransferSingle(address source, address to, uint256 amount) internal override {
        _transfer(source, to, amount);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../abstract/task-managed/AccountLocker.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TestAccountLocker is AccountLocker {

    constructor(address taskManager) {
        _setTaskManager(taskManager);
    }

    /* solhint-disable func-name-mixedcase */
    function testonly_getLockTs(address account) external view returns (uint256) {
        return _getLockTs(account);
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./ERC721URIStorage.sol";
import "./ERC721.sol";
import "./IarteQTaskFinalizer.sol";

/// @author Kam Amini <[email protected]> <[email protected]>
///
/// @notice Use at your own risk

/* solhint-disable contract-name-camelcase */
/* solhint-disable reason-string */
contract arteQArtDrop is ERC721URIStorage, IERC2981 {

    string private constant DEFAULT_TOKEN_URI = "DEFAULT_TOKEN_URI";

    uint256 public constant MAX_NR_TOKENS_PER_ACCOUNT = 5;
    uint256 public constant MAX_RESERVATIONS_COUNT = 10000;

    int256 public constant LOCKED_STAGE = 0;
    int256 public constant WHITELISTING_STAGE = 2;
    int256 public constant RESERVATION_STAGE = 3;
    int256 public constant DISTRIBUTION_STAGE = 4;

    // Counter for token IDs
    uint256 private _tokenIdCounter;

    // Counter for pre-minted token IDs
    uint256 private _preMintedTokenIdCounter;

    // number of tokens owned by the contract
    /* solhint-disable state-visibility */
    uint256 _contractBalance;

    address private _adminContract;

    // in wei
    uint256 private _pricePerToken;
    // in wei
    uint256 private _serviceFee;

    string private _defaultTokenURI;

    address _royaltyWallet;
    uint256 _royaltyPercentage;

    // The current art drop stage. It can have the following values:
    //
    //   0: Locked / Read-only mode
    //   2: Selection of the registered wallets (whitelisting)
    //   3: Reservation / Purchase stage
    //   4: Distribution of the tokens / Drop stage
    //
    // * 1 is missing from the above list. That's to keep the off-chain
    //   and on-chain states in sync.
    // * Only admin accounts with a quorum of votes can change the
    //   current stage.
    // * Some functions only work in certain stages.
    // * When the 4th stage (last stage) is finished, the contract
    //   will be put back into locked mode (stage 0).
    // * Admins can only advance/retreat the current stage by movements of +1 or -1.
    int256 private _stage;

    // A mapping from the whitelisted addresses to the maximum number of tokens they can obtain
    mapping(address => uint256) _whitelistedAccounts;

    // Counts the number of whitelisted accounts
    uint256 _whitelistedAccountsCounter;

    // Counts the number of reserved tokens
    uint256 _reservedTokensCounter;

    // Enabled reservations without a need to be whitelisted
    bool _canReserveWithoutBeingWhitelisted;

    // An operator which is allowed to perform certain operations such as adding whitelisted
    // accounts, removing them, or doing the token reservation for credit card payments. These
    // accounts can only be defined by a quorom of votes among admins.
    mapping(address => uint256) _operators;

    event WhitelistedAccountAdded(address doer, address account, uint256 maxNrOfTokensToObtain);
    event WhitelistedAccountRemoved(address doer, address account);
    event PricePerTokenChanged(address doer, uint256 adminTaskId, uint256 oldValue, uint256 newValue);
    event ServiceFeeChanged(address doer, uint256 adminTaskId, uint256 oldValue, uint256 newValue);
    event StageChanged(address doer, uint256 adminTaskId, int256 oldValue, int256 newValue);
    event OperatorAdded(address doer, uint256 adminTaskId, address toBeOperatorAccount);
    event OperatorRemoved(address doer, uint256 adminTaskId, address toBeRemovedOperatorAccount);
    event DefaultTokenURIChanged(address doer, uint256 adminTaskId, string newValue);
    event TokensReserved(address doer, address target, uint256 nrOfTokensToReserve);
    event Deposited(address doer, uint256 priceOfTokens, uint256 serviceFee, uint256 totalValue);
    event Returned(address doer, address target, uint256 returnedValue);
    event Withdrawn(address doer, address target, uint256 amount);
    event TokenURIChanged(address doer, uint256 tokenId, string newValue);
    event GenesisTokenURIChanged(address doer, uint256 adminTaskId, string newValue);
    event RoyaltyWalletChanged(address doer, uint256 adminTaskId, address newRoyaltyWallet);
    event RoyaltyPercentageChanged(address doer, uint256 adminTaskId, uint256 newRoyaltyPercentage);
    event CanReserveWithoutBeingWhitelistedChanged(address doer, uint256 adminTaskId, bool newValue);

    modifier adminApprovalRequired(uint256 adminTaskId) {
        _;
        // This must succeed otherwise the tx gets reverted
        IarteQTaskFinalizer(_adminContract).finalizeTask(msg.sender, adminTaskId);
    }

    modifier onlyLockedStage() {
        require(_stage == LOCKED_STAGE, "arteQArtDrop: only callable in locked stage");
        _;
    }

    modifier onlyWhitelistingStage() {
        require(_stage == WHITELISTING_STAGE, "arteQArtDrop: only callable in whitelisting stage");
        _;
    }

    modifier onlyReservationStage() {
        require(_stage == RESERVATION_STAGE, "arteQArtDrop: only callable in reservation stage");
        _;
    }

    modifier onlyReservationAndDistributionStages() {
        require(_stage == RESERVATION_STAGE || _stage == DISTRIBUTION_STAGE,
                "arteQArtDrop: only callable in reservation and distribution stage");
        _;
    }

    modifier onlyDistributionStage() {
        require(_stage == DISTRIBUTION_STAGE, "arteQArtDrop: only callable in distribution stage");
        _;
    }

    modifier onlyWhenNotLocked() {
        require(_stage > 1, "arteQArtDrop: only callable in not-locked stages");
        _;
    }

    modifier onlyWhenNotInReservationStage() {
        require(_stage != RESERVATION_STAGE, "arteQArtDrop: only callable in a non-reservation stage");
        _;
    }

    modifier onlyOperator() {
        require(_operators[msg.sender] > 0, "arteQArtDrop: not an operator account");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    constructor(
        address adminContract,
        string memory name,
        string memory symbol,
        uint256 initialPricePerToken,
        uint256 initialServiceFee,
        string memory initialDefaultTokenURI,
        string memory initialGenesisTokenURI
    ) ERC721(name, symbol) {

        require(adminContract != address(0), "arteQArtDrop: admin contract cannot be zero");
        require(adminContract.code.length > 0, "arteQArtDrop: non-contract account for admin contract");
        require(initialPricePerToken > 0, "arteQArtDrop: zero initial price per token");
        require(bytes(initialDefaultTokenURI).length > 0, "arteQArtDrop: invalid default token uri");
        require(bytes(initialGenesisTokenURI).length > 0, "arteQArtDrop: invalid genesis token uri");

        _adminContract = adminContract;

        _pricePerToken = initialPricePerToken;
        emit PricePerTokenChanged(msg.sender, 0, 0, _pricePerToken);

        _serviceFee = initialServiceFee;
        emit ServiceFeeChanged(msg.sender, 0, 0, _serviceFee);

        _defaultTokenURI = initialDefaultTokenURI;
        emit DefaultTokenURIChanged(msg.sender, 0, _defaultTokenURI);

        _tokenIdCounter = 1;
        _preMintedTokenIdCounter = 1;
        _contractBalance = 0;

        _whitelistedAccountsCounter = 0;
        _reservedTokensCounter = 0;

        // Contract is locked/read-only by default.
        _stage = 0;
        emit StageChanged(msg.sender, 0, 0, _stage);

        // Mint genesis token. Contract will be the eternal owner of the genesis token.
        _mint(address(0), address(this), 0);
        _setTokenURI(0, initialGenesisTokenURI);
        _contractBalance += 1;
        emit GenesisTokenURIChanged(msg.sender, 0, initialGenesisTokenURI);

        _royaltyWallet = address(this);
        emit RoyaltyWalletChanged(msg.sender, 0, _royaltyWallet);

        _royaltyPercentage = 10;
        emit RoyaltyPercentageChanged(msg.sender, 0, _royaltyPercentage);

        _canReserveWithoutBeingWhitelisted = false;
        emit CanReserveWithoutBeingWhitelistedChanged(msg.sender, 0, _canReserveWithoutBeingWhitelisted);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (_exists(tokenId)) {
            string memory tokenURIValue = super.tokenURI(tokenId);
            if (keccak256(bytes(tokenURIValue)) == keccak256(bytes(DEFAULT_TOKEN_URI))) {
                return _defaultTokenURI;
            }
            return tokenURIValue;
        }
        if (tokenId >= 1 && tokenId < _preMintedTokenIdCounter) {
            return _defaultTokenURI;
        }
        revert("arteQArtDrop: token id does not exist");
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        if (_exists(tokenId)) {
            return super.ownerOf(tokenId);
        }
        if (tokenId >= 1 && tokenId < _preMintedTokenIdCounter) {
            return address(this);
        }
        revert("arteQArtDrop: token is does not exist");
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(this)) {
            return _contractBalance;
        }
        return super.balanceOf(owner);
    }

    function preMint(uint256 nr) external
      onlyOperator {
        for (uint256 i = 0; i < nr; i++) {
            require(_preMintedTokenIdCounter <= MAX_RESERVATIONS_COUNT, "arteQArtDrop: cannot pre-mint more");
            emit Transfer(address(0), address(this), _preMintedTokenIdCounter);
            _preMintedTokenIdCounter += 1;
        }
        _contractBalance += nr;
    }

    function pricePerToken() external view returns (uint256) {
        return _pricePerToken;
    }

    function serviceFee() external view returns (uint256) {
        return _serviceFee;
    }

    function defaultTokenURI() external view returns (string memory) {
        return _defaultTokenURI;
    }

    function nrPreMintedTokens() external view returns (uint256) {
        return _preMintedTokenIdCounter - 1;
    }

    function stage() external view returns (int256) {
        return _stage;
    }

    function royaltyPercentage() external view returns (uint256) {
        return _royaltyPercentage;
    }

    function royaltyWallet() external view returns (address) {
        return _royaltyWallet;
    }

    function nrOfWhitelistedAccounts() external view returns (uint256) {
        return _whitelistedAccountsCounter;
    }

    function nrOfReservedTokens() external view returns (uint256) {
        return _reservedTokensCounter;
    }

    function canReserveWithoutBeingWhitelisted() external view returns (bool) {
        return _canReserveWithoutBeingWhitelisted;
    }

    function setPricePerToken(uint256 adminTaskId, uint256 newValue) external
      onlyWhenNotLocked
      onlyWhenNotInReservationStage
      adminApprovalRequired(adminTaskId) {
        require(newValue > 0, "arteQArtDrop: new price cannot be zero");
        uint256 oldValue = _pricePerToken;
        _pricePerToken = newValue;
        emit PricePerTokenChanged(msg.sender, adminTaskId, oldValue, _pricePerToken);
    }

    function setServiceFee(uint256 adminTaskId, uint256 newValue) external
      onlyWhenNotLocked
      onlyWhenNotInReservationStage
      adminApprovalRequired(adminTaskId) {
        require(newValue > 0, "arteQArtDrop: new price cannot be zero");
        uint256 oldValue = _serviceFee;
        _serviceFee = newValue;
        emit ServiceFeeChanged(msg.sender, adminTaskId, oldValue, _serviceFee);
    }

    function setDefaultTokenURI(uint256 adminTaskId, string memory newValue) external
      onlyWhenNotLocked
      onlyWhenNotInReservationStage
      adminApprovalRequired(adminTaskId) {
        require(bytes(newValue).length > 0, "arteQArtDrop: empty string");
        _defaultTokenURI = newValue;
        emit DefaultTokenURIChanged(msg.sender, adminTaskId, _defaultTokenURI);
    }

    function setGenesisTokenURI(uint256 adminTaskId, string memory newValue) external
      onlyLockedStage
      adminApprovalRequired(adminTaskId) {
        require(bytes(newValue).length > 0, "arteQArtDrop: empty string");
        _setTokenURI(0, newValue);
        emit GenesisTokenURIChanged(msg.sender, adminTaskId, newValue);
    }

    function setRoyaltyWallet(uint256 adminTaskId, address newRoyaltyWallet) external
      adminApprovalRequired(adminTaskId) {
        require(newRoyaltyWallet != address(0), "arteQArtDrop: invalid royalty wallet");
        _royaltyWallet = newRoyaltyWallet;
        emit RoyaltyWalletChanged(msg.sender, adminTaskId, newRoyaltyWallet);
    }

    function setRoyaltyPercentage(uint256 adminTaskId, uint256 newRoyaltyPercentage) external
      adminApprovalRequired(adminTaskId) {
        require(newRoyaltyPercentage >= 0 && newRoyaltyPercentage <= 75, "arteQArtDrop: invalid royalty percentage");
        _royaltyPercentage = newRoyaltyPercentage;
        emit RoyaltyPercentageChanged(msg.sender, adminTaskId, newRoyaltyPercentage);
    }

    function setCanReserveWithoutBeingWhitelisted(uint256 adminTaskId, bool newValue) external
      adminApprovalRequired(adminTaskId) {
        _canReserveWithoutBeingWhitelisted = newValue;
        emit CanReserveWithoutBeingWhitelistedChanged(msg.sender, adminTaskId, newValue);
    }

    function retreatStage(uint256 adminTaskId) external
      adminApprovalRequired(adminTaskId) {
        int256 oldStage = _stage;
        _stage -= 1;
        if (_stage == -1) {
            _stage = 4;
        } else if (_stage == 1) {
            _stage = 0;
        }
        emit StageChanged(msg.sender, adminTaskId, oldStage, _stage);
    }

    function advanceStage(uint256 adminTaskId) external
      adminApprovalRequired(adminTaskId) {
        int256 oldStage = _stage;
        _stage += 1;
        if (_stage == 5) {
            _stage = 0;
        } else if (_stage == 1) {
            _stage = 2;
        }
        emit StageChanged(msg.sender, adminTaskId, oldStage, _stage);
    }

    function addOperator(uint256 adminTaskId, address toBeOperatorAccount) external
      adminApprovalRequired(adminTaskId) {
        require(toBeOperatorAccount != address(0), "arteQArtDrop: cannot set zero as operator");
        require(_operators[toBeOperatorAccount] == 0, "arteQArtDrop: already an operator");
        _operators[toBeOperatorAccount] = 1;
        emit OperatorAdded(msg.sender, adminTaskId, toBeOperatorAccount);
    }

    function removeOperator(uint256 adminTaskId, address toBeRemovedOperatorAccount) external
      adminApprovalRequired(adminTaskId) {
        require(toBeRemovedOperatorAccount != address(0), "arteQArtDrop: cannot remove zero as operator");
        require(_operators[toBeRemovedOperatorAccount] == 1, "arteQArtDrop: not an operator");
        _operators[toBeRemovedOperatorAccount] = 0;
        emit OperatorRemoved(msg.sender, adminTaskId, toBeRemovedOperatorAccount);
    }

    function isOperator(address account) external view returns(bool) {
        return _operators[account] == 1;
    }

    function addToWhitelistedAccounts(
      address[] memory accounts,
      uint[] memory listOfMaxNrOfTokensToObtain
    ) external
      onlyOperator
      onlyWhitelistingStage {
        require(accounts.length > 0, "arteQArtDrop: zero length");
        require(listOfMaxNrOfTokensToObtain.length > 0, "arteQArtDrop: zero length");
        require(accounts.length == listOfMaxNrOfTokensToObtain.length, "arteQArtDrop: different lengths");
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 maxNrOfTokensToObtain = listOfMaxNrOfTokensToObtain[i];

            require(account != address(0), "arteQArtDrop: cannot whitelist zero address");
            require(maxNrOfTokensToObtain >= 1 && maxNrOfTokensToObtain <= MAX_NR_TOKENS_PER_ACCOUNT,
                "arteQArtDrop: invalid nr of tokens to obtain");
            require(account.code.length == 0, "arteQArtDrop: cannot whitelist a contract");
            require(_whitelistedAccounts[account] == 0, "arteQArtDrop: already whitelisted");

            _whitelistedAccounts[account] = maxNrOfTokensToObtain;
            _whitelistedAccountsCounter += 1;

            emit WhitelistedAccountAdded(msg.sender, account, maxNrOfTokensToObtain);
        }
    }

    function removeFromWhitelistedAccounts(address[] memory accounts) external
      onlyOperator
      onlyWhitelistingStage {
        require(accounts.length > 0, "arteQArtDrop: zero length");
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];

            require(account != address(0), "arteQArtDrop: cannot remove zero address");
            require(_whitelistedAccounts[account] > 0, "arteQArtDrop: account is not whitelisted");

            _whitelistedAccounts[account] = 0;
            _whitelistedAccountsCounter -= 1;

            emit WhitelistedAccountRemoved(msg.sender, account);
        }
    }

    function whitelistedNrOfTokens(address account) external view returns (uint256) {
        if (!_canReserveWithoutBeingWhitelisted) {
            return _whitelistedAccounts[account];
        }
        if (_whitelistedAccounts[account] == 0) {
            return MAX_NR_TOKENS_PER_ACCOUNT;
        }
        return _whitelistedAccounts[account];
    }

    // Only callable by a whitelisted account
    //
    // * Account must have sent enough ETH to cover the price of all tokens + service fee
    // * Account cannot reserve more than what has been whitelisted for
    function reserveTokens(uint256 nrOfTokensToReserve) external payable
      onlyReservationAndDistributionStages {
        require(msg.value > 0, "arteQArtDrop: zero funds");
        require(nrOfTokensToReserve > 0, "arteQArtDrop: zero tokens to reserve");

        if (_canReserveWithoutBeingWhitelisted && _whitelistedAccounts[msg.sender] == 0) {
            _whitelistedAccounts[msg.sender] = 5;
        }

        require(_whitelistedAccounts[msg.sender] > 0, "arteQArtDrop: not a whitelisted account");
        require(nrOfTokensToReserve <= _whitelistedAccounts[msg.sender],
              "arteQArtDrop: exceeding the reservation allowance");
        require((_reservedTokensCounter + nrOfTokensToReserve) <= MAX_RESERVATIONS_COUNT,
                "arteQArtDrop: exceeding max number of reservations");

        // Handle payments
        uint256 priceOfTokens = nrOfTokensToReserve * _pricePerToken;
        uint256 priceToPay = priceOfTokens + _serviceFee;
        require(msg.value >= priceToPay, "arteQArtDrop: insufficient funds");
        uint256 remainder = msg.value - priceToPay;
        if (remainder > 0) {
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = msg.sender.call{value: remainder}(new bytes(0));
            /* solhint-enable avoid-low-level-calls */
            require(success, "arteQArtDrop: failed to send the remainder");
            emit Returned(msg.sender, msg.sender, remainder);
        }
        emit Deposited(msg.sender, priceOfTokens, _serviceFee, priceToPay);

        _reserveTokens(msg.sender, nrOfTokensToReserve);
    }

    // This method is called by an operator to complete the reservation of fiat payments
    // such as credit card, iDeal, etc.
    function reserveTokensForAccounts(
      address[] memory accounts,
      uint256[] memory listOfNrOfTokensToReserve
    ) external
      onlyOperator
      onlyReservationAndDistributionStages {
        require(accounts.length > 0, "arteQArtDrop: zero length");
        require(listOfNrOfTokensToReserve.length > 0, "arteQArtDrop: zero length");
        require(accounts.length == listOfNrOfTokensToReserve.length, "arteQArtDrop: different lengths");
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 nrOfTokensToReserve = listOfNrOfTokensToReserve[i];

            require(account != address(0), "arteQArtDrop: cannot be zero address");

            if (_canReserveWithoutBeingWhitelisted && _whitelistedAccounts[account] == 0) {
                _whitelistedAccounts[account] = 5;
            }

            require(_whitelistedAccounts[account] > 0, "arteQArtDrop: not a whitelisted account");
            require(nrOfTokensToReserve <= _whitelistedAccounts[account],
                  "arteQArtDrop: exceeding the reservation allowance");

            _reserveTokens(account, nrOfTokensToReserve);
        }
    }

    function updateTokenURIs(uint256[] memory tokenIds, string[] memory newTokenURIs) external
      onlyOperator
      onlyDistributionStage {
        require(tokenIds.length > 0, "arteQArtDrop: zero length");
        require(newTokenURIs.length > 0, "arteQArtDrop: zero length");
        require(tokenIds.length == newTokenURIs.length, "arteQArtDrop: different lengths");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            string memory newTokenURI = newTokenURIs[i];

            require(tokenId > 0, "arteQArtDrop: cannot alter genesis token");
            require(bytes(newTokenURI).length > 0, "arteQArtDrop: empty string");

            _setTokenURI(tokenId, newTokenURI);
            emit TokenURIChanged(msg.sender, tokenId, newTokenURI);
        }
    }

    function transferTo(address target, uint256 amount) external
      onlyOperator {
        require(target != address(0), "arteQArtDrop: target cannot be zero");
        require(amount > 0, "arteQArtDrop: cannot transfer zero");
        require(amount <= address(this).balance, "arteQArtDrop: transfer more than balance");

        /* solhint-disable avoid-low-level-calls */
        (bool success, ) = target.call{value: amount}(new bytes(0));
        /* solhint-enable avoid-low-level-calls */
        require(success, "arteQArtDrop: failed to transfer");

        emit Withdrawn(msg.sender, target, amount);
    }

    function royaltyInfo(uint256, uint256 salePrice) external view virtual override returns (address, uint256) {
        uint256 royalty = (salePrice * _royaltyPercentage) / 100;
        return (_royaltyWallet, royalty);
    }

    function _reserveTokens(address target, uint256 nrOfTokensToReserve) internal {
        for (uint256 i = 1; i <= nrOfTokensToReserve; i++) {
            uint256 newTokenId = _tokenIdCounter;
            _mint(address(this), target, newTokenId);
            _setTokenURI(newTokenId, DEFAULT_TOKEN_URI);
            _tokenIdCounter += 1;
            require(_reservedTokensCounter <= MAX_RESERVATIONS_COUNT,
                    "arteQArtDrop: exceeding max number of reservations");
            _reservedTokensCounter += 1;
        }
        if ((_contractBalance - 1) > nrOfTokensToReserve) {
            _contractBalance -= nrOfTokensToReserve;
        } else {
            _contractBalance = 1; // eventually, the contract must only own the genesis token
        }
        require(_contractBalance >= 1, "arteQArtDrop: contract balance went below 1");
        _whitelistedAccounts[target] -= nrOfTokensToReserve;
        require(_whitelistedAccounts[target] >= 0, "arteQArtDrop: should not happen");
        emit TokensReserved(msg.sender, target, nrOfTokensToReserve);
    }

    receive() external payable {
        revert("arteQArtDrop: cannot accept ether");
    }

    fallback() external payable {
        revert("arteQArtDrop: cannot accept ether");
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0
// Based on OpenZeppelin Contracts v4.3.2 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity 0.8.1;

import "./ERC721.sol";

 /**
  * @author Modified by Kam Amini <[email protected]> <[email protected]>
  *
  * @notice Use at your own risk
  *
  * Note: The original contract has been modified to cover the needs as
  *       part of artèQ Investment Fund ecosystem
  *
  * @dev ERC721 token with storage based token URI management.
  */

/* solhint-disable reason-string */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/* solhint-disable contract-name-camelcase */
contract arteQCollection is ERC721URIStorage, IERC2981 {

    uint256 private _tokenIdCounter;
    bool private _publicMinting;
    uint16 private _adminCounter;

    mapping (address => uint8) private _admins;
    mapping (address => uint8) private _minters;

    address private _defaultRoyaltyWallet;
    uint256 private _defaultRoyaltyPercentage;
    mapping (uint256 => address) private _royaltyWallets;
    mapping (uint256 => uint256) private _royaltyPercentages;
    mapping (uint256 => uint8) private _royaltyExempts;

    event AdminAdded(address newAdmin);
    event AdminRemoved(address removedAdmin);
    event MinterAdded(address newMinter);
    event MinterRemoved(address removedMinter);
    event PublicMintingChanged(bool newValue);
    event TokenURIChanged(uint256 tokenId);
    event RoyaltyWalletChanged(uint256 tokenId, address newWallet);
    event RoyaltyPercentageChanged(uint256 tokenId, uint256 newValue);
    event DefaultRoyaltyWalletChanged(address newWallet);
    event DefaultRoyaltyPercentageChanged(uint256 newValue);
    event TokenRoyaltyInfoChanged(uint256 tokenId, address royaltyWallet, uint256 royaltyPercentage);
    event TokenAddedToExemptionList(uint256 tokenId);
    event TokenRemovedFromExemptionList(uint256 tokenId);

    modifier onlyAdmin {
        require(_admins[msg.sender] == 1, "arteQCollection: must be admin");
        _;
    }

    modifier onlyMinter {
        require(_publicMinting || _minters[msg.sender] == 1, "arteQCollection: must be minter");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    constructor(
        string memory name,
        string memory symbol,
        address admin2,
        address admin3,
        address initDefaultRoyaltyWallet,
        uint256 initDefaultRoyaltyPercentage
    ) ERC721(name, symbol) {

        _tokenIdCounter = 1;

        _publicMinting = false;
        emit PublicMintingChanged(false);

        _adminCounter = 0;

        _safeAddAdmin(msg.sender);
        _safeAddAdmin(admin2);
        _safeAddAdmin(admin3);

        _addMinter(msg.sender);

        _defaultRoyaltyWallet = initDefaultRoyaltyWallet;
        emit DefaultRoyaltyWalletChanged(_defaultRoyaltyWallet);

        _defaultRoyaltyPercentage = initDefaultRoyaltyPercentage;
        emit DefaultRoyaltyPercentageChanged(_defaultRoyaltyPercentage);
    }

    function isAdmin(address account) external view returns (bool) {
        return _admins[account] == 1;
    }

    function nrAdmins() external view returns (uint16) {
        return _adminCounter;
    }

    function addAdmin(address newAdmin) external onlyAdmin {
        _safeAddAdmin(newAdmin);
    }

    function removeAdmin(address toBeRemovedAdmin) external onlyAdmin {
        _removeAdmin(toBeRemovedAdmin);
    }

    function isMinter(address account) external view returns (bool) {
        return _minters[account] == 1;
    }

    function addMinter(address newMinter) external onlyAdmin {
        require(_minters[newMinter] == 0, "arteQCollection: already a minter");
        _addMinter(newMinter);
    }

    function removeMinter(address toBeRemovedMinter) external onlyAdmin {
        require(_minters[toBeRemovedMinter] == 1, "arteQCollection: not a minter");
        _removeMinter(toBeRemovedMinter);
    }

    function publicMinting() external view returns (bool) {
        return _publicMinting;
    }

    function setPublicMinting(bool newValue) external onlyAdmin {
        bool isThisAChange = (newValue != _publicMinting);
        _publicMinting = newValue;
        if (isThisAChange) {
            emit PublicMintingChanged(newValue);
        }
    }

    function defaultRoyaltyWallet() external view returns (address) {
        return _defaultRoyaltyWallet;
    }

    // set zero address to disable default roylaties
    function setDefaultRoyaltyWallet(address newDefaultRoyaltyWallet) external onlyAdmin {
        _defaultRoyaltyWallet = newDefaultRoyaltyWallet;
        emit DefaultRoyaltyWalletChanged(newDefaultRoyaltyWallet);
    }

    function defaultRoyaltyPercentage() external view returns (uint256) {
        return _defaultRoyaltyPercentage;
    }

    // Set to zero in order to disable default royalties. Still, settings set per token work.
    function setDefaultRoyaltyPercentage(uint256 newDefaultRoyaltyPercentage) external onlyAdmin {
        require(newDefaultRoyaltyPercentage >= 0 && newDefaultRoyaltyPercentage <= 50,
                "arteQCollection: wrong percentage");
        _defaultRoyaltyPercentage = newDefaultRoyaltyPercentage;
        emit DefaultRoyaltyPercentageChanged(newDefaultRoyaltyPercentage);
    }

    function addTokenToRoyaltyExemptionList(uint256 tokenId) external onlyAdmin {
        require(_exists(tokenId), "arteQCollection: non-existing token");
        require(_royaltyExempts[tokenId] == 0, "arteQCollection: already exempt");
        _royaltyExempts[tokenId] = 1;
        emit TokenAddedToExemptionList(tokenId);
    }

    function removeTokenFromRoyaltyExemptionList(uint256 tokenId) external onlyAdmin {
        require(_exists(tokenId), "arteQCollection: non-existing token");
        require(_royaltyExempts[tokenId] == 1, "arteQCollection: not in exemption list");
        _royaltyExempts[tokenId] = 0;
        emit TokenRemovedFromExemptionList(tokenId);
    }

    function setTokenRoyaltyInfo(uint256 tokenId, address royaltyWallet, uint256 royaltyPercentage)
      external onlyAdmin {
        require(_exists(tokenId), "arteQCollection: non-existing token");
        require(royaltyPercentage >= 0 && royaltyPercentage <= 50,
                "arteQCollection: wrong percentage");
        _royaltyWallets[tokenId] = royaltyWallet;
        _royaltyPercentages[tokenId] = royaltyPercentage;
        emit TokenRoyaltyInfoChanged(tokenId, royaltyWallet, royaltyPercentage);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
      external view virtual override returns (address, uint256) {
        require(_exists(tokenId), "arteQCollection: non-existing token");
        if (_royaltyExempts[tokenId] == 1) {
            return (address(0), 0);
        }
        address royaltyWallet = _royaltyWallets[tokenId];
        uint256 royaltyPercentage = _royaltyPercentages[tokenId];
        if (royaltyWallet == address(0) || royaltyPercentage == 0) {
            royaltyWallet = _defaultRoyaltyWallet;
            royaltyPercentage = _defaultRoyaltyPercentage;
        }
        if (royaltyWallet == address(0) || royaltyPercentage == 0) {
            return (address(0), 0);
        }
        uint256 royalty = (salePrice * royaltyPercentage) / 100;
        return (royaltyWallet, royalty);
    }

    function mint(string memory uri) external onlyMinter {
        _safeMintTo(msg.sender, uri);
    }

    function batchMint(string[] memory uris) external onlyMinter {
        for (uint256 i = 0; i < uris.length; i++) {
            string memory uri = uris[i];
            _safeMintTo(msg.sender, uri);
        }
    }

    function mintTo(address owner, string memory uri) external onlyMinter {
        _safeMintTo(owner, uri);
    }

    function batchMintTo(address owner, string[] memory uris) external onlyMinter {
        for (uint256 i = 0; i < uris.length; i++) {
            string memory uri = uris[i];
            _safeMintTo(owner, uri);
        }
    }

    function updateTokenURI(uint256 tokenId, string memory uri) external onlyAdmin {
        require(bytes(uri).length > 0, "arteQCollection: empty uri");
        _setTokenURI(tokenId, uri);
        emit TokenURIChanged(tokenId);
    }

    function batchUpdateTokenURI(uint256[] memory tokenIds, string[] memory uris) external onlyAdmin {
        require(tokenIds.length == uris.length, "arteQCollection: lengths do not match");
        for (uint256 i = 0; i < uris.length; i++) {
            uint256 tokenId = tokenIds[i];
            string memory uri = uris[i];
            require(bytes(uri).length > 0, "arteQCollection: empty uri");
            _setTokenURI(tokenId, uri);
            emit TokenURIChanged(tokenId);
        }
    }

    function burn(uint256 tokenId) external onlyAdmin {
        _burn(tokenId);
    }

    function _safeAddAdmin(address newAdmin) internal {
        require(newAdmin != address(0), "arteQCollection: cannot use zero address");
        require(_admins[newAdmin] == 0, "arteQCollection: already an admin");
        _admins[newAdmin] = 1;
        _adminCounter += 1;
        emit AdminAdded(newAdmin);
    }

    function _removeAdmin(address toBeRemovedAdmin) internal {
        require(_adminCounter > 1, "arteQCollection: no more admin can be removed");
        require(_admins[toBeRemovedAdmin] == 1, "arteQCollection: not an admin");
        _admins[toBeRemovedAdmin] = 0;
        _adminCounter -= 1;
        emit AdminRemoved(toBeRemovedAdmin);
    }

    function _addMinter(address newMinter) internal {
        _minters[newMinter] = 1;
        emit MinterAdded(newMinter);
    }

    function _removeMinter(address toBeRemovedMinter) internal {
        _minters[toBeRemovedMinter] = 0;
        emit MinterRemoved(toBeRemovedMinter);
    }

    function _safeMintTo(address owner, string memory uri) internal {
        require(bytes(uri).length > 0, "arteQCollection: empty uri");
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter += 1;
        _safeMint(owner, tokenId);
        _setTokenURI(tokenId, uri);
        emit TokenURIChanged(tokenId);
    }

    receive() external payable {
        revert("arteQCollection: cannot accept ether");
    }

    fallback() external payable {
        revert("arteQCollection: cannot accept ether");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TestERC1155 is ERC1155 {

    uint256 private _tokenIdCounter;

    constructor() ERC1155("https://token/{id}") {
        _mint(msg.sender, 1, 1000, "");
        _mint(msg.sender, 2, 5000, "");
        // 1 & 2 are reserved for two fungible tokens
        _tokenIdCounter = 3;
    }

    function mintToken(address owner) public {
        _mint(owner, _tokenIdCounter, 1, "");
        _tokenIdCounter += 1;
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TestERC721 is ERC721URIStorage {

    uint256 private _tokenIdCounter;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _tokenIdCounter = 1;
    }

    function mintNFT(address owner, string memory tokenURI) public {
        _mint(owner, _tokenIdCounter);
        _setTokenURI(_tokenIdCounter, tokenURI);
        _tokenIdCounter += 1;
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../security/task-executor/TaskExecutorLib.sol";
import "./AccountLockerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract AccountLockerFacet {

    function updateLockTs(
        uint256 taskId,
        address[] memory accounts,
        uint256[] memory lockTss
    ) external {
        require(accounts.length == lockTss.length, "ALF:WL");
        require(accounts.length > 0, "ALF:EI");
        for (uint256 i = 0; i < accounts.length; i++) {
            AccountLockerInternal._updateLockTs(accounts[i], lockTss[i]);
        }
        TaskExecutorLib._executeTask(taskId);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./AccountLockerStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library AccountLockerInternal {

    event LockTsChanged(address account, uint256 lockTimestamp);

    function _getLockTs(address account) internal view returns (uint256) {
        return __s().lockedAccounts[account];
    }

    function _updateLockTs(address account, uint256 lockTs) internal {
        uint256 oldLockTs = __s().lockedAccounts[account];
        __s().lockedAccounts[account] = lockTs;
        if (oldLockTs != lockTs) {
            emit LockTsChanged(account, lockTs);
        }
    }

    function _isLocked(address account) internal view returns (bool) {
        uint256 lockTs = _getLockTs(account);
        /* solhint-disable not-rely-on-time */
        return lockTs > 0 && block.timestamp <= lockTs;
    }

    function __s() private pure returns (AccountLockerStorage.Layout storage) {
        return AccountLockerStorage.layout();
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library AccountLockerStorage {

    struct Layout {
        mapping (address => uint256) lockedAccounts;
        mapping(uint256 => uint256) extra;
    }

    // Storage Slot: 3098ce16a8ed1f68ea20f7694311e285057a167791ff47ba6baf41ca0c4e98a0
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-tech.contracts.account-locker.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../diamond/Diamond.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TestDiamond is Diamond {

    /* solhint-disable no-empty-blocks */
    constructor(
        address taskManager,
        address[] memory diamondAdmins
    ) Diamond(
        taskManager,
        diamondAdmins,
        "test-diamond",
        address(0)
    ) {}

    /* solhint-disable no-complex-fallback */
    fallback() external payable {
        address facet = _findFacet(msg.sig);
        /* solhint-disable no-inline-assembly */
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
        /* solhint-enable no-inline-assembly */
    }

    receive() external payable {}
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../security/role-manager/RoleManagerLib.sol";
import "../../diamond/IDiamondFacet.sol";
import "../IAppRegistry.sol";
import "./AppRegistryInternal.sol";
import "./AppRegistryConfig.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract AppRegistryFacet is IDiamondFacet, IAppRegistry {

    modifier onlyAppRegistryAdmin() {
        RoleManagerLib._checkRole(AppRegistryConfig.ROLE_APP_REGISTRY_ADMIN);
        _;
    }

    function getFacetName() external pure override returns (string memory) {
        return "app-registry";
    }

    function getFacetVersion() external pure override returns (string memory) {
        return "0.0.1";
    }

    function getFacetPI() external pure override returns (string[] memory) {
        string[] memory pi = new string[](6);
        pi[0] = "getAllApps()";
        pi[1] = "getEnabledApps()";
        pi[2] = "isAppEnabled(string,string)";
        pi[3] = "addApp(string,string,address[],bool)";
        pi[4] = "enableApp(string,string,bool)";
        pi[5] = "getAppFacets(string,string)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external view override virtual returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId ||
               interfaceId == type(IAppRegistry).interfaceId;
    }

    function getAllApps() external view onlyAppRegistryAdmin returns (string[] memory) {
        return AppRegistryInternal._getAllApps();
    }

    function getEnabledApps() external view onlyAppRegistryAdmin returns (string[] memory) {
        return AppRegistryInternal._getEnabledApps();
    }

    function isAppEnabled(
        string memory name,
        string memory version
    ) external view onlyAppRegistryAdmin returns (bool) {
        return AppRegistryInternal._isAppEnabled(name, version);
    }

    function addApp(
        string memory name,
        string memory version,
        address[] memory facets,
        bool enabled
    ) external onlyAppRegistryAdmin {
        return AppRegistryInternal._addApp(name, version , facets, enabled);
    }

    // NOTE: This is the only mutator for the app entries
    function enableApp(
        string memory name,
        string memory version,
        bool enabled
    ) external onlyAppRegistryAdmin {
        return AppRegistryInternal._enableApp(name, version, enabled);
    }

    function getAppFacets(
        string memory name,
        string memory version
    ) external view override returns (address[] memory) {
        return AppRegistryInternal._getAppFacets(name, version);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./AppRegistryStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library AppRegistryInternal {

    function _appExists(string memory name, string memory version) internal view returns (bool) {
        bytes32 nvh = __getNameVersionHash(name, version);
        return __getStrLen(__s().apps[nvh].name) > 0 &&
               __getStrLen(__s().apps[nvh].version) > 0;
    }

    function _getAllApps() internal view returns (string[] memory) {
        string[] memory apps = new string[](__s().appsArray.length);
        uint256 index = 0;
        for (uint256 i = 0; i < __s().appsArray.length; i++) {
            (string memory name, string memory version) = __deconAppArrayEntry(i);
            bytes32 nvh = __getNameVersionHash(name, version);
            if (__s().apps[nvh].enabled) {
                apps[index] = string(abi.encode("E:", name, ":", version));
            } else {
                apps[index] = string(abi.encode("D:", name, ":", version));
            }
            index += 1;
        }
        return apps;
    }

    function _getEnabledApps() internal view returns (string[] memory) {
        uint256 count = 0;
        {
            for (uint256 i = 0; i < __s().appsArray.length; i++) {
                (string memory name, string memory version) = __deconAppArrayEntry(i);
                bytes32 nvh = __getNameVersionHash(name, version);
                if (__s().apps[nvh].enabled) {
                    count += 1;
                }
            }
        }
        string[] memory apps = new string[](count);
        {
            uint256 index = 0;
            for (uint256 i = 0; i < __s().appsArray.length; i++) {
                (string memory name, string memory version) = __deconAppArrayEntry(i);
                bytes32 nvh = __getNameVersionHash(name, version);
                if (__s().apps[nvh].enabled) {
                    apps[index] = string(abi.encode(name, ":", version));
                    index += 1;
                }
            }
        }
        return apps;
    }

    function _isAppEnabled(
        string memory name,
        string memory version
    ) internal view returns (bool) {
        require(_appExists(name, version), "AREG:ANF");
        bytes32 nvh = __getNameVersionHash(name, version);
        return (__s().apps[nvh].enabled);
    }

    function _addApp(
        string memory name,
        string memory version,
        address[] memory facets,
        bool enabled
    ) internal {
        require(facets.length > 0, "AREG:ZLEN");
        require(!_appExists(name, version), "AREG:AEX");

        __validateString(name);
        __validateString(version);

        // update apps entry
        bytes32 nvh = __getNameVersionHash(name, version);
        __s().apps[nvh].name = name;
        __s().apps[nvh].version = version;
        __s().apps[nvh].enabled = enabled;
        for (uint256 i = 0; i < facets.length; i++) {
            address facet = facets[i];
            __s().apps[nvh].facets.push(facet);
        }

        // update apps array
        bytes memory toAdd = abi.encode([name], [version]);
        __s().appsArray.push(toAdd);
    }

    // NOTE: This is the only mutator for the app entries
    function _enableApp(string memory name, string memory version, bool enabled) internal {
        require(_appExists(name, version), "AREG:ANF");
        bytes32 nvh = __getNameVersionHash(name, version);
        __s().apps[nvh].enabled = enabled;
    }

    function _getAppFacets(
        string memory appName,
        string memory appVersion
    ) internal view returns (address[] memory) {
        require(_appExists(appName, appVersion), "AREG:ANF");
        bytes32 nvh = __getNameVersionHash(appName, appVersion);
        return __s().apps[nvh].facets;
    }

    function __validateString(string memory str) private pure {
        bytes memory strBytes = bytes(str);
        for (uint256 i = 0; i < strBytes.length; i++) {
            bytes1 b = strBytes[i];
            if (
                !(b >= 0x30 && b <= 0x39) && // [0-9]
                !(b >= 0x41 && b <= 0x5a) && // [A-Z]
                !(b >= 0x61 && b <= 0x7a) && // [a-z]
                 b != 0x21 && // !
                 b != 0x23 && // #
                 b != 0x24 && // $
                 b != 0x25 && // %
                 b != 0x26 && // &
                 b != 0x28 && // (
                 b != 0x29 && // )
                 b != 0x2a && // *
                 b != 0x2b && // +
                 b != 0x2c && // ,
                 b != 0x2d && // -
                 b != 0x2e && // .
                 b != 0x3a && // =
                 b != 0x3d && // =
                 b != 0x3f && // ?
                 b != 0x3b && // ;
                 b != 0x40 && // @
                 b != 0x5e && // ^
                 b != 0x5f && // _
                 b != 0x5b && // [
                 b != 0x5d && // ]
                 b != 0x7b && // {
                 b != 0x7d && // }
                 b != 0x7e    // ~
            ) {
                revert("AREG:ISTR");
            }
        }
    }

    function __getStrLen(string memory str) private pure returns (uint256) {
        return bytes(str).length;
    }

    function __deconAppArrayEntry(uint256 index) private view returns (string memory, string memory) {
        (string[] memory names, string[] memory versions) =
            abi.decode(__s().appsArray[index], (string[], string[]));
        string memory name = names[0];
        string memory version = versions[0];
        return (name, version);
    }

    function __getNameVersionHash(string memory name, string memory version) private pure returns (bytes32) {
        return bytes32(keccak256(abi.encode(name, ":", version)));
    }

    function __s() private pure returns (AppRegistryStorage.Layout storage) {
        return AppRegistryStorage.layout();
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library AppRegistryConfig {

    uint256 constant public ROLE_APP_REGISTRY_ADMIN = uint256(keccak256(bytes("ROLE_REGISTRY_APP_ADMIN")));
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library AppRegistryStorage {

    struct AppEntry {
        string name;
        string version;
        bool enabled;
        address[] facets;
    }

    struct Layout {
        bytes[] appsArray;
        mapping(bytes32 => AppEntry) apps;
        mapping(uint256 => uint256) extra;
    }

    // Storage Slot: 67a6ead130f0dfb923ec9a2a7be97c6bf664f01dabfb954c97d300adcbd7528d
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-tech.contracts.app-registry.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../diamond/Diamond.sol";
import "./facet/AppRegistryConfig.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract AppRegistry is Diamond {

    constructor(
        string memory name,
        address taskManager,
        address[] memory diamondAdmins,
        address[] memory appRegistryAdmins
    ) Diamond(
        taskManager,
        diamondAdmins,
        name,
        address(0)
    ) {
        for (uint256 i = 0; i < appRegistryAdmins.length; i++) {
            RoleManagerLib._grantRole(appRegistryAdmins[i], AppRegistryConfig.ROLE_APP_REGISTRY_ADMIN);
        }
    }

    /* solhint-disable no-complex-fallback */
    fallback() external payable {
        address facet = _findFacet(msg.sig);
        /* solhint-disable no-inline-assembly */
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
        /* solhint-enable no-inline-assembly */
    }

    /* solhint-disable no-empty-blocks */
    receive() external payable {}
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./IarteQTaskFinalizer.sol";

/// @author Kam Amini <[email protected]> <[email protected]>
///
/// @title The interface of the admin contract controlling all other artèQ smart contracts
interface IarteQAdmin is IarteQTaskFinalizer {

    event TaskCreated(address creatorAdmin, uint256 taskId, string detailsURI);
    event TaskApproved(address approverAdmin, uint256 taskId);
    event TaskApprovalCancelled(address cancellerAdmin, uint256 taskId);
    event FinalizerAdded(address granter, address newFinalizer);
    event FinalizerRemoved(address revoker, address removedFinalizer);
    event AdminAdded(address granter, address newAdmin);
    event AdminReplaced(address replacer, address removedAdmin, address replacedAdmin);
    event AdminRemoved(address revoker, address removedAdmin);
    event NewMinRequiredNrOfApprovalsSet(address setter, uint minRequiredNrOfApprovals);

    function minNrOfAdmins() external view returns (uint);
    function maxNrOfAdmins() external view returns (uint);
    function nrOfAdmins() external view returns (uint);
    function minRequiredNrOfApprovals() external view returns (uint);

    function isFinalizer(address account) external view returns (bool);
    function addFinalizer(uint256 taskId, address toBeAdded) external;
    function removeFinalizer(uint256 taskId, address toBeRemoved) external;

    function createTask(string memory detailsURI) external;
    function taskURI(uint256 taskId) external view returns (string memory);
    function approveTask(uint256 taskId) external;
    function cancelTaskApproval(uint256 taskId) external;
    function nrOfApprovals(uint256 taskId) external view returns (uint);

    function isAdmin(address account) external view returns (bool);
    function addAdmin(uint256 taskId, address toBeAdded) external;
    function replaceAdmin(uint256 taskId, address toBeRemoved, address toBeReplaced) external;
    function removeAdmin(uint256 taskId, address toBeRemoved) external;
    function setMinRequiredNrOfApprovals(uint256 taskId, uint newMinRequiredNrOfApprovals) external;
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./IarteQAdmin.sol";

/// @author Kam Amini <[email protected]> <[email protected]>
///
/// @title The admin contract managing all other artèQ contracts
///
/// We achieve the followings by using this contract as the admin
/// account of any other artèQ contract:
///
/// 1) If one or two of the admin private keys are leaked out, other
///    admins can remove or replace the affected admin accounts.
///
/// 2) The contract having this account set as its admin account
///    cannot perform any adminitrative task without gathering
///    enough approvals from all admins (more than 50% of the admins
///    must approve a task).
///
///  3) With enough events emitted by this contract, any misuse of
///     administrative powers or a malicious behavior can be easily
///     tracked down, and if all other admins agree, the offender
///     account can get removed or replaced.
///
/// @notice Use at your own risk

/* solhint-disable reason-string */
/* solhint-disable contract-name-camelcase */
contract arteQAdmin is IarteQAdmin {

    /* solhint-disable var-name-mixedcase */
    uint public MAX_NR_OF_ADMINS = 10;
    uint public MIN_NR_OF_ADMINS = 5;

    mapping (address => uint) private _admins;
    mapping (address => uint) private _finalizers;

    mapping (uint256 => uint) private _tasks;
    mapping (uint256 => mapping(address => uint)) private _taskApprovals;
    mapping (uint256 => uint) private _taskApprovalsCount;
    mapping (uint256 => string) private _taskURIs;

    uint private _nrOfAdmins;
    uint private _minRequiredNrOfApprovals;
    uint256 private _taskIdCounter;

    modifier onlyOneOfAdmins() {
        require(_admins[msg.sender] == 1, "arteQAdmin: not an admin account");
        _;
    }

    modifier onlyFinalizer() {
        require(_finalizers[msg.sender] == 1, "arteQAdmin: not a finalizer account");
        _;
    }

    modifier taskMustExist(uint256 taskId) {
        require(_tasks[taskId] == 1, "arteQAdmin: task does not exist");
        _;
    }

    modifier mustBeOneOfAdmins(address account) {
        require(_admins[account] == 1, "arteQAdmin: not an admin account");
        _;
    }

    modifier taskMustBeApproved(uint256 taskId) {
        require(_taskApprovalsCount[taskId] >= _minRequiredNrOfApprovals, "arteQAdmin: task is not approved");
        _;
    }

    constructor(address[] memory initialAdmins) {
        require(initialAdmins.length >= MIN_NR_OF_ADMINS, "arteQAdmin: not enough inital admins");
        require(initialAdmins.length <= MAX_NR_OF_ADMINS, "arteQAdmin: max nr of admins exceeded");
        _nrOfAdmins = 0;
        for (uint i = 0; i < initialAdmins.length; i++) {
            address admin = initialAdmins[i];
            _admins[admin] = 1;
            _nrOfAdmins++;
            emit AdminAdded(msg.sender, admin);
        }

        _minRequiredNrOfApprovals = 1 + uint(initialAdmins.length) / uint(2);
        emit NewMinRequiredNrOfApprovalsSet(msg.sender, _minRequiredNrOfApprovals);

        _taskIdCounter = 1;
    }

    function minNrOfAdmins() external view virtual override returns (uint) {
        return MIN_NR_OF_ADMINS;
    }

    function maxNrOfAdmins() external view virtual override returns (uint) {
        return MAX_NR_OF_ADMINS;
    }

    function nrOfAdmins() external view virtual override returns (uint) {
        return _nrOfAdmins;
    }

    function minRequiredNrOfApprovals() external view virtual override returns (uint) {
        return _minRequiredNrOfApprovals;
    }

    function isFinalizer(address account) external view virtual override onlyOneOfAdmins returns (bool) {
        return _finalizers[account] == 1;
    }

    function addFinalizer(uint256 taskId, address toBeAdded) external virtual override
      onlyOneOfAdmins
      taskMustExist(taskId)
      taskMustBeApproved(taskId) {
        require(_finalizers[toBeAdded] == 0, "arteQAdmin: already a finalizer account");
        _finalizers[toBeAdded] = 1;
        emit FinalizerAdded(msg.sender, toBeAdded);
        // finalize task
        _tasks[taskId] = 0;
        emit TaskFinalized(msg.sender, msg.sender, taskId);
    }

    function removeFinalizer(uint256 taskId, address toBeRemoved) external virtual override
      onlyOneOfAdmins
      taskMustExist(taskId)
      taskMustBeApproved(taskId) {
        require(_finalizers[toBeRemoved] == 1, "arteQAdmin: not a finalizer account");
        _finalizers[toBeRemoved] = 0;
        emit FinalizerRemoved(msg.sender, toBeRemoved);
        // finalize task
        _tasks[taskId] = 0;
        emit TaskFinalized(msg.sender, msg.sender, taskId);
    }

    function createTask(string memory detailsURI) external virtual override onlyOneOfAdmins {
        uint256 taskId = _taskIdCounter;
        _taskIdCounter++;
        _tasks[taskId] = 1;
        _taskApprovalsCount[taskId] = 0;
        _taskURIs[taskId] = detailsURI;
        emit TaskCreated(msg.sender, taskId, detailsURI);
    }

    function taskURI(uint256 taskId)
      external view virtual override onlyOneOfAdmins taskMustExist(taskId) returns (string memory) {
        return _taskURIs[taskId];
    }

    function approveTask(uint256 taskId) external virtual override onlyOneOfAdmins taskMustExist(taskId) {
        require(_taskApprovals[taskId][msg.sender] == 0, "arteQAdmin: already approved");
        _taskApprovals[taskId][msg.sender] = 1;
        _taskApprovalsCount[taskId]++;
        emit TaskApproved(msg.sender, taskId);
    }

    function cancelTaskApproval(uint256 taskId) external virtual override onlyOneOfAdmins taskMustExist(taskId) {
        require(_taskApprovals[taskId][msg.sender] == 1, "arteQAdmin: no approval to cancel");
        _taskApprovals[taskId][msg.sender] = 0;
        _taskApprovalsCount[taskId]--;
        emit TaskApprovalCancelled(msg.sender, taskId);
    }

    function nrOfApprovals(uint256 taskId)
      external view virtual override onlyOneOfAdmins taskMustExist(taskId) returns (uint) {
        return _taskApprovalsCount[taskId];
    }

    function finalizeTask(address origin, uint256 taskId) external virtual override
      onlyFinalizer
      mustBeOneOfAdmins(origin)
      taskMustExist(taskId)
      taskMustBeApproved(taskId) {
        _tasks[taskId] = 0;
        emit TaskFinalized(msg.sender, origin, taskId);
    }

    function isAdmin(address account) external view virtual override onlyOneOfAdmins returns (bool) {
        return _admins[account] == 1;
    }

    function addAdmin(uint256 taskId, address toBeAdded) external virtual override
      onlyOneOfAdmins
      taskMustExist(taskId)
      taskMustBeApproved(taskId) {
        require(_nrOfAdmins < MAX_NR_OF_ADMINS, "arteQAdmin: cannot have more admin accounts");
        require(_admins[toBeAdded] == 0, "arteQAdmin: already an admin account");
        _admins[toBeAdded] = 1;
        _nrOfAdmins++;
        emit AdminAdded(msg.sender, toBeAdded);
        // adjust min required nr of approvals
        if (_minRequiredNrOfApprovals < (1 + uint(_nrOfAdmins) / uint(2))) {
            _minRequiredNrOfApprovals = 1 + uint(_nrOfAdmins) / uint(2);
            emit NewMinRequiredNrOfApprovalsSet(msg.sender, _minRequiredNrOfApprovals);
        }
        // finalize task
        _tasks[taskId] = 0;
        emit TaskFinalized(msg.sender, msg.sender, taskId);
    }

    function replaceAdmin(uint256 taskId, address toBeRemoved, address toBeReplaced) external virtual override
      onlyOneOfAdmins
      taskMustExist(taskId)
      taskMustBeApproved(taskId) {
        require(_admins[toBeRemoved] == 1, "arteQAdmin: no admin account found");
        require(_admins[toBeReplaced] == 0, "arteQAdmin: already an admin account");
        _admins[toBeRemoved] = 0;
        _admins[toBeReplaced] = 1;
        emit AdminReplaced(msg.sender, toBeRemoved, toBeReplaced);
        // finalize task
        _tasks[taskId] = 0;
        emit TaskFinalized(msg.sender, msg.sender, taskId);
    }

    function removeAdmin(uint256 taskId, address toBeRemoved) external virtual override
      onlyOneOfAdmins
      taskMustExist(taskId)
      taskMustBeApproved(taskId) {
        require(_nrOfAdmins > MIN_NR_OF_ADMINS, "arteQAdmin: cannot have fewer admin accounts");
        require(_admins[toBeRemoved] == 1, "arteQAdmin: no admin account found");
        _admins[toBeRemoved] = 0;
        _nrOfAdmins--;
        emit AdminRemoved(msg.sender, toBeRemoved);
        // adjust min required nr of approvals
        if (_minRequiredNrOfApprovals > _nrOfAdmins) {
            _minRequiredNrOfApprovals = _nrOfAdmins;
            emit NewMinRequiredNrOfApprovalsSet(msg.sender, _minRequiredNrOfApprovals);
        }
        // finalize task
        _tasks[taskId] = 0;
        emit TaskFinalized(msg.sender, msg.sender, taskId);
    }

    function setMinRequiredNrOfApprovals(uint256 taskId, uint newMinRequiredNrOfApprovals) external virtual override
      onlyOneOfAdmins
      taskMustExist(taskId)
      taskMustBeApproved(taskId) {
        require(newMinRequiredNrOfApprovals != _minRequiredNrOfApprovals , "arteQAdmin: same value");
        require(newMinRequiredNrOfApprovals > uint(_nrOfAdmins) / uint(2) , "arteQAdmin: value is too low");
        require(newMinRequiredNrOfApprovals <= _nrOfAdmins, "arteQAdmin: value is too high");
        _minRequiredNrOfApprovals = newMinRequiredNrOfApprovals;
        emit NewMinRequiredNrOfApprovalsSet(msg.sender, _minRequiredNrOfApprovals);
        // finalize task
        _tasks[taskId] = 0;
        emit TaskFinalized(msg.sender, msg.sender, taskId);
    }

    receive() external payable {
        revert("arteQAdmin: cannot accept ether");
    }

    fallback() external payable {
        revert("arteQAdmin: cannot accept ether");
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../../arteq-tech/contracts/diamond/IDiamondFacet.sol";
import "../../../arteq-tech/contracts/security/role-manager/RoleManagerLib.sol";
import "../arteQCollectionV2Config.sol";
import "./CrossmintInternal.sol";

contract CrossmintFacet is IDiamondFacet {

    modifier onlyAdmin() {
        RoleManagerLib._checkRole(arteQCollectionV2Config.ROLE_ADMIN);
        _;
    }

    function getFacetName()
      external pure override returns (string memory) {
        return "crossmint";
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getFacetVersion()
      external pure override returns (string memory) {
        return "0.0.1";
    }

    function getFacetPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](3);
        pi[0] = "getCrossmintSettings()";
        pi[1] = "setCrossmintSettings(bool,address)";
        pi[2] = "crossmintReserve(address,uint256)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId;
    }

    function getCrossmintSettings() external view returns (bool, address) {
        return CrossmintInternal._getCrossmintSettings();
    }

    function setCrossmintSettings(
        bool crossmintEnabled,
        address crossmintTrustedAddress
    ) external onlyAdmin {
        CrossmintInternal._setCrossmintSettings(
            crossmintEnabled,
            crossmintTrustedAddress
        );
    }

    function crossmintReserve(address to, uint256 nrOfTokens) external payable {
        CrossmintInternal._crossmintReserve(to, nrOfTokens);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../../diamond/IDiamondFacet.sol";
import "./TestPhonebookInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
contract TestPhonebookFacet is IDiamondFacet {

    function getFacetName() external pure override returns (string memory) {
        return "test-phonebook";
    }

    function getFacetVersion() external pure override returns (string memory) {
        return "0.0.1";
    }

    function getFacetPI() external pure override returns (string[] memory) {
        string[] memory pi = new string[](4);
        pi[0] = "init()";
        pi[1] = "getNrOfEntries()";
        pi[2] = "getEntry(uint256)";
        pi[3] = "addEntry(string,string,string)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId ||
               interfaceId == 0xaabbccdd;
    }

    function init() external {
        TestPhonebookInternal._init();
    }

    function getNrOfEntries() external view returns (uint256) {
        return TestPhonebookInternal._getNrOfEntries();
    }

    function getEntry(uint256 id)
      external view returns (string memory, string memory, string memory) {
        return TestPhonebookInternal._getEntry(id);
    }

    function addEntry(
        string memory name,
        string memory family,
        string memory phone
    ) external {
        TestPhonebookInternal._addEntry(name, family, phone);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./TestPhonebookStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library TestPhonebookInternal {

    event EntryAdd(uint256 id, string name, string family, string phone);

    function _init() internal {
        __s().entryIdCounter = 1;
    }

    function _getNrOfEntries() internal view returns (uint256) {
        return __s().entryIdCounter - 1;
    }

    function _getEntry(uint256 id) internal view returns (string memory, string memory, string memory) {
        require(id < __s().entryIdCounter, "TSI: entry does not exist");
        TestPhonebookStorage.PhonebookEntry memory entry = __s().entries[id];
        return (entry.name, entry.family, entry.phone);
    }

    function _addEntry(
        string memory name,
        string memory family,
        string memory phone
    ) internal {
        uint256 id = __s().entryIdCounter;
        __s().entryIdCounter += 1;
        TestPhonebookStorage.PhonebookEntry memory entry =
            TestPhonebookStorage.PhonebookEntry(id, name, family, phone);
        __s().entries[id] = entry;
        emit EntryAdd(id, name, family, phone);
    }

    function __s() private pure returns (TestPhonebookStorage.Layout storage) {
        return TestPhonebookStorage.layout();
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library TestPhonebookStorage {

    struct PhonebookEntry {
        uint256 id;
        string name;
        string family;
        string phone;
    }

    struct Layout {
        uint256 entryIdCounter;
        mapping(uint256 => PhonebookEntry) entries;
    }

    // Storage Slot: 04617b15fbfb5e3e1bad2accef63cd2943fbf36c46332f428fc84dd295d356e5
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-tech.contracts.test-phonebook-facet.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../abstract/task-managed/TaskManagedERC721VaultEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TestTaskManagedERC721VaultEnabled is TaskManagedERC721VaultEnabled {

    constructor(address taskManager) {
        _setTaskManager(taskManager);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./TaskExecutor.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract RoleManager is TaskExecutor {

    mapping (uint256 => mapping(address => bool)) private _roles;

    event RoleGrant(uint256 role, address account);
    event RoleRevoke(uint256 role, address account);

    modifier mustHaveRole(uint256 role) {
        require(_hasRole(msg.sender, role), "RM: missing role");
        _;
    }

    function hasRole(
        address account,
        uint256 role
    ) external view returns (bool) {
        return _hasRole(account, role);
    }

    function grantRole(
        uint256 taskId,
        address account,
        uint256 role
    ) external
      tryExecuteTaskAfterwards(taskId)
    {
        _grantRole(account, role);
    }

    function revokeRole(
        uint256 taskId,
        address account,
        uint256 role
    ) external
      tryExecuteTaskAfterwards(taskId)
    {
        _revokeRole(account, role);
    }

    function _hasRole(
        address account,
        uint256 role
    ) internal view returns (bool) {
        return _roles[role][account];
    }

    function _grantRole(
        address account,
        uint256 role
    ) internal {
        require(!_roles[role][account], "RM: already has role");
        _roles[role][account] = true;
        emit RoleGrant(role, account);
    }

    function _revokeRole(
        address account,
        uint256 role
    ) internal {
        require(_roles[role][account], "RM: does not have role");
        _roles[role][account] = false;
        emit RoleRevoke(role, account);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../abstract/task-manager/AdminTaskManaged.sol";
import "../../abstract/task-manager/CreatorRoleEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TestCreatorRoleEnabled is CreatorRoleEnabled, AdminTaskManaged {

    constructor(address[] memory initialAdmins, address[] memory initialCreators) {
        require(initialAdmins.length >= MIN_NR_OF_ADMINS, "TestCreatorRoleEnabled: not enough initial admins");
        for (uint i = 0; i < initialAdmins.length; i++) {
            _addAdmin(initialAdmins[i]);
        }
        for (uint i = 0; i < initialCreators.length; i++) {
            _addCreator(initialCreators[i]);
        }
    }

    /* solhint-disable func-name-mixedcase */
    function testonly_createNonAdministrativeTask(string memory taskURI) external {
        _createTask(taskURI, false);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../abstract/task-manager/AdminTaskManaged.sol";
import "../../abstract/task-manager/ApproverRoleEnabled.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TestApproverRoleEnabled is ApproverRoleEnabled, AdminTaskManaged {

    constructor(address[] memory initialAdmins, address[] memory initialApprovers) {
        require(initialAdmins.length >= MIN_NR_OF_ADMINS, "TestApproverRoleEnabled: not enough initial admins");
        for (uint i = 0; i < initialAdmins.length; i++) {
            _addAdmin(initialAdmins[i]);
        }
        for (uint i = 0; i < initialApprovers.length; i++) {
            _addApprover(initialApprovers[i]);
        }
    }

    /* solhint-disable func-name-mixedcase */
    function testonly_createNonAdministrativeTask(string memory taskURI) external {
        _createTask(taskURI, false);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../abstract/task-manager/AdminTaskManaged.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TestAdminTaskManaged is AdminTaskManaged {

    constructor(address[] memory initialAdmins) {
        require(initialAdmins.length >= MIN_NR_OF_ADMINS, "TestAdminTaskManaged: not enough initial admins");
        for (uint i = 0; i < initialAdmins.length; i++) {
            _addAdmin(initialAdmins[i]);
        }
    }

    /* solhint-disable func-name-mixedcase */
    function testonly_createNonAdministrativeTask(string memory taskURI) external {
        _createTask(taskURI, false);
    }

    function testonly_getTaskURI(uint256 taskId) external view
      taskMustExist(taskId)
      returns (string memory)
    {
        return _getTaskURI(taskId);
    }

    function testonly_isFinalized(uint256 taskId) external view
      taskMustExist(taskId)
      returns (bool)
    {
        return _isTaskFinalized(taskId);
    }

    function testonly_getNrOfApprovals(uint256 taskId) external view
      taskMustExist(taskId)
      returns (uint)
    {
        return _getTaskNrApprovals(taskId);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../abstract/task-manager/AdminTaskManaged.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TestAdminRoleEnabled is AdminTaskManaged {

    constructor(address[] memory initialAdmins) {
        require(initialAdmins.length >= MIN_NR_OF_ADMINS, "TestAdminRoleEnabled: not enough initial admins");
        for (uint i = 0; i < initialAdmins.length; i++) {
            _addAdmin(initialAdmins[i]);
        }
    }

    /* solhint-disable func-name-mixedcase */
    function testonly_createNonAdministrativeTask(string memory taskURI) external {
        _createTask(taskURI, false);
    }
}