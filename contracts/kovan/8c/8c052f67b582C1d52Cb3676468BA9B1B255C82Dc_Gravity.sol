//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);
  
  function swapExactTokensForTokens(
    //amount of tokens we are sending in
    uint256 amountIn,
    //the minimum amount of tokens we want out of the trade
    uint256 amountOutMin,
    //list of token addresses we are going to trade in.  this is necessary to calculate amounts
    address[] calldata path,
    //this is the address we are going to send the output tokens to
    address to,
    //the last time that the trade is valid for
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external returns (address);
}


contract Gravity is KeeperCompatibleInterface {
    address payable owner;
    bool public onOff = true;                                   // [testing] toggle Keeper on/off
    uint public immutable upKeepInterval;
    uint public lastTimeStamp;
    // uint public priorSlot;
    uint public nextSlot = 1;

    mapping (address => Account) public accounts;               // user address => user Account
    mapping (address => bool) public sourceTokens;              // mapping for supported tokens
    mapping (address => bool) public targetTokens;              // mapping for supported tokens
    mapping (uint => PurchaseOrder[]) public purchaseOrders;

    event NewStrategy(address);
    event PurchaseExecuted(uint256);                            // testing
    event PerformUpkeepFailed(uint256);                         // testing
    event Deposited(address, uint256);
    event Withdrawn(address, uint256);

    struct Account {
        uint            accountStart;
        address         sourceAsset;
        address         targetAsset;
        uint            sourceBalance;
        uint            scheduledBalance;
        uint            targetBalance;
        uint            interval;                               // 1, 7, 14, 21, 30
        uint            purchaseAmount;                         // purchase amount per interval of sourceBalance
        uint            purchasesRemaining;
        bool            withdrawFlag;
    }

    struct PurchaseOrder {
        address user;
        uint    purchaseAmount;
    }    

    constructor(address _sourceToken, address _targetToken, uint _upKeepInterval) {
        owner = payable(msg.sender);
        // keeper variables
        upKeepInterval = _upKeepInterval; // in seconds
        lastTimeStamp = block.timestamp;

        // for testing
        sourceTokens[address(_sourceToken)] = true; // TestToken (testing only)
        targetTokens[address(_targetToken)] = true;

        // interchanged target and Source to test withdrawals
        targetTokens[address(_sourceToken)] = true; 
        sourceTokens[address(_targetToken)] = true;

        // load asset Kovan addresses into tokenAddress mapping
        // sourceTokens[address(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa)] = true; // DAI
        // sourceTokens[address(0xd0A1E359811322d97991E03f863a0C30C2cF029C)] = true; // WETH
        // sourceTokens[address(0xa36085F69e2889c224210F603D836748e7dC0088)] = true; // LINK
    }

    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;

    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address _to) internal {
      
      // transfer the amount in tokens from the msg.sender to this contract
      // this contract will have the amount of in tokens
      // IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      
      //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
      //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract 
      IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);

      //path is an array of addresses.
      //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
      //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
      address[] memory path;
      if (_tokenIn == WETH || _tokenOut == WETH) {
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
      } else {
        path = new address[](3);
        path[0] = _tokenIn;
        path[1] = WETH;
        path[2] = _tokenOut;
      }
          //then we will call swapExactTokensForTokens
          //for the deadline we will pass in block.timestamp
          //the deadline is the latest time the trade is valid for
          IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp);
  }
    
      //this function will return the minimum amount from a swap
      //input the 3 parameters below and it will return the minimum amount out
      //this is needed for the swap function above
    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256) {

      //path is an array of addresses.
      //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
      //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }
        
        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER).getAmountsOut(_amountIn, path);
        return amountOutMins[path.length -1];  
    }  

    // [test_timestamp] accumulatePurchaseOrders
    function accumulatePurchaseOrders(uint _timestamp) public view returns (uint) {
        uint _total;
        for(uint i = 0; i < purchaseOrders[_timestamp].length; i++) {
            _total += purchaseOrders[_timestamp][i].purchaseAmount;
        }
        return _total;
    }

    // [production] initiateNewStrategy
    // function initiateNewStrategy(address _sourceAsset, address _targetAsset, uint _sourceBalance, uint _interval, uint _purchaseAmount) public {
    //     require(sourceTokens[_sourceAsset] == true, "Unsupported source asset type");
    //     require(targetTokens[_targetAsset] == true, "Unsupported target asset type");
    //     require(_sourceBalance > 0, "Insufficient deposit amount");
    //     require(_interval == 1 || _interval == 7 || _interval == 14 || _interval == 21 || _interval == 30, "Unsupported interval");
    //     uint _accountStart = block.timestamp;
    //     uint _purchasesRemaining = _sourceBalance / _purchaseAmount;
    //     accounts[msg.sender] = Account(_accountStart, 
    //                                    _sourceAsset, 
    //                                    _targetAsset, 
    //                                    _sourceBalance, 
    //                                    0, 
    //                                    0, 
    //                                    _interval, 
    //                                    _purchaseAmount, 
    //                                    _purchasesRemaining);

    //     // populate purchaseOrders mapping
    //     uint _unixNoonToday = _accountStart - (_accountStart % 86400) + 86400 + 43200;
    //     uint _unixInterval = _interval * 86400;
    //     for(uint i = 1; i <= _purchasesRemaining; i++) {
    //         uint _nextUnixPurchaseDate = _unixNoonToday + (_unixInterval * i);
    //         purchaseOrders[_nextUnixPurchaseDate].push(PurchaseOrder(msg.sender, _purchaseAmount));
    //     }

    //     // transfer user balance to contract
    //     (bool success) = IERC20(_sourceAsset).transferFrom(msg.sender, address(this), _sourceBalance);
    //     require(success, "Initiate new strategy unsuccessful");
    //     emit NewStrategy(msg.sender);
    // }

    // [test_timestamp] initiateNewStrategy
    function initiateNewStrategy(address _sourceAsset, address _targetAsset, uint _sourceBalance, uint _interval, uint _purchaseAmount) public {
        require(sourceTokens[_sourceAsset] == true, "Unsupported source asset type");
        require(targetTokens[_targetAsset] == true, "Unsupported target asset type");
        require(_sourceBalance > 0, "Insufficient deposit amount");
        require(_interval == 1 || _interval == 7 || _interval == 14 || _interval == 21 || _interval == 30, "Unsupported interval");
        uint _accountStart = block.timestamp;
        uint _purchasesRemaining = _sourceBalance / _purchaseAmount;
        accounts[msg.sender] = Account(_accountStart, 
                                       _sourceAsset, 
                                       _targetAsset, 
                                       _sourceBalance, 
                                       0, 
                                       0, 
                                       _interval,
                                       _purchaseAmount,
                                       _purchasesRemaining,
                                       false);

        // populate purchaseOrders mapping
        uint _unixNextTwoMinSlot = _accountStart - (_accountStart % 120) + 240;
        uint _unixInterval = _interval * 120;
        for(uint i = 1; i <= _purchasesRemaining; i++) {
            uint _nextUnixPurchaseDate = _unixNextTwoMinSlot + (_unixInterval * i);
            // TO DO: add check on sufficient sourceBalance, (sourceBalance - scheduledBalance) > purchaseAmount
            // else, deployment remaining amount (i.e., handle non-even deposits)
            purchaseOrders[_nextUnixPurchaseDate].push(PurchaseOrder(msg.sender, _purchaseAmount));
            accounts[msg.sender].scheduledBalance += _purchaseAmount;
            accounts[msg.sender].sourceBalance -= _purchaseAmount;
        }

        // Call depositSource to move account holders sourcebalance to Gravity contract
        depositSource(_sourceAsset, _sourceBalance);
        emit NewStrategy(msg.sender);
    }

    /*
    * - - - - - - - - - - - - keeper integration [start] - - - - - - - - - - - - 
    */

    // [production] checkUpkeep
    // function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
    //     require(onOff == true, "Keeper checkUpkeep is off");
    //     uint _now = block.timestamp;
    //     uint _unixNoonToday = _now - (_now % 86400) + 43200;
    //     // if timestamp > noon
    //     if(block.timestamp > _unixNoonToday) {
    //         // if total PO > 0
    //         uint _total = accumulatePurchaseOrders();
    //         if(_total > 0) {
    //             upkeepNeeded = true;
    //         }
    //     }
    // }

    // [test_timestamp] checkUpkeep
    function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
        require(onOff == true, "Keeper checkUpkeep is off");
        if((block.timestamp - lastTimeStamp) > upKeepInterval) {
            uint256 _now = block.timestamp;
            uint256 _nextSlot = _now - (_now % 120) + 240;
            // condition to prevent replay
            // if(_nextSlot > priorSlot) {
            uint _total = accumulatePurchaseOrders(_nextSlot);
            if(_total > 0) {
                upkeepNeeded = true;
            //}
            }
        }
    }

    // [test_timestamp] performUpkeep
    function performUpkeep(bytes calldata /* performData */) external override {
        //revalidate the upkeep in the performUpkeep function
        require(onOff == true, "Keeper checkUpkeep is off");
        uint256 _now = block.timestamp;
        nextSlot = _now - (_now % 120) + 240;
        uint256 _total = accumulatePurchaseOrders(nextSlot);
        lastTimeStamp = block.timestamp;
        if (_total > 0) {
            //priorSlot = nextSlot; // replay prevention
            /*
            * - - - - - - - - - - - - swap integration [start] - - - - - - - - - - - - 
            */

            swap(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa, 
                 0xd0A1E359811322d97991E03f863a0C30C2cF029C,
                 _total,
                 0,
                 address(this));

            /*
            * - - - - - - - - - - - - swap integration [end] - - - - - - - - - - - - 
            */
            emit PurchaseExecuted(nextSlot);
        } else {
            emit PerformUpkeepFailed(block.timestamp);
        }
    }

    /*
    *  - - - - - - - - - - - - keeper integration [end] - - - - - - - - - - - - 
    */
    
    // reconstruct deployment schedule of account's strategy, returns associated timestamps and purchase amounts
    // naive implementation (works for un-executed strategies)
    function reconstructSchedule(address _account) public view returns (uint256[] memory, uint256[] memory) {
        // get account data
        uint _accountStart = accounts[_account].accountStart;
        uint _scheduledBalance = accounts[_account].scheduledBalance;
        uint _interval = accounts[_account].interval;
        uint _purchasesRemaining = accounts[_account].purchasesRemaining;
        uint _purchaseAmount = accounts[_account].purchaseAmount;

        // create temporary arrays to be returned
        uint[] memory timestamps = new uint[](_purchasesRemaining);
        uint[] memory purchaseAmounts = new uint[](_purchasesRemaining);

        // reconstruct strategy's deployment schedule
        uint _unixNextTwoMinSlot = _accountStart - (_accountStart % 120) + 240;
        uint _unixInterval = _interval * 120;
        for(uint i = 1; i <= _purchasesRemaining; i++) {
            uint _nextUnixPurchaseDate = _unixNextTwoMinSlot + (_unixInterval * i);
            timestamps[i - 1] = _nextUnixPurchaseDate;
            purchaseAmounts[i - 1] = (_scheduledBalance / _purchasesRemaining);
        }
        return(timestamps, purchaseAmounts);
    }

    // TO DO: Aave deposit stablecoins
    // TO DO: update to handle depositing into existing strategy
    // deposit into existing strategy (basic implementation for single source; would updating strategy)
    function depositSource(address _token, uint256 _amount) internal {
        //require(sourceTokens[_token] == true, "Unsupported asset type");
        require(_amount > 0, "Insufficient value");
        (bool success) = IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        require(success, "Deposit unsuccessful: transferFrom");
        emit Deposited(msg.sender, _amount);
    }

    // TO DO: update to handle withdrawing from existing strategy
    function withdrawSource(address _token, uint256 _amount) external {
        //require(sourceTokens[_token] == true, "Unsupported asset type");
        require(accounts[msg.sender].sourceBalance >= _amount);
        accounts[msg.sender].sourceBalance -= _amount;
        (bool success) = IERC20(_token).transfer(msg.sender, _amount);
        require(success, "Withdraw unsuccessful");
        emit Withdrawn(msg.sender, _amount);
    }

    // [testing] temporary function to extract tokens
    function empty() public {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }

    // [testing] temporary function to control upkeep
    function toggleOnOff(bool _onOff) external {
        require(msg.sender == owner, "Owner only");
        onOff = _onOff;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

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