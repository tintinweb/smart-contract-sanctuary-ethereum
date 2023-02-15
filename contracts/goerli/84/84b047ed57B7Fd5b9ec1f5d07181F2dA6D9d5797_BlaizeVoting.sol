pragma solidity ^0.8.7;

import "./BlaizePassport.sol";

contract BlaizeVoting {
    struct VoteOption {
        string name;
    }

    struct Vote {
        string name;
        string[] options;
    }

    struct VoteOutcomeItem {
        mapping(address => bool) voters;
    }

    struct VoteOuctome {
        mapping(uint256 => VoteOutcomeItem) optionOutcomes;
    }

    uint256 lastVote = 0;
    address public owner;
    Vote[] public votes;
    mapping(uint256 => VoteOuctome) voteOuctomes;


    function create(string memory name, string[] memory options) public onlyPasspoerVerified returns (uint256) {
        Vote memory createdVote = Vote(name, options);
        votes.push(createdVote);
        lastVote += 1;

        return lastVote - 1;
    }


    modifier onlyPasspoerVerified() {
        BlaizePassport.Person memory verification = BlaizePassport(0x0AabFAc4cd0841E54E10fd9C97cF9A506080ad38).getPerson(msg.sender);
        require(verification.isValue, "Person not registered");
        require(verification.verified, "Person not verified");
        _;
    }
}

pragma solidity ^0.8.7;


contract BlaizePassport {

    struct Person {
        string firstName;
        string secondName;
        string governmentId;
        bool verified;
        bool isValue;
    }

    address public owner;

    mapping(address => Person) public persons;
    mapping(address => bool) public verifiers;
    
    event UserRegistred(address userAddr);
    event UserVerified(address userAddr, address verifierAddr);

    constructor() {
        owner = msg.sender; 
        verifiers[msg.sender] = true;
    }

    function register(string memory firstName, string memory secondName, string memory governmentId) public {
        persons[msg.sender] = Person(firstName, secondName, governmentId, false, true);
        emit UserRegistred(msg.sender);
    }

    function getPerson(address _addr) public view returns (Person memory) {
        return persons[_addr];
    }

    function markVerified(address _addr) public onlyVerifier {
        if (!persons[_addr].isValue) {
            revert("Person not registered");
        }
        persons[_addr].verified = true;
        emit UserVerified(_addr, msg.sender);
    }

    function addVerifier(address _addr) public onlyOwner {
        verifiers[_addr] = true;
    }


    modifier onlyOwner() {
        require(msg.sender==owner, "caller is not owner");
        _;
    }

    modifier onlyVerifier() {
        require(verifiers[msg.sender], "caller is not verifier");
        _;
    }
}