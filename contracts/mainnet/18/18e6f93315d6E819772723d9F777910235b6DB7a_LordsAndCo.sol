// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.7;


//  /$$                                 /$$               /$$$         /$$$$$$              
// | $$                                | $$              /$$ $$       /$$__  $$             
// | $$        /$$$$$$   /$$$$$$   /$$$$$$$  /$$$$$$$   |  $$$       | $$  \__/  /$$$$$$    
// | $$       /$$__  $$ /$$__  $$ /$$__  $$ /$$_____/    /$$ $$/$$   | $$       /$$__  $$   
// | $$      | $$  \ $$| $$  \__/| $$  | $$|  $$$$$$    | $$  $$_/   | $$      | $$  \ $$   
// | $$      | $$  | $$| $$      | $$  | $$ \____  $$   | $$\  $$    | $$    $$| $$  | $$   
// | $$$$$$$$|  $$$$$$/| $$      |  $$$$$$$ /$$$$$$$/   |  $$$$/$$   |  $$$$$$/|  $$$$$$//$$
// |________/ \______/ |__/       \_______/|_______/     \____/\_/    \______/  \______/|__/                                                                           


interface ILoomi  {
  function depositLoomiFor(address user, uint256 amount) external;
  function activeTaxCollectedAmount() external view returns (uint256);
}

interface IStaking {
  function ownerOf(address contractAddress, uint256 tokenId) external view returns (address);
}

