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
contract arteQTaskManager is TaskManager {

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

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
        require(_taskExists(taskId), "AdminTaskManaged: task does not exist");
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
        require(_isCreator(msg.sender), "CreatorRoleEnabled: not a creator account");
        _;
    }

    modifier onlyCreatorOrAdmin() {
        require(_isCreator(msg.sender) || _isAdmin(msg.sender),
                "CreatorRoleEnabled: not a creator or admin account");
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
        require(account != address(0), "CreatorRoleEnabled: zero account cannot be used");
        require(!_creators[account], "CreatorRoleEnabled: already a creator account");
        _creators[account] = true;
        _nrOfCreators += 1;
        emit CreatorAdded(account);
    }

    function _removeCreator(address account) internal {
        require(account != address(0), "CreatorRoleEnabled: zero account cannot be used");
        require(_creators[account], "CreatorRoleEnabled: not a creator account");
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
        require(_isApprover(msg.sender), "ApproverRoleEnabled: not an approver account");
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
        require(account != address(0), "ApproverRoleEnabled: zero account cannot be used");
        require(!_approvers[account], "ApproverRoleEnabled: already an approver account");
        _approvers[account] = true;
        _nrOfApprovers += 1;
        emit ApproverAdded(account);
    }

    function _removeApprover(address account) internal {
        require(account != address(0), "ApproverRoleEnabled: zero account cannot be used");
        require(_approvers[account], "ApproverRoleEnabled: not an approver account");
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

    modifier onlyExecutor() {
        require(_isExecutor(msg.sender), "ExecutorRoleEnabled: not an executor account");
        _;
    }

    modifier mustBeExecutor(address account) {
        require(_isExecutor(account), "ExecutorRoleEnabled: not an executor account");
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
        require(account != address(0), "ExecutorRoleEnabled: zero account cannot be used");
        require(!_executors[account], "ExecutorRoleEnabled: already an executor account");
        _executors[account] = true;
        _nrOfExecutors += 1;
        emit ExecutorAdded(account);
    }

    function _removeExecutor(address account) internal {
        require(account != address(0), "ExecutorRoleEnabled: zero account cannot be used");
        require(_executors[account], "ExecutorRoleEnabled: not an executor account");
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
        require(account != address(0), "FinalizerRoleEnabled: zero account cannot be used");
        require(!_finalizers[account], "FinalizerRoleEnabled: already a finalizer account");
        _finalizers[account] = true;
        _nrOfFinalizers += 1;
        emit FinalizerAdded(account);
    }

    function _removeFinalizer(address account) internal {
        require(account != address(0), "FinalizerRoleEnabled: zero account cannot be used");
        require(_finalizers[account], "FinalizerRoleEnabled: not a finalizer account");
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
        require(_isDepositEnabled() != enableDeposit, "ETHVaultEnabled: cannot set the same value");
        _setEnableDeposit(enableDeposit);
        _finalizeTask(adminTaskId, "");
    }

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

    uint public MAX_NR_OF_ADMINS = 10;
    uint public MIN_NR_OF_ADMINS = 4;

    mapping (address => bool) private _admins;
    uint internal _nrOfAdmins;

    event AdminAdded(address account);
    event AdminRemoved(address account);

    modifier onlyAdmin() {
        require(_isAdmin(msg.sender), "AdminRoleEnabled: not an admin account");
        _;
    }

    constructor() {
        _nrOfAdmins = 0;
    }

    function minNrOfAdmins() external view returns (uint) {
        return MIN_NR_OF_ADMINS;
    }

    function maxNrOfAdmins() external view returns (uint) {
        return MAX_NR_OF_ADMINS;
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
        require(account != address(0), "AdminRoleEnabled: zero account cannot be used");
        require(!_admins[account], "AdminRoleEnabled: already an admin account");
        require((_nrOfAdmins + 1) <= MAX_NR_OF_ADMINS, "AdminRoleEnabled: exceeds maximum number of admin accounts");
        _admins[account] = true;
        _nrOfAdmins += 1;
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        require(account != address(0), "AdminRoleEnabled: zero account cannot be used");
        require(_admins[account], "AdminRoleEnabled: not an admin account");
        require((_nrOfAdmins - 1) >= MIN_NR_OF_ADMINS,
                "AdminRoleEnabled: goes below minimum number of admin accounts");
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

    function _ETHTransfer(
        address to,
        uint256 amount
    ) internal {
        require(to != address(0), "ETHVault: cannot transfer to zero");
        require(amount > 0, "ETHVault: amount is zero");
        require(amount <= address(this).balance, "ETHVault: transfer more than balance");

        (bool success, ) = to.call{value: amount}(new bytes(0));
        require(success, "ETHVault: failed to transfer");
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

    function _ERC20Transfer(
        address tokenContract,
        address to,
        uint256 amount
    ) internal {
        require(tokenContract != address(0), "ERC20Vault: zero token address");
        require(to != address(0), "ERC20Vault: cannot transfer to zero");
        require(amount > 0, "ERC20Vault: amount is zero");
        require(amount <= IERC20(tokenContract).balanceOf(address(this)),
                                "ERC20Vault: transfer more than balance");

        IERC20(tokenContract).transfer(to, amount);
        emit ERC20Transferred(tokenContract, to, amount);
    }

    function _ERC20Approve(
        address tokenContract,
        address spender,
        uint256 amount
    ) internal {
        require(tokenContract != address(0), "ERC20Vault: zero token address");
        require(spender != address(0), "ERC20Vault: zero address for spender");

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

    function _ERC721Transfer(
        address tokenContract,
        address to,
        uint256 tokenId
    ) internal {
        require(tokenContract != address(0), "ERC721Vault: zero token address");
        require(to != address(0), "ERC721Vault: cannot transfer to zero");

        IERC721(tokenContract).safeTransferFrom(address(this), to, tokenId, "");
        emit ERC721Transferred(tokenContract, to, tokenId);
    }

    // operator can be the zero address.
    function _ERC721Approve(
        address tokenContract,
        address operator,
        uint256 tokenId
    ) internal {
        require(tokenContract != address(0), "ERC721Vault: zero token address");

        IERC721(tokenContract).approve(operator, tokenId);
        emit ERC721Approved(tokenContract, operator, tokenId);
    }

    function _ERC721SetApprovalForAll(
        address tokenContract,
        address operator,
        bool approved
    ) internal {
        require(tokenContract != address(0), "ERC721Vault: zero token address");
        require(operator != address(0), "ERC721Vault: zero address for operator");

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

    function _ERC1155Transfer(
        address tokenContract,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        require(tokenContract != address(0), "ERC1155Vault: zero token address");
        require(to != address(0), "ERC1155Vault: cannot transfer to zero");

        IERC1155(tokenContract).safeTransferFrom(address(this), to, tokenId, amount, "");
        emit ERC1155Transferred(tokenContract, to, tokenId, amount);
    }

    function _ERC1155SetApprovalForAll(
        address tokenContract,
        address operator,
        bool approved
    ) internal {
        require(tokenContract != address(0), "ERC1155Vault: zero token address");
        require(operator != address(0), "ERC1155Vault: zero address for operator");

        IERC1155(tokenContract).setApprovalForAll(operator, approved);
        emit ERC1155ApprovedForAll(tokenContract, operator, approved);
    }
}

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