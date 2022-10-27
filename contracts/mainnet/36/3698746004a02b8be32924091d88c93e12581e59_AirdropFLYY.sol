/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

interface ITokenVestingFLYY {
    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        uint256 _amount
    ) external;
}

contract AirdropFLYY is Ownable, ReentrancyGuard {
    IERC20 public tokenContractAddress =
        IERC20(0xd324Ba09f83A109da048001bBFb0E84C9733150E);
    uint8 private _tokenDecimals = 18;

    ITokenVestingFLYY public vestingContractAddress =
        ITokenVestingFLYY(0xE7FafeBd53Def137595aB6B7697D76F49b2073f6);
    uint8 unlockedPercentageTGE = 10;
    uint256 vestingCliff = 7889229;
    uint256 vestingStart = block.timestamp;
    uint256 vestingDuration = 31556916;
    uint256 vestingSlicePeriodSeconds = 2629743;

    mapping(address => bool) private _isIncludedInWhitelist;
    mapping(address => uint8) private _addressToPotNumber;
    uint256 public claimStartTime = 0;

    uint256 private _pot1TokenRewards = 280 * 10**_tokenDecimals;
    uint256 private _pot2TokenRewards = 300 * 10**_tokenDecimals;
    uint256 private _pot3TokenRewards = 800 * 10**_tokenDecimals;
    uint256 private _pot4TokenRewards = 1600 * 10**_tokenDecimals;
    uint256 private _pot5TokenRewards = 5000 * 10**_tokenDecimals;

    uint256 private _pot1ClaimPeriod = 432000;
    uint256 private _pot2ClaimPeriod = 172800;
    uint256 private _pot3ClaimPeriod = 172800;
    uint256 private _pot4ClaimPeriod = 172800;
    uint256 private _pot5ClaimPeriod = 172800;

    event WinnerTokensClaimed(address, uint256);
    event VestingScheduleChanged(uint8, uint256, uint256, uint256, uint256);

    modifier checkWhitelisting(address caller) {
        require(
            _isIncludedInWhitelist[caller],
            "AirdropFLYY: calling account address must be whitelisted first"
        );
        _;
    }

    constructor() {}

    function getAllPotsTokenRewards()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _pot1TokenRewards,
            _pot2TokenRewards,
            _pot3TokenRewards,
            _pot4TokenRewards,
            _pot5TokenRewards
        );
    }

    function getAllPotsClaimPeriods()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _pot1ClaimPeriod,
            _pot2ClaimPeriod,
            _pot3ClaimPeriod,
            _pot4ClaimPeriod,
            _pot5ClaimPeriod
        );
    }

    function changePotTokenRewardsAndClaimPeriod(
        uint8 potNumber,
        uint256 newTokenRewards,
        uint256 newClaimPeriod
    ) external onlyOwner returns (bool) {
        require(
            potNumber > 0 && potNumber < 6,
            "AirdropFLYY: pot number must be between 1 to 5"
        );
        if (potNumber == 1) {
            _pot1TokenRewards = newTokenRewards;
            _pot1ClaimPeriod = newClaimPeriod;
        } else if (potNumber == 2) {
            _pot2TokenRewards = newTokenRewards;
            _pot2ClaimPeriod = newClaimPeriod;
        } else if (potNumber == 3) {
            _pot3TokenRewards = newTokenRewards;
            _pot3ClaimPeriod = newClaimPeriod;
        } else if (potNumber == 4) {
            _pot4TokenRewards = newTokenRewards;
            _pot4ClaimPeriod = newClaimPeriod;
        } else {
            _pot5TokenRewards = newTokenRewards;
            _pot5ClaimPeriod = newClaimPeriod;
        }

        return true;
    }

    function changeClaimAndVestingStartTime(
        uint256 newClaimStartTime,
        uint256 newVestingStartTime
    ) external onlyOwner returns (bool) {
        claimStartTime = newClaimStartTime;
        vestingStart = newVestingStartTime;

        return true;
    }

    function changeVestingContractAddress(address newContractAddress)
        external
        onlyOwner
        returns (bool)
    {
        vestingContractAddress = ITokenVestingFLYY(newContractAddress);

        return true;
    }

    function changeTokenContractAddress(address newContractAddress)
        external
        onlyOwner
        returns (bool)
    {
        tokenContractAddress = IERC20(newContractAddress);

        return true;
    }

    function changeVestingSchedule(
        uint8 _unlockedPercentageTGE,
        uint256 _vestingCliff,
        uint256 _vestingStart,
        uint256 _vestingDuration,
        uint256 _vestingSlicePeriodSeconds
    ) external onlyOwner returns (bool) {
        require(
            _unlockedPercentageTGE <= 100,
            "AirdropFLYY: unlocked TGE percentage must not be greater than 100"
        );

        unlockedPercentageTGE = _unlockedPercentageTGE;
        vestingCliff = _vestingCliff;
        vestingStart = _vestingStart;
        vestingDuration = _vestingDuration;
        vestingSlicePeriodSeconds = _vestingSlicePeriodSeconds;

        emit VestingScheduleChanged(
            _unlockedPercentageTGE,
            _vestingCliff,
            _vestingStart,
            _vestingDuration,
            _vestingSlicePeriodSeconds
        );

        return true;
    }

    function getVestingSchedule()
        external
        view
        returns (
            uint8,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            unlockedPercentageTGE,
            vestingCliff,
            vestingStart,
            vestingDuration,
            vestingSlicePeriodSeconds
        );
    }

    function claimToken()
        external
        nonReentrant
        checkWhitelisting(_msgSender())
        returns (bool)
    {
        _claimToken();

        return true;
    }

    function _claimToken() private {
        address beneficiary = _msgSender();
        uint8 beneficiaryPotNumber = _addressToPotNumber[beneficiary];
        uint256 claimableRewards;
        uint256 potClaimPeriod;

        if (beneficiaryPotNumber == 1) {
            claimableRewards = _pot1TokenRewards;
            potClaimPeriod = _pot1ClaimPeriod;
        } else if (beneficiaryPotNumber == 2) {
            claimableRewards = _pot2TokenRewards;
            potClaimPeriod = _pot2ClaimPeriod;
        } else if (beneficiaryPotNumber == 3) {
            claimableRewards = _pot3TokenRewards;
            potClaimPeriod = _pot3ClaimPeriod;
        } else if (beneficiaryPotNumber == 4) {
            claimableRewards = _pot4TokenRewards;
            potClaimPeriod = _pot4ClaimPeriod;
        } else {
            claimableRewards = _pot5TokenRewards;
            potClaimPeriod = _pot5ClaimPeriod;
        }

        require(
            (claimStartTime + potClaimPeriod) > block.timestamp,
            "AirdropFLYY: claim period already passed"
        );
        require(
            getContractTokenBalance() >= claimableRewards,
            "AirdropFLYY: claimable rewards exceed contract token balance"
        );

        uint256 unlockedShareTGE = (claimableRewards * unlockedPercentageTGE) /
            100;
        uint256 vestingShare = claimableRewards - unlockedShareTGE;

        if (unlockedShareTGE > 0) {
            tokenContractAddress.transfer(beneficiary, unlockedShareTGE);
        }
        if (vestingShare > 0) {
            _sendToVesting(beneficiary, vestingShare);
        }

        _isIncludedInWhitelist[beneficiary] = false;
        _addressToPotNumber[beneficiary] = 0;

        emit WinnerTokensClaimed(beneficiary, claimableRewards);
    }

    function _sendToVesting(address beneficiary, uint256 amount) private {
        if (vestingCliff == 1 && vestingDuration == 1) {
            require(
                tokenContractAddress.transfer(beneficiary, amount),
                "AirdropFLYY: token FLYY transfer to winner not succeeded"
            );
        } else {
            require(
                tokenContractAddress.approve(
                    address(vestingContractAddress),
                    amount
                ),
                "AirdropFLYY: token FLYY approve to vesting contract not succeeded"
            );
            vestingContractAddress.createVestingSchedule(
                beneficiary,
                vestingStart,
                vestingCliff,
                vestingDuration,
                vestingSlicePeriodSeconds,
                amount
            );
        }
    }

    function getContractTokenBalance() public view returns (uint256) {
        return tokenContractAddress.balanceOf(address(this));
    }

    function withdrawContractTokenBalance(uint256 amount) external onlyOwner {
        require(
            getContractTokenBalance() >= amount,
            "TokenVestingFLYY: withdrawable funds exceed contract token balance"
        );
        tokenContractAddress.transfer(owner(), amount);
    }

    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    function excludeFromWhitelist(address account)
        external
        onlyOwner
        returns (bool)
    {
        _isIncludedInWhitelist[account] = false;
        _addressToPotNumber[account] = 0;

        return true;
    }

    function includeInWhitelist(address account, uint8 potNumber)
        external
        onlyOwner
        returns (bool)
    {
        require(
            potNumber > 0 && potNumber < 6,
            "AirdropFLYY: pot number must be between 1 to 5"
        );
        _isIncludedInWhitelist[account] = true;
        _addressToPotNumber[account] = potNumber;

        return true;
    }

    function checkIsWhitelistedAndPotNumber(address account)
        external
        view
        returns (bool, uint8)
    {
        return (_isIncludedInWhitelist[account], _addressToPotNumber[account]);
    }
}