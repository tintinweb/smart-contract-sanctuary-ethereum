// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "erc721a/contracts/extensions/IERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IRHNO{
    function mint(address account, uint256 amount) external;
}

contract MekaRhinosStake is Ownable, ReentrancyGuard {
    uint256 public constant DAY = 24 * 60 * 60; // 86400
    uint256 public constant THIRTY_DAYS = 30 * DAY; // 2592000
    uint256 public constant FIFTY_FIVE_DAYS = 55 * DAY; // 4752000

    uint256 public reward = 10 ether;

    address public RHNO = 0x9BeaF3c32dfe54081F095BFc5Abc2280c752B29f;
    address public MekaNFT = 0x08059075d6eF5392a361C7d00954138681D4497F;

    bool public emergencyUnstakePaused = true;

    IERC721AQueryable nft = IERC721AQueryable(MekaNFT);
    IRHNO token = IRHNO(RHNO);

    struct stakeRecord {
        address tokenOwner;
        uint256 tokenId;
        uint256 stakedAt;
        uint256 lastClaimed;
        uint256 endingTimestamp;
        uint256 timeFrame;
        uint256 earned;
    }

    mapping(uint256 => stakeRecord) public stakingRecords;

    mapping(address => uint256) public numOfTokenStaked;

    event Staked(address owner, uint256 amount, uint256 timeframe);

    event Unstaked(address owner, uint256 amount);

    event EmergencyUnstake(address indexed user, uint256 tokenId);

    constructor() {}

    // MODIFIER
    modifier checkArgsLength(
        uint256[] calldata tokenIds,
        uint256[] calldata timeframe
    ) {
        require(
            tokenIds.length == timeframe.length,
            "Token IDs and timeframes must have the same length."
        );
        _;
    }

    modifier checkStakingTimeframe(uint256[] calldata timeframe) {
        for (uint256 i = 0; i < timeframe.length; i++) {
            uint256 period = timeframe[i];
            require(
                period == THIRTY_DAYS ||
                    period == FIFTY_FIVE_DAYS,
                "Invalid staking timeframes."
            );
        }
        _;
    }

    // STAKING
    function batchStake(
        uint256[] calldata tokenIds,
        uint256[] calldata timeframe
    )
        external
        checkStakingTimeframe(timeframe)
        checkArgsLength(tokenIds, timeframe)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(msg.sender, tokenIds[i], timeframe[i]);
        }
    }

    function _stake(
        address _user,
        uint256 _tokenId,
        uint256 _timeframe
    ) internal {
        require(
            nft.ownerOf(_tokenId) == msg.sender,
            "You must own the NFT."
        );
        uint256 currentTimestamp = block.timestamp;

        uint256 endingTimestamp = currentTimestamp + _timeframe;

        stakingRecords[_tokenId] = stakeRecord(
            _user,
            _tokenId,
            currentTimestamp,
            currentTimestamp,
            endingTimestamp,
            _timeframe,
            0
        );
        numOfTokenStaked[_user] = numOfTokenStaked[_user] + 1;
        nft.safeTransferFrom(
            _user,
            address(this),
            _tokenId
        );

        emit Staked(_user, _tokenId, _timeframe);
    }

    function batchTotalEarned (uint256[] memory _tokenIds) public view returns (uint256){
        uint256 earned = 0;

        for(uint256 i = 0; i < _tokenIds.length; i++){
            earned += totalEarned(_tokenIds[i]);
        }

        return earned;
    }

    function totalEarned (uint256 _tokenId) public view returns (uint256){
        uint256 claimable = 0;
        uint256 maxEarned = (reward * stakingRecords[_tokenId].timeFrame / DAY) - stakingRecords[_tokenId].earned;
        uint256 earned = reward * (block.timestamp - stakingRecords[_tokenId].lastClaimed) / DAY;

        if(earned > maxEarned) claimable = maxEarned;
        else claimable = earned;

        return claimable;
    }

    function batchClaim(uint256[] memory _tokenIds) external{
        for(uint256 i = 0; i < _tokenIds.length; i++){
            claim(_tokenIds[i]);
        }
    }

    function claim(uint256 _tokenId) internal{
        require(stakingRecords[_tokenId].tokenOwner == msg.sender, "Token does not belong to you.");
        require(stakingRecords[_tokenId].lastClaimed < stakingRecords[_tokenId].endingTimestamp, "Not eligible to claim.");

        uint256 claimable = totalEarned(_tokenId);

        require(claimable > 0, "Not enough balance.");

        stakingRecords[_tokenId].earned = claimable;
        stakingRecords[_tokenId].lastClaimed = block.timestamp;
        
        token.mint(msg.sender, claimable);
    }

    // RESTAKE
    function batchRestake(
        uint256[] calldata tokenIds,
        uint256[] calldata timeframe
    )
        external
        checkStakingTimeframe(timeframe)
        checkArgsLength(tokenIds, timeframe)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _restake(msg.sender, tokenIds[i], timeframe[i]);
        }
    }

    function _restake(
        address _user,
        uint256 _tokenId,
        uint256 _timeframe
    ) internal {
        require(
            block.timestamp >= stakingRecords[_tokenId].endingTimestamp,
            "NFT is locked."
        );
        require(
            stakingRecords[_tokenId].tokenOwner == msg.sender,
            "Token does not belong to you."
        );

        uint256 currentTimestamp = block.timestamp;

        uint256 endingTimestamp = currentTimestamp + _timeframe;

        stakingRecords[_tokenId].endingTimestamp = endingTimestamp;
        stakingRecords[_tokenId].timeFrame = _timeframe;
        stakingRecords[_tokenId].earned = 0;
        stakingRecords[_tokenId].lastClaimed = currentTimestamp;
        stakingRecords[_tokenId].stakedAt = currentTimestamp;

        emit Staked(_user, _tokenId, _timeframe);
    }

    // UNSTAKE
    function batchUnstake(uint256[] calldata tokenIds) external nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _unstake(msg.sender, tokenIds[i]);
        }
    }

    function _unstake(address _user, uint256 _tokenId) internal {
        require(
            block.timestamp >= stakingRecords[_tokenId].endingTimestamp,
            "NFT is locked."
        );
        require(
            stakingRecords[_tokenId].tokenOwner == msg.sender,
            "Token does not belong to you."
        );

        delete stakingRecords[_tokenId];
        numOfTokenStaked[_user]--;
        nft.safeTransferFrom(
            address(this),
            _user,
            _tokenId
        );

        emit Unstaked(_user, _tokenId);
    }

    function getStakingRecords(address user)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory tokenIds = new uint256[](numOfTokenStaked[user]);
        uint256[] memory expiries = new uint256[](numOfTokenStaked[user]);
        uint256 counter = 0;
        for (
            uint256 i = 0;
            i <= IERC721A(MekaNFT).totalSupply();
            i++
        ) {
            if (stakingRecords[i].tokenOwner == user) {
                tokenIds[counter] = stakingRecords[i].tokenId;
                expiries[counter] = stakingRecords[i].endingTimestamp;
                counter++;
            }
        }
        return (tokenIds, expiries);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // MIGRATION ONLY.
    function setMekaNFTContract (address _address) public onlyOwner {
        MekaNFT = _address;
    }

    function setTokenContract (address _address) public onlyOwner {
        RHNO = _address;
    }

    function setReward (uint256 _newReward) public onlyOwner {
        reward = _newReward;
    }

    // EMERGENCY ONLY.
    function setEmergencyUnstakePaused(bool paused) public onlyOwner {
        emergencyUnstakePaused = paused;
    }

    function emergencyUnstake(uint256 tokenId) external nonReentrant {
        require(!emergencyUnstakePaused, "No emergency unstake.");
        require(
            stakingRecords[tokenId].tokenOwner == msg.sender,
            "Token does not belong to you."
        );
        delete stakingRecords[tokenId];
        numOfTokenStaked[msg.sender]--;
        nft.safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
        emit EmergencyUnstake(msg.sender, tokenId);
    }

    function emergencyUnstakeByOwner(uint256[] calldata tokenIds)
        external
        onlyOwner
        nonReentrant
    {
        require(!emergencyUnstakePaused, "No emergency unstake.");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            address user = stakingRecords[tokenId].tokenOwner;
            require(user != address(0x0), "Need owner exists.");
            delete stakingRecords[tokenId];
            numOfTokenStaked[user]--;
            nft.safeTransferFrom(
                address(this),
                user,
                tokenId
            );
            emit EmergencyUnstake(user, tokenId);
        }
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
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of an ERC721AQueryable compliant contract.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *   - `addr` = `address(0)`
     *   - `startTimestamp` = `0`
     *   - `burned` = `false`
     *
     * If the `tokenId` is burned:
     *   - `addr` = `<Address of owner before token was burned>`
     *   - `startTimestamp` = `<Timestamp when token was burned>`
     *   - `burned = `true`
     *
     * Otherwise:
     *   - `addr` = `<Address of owner>`
     *   - `startTimestamp` = `<Timestamp of start of ownership>`
     *   - `burned = `false`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
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
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set through `_extraData`.
        uint24 extraData;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    // ==============================
    //            IERC165
    // ==============================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // ==============================
    //            IERC721
    // ==============================

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

    // ==============================
    //        IERC721Metadata
    // ==============================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // ==============================
    //            IERC2309
    // ==============================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId` (inclusive) is transferred from `from` to `to`,
     * as defined in the ERC2309 standard. See `_mintERC2309` for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
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