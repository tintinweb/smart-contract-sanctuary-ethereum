/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.14;

/// @notice Kali DAO share manager interface
interface IKaliShareManager {
    function mintShares(address to, uint256 amount) external payable;

    function burnShares(address from, uint256 amount) external payable;
}

/// @notice Gas optimized reentrancy protection for smart contracts
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// License-Identifier: AGPL-3.0-only
abstract contract ReentrancyGuard {
    error Reentrancy();
    
    uint256 private locked = 1;

    modifier nonReentrant() {
        if (locked != 1) revert Reentrancy();
        
        locked = 2;
        _;
        locked = 1;
    }
}

/// @notice Safe ETH and ERC20 free function transfer collection that gracefully handles missing return values.
/// @author Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/utils/SafeTransfer.sol)
/// @author Modified from Zolidity (https://github.com/z0r0z/zolidity/blob/main/src/utils/SafeTransfer.sol)

/// @dev The ETH transfer has failed.
error ETHTransferFailed();

/// @dev Sends `amount` (in wei) ETH to `to`.
/// Reverts upon failure.
function safeTransferETH(address to, uint256 amount) {
    assembly {
        // Transfer the ETH and check if it succeeded or not.
        if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
            // Store the function selector of `ETHTransferFailed()`.
            mstore(0x00, 0xb12d13eb)
            // Revert with (offset, size).
            revert(0x1c, 0x04)
        }
    }
}

/// @dev The ERC20 `transfer` has failed.
error TransferFailed();

/// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
/// Reverts upon failure.
function safeTransfer(
    address token,
    address to,
    uint256 amount
) {
    assembly {
        // We'll write our calldata to this slot below, but restore it later.
        let memPointer := mload(0x40)

        // Write the abi-encoded calldata into memory, beginning with the function selector.
        mstore(0x00, 0xa9059cbb)
        mstore(0x20, to) // Append the "to" argument.
        mstore(0x40, amount) // Append the "amount" argument.

        if iszero(
            and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(eq(mload(0x00), 1), iszero(returndatasize())),
                // We use 0x44 because that's the total length of our calldata (0x04 + 0x20 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0x1c, 0x44, 0x00, 0x20)
            )
        ) {
            // Store the function selector of `TransferFailed()`.
            mstore(0x00, 0x90b8ec18)
            // Revert with (offset, size).
            revert(0x1c, 0x04)
        }

        mstore(0x40, memPointer) // Restore the memPointer.
    }
}

/// @dev The ERC20 `transferFrom` has failed.
error TransferFromFailed();

/// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
/// Reverts upon failure.
///
/// The `from` account must have at least `amount` approved for
/// the current contract to manage.
function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 amount
) {
    assembly {
        // We'll write our calldata to this slot below, but restore it later.
        let memPointer := mload(0x40)

        // Write the abi-encoded calldata into memory, beginning with the function selector.
        mstore(0x00, 0x23b872dd)
        mstore(0x20, from) // Append the "from" argument.
        mstore(0x40, to) // Append the "to" argument.
        mstore(0x60, amount) // Append the "amount" argument.

        if iszero(
            and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(eq(mload(0x00), 1), iszero(returndatasize())),
                // We use 0x64 because that's the total length of our calldata (0x04 + 0x20 * 3)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
            )
        ) {
            // Store the function selector of `TransferFromFailed()`.
            mstore(0x00, 0x7939f424)
            // Revert with (offset, size).
            revert(0x1c, 0x04)
        }

        mstore(0x60, 0) // Restore the zero slot to zero.
        mstore(0x40, memPointer) // Restore the memPointer.
    }
}

/// @title ProjectManager
/// @notice Project Manger for on-chain entities.
/// @author ivelin.eth | sporosdao.eth
/// @custom:coauthor audsssy.eth | kalidao.eth

enum Reward {
    ETH, 
    DAO,
    ERC20
}

enum Status {
    INACTIVE,
    ACTIVE
}

struct Project {
    address account; // The main address associated with a Project.
    Status status; // The status of a Project. 
    address manager; // The manager assigned to a Project.
    Reward reward; // The type of contribution reward.
    address token; // The token used to reward contributions.
    uint256 budget; // The budget (maximum amount) a Manager is authorized to distribute.
    uint256 distributed; // The amount already distributed to contributors.
    uint40 deadline; // The deadline to distribute Reward by.
    string docs; // The docs associated with a Project.
}

