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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IPool} from "./interfaces/IPool.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

/**
 * @notice The IncomeRouter contract is an escrow contract that
 * borrowers can use to share their income.
 */
contract IncomeRouter is Ownable {
    struct NFRData {
        /// The index of the nfr data
        uint256 priority;
        /// The amount of tokens the NFR
        /// holder can withdraw
        uint256 balance;
        /// The original face value the NFR was minted for
        uint256 faceValue;
        /// The maturity date of the NFR
        uint256 maturityDate;
        /// The address of the income source
        address from;
    }

    struct State {
        /// The index of the current NFR that
        /// can withdraw income
        uint256 waterfallIdx;
        /// The total balance owed by the router to all
        /// shared NFRs
        uint256 owedBalance;
        /// An ordered list of NFR Ids
        uint256[] nfrWaterfall;
    }

    /// @notice This error is thrown whenever the router
    /// does not have enough funds for an address to withdraw
    error InsufficientBalance();

    /// @notice This event is emitted whenever the income in the router
    /// is shared to nfr holders
    /// @param nfrId The ID of the NFR income is being shared to
    /// @param amount The amount of income that is being shared
    event IncomeShared(uint256 nfrId, uint256 amount);

    /// @notice This event is emitted whenever income is withdrawn
    /// from the router
    /// @param recipient The address receiving the funds
    /// @param amount The amount that was withdrawed
    event IncomeClaimed(address recipient, uint256 amount);

    /// @notice The current state of the router contract
    State private s_routerState;

    /// @notice The ERC20 token deposited that is managed
    /// by the router contract
    IERC20 private immutable i_token;

    /// @notice Mapping between NFR ID to the shared NFR
    mapping(uint256 => NFRData) private s_nfrs;

    constructor(IERC20 token) Ownable() {
        i_token = token;
    }

    /**
     * @notice Shares the tokens in the router to an NFR holder
     * @param nfrId The ID of the NFR income is being shared to
     * @param from The income source address
     * @param maturityDate The maturity date of the loan
     * @param amount The amount of tokens being shared
     * @dev This function can only be executed by the pool
     */
    function share(
        uint256 nfrId,
        address from,
        uint256 maturityDate,
        uint256 amount
    ) external onlyOwner {
        NFRData memory nfrData = NFRData({
            balance: amount,
            faceValue: amount,
            from: from,
            maturityDate: maturityDate,
            priority: s_routerState.nfrWaterfall.length
        });
        s_nfrs[nfrId] = nfrData;
        s_routerState.owedBalance += amount;
        s_routerState.nfrWaterfall.push(nfrId);
        emit IncomeShared(nfrId, amount);
    }

    /**
     * @notice Withdraws tokens from the router using to an NFR owner
     * NFR's balance.
     */
    function withdrawFromLatestNFR() external {
        State storage state = s_routerState;
        uint256 latestNFRId = state.nfrWaterfall[state.waterfallIdx];

        NFRData storage nfrData = s_nfrs[latestNFRId];
        uint256 withdrawableAmount = nfrData.balance;
        _checkPoolBalance(withdrawableAmount);

        // Update balances
        nfrData.balance -= withdrawableAmount;
        state.owedBalance -= withdrawableAmount;

        // Allow next nfr to be withdrawn
        if (nfrData.balance == 0) {
            state.waterfallIdx++;
        }

        // Transfer withdrawed NFR balance
        address poolAddr = owner(); // Income Router is owned by the pool
        address nfrOwner = IPool(poolAddr).ownerOf(latestNFRId);
        IERC20(i_token).transfer(nfrOwner, withdrawableAmount);
        emit IncomeClaimed(nfrOwner, withdrawableAmount);
    }

    /**
     * @notice Withdraws tokens from the router using to a recipient
     */
    function withdrawIncome(address recipient) external onlyOwner {
        uint256 ownerWithdrawableAmount = getOwnerWithdrawableAmount();
        _checkPoolBalance(ownerWithdrawableAmount);
        IERC20(i_token).transfer(recipient, ownerWithdrawableAmount);
        emit IncomeClaimed(recipient, ownerWithdrawableAmount);
    }

    function getToken() external view returns (address) {
        return address(i_token);
    }

    function getNFR(uint256 nfrId) external view returns (NFRData memory) {
        NFRData memory nfrData = s_nfrs[nfrId];
        nfrData.balance = nfrData.faceValue - getNFRWithdrawableAmount(nfrId);
        return nfrData;
    }

    function getOwnerWithdrawableAmount() public view returns (uint256) {
        uint256 tokenBalance = IERC20(i_token).balanceOf(address(this));
        return
            tokenBalance < s_routerState.owedBalance
                ? 0
                : tokenBalance - s_routerState.owedBalance;
    }

    function getNFRWithdrawableAmount(
        uint256 nfrId
    ) public view returns (uint256) {
        NFRData storage nfrData = s_nfrs[nfrId];
        if (
            nfrData.from == address(0) ||
            nfrData.priority > s_routerState.waterfallIdx
        ) return 0;

        uint256 tokenBalance = IERC20(i_token).balanceOf(address(this));
        return nfrData.balance > tokenBalance ? tokenBalance : nfrData.balance;
    }

    /**
     * @notice Checks to see if the pool has sufficient funds to cover a withdrawal
     * @param withdrawableAmount The amount being withdrawn
     */
    function _checkPoolBalance(uint256 withdrawableAmount) private view {
        uint256 routerBalance = IERC20(i_token).balanceOf(address(this));
        if (routerBalance < withdrawableAmount) revert InsufficientBalance();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IPool is IERC721 {
    /**
     * @notice Creates a new router contract with an ERC20 token
     * @param token The ERC20 token the income router manages
     * @return address The address of the newly created router
     */
    function createRouter(IERC20 token) external returns (address);

    /**
     * @notice Sets a new verifier for a source
     * @param source The hash of the verification source
     * @param verifier The address of the verifier contract
     */
    function setVerifier(bytes32 source, address verifier) external;

    /**
     * @notice Sets a new verifier's approval for a source
     * @param source The hash of the verification source
     * @param isApproved True if the verifier is approved
     */
    function setVerifierApproval(bytes32 source, bool isApproved) external;

    /**
     * @notice Returns the address of a verifier
     * @param source The hash of the verification source
     * @return address The address of the verifier
     * @return bool True if verifier is approved
     */
    function getVerifier(bytes32 source) external returns (address, bool);

    /**
     * @notice Returns the owner of a router
     * @param routerAddress The address of the router being queried
     * @return address The address of the router's owner
     */
    function getRouterOwner(
        address routerAddress
    ) external view returns (address);

    /**
     * @notice Requests to mint a new NFR to share income
     * @param verificationSource The source used to verify future income
     * @param routerAddr The address of the income router contract to
     * claim income from
     * @param incomeSource The source of income
     * @param maturityDate The maturity date of this NFR
     * @param faceValue The face value of the NFR
     * @param data Arbitrary data that is used to verify income
     */
    function requestToMint(
        bytes32 verificationSource,
        address routerAddr,
        address incomeSource,
        uint256 maturityDate,
        uint256 faceValue,
        bytes memory data
    ) external;

    /**
     * @notice Mints a new NFR to share income
     * @param verificationSource The source used to verify future income
     * @param routerAddr The address of the income router contract to
     * claim income from
     * @param incomeSource The source of income
     * @param maturityDate The maturity date of this NFR
     * @param faceValue The face value of the NFR
     * @param owner The original owner of the NFT
     */
    function mint(
        bytes32 verificationSource,
        address routerAddr,
        address incomeSource,
        uint256 maturityDate,
        uint256 faceValue,
        address owner
    ) external;

    /**
     * @notice Withdraws income using the router's latest NFR
     * @param routerAddr The address of the income router to withdraw from
     * using an NFR
     */
    function withdrawFromLatestNFR(address routerAddr) external;

    /**
     * @notice Withdraws income from an income router
     * @param routerAddr The address of the income router to withdraw from
     */
    function withdrawFromIncomeRouter(address routerAddr) external;
}