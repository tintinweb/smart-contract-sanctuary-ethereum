// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IGovernance} from "./interfaces/IGovernance.sol";
import {Pausable} from "../../Pausable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title DaoGovernance
 * @notice Contract which manages governances in MetaPlayerOne.
 */
contract DaoGovernance is Pausable {
    enum Themes { transfer_eth, transfer_erc20, add_committee, custom_execution }
    enum Percentage { absolute_majority, qualified_majority }
    enum VoicePower { balance, staking }

    struct ProposalData { string title; string description; uint256 start_time; uint256 period; Themes theme; Percentage percentage; VoicePower voice_power; address dao_address; uint256 threshold; }
    struct Proposal { string title; string description; uint256 start_time; uint256 period; Themes theme; Percentage percentage; VoicePower voice_power; address dao_address; address owner_of; bool resolved; bool accepted; bool withdrawed; uint256 threshold; }
    struct Voice { address ethAddress; bool voice; uint256 voice_amount; bool withdrawed; }

    struct TransferETH { address recipient; uint256 value; }
    struct TransferERC20 { address token_address; address recipient; uint256 value; }
    struct AddCommittee { address ethAddress; }
    struct CustomExecution { address execution_contract_address; }

    mapping(uint256 => Voice[]) private _voices;
    mapping(uint256 => Proposal) private _proposals;
    uint256 private proposal_quantity = 1;
    mapping(uint256 => mapping(address => bool)) private _registered_voice;
    mapping(address => mapping(address => bool)) private _committees_of_dao;
    mapping(uint256 => mapping(address => Voice)) private _voice;
    mapping(uint256 => TransferETH) private _transfers_eth;
    mapping(uint256 => TransferERC20) private _transfers_erc20;
    mapping(uint256 => AddCommittee) private _add_commitees;
    mapping(uint256 => CustomExecution) private _custom_executions;

    /**
     * @dev setup contract owner.
     */
    constructor(address owner_of_) Pausable(owner_of_) {}

    /**
     * @dev emits when new proposal creates.
     */
    event proposalCreated(uint256 uid, string title, string description, uint256 start_time, uint256 period, Themes theme, Percentage percentage, VoicePower voice_power, address dao_address, address owner_of);

    /**
     * @dev emits when new execution with transfering ETH creates.
     */
    event executionETHCreated(uint256 proposal_uid, address recipient, uint256 value);

    /**
     * @dev emits when new execution with transfering ERC20 token creates.
     */
    event executionERC20Created(uint256 proposal_uid, address token_address, address recipient, uint256 value);

    /**
     * @dev emits when new execution with choosing new committee creates.
     */
    event executionAddCommitteeCreated(uint256 proposal_uid, address ethAddress);

    /**
     * @dev emits when new execution with custom creates.
     */
    event executionCustomCreated(uint256 proposal_uid, address execution_contract_address);

    /**
     * @dev emits when voice has been submited.
     */
    event voteSubmited(uint256 proposal_uid, address owner_of, bool voice, uint256 voice_amount);

    /**
    * @dev emits after proposal executes.
    */
    event executed(uint256 proposal_uid, bool accepted, bool resolved);

    /**
     * @dev emits after staking after governance period withdraws.
     */
    event stakingWithdrawed(uint256 proposal_uid);

    /**
     * @dev emits after proposal staking after governance period withdraws.
     */
    event proposalWithdrawed(uint256 proposal_uid);
    

    /**
     * @dev creates single proposal and emits event proposalCreated.
     * @param proposal includes all information about new proposal. You can check it in ProposalData struct.
     * @param execution_eth spicifies all data about success transfer ether execution of proposal. Is a list with only first value. If 1 value is not specified - will be ignored soon.
     * @param execution_erc20 spicifies all data about success transfer ERC20 token execution of proposal. Is a list with only first value. If 1 value is not specified - will be ignored soon.
     * @param custom_execution spicifies all data about success custom execution of proposal. Is a list with only first value. If 1 value is not specified - will be ignored soon.
     * @param add_committee spicifies all data about success add committee execution of proposal. Is a list with only first value. If 1 value is not specified - will be ignored soon.
     */
    function createSingleChoiceProposal(ProposalData memory proposal, TransferETH[] memory execution_eth, TransferERC20[] memory execution_erc20, CustomExecution[] memory custom_execution, AddCommittee[] memory add_committee) public payable notPaused {
        IERC20 dao_token = IERC20(proposal.dao_address);
        require(dao_token.balanceOf(msg.sender) >= dao_token.totalSupply() * 2 / 100, "Not enough dao tokens on wallet");
        if (proposal.theme == Themes.transfer_eth) { require(msg.value >= execution_eth[0].value, "Not enough ETH sended"); }
        if (proposal.theme == Themes.transfer_erc20) { IERC20(execution_erc20[0].token_address).transferFrom(msg.sender, address(this), execution_erc20[0].value); }

        _proposals[proposal_quantity] = Proposal(proposal.title, proposal.description, proposal.start_time, proposal.period, proposal.theme, proposal.percentage, proposal.voice_power, proposal.dao_address, msg.sender, false, false, false, proposal.threshold);
        emit proposalCreated(proposal_quantity, proposal.title, proposal.description, proposal.start_time, proposal.period, proposal.theme, proposal.percentage, proposal.voice_power, proposal.dao_address, msg.sender);

        if (proposal.theme == Themes.transfer_eth) {
            _transfers_eth[proposal_quantity] = execution_eth[0];
            emit executionETHCreated(proposal_quantity, execution_eth[0].recipient, execution_eth[0].value);
        } else if (proposal.theme == Themes.transfer_erc20) {
            _transfers_erc20[proposal_quantity] = execution_erc20[0];
            emit executionERC20Created(proposal_quantity, execution_erc20[0].token_address, execution_erc20[0].recipient, execution_erc20[0].value);
        } else if (proposal.theme == Themes.add_committee) {
            _add_commitees[proposal_quantity] = add_committee[0];
            emit executionAddCommitteeCreated(proposal_quantity, add_committee[0].ethAddress);
        } else if (proposal.theme == Themes.custom_execution) {
            _custom_executions[proposal_quantity] = custom_execution[0];
            emit executionCustomCreated(proposal_quantity, custom_execution[0].execution_contract_address);
        } 

        proposal_quantity += 1;
    }

    /**
     * @dev emits voteSubmited event. Stores data about voting.
     * @param proposal_uid unique id of proposal you want to vote for
     * @param voice boolean value of voting parameter. `true` means that you voting for. `false` - voting against
     * @param voice_amount should be specified if `voice_power` parameter of staking is `staking`. The value will be 
     * ignored if `voice_power` parameter is not `staking`. It means how much ERC20 tokens should be staked to contract when you want to submit your voice
     */
    function vote(uint256 proposal_uid, bool voice, uint256 voice_amount) public notPaused {
        Proposal memory proposal = _proposals[proposal_uid];
        IERC20 dao_token = IERC20(proposal.dao_address);
        require(dao_token.balanceOf(msg.sender) >= proposal.threshold, "Not enouth dao tokens for vote");
        require(!_registered_voice[proposal_uid][msg.sender], "Vote registered");
        require(proposal.start_time <= block.timestamp, "Not started");
        require(proposal.start_time + proposal.period >= block.timestamp, "Finished");
        _registered_voice[proposal_uid][msg.sender] = true;
        _voices[proposal_uid].push(Voice(msg.sender, voice, voice_amount, false));
        _voice[proposal_uid][msg.sender] = Voice(msg.sender, voice, voice_amount, false);
        if (proposal.voice_power == VoicePower.staking) {
            IERC20(proposal.dao_address).transferFrom(msg.sender, address(this), voice_amount);
        }
        emit voteSubmited(proposal_uid, msg.sender, voice, voice_amount);
    }

    /**
     * @dev emits executed event. Stores data about voting.
     * @param proposal_uid id of proposal, which should be executed
     */
    function execute(uint256 proposal_uid) public notPaused {
        Proposal memory proposal = _proposals[proposal_uid];
        require(proposal.start_time + proposal.period <= block.timestamp, "Not finished");
        if (proposal.theme == Themes.add_committee) {
            require(proposal.owner_of == msg.sender || _committees_of_dao[proposal.dao_address][msg.sender], "You are nor proposal creator nor commitee of dao");
        } else {
            require(_committees_of_dao[proposal.dao_address][msg.sender], "You are not a committee of dao");
        }

        uint256 value_for = 0;
        uint256 value_against = 0;

        if (proposal.voice_power == VoicePower.balance) {
            for (uint256 i = 0; i < _voices[proposal_uid].length; i++) {
                Voice memory voice = _voices[proposal_uid][i];
                if (_voices[proposal_uid][i].voice) {
                    value_for += IERC20(proposal.dao_address).balanceOf(voice.ethAddress);
                } else {
                    value_against += IERC20(proposal.dao_address).balanceOf(voice.ethAddress);
                }
            } 
        } else if (proposal.voice_power == VoicePower.staking) {
            for (uint256 i = 0; i < _voices[proposal_uid].length; i++) {
                Voice memory voice = _voices[proposal_uid][i];
                if (_voices[proposal_uid][i].voice) {
                    value_for += voice.voice_amount;
                } else {
                    value_against += voice.voice_amount;
                }
            } 
        }

        bool result;
        if (proposal.percentage == Percentage.absolute_majority) {
            result = value_for > value_against;
        } else if (proposal.percentage == Percentage.qualified_majority) {
            result = ((value_for + value_against) * 100) / value_for > 67;
        }

        if (result) {
            if (proposal.theme == Themes.transfer_eth) {
                payable(_transfers_eth[proposal_uid].recipient).transfer(_transfers_eth[proposal_uid].value);
            } else if (proposal.theme == Themes.transfer_erc20) {
                IERC20(_transfers_erc20[proposal_uid].token_address).transfer(_transfers_erc20[proposal_uid].recipient, _transfers_erc20[proposal_uid].value);
            } else if (proposal.theme == Themes.add_committee) {
                _committees_of_dao[proposal.dao_address][_add_commitees[proposal_uid].ethAddress] = true;
            } else if (proposal.theme == Themes.custom_execution) {
                try IGovernance(_custom_executions[proposal_uid].execution_contract_address).execute() {
                } catch {}
            } 
        }
        _proposals[proposal_uid].accepted = result;
        _proposals[proposal_uid].resolved = true;
        emit executed(proposal_uid, result, true);
    }

    /**
     * @dev emits stakingWithdrawed event. Proceed withdrawing of staking type proposals.
     * @param proposal_uid id of proposal, which should be withdrawed. Claim staking of proposal by address which call the function
     */
    function withdrawStaking(uint256 proposal_uid) public notPaused {
        Proposal memory proposal = _proposals[proposal_uid];
        require(proposal.voice_power == VoicePower.staking, "Proposal voting type is not staking");
        require(proposal.start_time + proposal.period <= block.timestamp, "Not finished");
        require(_registered_voice[proposal_uid][msg.sender], "You dont vote in this proposal");
        require(!_voice[proposal_uid][msg.sender].withdrawed, "This voice has been returned");
        IERC20(proposal.dao_address).transfer(msg.sender, _voice[proposal_uid][msg.sender].voice_amount);
        _voice[proposal_uid][msg.sender].withdrawed = true;
        emit stakingWithdrawed(proposal_uid);
    }

    /**
     * @dev emits proposalWithdrawed event. Proceed withdrawing of unsuccessfull proposals by creator.
     * @param proposal_uid id of proposal, which should be withdrawed. Claim staking of proposal by proposal unique id and address should be creator of proposal.
     */
    function withdrawVoting(uint256 proposal_uid) public notPaused {
        Proposal memory proposal = _proposals[proposal_uid];
        require(proposal.withdrawed, "Already resolved");
        require(proposal.resolved, "Not resolved");
        require(!proposal.accepted, "Governance executed");
        require(proposal.owner_of == msg.sender, "You are not owner of this staking");
        require(proposal.theme == Themes.transfer_eth || proposal.theme == Themes.transfer_erc20, "Custom");
        if (proposal.theme == Themes.transfer_eth) {
            payable(proposal.owner_of).transfer(_transfers_eth[proposal_uid].value);
        } else if (proposal.theme == Themes.transfer_erc20) {
            IERC20(proposal.owner_of).transfer(_transfers_erc20[proposal_uid].recipient, _transfers_erc20[proposal_uid].value);
        }
        _proposals[proposal_uid].withdrawed = true;
        emit proposalWithdrawed(proposal_uid);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGovernance {
    function execute() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @author MetaPlayerOne DAO
 * @title Pausable
 * @notice Contract which manages allocations in MetaPlayerOne.
 */
contract Pausable {
    address internal _owner_of;
    bool internal _paused = false;

    /**
    * @dev setup owner of this contract with paused off state.
    */
    constructor(address owner_of_) {
        _owner_of = owner_of_;
        _paused = false;
    }

    /**
    * @dev modifier which can be used on child contract for checking if contract services are paused.
    */
    modifier notPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    /**
    * @dev function which setup paused variable.
    * @param paused_ new boolean value of paused condition.
    */
    function setPaused(bool paused_) external {
        require(_paused == paused_, "Param has been asigned already");
        require(_owner_of == msg.sender, "Permission address");
        _paused = paused_;
    }

    /**
    * @dev function which setup owner variable.
    * @param owner_of_ new owner of contract.
    */
    function setOwner(address owner_of_) external {
        require(_owner_of == msg.sender, "Permission address");
        _owner_of = owner_of_;
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