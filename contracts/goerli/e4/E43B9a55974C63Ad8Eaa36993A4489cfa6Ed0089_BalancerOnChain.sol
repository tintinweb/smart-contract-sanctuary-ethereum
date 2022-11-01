// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import '@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol';

/**
 * @dev Example contract which perform all the computation in `performUpkeep`
 * @notice important to implement {AutomationCompatibleInterface}
 */

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract BalancerOnChain is AutomationCompatibleInterface {
    uint256 public constant SIZE = 1000;
    uint256 public constant LIMIT = 1000;
    uint256[SIZE] public balances;
    uint256 public liquidity = 1000000;

    constructor() {
        // On the initialization of the contract, all the elements have a balance equal to the limit
        for (uint256 i = 0; i < SIZE; i++) {
            balances[i] = LIMIT;
        }
    }

    /// @dev called to increase the liquidity of the contract
    function addLiquidity(uint256 liq) public {
        liquidity += liq;
    }

    /// @dev withdraw an `amount`from multiple elements of `balances` array. The elements are provided in `indexes`
    function withdraw(uint256 amount, uint256[] memory indexes) public {
        for (uint256 i = 0; i < indexes.length; i++) {
            require(indexes[i] < SIZE, 'Provided index out of bound');
            balances[indexes[i]] -= amount;
        }
    }

    /// @dev this method is called by the Automation Nodes to check if `performUpkeep` should be performed
    function checkUpkeep(
        bytes calldata /* checkData */
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = false;
        for (uint256 i = 0; i < SIZE && !upkeepNeeded; i++) {
            if (balances[i] < LIMIT) {
                // if one element has a balance < LIMIT then rebalancing is needed
                upkeepNeeded = true;
            }
        }
        return (upkeepNeeded, '');
    }

    /// @dev this method is called by the Automation Nodes. it increases all elements which balances are lower than the LIMIT
    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        uint256 increment;
        uint256 _balance;
        for (uint256 i = 0; i < SIZE; i++) {
            _balance = balances[i];
            // best practice: reverify the upkeep is needed
            if (_balance < LIMIT) {
                // calculate the increment needed
                increment = LIMIT - _balance;
                // decrease the contract liquidity accordingly
                liquidity -= increment;
                // rebalance the element
                balances[i] = LIMIT;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
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