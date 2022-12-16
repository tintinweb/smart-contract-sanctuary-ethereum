/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

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

// File: openzeppelin-solidity\contracts\access\Ownable.sol


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

// File: openzeppelin-solidity\contracts\security\Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)




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

// File: openzeppelin-solidity\contracts\security\ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)



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

// File: openzeppelin-solidity\contracts\token\ERC20\IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)



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

// File: node_modules\openzeppelin-solidity\contracts\utils\introspection\IERC165.sol


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

// File: openzeppelin-solidity\contracts\token\ERC721\IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)




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
}

// File: contracts\YonkoStaking.sol
interface Yonko is IERC721 {
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
}

interface IPair{
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IFactory{
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IFeed{
    function latestAnswer() external view returns (int256);
}

contract YonkoStaking is Ownable, Pausable, ReentrancyGuard {

    uint8[1001] private rarity;
    uint public lastConfigBlock;

    struct UserInfo {
        mapping(uint256=>uint256) staked;
        mapping(uint256=>uint256) transferredRewardToken; // transferredRewardtoken amount on deposit
        uint256 totalWithdrawnInUSD; // withdrawn usd amount
        mapping(uint256=>uint256) withdrawnInUSD; // withdrawn amount in usd for each token
        uint256 totalWithdrawn; // withdrawn token amount
        mapping(uint256=>uint256) withdrawn; // withdrawn token amount for each token
        uint8 depositedCount; // count of staked nft itmes
        uint256 lastConfigBlock;
    }

    struct ConfigChanges {
        uint[4] rewardForRarity;
        uint rewardCycle; // rewardForRarity per rewardCycle 
        uint prevBlock;
    }

    mapping(address=>UserInfo) public userInfos;
    mapping(uint => ConfigChanges) public configChanges;

    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // depends on network
    IFactory public factory = IFactory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IERC20 public rewardToken;
    Yonko public yonkoNFT;
    IFeed public feed;
    uint256 public minTokenUSD = 10000000000;
    uint256 public perNFT = 1;
    uint256 public rewardPeriod = 216000 minutes / 12; // interval for claiming

    event deposited(address user, uint256 tokenID, uint256 timestamp);
    event withdrawn(address user, uint256 tokenID, uint256 timestamp);
    event claimed(address user, uint256 amount, uint256 timestamp);
    event blacklisted(address user, bool toBlock);
    event depositConditionUpdated(uint256 minTokenUSD, uint256 perNFT);
    event bonusRateUpdated(uint256 bonusRate, uint256 bonusPeriod);

    constructor (
        Yonko _yonkoNFT,
        uint8[1001] memory _rarity,
        uint256[4] memory _rewardForRarity,
        IERC20 _rewardToken,
        IFeed _feed)
    {
        require(address(_yonkoNFT) != address(0), "Invalid yonko address");
        require(address(_rewardToken) != address(0), "Invalid reward token address");
        require(address(_feed) != address(0), "Invalid price feed address");
        
        yonkoNFT = _yonkoNFT;
        rarity = _rarity;
        rewardToken = _rewardToken;
        feed = _feed;
        lastConfigBlock = block.number;
        configChanges[block.number].rewardForRarity = _rewardForRarity;
        configChanges[block.number].rewardCycle = 30 days / 12;
    }


    function updateConfig(
        Yonko _yonkoNFT,
        uint256[4] memory _rewardForRarity,
        IERC20 _rewardToken,
        IFeed _feed
    ) external onlyOwner {
        require(address(_yonkoNFT) != address(0), "Invalid yonko address");
        require(address(_rewardToken) != address(0), "Invalid reward token address");
        require(address(_feed) != address(0), "Invalid price feed address");

        yonkoNFT = _yonkoNFT;
        configChanges[block.number].prevBlock = lastConfigBlock;
        lastConfigBlock=block.number;
        configChanges[block.number].rewardForRarity = _rewardForRarity;
        rewardToken = _rewardToken;
        feed = _feed;
    }

    function pauseRunning(bool toPause) external onlyOwner {
        if(toPause)
            _pause();
        else
            _unpause();
    }

    function updateDepositCondition(uint256 _minTokenUSD, uint256 _perNFT) external onlyOwner {
        require(_minTokenUSD > 0 && _perNFT > 0, "Invalid setting");
        minTokenUSD = _minTokenUSD;
        perNFT = _perNFT;
        emit depositConditionUpdated(_minTokenUSD, _perNFT);
    }

    function updateReward(uint256[4] memory _rewardForRarity, uint256 _rewardCycle) external onlyOwner {
        configChanges[block.number].prevBlock = lastConfigBlock;
        lastConfigBlock=block.number;
        configChanges[block.number].rewardForRarity = _rewardForRarity;
        configChanges[block.number].rewardCycle = _rewardCycle;
    }

    function updateRewardPeriod(uint256 _rewardPeriod) external onlyOwner {
        require(_rewardPeriod > 0, "Invalid setting");
        rewardPeriod = _rewardPeriod;
    }

    function depositAction(uint256 tokenID, uint256 minTokenAmount) internal {
        require(msg.sender == yonkoNFT.ownerOf(tokenID), "You are not the owner of the token.");
        yonkoNFT.safeTransferFrom(msg.sender, address(this), tokenID);
        UserInfo storage info = userInfos[msg.sender];
        info.depositedCount++;
        info.staked[tokenID] = block.number;
        info.lastConfigBlock = lastConfigBlock;
        info.transferredRewardToken[tokenID] = minTokenAmount;
        emit deposited(msg.sender, tokenID, block.timestamp);
    }

    function deposit(uint256 tokenID) external whenNotPaused nonReentrant{
        uint256 minTokenAmount = getTokenAmount(minTokenUSD)/perNFT;
        require(rewardToken.balanceOf(msg.sender) >= minTokenAmount, "Not enough token balance.");
        rewardToken.transferFrom(msg.sender, address(this), minTokenAmount);
        claimAction();
        depositAction(tokenID, minTokenAmount);
    }

    function depositAll() external whenNotPaused nonReentrant{
        uint256 nftCount = yonkoNFT.balanceOf(msg.sender);
        uint256 minTokenAmountPerNFT = getTokenAmount(minTokenUSD)/perNFT;
        uint256 minTokenAmount = minTokenAmountPerNFT*nftCount;
        require(rewardToken.balanceOf(msg.sender) >= minTokenAmount, "Not enough token balance.");
        rewardToken.transferFrom(msg.sender, address(this), minTokenAmount);
        claimAction();
        uint256[] memory ownTokenIDs = yonkoNFT.walletOfOwner(address(msg.sender));
        for(uint256 i = 0; i < ownTokenIDs.length; i++) {
            depositAction(ownTokenIDs[i], minTokenAmountPerNFT);
        }
    }

    function withdrawAction(uint256 tokenID) internal returns(uint256){
        UserInfo storage info = userInfos[msg.sender];
        require(info.staked[tokenID] > 0, "You are not the staker of the token.");
        yonkoNFT.safeTransferFrom(address(this), msg.sender, tokenID);
        info.depositedCount--;
        info.totalWithdrawnInUSD -= rewardForTokenInUSD(msg.sender, tokenID);
        info.staked[tokenID] = 0;

        emit withdrawn(msg.sender, tokenID, block.timestamp);

        return info.transferredRewardToken[tokenID];
    }

    function withdraw(uint256 tokenID) public whenNotPaused nonReentrant {
        claimAction();
        uint256 rewardTokenAmount = withdrawAction(tokenID);
        rewardToken.transfer(msg.sender, rewardTokenAmount);
    }

    function withdrawAll() external whenNotPaused nonReentrant {
        uint256 rewardTokenAmount = 0;
        uint256[] memory stakedIDs = getStakedIDs(msg.sender);
        claimAction();
        for(uint256 i = 0; i < stakedIDs.length; i++) {
            rewardTokenAmount += withdrawAction(stakedIDs[i]);
        }
        rewardToken.transfer(msg.sender, rewardTokenAmount);
    }

    function emergencyWithdraw(uint256 tokenID) public whenNotPaused nonReentrant {
        UserInfo storage info = userInfos[msg.sender];
        require(info.staked[tokenID] > 0, "You are not the staker of the token.");
        yonkoNFT.safeTransferFrom(address(this), msg.sender, tokenID);
        info.depositedCount--;
        info.staked[tokenID] = 0;
        emit withdrawn(msg.sender, tokenID, block.timestamp);
    }

    function pendingRewardInUSD(address user) public view returns(uint256) {
        uint256[] memory stakedIDs = getStakedIDs(user);
        uint256 pendingReward = 0;
        for(uint256 i = 0; i < stakedIDs.length; i++) {
            pendingReward += rewardForTokenInUSD(user, stakedIDs[i]);
        }
        return pendingReward;
    }

    function _pendingRewards(address user, uint256 tokenId) private view returns(uint256 totalRewards) {
        UserInfo storage info = userInfos[user];
        uint endBlock = block.number - ((block.number-info.staked[tokenId])%rewardPeriod);
        // uint lastBlock = info.lastConfigBlock;
        uint lastBlock = lastConfigBlock;
        ConfigChanges memory changes;
        do {
            changes = configChanges[lastBlock];
            uint rewardPerCycle = changes.rewardForRarity[rarity[tokenId - 1] -1];
            uint rewardCycle = changes.rewardCycle;
            if(endBlock > lastBlock) {
                uint stakeBlocks = endBlock - (lastBlock>info.staked[tokenId]?lastBlock:info.staked[tokenId]);
                totalRewards += stakeBlocks*rewardPerCycle/rewardCycle;
            }

            if(lastBlock<=info.staked[tokenId])
                break;
            if(endBlock > lastBlock) {
                endBlock = lastBlock;
            }
            lastBlock = changes.prevBlock;
        }
        while(lastBlock != 0);
    }

    function rewardForTokenInUSD(address user, uint256 tokenID) public view returns(uint256) {
        UserInfo storage info = userInfos[user];

        uint256 currentPending = _pendingRewards(user, tokenID);
        if(currentPending <= info.withdrawnInUSD[tokenID])
            return 0;
        return currentPending - info.withdrawnInUSD[tokenID];
    }

    function stakedTime(address user, uint256 tokenID) external view returns(uint256){
        return userInfos[user].staked[tokenID];
    }

    function isStaked(address user, uint256 tokenID) external view returns(bool){
        return userInfos[user].staked[tokenID] > 0;
    }

    function claimAction() internal {
        UserInfo storage info = userInfos[msg.sender];

        uint256 rewardAmount = pendingRewardInUSD(msg.sender);
        if(rewardAmount == 0) {
            return;
        }
        updateWithdrawn(msg.sender);
        info.totalWithdrawnInUSD += rewardAmount;

        rewardAmount = getTokenAmount(rewardAmount);
        uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
        if(rewardTokenBalance < rewardAmount) revert("Not enought reward token balance");
        info.totalWithdrawn += rewardAmount;
        rewardToken.transfer(msg.sender, rewardAmount);

        emit claimed(msg.sender, rewardAmount, block.timestamp);
    }

    function updateWithdrawn(address user) internal {
        UserInfo storage info = userInfos[msg.sender];

        uint256[] memory stakedIDs = getStakedIDs(user);
        for(uint256 i = 0; i < stakedIDs.length; i++) {
            uint256 amount = rewardForTokenInUSD(user, stakedIDs[i]);
            if(amount > 0) {
                info.withdrawnInUSD[stakedIDs[i]] += amount;
                info.withdrawn[stakedIDs[i]] += getTokenAmount(amount);
            }
        }
    }

    function claim() public whenNotPaused nonReentrant {
        claimAction();
    }

    function getTokenAmount(uint256 usdValue) public view returns(uint256) {
        //get ETH price in usd
        uint256 ETHPrice = uint256(feed.latestAnswer());
        //get ETH amount for usdValue
        uint256 ETHAmount = 1e18*usdValue / ETHPrice;
        //get token price in ETHValue
        IPair pair = IPair(factory.getPair(address(rewardToken), WETH));
        (uint256 amount0, uint256 amount1,) = pair.getReserves();
        address token0 = pair.token0();
        uint256 tokenAmount = token0 == WETH ? (ETHAmount*amount1/amount0) : (ETHAmount*amount0/amount1);

        return tokenAmount;
    }

    function getUSDAmount(uint256 tokenValue) public view returns(uint256) {
        //get token price in ETHValue
        IPair pair = IPair(factory.getPair(address(rewardToken), WETH));
        (uint256 amount0, uint256 amount1,) = pair.getReserves();
        address token0 = pair.token0();
        uint256 EthAmount = token0 == WETH ? (tokenValue*amount0/amount1) : (tokenValue*amount1/amount0);
        //get ETH price in usd
        uint256 ETHPrice = uint256(feed.latestAnswer());

        return ETHPrice*EthAmount/1e18;
    }

    function gettingRemainingTime(address user, uint256 tokenID) public view returns(uint256) {
        UserInfo storage info = userInfos[user];
        uint256 restDays = rewardPeriod - ((block.number-info.staked[tokenID])%rewardPeriod);
        return restDays;
    }

    function getStakedIDs(address user) public view returns(uint256[] memory) {
        UserInfo storage info = userInfos[user];
        uint256[] memory result = new uint256[](info.depositedCount);
        uint256[] memory totalStakedIDs = yonkoNFT.walletOfOwner(address(this));
        uint256 k = 0;
        for(uint256 i = 0; i < totalStakedIDs.length; i++) {
            if(info.staked[totalStakedIDs[i]] > 0) {
                result[k] = totalStakedIDs[i];
                k++;
            }
        }
        return result;
    }

    function getTransferredToken(address user, uint256 tokenID) external view returns(uint256) {
        UserInfo storage info = userInfos[user];
        return info.transferredRewardToken[tokenID];
    }

    function onERC721Received(address, address, uint256, bytes memory) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function rewardWithdraw() external onlyOwner {
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }

    function rewardForRarity(uint256 _rarity) external view returns(uint256) {
        return configChanges[lastConfigBlock].rewardForRarity[_rarity];
    }

    fallback() external {}
}