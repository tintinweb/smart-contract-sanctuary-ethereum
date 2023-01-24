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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    /**
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() external view returns (uint8);
    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
}

contract Vesting is Ownable {
    struct VestingSchedule {
        address receiveAddress;
        uint256 totalAmount;
        uint8[] schedule;
        uint8 vestedCount;
    }

    struct ChangeAddress {
        address newAddress;
        uint8 index;
    }

    address public PKPLToken;
    address public admin;

    uint256 public immutable startDate; // vesting start date
    uint256 public constant ROUND = 2628000; // 1 month = 30.416 days, 1 day = 60 * 60 * 24 seconds
    uint256 public constant DENOMINATOR = 1000;
    uint8 public constant VESTINGPLACECOUNT = 8; // seed, private, public, staking, dao, community rewards, marketing & listing, team

    mapping(uint8 => VestingSchedule) private vestingSchedule;

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier enableVest() {
        require(block.timestamp >= startDate, "vesting is not started");
        _;
    }

    constructor(VestingSchedule[] memory _vestingSchedule, uint256 _startDate, address _admin) {
        // require(_vestingSchedule.length == uint256(VESTINGPLACECOUNT), "invalid schedule");
        for (uint8 i = 0; i < _vestingSchedule.length; i++) {
            // require(getArraySum(_vestingSchedule[i].schedule) == uint8(DENOMINATOR), "invalid schedule percents");
            vestingSchedule[i] = _vestingSchedule[i];
        }

        startDate = _startDate;
        admin = _admin;
    }

    function vestingByIndex(uint8 _index) external onlyAdmin enableVest {
        require(_index < VESTINGPLACECOUNT, "index should be less than vesting place count");
        vesting(_index);
    }

    function vestingAll() external onlyAdmin enableVest {
        for (uint8 i = 0; i < VESTINGPLACECOUNT; i++) {
            vesting(i);
        }
    }

    function changeAdmin(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0), "can't be zero address");
        admin = _newAdmin;
    }

    function changeAddresses(ChangeAddress[] memory _newChangeAddress) external onlyOwner {
        for(uint8 i = 0; i < _newChangeAddress.length; i++) {
            require(_newChangeAddress[i].index < VESTINGPLACECOUNT);
            vestingSchedule[_newChangeAddress[i].index].receiveAddress = _newChangeAddress[i].newAddress;
        }
    }

    function changeTokenAddress(address _pkpl) external onlyOwner {
        require(_pkpl != address(0), "can't be zero address");
        PKPLToken = _pkpl;
    }

    function decimals() public view returns (uint8) {
        return IERC20(PKPLToken).decimals();
    }

    function totalSupply() external view returns (uint256) {
        return IERC20(PKPLToken).totalSupply();
    }

    function balance() external view returns (uint256) {
        return IERC20(PKPLToken).balanceOf(address(this));
    }

    function getArraySum(uint8[] memory _array) private pure returns (uint8 sum_) 
    {
        sum_ = 0;
        for (uint8 i = 0; i < _array.length; i++) {
            sum_ += _array[i];
        }
    }

    function vesting(uint8 _index) private {
        uint8 vestedCount_ = vestingSchedule[_index].vestedCount;
        uint8 scheduleLength_ = uint8(vestingSchedule[_index].schedule.length);
        uint8 nowByMonth = uint8((block.timestamp - startDate) / ROUND) + 1;

        require(scheduleLength_ > vestedCount_, "all token vested");
        require(nowByMonth >= vestedCount_, "vesting for this month is not started");
        uint8 monthsCount = nowByMonth > scheduleLength_ ? scheduleLength_ - vestedCount_ : nowByMonth - vestedCount_;
        uint8 vestingPercent;
        if (monthsCount > 1) {
            for (uint8 i = 0; i < monthsCount; i++) {
                vestingPercent += vestingSchedule[_index].schedule[vestedCount_ + i];
            }
        } else {
            vestingPercent = vestingSchedule[_index].schedule[vestedCount_];
        }

        vestingSchedule[_index].vestedCount += monthsCount;
        IERC20(PKPLToken).transfer(
            vestingSchedule[_index].receiveAddress,
            vestingSchedule[_index].totalAmount * vestingPercent / DENOMINATOR * decimals()
        );
    }
}