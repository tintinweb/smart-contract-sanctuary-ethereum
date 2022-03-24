//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

interface CErc20 {
    function mint(uint256) external returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
    function supplyRatePerBlock() external returns (uint256);
    function redeem(uint) external returns (uint);
    function redeemUnderlying(uint) external returns (uint);
}

contract Gravity is KeeperCompatibleInterface {
    address payable owner;
    bool public onOff = true;                                   // manage toggle Keeper
    uint public immutable upKeepInterval;
    uint public lastTimeStamp;

    uint24 public constant poolFee = 3000;                      // pool fee set to 0.3%
    ISwapRouter public immutable swapRouter = 
    ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);    // UniswapV3
    uint public amountLent;                                     // DAI lent on Compound

    mapping (address => Account) public accounts;               // user address => user Account
    mapping (uint => PurchaseOrder[]) public purchaseOrders;
    mapping (address => bool) public sourceTokens;              // mapping for supported tokens
    mapping (address => bool) public targetTokens;              // mapping for supported tokens

    event NewStrategy(uint now, uint accountStart, address account);
    event PerformUpkeepSucceeded(uint now, uint lastTimeStamp, uint nextSlot, uint targetPurchased);
    event PerformUpkeepFailed(uint now, uint lastTimeStamp, uint nextSlot, uint toPurchase);
    event Deposited(uint timestamp, address from, uint256 sourceDeposited);
    event WithdrawnSource(uint timestamp, address to, uint256 sourceWithdrawn);
    event WithdrawnTarget(uint timestamp, address to, uint256 targetWithdrawn);
    event LentDAI(uint timestamp, uint256 exchangeRate, uint256 supplyRate);
    event RedeemedDAI(uint timestamp, uint256 redeemResult);

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
    }


    struct PurchaseOrder {
        address         user;
        uint            purchaseAmount;
    }


    constructor(address _sourceToken, address _targetToken, uint _upKeepInterval) {
        owner = payable(msg.sender);
        // keeper variables (in seconds)
        upKeepInterval = _upKeepInterval;
        lastTimeStamp = block.timestamp;
        sourceTokens[address(_sourceToken)] = true;
        targetTokens[address(_targetToken)] = true;
    }


    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin) internal returns (uint256 amountOut) {
        // approve router to spend tokenIn
        TransferHelper.safeApprove(_tokenIn, address(swapRouter), _amountIn);

        // naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum
        // set sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: _amountIn,
                amountOutMinimum: _amountOutMin,
                sqrtPriceLimitX96: 0
            });

        // execute the swap
        amountOut = swapRouter.exactInputSingle(params);
    }
    

    function lendCompound(address _tokenIn, uint256 _lendAmount) internal returns (uint) {
        // create a reference to the corresponding cToken contract, like cDAI
        CErc20 cToken = CErc20(0xF0d0EB522cfa50B716B3b1604C4F0fA6f04376AD);

        // amount of current exchange rate from cToken to underlying
        uint256 exchangeRate = cToken.exchangeRateCurrent();

        // amount added to you supply balance this block
        uint256 supplyRate = cToken.supplyRatePerBlock();

        // approve transfer on the ERC20 contract
        IERC20(_tokenIn).approve(0xF0d0EB522cfa50B716B3b1604C4F0fA6f04376AD, _lendAmount);
        amountLent += _lendAmount;

        // mint cTokens
        uint mintResult = cToken.mint(_lendAmount);
        emit LentDAI(block.timestamp, exchangeRate, supplyRate);
        return mintResult;
    }


    function redeemCompound(uint256 _redeemAmount) internal returns (bool) { 
        require(_redeemAmount <= amountLent, "Redemption amount exceeds lent amount");
        CErc20 cToken = CErc20(0xF0d0EB522cfa50B716B3b1604C4F0fA6f04376AD);
    
        // retrieve asset based on an amount of the asset
        uint256 redeemResult;
        amountLent -= _redeemAmount;

        // redeem underlying
        redeemResult = cToken.redeemUnderlying(_redeemAmount);
        emit RedeemedDAI(block.timestamp, redeemResult);
        return true;
    }

    // [accelerated demo version]
    function accumulatePurchaseOrders(uint _timestamp) public view returns (uint) {
        uint _total;
        for(uint i = 0; i < purchaseOrders[_timestamp].length; i++) {
            _total += purchaseOrders[_timestamp][i].purchaseAmount;
        }
        return _total;
    }

    // [accelerated demo version]
    function initiateNewStrategy(address _sourceAsset, address _targetAsset, uint _sourceBalance, uint _interval, uint _purchaseAmount) public {
        require(accounts[msg.sender].purchasesRemaining == 0, "Account has existing strategy");
        require(sourceTokens[_sourceAsset] == true, "Unsupported source asset type");
        require(targetTokens[_targetAsset] == true, "Unsupported target asset type");
        require(_sourceBalance > 0, "Insufficient deposit amount");
        require(_interval == 1 || _interval == 7 || _interval == 14 || _interval == 21 || _interval == 30, "Unsupported interval");
        
        uint _now = block.timestamp;
        uint _accountStart = _now - (_now % upKeepInterval) + upKeepInterval; // [V2 removed 2 *]
        uint _purchasesRemaining = _sourceBalance / _purchaseAmount;
        
        // handle remainder purchaseAmounts
        if((_sourceBalance % _purchaseAmount) > 0) {
            _purchasesRemaining += 1;
        }

        // naive target balance carry over if existing user initiates new strategy
        uint _targetBalance = 0;
        if(accounts[msg.sender].targetBalance > 0){
            _targetBalance += accounts[msg.sender].targetBalance;
        }

        accounts[msg.sender] = Account(_accountStart, 
                                       _sourceAsset, 
                                       _targetAsset, 
                                       _sourceBalance, 
                                       0, 
                                       _targetBalance, 
                                       _interval,
                                       _purchaseAmount,
                                       _purchasesRemaining
                                       );

        // populate purchaseOrders mapping
        uint _unixInterval = _interval * upKeepInterval;
        for(uint i = 0; i < _purchasesRemaining; i++) {
            uint _nextUnixPurchaseDate = _accountStart + (_unixInterval * i);
            if(accounts[msg.sender].sourceBalance >= accounts[msg.sender].purchaseAmount) {
                purchaseOrders[_nextUnixPurchaseDate].push(PurchaseOrder(msg.sender, _purchaseAmount));
                accounts[msg.sender].scheduledBalance += _purchaseAmount;
                accounts[msg.sender].sourceBalance -= _purchaseAmount;
            } else { // handles remainder purchase amount
                purchaseOrders[_nextUnixPurchaseDate].push(PurchaseOrder(msg.sender, accounts[msg.sender].sourceBalance));
                accounts[msg.sender].scheduledBalance += accounts[msg.sender].sourceBalance;
                accounts[msg.sender].sourceBalance -= accounts[msg.sender].sourceBalance;
            }
        }
        depositSource(_sourceAsset, _sourceBalance);
        // [LOCAL TESTING]
        lendCompound(_sourceAsset, _sourceBalance / 2);
        // [LOCAL TESTING]
        emit NewStrategy(_now, _accountStart, msg.sender);
    }

    // [accelerated demo version]
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        // [V2] get block.timestamp once
        uint _now = block.timestamp;
        // two condition validation
        if((_now - lastTimeStamp) >= upKeepInterval) { // [V2 >=]
            uint _nextSlot = _now - (_now % upKeepInterval) + upKeepInterval; // [V2 removed 2 *]
            uint _toPurchase = accumulatePurchaseOrders(_nextSlot);
            
            if(_toPurchase > 0) {
                upkeepNeeded = true;
            }
        }
    }

    // [accelerated demo version]
    function performUpkeep(bytes calldata /* performData */) external override {
        // [V2] get block.timestamp once
        uint _now = block.timestamp;
        // revalidate two conditions
        if((_now - lastTimeStamp) >= upKeepInterval) { // [V2 >=]
            uint _nextSlot = _now - (_now % upKeepInterval) + upKeepInterval; // [V2 removed 2 *]
            uint _toPurchase = accumulatePurchaseOrders(_nextSlot);
            lastTimeStamp = _now;
        
            if (_toPurchase > 0) {
                // compound redeem
                if(_toPurchase > IERC20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa).balanceOf(address(this))) {
                    redeemCompound(_toPurchase - IERC20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa).balanceOf(address(this)));
                }

                uint256 _targetPurchased = swap(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa, 
                                                0xd0A1E359811322d97991E03f863a0C30C2cF029C,
                                                _toPurchase,
                                                0);

                // update each account's scheduledBalance, targetBalance, and purchasesRemaining
                for(uint i = 0; i < purchaseOrders[_nextSlot].length; i++) {
                    accounts[purchaseOrders[_nextSlot][i].user].scheduledBalance -= purchaseOrders[_nextSlot][i].purchaseAmount;
                    accounts[purchaseOrders[_nextSlot][i].user].purchasesRemaining -= 1;
                    accounts[purchaseOrders[_nextSlot][i].user].targetBalance += purchaseOrders[_nextSlot][i].purchaseAmount * _targetPurchased / _toPurchase;
                    accounts[purchaseOrders[_nextSlot][i].user].accountStart = _nextSlot;
                }
                
                // delete purchaseOrder post swap
                delete purchaseOrders[_nextSlot];
                emit PerformUpkeepSucceeded(_now, lastTimeStamp, _nextSlot, _targetPurchased);
            } else {
                emit PerformUpkeepFailed(_now, lastTimeStamp, _nextSlot, _toPurchase);
            }
        }
    }

    // reconstruct accounts deployment schedule
    function reconstructSchedule(address _account) public view returns (uint256[] memory, uint256[] memory) {
        // get account data
        uint _accountStart = accounts[_account].accountStart;
        uint _interval = accounts[_account].interval;
        uint _purchasesRemaining = accounts[_account].purchasesRemaining;

        // create temporary arrays to be returned
        uint[] memory timestamps = new uint[](_purchasesRemaining);
        uint[] memory purchaseAmounts = new uint[](_purchasesRemaining);

        // reconstruct strategy's deployment schedule
        uint _unixInterval = _interval * upKeepInterval;
        for(uint i = 0; i < _purchasesRemaining; i++) {
            uint _nextUnixPurchaseDate = _accountStart + (_unixInterval * i);
            timestamps[i] = _nextUnixPurchaseDate;
            for(uint k = 0; k < purchaseOrders[timestamps[i]].length; k++){
                if(purchaseOrders[timestamps[i]][k].user == _account){
                    purchaseAmounts[i] = purchaseOrders[timestamps[i]][k].purchaseAmount;
                    k = purchaseOrders[timestamps[i]].length;
                }
            }
        }
        return(timestamps, purchaseAmounts);
    }

    // [initiateNewStrategy helper] does not handle depositing into existing strategies
    function depositSource(address _token, uint256 _amount) internal {
        require(sourceTokens[_token] == true, "Unsupported asset type");
        require(_amount > 0, "Insufficient value");
        (bool success) = IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        require(success, "Deposit unsuccessful");
        emit Deposited(block.timestamp, msg.sender, _amount);
    }

    // [withdrawSource helper] constant time delete function 
    function removePurchaseOrder(uint _timestamp, uint _purchaseOrderIndex) internal {
        require(purchaseOrders[_timestamp].length > _purchaseOrderIndex, "Purchase order index out of range");
        purchaseOrders[_timestamp][_purchaseOrderIndex] = purchaseOrders[_timestamp][purchaseOrders[_timestamp].length - 1];
        purchaseOrders[_timestamp].pop(); // implicit delete
    }

    // withdraw source token
    function withdrawSource(address _token, uint256 _amount) external {
        require(sourceTokens[_token] == true, "Unsupported asset type");
        require(accounts[msg.sender].scheduledBalance >= _amount, "Scheduled balance insufficient");
        (uint[] memory timestamps, uint[] memory purchaseAmounts) = reconstructSchedule(msg.sender);
        uint256 _accumulate;
        uint256 i = timestamps.length - 1;
        // remove purchase orders in reverse order, comparing withdrawal amount with purchaseAmount
        while(_amount > _accumulate) {
            for(uint k = 0; k < purchaseOrders[timestamps[i]].length; k++) {
                if(purchaseOrders[timestamps[i]][k].user == msg.sender) {
                    // case 1: amount equals (purchase amount + accumulated balance), PO is removed
                    if(purchaseOrders[timestamps[i]][k].purchaseAmount + _accumulate == _amount) {
                        _accumulate = _amount;
                        accounts[msg.sender].purchasesRemaining -= 1;
                        // remove PO from array
                        removePurchaseOrder(timestamps[i], k); 
                    // case 2: amount less than (purchase amount + accumulated balance), PO is reduced
                    } else if(purchaseOrders[timestamps[i]][k].purchaseAmount + _accumulate > _amount) {
                        // reduce purchase amount by difference
                        purchaseOrders[timestamps[i]][k].purchaseAmount -= (_amount - _accumulate);
                        _accumulate = _amount;
                    // case 3: amount exceeds (purchase amount + accumulated balance), PO is removed, continue accumulating
                    } else {
                        _accumulate += purchaseOrders[timestamps[i]][k].purchaseAmount;
                        accounts[msg.sender].purchasesRemaining -= 1;
                        // remove PO from array
                        removePurchaseOrder(timestamps[i], k);
                    }
                    k = purchaseOrders[timestamps[i]].length;
                }
            }
            if(i > 0) {
                i -= 1;
            }
        }

        // if treasury cannot cover, redeem

        // [LOCAL TESTING]
        if(_amount > IERC20(_token).balanceOf(address(this))){
           redeemCompound(_amount - IERC20(_token).balanceOf(address(this)));
        }
        // [LOCAL TESTING]

        accounts[msg.sender].scheduledBalance -= _amount;
        (bool success) = IERC20(_token).transfer(msg.sender, _amount);
        require(success, "Withdrawal unsuccessful");
        emit WithdrawnSource(block.timestamp, msg.sender, _amount);
    }

    // withdraw target token
    function withdrawTarget(address _token, uint256 _amount) external {
        require(targetTokens[_token] == true, "Unsupported asset type");
        require(accounts[msg.sender].targetBalance >= _amount);
        accounts[msg.sender].targetBalance -= _amount;
        (bool success) = IERC20(_token).transfer(msg.sender, _amount);
        require(success, "Withdrawal unsuccessful");
        emit WithdrawnTarget(block.timestamp, msg.sender, _amount);
    }
    
    // temporary demo function to extract tokens
    function withdrawERC20(address _token, uint256 _amount) onlyOwner external {
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "Insufficient balance");
        (bool success) = IERC20(_token).transfer(msg.sender, _amount);
        require(success, "Withdrawal unsuccessful");
    }

    // temporary demo function to extract ETH
    function withdrawETH() onlyOwner external {
        owner.transfer(address(this).balance);
    }

    // temporary demo function to manage Keeper
    function toggleOnOff(bool _onOff) onlyOwner external {
        require(msg.sender == owner, "Owner only");
        onOff = _onOff;
    }

    modifier onlyOwner () {
        require(msg.sender == owner, "Owner only");
        _;
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