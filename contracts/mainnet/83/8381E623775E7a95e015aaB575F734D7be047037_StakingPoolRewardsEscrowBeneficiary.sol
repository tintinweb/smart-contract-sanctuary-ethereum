pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

import "./Escrow.sol";

interface IBeneficiaryContract {
    function __escrowSentTokens(uint256 amount) external;
}

/// @title PhasedEscrow
/// @notice A token holder contract allowing contract owner to set beneficiary of
///         tokens held by the contract and allowing the owner to withdraw the
///         tokens to that beneficiary in phases.
contract PhasedEscrow is Ownable {
    using SafeERC20 for IERC20;

    event BeneficiaryUpdated(address beneficiary);
    event TokensWithdrawn(address beneficiary, uint256 amount);

    IERC20 public token;
    IBeneficiaryContract public beneficiary;

    constructor(IERC20 _token) public {
        token = _token;
    }

    /// @notice Sets the provided address as a beneficiary allowing it to
    ///         withdraw all tokens from escrow. This function can be called only
    ///         by escrow owner.
    function setBeneficiary(IBeneficiaryContract _beneficiary)
        external
        onlyOwner
    {
        beneficiary = _beneficiary;
        emit BeneficiaryUpdated(address(beneficiary));
    }

    /// @notice Withdraws the specified number of tokens from escrow to the
    ///         beneficiary. If the beneficiary is not set, or there are
    ///         insufficient tokens in escrow, the function fails.
    function withdraw(uint256 amount) external onlyOwner {
        require(address(beneficiary) != address(0), "Beneficiary not assigned");

        uint256 balance = token.balanceOf(address(this));
        require(amount <= balance, "Not enough tokens for withdrawal");

        token.safeTransfer(address(beneficiary), amount);
        emit TokensWithdrawn(address(beneficiary), amount);

        beneficiary.__escrowSentTokens(amount);
    }

    /// @notice Funds the escrow by transferring all of the approved tokens
    ///         to the escrow.
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes memory
    ) public {
        require(IERC20(_token) == token, "Unsupported token");
        token.safeTransferFrom(_from, address(this), _value);
    }

    /// @notice Withdraws all funds from a non-phased Escrow passed as
    ///         a parameter. For this function to succeed, this PhasedEscrow
    ///         has to be set as a beneficiary of the non-phased Escrow.
    function withdrawFromEscrow(Escrow _escrow) public {
        _escrow.withdraw();
    }
}

/// @title BatchedPhasedEscrow
/// @notice A token holder contract allowing contract owner to approve a set of
///         beneficiaries of tokens held by the contract, to appoint a separate
///         drawee role, and allowing that drawee to withdraw tokens to approved
///         beneficiaries in phases.
contract BatchedPhasedEscrow is Ownable {
    using SafeERC20 for IERC20;

    event BeneficiaryApproved(address beneficiary);
    event TokensWithdrawn(address beneficiary, uint256 amount);
    event DraweeRoleTransferred(address oldDrawee, address newDrawee);

    IERC20 public token;
    address public drawee;
    mapping(address => bool) private approvedBeneficiaries;

    modifier onlyDrawee() {
        require(drawee == msg.sender, "Caller is not the drawee");
        _;
    }

    constructor(IERC20 _token) public {
        token = _token;
        drawee = msg.sender;
    }

    /// @notice Approves the provided address as a beneficiary of tokens held by
    ///         the escrow. Can be called only by escrow owner.
    function approveBeneficiary(IBeneficiaryContract _beneficiary)
        external
        onlyOwner
    {
        address beneficiaryAddress = address(_beneficiary);
        require(
            beneficiaryAddress != address(0),
            "Beneficiary can not be zero address"
        );
        approvedBeneficiaries[beneficiaryAddress] = true;
        emit BeneficiaryApproved(beneficiaryAddress);
    }

    /// @notice Returns `true` if the given address has been approved as a
    ///         beneficiary of the escrow, `false` otherwise.
    function isBeneficiaryApproved(IBeneficiaryContract _beneficiary)
        public
        view
        returns (bool)
    {
        return approvedBeneficiaries[address(_beneficiary)];
    }

    /// @notice Transfers the role of drawee to another address. Can be called
    ///         only by the contract owner.
    function setDrawee(address newDrawee) public onlyOwner {
        require(newDrawee != address(0), "New drawee can not be zero address");
        emit DraweeRoleTransferred(drawee, newDrawee);
        drawee = newDrawee;
    }

    /// @notice Funds the escrow by transferring all of the approved tokens
    ///         to the escrow.
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes memory
    ) public {
        require(IERC20(_token) == token, "Unsupported token");
        token.safeTransferFrom(_from, address(this), _value);
    }

    /// @notice Withdraws tokens from escrow to selected beneficiaries,
    ///         transferring to each beneficiary the amount of tokens specified
    ///         as a parameter. Only beneficiaries previously approved by escrow
    ///         owner can receive funds.
    function batchedWithdraw(
        IBeneficiaryContract[] memory beneficiaries,
        uint256[] memory amounts
    ) public onlyDrawee {
        require(
            beneficiaries.length == amounts.length,
            "Mismatched arrays length"
        );

        for (uint256 i = 0; i < beneficiaries.length; i++) {
            IBeneficiaryContract beneficiary = beneficiaries[i];
            require(
                isBeneficiaryApproved(beneficiary),
                "Beneficiary was not approved"
            );
            withdraw(beneficiary, amounts[i]);
        }
    }

    function withdraw(IBeneficiaryContract beneficiary, uint256 amount)
        private
    {
        token.safeTransfer(address(beneficiary), amount);
        emit TokensWithdrawn(address(beneficiary), amount);
        beneficiary.__escrowSentTokens(amount);
    }
}

