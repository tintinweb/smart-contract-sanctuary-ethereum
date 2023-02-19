/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable
{
    address public owner;
    address private proposedOwner;

    event OwnershipProposed(address indexed newOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor(address _owner) {
        owner = _owner;   // msg.sender;
    }

    /**
    * @dev Returns the bep token owner.
    */
    function getOwner() external view returns (address) {
        return owner;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    /**
    * @dev propose a new owner by an existing owner
    * @param newOwner The address proposed to transfer ownership to.
    */
    function proposeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        proposedOwner = newOwner;
        emit OwnershipProposed(newOwner);
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    */
    function takeOwnership() public {
        require(proposedOwner == msg.sender, "Ownable: not the proposed owner");
        _transferOwnership(proposedOwner);
    }

    /**
    * @dev Transfers control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: zero address not allowed");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

abstract contract Governable is Ownable {

    uint256 public constant RATIO_DECIMALS = 4;  /** ratio decimals */
    uint256 public constant RATIO_PRECISION = 10 ** RATIO_DECIMALS /** ratio precision， 10000 */;
    uint256 public constant MAX_FEE_RATIO = 1 * RATIO_PRECISION - 1; /** max fee ratio, 100% */
    uint256 public constant MIN_APPROVE_RATIO = 6666 ; /** min approve ratio, 66.66% */

    enum ApprovedStatus { NONE, STARTED, APPROVED, OPPOSED }

    event ApproverChanged(address indexed account, bool approve);
    event ProposerChanged(address indexed account, bool on);

    mapping (address => bool) public Approvers;
    uint256 approverCount;

    mapping (address => bool) public Proposers;

    /**
    * @dev Throws if called by any account other than the approver.
    */
    modifier onlyApprover() {
        require(Approvers[msg.sender], "Governable: caller is not the approver");
        _;
    }

    /**
    * @dev Throws if called by any account other than the proposer.
    */
    modifier onlyProposer() {
        require(Proposers[msg.sender], "Governable: caller is not the proposer");
        _;
    }

    function setApprover(address account, bool approve) public onlyOwner {
        if (Approvers[account] != approve) {
            if (approve) {
                Approvers[account] = true;
                approverCount += 1;
            } else {
                delete Approvers[account];
                approverCount -= 1;
            }
            emit ApproverChanged(account, approve);
        }
    }

    function setProposer(address account, bool on) public onlyOwner {
        if (Proposers[account] != on) {

            if (on) {
                Proposers[account] = on;
            } else {
                delete Proposers[account];
            }
            emit ApproverChanged(account, on);
        }
    }

    function _isProposalApproved(uint256 approvedCount) internal view returns(bool) {
        if (approverCount == 0) return false;

        return approvedCount * RATIO_PRECISION / approverCount >= MIN_APPROVE_RATIO;
    }

    function _isProposalOpposed(uint256 opposedCount) internal view returns(bool) {
        if (approverCount == 0) return false;

        return opposedCount  * RATIO_PRECISION / approverCount > RATIO_PRECISION - MIN_APPROVE_RATIO;
    }

    function _existIn(address account, address[] memory accounts) internal pure returns(bool) {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (account == accounts[i]) return true;
        }
        return false;
    }
}


abstract contract Administrable is Governable {

    event AdminProposed(address indexed proposer, address indexed newAdmin);
    event AdminApproved(address indexed proposer,
        address indexed newAdmin,
        address indexed approver,
        bool approved
    );
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    struct ProposalAdminData {
        address     proposer;
        address     admin;
        address[]   approvers;
        address[]   opposers;
    }

    address public admin;
    ProposalAdminData public proposalAdmin;


    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Administrable: caller is not admin");
        _;
    }

    function getProposalAdmin(bool) public view returns(
        address     proposer,
        address     newAdmin,
        address[] memory  approvers,
        address[] memory  opposers,
        ApprovedStatus approvedStatus
    ) {
        ApprovedStatus _approvedStatus =
            _isProposalAdminOpposed()   ? ApprovedStatus.OPPOSED  :
            _isProposalAdminApproved()  ? ApprovedStatus.APPROVED :
            _isProposalAdminApproving() ? ApprovedStatus.STARTED  : ApprovedStatus.NONE;

        return (proposalAdmin.proposer, proposalAdmin.admin, proposalAdmin.approvers,
            proposalAdmin.opposers, _approvedStatus);
    }

    /**
    * @dev propose new admin
    * @param newAdmin propose newAdmin
    */
    function proposeAdmin(address newAdmin) public onlyProposer()  returns(bool) {
        require(newAdmin != address(0), "Administrable: zero address not allowed" );
        require(!_isProposalAdminApproving() || _isProposalAdminOpposed(),
            "Administrable: proposal is approving and not opposed" );

        delete proposalAdmin;

        //proposalAdmin by a proposer for once only otherwise would be overwritten
        proposalAdmin.proposer = msg.sender;
        proposalAdmin.admin = newAdmin;
        emit AdminProposed(msg.sender, newAdmin);
        return true;
    }

    function approveAdmin(address proposer, address newAdmin, bool approved) public onlyApprover() returns(bool) {
        require( proposalAdmin.proposer != address(0) && proposalAdmin.admin != address(0),
            "Administrable: proposal admin data not exist" );
        require( proposer == proposalAdmin.proposer, "Administrable: proposer mismatch" );
        require( newAdmin == proposalAdmin.admin, "Administrable: newAdmin mismatch" );
        require( !_existIn(msg.sender, proposalAdmin.approvers) &&  !_existIn(msg.sender, proposalAdmin.opposers),
            "Administrable: duplicated approve admin" );

        if (approved) {
            proposalAdmin.approvers.push(msg.sender);
        } else {
            proposalAdmin.opposers.push(msg.sender);
        }

        emit AdminApproved(proposer, newAdmin, msg.sender, approved);

        return true;
    }

    function takeAdmin() public returns(bool) {
        require( proposalAdmin.proposer != address(0) && proposalAdmin.admin != address(0),
            "Administrable: proposal admin data not exist" );

        require( !_isProposalAdminOpposed(), "Administrable: proposal has been opposed" );
        require( _isProposalAdminApproved(), "Administrable: approved count not reach min approve ratio yet" );

        address previousAdmin = admin;
        admin = proposalAdmin.admin;

        delete proposalAdmin;

        emit AdminChanged(previousAdmin, admin);

        return true;
    }

    function _isProposalAdminApproved() internal view returns(bool) {
        return _isProposalApproved(proposalAdmin.approvers.length);
    }

    function _isProposalAdminOpposed() internal view returns(bool) {
        return _isProposalOpposed(proposalAdmin.opposers.length);
    }

    function _isProposalAdminApproving() internal view returns(bool) {
         return proposalAdmin.approvers.length > 0 || proposalAdmin.opposers.length > 0;
    }

}

