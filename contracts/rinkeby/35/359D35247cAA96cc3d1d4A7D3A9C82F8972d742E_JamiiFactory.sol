// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.8;

import "IJamiiFactory.sol";
import "JamiiBase.sol";

contract JamiiFactory is IJamiiFactory, JamiiBase {
    Ballot[] private ballots;
    Voter[] private voters;

    // numbers
    uint256 private ballot_fee = 340000000000000000; // $
    uint256 private ballot_count;
    uint256[] private voter_ids;
    uint256[] internal ballot_types_arr = [0, 1, 2, 3, 4, 5, 6];
    uint256 internal ballot_types = ballot_types_arr.length;

    // mappings
    mapping(address => Ballot) private ballots_mapping;
    mapping(uint256 => Ballot) private id_to_ballot_mapping;
    mapping(uint256 => address[]) private ballot_candidate_mapping;
    mapping(uint256 => address[]) private ballot_voters_mapping;
    mapping(address => Candidate) private address_to_candidate_mapping;
    mapping(address => address[]) private chair_to_candidates;
    mapping(address => Voter) private address_to_voter_mapping;
    mapping(address => bytes32) private voter_to_unique_id;
    mapping(uint256 => address) private id_to_voter;
    mapping(address => uint256[]) private voter_to_ballots;
    mapping(address => uint256[]) private voted_to_ballots;
    mapping(uint256 => uint256[]) private voter_id_to_ballots;

    modifier only_voter(address _candidate, uint256 _ballot_id) {
        Ballot memory ballot = id_to_ballot_mapping[_ballot_id];
        require(
            address_to_voter_mapping[msg.sender].registered == true,
            "Please Register to Vote!"
        );
        require(
            !exists(voted_to_ballots[msg.sender], _ballot_id),
            "You already CAST your Vote in This Ballot!"
        );
        require(
            id_to_ballot_mapping[_ballot_id].ballot_id == _ballot_id,
            "Invalid Ballot Id!"
        );
        require(ballot.expired == false, "Ballot has Expired");
        require(
            address_to_candidate_mapping[_candidate].ballot_id == _ballot_id,
            "Candidate does not exist in Ballot!"
        );
        _;
    }

    modifier only_voter_closed_ballots(address _candidate, uint256 _ballot_id) {
        Ballot memory ballot = id_to_ballot_mapping[_ballot_id];
        Voter memory voter = address_to_voter_mapping[msg.sender];
        require(voter.rights == true, "No Voting Rights!");
        require(
            address_to_voter_mapping[msg.sender].registered == true,
            "Please Register to Vote!"
        );
        require(
            !exists(voted_to_ballots[msg.sender], _ballot_id),
            "You already CAST your Vote in This Ballot!"
        );
        require(
            id_to_ballot_mapping[_ballot_id].ballot_id == _ballot_id,
            "Invalid Ballot Id!"
        );
        require(ballot.expired == false, "Ballot has Expired");
        require(
            address_to_candidate_mapping[_candidate].ballot_id == _ballot_id,
            "Candidate does not exist in Ballot!"
        );
        _;
    }

    modifier only_secret_ballot(uint256 _ballot_id) {
        Ballot memory ballot = id_to_ballot_mapping[_ballot_id];
        require(ballot.ballot_type < 4, "This is a Secret Ballot!");
        _;
    }

    modifier only_register_voter(uint256 _id_number, uint256 _ballot_id) {
        Ballot memory ballot = id_to_ballot_mapping[_ballot_id];
        uint256 duration = (block.timestamp - ballot.open_date);
        uint256 n = ballots.length;
        require(n >= 1, "No such Ballot Exists!");
        // require(
        //     ballot.ballot_id <= ballots[n - 1].ballot_id,
        //     "No such Ballot Exists!"
        // );
        require(duration < (ballot._days * 86400), "This Ballot Expired!");
        require(
            !exists(voter_to_ballots[msg.sender], _ballot_id),
            "You are Registered in this Ballot!"
        );
        require(
            !exists(voter_id_to_ballots[_id_number], _ballot_id),
            "Your ID is Registered in this Ballot!"
        );
        require(
            (duration < (ballot.registration_window * 86400)),
            "Registration Period has Passed!"
        );
        _;
    }

    function initialize(string memory _arbitrary_text) public initializer {
        JamiiBase.initialize();
    }

    function exists(uint256[] memory _voter_ballots, uint256 _target)
        internal
        pure
        returns (bool)
    {
        uint256 n = _voter_ballots.length;
        for (uint256 i = 0; i < n; i++) {
            if (_voter_ballots[i] == _target) {
                return true;
            }
        }
        return false;
    }

    function create_ballot_type(
        uint256 _ballot_type,
        string memory _ballot_name
    ) public onlyOwner {
        require(
            _ballot_type > (ballot_types - 1) &&
                _ballot_type < (ballot_types + 1),
            "Invalid Type Index!"
        );
        ballot_types_arr.push(ballot_types + 1);
        ballot_types_mapping[_ballot_type] = _ballot_name;
    }

    function create_ballot(
        string memory _ballot_name,
        address[] memory _ballot_candidates_addr,
        uint256 _ballot_type,
        uint256 _days,
        uint256 _registration_period
    ) public payable {
        require(msg.value >= ballot_fee, "Insufficient funds!");
        bytes memory bytes_ballot_name = bytes(_ballot_name);
        require(bytes_ballot_name.length > 0, "Enter a valid Ballot Name!");
        require(
            _ballot_candidates_addr.length > 1,
            "Not Enough Ballot Candidates!"
        );
        require(_ballot_type <= ballot_types, "Not a valid Ballot Type!");
        require(
            _days > _registration_period,
            "Registration Period > Voting Days!"
        );
        require(_registration_period > 0, "Registration Period should be > 1!");

        ballot_candidate_mapping[uid] = _ballot_candidates_addr;

        uint256 n = _ballot_candidates_addr.length;
        for (uint256 i = 0; i < n; i++) {
            Candidate memory candidate = Candidate(
                candidates_count,
                uid,
                _ballot_candidates_addr[i],
                0
            );
            address_to_candidate_mapping[
                _ballot_candidates_addr[i]
            ] = candidate;
            candidates_count++;
        }

        Ballot memory new_ballot = Ballot(
            uid,
            _ballot_type,
            _ballot_name,
            msg.sender,
            0,
            block.timestamp,
            _days,
            false,
            _registration_period,
            address(0x0),
            false
        );
        id_to_ballot_mapping[uid] = new_ballot;
        ballots.push(new_ballot);
        ballots_mapping[msg.sender] = new_ballot;
        chair_to_candidates[msg.sender] = _ballot_candidates_addr;
        ballot_count++;
        uid++;

        emit created_ballot(_ballot_type);
    }

    // createBallot(_ballot_candidates)
    // ballot 0 -> ["0xf9d48aC9eC8F207AEF93518B51D2CdA61e596904", "0x6c0A17AEe0a1420583446B77f0c8a55e369Bb07e"]
    // ballot 1 -> ["0xa8d17cc9cAF29Af964d19267DDEb4dfF122697B0","0xA0341558519429f6A93475bA53AD319f99302bff"]
    // ballot 2 -> ["0x4A4eC531A0c952d76fdb0E1DC9561A893Cc3177c", "0xfA5C1650946124cB9ACBe478e6D37b5F6c1983D6"]
    // ballot 3 -> ["0x7ffC57839B00206D1ad20c69A1981b489f772031", "0x8E9a9f198d9d6457339A11b05A214F9aa78dbc8b"]
    // ballot 4 -> ["0xfA5C1650946124cB9ACBe478e6D37b5F6c1983D6", "0xfe3e6ab5d787f4099478bbe811a740d903e219fb"]
    // ballot 5 -> ballot 0
    // ballot 6 -> ballot 1

    /** REGISTERS VOTERS **/

    function create_voter_open_ballot(uint256 _id_number, uint256 _ballot_id)
        internal
    {
        Ballot storage ballot = id_to_ballot_mapping[_ballot_id];

        ballot_voters_mapping[_ballot_id].push(msg.sender);

        // id_number validation here
        bytes32 unique_voter_id = keccak256(abi.encode(_id_number));
        voter_to_unique_id[msg.sender] = unique_voter_id;

        Voter memory new_voter = Voter(
            ballot.voters_count,
            msg.sender,
            _ballot_id,
            true,
            true,
            false,
            unique_voter_id
        );
        address_to_voter_mapping[msg.sender] = new_voter;
        voters.push(new_voter);

        id_to_ballot_mapping[_ballot_id].voters_count++;

        id_to_voter[_id_number] = msg.sender;

        voter_to_ballots[msg.sender].push(_ballot_id);
        voter_id_to_ballots[_id_number].push(_ballot_id);

        emit registered_voter(unique_voter_id);
    }

    function create_voter_closed_ballot(uint256 _id_number, uint256 _ballot_id)
        internal
    {
        Ballot storage ballot = id_to_ballot_mapping[_ballot_id];

        ballot_voters_mapping[_ballot_id].push(msg.sender);

        // id_number validation here
        bytes32 unique_voter_id = keccak256(abi.encode(_id_number));
        voter_to_unique_id[msg.sender] = unique_voter_id;

        Voter memory new_voter = Voter(
            ballot.voters_count,
            msg.sender,
            _ballot_id,
            true,
            false,
            false,
            unique_voter_id
        );
        address_to_voter_mapping[msg.sender] = new_voter;
        voters.push(new_voter);

        id_to_ballot_mapping[_ballot_id].voters_count++;

        id_to_voter[_id_number] = msg.sender;

        voter_to_ballots[msg.sender].push(_ballot_id);
        voter_id_to_ballots[_id_number].push(_ballot_id);

        emit registered_voter(unique_voter_id);
    }

    function register_voter_open_ballot(uint256 _id_number, uint256 _ballot_id)
        internal
        only_register_voter(_id_number, _ballot_id)
    {
        Ballot storage ballot = id_to_ballot_mapping[_ballot_id];
        require(ballot.ballot_type == 0, "Wrong ballot Type!");

        create_voter_open_ballot(_id_number, _ballot_id);
    }

    function register_voter_closed_ballot(
        uint256 _id_number,
        uint256 _ballot_id
    ) internal only_register_voter(_id_number, _ballot_id) {
        Ballot storage ballot = id_to_ballot_mapping[_ballot_id];
        require(
            ballot.ballot_type == 1 || ballot.ballot_type == 4,
            "Wrong ballot Type!"
        );
        // require("You need to lock value in the Ballot! -> redistributed after ballot!");

        create_voter_closed_ballot(_id_number, _ballot_id);
    }

    // register voter closedPaidElection
    function register_voter_open_paid_ballot(
        uint256 _id_number,
        uint256 _ballot_id
    ) internal only_register_voter(_id_number, _ballot_id) {
        Ballot storage ballot = id_to_ballot_mapping[_ballot_id];
        require(
            ballot.ballot_type == 2 || ballot.ballot_type == 5,
            "Wrong ballot Type!"
        );
        // require("You need to lock value in the Ballot!");

        create_voter_open_ballot(_id_number, _ballot_id);
    }

    function register_voter_closed_paid_ballot(
        uint256 _id_number,
        uint256 _ballot_id
    ) internal only_register_voter(_id_number, _ballot_id) {
        Ballot storage ballot = id_to_ballot_mapping[_ballot_id];
        require(
            ballot.ballot_type == 3 || ballot.ballot_type == 6,
            "Wrong ballot Type!"
        );
        // require("You need to lock value in the Ballot!");

        create_voter_closed_ballot(_id_number, _ballot_id);
    }

    function register_voter(uint256 _id_number, uint256 _ballot_id)
        public
        only_register_voter(_id_number, _ballot_id)
    {
        Ballot memory ballot = id_to_ballot_mapping[_ballot_id];

        // 0, 1, 2, 3, 4, 5, 6 => open free, closed free, open paid, closed paid,
        if (ballot.ballot_type == 0) {
            register_voter_open_ballot(_id_number, _ballot_id);
        } else if (ballot.ballot_type == 1 || ballot.ballot_type == 4) {
            register_voter_closed_ballot(_id_number, _ballot_id);
        } else if (ballot.ballot_type == 2 || ballot.ballot_type == 5) {
            register_voter_open_paid_ballot(_id_number, _ballot_id);
        } else if (ballot.ballot_type == 3 || ballot.ballot_type == 6) {
            register_voter_closed_paid_ballot(_id_number, _ballot_id);
        }
    }

    /** VOTING RIGHTS **/
    function assign_voting_rights(address _voter, uint256 _ballot_id) public {
        require(
            msg.sender == get_ballot_owner(_ballot_id),
            "Insufficient Permissions!"
        );
        Ballot memory ballot = id_to_ballot_mapping[_ballot_id];

        uint256 n = ballots.length;
        require(
            ballot.ballot_id <= ballots[n - 1].ballot_id,
            "No such Ballot Exists!"
        );

        uint256 _ballot_type = ballot.ballot_type;
        require(ballot.expired == false, "This Ballot Expired!");

        require(
            _ballot_type == 1 ||
                _ballot_type == 3 ||
                _ballot_type == 4 ||
                _ballot_type == 6,
            "Not a Closed Ballot!"
        );
        require(
            address_to_voter_mapping[_voter].ballot_id == _ballot_id,
            "Voter CanNOT vote in this Ballot!"
        );
        require(
            address_to_voter_mapping[_voter].registered == true,
            "NOT a Registered Voter!"
        );
        require(
            address_to_voter_mapping[_voter].rights == false,
            "Already has Voting Rights!"
        );

        // closed paid ballot [3]
        // require voter has sufficient voting tokens for a ballot -> buy voting rights -> awaiting approval
        address_to_voter_mapping[_voter].rights = true;

        emit assigned_voting_rights(_voter);
    }

    // function buy_voting_rights(){

    // }

    function create_vote(address _candidate) internal {
        address_to_candidate_mapping[_candidate].vote_count++;
        address_to_voter_mapping[msg.sender].voted = true;
        emit voted(_candidate);
    }

    function vote_open_ballot(address _candidate, uint256 _ballot_id)
        internal
        only_voter(_candidate, _ballot_id)
    {
        // require("Need to have locked value in ballot during registration!")

        Ballot memory ballot = id_to_ballot_mapping[_ballot_id];
        ballot.current_winner = _candidate;
        find_winner(_candidate, ballot);
        create_vote(_candidate);
    }

    function vote_closed_free_ballot(address _candidate, uint256 _ballot_id)
        internal
        only_voter_closed_ballots(_candidate, _ballot_id)
    {
        Ballot memory ballot = id_to_ballot_mapping[_ballot_id];
        require(ballot.ballot_type == 1, "Wrong Ballot Type!");
        // require("Need to have locked value in ballot during registration!")

        ballot.current_winner = _candidate;
        find_winner(_candidate, ballot);
        create_vote(_candidate);
    }

    function vote_open_paid_ballot(address _candidate, uint256 _ballot_id)
        internal
        only_voter(_candidate, _ballot_id)
    {
        Ballot memory ballot = id_to_ballot_mapping[_ballot_id];
        require(ballot.ballot_type == 2, "Wrong Ballot Type!");
        // require("Enough tokens for This Vote")
        ballot.current_winner = _candidate;

        find_winner(_candidate, ballot);
        create_vote(_candidate);
    }

    function vote_closed_paid_ballot(address _candidate, uint256 _ballot_id)
        internal
        only_voter_closed_ballots(_candidate, _ballot_id)
    {
        // require(election_type == 2);
        Ballot memory ballot = id_to_ballot_mapping[_ballot_id];
        require(ballot.ballot_type == 3, "Wrong Ballot Type!");
        // require("Enough tokens for This Vote")

        ballot.current_winner = _candidate;
        find_winner(_candidate, ballot);
        create_vote(_candidate);
    }

    function vote(address _candidate, uint256 _ballot_id)
        public
        only_voter(_candidate, _ballot_id)
    {
        uint256 int_ballot_id = _ballot_id - 100;
        Ballot memory ballot = ballots[int_ballot_id];

        // 0, 1, 2, 3, 4, 5, 6 => open free, closed free, open paid, closed paid,
        if (ballot.ballot_type == 0) {
            vote_open_ballot(_candidate, _ballot_id);
            voted_to_ballots[msg.sender].push(_ballot_id);
        } else if (ballot.ballot_type == 1) {
            vote_closed_free_ballot(_candidate, _ballot_id);
            voted_to_ballots[msg.sender].push(_ballot_id);
        } else if (ballot.ballot_type == 2) {
            vote_open_paid_ballot(_candidate, _ballot_id);
            voted_to_ballots[msg.sender].push(_ballot_id);
        } else if (ballot.ballot_type == 3) {
            vote_closed_paid_ballot(_candidate, _ballot_id);
            voted_to_ballots[msg.sender].push(_ballot_id);
        }
    }

    /** GETTERS **/

    function get_ballot_owner(uint256 _ballot_id)
        public
        view
        only_secret_ballot(_ballot_id)
        returns (address)
    {
        return id_to_ballot_mapping[_ballot_id].chair;
    }

    function get_ballot(uint256 _ballot_id)
        public
        view
        only_secret_ballot(_ballot_id)
        returns (Ballot memory)
    {
        return id_to_ballot_mapping[_ballot_id];
    }

    function get_candidate(address _candidate_addr)
        public
        view
        only_secret_ballot(100)
        returns (Candidate memory)
    {
        return address_to_candidate_mapping[_candidate_addr];
    }

    function get_voter(address _voter_address, uint256 _ballot_id)
        public
        view
        only_secret_ballot(_ballot_id)
        returns (Voter memory)
    {
        return address_to_voter_mapping[_voter_address];
    }

    function get_candidates(uint256 _ballot_id)
        public
        view
        returns (address[] memory)
    {
        return ballot_candidate_mapping[_ballot_id];
    }

    function get_voters(uint256 _ballot_id)
        public
        view
        only_secret_ballot(_ballot_id)
        returns (address[] memory)
    {
        return ballot_voters_mapping[_ballot_id];
    }

    function find_winner(address _candidate, Ballot memory ballot)
        internal
        view
        returns (bool)
    {
        if (
            address_to_candidate_mapping[_candidate].vote_count + 1 >
            address_to_candidate_mapping[ballot.current_winner].vote_count
        ) {
            ballot.current_winner = _candidate;
            ballot.tie = false;
        } else if (
            address_to_candidate_mapping[_candidate].vote_count + 1 ==
            address_to_candidate_mapping[ballot.current_winner].vote_count
        ) {
            ballot.tie = true;
        }
        return ballot.tie;
    }

    function get_winner(uint256 _ballot_id)
        public
        only_secret_ballot(_ballot_id)
        returns (address)
    {
        Ballot memory ballot = id_to_ballot_mapping[_ballot_id];
        require(
            _ballot_id <= ballot_count,
            "Ballot with that Id does NOT exist!"
        );

        uint256 duration = (block.timestamp - ballot.open_date) / 60 / 60 / 24;
        require(duration > ballot._days, "This Ballot is NOT yet Expired!");

        if (ballot.tie == true) {
            emit tied_ballot(ballot.tie);
            return address(0x0);
        } else {
            address winner = ballot.current_winner;
            return winner;
        }
    }

    function end_ballot(uint256 _ballot_id) public {
        Ballot storage ballot = id_to_ballot_mapping[_ballot_id];

        uint256 duration = (block.timestamp - ballot.open_date) / 60 / 60 / 24;
        require(duration < ballot._days, "This Ballot is NOT yet Expired!");

        require(msg.sender == ballot.chair, "Insufficient Permissions!");

        ballot.expired = true;
        ballots_mapping[msg.sender].expired = true;
        id_to_ballot_mapping[_ballot_id].expired = true;

        emit ended_ballot(_ballot_id);
    }

    function withdraw() public onlyOwner {
        payable(fee_addr).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.8;

interface IJamiiFactory {
    /*
     * @dev ballot struct
     * @arg ballot_id A unique identification number for a ballot
     * @arg ballot_type An integer representing the type of ballot
     * @arg ballot_name The name of the ballot
     * @arg chair Address of the ballot creator/owner
     * @arg ballot_candidates Array of address of ballot candidates
     * @arg ballot_voters Registered voters of a ballot
     * @arg open The status of the Ballot, open/closed
     * @arg current_winner The current_winner of a Ballot
     * @arg tie True is there is a tie between candidates False otherwise
     */
    struct Ballot {
        uint256 ballot_id;
        uint256 ballot_type;
        string ballot_name;
        address chair;
        uint256 voters_count;
        uint256 open_date;
        uint256 _days;
        bool expired;
        uint256 registration_window;
        address current_winner;
        bool tie;
    }

    /*
     * @dev candidate struct
     * @arg candidate_id A unique identification number for a candidate
     * @arg ballot_id A unique identifier for a Ballot
     * @arg candidate_address The address of a candidate
     * @arg vote_count The number of votes a candidates has
     */
    struct Candidate {
        uint256 candidate_id;
        uint256 ballot_id;
        address candidate_address;
        uint256 vote_count;
        // implement other stats(party, funding)
    }

    /*
     * @dev voter struct
     * @arg voter_id A unique identification number for a candidate
     * @arg voter_address The address of a voter
     * @arg ballot_id A unique identifier for a Ballot
     * @arg registered A bool indicating whether the candidate is registered in Ballot
     * @arg rights A voter's voting rights in Ballot
     * @arg voted Status of a Voter, voted/not voted
     * @arg unique_voter_id A unique identifier for a voter in Ballot
     */
    struct Voter {
        uint256 voter_id;
        address voter_address;
        uint256 ballot_id;
        bool registered;
        bool rights;
        bool voted;
        bytes32 unique_voter_id;
        // implement other stats(voting weight, tokens)
    }

    /*
     * @dev Emitted when ballot_ownercreate a new Ballot with unique `_ballot_id`.
     */
    event created_ballot(uint256 _ballot_type);

    /*
     * @dev Emitted when `_voter` registers to vote.
     */
    event registered_voter(bytes32 _voter_unique_id);

    /*
     * @dev Emitted when `ballot_owner` assigns voting rights to `voter`.
     */
    event assigned_voting_rights(address _voter);

    /*
     * @dev Emitted when `_voter` casts a vote to `_candidate`.
     */
    event voted(address indexed _candidate);

    /*
     * @dev Emitted when there is a tie between `ballot_candidates` in a Ballot.
     */
    event tied_ballot(bool _tie);

    /*
     * @dev Emitted when a ballot chair ends a ballot with `_ballot_id`.
     */
    event ended_ballot(uint256 _ballot_id);

    /*
     * @dev creates a new open ballot
     * @param _ballot_name An arbitrary ballot name
     * @param _ballot_candidates An array of address of candidates participating in the ballot
     * @param _ballot_type The type of ballot, open, closed...
     *
     * @require:
     *  - ballot_candidates.length > 1
     *  - msg.sender == ballot_owner
     *  - creators pay ballot_cost
     *  - valid ballot_type <= ballot_types
     *  - ballots.length <= limit
     */
    function create_ballot(
        string memory _ballot_name,
        address[] memory _ballot_candidates,
        uint256 _ballot_type,
        uint256 _days,
        uint256 _registration_window
    ) external payable;

    function register_voter(uint256 _id_number, uint256 _ballot_id) external;

    /*
     * @dev assign voting rights
     * @param _voter A unique voter address
     * @param _ballot_id The Id of a specific ballot
     *
     * @require:
     *  - valid _ballot_id
     *  - ballot is still open
     *  - Ballots must exist
     *  - msg.sender == ballot_owner || msg.sender == authorized
     *  - msg.sender is registered voter in specified ballot
     *  - ballot_type >= 1
     *  - msg.sender == registered voter
     *  - voting_rights == None
     */
    function assign_voting_rights(address _voter, uint256 _ballot_id) external;

    /*
     * @dev voter votes for a candidate
     * @param _candidate The address of a candidate in the ballot
     *
     * @require:
     *  - ballot_type == 0(open)
     *  - msg.sender registered voter
     *  - msg.sender NOT voted
     *  - ballot is Open
     *  - _candidate is a valid candidate
     *  - ballot_id is valid
     */
    function vote(address _candidate, uint256 _ballot_id) external;

    /*
     * @dev msg.sender gets the owner of a ballot.
     * @param _ballot_id The unique Id of a Ballot!
     *
     * @require:
     *
     *
     *
     */
    function get_ballot_owner(uint256 _ballot_id)
        external
        view
        returns (address);

    /*
     * @dev msg.sender gets a ballot.
     * @param _ballot_id The unique Id of a Ballot!
     *
     * @require:
     *
     *
     *
     */
    function get_ballot(uint256 _ballot_id)
        external
        view
        returns (Ballot memory);

    /*
     * @dev msg.sender gets a candidate.
     * @param _candidate_addr The unique address of a Candidate!
     *
     * @require:
     *
     *
     *
     */
    function get_candidate(address _candidate_addr)
        external
        view
        returns (Candidate memory);

    /*
     * @dev msg.sender gets a voter of a ballot.
     * @param _voter_address The unique address of a voter!
     * @param _ballot_id The unique Id of a Ballot!
     *
     * @require:
     *
     *
     *
     */
    function get_voter(address _voter_address, uint256 _ballot_id)
        external
        view
        returns (Voter memory);

    /*
     * @dev msg.sender gets candidates of a ballot.
     * @param _ballot_id The unique Id of a Ballot!
     *
     * @require:
     *
     *
     *
     */
    function get_candidates(uint256 _ballot_id)
        external
        view
        returns (address[] memory);

    /*
     * @dev msg.sender gets the voters of a ballot.
     * @param _ballot_id The unique Id of a Ballot!
     *
     * @require:
     *
     *
     *
     */
    function get_voters(uint256 _ballot_id)
        external
        view
        returns (address[] memory);

    /*
     * @dev Get the winner of a ballot
     * @param _ballot_id A integer representing the ballot id
     * @return An address of the winner(candidate)
     *
     * @require:
     *  - valid _ballot_id
     *  - if ballot_type >= 1, Require msg.sender == ballot_owner || authorized owner
     *  - ballot is over(closed)
     */
    function get_winner(uint256 _ballot_id) external returns (address);

    /*
     * @dev ends a ballot
     * @param _ballot_id The Id of a ballot
     *
     * @require:
     *  - time for ballot is up block_number >= set_block_number
     *  - msg.sender == ballot_owner
     */
    function end_ballot(uint256 _ballot_id) external;

    // function withdraw(uint256 _ballot_id, bool _destroy) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.8;

import "Initializable.sol";
import "OwnableUpgradeable.sol";

contract JamiiBase is Initializable, OwnableUpgradeable {
    address internal fee_addr;
    uint256 internal uid;
    uint256 internal candidates_count;
    mapping(uint256 => string) internal ballot_types_mapping;

    function initialize() internal onlyInitializing {
        uid = 100;
        candidates_count = 1000;
        create_ballot_types();
        __Ownable_init();
        fee_addr = owner();
    }

    function create_ballot_types() private {
        ballot_types_mapping[0] = "open-free";
        ballot_types_mapping[1] = "closed-free";
        ballot_types_mapping[2] = "open-paid";
        ballot_types_mapping[3] = "closed-paid";
        ballot_types_mapping[4] = "closed-free-secret";
        ballot_types_mapping[5] = "open-paid-secret";
        ballot_types_mapping[6] = "closed-paid-secret";
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "ContextUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}