pragma solidity 0.5.7;

import "IERC20.sol";
import "SafeERC20.sol";
import "IRSV.sol";
import "Ownable.sol";
import "Basket.sol";

/**
 * A Proposal represents a suggestion to change the backing for RSV.
 *
 * The lifecycle of a proposal:
 * 1. Creation
 * 2. Acceptance
 * 3. Completion
 *
 * A time can be set during acceptance to determine when completion is eligible.  A proposal can
 * also be cancelled before it is completed. If a proposal is cancelled, it can no longer become
 * Completed.
 *
 * This contract is intended to be used in one of two possible ways. Either:
 * - A target RSV basket is proposed, and quantities to be exchanged are deduced at the time of
 *   proposal execution.
 * - A specific quantity of tokens to be exchanged is proposed, and the resultant RSV basket is
 *   determined at the time of proposal execution.
 */

interface IProposal {
    function proposer() external returns(address);
    function accept(uint256 time) external;
    function cancel() external;
    function complete(IRSV rsv, Basket oldBasket) external returns(Basket);
    function nominateNewOwner(address newOwner) external;
    function acceptOwnership() external;
}

interface IProposalFactory {
    function createSwapProposal(address,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bool[] calldata toVault
    ) external returns (IProposal);

    function createWeightProposal(address proposer, Basket basket) external returns (IProposal);
}

contract ProposalFactory is IProposalFactory {
    function createSwapProposal(
        address proposer,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bool[] calldata toVault
    )
        external returns (IProposal)
    {
        IProposal proposal = IProposal(new SwapProposal(proposer, tokens, amounts, toVault));
        proposal.nominateNewOwner(msg.sender);
        return proposal;
    }

    function createWeightProposal(address proposer, Basket basket) external returns (IProposal) {
        IProposal proposal = IProposal(new WeightProposal(proposer, basket));
        proposal.nominateNewOwner(msg.sender);
        return proposal;
    }
}

contract Proposal is IProposal, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public time;
    address public proposer;

    enum State { Created, Accepted, Cancelled, Completed }
    State public state;
    
    event ProposalCreated(address indexed proposer);
    event ProposalAccepted(address indexed proposer, uint256 indexed time);
    event ProposalCancelled(address indexed proposer);
    event ProposalCompleted(address indexed proposer, address indexed basket);

    constructor(address _proposer) public {
        proposer = _proposer;
        state = State.Created;
        emit ProposalCreated(proposer);
    }

    /// Moves a proposal from the Created to Accepted state.
    function accept(uint256 _time) external onlyOwner {
        require(state == State.Created, "proposal not created");
        time = _time;
        state = State.Accepted;
        emit ProposalAccepted(proposer, _time);
    }

    /// Cancels a proposal if it has not been completed.
    function cancel() external onlyOwner {
        require(state != State.Completed);
        state = State.Cancelled;
        emit ProposalCancelled(proposer);
    }

    /// Moves a proposal from the Accepted to Completed state.
    /// Returns the tokens, quantitiesIn, and quantitiesOut, required to implement the proposal.
    function complete(IRSV rsv, Basket oldBasket)
        external onlyOwner returns(Basket)
    {
        require(state == State.Accepted, "proposal must be accepted");
        require(now > time, "wait to execute");
        state = State.Completed;

        Basket b = _newBasket(rsv, oldBasket);
        emit ProposalCompleted(proposer, address(b));
        return b;
    }

    /// Returns the newly-proposed basket. This varies for different types of proposals,
    /// so it's abstract here.
    function _newBasket(IRSV trustedRSV, Basket oldBasket) internal returns(Basket);
}

/**
 * A WeightProposal represents a suggestion to change the backing for RSV to a new distribution
 * of tokens. You can think of it as designating what a _single RSV_ should be backed by, but
 * deferring on the precise quantities of tokens that will be need to be exchanged until a later
 * point in time.
 *
 * When this proposal is completed, it simply returns the target basket.
 */
contract WeightProposal is Proposal {
    Basket public trustedBasket;

    constructor(address _proposer, Basket _trustedBasket) Proposal(_proposer) public {
        require(_trustedBasket.size() > 0, "proposal cannot be empty");
        trustedBasket = _trustedBasket;
    }

    /// Returns the newly-proposed basket
    function _newBasket(IRSV, Basket) internal returns(Basket) {
        return trustedBasket;
    }
}

