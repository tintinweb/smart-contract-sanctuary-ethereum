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
     * @dev Sets `amount` as the allowance of `spender` over the caller's
     * tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the
     * risk
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId`
     * token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to
     * manage all of its assets.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by
     * either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first
     * that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever
     * locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this
     * token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the
     * recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom}
     * prevents loss, though the caller must
     * understand this adds an external call which potentially creates a
     * reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by
     * either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another
     * account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero
     * address clears previous approvals.
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
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token
     * owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of
     * `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address addr) {
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via
     * {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via
     * {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same
     * value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer)
        internal
        pure
        returns (address addr)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓
            // ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC
            // |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            |
            // 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC
            // |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
            // |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage
                // bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final
                // garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
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
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP
     * section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

import "./interfaces/IERC721Mintable.sol";
import "./interfaces/IFundraising01Factory/IFundraising01Factory.sol";
import "./interfaces/IWETH.sol";
import {IFundraising01Base} from "./base/interfaces/IFundraising01Base/IFundraising01Base.sol";
import {IFundraising01FactoryERC20} from "./interfaces/IFundraising01FactoryERC20/IFundraising01FactoryERC20.sol";
import {IFundraising01FactoryERC721} from "./interfaces/IFundraising01FactoryERC721/IFundraising01FactoryERC721.sol";

/// @title Fundraising01Factory
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Factory contract for Fundraising01 contracts.
contract Fundraising01Factory is IFundraising01Factory {
    /// @inheritdoc IFundraising01FactoryState
    address[] public override sales;

    /// @inheritdoc IFundraising01FactoryImmutableState
    IFundraising01FactoryERC20 public immutable override factoryERC20;
    /// @inheritdoc IFundraising01FactoryImmutableState
    IFundraising01FactoryERC721 public immutable override factoryERC721;

    constructor(IFundraising01FactoryERC20 _factoryERC20, IFundraising01FactoryERC721 _factoryERC721) {
        factoryERC20 = _factoryERC20;
        factoryERC721 = _factoryERC721;
    }

    /// @inheritdoc IFundraising01FactoryActions
    function createFundraisingERC20(
        IERC20 _tokenToSell,
        IERC20 _tokenToRaise,
        uint256 _amountToSellSoft,
        ISaleRounds.SaleRound[] memory _saleRounds,
        IVestable.Period[] memory _periods,
        IRefunds.RefundConfiguration memory _refundConfiguration,
        uint256 _executionDelay
    ) external override returns (address sale) {
        sales.push(
            (
                sale = factoryERC20.createFundraisingERC20(
                    msg.sender,
                    _tokenToSell,
                    _tokenToRaise,
                    _amountToSellSoft,
                    _saleRounds,
                    _periods,
                    _refundConfiguration,
                    _executionDelay
                )
            )
        );
    }

    /// @inheritdoc IFundraising01FactoryActions
    function createFundraisingERC721(
        IERC721Mintable _tokenToSell,
        IERC20 _tokenToRaise,
        uint256 _amountToSellSoft,
        ISaleRounds.SaleRound[] memory _saleRounds,
        IRefunds.RefundConfiguration memory _refundConfiguration,
        uint256 _executionDelay
    ) external returns (address sale) {
        sales.push(
            (
                sale = factoryERC721.createFundraisingERC721(
                    msg.sender,
                    _tokenToSell,
                    _tokenToRaise,
                    _amountToSellSoft,
                    _saleRounds,
                    _refundConfiguration,
                    _executionDelay
                )
            )
        );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

/// @title Build Rounds
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
interface IBuildRounds {
    event BuildingRoundPushed(uint256 index);

    error CannotPushRoundIfAnotherRoundIsPendingError();
    error CannotPushRoundBeforePreviousRoundIsExecutedError();
    error CannotPushRoundIfInsufficientReservesForProposalError(uint256 amountExceeds);

    struct BuildRound {
        uint256 amountAsked;
        string details;
        uint256 createdAt;
        uint256 amountUnlocked;
        uint256 amountRefunded;
        uint256 amountRefundedCumulative;
        bool isExecuted;
        bool isFulfilled;
    }

    /**
     * @notice Returns build round by index.
     * @param _index index.
     */
    function buildRounds(uint256 _index)
        external
        view
        returns (
            uint256 amountAsked,
            string memory details,
            uint256 createdAt,
            uint256 amountUnlocked,
            uint256 amountRefunded,
            uint256 amountRefundedCumulative,
            bool isExecuted,
            bool isFulfilled
        );

    /**
     * @notice Returns build rounds count.
     */
    function buildRoundsCount() external view returns (uint256);

    /// @notice Ask for unlock
    /// @dev Only the issuer can call this function.
    /// @param amount The amount of tokens to unlock.
    /// @param details The unlock details
    function pushBuildRound(uint256 amount, string memory details) external;

    function executeBuildRound() external;

    function hasPendingBuildRound() external view returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

import "@/base/interfaces/IBuildRounds.sol";
import "@/base/interfaces/ISaleRounds.sol";
import "./IFundraising01BaseActions.sol";
import "./IFundraising01BaseConstants.sol";
import "./IFundraising01BaseDerivedState.sol";
import "./IFundraising01BaseErrors.sol";
import "./IFundraising01BaseEvents.sol";
import "./IFundraising01BaseImmutableState.sol";
import "./IFundraising01BaseOwnerActions.sol";
import "./IFundraising01BaseState.sol";

/// @title IFundraising01Base
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Interface for Fundraising01Base contract.
interface IFundraising01Base is
    ISaleRounds,
    IBuildRounds,
    IFundraising01BaseActions,
    IFundraising01BaseConstants,
    IFundraising01BaseDerivedState,
    IFundraising01BaseErrors,
    IFundraising01BaseEvents,
    IFundraising01BaseImmutableState,
    IFundraising01BaseOwnerActions,
    IFundraising01BaseState
{}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

/// @title IFundraising01BaseActions
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Public Fundraising01 actions that anyone can call
interface IFundraising01BaseActions {
    /// @notice Invest in the sale.
    /// @param amount The amount of tokens to invest.
    function invest(uint256 amount, bytes memory data) external;

    /// @notice Forces balances to match reserves.
    /// @dev If some tokens were transferred directly to the contract, they can
    /// be claimed.
    function skim() external;
}

// SPDX-License-Identifier: Unlicense

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.18;

/// @title IFundraising01BaseConstants
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice State of the sale that will never change and encoded in the
/// contract.
interface IFundraising01BaseConstants {
    /// @notice The time period at which a sell should be up and running.
    /// If this period has lasted after the sale start, the sale will be
    /// destroyed.
    /// @return Start period.
    function SALE_STAGE_MIN_PERIOD() external pure returns (uint256);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

/// @title IFundraising01BaseDerivedState
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice State of the sale that is computed on fly.
interface IFundraising01BaseDerivedState {
    /// @notice Returns available amount for claim.
    /// @return Claimable amount
    function claimable() external view returns (uint256);

    /// @notice Is the sale failed
    /// @return True if sale is failed
    function isFailed() external view returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

interface IFundraising01BaseErrors {
    error CannotCreateFundraisingIfFactoryIsZeroAddressError();

    error InsufficientTTLError();

    error CannotCreateFundraisingIfAmountToSellSoftIsZeroError();
    error CannotCreateFundraisingIfAmountToSellHardIsZeroError();
    error CannotCreateFundraisingIfAmountToRaiseIsZeroError();
    error CannotCreateFundraisingIfTokenToRaiseIsZeroAddressError();
    error CannotCreateFundraisingIfTokenToSellIsZeroAddressError();
    error CannotCreateFundraisingIfTokenToSellAndTokenToRaiseAreSameError();

    error AmountCannotBeZeroError();

    error CannotInvestIfSaleRoundIsNotInProgressError();
    error SaleIsFailedError();
    error SaleIsNotFinishedError();

    error CannotUnlockIfDesiredUnlockAmountExceedsInvestedError(uint256 max);

    error CannotInvestIfInvestAmountExceedsRaiseHardAmountError(uint256 amountExceeds);

    error CannotInvestWithETHError(address tokenToRaise);

    error CannotRefundStartIfRefundIsNotAvailableYetError();
    error CannotRefundYet(uint256 availableAt);

    error CannotRefundStartIfAmountToRefundExceedsAvailableToRefundError(uint256 amountExceeds);

    error CannotCancelRefundIfNotStartedError();
    error CannotCancelRefundIfWindowPassedError();

    error CannotExecuteRoundIfNoRoundIsPendingError();
    error CannotExecuteRoundIfDelayNotPassedYetError();
    error CannotExecuteRoundIfThereIsPendingProposalError();
    error CannotExecuteRoundIfProposalIsExecutedError();

    error CannotWithdrawZeroTokensError();
    error CannotWithdrawIfRoundIsFulfilledError();

    error ProposalToLiquidateIsInProgressError();

    error LiquidationIsNotAvailableYetError();

    error CannotClaimIfExceedsClaimableMaximumError();

    error CannotInvestIfSaleRoundConditionIsNotPassedError();
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

interface IFundraising01BaseEvents {
    event SaleFailed();
    event UnlockExecuted(address indexed executor, uint256 index);

    event Invest(address indexed investor, uint256 amount);
    event Withdraw(uint256 amount);
    event Unlock(address indexed investor, uint256 amount);

    event SkimRaiseReserves(address indexed skimmer, uint256 reserveRaiseSkim);
}

// SPDX-License-Identifier: Unlicense

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.18;

/// @title IFundraising01BaseImmutableState
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Immutable state of the sale that will never change.
interface IFundraising01BaseImmutableState {
    /// @notice Timestamp when the sale took place
    /// @return Timestamp
    function createdAt() external view returns (uint256);

    /// @notice Amount of tokens to raise
    /// @return Amount
    function amountToRaise() external view returns (uint256);

    /// @notice Amount of tokens to sell
    /// If sale doesn't sell the `amountToSellSoft` – it is considered as
    /// failed.
    /// @return Amount
    function amountToSellSoft() external view returns (uint256);

    /// @notice Amount of tokens to sell
    /// Fundraising cannot sell more than this amount.
    /// @return Amount
    function amountToSellHard() external view returns (uint256);

    /// @notice The token to raise
    /// @return The token to raise
    function tokenToRaise() external view returns (IERC20);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

/// @title Owner Actions of Fundraising01
/// @notice Actions that can be performed by the owner of the sale.
interface IFundraising01BaseOwnerActions {
    function transferOwnership(address newOwner) external;

    /// @notice Withdraw available raised funds.
    /// @dev Only the owner can call this function.
    /// @param index Index of the unlock proposal.
    function withdraw(uint256 index) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

/// @title IFundraising01BaseState
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice State of the sale that can change.
interface IFundraising01BaseState {
    /// @notice Raise Reserves
    /// @dev Used in skim() to equalize the tokens with real balance
    /// @return Raise Reserves
    function reservesRaise() external view returns (uint256);

    /// @notice Amount raised
    /// @return Amount raised
    function amountRaised() external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

interface IRefunds {
    error CannotCreateFundraisingIfAvailabilityDelayIsGreaterThan60DaysError();
    error CannotCreateFundraisingIfCancelWindowIsGreaterThan30DaysError();

    struct RefundConfiguration {
        uint32 cancelWindow; // max 30 days
        uint32 availabilityDelay; // max 60 days
    }

    function refundConfiguration() external view returns (uint32 cancelWindow, uint32 availabilityDelay);

    function isRefundAvailable() external view returns (bool);

    function refundStart(bytes calldata _data) external;

    function refundFinish() external;

    function refundCancel() external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

import "@/interfaces/ICondition.sol";

/// @title Sale Stages
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
interface ISaleRounds {
    error NoApplicableSaleRoundIndex();

    struct SaleRound {
        uint256 startsAt;
        uint256 endsAt;
        uint256 amountToRaise;
        uint256 amountToSell;
        ICondition condition;
    }

    function saleRounds(uint256 _index)
        external
        view
        returns (uint256 startsAt, uint256 endsAt, uint256 amountToRaise, uint256 amountToSell, ICondition condition);

    function saleRoundsCount() external view returns (uint256);

    function applicableSaleRoundIndexOf(bytes memory data) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

/// @title Vestable
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Abstract contract for calculating claimable amounts with unlock
/// periods.
interface IVestable {
    struct Period {
        uint256 start;
        uint16 bps;
        bool cliffs;
    }

    error TotalBPSUnfulfilledError();
    error MinimumOfPeriodsNotMetError();
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

/**
 * @title ICondition
 * @dev Interface for the Condition contract.
 */
interface ICondition {
    /**
     * @notice Checks if the condition is met.
     * @param _data The data needed to perform a check.
     * @return True if the condition is met, false otherwise.
     */
    function check(bytes memory _data) external view returns (bool);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Mintable is IERC721 {
    function mint(address account, uint256 amount) external;

    function MINTER_ROLE() external view returns (bytes32);

    function hasRole(bytes32 role, address account) external view returns (bool);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

import "./IFundraising01FactoryActions.sol";
import "./IFundraising01FactoryState.sol";
import "./IFundraising01FactoryImmutableState.sol";

/// @title IFundraising01Factory
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice This interface combines all interfaces for Factory.
interface IFundraising01Factory is
    IFundraising01FactoryState,
    IFundraising01FactoryImmutableState,
    IFundraising01FactoryActions
{}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

import "../IFundraising01FactoryERC20/IFundraising01FactoryERC20Actions.sol";
import "../IFundraising01FactoryERC721/IFundraising01FactoryERC721Actions.sol";

/// @title IFundraising01FactoryActions
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Actions for factory contract for Fundraising01 contracts.
interface IFundraising01FactoryActions {
    /// @notice Creates a new sale.
    /// @param tokenToSell The token to sell.
    /// @param tokenToRaise The token to raise.
    /// @param amountToSellSoft The amount of tokens to sell soft (Soft Cap).
    /// @param saleRounds Sale Rounds.
    /// @param periods Vesting periods.
    /// @param refundConfiguration Refund configuration.
    /// @param executionDelay Refund configuration.
    /// @return The address of the sale.
    function createFundraisingERC20(
        IERC20 tokenToSell,
        IERC20 tokenToRaise,
        uint256 amountToSellSoft,
        ISaleRounds.SaleRound[] memory saleRounds,
        IVestable.Period[] memory periods,
        IRefunds.RefundConfiguration memory refundConfiguration,
        uint256 executionDelay
    ) external returns (address);

    /**
     * @notice Creates a new ERC721 sale contract.
     * @param tokenToSell The ERC721 token to be sold.
     * @param tokenToRaise The ERC20 token to be used to buy the ERC721 token.
     * @param amountToSellSoft The soft cap of the ERC721 token to be sold.
     * @param saleRounds Sale Rounds.
     * @param refundConfiguration Refund configuration.
     * @param executionDelay Refund configuration.
     */
    function createFundraisingERC721(
        IERC721Mintable tokenToSell,
        IERC20 tokenToRaise,
        uint256 amountToSellSoft,
        ISaleRounds.SaleRound[] memory saleRounds,
        IRefunds.RefundConfiguration memory refundConfiguration,
        uint256 executionDelay
    ) external returns (address);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

import "../IWETH.sol";

import "../IFundraising01FactoryERC20/IFundraising01FactoryERC20.sol";
import "../IFundraising01FactoryERC721/IFundraising01FactoryERC721.sol";

/// @title IFundraising01ERC721FactoryImmutableState
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Immutable state of the Factory that will never change.
interface IFundraising01FactoryImmutableState {
    /// @notice The address of the Fundraising Factory ERC20.
    /// @return The address of the Fundraising Factory ERC20.
    function factoryERC20() external view returns (IFundraising01FactoryERC20);

    /// @notice The address of the Fundraising Factory ERC721.
    /// @return The address of the Fundraising Factory ERC721.
    function factoryERC721() external view returns (IFundraising01FactoryERC721);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

/// @title IFundraising01FactoryState
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice State of the factory that can change.
interface IFundraising01FactoryState {
    /// @notice All ongoing sales.
    /// @param index The index of the sale.
    /// @return The IFundraising01 sale contract.
    function sales(uint256 index) external view returns (address);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

import "./IFundraising01FactoryERC20Actions.sol";
import "./IFundraising01FactoryERC20ImmutableState.sol";
import "./IFundraising01FactoryERC20Events.sol";

/// @title IFundraising01FactoryERC20
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice This interface combines all interfaces for FactoryERC20.
interface IFundraising01FactoryERC20 is
    IFundraising01FactoryERC20ImmutableState,
    IFundraising01FactoryERC20Actions,
    IFundraising01FactoryERC20Events
{}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../IERC721Mintable.sol";
import "../../base/interfaces/ISaleRounds.sol";
import "../../base/interfaces/IRefunds.sol";
import "../../base/interfaces/IVestable.sol";

/// @title IFundraising01FactoryERC20Actions
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Actions for factory contract for Fundraising01 contracts.
interface IFundraising01FactoryERC20Actions {
    /// @notice Creates a new sale.
    /// @param tokenToSell The token to sell.
    /// @param tokenToRaise The token to raise.
    /// @param amountToSellSoft The amount of tokens to sell soft (Soft Cap).
    /// @param saleRounds Sale Rounds.
    /// @param periods Vesting periods.
    /// @param refundConfiguration Refund configuration.
    /// @param executionDelay Refund configuration.
    /// @return The address of the sale.
    function createFundraisingERC20(
        address creator,
        IERC20 tokenToSell,
        IERC20 tokenToRaise,
        uint256 amountToSellSoft,
        ISaleRounds.SaleRound[] memory saleRounds,
        IVestable.Period[] memory periods,
        IRefunds.RefundConfiguration memory refundConfiguration,
        uint256 executionDelay
    ) external returns (address);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

/// @title IFundraising01ERC20FactoryEvents
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Events emitted by factory.
interface IFundraising01FactoryERC20Events {
    event Fundraising01ERC20Created(address indexed fundraising, address indexed creator);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

import "../IWETH.sol";

/// @title IFundraising01ERC20FactoryImmutableState
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Immutable state of the Factory that will never change.
interface IFundraising01FactoryERC20ImmutableState {
    /// @notice The address of the WETH contract.
    /// @return The address of the WETH contract.
    function WETH() external view returns (IWETH);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

import "./IFundraising01FactoryERC721Actions.sol";
import "./IFundraising01FactoryERC721ImmutableState.sol";
import "./IFundraising01FactoryERC721Events.sol";

/// @title IFundraising01FactoryERC721
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice This interface combines all interfaces for FactoryERC721.
interface IFundraising01FactoryERC721 is
    IFundraising01FactoryERC721ImmutableState,
    IFundraising01FactoryERC721Actions,
    IFundraising01FactoryERC721Events
{}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../IERC721Mintable.sol";
import "../../base/interfaces/ISaleRounds.sol";
import "../../base/interfaces/IRefunds.sol";
import "../../base/interfaces/IVestable.sol";

/// @title IFundraising01FactoryERC721Actions
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Actions for factory contract for Fundraising01 contracts.
interface IFundraising01FactoryERC721Actions {
    /**
     * @notice Creates a new ERC721 sale contract.
     * @param tokenToSell The ERC721 token to be sold.
     * @param tokenToRaise The ERC20 token to be used to buy the ERC721 token.
     * @param amountToSellSoft The soft cap of the ERC721 token to be sold.
     * @param saleRounds Sale Rounds.
     * @param refundConfiguration Refund configuration.
     * @param executionDelay Refund configuration.
     */
    function createFundraisingERC721(
        address creator,
        IERC721Mintable tokenToSell,
        IERC20 tokenToRaise,
        uint256 amountToSellSoft,
        ISaleRounds.SaleRound[] memory saleRounds,
        IRefunds.RefundConfiguration memory refundConfiguration,
        uint256 executionDelay
    ) external returns (address);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

/// @title IFundraising01ERC721FactoryEvents
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Events emitted by factory.
interface IFundraising01FactoryERC721Events {
    event Fundraising01ERC721Created(address indexed fundraising, address indexed creator);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

import "../IWETH.sol";

/// @title IFundraising01ERC721FactoryImmutableState
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Immutable state of the Factory that will never change.
interface IFundraising01FactoryERC721ImmutableState {
    /// @notice The address of the WETH contract.
    /// @return The address of the WETH contract.
    function WETH() external view returns (IWETH);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}