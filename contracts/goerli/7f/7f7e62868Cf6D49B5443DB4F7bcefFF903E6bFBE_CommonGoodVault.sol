// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../vault/IVault.sol";
import "../platform/IPlatform.sol";
import "../project/IProject.sol";
import "../project/PledgeEvent.sol";
import "../utils/InitializedOnce.sol";


contract CommonGoodVault is IVault, ERC165Storage, InitializedOnce {

    event PTokPlacedInVault( uint sum);

    event PTokTransferredToTeamWallet( uint sumToTransfer_, address indexed teamWallet_, uint platformCut_, address indexed platformAddr_);

    event PTokTransferredToPledger( uint sumToTransfer_, address indexed pledgerAddr_);

    error VaultOwnershipCannotBeTransferred( address _owner, address newOwner);

    error VaultOwnershipCannotBeRenounced();
    //----

    uint public numTokensInVault; // all deposits from all pledgers

    constructor() {
        _initialize();
    }

    function initialize(address owner_) external override onlyIfNotInitialized { //@PUBFUNC called by platform //@CLONE
        markAsInitialized(owner_);
        _initialize();
    }

    function _initialize() private {
        _registerInterface( type(IVault).interfaceId);
        numTokensInVault = 0;
    }

    function increaseBalance( uint numPaymentTokens_) external override onlyOwner {
        numTokensInVault += numPaymentTokens_;
        emit PTokPlacedInVault( numPaymentTokens_);
    }

    function transferPaymentTokensToPledger( address pledgerAddr_, uint numPaymentTokens_)
                                                    external override onlyOwner returns(uint) {
        // can only be invoked by connected project
        // @PROTECT: DoS, Re-entry

        uint actuallyRefunded_ = _transferFromVaultTo( pledgerAddr_, numPaymentTokens_);

        emit PTokTransferredToPledger( numPaymentTokens_, pledgerAddr_);

        return actuallyRefunded_;
    }


    function _totalNumOwnedTokens() private view returns(uint) {
        address paymentTokenAddress_ = getPaymentTokenAddress();
        return IERC20( paymentTokenAddress_).balanceOf( address(this));
    }


    function transferPaymentTokenToTeamWallet (uint totalSumToTransfer_, uint platformCut_, address platformAddr_)
                                                external override onlyOwner { //@PUBFUNC

        // can only be invoked by connected project
        // @PROTECT: DoS, Re-entry
        address teamWallet_ = getTeamWallet();

        require( numTokensInVault >= totalSumToTransfer_, "insufficient numTokensInVault");
        require( _totalNumOwnedTokens() >= totalSumToTransfer_, "insufficient totalOwnedTokens");

        uint teamCut_ = totalSumToTransfer_ - platformCut_;


        // transfer from vault to team
        _transferFromVaultTo( teamWallet_, teamCut_);

        _transferFromVaultTo( platformAddr_, platformCut_);

        emit PTokTransferredToTeamWallet( teamCut_, teamWallet_, platformCut_, platformAddr_);
    }


    function _transferFromVaultTo( address receiverAddr_, uint numTokensToTransfer) private returns(uint) {
        uint actuallyTransferred_ = numTokensToTransfer;

        if (actuallyTransferred_ > numTokensInVault) {
            actuallyTransferred_ = numTokensInVault;
        }

        numTokensInVault -= actuallyTransferred_;

        address paymentTokenAddress_ = getPaymentTokenAddress();

        bool ok = IERC20( paymentTokenAddress_).transfer( receiverAddr_, actuallyTransferred_);
        require( ok, "Failed to transfer payment tokens");

        return actuallyTransferred_;
    }

    //----


    function getPaymentTokenAddress() private view returns(address) {
        address project_ = getOwner();
        return IProject(project_).getPaymentTokenAddress();
    }

    function getTeamWallet() private view returns(address) {
        address project_ = getOwner();
        return IProject(project_).getTeamWallet();
    }


    function changeOwnership( address newOwner) public override( InitializedOnce, IVault) onlyOwnerOrNull {
        return InitializedOnce.changeOwnership( newOwner);
    }

    function vaultBalance() public view override returns(uint) {
        return numTokensInVault;
    }

    function totalAllPledgerDeposits() public view override returns(uint) {
        return numTokensInVault;
    }


    function decreaseTotalDepositsOnPledgerGraceExit(PledgeEvent[] calldata pledgerEvents) external override onlyOwner {
        uint totalForPledger_ = 0 ;
        for (uint i = 0; i < pledgerEvents.length; i++) {
            totalForPledger_ += pledgerEvents[i].sum;
        }
        numTokensInVault -= totalForPledger_;
    }

    function getOwner() public override( InitializedOnce, IVault) view returns (address) {
        return InitializedOnce.getOwner();
    }


    //------ retain connected project ownership (behavior declaration)

    function renounceOwnership() public view override onlyOwner {
        revert VaultOwnershipCannotBeRenounced();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../@openzeppelin/contracts/access/Ownable.sol";
import "../project/PledgeEvent.sol";

interface IVault {

    function transferPaymentTokenToTeamWallet(uint sum_, uint platformCut, address platformAddr_) external;
    function transferPaymentTokensToPledger( address pledgerAddr_, uint sum_) external returns(uint);

    function increaseBalance( uint numPaymentTokens_) external;

    function vaultBalance() external view returns(uint);

    function totalAllPledgerDeposits() external view returns(uint);

    function decreaseTotalDepositsOnPledgerGraceExit(PledgeEvent[] calldata pledgerEvents) external;

    function changeOwnership( address project_) external;
    function getOwner() external view returns (address);

    function initialize( address owner_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


abstract contract InitializedOnce {

    bool public wasInitialized;

    address public owner;


    event OwnershipChanged( address indexed owner_, address indexed oldOwner_);

    event OwnershipRenounced( address indexed oldOwner_);

    event MarkedAsInitialized();


    modifier onlyIfNotInitialized() {
        require( !wasInitialized, "can only be initialized once");
        _;
    }

    modifier onlyOwner() {
        require( owner == msg.sender, "caller is not owner");
        _;
    }

    modifier onlyOwnerOrNull() {
        require( owner == address(0) || owner == msg.sender, "onlyOwnerOrNull");
        _;
    }

    function changeOwnership(address newOwner) virtual public onlyOwnerOrNull {
        require( newOwner != address(0), "new owner cannot be zero");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipChanged( owner, oldOwner);
    }

    function renounceOwnership() public virtual onlyOwner {
        address oldOwner = owner;
        owner = address(0);
        emit OwnershipRenounced( oldOwner);
    }

    function getOwner() public virtual view returns (address) {
        return owner;
    }

    function markAsInitialized( address owner_) internal onlyIfNotInitialized {
        wasInitialized = true;

        changeOwnership(owner_);

        emit MarkedAsInitialized();
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../@openzeppelin/contracts/access/Ownable.sol";

import "../project/IProject.sol";

interface IMintableOwnedERC20 is IERC20 {

    function mint(address to, uint256 amount) external ;

    function getOwner() external view returns (address);

    function changeOwnership( address dest) external;

    function setConnectedProject( IProject project_) external;

    function performInitialMint( uint numTokens) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16; 

enum ProjectState {
    IN_PROGRESS,
    SUCCEEDED,
    FAILED
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../vault/IVault.sol";
import "../milestone/Milestone.sol";
import "../token/IMintableOwnedERC20.sol";

struct ProjectInitParams {
    address projectTeamWallet;
    IVault vault;
    Milestone[] milestones;
    IMintableOwnedERC20 projectToken;
    uint platformCutPromils;
    uint minPledgedSum;
    uint onChangeExitGracePeriod;
    uint pledgerGraceExitWaitTime;
    address paymentToken;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

struct PledgeEvent { //@STORAGEOPT
    uint32 date;
    uint sum;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;


import "../token/IMintableOwnedERC20.sol";
import "../vault/IVault.sol";
import "../milestone/Milestone.sol";
import "./ProjectState.sol";
import "./ProjectInitParams.sol";


interface IProject {

    function initialize( ProjectInitParams memory params_) external;

    function getOwner() external view returns(address);

    function getTeamWallet() external view returns(address);

    function getPaymentTokenAddress() external view returns(address);

    function mintProjectTokens( address receiptOwner_, uint numTokens_) external;

    function getProjectStartTime() external view returns(uint);

    function getProjectState() external view returns(ProjectState);

    function getVaultBalance() external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IPlatform {
    function onReceivePaymentTokens( address paymentTokenAddress_, uint platformCut_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

enum MilestoneResult {
    UNRESOLVED,
    SUCCEEDED,
    FAILED
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

struct MilestoneApprover {
    //off-chain: oracle, judge..
    address externalApprover;

    //on-chain
    uint32 targetNumPledgers;
    uint fundingTarget;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./MilestoneApprover.sol";
import "./MilestoneResult.sol";
import "../vault/IVault.sol";

struct Milestone {

    MilestoneApprover milestoneApprover;
    MilestoneResult result;

    uint32 dueDate;
    int32 prereqInd;

    uint pTokValue;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

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