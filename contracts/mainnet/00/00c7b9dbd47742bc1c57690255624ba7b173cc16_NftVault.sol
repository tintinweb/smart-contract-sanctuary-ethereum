//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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

    function decimals() external view returns (uint8);
}
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/IERC721A.sol


// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
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
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
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

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}
// File: contracts/NFTVAULT.sol

pragma solidity ^0.8.0;






contract NftVault is Ownable, ReentrancyGuard {
    IERC721A public nft_v1;
    IERC721A public nft_v2;
    IERC20 public rewardToken;

    struct Share {
        uint256 amount;
        uint256 lockTime;
        uint256 lockEndTime;
    }

    struct Receiver {
        address userAddress;
        uint256 tokenId;
    }

    //constants
    uint256 constant ONE_DAY = 86400;
    int256 private constant OFFSET19700101 = 2440588;

    //public variables
    uint256 public claimFee = 0 ether;
    uint256 public timeLock = 30 days;
    uint256 public holdingTime = 25 days;
    uint256 public totalDepositedAmount;
    uint8 public minDayOfMonthCanUnlock = 1;
    uint8 public maxDayOfMonthCanUnlock = 5;

    //mappings
    mapping(uint256 => address) public receiver;
    mapping(address => uint256[]) public unclaimedTokens;
    mapping(address => Share) public userData;

    event AirDrop(address receiver, uint256 tokenId);
    event NftDistributed(address receiver, uint256 tokenId);
    event NftClaimed(address receiver, uint256 tokenId);
    event TokensLocked(address user, uint256 amount, uint256 start, uint256 end);
    event TokensUnlocked(address user, uint256 amount, uint256 time);
    event MinDayUpdated(uint8 newDay, uint8 oldDay);
    event MaxDayUpdated(uint8 newDay, uint8 oldDay);
    event ClaimFeeUpdated(uint256 newFee, uint256 oldFee);
    event NftAddressesUpdated(address v1, address v2);
    event RewardTokenUpdated(address rewardToken);
    event LockPeriodUpdated(uint256 newPeriod, uint256 oldPeriod);
    event HoldingTimeUpdated(uint256 newTime, uint256 oldTime);

    function airDrop(Receiver[] memory _addressesAndTokenID) external onlyOwner {
        for (uint i=0; i < _addressesAndTokenID.length; i++ ) {
            require(nft_v2.ownerOf(_addressesAndTokenID[i].tokenId) == owner(), "missing token on owner wallet");
            nft_v2.safeTransferFrom(_msgSender(), _addressesAndTokenID[i].userAddress, _addressesAndTokenID[i].tokenId);
            emit AirDrop(_addressesAndTokenID[i].userAddress, _addressesAndTokenID[i].tokenId);
        }
    }
   
    function distributeTokens(address user, uint256[] memory tokens) external onlyOwner {
        for (uint i = 0; i < tokens.length; i++) {
            require(nft_v2.ownerOf(tokens[i]) == owner(), "no such token id on owner's wallet");
            require(receiver[tokens[i]] == address(0), "token already assigned");
            nft_v2.transferFrom(_msgSender(), address(this), tokens[i]);
            receiver[tokens[i]] = user;
            unclaimedTokens[user].push(tokens[i]);
            emit NftDistributed(user,tokens[i]);
        }
    }

    function claimAll() public payable nonReentrant {
        require(unclaimedTokens[_msgSender()].length > 0, "no tokens for claim");
        uint256 userClaimFee;
        for (uint i = 0; i < unclaimedTokens[_msgSender()].length; i++) {
            uint256 token = unclaimedTokens[_msgSender()][i];
            if (token != 0 && nft_v1.ownerOf(token) == _msgSender()) {
                require(receiver[token] == _msgSender(), "token distribution error");
                nft_v2.safeTransferFrom(address(this), _msgSender(), token);
                unchecked{
                    delete receiver[token];
                    delete unclaimedTokens[_msgSender()][i];
                    userClaimFee += claimFee;
                }
                emit NftClaimed(_msgSender(), token);
            }
        }
        require(msg.value >= userClaimFee, "not enough ether send");
    }

    function claimExactToken(uint256 tokenId) public payable nonReentrant {
        require(unclaimedTokens[_msgSender()].length > 0, "no tokens for claim");
        require(tokenId > 0, "zero token id");
        require(msg.value >= claimFee, "not enough ether send");
        require(nft_v1.ownerOf(tokenId) == _msgSender(), "user not the owner of v1 token");
        for (uint i = 0; i < unclaimedTokens[_msgSender()].length; i++) {
            uint256 token = unclaimedTokens[_msgSender()][i];
            if (token == tokenId) {
                require(receiver[token] == _msgSender(), "token distribution error");
                nft_v2.safeTransferFrom(address(this), _msgSender(), token);
                delete receiver[token];
                delete unclaimedTokens[_msgSender()][i];
                emit NftClaimed(_msgSender(), token);
            }
        }
    }

    function getClaimAllFee(address user) public view returns (uint256) {
        uint256 userClaimFee;
        for (uint i = 0; i < unclaimedTokens[user].length; i++) {
            uint256 token = unclaimedTokens[user][i];
            if (token != 0 && nft_v1.ownerOf(token) == user) {
                userClaimFee += claimFee;
            }
        }
        return userClaimFee;
    }

    function lock(uint256 amount) public nonReentrant {
        uint256 totalAmount = amount * 10 ** rewardToken.decimals();
        require(rewardToken.allowance(_msgSender(), address(this)) >= totalAmount, "insufficient allowance");
        require(rewardToken.balanceOf(_msgSender()) >= totalAmount, "insufficient balance");
        require(rewardToken.transferFrom(_msgSender(), address(this), totalAmount), "token transfer failed");
        if (userData[_msgSender()].amount > 0) {
            userData[_msgSender()].amount += totalAmount;
            userData[_msgSender()].lockTime = block.timestamp;
            userData[_msgSender()].lockEndTime = block.timestamp + timeLock;
            emit TokensLocked(_msgSender(), userData[_msgSender()].amount, block.timestamp, userData[_msgSender()].lockEndTime);
        } else {
            userData[_msgSender()] = Share(totalAmount, block.timestamp, block.timestamp + timeLock);
            emit TokensLocked(_msgSender(), totalAmount, block.timestamp, block.timestamp + timeLock);
        }
    }

    function unlock(uint256 amount) public nonReentrant {
        uint256 _currentDayOfMonth = _dayOfMonth(block.timestamp);
        require(
            _currentDayOfMonth >= minDayOfMonthCanUnlock &&
            _currentDayOfMonth <= maxDayOfMonthCanUnlock,
            "outside of allowed lock window"
        );
        uint256 totalAmount = amount * 10 ** rewardToken.decimals();
        require(userData[_msgSender()].lockEndTime <= block.timestamp, "lock period not ended");
        require(userData[_msgSender()].amount >= totalAmount, "input exceed locked amount");
        userData[_msgSender()].amount -= totalAmount;
        if (userData[_msgSender()].amount == 0) {
            delete userData[_msgSender()];
        }
        require(rewardToken.transfer(_msgSender(), totalAmount), "token transfer failed");
        emit TokensUnlocked(_msgSender(), totalAmount, block.timestamp);
    }

    function userInfo(address user) external view returns(uint256, bool) {
        bool canClaim = block.timestamp >= (userData[user].lockTime + holdingTime) && userData[user].lockTime != 0;
        return (userData[user].amount, canClaim);
    }

    function setMinDayOfMonthCanUnlock(uint8 _day) external onlyOwner {
        require(_day < 32,"exceed month");
        require(_day <= maxDayOfMonthCanUnlock, "can set min day above max day");
        uint8 oldDay = minDayOfMonthCanUnlock;
        minDayOfMonthCanUnlock = _day;
        emit MinDayUpdated(_day, oldDay);

    }

    function setMaxDayOfMonthCanUnlock(uint8 _day) external onlyOwner {
        require(_day < 32,"exceed month");
        require(_day >= minDayOfMonthCanUnlock, "can set max day below min day");
        uint8 oldDay = maxDayOfMonthCanUnlock;
        maxDayOfMonthCanUnlock = _day;
        emit MaxDayUpdated(_day, oldDay);
    }

    function reassignToken(uint256 tokenId, address newReceiver) public onlyOwner {
        require(nft_v2.ownerOf(tokenId) == address(this), "no such token id on contract");
        address oldReceiver = receiver[tokenId];
        receiver[tokenId] = newReceiver;
        unclaimedTokens[newReceiver].push(tokenId);

        for (uint i = 0; i < unclaimedTokens[oldReceiver].length; i++) {
            uint256 token = unclaimedTokens[oldReceiver][i];
            if (token == tokenId) {
                delete unclaimedTokens[oldReceiver][i];
            }
        }
        emit NftDistributed(newReceiver, tokenId);
    }

    receive() external payable {}

    function getUnclaimedToken(address user) external view returns (uint256[] memory) {
        return unclaimedTokens[user];
    }

    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = rewardToken.balanceOf(address(this));
        require(rewardToken.transfer(owner(), balance), "transfer failed");
    }


     // Emergency ERC20 withdrawal 

  function rescueERC20(address tokenAdd, uint256 amount) external onlyOwner {
    // require(tokenAdd != address(this), "Cannot rescue self");
    require(
      IERC20(tokenAdd).balanceOf(address(this)) >= amount,
      'Insufficient ERC20 balance'
    );
    IERC20(tokenAdd).transfer(owner(), amount);
  }



    function changeClaimFee(uint256 newFeeInWei) external onlyOwner {
        uint256 oldFee = claimFee;
        claimFee = newFeeInWei;
        emit ClaimFeeUpdated(claimFee, oldFee);
    }

    function clearUnclaimedTokens(address user) external onlyOwner {
        uint256 counter;
        for (uint i = 0; i < unclaimedTokens[user].length; i++) {
            if (unclaimedTokens[user][i] == 0) {
                counter++;
            }
        }
        if (counter == unclaimedTokens[user].length) {
            delete unclaimedTokens[user];
        } else {
            revert ("Please reassign unclaimed tokens");
        }
    }
    function setNfts(address _nft_v1, address _nft_v2) external onlyOwner {
        require(_nft_v1 != address(0) && _nft_v2 != address(0), "zero address passed");
        nft_v1 = IERC721A(_nft_v1);
        nft_v2 = IERC721A(_nft_v2);
        emit NftAddressesUpdated(_nft_v1, _nft_v2);
    }

    function setRewardToken(address _rewardToken) external onlyOwner {
        require(_rewardToken != address(0), "zero address passed");
        rewardToken = IERC20(_rewardToken);
        emit RewardTokenUpdated(_rewardToken);
    }

    function setNewLockPeriod(uint256 _newLockInDays) external onlyOwner {
        require(_newLockInDays < 365, "more than one year");
        uint256 oldPeriod = timeLock;
        timeLock = _newLockInDays * 86400;
        emit LockPeriodUpdated(timeLock, oldPeriod);
    }

    function setNewHoldingTime(uint256 _newHoldingTimeInDays) external onlyOwner {
        require(_newHoldingTimeInDays < 365, "more than one year");
        uint256 oldTime = holdingTime;
        holdingTime = _newHoldingTimeInDays * 86400;
        emit HoldingTimeUpdated(holdingTime, oldTime);
    }
   
    function testTime() external view returns (uint256) {
        return _dayOfMonth(block.timestamp);
    }

    function _dayOfMonth(uint256 _timestamp) internal pure returns (uint256) {
        (, , uint256 day) = _daysToDate(_timestamp / ONE_DAY);
        return day;
    }

    // date conversion algorithm from http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    function _daysToDate(uint256 _days) internal pure returns (uint256, uint256, uint256) {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        return (uint256(_year), uint256(_month), uint256(_day));
    }
}