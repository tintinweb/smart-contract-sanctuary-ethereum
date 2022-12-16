/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IQueryableErc20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address addr) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
     * by making the `nonReentrant` function external, and make it call a
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

/**
 * @title Represents a resource that requires initialization.
 */
contract CustomInitializable {
    bool private _wasInitialized;

    /**
     * @notice Throws if the resource was not initialized yet.
     */
    modifier ifInitialized () {
        require(_wasInitialized, "Not initialized yet");
        _;
    }

    /**
     * @notice Throws if the resource was initialized already.
     */
    modifier ifNotInitialized () {
        require(!_wasInitialized, "Already initialized");
        _;
    }

    /**
     * @notice Marks the resource as initialized.
     */
    function _initializationCompleted () internal ifNotInitialized {
        _wasInitialized = true;
    }
}

/**
 * @title Represents an ownable resource.
 */
contract CustomOwnable {
    // The current owner of this resource.
    address internal _owner;

    /**
     * @notice This event is triggered when the current owner transfers ownership of the contract.
     * @param previousOwner The previous owner
     * @param newOwner The new owner
     */
    event OnOwnershipTransferred (address previousOwner, address newOwner);

    /**
     * @notice This modifier indicates that the function can only be called by the owner.
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Only owner");
        _;
    }

    /**
     * @notice Transfers ownership to the address specified.
     * @param addr Specifies the address of the new owner.
     * @dev Throws if called by any account other than the owner.
     */
    function transferOwnership (address addr) external virtual onlyOwner {
        require(addr != address(0), "non-zero address required");
        emit OnOwnershipTransferred(_owner, addr);
        _owner = addr;
    }

    /**
     * @notice Gets the owner of this contract.
     * @return Returns the address of the owner.
     */
    function owner () external virtual view returns (address) {
        return _owner;
    }
}

