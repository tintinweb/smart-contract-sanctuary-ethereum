/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// SPDX-License-Identifier: MIT
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Staking.sol







pragma solidity ^0.8.7;

contract WukongStaking is Ownable, ReentrancyGuard {
    IERC721 public WukongNFT;

    uint256 public constant SECONDS_IN_DAY = 24 * 60 * 60;
    uint256 public HARDSTAKE_YIELD_PERDAY = 15;
    uint256 public PASSIVESTAKE_YIELD_PERDAY = 5;

    uint256 public stakingStartPoint;

    address[] public authorisedLog;

    bool public stakingLaunched;
    bool public depositPaused;
    uint256 public totalHardStaker;
    uint256 public totalStakedNFT;
    
    struct HardStaker {
        uint256 accumulatedAmount;
        uint256 lastCheckpoint;
        uint256[] hardStakedWukongId; 
    }

    struct PassiveStaker {
        uint256 lastCheckPoint;
        uint256 accumulatedAmount;
    }

    mapping(address => PassiveStaker) private _passiveStakers;
    mapping(address => HardStaker) private _hardStakers;
    mapping(uint256 => address) private _ownerOfHardStakingToken;
    mapping (address => bool) private _authorised;

    constructor(
        address _wukong,
        uint256 _stakingStartPoint
    ) {
        WukongNFT = IERC721(_wukong);
        stakingStartPoint = _stakingStartPoint;
    }

    modifier authorised() {
        require(_authorised[_msgSender()], "The token contract is not authorised");
            _;
    }

    function getHardStakingTokens(address _owner) public view returns (uint256[] memory) {
        return _hardStakers[_owner].hardStakedWukongId;
    }

    function hardStake(uint256 tokenId) external returns (bool) {
        address _sender = _msgSender();
        require(WukongNFT.ownerOf(tokenId) == _sender, "Not owner");
        
        HardStaker storage user = _hardStakers[_sender];

        accumulatePassiveStake(_sender);

        WukongNFT.safeTransferFrom(_sender, address(this), tokenId);
        _ownerOfHardStakingToken[tokenId] = _sender;

        accumulateHardStake(_sender);

        user.hardStakedWukongId.push(tokenId);
        if (user.hardStakedWukongId.length == 1) {
            totalHardStaker += 1;
        }
        totalStakedNFT += 1;

        return true;
    }

    function unHardStake(uint256 tokenId) external returns (bool) {
        address sender = _msgSender();
        require(_ownerOfHardStakingToken[tokenId] == sender, "Not owner of the staking NFT");
        
        HardStaker storage user = _hardStakers[sender];

        accumulatePassiveStake(sender);

        accumulateHardStake(sender);

        WukongNFT.safeTransferFrom(address(this), sender, tokenId);
        _ownerOfHardStakingToken[tokenId] = address(0);

        user.hardStakedWukongId = _moveTokenInTheList(user.hardStakedWukongId, tokenId);
        user.hardStakedWukongId.pop();

        if (user.hardStakedWukongId.length == 0) {
            totalHardStaker -= 1;
        }
        totalStakedNFT -= 1;

        return true;
    }

    function getAccumulatedHardStakeAmount(address staker) external view returns (uint256) {
        return _hardStakers[staker].accumulatedAmount + getCurrentHardStakeReward(staker);
    }
    
    function getAccumulatedPassiveStakeAmount(address _owner) external view returns (uint256) {
        return _passiveStakers[_owner].accumulatedAmount + getPassiveStakeReward(_owner);
    }

    function accumulatePassiveStake(address _owner) internal {
        _passiveStakers[_owner].accumulatedAmount += getPassiveStakeReward(_owner);
        _passiveStakers[_owner].lastCheckPoint = block.timestamp;
    }

    function accumulateHardStake(address staker) internal {
        _hardStakers[staker].accumulatedAmount += getCurrentHardStakeReward(staker);
        _hardStakers[staker].lastCheckpoint = block.timestamp;
    }

    function getCurrentHardStakeReward(address staker) internal view returns (uint256) {
        HardStaker memory user = _hardStakers[staker];

        // return (block.timestamp - user.lastCheckpoint);

        if (user.lastCheckpoint == 0 || block.timestamp < stakingStartPoint) {return 0;}

        return (block.timestamp - user.lastCheckpoint) / SECONDS_IN_DAY * user.hardStakedWukongId.length * HARDSTAKE_YIELD_PERDAY;
    }

    function getPassiveStakeReward(address _owner) internal view returns (uint256) {
        uint256 nftAmount = WukongNFT.balanceOf(_owner);

        uint256 startPoint = stakingStartPoint;
        if (_passiveStakers[_owner].lastCheckPoint != 0) {
            startPoint = _passiveStakers[_owner].lastCheckPoint;
        }

        return (block.timestamp - startPoint) / SECONDS_IN_DAY * nftAmount * PASSIVESTAKE_YIELD_PERDAY;
    }

    /**
    * @dev Returns token owner address (returns address(0) if token is not inside the gateway)
    */
    function ownerOf(uint256 tokenID) public view returns (address) {
        return _ownerOfHardStakingToken[tokenID];       
    }

    /**
    * @dev Admin function to authorise the contract address
    */
    function authorise(address toAuth) public onlyOwner {
        _authorised[toAuth] = true;
        authorisedLog.push(toAuth);
      }

    /**
    * @dev Function allows admin add unauthorised address.
    */
    function unauthorise(address addressToUnAuth) public onlyOwner {
        _authorised[addressToUnAuth] = false;
    }
  
    function emergencyWithdraw(uint256[] memory tokenIDs) public onlyOwner {
        require(tokenIDs.length <= 50, "50 is max per tx");
        pauseDeposit(true);

        for (uint256 i; i < tokenIDs.length; i++) {
            address receiver = _ownerOfHardStakingToken[tokenIDs[i]];

            if (receiver != address(0) && IERC721(WukongNFT).ownerOf(tokenIDs[i]) == address(this)) {
                IERC721(WukongNFT).transferFrom(address(this), receiver, tokenIDs[i]);
                // emit WithdrawStuckERC721(receiver, WukongNFT, tokenIDs[i]);
              }
        }
    }

    function _moveTokenInTheList(uint256[] memory list, uint256 tokenId) internal pure returns (uint256[] memory) {
        uint256 tokenIndex = 0;
        uint256 lastTokenIndex = list.length - 1;
        uint256 length = list.length;
  
        for(uint256 i = 0; i < length; i++) {
          if (list[i] == tokenId) {
            tokenIndex = i + 1;
            break;
          }
        }
        require(tokenIndex != 0, "msg.sender is not the owner");
  
        tokenIndex -= 1;
  
        if (tokenIndex != lastTokenIndex) {
          list[tokenIndex] = list[lastTokenIndex];
          list[lastTokenIndex] = tokenId;
        }
  
        return list;
      }


    /**
    * @dev Function allows to pause deposits if needed. Withdraw remains active.
    */
    function pauseDeposit(bool _pause) public onlyOwner {
        depositPaused = _pause;
      }
  
    
    function launchStaking() public onlyOwner {
        require(!stakingLaunched, "Staking has been launched already");
        stakingLaunched = true;
        // acceleratedYield = block.timestamp + (SECONDS_IN_DAY * HARDSTAKE_YIELD_PERDAY);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns(bytes4){
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}