/**
 * A SwapProposal represents a suggestion to transfer fixed amounts of tokens into and out of the
 * vault. Whereas a WeightProposal designates how much a _single RSV_ should be backed by,
 * a SwapProposal first designates what quantities of tokens to transfer in total and then
 * solves for the new resultant basket later.
 *
 * When this proposal is completed, it calculates what the weights for the new basket will be
 * and returns it. If RSV supply is 0, this kind of Proposal cannot be used. 
 */

// On "unit" comments, see comment at top of Manager.sol.
contract SwapProposal is Proposal {
    address[] public tokens;
    uint256[] public amounts; // unit: qToken
    bool[] public toVault;

    uint256 constant WEIGHT_SCALE = uint256(10)**18; // unit: aqToken / qToken

    constructor(address _proposer,
                address[] memory _tokens,
                uint256[] memory _amounts, // unit: qToken
                bool[] memory _toVault )
        Proposal(_proposer) public
    {
        require(_tokens.length > 0, "proposal cannot be empty");
        require(_tokens.length == _amounts.length && _amounts.length == _toVault.length,
                "unequal array lengths");
        tokens = _tokens;
        amounts = _amounts;
        toVault = _toVault;
    }

    /// Return the newly-proposed basket, based on the current vault and the old basket.
    function _newBasket(IRSV trustedRSV, Basket trustedOldBasket) internal returns(Basket) {

        uint256[] memory weights = new uint256[](tokens.length);
        // unit: aqToken/RSV

        uint256 scaleFactor = WEIGHT_SCALE.mul(uint256(10)**(trustedRSV.decimals()));
        // unit: aqToken/qToken * qRSV/RSV

        uint256 rsvSupply = trustedRSV.totalSupply();
        // unit: qRSV

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 oldWeight = trustedOldBasket.weights(tokens[i]);
            // unit: aqToken/RSV

            if (toVault[i]) {
                // We require that the execution of a SwapProposal takes in no more than the funds
                // offered in its proposal -- that's part of the premise. It turns out that,
                // because we're rounding down _here_ and rounding up in
                // Manager._executeBasketShift(), it's possible for the naive implementation of
                // this mechanism to overspend the proposer's tokens by 1 qToken. We avoid that,
                // here, by making the effective proposal one less. Yeah, it's pretty fiddly.
                
                weights[i] = oldWeight.add( (amounts[i].sub(1)).mul(scaleFactor).div(rsvSupply) );
                //unit: aqToken/RSV == aqToken/RSV == [qToken] * [aqToken/qToken*qRSV/RSV] / [qRSV]
            } else {
                weights[i] = oldWeight.sub( amounts[i].mul(scaleFactor).div(rsvSupply) );
                //unit: aqToken/RSV
            }
        }

        return new Basket(trustedOldBasket, tokens, weights);
        // unit check for weights: aqToken/RSV
    }
}

pragma solidity 0.5.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity 0.5.7;

import "IERC20.sol";
import "SafeMath.sol";
import "Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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

pragma solidity 0.5.7;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity 0.5.7;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}

pragma solidity 0.5.7;

