// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library Search {
    function exist(address[] storage self, address _address)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < self.length; i++)
            if (self[i] == _address) return true;
        return false;
    }

    function index_of(address[] storage self, address _address)
        internal
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < self.length; i++)
            if (self[i] == _address) return i;
        return 0;
    }
}

enum GM_Status {
    Pending,
    Accepted,
    Disputing,
    Finished,
    Canceled
}

library GM_View {
    function get_times(GM_DATA storage self)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            self.gm_times.respond_time,
            self.gm_times.feedback_time,
            self.gm_times.dispute_execute_time
        );
    }

    function get_status(GM_DATA storage self)
        internal
        view
        returns (GM_Status status)
    {
        return self.status;
    }
}

struct Time_Keeper {
    uint256 respond_time;
    uint256 feedback_time;
    uint256 dispute_execute_time;
}

struct Feedback {
    uint256 feedback_counter;
    bool su_submit_first;
    bytes32 rm_feedback_hash;
    bool rm_GM_occurred;
    bool rm_request_dispute;
    bytes32 su_feedback_hash;
    bool su_GM_occurred;
    bool su_request_dispute;
}

struct GM_DATA {
    address rm_lead;
    address su_address;
    address gm_proposer;
    bytes32 gm_statement_hash;
    uint256 rm_lead_stake_required;
    uint256 su_stake_required;
    bool rm_lead_staked;
    bool su_staked;
    uint256 dispute_cost;
    bool rm_staked_dispute;
    bool su_staked_dispute;
    address[] participants;
    uint16[] gm_cap_table;
    uint256 feedback_deadline;
    Time_Keeper gm_times;
    bool agreed;
    Feedback feedbacks;
    bool frozen_user;
    bool paused_contract;
    GM_Status status;
}

interface Rain_Interface {
    function isAccountFrozen(address account) external view returns (bool);
}

