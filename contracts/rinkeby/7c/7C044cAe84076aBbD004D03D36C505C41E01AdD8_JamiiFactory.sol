// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

import "IJamiiFactory.sol";

contract JamiiFactory is IJamiiFactory {
    Ballot[] private ballots;
    Voter[] private voters;

    // numbers
    uint256 private ballot_fee = 340000000000000000; // $
    uint256 private candidates_count;
    uint256 private ballot_count;
    uint256[] private voter_ids;
    uint256[] internal ballot_types_arr = [0, 1, 2, 3, 4, 5, 6];
    uint256 internal ballot_types = ballot_types_arr.length;
    uint256 private uid;

    // addresses
    address private fee_addr = 0x91B01E14032f8AAAa88d66DfF50dB471208bDC19;

    // mappings
    mapping(uint256 => string) private ballot_types_mapping;
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

    constructor(string memory _arbitray_text) {
        bytes memory bytes_text = bytes(_arbitray_text);
        require(bytes_text.length > 0, "Enter a valid text!");
        require(msg.sender == fee_addr, "Insufficient Permissions!");
        fee_addr = msg.sender;
        uid = 100;
        candidates_count = 1000;
        create_ballot_types();
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

    function create_ballot_type(
        uint256 _ballot_type,
        string memory _ballot_name
    ) public {
        require(msg.sender == fee_addr, "This Action is NOT permitted!");
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
            false,
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
        Ballot memory ballot = id_to_ballot_mapping[_ballot_id];

        uint256 duration = (block.timestamp - ballot.open_date) / 60 / 60 / 24;
        require(duration < ballot._days, "This Ballot is NOT yet Expired!");

        require(msg.sender == ballot.chair, "Insufficient Permissions!");

        ballot.expired = true;
        ballots_mapping[msg.sender].expired = true;
        id_to_ballot_mapping[_ballot_id].expired = true;

        emit ended_ballot(_ballot_id);
    }

    function withdraw(uint256 _ballot_id, bool _destroy) public {
        // after ballot ends
        Ballot memory ballot = id_to_ballot_mapping[_ballot_id];
        uint256 duration = (block.timestamp - ballot.open_date) / 60 / 60 / 24;
        require(duration < ballot._days, "This Ballot is NOT yet Expired!");

        require(msg.sender == fee_addr, "Insuffcient Permissions!");
        ballot.balance = true;

        if (_destroy) {
            payable(fee_addr).transfer(ballot_fee);
        } else {
            payable(fee_addr).transfer(ballot_fee);
        }
    }
}

// SPDX-License-Identifier: MIT

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
        bool balance;
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

    function withdraw(uint256 _ballot_id, bool _destroy) external;
}