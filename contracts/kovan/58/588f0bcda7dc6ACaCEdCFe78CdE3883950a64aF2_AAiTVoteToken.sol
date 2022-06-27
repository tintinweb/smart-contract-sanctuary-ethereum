// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./AAiTElection.sol";

contract AAiTVoteToken is ERC20, BaseRelayRecipient {
    address public owner;
    address private AAiTElectionAddress;
    modifier onlyOwner() {
        require(
            owner == msg.sender || msg.sender == AAiTElectionAddress,
            "This function is restricted to the contract's owner"
        );
        _;
    }

    function mint(uint256 supply) public onlyOwner {
        _mint(_msgSender(), supply);
    }

    function transfer(address to, uint256 amount)
        public
        override
        onlyOwner
        returns (bool)
    {
        require(amount <= 2, "Invalid Operation");

        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override onlyOwner returns (bool) {
        require(amount == 1, "Invalid Operation");
        _transfer(from, to, amount);
        return true;
    }

    function burn(address tokenOwner) public onlyOwner {
        if (balanceOf(tokenOwner) > 0) {
            _burn(tokenOwner, balanceOf(tokenOwner));
        }
    }

    function setAddresses(
        address _AAiTElectionAddress
    ) public onlyOwner {
        AAiTElectionAddress = _AAiTElectionAddress;
    }

    // function getRemainingToken(address voter) public view returns (uint256) {
    //     return balanceOf(voter);
    // }

    // constructor(address _trustedForwarder) ERC20("AAiT Vote", "VOT") {
    //     _mint(msg.sender, 1000);
    //     _setTrustedForwarder(_trustedForwarder);
    //     owner = msg.sender;
    // }

    constructor() ERC20("AAiT Vote", "VOT") {
        owner = msg.sender;
        // mint(1000);
        // _setTrustedForwarder(_trustedForwarder);
    }

    /**
     * OPTIONAL
     * You should add one setTrustedForwarder(address _trustedForwarder)
     * method with onlyOwner modifier so you can change the trusted
     * forwarder address to switch to some other meta transaction protocol
     * if any better protocol comes tomorrow or current one is upgraded.
     */
    function setTrustForwarder(address _trustedForwarder) public onlyOwner {
        _setTrustedForwarder(_trustedForwarder);
    }

    /**
     * Override this function.
     * This version is to keep track of BaseRelayRecipient you are using
     * in your contract.
     */
    function versionRecipient() external pure override returns (string memory) {
        return "1";
    }

    function _msgSender()
        internal
        view
        override(Context, BaseRelayRecipient)
        returns (address sender)
    {
        sender = BaseRelayRecipient._msgSender();
    }

    function _msgData()
        internal
        view
        override(Context, BaseRelayRecipient)
        returns (bytes memory)
    {
        return BaseRelayRecipient._msgData();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "./Candidate.sol";
// import "./Voter.sol";
import "./AAiTVoteToken.sol";

// import "./AAiTStudent.sol";
// import "./AAiTElectionHandler.sol";

library AAiTElectionLibrary {
    function contains(address[] memory array, address value)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    function indexOf(address[] memory array, address value)
        internal
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return i;
            }
        }
        return array.length;
    }

    function findLargest(uint256[] memory array)
        internal
        pure
        returns (uint256)
    {
        uint256 largest = 0;
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] > largest) {
                largest = array[i];
            }
        }
        return largest;
    }

    // function bytes32ToString(bytes32 _bytes32)
    //     internal
    //     pure
    //     returns (string memory)
    // {
    //     uint8 i = 0;
    //     while (i < 32 && _bytes32[i] != 0) {
    //         i++;
    //     }
    //     bytes memory bytesArray = new bytes(i);
    //     for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
    //         bytesArray[i] = _bytes32[i];
    //     }
    //     return string(bytesArray);
    // }
}

