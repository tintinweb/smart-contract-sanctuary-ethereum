// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../utils/KarmSentry.sol";

import "../interfaces/iKarmToken.sol";

contract KarmGovernanceV1 is KarmSentry {
    using SafeMath for uint256;

    iKarmToken private MDT;

    uint256 private minHolding;

    uint256 private voteDuration;

    enum ProposalStatus { Inactive, Active, Passed, Executed, Cancelled }

    enum VoteStatus { Abstain, Yes, No }

    uint256 private quorum; // Quorum in percentage of total voted population and 1000000 as 100%

    uint256 private proposalCounter;

    mapping ( uint256 => proposalStruct ) private proposals;

    struct proposalStruct{
        address[] to;
        bytes[] data;
        uint256 totalVotes;
        uint256 Yes;
        uint256 No;
        uint256 StartBlock;
        ProposalStatus status;
    }

    mapping ( uint256 => mapping ( uint256 => returnStruct ) ) private proposalReturns;

    struct returnStruct{
        bool status;
        bytes returnValue;
    }

    modifier isValidHolding( ){
        require(MDT.balanceOf(msg.sender) >= minHolding , "KarmGovernance : Not enough tokens to raise proposal");
        _;
    }

    modifier isActiveProposal( uint256 _proposal ){
        require(proposals[_proposal].StartBlock+voteDuration >= block.number , "KarmGovernance : Voting time passed");
        require(MDT.balanceOf(msg.sender) >= 0 , "KarmGovernance : Not enough balance for voting");
        _;
    }

    modifier isValidUpdate( uint256 _proposal ){
        require(proposals[_proposal].StartBlock+voteDuration <= block.number , "KarmGovernance : Voting time still active");
        require(proposals[_proposal].status == ProposalStatus.Active , "KarmGovernance : Proposal must be active");
        _;
    }

    modifier isValidExecute( uint256 _proposal ){
        require(proposals[_proposal].status == ProposalStatus.Passed , "KarmGovernance : Proposal must be Passed");
        _;
    }

    constructor( address _parent ) KarmSentry() {
        MDT = iKarmToken(_parent);
        quorum = 100000;
        voteDuration = 100;
    }

    function activation( address _gov ) external {
        activate(_gov);
    }

    function initProposal( address[] memory _to , bytes[] memory _data ) external isValidHolding {
        require(_to.length == _data.length ,"KarmGovernance : Array Length mismatch");
        proposalCounter = proposalCounter + 1;
        proposals[proposalCounter] = proposalStruct(_to ,  _data , 0 ,0 ,0 ,block.number ,ProposalStatus.Active);
    }

    function CastVote( uint256 _proposal , VoteStatus v1) external isActiveProposal(_proposal) {
        uint256 bal = MDT.balanceOf(msg.sender);
        proposals[_proposal].totalVotes = proposals[_proposal].totalVotes + bal;
        if (v1 == VoteStatus.Yes ){
            proposals[_proposal].Yes = proposals[_proposal].Yes + bal;
        }else if ( v1 == VoteStatus.No ){
            proposals[_proposal].No = proposals[_proposal].No + bal;
        }
    }

    function updateProposal( uint256 _proposal ) external  isValidUpdate(_proposal) {
        bool result = isPassed(_proposal);
        if( result == true ){
            proposals[_proposal].status = ProposalStatus.Passed;

        }else{
            proposals[_proposal].status = ProposalStatus.Cancelled;
        }
    }

    function isPassed( uint256 _proposal ) internal view returns( bool ){
        uint256 totalVotes = proposals[_proposal].totalVotes;
        uint256 totalYes = proposals[_proposal].Yes;
        uint256 percent = ( ( totalYes * 1000000 ) / totalVotes );
        if ( percent > quorum) {
            return true;
        }else{
            return false;
        }
    }

    function executeProposal( uint256 _proposal ) external isValidExecute(_proposal) {
        uint256 length = proposals[_proposal].to.length;
        for ( uint256 i = 0; i < length; i = i+1 ) {
            address caller = proposals[_proposal].to[i];
            ( bool _success , bytes memory _return ) = caller.call( proposals[_proposal].data[i] );
            proposalReturns[_proposal][i] = returnStruct( _success , _return );
        }
        proposals[_proposal].status = ProposalStatus.Executed;
    }

    function setMinHolding( uint256 _holding ) external isGov {
        minHolding = _holding;
    }

    function setVoteDuration( uint256 _duration ) external isGov {
        voteDuration = _duration;
    }

    function setQuorum( uint256 _quorum ) external isGov {
        quorum = _quorum;
    }

    function fetchProposal( uint256 _proposal ) external view returns ( proposalStruct memory ){
        return proposals[_proposal];
    }

    function fetchMetaDaoToken() external view returns ( iKarmToken  ){
        return MDT;
    }

    function fetchMinHolding() external view returns ( uint256 ){
        return minHolding;
    }

    function fetchVoteDuration() external view returns ( uint256 ){
        return voteDuration;
    }

    function fetchQuorum() external view returns ( uint256 ){
        return quorum;
    }

    function fetchProposalCounter() external view returns ( uint256 ){
        return proposalCounter;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KarmSentry {

    address private Governance;

    address private deployer;

    bool private active;

    modifier isDeployer(){
        require(msg.sender == deployer, "KarmSentry: Sender is not deployer");
        _;
    }

    modifier isInActive(){
        require(active == false, "KarmSentry: contract is active");
        _;
    }

    modifier isActive(){
        require(active == true, "KarmSentry: contract is not active");
        _;
    }

    modifier isGov() {
        require( msg.sender == Governance , "KarmSentry: Invalid Governance Address");
        _;
    }

    constructor ( ) {
        deployer = msg.sender;
        active = false;
    }

    function activate( address _Governance ) internal isDeployer isInActive {
        deployer = address(0);
        Governance = _Governance;
        active = true;
    }

    function fetchGovernance( ) external view returns ( address ) {
        return Governance;
    }

    function fetchDeployer( ) external view returns ( address ) {
        return deployer;
    }

    function fetchActive( ) external view returns ( bool ) {
        return active;
    }

    function setGovernance( address _governance ) external isGov isActive {
        require( Governance != address(this) , "KarmSentry : Cant Governance of MetaDAOCouncil");
        Governance = _governance;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface iKarmToken is IERC20 {

    function createSnapshot() external returns (uint256);

    function pauseToken() external returns (bool);

    function unpauseToken() external returns (bool);

    function mint(address _to, uint256 _value) external returns (bool);

    function burn(address _to, uint256 _value) external returns (bool);

    function freeze(address _to) external returns (bool);

    function unfreeze(address _to) external returns (bool);

    function isFrozen(address _to) external view returns (bool);

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