// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TokenVesting
 */
contract TokenVesting is Ownable, ReentrancyGuard {
    // 1 slot
    uint32 constant START = 1685232000; // Sun May 28 2023 00:00:00 GMT+0000. start time of the vesting period
    uint16 constant SLICE_PERIOD_DAYS = 30; // duration of a slice period for the vesting in days
    address public immutable tokenAddress;
    // 2 slot
    uint256 public vestingSchedulesTotalAmount;

    // Takes 2 slots :(
    struct VestingSchedule {
        uint8 cliffDays;
        uint16 durationDays; // duration of the vesting period in days
        uint112 amountTotal; // total amount of tokens WITHOUT! amountAfterCliff to be released at the end of the vesting
        uint112 released; // amount of tokens released
        //
        uint112 amountAfterCliff;
    }

    mapping(address => VestingSchedule) private vestingSchedules;

    event Clamed(address indexed beneficiary, uint256 amount);
    event ScheduleCreated(
        address indexed beneficiary,
        uint16 durationDays,
        uint112 amount
    );
    event WithdrawedByAdmin(uint256 amount);

    /**
     * @dev Creates a vesting contract.
     * @param _token address of the ERC20 token contract
     */
    constructor(address _token) {
        require(_token != address(0x0));
        tokenAddress = _token;
    }

    /**
     * @notice Creates a new vesting schedule for a beneficiary.
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _durationDays duration in days of the period in which the tokens will vest
     * @param _cliffDays duration in days of cliff
     * @param _amountTotal total amount of tokens to be released at the end of the vesting
     * @param _amountAfterCliff amount after cliff
     */
    function createVestingSchedule(
        address _beneficiary,
        uint16 _durationDays,
        uint8 _cliffDays,
        uint112 _amountTotal,
        uint112 _amountAfterCliff
    ) external onlyOwner {
        require(
            START > uint32(block.timestamp),
            "TokenVesting: forbidden to create a schedule after the start of vesting"
        );
        require(_durationDays > 0, "TokenVesting: duration must be > 0");
        require(_amountTotal > 0, "TokenVesting: amount must be > 0");
        require(
            _durationDays >= uint16(_cliffDays),
            "TokenVesting: duration must be >= cliff"
        );
        // require(
        //     _amountTotal >= _amountAfterCliff,
        //     "TokenVesting: total amount must be >= amount after cliff"
        // );
        vestingSchedules[_beneficiary] = VestingSchedule(
            _cliffDays,
            _durationDays,
            _amountTotal,
            0,
            _amountAfterCliff
        );
        vestingSchedulesTotalAmount += (_amountTotal + _amountAfterCliff);

        emit ScheduleCreated(_beneficiary, _durationDays, _amountTotal);
    }

    /**
     * @notice claim vested amount of tokens.
     */
    function claim() external nonReentrant {
        VestingSchedule storage vestingSchedule = vestingSchedules[msg.sender];
        require(
            vestingSchedule.amountTotal > 0,
            "TokenVesting: only investors can claim"
        );
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        require(vestedAmount > 0, "TokenVesting: nothing to claim");

        // amountAfterCliff - could not be > vestedAmount, because it used in calculation of vestedAmount
        vestingSchedule.released += (uint112(vestedAmount) -
            vestingSchedule.amountAfterCliff);
        vestingSchedule.amountAfterCliff = 0;
        vestingSchedulesTotalAmount -= vestedAmount;
        _safeTransfer(tokenAddress, msg.sender, vestedAmount);

        emit Clamed(msg.sender, vestedAmount);
    }

    /**
     * @notice Computes the vested amount of tokens for the given vesting schedule identifier.
     * @return the vested amount
     */
    function computeReleasableAmount(
        address _beneficiary
    ) external view returns (uint256) {
        return _computeReleasableAmount(vestingSchedules[_beneficiary]);
    }

    /**
     * @notice Returns the vesting schedule information for a given identifier.
     * @return the vesting schedule structure information
     */
    function getVestingSchedule(
        address _beneficiary
    ) external view returns (VestingSchedule memory) {
        return vestingSchedules[_beneficiary];
    }

    /**
     * @dev Returns the amount of tokens that can be withdrawn by the owner.
     * @return the amount of tokens
     */
    function getWithdrawableAmount() external view returns (uint256) {
        return
            _balanceOf(tokenAddress, address(this)) -
            vestingSchedulesTotalAmount;
    }

    /**
     * @dev Computes the releasable amount of tokens for a vesting schedule.
     * @return the amount of releasable tokens
     */
    function _computeReleasableAmount(
        VestingSchedule memory vestingSchedule
    ) internal view returns (uint256) {
        // If the current time is before the cliff, no tokens are releasable.
        uint32 cliffDuration = (uint32(vestingSchedule.cliffDays) * 86400);
        if (uint32(block.timestamp) < START + cliffDuration) {
            return 0;
        }
        // If the current time is after the vesting period, all tokens are releasable,
        // minus the amount already released.
        else if (
            uint32(block.timestamp) >=
            START + (uint32(vestingSchedule.durationDays) * 86400)
        ) {
            return
                uint256(
                    vestingSchedule.amountTotal +
                        vestingSchedule.amountAfterCliff -
                        vestingSchedule.released
                );
        }
        // Otherwise, some tokens are releasable.
        else {
            uint32 vestedSlicePeriods = (uint32(block.timestamp) -
                START -
                cliffDuration) / (uint32(SLICE_PERIOD_DAYS) * 86400); // Compute the number of full vesting periods that have elapsed.
            uint32 vestedSeconds = vestedSlicePeriods *
                (uint32(SLICE_PERIOD_DAYS) * 86400);
            uint256 vestedAmount = (vestingSchedule.amountTotal *
                uint256(vestedSeconds)) /
                ((uint256(vestingSchedule.durationDays) -
                    uint256(vestingSchedule.cliffDays)) * 86400); // Compute the amount of tokens that are vested.
            return
                vestedAmount +
                uint256(vestingSchedule.amountAfterCliff) -
                uint256(vestingSchedule.released); // Subtract the amount already released and return.
        }
    }

    function _safeTransfer(
        address _token,
        address _to,
        uint256 _value
    ) internal {
        // Transfer selector `bytes4(keccak256(bytes('transfer(address,uint256)')))` should be equal to 0xa9059cbb
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(0xa9059cbb, _to, _value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TRANSFER_FAILED"
        );
    }

    function _balanceOf(
        address _token,
        address _account
    ) internal view returns (uint) {
        // balanceOf selector `bytes4(keccak256('balanceOf(address)'))` should be equal to 0x70a08231
        (, bytes memory data) = _token.staticcall(
            abi.encodeWithSelector(0x70a08231, _account)
        );
        return abi.decode(data, (uint));
    }
}