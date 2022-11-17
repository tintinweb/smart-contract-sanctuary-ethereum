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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Game__NotEnoughETHEntered();
error Game__TransferFailed();
error Game__NotOpen();
error Game__UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 gameState
);

/**@title A sample Game Contract
 * @author Yousuf Ejaz Ahmad
 * @notice This contract is for creating a sample Game contract
 * @dev This implements the  Chainlink Automation
 */

contract Game is KeeperCompatibleInterface {
    // Type Declarations
    enum GameState {
        OPEN,
        CALCULATING
    }
    // Storage Variables
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    mapping(address => uint) public s_scores;

    // Lottery Variables
    address private s_recentWinner;
    GameState private s_gameState;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;

    // Events
    event GameEnter(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        s_gameState = GameState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    // Functions

    function enterGame() public payable {
        if (msg.value < i_entranceFee) {
            revert Game__NotEnoughETHEntered();
        }
        if (s_gameState != GameState.OPEN) {
            revert Game__NotOpen();
        }
        s_players.push(payable(msg.sender));
        s_scores[payable(msg.sender)] = 0;
        emit GameEnter(msg.sender);
    }

    function getWinner() internal {
        uint256 indexOfWinner = 0;
        uint256 maxScore = 0;
        for (uint256 i = 0; i < s_players.length; ++i) {
            if (s_scores[s_players[i]] > maxScore) {
                indexOfWinner = i;
                maxScore = s_scores[s_players[i]];
            }
        }

        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_players = new address payable[](0);
        s_gameState = GameState.OPEN;
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Game__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isOpen = GameState.OPEN == s_gameState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Game__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_gameState)
            );
        }

        s_gameState = GameState.CALCULATING;
        getWinner();
    }

    // View / Pure functions
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getGameState() public view returns (GameState) {
        return s_gameState;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getScore(address _addr) public view returns (uint) {
        return s_scores[_addr];
    }

    function setScore(address _addr, uint _i) public {
        s_scores[_addr] = _i;
    }
}