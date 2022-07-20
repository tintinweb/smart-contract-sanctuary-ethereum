pragma solidity ^0.8.0;

import "Ownable.sol";
import "ReentrancyGuard.sol";
import "Pausable.sol";
import "AggregatorV3Interface.sol";

contract TokenPredictionV2 is Ownable, Pausable, ReentrancyGuard {

    uint256 public treasuryFee;
    uint256 public treasuryAmount;
    uint256 public constant MAX_TREASURY_FEE = 1000; // 10%
    address public adminAddress;
    mapping(address => bool) public isOperator;
    uint256 public lastId;

    mapping(uint256 => mapping(address => PositionInfo)) public ledger;
    mapping(uint256 => Product) public products;
    mapping(address => uint256[]) public userPositions;

    modifier onlyOperator() {
        require(isOperator[msg.sender], "Not operator");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    struct Product {
        uint256 id;
        uint256 productType;
        uint256 startStamp;
        uint256 lockStamp;
        uint256 closeStamp;
        uint256 lockPrice;
        uint256 closePrice;
        uint256 minAmount;
        uint256 shortAmount;
        uint256 longAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        address oracleAddress;
        bool oracleCalled;
    }

    enum Position {
        Long,
        Short
    }

    struct PositionInfo {
        Position position;
        uint256 amount;
        bool claimed; // default false
    }

    event NewProduct(
        uint256 indexed id, uint256 productId,
        uint256 indexed lockPrice, uint256 minAmount,
        uint256 startStamp, uint256 lockStamp, uint256 indexed closeStamp,
        uint256 creationTime, address _oracle);
    event NewPosition(address indexed user, uint256 indexed id, bool indexed isLong, uint256 amount, uint256 creationTime);
    event Settlement(uint256 indexed id, uint256 rewardBaseCalAmount, uint256 rewardAmount, uint256 treasuryAmount, uint256 closePrice);
    event Claim(address indexed sender, uint256 indexed product, uint256 amount);

    constructor(uint256 _treasuryFee) {
        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");
        treasuryFee = _treasuryFee;
        isOperator[msg.sender] = true;
        lastId = 0;
    }

    function createProduct(
        uint256 _productType,
        uint256 _minAmount,
        uint256 _startStamp,
        uint256 _lockStamp,
        uint256 _closeStamp,
        address _oracle,
        uint256 _lockPrice)
    public onlyOperator {
        Product memory newProduct = Product({
        id : lastId,
        productType : _productType,
        startStamp : _startStamp,
        lockStamp : _lockStamp,
        closeStamp : _closeStamp,
        lockPrice : _lockPrice,
        closePrice : _lockPrice,
        minAmount : _minAmount,
        shortAmount : 0,
        longAmount : 0,
        rewardBaseCalAmount : 0,
        rewardAmount : 0,
        oracleAddress : _oracle,
        oracleCalled : false
        });
        products[lastId] = newProduct;
        emit NewProduct(lastId, _productType, _lockPrice, _minAmount,
            _startStamp, _lockStamp, _closeStamp, block.timestamp, _oracle);
        lastId++;
    }


    function enterPosition(uint256 _id, bool _isLong) external payable whenNotPaused nonReentrant notContract {

        uint256 amount = msg.value;

        // get product and positionInfo
        Product storage product = products[_id];
        PositionInfo storage positionInfo = ledger[_id][msg.sender];

        require(amount >= product.minAmount, "Not enough ETH sent!");

        if (_isLong) {
            product.longAmount += amount;
            positionInfo.position = Position.Long;
        } else {
            product.shortAmount += amount;
            positionInfo.position = Position.Short;
        }

        positionInfo.amount = amount;
        userPositions[msg.sender].push(_id);

        emit NewPosition(msg.sender, _id, _isLong, amount, block.timestamp);

    }


    function settleProduct(uint256 _id, uint80 _roundId) external whenNotPaused nonReentrant notContract {

        uint256 rewardBaseCalAmount;
        uint256 treasuryAmt;
        uint256 rewardAmount;
        uint256 productTotalAmount;

        Product storage product = products[_id];

        // call Oracle twice to make sure roundId is correct
        (uint256 closePrice, uint256 closeStamp) = oraclePrice(product.oracleAddress, _roundId);
        (uint256 previousPrice, uint256 previousStamp) = oraclePrice(product.oracleAddress, _roundId - 1);
        require(closeStamp >= product.closeStamp && product.closeStamp >= previousStamp, "Wrong roundId provided!");

        product.closePrice = closePrice;
        productTotalAmount = product.longAmount + product.shortAmount;

        // Long wins
        if (product.closePrice > product.lockPrice) {
            rewardBaseCalAmount = product.longAmount;
            treasuryAmt = (productTotalAmount * treasuryFee) / 10000;
            rewardAmount = productTotalAmount - treasuryAmt;
        }
        // Short wins
        else if (product.closePrice < product.lockPrice) {
            rewardBaseCalAmount = product.shortAmount;
            treasuryAmt = (productTotalAmount * treasuryFee) / 10000;
            rewardAmount = productTotalAmount - treasuryAmt;
        }
        // Everyone wins
        else {
            rewardBaseCalAmount = productTotalAmount;
            treasuryAmt = (productTotalAmount * treasuryFee) / 10000;
            rewardAmount = productTotalAmount - treasuryAmt;
        }
        product.rewardBaseCalAmount = rewardBaseCalAmount;
        product.rewardAmount = rewardAmount;
        product.oracleCalled = true;

        // Add to treasury
        treasuryAmount += treasuryAmt;

        emit Settlement(_id, rewardBaseCalAmount, rewardAmount, treasuryAmt, closePrice);

    }

    function claimable(uint256 epoch, address user) public view returns (bool) {
        PositionInfo memory positionInfo = ledger[epoch][user];
        Product memory product = products[epoch];
        return
        product.oracleCalled &&
        positionInfo.amount != 0 &&
        !positionInfo.claimed &&
        ((product.closePrice >= product.lockPrice && positionInfo.position == Position.Long) ||
        (product.closePrice <= product.lockPrice && positionInfo.position == Position.Short));
    }

    function claim(uint256[] calldata epochs) external nonReentrant notContract {
        uint256 reward;
        // Initializes reward

        for (uint256 i = 0; i < epochs.length; i++) {

            require(block.timestamp >= products[epochs[i]].startStamp, "Round has not started yet");
            require(block.timestamp >= products[epochs[i]].closeStamp, "Round has not ended yet");

            uint256 addedReward = 0;

            // Round valid, claim rewards
            if (products[epochs[i]].oracleCalled) {
                require(claimable(epochs[i], msg.sender), "Not eligible for claim");
                Product memory product = products[epochs[i]];
                addedReward = (ledger[epochs[i]][msg.sender].amount * product.rewardAmount) / product.rewardBaseCalAmount;
            }

            ledger[epochs[i]][msg.sender].claimed = true;
            reward += addedReward;

            emit Claim(msg.sender, epochs[i], addedReward);
        }

    }

    function oraclePrice(address _oracle, uint80 _roundId) public view returns (uint256 price, uint256 stamp) {
        AggregatorV3Interface oracle = AggregatorV3Interface(_oracle);
        (, int256 roundPrice, uint256 roundStamp,,) = oracle.getRoundData(_roundId);
        uint8 decimals = oracle.decimals();
        // format is done so that returned price is ALWAYS with 18 decimals
        return (uint256(roundPrice) * uint256(10 ** 18 / 10 ** decimals), roundStamp);
    }

    function _isContract(address _account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_account)
        }
        return size > 0;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}