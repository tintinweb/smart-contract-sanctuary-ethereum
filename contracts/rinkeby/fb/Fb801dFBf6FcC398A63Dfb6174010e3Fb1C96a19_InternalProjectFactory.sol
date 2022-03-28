// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../Project/Department.sol";

contract InternalProjectFactory{


    function createInternalProject(address payable _teamLead,
                                   address _votingAddress,
                                   uint256 _votingDuration,
                                   uint256 _paymentInterval,
                                   uint256[] memory _requestedAmounts,
                                   address[] memory _requestedTokenAddresses) 
    external
    returns(address)
    {

        return address(new InternalProject(
                                msg.sender, // the source.
                                _teamLead,
                                _votingAddress,
                                _votingDuration,
                                _paymentInterval,
                                _requestedAmounts,
                                _requestedTokenAddresses));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Token/IRepToken.sol";
import "../Arbitration/Arbitration.sol";
import "../DAO/IDAO.sol";
import "../Voting/IVoting.sol";

contract InternalProject { 
    // maybe inherit from mutual parent with Project contract.

    // possibility to turn project into ongoing

    enum ProjectType {fixedTerm, ongoing}
    enum ProjectStatus {proposal, active, inactive, completed, rejected}

    ProjectStatus public status;
    ProjectType public projectType;

    // payment after fixed interval.

    /* ========== CONTRACT VARIABLES ========== */

    IVoting public voting;
    IRepToken public repToken;
    ISource public source;
    IERC20 public paymentToken;


    uint256 public startingTime;
    uint256 public votingDuration;
    uint256 public votes_pro;
    uint256 public votes_against;
    uint256 public numberOfVotes;
    uint256 public paymentInterval;

    struct Payout {
        address payee;
        uint256[] erc20Amounts;
        address[] erc20Addresses;
    }

    Payout[] payoutSpecs;

    address payable[] team;
    mapping(address=>bool) _isTeamMember;
    mapping(address=>uint256) public funds;
    address[] public registeredPaymentTokens;
    address payable public teamLead;

    uint256 MILLE = 1000;
    
    event PayrollRosterSubmitted();


    /* ========== CONSTRUCTOR ========== */
                

    constructor(address _sourceAddress,
                address payable _teamLead,
                address _votingAddress,
                uint256 _votingDuration,
                uint256 _paymentInterval,
                uint256[] memory _requestedAmounts,
                address[] memory _requestedTokenAddresses){
                    
        require(_requestedAmounts.length==_requestedTokenAddresses.length);
        paymentInterval = _paymentInterval;
        for (uint256 i; i<_requestedAmounts.length; i++){
            funds[_requestedTokenAddresses[i]] = _requestedAmounts[i];
        }
        registeredPaymentTokens = _requestedTokenAddresses;
        status = ProjectStatus.proposal;
        teamLead = _teamLead;
        team.push(teamLead);
        _isTeamMember[teamLead] = true;
        source = ISource(_sourceAddress);
        repToken = IRepToken(_requestedTokenAddresses[0]);
        startingTime = block.timestamp;
        votingDuration = _votingDuration;
        voting = IVoting(_votingAddress);
        // use default ratio between Rep and Payment
        // PAYMENT OPTIONS ? (A,B  or C)

        // RepSplitting Options
        // _addRepSplittingOption(uint32(250), uint32(750));
        // _addRepSplittingOption(uint32(0), uint32(1000));
    }




     /* ========== VOTING  ========== */


    function voteOnProject(bool decision) external returns(bool){
        // if the duration is less than a week, then set flag to 1
        bool durationCondition = block.timestamp - startingTime > votingDuration;
        bool majorityCondition = votes_pro > repToken.totalSupply() / 2 || votes_against > repToken.totalSupply() / 2;
        if(durationCondition || majorityCondition ){ 
            _registerVote();
            return false;
        }
        uint256 vote = repToken.balanceOf(msg.sender);
        if (decision){
            votes_pro += vote ;// add safeMath
        } else {
            votes_against += vote;  // add safeMath
        }
        numberOfVotes += 1;
        return true;
    }
 

    function registerVote() external {
        bool durationCondition = block.timestamp - startingTime > votingDuration;
        bool majorityCondition = votes_pro > repToken.totalSupply() / 2 || votes_against > repToken.totalSupply() / 2;
        require(durationCondition || majorityCondition, "Voting is still ongoing");
        _registerVote();
    }


    function _registerVote() internal {
        status = (votes_pro > votes_against) ? ProjectStatus.active : ProjectStatus.rejected ;
        if (status == ProjectStatus.active){
            for (uint256 i; i<registeredPaymentTokens.length; i++){
                source.transferToken(registeredPaymentTokens[i], address(this), funds[registeredPaymentTokens[i]]);
            }
        }
    }

    uint256 _totalPaymentValueThisPayroll = 0;
    uint256 _totalRepValueThisPayroll = 0;



    function submitPayrollRoster(address payable[] memory _payees, uint256[][] memory _amounts, address[][] memory _erc20Addresses) external {
        require(msg.sender==teamLead && _payees.length == _amounts.length);
        // TODO: do we need the _payees.length == _amounts.length requirements.
        // Will the contract function call revert if _amounts[i] doesnt exist?
        // If not, then we need to add another row with _repAmount length. 
        require(block.timestamp - source.getStartPaymentTimer() < (paymentInterval * 3) / 4);

        for (uint256 i=0; i<_payees.length; i++){
            payoutSpecs.push(Payout({
                payee: _payees[i],
                erc20Amounts: _amounts[i],
                erc20Addresses: _erc20Addresses[i]
            }));
        }
        
        // uint256 totalPaymentValue = 0;
        // uint256 totalRepValue = 0;
        // for (uint256 i; i<_payees.length; i++){
        //     totalPaymentValue += _amounts[i];
        //     totalRepValue += _repAmounts[i];
        // } 
        // TODO: Maybe check for available funds
        // require(totalPaymentValue <= funds, "Not enough funds in contract");
 
        // payees = _payees;
        // amounts = _amounts;
        // repAmounts = _repAmounts;

        // check whether requested and then approved amount is not exceeded

        emit PayrollRosterSubmitted();  // maybe milestones[milestoneIndex].payrollVetoDeadline
    }
   

    function pay() external returns(uint256 totalPaymentValue, uint256 totalRepValue) {
        require(msg.sender==address(source));

        
        for (uint256 i; i<payoutSpecs.length; i++){
            for (uint256 j; j<payoutSpecs[i].erc20Addresses.length; j++){
                uint256 paymentAmount =  payoutSpecs[i].erc20Amounts[j];
                IERC20(payoutSpecs[i].erc20Addresses[j]).transfer(payoutSpecs[i].payee, paymentAmount);
                funds[payoutSpecs[i].erc20Addresses[j]] -= paymentAmount;
            }
            
        }

        // and set payee amounts to []
        // delete payees;
        // delete amounts;
        // delete repAmounts;
        delete payoutSpecs;
        totalPaymentValue = _totalPaymentValueThisPayroll;
        totalRepValue = _totalRepValueThisPayroll;
        _totalPaymentValueThisPayroll = 0;
        _totalRepValueThisPayroll = 0;

    }    


    function withdraw() external {
        require(msg.sender==address(source));
        for (uint256 i; i<registeredPaymentTokens.length; i++){
            uint256 amount = IERC20(registeredPaymentTokens[i]).balanceOf(address(this));
            IERC20(registeredPaymentTokens[i]).transfer(address(source), amount);
        }
    }


    function freeze() external {
        // lock contract functions until further action.
    }

    function unfreeze() external {
        // unlock contract functions.
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRepToken {
    function mint(address holder, uint256 amount) external;

    function burn(address holder, uint256 amount) external;

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

        /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);



}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract ArbitrationEscrow {
    mapping(address=>uint256) arbrationFee;  // project address => fee
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface ISource {
    function mintRepTokens(address payable payee, uint256 amount) external;
    function transferToken(address _erc20address, address _recipient, uint256 _amount) external; 
    function setPayrollRoster(address payable[] memory _payees, uint256[] memory _amounts) external;
    function getStartPaymentTimer() external returns(uint256);
    function mintRep(uint256 _amount) external;
    function burnRep() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IVoting {
    function start(uint8 _votingType, uint40 _deadline, uint120 _threshold, uint120 _totalAmount) external returns(uint256);
    function vote(uint256 poll_id, address votedBy, address votedOn, uint256 amount) external;
    function safeVote(uint256 poll_id, address votedBy, address votedOn, uint128 amount) external;
    function safeVoteReturnStatus(uint256 poll_id, address votedBy, address votedOn, uint128 amount) external returns(uint8);
    function getStatus(uint256 poll_id) external returns(uint8);
    function getElected(uint256 poll_id) view external returns(address);
    function getStatusAndElected(uint256 poll_id) view external returns(uint8, address);
    function stop(uint256 poll_id) external;
    function retrieve(uint256 poll_id) view external returns(uint8, uint40, uint256, uint256, address);
}