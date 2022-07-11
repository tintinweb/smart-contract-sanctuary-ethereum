//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

/**
 * @notice Implementation of the Gravity Strategy Factory contract. Handles pair account, 
 * strategy initiation, strategy topping up, keeper automation, swapping, and target
 * withdrawal.
 */
contract StrategyFactory is Ownable {
    /// @notice [TESTING]
    bool public localTesting = true;
    uint public purchaseSlot;
    uint public lastTimeStamp;
    uint public immutable upKeepInterval;
    uint public fee;
    uint public slippageFactor = 99;
    uint public minPurchaseAmount = 100e18;
    
    /// @notice Ensures all swaps are executed if necessary before incrementing purchase slot and lastTimeStamp
    uint public swapIndex = 1;
    
    /// @notice Tracks first swap timestamp of purchase slot to maintain daily swap cadence
    uint public firstTimeStamp;
    
    /// @notice Pool fee set to 0.3%
    uint24 public constant poolFee = 3000;                      
    ISwapRouter public immutable swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    /// @notice Oracle pricefeed
    AggregatorV3Interface internal priceFeed;

    /**
    * @notice Mapping of each user's live strategy for each respective asset 
    * ( user address => ( strategy pairId => strategy configuration ) )
    */ 
    mapping (address => mapping (uint => Strategy)) public accounts;
    
    /**
    * @notice Mapping for each purchase slot's purchase order array
    * ( day's purchase slot => (pairId => array of purchase orders ) )
    */     
    mapping (uint => mapping(uint => PurchaseOrder[])) public purchaseOrders;

    /**
    * @notice Forward mapping for a pair's addresses to id
    * ( fromToken address => ( toToken address => pair id )
    */     
    mapping (address => mapping (address => uint)) public pairs;

    /**
    * @notice Reverse index array for all pairs
    * Pairs[ pairId ] = Pair( fromToken, toToken )
    */   
    Pair[] public reversePairs;

    /**
    * @notice Treasury mapping for each respective asset 
    * ( source asset address => accumulated treasury )
    */ 
    mapping (address => uint) public treasury;

    /**
    * @notice Oracle price fee mapping for each asset 
    * (ERC20 token address => oracle price feed address)
    */ 
    mapping (address => address) public priceFeeds;

    /// @notice Used for slotting a user's future purchase orders
    struct PurchaseOrder {
        address         user;
        uint            amount;
        uint            pairId;
    }

    /// @notice Used for tracking a user's DCA strategy for pair
    struct Strategy {
        uint            nextSlot;
        uint            targetBalance;
        uint            interval;
        uint            purchaseAmount;
        uint            purchasesRemaining;
    }

    /// @notice Used for specifying unique asset pairs and routing paths
    struct Pair {
        address         fromToken;
        address         toToken;
        bytes           path;
    }

    event StrategyInitiated(address account, uint nextPurchaseSlot);
    event StrategyToppedUp(address account, uint topUpPurchaseSlot);
    event Deposited(uint timestamp, address from, uint sourceDeposited);
    event Withdrawal(address account, uint amount);

    /// @notice Set Keepers upkeep interval, last timestamp, 1-base pairId (avoid default mapping value)
    constructor(uint _upKeepInterval) {
        upKeepInterval = _upKeepInterval;
        lastTimeStamp = block.timestamp;
        reversePairs.push(Pair(address(0), address(0), ""));
    }

    /**
     * @notice 'accounts' nested mapping getter
     * @param user Address of user account
     * @param pairId Strategy pairId of the source and target assets
     * @return Strategy struct mapped from user's address and strategy pairId
     */
    function getStrategyDetails(address user, uint pairId) public view returns (Strategy memory) {
        return accounts[user][pairId];
    }

    /**
     * @notice 'purchaseOrders' mapping getter
     * @param slot Purchase slot for which details are being sought
     * @param pairId The pairId for which details are being sought
     * @return PurchaseOrder Array containing all purchase orders of the passed purchase slot
     */
    function getPurchaseOrderDetails(uint slot, uint pairId) public view returns (PurchaseOrder[] memory) {
        return purchaseOrders[slot][pairId];
    }

    /**
     * @notice Sums a purchase slot's purchase order for each asset and returns results in an array
     * @param slot The purchase slot accumulated purchase amounts are being sought for
     * @param pairId The pairId accumulated purchase amounts are being sought for
     */
    function accumulatePurchaseOrders(uint slot, uint pairId) public view returns (uint) {
        uint _total;
        for(uint i = 0; i < purchaseOrders[slot][pairId].length; i++) {
            _total += purchaseOrders[slot][pairId][i].amount;
        }
        return _total;
    }
    /**
     * @notice Initiates new dollar cost strategy based on user's configuration
     * @param sourceAsset Deposited asset the user's strategy will use to fund future purchases
     * @param targetAsset Asset the user's strategy will be purchasing
     * @param sourceBalance Deposit amount of the source asset
     * @param interval Defines daily cadence of target asset purchases
     * @param purchaseAmount Defines amount to be purchased at each interval
     * note: Population of the purchaseOrders mapping uses 1-based indexing to initialize 
     * strategy at first interval.
     */
    function initiateNewStrategy(address sourceAsset, address targetAsset, uint sourceBalance, uint interval, uint purchaseAmount) public {
        uint _pairId = pairs[sourceAsset][targetAsset];
        require(_pairId > 0, "Pair does not exist");
        require(accounts[msg.sender][_pairId].purchasesRemaining == 0, "Existing strategy");
        require(interval == 1 || interval == 7 || interval == 14 || interval == 21 || interval == 30, "Unsupported interval");
        depositSource(sourceAsset, sourceBalance);

        // [TESTING]
        if(!localTesting) {
            int sourceUSD = getLatestPrice(sourceAsset);
            uint purchaseAmountUSD = uint(sourceUSD) * purchaseAmount / 1e8;
            require(purchaseAmountUSD >= minPurchaseAmount, "Purchase amount below minimum");
        }

        // Incur fee
        uint _balance = sourceBalance;
        if(fee > 0) {
            _balance = incurFee(sourceAsset, sourceBalance);
        }

        // Calculate purchases remaining and account for remainder purchase amounts
        uint _purchasesRemaining = _balance / purchaseAmount;
        uint _remainder;
        if((_balance % purchaseAmount) > 0) {
            _remainder = _balance - (_purchasesRemaining * purchaseAmount);
            _purchasesRemaining += 1;
        }

        // Target balance carries over if existing user initiates new strategy
        uint _targetBalance = 0;
        if(accounts[msg.sender][_pairId].targetBalance > 0){
            _targetBalance += accounts[msg.sender][_pairId].targetBalance;
        }

        accounts[msg.sender][_pairId] = Strategy(purchaseSlot + interval,
                                                 0,
                                                 interval,
                                                 purchaseAmount,
                                                 _purchasesRemaining
                                                 );

        // Populate purchaseOrders mapping
        uint _currentSlot = purchaseSlot;
        for(uint i = 1; i <= _purchasesRemaining; i++) {
            uint _purchaseSlot = _currentSlot + (interval * i);
            if(_purchasesRemaining == i && _remainder > 0) {
                purchaseOrders[_purchaseSlot][_pairId].push(PurchaseOrder(msg.sender, _remainder, _pairId));
            } else {
                purchaseOrders[_purchaseSlot][_pairId].push(PurchaseOrder(msg.sender, purchaseAmount, _pairId));
            }
        }
        emit StrategyInitiated(msg.sender, purchaseSlot + interval);
    }

    /**
     * @notice Tops up users existing strategy with additional units of the source asset
     * @param sourceAsset Deposited asset the user's strategy will use to fund future purchases
     * @param targetAsset Asset the user's strategy will be purchasing
     * @param topUpAmount Defines amount to be purchased at each interval
     * note:
     * - Population of the purchaseOrders mapping uses 0-based indexing to top up an existing
     *   strategy starting at the _slotOffset
     * - Function first checks for a purchaseAmount shortfall in the last purchase slot of the 
     *   user's existing strategy and if one exists, it fills that purchase slot and updates the 
     *   topUpAmount accordingly
     */
    function topUpStrategy(address sourceAsset, address targetAsset, uint topUpAmount) public payable {
        uint _pairId = pairs[sourceAsset][targetAsset];
        require(_pairId > 0, "Pair does not exist");
        require(accounts[msg.sender][_pairId].purchasesRemaining > 0, "No existing strategy for pair");
        depositSource(sourceAsset, topUpAmount);

        Strategy storage strategy = accounts[msg.sender][_pairId];
        uint _purchaseAmount = strategy.purchaseAmount;
        // [TESTING]
        if(!localTesting) {
            int sourceUSD = getLatestPrice(sourceAsset);
            uint purchaseAmountUSD = uint(sourceUSD) * _purchaseAmount / 1e8;
            require(purchaseAmountUSD >= minPurchaseAmount, "Purchase amount below minimum");
        }

        // Incur fee
        uint _balance = topUpAmount;
        if(fee > 0) {
            _balance = incurFee(sourceAsset, topUpAmount);
        }

        // Calculate offset starting point for top up purchases and ending point for existing purchase shortfalls
        uint _slotOffset = strategy.nextSlot + (strategy.purchasesRemaining * strategy.interval);
        uint _strategyLastSlot = _slotOffset - strategy.interval;

        // If remainder 'shortfall' below purchaseAmount on final purchase slot of existing strategy, fill
        for(uint i = 0; i < purchaseOrders[_strategyLastSlot][_pairId].length; i++) {
            if(purchaseOrders[_strategyLastSlot][_pairId][i].user == msg.sender) {
                if(purchaseOrders[_strategyLastSlot][_pairId][i].pairId == _pairId) {
                    uint _amountLastSlot = purchaseOrders[_strategyLastSlot][_pairId][i].amount;
                    if(_amountLastSlot < _purchaseAmount) {
                        if(_balance > (_purchaseAmount - _amountLastSlot)) {
                            _balance -= (_purchaseAmount - _amountLastSlot);
                            purchaseOrders[_strategyLastSlot][_pairId][i].amount = _purchaseAmount;
                        } else if (_balance < (_purchaseAmount - _amountLastSlot)) {
                            purchaseOrders[_strategyLastSlot][_pairId][i].amount += _balance;
                            _balance = 0;
                        } else {
                            purchaseOrders[_strategyLastSlot][_pairId][i].amount = _purchaseAmount;
                            _balance = 0;
                        }
                    }
                    break; // Break once strategy is found
                }
            }
        }

        uint _topUpPurchasesRemaining = _balance / _purchaseAmount;
        uint _remainder;
        if((_balance % _purchaseAmount > 0) && (_topUpPurchasesRemaining > 0)) {
            _remainder = _balance - (_topUpPurchasesRemaining * _purchaseAmount);
            _topUpPurchasesRemaining += 1;
        }

        uint _purchaseSlot = _slotOffset;
        for(uint i = 0; i < _topUpPurchasesRemaining; i++) {
            _purchaseSlot = _slotOffset + (strategy.interval * i);
            if((_topUpPurchasesRemaining - 1) == i && _remainder > 0) {
                purchaseOrders[_purchaseSlot][_pairId].push(PurchaseOrder(msg.sender, _remainder, _pairId));
            } else {
                purchaseOrders[_purchaseSlot][_pairId].push(PurchaseOrder(msg.sender, _purchaseAmount, _pairId));
            }
        }
        strategy.purchasesRemaining += _topUpPurchasesRemaining;
        emit StrategyToppedUp(msg.sender, _balance);
    }

    /**
     * @notice Sums a purchase slot's purchase order for each asset and returns results in an array
     * @param token address of ERC20 token to be deposited into contract
     * @param amount amount of ERC20 token to be deposited into contract
     */
    function depositSource(address token, uint256 amount) internal {
        (bool success) = IERC20(token).transferFrom(msg.sender, address(this), amount);
        require(success, "Deposit unsuccessful");
        emit Deposited(block.timestamp, msg.sender, amount);
    }

    /**
     * @notice Allows users to withdrawal target asset
     * @param pairId pairId of the strategy user is withdrawing the target asset from
     * @param amount Amount of the target asset the user is withdrawing
     * note:
     * - deletes stored strategy details if user withdraws full target balance
     */
    function withdrawTarget(uint pairId, uint amount) external {
        uint _balance = accounts[msg.sender][pairId].targetBalance;
        require(_balance >= amount, "Amount exceeds balance");
        accounts[msg.sender][pairId].targetBalance -= amount;
        (bool success) = IERC20(reversePairs[pairId].toToken).transfer(msg.sender, amount);
        require(success, "Withdrawal unsuccessful");
        if(_balance == amount) {
            delete accounts[msg.sender][pairId];
        }
        emit Withdrawal(msg.sender, amount);
    }

   /**
     * @notice Enables new strategy pairing
     * @param fromToken Token that funds _toToken purchase
     * @param toToken Token that gets purchased with _fromToken
     */
    function setPair(address fromToken, address toToken) external onlyOwner {
        require(pairs[fromToken][toToken] == 0, "Pair exists");
        uint _pairId = reversePairs.length;
        pairs[fromToken][toToken] = _pairId;
        reversePairs.push(Pair(fromToken, toToken, ""));
    }

    /**
     * @notice 'pairId' getter
     * @param fromToken Token address that funds _toToken purchase
     * @param toToken Token address that gets purchased with _fromToken
     */
    function getPairId(address fromToken, address toToken) public view returns (uint) {
        return pairs[fromToken][toToken];
    }

    /**
     * @notice Pair's addresses getter
     * @param pairId pairId of the pair's addresses being sought
     * @return fromToken and toToken addresses tuple associated with the passed pairId
     */
    function getPairAddresses(uint pairId) public view returns (address, address) {
        return(reversePairs[pairId].fromToken, reversePairs[pairId].toToken);
    }

    /**
     * @notice Handles removable of existing pair
     * note:
     * - Should only be executed if no live strategies exist for either pair
     * - Deletes pair from 'pairs' mapping
     * - Swaps last pair in 'reversePairs' into index of pair being removed
     * - Points 'pairs' mapping for last pair to new pairId
     * @param fromToken Source token address of pair being removed
     * @param toToken Target token address of pair being removed
     */
    function removePair(address fromToken, address toToken) external onlyOwner {
        require(pairs[fromToken][toToken] > 0, "Pair does not exist");
        uint _pairId = pairs[fromToken][toToken];
        delete pairs[fromToken][toToken];
        uint _lastPairIdx = reversePairs.length - 1;
        reversePairs[_pairId] = reversePairs[_lastPairIdx];
        reversePairs.pop();
        (address _from, address _to) = getPairAddresses(_pairId);
        pairs[_from][_to] = _pairId;
    }

    /**
     * @notice Sets pair pool path for V3 swapping [TESTING]
     * NOTE in production would be only owner
     */
    function setPath(uint24 pairId, uint24 params,
                     address assetA, uint24 fee1, 
                     address assetB, uint24 fee2, 
                     address assetC, uint24 fee3, 
                     address assetD)
                     external onlyOwner {
        if(params == 3) {
            reversePairs[pairId].path = abi.encodePacked(assetA, fee1, assetB);
        } else if(params == 5) {
            reversePairs[pairId].path = abi.encodePacked(assetA, fee1, assetB, fee2, assetC);
        } else if (params == 7) {
            reversePairs[pairId].path = abi.encodePacked(assetA, fee1, assetB, fee2, assetC, fee3, assetD);
        }
    }

     /**
     * @notice Get pair pool path
     * @param pairId pairId of pair path being sought
     * @return Path
     */
    function getPath(uint pairId) public view returns (bytes memory) {
        return reversePairs[pairId].path;
    }

    /**
     * @notice Allows owner to set protocol fee
     * @param _fee Fee value in decimal representation of percent, 0.XX * 10e18
     */
    function setFee(uint _fee) external onlyOwner {
        fee = _fee;
    }

    /**
     * @notice Incurs fee on balance
     * @param balance Balance on which a fee is to be incurred
     * @return The passed balance less the fee incurred
     */
    function incurFee(address sourceAsset, uint balance) internal returns (uint) {
        uint _feeIncurred = balance * fee / 100e18;
        treasury[sourceAsset] += _feeIncurred;
        return balance - _feeIncurred;
    }

    /**
     * @notice Allows owner to set price feed addresses for each token
     * @param token Address of token price feed is being set for
     * @param feed Address of price feed for token
     */
    function setPriceFeed(address token, address feed) external onlyOwner {
        priceFeeds[token] = feed;
    }

    /**
     * @notice Price fee getter
     * @param token Address of token price feed address is being sought for
     * @return Price feed address for token
     */
    function getPriceFeed(address token) public view returns (address) {
        return priceFeeds[token];
    }

    /**
     * @notice Max slippage setter
     * @param _slippageFactor New slippage factor value
     */
    function setSlippageFactor(uint _slippageFactor) external onlyOwner {
         slippageFactor = _slippageFactor;
    }

    /**
     * @notice Min purchase amount setter
     * @param _minPurchaseAmount New min purchase amount value
     */
    function setMinPurchaseAmount(uint _minPurchaseAmount) external onlyOwner {
         minPurchaseAmount = _minPurchaseAmount;
    }

    /**
     * @notice Treasury mapping getter by source asset
     * @return Treasury balance of source asset
     */
    function getTreasury(address sourceAsset) public view returns (uint) {
        return treasury[sourceAsset];
    }

    /////////////////////////////////////////////////////
    ////////////////////// TESTING //////////////////////
    ///////// PLACEHOLDER KEEPERS & SWAP FUNCTIONS //////

    /**
     * NOTE: [TESTING visibility needs to be changed to INTERNAL post
     */
    function swap(uint pairId, address tokenIn, address tokenOut, uint256 amountIn) public returns (uint256 amountOut) {
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);
        int _tokenInPrice = getLatestPrice(tokenIn);
        int _tokenOutPrice = getLatestPrice(tokenOut);
        uint amountOutMin = ((amountIn * uint(_tokenInPrice)) / uint(_tokenOutPrice) * slippageFactor) / 100;

        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: reversePairs[pairId].path,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin
            });
        amountOut = swapRouter.exactInput(params);
    }

    /**
     * @notice Chainlink oracle price feed
     * @return the latest price and decimal for the passed token address
     */
    function getLatestPrice(address token) public view returns (int) {
        address _token = priceFeeds[token];
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(_token).latestRoundData();
        require(timeStamp > 0, "Round not complete");
        return price;
    }

    /// @notice [TESTING] placeholder oracle prices for local swap testing
    uint[] public AssetPrices = [0, 2000, 30000, 1]; // null, ETH, BTC, MATIC


    /// @notice [TESTING] checkUpkeep keeper integration placeholder function for testing purposes
    function checkUpkeepTEST(uint _pairId /* bytes calldata checkData */) external  {
        if((block.timestamp - lastTimeStamp) > upKeepInterval){
            uint _purchaseAmount = accumulatePurchaseOrders(purchaseSlot, _pairId);
            performUpkeepTEST(_pairId, _purchaseAmount);

            ///////////////// REGISTERED UPKEEP /////////////////
            // returns (bool upkeepNeeded, bytes memory performData)
            // upkeepNeeded = true;
            // uint _pairId = abi.decode(checkData, (uint));
            // performData = abi.encode(_pairId, purchaseAmount);
            // return (upkeepNeeded, performData);
            /////////////////////////////////////////////////////
        }
    }

    /// @notice [TESTING] performUpkeep keeper integration placeholder function for testing purposes
    function performUpkeepTEST(uint _pairId, uint _purchaseAmount) internal {
        if ((block.timestamp - lastTimeStamp) > upKeepInterval) {
            if(swapIndex == 1) {
                firstTimeStamp = block.timestamp;
            }
            uint _purchaseAmountCheck = accumulatePurchaseOrders(purchaseSlot, _pairId);
            require(_purchaseAmountCheck == _purchaseAmount, "Purchase amount invalid");
            ///////////////// REGISTERED UPKEEP /////////////////
            // (uint _pairId, uint purchaseAmount) = abi.decode(performData, (uint, uint));
            /////////////////////////////////////////////////////
            uint _purchased;
            if(_purchaseAmount > 0) {

                /////////////////////////////////////////////////////
                ////////////////////// TESTING //////////////////////
                if(localTesting) {
                    // [SIMULATED LOCAL SWAP]
                   _purchased += _purchaseAmount / AssetPrices[_pairId];
                } else {
                    // [FORKED MAINNET SWAP]
                    _purchased = swap(_pairId,
                                      reversePairs[_pairId].fromToken,
                                      reversePairs[_pairId].toToken,
                                      _purchaseAmount);
                }
                ////////////////////// TESTING //////////////////////
                /////////////////////////////////////////////////////                    
            
                uint _purchaseSlot = purchaseSlot;
                for(uint i = 0; i < purchaseOrders[_purchaseSlot][_pairId].length; i++) {
                    address _user = purchaseOrders[_purchaseSlot][_pairId][i].user;
                    accounts[_user][_pairId].purchasesRemaining -= 1;
                    accounts[_user][_pairId].targetBalance += purchaseOrders[_purchaseSlot][_pairId][i].amount * 
                                                              _purchased / 
                                                              _purchaseAmount;
                    accounts[_user][_pairId].nextSlot = purchaseSlot + accounts[_user][_pairId].interval;
                    if(accounts[_user][_pairId].purchasesRemaining == 0) {
                        accounts[_user][_pairId].interval = 0;
                    }
                }
            }
            swapIndex++;
            delete purchaseOrders[purchaseSlot][_pairId];
            if(swapIndex == reversePairs.length) {
                lastTimeStamp = firstTimeStamp;
                swapIndex = 1;
                purchaseSlot++;
            }
        }
    }

    ///////// PLACEHOLDER KEEPERS & SWAP FUNCTIONS //////
    ////////////////////// TESTING //////////////////////
    /////////////////////////////////////////////////////

    receive() payable external {}

    /**
    * Built in the depths of the bear market of 2022. Keep building friends.
    */
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
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
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
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}