// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/*
 ____                   _           _         
|  _ \                 | |         | |        
| |_) | __ _ ___  ___  | |     __ _| |__  ___ 
|  _ < / _` / __|/ _ \ | |    / _` | '_ \/ __|
| |_) | (_| \__ \  __/ | |___| (_| | |_) \__ \
|____/ \__,_|___/\___| |______\__,_|_.__/|___/
                                              
*/

pragma solidity ^0.8.7;

/**
 * @title CheersUpPeriodStake
 * @author BaseLabs
 */
contract CheersUpPeriodStake is Ownable, ReentrancyGuard {
    event StakeStarted(uint256 indexed tokenId, address indexed account);
    event StakeStopped(uint256 indexed tokenId, address indexed account);
    event StakeInterrupted(uint256 indexed tokenId);
    event StakeConfigChanged(StakeConfig config);
    event TransferUnstakingToken(uint256 indexed tokenId, address indexed account);
    event StakingTokenTransfered(address indexed from, address indexed to, uint256 indexed tokenId);
    event Withdraw(address indexed account, uint256 amount);

    struct StakeStatus {
        address owner;
        uint256 lastStartTime;
        uint256 total;
    }
    struct StakeConfig {
        uint256 startTime;
        uint256 endTime;
    }
    struct StakeReward {
        bool isStaking;
        uint256 total;
        uint256 current;
        address owner;
    }
    string public name = "Cheers UP Period Stake";
    string public symbol = "CUPS";
    StakeConfig public stakeConfig;
    address public cheersUpPeriodContractAddress;
    mapping(uint256 => StakeStatus) private _stakeStatuses;
    IERC721 cheersUpPeriodContract;

    constructor(address cheersUpPeriodContractAddress_, StakeConfig memory stakeConfig_) {
        require(cheersUpPeriodContractAddress_ != address(0), "cheers up period contract address is required");
        cheersUpPeriodContractAddress = cheersUpPeriodContractAddress_;
        cheersUpPeriodContract = IERC721(cheersUpPeriodContractAddress);
        stakeConfig = stakeConfig_;
    }

    /***********************************|
    |               Core                |
    |__________________________________*/

    /**
     * @notice _stake is used to set the stake state of NFT.
     * @param owner_ the owner of the token
     * @param tokenId_ the tokenId of the token
     */
    function _stake(address owner_, uint256 tokenId_) internal {
        require(isStakeEnabled(), "stake is not allowed");
        StakeStatus storage status = _stakeStatuses[tokenId_];
        require(status.lastStartTime == 0, "token is staking");
        status.owner = owner_;
        status.lastStartTime = block.timestamp;
        emit StakeStarted(tokenId_, owner_);
    }

    /**
     * @notice unstake is used to release the stake state of a batch of tokenId.
     * @param tokenIds_ the tokenIds to operate
     */
    function unstake(uint256[] calldata tokenIds_) external nonReentrant {
        for (uint256 i; i < tokenIds_.length; i++) {
            _unstake(tokenIds_[i]);
        }
    }

    /**
     * @notice _unstake is used to release the stake status of a token.
     * @param tokenId_ the tokenId to operate
     */
    function _unstake(uint256 tokenId_) internal {
        StakeStatus storage status = _stakeStatuses[tokenId_];
        require(status.lastStartTime > 0, "token is not staking");
        require(status.owner == msg.sender || owner() == msg.sender, "not the owner");
        cheersUpPeriodContract.safeTransferFrom(address(this), status.owner, tokenId_);
        status.total += block.timestamp - status.lastStartTime;
        status.lastStartTime = 0;
        status.owner = address(0);
        emit StakeStopped(tokenId_, msg.sender);
    }

    /**
     * @notice safeTransferWhileStaking is used to transfer NFT ownership in the staked state.
     * @param to_ the address to which the `token owner` will be transferred
     * @param tokenId_ the tokenId to operate
     */
    function safeTransferWhileStaking(address to_, uint256 tokenId_) external nonReentrant {
        StakeStatus storage status = _stakeStatuses[tokenId_];
        require(status.lastStartTime > 0, "token is not staking");
        require(status.owner == msg.sender, "not the owner");
        status.owner = to_;
        emit StakingTokenTransfered(msg.sender, to_, tokenId_);
    }


    /***********************************|
    |             Getter                |
    |__________________________________*/

    /**
     * @notice getStakeReward is used to get the stake status of the token.
     * @param tokenId_ tokenId
     */
    function getStakeReward(uint256 tokenId_) external view returns (StakeReward memory) {
        StakeStatus memory status = _stakeStatuses[tokenId_];
        StakeReward memory reward;
        if (status.lastStartTime != 0) {
            reward.isStaking = true;
            reward.owner = status.owner;
            reward.current = block.timestamp - status.lastStartTime;
        }
        reward.total = status.total + reward.current;
        return reward;
    }
    
    /**
     * @notice isStakeEnabled is used to return whether the stake has been enabled.
     */
    function isStakeEnabled() public view returns (bool) {
        if (stakeConfig.endTime > 0 && block.timestamp > stakeConfig.endTime) {
            return false;
        }
        return stakeConfig.startTime > 0 && block.timestamp > stakeConfig.startTime;
    }

    /***********************************|
    |              Admin                |
    |__________________________________*/

    /**
     * @notice setStakeConfig is used to modify the stake configuration.
     * @param config_ the stake config
     */
    function setStakeConfig(StakeConfig calldata config_) external onlyOwner {
        stakeConfig = config_;
        emit StakeConfigChanged(stakeConfig);
    }

    /**
     * @notice interruptStake is used to forcibly interrupt NFTs in the stake state
     * and return them to their original owners.
     * This process is under the supervision of the community.
     * caution: Because safeTransferFrom is called for refund (when the target address is a contract,  its onERC721Received logic will be triggered), 
     * be sure to set a reasonable GasLimit before calling this method, or check adequately if the target address is a malicious contract to 
     * prevent bear the high gas cost accidentally.
     * @param tokenIds_ the tokenId list
     */
    function interruptStake(uint256[] calldata tokenIds_) external onlyOwner {
        for (uint256 i; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            _unstake(tokenId);
            emit StakeInterrupted(tokenId);
        }
    }

    /**
     * @notice transferUnstakingTokens is used to return the NFT that was mistakenly transferred into the contract to the original owner.
     * This contract realizes the stake feature through "safeTransferFrom".
     * This method is used to prevent some users from mistakenly using transferFrom (instead of safeTransferFrom) to transfer NFT into the contract.
     * caution: Because safeTransferFrom is called for refund (when the target address is a contract,  its onERC721Received logic will be triggered), 
     * be sure to set a reasonable GasLimit before calling this method, or check adequately if the target address is a malicious contract to 
     * prevent bear the high gas cost accidentally.
     * @param contractAddress_ contract address of NFT
     * @param tokenIds_ the tokenId list
     * @param accounts_ the address list
     */
    function transferUnstakingTokens(address contractAddress_, uint256[] calldata tokenIds_, address[] calldata accounts_) external onlyOwner {
        require(tokenIds_.length == accounts_.length, "tokenIds_ and accounts_ length mismatch");
        require(tokenIds_.length > 0, "no tokenId");
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            address account = accounts_[i];
            if (address(this) == contractAddress_) {
                require(_stakeStatuses[tokenId].lastStartTime == 0, "token is staking");
            }
            IERC721(contractAddress_).safeTransferFrom(address(this), account, tokenId);
            emit TransferUnstakingToken(tokenId, account);
        }
    }

    /**
     * @notice issuer withdraws the ETH temporarily stored in the contract through this method.
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
        emit Withdraw(_msgSender(), balance);
    }

    /***********************************|
    |               Hook                |
    |__________________________________*/

    /**
     * @notice onERC721Received is a hook function, which is the key to implementing the stake feature.
     * When the user calls the safeTransferFrom method to transfer the NFT to the current contract, 
     * onERC721Received will be called, and the stake state is modified at this time.
     */
    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes memory
    ) public returns (bytes4) {
        require(msg.sender == cheersUpPeriodContractAddress, "this contract is not allowed");
        _stake(_from, _tokenId);
        return this.onERC721Received.selector;
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