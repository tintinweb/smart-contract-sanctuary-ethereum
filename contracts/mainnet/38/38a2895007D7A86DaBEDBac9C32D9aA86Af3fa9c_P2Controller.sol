// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./interface/IP2Controller.sol";
import "./interface/IOracle.sol";
import "./interface/IXNFT.sol";
import "./P2ControllerStorage.sol";
import "./Exponential.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract P2Controller is P2ControllerStorage, Exponential,  Initializable{

    using SafeMath for uint256;

    function initialize(ILiquidityMining _liquidityMining) external initializer {
        admin = msg.sender;
        liquidityMining = _liquidityMining;
    }

    function mintAllowed(address xToken, address minter, uint256 mintAmount) external view whenNotPaused(xToken, 1){
        require(poolStates[xToken].isListed, "token not listed");

        uint256 supplyCap = poolStates[xToken].supplyCap;

        if (supplyCap != 0) {
            uint256 _totalSupply = IXToken(xToken).totalSupply();
            uint256 _exchangeRate = IXToken(xToken).exchangeRateStored();
            
            uint256 totalUnderlyingSupply = mulScalarTruncate(_exchangeRate, _totalSupply);
            uint nextTotalUnderlyingSupply = totalUnderlyingSupply.add(mintAmount);
            require(nextTotalUnderlyingSupply < supplyCap, "market supply cap reached");
        }
    }

    function mintVerify(address xToken, address account) external whenNotPaused(xToken, 1){
        updateSupplyVerify(xToken, account, true);
    }

    function redeemAllowed(address xToken, address redeemer, uint256 redeemTokens, uint256 redeemAmount) external view whenNotPaused(xToken, 2){
        require(poolStates[xToken].isListed, "token not listed");
    }

    function redeemVerify(address xToken, address redeemer) external whenNotPaused(xToken, 2){
        updateSupplyVerify(xToken, redeemer, false);
    } 

    function orderAllowed(uint256 orderId, address borrower) internal view returns(address){
        (address _collection , , address _pledger) = xNFT.getOrderDetail(orderId);

        require((_collection != address(0) && _pledger != address(0)), "order not exist");
        require(_pledger == borrower, "borrower don't hold the order");

        bool isLiquidated = xNFT.isOrderLiquidated(orderId);
        require(!isLiquidated, "order has been liquidated");
        return _collection;
    }

    function borrowAllowed(address xToken, uint256 orderId, address borrower, uint256 borrowAmount) external whenNotPaused(xToken, 3){
        require(poolStates[xToken].isListed, "token not listed");

        orderAllowed(orderId, borrower);

        (address _collection , , ) = xNFT.getOrderDetail(orderId);

        CollateralState storage _collateralState = collateralStates[_collection];
        require(_collateralState.isListed, "collection not exist");
        require(_collateralState.supportPools[xToken] || _collateralState.isSupportAllPools, "collection don't support this pool");

        address _lastXToken = orderDebtStates[orderId];
        require(_lastXToken == address(0) || _lastXToken == xToken, "only support borrowing of one xToken");

        (uint256 _price, bool valid) = oracle.getPrice(_collection, IXToken(xToken).underlying());
        require(_price > 0 && valid, "price is not valid");

        // Borrow cap of 0 corresponds to unlimited borrowing
        if (poolStates[xToken].borrowCap != 0) {
            require(IXToken(xToken).totalBorrows().add(borrowAmount) < poolStates[xToken].borrowCap, "pool borrow cap reached");
        }

        uint256 _maxBorrow = mulScalarTruncate(_price, _collateralState.collateralFactor);
        uint256 _mayBorrowed = borrowAmount;
        if (_lastXToken != address(0)){
            _mayBorrowed = IXToken(_lastXToken).borrowBalanceStored(orderId).add(borrowAmount);  
        }
        require(_mayBorrowed <= _maxBorrow, "borrow amount exceed");

        if (_lastXToken == address(0)){
            orderDebtStates[orderId] = xToken;
        }
    }

    function borrowVerify(uint256 orderId, address xToken, address borrower) external whenNotPaused(xToken, 3){
        require(orderDebtStates[orderId] == xToken , "collateral debt invalid");
        uint256 _borrowBalance = IXToken(xToken).borrowBalanceCurrent(orderId);
        updateBorrowVerify(orderId, xToken, borrower, _borrowBalance, true);
    }

    function repayBorrowAllowed(address xToken, uint256 orderId, address borrower, address payer, uint256 repayAmount) external view whenNotPaused(xToken, 4){
        require(poolStates[xToken].isListed, "token not listed");

        address _collection = orderAllowed(orderId, borrower);

        require(orderDebtStates[orderId] == xToken , "collateral debt invalid");
    }

    function repayBorrowVerify(address xToken, uint256 orderId, address borrower, address payer, uint256 repayAmount) external whenNotPaused(xToken, 4){
        require(orderDebtStates[orderId] == xToken , "collateral debt invalid");
        uint256 _borrowBalance = IXToken(xToken).borrowBalanceCurrent(orderId);

        updateBorrowVerify(orderId, xToken, borrower, _borrowBalance, false);

        if (_borrowBalance == 0) {
            delete orderDebtStates[orderId];
        }
    }

    function repayBorrowAndClaimVerify(address xToken, uint256 orderId) external whenNotPaused(xToken, 4){
        require(orderDebtStates[orderId] == address(0), "address invalid");
        xNFT.notifyRepayBorrow(orderId);
    }

    function liquidateBorrowAllowed(address xToken, uint256 orderId, address borrower, address liquidator) external view whenNotPaused(xToken, 5){
        require(poolStates[xToken].isListed, "token not listed");

        orderAllowed(orderId, borrower);

        (address _collection , , ) = xNFT.getOrderDetail(orderId);

        require(orderDebtStates[orderId] == xToken , "collateral debt invalid");

        (uint256 _price, bool valid) = oracle.getPrice(_collection, IXToken(xToken).underlying());
        require(_price > 0 && valid, "price is not valid");

        uint256 _borrowBalance = IXToken(xToken).borrowBalanceStored(orderId);
        uint256 _liquidateBalance = mulScalarTruncate(_price, collateralStates[_collection].liquidateFactor);

        require(_borrowBalance > _liquidateBalance, "order don't exceed borrow balance");
    } 

    function liquidateBorrowVerify(address xToken, uint256 orderId, address borrower, address liquidator, uint256 repayAmount)external whenNotPaused(xToken, 5){
        orderAllowed(orderId, borrower);

        (bool _valid, address _liquidator, uint256 _liquidatedPrice) = IXToken(xToken).orderLiquidated(orderId);

        if (_valid && _liquidator != address(0)){
            xNFT.notifyOrderLiquidated(xToken, orderId, _liquidator, _liquidatedPrice);
        }
    }

    function transferAllowed(address xToken, address src, address dst, uint256 transferTokens) external view{
        require(poolStates[xToken].isListed, "token not listed");
    }

    function transferVerify(address xToken, address src, address dst) external{
        updateSupplyVerify(xToken, src, false);
        updateSupplyVerify(xToken, dst, true);
    }

    function getOrderBorrowBalanceCurrent(uint256 orderId) external returns(uint256){
        address _xToken = orderDebtStates[orderId];
        if (_xToken == address(0)){
            return 0;
        }
        uint256 _borrowBalance = IXToken(_xToken).borrowBalanceCurrent(orderId);
        return _borrowBalance;
    }

    function updateSupplyVerify(address xToken, address account, bool isDeposit) internal{
        uint256 balance = IXToken(xToken).balanceOf(account);
        if(address(liquidityMining) != address(0)){
            liquidityMining.updateSupply(xToken, balance, account, isDeposit);
        }
    }

    function updateBorrowVerify(uint256 orderId, address xToken, address account, uint256 borrowBalance, bool isDeposit) internal{
        address collection = orderAllowed(orderId, account);
        if(address(liquidityMining) != address(0)){
            liquidityMining.updateBorrow(xToken, collection, borrowBalance, account, orderId, isDeposit);
        }
    }

    //================== admin funtion ==================

    function addPool(address xToken, uint256 _borrowCap, uint256 _supplyCap) external onlyAdmin{
        require(!poolStates[xToken].isListed, "pool has added");
        poolStates[xToken] = PoolState(
            true,
            _borrowCap,
            _supplyCap
        );
    }

    function addCollateral(address _collection, uint256 _collateralFactor, uint256 _liquidateFactor, address[] calldata _pools) external onlyAdmin{
        require(!collateralStates[_collection].isListed, "collection has added");
        require(_collateralFactor <= COLLATERAL_FACTOR_MAX, "_collateralFactor is greater than COLLATERAL_FACTOR_MAX");
        require(_liquidateFactor <= LIQUIDATE_FACTOR_MAX, " _liquidateFactor is greater than LIQUIDATE_FACTOR_MAX");
        
        collateralStates[_collection].isListed = true;
        collateralStates[_collection].collateralFactor = _collateralFactor;
        collateralStates[_collection].liquidateFactor = _liquidateFactor;

        if (_pools.length == 0){
            collateralStates[_collection].isSupportAllPools = true;
        }else{
            collateralStates[_collection].isSupportAllPools = false;

            for (uint i = 0; i < _pools.length; i++){
                collateralStates[_collection].supportPools[_pools[i]] = true;
            }
        }
    }

    function setCollateralState(address _collection, uint256 _collateralFactor, uint256 _liquidateFactor) external onlyAdmin {
        require(collateralStates[_collection].isListed, "collection has not added");
        require(_collateralFactor <= COLLATERAL_FACTOR_MAX, "_collateralFactor is greater than COLLATERAL_FACTOR_MAX");
        require(_liquidateFactor <= LIQUIDATE_FACTOR_MAX, " _liquidateFactor is greater than LIQUIDATE_FACTOR_MAX");
        collateralStates[_collection].collateralFactor = _collateralFactor;
        collateralStates[_collection].liquidateFactor = _liquidateFactor;
    }

    function setCollateralSupportPools(address _collection, address[] calldata _pools) external onlyAdmin{
        require(collateralStates[_collection].isListed, "collection has not added");
        
        if (_pools.length == 0){
            collateralStates[_collection].isSupportAllPools = true;
        }else{
            collateralStates[_collection].isSupportAllPools = false;

            for (uint i = 0; i < _pools.length; i++){
                collateralStates[_collection].supportPools[_pools[i]] = true;
            }
        }
    }

    function setOracle(address _oracle) external onlyAdmin{
        oracle = IOracle(_oracle);
    }

    function setXNFT(address _xNFT) external onlyAdmin{
        xNFT = IXNFT(_xNFT);
    }

    function setLiquidityMining(ILiquidityMining _liquidityMining) external onlyAdmin{
        liquidityMining = _liquidityMining;
    }

    function setPendingAdmin(address newPendingAdmin) external onlyAdmin{
        pendingAdmin = newPendingAdmin;
    }

    function acceptAdmin() external{
        require(msg.sender == pendingAdmin, "only pending admin could accept");
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    // 1 mint, 2 redeem, 3 borrow, 4 repayborrow, 5 liquidity
    function setPause(address xToken, uint256 index, bool isPause) external onlyAdmin{
        xTokenPausedMap[xToken][index] = isPause;
    }

    //================== admin funtion ==================
    modifier onlyAdmin(){
        require(msg.sender == admin, "admin auth");
        _;
    }

    modifier whenNotPaused(address xToken, uint256 index) {
        require(!xTokenPausedMap[xToken][index], "Pausable: paused");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IP2Controller {

    function mintAllowed(address xToken, address minter, uint256 mintAmount) external;

    function mintVerify(address xToken, address account) external;

    function redeemAllowed(address xToken, address redeemer, uint256 redeemTokens, uint256 redeemAmount) external;

    function redeemVerify(address xToken, address redeemer) external;
    
    function borrowAllowed(address xToken, uint256 orderId, address borrower, uint256 borrowAmount) external;

    function borrowVerify(uint256 orderId, address xToken, address borrower) external;

    function repayBorrowAllowed(address xToken, uint256 orderId, address borrower, address payer, uint256 repayAmount) external;

    function repayBorrowVerify(address xToken, uint256 orderId, address borrower, address payer, uint256 repayAmount) external;

    function repayBorrowAndClaimVerify(address xToken, uint256 orderId) external;

    function liquidateBorrowAllowed(address xToken, uint256 orderId, address borrower, address liquidator) external;

    function liquidateBorrowVerify(address xToken, uint256 orderId, address borrower, address liquidator, uint256 repayAmount)external;
    
    function transferAllowed(address xToken, address src, address dst, uint256 transferTokens) external;

    function transferVerify(address xToken, address src, address dst) external;

    function getOrderBorrowBalanceCurrent(uint256 orderId) external returns(uint256);

    // admin function

    function addPool(address xToken, uint256 _borrowCap, uint256 _supplyCap) external;

    function addCollateral(address _collection, uint256 _collateralFactor, uint256 _liquidateFactor, address[] calldata _pools) external;

    function setPriceOracle(address _oracle) external;

    function setXNFT(address _xNFT) external;
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IOracle {
    function getPrice(address collection, address denotedToken) external view returns (uint256, bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IXNFT {

    function pledge(address collection, uint256 tokenId, uint256 nftType) external;
    function pledge721(address _collection, uint256 _tokenId) external;
    function pledge1155(address _collection, uint256 _tokenId) external;
    function getOrderDetail(uint256 orderId) external view returns(address collection, uint256 tokenId, address pledger);
    function isOrderLiquidated(uint256 orderId) external view returns(bool);
    function withdrawNFT(uint256 orderId) external;


    // onlyController
    function notifyOrderLiquidated(address xToken, uint256 orderId, address liquidator, uint256 liquidatedPrice) external;
    function notifyRepayBorrow(uint256 orderId) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./interface/IXToken.sol";
import "./interface/IXNFT.sol";
import "./interface/IOracle.sol";
import "./interface/ILiquidityMining.sol";

contract P2ControllerStorage{

    address public admin;
    address public pendingAdmin;

    bool internal _notEntered;

    struct PoolState{
        bool isListed;
        uint256 borrowCap;
        uint256 supplyCap;
    }
    // xToken => poolState
    mapping(address => PoolState) public poolStates;

    struct CollateralState{
        bool isListed;
        uint256 collateralFactor;
        uint256 liquidateFactor;
        bool isSupportAllPools;
        mapping(address => bool) supportPools;
        // the speical NFT could or not borrow
        // mapping(uint256 => bool) blackList;
    }
    //nft address => state
    mapping(address => CollateralState) public collateralStates;

    // orderId => xToken
    mapping(uint256 => address) public orderDebtStates;

    IXNFT public xNFT;
    IOracle public oracle;
    ILiquidityMining public liquidityMining;

    uint256 internal constant COLLATERAL_FACTOR_MAX = 1e18;
    uint256 internal constant LIQUIDATE_FACTOR_MAX = 1e18;

    mapping(address => mapping(uint256 => bool)) public xTokenPausedMap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./library/SafeMath.sol";

contract Exponential {
    uint256 constant expScale = 1e18;
    uint256 constant halfExpScale = expScale / 2;

    using SafeMath for uint256;

    function getExp(uint256 num, uint256 denom)
        public
        pure
        returns (uint256 rational)
    {
        rational = num.mul(expScale).div(denom);
    }

    function getDiv(uint256 num, uint256 denom)
        public
        pure
        returns (uint256 rational)
    {
        rational = num.mul(expScale).div(denom);
    }

    function addExp(uint256 a, uint256 b) public pure returns (uint256 result) {
        result = a.add(b);
    }

    function subExp(uint256 a, uint256 b) public pure returns (uint256 result) {
        result = a.sub(b);
    }

    function mulExp(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 doubleScaledProduct = a.mul(b);

        uint256 doubleScaledProductWithHalfScale = halfExpScale.add(
            doubleScaledProduct
        );

        return doubleScaledProductWithHalfScale.div(expScale);
    }

    function divExp(uint256 a, uint256 b) public pure returns (uint256) {
        return getDiv(a, b);
    }

    function mulExp3(
        uint256 a,
        uint256 b,
        uint256 c
    ) external pure returns (uint256) {
        return mulExp(mulExp(a, b), c);
    }

    function mulScalar(uint256 a, uint256 scalar)
        public
        pure
        returns (uint256 scaled)
    {
        scaled = a.mul(scalar);
    }

    function mulScalarTruncate(uint256 a, uint256 scalar)
        public
        pure
        returns (uint256)
    {
        uint256 product = mulScalar(a, scalar);
        return truncate(product);
    }

    function mulScalarTruncateAddUInt(
        uint256 a,
        uint256 scalar,
        uint256 addend
    ) external pure returns (uint256) {
        uint256 product = mulScalar(a, scalar);
        return truncate(product).add(addend);
    }

    function divScalarByExpTruncate(uint256 scalar, uint256 divisor)
        public
        pure
        returns (uint256)
    {
        uint256 fraction = divScalarByExp(scalar, divisor);
        return truncate(fraction);
    }

    function divScalarByExp(uint256 scalar, uint256 divisor)
        public
        pure
        returns (uint256)
    {
        uint256 numerator = expScale.mul(scalar);
        return getExp(numerator, divisor);
    }

    function divScalar(uint256 a, uint256 scalar)
        external
        pure
        returns (uint256)
    {
        return a.div(scalar);
    }

    function truncate(uint256 exp) public pure returns (uint256) {
        return exp.div(expScale);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
import "./IERC20.sol";
import "./IInterestRateModel.sol";

interface IXToken is IERC20 {

    function balanceOfUnderlying(address owner) external returns (uint256);

    function mint(uint256 amount) external payable;
    function redeem(uint256 redeemTokens) external;
    function redeemUnderlying(uint256 redeemAmounts) external;

    function borrow(uint256 orderId, address payable borrower, uint256 borrowAmount) external;
    function repayBorrow(uint256 orderId, address borrower, uint256 repayAmount) external payable;
    function liquidateBorrow(uint256 orderId, address borrower) external payable;

    function orderLiquidated(uint256 orderId) external view returns(bool, address, uint256); 

    function accrueInterest() external;

    function borrowBalanceCurrent(uint256 orderId) external returns (uint256);
    function borrowBalanceStored(uint256 orderId) external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);
    function exchangeRateStored() external view returns (uint256);

    function underlying() external view returns(address);
    function totalBorrows() external view returns(uint256);
    function totalCash() external view returns (uint256);
    function totalReserves() external view returns (uint256);

    /**admin function **/
    function setPendingAdmin(address payable newPendingAdmin) external;
    function acceptAdmin() external;
    function setReserveFactor(uint256 newReserveFactor) external;
    function reduceReserves(uint256 reduceAmount) external;
    function setInterestRateModel(IInterestRateModel newInterestRateModel) external;
    function setTransferEthGasCost(uint256 _transferEthGasCost) external;

    /**event */
    event Mint(address minter, uint256 mintAmount, uint256 mintTokens);
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);
    event Borrow(uint256 orderId, address borrower, uint256 borrowAmount, uint256 orderBorrows, uint256 totalBorrows);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewAdmin(address oldAdmin, address newAdmin);
    
}

pragma solidity ^0.8.2;

interface ILiquidityMining {

    function updateBorrow(address xToken, address collection, uint256 amount, address account, uint256 orderId, bool isDeposit) external; 

    function updateSupply(address xToken, uint256 amount, address account, bool isDeposit) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function decimals() external view returns (uint8);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IInterestRateModel {

    function blocksPerYear() external view returns (uint256); 

    function isInterestRateModel() external returns(bool);

    function getBorrowRate(
        uint256 cash, 
        uint256 borrows, 
        uint256 reserves) external view returns (uint256);

    function getSupplyRate(
        uint256 cash, 
        uint256 borrows, 
        uint256 reserves, 
        uint256 reserveFactor) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function abs(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) {
            return b - a;
        }
        return a - b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}