contract QuestMvp is Pausable, AccessControl, ChainlinkClient {
    using Chainlink for Chainlink.Request;

    // This modifier tests that the referenced GM exists (already has been proposed).
    modifier valid_index(uint8 gm_index) {
        require(gm_index < next_gm_index, "Not valid GM");
        _;
    }

    modifier only_su() {
        require(su_multisigs.exist(msg.sender), "SU1");
        _;
    }

    modifier only_admin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "AD1");
        _;
    }

    uint256 constant TIME_INTERVAL_ONE = 100000;
    uint256 constant TIME_INTERVAL_THREE = 300000;
    uint256 constant TIME_INTERVAL_FOUR = 500000;
    address constant ADMIN_ADDRESS = 0x99dbB9D1A7FFd38467F94443a9dEe088c6AB34B9;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER");
    bytes32 public constant DISPUTE_RESOLVER = keccak256("DISPUTE_RESOLVER");

    address public rain_token_address;
    address public rm_lead;
    address[] public su_multisigs;
    address[] public all_RMs;
    address public dispute_multisig;
    uint8 public next_gm_index;
    mapping(address => address[]) private su_multisig_nominee_list;
    mapping(uint8 => GM_DATA) gm_list;
    mapping(address => bool) public is_rm;

    bytes32 private externalJobId;
    uint256 private oraclePayment;

    using Search for address[];
    using GM_View for GM_DATA;

    event GM_Proposed(
        uint256 gm_index,
        bytes32 gm_statement_hash,
        address rm_lead,
        address su_address,
        address gm_proposer,
        uint256 rm_lead_stake_required,
        uint256 su_stake_required,
        uint256 feedback_deadline,
        uint256 respond_time
    );

    event OracleFuilfilled(uint256 gm_index);

    event GM_Agreed(uint256 gm_index, address sender, uint256 accepted_time);
    event GM_Disagreed(uint256 gm_index, address sender);
    event GM_Resolved(uint256 gm_index, uint256 resolve_result);
    event RM_Lead_Updated(address new_rm_lead);
    event Feedback_Submitted(
        uint256 gm_index,
        bytes32 feedback_hash,
        address submitor,
        bool is_su_party_submit,
        bool is_rm_party_submit,
        bool is_gm_occured,
        bool is_disputed
    );

    event Feedback_Proposed(
        uint256 gm_index,
        bytes32 feedback_hash,
        bool is_su_party_submit,
        bool is_rm_party_submit
    );

    event GM_Dispute_Executed(uint256 gm_index, uint8 dispute_choice);

    constructor(
        address _rm_lead,
        address[] memory _su_multisigs,
        address[] memory _all_RMs,
        address _rain_token_address,
        address _dispute_multisig
    ) {
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0xedaa6962Cf1368a92e244DdC11aaC49c0A0acC37);
        externalJobId = "90ec64e83b32429b958deb238a23eeed";
        oraclePayment = (0.0 * LINK_DIVISIBILITY);

        rm_lead = _rm_lead;
        su_multisigs = _su_multisigs;
        all_RMs = _all_RMs;
        next_gm_index = 0;
        rain_token_address = _rain_token_address;
        dispute_multisig = _dispute_multisig;

        for (uint256 i = 0; i < _all_RMs.length; i++) {
            is_rm[all_RMs[i]] = true;
        }
        _grantRole(DEFAULT_ADMIN_ROLE, ADMIN_ADDRESS);
    }

    function propose_new_GM(
        address _su_address,
        bytes32 _gm_statement_hash,
        uint256 _rm_lead_stake_required,
        uint256 _su_stake_required,
        uint256 _dispute_cost,
        address[] calldata _participants,
        uint16[] calldata _gm_cap_table,
        uint256 _feedback_deadline
    ) external whenNotPaused {
        bool proposer_is_su = false;
        bool proposer_is_su_nominee = false;
        bool proposer_is_rm = false;
        address gm_su_address = _su_address;

        {
            if (msg.sender == rm_lead) {
                proposer_is_rm = true;
            } else {
                // check sender is su multisig
                if (su_multisigs.exist(msg.sender)) {
                    proposer_is_su = true;
                }

                if (!proposer_is_su) {
                    // check sender is su nominee
                    if (
                        su_multisig_nominee_list[gm_su_address].exist(
                            msg.sender
                        )
                    ) {
                        proposer_is_su_nominee = true;
                    }
                }
            }

            require(
                proposer_is_rm || proposer_is_su || proposer_is_su_nominee,
                "GM1"
            );
        }

        {
            require(su_multisigs.exist(gm_su_address), "SU1");
            // requre participants has same length with the cap table
            require(
                _participants.length == _gm_cap_table.length,
                "Lengths are not the same"
            );

            // check participants are rm
            for (uint256 i = 0; i < _participants.length; i++) {
                require(is_rm[_participants[i]], "RM1");
            }
        }

        GM_DATA memory new_GM;
        new_GM.gm_proposer = msg.sender;
        new_GM.gm_statement_hash = _gm_statement_hash;

        new_GM.gm_times = Time_Keeper(
            block.timestamp + TIME_INTERVAL_ONE,
            0,
            0
        );

        new_GM.feedbacks = Feedback(
            0,
            false,
            bytes32(0),
            false,
            false,
            bytes32(0),
            false,
            false
        );

        new_GM.feedback_deadline = _feedback_deadline;

        {
            new_GM.rm_lead_stake_required = _rm_lead_stake_required;
            new_GM.su_stake_required = _su_stake_required;
            new_GM.rm_lead = rm_lead;
            new_GM.su_address = gm_su_address;
            new_GM.dispute_cost = _dispute_cost;
            new_GM.participants = _participants;
            new_GM.gm_cap_table = _gm_cap_table;
        }

        if (proposer_is_su || proposer_is_su_nominee) {
            _contract_spend_from(
                msg.sender,
                address(this),
                new_GM.su_stake_required
            );
            new_GM.su_staked = true;
        } else {
            _contract_spend_from(
                msg.sender,
                address(this),
                new_GM.rm_lead_stake_required
            );
            new_GM.rm_lead_staked = true;
        }

        gm_list[next_gm_index] = new_GM;

        emit GM_Proposed(
            next_gm_index,
            new_GM.gm_statement_hash,
            new_GM.rm_lead,
            new_GM.su_address,
            msg.sender,
            new_GM.rm_lead_stake_required,
            new_GM.su_stake_required,
            new_GM.feedback_deadline,
            new_GM.gm_times.respond_time
        );
        next_gm_index += 1;
    }

    function repropose_GM(
        address _su_address,
        bytes32 _gm_statement_hash,
        uint256 _rm_lead_stake_required,
        uint256 _su_stake_required,
        uint256 _dispute_cost,
        address[] calldata _participants,
        uint16[] calldata _gm_cap_table,
        uint256 _feedback_deadline,
        uint8 _gm_index
    ) external whenNotPaused valid_index(_gm_index) {
        GM_DATA memory new_GM;
        {
            new_GM.su_address = _su_address;
            new_GM.gm_proposer = msg.sender;
            new_GM.gm_statement_hash = _gm_statement_hash;
        }

        bool reproposer_is_su = false;
        bool reproposer_is_su_nominee = false;
        bool reproposer_is_gm_rm = false;
        bool reproposer_is_rm = false;

        {
            require(!gm_list[_gm_index].agreed, "GM3");
            // require pending
        }

        {
            require(su_multisigs.exist(new_GM.su_address), "SU not valid");
        }

        if (msg.sender == rm_lead) {
            reproposer_is_rm = true;
        } else if (msg.sender == gm_list[_gm_index].rm_lead) {
            reproposer_is_gm_rm = true;
        } else if (msg.sender == new_GM.su_address) {
            reproposer_is_su = false;
        } else {
            if (su_multisig_nominee_list[new_GM.su_address].exist(msg.sender)) {
                reproposer_is_su_nominee = true;
            }
        }

        require(
            reproposer_is_su ||
                reproposer_is_su_nominee ||
                reproposer_is_gm_rm ||
                reproposer_is_rm,
            "GM1"
        );

        {
            // requre participants has same length with the cap table
            require(
                _participants.length == _gm_cap_table.length,
                "Length are not the same"
            );

            // check participants are rm
            for (uint256 i = 0; i < _participants.length; i++) {
                require(is_rm[_participants[i]], "RM1");
            }
        }

        require(
            block.timestamp < gm_list[_gm_index].gm_times.respond_time,
            "GM4"
        );

        {
            new_GM.rm_lead_stake_required = _rm_lead_stake_required;
            new_GM.su_stake_required = _su_stake_required;
            new_GM.rm_lead = rm_lead;
            new_GM.dispute_cost = _dispute_cost;
            new_GM.participants = _participants;
            new_GM.gm_cap_table = _gm_cap_table;
            new_GM.gm_times = gm_list[_gm_index].gm_times;
            new_GM.feedbacks = gm_list[_gm_index].feedbacks;
            new_GM.feedback_deadline = _feedback_deadline;
            new_GM.status = gm_list[_gm_index].status;
        }

        if (
            gm_list[_gm_index].gm_proposer == rm_lead ||
            gm_list[_gm_index].gm_proposer == gm_list[_gm_index].rm_lead
        ) {
            // if the gm is proposed by rm lead before.
            _transfer_rain_to(
                gm_list[_gm_index].gm_proposer,
                gm_list[_gm_index].rm_lead_stake_required
            );
            new_GM.rm_lead_staked = false;
            if (reproposer_is_rm || reproposer_is_gm_rm) {
                _contract_spend_from(
                    msg.sender,
                    address(this),
                    new_GM.rm_lead_stake_required
                );
                new_GM.rm_lead_staked = true;
            } else {
                _contract_spend_from(
                    msg.sender,
                    address(this),
                    new_GM.su_stake_required
                );
                new_GM.su_staked = true;
            }
        } else {
            // if the gm is proposed by su before.
            _transfer_rain_to(
                gm_list[_gm_index].gm_proposer,
                gm_list[_gm_index].su_stake_required
            );
            new_GM.su_staked = false;
            if (reproposer_is_gm_rm || reproposer_is_rm) {
                _contract_spend_from(
                    msg.sender,
                    address(this),
                    new_GM.rm_lead_stake_required
                );
                new_GM.rm_lead_staked = true;
            } else {
                _contract_spend_from(
                    msg.sender,
                    address(this),
                    new_GM.su_stake_required
                );
                new_GM.su_staked = true;
            }
        }

        gm_list[_gm_index] = new_GM;

        emit GM_Proposed(
            _gm_index,
            new_GM.gm_statement_hash,
            new_GM.rm_lead,
            new_GM.su_address,
            msg.sender,
            new_GM.rm_lead_stake_required,
            new_GM.su_stake_required,
            new_GM.feedback_deadline,
            new_GM.gm_times.respond_time
        );
    }

    function submit_feedback(
        uint8 _gm_index,
        bytes32 _feedback_hash,
        bool _GM_occurred,
        bool _request_dispute
    ) external valid_index(_gm_index) {
        GM_DATA memory selected_GM = gm_list[_gm_index];
        require(selected_GM.agreed, "GM1");
        require(
            block.timestamp < selected_GM.gm_times.feedback_time,
            "This GM is Lock"
        );

        require(selected_GM.feedbacks.feedback_counter < 2, "FB2.");

        bool is_rm_party_submit;
        bool is_su_party_submit;

        // check rm party or su party submit the feedback
        if (msg.sender == rm_lead || msg.sender == selected_GM.rm_lead) {
            is_rm_party_submit = true;
        } else {
            if (msg.sender == selected_GM.su_address) {
                is_su_party_submit = true;
            } else {
                if (
                    su_multisig_nominee_list[selected_GM.su_address].exist(
                        msg.sender
                    )
                ) {
                    is_su_party_submit = true;
                }
            }
        }

        require(is_rm_party_submit || is_su_party_submit, "FB2");

        if (_request_dispute) {
            _pause();
            selected_GM.status = GM_Status.Disputing;

            if (selected_GM.gm_times.dispute_execute_time == 0) {
                selected_GM.gm_times.dispute_execute_time =
                    block.timestamp +
                    TIME_INTERVAL_FOUR;
            }
        }

        if (selected_GM.feedbacks.feedback_counter == 0) {
            if (is_su_party_submit) {
                selected_GM.feedbacks.su_feedback_hash = _feedback_hash;
                selected_GM.feedbacks.su_GM_occurred = _GM_occurred;
                selected_GM.feedbacks.su_request_dispute = _request_dispute;
                selected_GM.feedbacks.su_submit_first = true;
            } else {
                selected_GM.feedbacks.rm_feedback_hash = _feedback_hash;
                selected_GM.feedbacks.rm_GM_occurred = _GM_occurred;
                selected_GM.feedbacks.rm_request_dispute = _request_dispute;
                selected_GM.feedbacks.su_submit_first = false;
            }
            selected_GM.feedbacks.feedback_counter += 1;
        }
        if (selected_GM.feedbacks.feedback_counter == 1) {
            require(
                selected_GM.feedbacks.su_submit_first != is_su_party_submit,
                "Only other can submit"
            );

            if (is_su_party_submit) {
                selected_GM.feedbacks.su_feedback_hash = _feedback_hash;
                selected_GM.feedbacks.su_GM_occurred = _GM_occurred;
                selected_GM.feedbacks.su_request_dispute = _request_dispute;
            } else {
                selected_GM.feedbacks.rm_feedback_hash = _feedback_hash;
                selected_GM.feedbacks.rm_GM_occurred = _GM_occurred;
                selected_GM.feedbacks.rm_request_dispute = _request_dispute;
            }

            selected_GM.feedbacks.feedback_counter += 1;

            if (
                !selected_GM.feedbacks.su_request_dispute &&
                !selected_GM.feedbacks.rm_request_dispute
            ) {
                // selected_GM.status = GM_Status.Finished;
                if (
                    selected_GM.feedbacks.su_GM_occurred &&
                    selected_GM.feedbacks.rm_GM_occurred
                ) {
                    _transfer_rain_to(
                        selected_GM.rm_lead,
                        selected_GM.rm_lead_stake_required
                    );
                    _transfer_rain_to(
                        selected_GM.rm_lead,
                        selected_GM.su_stake_required
                    );
                    selected_GM.rm_lead_staked = false;
                    selected_GM.su_staked = false;
                    selected_GM.status = GM_Status.Finished;
                } else if (
                    !selected_GM.feedbacks.su_GM_occurred &&
                    !selected_GM.feedbacks.rm_GM_occurred
                ) {
                    _transfer_rain_to(
                        selected_GM.su_address,
                        selected_GM.su_stake_required
                    );
                    _transfer_rain_to(
                        ADMIN_ADDRESS,
                        selected_GM.rm_lead_stake_required
                    );
                    selected_GM.rm_lead_staked = false;
                    selected_GM.su_staked = false;
                    selected_GM.status = GM_Status.Finished;
                } else {
                    _pause();
                    selected_GM.status = GM_Status.Disputing;

                    if (selected_GM.gm_times.dispute_execute_time == 0) {
                        selected_GM.gm_times.dispute_execute_time =
                            block.timestamp +
                            TIME_INTERVAL_FOUR;
                    }
                }
            }
        }

        gm_list[_gm_index] = selected_GM;

        emit Feedback_Submitted(
            _gm_index,
            _feedback_hash,
            msg.sender,
            is_su_party_submit,
            is_rm_party_submit,
            _GM_occurred,
            _request_dispute
        );
    }

    function resolve_gm(uint8 _gm_index)
        external
        valid_index(_gm_index)
        returns (uint16 result_index)
    {
        GM_DATA memory selected_GM = gm_list[_gm_index];
        require(selected_GM.status == GM_Status.Accepted, "GM4");

        require(
            selected_GM.su_staked && selected_GM.rm_lead_staked,
            "GM resolved"
        );

        if (selected_GM.status == GM_Status.Accepted) {
            require(
                // The feedback submission deadline has passed,
                block.timestamp >= selected_GM.gm_times.feedback_time,
                "Feedback deadline not passed"
            );
        }

        // zero partiy submitted feedback, send all the stakd to foundation
        if (selected_GM.feedbacks.feedback_counter == 0) {
            _transfer_rain_to(
                ADMIN_ADDRESS,
                selected_GM.rm_lead_stake_required +
                    selected_GM.su_stake_required
            );
        }

        // only one party submit feedback
        if (selected_GM.feedbacks.feedback_counter == 1) {
            if (
                // only su respond
                selected_GM.feedbacks.su_submit_first
            ) {
                if (selected_GM.feedbacks.su_GM_occurred) {
                    if (!selected_GM.feedbacks.su_request_dispute) {
                        result_index = 1;
                    } else {
                        result_index = 2;
                    }
                } else {
                    result_index = 2;
                }
            } else {
                if (selected_GM.feedbacks.rm_GM_occurred) {
                    result_index = 1;
                } else {
                    if (!selected_GM.feedbacks.rm_request_dispute) {
                        result_index = 2;
                    } else {
                        result_index = 2;
                    }
                }
            }
        }

        selected_GM.su_staked = false;
        selected_GM.rm_lead_staked = false;
        gm_list[_gm_index] = selected_GM;
        emit GM_Resolved(_gm_index, result_index);
        return result_index;
    }

    function dispute_gm(uint8 _gm_index, uint8 _dispute_choice)
        external
        valid_index(_gm_index)
    {
        GM_DATA memory selected_GM = gm_list[_gm_index];
        require(selected_GM.status == GM_Status.Disputing, "GM not disputing");

        if (_dispute_choice == 0) {
            uint256 gm_total_staked = selected_GM.rm_lead_stake_required +
                selected_GM.su_stake_required;
            _transfer_rain_to(selected_GM.rm_lead, gm_total_staked);
        } else if (_dispute_choice == 1) {
            _transfer_rain_to(
                selected_GM.su_address,
                selected_GM.su_stake_required
            );
        } else if (_dispute_choice == 2) {
            _transfer_rain_to(
                selected_GM.rm_lead,
                selected_GM.rm_lead_stake_required
            );
        }
        selected_GM.status = GM_Status.Finished;
        gm_list[_gm_index] = selected_GM;
        emit GM_Dispute_Executed(_gm_index, _dispute_choice);
    }

    function cancel_GM(uint8 _gm_index) external valid_index(_gm_index) {
        require(
            (gm_list[_gm_index].status == GM_Status.Pending &&
                block.timestamp >= gm_list[_gm_index].gm_times.respond_time) ||
                (gm_list[_gm_index].gm_proposer == msg.sender),
            "CA1"
        );

        if (gm_list[_gm_index].rm_lead_staked) {
            _transfer_rain_to(
                gm_list[_gm_index].gm_proposer,
                gm_list[_gm_index].rm_lead_stake_required
            );
            gm_list[_gm_index].rm_lead_staked = false;
        } else {
            _transfer_rain_to(
                gm_list[_gm_index].gm_proposer,
                gm_list[_gm_index].su_stake_required
            );
            gm_list[_gm_index].su_staked = false;
        }

        gm_list[_gm_index].status = GM_Status.Canceled;
    }

    function update_gm_hash(uint8 _gm_index, bytes32 _gm_hash)
        external
        valid_index(_gm_index)
        only_admin
    {
        gm_list[_gm_index].gm_statement_hash = _gm_hash;
    }

    function request_oracle_from_admin(uint256 _gm_index, string calldata url)
        external
        only_admin
    {
        requestOracle(_gm_index, url);
    }

    function requestOracle(uint256 _gm_index, string calldata url) internal {
        Chainlink.Request memory req = buildChainlinkRequest(
            externalJobId,
            address(this),
            this.fulfillOracle.selector
        );
        req.add("get", string.concat(url, "/", Strings.toString(_gm_index)));
        req.add("path", "data");
        sendOperatorRequest(req, oraclePayment);
    }

    function fulfillOracle(bytes32 requestId, uint256[] calldata _array)
        public
        recordChainlinkFulfillment(requestId)
    {
        uint8 gm_index = uint8(_array[0]);
        bool has_crew_compensation = false;

        for (uint256 i = 1; i < _array.length; i += 2) {
            address wallet = address(uint160(_array[i]));
            uint256 amount = _array[i + 1];
            if (!has_crew_compensation) {
                if (wallet == address(0)) {
                    has_crew_compensation = true;
                    continue;
                } else {
                    _transfer_rain_to(wallet, amount);
                }
            } else {
                _contract_spend_from(ADMIN_ADDRESS, wallet, amount);
            }
        }
        gm_list[gm_index].su_staked = false;
        gm_list[gm_index].rm_lead_staked = false;
        //emit event
        emit OracleFuilfilled(gm_index);
    }

    function su_nominate(address _nominee) external only_su {
        if (!su_multisig_nominee_list[msg.sender].exist(_nominee)) {
            su_multisig_nominee_list[msg.sender].push(_nominee);
        }
    }

    function su_de_nominate(address _nominee_to_remove) external only_su {
        if (su_multisig_nominee_list[msg.sender].exist(_nominee_to_remove)) {
            uint256 index = su_multisig_nominee_list[msg.sender].index_of(
                _nominee_to_remove
            );
            for (
                uint256 i = index;
                i < su_multisig_nominee_list[msg.sender].length;
                i++
            ) {
                su_multisig_nominee_list[msg.sender][
                    i
                ] = su_multisig_nominee_list[msg.sender][i + 1];
            }
            su_multisig_nominee_list[msg.sender].pop();
        }
    }

    function agree_GM(uint8 gm_index) external valid_index(gm_index) {
        GM_DATA memory selected_GM = gm_list[gm_index];

        require(block.timestamp < selected_GM.gm_times.respond_time, "GM1");
        bool sender_is_su_nominee = su_multisig_nominee_list[
            selected_GM.su_address
        ].exist(msg.sender);

        require(
            msg.sender == rm_lead ||
                msg.sender == selected_GM.rm_lead ||
                msg.sender == selected_GM.su_address ||
                sender_is_su_nominee,
            "GM2"
        );

        if (
            selected_GM.gm_proposer == selected_GM.rm_lead ||
            selected_GM.gm_proposer == rm_lead
        ) {
            // founder or su agree
            require(
                msg.sender == selected_GM.su_address || sender_is_su_nominee,
                "AP1"
            );
            _contract_spend_from(
                msg.sender,
                address(this),
                selected_GM.su_stake_required
            );
            selected_GM.su_staked = true;
        } else {
            // if gm proposed by su, now rm agree
            require(
                msg.sender == rm_lead || msg.sender == selected_GM.rm_lead,
                "AP1"
            );
            _contract_spend_from(
                msg.sender,
                address(this),
                selected_GM.rm_lead_stake_required
            );

            selected_GM.rm_lead_staked = true;
        }

        selected_GM.agreed = true;
        selected_GM.status = GM_Status.Accepted;
        selected_GM.gm_times.feedback_time =
            block.timestamp +
            selected_GM.feedback_deadline;
        gm_list[gm_index] = selected_GM;

        emit GM_Agreed(gm_index, msg.sender, block.timestamp);
    }

    function transfer_rm_lead(address _new_rm_lead) external {
        require(
            msg.sender == rm_lead || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Can not transfer rm_lead"
        );
        rm_lead = _new_rm_lead;
        emit RM_Lead_Updated(_new_rm_lead);
    }

    function _transfer_rain_to(address to, uint256 value) internal {
        IERC20 rain_token = IERC20(rain_token_address);
        require(
            rain_token.balanceOf(address(this)) >= value,
            "Contract not enough rain"
        );
        rain_token.transfer(to, value);
    }

    function _contract_spend_from(
        address from,
        address to,
        uint256 value
    ) internal {
        IERC20 rain_token = IERC20(rain_token_address);
        require(rain_token.balanceOf(from) >= value, "Address not enough rain");

        rain_token.transferFrom(from, to, value);
    }

    function pause() external whenNotPaused {
        require(hasRole(PAUSER_ROLE, msg.sender), "AD1");
        _pause();
    }

    function unpause() external whenPaused {
        require(hasRole(PAUSER_ROLE, msg.sender), "AD1");
        _unpause();
    }

    function get_gm_time(uint8 gm_index)
        external
        view
        valid_index(gm_index)
        returns (
            uint256 respond_time,
            uint256 feedback_time,
            uint256 dispute_execute_time
        )
    {
        return (gm_list[gm_index].get_times());
    }

    function get_gm_status(uint8 gm_index)
        external
        view
        valid_index(gm_index)
        returns (GM_Status gm_status)
    {
        return gm_list[gm_index].get_status();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Chainlink.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/ChainlinkRequestInterface.sol";
import "./interfaces/OperatorInterface.sol";
import "./interfaces/PointerInterface.sol";
import {ENSResolver as ENSResolver_Chainlink} from "./vendor/ENSResolver.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
abstract contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 internal constant LINK_DIVISIBILITY = 10**18;
  uint256 private constant AMOUNT_OVERRIDE = 0;
  address private constant SENDER_OVERRIDE = address(0);
  uint256 private constant ORACLE_ARGS_VERSION = 1;
  uint256 private constant OPERATOR_ARGS_VERSION = 2;
  bytes32 private constant ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 private constant ENS_ORACLE_SUBNAME = keccak256("oracle");
  address private constant LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private s_ens;
  bytes32 private s_ensNode;
  LinkTokenInterface private s_link;
  OperatorInterface private s_oracle;
  uint256 private s_requestCount = 1;
  mapping(bytes32 => address) private s_pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddr address to operate the callback on
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 specId,
    address callbackAddr,
    bytes4 callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(specId, callbackAddr, callbackFunctionSignature);
  }

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildOperatorRequest(bytes32 specId, bytes4 callbackFunctionSignature)
    internal
    view
    returns (Chainlink.Request memory)
  {
    Chainlink.Request memory req;
    return req.initialize(specId, address(this), callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendChainlinkRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      ChainlinkRequestInterface.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      address(this),
      req.callbackFunctionId,
      nonce,
      ORACLE_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `sendOperatorRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendOperatorRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      OperatorInterface.operatorRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackFunctionId,
      nonce,
      OPERATOR_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param nonce used to generate the request ID
   * @param payment The amount of LINK to send for the request
   * @param encodedRequest data encoded for request type specific format
   * @return requestId The request ID
   */
  function _rawRequest(
    address oracleAddress,
    uint256 nonce,
    uint256 payment,
    bytes memory encodedRequest
  ) private returns (bytes32 requestId) {
    requestId = keccak256(abi.encodePacked(this, nonce));
    s_pendingRequests[requestId] = oracleAddress;
    emit ChainlinkRequested(requestId);
    require(s_link.transferAndCall(oracleAddress, payment, encodedRequest), "unable to transferAndCall to oracle");
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param requestId The request ID
   * @param payment The amount of LINK sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  ) internal {
    OperatorInterface requested = OperatorInterface(s_pendingRequests[requestId]);
    delete s_pendingRequests[requestId];
    emit ChainlinkCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice the next request count to be used in generating a nonce
   * @dev starts at 1 in order to ensure consistent gas cost
   * @return returns the next request count to be used in a nonce
   */
  function getNextRequestCount() internal view returns (uint256) {
    return s_requestCount;
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setChainlinkOracle(address oracleAddress) internal {
    s_oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the LINK token address
   * @param linkAddress The address of the LINK token contract
   */
  function setChainlinkToken(address linkAddress) internal {
    s_link = LinkTokenInterface(linkAddress);
  }
  
  // initiate the requestCount
  // function initiateRequestCount() internal {
  //   s_requestCount = 1;
  // }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress() internal view returns (address) {
    return address(s_link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress() internal view returns (address) {
    return address(s_oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
    s_pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  function useChainlinkWithENS(address ensAddress, bytes32 node) internal {
    s_ens = ENSInterface(ensAddress);
    s_ensNode = node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS() internal {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(bytes32 requestId)
    internal
    recordChainlinkFulfillment(requestId)
  // solhint-disable-next-line no-empty-blocks
  {

  }

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 requestId) {
    require(msg.sender == s_pendingRequests[requestId], "Source must be the oracle of the request");
    delete s_pendingRequests[requestId];
    emit ChainlinkFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    require(s_pendingRequests[requestId] == address(0), "Request is already pending");
    _;
  }
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CBORChainlink} from "./vendor/CBORChainlink.sol";
import {BufferChainlink} from "./vendor/BufferChainlink.sol";

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  ) internal pure returns (Chainlink.Request memory) {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory data) internal pure {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ENSInterface {
  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);

  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external;

  function setResolver(bytes32 node, address resolver) external;

  function setOwner(bytes32 node, address owner) external;

  function setTTL(bytes32 node, uint64 ttl) external;

  function owner(bytes32 node) external view returns (address);

  function resolver(bytes32 node) external view returns (address);

  function ttl(bytes32 node) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PointerInterface {
  function getAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OracleInterface.sol";
import "./ChainlinkRequestInterface.sol";

interface OperatorInterface is OracleInterface, ChainlinkRequestInterface {
  function operatorRequest(
    address sender,
    uint256 payment,
    bytes32 specId,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  ) external returns (bool);

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function distributeFunds(address payable[] calldata receivers, uint256[] calldata amounts) external payable;

  function getAuthorizedSenders() external returns (address[] memory);

  function setAuthorizedSenders(address[] calldata senders) external;

  function getForwarder() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19;

import {BufferChainlink} from "./BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeFixedNumeric(BufferChainlink.buffer memory buf, uint8 major, uint64 value) private pure {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if (value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if (value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if (value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(BufferChainlink.buffer memory buf, uint8 major) private pure {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(BufferChainlink.buffer memory buf, uint value) internal pure {
    if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
    }
  }

  function encodeInt(BufferChainlink.buffer memory buf, int value) internal pure {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, uint(value));
    } else if(value >= 0) {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(uint256(value)));
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(uint256(-1 - value)));
    }
  }

  function encodeBytes(BufferChainlink.buffer memory buf, bytes memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
    buf.append(value);
  }

  function encodeBigNum(BufferChainlink.buffer memory buf, uint value) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(value));
  }

  function encodeSignedBigNum(BufferChainlink.buffer memory buf, int input) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint256(-1 - input)));
  }

  function encodeString(BufferChainlink.buffer memory buf, string memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
    buf.append(bytes(value));
  }

  function startArray(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for writing to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library BufferChainlink {
  /**
   * @dev Represents a mutable buffer. Buffers have a current value (buf) and
   *      a capacity. The capacity may be longer than the current value, in
   *      which case it can be extended without the need to allocate more memory.
   */
  struct buffer {
    bytes buf;
    uint256 capacity;
  }

  /**
   * @dev Initializes a buffer with an initial capacity.
   * @param buf The buffer to initialize.
   * @param capacity The number of bytes of space to allocate the buffer.
   * @return The buffer, for chaining.
   */
  function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
   * @dev Initializes a new buffer from an existing bytes object.
   *      Changes to the buffer may mutate the original value.
   * @param b The bytes object to initialize the buffer with.
   * @return A new buffer.
   */
  function fromBytes(bytes memory b) internal pure returns (buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint256 capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
   * @dev Sets buffer length to 0.
   * @param buf The buffer to truncate.
   * @return The original buffer, for chaining..
   */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
   * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The start offset to write to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint256 dest;
    uint256 src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    unchecked {
      uint256 mask = (256**(32 - len)) - 1;
      assembly {
        let srcpart := and(mload(src), not(mask))
        let destpart := and(mload(dest), mask)
        mstore(dest, or(destpart, srcpart))
      }
    }

    return buf;
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function append(
    buffer memory buf,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
   * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write the byte at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeUint8(
    buffer memory buf,
    uint256 off,
    uint8 data
  ) internal pure returns (buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
   * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (left-aligned).
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes32 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    unchecked {
      uint256 mask = (256**len) - 1;
      // Right-align data
      data = data >> (8 * (32 - len));
      assembly {
        // Memory address of the buffer data
        let bufptr := mload(buf)
        // Address = buffer address + sizeof(buffer length) + off + len
        let dest := add(add(bufptr, off), len)
        mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
        if gt(add(off, len), mload(bufptr)) {
          mstore(bufptr, add(off, len))
        }
      }
    }
    return buf;
  }

  /**
   * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeBytes20(
    buffer memory buf,
    uint256 off,
    bytes20 data
  ) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chhaining.
   */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
   * @dev Writes an integer to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (right-aligned).
   * @return The original buffer, for chaining.
   */
  function writeInt(
    buffer memory buf,
    uint256 off,
    uint256 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint256 mask = (256**len) - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the end of the buffer. Resizes if doing so would
   * exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer.
   */
  function appendInt(
    buffer memory buf,
    uint256 data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  ) external returns (bool);

  function isAuthorizedSender(address node) external view returns (bool);

  function withdraw(address recipient, uint256 amount) external;

  function withdrawable() external view returns (uint256);
}