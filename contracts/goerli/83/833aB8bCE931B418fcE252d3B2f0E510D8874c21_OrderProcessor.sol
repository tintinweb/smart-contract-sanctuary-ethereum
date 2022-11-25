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
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error OrderProcessor__SentValueNotEnough();
error OrderProcessor__SystemBusy();
error OrderProcessor__UpkeepNeededFalse(uint256 contractBalance, uint256 clientsNum);
error OrderProcessor__TransferFailed();

contract OrderProcessor is KeeperCompatibleInterface {
    enum OrderState {
        OPEN,
        PROCESSING
    }

    string private constant TRACKING_ID = "123456789C1243456789";
    address payable private immutable i_owner;
    uint256 private immutable i_upkeepInterval;
    uint256 private immutable i_maxWaitTime;
    uint256 private s_latestTimestamp;
    OrderState private s_orderState;

    struct StructOrders {
        address payable clientAddress;
        uint256 orderTimestamp;
        uint256 orderAmount;
        string trackingNum;
        uint256 index;
    }

    mapping(string => StructOrders) public dictStructOrder;
    string[] public s_arrayOrderId;

    /* Event */
    event trackingIdSet(string indexed trackingId);
    event fundTransfered(string indexed orderId, address to, uint256 amount);

    constructor(uint256 upkeepInterval, uint256 maxWaitTime) {
        i_owner = payable(msg.sender);
        i_upkeepInterval = upkeepInterval;
        i_maxWaitTime = maxWaitTime;
        s_latestTimestamp = block.timestamp;
        s_orderState = OrderState.OPEN;
    }

    function checkOut(uint256 _orderAmount, string memory _orderId) public payable {
        //1. Order web page passes order ID to contract
        //2. Client send ETH to contract address
        if (msg.value < _orderAmount) {
            revert OrderProcessor__SentValueNotEnough();
        }
        if (s_orderState != OrderState.OPEN) {
            revert OrderProcessor__SystemBusy();
        }
        /**
         * ToDo
         * 1. Check if orderId is correct
         * 2. Check if orderId not duplicated
         * 3. May be emit event once checkOut is called
         */

        // update arrayOrderId
        s_arrayOrderId.push(_orderId);

        // set orderAmount
        //orderIdToAmount[orderId] = orderAmount;
        dictStructOrder[_orderId].orderAmount = _orderAmount;

        // set ordertimestamp
        //orderIdToOrdertimestamp[orderId] = block.timestamp;
        dictStructOrder[_orderId].orderTimestamp = block.timestamp;

        // set client address
        dictStructOrder[_orderId].clientAddress = payable(msg.sender);

        // set index
        dictStructOrder[_orderId].index = s_arrayOrderId.length - 1;

        // 3. Contract sends request to generate Estafeta Tracking ID
        // set new trachkin number
        dictStructOrder[_orderId].trackingNum = callTrackingId();
    }

    //function callTrackingId(string memory orderId) public {
    function callTrackingId() internal returns (string memory) {
        // send API request
        string memory s_trackingId = apiTrackingIdMock();
        // 4. Emits event when tracking id is generated
        emit trackingIdSet(s_trackingId);
        return s_trackingId;
    }

    function apiTrackingIdMock() internal pure returns (string memory) {
        return TRACKING_ID;
    }

    function callOrderStatus(string memory orderId) public pure returns (bool) {
        if (keccak256(abi.encodePacked(orderId)) == keccak256(abi.encodePacked("1001"))) {
            return false;
        }
        return true;
    }

    // 5. Contract start monitoring shipping status once each 24h
    /**
    - Shipping status must be 4
    - This contract has to have funds
    - At least one client must be registered
    - Interval time should have passed 
    */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isOpen = (s_orderState == OrderState.OPEN);
        bool hasFund = (address(this).balance > 0);
        bool hasClient = (s_arrayOrderId.length > 0);
        bool timePassed = ((block.timestamp - s_latestTimestamp) > i_upkeepInterval);
        upkeepNeeded = (isOpen && hasFund && hasClient && timePassed);
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        // Revalidating the upkeep in the performUpkeep function
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert OrderProcessor__UpkeepNeededFalse(address(this).balance, s_arrayOrderId.length);
        }
        // set OrderState to PROCESSING
        s_orderState = OrderState.PROCESSING;

        /**        
            1. loop and store orders younger than 30 days to temp array
            2. create a temporary array
            3. loop all the orders and make transaction call 
            4. delete struct elements from mapping thas was 30 more days
            5. loop temp array and match struct index to array key
            6. reset orderIdArray to temp array
        */

        // 1. loop and store orders younger than 30 days to temp array
        // inicialize arraySize variable.
        uint256 arraySize = 0;
        for (uint256 indexOfOrderId = 0; indexOfOrderId < s_arrayOrderId.length; indexOfOrderId++) {
            string memory orderId = s_arrayOrderId[indexOfOrderId];
            // store structOrder to local memory so we can save gas
            StructOrders memory thisOrder = dictStructOrder[orderId];
            // fetch basic data needed
            uint256 orderTimestamp = thisOrder.orderTimestamp;
            uint256 cuttOffTimestamp = orderTimestamp + i_maxWaitTime;

            if (cuttOffTimestamp > block.timestamp) {
                arraySize += 1;
            }
        }

        // 2. create a temporary array
        string[] memory arrayOrderIdsTemporary = new string[](arraySize);
        // inicialize temp array counter
        uint256 temporaryCounter = 0;

        // 3. loop all the orders and make transaction call
        // set s_arrayOrderId.length+1 becuse of pop in the end
        for (uint256 indexOfOrderId = 0; indexOfOrderId < s_arrayOrderId.length; indexOfOrderId++) {
            //for(uint256 indexOfOrderId=(s_arrayOrderId.length-1); indexOfOrderId >= 0; indexOfOrderId-- ){
            string memory orderId = s_arrayOrderId[indexOfOrderId];
            // store structOrder to local memory so we can save gas
            StructOrders memory thisOrder = dictStructOrder[orderId];
            // fetch basic data needed
            uint256 orderTimestamp = thisOrder.orderTimestamp;
            uint256 cuttOffTimestamp = orderTimestamp + i_maxWaitTime;

            if (cuttOffTimestamp < block.timestamp) {
                // retreive sendAmount and cilent address
                uint256 sendValue = thisOrder.orderAmount;
                address clientAddress = thisOrder.clientAddress;

                // call api and check if orders delivered status is true
                // if true transfer fund to owner
                // if deliver status is still pending (false) then return funds to client
                address reciever = (callOrderStatus(orderId)) ? i_owner : clientAddress;

                // make transaction
                (bool success, ) = reciever.call{value: sendValue}("");
                if (!success) {
                    revert OrderProcessor__TransferFailed();
                }
                emit fundTransfered(orderId, reciever, sendValue);

                // delete current orderId from struct
                // 4. delete struct elements from mapping thas was 30 more days
                delete dictStructOrder[orderId];
            } else {
                // update temp array with temp array counter
                arrayOrderIdsTemporary[temporaryCounter] = orderId;
                temporaryCounter += 1;
            }
        }

        //5. loop temp array and match struct index to array key
        if (arrayOrderIdsTemporary.length > 0) {
            for (
                uint256 indexOfOrderId = 0;
                indexOfOrderId < arrayOrderIdsTemporary.length;
                indexOfOrderId++
            ) {
                // basic settings
                string memory orderId = arrayOrderIdsTemporary[indexOfOrderId];
                StructOrders memory thisOrder = dictStructOrder[orderId];

                // update mapping
                // if this order is not the last element of the s_arrayOrderId modify array and update dictStructOrder
                if (thisOrder.index != indexOfOrderId) {
                    thisOrder.index = indexOfOrderId;
                }
            }
            // 6. reset orderIdArray with temp array
            s_arrayOrderId = arrayOrderIdsTemporary;
        } else {
            // reset s_arrayOrderId to zero;
            s_arrayOrderId = new string[](0);
        }

        // update latestTimestamp
        s_latestTimestamp = block.timestamp;
        // update OrderState
        s_orderState = OrderState.OPEN;
    }

    function getOrderAmount(string memory orderId) public view returns (uint256) {
        return dictStructOrder[orderId].orderAmount;
    }

    function getTrackingId(string memory orderId) public view returns (string memory) {
        return dictStructOrder[orderId].trackingNum;
    }

    function getOrderTimestamp(string memory orderId) public view returns (uint256) {
        return dictStructOrder[orderId].orderTimestamp;
    }

    function getClientAddress(string memory orderId) public view returns (address) {
        return dictStructOrder[orderId].clientAddress;
    }

    function getLatestTimestamp() public view returns (uint256) {
        return s_latestTimestamp;
    }

    function getMaxWaitTime() public view returns (uint256) {
        return i_maxWaitTime;
    }

    function getClientNum() public view returns (uint256) {
        return s_arrayOrderId.length;
    }

    function getUpkeepInterval() public view returns (uint256) {
        return i_upkeepInterval;
    }

    function getOrderProcessorState() public view returns (OrderState) {
        return s_orderState;
    }

    function getOrderId(uint256 index) public view returns (string memory) {
        return s_arrayOrderId[index];
    }
}