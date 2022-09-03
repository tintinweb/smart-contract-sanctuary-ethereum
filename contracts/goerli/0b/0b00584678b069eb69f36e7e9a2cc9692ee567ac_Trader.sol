// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Configurable.sol";
import "./AssetHandler.sol";
import "./Banker.sol";

import "solmate/utils/ReentrancyGuard.sol";

struct Trade {
    address creator;
    address counterparty;
    address refer;
    bool accepted;
    uint256 expireAt;
    uint256 creatorNativeTokens;
    ERC20Asset[] creator20Assets;
    ERC721Asset[] creator721Assets;
    ERC1155Asset[] creator1155Assets;
    uint256 counterpartyNativeTokens;
    ERC20Asset[] counterparty20Assets;
    ERC721Asset[] counterparty721Assets;
    ERC1155Asset[] counterparty1155Assets;
}

enum TradeEvent {
    Offered,
    Accepted,
    Executed,
    Cancelled,
    ExpiredWithdrawn
}

error TradeAlreadyExists();
error TradeDoesNotExist();
error TradeIsCancelled();
error TradeIsNotExpired();
error TradeIsNotAccepted();
error TradeIsAlreadyAccepted();
error TradeHasExpired();
error InvalidExpiration();
error InvalidRefer();
error InvalidCounterparty();
error InvalidAssets();
error UserNotInTrade();
error UserDontHaveEscrow();
error InvalidPayment();

