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
        /// The amount of tokens the NFR
        /// holder can withdraw
        uint256 balance;
        /// The original face value the NFR was minted for
        uint256 faceValue;
        /// The maturity date of the NFR
        uint256 maturityDate;
        /// The address of the income source
        address from;
        // The address of the token the nfr loan is denominated in
        address token;
        /// Total Income
        uint256 totalIncome;
        /// The source used to verify income
        bytes32 verificationSource;
    }

    /// @notice This error is thrown whenever the router
    /// does not have enough funds for an address to withdraw
    error InsufficientBalance();

    /// @notice This error is thrown when a NFR with ID 0 is
    /// shared
    error InvalidNFR();

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

    /// @notice Mapping between NFR ID to the shared NFR
    mapping(uint256 => NFRData) private s_nfrs;

    /// @notice Sorted list of NFRs to be paid.  The map
    /// tracks which NFR should be paid next for a token
    mapping(address => mapping(uint256 => uint256)) private s_waterfalls;

    /// @notice The ID of the first NFR to be paid for a token
    mapping(address => uint256) private s_nfrToBePaid;

    constructor() Ownable() {}

    /**
     * @notice Shares the tokens in the router to an NFR holder
     * @param nfrId The ID of the NFR income is being shared to
     * @param from The income source address
     * @param maturityDate The maturity date of the loan
     * @param amount The amount of tokens being shared
     * @param verificationSource The source used to verify income
     * @param totalIncome The total source's income
     * @dev This function can only be executed by the pool
     */
    function share(
        uint256 nfrId,
        address from,
        address token,
        uint256 maturityDate,
        uint256 amount,
        bytes32 verificationSource,
        uint256 totalIncome
    ) external onlyOwner {
        if (nfrId == 0 || maturityDate <= block.timestamp) revert InvalidNFR();

        NFRData memory nfrData = NFRData({
            balance: amount,
            faceValue: amount,
            from: from,
            maturityDate: maturityDate,
            verificationSource: verificationSource,
            totalIncome: totalIncome,
            token: token
        });
        s_nfrs[nfrId] = nfrData;

        if (s_nfrToBePaid[token] == 0) {
            s_nfrToBePaid[token] = nfrId;
        } else {
            uint256 currNFRId = s_nfrToBePaid[token];

            // If new NFR has a maturity date earlier than the NFR with the earliest maturity date
            // then put the newly minted NFR at the front
            if (maturityDate < s_nfrs[currNFRId].maturityDate) {
                s_nfrToBePaid[token] = nfrId;
            }

            // We acknowledge that there is a risk that the owner will accidentally DDOS
            // the contract by minting too many open NFRs.  We think that the
            // risk for this is low as users will not mint too many open NFRs at any time.
            while (
                s_waterfalls[token][currNFRId] > 0 &&
                s_nfrs[s_waterfalls[token][currNFRId]].maturityDate <=
                maturityDate
            ) {
                currNFRId = s_waterfalls[token][currNFRId];
            }

            // If at the end of the waterfall
            if (s_waterfalls[token][currNFRId] == 0) {
                s_waterfalls[token][currNFRId] = nfrId;
            } else {
                // Reorder waterfall as the new NFR being minted needs to be
                // inserted in the middle.
                s_waterfalls[token][nfrId] = s_waterfalls[token][currNFRId];
                s_waterfalls[token][currNFRId] = nfrId;
            }
        }

        emit IncomeShared(nfrId, amount);
    }

    /**
     * @notice Withdraws tokens from the router using to an NFR owner
     * NFR's balance.
     */
    function withdrawFromLatestNFR(address token) external {
        uint256 latestNFRId = s_nfrToBePaid[token];

        NFRData storage nfrData = s_nfrs[latestNFRId];
        uint256 withdrawableAmount = getNFRWithdrawableAmount(
            latestNFRId,
            token
        );

        // Update balances
        nfrData.balance -= withdrawableAmount;

        // Allow next nfr to be withdrawn
        if (nfrData.balance == 0) {
            s_nfrToBePaid[token] = s_waterfalls[token][latestNFRId];
        }

        // Transfer withdrawed NFR balance
        address poolAddr = owner(); // Income Router is owned by the pool
        address nfrOwner = IPool(poolAddr).ownerOf(latestNFRId);
        IERC20(token).transfer(nfrOwner, withdrawableAmount);
        emit IncomeClaimed(nfrOwner, withdrawableAmount);
    }

    /**
     * @notice Withdraws tokens from the router using to a recipient
     */
    function withdrawIncome(
        address recipient,
        address token,
        address feeRecipient,
        uint256 feeDenominator
    ) external onlyOwner {
        uint256 ownerWithdrawableAmount = getOwnerWithdrawableAmount(token);
        uint256 feeRepaymentAmount = ownerWithdrawableAmount / feeDenominator;
        IERC20(token).transfer(feeRecipient, feeRepaymentAmount);
        IERC20(token).transfer(
            recipient,
            ownerWithdrawableAmount - feeRepaymentAmount
        );
        emit IncomeClaimed(recipient, ownerWithdrawableAmount);
    }

    function getNFR(uint256 nfrId) external view returns (NFRData memory) {
        NFRData memory nfrData = s_nfrs[nfrId];
        nfrData.balance =
            nfrData.faceValue -
            getNFRWithdrawableAmount(nfrId, nfrData.token);
        return nfrData;
    }

    /**
     * @notice Returns the amount the income router owner can withdraw
     * from the contract
     * @return uint256 The amount the owner can withdraw from the contract
     */
    function getOwnerWithdrawableAmount(
        address token
    ) public view returns (uint256) {
        uint256 currNFRId = s_nfrToBePaid[token];
        uint256 owedBalance = getNFRWithdrawableAmount(currNFRId, token);
        while (
            s_waterfalls[token][currNFRId] > 0 &&
            s_nfrs[s_waterfalls[token][currNFRId]].maturityDate <=
            block.timestamp
        ) {
            currNFRId = s_waterfalls[token][currNFRId];
            owedBalance += s_nfrs[currNFRId].balance;
        }
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        return tokenBalance < owedBalance ? 0 : tokenBalance - owedBalance;
    }

    /**
     * @notice Returns the amount an NFR can withdraw from the router contract
     * @param nfrId The ID of the NFR being queried
     * @return uint256 The amount the NFR can withdraw
     */
    function getNFRWithdrawableAmount(
        uint256 nfrId,
        address token
    ) public view returns (uint256) {
        if (nfrId != s_nfrToBePaid[token]) return 0;
        NFRData storage nfrData = s_nfrs[nfrId];
        if (nfrData.maturityDate > block.timestamp) return 0;

        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        return nfrData.balance > tokenBalance ? tokenBalance : nfrData.balance;
    }

    function getNFRToBePaid(address token) external view returns (uint256) {
        return s_nfrToBePaid[token];
    }

    function getNFRPriority(
        address token,
        uint256 nfrId
    ) external view returns (uint256) {
        uint256 currId = s_nfrToBePaid[token];
        uint256 priority;
        while (nfrId != currId) {
            currId = s_waterfalls[token][currId];
            priority++;
        }
        return priority;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IPool is IERC721 {
    /**
     * @notice Creates a new router contract
     * @return address The address of the newly created router
     */
    function createRouter() external returns (address);

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
     * @param owner The owner address being queried for
     * @return address The address of the router belonging to the owner
     */
    function getRouter(address owner) external view returns (address);

    /**
     * @notice Requests to mint a new NFR to share income
     * @param verificationSource The source used to verify future income
     * @param incomeSource The source of income
     * @param maturityDate The maturity date of this NFR
     * @param faceValue The face value of the NFR
     * @param data Arbitrary data that is used to verify income
     */
    function requestToMint(
        bytes32 verificationSource,
        address incomeSource,
        address token,
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
     * @param totalIncome The borrower's total income
     * @param owner The original owner of the NFT
     */
    function mint(
        bytes32 verificationSource,
        address routerAddr,
        address incomeSource,
        uint256 maturityDate,
        uint256 faceValue,
        uint256 totalIncome,
        address owner,
        address token
    ) external;

    /**
     * @notice Withdraws income using the router's latest NFR
     * @param routerAddr The address of the income router to withdraw from
     * using an NFR
     * @param token The address of the token to withdraw
     */
    function withdrawFromLatestNFR(address routerAddr, address token) external;

    /**
     * @notice Withdraws income from an income router
     * @param token The address of the token to withdraw
     */
    function withdrawFromIncomeRouter(address token) external;
}