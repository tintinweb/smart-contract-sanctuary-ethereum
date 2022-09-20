// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

error NotAuthorized();
error NotAuthorizedToVote(address invalidPerson);
error ProposalNotFound();
error WrongState();

contract VotingAutomated is KeeperCompatible {
    event MemberAdded(address member);
    event ProposalAdded(uint256 proposalIndex);
    event VoteUsed(address indexed voter, uint256 indexed proposalIndex);
    event WinnerDeclared(uint256 indexed proposalIndex);
    event NewVotingCreated();
    event StateChanged(Status oldState, Status newState);

    address private immutable s_chairPerson;
    uint256 private lastTimeStamp;
    uint256 private immutable interval;
    uint256 private s_LastWinner;
    enum Status {
        PREPARING,
        VOTING,
        FINISH
    }

    Status private state;

    struct VoteRight {
        uint256 voteWeight;
        bool isVoted;
    }

    struct Map {
        address[] keys;
        mapping(address => VoteRight) values;
    }
    Map private s_voters;

    struct Proposal {
        uint256 proposalIndex;
        uint256 voteCount;
    }

    Proposal[] private proposals;

    constructor(uint256 _interval) {
        s_chairPerson = msg.sender;
        s_voters.values[msg.sender] = VoteRight(2, false);
        s_voters.keys.push(msg.sender);
        state = Status.PREPARING;
        interval = _interval;
        lastTimeStamp = block.timestamp;
    }

    function incrementState() public {
        if (msg.sender != s_chairPerson) {
            revert NotAuthorized();
        }
        Status temp = state;
        state = Status(uint(state) + 1);
        emit StateChanged(temp, state);
    }

    function addMember(address candidateMember) public {
        if (state != Status.PREPARING) {
            revert WrongState();
        }

        if (msg.sender != s_chairPerson) {
            revert NotAuthorized();
        }
        VoteRight memory temp = VoteRight(1, false);
        s_voters.values[candidateMember] = temp;
        s_voters.keys.push(candidateMember);
        emit MemberAdded(candidateMember);
    }

    function addProposal() public {
        if (state != Status.PREPARING) {
            revert WrongState();
        }
        if (msg.sender != s_chairPerson) {
            revert NotAuthorized();
        }
        proposals.push(Proposal(proposals.length + 1, 0));
        emit ProposalAdded(proposals.length);
    }

    function vote(uint256 proposalIndex) public {
        if (state != Status.VOTING) {
            revert WrongState();
        }
        if (
            (s_voters.values[msg.sender].voteWeight == 0) ||
            (s_voters.values[msg.sender].isVoted)
        ) {
            revert NotAuthorizedToVote(msg.sender);
        }
        if (proposals[proposalIndex].proposalIndex == 0) {
            revert ProposalNotFound();
        }

        proposals[proposalIndex].voteCount =
            proposals[proposalIndex].voteCount +
            s_voters.values[msg.sender].voteWeight;
        s_voters.values[msg.sender].isVoted = true;
        emit VoteUsed(msg.sender, proposalIndex);
    }

    function declareWinner() public returns (uint256) {
        if (state != Status.FINISH) {
            revert WrongState();
        }

        uint256 winnerIndex = 0;
        uint256 mostVote = 0;
        uint256 currentVoteCount;

        for (uint i = 0; i < proposals.length; i++) {
            currentVoteCount = proposals[i].voteCount;
            if (currentVoteCount > mostVote) {
                winnerIndex = i;
                mostVote = currentVoteCount;
            }
        }
        emit WinnerDeclared(winnerIndex);
        return proposals[winnerIndex].proposalIndex;
    }

    function startNewVoting() public {
        if (state != Status.FINISH) {
            revert WrongState();
        }

        delete proposals;
        address tempMember;
        for (uint i = 0; i < s_voters.keys.length; i++) {
            tempMember = s_voters.keys[i];
            delete s_voters.values[tempMember];
        }
        delete s_voters.keys;
        s_voters.values[msg.sender] = VoteRight(2, false);
        s_voters.keys.push(msg.sender);

        state = Status.PREPARING;
        emit NewVotingCreated();
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded =
            ((block.timestamp - lastTimeStamp) > interval) &&
            (proposals.length > 0) &&
            (s_voters.keys.length > 0);
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - lastTimeStamp) > interval) {
            lastTimeStamp = block.timestamp;
            if (state == Status.PREPARING) {
                state = Status.VOTING;
            } else if (state == Status.VOTING) {
                state = Status.FINISH;
                s_LastWinner = declareWinner();
                startNewVoting();
            }
        }
    }

    function getChairPerson() public view returns (address) {
        return s_chairPerson;
    }

    function getVoteRight(address member)
        public
        view
        returns (VoteRight memory)
    {
        return s_voters.values[member];
    }

    function getProposal(uint256 index) public view returns (Proposal memory) {
        return proposals[index];
    }

    function getState() public view returns (Status) {
        return state;
    }

    function getLastTimeStamp() public view returns (uint256) {
        return lastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return interval;
    }

    function getLastWinner() public view returns (uint256) {
        return s_LastWinner;
    }

    function getDifference() public view returns (uint256) {
        return block.timestamp - lastTimeStamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

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