// Interface representing staking pool rewards contract such as CurveRewards
// contract deployed for Keep (0xAF379f0228ad0d46bB7B4f38f9dc9bCC1ad0360c) or
// LPRewards contract from keep-ecdsa repository deployed for Uniswap.
interface IStakingPoolRewards {
    function notifyRewardAmount(uint256 amount) external;
}

/// @title StakingPoolRewardsEscrowBeneficiary
/// @notice A beneficiary contract that can receive a withdrawal phase from a
///         PhasedEscrow contract. Immediately stakes the received tokens on a
///         designated IStakingPoolRewards contract.
contract StakingPoolRewardsEscrowBeneficiary is Ownable, IBeneficiaryContract {
    IERC20 public token;
    IStakingPoolRewards public rewards;

    constructor(IERC20 _token, IStakingPoolRewards _rewards) public {
        token = _token;
        rewards = _rewards;
    }

    function __escrowSentTokens(uint256 amount) external onlyOwner {
        token.approve(address(rewards), amount);
        rewards.notifyRewardAmount(amount);
    }
}

/// @dev Interface of recipient contract for approveAndCall pattern.
interface IStakerRewards {
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes calldata _extraData
    ) external;
}

/// @title StakerRewardsBeneficiary
/// @notice An abstract beneficiary contract that can receive a withdrawal phase
///         from a PhasedEscrow contract. The received tokens are immediately
///         funded for a designated rewards escrow beneficiary contract.
contract StakerRewardsBeneficiary is Ownable {
    IERC20 public token;
    IStakerRewards public stakerRewards;

    constructor(IERC20 _token, IStakerRewards _stakerRewards) public {
        token = _token;
        stakerRewards = _stakerRewards;
    }

    function __escrowSentTokens(uint256 amount) external onlyOwner {
        bool success = token.approve(address(stakerRewards), amount);
        require(success, "Token transfer approval failed");

        stakerRewards.receiveApproval(
            address(this),
            amount,
            address(token),
            ""
        );
    }
}

/// @title BeaconBackportRewardsEscrowBeneficiary
/// @notice Transfer the received tokens to a designated
///         BeaconBackportRewardsEscrowBeneficiary contract.
contract BeaconBackportRewardsEscrowBeneficiary is StakerRewardsBeneficiary {
    constructor(IERC20 _token, IStakerRewards _stakerRewards)
        public
        StakerRewardsBeneficiary(_token, _stakerRewards)
    {}
}

/// @title BeaconRewardsEscrowBeneficiary
/// @notice Transfer the received tokens to a designated
///         BeaconRewardsEscrowBeneficiary contract.
contract BeaconRewardsEscrowBeneficiary is StakerRewardsBeneficiary {
    constructor(IERC20 _token, IStakerRewards _stakerRewards)
        public
        StakerRewardsBeneficiary(_token, _stakerRewards)
    {}
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

// @title Escrow
// @notice A token holder contract allowing contract owner to set beneficiary of
// all tokens held by the contract and allowing the beneficiary to withdraw
// the tokens.
contract Escrow is Ownable {
    using SafeERC20 for IERC20;

    event BeneficiaryUpdated(address beneficiary);
    event TokensWithdrawn(address beneficiary, uint256 amount);

    IERC20 public token;
    address public beneficiary;

    constructor(IERC20 _token) public {
        token = _token;
    }

    // @notice Sets the provided address as a beneficiary allowing it to
    // withdraw all tokens from escrow. This function can be called only
    // by escrow owner.
    function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
        emit BeneficiaryUpdated(beneficiary);
    }

    // @notice Withdraws all tokens from escrow to the beneficiary.
    // If the beneficiary is not set, caller is not the beneficiary, or there
    // are no tokens in escrow, function fails.
    function withdraw() public {
        require(beneficiary != address(0), "Beneficiary not assigned");
        require(msg.sender == beneficiary, "Caller is not the beneficiary");

        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "No tokens to withdraw");

        token.safeTransfer(beneficiary, amount);
        emit TokensWithdrawn(beneficiary, amount);
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

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

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

pragma solidity ^0.5.0;

/**
 * @dev Collection of functions related to the address type,
 */
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

