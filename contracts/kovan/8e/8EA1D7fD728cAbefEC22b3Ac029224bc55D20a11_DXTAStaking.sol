// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./openzeppelin/IERC20.sol";
import "./Administrable.sol";
import "./openzeppelin/Pausable.sol";
import "./openzeppelin/SafeERC20.sol";

contract DXTAStaking is Administrable {
    using SafeERC20 for IERC20;
    /*///////////////////////////////////////////////////////////////
                    DATA STRUCTURES 
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev `StakingOption`  Represent allowed configurations for the staking platform.
     */
    struct StakingOption {
        uint256 duration; //in days
        uint256 apy; //in percentage 1.23% => 123, 12.34% => 1234, 123.45% => 12345
        bool allowed;
    }

    /**
     * @dev `StakingPrams` Represents one instance of staking conducted on the platform.
     */
    struct StakingParams {
        uint256 created;
        uint256 duration; //in days
        uint256 apy; //in percentage 1.23% => 123, 12.34% => 1234, 123.45% => 12345
        uint256 baseAmount;
        bool claimed;
        bool blocked;
    }

    /**
     * @dev `StakingParamsView` Represnts view of one StakingParams, maily used in frontend.
     */
    struct StakingParamsView {
        address addr;
        uint256 created;
        uint256 expire;
        uint256 amountWithIntrest;
        uint256 apy; //in percentage 1.23% => 123, 12.34% => 1234, 123.45% => 12345
    }

    /*///////////////////////////////////////////////////////////////
                    Global STATE
    //////////////////////////////////////////////////////////////*/

    IERC20 private _token;
    mapping(address => StakingParams) private _staking;
    address[] private _stakingLookup;
    StakingOption[] private _allowedOptions;

    uint256 private _maxStakingAmount = 1000000;
    uint256 private _minStakingAmount = 10;

    uint256 private _totalValueLocked;

    /**
     * @dev The contract constructor needs an address `tokenAddress` for the IBEP20 _token on which staking is conducted.
     */
    constructor(address tokenAddress, StakingOption[] memory allowedOptions) {
        require(tokenAddress != address(0), "DXTAStaking:Wrong address");
        _token = IERC20(tokenAddress);
        _swapAllAlowedOptions(allowedOptions);
    }

    /*///////////////////////////////////////////////////////////////
                    PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Creates user stake by creating `StakingParams`.
     * `StakingParams` is created based on selected `StakingOption` and `amount`.
     * StakingOption is selected by `stakingOptionId` parameter.
     * Returns `StakingParamView`.
     * Emits `Staked` event.
     */
    function deposit(uint256 stakingOptionId, uint256 amount)
        external
        whenNotPaused
        returns (StakingParamsView memory)
    {
        checkDepositRequirements(_msgSender(), stakingOptionId, amount);
        StakingOption memory options = _allowedOptions[stakingOptionId];
        _staking[_msgSender()] = StakingParams(
            block.timestamp,
            options.duration,
            options.apy,
            amount,
            false,
            false
        );
        StakingParamsView memory stakingParamsView = viewStake(_msgSender());
        _stakingLookup.push(_msgSender());
        _totalValueLocked+=amount;
        emit Staked(
            _msgSender(),
            amount,
            stakingParamsView.expire,
            stakingParamsView.amountWithIntrest
        );
        _token.safeTransferFrom(_msgSender(), address(this), amount);
        return stakingParamsView;
    }

    /**
     * @dev Allows sender to withdraw staking if it has expired.
     * Returns `bool`, which indicates the success of withdrawn.
     * Emits `Claimed` event.
     */
    function claim() external whenNotPaused returns (bool) {
        require(stakeExists(_msgSender()), "DXTAStaking:Not found");
        require(canWithdraw(_msgSender()), "DXTAStaking:Premature withdrawal");
        StakingParams memory stakingParams = _staking[_msgSender()];
        uint256 amountWithInterest = calculateWithInterest(
            stakingParams.baseAmount,
            stakingParams.apy,
            stakingParams.duration
        );
        _totalValueLocked -= _staking[_msgSender()].baseAmount;
        _withdrawal(amountWithInterest);
        return true;
    }

    /*///////////////////////////////////////////////////////////////
                    VIEWERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Checks does sender meet requirements to deposit `amount` with StakingOption selected by `stakingOptionId`.
     */
    function checkDepositRequirements(
        address addr,
        uint256 stakingOptionId,
        uint256 amount
    ) public view {
        require(
            _minStakingAmount <= amount && amount <= _maxStakingAmount,
            "Invalid amount"
        );
        require(!stakeExists(addr), "DXTAStaking:Stake exists");
        require(
            stakingOptionId < _allowedOptions.length,
            "DXTAStaking:Wrong index"
        );
        require(
            _allowedOptions[stakingOptionId].allowed,
            "DXTAStaking:Invalid option"
        );
        require(
            _token.allowance(addr, address(this)) >= amount,
            "DXTAStaking:Approve first"
        );
    }

    /**
     * @dev Creates `StakingParamView` based on `StakingParams`, stored in the contract for address `addr`.
     */
    function viewStake(address addr)
        public
        view
        returns (StakingParamsView memory)
    {
        require(stakeExists(addr), "DXTAStaking:Not found");
        StakingParams memory stakingParams = _staking[addr];
        return
            StakingParamsView(
                addr,
                stakingParams.created,
                getDateFrom(stakingParams.created, stakingParams.duration),
                calculateWithInterest(
                    stakingParams.baseAmount,
                    stakingParams.apy,
                    stakingParams.duration
                ),
                stakingParams.apy
            );
    }

    /**
     * @dev Checks can `addr` withdraw tokens.
     * Returns bool which indicates is `addr` allowed to withdrawal tokens without penalty.
     * Function checks is addr temporally suspended, is stake claimed and is stake expired
     */
    function canWithdraw(address addr) public view returns (bool) {
        require(stakeExists(addr), "DXTAStaking:Not found");
        require(!_staking[addr].blocked, "DXTAStaking:Suspended");
        uint256 expiration = getDateFrom(
            _staking[addr].created,
            _staking[addr].duration
        );
        return expiration <= block.timestamp;
    }

    /**
     * @dev Checks does sender have already staked tokens in the contract for address `addr`.
     */
    function stakeExists(address addr) public view returns (bool) {
        return _staking[addr].created > 0 && !_staking[addr].claimed;
    }

    /**
     * @dev Returns upcoming withdrawals which expire in the `daysFromNow` number of days.
     * Returns array of StakingParamView,
     * the sum of all amounts which can be paid in the upcoming period,
     * and the timestamp when first staking will expire.
     */
    function getUpcomingWithdrawals(uint256 daysFromNow)
        external
        view
        returns (
            StakingParamsView[] memory,
            uint256,
            uint256
        )
    {
        uint256 endTime = getDateFrom(block.timestamp, daysFromNow);
        StakingParamsView[] memory upcoming = new StakingParamsView[](
            _stakingLookup.length
        );
        uint256 firstUpcoming = getDateFrom(block.timestamp, daysFromNow + 1);
        uint256 j = 0;
        uint256 sum = 0;
        for (uint256 i = 0; i < _stakingLookup.length; i++) {
            if (!_staking[_stakingLookup[i]].claimed) {
                StakingParamsView memory stakingParamsView = viewStake(
                    _stakingLookup[i]
                );
                if (stakingParamsView.expire <= endTime) {
                    upcoming[j++] = stakingParamsView;
                    sum += stakingParamsView.amountWithIntrest;
                    if (stakingParamsView.expire < firstUpcoming) {
                        firstUpcoming = stakingParamsView.expire;
                    }
                }
            }
        }
        StakingParamsView[] memory upcomingReturn = new StakingParamsView[](j);
        for (uint256 i = 0; i < j; i++) {
            upcomingReturn[i] = upcoming[i];
        }
        if (upcomingReturn.length == 0) {
            firstUpcoming = 0;
        }
        return (upcomingReturn, sum, firstUpcoming);
    }

    /**
     * @dev Returns array of `StakingParams` which represents all unclaimed stakes.
     */
    function getAllStakings() external view returns (StakingParams[] memory) {
        StakingParams[] memory array = new StakingParams[](
            _stakingLookup.length
        );
        for (uint256 i = 0; i < array.length; i++) {
            if (!_staking[_stakingLookup[i]].claimed) {
                array[i] = _staking[_stakingLookup[i]];
            }
        }
        return array;
    }

    /**
     * @dev Returns array of all allowed `StakingOptions`
     */
    function getAllowedOptions()
        external
        view
        returns (StakingOption[] memory)
    {
        return _allowedOptions;
    }

    /**
     * @dev Returns StakingOption which is selected by `id`
     */
    function getAllowedOption(uint256 id)
        external
        view
        returns (StakingOption memory)
    {
        return _allowedOptions[id];
    }

    /**
     * @dev Returns amount increased for interest which can be paid to address `addr`.
     */
    function calculateWithInterestForAddress(address addr)
        external
        view
        returns (uint256)
    {
        require(stakeExists(addr), "DXTAStaking:Not found");
        return
            calculateWithInterest(
                _staking[addr].apy,
                _staking[addr].duration,
                _staking[addr].baseAmount
            );
    }

    /**
     * @dev Returns amount `amount` increased for interest, which can be paid for the number of days `duration` with APY `apy`.
     * APY must be written in the following format:
     * 12.34 % APY must be written as apy=1234.
     * The last two digits are decimals after floating-point.
     */
    function calculateWithInterest(
        uint256 amount,
        uint256 apy,
        uint256 duration
    ) public pure returns (uint256) {
        return (amount * (100000 + (1000 * apy * duration) / 36525)) / 100000;
    }

    /**
     * @dev Returns total value locked
     */
    function getTotalValueLocked() external view returns (uint256) {
        return _totalValueLocked;
    }

    /**
     * @dev Getter for minimal allowed staking amount.
     */
    function getMinStakingAmount() external view returns (uint256) {
        return _minStakingAmount;
    }

    /**
     * @dev Getter for maximal allowed staking amount
     */
    function getMaxStakingAmount() external view returns (uint256) {
        return _maxStakingAmount;
    }

    /**
     * @dev Utility function. Allows adding of `durationInDay` to `start` timestamp.
     */
    function getDateFrom(uint256 start, uint256 durationInDay)
        public
        pure
        returns (uint256)
    {
        return start + durationInDay * 10 days;
    }

    /**
     * @dev Returns `_token` address.
     */
    function getTokenAddress() public view returns (address) {
        return address(_token);
    }

    /*///////////////////////////////////////////////////////////////
                    OWNER'S AND ADMIN'S FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Allows owner to cancel staking for address `addr`.
     * Base amount which was deposited will be returned to `addr`
     */
    function cancelStaking(address addr) external onlyOwner returns (bool) {
        require(stakeExists(addr), "DXTAStaking:Not found");
        if (_staking[addr].created == 0) {
            return false;
        }
        _staking[addr].claimed = true;
        if (_staking[addr].baseAmount > 0) {
            _totalValueLocked -= _staking[addr].baseAmount;
            _token.safeTransfer(addr, _staking[addr].baseAmount);
        }
        return true;
    }

    /**
     * @dev Extract mistakenly sent tokens to the contract.
     */
    function extractMistakenlySentTokens(address tokenAddress)
        external
        onlyOwner
    {
        if (tokenAddress == address(0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }
        IERC20 bep20Token = IERC20(tokenAddress);
        uint256 balance = bep20Token.balanceOf(address(this));
        emit ExtractedTokens(tokenAddress, owner(), balance);
        _token.safeTransfer(owner(), balance);
    }

    /**
     * @dev Setter for minimal allowed staking amount. Sender must be administrator.
     */
    function setMinStakingAmount(uint256 min) external onlyAdmin {
        require(min < type(uint256).max);
        _minStakingAmount = min;
    }

    /**
     * @dev Setter for maximal allowed staking amount. Sender must be administrator.
     */
    function setMaxStakingAmount(uint256 max) external onlyAdmin {
        require(max < type(uint256).max);
        _maxStakingAmount = max;
    }

    /**
     * @dev Adds new or update existing `StakingOption` selected by `id`.
     * Returns index of staking option.
     * Sender must be administrator.
     */
    function updateAllowedOptions(uint256 id, StakingOption memory option)
        external
        onlyAdmin
        returns (uint256)
    {
        require(option.apy > 0);
        if (id > _allowedOptions.length - 1) {
            _allowedOptions.push(option);
            return _allowedOptions.length - 1;
        } else {
            _allowedOptions[id] = option;
            return id;
        }
    }

    /**
     * @dev Removes existing StakingOption selected by `id`.
     * Sender must be administrator.
     */
    function removeAllowedOptions(uint256 id) external onlyAdmin {
        require(id < _allowedOptions.length, "DXTAStaking:Wrong index");
        StakingOption[] memory readingOptions = _allowedOptions;
        delete _allowedOptions;
        for (uint256 i = 0; i < readingOptions.length; i++) {
            if (i != id) {
                _allowedOptions.push(readingOptions[i]);
            }
        }
    }

    /**
     * @dev Swapes all existing StakingOptions by StakingOption array named `options`.
     * Sender must be administrator.
     */
    function swapAllAlowedOptions(StakingOption[] memory options)
        external
        onlyAdmin
    {
        _swapAllAlowedOptions(options);
    }

    function _swapAllAlowedOptions(StakingOption[] memory options) internal {
        require(options.length > 0, "DXTAStaking:Array can't be empty");
        delete _allowedOptions;
        for (uint256 i = 0; i < options.length; i++) {
            _allowedOptions.push(options[i]);
        }
    }

    /**
     * @dev Allows administrator to suspend `addr` from withdrawl.
     */
    function blockUnstake(address addr) external onlyAdmin {
        _staking[addr].blocked = true;
    }

    /**
     * @dev Allows an administrator to unsuspend `addr` from _withdrawal.
     */
    function unblockUnstake(address addr) external onlyAdmin {
        _staking[addr].blocked = false;
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL  HELPERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Send _withdrawal request to `_token`.
     * Emits `Claimed` event
     */
    function _withdrawal(uint256 amount) private {
        uint256 balance = _token.balanceOf(address(this));
        require(balance >= amount, "DXTAStaking:Balance too low");
        _staking[_msgSender()].claimed = true;
        _removeFromLookup(_msgSender());
        StakingParams memory stakingParams = _staking[_msgSender()];
        emit Claimed(
            _msgSender(),
            stakingParams.baseAmount,
            getDateFrom(stakingParams.created, stakingParams.duration),
            amount
        );
        _token.safeTransfer(_msgSender(), amount);
    }

    /**
     * @dev Removes address `addr` from `_stakingLookup`.
     * Base amount which was deposited will be returned to `addr`
     */
    function _removeFromLookup(address addr) private {
        address[] memory readingParams = _stakingLookup;
        delete _stakingLookup;
        for (uint256 i = 0; i < readingParams.length; i++) {
            if (readingParams[i] != addr) {
                _stakingLookup.push(readingParams[i]);
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                     EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev It is emitted when deposits `value` to contract.
     */
    event Staked(
        address indexed addr,
        uint256 value,
        uint256 expire,
        uint256 claimableAmount
    );

    /**
     * @dev It is emitted when the user claims a stake from the contract.
     */
    event Claimed(
        address indexed addr,
        uint256 value,
        uint256 expire,
        uint256 claimed
    );

    /**
     * @dev It is emitted when mistakenly sent _token are extracted.
     */
    event ExtractedTokens(address _token, address _owner, uint256 _amount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.1;

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./openzeppelin/Pausable.sol";
import "./Globals.sol";

contract Administrable is Pausable {
    modifier onlyAdmin() {
        require(
            isAdmin(_msgSender()),
            "Administrable: Caller is not administrator"
        );
        _;
    }
    modifier onlyOperator() {
        require(
            isOperator(_msgSender()),
            "Adminstrable: Caller is not operator"
        );
        _;
    }

    constructor() {
        _addAdmin(_msgSender());
    }

    function isAdmin(address addr) public view returns (bool) {
        return _roles[Globals.Roles.ADMIN][addr];
    }

    function isOperator(address addr) public view returns (bool) {
        return _roles[Globals.Roles.OPERATOR][addr];
    }

    mapping(Globals.Roles => mapping(address => bool)) _roles;

    /**
     * @dev Allows an administrator to add new administrator address `addr`.
     * Returns bool which indicates success of operation.
     * Sender must be administrator.
     * `addr` can't be address(0)
     */
    function addAdmin(address addr) public virtual onlyAdmin returns (bool) {
        return _addAdmin(addr);
    }

    function _addAdmin(address addr) internal returns (bool) {
        require(addr != address(0));
        _roles[Globals.Roles.ADMIN][addr] = true;
        return true;
    }

    function addOperator(address addr) public virtual onlyAdmin returns (bool) {
        require(addr != address(0));
        _roles[Globals.Roles.OPERATOR][addr] = true;
        return true;
    }

    /**
     * @dev   Allows an administrator to remove an existing administrator identified by address `addr`.
     * Administrators can’t remove `owner` from the list of administrators.
     * Sender must be administrator.
     * Returns bool, which indicates the success of the operation.
     */
    function removeAdmin(address addr) external onlyOwner returns (bool) {
        require(addr != owner() || _msgSender() == owner(), "Not allowed");
        _roles[Globals.Roles.ADMIN][addr] = false;
        return true;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        addAdmin(newOwner);
        _roles[Globals.Roles.ADMIN][_msgSender()] = false;
        super.transferOwnership(newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (Pausable.sol)

pragma solidity ^0.8.1;

import "./Ownable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Ownable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public whenNotPaused onlyOwner {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public whenPaused onlyOwner {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.1;

import "./IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./openzeppelin/IERC20.sol";
contract Globals {
    /**   Alternative Enum
     * enum UserStatus{
     *    NONE,
     *    APPROVED,
     *    SUSPENDED,
     *    BLOCKED
     *  }
     */

    enum UserStatus {
        NONE,
        WHITELISTED,
        LIMITED,
        BLACKLISTED
    }

    enum ERC20s {
        NONE,
        USDC,
        DXTA
    }
    enum Roles {
        NONE,
        OPERATOR,
        ADMIN
    }

    struct Yield {
        uint256 timestamp;
        uint256 apr;
    }

    struct Contribution {
        uint256 amount;
        uint256 burnableAfter;
        ERC20s depositedIn;
        uint256 nextYieldIndex;
        bool locked;
    }

    struct ContributionLite {
        uint256 amount;
        uint256 burnableAfter;
        IERC20 depositedIn;
        bool locked;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (Ownable.sol)

pragma solidity ^0.8.1;

import "./Context.sol";

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
pragma solidity ^0.8.1;
abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}