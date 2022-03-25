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

pragma solidity 0.8.6;

import "./interfaces/ITokenVesting.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TokenVestingWarrants is ReentrancyGuard, Ownable {
    ITokenVesting public immutable vestingContract;

    constructor(address aragonAgent, address _vestingContract) {
        require(aragonAgent != address(0), "invalid aragon agent address");
        require(_vestingContract != address(0), "invalid vesting contract address");
        vestingContract = ITokenVesting(_vestingContract);
        _transferOwnership(aragonAgent);
    }

    function addNewSchedule(
        address _recipient,
        uint256 _startTime,
        uint256 _amount,
        uint16 _durationInWeeks,
        uint16 _delayInWeeks
    ) internal {
        uint256 activeVestingId = vestingContract.getActiveVesting(_recipient);
        if (activeVestingId > 0) {
            ITokenVesting.VestingSchedule memory vs = vestingContract.vestingSchedules(activeVestingId);
            require(vs.duration == _durationInWeeks, "vesting duration didn't match");
            require(vs.delay == _delayInWeeks, "vesting delay didn't match");
            _amount += vs.amount;
            vestingContract.removeVestingSchedule(activeVestingId);
        }

        vestingContract.addVestingSchedule(_recipient, _startTime, _amount, _durationInWeeks, _delayInWeeks);
    }

    function addNewSchedules(uint256 startTime) external onlyOwner nonReentrant {
        addNewSchedule(0x1E8Bc927e3e21cc78dAFf453aeb857032EAe4C25, startTime, 49_897_674 * 10**18, 50, 0);
        addNewSchedule(0x3AbE443904BD79BA03e8F5CDe12E211cCE2E8c72, startTime, 7_761_860 * 10**18, 50, 0);
        addNewSchedule(0x3eF7f258816F6e2868566276647e3776616CBF4d, startTime, 7_761_860 * 10**18, 50, 0);
        addNewSchedule(0x29501657ceAd09579991f0674F8d7A20e38a011c, startTime, 7_207_442 * 10**18, 50, 0);
        addNewSchedule(0x3BB9378a2A29279aA82c00131a6046aa0b5F6A79, startTime, 4_435_349 * 10**18, 50, 0);
        addNewSchedule(0xCa7a491524BD6AaD034067F7EBDdc7475aD4e751, startTime, 4_435_349 * 10**18, 50, 0);
        addNewSchedule(0x31476BE87e39722488b9B228284B1Fe0A6deD88c, startTime, 2_772_093 * 10**18, 50, 0);
        addNewSchedule(0x44944113c500d5D656Bc49bd019168F05a238553, startTime, 2_709_091 * 10**18, 50, 0);
        addNewSchedule(0x3A2CE76BCd1B9bC0Dfbe271bbCdc0d599245B2bD, startTime, 2_772_093 * 10**18, 50, 0);
        addNewSchedule(0x8842F97d36913C09d640EB0e187260429E87d78A, startTime, 2_167_273 * 10**18, 50, 0);
        addNewSchedule(0xB88F61E6FbdA83fbfffAbE364112137480398018, startTime, 2_217_674 * 10**18, 50, 0);
        addNewSchedule(0x06AAEa0884eCc5f7A6d1c5ae328db63E5A6e3B5b, startTime, 2_217_674 * 10**18, 50, 0);
        addNewSchedule(0x34Fd314838A4E5E920A073dA05FfFEFC4295aAa3, startTime, 874_133 * 10**18, 50, 0);
        addNewSchedule(0x58791B7d2CFC8310f7D2032B99B3e9DfFAAe4f17, startTime, 794_666 * 10**18, 50, 0);
        addNewSchedule(0xBbb6e8eabFBF4D1A6ebf16801B62cF7Bdf70cE57, startTime, 715_200 * 10**18, 50, 0);
        addNewSchedule(0x0b8b0a626a397aF6448D2a400f4798d897582cD9, startTime, 397_333 * 10**18, 50, 0);
        addNewSchedule(0x59AA30950270Ffd59e9A9166AD1d34Be151BeED7, startTime, 596_000 * 10**18, 50, 0);
        addNewSchedule(0x34bcBCc1F494402C5d9739C26721a0BB386fDCfd, startTime, 397_333 * 10**18, 50, 0);
        addNewSchedule(0xFb3aB0f8542D8f8F9F24b6dD211F31d76999b365, startTime, 317_867 * 10**18, 50, 0);
        addNewSchedule(0x27aaD4D768f91Fa60f824DC3153FaaEc25b06f4D, startTime, 198_667 * 10**18, 50, 0);
        addNewSchedule(0x1afA0452bCa780A54f265290371798130601e23A, startTime, 198_667 * 10**18, 50, 0);
        addNewSchedule(0x5a3338e833D0b947089E7A4cb76f1FdE73702E59, startTime, 198_667 * 10**18, 50, 0);
        addNewSchedule(0x49ca963Ef75BCEBa8E4A5F4cEAB5Fd326beF6123, startTime, 198_667 * 10**18, 50, 0);
        addNewSchedule(0x5Ef418b862a5356C30Ab1eaC52076bdc79Dd2029, startTime, 198_667 * 10**18, 50, 0);
        addNewSchedule(0x26c8208804de8Cae08f367d985a5e0DC3CE639B0, startTime, 198_667 * 10**18, 50, 0);
        addNewSchedule(0x70499eeB16D5D3B6313f5ca2b6c4F17e684e7fE9, startTime, 198_667 * 10**18, 50, 0);
        addNewSchedule(0xCE95E48Bb08346798b56dFdEbecB5DAD5cC8b273, startTime, 309_920 * 10**18, 50, 0);
        addNewSchedule(0x0549613eb7310733dE690e59deEed1289409061d, startTime, 79_466 * 10**18, 50, 0);
        addNewSchedule(0x0060B0f5986185d06100A3F555c28F615A5D0CCe, startTime, 47_680 * 10**18, 50, 0);
        addNewSchedule(0x8dc61C26709159cB5907b38b4659da907e0C4a00, startTime, 39_733 * 10**18, 50, 0);
        addNewSchedule(0x73A540D80AF861645431e60Cf1D9eBc55aEa835b, startTime, 210_007 * 10**18, 50, 0);
        addNewSchedule(0x8de30775Ee5c4164E6754A6280eabe6A5Ad520E0, startTime, 210_007 * 10**18, 50, 0);
        addNewSchedule(0x8e1fb83D27f9eb464472aC7a74c01E89e2fBe99e, startTime, 210_007 * 10**18, 50, 0);
    }

    function updateVestingContractOwner(address aragonAgent) external onlyOwner nonReentrant {
        require(aragonAgent == owner(), "invalid aragon agent address");
        vestingContract.transferOwnership(aragonAgent);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface ITokenVesting {
    struct VestingSchedule {
        bool isValid;
        uint256 startTime;
        uint256 amount;
        uint16 duration;
        uint16 delay;
        uint16 weeksClaimed;
        uint256 totalClaimed;
        address recipient;
    }

    function vestingSchedules(uint256 _vestingId) external view returns (VestingSchedule memory);

    function getActiveVesting(address _recipient) external view returns (uint256);

    function addVestingSchedule(
        address _recipient,
        uint256 _startTime,
        uint256 _amount,
        uint16 _durationInWeeks,
        uint16 _delayInWeeks
    ) external;

    function removeVestingSchedule(uint256 _vestingId) external;

    function transferOwnership(address newOwner) external;
}