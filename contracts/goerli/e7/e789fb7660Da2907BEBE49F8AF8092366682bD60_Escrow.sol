// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.9 <0.9.0;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

// Author: @avezorgen
contract Escrow is AutomationCompatibleInterface {
    mapping(bytes32 => details) public deals;
    struct details {
        address buyer;
        address seller;
        uint value;
        uint Bfee;
        uint8 status;
    }

    //buyerConf | sellerConf    = uint8 status
    //     0    |       0       = 0  
    //       created            = 1
    //     1    |       0       = 2
    //     1    |       1       = 3

    address public owner;
    uint public hold;
    uint public limit;

    event Created(address indexed buyer, address indexed seller, bytes32 indexed TxId);
    event BuyerConfim(bytes32 indexed TxId);
    event SellerConfim(bytes32 indexed TxId);
    event Finished(bytes32 indexed TxId);
    event Conflict(bytes32 indexed TxId);

    modifier onlyPerson(address pers) {
        require(msg.sender == pers, "Don't have permission");
        _;
    }

    constructor(uint _limit) {
        owner = msg.sender;
        hold = 0;
        limit = _limit;
    }

    function getFee(uint value) internal pure returns(uint fee){
        fee = value / 1e2 * 2;
    }

    function create(address buyer, address seller, uint value, uint8 feeStyle) external {
        require(msg.sender == buyer || msg.sender == seller, "Don't have permission");
        require(value != 0, "Can't provide deal with 0 value");
        bytes32 TxId = keccak256(abi.encode(buyer, seller, block.timestamp));
        require(deals[TxId].value == 0, "Deal already exists");
        require(feeStyle <= 2, "Wrong feeStyle");
        uint Bfee = 0;
        if (feeStyle == 0) Bfee = getFee(value);
        else if (feeStyle == 1) Bfee = getFee(value) / 2;
        deals[TxId] = details(buyer, seller, value - Bfee, Bfee, 1);
        emit Created(buyer, seller, TxId);
    }

    function sendB(bytes32 TxId) external payable onlyPerson(deals[TxId].buyer) {
        require(msg.value == deals[TxId].value + deals[TxId].Bfee, "Wrong money value");
        require(deals[TxId].status == 1, "Money was already sent");
        deals[TxId].status = 2;
        emit BuyerConfim(TxId);
    }

    function sendS(bytes32 TxId) external onlyPerson(deals[TxId].seller) {
        require(deals[TxId].status == 2, "Money was not sent or Subject was already sent");
        deals[TxId].status = 3;
        emit SellerConfim(TxId);
    }

    function cancel(bytes32 TxId) external {
        require(msg.sender == deals[TxId].buyer || msg.sender == deals[TxId].seller, "Don't have permission");
        require(deals[TxId].status != 3, "Can't be cancelled already");
        if (deals[TxId].status == 2) {
            if (msg.sender == deals[TxId].seller) {
                emit Conflict(TxId); //seller отменил сделку, когда buyer уже отправил деньги
            }
            payable(deals[TxId].buyer).transfer(deals[TxId].value + deals[TxId].Bfee);
        }
        delete deals[TxId];
        emit Finished(TxId);
    }

    function approve(bytes32 TxId) external onlyPerson(deals[TxId].buyer) {
        require(deals[TxId].status == 3, "Seller did not confirm the transaction");
        uint InpValue = deals[TxId].value + deals[TxId].Bfee;
        uint fee = getFee(InpValue);
        hold += fee;
        payable(deals[TxId].seller).transfer(InpValue - fee);
        delete deals[TxId];
        emit Finished(TxId);
    }

    function disapprove(bytes32 TxId) external onlyPerson(deals[TxId].buyer) {
        require(deals[TxId].status == 3, "Seller did not confirm the transaction");
        hold += deals[TxId].Bfee;
        payable(msg.sender).transfer(deals[TxId].value); //buyer отправлял и seller отправлял
        delete deals[TxId];
        emit Finished(TxId);
    }

    function withdraw(address target) external onlyPerson(owner) {
        payable(target).transfer(hold);
        hold = 0;
    }

    function setOwner(address newOwner) external onlyPerson(owner) {
        owner = newOwner;
    }

    function setLimit(uint newlimit) external onlyPerson(owner)  {
        limit = newlimit;
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = hold > limit;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        if (hold > limit) {
            payable(owner).transfer(hold);
            hold = 0;
        }
    }
    
    receive() external payable {
        hold += msg.value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

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