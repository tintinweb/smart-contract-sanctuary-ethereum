// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import './libraries/Claimable.sol';
import './libraries/RandomUtil.sol';
import './interfaces/IRagmon.sol';
import './interfaces/IZeny.sol';
import './interfaces/IMinter.sol';

contract Minter is IMinter, Claimable, Pausable, ReentrancyGuard {
  using SafeMath for uint256;

  uint256 public nonce = 0;
  uint256 public auctionStartTime;
  bool public isMinter = true;

  mapping(address => bool) private _delegates;

  mapping(uint8 => uint256) public mintCountByGrade;
  mapping(uint8 => uint256) public mintLimitByGrade;

  uint16[] private _freeMintAllowedMonsterTypes;
  mapping(address => uint256) private _whitelists;
  mapping(uint8 => uint256[5]) private _lastMintPricesByGrade;
  mapping(uint8 => uint256) private _lastMintIndexByGrade;

  uint256 public constant START_PRICE = 0.1 * (10 ** 18);
  uint256 public constant AUCTION_DURATION = 1 days;

  /**
   * @notice Mappings
   */
  IRagmon public ragmon;
  IERC20 public paymentToken;

  constructor(address _ragmonAddress, address _paymentTokenAddress) {
    ragmon = IRagmon(_ragmonAddress);
    paymentToken = IERC20(_paymentTokenAddress);

    auctionStartTime = block.timestamp;
  }

  /**
   * @dev Setters
   */
  function setRagmon(IRagmon _ragmon) external onlyOwner {
    ragmon = _ragmon;
    require(ragmon.isRagmon(), 'Invalid Ragmon contract');
  }

  function setPaymentToken(IERC20 _paymentToken) external onlyOwner {
    paymentToken = _paymentToken;
  }

  function setMintLimit(uint8 monsterGrade, uint256 limit) external onlyOwner {
    require(limit > mintLimitByGrade[monsterGrade]);
    require(limit > mintCountByGrade[monsterGrade]);

    mintLimitByGrade[monsterGrade] = limit;
  }

  function addWhiteList(address[] memory _addresses) public onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      _whitelists[_addresses[i]] = 1;
    }
  }

  function setFreeMintAllowedMonsterTypes(
    uint16[] memory _monsterTypes
  ) public onlyOwner {
    _freeMintAllowedMonsterTypes = new uint16[](_monsterTypes.length);
    for (uint256 i = 0; i < _monsterTypes.length; i++) {
      uint8 monsterGrade = ragmon.getPrototype(_monsterTypes[i]).monsterGrade;
      require(monsterGrade == 1, 'Free mint only allowed for grade 1');

      _freeMintAllowedMonsterTypes[i] = _monsterTypes[i];
    }
  }

  /**
   * @dev Pausable
   */
  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  /**
   * @dev Methods
   */
  function mint(
    uint16 monsterType,
    string memory signature,
    address receiver,
    uint256 _nonce
  ) external payable nonReentrant whenNotPaused {
    require(receiver != address(0), 'Invalid receiver');
    // NOTE: To avoid
    require(_nonce == nonce, 'Invalid nonce');

    uint256 hashed = RandomUtil.generateSeed(signature);
    IRagmon.MonsterPrototype memory prototype = ragmon.getPrototype(
      monsterType
    );
    require(prototype.monsterType > 0, 'Invalid monster type');

    uint8 monsterGrade = prototype.monsterGrade;
    require(
      mintCountByGrade[monsterGrade] + 1 <= mintLimitByGrade[monsterGrade],
      'Mint limit reached'
    );

    uint256 currentPrice = getCurrentPrice(monsterGrade);
    if (address(paymentToken) == address(0)) {
      uint256 amount = msg.value;
      require(amount >= currentPrice, 'Insufficient ETH');
      if (amount > currentPrice) {
        payable(msg.sender).transfer(amount - currentPrice);
      }
    } else {
      require(msg.value == 0, 'Invalid ETH');

      paymentToken.transferFrom(msg.sender, address(this), currentPrice);
    }
    _createMonster(prototype, hashed, signature, receiver);

    setLastMintPrice(monsterGrade, currentPrice);
    mintCountByGrade[monsterGrade]++;
  }

  function freeMint(
    string memory signature
  ) public whenNotPaused nonReentrant returns (uint256 tokenId) {
    require(_whitelists[msg.sender] > 0, 'Not whitelisted');
    require(_freeMintAllowedMonsterTypes.length > 0, 'No free mint allowed');
    _whitelists[msg.sender]--;

    uint256 hashed = RandomUtil.generateSeed(
      string(abi.encodePacked(signature))
    );
    uint16 sliced = uint16(RandomUtil.slice(hashed, 16, 0));
    uint16 monsterType = _freeMintAllowedMonsterTypes[
      sliced % _freeMintAllowedMonsterTypes.length
    ];
    IRagmon.MonsterPrototype memory prototype = ragmon.getPrototype(
      monsterType
    );
    require(prototype.monsterType > 0, 'Invalid monster type');

    return _createMonster(prototype, hashed, signature, msg.sender);
  }

  function airdrop(
    uint16 monsterType,
    string memory signature,
    address[] memory receivers
  ) external nonReentrant whenNotPaused onlyAuthorized {
    require(receivers.length > 0, 'No receivers');
    require(receivers.length <= 160, 'Too many receivers');

    uint256 hashed = RandomUtil.generateSeed(signature);
    IRagmon.MonsterPrototype memory prototype;
    for (uint i = 0; i < receivers.length; i++) {
      prototype = ragmon.getPrototype(monsterType);
      require(prototype.monsterType > 0, 'Invalid monster type');

      _createMonster(prototype, hashed, signature, receivers[i]);
    }
  }

  function airdropRandom(
    string memory signature,
    address[] memory receivers
  ) external nonReentrant whenNotPaused onlyAuthorized {
    require(receivers.length > 0, 'No receivers');
    require(receivers.length <= 160, 'Too many receivers');

    uint16[] memory types = ragmon.getAllowedMonsterTypes(1);
    uint16 count = uint16(types.length);

    uint256 hashed;
    uint16 offset;
    uint16 sliced;
    uint16 monsterType;
    IRagmon.MonsterPrototype memory prototype;
    for (uint i = 0; i < receivers.length; i++) {
      offset = uint16(i % 16);
      if (offset == 0) {
        hashed = RandomUtil.generateSeed(
          string(abi.encodePacked(signature, i))
        );
      }

      sliced = uint16(RandomUtil.slice(hashed, 16, offset));
      monsterType = types[sliced % count];
      prototype = ragmon.getPrototype(monsterType);
      require(prototype.monsterType > 0, 'Invalid monster type');

      _createMonster(prototype, hashed, signature, receivers[i]);
    }
  }

  function _createMonster(
    IRagmon.MonsterPrototype memory prototype,
    uint256 hashed,
    string memory signature,
    address receiver
  ) internal returns (uint256 tokenId) {
    nonce++;
    uint256 genes = ragmon.monsterGene().generate(
      prototype,
      string(abi.encodePacked(hashed, signature, nonce))
    );

    tokenId = ragmon.mintMonster(
      prototype.monsterGrade,
      prototype.monsterType,
      genes,
      receiver
    );

    emit Minted(receiver, tokenId);
  }

  function setDelegate(
    address runner,
    bool enabled
  ) external onlyOwner whenNotPaused {
    _delegates[runner] = enabled;

    emit Delegate(runner, enabled);
  }

  function getAverageLastMintPrice(
    uint8 monsterGrade
  ) public view returns (uint256) {
    uint256[5] memory lastMintPrices = _lastMintPricesByGrade[monsterGrade];
    uint256 sum = 0;
    for (uint256 i = 0; i < 5; i++) {
      if (lastMintPrices[i] > 0) {
        sum += lastMintPrices[i];
      } else {
        sum += START_PRICE;
      }
    }

    return sum / 5;
  }

  function setLastMintPrice(uint8 monsterGrade, uint256 price) private {
    // function setLastMintPrice(uint8 monsterGrade, uint256 price) private {
    uint256[5] storage lastMintPrices = _lastMintPricesByGrade[monsterGrade];
    uint256 lastMintIndex = _lastMintIndexByGrade[monsterGrade];

    lastMintPrices[lastMintIndex] = price;
    _lastMintIndexByGrade[monsterGrade] = (lastMintIndex + 1) % 5;
    auctionStartTime = block.timestamp;
  }

  function getCurrentPrice(uint8 monsterGrade) public view returns (uint256) {
    uint256 averageLastMintPrice = getAverageLastMintPrice(monsterGrade);
    require(averageLastMintPrice == uint256(uint128(averageLastMintPrice)));

    if (averageLastMintPrice < START_PRICE) {
      return START_PRICE;
    }

    uint256 nextPrice = averageLastMintPrice.mul(150).div(100);
    if (nextPrice < START_PRICE) {
      return START_PRICE;
    }

    uint256 secondsPassed = 0;
    if (block.timestamp > auctionStartTime) {
      secondsPassed = block.timestamp - auctionStartTime;
    }

    nextPrice = _computeCurrentPrice(
      nextPrice,
      0,
      AUCTION_DURATION,
      secondsPassed
    );

    if (nextPrice < START_PRICE) {
      return START_PRICE;
    }

    return nextPrice;
  }

  function _computeCurrentPrice(
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration,
    uint256 _secondsPassed
  ) internal pure returns (uint256) {
    if (_secondsPassed >= _duration) {
      return _endingPrice;
    }

    int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);
    int256 currentPriceChange = (totalPriceChange * int256(_secondsPassed)) /
      int256(_duration);
    int256 currentPrice = int256(_startingPrice) + currentPriceChange;

    return uint256(currentPrice);
  }

  function _isAuthorized(address caller) internal view returns (bool) {
    return _delegates[caller] || owner() == caller;
  }

  modifier onlyAuthorized() {
    require(_isAuthorized(msg.sender), 'Not authorized');
    _;
  }

  /**
   * @dev Emitted when delegate is enabled or disabled
   */
  event Delegate(address runner, bool enabled);

  event Minted(address indexed owner, uint256 indexed tokenId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IBalanceSheet {
  function isBalanceSheet() external view returns (bool);

  function getCost(uint16 monsterType) external view returns (uint);

  function setCost(uint16 monsterType, uint8 cost) external;

  function getMergeRate(uint8 monsterGrade) external view returns (uint16);

  function setMergeRate(uint8 monsterGrade, uint16 mergeRate) external;

  function getMergeCost(uint8 monsterGrade) external view returns (uint16);

  function setMergeCost(uint8 monsterGrade, uint16 mergeCost) external;

  function getMaxMonsterGrade() external view returns (uint8);

  function setMaxMonsterGrade(uint8 _maxMonsterGrade) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import './IMonsterGene.sol';

interface IMinter {
  function isMinter() external view returns (bool);

  function mint(
    uint16 monsterType,
    string memory signature,
    address receiver,
    uint256 _nonce
  ) external payable;

  function airdrop(
    uint16 monsterType,
    string memory signature,
    address[] memory receivers
  ) external;

  function airdropRandom(
    string memory signature,
    address[] memory receivers
  ) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import './IRagmon.sol';

interface IMonsterGene {
  function isMonsterGene() external view returns (bool);

  function generate(
    IRagmon.MonsterPrototype memory prototype,
    string memory signature
  ) external view returns (uint256);

  function decode(
    uint256 gene
  ) external view returns (IRagmon.DecodedMonster memory);

  function merge(
    uint256 gene1,
    uint256 gene2,
    string memory signature
  ) external view returns (uint256);

  function decodeMonsterGrade(uint256 genes) external pure returns (uint8);

  function decodeMonsterType(uint256 genes) external pure returns (uint16);

  function decodeMonsterDummyGenes(
    uint256 genes
  ) external pure returns (uint256 dummyGenes);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/interfaces/IERC721.sol';
import './IBalanceSheet.sol';
import './IMonsterGene.sol';

interface IRagmon is IERC721 {
  struct Monster {
    uint8 monsterGrade;
    uint16 monsterType;
    uint256 genes;
  }

  struct MonsterPrototype {
    string name;
    uint8 monsterGrade;
    uint16 monsterType;
    uint8 race;
    uint8 element;
    uint8 size;
    bool rangeAttack;
    uint16[2][6] statRanges;
  }

  enum Race {
    Angel,
    Brute,
    DemiHuman,
    Demon,
    Dragon,
    Fish,
    Formless,
    Insect,
    Plant,
    Undead
  }

  enum Element {
    Dark,
    Earth,
    Fire,
    Holy,
    Water,
    Wind
  }

  enum Size {
    Large,
    Medium,
    Small
  }

  struct DecodedMonster {
    string name;
    uint8 monsterGrade;
    uint16 monsterType;
    uint8 race;
    uint8 element;
    uint8 size;
    bool rangeAttack;
    uint16[6] stats; // STR, AGI, LUK, INT, DEX, CON
  }

  function isRagmon() external view returns (bool);

  function balanceSheet() external view returns (IBalanceSheet);

  function monsterGene() external view returns (IMonsterGene);

  function setBaseURI(string calldata baseTokenURI) external;

  function mintMonster(
    uint8 monsterGrade,
    uint16 monsterType,
    uint256 genes
  ) external returns (uint256);

  function mintMonster(
    uint8 monsterGrade,
    uint16 monsterType,
    uint256 genes,
    address receiver
  ) external returns (uint256);

  function burn(uint256 tokenId) external;

  function getMonster(uint256 tokenId) external view returns (Monster memory);

  function setAllowedMonsterType(
    uint8 monsterGrade,
    uint16 monsterType,
    bool enabled
  ) external;

  function getAllowedMonsterTypes(
    uint8 monsterGrade
  ) external view returns (uint16[] memory);

  function setMinter(address minter, bool enabled) external;

  function isMinter(address account) external view returns (bool);

  function getPrototype(
    uint16 monsterType
  ) external view returns (MonsterPrototype memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/interfaces/IERC20.sol';

interface IZeny is IERC20 {
  function isZeny() external view returns (bool);

  function decimals() external view returns (uint8);

  function burn(uint256 amount) external;

  function burnFrom(address account, uint256 amount) external;

  function setInterestRate(int16 _interestRate) external;

  function setIssuer(address _issuer) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';

contract Claimable is Ownable {
  function claim(
    address tokenAddress,
    address payable targetAddress
  ) external onlyOwner {
    address target = targetAddress == address(0) ? owner() : targetAddress;

    if (tokenAddress == address(0)) {
      // Claim Ether
      uint256 etherBalance = address(this).balance;
      require(etherBalance > 0, 'No Ether to claim');
      payable(target).transfer(etherBalance);
    } else {
      // Claim ERC20 tokens
      IERC20 token = IERC20(tokenAddress);
      uint256 tokenBalance = token.balanceOf(address(this));
      require(tokenBalance > 0, 'No tokens to claim');
      token.transfer(owner(), tokenBalance);
    }
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

library RandomUtil {
  function generateSeed(
    string memory _signature
  ) internal view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            block.timestamp,
            block.difficulty,
            msg.sender,
            _signature
          )
        )
      );
  }

  /**
   * @dev given a number get a slice of any bits, at certain offset
   * @param _input a number to be sliced
   * @param _nbits how many bits long is the new number
   * @param _offset how many bits to skip
   */
  function slice(
    uint256 _input,
    uint256 _nbits,
    uint256 _offset
  ) internal pure returns (uint256) {
    // mask is made by shifting left an offset number of times
    uint256 mask = uint256((2 ** _nbits) - 1) << _offset;
    // AND n with mask, and trim to max of _nbits bits
    return uint256((_input & mask) >> _offset);
  }

  function clamp(
    uint16 _input,
    uint16 _min,
    uint16 _max
  ) internal pure onlyProperRange(_min, _max) returns (uint16) {
    return (_input % (_max - _min + 1)) + _min;
  }

  function get16Bits(
    uint256 _input,
    uint256 _slot
  ) internal pure returns (uint16) {
    return uint16(slice(_input, uint256(16), _slot * 16));
  }

  function determineRandomValue(
    uint256 _input,
    uint256 _min,
    uint256 _max
  ) internal pure onlyProperRange(_min, _max) returns (uint256) {
    return (_input % (_max - _min + 1)) + _min;
  }

  modifier onlyProperRange(uint256 _min, uint256 _max) {
    require(
      _min <= _max,
      'Min value should be less than or equal to max value'
    );
    _;
  }
}