abstract contract Pausable is Administrable {
    uint public lastPauseTime;
    bool public paused;

    constructor() {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");
        // Paused will be false, and lastPauseTime will be 0 upon initialisation
    }

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = block.timestamp;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}

abstract contract Distributable is Pausable {
    using SafeMath for uint256;

    uint256 public constant MIN_DELAY = 31536000; // 1 year in seconds 

    event DistributionProposed(address indexed proposer, uint256 delay);
    event DistributionApproved(address indexed proposer, uint256 delay, address indexed approver, bool approved);
    event DistributionStarted(address indexed proposer, uint256 theDistributionTime);
    event DistributorUpdated(address indexed user, uint256 equity, uint256 withdrawable);

    uint256 public theDistributionTime;
    bool public distributionTimeOn;

    struct DistributeProposal {
        uint256     delayedTime;      // after approval, approved block.timestamp + delayedTime will be set as distributable time 
        address[]   approvers;
        address[]   opposers;
    }

    // proposer -> DistributeProposal
    mapping (address => DistributeProposal) public theDistributeProposals;

    function getDistributeProposal(address proposer) public view returns(
        uint256     timeStamp,
        address[] memory  approvers,
        address[] memory  opposers,
        ApprovedStatus approvedStatus
    ) {
        DistributeProposal memory proposal = theDistributeProposals[proposer];

        ApprovedStatus _approvedStatus =
            _isProposalDistributionOpposed(proposer)   ? ApprovedStatus.OPPOSED  :
            _isProposalDistributionApproved(proposer)  ? ApprovedStatus.APPROVED :
            _isProposalDistributionApproving(proposer) ? ApprovedStatus.STARTED  : ApprovedStatus.NONE;

        return (proposal.delayedTime, proposal.approvers, proposal.opposers, _approvedStatus);
    }

    /**
    * @dev propose to distribute
    * @param timeDelay in seconds after which distribution will begin
    * @return proposer ID
    */
    function proposDistribution(uint256 timeDelay) public onlyProposer() returns(bool) {
        require(timeDelay > MIN_DELAY, "only distributable after 1 year" );

        require(!_isProposalDistributionApproving(msg.sender) || _isProposalDistributionOpposed(msg.sender),
            "proposal is approving and not opposed" );

        delete theDistributeProposals[msg.sender];
        theDistributeProposals[msg.sender].delayedTime = timeDelay;
        emit DistributionProposed(msg.sender, timeDelay);

        return true;
    }

    function approveDistribution(address proposer, uint256 delay, bool approved) public onlyApprover() returns(bool) {
        DistributeProposal storage proposal = theDistributeProposals[proposer];
        require( delay > MIN_DELAY, "proposal delay does not exist" );
        require( proposal.delayedTime == delay, "delay mismatch" );

        require( !_existIn(msg.sender, proposal.approvers) &&  !_existIn(msg.sender, proposal.opposers),
            "duplicated approve" );

        if (approved) {
            proposal.approvers.push(msg.sender);
        } else {
            proposal.opposers.push(msg.sender);
        }

        emit DistributionApproved(proposer, delay, msg.sender, approved);

        return true;
    }

    function distributionStart(address proposer) public onlyProposer() returns(bool) {
        require( theDistributeProposals[proposer].delayedTime > MIN_DELAY, "proposal delay not exist" );
        require( !_isProposalDistributionOpposed(proposer), "proposal has been opposed" );
        require( _isProposalDistributionApproved(proposer), "approved count not reach min approve ratio yet" );

        uint256 delay = theDistributeProposals[proposer].delayedTime;
        delete theDistributeProposals[proposer];
        
        theDistributionTime = delay.add( block.timestamp ) ;
        distributionTimeOn = true;

        emit DistributionStarted(proposer, theDistributionTime);

        return true;
    }

    function _isProposalDistributionApproved(address proposer) internal view returns(bool) {
        return _isProposalApproved(theDistributeProposals[proposer].approvers.length);
    }

    function _isProposalDistributionOpposed(address proposer) internal view returns(bool) {
        return _isProposalOpposed(theDistributeProposals[proposer].opposers.length);
    }

    function _isProposalDistributionApproving(address proposer) internal view returns(bool) {
         return theDistributeProposals[proposer].approvers.length > 0
            || theDistributeProposals[proposer].opposers.length > 0;
    }
}

