//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract voting {
    address public owner;
    uint256 public startTime;
    uint256 public endTime;
    bool public _votingIsStarted;
    address payable[] private candidates;
    address[] private voters;

    event votingIsStarted(uint256 _timestamp);
    event voted(address _voter, address _candidate);
    event newCandidate(address _candidate);
    event votingIsEnded(uint256 _timestamp);

    // true if address has already voted and fale if hasn't
    mapping(address => bool) private boolOfVoters;
    // votings counter
    mapping(address => uint256) public amountOfVotingsForCandidate;
    // true if owner has added this address for candidates and false if hasn't
    mapping(address => bool) private isCandidateExists;

    constructor() {
        owner = msg.sender;
        startTime = block.timestamp;
        endTime = startTime + 259200;
        _votingIsStarted = true;
        emit votingIsStarted(startTime);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner");
        _;
    }

    function vote(address candidate, address voter) external payable {
        require(_votingIsStarted, "This voting hasn't started yet");
        require(!boolOfVoters[voter], "You can vote only once in this voting");
        require(msg.value == 0.01 ether, "For vote you must pay 0.01 ETH");
        require(
            isCandidateExists[candidate],
            "There is no candidate with this address in this voting"
        );

        boolOfVoters[voter] = true;
        amountOfVotingsForCandidate[candidate]++;
        voters.push(voter);
        emit voted(voter, candidate);
    }

    function endVoting() public payable {
        require(_votingIsStarted, "This voting hasn't started yet");
        require(
            block.timestamp >= endTime,
            "It hasn't been three days yet since this voting started"
        );
        _votingIsStarted = false;
        uint256 num;
        address payable winningCandidate;
        for (uint256 i = 0; i < candidates.length; i++) {
            if (amountOfVotingsForCandidate[candidates[i]] > num) {
                num = amountOfVotingsForCandidate[candidates[i]];
                winningCandidate = candidates[i];
            }
        }
        winningCandidate.transfer(((address(this).balance) / 100) * 90);
        emit votingIsEnded(endTime);
    }

    function addCandidate(address payable addressOfCandidate) public onlyOwner {
        require(
            !isCandidateExists[addressOfCandidate],
            "This address already exists in this voting"
        );
        isCandidateExists[addressOfCandidate] = true;
        candidates.push(addressOfCandidate);
        emit newCandidate(addressOfCandidate);
    }

    function withdrawCommission(address payable _address)
        public
        payable
        onlyOwner
    {
        require(!_votingIsStarted, "This voting hasn't ended yet");
        _address.transfer(address(this).balance);
    }

    function returnVoters() public view returns (address[] memory) {
        return voters;
    }
}

contract votingFactory {
    address owner;

    event newVotingCreated(string _nameOfVoting, address _addressOfVoting);
    event votingEnded(string _nameOfVoting, address _addressOfVoting);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner");
        _;
    }

    struct votingStruct {
        string _nameOfVoting;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    // address of voting => voting information
    mapping(voting => votingStruct) public votingInfo;

    voting[] private createdVotings;

    function newVoting(string memory name) external onlyOwner {
        voting v = new voting();
        votingInfo[v] = votingStruct(name, v.startTime(), v.endTime());
        createdVotings.push(v);
        emit newVotingCreated(name, address(v));
    }

    function addCandidate(
        address addressOfVoting,
        address payable addressOfCandidate
    ) external onlyOwner {
        voting v = voting(addressOfVoting);
        v.addCandidate(addressOfCandidate);
    }

    function vote(address addressOfVoting, address payable addressOfCandidate)
        external
        payable
    {
        voting v = voting(addressOfVoting);
        v.vote{value: msg.value}(addressOfCandidate, msg.sender);
    }

    function endVoting(address addressOfVoting) external {
        voting v = voting(addressOfVoting);
        v.endVoting();
        votingStruct memory vs = votingInfo[v];
        emit votingEnded(vs._nameOfVoting, addressOfVoting);
    }

    function withdrawCommission(address addressOfVoting, address payable to)
        external
        onlyOwner
    {
        voting v = voting(addressOfVoting);
        v.withdrawCommission(to);
    }

    function amountOfVotingsForCandidate(
        address addressOfVoting,
        address addressOfCandidate
    ) external view returns (uint256) {
        voting v = voting(addressOfVoting);
        return v.amountOfVotingsForCandidate(addressOfCandidate);
    }

    function returnVoters(address addressOfVoting)
        external
        view
        returns (address[] memory)
    {
        voting v = voting(addressOfVoting);
        return v.returnVoters();
    }

    function votingIsStarted(address addressOfVoting)
        external
        view
        returns (bool)
    {
        voting v = voting(addressOfVoting);
        return v._votingIsStarted();
    }

    function showCreatedVotings() external view returns (voting[] memory) {
        return createdVotings;
    }

    // return time remain for opportunity to end voting (in seconds)
    function timeToEndVoting(address addressOfVoting)
        external
        view
        returns (uint256)
    {
        voting v = voting(addressOfVoting);
        votingStruct memory vs = votingInfo[v];
        uint256 currentTimestamp = block.timestamp;
        uint256 timestampOfEnding = vs.endTimestamp;
        if (currentTimestamp < timestampOfEnding) {
            return timestampOfEnding - currentTimestamp;
        } else {
            return 0;
        }
    }
}