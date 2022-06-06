//SPDX-License-Identifier: BUSL -1.1
//SPDX-FileCopyrightText: Copyright 2021-22 Spherium Finance Ltd
pragma solidity ^0.8.7;

// KeeperCompatible.sol imports the functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol
import "KeeperCompatible.sol";
import {ISpheriumLottery} from "ISpheriumLottery.sol";

error Start__Lottery__Failed();
error Draw__Final__Number__Failed();
error Close__Lottery_Failed();

contract SpheriumLotteryAdmin is KeeperCompatibleInterface {
    ISpheriumLottery public sphiriLottery;

    uint256 public lastTimeStamp;
    bool public closeLotterySuuccess;
    bool public drawFinalNumberSuccess;

    constructor(address _sphiriLotteryAddress) {
        lastTimeStamp = block.timestamp;
        sphiriLottery = ISpheriumLottery(_sphiriLotteryAddress);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if (
            (block.timestamp - lastTimeStamp) >=
            sphiriLottery.MAX_LENGTH_LOTTERY()
        ) {
            upkeepNeeded = true;
            performData = abi.encodePacked(uint256(1));
        }
        if (closeLotterySuuccess == true) {
            upkeepNeeded = true;
            performData = abi.encodePacked(uint256(2));
        }
        if (drawFinalNumberSuccess == true) {
            upkeepNeeded = true;
            performData = abi.encodePacked(uint256(3));
        }
        if (sphiriLottery.viewCurrentLotteryId() == 0) {
            upkeepNeeded = true;
            performData = abi.encodePacked(uint256(4));
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        uint256 decodedvalue = abi.decode(performData, (uint256));
        if (decodedvalue == 1) {
            lastTimeStamp = block.timestamp;
            uint256 _lotteryId = sphiriLottery.viewCurrentLotteryId();
            bool closeLoto = sphiriLottery.closeLottery(_lotteryId);
            if (!closeLoto) {
                revert Close__Lottery_Failed();
            }
            closeLotterySuuccess = true;
        }
        if (decodedvalue == 2) {
            uint256 _lotteryId = sphiriLottery.viewCurrentLotteryId();
            bool drawNumber = sphiriLottery
                .drawFinalNumberAndMakeLotteryClaimable(_lotteryId, false);
            if (!drawNumber) {
                revert Draw__Final__Number__Failed();
            }
            closeLotterySuuccess = false;
            drawFinalNumberSuccess = true;
        }
        if (decodedvalue == 3) {
            bool success = sphiriLottery.startLottery();
            if (!success) {
                revert Start__Lottery__Failed();
            }
            drawFinalNumberSuccess = false;
        }
        if (decodedvalue == 4) {
            bool success = sphiriLottery.startLottery();
            if (!success) {
                revert Start__Lottery__Failed();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "KeeperBase.sol";
import "KeeperCompatibleInterface.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISpheriumLottery {
    function MIN_LENGTH_LOTTERY() external view returns (uint256);

    function MAX_LENGTH_LOTTERY() external view returns (uint256);

    /**
     * @notice Buy tickets for the current lottery
     * @param _lotteryId: lotteryId
     * @param _ticketNumbers: array of ticket numbers between 1,000,000 and 1,999,999
     * @dev Callable by users
     */
    function buyTickets(uint256 _lotteryId, uint32[] calldata _ticketNumbers)
        external;

    /**
     * @notice Claim a set of winning tickets for a lottery
     * @param _lotteryId: lottery id
     * @param _ticketIds: array of ticket ids
     * @param _brackets: array of brackets for the ticket ids
     * @dev Callable by users only, not contract!
     */
    function claimTickets(
        uint256 _lotteryId,
        uint256[] calldata _ticketIds,
        uint32[] calldata _brackets
    ) external;

    /**
     * @notice Close lottery
     * @param _lotteryId: lottery id
     * @dev Callable by operator
     */
    function closeLottery(uint256 _lotteryId) external returns (bool closeLoto);

    /**
     * @notice Draw the final number, calculate reward in CAKE per group, and make lottery claimable
     * @param _lotteryId: lottery id
     * @param _autoInjection: reinjects funds into next lottery (vs. withdrawing all)
     * @dev Callable by operator
     */
    function drawFinalNumberAndMakeLotteryClaimable(
        uint256 _lotteryId,
        bool _autoInjection
    ) external returns (bool drawNumber);

    /**
     * @notice Inject funds
     * @param _lotteryId: lottery id
     * @param _amount: amount to inject in CAKE token
     * @dev Callable by operator
     */
    function feedFunds(uint256 _lotteryId, uint256 _amount) external;

    /**
     * @notice Start the lottery
     * @dev Callable by lottery admin
     */
    function startLottery() external returns (bool success);

    /**
     * @notice View current lottery id
     */
    function viewCurrentLotteryId() external view returns (uint256);
}