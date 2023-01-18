pragma solidity ^0.8.12;

import "Ownable.sol";
import "ReentrancyGuard.sol";
import "Pausable.sol";
import "AggregatorV3Interface.sol";

contract LookBack is Ownable, Pausable, ReentrancyGuard {

    bytes32 private jobId;
    uint256 private fee;

    uint256 treasury;
    uint256 treasuryFee;
    uint64 collateralRatio;
    uint256 stakeMin;
    uint256 lockingRatio;
    bool isInitialized;
    string baseURL;
    uint256 public constant MAX_TREASURY_FEE = 1000; // 10%
    mapping(address => uint256[]) public userPositions;
    mapping(address => bool) public isOperator;
    uint256 public lastProductId;
    uint256 public lastPositionId;
    uint256 public lastSettlementId;
    uint256 public lastStakeId;
    mapping(uint256 => Product) public products;
    mapping(uint256 => Position) public positions;
    mapping(address => uint256) public stakers;
    mapping(uint256 => mapping(address => StakeInfo)) public stakingLedger;
    mapping(bytes32 => BindingBid) public bindingBids;

    receive() external payable {}

    fallback() external payable {}

    modifier onlyOperator() {
        require(isOperator[msg.sender], "Not operator");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    enum ProductStrikeType {
        Fixed,
        Floating
    }

    struct StakeInfo {
        uint256 id;
        uint256 productId;
        uint256 stakeUnits;
        uint256 lockedUntil;
        address user;
        bool isExist;
    }

    struct Product {
        uint256 id;
        bool isCall;
        uint256 timeToExpiry;
        uint256 startValidity;
        uint256 endValidity;
        uint256 minQuantity;
        uint256 impliedVol;
        uint256 priceRatio;
        address oracleAddress;
        bool isInitialized;
        uint256 stake;
        uint256 stakeUnits;
        uint256 lockedStake;
    }

    struct Position {
        uint256 id;
        uint256 productId;
        uint256 startStamp;
        uint256 closeStamp;
        uint256 refPrice;
        uint256 strike;
        uint256 quantity;
        bool isClaimed;
        address user;
    }

    struct BindingBid {
        bytes32 id;
        address user;
        uint256 positionId;
        uint256 productId;
        uint256 bid;
        uint256 bidValidity;
    }

    constructor(uint256 _treasuryFee) {
        treasuryFee = _treasuryFee;
        isOperator[msg.sender] = true;
        lastProductId = 0;
        lastPositionId = 0;
        lastSettlementId = 0;
        lastStakeId = 0;
        collateralRatio = 3;
        lockingRatio = 3;
        stakeMin = 0.005 ether;
    }

    event NewProduct(uint256 indexed id, bool isCall, uint256 timeToExpiry, uint256 impliedVol, uint256 priceRatio,
        uint256 startValidity, uint256 endValidity, uint256 minQuantity, address oracle);

    function createProduct(
        bool _isCall,
        uint256 _timeToExpiry,
        uint256 _impliedVol,
        uint256 _priceRatio,
        uint256 _startValidity,
        uint256 _endValidity,
        uint256 _minQuantity,
        address _oracle
    )
    public onlyOperator {
        Product memory newProduct = Product({
        id : lastProductId,
        isCall : _isCall,
        timeToExpiry : _timeToExpiry,
        impliedVol : _impliedVol,
        priceRatio: _priceRatio,
        startValidity : _startValidity,
        endValidity : _endValidity,
        minQuantity : _minQuantity,
        oracleAddress : _oracle,
        isInitialized : false,
        stake : 0,
        stakeUnits : 0,
        lockedStake : 0
        });
        products[lastProductId] = newProduct;
        emit NewProduct(lastProductId, _isCall, _timeToExpiry, _impliedVol, _priceRatio, _startValidity, _endValidity, _minQuantity, _oracle);
        lastProductId++;
    }

    // TODO: add user so can get it back for StakeInfo
    event ProductInitialized(uint256 indexed id, uint256 stake, uint256 stakeUnits, uint256 lockedUntil, address user);

    function initializeProduct(uint256 _productId, uint256 _stakeUnits) external onlyOwner payable {
        Product storage product = products[_productId];
        require(!product.isInitialized, "Product has already been initialized!");
        product.stakeUnits = _stakeUnits;
        product.stake = msg.value;
        product.isInitialized = true;
        StakeInfo memory stakeInfo = StakeInfo({
        id : lastStakeId,
        productId : _productId,
        stakeUnits : _stakeUnits,
        lockedUntil : block.timestamp + (product.timeToExpiry * lockingRatio),
        user : msg.sender,
        isExist : true
        });
        stakingLedger[_productId][msg.sender] = stakeInfo;
        emit ProductInitialized(_productId, msg.value, _stakeUnits, block.timestamp + (product.timeToExpiry * lockingRatio), msg.sender);
    }

    event NewPosition(uint256 indexed id, uint256 productId, uint256 startStamp, uint256 endStamp, uint256 refPrice, uint256 quantity, uint256 value, address user);

    function createPosition(uint256 _productId) public payable {

        // get product from storage
        Product storage product = products[_productId];
        require(product.endValidity >= block.timestamp + (15 * 60), "This product is not valid anymore");

        // get current price from oracle
        (uint256 currentPrice, uint8 decimals, uint256 currentStamp) = oraclePrice(product.oracleAddress, 0, true);
        require(currentPrice > 0, "Looks there is an issue with the oracle price");

        // get option price
        uint256 optionPrice = product.priceRatio;
        uint256 adjustedQuantity = msg.value * 10 ** 18 / optionPrice;

        treasury += treasuryFee * msg.value;
        product.stake += (1 - treasuryFee / 10000) * msg.value;
        require(adjustedQuantity >= product.minQuantity, "Not enough ETH sent!");
        require((product.stake - product.lockedStake) / collateralRatio >= adjustedQuantity, "Not enough collateral for this position size");
        product.lockedStake += collateralRatio * adjustedQuantity;

        // create empty position
        Position memory position = Position({
        id : lastPositionId,
        productId : _productId,
        startStamp : currentStamp,
        closeStamp : currentStamp + product.timeToExpiry,
        refPrice : currentPrice,
        strike : currentPrice,
        quantity : adjustedQuantity,
        isClaimed : false,
        user : msg.sender
        });
        positions[lastPositionId] = position;
        emit NewPosition(lastPositionId, _productId, currentStamp, currentStamp + product.timeToExpiry, currentPrice, adjustedQuantity, msg.value, msg.sender);
        lastPositionId++;
    }

    event Settlement(uint256 indexed id, uint256 positionId, uint256 refPrice, uint256 closePrice, uint256 stamp, uint256 value, address user);

    function settlePosition(uint256 _positionId, uint80 _roundId, uint80 _closeRoundId) external payable whenNotPaused nonReentrant notContract {
        Position storage position = positions[_positionId];
        require(position.closeStamp <= block.timestamp, "This position cannot be settled yet!");
        require(!position.isClaimed, "Position has already been claimed!");
        require(msg.sender == position.user, "You are not the owner of this position");
        Product storage product = products[position.productId];
        (uint256 historicPrice, uint8 historicDecimals, uint256 historicStamp) = oraclePrice(product.oracleAddress, _roundId, false);
        (uint256 closePrice, uint8 closeDecimals, uint256 closeStamp) = oraclePrice(product.oracleAddress, _closeRoundId, false);
        (uint256 previousPrice, uint8 previousDecimals, uint256 previousStamp) = oraclePrice(product.oracleAddress, _closeRoundId - 1, false);
        require(historicStamp >= position.startStamp && historicStamp <= position.closeStamp, "Wrong historic roundId provided");
        require(closeStamp >= position.closeStamp && position.closeStamp >= previousStamp, "Wrong close roundId provided!");
        position.refPrice = historicPrice;
        uint256 positionResult = 0;
        if (!product.isCall && position.strike > position.refPrice) {
            positionResult = (position.quantity * (position.strike - position.refPrice) / closePrice);
        } else if (product.isCall && position.refPrice > position.strike) {
            positionResult = (position.quantity * (position.refPrice - position.strike) / closePrice);
        }
        require(product.stake >= positionResult, "Collateral is not sufficient to pay you back ... Please contact support");
        position.isClaimed = true;
        product.stake -= positionResult;
        product.lockedStake -= collateralRatio * position.quantity;
        require(positionResult > 0, "Result is 0, nothing to be sent!");
        payable(msg.sender).transfer(positionResult);
        emit Settlement(lastSettlementId, position.id, historicPrice, closePrice, block.timestamp, positionResult, msg.sender);

        lastSettlementId += 1;
    }

    function oraclePrice(address _oracle, uint80 _roundId, bool _isLive) public view returns (uint256, uint8, uint256) {
        AggregatorV3Interface oracle = AggregatorV3Interface(_oracle);
        if (_isLive) {
            (, int256 roundPrice, uint256 roundStamp,,) = oracle.latestRoundData();
            uint8 decimals = oracle.decimals();
            return (uint256(roundPrice) * 10 ** (18 - decimals), decimals, roundStamp);
        } else {
            (, int256 roundPrice, uint256 roundStamp,,) = oracle.getRoundData(_roundId);
            uint8 decimals = oracle.decimals();
            return (uint256(roundPrice) * 10 ** (18 - decimals), decimals, roundStamp);
        }
    }


    event Staked(uint256 indexed id, uint256 productId, address user, uint256 stake, uint256 stakeUnits, uint256 lockedUntil);

    function stake(uint256 _productId) public payable whenNotPaused nonReentrant notContract {
        Product storage product = products[_productId];
        uint256 currentCollateralUnitValue = product.stake / product.stakeUnits;
        uint256 stakeUnitsAttributed = msg.value / currentCollateralUnitValue;
        product.stake += msg.value;
        product.stakeUnits += stakeUnitsAttributed;
        if (!stakingLedger[_productId][msg.sender].isExist) {
            StakeInfo storage stakeInfo = stakingLedger[_productId][msg.sender];
            stakeInfo.stakeUnits += stakeUnitsAttributed;
            stakeInfo.lockedUntil += block.timestamp + (product.timeToExpiry * lockingRatio);
            emit Staked(stakeInfo.id, _productId, msg.sender, msg.value, stakeUnitsAttributed, block.timestamp + (product.timeToExpiry * lockingRatio));
        } else {
            StakeInfo memory stakeInfo = StakeInfo({
            id : lastStakeId,
            productId : _productId,
            user : msg.sender,
            stakeUnits : stakeUnitsAttributed,
            lockedUntil : block.timestamp + (product.timeToExpiry * lockingRatio),
            isExist : true
            });
            emit Staked(lastStakeId, _productId, msg.sender, msg.value, stakeUnitsAttributed, block.timestamp + (product.timeToExpiry * lockingRatio));
            lastStakeId++;
        }
    }

    event Unstaked(uint256 indexed id, uint256 productId, address user, uint256 stakeUnits);

    function unstake(uint256 _productId, uint256 _units) public payable whenNotPaused nonReentrant notContract {
        Product storage product = products[_productId];
        StakeInfo storage stakeInfo = stakingLedger[_productId][msg.sender];
        require(block.timestamp >= stakeInfo.lockedUntil, "Your stake is currently locked");
        require(stakeInfo.stakeUnits > 0, "You don't have any staking units for this product");
        require(_units <= stakeInfo.stakeUnits, "You can't withdraw more units than what you have");
        uint256 currentCollateralUnitValue = product.stake / product.stakeUnits;
        uint256 stakeUnitsValue = _units * currentCollateralUnitValue;
        require(product.stake - stakeUnitsValue >= product.lockedStake, "You can't withdraw that much collateral. Please wait for more positions to be unlocked.");
        stakeInfo.stakeUnits -= _units;
        product.stake -= stakeUnitsValue;
        product.stakeUnits -= _units;
        payable(msg.sender).transfer(stakeUnitsValue);
        emit Unstaked(stakeInfo.id, _productId, msg.sender, _units);
    }

    function withdrawTreasury(uint256 _amount) public payable onlyOwner nonReentrant {
        require(treasury >= _amount, "Not enough treasury to withdraw");
        treasury -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function switchOperator(address _user) public onlyOwner {
        isOperator[_user] = !isOperator[_user];
    }

    event IVPRUpdated(uint256 productId, uint256 IV, uint256 PR);
    function modifyIVPR(uint256[] memory _IVPR) public onlyOperator {
        require(_IVPR.length % 3 == 0, "Looks array is not correct!");
        for (uint256 i=0; i < _IVPR.length; i+=3) {
            require(_IVPR[i+1] > 0, "IV must be a positive number");
            require(_IVPR[i+2] > 0, "PR must be a positive number");
            products[i].impliedVol = _IVPR[i+1];
            products[i].priceRatio = _IVPR[i+2];
            emit IVPRUpdated(i, _IVPR[i+1], _IVPR[i+2]);
        }
    }

    function modifyProduct(uint256 _productId, uint256 _minQuantity, uint256 _endValidity) public onlyOperator {
        Product storage product = products[_productId];
        product.minQuantity = _minQuantity;
        product.endValidity = _endValidity;
    }

    function modifyBaseURL(string memory _newBaseURL) public onlyOwner {
        baseURL = _newBaseURL;
    }

    function modifyCollateralRatio(uint64 _newRatio) public onlyOwner {
        collateralRatio = _newRatio;
    }

    function viewStakeUnits(address _user, uint256 _productId) public view returns (uint256, uint256) {
        StakeInfo storage stakeInfo = stakingLedger[_productId][msg.sender];
        return (stakeInfo.stakeUnits, stakeInfo.lockedUntil);
    }

    function viewCollateral(uint256 _productId) public view returns (uint256, uint256) {
        Product storage product = products[_productId];
        return (product.stake, product.stakeUnits);
    }

    function viewProduct(uint256 _productId) public view returns (Product memory) {
        Product storage product = products[_productId];
        return product;
    }

    function viewProducts() public view returns (Product[] memory) {
        Product[] memory productsArray = new Product[](lastProductId);
        for (uint i = 0; i < lastProductId; i++) {
            Product storage product = products[i];
            productsArray[i] = product;
        }
        return productsArray;
    }

    function viewPosition(uint256 _positionId) public view returns (Position memory) {
        Position storage position = positions[_positionId];
        return position;
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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