// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Interfaces/BAPMethaneInterface.sol";

/**
 * A number of codes are defined as error messages.
 * Codes are resembling HTTP statuses. This is the structure
 * CODE:SHORT
 * Where CODE is a number and SHORT is a short word or phrase
 * describing the condition
 * CODES:
 * 100  contract status: open/closed, depleted. In general for any flag
 *     causing the mint too not to happen.
 * 200  parameters validation errors, like zero address or wrong values
 * 300  User payment amount errors like not enough funds.
 * 400  Contract amount/availability errors like not enough tokens or empty vault.
 * 500  permission errors, like not whitelisted, wrong address, not the owner.
 */
contract BAPVesting is ReentrancyGuard, Ownable {
    address public methContractAdress;
    uint256 public constant totalRewards = 210000000;
    uint256 public totalVested;
    // Emission left is the amount of Meth available for vesting
    // The initial value is maxSupply - totalRewards
    // It should always be less or equal than the total scheduled for vesting
    uint256 public emissionLeft = 327600000;
    BAPMethaneInterface private methContract;

    struct VestingScheduleStruct {
        uint256 totalAllocation;
        uint256 start;
        uint256 duration;
    }
    mapping(address => uint256) public vested;
    mapping(address => VestingScheduleStruct) public vestingWallets;

    constructor(
        address _methContractAdress,
        address treasuryWallet,
        address teamsWallet
    ) {
        methContractAdress = _methContractAdress;
        methContract = BAPMethaneInterface(methContractAdress);
        require(_methContractAdress != address(0), "200:ZERO_ADDRESS");
        require(treasuryWallet != address(0), "200:ZERO_ADDRESS");
        require(teamsWallet != address(0), "200:ZERO_ADDRESS");
        vestingWallets[treasuryWallet] = VestingScheduleStruct(
            187600000, // Distribute 187.76 mill
            block.timestamp + 90 days, // starting in 90 days
            24 * 30 days
        ); // for 24 months
        vestingWallets[teamsWallet] = VestingScheduleStruct(
            140000000, // Distribute 14 mill
            block.timestamp + 180 days, // starting in 180 days
            36 * 30 days
        ); // for 36 months

    }

    function setBAPMethaneAddress(address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "200:ZERO_ADDRESS");
        methContractAdress = contractAddress;
        methContract = BAPMethaneInterface(methContractAdress);
    }

    function addVestingSchedule(
        address wallet,
        uint256 totalAllocation,
        uint256 start,
        uint256 duration
    ) external onlyOwner {
        require(wallet != address(0), "200:ZERO_ADDRESS");
        require(start > block.timestamp, "INVALID VESTING SCHEDULE START TIME");
        require(verifyMethSupply(totalAllocation), "200:ABOVE_SUPPLY");
        if (vestingWallets[wallet].start != 0) {
            emissionLeft -= vestingWallets[wallet].totalAllocation;
        }
        emissionLeft += totalAllocation;
        vestingWallets[wallet] = VestingScheduleStruct(
            totalAllocation,
            start,
            duration
        );
    }

    function verifyMethSupply(uint256 totalAllocation)
        internal
        view
        returns (bool)
    {
        return
            totalRewards + emissionLeft + totalAllocation <=
            methContract.maxSupply();
    }

    function vesting() public nonReentrant {
        require(vestingWallets[msg.sender].start != 0, "200:UNREGISTERED");
        uint256 methAmount = vestingAmount();
        require(methAmount > 0, "Meth Amount is Zero");
        methContract.claim(msg.sender, methAmount);
        vested[msg.sender] += methAmount;
        totalVested += methAmount;
        emissionLeft -= methAmount;
    }

    /**
     * Retrieve vesting amount available for wallet
     */
    function vestingAmount() internal view virtual returns (uint256) {
        require(vestingWallets[msg.sender].start != 0, "200:UNREGISTERED");
        VestingScheduleStruct memory schedule = vestingWallets[msg.sender];
        if (block.timestamp < schedule.start) {
            return 0;
        } else if (block.timestamp > schedule.start + schedule.duration) {
            return schedule.totalAllocation;
        } else {
            return
                (schedule.totalAllocation *
                    (block.timestamp - schedule.start)) /
                vestingWallets[msg.sender].duration;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPMethaneInterface {
  function name() external view returns (string memory);
  function maxSupply() external view returns (uint256);
  function claims(address) external view returns (uint256);
  function claim(address, uint256) external;
  function pay(uint256,uint256) external;
  function treasuryWallet() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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