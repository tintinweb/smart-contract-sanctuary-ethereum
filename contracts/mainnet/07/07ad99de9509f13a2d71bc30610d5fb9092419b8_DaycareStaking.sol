/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// File: contracts/interface/ISkvllbabiez.sol


pragma solidity ^0.8.0;

interface ISkvllbabiez {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function walletOfOwner(address _owner) external view returns(uint256[] memory);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function approve(address operator, uint256 tokenId) external;
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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

// File: contracts/DaycareStaking.sol


pragma solidity ^0.8.0;






contract DaycareStaking is IERC721Receiver, Ownable, ReentrancyGuard {

    event SkvllbabyCheckedIn(address owner, uint256 skvllbabyId);
    event SkvllbabyCheckedOut(address owner, uint256 skvllbabyId);
    event RewardCollected(address owner, uint256 skvllbabyId, uint256 amount);
    event DaycareOpen();
    event DaycareClosed();

    struct Skvllbaby{
        uint256 id;
        address owner;
        uint256 lastClaimTimestamp;
        uint256 accruedBalance;
        bool staked;
    }

    uint256 private constant REWARD_PER_DAY = 4*10**18;
    uint256 private constant REWARD_PER_SEC = REWARD_PER_DAY / 86400;

    ISkvllbabiez private SkvllpvnkzDaycare = ISkvllbabiez(0x40BCA1edDf13b5FFA8f6f1d470cabC78Ec2FC3bb);
    IERC20 private SkvllpvnkzTreasury = IERC20(0xBcB6112292a9EE9C9cA876E6EAB0FeE7622445F1);
    
    bool public isDaycareOpen = false;

    mapping(uint256 => Skvllbaby) private skvllbabiez;
    mapping(address => uint256[]) private skvllbabiezByOwner;
    uint256[] private checkedInList;
    
    modifier daycareOpen {
        require( isDaycareOpen, "Skvllpvnkz Daycare is closed" );
        _;
    }

    modifier isSkvllbaby(address contractAddress) {    
        require( contractAddress == address(SkvllpvnkzDaycare), "Not a Skvllbaby!" );
        _;
    }
    
    function onERC721Received(address, address from, uint256 skvllbabyId, bytes memory) 
        override external daycareOpen isSkvllbaby(msg.sender) returns(bytes4) { 
            skvllbabiezByOwner[from].push(skvllbabyId);
            skvllbabiez[skvllbabyId] = 
                Skvllbaby(
                    skvllbabyId, 
                    from, 
                    block.timestamp, 
                    0, 
                    true); 
            emit SkvllbabyCheckedIn( from, skvllbabyId );
            return IERC721Receiver.onERC721Received.selector;
    }
    
    function checkIn(uint256[] memory skvllbabyIds) external nonReentrant {
        for (uint256 i; i < skvllbabyIds.length; i++){
            SkvllpvnkzDaycare.safeTransferFrom( msg.sender, address(this), skvllbabyIds[i]);
        }
    }

    function checkOut(uint256[] memory skvllbabyIds) public daycareOpen nonReentrant {
        require(skvllbabyIds.length > 0, "Need to provide at least 1 id");
        uint256 rewardTimestamp = block.timestamp;
        for (uint256 i; i < skvllbabyIds.length; i++){
            require(msg.sender == skvllbabiez[skvllbabyIds[i]].owner, "Not your Skvllbaby");
            skvllbabiez[skvllbabyIds[i]].accruedBalance = _calculateRewards(skvllbabyIds[i], rewardTimestamp );
            skvllbabiez[skvllbabyIds[i]].staked = false;
            SkvllpvnkzDaycare.safeTransferFrom( address(this), msg.sender, skvllbabyIds[i]);
            updateSkvllbabiezByOwner(skvllbabyIds[i]);
            emit SkvllbabyCheckedOut(msg.sender, skvllbabyIds[i]);
        }
    }

    function collectRewards(uint256[] memory skvllbabyIds) public daycareOpen nonReentrant{
        uint256 rewardTimestamp = block.timestamp;
        uint256 rewardAmount = 0;
        for (uint256 i; i < skvllbabyIds.length; i++){
            if (address(this) == SkvllpvnkzDaycare.ownerOf(skvllbabyIds[i])) {
                rewardAmount += _calculateRewards(skvllbabyIds[i], rewardTimestamp );
                rewardAmount += skvllbabiez[skvllbabyIds[i]].accruedBalance;             
            } else {
                require(msg.sender == SkvllpvnkzDaycare.ownerOf(skvllbabyIds[i]), "Not your Skvllbaby");
                rewardAmount += skvllbabiez[skvllbabyIds[i]].accruedBalance;
            }
            skvllbabiez[skvllbabyIds[i]].accruedBalance = 0;
            skvllbabiez[skvllbabyIds[i]].lastClaimTimestamp = rewardTimestamp;
            emit RewardCollected(msg.sender, skvllbabyIds[i], rewardAmount);
        }
        _releasePayment(rewardAmount);
    }

    function _calculateRewards(uint256 skvllbabyId, uint256 currentTime ) internal view returns (uint256){
        return (currentTime - skvllbabiez[skvllbabyId].lastClaimTimestamp) * REWARD_PER_SEC;
    }

    function _releasePayment(uint256 rewardAmount) internal {
        require(rewardAmount > 0, "Nothing to collect");
        require(SkvllpvnkzTreasury.balanceOf(address(this)) >= rewardAmount, "Not enough AMMO");
        SkvllpvnkzTreasury.approve(address(this), rewardAmount); 
        SkvllpvnkzTreasury.transfer(msg.sender, rewardAmount);
    }
    
    function getSkvllbabyReport(uint256 skvllbabyId) public view returns (Skvllbaby memory ){
        bool staked = address(this) == SkvllpvnkzDaycare.ownerOf(skvllbabyId);
        return Skvllbaby(
                    skvllbabyId,
                    staked ? skvllbabiez[skvllbabyId].owner : SkvllpvnkzDaycare.ownerOf(skvllbabyId), 
                    skvllbabiez[skvllbabyId].lastClaimTimestamp, 
                    staked ? _calculateRewards(skvllbabyId, block.timestamp) : skvllbabiez[skvllbabyId].accruedBalance,
                    staked);
        
    }

    function getWalletReport(address wallet) external view returns(Skvllbaby[] memory ){
        uint256[] memory stakedIds = skvllbabiezByOwner[ wallet ];
        uint256[] memory unstakedIds = SkvllpvnkzDaycare.walletOfOwner(wallet);
        uint256[] memory ids = _concatArrays(stakedIds, unstakedIds);
        require(ids.length > 0, "Wallet has no babiez");
        Skvllbaby[] memory babiez = new Skvllbaby[](ids.length);
        for (uint256 i; i < ids.length; i++){
            babiez[i] = getSkvllbabyReport(ids[i]);
        }
        return babiez;
        
    }

    function getBatchPendingRewards(uint64[] memory tokenIds) external view returns(Skvllbaby[] memory) {
        Skvllbaby[] memory allRewards = new Skvllbaby[](tokenIds.length);
        for (uint64 i = 0; i < tokenIds.length; i++){
            allRewards[i] = getSkvllbabyReport(tokenIds[i]);
        }
        return allRewards;
    }

    function _concatArrays(uint256[] memory ids, uint256[] memory ids2) internal pure returns(uint256[] memory) {
        uint256[] memory returnArr = new uint256[](ids.length + ids2.length);

        uint i=0;
        for (; i < ids.length; i++) {
            returnArr[i] = ids[i];
        }

        uint j=0;
        while (j < ids2.length) {
            returnArr[i++] = ids2[j++];
        }

        return returnArr;
    }

    function updateSkvllbabiezByOwner(uint256 skvllbabyId) internal {
        if (skvllbabiezByOwner[msg.sender].length == 1) {
            delete skvllbabiezByOwner[msg.sender];
        } else {
            for (uint256 i; i < skvllbabiezByOwner[msg.sender].length; i++){
                if (skvllbabiezByOwner[msg.sender][i] == skvllbabyId) {
                    skvllbabiezByOwner[msg.sender][i] = skvllbabiezByOwner[msg.sender][skvllbabiezByOwner[msg.sender].length - 1];
                    skvllbabiezByOwner[msg.sender].pop();
                }
            }
        }
    }

    function isSkvllbabyCheckedIn (uint256 skvllbabyId) external view returns (bool){
        return SkvllpvnkzDaycare.ownerOf(skvllbabyId) == address(this) ? true : false;
    }

    function openCloseDaycare() external onlyOwner {
        isDaycareOpen = !isDaycareOpen;
    }

    function withdraw(uint256 amount) external payable onlyOwner {
        require(payable(msg.sender).send(amount), "Payment failed");
    }

    function setTreasuryContract(address skvllpvnkzTreasury) external onlyOwner {
        SkvllpvnkzTreasury = IERC20(skvllpvnkzTreasury);
    }

    function setSkvllbabiezContract(address skvllpvnkzDaycare) external onlyOwner {
        SkvllpvnkzDaycare = ISkvllbabiez(skvllpvnkzDaycare);
    }
}