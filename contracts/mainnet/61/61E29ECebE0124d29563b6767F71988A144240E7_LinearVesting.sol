/**
 *Submitted for verification at Arbiscan on 2022-12-01
 */

// File @openzeppelin/contracts/token/ERC20/[email protected]

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IToken {
    function balanceOf(address) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}

/**
 * @dev Implementation of the {ILinearVesting} interface.
 *
 * The straightforward vesting contract that gradually releases a
 * fixed supply of tokens to multiple vest parties over a 13 day
 * window.
 *
 * The token expects the {begin} hook to be invoked the moment
 * it is supplied with the necessary amount of tokens to vest,
 * which should be equivalent to the time the {setComponents}
 * function is invoked on the Vader token.
 */
contract LinearVesting is Ownable {
    uint _TEAM_ALLOCATION = 41_087_886 ether;
    uint _VESTING_DURATION = 4 days;

    struct Vester {
        uint192 amount;
        uint64 lastClaim;
        uint128 start;
        uint128 end;
    }
    /* ========== STATE VARIABLES ========== */

    // The Hamichef token
    IERC20 public immutable hamichef;

    // The start of the vesting period
    uint256 public start;

    // The end of the vesting period
    uint256 public end;

    // The status of each vesting member (Vester)
    mapping(address => Vester) public vest;

    event VestingInitialized(uint256 duration);
    event VestingCreated(address user, uint256 amount);
    event Vested(address indexed from, uint256 amount);

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Initializes the contract's vesters and vesting amounts as well as sets
     * the Vader token address.
     *
     * It conducts a sanity check to ensure that the total vesting amounts specified match
     * the team allocation to ensure that the contract is deployed correctly.
     *
     * Additionally, it transfers ownership to the Vader contract that needs to consequently
     * initiate the vesting period via {begin} after it mints the necessary amount to the contract.
     */
    constructor() {
        hamichef = IERC20(0x9B63DC3DeB9477D563b9B53cD04da78E4262B70b);
    }

    /* ========== VIEWS ========== */

    /**
     * @dev Returns the amount a user can claim at a given point in time.
     *
     * Requirements:
     * - the vesting period has started
     */
    function getClaim(address _vester) external view hasStarted returns (uint256 vestedAmount) {
        Vester memory vester = vest[_vester];
        return _getClaim(vester.amount, vester.lastClaim, vester.start, vester.end);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev Allows a user to claim their pending vesting amount of the vested claim
     *
     * Emits a {Vested} event indicating the user who claimed their vested tokens
     * as well as the amount that was vested.
     *
     * Requirements:
     *
     * - the vesting period has started
     * - the caller must have a non-zero vested amount
     */
    function claim() external returns (uint256 vestedAmount) {
        Vester memory vester = vest[msg.sender];

        require(vester.start != 0, "LinearVesting::claim: Incorrect Vesting Type");

        require(vester.start < block.timestamp, "LinearVesting::claim: Not Started Yet");

        vestedAmount = _getClaim(vester.amount, vester.lastClaim, vester.start, vester.end);

        require(vestedAmount != 0, "LinearVesting::claim: Nothing to claim");

        vester.amount -= uint192(vestedAmount);
        vester.lastClaim = uint64(block.timestamp);

        vest[msg.sender] = vester;

        emit Vested(msg.sender, vestedAmount);

        hamichef.transfer(msg.sender, vestedAmount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @dev Allows the vesting period to be initiated.
     *
     * Emits a {VestingInitialized} event from which the start and
     * end can be calculated via it's attached timestamp.
     *
     * Requirements:
     *
     * - the caller must be the owner (vader token)
     */
    function begin(address[] calldata vesters, uint192[] calldata amounts) external onlyOwner {
        require(vesters.length == amounts.length, "LinearVesting::begin: Vesters and Amounts lengths do not match");

        uint256 _start = block.timestamp;
        uint256 _end = block.timestamp + _VESTING_DURATION;

        start = _start;
        end = _end;

        uint256 total;
        for (uint256 i = 0; i < vesters.length; i++) {
            require(amounts[i] != 0, "LinearVesting::begin: Incorrect Amount Specified");
            require(vesters[i] != address(0), "LinearVesting::begin: Zero Vester Address Specified");
            require(vest[vesters[i]].amount == 0, "LinearVesting::begin: Duplicate Vester Entry Specified");
            vest[vesters[i]] = Vester(amounts[i], 0, uint128(_start), uint128(_end));
            total = total + amounts[i];
        }
        require(total <= _TEAM_ALLOCATION, "LinearVesting::begin: Invalid Vest Amounts Specified");

        require(
            hamichef.balanceOf(address(this)) >= _TEAM_ALLOCATION,
            "LinearVesting::begin: Vader is less than TEAM_ALLOCATION"
        );

        emit VestingInitialized(_VESTING_DURATION);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _getClaim(uint256 amount, uint256 lastClaim, uint256 _start, uint256 _end) private view returns (uint256) {
        if (block.timestamp >= _end) return amount;
        if (lastClaim == 0) lastClaim = _start;

        return (amount * (block.timestamp - lastClaim)) / (_end - lastClaim);
    }

    /**
     * @dev Validates that the vesting period has started
     */
    function _hasStarted() private view {
        require(start != 0, "LinearVesting::_hasStarted: Vesting hasn't started yet");
    }

    /* ========== MODIFIERS ========== */

    /**
     * @dev Throws if the vesting period hasn't started
     */
    modifier hasStarted() {
        _hasStarted();
        _;
    }

    function panic() public onlyOwner {
        // only use if there's an error deploying
        hamichef.transfer(owner(), hamichef.balanceOf(address(this)));
    }

    function somethingAboutTokens(address token) external onlyOwner {
        uint256 balance = IToken(token).balanceOf(address(this));
        IToken(token).transfer(msg.sender, balance);
    }
}