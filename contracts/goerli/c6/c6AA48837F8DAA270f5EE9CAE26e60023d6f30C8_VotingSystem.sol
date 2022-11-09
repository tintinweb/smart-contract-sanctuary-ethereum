// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract VotingSystem {
    struct Voter {
        string name;
        string surname;
        string PESEL; // Identity number
        int256 age; // to check if in proper age to vote
        bool allowedToVote; // voted or not ? Or does his rights to vote exist?
    }

    struct Candidate {
        string name;
        uint256 receivedVotes; // which place candidate took after finished voting
    }

    address public electionChief;
    bool public electionOpen;

    mapping(string => Voter) public voters; // voter's PESEL => Voter ---- consider using a list of voters indexed by int(PESEL)
    mapping(string => Candidate) public candidates; // candidate's name => Candidate

    Candidate[] public listOfCandidates;

    constructor() {
        electionChief = msg.sender;
        electionOpen = true;

        initializeVoters();
        initializeCandidates();
    }

    function vote(
        string memory voterName,
        string memory voterSurname,
        string memory voterPESEL,
        string memory candidateName
    ) public {
        require(electionOpen, "Election is closed!");
        require(
            verifyVoter(voterName, voterSurname, voterPESEL),
            "Voter didn't fulfills requirements!"
        );
        voters[voterPESEL].allowedToVote = false;
        candidates[candidateName].receivedVotes += 1;
    }

    function verifyVoter(
        string memory voterName,
        string memory voterSurname,
        string memory voterPESEL
    ) public view returns (bool voterEligible) {
        Voter memory currentVoter = voters[voterPESEL];
        require(
            isTheSameString(currentVoter.PESEL, voterPESEL),
            "This person doesn't exists in voters database!"
        );
        require(
            isTheSameString(currentVoter.name, voterName),
            "The name of the person is not correct!"
        );
        require(
            isTheSameString(currentVoter.surname, voterSurname),
            "The surname of the person is not correct!"
        );
        require(currentVoter.age >= 18, "The person is not an adult!");
        require(
            currentVoter.allowedToVote,
            "The person is not allowed to vote!"
        );
        return true; // Check if this won't work if required aren't fulfilled!!!
    }

    modifier onlyOwner() {
        require(msg.sender == electionChief, "Not the contract owner!");
        _;
    }

    function finishElection() public onlyOwner {
        electionOpen = false;
        listOfCandidates[0].receivedVotes = candidates["Kandydat 1"]
            .receivedVotes;
        listOfCandidates[1].receivedVotes = candidates["Kandydat 2"]
            .receivedVotes;
        listOfCandidates[2].receivedVotes = candidates["Kandydat 3"]
            .receivedVotes;
    }

    function initializeCandidates() internal {
        listOfCandidates.push(
            Candidate({name: "Kandydat 1", receivedVotes: 0})
        );
        listOfCandidates.push(
            Candidate({name: "Kandydat 2", receivedVotes: 0})
        );
        listOfCandidates.push(
            Candidate({name: "Kandydat 3", receivedVotes: 0})
        );
        candidates["Kandydat 1"] = listOfCandidates[0];
        candidates["Kandydat 2"] = listOfCandidates[1];
        candidates["Kandydat 3"] = listOfCandidates[2];
    }

    function initializeVoters() internal {
        voters["00223390432"] = Voter({
            name: "Jan",
            surname: "Kowalski",
            PESEL: "00223390432",
            age: 22,
            allowedToVote: true
        });
        voters["90022074332"] = Voter({
            name: "Halina",
            surname: "Nowak",
            PESEL: "90022074332",
            age: 32,
            allowedToVote: true
        });
        voters["93031065465"] = Voter({
            name: "Ludwik",
            surname: "Montgommery",
            PESEL: "93031065465",
            age: 29,
            allowedToVote: true
        });
        voters["80030485668"] = Voter({
            name: "Katarzyna",
            surname: "Mak",
            PESEL: "80030485668",
            age: 42,
            allowedToVote: true
        });
        voters["91080196662"] = Voter({
            name: "Joanna",
            surname: "Zych",
            PESEL: "91080196662",
            age: 31,
            allowedToVote: true
        });
        voters["01302417347"] = Voter({
            name: "Monika",
            surname: "Grabowska",
            PESEL: "01302417347",
            age: 21,
            allowedToVote: true
        });
        voters["00221724457"] = Voter({
            name: "Dariusz",
            surname: "Duda",
            PESEL: "00221724457",
            age: 22,
            allowedToVote: true
        });
        voters["11301926436"] = Voter({
            name: "Karol",
            surname: "Nowak",
            PESEL: "11301926436",
            age: 11,
            allowedToVote: false
        });
    }

    function isTheSameString(string memory stringOne, string memory stringTwo)
        public
        pure
        returns (bool)
    {
        // Compare string keccak256 hashes to check equality
        if (
            keccak256(abi.encodePacked(stringOne)) ==
            keccak256(abi.encodePacked(stringTwo))
        ) {
            return true;
        }
        return false;
    }

    // Found Function - maybe will be usefull in aim to index listOfCandidates by PESEL
    /*
    function st2num(string memory numString) public pure returns(uint) {
        uint  val=0;
        bytes   memory stringBytes = bytes(numString);
        for (uint  i =  0; i<stringBytes.length; i++) {
            uint exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
           uint jval = uval - uint(0x30);
   
           val +=  (uint(jval) * (10**(exp-1))); 
        }
      return val;
    }
    */
}