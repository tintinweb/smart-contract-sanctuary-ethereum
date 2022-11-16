// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// import "Proposal.sol";
import "User.sol";

contract ConsensusNetwork {
    address public owner;
    User[] public users;
    string public networkName;

    // Proposal[] public openProposals;
    // Proposal[] public allProposals;

    struct Vote {
        string response;
    }

    constructor(string memory _networkName) {
        owner = msg.sender;
        networkName = _networkName;
    }

    // function addUser(address _user) public onlyOwner {}      These will be used in a private version of network
    // function removeUser(address _user) public onlyOwner {}

    function join(address _userAddress) public {
        User user = User(_userAddress);
        users.push(user);
    }

    function leave() public {}

    function depolyProposal() public onlyOwner {}

    function changeProposalStatus() public onlyOwner {}

    function distributeReward() public payable onlyOwner {}

    function vote() public {}

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.10;

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

//     modifier onlyOwner() {
//         require(msg.sender == owner);
//         _;
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

    // string[] public tags;

    constructor(
        address _ethAddress,
        string memory _username // string[] _tags;
    ) {
        ethAddress = _ethAddress;
        username = _username;
        // tags = _tags;
    }
}