contract AAiTElection {
    enum DEPTARTMENT_TYPE {
        BIOMED,
        CHEMICAL,
        CIVIL,
        ELEC,
        MECHANICAL,
        SITE
    }
    enum ELECTION_STATUS {
        PENDING,
        ONGOING,
        COMPLETED
    }
    enum PHASE_NAME {
        REGISTRATION,
        REGISTRATION_BREAK,
        SECTION_ELECTION,
        SECTION_ELECTION_BREAK,
        BATCH_ELECTION,
        BATCH_ELECTION_BREAK,
        DEPARTMENT_ELECTION,
        COMPLETED
    }
    string[] private deptTypes = [
        "Biomedical Engineering",
        "Chemical Engineering",
        "Civil Engineering",
        "Electrical Engineering",
        "Mechanical Engineering",
        "Software Engineering"
    ];

    struct ElectionStruct {
        uint256 index;
        string name;
        ELECTION_STATUS status;
        uint256 startDate;
        uint256 endDate;
        address[] candidates;
        address[] winners;
        uint256 year;
        uint256 section;
        DEPTARTMENT_TYPE department;
    }
    struct ElectionPhase {
        PHASE_NAME phaseName;
        uint256 start;
        uint256 end;
    }

    ElectionPhase public phase;

    event LogCurrentElectionPhase(string currentPhase);

    struct ElectionResultStruct {
        string electionName;
        // string candidateFullName;
        // string candidateLName;
        // string candidateGName;
        address[] candidateAddress;
        // uint256 votes;
    }

    address private immutable owner;
    address[] private voted;
    address[] private blacklist;

    // address private AAiTVoteTokenAddress;
    // address private AAiTStudentAddress;
    // address private AAiTElectionTimerAddress;

    mapping(string => ElectionStruct) private electionStructsMapping;
    mapping(address => address[]) private voterToCandidatesMapping;
    // mapping(address => uint256) private voterRemainingVotesMapping;
    string[] private electionIndex;
    ElectionStruct[] private electionValue;
    ElectionStruct[] private completedElections;
    ElectionResultStruct[] private completedElectionResults;
    address[] tempWinners;

    // AAiTElectionHandler electionHandler;
    // AAiTElectionTimer electionTimer;
    // AAiTStudent student;
    AAiTVoteToken voteToken;

    // event LogNewElection(
    //     uint256 index,
    //     string name,
    //     ELECTION_STATUS status,
    //     string startDate,
    //     string endDate,
    //     address[] candidates,
    //     address[] winners,
    //     address[] voters,
    //     address[] voted,
    //     uint256 year,
    //     uint256 section,
    //     DEPTARTMENT_TYPE department
    // );
    // event LogUpdateElection(
    //     uint256 index,
    //     string name,
    //     ELECTION_STATUS status,
    //     string startDate,
    //     string endDate,
    //     address[] candidates,
    //     address[] winners,
    //     address[] voters,
    //     address[] voted,
    //     uint256 year,
    //     uint256 section,
    //     DEPTARTMENT_TYPE department
    // );

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(
        address _AAiTVoteTokenAddress // address _AAiTStudentAddress, // address _AAiTElectionTimerAddress
    ) {
        owner = msg.sender;
        // AAiTVoteTokenAddress = _AAiTVoteTokenAddress;
        // AAiTStudentAddress = _AAiTStudentAddress;
        // AAiTElectionTimerAddress = _AAiTElectionTimerAddress;
        // electionHandler = AAiTElectionHandler(AAiTElectionHandlerAddress);
        // electionTimer = AAiTElectionTimer(_AAiTElectionTimerAddress);
        // student = AAiTStudent(_AAiTStudentAddress);
        voteToken = AAiTVoteToken(_AAiTVoteTokenAddress);
        phase = ElectionPhase(PHASE_NAME.COMPLETED, 0, 0);
    }

    //  REGISTRATION,
    //     REGISTRATION_BREAK,
    //     SECTION_ELECTION,
    //     // SECTION_ELECTION_DONE,
    //     SECTION_ELECTION_BREAK,
    //     BATCH_ELECTION,
    //     BATCH_ELECTION_BREAK,
    //     // BATCH_ELECTION_DONE,
    //     DEPARTMENT_ELECTION,
    //     // DEPARTMENT_ELECTION_DONE,
    //     COMPLETED

    // function changeVal(string memory _newVal) internal {
    //     require(msg.sender == owner, "Only the owner can change the value");
    //     val = _newVal;
    //     // IERC20(token).transferFrom(msg.sender, address(this), amount);
    // }

    // function getPhaseEnd() public view returns (uint256) {
    //     return end;
    // }

    // function startTimer(uint256 _votingDuration, uint256 _breakDuration)
    //     public
    //     onlyOwner
    // {
    //     if (phase.phaseName == PHASE_NAME.COMPLETED) {
    //         votingDuration = _votingDuration;
    //         breakDuration = _breakDuration;
    //         phase = ElectionPhase(
    //             PHASE_NAME.REGISTRATION,
    //             block.timestamp,
    //             block.timestamp + votingDuration
    //         );
    //     }
    // }

    // function stopTimer() public onlyOwner {
    //     phase = ElectionPhase(PHASE_NAME.COMPLETED, 0, 0);
    // }
    function getCurrentPhase() public view returns (ElectionPhase memory) {
        return phase;
    }

    function changePhase(uint256 startDate, uint256 endDate) public onlyOwner {
        // require(msg.sender == owner, "Only the owner can change the phase");

        if (phase.phaseName == PHASE_NAME.DEPARTMENT_ELECTION) {
            phase = ElectionPhase(PHASE_NAME.COMPLETED, 0, 0);
            // changeVal("unos");
            return;
        } else if (phase.phaseName == PHASE_NAME.COMPLETED) {
            phase = ElectionPhase(PHASE_NAME.REGISTRATION, startDate, endDate);
            return;
        }
        // return uint(phase.phaseName)+1;
        phase.phaseName = PHASE_NAME(uint256(phase.phaseName) + 1);
        // phase.phaseName = PHASE_NAME.REGISTRATION_BREAK;
        phase.start = startDate;
        // phase.end = block.timestamp + _newEnd;
        phase.end = endDate;
    }

    function revertPhase(
        uint256 phaseName,
        uint256 startDate,
        uint256 endDate
    ) external onlyOwner {
        if (phaseName == uint256(phase.phaseName)) {
            return;
        } else {
            phase.phaseName = PHASE_NAME(uint256(phase.phaseName));
            phase.start = startDate;
            phase.end = endDate;
            return;
        }
    }

    // function getRemainingTime() external view returns (uint256) {
    //     if (phase.phaseName == PHASE_NAME.COMPLETED) {
    //         return 0;
    //     }
    //     return phase.end - block.timestamp;
    // }

    // ELECTION FUNCTIONS

    function findElectionByName(string memory _name)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < electionValue.length; i++) {
            if (
                keccak256(abi.encodePacked(electionValue[i].name)) ==
                keccak256(abi.encodePacked(_name))
            ) {
                return true;
            }
        }
        return false;
    }

    function findElectionByType(
        uint256 year,
        uint256 section,
        DEPTARTMENT_TYPE department
    ) private view returns (bool) {
        for (uint256 i = 0; i < electionValue.length; i++) {
            if (
                electionValue[i].year == year &&
                electionValue[i].section == section &&
                keccak256(abi.encodePacked(electionValue[i].department)) ==
                keccak256(abi.encodePacked(department))
            ) {
                return true;
            }
        }
        return false;
    }

    // function addElection(
    //     string memory name,
    //     ELECTION_STATUS status,
    //     string memory startDate,
    //     string memory endDate,
    //     address[] memory candidates,
    //     address[] memory voters,
    //     uint256 year,
    //     uint256 section,
    //     DEPTARTMENT_TYPE department
    // ) public {
    //     require(
    //         !findElectionByName(name) ||
    //             !findElectionByType(year, section, department),
    //         "exists"
    //     );

    //     uint256 index = allElections.length;
    //     address[] memory empty;
    //     electionStructsMapping[name] = ElectionStruct(
    //         allElections.length,
    //         name,
    //         status,
    //         startDate,
    //         endDate,
    //         candidates,
    //         empty,
    //         voters,
    //         empty,
    //         year,
    //         section,
    //         department
    //     );
    //     allElections.push(
    //         ElectionStruct({
    //             index: allElections.length,
    //             name: name,
    //             status: status,
    //             startDate: startDate,
    //             endDate: endDate,
    //             candidates: candidates,
    //             winners: empty,
    //             voters: voters,
    //             voted: empty,
    //             year: year,
    //             section: section,
    //             department: department
    //         })
    //     );
    // }

    // function setElectionHandler(address _AAiTElectionHandlerAddress)
    //     public
    //     onlyOwner
    // {
    //     electionHandler = AAiTElectionHandler(_AAiTElectionHandlerAddress);
    // }

    function createElection(
        string memory name,
        uint256 startDate,
        uint256 endDate,
        address[] memory candidates,
        uint256 year,
        uint256 section,
        DEPTARTMENT_TYPE department
    ) external {
        address[] memory empty;
        // electionStructsMapping[name].name =

        require(
            !findElectionByName(name) &&
                !findElectionByType(year, section, department),
            "Election Already Exists"
        );
        electionIndex.push(name);
        ElectionStruct memory tempElection = ElectionStruct(
            electionIndex.length - 1,
            name,
            ELECTION_STATUS.ONGOING,
            startDate,
            endDate,
            candidates,
            empty,
            year,
            section,
            department
        );
        electionStructsMapping[name] = tempElection;
        electionValue.push(tempElection);
        // emit LogNewElection(electionStruct);

        // return electionStruct;
        // revert("Invalid Operation");
        // return true;
    }

    // function retrieveElections() public {
    //     // allElections = ;
    //     delete allElections;
    //     delete electionIndex;
    //     delete electionValue;
    //     // delete electionStructsMapping;
    //     ElectionStruct[] memory temp = electionHandler.getPendingElections();
    //     for (uint256 i = 0; i < temp.length; i++) {
    //         electionStructsMapping[temp[i].name] = temp[i];
    //         allElections.push(temp[i]);
    //         electionIndex.push(temp[i].name);
    //         electionValue.push(temp[i]);
    //         // electionStructsMapping[allElections[i].name] = allElections[i];
    //         // electionIndex.push(allElections[i].name);
    //         // electionValue.push(allElections[i]);
    //     }
    // }

    // function removeElection(string memory name) internal onlyOwner {
    //     require(findElectionByName(name), "No Election");
    // uint256 rowToDelete = electionStructsMapping[name].index;
    // // string memory keyToMove = electionIndex[electionIndex.length - 1];
    // electionIndex[electionStructsMapping[name].index] = electionIndex[
    //     electionIndex.length - 1
    // ];
    // electionStructsMapping[electionIndex[electionIndex.length - 1]]
    //     .index = electionStructsMapping[name].index;

    // electionValue[electionStructsMapping[name].index] = electionValue[
    //     electionValue.length - 1
    // ];
    // electionValue[electionStructsMapping[name].index]
    //     .index = electionStructsMapping[name].index;
    // electionValue.pop();
    // electionIndex.pop();
    // delete allElections[electionStructsMapping[name].index];
    // previousElections.push(
    //     electionStructsMapping[electionIndex[electionIndex.length - 1]]
    // );
    // delete electionStructsMapping[electionIndex[electionIndex.length - 1]];
    // }

    function vote(address voterAddress, address candidateAddress)
        public
        onlyOwner
    {
        // AAiTVoteToken tempToken = AAiTVoteToken(AAiTVoteTokenAddress);
        // AAiTStudent student = AAiTStudent(AAiTStudentAddress);
        // AAiTStudent.VoterStruct memory tempVoter = student.getVoter(
        //     voterAddress
        // );
        // require(voterAddress != address(0), "Invalid Address");
        // require(candidateAddress != address(0), "Invalid Address");
        require(
            voterAddress != owner && candidateAddress != owner,
            "Invalid Operation"
        );
        require(
            voterToCandidatesMapping[voterAddress].length < 2,
            "Voter Already Voted"
        );
        require(
            !AAiTElectionLibrary.contains(blacklist, candidateAddress),
            "Candidate Disqualified"
        );
        require(
            !AAiTElectionLibrary.contains(
                voterToCandidatesMapping[voterAddress],
                candidateAddress
            ),
            "Already Voted For This Candidate"
        );
        // require()

        require(voteToken.balanceOf(voterAddress) > 0, "Insufficient Token");

        for (uint256 i = 0; i < electionValue.length; i++) {
            if (
                AAiTElectionLibrary.contains(
                    electionValue[i].candidates,
                    candidateAddress
                )
            ) {
                if (electionValue[i].status == ELECTION_STATUS.ONGOING) {
                    if (
                        AAiTElectionLibrary.contains(
                            electionValue[i].candidates,
                            voterAddress
                        )
                    ) {
                        candidateVote(voterAddress, candidateAddress);
                        voterToCandidatesMapping[voterAddress].push(
                            candidateAddress
                        );
                        voted.push(voterAddress);
                    } else {
                        require(
                            voterAddress != candidateAddress,
                            "Invalid Operation"
                        );
                        voteToken.transferFrom(
                            voterAddress,
                            candidateAddress,
                            1
                        );
                        voterToCandidatesMapping[voterAddress].push(
                            candidateAddress
                        );

                        voted.push(voterAddress);
                    }

                    return;
                } else {
                    revert("Invalid Phase");
                }
            }
            continue;
        }

        revert("Couldn't Vote");

        // require(
        //     ,
        //     "You have already voted"
        // );
        // moveToVoted(
        //     voterAddress,
        //     getElectionByType(
        //         tempVoter.voterInfo.voterInfo.currentYear,
        //         tempVoter.voterInfo.voterInfo.currentSection,
        //         DEPTARTMENT_TYPE(
        //             uint256(tempVoter.voterInfo.voterInfo.currentDepartment)
        //         )
        //     ).name
        // // );
        // string memory tempName = getElectionByType(
        //     tempVoter.voterInfo.voterInfo.currentYear,
        //     tempVoter.voterInfo.voterInfo.currentSection,
        //     DEPTARTMENT_TYPE(
        //         uint256(tempVoter.voterInfo.voterInfo.currentDepartment)
        //     )
        // ).name;

        // // electionStructsMapping[tempName].voted.push(voterAddress);
        // delete electionStructsMapping[electionName].voters[index];
        // uint256 index = electionStructsMapping[electionName].index;
        // electionValue[electionStructsMapping[tempName].index]
        //     .voted = electionStructsMapping[tempName].voted;
        // allElections[electionStructsMapping[tempName].index]
        //     .voted = electionStructsMapping[tempName].voted;
    }

    function candidateVote(address voterAddress, address candidateAddress)
        public
        onlyOwner
    {
        // AAiTVoteToken tempToken = AAiTVoteToken(AAiTVoteTokenAddress);
        voteToken.mint(1);
        voteToken.transfer(voterAddress, 1);
        voteToken.transferFrom(voterAddress, candidateAddress, 1);
    }

    // function moveToVoted(address voterAddress, address candidateAddress)
    //     internal
    //     onlyOwner
    // {
    //     if (voterRemainingVotesMapping[voterAddress] == 0) {
    //         voted.push(voterAddress);
    //     }
    // }

    // AAiTVoteToken tempToken = AAiTVoteToken(AAiTVoteTokenAddress);

    function extendPhase(uint256 endDate) external onlyOwner {
        phase.end = endDate;        
    }

    function extendElection(string memory electionName, uint256 endDate) external onlyOwner {
        electionStructsMapping[electionName].endDate = endDate;
        electionValue[electionStructsMapping[electionName].index].endDate = endDate;
    }

    function pauseElection(string memory electionName) external onlyOwner {
        electionStructsMapping[electionName].status = ELECTION_STATUS.PENDING;
        electionValue[electionStructsMapping[electionName].index].status = ELECTION_STATUS.PENDING;
    }

    function startElection(string memory electionName) external onlyOwner {
        electionStructsMapping[electionName].status = ELECTION_STATUS.ONGOING;
        electionValue[electionStructsMapping[electionName].index].status = ELECTION_STATUS.ONGOING;
    }

    function completeElection(string memory electionName) public onlyOwner {
        electionStructsMapping[electionName].status = ELECTION_STATUS.COMPLETED;
        electionValue[electionStructsMapping[electionName].index].status = ELECTION_STATUS.COMPLETED;
    }    

    function endElection(string memory electionName) public onlyOwner {
        // electionStructsMapping[electionName].status = ELECTION_STATUS.ENDED;
        // electionValue[electionStructsMapping[electionName].index]
        //     .status = ELECTION_STATUS.ENDED;
        require(findElectionByName(electionName), "Election Does Not Exist");
        declareWinner(electionName);
        // completedElections.push(electionStructsMapping[electionName]);
        // completedElectionResults.push(
        //     ElectionResultStruct(
        //         electionName,
        //         getElectionByName(electionName).candidates
        //     )
        // );
        // removeElection(electionName);
    }

    function removeElection(string memory electionName) public onlyOwner {        
        require(findElectionByName(electionName), "Election Does Not Exist");

        uint256 rowToDelete = electionStructsMapping[electionName].index;
        string memory keyToMove = electionIndex[electionIndex.length - 1];
        electionIndex[rowToDelete] = keyToMove;
        electionStructsMapping[keyToMove].index = rowToDelete;
        electionIndex.pop();
        electionValue[rowToDelete] = electionValue[electionValue.length - 1];
        electionValue.pop();
    }

    function removeVotesRemainingForVoters(address[] memory voters) public onlyOwner {
        for (uint256 i = 0; i < voters.length; i++) {
            delete voterToCandidatesMapping[voters[i]];
            if(AAiTElectionLibrary.contains(voted, voters[i])){
                delete voted[AAiTElectionLibrary.indexOf(voted, voters[i])];
            }
        }

    }

    function removeAllCompletedElections() external onlyOwner {
        delete completedElections;
        // delete electionStructsMapping;
        delete electionValue;
        delete electionIndex;
        // delete voterRemainingVotesMapping;
        for (uint256 i = 0; i < voted.length; i++) {
            delete voterToCandidatesMapping[voted[i]];
        }
        delete voted;
    }

    function declareWinner(string memory electionName) internal {
        // AAiTVoteToken tempToken = AAiTVoteToken(AAiTVoteTokenAddress);
        ElectionStruct memory temp = electionStructsMapping[electionName];
        delete tempWinners;
        uint256[] memory tempVoteCount = new uint256[](temp.candidates.length);
        for (uint256 i = 0; i < temp.candidates.length; i++) {
            tempVoteCount[i] = voteToken.balanceOf(temp.candidates[i]);
            // tempVoteCount.push(tempToken.balanceOf(temp.candidates[i]));
        }
        uint256 max = AAiTElectionLibrary.findLargest(tempVoteCount);
        for (uint256 i = 0; i < temp.candidates.length; i++) {
            if (tempVoteCount[i] == max) {
                // winners[i] = temp.candidates[i];
                tempWinners.push(temp.candidates[i]);
            }
        }

        temp.winners = tempWinners;
        temp.status = ELECTION_STATUS.COMPLETED;

        electionStructsMapping[electionName] = temp;
        electionValue[electionStructsMapping[electionName].index] = temp;
        // allElections[electionStructsMapping[electionName].index] = temp;

        // sort candidates
        // uint256[] memory sortedCandidates = temp.candidates;

        // removeElection(electionName);

        // uint256 index = electionStructsMapping[electionName].index;
        // uint256 winnerIndex = electionStructsMapping[electionName].winners.length;
        // electionStructsMapping[electionName].winners.push(electionStructsMapping[electionName].candidates[winnerIndex]);
    }

    function blacklistCandidate(address candidateAddress) public onlyOwner {
        // AAiTStudent student = AAiTStudent(AAiTStudentAddress);
        // AAiTStudent.CandidateStruct memory tempCandidate = student.getCandidate(
        //     candidateAddress
        // );
        // ElectionStruct[] memory tempElection = allElections;
        require(
            !AAiTElectionLibrary.contains(blacklist, candidateAddress),
            "Candidate already blacklisted"
        );
        for (uint256 i = 0; i < electionValue.length; i++) {
            if (
                AAiTElectionLibrary.contains(
                    electionValue[i].candidates,
                    candidateAddress
                )
            ) {
                uint256 index = AAiTElectionLibrary.indexOf(
                    electionValue[i].candidates,
                    candidateAddress
                );

                // require(index < electionValue[i].candidates.length);
                electionValue[i].candidates[index] = electionValue[i]
                    .candidates[electionValue[i].candidates.length - 1];
                electionValue[i].candidates.pop();
                electionStructsMapping[electionValue[i].name]
                    .candidates = electionValue[i].candidates;

                // student.removeCandidate(
                //     // tempCandidate.candidateInfo.candidateInfo.fName,
                //     // tempCandidate.candidateInfo.candidateInfo.lName,
                //     // tempCandidate.candidateInfo.candidateInfo.gName,
                //     candidateAddress
                // );

                blacklist.push(candidateAddress);
                // return true;
            }
        }
        // revert("Invalid Operation");
    }

    function burnAllTokens(address[] memory users) public onlyOwner {
        // AAiTVoteToken tempToken = AAiTVoteToken(AAiTVoteTokenAddress);
        // AAiTStudent tempStudent = AAiTStudent(AAiTStudentAddress);
        // AAiTStudent.CandidateStruct[] memory tempCandidate = student
        //     .getAllCandidates();
        // AAiTStudent.VoterStruct[] memory tempVoter = student.getAllVoters();
        for (uint256 i = 0; i < users.length; i++) {
            voteToken.burn(users[i]);
        }

        voteToken.burn(owner);
        // temp.burnRemainingTokens(owner);
    }

    function mintAndSendTokens(address[] memory voters) public onlyOwner {
        // AAiTVoteToken tempToken = AAiTVoteToken(AAiTVoteTokenAddress);
        // AAiTStudent tempStudent = AAiTStudent(AAiTStudentAddress);
        // AAiTStudent.VoterStruct[] memory tempVoters = student.getAllVoters();
        // uint256 totalTokenCount = tempVoters.length;
        voteToken.mint((voters.length) * 2);
        for (uint256 i = 0; i < voters.length; i++) {
            voteToken.transfer(voters[i], 2);
        }
    }

    // function endElection(string memory electionName) public onlyOwner {
    //     declareWinner(electionName);
    //     removeElection(electionName);
    // }

    // function getElectionResult(string memory electionName)
    //     public
    //     view
    //     returns (ElectionResultStruct[] memory)
    // {
    //     // ElectionStruct memory temp = electionStructsMapping[electionName];
    //     ElectionResultStruct[] memory result = new ElectionResultStruct[](
    //         electionStructsMapping[electionName].candidates.length
    //     );
    //     // AAiTVoteToken tempToken = AAiTVoteToken(AAiTVoteTokenAddress);
    //     // AAiTStudent student = AAiTStudent(AAiTStudentAddress);

    //     for (
    //         uint256 i = 0;
    //         i < electionStructsMapping[electionName].candidates.length;
    //         i++
    //     ) {
    //         AAiTStudent.CandidateStruct memory tempCandidate = student
    //             .getCandidate(
    //                 electionStructsMapping[electionName].candidates[i]
    //             );
    //         ElectionResultStruct memory tempResult = ElectionResultStruct(
    //             tempCandidate.candidateInfo.candidateInfo.fullName,
    //             // tempCandidate.candidateInfo.candidateInfo.lName,
    //             // tempCandidate.candidateInfo.candidateInfo.gName,
    //             electionStructsMapping[electionName].candidates[i],
    //             voteToken.balanceOf(
    //                 electionStructsMapping[electionName].candidates[i]
    //             )
    //         );
    //         result[i] = tempResult;
    //     }
    //     return result;
    // }

    // function goToNextPhase() public onlyOwner {
    //     AAiTElectionTimer.ElectionPhase memory tempPhase = electionTimer
    //         .getCurrentPhase();
    //     if (tempPhase.phaseName == AAiTElectionTimer.PHASE_NAME.REGISTRATION) {
    //         electionTimer.changePhase();
    //         // electionTimer.goToNextPhase();
    //     } else if (
    //         tempPhase.phaseName ==
    //         AAiTElectionTimer.PHASE_NAME.REGISTRATION_BREAK
    //     ) {
    //         electionTimer.changePhase();
    //         // electionHandler.generateElectionsPerPhase();
    //         // retrieveElections();
    //         // electionHandler.mintAndSendTokens();
    //     } else if (
    //         tempPhase.phaseName == AAiTElectionTimer.PHASE_NAME.SECTION_ELECTION
    //     ) {
    //         electionTimer.changePhase();
    //         electionHandler.endAllOngoingElections();
    //         electionHandler.burnAllTokens();
    //     } else if (
    //         tempPhase.phaseName ==
    //         AAiTElectionTimer.PHASE_NAME.SECTION_ELECTION_BREAK
    //     ) {
    //         electionTimer.changePhase();
    //         retrieveElections();
    //         electionHandler.mintAndSendTokens();
    //     } else if (
    //         tempPhase.phaseName == AAiTElectionTimer.PHASE_NAME.BATCH_ELECTION
    //     ) {
    //         electionTimer.changePhase();
    //         electionHandler.endAllOngoingElections();
    //         electionHandler.burnAllTokens();
    //     } else if (
    //         tempPhase.phaseName ==
    //         AAiTElectionTimer.PHASE_NAME.BATCH_ELECTION_BREAK
    //     ) {
    //         electionTimer.changePhase();
    //         retrieveElections();
    //         electionHandler.mintAndSendTokens();
    //     } else if (
    //         tempPhase.phaseName ==
    //         AAiTElectionTimer.PHASE_NAME.DEPARTMENT_ELECTION
    //     ) {
    //         electionTimer.changePhase();
    //         electionHandler.endAllOngoingElections();
    //         electionHandler.burnAllTokens();
    //     } else if (
    //         tempPhase.phaseName == AAiTElectionTimer.PHASE_NAME.COMPLETED
    //     ) {
    //         electionTimer.changePhase();
    //     } else {
    //         revert("Invalid Operation");
    //     }
    // }

    // function moveToVoted(address voterAddress, string memory electionName)
    //     private
    // {
    //     // uint256 index = electionStructsMapping[electionName].index;

    //     electionStructsMapping[electionName].voted.push(voterAddress);
    //     // delete electionStructsMapping[electionName].voters[index];
    //     // uint256 index = electionStructsMapping[electionName].index;
    //     electionValue[electionStructsMapping[electionName].index]
    //         .voted = electionStructsMapping[electionName].voted;
    //     // emit LogUpdateElection(
    //     //     index,
    //     //     electionStructsMapping[electionName].name,
    //     //     electionStructsMapping[electionName].status,
    //     //     electionStructsMapping[electionName].startDate,
    //     //     electionStructsMapping[electionName].endDate,
    //     //     electionStructsMapping[electionName].candidates,
    //     //     electionStructsMapping[electionName].winners,
    //     //     electionStructsMapping[electionName].voters,
    //     //     electionStructsMapping[electionName].voted,
    //     //     electionStructsMapping[electionName].year,
    //     //     electionStructsMapping[electionName].section,
    //     //     electionStructsMapping[electionName].department
    //     // );
    // }

    // GET FUNCTIONS

    function getVotesRemaining(address voterAddress)
        external
        view
        returns (uint256)
    {
        return voterToCandidatesMapping[voterAddress].length;
    }

    function getAllCurrentElections()
        public
        view
        returns (ElectionStruct[] memory)
    {
        return electionValue;
    }

    function getAllCompletedElections()
        public
        view
        returns (ElectionStruct[] memory)
    {
        return completedElections;
    }

    function getElectionByName(string memory electionName)
        public
        view
        returns (ElectionStruct memory)
    {
        require(findElectionByName(electionName), "Election not found");
        return electionStructsMapping[electionName];
    }

    function getElectionStatus(string memory electionName)
        public
        view
        returns (uint256 status)
    {
        require(findElectionByName(electionName), "Election not found");
        return uint256(electionStructsMapping[electionName].status);
    }

    function getElectionEndDate(string memory electionName)
        public
        view
        returns (uint256)
    {
        require(findElectionByName(electionName), "Election not found");
        return electionStructsMapping[electionName].endDate;
    }

    // function getElectionByType(
    //     uint256 year,
    //     uint256 section,
    //     DEPTARTMENT_TYPE department
    // ) public view returns (ElectionStruct memory result) {
    //     require(
    //         findElectionByType(year, section, department),
    //         "Election not found"
    //     );
    //     // AAiTElectionTimer electionTimer = AAiTElectionTimer(
    //     //     AAiTElectionTimerAddress
    //     // );
    //     // AAiTElection tempElection = AAiTElection(AAiTElectionAddress);
    //     // AAiTElection.ElectionStruct[] memory allElections = tempElection
    //     //     .getAllElections();
    //     // ElectionPhase memory phase = getCurrentPhase();
    //     if (
    //         phase.phaseName == PHASE_NAME.DEPARTMENT_ELECTION
    //         // ||
    //         // phase.phaseName ==
    //         // PHASE_NAME.DEPARTMENT_ELECTION_DONE
    //     ) {
    //         for (uint256 i = 0; i < electionValue.length; i++) {
    //             if (electionValue[i].department == department) {
    //                 return electionValue[i];
    //             }
    //         }
    //     } else if (
    //         phase.phaseName == PHASE_NAME.BATCH_ELECTION
    //         // ||
    //         // phase.phaseName ==
    //         // PHASE_NAME.BATCH_ELECTION_DONE
    //     ) {
    //         for (uint256 i = 0; i < electionValue.length; i++) {
    //             if (
    //                 electionValue[i].department == department &&
    //                 electionValue[i].year == year
    //             ) {
    //                 return electionValue[i];
    //             }
    //         }
    //     } else if (
    //         phase.phaseName == PHASE_NAME.SECTION_ELECTION
    //         // ||
    //         // phase.phaseName ==
    //         // PHASE_NAME.SECTION_ELECTION_DONE
    //     ) {
    //         for (uint256 i = 0; i < electionValue.length; i++) {
    //             if (
    //                 electionValue[i].department == department &&
    //                 electionValue[i].year == year &&
    //                 electionValue[i].section == section
    //             ) {
    //                 return electionValue[i];
    //             }
    //         }
    //     } else {
    //         revert("Invalid Operation");
    //     }
    // }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}