/**
 * @title The interface of a fully compliant EIP20
 * @dev The interface is defined by https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
interface IERC20Strict is IQueryableErc20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
}

interface ITwapQuery {
  function getOrderMetrics () external view returns (uint256 pStartedOn, uint256 pDeadline, uint256 pSpent, uint256 pFilled, uint256 pTradeSize, uint256 pChunkSize, uint256 pPriceLimit, address srcToken, address dstToken, uint8 pState, bool pAlive);
}

interface IParaSwapAugustus {
  function getTokenTransferProxy() external view returns (address);
}

contract TwapOrder is ITwapQuery, CustomOwnable, CustomInitializable, ReentrancyGuard {    
    address private constant AUGUSTUS_SWAPPER_ADDR = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;

    uint8 private constant STATE_ACTIVE = 1;
    uint8 private constant STATE_FINISHED = 2;
    uint8 private constant STATE_CANCELLED = 3;

    uint256 internal _startedOn;
    uint256 internal _deadline;
    uint256 internal _spent;
    uint256 internal _filled;
    uint256 internal _tradeSize;
    uint256 internal _priceLimit;
    uint256 internal _chunkSize;
    address public sellingTokenAddress;
    address public buyingTokenAddress;
    address public traderAddress;
    address public depositorAddress;

    uint8 internal _currentState;
    bool internal _orderAlive;

    event OnTraderChanged (address newAddr);
    event OnDepositorChanged (address newAddr);
    event OnCompletion ();
    event OnCancel ();
    event OnClose ();
    event OnOpen ();
    event OnSwap (address fromToken, uint256 fromAmount, address toToken, uint256 toAmount);


    constructor () {
        _owner = msg.sender;
    }

    modifier onlyTrader() {
        require(traderAddress == msg.sender, "Only trader");
        _;
    }

    modifier onlyDepositor() {
        require(depositorAddress == msg.sender, "Only depositor");
        _;
    }

    modifier ifCanCloseOrder () {
        require(_orderAlive, "Current order is not live");
        require(
            (_currentState == STATE_FINISHED || _currentState == STATE_CANCELLED) || 
            (_currentState == STATE_ACTIVE && block.timestamp > _deadline) // solhint-disable-line not-rely-on-time
        , "Cannot close order yet");
        _;
    }

    function initialize (address traderAddr, address depositorAddr, IERC20Strict sellingToken, IERC20Strict buyingToken) external onlyOwner ifNotInitialized {
        require(address(sellingToken) != address(buyingToken), "Invalid pair");

        traderAddress = traderAddr;
        depositorAddress = depositorAddr;
        sellingTokenAddress = address(sellingToken);
        buyingTokenAddress = address(buyingToken);

        _initializationCompleted();
    }

    function switchTrader (address traderAddr) external onlyOwner ifInitialized {
        require(traderAddr != address(0), "Invalid trader");
        require(traderAddr != traderAddress, "Trader already set");
        require(!_orderAlive, "Current order still alive");

        traderAddress = traderAddr;
        emit OnTraderChanged(traderAddr);
    }

    function switchDepositor (address depositorAddr) external onlyOwner ifInitialized {
        require(depositorAddr != address(0), "Invalid depositor");
        require(depositorAddr != depositorAddress, "Depositor already set");
        require(!_orderAlive, "Current order still alive");

        depositorAddress = depositorAddr;
        emit OnDepositorChanged(depositorAddr);
    }

    function openOrder (uint256 durationInMins, uint256 targetQty, uint256 chunkSize, uint256 maxPriceLimit) external onlyDepositor ifInitialized {
        require(durationInMins >= 5, "Invalid duration");
        require(targetQty > 0, "Invalid trade size");
        require(chunkSize > 0, "Invalid chunk size");
        require(maxPriceLimit > 0, "Invalid price limit");
        require(!_orderAlive, "Current order still alive");

        _startedOn = block.timestamp; // solhint-disable-line not-rely-on-time
        _deadline = block.timestamp + (durationInMins * 1 minutes); // solhint-disable-line not-rely-on-time
        _tradeSize = targetQty;
        _chunkSize = chunkSize;
        _priceLimit = maxPriceLimit;
        _filled = 0;
        _spent = 0;
        _orderAlive = true;
        _currentState = STATE_ACTIVE;

        _approveProxy();
        emit OnOpen();
    }

    function deposit (uint256 depositAmount) external onlyDepositor ifInitialized {
        require(IERC20Strict(sellingTokenAddress).transferFrom(msg.sender, address(this), depositAmount), "Deposit failed");
    }

    function swap (uint256 sellQty, uint256 buyQty, bytes memory payload) external nonReentrant onlyTrader ifInitialized {
        require(_currentState == STATE_ACTIVE, "Invalid state");
        require(_deadline > block.timestamp, "Deadline expired"); // solhint-disable-line not-rely-on-time
        //require(sellQty <= _priceLimit, "Price limit reached");
 
        IERC20Strict sellingToken = IERC20Strict(sellingTokenAddress);
        uint256 sellingTokenBefore = sellingToken.balanceOf(address(this));
        require(sellingTokenBefore > 0, "Insufficient balance");

        IERC20Strict buyingToken = IERC20Strict(buyingTokenAddress);
        uint256 buyingTokenBefore = buyingToken.balanceOf(address(this));

        // Swap
        (bool success,) = AUGUSTUS_SWAPPER_ADDR.call(payload); // solhint-disable-line avoid-low-level-calls
        require(success, "Swap failed");

        uint256 sellingTokenAfter = sellingToken.balanceOf(address(this));
        uint256 buyingTokenAfter = buyingToken.balanceOf(address(this));
        require(buyingTokenAfter > buyingTokenBefore, "Invalid swap: Buy");
        require(sellingTokenBefore > sellingTokenAfter, "Invalid swap: Sell");

        // The number of tokens received after running the swap
        uint256 tokensReceived = buyingTokenAfter - buyingTokenBefore;
        require(tokensReceived >= buyQty, "Invalid amount received");
        _filled += tokensReceived;

        // The number of tokens sold during this swap
        uint256 tokensSold = sellingTokenBefore - sellingTokenAfter;
        require(tokensSold <= sellQty, "Invalid amount spent");
        _spent += tokensSold;

        emit OnSwap(sellingTokenAddress, tokensSold, buyingTokenAddress, tokensReceived);

        if (buyingTokenAfter >= _tradeSize) {
            _currentState = STATE_FINISHED;
            emit OnCompletion();
        }
    }

    function cancelOrder () external nonReentrant onlyDepositor ifInitialized {
        require(_currentState == STATE_ACTIVE, "Invalid state");

        _currentState = STATE_CANCELLED;
        emit OnCancel();

        _closeOrder();
    }

    function closeOrder () external nonReentrant onlyDepositor ifInitialized {
        _closeOrder();
    }

    function _closeOrder () private ifCanCloseOrder {
        _orderAlive = false;

        IERC20Strict sellingToken = IERC20Strict(sellingTokenAddress);
        IERC20Strict buyingToken = IERC20Strict(buyingTokenAddress);
        uint256 sellingTokenBalance = sellingToken.balanceOf(address(this));
        uint256 buyingTokenBalance = buyingToken.balanceOf(address(this));

        if (sellingTokenBalance > 0) require(sellingToken.transfer(depositorAddress, sellingTokenBalance), "Transfer failed: sell");
        if (buyingTokenBalance > 0) require(buyingToken.transfer(depositorAddress, buyingTokenBalance), "Transfer failed: buy");
        _revokeProxy();

        emit OnClose();
    }

    function _approveProxy () private {
        IERC20Strict token = IERC20Strict(sellingTokenAddress);
        address proxyAddr = IParaSwapAugustus(AUGUSTUS_SWAPPER_ADDR).getTokenTransferProxy();
        if (token.allowance(address(this), proxyAddr) != type(uint256).max) {
            require(token.approve(proxyAddr, type(uint256).max), "Token approval failed");
        }

        /*
        IERC20Strict token = IERC20Strict(sellingTokenAddress);
        uint256 currentBalance = token.balanceOf(address(this));
        address proxyAddr = IParaSwapAugustus(AUGUSTUS_SWAPPER_ADDR).getTokenTransferProxy();
        if (token.allowance(address(this), proxyAddr) < currentBalance) {
            require(token.approve(proxyAddr, currentBalance), "Token approval failed");
        }
        */
    }

    function _revokeProxy () private {
        IERC20Strict token = IERC20Strict(sellingTokenAddress);
        address proxyAddr = IParaSwapAugustus(AUGUSTUS_SWAPPER_ADDR).getTokenTransferProxy();
        if (token.allowance(address(this), proxyAddr) > 0) {
            require(token.approve(proxyAddr, 0), "Token approval failed");
        }
    }

    function getOrderMetrics () external view override returns (uint256 pStartedOn, uint256 pDeadline, uint256 pSpent, uint256 pFilled, uint256 pTradeSize, uint256 pChunkSize, uint256 pPriceLimit, address srcToken, address dstToken, uint8 pState, bool pAlive) {
        pDeadline = _deadline;
        pSpent = _spent;
        pFilled = _filled;
        pStartedOn = _startedOn;
        pTradeSize = _tradeSize;
        pChunkSize = _chunkSize;
        srcToken = sellingTokenAddress;
        dstToken = buyingTokenAddress;
        pState = _currentState;
        pAlive = _orderAlive;
        pPriceLimit = _priceLimit;
    }
}