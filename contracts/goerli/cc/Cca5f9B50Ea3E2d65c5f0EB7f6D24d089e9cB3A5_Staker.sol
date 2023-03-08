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
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

error lessFundAmt();
error tranferETHFailed();
error fundingClosed();
error upkeepNotNeeded();

contract Staker is AutomationCompatibleInterface {
    enum StakerState {
        OPEN,
        CLOSED
    }

    // Contract Variables
    mapping(address => uint256) private amountFunded;
    address[] private funders;
    uint256 private immutable i_thresholdETH;
    uint256 private immutable i_interval;
    uint256 private immutable i_minFundingAmount;
    address private immutable i_owner;
    uint256 private lastBlockTime;
    StakerState private stakerState;

    // External Contract
    address payable private immutable i_externalContract;

    // Contract Event
    event Stake(address indexed funder, uint256 indexed fundAmt);
    event fundCollectedInExternalContract(uint256 indexed fundingAmt);
    event fundWithdrawn();

    // Constructor
    constructor(uint256 _minFundingAmount, uint256 _thresholdETH, address _externalContract, uint256 _interval) {
        i_owner = msg.sender;
        i_minFundingAmount = _minFundingAmount;
        i_thresholdETH = _thresholdETH;
        i_externalContract = payable(_externalContract);
        stakerState = StakerState.OPEN;
        i_interval = _interval;
        lastBlockTime = block.timestamp;
    }

    // Transaction Function
    function stake() public payable {
        if (stakerState == StakerState.CLOSED) {
            revert fundingClosed();
        }
        if (msg.value < i_minFundingAmount) {
            revert lessFundAmt();
        }

        funders.push(msg.sender);
        amountFunded[msg.sender] += msg.value;

        emit Stake(msg.sender, msg.value);
    }


    // Time to get automation
    function checkUpkeep(bytes memory /* checkData */) public view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool stateResult = (stakerState == StakerState.OPEN);
        bool deadlineStatisfied = ((block.timestamp - lastBlockTime) > i_interval);

        upkeepNeeded = stateResult && deadlineStatisfied;
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        // check it again if checkUpKeep Needed
        (bool isUpKeedNeeded, ) = checkUpkeep("");
        if (!isUpKeedNeeded) {
            revert upkeepNotNeeded();
        }

        stakerState = StakerState.CLOSED;

        if (address(this).balance >= i_thresholdETH) {
            complete();
        }
        else {
            withdraw();
        }

        lastBlockTime = block.timestamp;
        stakerState = StakerState.OPEN;
    }


    // Runs if threshold eth has reached
    function complete() private {
        // Send eth to external contract
        uint256 balance = address(this).balance;
        (bool success, ) = i_externalContract.call{value: balance}("");

        if (!success) {
            revert tranferETHFailed();
        }

        emit fundCollectedInExternalContract(balance);

        // Reset Amount Funded Mapping
        for (uint256 i = 0; i<funders.length; i++) {
            amountFunded[funders[i]] = 0;
        }

        // Reset Funders Array
        funders = new address[](0);
    }

    // Runs if threshold eth not reached after deadline
    function withdraw() private {
        // send all eth to the funders

        for (uint256 i = 0; i<funders.length; i++) {
            if (amountFunded[funders[i]] != 0) {
                (bool result, ) = payable(funders[i]).call{value: amountFunded[funders[i]]}("");
                if (!result) {
                    revert tranferETHFailed();
                }
            }
            amountFunded[funders[i]] = 0;
        }

        emit fundWithdrawn();

        funders = new address[](0);
    }
    

    // View/Pure Function
    function getAmountFunded(address _funder) public view returns (uint256) {
        return amountFunded[_funder];
    }

    function getFunderByIdx(uint256 idx) public view returns (address) {
        return funders[idx];
    }

    function getThresholdEth() public view returns (uint256) {
        return i_thresholdETH;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getMinFundingAmt() public view returns (uint256) {
        return i_minFundingAmount;
    }

    function getLastBlockTime() public view returns (uint256) {
        return lastBlockTime;
    }

    function getStakerState() public view returns (uint256) {
        return uint256(stakerState);
    }

    function getExternalContract() public view returns (address) {
        return i_externalContract;
    }

    // Receive function
    receive() external payable {
        stake();
    }
}