abstract contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract Everything is ReentrancyGuard, Distributable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */
    address public theGovernanceToken;
    bool public toDistribute;

    // user -> collateral token -> deposit amount
    //    mapping(address => mapping(address => uint256)) public userDeposits;

    IERC20 public collateralToken; 

    // proof of Balance Sheet CID
    uint256 public latestCIDTime;
    string public latestCID;

    // distribution variables
    uint256 public totalEquityMtmTime;
    uint256 public totalEquityAmount;   
    uint256 public totalWithdrawable;

    struct EBalance {
        uint256 mtmTime;  // inclusive of this time
	    uint256 equity;	       // equity at startingTime
        uint256 withdrawable;  // withdrawable amount at startingTime 
    }
    // user -> EBalance
    mapping(address => EBalance) public userEBalance;


    // sending claims variables
    uint256 public claimSendingTime;
    uint256 public cliamMtmTime;
    uint256 public totalClaim;

    struct ApprovedClaim {
        uint256 mtmTime;       // inclusive of this time
        bool approval;
        uint256 withdrawable;  // withdrawable amount at startingTime 
    }
    // user -> ApprovedClaim
    mapping(address => ApprovedClaim) public userClaimsApproved;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
        address _collateralToken
    ) Ownable(_owner) {
        collateralToken = IERC20(_collateralToken);
    }

    /* ========== VIEWS ========== */

    function totalEquity() external view returns (uint256) {
        return totalEquityAmount;
    }

    function balanceOf(address account) external view returns (uint256) {
        require(userEBalance[account].equity <= totalEquityAmount, "equity constraint");
        return userEBalance[account].equity;
    }

    function withdrawable(address account) external view returns (uint256) {
	    uint256 actualAmount = userEBalance[account].withdrawable;
	    require(actualAmount <= userEBalance[account].equity, "balance contraint");
        require(userEBalance[account].equity <= totalEquityAmount, "equity constraint");
        return actualAmount;
    }

    function userClaimAmount(address account, uint256 timeStamp) external view returns (uint256) {
        uint256 sending = userClaimsApproved[account].withdrawable;
	    require(sending > 0, "balance contraint");
        require(userClaimsApproved[account].mtmTime == timeStamp, "time matches");
        return sending;
    }

    function userClaimable(address account, uint256 amount, uint256 timeStamp) external view returns (bool) {
        uint256 sending = userClaimsApproved[account].withdrawable;
        require(sending == amount, "balance contraint");
	    require(sending > 0, "balance contraint");
        require(userClaimsApproved[account].mtmTime == timeStamp, "time matches");
        return userClaimsApproved[account].approval;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function set_governance_token(address govToken) nonReentrant notPaused external onlyOwner {
        theGovernanceToken = govToken;
        toDistribute = false;
    }

    function set_governance(bool test) nonReentrant notPaused external {
        require(msg.sender == theGovernanceToken, "only goverance token");
        toDistribute = test;
    }

    function set_proof_balance_sheet_cid(uint256 timeStamp, string calldata cid) nonReentrant notPaused external onlyOwner {
        latestCIDTime = timeStamp;
        latestCID = cid;

        emit Set_Proof(timeStamp, cid);
    }

    function set_equity(uint256 equityTotal, uint256 withdrawableTotal, uint256 timeStamp) nonReentrant notPaused external onlyOwner {
        totalEquityMtmTime = timeStamp;
        totalEquityAmount = equityTotal;   
        totalWithdrawable = withdrawableTotal;

        emit Set_Equity(equityTotal, withdrawableTotal, timeStamp);
    }

    function update_value(address[] calldata addies, uint256[] calldata equities, uint256[] calldata withdrawables, uint256 timeStamp) nonReentrant notPaused external onlyOwner {
        uint256 addlen = addies.length;
        require(addlen == equities.length, "equity length matches");
        require(addlen == withdrawables.length, "equity length matches");

        for(uint256 i=0; i<addlen; i++) {
            require(addies[i] != address(0), "cannot be 0");

            userEBalance[addies[i]].mtmTime = timeStamp;
            userEBalance[addies[i]].equity = equities[i];
            userEBalance[addies[i]].withdrawable = withdrawables[i];

            emit DistributionUpdated(addies[i], equities[i], withdrawables[i], timeStamp);
        }
    }

    function withdraw(uint256 amount) public nonReentrant notPaused {
	    uint256 askedAmount = Math.min(amount, userEBalance[msg.sender].withdrawable);
        require(askedAmount > 0, "Cannot withdraw 0");
        require(askedAmount <= userEBalance[msg.sender].equity, "amount consistent");
        require(distributionTimeOn, "distribution is allowed");
        require(block.timestamp >= theDistributionTime, "only after distribution time");

        totalEquityAmount.sub(askedAmount);
        totalWithdrawable.sub(askedAmount);
        userEBalance[msg.sender].equity.sub( askedAmount );
        userEBalance[msg.sender].withdrawable.sub( askedAmount );

        collateralToken.safeTransfer(msg.sender, askedAmount);
        emit Withdrawn(msg.sender, askedAmount);
    }

    function update_total_claim(uint256 _totalClaim, uint256 _mtmTime, uint256 _sentTimeDelay) nonReentrant notPaused external onlyOwner {
        totalClaim = _totalClaim;
        cliamMtmTime = _mtmTime;
        //claimSendingTime = _sentTimeDelay.add(block.timestamp);

        emit ClaimTotalUpdated(totalClaim, cliamMtmTime, claimSendingTime);
    }

    function update_claim(address[] calldata addies, uint256[] calldata claims, uint256 timeStamp) nonReentrant notPaused external onlyOwner {
        uint256 addlen = addies.length;
        require(addlen == claims.length, "array length matches");
        for(uint256 i=0; i< addlen; i++) {
            require(addies[i] != address(0), "cannot be 0");

            userClaimsApproved[addies[i]].mtmTime = timeStamp;
            userClaimsApproved[addies[i]].approval = false;
            userClaimsApproved[addies[i]].withdrawable = claims[i];

            emit ClaimUpdated(addies[i], claims[i], timeStamp);
        }
    }

    function approve_claim(address[] calldata addies, uint256[] calldata claims, uint256 timeStamp) nonReentrant notPaused external onlyOwner {
        uint256 addlen = addies.length;
        require(addlen == claims.length, "array length matches");
        for(uint256 i=0; i< addlen; i++) {
            require(addies[i] != address(0), "cannot be 0");
            require(userClaimsApproved[addies[i]].mtmTime == timeStamp, "time matches");
            require(userClaimsApproved[addies[i]].withdrawable == claims[i], "amount matches");
            userClaimsApproved[addies[i]].approval = true;

            emit ClaimApproved(addies[i], claims[i], timeStamp);
        }
    }

    function batchSendToAddress(address[] calldata addies, uint256[] calldata claims, uint256 timeStamp) nonReentrant notPaused external onlyOwner {
        uint256 addlen = addies.length;
        require(addlen == claims.length, "array length matches");
        for(uint256 i=0; i< addlen; i++) {
            address _user = addies[i];
            uint256 _askedAmount = claims[i];
            require(_askedAmount == userClaimsApproved[_user].withdrawable, "amount agree");
            require(_askedAmount > 0, "Cannot send 0");
            require(_askedAmount <= totalClaim, "limited to total claim");
            require(userClaimsApproved[_user].mtmTime == timeStamp, "time matches");
            require(userClaimsApproved[_user].approval, "approved");
            // require(block.timestamp >= claimSendingTime, "only after sending time");

            totalClaim.sub( _askedAmount );
            delete userClaimsApproved[_user];

            collateralToken.safeApprove( _user, _askedAmount);
            collateralToken.safeTransfer(_user, _askedAmount);
            //safeTransferFrom(collateralToken, address(this), _user, _askedAmount);

            emit SentClaimToAddress(_user, _askedAmount);
        }
    }

    function sendToAddress(address _user, uint256 _askedAmount, uint256 _timeStamp) nonReentrant notPaused external onlyOwner {
        require(_askedAmount == userClaimsApproved[_user].withdrawable, "amount agree");
        require(_askedAmount > 0, "Cannot send 0");
        require(_askedAmount <= totalClaim, "limited to total claim");
        require(userClaimsApproved[_user].mtmTime == _timeStamp, "time matches");
        require(userClaimsApproved[_user].approval, "approved");
        require(block.timestamp >= claimSendingTime, "only after sending time");

        totalClaim.sub( _askedAmount );
        delete userClaimsApproved[_user];

        collateralToken.safeApprove( _user, _askedAmount);
        collateralToken.safeTransfer(_user, _askedAmount);

        emit SentClaimToAddress(_user, _askedAmount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */


    /* ========== MODIFIERS ========== */

    // modifier updateAcount(address account, uint256 timeStamp, uint256 equity, uint256 withdrawable) {
    //     if (account != address(0)) {
    //         userEBalance[account].equity = 0;
    //         userEBalance[account].withdrawable = 0;
    //     }
    //     _;
    // }

    /* ========== EVENTS ========== */
    event Set_Proof(uint256 timeStamp, string cid);

    event Set_Equity(uint256 equityTotal, uint256 withdrawableTotal, uint256 timeStamp);
    event DistributionUpdated(address indexed user, uint256 equity, uint256 withdrawable, uint256 timeStamp);
    event Withdrawn(address indexed user, uint256 amount);

    event ClaimTotalUpdated(uint256 totalClaim, uint256 mtmClaim, uint256 claimSentTime);
    event ClaimUpdated(address indexed user, uint256 amount, uint256 timeStamp);  //         emit ClaimUpdated(addone, claim, timeStamp);
    event ClaimApproved(address indexed user, uint256 amount, uint256 timeStamp);
    event SentClaimToAddress(address indexed user, uint256 amount);
}

contract EverythingGov is ReentrancyGuard, Distributable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */
    address public everythingToken;
    bool public toDistribute;

    constructor(
        address _owner
    ) Ownable(_owner) {
        toDistribute = false;
    }

    function setTokenAddress(address every) nonReentrant notPaused external onlyOwner {
        everythingToken = every;
    }

    function setDistribution(bool distribute) nonReentrant notPaused external onlyOwner {
        toDistribute = distribute;
    }

    function changeEverything() nonReentrant notPaused external onlyOwner {
        Everything every = Everything(everythingToken);
        every.set_governance(toDistribute);
    }
}