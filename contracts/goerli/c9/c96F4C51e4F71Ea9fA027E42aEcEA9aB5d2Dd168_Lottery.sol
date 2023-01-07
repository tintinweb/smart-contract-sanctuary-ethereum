// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "KeeperCompatibleInterface.sol";

error EntranceFeeNotEnough();
error LotteryPrizeCanNotBeSent();
error NoPlayersFoundGivenAddress();
error ExitingPlayerFundFailure();

contract Lottery is KeeperCompatibleInterface {
    uint256 private i_interval;
    uint256 private s_firstTimeStamp;
    uint256 private i_fee;
    address payable[] private s_players;
    mapping(address => uint256) private s_address_to_index;

    event upkeepPerformed();
    event NOT_ENOUGH_ENTRANCE_FEE(address indexed _poorAddress);
    event PRIZE_COULD_NOT_BE_SENT(address indexed _luckilyButCanNotSendPrize);
    event THIS_GUY_NOT_IN_PLAYERS_BUT_TRING_TAKE_MONEY(address indexed whoAreYou);
    event WINNER_SELECTED(address indexed _winnerAddress);

    constructor(uint256 _interval, uint256 _fee) {
        i_interval = _interval;
        i_fee = _fee;

        s_firstTimeStamp = block.timestamp;
    }

    function checkUpkeep(
        bytes memory
    ) external view override returns (bool upkeepNeeded, bytes memory) {
        bool interval_test = (block.timestamp - s_firstTimeStamp) > i_interval;
        bool playerLengthTest = s_players.length > 0;

        upkeepNeeded = interval_test && playerLengthTest;
    }

    function performUpkeep(bytes calldata) external override {
        s_firstTimeStamp = block.timestamp;

        address payable recentWinner = s_players[0]; // this area will be randomized...

        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            emit PRIZE_COULD_NOT_BE_SENT(recentWinner);
            revert LotteryPrizeCanNotBeSent();
        }

        emit WINNER_SELECTED(recentWinner);
        emit upkeepPerformed();
    }

    function enterToLottery() public payable {
        if (msg.value < (i_fee)) {
            emit NOT_ENOUGH_ENTRANCE_FEE((msg.sender));
            revert EntranceFeeNotEnough();
        }

        s_address_to_index[msg.sender] = s_players.length;
        s_players.push(payable(msg.sender));
    }

    function exitFromLottery() public {
        address payable whoWantToExit = payable(msg.sender);

        uint256 indexOfThisGuy = getIndexOfAddress(whoWantToExit);

        (bool success,) = whoWantToExit.call{value: (i_fee)}("");
        if (!success){
            revert ExitingPlayerFundFailure();
        }

        delete s_players[indexOfThisGuy];

        for (uint256 index = indexOfThisGuy; index < s_players.length; index++) {
            s_players[index] = s_players[index + 1];
        }
        s_players.pop();

        delete s_address_to_index[whoWantToExit];
    }

    function getDelta() public view returns (uint256) {
        return (block.timestamp - s_firstTimeStamp);
    }

    function getPlayers(uint256 index_of_needed_player) public view returns (address payable) {
        return (s_players[index_of_needed_player]);
    }

    function areKeepersPerform() public view returns (bool performNeeded) {
        bool interval_test = (block.timestamp - s_firstTimeStamp) > i_interval;
        bool playerLengthTest = s_players.length > 0;

        performNeeded = interval_test && playerLengthTest;
    }

    function getIndexOfAddress(address whichAddressLookingFor) public view returns (uint256) {

        // bool thisGuyInOurList = true;
        // address payable emptyValue = payable(address(0));

        // for (uint256 index = 0; index < s_players.length; index++) {
        //     if(s_players[index] == emptyValue ){
        //         thisGuyInOurList = false;
        //     }
        // }

        // if(!thisGuyInOurList){
        //     emit THIS_GUY_NOT_IN_PLAYERS_BUT_TRING_TAKE_MONEY(whichAddressLookingFor);
        //     revert NoPlayersFoundGivenAddress();
        // }

        return s_address_to_index[whichAddressLookingFor];
    }
}

// SPDX-License-Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "AutomationCompatibleInterface.sol";

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