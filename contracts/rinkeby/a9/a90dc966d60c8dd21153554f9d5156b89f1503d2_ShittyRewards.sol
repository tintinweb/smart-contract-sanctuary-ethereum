/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// SPDX-License-Identifier: MIT
// File: erc721a/contracts/IERC721A.sol


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/03_ShittyRewards.sol



pragma solidity ^0.8.4;







contract ShittyRewards is Pausable, Ownable, ReentrancyGuard{
    using SafeMath for uint256;

    // Custom Errors
    error InSufficientEthSent();
    error NumberOfTokensExceedOnePercentOfEligibleTokens();
    error RewardAmountIsInsufficient(uint256 numberOfTokens, uint256 requiredFixedRewardsInWei, uint256 amountInWeiSent);
    error NumberOfTokensExceeds69();
    error MinWeightNotLessThanMaxWeight(uint256 minWeight, uint256 maxWeight);
    error NoTokensFoundForRewardAllocation();
    error NoNftTokensOwned(address userAddress, IERC721A nftAddress);
    error AtLeastOneTokenNotOwned(uint256 tokenId, IERC721A nftAddress);
    error NoRewardsAvaialbleToClaim();
    error ClaimRewardsEthTransferFailed();

    struct ShittyRewardDetail{
        uint256 rewardAmountInWei;
        bool rewardClaimed; 
    }
    mapping(uint => ShittyRewardDetail) public allotedShittyReward;
    
    bool repeatRewardsPerTokenEnabled = false;    
    uint256 public constant MIN_TOKEN_REWARD = 0.0002 ether;

    IERC721A public nftContractAddress;
            
    constructor(IERC721A _nftContractAddress){
        nftContractAddress = _nftContractAddress;
        _pause();
    }

    function setRepeatRewardsPerTokenEnabled(bool _isEnabled) public onlyOwner{
        repeatRewardsPerTokenEnabled = _isEnabled;
    }

    function setNftContractAddress(IERC721A _nftContractAddress) public onlyOwner{
        nftContractAddress = _nftContractAddress;
    }

    function resetRewardState(uint[] memory _tokenIds) public onlyOwner{
        for(uint256 i = 0; i < _tokenIds.length; i++){
            allotedShittyReward[_tokenIds[i]].rewardAmountInWei = 0;
            allotedShittyReward[_tokenIds[i]].rewardClaimed = false;
        }
    }

    //Pausable
    function pause() public onlyOwner{
        _pause();
    }
    function unpause() public onlyOwner{
        _unpause();
    }

    //Random Rewards utility methods
    function distributeRewards(uint256 _numberOfTokens, uint256 _rewardKittyInWei, uint256 _minWeight, uint256 _maxWeight) public payable whenNotPaused onlyOwner{
      // require(msg.value >= _rewardKittyInWei, "Insufficient Eth payed");
      if(msg.value < _rewardKittyInWei) revert InSufficientEthSent();

      uint256 totalSold =  nftContractAddress.totalSupply();
      // require (_numberOfTokens <= totalSold.div(100), "Only 1 percent max of sold tokens eligible for reward");
      if(_numberOfTokens > totalSold.div(100)) revert NumberOfTokensExceedOnePercentOfEligibleTokens();

      uint256 totalFixedReward = MIN_TOKEN_REWARD.mul(_numberOfTokens);
      // require (totalFixedReward < _rewardKittyInWei, "Insufficient reward amount");
      if (totalFixedReward >= _rewardKittyInWei)
        revert RewardAmountIsInsufficient({numberOfTokens: _numberOfTokens, requiredFixedRewardsInWei: totalFixedReward, amountInWeiSent: msg.value});
      
      uint256 totalVariableReward = _rewardKittyInWei.sub(totalFixedReward);

      uint256[] memory winningTokens = getWinnerTokenIds(totalSold, _numberOfTokens);
      (uint256 sumOfWeights, uint256[] memory weights) = getRandomWeights(_numberOfTokens, _minWeight, _maxWeight);
      
      for(uint i = 0; i < _numberOfTokens; i++){
        allotedShittyReward[winningTokens[i]].rewardAmountInWei = 
            allotedShittyReward[winningTokens[i]].rewardAmountInWei.add(
                MIN_TOKEN_REWARD.add(totalVariableReward.mul(weights[i]).div(sumOfWeights)));              
      }
    }

    function getRandomWeights(uint256 numberOfTokens, uint256 minWeight, uint256 maxWeight) private view returns(uint, uint[] memory){
        // require (numberOfTokens <= 69, "numberOfTokens must be less than or equal to 69");
        if (numberOfTokens > 69) revert NumberOfTokensExceeds69();

        // require(minWeight < maxWeight, "minWeight must be less than maxWeight");
        if (minWeight >= maxWeight) revert MinWeightNotLessThanMaxWeight({minWeight: minWeight, maxWeight: maxWeight});

        uint rangeLength = maxWeight - minWeight + 1;
        uint sumOfWeights = 0;
        uint[] memory weights = new uint[](numberOfTokens);
        for(uint i = 0; i < numberOfTokens; i++){
            uint randomNumber = 
                (
                    uint(keccak256 (abi.encodePacked(block.timestamp + block.difficulty, i)))
                        .mod(rangeLength)
                ).add(minWeight);

            sumOfWeights = sumOfWeights + randomNumber; 
            weights[i] = randomNumber;
        }
        return (sumOfWeights, weights);        
    }

    function getWinnerTokenIds(uint256 totalSupply, uint256 numberOfTokens) private returns(uint[] memory){
        // require (numberOfTokens <= 69, "numberOfTokens must be less than or equal to 69");
        if (numberOfTokens > 69) revert NumberOfTokensExceeds69();

        uint[] memory winnerTokens = new uint[](numberOfTokens);
        for(uint i = 0; i< numberOfTokens; i++){
            uint seedVal = (i == 0) ? numberOfTokens: winnerTokens[i-1];
            uint randNumber = 
                (
                    uint(keccak256 (abi.encodePacked(block.timestamp + block.difficulty, seedVal)))
                        .mod(totalSupply)
                );
            winnerTokens[i] = adjustIfTokenIdAlreadyRewarded(randNumber, totalSupply);
            allotedShittyReward[winnerTokens[i]].rewardClaimed = false; 
        }
        return winnerTokens;        
    }

    function adjustIfTokenIdAlreadyRewarded(uint256 inputTokenId, uint256 totalSupply) private view returns(uint){
        if(repeatRewardsPerTokenEnabled || !allotedShittyReward[inputTokenId].rewardClaimed){
            return inputTokenId;
        }             
        else{
            uint256 nextTokenId = inputTokenId;
            uint256 counter = 1;
            while (counter < totalSupply - 1){
                nextTokenId = (nextTokenId == (totalSupply-1)) ? 0 : nextTokenId + 1;
                counter = counter + 1;
                if(allotedShittyReward[nextTokenId].rewardAmountInWei == 0) 
                    return nextTokenId;
            }
            revert NoTokensFoundForRewardAllocation();
        }
    }
    
    function claimRewards(uint256[] memory _tokenIds) public whenNotPaused nonReentrant {
        // require(nftContractAddress.balanceOf(_msgSender()) > 0, "No NFT tokens owned");
        if(nftContractAddress.balanceOf(_msgSender()) == 0) 
            revert NoNftTokensOwned({userAddress: _msgSender(), nftAddress: nftContractAddress});
        
        uint totalRewardAmountInWei = 0;
        for(uint i = 0; i < _tokenIds.length; i++){
          // require(nftContractAddress.ownerOf(_tokenIds[i]) == _msgSender(), "At least one of the passed NFT tokenId not owned by sender");
          if (nftContractAddress.ownerOf(_tokenIds[i]) != _msgSender()) 
            revert AtLeastOneTokenNotOwned({tokenId: _tokenIds[i], nftAddress: nftContractAddress});

          if(!allotedShittyReward[_tokenIds[i]].rewardClaimed){
            totalRewardAmountInWei += allotedShittyReward[_tokenIds[i]].rewardAmountInWei;
            _setRewardClaimedForToken(_tokenIds[i]);
          }
        }
        // require(totalRewardAmountInWei > 0, "No rewards available to claim");
        if(totalRewardAmountInWei <= 0) revert NoRewardsAvaialbleToClaim();

        (bool success, ) = payable(_msgSender()).call{value: totalRewardAmountInWei}("");
        // require(success, "claimRewards: Call failed");
        if(!success) revert ClaimRewardsEthTransferFailed();
    }

    function _setRewardClaimedForToken(uint256 _tokenId) private {
      allotedShittyReward[_tokenId].rewardClaimed = true;
      allotedShittyReward[_tokenId].rewardAmountInWei = 0;
    }
    
    struct TokensWithRewards{
        uint256 tokenId;
        uint256 rewardAmountInWei; 
        bool rewardClaimed;
    }

    function getTokenIdsWithRewards(address _userAddress, uint256[] memory _tokenIds) public view whenNotPaused returns (TokensWithRewards[] memory) {
        // require (nftContractAddress.balanceOf(_userAddress) > 0, "No NFT tokens owned by the userAddress");
        if(nftContractAddress.balanceOf(_userAddress) == 0)
            revert NoNftTokensOwned({userAddress: _userAddress, nftAddress: nftContractAddress});

        uint[] memory rewardedTokenIds = new uint[](_tokenIds.length);
        uint numOfRewardedTokens = 0;
        for(uint i = 0; i < _tokenIds.length; i++){
          // require(nftContractAddress.ownerOf(_tokenIds[i]) == _userAddress, "At least one of the passed NFT tokenId not owned by the userAddress");
          if (nftContractAddress.ownerOf(_tokenIds[i]) != _userAddress) 
            revert AtLeastOneTokenNotOwned({tokenId: _tokenIds[i], nftAddress: nftContractAddress});

          if(allotedShittyReward[_tokenIds[i]].rewardAmountInWei > 0 
                && allotedShittyReward[_tokenIds[i]].rewardClaimed == false) {
            rewardedTokenIds[numOfRewardedTokens] = _tokenIds[i];
            numOfRewardedTokens = numOfRewardedTokens + 1;
          }
        }
        
        TokensWithRewards[] memory tokenIdsWithRewards = new TokensWithRewards[](numOfRewardedTokens);
        for(uint i = 0; i < numOfRewardedTokens; i++){
          tokenIdsWithRewards[i] = 
            TokensWithRewards(
                rewardedTokenIds[i], 
                allotedShittyReward[rewardedTokenIds[i]].rewardAmountInWei,
                allotedShittyReward[rewardedTokenIds[i]].rewardClaimed
            );
        }

        return (tokenIdsWithRewards);
    }

    function checkTokenIdsWithRewards(uint256[] memory _tokenIds) public view whenNotPaused onlyOwner returns (uint256[] memory) {
        TokensWithRewards[] memory tempTokensWithRewards = new TokensWithRewards[](_tokenIds.length);
        uint numOfRewardedTokens = 0;
        for(uint i = 0; i < _tokenIds.length; i++){
            if (!allotedShittyReward[_tokenIds[i]].rewardClaimed 
                    && allotedShittyReward[_tokenIds[i]].rewardAmountInWei > 0) 
            {
                tempTokensWithRewards[numOfRewardedTokens] = 
                    TokensWithRewards(
                        _tokenIds[i], 
                        allotedShittyReward[_tokenIds[i]].rewardAmountInWei, 
                        allotedShittyReward[_tokenIds[i]].rewardClaimed
                    );
                numOfRewardedTokens = numOfRewardedTokens + 1;
            }          
        }
        uint[] memory rewardedTokenIds = new uint[](numOfRewardedTokens);
        for(uint i = 0; i < numOfRewardedTokens; i++){
          rewardedTokenIds[i] = tempTokensWithRewards[i].tokenId;
        }
        return (rewardedTokenIds);      
    }
    
    function ownerWithdraw(uint256 _withdrawalAmountInWei) public onlyOwner{
        require(_withdrawalAmountInWei <= address(this).balance);
        (bool success, ) = payable(_msgSender()).call{value: _withdrawalAmountInWei}("");
        require(success, "ownerWithdraw: Call failed"); 
    }

}