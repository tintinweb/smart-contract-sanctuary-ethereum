/**
 * Directory: P2P-Lending/contracts/IcoContract/TrustToken.sol
 * Implements EIP20 token standard: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
pragma solidity ^0.6.0;

import "./EIP20Interface.sol";
import "../SafeMath.sol";

contract TrustToken is EIP20Interface {
    using SafeMath for uint256;

    modifier calledByProposalManagement {
        require(msg.sender == proposalManagement, "Invalid caller");
        _;
    }

    // Whether an address' ICO tokens are locked.
    mapping(address => bool) public isUserLocked;
    // Token balances of ICO participants.
    mapping(address => uint256) private tokenBalances;
    // Invested ether of ICO participants.
    mapping(address => uint256) public etherBalances;
    // Map of true/false permission to transfer tokens from sender->recipient.
    mapping(address => mapping(address => uint256)) public allowed;
    // Whether an address is an ICO participant.
    mapping(address => bool) public isTrustee;

    address public proposalManagement;
    address[] public participants;
    string public name;
    string public symbol;
    //uint256 public totalSupply;
    uint256 public trusteeCount;
    uint256 public goal = 0.1 ether;
    uint256 public contractEtherBalance;
    uint8 public decimals;
    bool public isIcoActive;

    // Event definition for an ICO token transfer.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // Event definition for
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    // Track Participation & ICO Status.
    event Participated();
    event ICOFinished();

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) public {
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
        totalSupply = _initialAmount.mul(10 ** uint256(decimals));
        isIcoActive = true;
    }

    /**
     * @notice Sets the proposalManagement address.
     * @param _management The address of the proposalManagement
     */
    function setManagement(address _management) external {
        if (proposalManagement != address(0)) {
            require(msg.sender == proposalManagement, "Invalid caller");
        }
        proposalManagement = _management;
    }

    /**
     * @notice Locks the tokens of '_user'.
     * @param _user Address of user to lock
     */
    function lockUser(address _user) external calledByProposalManagement returns (bool) {
        isUserLocked[_user] = true;
        return isUserLocked[_user];
    }

    /**
     * @notice Unlocks tokens of a list of users.
     * @param _users List of users to unlock
     */
    function unlockUsers(address[] calldata _users) external calledByProposalManagement {
        for (uint256 i; i < _users.length; i++) {
            isUserLocked[_users[i]] = false;
        }
    }

    /**
     * @notice Invests sender's Ether to become a Trustee and receive tokens when ICO finishes.
     */
    function participate() external payable {

        // Validate parameters.
        require(isIcoActive, "ICO period is inactive");
        require(msg.value > 1 ether, "ICO investment must be at least 1 ether");

        // Check if the investment would be overfund the ICO.
        uint256 allowedToAdd = msg.value;
        uint256 returnAmount;
        if ((contractEtherBalance.add(msg.value)) > goal) {
            // Calculate amount of ether user is allowed to invest.
            allowedToAdd = goal.sub(contractEtherBalance);
            // Calculate excess amount of ether to be returned afterwards.
            returnAmount = msg.value.sub(allowedToAdd);
        }

        // Update state variables to track user's investment.
        etherBalances[msg.sender] = etherBalances[msg.sender].add(allowedToAdd);
        contractEtherBalance = contractEtherBalance.add(allowedToAdd);
        if (!isTrustee[msg.sender]) {
            participants.push(msg.sender);
            isTrustee[msg.sender] = true;
        }

        // Trigger participation event.
        emit Participated();

        // Check if the ICO has met its funding goal.
        if (contractEtherBalance >= goal) {
            isIcoActive = false;
            trusteeCount = participants.length;
            distributeToken();
            emit ICOFinished();
        }

        // Transfer any excess ether back to the user.
        if (returnAmount > 0) {
            msg.sender.transfer(returnAmount);
        }
    }

    /**
     * @notice Sends '_value' amount of tokens (not ether) to '_to' from 'msg.sender'.
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     */
    function transfer(address _to, uint256 _value) public override returns (bool success) {

        // Validate request.
        require(tokenBalances[msg.sender] >= _value, "Insufficient funds");

        // Update state variables to account for the transfer.
        tokenBalances[msg.sender] = tokenBalances[msg.sender].sub(_value);
        tokenBalances[_to] = tokenBalances[_to].add(_value);

        // Trigger transfer event.
        emit Transfer(msg.sender, _to, _value);

        // Check to mark the recipient as a new token holder.
        if (!isTrustee[_to]) {
            trusteeCount = trusteeCount.add(1);
            isTrustee[_to] = true;
        }

        // Check to mark the sender as no longer being a token holder.
        if (tokenBalances[msg.sender] <= 0) {
            trusteeCount = trusteeCount.sub(1);
            isTrustee[msg.sender] = false;
        }

        // Return successfully.
        return true;
    }

    /**
     * @notice Sends '_value' amount of tokens to '_to' from '_from', on the condition it is approved by '_from' (using approve() function).
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {

        // Validate parameters.
        uint256 allowance = allowed[_from][_to];
        require(allowance >= _value || _to == proposalManagement, "User has not allowed you to spend this amount");
        require(tokenBalances[_from] >= _value, "Insufficient balance");

        tokenBalances[_to] = tokenBalances[_to].add(_value);
        tokenBalances[_from] = tokenBalances[_from].sub(_value);
        allowed[_from][_to] = allowed[_from][_to].sub(_value);

        emit Transfer(_from, _to, _value);

        // Check to mark recipient as a new token holder.
        if (!isTrustee[_to]) {
            trusteeCount = trusteeCount.add(1);
            isTrustee[_to] = true;
        }

        // Check to mark the sender as no longer being a token holder.
        if (tokenBalances[_from] <= 0) {
            isTrustee[_from] = false;
            trusteeCount = trusteeCount.sub(1);
        }

        return true;
    }

    /**
     * @notice 'msg.sender' approves '_spender' to spend '_value' of sender's tokens.
     * @param _spender The address of the account able to transfer the tokens
     * @param _value The amount of tokens to be approved for transfer
     */
    function approve(address _spender, uint256 _value) public override returns (bool success) {
        require(balanceOf(msg.sender) >= _value, "Insufficient funds");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @param _owner address of the account owning tokens
     * @param _spender address of the account able to transfer the tokens
     * @return remaining - Amount of remaining tokens allowed to spent
     */
    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * @param _owner The address whose balance will be retrieved
     */
    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return tokenBalances[_owner];
    }

    function getICOParameters()
    public
    view
    returns
    (uint256 icoGoal, uint256 icoEtherBalance, bool isActive, uint256 totalTokenSupply,
        uint256 icoParticipantCount, string memory tokenSymbol, uint256 tokenBalanceUser,
        uint256 etherBalanceUser, string memory icoName, uint256 numDecimals, uint256 numTrustees)
    {
        icoGoal = goal;
        icoEtherBalance = address(this).balance;
        isActive = isIcoActive;
        totalTokenSupply = totalSupply;
        icoParticipantCount = participants.length;
        tokenSymbol = symbol;
        tokenBalanceUser = balanceOf(msg.sender);
        etherBalanceUser = getEtherBalance();
        icoName = name;
        numDecimals = decimals;
        numTrustees = trusteeCount;
    }

    /**
     * @return Getter for ether balance of 'msg.sender'
     */
    function getEtherBalance() public view returns (uint256) {
        return etherBalances[msg.sender];
    }

    /**
     * @notice Distributes tokenSupply between all ICO participants by emitting a transfer event from the ICO contract
     *          to the participant.
     */
    function distributeToken() private {
        for (uint256 i; i < participants.length; i++) {
            tokenBalances[participants[i]] = (etherBalances[participants[i]].mul(totalSupply)).div(contractEtherBalance);
            emit Transfer(address(this), participants[i], tokenBalances[participants[i]]);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// Directory: P2P-Lending/contracts/IcoContract/EIP20Interface.sol
// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
pragma solidity ^0.6.0;

abstract contract EIP20Interface {
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    function balanceOf(address _owner) public virtual view returns (uint256 balance);

    /// @notice Send '_value' token to '_to' from 'msg.sender'
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    function transfer(address _to, uint256 _value) public virtual returns (bool success);

    /// @notice Send '_value' token to '_to' from '_from' on the condition it is approved by '_from'
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);

    /// @notice 'msg.sender' approves '_spender' to spend '_value' tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    function approve(address _spender, uint256 _value) public virtual returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    function allowance(address _owner, address _spender) public virtual view returns (uint256 remaining);

    // Display transactions and approvals
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}