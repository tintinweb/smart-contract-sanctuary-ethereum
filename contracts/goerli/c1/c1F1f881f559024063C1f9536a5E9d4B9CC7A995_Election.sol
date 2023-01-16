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
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "./structs.sol";

error user__not__exist();
error Not_Allowed();
error out_of_time();
error already_voted();
error already_exist();
error Not_Found();
error candidate_Not_Exist();
error Election_UpkeepNotNeeded();

/**
 *       @title this is a sample Election App
 *       @author moah
 *       @dev this implements Chainlink Keepers
 */

contract Election is AutomationCompatibleInterface {
    /*tyoe declaration */

    enum ElectionState {
        CLOSE,
        OPEN
    }

    /*election variable */

    ElectionState private s_ellectionState;
    uint256 private s_timeStamp;
    uint216 private s_interval;
    uint256 private s_lastTimeStamp;
    address private immutable i_owner;
    address[] private s_admins;
    uint256 private s_lastcandidateId;
    uint256 private s_electionId;
    string[] private s_numOfcandidates;
    mapping(address => Structs.User) private users;
    mapping(string => Structs.Candidate) private candidate;
    mapping(uint256 => Structs.Elction) private election;

    /* modefiers */

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert Not_Allowed();
        }
        _;
    }

    modifier onlyAdmins() {
        for (uint256 i = 0; i < s_admins.length; i++) {
            if (msg.sender == s_admins[i]) {
                _;
            }
        }
    }

    /*constructor */

    constructor() {
        s_ellectionState = ElectionState.CLOSE;
        i_owner = msg.sender;
        s_admins.push(i_owner);
        s_electionId = 0;
        initializecandidates();
    }

    /*functions */

    function addAdmin(address addr) public onlyOwner {
        for (uint256 i = 0; i < s_admins.length; i++) {
            if (s_admins[i] == addr) revert already_exist();
        }
        s_admins.push(addr);
    }

    function addcandidate(
        string memory candidateName,
        string memory description,
        string memory party
    ) public onlyAdmins {
        candidate[candidateName].candidateName = candidateName;
        candidate[candidateName].description = description;
        candidate[candidateName].party = party;
        candidate[candidateName].nominationNumber = 0;
        candidate[candidateName].numberOfWins = 0;
        s_numOfcandidates.push(candidateName);
    }

    function addElection(
        uint256 interval,
        string[4] memory candidates,
        string memory title,
        string memory description
    ) public onlyAdmins {
        if ((block.timestamp - s_lastTimeStamp) > s_interval) {
            s_electionId += 1;
            election[s_electionId].electionId = s_electionId;
            election[s_electionId].title = title;
            election[s_electionId].interval = interval;
            election[s_electionId].description = description;
            election[s_electionId].isClose = false;
            election[s_electionId].winner = "-1";
            for (uint256 i = 0; i < candidates.length; i++) {
                if (keccak256(abi.encode(candidates[i])) == keccak256(abi.encode(""))) {
                    break;
                }
                if (
                    keccak256(abi.encode(candidates[i])) !=
                    keccak256(abi.encode(candidate[candidates[i]].candidateName))
                ) {
                    revert candidate_Not_Exist();
                }
                candidate[candidates[i]].nominationNumber += 1;
                election[s_electionId].candidateNames.push(candidates[i]);
            }

            for (uint256 i = 0; i < election[s_electionId].candidateNames.length; i++) {
                election[s_electionId]
                    .votes[election[s_electionId].candidateNames[i]]
                    .numOfVotes = 0;
            }

            s_ellectionState = ElectionState.OPEN;

            s_lastTimeStamp = block.timestamp;
        }
    }

    function vote(address voter, string memory candidateName) public {
        uint256 electionId = s_electionId;
        if (
            (s_ellectionState == ElectionState.OPEN) &&
            ((block.timestamp - s_lastTimeStamp) < election[s_electionId].interval)
        ) {
            if (!users[voter].isValid) {
                users[voter].id = voter;
                users[voter].isValid = true;
            }

            if (!users[voter].votes[electionId].isVoted) {
                users[voter].votes[electionId].electionId = electionId;
                users[voter].votes[electionId].candidateName = candidateName;
                election[electionId].votes[candidateName].numOfVotes += 1;
                users[voter].votes[electionId].isVoted = true;
            } else revert already_voted();
        } else revert out_of_time();
    }

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeSet = (s_lastTimeStamp != 0);
        bool isOpen = (ElectionState.OPEN == s_ellectionState);
        bool timePassed = ((block.timestamp - s_timeStamp) > s_interval);
        upkeepNeeded = (isOpen && timePassed && timeSet);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Election_UpkeepNotNeeded();
        }
        setResult();
    }

    function setResult() internal {
        if ((block.timestamp - s_lastTimeStamp) > election[s_electionId].interval) {
            s_ellectionState = ElectionState.CLOSE;
            s_lastTimeStamp = 0;
            election[s_electionId].isClose = true;

            uint256 numOfVotes = 0;
            string memory winner = "0";

            for (uint256 i = 0; i < election[s_electionId].candidateNames.length; i++) {
                if (
                    election[s_electionId]
                        .votes[election[s_electionId].candidateNames[i]]
                        .numOfVotes > numOfVotes
                ) {
                    winner = election[s_electionId].candidateNames[i];

                    numOfVotes = election[s_electionId]
                        .votes[election[s_electionId].candidateNames[i]]
                        .numOfVotes;
                } else if (
                    (election[s_electionId]
                        .votes[election[s_electionId].candidateNames[i]]
                        .numOfVotes == numOfVotes) &&
                    ((keccak256(abi.encode(winner)) != keccak256(abi.encode("0"))) ||
                        (keccak256(abi.encode(winner)) != keccak256(abi.encode("-1"))))
                ) {
                    winner = "0";
                }
            }

            election[s_electionId].winner = winner;
            if (
                (keccak256(abi.encode(winner)) != keccak256(abi.encode("0"))) ||
                (keccak256(abi.encode(winner)) != keccak256(abi.encode("-1")))
            ) {
                candidate[winner].numberOfWins += 1;
            }
        }
    }

    /** Getter Functions */

    function isOwner(address addr) public view returns (uint256) {
        if (addr == i_owner) {
            return 1;
        } else return 0;
    }

    function isAdmins(address addr) public view returns (uint256) {
        for (uint256 i = 0; i < s_admins.length; i++) {
            if (s_admins[i] == addr) return 1;
        }
        return 0;
    }

    function isUserExist(address addr) public view returns (bool) {
        return users[addr].isValid;
    }

    function getElectionsCount() public view returns (uint256) {
        return s_electionId;
    }

    function getcandidate(string memory name) public view returns (Structs.Candidate memory) {
        if (keccak256(abi.encode(candidate[name].candidateName)) == keccak256(abi.encode(name))) {
            return candidate[name];
        } else revert candidate_Not_Exist();
    }

    function getReminingTime() public view returns (uint256) {
        if ((block.timestamp - s_lastTimeStamp) > election[s_electionId].interval) return 0;
        else return election[s_electionId].interval - (block.timestamp - s_lastTimeStamp);
    }

    function getUserHistory(address addr) public view returns (Structs.UserVotes[] memory) {
        if (users[addr].isValid) {
            uint256 voteCounter = 0;
            for (uint256 i = 1; i <= s_electionId; i++) {
                if (users[addr].votes[i].isVoted) {
                    voteCounter += 1;
                }
            }

            Structs.UserVotes[] memory history = new Structs.UserVotes[](voteCounter);

            uint256 historycounter = 0;

            for (uint256 i = 1; i <= s_electionId; i++) {
                if (users[addr].votes[i].isVoted) {
                    history[historycounter] = users[addr].votes[i];
                    historycounter += 1;
                }
            }
            return history;
        } else revert user__not__exist();
    }

    function getCurrrentElection()
        public
        view
        returns (
            string memory,
            string memory,
            string[] memory,
            Structs.candidateVote[] memory,
            string memory
        )
    {
        uint256 candidateCount = 0;
        uint256 lastElection = s_electionId;

        for (uint256 i = 1; i <= election[lastElection].candidateNames.length; i++) {
            candidateCount += 1;
        }
        Structs.candidateVote[] memory candidateVotes = new Structs.candidateVote[](candidateCount);

        for (uint256 i = 0; i < candidateCount; i++) {
            candidateVotes[i] = election[lastElection].votes[
                election[lastElection].candidateNames[i]
            ];
        }

        return (
            election[lastElection].title,
            election[lastElection].description,
            election[lastElection].candidateNames,
            candidateVotes,
            election[lastElection].winner
        );
    }

    function getElectionsTable() public view returns (Structs.Table[] memory) {
        Structs.Table[] memory history = new Structs.Table[](s_electionId);
        for (uint256 i = 1; i <= s_electionId; i++) {
            history[i - 1].electionId = election[i].electionId;
            history[i - 1].description = election[i].description;
            history[i - 1].winner = election[i].winner;
        }
        return history;
    }

    function getElectionById(
        uint256 electionId
    )
        public
        view
        returns (
            bool,
            string memory,
            string memory,
            string[] memory,
            Structs.candidateVote[] memory,
            string memory
        )
    {
        if (election[electionId].electionId == electionId) {
            uint256 candidateCount = 0;
            for (uint256 i = 0; i < election[electionId].candidateNames.length; i++) {
                candidateCount += 1;
            }
            Structs.candidateVote[] memory candidateVotes = new Structs.candidateVote[](
                candidateCount
            );

            for (uint256 i = 0; i < candidateCount; i++) {
                candidateVotes[i] = election[electionId].votes[
                    election[electionId].candidateNames[i]
                ];
            }

            return (
                election[electionId].isClose,
                election[electionId].title,
                election[electionId].description,
                election[electionId].candidateNames,
                candidateVotes,
                election[electionId].winner
            );
        } else revert Not_Found();
    }

    // primery data

    function initializecandidates() internal {
        addcandidate(
            "Satya",
            "Satya Narayana Nadella is an Indian-American business executive. He is the executive chairman and CEO of Microsoft, succeeding Steve Ballmer in 2014 as CEO and John W. Thompson in 2021 as chairman.",
            "microsoft"
        );
        addcandidate(
            "Jeff",
            "Jeffrey Preston Bezos is an American entrepreneur, media proprietor, investor, and commercial astronaut. He is the founder, executive chairman, and former president and CEO of Amazon",
            "Amazon"
        );
        addcandidate(
            "Elon",
            "Elon Reeve Musk FRS is a business magnate and investor. He is the founder, CEO and chief engineer of SpaceX; angel investor, CEO and product architect of Tesla, Inc.; owner and CEO of Twitter, Inc.; founder of The Boring Company; co-founder of Neuralink and OpenAI; and president of the philanthropic Musk Foundation",
            "SpaceX"
        );
        addcandidate(
            "Mark",
            "Mark Elliot Zuckerberg is an American business magnate, internet entrepreneur, and philanthropist. He is known for co-founding the social media website Facebook and its parent company Meta Platforms, of which he is the chairman, chief executive officer, and controlling shareholder",
            "meta"
        );
        addcandidate(
            "Pavel",
            "Pavel Valeryevich Durov is a Russian-born French-Emirati entrepreneur who is known for being the founder of the social networking site VK and Telegram Messenger. He is the younger brother of Nikolai Durov.",
            "telegram"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 *       @author moah
 */

library Structs {
    struct User {
        address id;
        bool isValid;
        mapping(uint256 => UserVotes) votes;
    }

    struct UserVotes {
        uint256 electionId;
        string candidateName;
        bool isVoted;
    }

    struct Candidate {
        string candidateName;
        string description;
        string party;
        uint256 nominationNumber;
        uint256 numberOfWins;
    }

    struct Elction {
        uint256 electionId;
        string title;
        uint256 interval;
        string description;
        bool isClose;
        string[] candidateNames;
        mapping(string => candidateVote) votes;
        string winner;
    }

    struct candidateVote {
        string candidateNames;
        uint256 numOfVotes;
    }

    struct Table {
        uint256 electionId;
        string description;
        string winner;
    }
}