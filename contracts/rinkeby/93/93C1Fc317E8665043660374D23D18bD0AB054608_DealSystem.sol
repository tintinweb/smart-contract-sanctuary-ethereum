// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./DS.sol";
import "./Modifiers.sol";
import "./Utils.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; 

contract DealSystem is Modifiers, Utils{

    function showDealCount()external view returns(uint256){
        return DS.getVar().dealCount;
    }
    function resetCounter() onlyOwner external{
        DS.getVar().dealCount = 0;
    }
    function showAddressContract() view external returns(address){
        return address(this);
    }

   

    using SafeERC20 for IERC20;
    IERC20 _token;

    function addToCounter() external returns(bool){
        uint256 _count = DS.getVar().dealCount + 1;
        if(DS.getVar().deals[_count].amount == 0){
            return false;
        }else{
            DS.getVar().dealCount += 1;
            return true;
        }
    }

    function createDeal(
        address _buyer, 
        address _seller, 
        string memory _title,
        uint256 _amount,
        string memory _coin, 
        uint256 _deadlineInDays

        )external tokenValid(_coin) isWorking wasStopped returns(bool){
            
        uint256 _count = DS.getVar().dealCount + 1;
        require(_buyer != _seller,"Buyer and Seller must be different");
        require(DS.getVar().deals[_count].amount == 0, "This ID already exists");
        require(_amount > 100, "above 100 wei");
        require(_deadlineInDays >= 0 && _deadlineInDays <= 30,"Deadline in days. From 0 to 30");

        DS.getVar().dealCount =  _count; //updating deal counter
        uint256 _newDeadline = deadlineCal(_deadlineInDays, DS.getVar().defaultLifeTime);

        if(_buyer == msg.sender){
        DS.getVar().acceptance[_count]  = DS.agreement(0,0,true,false);
        
        DS.getVar().deals[_count] = DS.metadataDeal(msg.sender, _seller, _title, _amount,
                                                        0, 0, block.timestamp, _newDeadline, _coin, 0, false);

        }else if(_seller == msg.sender){
        DS.getVar().acceptance[_count]  = DS.agreement(0,0,false,true);
        
        DS.getVar().deals[_count] = DS.metadataDeal(_buyer, msg.sender, _title, _amount,
                                                        0, 0, block.timestamp, _newDeadline, _coin, 0, false);

        } else{
            revert("only B or S");
        }
        
        //emit _dealEvent( _current,  _coin,  true);
        return true;
    }

    function acceptDraft(uint256 _dealID, bool _decision)public openDraft(_dealID) isPartTaker(_dealID){
        if(msg.sender == DS.getVar().deals[_dealID].buyer){
            DS.getVar().acceptance[_dealID].buyerAcceptDraft = _decision;
        }
        if(msg.sender == DS.getVar().deals[_dealID].seller){
            DS.getVar().acceptance[_dealID].sellerAcceptDraft = _decision;
        }
        if(DS.getVar().acceptance[_dealID].buyerAcceptDraft == true && 
            DS.getVar().acceptance[_dealID].sellerAcceptDraft == true )
        {
            DS.getVar().deals[_dealID].status = 1;
        }
    }

    function depositGoods(uint256 _dealID)public openDeal(_dealID) isPartTaker(_dealID) goodsInDeal(_dealID){ 
        _token = IERC20 (DS.getVar().tokens[DS.getVar().deals[_dealID].coin]);
        require(_token.allowance(msg.sender, address(this)) >= DS.getVar().deals[_dealID].amount, "increaseAllowance to ERC20 contract");
        require(DS.getVar().deals[_dealID].buyer == msg.sender, "only buyer");


        (bool _success) =_token.transferFrom(msg.sender, address(this), DS.getVar().deals[_dealID].amount);
        if(!_success) revert();
        
        DS.getVar().deals[_dealID].goods += DS.getVar().deals[_dealID].amount;
        
        if(DS.getVar().deals[_dealID].goods == DS.getVar().deals[_dealID].amount){
            DS.getVar().deals[_dealID].goodsCovered = true;
        }else{
            revert("Must send total amount in 1 tx");
        }
        
    }

    function partTakerDecision(uint256 _dealID, uint8 _decision)public isPartTaker(_dealID) openDeal(_dealID){
        require(DS.getVar().deals[_dealID].goods == DS.getVar().deals[_dealID].amount, "Buyer needs send the tokens");
        require((_decision > 0 && _decision < 3), "1 = Accepted, 2 = Cancelled");
        if(msg.sender == DS.getVar().deals[_dealID].buyer){
            DS.getVar().acceptance[_dealID].buyerChoose = _decision;
        }
        if(msg.sender == DS.getVar().deals[_dealID].seller){
            DS.getVar().acceptance[_dealID].sellerChoose = _decision;
        }
    }

    function completeDeal(uint256 _dealID)public isPartTaker(_dealID) openDeal(_dealID) {
        //both want to proceed and finish
        require(msg.sender == DS.getVar().deals[_dealID].seller, "Only Seller");
        require((DS.getVar().acceptance[_dealID].buyerChoose == 1 && DS.getVar().acceptance[_dealID].sellerChoose == 1),"B&S must be agree");

        (bool _flag) = payDeal(_dealID);
        if(!_flag) revert();

    }

    function payDeal(uint256 _dealID)internal openDeal(_dealID) wasStopped returns(bool){
        // TODO> Agregar anti Reentry Guard
        _token = IERC20 (DS.getVar().tokens[DS.getVar().deals[_dealID].coin]);
        uint256 _fee = feeCalculation(DS.getVar().deals[_dealID].amount,  DS.getVar().defaultFee);

        require(_fee >= 0, "Fee > 0");
        require( DS.getVar().deals[_dealID].goods > 0, "No tokens ");
        require( DS.getVar().deals[_dealID].goods ==  DS.getVar().deals[_dealID].amount, "Goods and Amount diff value");

        //closing the Deal as completed
         DS.getVar().deals[_dealID].status = 2;

        (bool flagAmountFee, uint256 _newAmount)= SafeMath.trySub( DS.getVar().deals[_dealID].amount, _fee);
        if(!flagAmountFee) revert();

         DS.getVar().deals[_dealID].goods = 0;
         DS.getVar().acceptance[_dealID].buyerChoose = 3;
         DS.getVar().acceptance[_dealID].sellerChoose = 3;

        // send the Fee to owner
        (bool _success)=_token.transfer(DS.getVar().owner, _fee);
        if(!_success) revert();
        // send to Seller tokens
        (bool _successSeller) = _token.transfer( DS.getVar().deals[_dealID].seller, _newAmount);
        if(!_successSeller) revert();

        return(true);
    }

    function refundBuyer(uint256 _dealID)internal openDeal(_dealID) wasStopped returns(bool){
        // TODO> Agregar anti Reentry Guard
        // TODO> pendiente de testear el calculo del penalty
        _token = IERC20 (DS.getVar().tokens[DS.getVar().deals[_dealID].coin]);
        
        require(DS.getVar().deals[_dealID].goods > 0, "No tokens ");
        require(DS.getVar().deals[_dealID].goods == DS.getVar().deals[_dealID].amount, "Goods and Amount diff value");

        DS.getVar().deals[_dealID].status = 3; //cancel
        uint256 _refundAmount = DS.getVar().deals[_dealID].goods;
        DS.getVar().deals[_dealID].goods = 0;
        DS.getVar().acceptance[_dealID].buyerChoose = 4;
        DS.getVar().acceptance[_dealID].sellerChoose = 4;
        
        uint256 _newPenalty = (DS.getVar().defaultPenalty * 10 ** DS.getVar().tokenDecimal[DS.getVar().deals[_dealID].coin]);
        (bool flagPenalty, uint256 _newamount)= SafeMath.trySub(_refundAmount, _newPenalty);
        if(!flagPenalty) revert();

        uint256 _penaltyFee = _refundAmount -= _newamount;
        // send the Fee to owner
        (bool _success)=_token.transfer(DS.getVar().owner, _penaltyFee);
        if(!_success) revert();
       
        (bool _successBuyer)= _token.transfer(DS.getVar().deals[_dealID].buyer, _newamount);
        if(!_successBuyer) revert();

        return(true);
    }

    function cancelDeal(uint256 _dealID)public isPartTaker(_dealID) openDeal(_dealID) {
        //both want to cancel and finish
        require(msg.sender == DS.getVar().deals[_dealID].buyer,"Only Buyer");
        require((DS.getVar().acceptance[_dealID].buyerChoose == 2 && 
                DS.getVar().acceptance[_dealID].sellerChoose == 2),"B&S must be agree");
            
        (bool _flag) = refundBuyer(_dealID);
        if(!_flag) revert();

    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
pragma solidity ^0.8.8;

import "./DS.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; 

contract Utils{

    function feeCalculation(uint256 _amount, uint256 _defaultFee)internal pure returns (uint256){

        (bool flagMultiply,uint256 mult) = SafeMath.tryMul(_amount, _defaultFee);
        if(!flagMultiply) revert();
        
        (bool flagDiv, uint256 _fee) = SafeMath.tryDiv(mult,10000);
        if(!flagDiv) revert();

        (bool flagAmountFee, uint256 _diff)= SafeMath.trySub(_amount, _fee);
        if(!flagAmountFee) revert();

        (bool flagFee, uint256 _newAmount)= SafeMath.trySub(_amount, _diff);
        if(!flagFee) revert();
        return(_newAmount);
    }

    function deadlineCal(uint256 _deadlineInDays, uint256 defaultLifeTime)internal view returns(uint256){
        // MODIFIED FOR FAST TEST, PENDING TO REMOVE COMMENTS
        if(_deadlineInDays > 0){
            (bool _flagMul,uint256 secs) = SafeMath.tryMul(_deadlineInDays, 86400);
            if(!_flagMul) revert();

            (bool _flagAdd, uint256 _newDeadline) = SafeMath.tryAdd(secs,block.timestamp);
            if(!_flagAdd) revert();

            return(_newDeadline);
        }else{
            (bool _flagAddDeadline, uint256 _defaultDeadline) = SafeMath.tryAdd(0, block.timestamp);//SafeMath.tryAdd(defaultLifeTime, block.timestamp);
            if(!_flagAddDeadline) revert();
            defaultLifeTime; //DELETE AFTER TESTING
            return(_defaultDeadline); 
        }
    }

    function daysToSecs(uint256 _days)internal pure returns(uint256){
        (bool _flagMul,uint256 _secs) = SafeMath.tryMul(_days, 86400);
            if(!_flagMul) revert();
        return _secs;
    }

    function seeProposals(uint _dealId, uint _proposalId) internal  view returns(uint256, uint256, uint16, string memory, uint256, uint256, bool){
        DS.proposal memory _info = DS.getVar().updates[_dealId].proposalsInfo[_proposalId];
        return(_info.created,_info.proposalType,_info.accepted, _info.infOrTitle, _info.timeInDays, _info.subOrAddToken, _info.proposalStatus);
    }

    function fillutils()external{}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./DS.sol";

contract Modifiers{

    modifier onlyOwner(){
        require(DS.getVar().owner == msg.sender, "Only OWNER");
        _;
    }
    modifier onlyOracle(){
        require(DS.getVar().oracle == msg.sender, "Only ORACLE");
        _;
    }
    modifier onlyTribunal(){
        require(DS.getVar().tribunal == msg.sender, "Only TRIBUNAL");
        _;
    }
    modifier tokenValid(string memory _tokenName){
        require(DS.getVar().tokens[_tokenName] != address(0),"token NOT supported");
        _;
    }
    // Validate Only the buyer or seller can edit
    modifier isPartTaker(uint256 _dealID){
        require(((msg.sender == DS.getVar().deals[_dealID].buyer)||(msg.sender == DS.getVar().deals[_dealID].seller)),
        "You are not part of the deal");
        _;
    }
    // Validate the Deal status still OPEN
    modifier openDeal(uint256 _dealID){
        require(DS.getVar().deals[_dealID].status == 1," DEAL are not OPEN");
        _;
    }

    // Validate the Deal status is a DRAFT
    modifier openDraft(uint256 _dealID){
        require(DS.getVar().deals[_dealID].status == 0," DRAFT are not PENDING");
        _;
    }
    
    modifier goodsInDeal(uint256 _dealID){
        require(!DS.getVar().deals[_dealID].goodsCovered);
        _;
    }

    modifier isWorking(){
        require(DS.getVar().contractWorking == true, "Contract turned OFF");
        _;
    }

    modifier wasStopped(){
        require(DS.getVar().emergencyStop == false, "Contract stopped for emergency ");
        _;
    }

    function fill()external{

    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

library DS{

    //bytes32 internal constant NAMESPACE = keccak256("deploy.1.var.diamondstorage");
    bytes32 internal constant NAMESPACE = keccak256("test.1.var.diamondstorage");

    struct Appstorage{
        uint256 defaultLifeTime;
        uint256 defaultFee;
        uint256 defaultPenalty;
        address payable owner;
        address oracle;
        address tribunal;

        // map tokens contract
        mapping(string => address)  tokens;     
        // map tokens contract > decimals
        mapping(string => uint)  tokenDecimal;
        // deal ID to metadata Deal 
        mapping(uint256 => metadataDeal) deals;
        // deal ID to partTake choose
        mapping(uint256 => agreement) acceptance;
        
        uint256 dealCount;
        // deal ID to history updates
        mapping(uint256 => historyUpdates) updates;
        bool emergencyStop;
        bool contractWorking;
    }

    struct metadataDeal{
        address buyer; 
        address seller; 
        string title;
        uint256 amount; 
        uint256 goods; 
        uint16 status; //0=pending, 1= open, 2= completed, 3= cancelled, 4= OracleForce
        uint256 created;
        uint256 deadline; // timestamp
        string coin;
        uint256 numOfProposals;
        bool goodsCovered;
    }

    // (0 = No answer, 1 = Accepted, 2 = Cancelled, 3 = Paid, 4 = Refund)
    struct agreement{
        uint8 buyerChoose;
        uint8 sellerChoose;
        bool buyerAcceptDraft;
        bool sellerAcceptDraft;
    }

    struct historyUpdates{
        uint256 lastUpdateId;
        uint8 buyerChoose;
        uint8 sellerChoose;
        //
        mapping(uint256 => proposal) proposalsInfo;
    }

    struct proposal{
        uint256 created;
        uint256 proposalType; // 0 = informative, 1 = update deadline, 2=update title, 3=discount, 4=addtokens
        uint16 accepted; //(0 = No answer, 1 = Accepted, 2 = Cancelled, 3 =  No changes, 4 = updated)
        string infOrTitle;
        uint256 timeInDays;
        uint256 subOrAddToken;
        bool proposalStatus;
    }

    function getVar() internal pure returns (Appstorage storage s){
        bytes32 position = NAMESPACE;
        assembly{
            s.slot := position
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}