contract ProjectManager is ReentrancyGuard {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event ExtensionSet(uint256 projectId, Project project);

    event ProjectUpdated(uint256 projectId, Project project);

    event ExtensionCalled(uint256 projectId, address indexed contributor, uint256 amount);

    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    error SetupFailed();

    error UpdateFailed();

    error ExpiredProject();

    error InvalidProject();

    error InactiveProject();

    error InvalidEthTransfer();

    error NotAuthorized();

    error OnlyAccount();

    error InsufficientBudget();

    error InvalidInput();
    
    /// -----------------------------------------------------------------------
    /// Project Management Storage
    /// -----------------------------------------------------------------------

    uint256 public projectId;

    mapping(uint256 => Project) public projects;

    /// -----------------------------------------------------------------------
    /// ProjectManager Logic
    /// -----------------------------------------------------------------------

    function setExtension(bytes calldata extensionData) external payable {
        (
            uint256 id,
            Status status,
            address manager,
            Reward reward,
            address token,
            uint256 budget,
            uint40 deadline,
            string memory docs
        ) = abi.decode(
            extensionData,
            (uint256, Status, address, Reward, address, uint256, uint40, string)
        );

        if (id == 0) {            
            if (!_setProject(status, manager, reward, token, budget, deadline, docs))
                revert SetupFailed(); 
        } else {
            if (projects[id].status == Status.INACTIVE && projects[id].account == address(0)) revert InactiveProject();
            if (projects[id].account != msg.sender && projects[id].manager != msg.sender)
                revert NotAuthorized();
            if (projects[id].budget != budget && projects[id].account != msg.sender) revert OnlyAccount();
            if (!_updateProject(id, status, manager, budget, deadline, docs)) 
                revert UpdateFailed();
        }
    }

    function callExtension(bytes[] calldata extensionData)
        external
        payable
        nonReentrant
    {
        for (uint256 i; i < extensionData.length; ) {
            (uint256 _projectId, address contributor, uint256 amount) = 
                abi.decode(extensionData[i], (uint256, address, uint256));

            Project storage project = projects[_projectId];

            if (project.account == address(0)) revert InvalidProject();

            if (project.account != msg.sender && project.manager != msg.sender)
                revert NotAuthorized();

            if (project.status == Status.INACTIVE) revert InactiveProject();

            if (project.deadline < block.timestamp) revert ExpiredProject();

            if (project.budget < amount) revert InsufficientBudget();

            if (_projectId == 0 || contributor == address(0) || amount == 0) revert InvalidInput();

            project.budget -= amount;
            project.distributed += amount;

            if (project.reward == Reward.ETH) {
                safeTransferETH(contributor, amount);
            } else if (project.reward == Reward.DAO) {
                IKaliShareManager(project.account).mintShares(contributor, amount);
            } else {
                safeTransfer(project.token, contributor, amount);
            }

            // cannot realistically overflow
            unchecked {
                ++i;
            }

            emit ExtensionCalled(_projectId, contributor, amount);
        }
    }

    receive() external payable virtual {}

    /// -----------------------------------------------------------------------
    /// Internal Functions
    /// -----------------------------------------------------------------------
    
    function _setProject(
        Status status, 
        address manager, 
        Reward reward, 
        address token, 
        uint256 budget, 
        uint40 deadline, 
        string memory docs
    ) internal returns(bool) {
        // cannot realistically overflow
        unchecked {
            projectId++;
        }   

        if (reward == Reward.ETH) {
            (bool success,) = address(this).call{value: budget}("");
            if (!success) revert InvalidEthTransfer();

            projects[projectId] = Project({
                account: msg.sender,
                status: status,
                manager: manager,
                reward: reward,
                token: address(0),
                budget: budget,
                distributed: 0,
                deadline: deadline,
                docs: docs
            });
        } else if (reward == Reward.DAO) {
            projects[projectId] = Project({
                account: msg.sender,
                status: status,
                manager: manager,
                reward: reward,
                token: msg.sender,
                budget: budget,
                distributed: 0,
                deadline: deadline,
                docs: docs
            });
        } else {
            safeTransferFrom(token, msg.sender, address(this), budget);

            projects[projectId] = Project({
                account: msg.sender,
                status: status,
                manager: manager,
                reward: reward,
                token: token,
                budget: budget,
                distributed: 0,
                deadline: deadline,
                docs: docs
            });
        }
        
        emit ExtensionSet(projectId, projects[projectId]);

        return true;
    }

    function _updateProject(
        uint256 id,
        Status status, 
        address manager,  
        uint256 budget, 
        uint40 deadline, 
        string memory docs
    ) internal returns(bool) {

        projects[id] = Project({
            account: projects[id].account,
            status: (status != projects[id].status) ? status : projects[id].status,
            manager: (manager != projects[id].manager) ? manager : projects[id].manager,
            reward: projects[id].reward,
            token: projects[id].token,
            budget: _handleUpdatedBudget(id, budget),
            distributed: projects[id].distributed,
            deadline: (deadline != projects[id].deadline) ? deadline : projects[id].deadline,
            docs: docs
        });

        emit ProjectUpdated(id, projects[id]);

        return true;
    }

    function _handleUpdatedBudget(uint256 id, uint256 newBudget) internal returns(uint256) {
        Reward _reward = projects[id].reward;
        address _token = projects[id].token;
        uint256 _budget = projects[id].budget;
        uint256 diff;

        if (newBudget != _budget) {
            if (newBudget > _budget) {
                // cannot realistically overflow 
                unchecked{
                    diff = newBudget - _budget;
                }

                if (_reward == Reward.ETH) {
                    safeTransferETH(address(this), diff);
                } else if (_reward == Reward.DAO) {
                    IKaliShareManager(msg.sender).mintShares(address(this), diff);
                } else {
                    safeTransferFrom(_token, msg.sender, address(this), diff);
                }

                return newBudget;
            } else {
                // cannot realistically overflow 
                unchecked {
                    diff = _budget - newBudget;
                }

                if (_reward == Reward.ETH) {
                    (bool success, ) = msg.sender.call{value: diff}('');
                    if (!success) revert TransferFailed();
                } else if (_reward == Reward.DAO) {
                    IKaliShareManager(msg.sender).burnShares(address(this), diff);
                } else {
                    safeTransfer(_token, msg.sender, diff);
                }

                return newBudget;
            }
        } else {
            return _budget;
        }
    }
}