interface IRSV {
    // Standard ERC20 functions
    function transfer(address, uint256) external returns(bool);
    function approve(address, uint256) external returns(bool);
    function transferFrom(address, address, uint256) external returns(bool);
    function totalSupply() external view returns(uint256);
    function balanceOf(address) external view returns(uint256);
    function allowance(address, address) external view returns(uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // RSV-specific functions
    function decimals() external view returns(uint8);
    function mint(address, uint256) external;
    function burnFrom(address, uint256) external;
    function relayTransfer(address, address, uint256) external returns(bool);
    function relayTransferFrom(address, address, address, uint256) external returns(bool);
    function relayApprove(address, address, uint256) external returns(bool);
}

pragma solidity 0.5.7;

import "Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where there is an account
 * (owner) that can be granted exclusive access to specific functions.
 *
 * This module is used through inheritance by using the modifier `onlyOwner`.
 *
 * To change ownership, use a 2-part nominate-accept pattern.
 *
 * This contract is loosely based off of https://git.io/JenNF but additionally requires new owners
 * to accept ownership before the transition occurs.
 */
contract Ownable is Context {
    address private _owner;
    address private _nominatedOwner;

    event NewOwnerNominated(address indexed previousOwner, address indexed nominee);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current nominated owner.
     */
    function nominatedOwner() external view returns (address) {
        return _nominatedOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        require(_msgSender() == _owner, "caller is not owner");
    }

    /**
     * @dev Nominates a new owner `newOwner`.
     * Requires a follow-up `acceptOwnership`.
     * Can only be called by the current owner.
     */
    function nominateNewOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "new owner is 0 address");
        emit NewOwnerNominated(_owner, newOwner);
        _nominatedOwner = newOwner;
    }

    /**
     * @dev Accepts ownership of the contract.
     */
    function acceptOwnership() external {
        require(_nominatedOwner == _msgSender(), "unauthorized");
        emit OwnershipTransferred(_owner, _nominatedOwner);
        _owner = _nominatedOwner;
    }

    /** Set `_owner` to the 0 address.
     * Only do this to deliberately lock in the current permissions.
     *
     * THIS CANNOT BE UNDONE! Call this only if you know what you're doing and why you're doing it!
     */
    function renounceOwnership(string calldata declaration) external onlyOwner {
        string memory requiredDeclaration = "I hereby renounce ownership of this contract forever.";
        require(
            keccak256(abi.encodePacked(declaration)) ==
            keccak256(abi.encodePacked(requiredDeclaration)),
            "declaration incorrect");

        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

pragma solidity 0.5.7;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.5.7;


/**
 * This Basket contract is essentially just a data structure; it represents the tokens and weights
 * in some Reserve-backing basket, either proposed or accepted.
 *
 * @dev Each `weights` value is an integer, with unit aqToken/RSV. (That is, atto-quantum-Tokens
 * per RSV). If you prefer, you can think about this as if the weights value is itself an
 * 18-decimal fixed-point value with unit qToken/RSV. (It would be prettier if these were just
 * straightforwardly qTokens/RSV, but that introduces unacceptable rounding error in some of our
 * basket computations.)
 *
 * @dev For example, let's say we have the token USDX in the vault, and it's represented to 6
 * decimal places, and the RSV basket should include 3/10ths of a USDX for each RSV. Then the
 * corresponding basket weight will be represented as 3*(10**23), because:
 *
 * @dev 3*(10**23) aqToken/RSV == 0.3 Token/RSV * (10**6 qToken/Token) * (10**18 aqToken/qToken)
 *
 * @dev For further notes on units, see the header comment for Manager.sol.
*/

contract Basket {
    address[] public tokens;
    mapping(address => uint256) public weights; // unit: aqToken/RSV
    mapping(address => bool) public has;
    // INVARIANT: {addr | addr in tokens} == {addr | has[addr] == true}
    
    // SECURITY PROPERTY: The value of prev is always a Basket, and cannot be set by any user.
    
    // WARNING: A basket can be of size 0. It is the Manager's responsibility
    //                    to ensure Issuance does not happen against an empty basket.

    /// Construct a new basket from an old Basket `prev`, and a list of tokens and weights with
    /// which to update `prev`. If `prev == address(0)`, act like it's an empty basket.
    constructor(Basket trustedPrev, address[] memory _tokens, uint256[] memory _weights) public {
        require(_tokens.length == _weights.length, "Basket: unequal array lengths");

        // Initialize data from input arrays
        tokens = new address[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(!has[_tokens[i]], "duplicate token entries");
            weights[_tokens[i]] = _weights[i];
            has[_tokens[i]] = true;
            tokens[i] = _tokens[i];
        }

        // If there's a previous basket, copy those of its contents not already set.
        if (trustedPrev != Basket(0)) {
            for (uint256 i = 0; i < trustedPrev.size(); i++) {
                address tok = trustedPrev.tokens(i);
                if (!has[tok]) {
                    weights[tok] = trustedPrev.weights(tok);
                    has[tok] = true;
                    tokens.push(tok);
                }
            }
        }
        require(tokens.length <= 10, "Basket: bad length");
    }

    function getTokens() external view returns(address[] memory) {
        return tokens;
    }

    function size() external view returns(uint256) {
        return tokens.length;
    }
}