// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "Proposal.sol";
import "User.sol";

contract ConsensusNetwork {
    address public owner;
    string public networkName;

    uint256 public userIndex = 0;
    uint256 internal proposalIndex = 0;
    uint256 public minimumStake;

    Proposal[] public proposals;
    User[] public users;

    mapping(uint256 => User) public indexUser;
    mapping(uint256 => Proposal) public indexProposal;

    struct Vote {
        string response;
    }

    constructor(string memory _networkName) {
        owner = msg.sender;
        networkName = _networkName;
        minimumStake = 10;
    }

    // function addUser(address _user) public onlyOwner {}      These will be used in a private version of network
    // function removeUser(uint _userAddress) public returns(uint[]) {
    //     User[] storage auxUsers;
    //     for (uint i = 0; i < users.length; i++){
    //         if(users[i] != _valueToFindAndRemove)
    //             auxUsers.push(_array[i]);
    //     }
    //     return auxUsers;
    // }
    // function join(address _userAddress) public {}
    // function leave(address _userAddress) public {}

    function depolyProposal(
        string memory _description,
        bool _singleResponse,
        uint256 _reward,
        bool _randomReward,
        uint256 _responseRequired,
        uint256 _deadline
    ) public onlyOwner {
        Proposal _proposal = new Proposal(
            _description,
            _singleResponse,
            _reward,
            _randomReward,
            _responseRequired,
            _deadline
        );
        proposals.push(_proposal);
        proposalIndex += 1;
    }

    function changeProposalStatus(uint256 _proposalIndex, bool _status)
        public
        onlyOwner
    {
        proposals[_proposalIndex].setStatus(_status);
    }

    function createReward() public payable onlyOwner {}

    function vote() public {}

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Proposal {
    address public owner;

    // Description of proposal, questions involved,
    // suggested responses/format
    string public description;
    string[] public responses;

    string[] public userFilters; // list of user filters? have to have dictionary-like way of mapping

    // Switch to either record string as single response,
    // or look for "," to split responses
    bool public singleResponse;
    uint256 public reward; // denominated in consensus tokens

    // Switch that determines whether the reward is distributed evenly
    // among majority voters, or to a single voter randomly
    bool public randomReward;

    uint256 public date;
    uint256 public deadline;
    uint256 public responsesRequired; // have default value so contract can know whethers
    bool public status;

    // to wait for a certain # of votes, or to wait for owner to end
    constructor(
        string memory _description,
        bool _singleResponse,
        uint256 _reward,
        bool _randomReward,
        uint256 _responsesRequired,
        uint256 _deadline
    ) {
        owner = msg.sender;
        description = _description;
        singleResponse = _singleResponse;
        reward = _reward;
        randomReward = _randomReward;
        responsesRequired = _responsesRequired;
        date = block.timestamp;
        deadline = _deadline;
        status = true;
    }

    function getStatus() public returns (bool) {
        return status;
    }

    function setStatus(bool _status) public {
        require(status != _status);
        status = _status;
    }

    function respond(string memory _response) public {}

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

// contract Proposal {
//     address public owner;
//     string public proposal;
//     string  public response;
//     uint256 public date;
//     uint256 public deadline;
//     uint256 public reward;
//     uint256 public votesRequired;
//     bool public status;

//     constructor(
//         string _proposal;
//         string _responseOptions;
//         uint256 _date;
//         uint256 _deadline;
//         uint256 _reward;
//         uint256 _votesRequired;
//         bool _status;
//     ) {
//         owner = msg.sender;
//         proposal = _proposal;
//         response = _response;
//         date = _date;
//         deadline = _deadline;
//         reward = _reward;
//         votesRequired = _votesRequired
//         status = _status;
//     }

//     function closeProposal() public onlyOwner {}

//     function changeStatus(bool _status) public onlyOwner {
//         status = _status;
//     }
// }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// import "Proposal.sol";

// Description tags (age, nationality, location, profession, field of study))
// minimum Consensus token holding (locked for a time period or until user wants to drop off network)
// OR users can only interact with networks when a certain amount of value is held
contract User {
    address public ethAddress;
    string public username;
    Traits public traits;

    struct Traits {
        uint8 age;
        // string country;
        // bool sex;
        // string ethnicity;
        // string occupation;
        // string areaOfStudy;
        // string[] languages;
    }

    constructor(
        address _ethAddress,
        string memory _username,
        uint8 _age
    ) {
        ethAddress = _ethAddress;
        username = _username;
        traits = Traits(_age);
    }
}