// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IVesting.sol";
import "./interfaces/IERC20Mintable.sol";

contract Vesting is IVesting, Ownable {
    uint256 private constant UNLOCKEDPERIOD = 360;
    uint256 private constant CLIFF = 600;
    uint256 private constant VESTINGTIME = 36000;

    IERC20 public immutable token;
    bool public isInitialTimestamp;
    mapping(address => Investor) public investorsBalances;
    mapping(AllocationTypes => uint256) public allocations;

    uint256 private vestingStarted; // start unlock tokens
    uint256 private vestingfinished; // finish unlock tokens
    uint256 private endCliffPeriod;

    constructor(address token_) {
        require(token_ != address(0), "Vesting: Invalid token address");
        token = IERC20(token_);

        allocations[AllocationTypes.Private] = 15;
        allocations[AllocationTypes.Seed] = 10;
    }

    /**
     * @dev Set initial timestamp, can be called only by the owner, can be called only once
     *
     * @param  _initialTimestamp - in seconds
     */
    function setInitialTimestamp(uint256 _initialTimestamp)
        external
        override
        onlyOwner
    {
        require(
            getCurrentTime() <= _initialTimestamp,
            "Vesting: initial timestamp cannot be less than current time"
        );
        require(!isInitialTimestamp, "Vesting: Is alredy called");
        isInitialTimestamp = true;

        vestingStarted = _initialTimestamp;
        vestingfinished = vestingStarted + VESTINGTIME;
        endCliffPeriod = vestingStarted + CLIFF;
    }

    /**
     * @dev Mint tokens for vesting contract equal to the sum of param tokens amount,
     * can be called only by the owner
     *
     * @param  _investors - array of investors
     * @param  _amounts - array of amounts(how much every investor can withdrow)
     * @param  _allocationType - enum param
     */
    function addInvestors(
        address[] memory _investors,
        uint256[] memory _amounts,
        AllocationTypes _allocationType
    ) external override onlyOwner {
        require(
            _investors.length == _amounts.length,
            "Vesting: Array lengths different"
        );

        uint256 sumToMint;

        for (uint256 i = 0; i < _investors.length; i++) {
            require(
                investorsBalances[_investors[i]].amount == 0,
                "Vesting: this beneficiary is already added to the vesting list"
            );
            investorsBalances[_investors[i]].amount = _amounts[i];

            investorsBalances[_investors[i]].allocationPercantage = allocations[
                _allocationType
            ];

            sumToMint += _amounts[i];
        }

        IERC20Mintable(address(token)).mint(address(this), sumToMint);

        emit AddedInvestors(_investors, _amounts, _allocationType);
    }

    /**
     * @dev Should transfer tokens to investors, can be called only after the initial timestamp is set
     *
     * @return -how much tokens beneficiary is already withdraw
     */
    function withdrawTokens() external override returns (uint256) {
        require(
            isInitialTimestamp,
            "Vesting: Initial timestamp is not already set"
        );
        require(
            !investorsBalances[msg.sender].isWithdraw,
            "Vesting: all tokens is already withdraw"
        );
        require(
            investorsBalances[msg.sender].amount != 0,
            "Vesting: this beneficiary is not added to the vesting list"
        );

        uint256 allocationAmount = investorsBalances[msg.sender].amount;
        uint256 availableWithdrawAmount;
        if (getCurrentTime() <= endCliffPeriod) {
            availableWithdrawAmount = 0;
        } else if (getCurrentTime() > vestingfinished) {
            availableWithdrawAmount = allocationAmount;
        } else {
            uint256 percentage = ((getCurrentTime() - vestingStarted) / UNLOCKEDPERIOD) +
                        investorsBalances[msg.sender].allocationPercantage;
            if(percentage >=100) percentage = 100;
            availableWithdrawAmount = allocationAmount * percentage /100;
        }

        token.transfer(msg.sender, availableWithdrawAmount);
        investorsBalances[msg.sender].claimedAmount += availableWithdrawAmount;

        emit WithdrawTokens(address(this), msg.sender, availableWithdrawAmount);

        _isWithdrawAllTokens(msg.sender);

        return availableWithdrawAmount;
    }

    function getCurrentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /* @dev set true is claimed tokens equal total amount
     *
     */
    function _isWithdrawAllTokens(address _beneficiary) private {
        if (
            investorsBalances[_beneficiary].amount ==
            investorsBalances[_beneficiary].claimedAmount
        ) {
            investorsBalances[_beneficiary].isWithdraw = true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

pragma solidity ^0.8.0;

interface IVesting {
    event AddedInvestors(
        address[] indexed _investor,
        uint256[] _amount,
        AllocationTypes _allocationType
    );

    event WithdrawTokens(
        address indexed _from,
        address indexed _to,
        uint256 _amount
    );

    enum AllocationTypes {
        Seed,
        Private
    }

    struct Investor {
        uint256 amount;
        uint256 claimedAmount;
        uint256 allocationPercantage;
        bool isWithdraw;
    }

    /**
     * @dev Set initial timestamp, can be called only by the owner, can be called only once
     *
     * @param  _initialTimestamp -
     */
    function setInitialTimestamp(uint256 _initialTimestamp) external;

    /**
     * @dev Mint tokens for vesting contract equal to the sum of param tokens amount,
     * can be called only by the owner
     *
     * @param  _investors - array of investors
     * @param  _amounts - array of amounts(how much every investor can withdrow)
     * @param  _allocationType - enum param
     */
    function addInvestors(
        address[] memory _investors,
        uint256[] memory _amounts,
        AllocationTypes _allocationType
    ) external;

    /**
     * @dev Should transfer tokens to investors, can be called only after the initial timestamp is set
     *
     * @return -how much tokens beneficiary is already withdraw
     */
    function withdrawTokens() external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20Mintable {
    function mint(address account, uint256 amount) external;
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