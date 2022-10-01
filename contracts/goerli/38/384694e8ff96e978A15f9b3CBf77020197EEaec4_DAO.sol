// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

contract DAO {
    // Error
    error CannotVoteOwnPolling();
    error CannotVoteMoreThanOnce();
    error NotMember();
    error NotDecider();
    error NotCreater();
    error CannotCancelVoteBeforeVote();
    error PollingIsNotOpen();
    error ShortInterval();

    // Event
    event PollingAdded(address indexed pollingOwner, uint256 indexed pollingId);
    event Voted(
        address indexed voter,
        address indexed pollingOwner,
        uint256 currentVotesAmount,
        uint256 currentTotalVoteAmount,
        uint256 reputation
    );
    event VoteCanceled(
        address indexed voter,
        address indexed pollingOwner,
        uint256 currentVotesAmount,
        uint256 currentTotalVoteAmount,
        uint256 reputation
    );

    enum PollingType {
        ADD_MEMBER,
        REMOVE_MEMBER,
        REMOVE_DECIDER,
        SEND_FUND
    }

    enum PollingState {
        Open,
        Accepted,
        Rejected
    }

    struct Polling {
        PollingType pollingType;
        PollingState pollingState;
        uint256 id;
        address owner;
        uint256 pollingStartTime;
        uint256 interval;
        address[] addressData;
        uint256[] fundData;
        uint256 yesCount;
        uint256 noCount;
    }

    uint256 constant MINIMUM_POLLING_INTERVAL = 1 seconds;
    uint256 totalPolling;
    uint256 totalMember;
    address public immutable i_creater;
    mapping(address => bool) private s_deciders;
    mapping(address => bool) private s_members;
    mapping(uint256 => Polling) private s_pollingRegistry;
    mapping(address => uint256) private s_reputations;
    mapping(address => mapping(uint256 => bool)) private s_voteRegistry;
    mapping(address => mapping(uint256 => bool)) private s_voteAnswerRegistry;

    constructor() {
        i_creater = msg.sender;
        s_deciders[msg.sender] = true;
        s_members[msg.sender] = true;
    }

    function Vote(uint256 pollingId, bool answer) public {
        Polling memory polling = s_pollingRegistry[pollingId];
        if (!s_members[msg.sender]) {
            revert NotMember();
        }
        if (polling.owner == msg.sender) {
            revert CannotVoteOwnPolling();
        }
        if (s_voteRegistry[msg.sender][pollingId]) {
            revert CannotVoteMoreThanOnce();
        }
        if (polling.pollingState != PollingState.Open) {
            revert PollingIsNotOpen();
        }
        s_voteAnswerRegistry[msg.sender][pollingId] = answer;
        polling.yesCount += answer ? 1 : 0;
        polling.noCount += answer ? 0 : 1;

        s_pollingRegistry[pollingId] = polling;
        s_voteRegistry[msg.sender][pollingId] = true;
        emit Voted(
            msg.sender,
            polling.owner,
            polling.yesCount,
            polling.noCount,
            s_reputations[msg.sender]
        );
    }

    function CancelVote(uint256 pollingId) public {
        Polling memory polling = s_pollingRegistry[pollingId];
        if (!isMember(msg.sender)) {
            revert NotMember();
        }
        if (polling.owner == msg.sender) {
            revert CannotVoteOwnPolling();
        }
        if (!s_voteRegistry[msg.sender][pollingId]) {
            revert CannotCancelVoteBeforeVote();
        }

        polling.yesCount -= s_voteRegistry[msg.sender][pollingId] ? 1 : 0;
        polling.noCount -= s_voteRegistry[msg.sender][pollingId] ? 0 : 1;
        s_voteRegistry[msg.sender][pollingId] = true;
    }

    function CreatePolling(
        PollingType pollingType,
        uint256 _interval,
        address[] memory addressData,
        uint256[] memory fundData
    ) public {
        if (!s_members[msg.sender]) {
            revert NotMember();
        }
        if (_interval < MINIMUM_POLLING_INTERVAL) {
            revert ShortInterval();
        }

        uint256 t_totalPolling = totalPolling;

        Polling memory polling = Polling({
            pollingType: pollingType,
            pollingState: PollingState.Open,
            id: t_totalPolling,
            owner: msg.sender,
            yesCount: 0,
            noCount: 0,
            pollingStartTime: block.timestamp,
            interval: _interval,
            addressData: addressData,
            fundData: fundData
        });
        s_pollingRegistry[t_totalPolling] = polling;

        emit PollingAdded(msg.sender, t_totalPolling);
        totalPolling++;
    }

    function addDecider(address _candidate) public {
        if (!(msg.sender == i_creater)) {
            revert NotCreater();
        }
        s_members[_candidate] = true;
        s_deciders[_candidate] = true;
    }

    function addMember(address _candidate) public {
        if (!isDecider(msg.sender)) {
            revert NotDecider();
        }
        s_members[_candidate] = true;
        totalMember++;
    }

    function getPolling(uint256 pollingIndex) public view returns (Polling memory) {
        return s_pollingRegistry[pollingIndex];
    }

    function getFund() external payable {}

    // Chainlink

    function updatePollings() public {
        for (uint256 i = 0; i < totalPolling; i++) {
            Polling memory polling = s_pollingRegistry[i];
            if (polling.pollingState == PollingState.Open) {
                if (block.timestamp - polling.pollingStartTime >= polling.interval) {
                    if (polling.yesCount > polling.noCount) {
                        if (polling.pollingType == PollingType.ADD_MEMBER) {
                            for (uint256 j = 0; j < polling.addressData.length; j++) {
                                s_members[(polling.addressData[j])] = true;
                            }
                        } else if (polling.pollingType == PollingType.REMOVE_MEMBER) {
                            for (uint256 j = 0; j < polling.addressData.length; j++) {
                                s_members[polling.addressData[j]] = false;
                            }
                        } else if (polling.pollingType == PollingType.REMOVE_DECIDER) {
                            for (uint256 j = 0; j < polling.addressData.length; j++) {
                                s_deciders[address(polling.addressData[j])] = false;
                            }
                        } else if (polling.pollingType == PollingType.SEND_FUND) {
                            for (uint256 j = 0; j < polling.addressData.length; j += 1) {
                                (bool sent, ) = polling.addressData[j].call{
                                    value: uint256(address(this).balance)
                                }(""); // *  polling.fundData[j])
                            }
                        } else {
                            polling.pollingState = PollingState.Rejected;
                        }
                    }

                    s_pollingRegistry[i] = polling;
                }
            }
        }
    }

    // View / Pure Functions
    function isMember(address _candidate) public view returns (bool) {
        return s_members[_candidate];
    }

    function isDecider(address _candidate) public view returns (bool) {
        return s_deciders[_candidate];
    }

    function getPollingVoteCount(uint256 pollingId) public view returns (uint256) {
        return
            s_pollingRegistry[pollingId].yesCount + s_pollingRegistry[pollingId].noCount;
    }
    // cuzdan kontrolu
    // proposal
    // oylanma
    // oylanma suresi
    // proposal devreye girme suresi
    // isteyen proposal yayinlayabilir -> belli bir kurali olacak
}