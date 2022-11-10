// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
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

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

/** @title The RedeemBonds contract
 * @notice An example contract compatible with Chainlink Automation Network that monitors & redeems bonds to user
 */

contract RedeemBonds is AutomationCompatibleInterface {
    error RedeemBonds__EmptyBondPool();
    event RedeemSucceeded(address indexed bondAddress, address indexed buyer);

    struct Bond {
        // bool isActive;
        uint256 matureDuration; // in seconds
        address seller;
        uint56 lastRedeemTimeStamp;
        address[] buyers;
        uint256 profit;
    }

    uint256 private s_bondPool;
    address[] private s_watchList;

    // { bondAddress: Bond struct }
    mapping(address => Bond) private s_bondListings;

    constructor() {}

    function listBond(
        address bondAddress,
        uint256 matureDuration,
        uint256 profit
    ) external {
        address[] memory buyers;
        // add bond to listing
        s_bondListings[bondAddress] = Bond({
            matureDuration: matureDuration,
            seller: msg.sender,
            buyers: buyers,
            lastRedeemTimeStamp: 0,
            profit: profit
        });

        // add bond address to watch list for monitoring
        s_watchList.push(bondAddress);
    }

    function buyBond(address bondAddress) external payable {
        // get target bond
        Bond storage targetBond = s_bondListings[bondAddress];
        s_bondPool = s_bondPool + msg.value;

        // update buyers list
        targetBond.buyers.push(msg.sender);
    }

    function redeem() public {
        Bond memory targetBond;

        if (s_bondPool <= 0) {
            revert RedeemBonds__EmptyBondPool();
        }

        for (uint i = 0; i < s_watchList.length; i++) {
            targetBond = s_bondListings[s_watchList[i]];

            // FIX: the comparison logic need to be improved
            // mature duration is set to be 5 mins when list the bond
            // so the contract will redeem to buyer every 5 mins no matter what
            if (
                targetBond.matureDuration <=
                block.timestamp - targetBond.lastRedeemTimeStamp
            ) {
                for (uint j = 0; j < targetBond.buyers.length; j++) {
                    (bool success, ) = payable(targetBond.buyers[j]).call{
                        value: targetBond.profit
                    }("");

                    if (success) {
                        targetBond.lastRedeemTimeStamp = uint56(
                            block.timestamp
                        );

                        emit RedeemSucceeded(
                            s_watchList[i],
                            targetBond.buyers[j]
                        );
                    }
                }
            }
        }
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        upkeepNeeded = s_watchList.length > 0;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        redeem();
    }

    function getBond(
        address bondAddress
    ) external view returns (Bond memory targetBond) {
        return s_bondListings[bondAddress];
    }

    function getWatchList() external view returns (address[] memory watchList) {
        return s_watchList;
    }

    function getBondPool() external view returns (uint256 bondPool) {
        return s_bondPool;
    }
}