contract LordsAndCo is Ownable, ReentrancyGuard {
    
    // Creepz Contracts
    IERC721 public loomiVault;
    IERC721 public creepz;
    ILoomi public loomi;
    IStaking public staking;

    // Variables for daily yield
    uint256 public constant SECONDS_IN_DAY = 24 * 60 * 60;
    uint256 public constant DIVIDER = 10000;
    uint256 public baseYield;

    // Config bools
    bool public isPaused;
    bool public creepzRestriction;

    struct Staker {
      uint256 accumulatedAmount;
      uint256 lastCheckpoint;
      uint256 loomiPotSnapshot;
      uint256[] stakedVault;
    }

    mapping(address => Staker) private _stakers;
    mapping(uint256 => address) private _ownerOfToken;

    event Deposit(address indexed staker,uint256 tokensAmount);
    event Withdraw(address indexed staker,uint256 tokensAmount);
    event Claim(address indexed staker,uint256 tokensAmount);
    event WithdrawStuckERC721(address indexed receiver, address indexed tokenAddress, uint256 indexed tokenId);

    constructor(
      address _loomiVault,
      address _loomi,
      address _creepz,
      address _staking
    ) {
        loomiVault = IERC721(_loomiVault);
        loomi = ILoomi(_loomi);
        creepz = IERC721(_creepz);
        staking = IStaking(_staking);

        isPaused = true;
        creepzRestriction = true;
        baseYield = 500 ether;
    }

    modifier whenNotPaused() {
      require(!isPaused, "Contract paused");
        _;
    }

    /**
    * @dev Function for loomiVault deposit
    */
    function deposit(uint256[] memory tokenIds) public nonReentrant whenNotPaused {
      require(tokenIds.length > 0, "Empty array");
      Staker storage user = _stakers[_msgSender()];

      if (user.stakedVault.length == 0) {
        uint256 currentLoomiPot = _getLoomiPot();
        user.loomiPotSnapshot = currentLoomiPot;
      } 
      accumulate(_msgSender());

      for (uint256 i; i < tokenIds.length; i++) {
        require(loomiVault.ownerOf(tokenIds[i]) == _msgSender(), "Not the owner");
        loomiVault.safeTransferFrom(_msgSender(), address(this), tokenIds[i]);

        _ownerOfToken[tokenIds[i]] = _msgSender();

        user.stakedVault.push(tokenIds[i]);
      }

      emit Deposit(_msgSender(), tokenIds.length);
    }

    /**
    * @dev Function for loomiVault withdraw
    */
    function withdraw(uint256[] memory tokenIds) public nonReentrant whenNotPaused {
      require(tokenIds.length > 0, "Empty array");

      Staker storage user = _stakers[_msgSender()];
      accumulate(_msgSender());

      for (uint256 i; i < tokenIds.length; i++) {
        require(loomiVault.ownerOf(tokenIds[i]) == address(this), "Not the owner");

        _ownerOfToken[tokenIds[i]] = address(0);
        user.stakedVault = _moveTokenInTheList(user.stakedVault, tokenIds[i]);
        user.stakedVault.pop();

        loomiVault.safeTransferFrom(address(this), _msgSender(), tokenIds[i]);
      }

      emit Withdraw(_msgSender(), tokenIds.length);
    }

    /**
    * @dev Function for loomi reward claim
    * @notice caller must own a Genesis Creepz
    */
    function claim(uint256 tokenId) public nonReentrant whenNotPaused {
      Staker storage user = _stakers[_msgSender()];
      accumulate(_msgSender());

      require(user.accumulatedAmount > 0, "Insufficient funds");
      require(_validateCreepzOwner(tokenId, _msgSender()), "!Creepz owner");

      uint256 currentLoomiPot = _getLoomiPot();
      uint256 prevLoomiPot = user.loomiPotSnapshot;
      uint256 change = currentLoomiPot * DIVIDER / prevLoomiPot;
      uint256 finalAmount = user.accumulatedAmount * change / DIVIDER;

      user.loomiPotSnapshot = currentLoomiPot;
      user.accumulatedAmount = 0;
      loomi.depositLoomiFor(_msgSender(), finalAmount);

      emit Claim(_msgSender(), finalAmount);
    }

    /**
    * @dev Function for Genesis Creepz ownership validation
    */
    function _validateCreepzOwner(uint256 tokenId, address user) internal view returns (bool) {
      if (!creepzRestriction) return true;
      if (staking.ownerOf(address(creepz), tokenId) == user) {
        return true;
      }
      return creepz.ownerOf(tokenId) == user;
    }

    /**
    * @dev Returns accumulated $loomi amount for user based on baseRate
    */
    function getAccumulatedAmount(address staker) external view returns (uint256) {
      return _stakers[staker].accumulatedAmount + getCurrentReward(staker);
    }

    /**
    * @dev Returnes pot change from the last user claim
    */
    function getPriceChange(address user) public view returns (uint256) {
      if (_stakers[user].loomiPotSnapshot == 0) return 0;
      uint256 currentLoomiPot = _getLoomiPot();
      uint256 change = currentLoomiPot * DIVIDER / _stakers[user].loomiPotSnapshot;

      return change;
    }

    /**
    * @dev Returnes $loomi yield rate for user based on baseRate
    */
    function getStakerYield(address staker) public view returns (uint256) {
      return _stakers[staker].stakedVault.length * baseYield;
    }

    /**
    * @dev Returns array of IDs staked by address
    */
    function getStakerTokens(address staker) public view returns (uint256[] memory) {
      return _stakers[staker].stakedVault;
    }

    /**
    * @dev Returns current $loomi pot
    */
    function getLoomiPot() public view returns (uint256) {
      return _getLoomiPot();
    }

    /**
    * @dev Helper function for arrays
    */
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
    * @dev Returns current $loomi pot
    */
    function _getLoomiPot() internal view returns (uint256) {
      uint256 pot = loomi.activeTaxCollectedAmount();
      return pot;
    }

    /**
    * @dev Returns accumulated amount from last snapshot based on baseRate
    */
    function getCurrentReward(address staker) public view returns (uint256) {
      Staker memory user = _stakers[staker];
      if (user.lastCheckpoint == 0) { return 0; }
      return (block.timestamp - user.lastCheckpoint) * (baseYield * user.stakedVault.length) / SECONDS_IN_DAY;
    }

    /**
    * @dev Aggregates accumulated $loomi amount from last snapshot to user total accumulatedAmount
    */
    function accumulate(address staker) internal {
      _stakers[staker].accumulatedAmount += getCurrentReward(staker);
      _stakers[staker].lastCheckpoint = block.timestamp;
    }

    /**
    * @dev Returns token owner address (returns address(0) if token is not inside the gateway)
    */
    function ownerOf(uint256 tokenId) public view returns (address) {
      return _ownerOfToken[tokenId];
    }

    function updateCreepzRestriction(bool _restrict) public onlyOwner {
      creepzRestriction = _restrict;
    }

    /**
    * @dev Function allows admin withdraw ERC721 in case of emergency.
    */
    function emergencyWithdraw(address tokenAddress, uint256[] memory tokenIds) public onlyOwner {
      require(tokenIds.length <= 50, "50 is max per tx");
      for (uint256 i; i < tokenIds.length; i++) {
        address receiver = _ownerOfToken[tokenIds[i]];
        if (receiver != address(0) && IERC721(tokenAddress).ownerOf(tokenIds[i]) == address(this)) {
          IERC721(tokenAddress).transferFrom(address(this), receiver, tokenIds[i]);
          emit WithdrawStuckERC721(receiver, tokenAddress, tokenIds[i]);
        }
      }
    }

    /**
    * @dev Function allows to pause deposits if needed. Withdraw remains active.
    */
    function pause(bool _pause) public onlyOwner {
      isPaused = _pause;
    }

    /**
    * @dev Function allows admin to update the base yield for users.
    */
    function updateBaseYield(uint256 _yield) public onlyOwner {
      baseYield = _yield;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns(bytes4){
      return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
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