contract Trader is ReentrancyGuard, Configurable, AssetHandler, Banker {
    event TradeUpdated(TradeEvent indexed kind, string indexed id, address user);

    constructor(address owner) Configurable(owner) {}

    /// @dev Only trades in progress are on-chain. Once a trade gets completed or cancelled it is deleted.
    /// Trades are mapped by id
    mapping(string => Trade) trades;

    function getTrade(string memory id) public view returns (Trade memory) {
        return trades[id];
    }

    function offerTrade(
        string memory id,
        address counterparty,
        address refer,
        uint256 expireAt,
        uint256 creatorNativeTokens,
        ERC20Asset[] memory creator20Assets,
        ERC721Asset[] memory creator721Assets,
        ERC1155Asset[] memory creator1155Assets,
        uint256 counterpartyNativeTokens,
        ERC20Asset[] memory counterparty20Assets,
        ERC721Asset[] memory counterparty721Assets,
        ERC1155Asset[] memory counterparty1155Assets
    ) external newTradesNotSuspended allOperationsNotSuspended {
        if (counterparty == msg.sender || counterparty == address(0)) {
            revert InvalidCounterparty();
        }

        if (refer == msg.sender || refer == counterparty) {
            revert InvalidRefer();
        }

        if (
            (creatorNativeTokens == 0 &&
                creator20Assets.length == 0 &&
                creator721Assets.length == 0 &&
                creator1155Assets.length == 0) ||
            (counterpartyNativeTokens == 0 &&
                counterparty20Assets.length == 0 &&
                counterparty721Assets.length == 0 &&
                counterparty1155Assets.length == 0)
        ) {
            revert InvalidAssets();
        }

        if (trades[id].creator != address(0)) {
            revert TradeAlreadyExists();
        }

        if (expireAt <= block.timestamp) {
            revert InvalidExpiration();
        }

        // Save native tokens counts
        trades[id].creatorNativeTokens = creatorNativeTokens;
        trades[id].counterpartyNativeTokens = counterpartyNativeTokens;

        // Copy creator' assets: solidity limitation of 'array of structs' forces us to manually copy elements
        for (uint256 i = 0; i < creator20Assets.length; ++i) {
            trades[id].creator20Assets.push(creator20Assets[i]);
        }
        for (uint256 i = 0; i < creator721Assets.length; ++i) {
            trades[id].creator721Assets.push(creator721Assets[i]);
        }
        for (uint256 i = 0; i < creator1155Assets.length; ++i) {
            trades[id].creator1155Assets.push(creator1155Assets[i]);
        }

        // Copy counterparty' requested assets: solidity limitation of 'array of structs' forces us to manually copy elements
        for (uint256 i = 0; i < counterparty20Assets.length; ++i) {
            trades[id].counterparty20Assets.push(counterparty20Assets[i]);
        }
        for (uint256 i = 0; i < counterparty721Assets.length; ++i) {
            trades[id].counterparty721Assets.push(counterparty721Assets[i]);
        }
        for (uint256 i = 0; i < counterparty1155Assets.length; ++i) {
            trades[id].counterparty1155Assets.push(counterparty1155Assets[i]);
        }

        trades[id].creator = msg.sender;
        trades[id].counterparty = counterparty;
        trades[id].refer = refer;
        trades[id].expireAt = expireAt;

        emit TradeUpdated(TradeEvent.Offered, id, msg.sender);
    }

    function acceptTrade(string memory id)
        external
        payable
        allOperationsNotSuspended
        tradeIsOngoing(id)
        nativeTokensAndFeesAreProvided(trades[id].counterparty, trades[id].counterpartyNativeTokens)
    {
        if (msg.sender != trades[id].counterparty) {
            revert UserNotInTrade();
        }

        if (trades[id].accepted) {
            revert TradeIsAlreadyAccepted();
        }

        trades[id].accepted = true;

        // Track the funds provided by counterparty as pending, until the trade gets resolved (executed or canceled)
        totalPendingFunds += msg.value;

        emit TradeUpdated(TradeEvent.Accepted, id, msg.sender);
    }

    function executeTrade(string memory id)
        external
        payable
        nonReentrant
        allOperationsNotSuspended
        tradeIsOngoing(id)
        tradeIsAccepted(id)
        nativeTokensAndFeesAreProvided(trades[id].creator, trades[id].creatorNativeTokens)
    {
        if (msg.sender != trades[id].creator) {
            revert UserNotInTrade();
        }

        uint256 pendingFunds = TradingFee + trades[id].counterpartyNativeTokens;
        totalPendingFunds -= pendingFunds;

        // Transfer native tokens
        if (trades[id].creatorNativeTokens > 0) {
            _transferNativeTokens({
                to: trades[id].counterparty,
                amount: trades[id].creatorNativeTokens
            });
        }
        if (trades[id].counterpartyNativeTokens > 0) {
            _transferNativeTokens({
                to: trades[id].creator,
                amount: trades[id].counterpartyNativeTokens
            });
        }

        // Transfer creator's assets
        _transferAssets({
            erc20: trades[id].creator20Assets,
            erc721: trades[id].creator721Assets,
            erc1155: trades[id].creator1155Assets,
            from: trades[id].creator,
            to: trades[id].counterparty
        });

        // Transfer counterparty's assets
        _transferAssets({
            erc20: trades[id].counterparty20Assets,
            erc721: trades[id].counterparty721Assets,
            erc1155: trades[id].counterparty1155Assets,
            from: trades[id].counterparty,
            to: trades[id].creator
        });

        if (trades[id].refer != address(0) && referBasisPoint > 0) {
            // Send percentage of total trade revenue (TradingFee twice to account for both parties) to refer.
            // If refer is an invalid address that cannot receive ether, ignore and let the trade execute nonetheless
            (bool success, ) = trades[id].refer.call{
                value: (TradingFee * 2 * referBasisPoint) / 10_000
            }("");
        }

        // Remove the trade now it's executed
        delete trades[id];

        emit TradeUpdated(TradeEvent.Executed, id, msg.sender);
    }

    function cancelTrade(string memory id)
        external
        nonReentrant
        allOperationsNotSuspended
        tradeIsOngoing(id)
        participatesInTrade(id)
    {
        if (trades[id].accepted) {
            uint256 pendingFunds = TradingFee + trades[id].counterpartyNativeTokens;
            totalPendingFunds -= pendingFunds;

            // Transfer back the counterparty's fees and assets
            _transferNativeTokens({to: trades[id].counterparty, amount: pendingFunds});
        }

        delete trades[id];

        emit TradeUpdated(TradeEvent.Cancelled, id, msg.sender);
    }

    function withdrawExpiredTrade(string memory id)
        external
        nonReentrant
        allOperationsNotSuspended
        tradeIsExpired(id)
    {
        if (!trades[id].accepted || msg.sender != trades[id].counterparty) {
            revert();
        }

        uint256 funds = TradingFee + trades[id].counterpartyNativeTokens;
        totalPendingFunds -= funds;

        // Transfer back the counterparty's fees and assets
        _transferNativeTokens({to: trades[id].counterparty, amount: funds});

        delete trades[id];

        emit TradeUpdated(TradeEvent.ExpiredWithdrawn, id, msg.sender);
    }

    modifier tradeIsOngoing(string memory id) {
        if (trades[id].creator == address(0)) {
            revert TradeDoesNotExist();
        }

        if (trades[id].expireAt <= block.timestamp) {
            revert TradeHasExpired();
        }

        _;
    }

    modifier tradeIsExpired(string memory id) {
        if (trades[id].creator == address(0)) {
            revert TradeDoesNotExist();
        }

        if (trades[id].expireAt > block.timestamp) {
            revert TradeIsNotExpired();
        }

        _;
    }

    modifier tradeIsAccepted(string memory id) {
        if (!trades[id].accepted) {
            revert TradeIsNotAccepted();
        }

        _;
    }

    modifier participatesInTrade(string memory id) {
        if (msg.sender != trades[id].creator && msg.sender != trades[id].counterparty) {
            revert UserNotInTrade();
        }

        _;
    }

    modifier nativeTokensAndFeesAreProvided(address account, uint256 nativeTokens) {
        if (msg.value != TradingFee + nativeTokens) {
            revert InvalidPayment();
        }

        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "solmate/auth/Owned.sol";

error Suspended();
error NotSuspended();

/// @dev Handles the admin part of the contract: suspension, commission settings, etc
abstract contract Configurable is Owned {
    bool public newTradesSuspended;
    bool public allOperationsSuspended;
    uint256 public referBasisPoint;

    constructor(address owner) Owned(owner) {}

    function setNewTradeSuspended(bool suspended) external onlyOwner {
        newTradesSuspended = suspended;
    }

    function setAllOperationsSuspended(bool suspended) external onlyOwner {
        allOperationsSuspended = suspended;
    }

    function setReferBasisPoint(uint256 referBasisPoint_) external onlyOwner {
        if (referBasisPoint_ < 0 || referBasisPoint_ > 10000) {
            revert();
        }

        referBasisPoint = referBasisPoint_;
    }

    modifier newTradesNotSuspended() {
        if (newTradesSuspended) {
            revert Suspended();
        }

        _;
    }

    modifier allOperationsNotSuspended() {
        if (allOperationsSuspended) {
            revert Suspended();
        }

        _;
    }

    modifier allOperationsAreSuspended() {
        if (!allOperationsSuspended) {
            revert NotSuspended();
        }

        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

struct ERC721Asset {
    address collection;
    uint64 id;
}

struct ERC20Asset {
    address collection;
    uint64 amount;
}

struct ERC1155Asset {
    address collection;
    uint256[] ids;
    uint256[] amounts;
}

error NativeTokensTransferFailed(address to, uint256 amount);

abstract contract AssetHandler is IERC721Receiver, IERC1155Receiver {
    using SafeERC20 for IERC20;

    function _transferNativeTokens(uint256 amount, address to) internal {
        (bool success, ) = to.call{value: amount}("");
        if (!success) {
            revert NativeTokensTransferFailed(to, amount);
        }
    }

    function _transfer20Asset(
        ERC20Asset memory asset,
        address from,
        address to
    ) internal {
        IERC20 collection = IERC20(asset.collection);
        if (from == address(this)) {
            collection.safeTransfer(to, asset.amount);
        } else {
            collection.safeTransferFrom(from, to, asset.amount);
        }
    }

    function _transfer721Asset(
        ERC721Asset memory asset,
        address from,
        address to
    ) internal {
        IERC721 collection = IERC721(asset.collection);
        collection.safeTransferFrom(from, to, asset.id);
    }

    function _transfer1155Asset(
        ERC1155Asset memory asset,
        address from,
        address to
    ) internal {
        IERC1155 collection = IERC1155(asset.collection);
        collection.safeBatchTransferFrom(from, to, asset.ids, asset.amounts, "");
    }

    function _transferAssets(
        ERC20Asset[] memory erc20,
        ERC721Asset[] memory erc721,
        ERC1155Asset[] memory erc1155,
        address from,
        address to
    ) internal {
        for (uint256 i = 0; i < erc20.length; ++i) {
            _transfer20Asset(erc20[i], from, to);
        }
        for (uint256 i = 0; i < erc721.length; ++i) {
            _transfer721Asset(erc721[i], from, to);
        }
        for (uint256 i = 0; i < erc1155.length; ++i) {
            _transfer1155Asset(erc1155[i], from, to);
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC721).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "solmate/auth/Owned.sol";

import "./Configurable.sol";

uint256 constant TradingFee = 0.005 ether;

error NoFundsAvailable();
error WithdrawFailed();

abstract contract Banker is Owned, Configurable {
    /// Funds from ongoing trades where counterparty has already accepted and put funds in escrow
    uint256 public totalPendingFunds;

    /// Withdraw all funds available, minus the amount belonging to trades funds
    function withdraw(address account) external onlyOwner {
        uint256 funds = address(this).balance - totalPendingFunds;
        if (funds == 0) {
            revert NoFundsAvailable();
        }

        (bool success, ) = account.call{value: funds}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }

    /// Withdraw all funds, without taking in account the trades funds
    function unsafeWithdraw(address account) external onlyOwner allOperationsAreSuspended {
        if (address(this).balance == 0) {
            revert NoFundsAvailable();
        }

        (bool success, ) = account.call{value: address(this).balance}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
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

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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