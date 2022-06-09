//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract DistributedVoting {
    uint128 immutable minimumQuorum;
    uint128 immutable debatingPeriodDuration;

    address chairPerson;
    bool private locker;

    uint128 countOfProposals;
    
    IERC20 erc20;

    mapping(address => uint256) balances;
    mapping(address => uint256) participations;

    struct Proposal {
        bytes signature;
        string description;
        address recipient;
        uint256 endAt;
        bool inProgrss;
        address[] members;
        mapping(address => bool) voted;
        mapping(bool => uint256) votes;
        mapping(address => bool) delegated;
        mapping(address => bool) representatives;
        mapping(address => address[]) delegations;
    }

    mapping(uint256 => Proposal) proposals;

    event AddProposal(uint128 indexed proposalId);
    event CallStatus(uint128 indexed proposalId, bool status);
    event ProposalRejected(uint128 indexed proposalId);
    event MinimumQuorumNotReached(uint128 indexed proposalId);

    constructor(address _chairPerson, address _tokenAddress,
                uint128 _minimumQuorum, uint128 _debatingPeriodDuration) {
        chairPerson = _chairPerson;
        erc20 = IERC20(_tokenAddress);
        minimumQuorum = _minimumQuorum;
        debatingPeriodDuration = _debatingPeriodDuration;
    }

    function delegate(uint128 _proposalId, address _to) external votingIsExist(_proposalId) {
        require(balances[msg.sender] > 0, "deposite is 0");
        require(!proposals[_proposalId].voted[_to], "already voted");
        require(!proposals[_proposalId].delegated[msg.sender],
                "already delegeted");

        proposals[_proposalId].delegated[msg.sender] = true;
        if (!proposals[_proposalId].representatives[_to]) {
            proposals[_proposalId].representatives[_to] = true;
        }
        proposals[_proposalId].delegations[_to].push(msg.sender);
    }

    function deposite(uint256 _amount) external {
        require(_amount > 0, "amount must be more then 0");

        erc20.transferFrom(msg.sender, address(this), _amount);
        balances[msg.sender] += _amount;
    }

    function withdraw() external {
        require(balances[msg.sender] > 0, "deposite is 0");
        require(participations[msg.sender] == 0, "you are still a voter");

        erc20.transfer(msg.sender, balances[msg.sender]);
        balances[msg.sender] = 0;
    }

    function addProposal(address _recipient, bytes calldata _signature, string calldata _description) 
        external onlyChairPerson {
        proposals[countOfProposals].signature = _signature;
        proposals[countOfProposals].description = _description;
        proposals[countOfProposals].recipient = _recipient;
        proposals[countOfProposals].endAt = block.timestamp + debatingPeriodDuration;
        proposals[countOfProposals].inProgrss = true;
        emit AddProposal(countOfProposals);
        countOfProposals++;
    }

    function getSignature(uint128 _proposalId) external view votingIsExist(_proposalId) 
        returns (bytes memory) {
        return proposals[_proposalId].signature;
    }

    function getDescription(uint128 _proposalId) external view votingIsExist(_proposalId) 
        returns (string memory) {
        return proposals[_proposalId].description;
    }

    function getVotes(uint128 _proposalId, bool _val) external view votingIsExist(_proposalId) 
        returns (uint256) {
        return proposals[_proposalId].votes[_val];
    }

    function getRecipient(uint128 _proposalId) external view votingIsExist(_proposalId) 
        returns (address) {
        return proposals[_proposalId].recipient;
    }

    function vote(uint128 _proposalId, bool _choice) external votingIsExist(_proposalId) {
        require(proposals[_proposalId].endAt > block.timestamp,
                "voting is over");
        require(!proposals[_proposalId].voted[msg.sender], "already voted");
        require(!proposals[_proposalId].delegated[msg.sender],
                "your votes are delegated");
        require(balances[msg.sender] > 0 ||
                proposals[_proposalId].representatives[msg.sender],
                "voting tokens are 0");

        uint256 balance = balances[msg.sender];
        if (proposals[_proposalId].representatives[msg.sender]) {
            address[] memory delegation = proposals[_proposalId].delegations[msg.sender];
            for (uint256 i = 0; i < delegation.length; i++) {
                if (balances[delegation[i]] > 0) {
                    balance += balances[delegation[i]];
                    proposals[_proposalId].members.push(delegation[i]);
                    participations[delegation[i]]++;
                }
            }
        }

        require(balance > 0, "voting tokens are 0");

        proposals[_proposalId].voted[msg.sender] = true;
        proposals[_proposalId].votes[_choice] += balance;
        proposals[_proposalId].members.push(msg.sender);
        participations[msg.sender]++;
    }

    function finishProposal(uint128 _proposalId) external votingIsExist(_proposalId) {
        require(proposals[_proposalId].endAt < block.timestamp,
                "voting in progress");
        require(proposals[_proposalId].inProgrss, "voting is finished");
        proposals[_proposalId].inProgrss = false;
        if (proposals[_proposalId].votes[true] + proposals[_proposalId].votes[false] >= minimumQuorum) {
            if (proposals[_proposalId].votes[true] > proposals[_proposalId].votes[false]) {
                (bool success, ) = proposals[_proposalId].recipient
                                        .call{value: 0}(proposals[_proposalId].signature);
                emit CallStatus(_proposalId, success);
            } else {
                emit ProposalRejected(_proposalId);
            }
        } else {
            emit MinimumQuorumNotReached(_proposalId);
        }

        address[] memory members = proposals[_proposalId].members;
        for (uint256 i = 0; i < members.length; i++) {
            participations[members[i]]--;
        }
    }

    modifier onlyChairPerson() {
        require(msg.sender == chairPerson, "not a chair person");
        _;
    }

    modifier votingIsExist(uint256 _proposalId) {
        require(_proposalId < countOfProposals, "voting is not exist");
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _address) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _tokenOwner, address _spender) external view returns (uint256 remaining);
    function mint(address _to, uint256 _value) external;
    function burn(address _from, uint256 _value) external;
    function setOwner(address _owner) external;    
}