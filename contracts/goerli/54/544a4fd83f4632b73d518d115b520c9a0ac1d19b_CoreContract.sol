// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import "forge-std/Vm.sol";
// import "forge-std/console2.sol";
// import "forge-std/Test.sol";
import "./VotingPower.sol";

struct SubmitMeRequirement {
    string videoUrl;
    string[] countries;
}

contract CoreContract {
    mapping(string => VotingPower) public countries;
    uint256 public neededVoteToAllow;
    address[] public allowedToVote;
    address fakeWorldCoin;
    string[] private countriesToIterate;

    constructor(
        address[] memory _allowedToVote,
        uint256 _neededVoteToAllow,
        address _fakeWorldCoin
    ) {
        allowedToVote = _allowedToVote;
        neededVoteToAllow = _neededVoteToAllow;
        fakeWorldCoin = _fakeWorldCoin;
    }

    function addWallet(address _walletToAdd) external {
        allowedToVote.push(_walletToAdd);
        for (uint256 i = 0; i < countriesToIterate.length; i++) {
            string memory country = countriesToIterate[i];
            VotingPower votingPower = countries[country];
            votingPower.addWallet(_walletToAdd);
        }
    }

    function submitRequirement(SubmitMeRequirement memory _submitRequirement)
        public
    {
        SubmitRequirement memory submitRequirement = SubmitRequirement(
            _submitRequirement.videoUrl,
            false,
            _submitRequirement.countries
        );

        for (uint256 i = 0; i < _submitRequirement.countries.length; i++) {
            string memory country = _submitRequirement.countries[i];

            VotingPower votingPower = countries[country];

            votingPower.submitRequirement(msg.sender, submitRequirement);
        }
    }

    function getCountries() public view returns (string[] memory) {
        return countriesToIterate;
    }

    function vote(
        string memory _country,
        address _addressToVote,
        bool _vote
    ) public {
        VotingPower votingPower = countries[_country];
        require(
            address(votingPower) != address(0),
            "The country does not exist"
        );

        votingPower.vote(msg.sender, _addressToVote, _vote);
    }

    function addNewCountry(string memory _country, uint256 _neededVoteToAllow)
        public
    {
        require(
            address(countries[_country]) == address(0),
            "You have already added this country"
        );
        VotingPower votinPower = new VotingPower(
            allowedToVote,
            _neededVoteToAllow,
            fakeWorldCoin,
            _country
        );
        countries[_country] = votinPower;
        countriesToIterate.push(_country);
    }

    function checkAllowed(
        string memory _country,
        string memory _biometricalData
    ) public returns (bool) {
        VotingPower votingPower = countries[_country];
        require(
            address(votingPower) != address(0),
            "The country is not in the list"
        );
        return votingPower.allowed(_biometricalData);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import "forge-std/Vm.sol";
// import "forge-std/console2.sol";
// import "forge-std/Test.sol";

struct SubmitRequirement {
    string videoUrl;
    bool subimted;
    string[] countries;
}

struct Vote {
    address votedBy;
    bool vote;
}

interface IFakeWorldCoin {
    function balanceByBiometricalData(string memory _hashOfBiometricalData)
        external
        returns (uint256);

    function biometricalData(string memory _biometricalData)
        external
        returns (address);

    function balanceOf(address owner) external view returns (uint256);
}
struct RequirementToVote {
    string videoUrl;
    address submitedBy;
    address votingPower;
    string country;
}

contract VotingPower {
    mapping(address => bool) public allowedToVote;
    mapping(address => SubmitRequirement) public requirements;
    mapping(address => Vote[]) public requirementsVoted;
    address[] private requirementsList;
    uint256 public neededVoteToAllow;
    IFakeWorldCoin public fakeWorldCoin;
    string country;

    constructor(
        address[] memory _allowedToVote,
        uint256 _neededVoteToAllow,
        address _fakeWorldCoin,
        string memory _country
    ) {
        for (uint256 i = 0; i < _allowedToVote.length; i++) {
            address allowed = _allowedToVote[i];
            allowedToVote[allowed] = true;
        }
        neededVoteToAllow = _neededVoteToAllow;
        fakeWorldCoin = IFakeWorldCoin(_fakeWorldCoin);
        country = _country;
    }

    function getRequirements(address _toCheck)
        public
        view
        returns (SubmitRequirement memory)
    {
        return requirements[_toCheck];
    }

    function getRequirementsVotes(address _toCheck)
        public
        view
        returns (Vote[] memory)
    {
        return requirementsVoted[_toCheck];
    }

    function addWallet(address _walletToAdd) external {
        allowedToVote[_walletToAdd] = true;
    }

    function checkAlreadyVoted(address _requiredUser, address _voterToCheck)
        public
        returns (bool)
    {}

    function getAllRequirementsList() public view returns (address[] memory) {
        return requirementsList;
    }

    function alreadyVoted(address _voterToCheck, address _requirementWallet)
        public
        view
        returns (bool)
    {
        Vote[] memory votesToCheck = requirementsVoted[_requirementWallet];
        for (uint256 i = 0; i < votesToCheck.length; i++) {
            Vote memory vote = votesToCheck[i];
            if (vote.votedBy == _voterToCheck) {
                return true;
            }
        }
        return false;
    }

    function submitRequirement(
        address _fromRequirement,
        SubmitRequirement memory _submitRequirement
    ) public {
        require(!requirements[_fromRequirement].subimted);
        require(
            fakeWorldCoin.balanceOf(_fromRequirement) == 1,
            "This address does not have a WorldFakeCoin"
        );
        _submitRequirement.subimted = true;
        requirements[_fromRequirement] = _submitRequirement;
        requirementsList.push(_fromRequirement);
    }

    function vote(
        address _voteFrom,
        address _addressToVote,
        bool _vote
    ) external {
        require(allowedToVote[_voteFrom], "You can't  vote");

        require(
            requirements[_addressToVote].subimted,
            "There is not a requirement from this url"
        );

        Vote memory vote = Vote(_voteFrom, _vote);
        requirementsVoted[_addressToVote].push(vote);
    }

    function allowed(string memory _biometricalData) public returns (bool) {
        address addressToCheck = fakeWorldCoin.biometricalData(
            _biometricalData
        );
        Vote[] memory votes = requirementsVoted[addressToCheck];
        uint256 totalCount = 0;
        for (uint256 i = 0; i < votes.length; i++) {
            Vote memory vote = votes[i];
            if (vote.vote) {
                totalCount += 1;
            }
        }
        if (totalCount >= neededVoteToAllow) {
            return true;
        } else {
            return false;
        }
    }
}