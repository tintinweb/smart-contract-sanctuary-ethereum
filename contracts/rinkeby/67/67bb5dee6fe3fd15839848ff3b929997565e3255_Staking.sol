/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
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
// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
// File: @openzeppelin/contracts/utils/introspection/ERC165.sol
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

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
// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}
// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
// File: @openzeppelin/contracts/token/ERC721/IERC721.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)
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
// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
// File: @openzeppelin/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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
// File: @openzeppelin/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)
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
// File: Staking.sol
// Staking.sol
contract Staking is ERC721Holder, ERC1155Holder, Ownable {
    address public whaleMakerAddress = 0x60000937f603F5121427956c9f65c3c84B5873AF;
    address public alphaPassAddress = 0xFdFfc7067d0f51dbCF1fe0b0862269AD0910f849;
    address public podAddress = 0x0e352065a05a3659dC54AE24F637168C511173b2;
    address public stakeMasterAddress = 0xDBef1bbCb494fAcd6cD1BF426e25dA7A10d96eAa;
    address nullAddress = 0x0000000000000000000000000000000000000000;
    uint256 public maxWalletStaked = 10;
    uint256 public contractPublishedAt = block.timestamp;
    uint256 oneMonthSeconds = 2592000; // 30 days in seconds
    struct StakingInfo {
        uint256 whaleId;
        uint256 alphaId;
        uint256 stakedAt;
    }
    mapping(address => StakingInfo[]) private _stakers;
    struct RewardState {
        uint256 unstakedRewardsAmount;
        uint256 claimedAmount;
        uint256 lastClaimedAt;
    }
    mapping(address => RewardState) private _stakerRewards;
    uint256 public claimStartTime = 1672531200; // Jan 1 2023 00:00:00 AM

    uint256[] public rewardsStepsTimestamp = [1672531199, 1704067199, 1735689599, 1767225599, 1798761599, 1830297599, 1956527999]; 
    mapping(uint256 => uint256) public rewardsStepsMonthlyAmount;

    event Staked(address staker, uint256 whaleId, uint256 alphaId);
    event Unstaked(address staker, uint256 whaleId, uint256 alphaId);
    event Claimed(address staker, uint256 amount);

    constructor() {
        rewardsStepsMonthlyAmount[1672531199] = 4500; // Dec 31 2022 11:59:59 PM
        rewardsStepsMonthlyAmount[1704067199] = 3500; // Dec 31 2023 11:59:59 PM
        rewardsStepsMonthlyAmount[1735689599] = 2500; // Dec 31 2024 11:59:59 PM
        rewardsStepsMonthlyAmount[1767225599] = 1500; // Dec 31 2025 11:59:59 PM
        rewardsStepsMonthlyAmount[1798761599] = 1000; // Dec 31 2026 11:59:59 PM
        rewardsStepsMonthlyAmount[1830297599] = 500; // Dec 31 2027 11:59:59 PM
        rewardsStepsMonthlyAmount[1956527999] = 250; // Dec 31 2031 11:59:59 PM
    }
    function getTokensStaked(address staker) public view returns (StakingInfo[] memory) {
        return _stakers[staker];
    }
    function _remove(address staker, uint256 index) internal {
        if (index >= _stakers[staker].length) return;
        for (uint256 i=index; i<_stakers[staker].length-1; i++) {
            _stakers[staker][i] = _stakers[staker][i + 1];
        }
        _stakers[staker].pop();
    }
    function _calculateRewards(address staker, uint256 stakeId) internal view returns (uint256) {
        require(stakeId<_stakers[staker].length);
        uint256 rewards = 0;
        uint256 staked_secs; // The seconds of token staken in this step
        StakingInfo memory staking_info = _stakers[staker][stakeId];
        uint256 startTs = staking_info.stakedAt; // The timestamp that the step started
        for (uint256 i=0; i<rewardsStepsTimestamp.length; i++) {
            if (rewardsStepsTimestamp[i] < block.timestamp) {
                if (startTs < rewardsStepsTimestamp[i]) {
                    staked_secs = rewardsStepsTimestamp[i] - startTs + 1;
                    rewards = rewards + staked_secs * rewardsStepsMonthlyAmount[rewardsStepsTimestamp[i]] * 10 ** 18 / oneMonthSeconds;
                    startTs = rewardsStepsTimestamp[i] + 1;
                }
            } else { // the current step
                staked_secs = block.timestamp - startTs; 
                rewards = rewards + staked_secs * rewardsStepsMonthlyAmount[rewardsStepsTimestamp[i]] * 10 ** 18 / oneMonthSeconds;
                break; // Ignore the next steps
            }
        }
        return rewards;
    }
    function stakerRewardsState(address staker) public view returns (uint256 totalRewards, uint256 claimedAmount, uint256 lastClaimedAt) {
        StakingInfo[] memory staking_info = _stakers[staker];
        RewardState memory reward_state = _stakerRewards[staker];
        uint256 staked_rewards = 0;
        for (uint256 i = 0; i < staking_info.length; i++) {
            staked_rewards = staked_rewards + _calculateRewards(staker, i);
        }
        uint256 total_rewards = staked_rewards + reward_state.unstakedRewardsAmount;
        return (total_rewards, reward_state.claimedAmount, reward_state.lastClaimedAt);
    }
    function stake(uint256 whaleId, uint256 alphaId) public {
        require(_stakers[msg.sender].length+1<=maxWalletStaked, "EXCEED_MAX_WALLET_STAKED");
        require(
            IERC721(whaleMakerAddress).ownerOf(whaleId) == msg.sender && IERC1155(alphaPassAddress).balanceOf(msg.sender, alphaId) > 0,
            "NOT_BOTH_TOKEN_OWNER"
        );
        IERC721(whaleMakerAddress).safeTransferFrom(msg.sender, address(this), whaleId);
        IERC1155(alphaPassAddress).safeTransferFrom(msg.sender, address(this), alphaId, 1, "");
        _stakers[msg.sender].push(StakingInfo(whaleId, alphaId, block.timestamp));
        emit Staked(msg.sender, whaleId, alphaId);
    }
    function unstake(uint256 stakeId) public {
        require(claimStartTime < block.timestamp, "DISABLED_CLAIM");
        require(stakeId<_stakers[msg.sender].length, "WRONG_STAKE_ID");
        StakingInfo memory staking_info = _stakers[msg.sender][stakeId];
        IERC721(whaleMakerAddress).safeTransferFrom(address(this), msg.sender, staking_info.whaleId);
        IERC1155(alphaPassAddress).safeTransferFrom(address(this), msg.sender, staking_info.alphaId, 1, "");
        uint256 rewards_amount = _calculateRewards(msg.sender, stakeId);
        _stakerRewards[msg.sender].unstakedRewardsAmount = _stakerRewards[msg.sender].unstakedRewardsAmount + rewards_amount;
        _remove(msg.sender, stakeId);
        emit Unstaked(msg.sender, staking_info.whaleId, staking_info.alphaId);
    }
    function unstakeAll() public {
        require(claimStartTime < block.timestamp, "DISABLED_CLAIM");
        require(_stakers[msg.sender].length>0, "NO_TOKEN_STAKED");
        for (uint256 i = 0; i < _stakers[msg.sender].length; i++) {
            unstake(i);
        }
    }
    function claimableAmount(address staker) public view returns (uint256) {
        uint256 available_amount;
        uint256 total_rewards;
        uint256 claimed_amount;
        uint256 last_claimed_at;
        (total_rewards, claimed_amount, last_claimed_at) = stakerRewardsState(staker);
        if (last_claimed_at < claimStartTime) last_claimed_at = 1672531200;
        uint256 current_ts = block.timestamp;
        if (current_ts < claimStartTime) available_amount = uint256(0);
        else {
            if (current_ts >= 1704067200) { // after Jan 2024
                available_amount = total_rewards - claimed_amount;
            } else {
                if ((current_ts - last_claimed_at) < oneMonthSeconds) {
                    available_amount = uint256(0);
                } else {
                    if (1672531200 <= current_ts && current_ts < 1675209600) { // current date is in Jan 2023
                        available_amount = (total_rewards - claimed_amount) * 20 / 100; // 20%
                    } else {
                        uint256 month_counts = (current_ts - last_claimed_at) / oneMonthSeconds;
                        uint256 total_percent = month_counts * 727 / 100; // 7.27% per month
                        if (total_percent > 100) total_percent = 100;
                        available_amount = (total_rewards - claimed_amount) * total_percent / 100;
                    }
                }
            }
        }
        return available_amount;
    }
    function nextClaimInSeconds(address staker) public view returns (uint256) {
        uint256 next_claim_in;
        RewardState memory reward_state = _stakerRewards[staker];
        uint256 current_ts = block.timestamp;
        if (current_ts < claimStartTime) next_claim_in = claimStartTime - current_ts;
        else {
            if (current_ts >= 1704067200) { // after Jan 2024
                next_claim_in = uint256(0);
            } else {
                next_claim_in = reward_state.lastClaimedAt + oneMonthSeconds - current_ts;
            }
        }
        return next_claim_in;
    }
    function claim() public {
        uint256 amount = claimableAmount(msg.sender);
        require(amount > 0, "ZERO_AVAILABLE_AMOUNT");
        require(amount < IERC20(podAddress).balanceOf(stakeMasterAddress), "NOT_ENOUGH_POD_MASTER");
        IERC20(podAddress).transferFrom(stakeMasterAddress, msg.sender, amount);
        _stakerRewards[msg.sender].claimedAmount = _stakerRewards[msg.sender].claimedAmount + amount;
        _stakerRewards[msg.sender].lastClaimedAt = block.timestamp;
        emit Claimed(msg.sender, amount);
    }

    function currentMonthlyRewards() public view returns (uint256) {
        uint256 cur_rewards = uint256(0);
        for (uint256 i=0; i<=rewardsStepsTimestamp.length; i++) {
            if (block.timestamp <= rewardsStepsTimestamp[i]) {
                cur_rewards = rewardsStepsMonthlyAmount[rewardsStepsTimestamp[i]] * 10 ** 18;
                break;
            }
        }
        return cur_rewards;
    }
    // Owner functions
    function setWhaleMakerAddress(address newAddress) public onlyOwner {
        whaleMakerAddress = newAddress;
    }
    function setAlphaPassAddress(address newAddress) public onlyOwner {
        alphaPassAddress = newAddress;
    }
    function setPodAddress(address newAddress) public onlyOwner {
        podAddress = newAddress;
    }
    function setStakeMasterAddress(address newAddress) public onlyOwner {
        stakeMasterAddress = newAddress;
    }
    function setMaxWalletStaked(uint256 newValue) public onlyOwner {
        maxWalletStaked = newValue;
    }
    function setClaimStartTime(uint256 newClaimStartTime) public onlyOwner {
        claimStartTime = newClaimStartTime;
    }
    function withdrawETH() external onlyOwner {
        require(address(this).balance > 0, "NO_BALANCE");
        payable(msg.sender).transfer(address(this).balance);
    }
}