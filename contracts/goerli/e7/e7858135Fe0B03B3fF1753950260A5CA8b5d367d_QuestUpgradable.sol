// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
// import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
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

contract QuestUpgradable is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
    
{
    // using Chainlink for Chainlink.Request;

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

    function initialize(
        address _rm_lead,
        address[] memory _su_multisigs,
        address[] memory _all_RMs,
        address _rain_token_address,
        address _dispute_multisig
    ) external initializer {
        // mumbai
        // setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        // setChainlinkOracle(0xedaa6962Cf1368a92e244DdC11aaC49c0A0acC37);
        // externalJobId = "90ec64e83b32429b958deb238a23eeed";
        // oraclePayment = (0.0 * LINK_DIVISIBILITY);

        rm_lead = _rm_lead;
        su_multisigs = _su_multisigs;
        all_RMs = _all_RMs;
        next_gm_index = 0;
        rain_token_address = _rain_token_address;
        dispute_multisig = _dispute_multisig;

        for (uint256 i = 0; i < _all_RMs.length; i++) {
            is_rm[all_RMs[i]] = true;
        }

        __Pausable_init();
        __AccessControl_init();
        __Context_init();

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
            _contract_spend_from(msg.sender, new_GM.su_stake_required);
            new_GM.su_staked = true;
        } else {
            _contract_spend_from(msg.sender, new_GM.rm_lead_stake_required);
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
                _contract_spend_from(msg.sender, new_GM.rm_lead_stake_required);
                new_GM.rm_lead_staked = true;
            } else {
                _contract_spend_from(msg.sender, new_GM.su_stake_required);
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
                _contract_spend_from(msg.sender, new_GM.rm_lead_stake_required);
                new_GM.rm_lead_staked = true;
            } else {
                _contract_spend_from(msg.sender, new_GM.su_stake_required);
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

    //     function request_oracle_from_admin(uint256 _gm_index, string calldata url)
    //     external
    //     only_admin
    // {
    //     requestOracle(_gm_index, url);
    // }

    // function requestOracle(uint256 _gm_index, string calldata url) internal {
    //     Chainlink.Request memory req = buildChainlinkRequest(
    //         externalJobId,
    //         address(this),
    //         this.fulfillOracle.selector
    //     );
    //     req.add("get", string.concat(url, "/", Strings.toString(_gm_index)));
    //     req.add("path", "data");
    //     sendOperatorRequest(req, oraclePayment);
    // }

    // function fulfillOracle(bytes32 requestId, uint256[] calldata _array)
    //     public
    //     recordChainlinkFulfillment(requestId)
    // {
    //     uint8 gm_index = uint8(_array[0]);
    //     bool has_crew_compensation = false;

    //     for (uint256 i = 1; i < _array.length; i += 2) {
    //         address wallet = address(uint160(_array[i]));
    //         uint256 amount = _array[i + 1];
    //         if (!has_crew_compensation) {
    //             if (wallet == address(0)) {
    //                 has_crew_compensation = true;
    //                 continue;
    //             } else {
    //                 //transfer token from contract
    //             }
    //         } else {
    //             //transfer token from foundation wallet
    //         }
    //     }

    //     gm_list[gm_index].su_staked = false;
    //     gm_list[gm_index].rm_lead_staked = false;
    //     //emit event
    // }

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
                msg.sender == selected_GM.gm_proposer ||
                sender_is_su_nominee,
            "GM2"
        );

        if (
            selected_GM.gm_proposer == selected_GM.rm_lead ||
            selected_GM.gm_proposer == rm_lead
        ) {
            // founder or su agree
            require(
                msg.sender != selected_GM.rm_lead && msg.sender != rm_lead,
                "AP1"
            );
            _contract_spend_from(msg.sender, selected_GM.su_stake_required);
            selected_GM.su_staked = true;
        } else {
            // rm lead agree
            require(
                msg.sender != selected_GM.gm_proposer &&
                    msg.sender != selected_GM.su_address &&
                    sender_is_su_nominee == true,
                "AP1"
            );
            _contract_spend_from(
                msg.sender,
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

    function _contract_spend_from(address from, uint256 value) internal {
        IERC20 rain_token = IERC20(rain_token_address);
        require(rain_token.balanceOf(from) >= value, "Address not enough rain");

        rain_token.transferFrom(from, address(this), value);
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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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
interface IERC165Upgradeable {
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