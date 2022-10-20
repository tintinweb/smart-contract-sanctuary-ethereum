// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Voting__CannotVoteAgain();
error Voting__OnlyOwnerCanSetNewVoting();
error Voting__UpKeepNotNeeded();
error Voting__NotOpen();

contract Voting is KeeperCompatibleInterface {
    /* Types declarations */
    enum VotingState {
        OPEN,
        CALCULATING
    }

    //State variable //

    uint256 public immutable i_interval; // We are dealing with time in seconds //
    VotingState private s_votingState;
    address public immutable i_owner;

    // Voting variable //

    string[] public Parties;
    mapping(uint256 => uint256) voting;
    mapping(address => bool) voters;
    string private s_winner;
    uint256 private s_lastTimeStamp;
    // Events //
    event NewVoting(string[] indexed parties);
    event Voted(address indexed voter);
    event WinnerPicked(string indexed name);

    // Constructor //

    constructor(uint256 _interval) {
        i_interval = _interval;
        i_owner = msg.sender;
        s_lastTimeStamp = block.timestamp;
        s_votingState = VotingState.OPEN;
    }

    // Function //

    function setVoting(string[] memory _Parties) public {
        if (msg.sender != i_owner) {
            revert Voting__OnlyOwnerCanSetNewVoting();
        }
        if (s_votingState != VotingState.OPEN) {
            revert Voting__NotOpen();
        }
        Parties = _Parties;
        for (uint256 i = 0; i < Parties.length; i++) {
            voting[i] = 0;
        }
        emit NewVoting(Parties);
        s_votingState = VotingState.CALCULATING;
    }

    function vote(uint256 partyNo) public {
        if (voters[msg.sender] == true) {
            revert Voting__CannotVoteAgain();
        }
        voters[msg.sender] = true;
        voting[partyNo]++;
        emit Voted(msg.sender);
    }

    function results() internal {
        uint256 max;
        for (uint256 i = 0; i < Parties.length; i++) {
            if (voting[i] > max) {
                max = voting[i];
            }
            if (voting[i] == max) {
                s_winner = Parties[i];
            }
        }
        s_lastTimeStamp = block.timestamp;
    }

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
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool isOpen = VotingState.CALCULATING == s_votingState;
        upkeepNeeded = (timePassed && isOpen);
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Voting__UpKeepNotNeeded();
        }

        results();
        emit WinnerPicked(s_winner);
        s_votingState = VotingState.OPEN;
    }

    // View / Pure //

    function getPartiesName(uint256 no) public view returns (string memory) {
        return Parties[no];
    }

    function votingStatus(address name) public view returns (bool) {
        return voters[name];
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getLatestTimeStamps() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getWinner() public view returns (string memory) {
        return s_winner;
    }

    function getVotingState() public view returns (VotingState) {
        return s_votingState;
    }

    function getVotes(uint256 no) public view returns (uint256) {
        return voting[no];
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