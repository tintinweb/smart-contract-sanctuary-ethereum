//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

contract Gravity is KeeperCompatibleInterface {
    address payable owner;
    bool public onOff = true; // [testing] toggle Keeper on/off
    uint public immutable upKeepInterval;
    uint public lastTimeStamp;

    mapping (address => Account) public accounts;               // user address => user Account
    mapping (address => bool) public sourceTokens;              // mapping for supported tokens
    mapping (address => bool) public targetTokens;              // mapping for supported tokens
    mapping (uint => PurchaseOrder[]) public purchaseOrders;

    event NewStrategy(address);
    event PurchaseExecuted(uint256);
    event Deposited(address, uint256);
    event Withdrawn(address, uint256);

    struct Account {
        uint            accountStart;
        address         sourceAsset;
        address         targetAsset;
        uint            sourceBalance;
        uint            deployedBalance;
        uint            targetBalance;
        uint            interval;               // 1, 7, 14, 21, 30
        uint            purchaseAmount;         // purchase amount per interval of sourceBalance
        uint            purchasesRemaining;
    }

    struct PurchaseOrder {
        address user;
        uint    purchaseAmount;
    }    

    constructor(address _sourceToken, address _targetToken, uint _upKeepInterval) {
        owner = payable(msg.sender);

        // for testing
        sourceTokens[address(_sourceToken)] = true; // TestToken (testing only)
        targetTokens[address(_targetToken)] = true;

        // keeper variables
        upKeepInterval = _upKeepInterval; // in seconds
        lastTimeStamp = block.timestamp;

        // load initial Kovan asset addresses into tokenAddress mapping
        // sourceTokens[address(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa)] = true; // DAI
        // sourceTokens[address(0xd0A1E359811322d97991E03f863a0C30C2cF029C)] = true; // WETH
        // sourceTokens[address(0xa36085F69e2889c224210F603D836748e7dC0088)] = true; // LINK
    }

    /*
    * - - - - - - - - - - - - keeper integration [start] - - - - - - - - - - - - 
    */

    // [production] accumulatePurchaseOrders
    // function accumulatePurchaseOrders() internal view returns (uint) {
    //     uint _now = block.timestamp;
    //     uint _unixNoonToday = _now - (_now % 86400) + 43200;
    //     uint _total;
    //     for(uint i = 0; i < purchaseOrders[_unixNoonToday].length; i++) {
    //         _total += purchaseOrders[_unixNoonToday][i].purchaseAmount;
    //     }
    //     return _total;
    // }

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
    //     upkeepNeeded = false;
    // }

    // [test] accumulatePurchaseOrders
    function accumulatePurchaseOrders() internal view returns (uint) {
        uint _total;
        for(uint i = 0; i < purchaseOrders[0].length; i++) {
            _total += purchaseOrders[0][i].purchaseAmount;
        }
        return _total;
    }


    // [test] initiateNewStrategy (using second intervals versus daily intervals)
    function initiateNewStrategy(address _sourceAsset, address _targetAsset, uint _sourceBalance, uint _interval, uint _purchaseAmount) public {
        require(sourceTokens[_sourceAsset] == true, "Unsupported source asset type");
        require(targetTokens[_targetAsset] == true, "Unsupported target asset type");
        require(_sourceBalance > 0, "Insufficient deposit amount");
        require(_interval == 60, "Unsupported interval");
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
                                       _purchasesRemaining);

        // populate purchaseOrders mapping
        for(uint i = 1; i <= _purchasesRemaining; i++) {
            uint _nextUnixPurchaseDate = _accountStart + (_interval * i);
            PurchaseOrder memory _purchaseOrder = PurchaseOrder(msg.sender, _purchaseAmount);
            purchaseOrders[0].push(_purchaseOrder);
        }

        // transfer user balance to contract
        (bool success) = IERC20(_sourceAsset).transferFrom(msg.sender, address(this), _sourceBalance);
        require(success, "Initiate new strategy unsuccessful");
        emit NewStrategy(msg.sender);
    }

    // [test] checkUpkeep
    function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
        require(onOff == true, "Keeper checkUpkeep is off");

        /*
        * testing batch transaction
        */

        if((block.timestamp - lastTimeStamp) > upKeepInterval) {
            // if total PO > 0
            uint _total = accumulatePurchaseOrders();
            if(_total > 0) {
                upkeepNeeded = true;
            }
        }
        upkeepNeeded = false;
    }

    // [test] performUpkeep
    function performUpkeep(bytes calldata /* performData */) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        require(onOff == true, "Keeper checkUpkeep is off");
        lastTimeStamp = block.timestamp;
        uint _total = accumulatePurchaseOrders();
        if (_total > 0) {
            /*
            * TO DO: add dex transaction
            */
            emit PurchaseExecuted(block.timestamp);
        }
    }

    /*
    *  - - - - - - - - - - - - keeper integration [end] - - - - - - - - - - - - 
    */

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
    //     uint _unixNoonToday = _accountStart - (_accountStart % 86400) + 43200;
    //     uint _unixInterval = _interval * 86400;
    //     for(uint i = 1; i <= _purchasesRemaining; i++) {
    //         uint _nextUnixPurchaseDate = _unixNoonToday + (_unixInterval * i);
    //         PurchaseOrder memory _purchaseOrder = PurchaseOrder(msg.sender, _purchaseAmount);
    //         purchaseOrders[_nextUnixPurchaseDate].push(_purchaseOrder);
    //     }

    //     // transfer user balance to contract
    //     (bool success) = IERC20(_sourceAsset).transferFrom(msg.sender, address(this), _sourceBalance);
    //     require(success, "Initiate new strategy unsuccessful");
    //     emit NewStrategy(msg.sender);
    // }


    // TO DO: DEX swap

    // TO DO: Aave deposit stablecoins

    // TO DO: update to handle depositing into existing strategy
    // deposit into existing strategy (basic implementation for single source; would updating strategy)
    function depositSource(address _token, uint256 _amount) external {
        //require(sourceTokens[_token] == true, "Unsupported asset type");
        require(_amount > 0, "Insufficient value");
        accounts[msg.sender].sourceBalance += _amount;
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