pragma solidity ^0.8.0;

contract voting {
    address public owner;
    uint256 private time;
    address payable[] private candidates;
    bool public votingIsStarted;
    address[] private voters;

    mapping(address => bool) private boolOfVoters;
    mapping(address => uint256) public amountOfVotingsForCandidate;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner");
        _;
    }

    function createVoting() public onlyOwner {
        require(votingIsStarted == false, "Voting is already started");
        time = block.timestamp;
        votingIsStarted = true;
    }

    function vote(address candidate) public payable {
        require(votingIsStarted == true, "Voting hasn't started yet");
        require(boolOfVoters[msg.sender] == false, "You can vote only once");
        require(
            msg.value == 10000000000000000,
            "For vote you must pay 0.01 ETH"
        );
        boolOfVoters[msg.sender] = true;
        bool flag;

        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidate == candidates[i]) {
                amountOfVotingsForCandidate[candidates[i]]++;
                flag = true;
                break;
            }
        }
        if (flag == false) {
            revert("There is no candidate with this address");
        }
        voters.push(msg.sender);
    }

    function endVoting() public payable {
        require(votingIsStarted == true, "Voting hasn't started yet");
        require(
            block.timestamp >= time + 259200,
            "It hasn't been three days yet"
        );
        votingIsStarted = false;
        uint256 num;
        address payable winningCandidate;
        for (uint256 i = 0; i < candidates.length; i++) {
            if (amountOfVotingsForCandidate[candidates[i]] > num) {
                num = amountOfVotingsForCandidate[candidates[i]];
                winningCandidate = candidates[i];
            }
        }
        winningCandidate.transfer(((address(this).balance) / 100) * 90);

        for (uint256 i = 0; i < voters.length; i++) {
            boolOfVoters[voters[i]] = false;
        }
    }

    function addCandidate(address payable addressOfCandidate) public onlyOwner {
        bool flag;
        for (uint256 i = 0; i < candidates.length; i++) {
            if (addressOfCandidate == candidates[i]) {
                flag = true;
                break;
            }
        }
        if (flag == false) {
            candidates.push(addressOfCandidate);
        } else {
            revert("This address already exists");
        }
    }

    function withdrawCommission(address payable _address)
        public
        payable
        onlyOwner
    {
        require(votingIsStarted == false, "Voting hasn't ended yet");
        _address.transfer(address(this).balance);
    }

    function returnCandidates() public view returns (address payable[] memory) {
        return candidates;
    }

    function returnVoters() public view returns (address[] memory) {
        return voters;
    }
}