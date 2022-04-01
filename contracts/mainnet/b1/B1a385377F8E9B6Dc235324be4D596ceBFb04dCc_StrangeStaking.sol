// SPDX-License-Identifier: MIT

// ( ˘▽˘)っ♨ cooked by @nftchef
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ++++++++++++++++++++++++++++++++*%%?*+++++++++++++++++++++++++++++++++
// +++++++++++++++++++++++++*??*+++?%%%%*++++*??*++++++++++++++++++++++++
// ++++++++++++++++++++++++*S%%%+++?%%%%*+++*%%%%++++++++++++++++++++++++
// ++++++++++++++++++++++++*S%%S?++?S%%S*+++?%%%?++++++++++++++++++++++++
// +++++++++++++++++++++++++SS%S?++*S%%%?+++S%%S?++??*+++++++++++++++++++
// +++++++++++++++++++++++++%%%%%++?S%%%%++?S%%S*+?%%S+++++++++++++++++++
// +++++++++++++++++++++++++%%%%S*+?S%%%%++%%%%%++%%%S+++++++++++++++++++
// +++++++++++++++++++++++++*S%%%?+?S%%%%++S%%%%++S%%S+++++++++++++++++++
// ++++++++++++++++++++++++++%%%%S+?S%%%%+*S%%%?+*S%%S+++++++++++++++++++
// ++++++++++++++++++++++++++%%%%S*?S%%%S+%%%%%*+%%%S%+++++++++++++++++++
// +++++++++++++++*???*++++++%%%%%?%S%%%S?S%%%S*?S%%S?+++++++++++++++++++
// +++++++++++++++%%%%%*+++++?S%%%%%%%%%%%%%%%S?S%%%S++++++++++++++++++++
// +++++++++++++++*S%%%%*++++?S%%%%%%%%%%%%%%%%%%%%S?++++++++++++++++++++
// ++++++++++++++++?S%%%?++++%S%%%%%%%%S%%%%%%%%%%%S*++++++++++++++++++++
// +++++++++++++++++SS%%%?*+*S%%%%%%%%%%%%%%%%%%%%%%+++++++++++++++++++++
// +++++++++++++++++*SS%%%%%SS%%%%%%%%%%%%%%%%%%%%%%+++++++++++++++++++++
// ++++++++++++++++++*%S%%%%%%%%%%%%%%%%%%%%%%%%%%%?+++++++++++++++++++++
// ++++++++++++++++++++%S%%%%%%%%%%%%%%%%%%%%%%%%%S?+++++++++++++++++++++
// +++++++++++++++++++++SS%%%%%%%%%%%S%%%%%%%%%%%%S*+++++++++++++++++++++
// +++++++++++++++++++++*SS%%%%%%%%%%%%%%%%%%%%%%%S*+++++++++++++++++++++
// ++++++++++++++++++++++*SS%%%%%%%%%%%%%%%%%%%%%%%++++++++++++++++++++++
// ++++++++++++++++++++++++?SS%%%%%%%%%%%%%%%%%%%S?++++++++++++++++++++++
// ++++++++++++++++++++++++++%S%%%%%%%%%%%%%%%%%S?+++++++++++++++++++++++
// +++++++++++++++++++++++++++*%S%%%%%SH%%%%%%%S?++++++++++++++++++++++++
// ++++++++++++++++++++++++++++?S%%%%%%%%%%%%%%S*++++++++++++++++++++++++
// ++++++++++++++++++++++++++++*S%%%%%%%%%%%%%%S*++++++++++++++++++++++++
// ++++++++++++++++++++++++++++*S%%%%%%%%%%%%%%S*++++++++++++++++++++++++
// ++++++++++++++++++++++++++++*S%%%%%%%%%%%%%%S*++++++++++++++++++++++++
// ++++++++++++++++++++++++++++*S%%%NFTCHEF%%%%S+++++++++++++++++++++++++
// ++++++++++++++++++++++++++++?S%%%%%%%%%%%%%%%+++++++++++++++++++++++++
// ++++++++++++++++++++++++++++?S%%%%%%%%%%%%%S%+++++++++++++++++++++++++
// ++++++++++++++++++++++++++++?S%%%%%%%%%%%%%S%+++++++++++++++++++++++++
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StrangeStaking is Pausable, Ownable, ReentrancyGuard {
    IERC721 public StrangeHandsNFT;

    struct Stake {
        address owner;
        uint256 timestamp;
    }

    struct Cycle {
        uint256 timestamp;
        uint256 shares;
        uint256 reward; // wei
    }

    uint256 public totalStaked;
    uint256 public MAX_UNSTAKE = 20;
    uint256 QUALIFICATION = 30 days;

    // maintain the last deposit cycle state
    uint256 public LAST_CYCLE_TIME;
    uint256 public LAST_CYCLE_SHARES;
    uint256[] public stakedTokens;

    // maps tokenID to Stake details
    mapping(uint256 => Stake) public stakes;

    mapping(address => uint256[]) public owned;
    mapping(address => uint256) public redeemedRewards;
    mapping(address => uint256) public allocatedRewards;

    // track owned array, token order
    mapping(uint256 => uint256) public index;

    // Array index tracker for all staked tokens
    mapping(uint256 => uint256) public stakedTokenIndex;

    // all reward cycles tracked over time
    Cycle[] rewardCycles;

    constructor(address _strange) {
        StrangeHandsNFT = IERC721(_strange);
    }

    modifier isApprovedForAll() {
        require(
            StrangeHandsNFT.isApprovedForAll(msg.sender, address(this)),
            "ERC721: transfer caller is not owner nor approved"
        );
        _;
    }

    /**
     * @notice This is what you're here for d=(´▽｀)=b.
     * @param tokenIds array of tokens owned by caller, to be staked.
     */
    function stake(uint256[] calldata tokenIds)
        external
        isApprovedForAll
        whenNotPaused
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                StrangeHandsNFT.ownerOf(tokenIds[i]) == msg.sender,
                "Caller is not token owner"
            );
        }

        uint256[] storage ownedTokens = owned[msg.sender];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            index[tokenIds[i]] = ownedTokens.length;
            ownedTokens.push(tokenIds[i]);
            // updates global arr of all stakedTokens
            stakedTokenIndex[tokenIds[i]] = stakedTokens.length;
            stakedTokens.push(tokenIds[i]);
            // create a Stake
            stakes[tokenIds[i]] = Stake(msg.sender, block.timestamp);

            StrangeHandsNFT.transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );
        }

        totalStaked += tokenIds.length;
    }

    /**
     * @notice unstake a single token. May only be called by the owner of
     * the token
     * @param tokenId token to unstake.
     */
    function unstake(uint256 tokenId) public nonReentrant {
        require(
            stakes[tokenId].owner == msg.sender,
            "Caller is not token owner"
        );
        _unstake(tokenId);
        totalStaked--;
    }

    /**
     * @notice convenience function for calling unstake for multiple arrays in a
     * single transaction.
     * @param tokenIds array of token id's
     */
    function unstakeMultiple(uint256[] calldata tokenIds)
        external
        nonReentrant
    {
        require(
            tokenIds.length <= MAX_UNSTAKE,
            "Exceeds maximum number to unstake at once"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                stakes[tokenIds[i]].owner == msg.sender,
                "Caller is not token owner"
            );
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _unstake(tokenIds[i]);
        }
        totalStaked -= tokenIds.length;
    }

    /**
     * @notice Retrieves the token ID's owned by _address that are staked
     * @param _address owner wallet address.
     */
    function getOwned(address _address) public view returns (uint256[] memory) {
        return owned[_address];
    }

    /**
     * @notice convenience view function to get the number of total staked tokens
     * owned by a given wallet
     * @param _address owner wallet address
     */
    function getOwnedCount(address _address) public view returns (uint256) {
        return owned[_address].length;
    }

    /**
     * @notice determins which tokens owned by an owner are considered
     *   "qualified" for any cycle.
     * @param _address adress to lookup qualified tokens.
     * @return qualifed array of booleans that map to the index order of owned tokens
     */
    function getAllQualified(address _address)
        external
        view
        returns (bool[] memory)
    {
        bool[] memory qualified = new bool[](owned[_address].length);

        for (uint256 nft = 0; nft < owned[_address].length; nft++) {
            for (uint256 cycle = 0; cycle < rewardCycles.length; cycle++) {
                if (
                    stakes[owned[_address][nft]].timestamp + QUALIFICATION <=
                    rewardCycles[cycle].timestamp
                ) {
                    qualified[nft] = true;
                } else {
                    qualified[nft] = false;
                }
            }
        }

        return qualified;
    }

    /**
     * @notice get all tokenId's that are currently staked.
     * @dev Can also be used to get the number of staked tokens.
     *    Does not a 'sorted' order. Sort offchain if needed.
     * @return tokens array of all staked tokens
     */
    function getStakedTokens() public view returns (uint256[] memory) {
        return stakedTokens;
    }

    function pendingBalance(address _address)
        public
        view
        returns (uint256 claim)
    {
        //  ... calculate qualified tokens
        for (uint256 nft = 0; nft < owned[_address].length; nft++) {
            claim += tokenValue(owned[_address][nft]);
        }
        // then, subtract claimed
        claim -= redeemedRewards[_address];
        // then, add saved
        claim += allocatedRewards[_address];
    }

    function collectRewards() external payable nonReentrant {
        uint256 claim = pendingBalance(msg.sender);
        require(claim > 0, "No rewards available");

        (bool sent, bytes memory data) = msg.sender.call{value: claim}("");
        require(sent, "Failed to send Ether");
        redeemedRewards[msg.sender] += claim;
        allocatedRewards[msg.sender] = 0;
    }

    function tokenValue(uint256 _tokenId)
        internal
        view
        returns (uint256 claim)
    {
        // check every cycle for qualification & rewards. accumulate it-
        for (uint256 cycle = 0; cycle < rewardCycles.length; cycle++) {
            if (
                stakes[_tokenId].timestamp + QUALIFICATION <=
                rewardCycles[cycle].timestamp
            ) {
                // accumlate gross, current staked total wei
                claim += rewardCycles[cycle].reward;
            }
        }
    }

    function _unstake(uint256 tokenId) private {
        uint256[] storage ownedTokens = owned[msg.sender];

        // get and store unclaimed rewards earned for the token
        allocatedRewards[msg.sender] += tokenValue(tokenId);
        // swap and pop to remove token from index
        ownedTokens[index[tokenId]] = ownedTokens[ownedTokens.length - 1];
        index[ownedTokens[ownedTokens.length - 1]] = index[tokenId];
        ownedTokens.pop();

        // set token to "unowned"
        stakes[tokenId] = Stake(address(0), 0);
        // remove the tokenID from stakedTokens
        stakedTokens[stakedTokenIndex[tokenId]] = stakedTokens[
            stakedTokens.length - 1
        ];
        // swap the the index mapping for staked tokenId's
        stakedTokenIndex[
            stakedTokens[stakedTokens.length - 1]
        ] = stakedTokenIndex[tokenId];
        stakedTokens.pop();

        // finally, send the token back to the owners wallet.
        StrangeHandsNFT.transferFrom(address(this), msg.sender, tokenId);
    }

    function snapshotAllQualified() public view returns (uint256) {
        // calculates all qualified tokens (gas intensive) when called
        // on-chain. only used when dopositing, so it's ok.
        uint256 totalShares;

        for (uint256 i = 0; i < stakedTokens.length; i++) {
            if (
                stakes[stakedTokens[i]].timestamp + QUALIFICATION <=
                LAST_CYCLE_TIME
            ) {
                totalShares++;
            }
        }
        return totalShares;
    }

    function depositCycle() external payable onlyOwner {
        LAST_CYCLE_TIME = block.timestamp;
        LAST_CYCLE_SHARES = snapshotAllQualified();
        require(LAST_CYCLE_SHARES > 0, "No qualified shares");

        // add a new cycle to the contract state. forever.
        rewardCycles.push(
            Cycle(
                block.timestamp,
                LAST_CYCLE_SHARES,
                msg.value / LAST_CYCLE_SHARES
            )
        );
    }

    /**
     * @dev Set the timespan required to consider tokens "qualified"
     * @param _time length of time in seconds
     */
    function setQualificationPeriod(uint256 _time) external onlyOwner {
        QUALIFICATION = _time;
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}