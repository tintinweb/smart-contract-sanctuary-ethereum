//  ____   ___  ____ ___ _   _ __  __ 
// |  _ \ / _ \|  _ \_ _| | | |  \/  |
// | |_) | | | | | | | || | | | |\/| |
// |  __/| |_| | |_| | || |_| | |  | |
// |_|    \___/|____/___|\___/|_|  |_|
//        
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/* ----------------------------------------------------------------------------
* Staking for the Podium Genesis NFT
* Note this allows for staking and calculation. No withdrawal exists yet.
* This will be in another contract. Allow people to start earning ASAP.
* Daily staking rate set to 100 as round number. Rate will be multiplied/devided
* With ERC20 implementation
*
/ -------------------------------------------------------------------------- */

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PodiumGenesisStaking is ERC721Holder, ReentrancyGuard, Ownable, Pausable {

    // Declerations
    // ------------------------------------------------------------------------

    IERC721 public PodiumGenesis; // Podium Genesis NFT to be staked
    uint256 public rewardRate = 66; // Daily reward rate. See above.
    mapping(address => bool) public teamMember; 
    address withdrawContract;

    uint256 public totalStaked;
    mapping(address => uint256) public balanceOfStaked; // Count of staked by Address
    mapping(uint256 => address) public stakedAssetsByToken; // Staked assets and owner
    mapping(address => uint256[]) public stakedAssetsByAddr; // Staked assets and owner
    mapping(address => uint256) public earnedRewards; // Earned so far
    mapping(address => uint256) public dataLastUpdated; // when was address data updated
    mapping(bytes4 => bool) public functionLocked;

    constructor(address _PodiumGenesis) 
    {
        PodiumGenesis = IERC721(_PodiumGenesis);
        teamMember[msg.sender] = true;
    }

    event Staked(
        address indexed addressSender, 
        uint256 quantity, 
        uint256[] tokenIds
    );
    event UnStaked(
        address indexed addressSender, 
        uint256 quantity, 
        uint256[] tokenIds
    );

    // Staking functions and helpers
    // ------------------------------------------------------------------------

    /*
     * @notice Stake 1 or more NFTs
     * @param `tokenIds` a list of NFTs to be staked
    */
    function stake(uint256[] memory tokenIds) external nonReentrant whenNotPaused updateRewardData {
        require(tokenIds.length > 0, "Need to provide tokenIds");

        uint256 quantity; // Do not use length as safeTransfer check not performed
        for (uint256 i = 0; i < tokenIds.length; i += 1) {
            
            PodiumGenesis.safeTransferFrom(msg.sender, address(this), tokenIds[i]);


            stakedAssetsByToken[tokenIds[i]] = msg.sender;
            stakedAssetsByAddr[msg.sender].push(tokenIds[i]);
            quantity++;
        }

        totalStaked += quantity;
        balanceOfStaked[msg.sender] += quantity;
        emit Staked(msg.sender, quantity, tokenIds); 
    }

    /*
     * @notice Withdraw 1 or more NFTs
     * @param `tokenIds` a list of NFTs to be unstaked
     */
    function unstake(uint256[] memory tokenIds) public nonReentrant whenNotPaused updateRewardData {
        require(tokenIds.length != 0, "Staking: No tokenIds provided");

        uint256 quantity;
        for (uint256 i = 0; i < tokenIds.length; i += 1) {
            // Confirm ownership
            require(
                stakedAssetsByToken[tokenIds[i]] == msg.sender,
                "Staking: Not the staker of the token"
            );
            
            // Replace the unstake with the last in the list
            
            uint256 popped = stakedAssetsByAddr[msg.sender][balanceOfStaked[msg.sender] - 1];
            stakedAssetsByAddr[msg.sender].pop();

            if (popped != tokenIds[i]) {
                uint256 tokenStakeIndex = 0;
                while (stakedAssetsByAddr[msg.sender][tokenStakeIndex] != tokenIds[i]) {
                    tokenStakeIndex++;
                }
                stakedAssetsByAddr[msg.sender][tokenStakeIndex] = popped;
            }

            stakedAssetsByToken[tokenIds[i]] = address(0);
            quantity++;

            // Send back the NFT
            PodiumGenesis.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
            balanceOfStaked[msg.sender]--;
            
        }
        totalStaked -= quantity;

        emit UnStaked(msg.sender, quantity, tokenIds);
    }


    /*
     * @notice Modifier called to updateRewards when needed (by stake and unstake, write them)
    */
    modifier updateRewardData() {
        earnedRewards[msg.sender] += _getPending(msg.sender);
        dataLastUpdated[msg.sender] = block.timestamp;
        _;
    }


    /*
     * @notice Update rewards rate for tokens
     * @param `_newReward` new reward value
    */
    function updateRewardRate(uint256 _newReward) public onlyTeamMember {
        rewardRate = _newReward;
    }

    /*
     * @notice How many pending tokens are earned
     * Note this is used internally and added to earned set later
     * @param `account` The address of the staker account
     * @return The amount of pending tokens
    */
    function _getPending(address account) internal view returns (uint256) {
        return
            (   
                (balanceOfStaked[account] * rewardRate) * 
                ((block.timestamp - dataLastUpdated[account]) / 1 days)
            );
    }

    /*
     * @notice Withdraw funds from the child contract
     * @param account for which withdrawal will be done
     * returns amount to be withdrawn
    */
    function withdraw(address account) external onlyWithdrawContract updateRewardData nonReentrant returns(uint256) {
        uint256 withdrawAmount = getEarnedAmount(account);
        earnedRewards[account] = 0;
        return withdrawAmount;
    }


    /*
     * @notice Total ammount earned
     * @param `account` The address of the staker account
     * @return The total ammount earned
    */
    function getEarnedAmount(address account) public view returns (uint256) {
        return earnedRewards[account] + _getPending(account);
    }


    /*
     * @notice Pause used to pause staking if needed
    */
    function pause() external onlyTeamMember {
        _pause();
    }

    /*
     * @notice Unpause used to unpause staking if needed
    */
    function unpause() external onlyTeamMember {
        _unpause();
    }


    /**
     * @dev Throws if called by any account other than team members
     */
    modifier onlyTeamMember() {
        require(teamMember[msg.sender], "Caller is not an owner");
        _;
    }

    /**
     * Add new team meber role with admin permissions
     */
    function addTeamMemberAdmin(address newMember) external onlyTeamMember {
        teamMember[newMember] = true;
    }

    /**
     * Remove team meber role from admin permissions
     */
    function removeTeamMemberAdmin(address newMember) external onlyTeamMember {
        teamMember[newMember] = false;
    }

    /**
     * Returns true if address is team member
     */
    function isTeamMemberAdmin(address checkAddress) public view onlyTeamMember returns (bool) {
        return teamMember[checkAddress];
    }


    /**
     * @dev Throws if called by any account other than team members
     */
    modifier onlyWithdrawContract() {
        require(withdrawContract == msg.sender, "Caller is not withdraw contract");
        _;
    }


    /**
     * Updates contract that can withdraw
     */
    function updateWithdrawContract(address _newWithdrawContract) external lockable onlyTeamMember {
        withdrawContract = _newWithdrawContract;
    }

    /**
     * @notice Modifier applied to functions that will be disabled when they're no longer needed
     */
    modifier lockable() {
        require(!functionLocked[msg.sig], "Function has been locked");
        _;
    }


    /**
     * @notice Lock individual functions that are no longer needed
     * @dev Only affects functions with the lockable modifier
     * @param id First 4 bytes of the calldata (i.e. function identifier)
     */
    function lockFunction(bytes4 id) public onlyTeamMember {
        functionLocked[id] = true;
    }

     /**
     * Recover tokens accidentally sent to contract without explicit owner
     */
    function strandedRecovery(address to, uint256 tokenId) external onlyTeamMember {
        require(stakedAssetsByToken[tokenId] == address(0), "Token is not in limbo"); 

        PodiumGenesis.safeTransferFrom(address(this), to, tokenId);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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