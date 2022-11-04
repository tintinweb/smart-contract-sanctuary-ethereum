// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ProductOrder.sol";

contract ProductOrderFactory {
    function createProductOrder(address vendorAddress, uint PONo, uint timeToAccept, uint timeToShip) public payable {
        // Creates new ProductOrder contract with above parameters, as well as:
        //     msg.sender as purchaserAddress
        //     block.timestamp as acceptTimeStamp
        // Also calls setPayment(), sending msg.value amount of token to it.
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error ProductOrder__NotFactory();
error ProductOrder__NotPurchaser();
error ProductOrder__NotVendor();


contract ProductOrder is KeeperCompatibleInterface {
    // State of Order
    enum POState {
	    SENT,
	    CANCELLED,
	    ACCEPTED,
	    DISPUTE,
        END,
        DISPUTE_END
    }
    POState private s_state;
    
    // All addresses
    address private i_factoryAddress;
    address private i_purchaserAddress;
    address private i_vendorAddress;

    // Amount of Money currently in contract
    uint256 private s_amountOfMoney;

    // Identifier to know what purchase order it is.
    uint256 private i_PONo;

    // Timing to accept and shipping
    uint256 private i_timeToAccept;
    uint256 private i_acceptTimeStamp;
    uint256 private i_timeToShip;
    uint256 private s_shippingTimeStamp;

    // Dispute Variables
    int256 private s_tokenWorthGot = -1;
    uint256 private s_tokenWorthShipped;

    // Events??

    // Modifiers
    modifier onlyFactory() {
        // Continue if sender is the factory.
        _;
    }
    modifier onlyPurchaser() {
        // Continue if sender is the purchaser.
        _;
    }
    modifier onlyVendor() {
        // Continue if sender is the vendor.
        _;
    }
    
    constructor(address purchaserAddress, address vendorAddress, uint256 PONo, uint256 timeToAccept, uint256 acceptTimeStamp, uint256 timeToShip) {
        // Sets i_factoryAddress to msg.sender.
        // Sets above parameters to their respective variables in the smart contract.
        // Sets s_state to state SENT.
    }

    function setPayment() public payable onlyFactory {
        // Sets s_amountOfMoney to msg.value.
    }

    function cancelOrder() public payable onlyPurchaser {
        // Requires s_state to be in SENT
        // Refund s_amountOfMoney to purchaserAddress.
        // Sets s_amountOfMoney to 0.
        // Sets s_state to CANCELLED
    }

    function recievePurchaseOrder(bool orderAccepted, uint256 amountOfPOAccepted) public onlyVendor {
        // Requires s_state to be SENT
        // Requires amountOfPOAccepted to be less than s_amountOfMoney
        // If orderAccepted is false
        //     s_state is set to CANCELLED
        //     Refunds s_amountOfMoney to purchaserAddress
        //     Sets s_amountOfMoney to 0
        // Else if orderAccepted is true
        //     s_state is set to ACCEPTED.
        //     Sets s_shippingTimeStamp to block.timestamp.
        //     Refunds (s_amountOfMoney - amountOfPOAccepted) to purchaserAddress.
        //     Sets s_amountOfMoney to amountOfPOAccepted
    }

    function setShipmentValue(uint256 shipmentValue) public payable onlyPurchaser {
        // Requires s_state to be ACCEPTED
        // Requires shipmentValue to be less than or equal to s_amountOfMoney and greater than 0.
        // If shipmentValue is equal to s_amountOfMoney:
        //     Send s_amountOfMoney to vendorAddress.
        //     Sets s_amountOfMoney to 0.
        //     s_state is set to END
        // Else if shipment value isn’t equal to s_amountOfMoney:
        //     s_state is set to DISPUTE.
        //     s_tokenWorthGot is set to shipmentValue
    }

    function setPurchaserDispute(uint256 tokenWorthGot) public onlyPurchaser {
        // Sets s_tokenWorthGot to tokenWorthGot.
    }

    function setVendorDispute(uint256 tokenWorthShipped) public onlyVendor {
        // Sets s_tokenWorthShipped to tokenWorthShipped.
    }

    function checkUpkeep(bytes memory) public override returns (bool upkeepNeeded, bytes memory) {
        // If s_state is SENT
        //     upkeepNeeded equals if (block.timestamp - i_acceptTimeStamp) is greater than i_timeToAccept.
        // If s_state is ACCEPTED
        //     upkeepNeeded both conditions (AND)
        //         (block.timestamp - s_shippingTimeStamp) is greater than i_timeToShip
        //         s_tokenWorthGot equals -1
        // If s_state is DISPUTE
        //     upkeepNeeded equals if s_tokenWorthGot and s_tokenWorthShipped are equal.
    }

    function performUpkeep(bytes calldata) external override {
        // Gets upkeepNeeded bool from checkUpkeep() function
        // Requires upkeepNeeded to be true.
        // If s_state is SENT or ACCEPTED
        //     s_state is set to CANCELLED
        //     Refunds s_amountOfMoney to purchaserAddress.
        //     Sets s_amountOfMoney to 0.
        // If s_state is DISPUTE
        //     s_state is set to DISPUTE_END
        //     Sends (s_amountOfMoney - s_tokenWorthShipped) to i_purchaserAddress
        //     Sets s_amountOfMoney to s_tokenWorthShipped.
        //     Sends s_tokenWorthShipped token to i_vendorAddress.
        //     Sets s_amountOfMoney to 0.
    }
}

// SPDX-License-Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

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