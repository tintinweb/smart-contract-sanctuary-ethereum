// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ITokenSale.sol";

pragma solidity 0.8.17;

contract ProjectVesting is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    struct VestingProgram {
        uint256 startTime; // vesting start time timestamp
        uint256 endTime; // vesting end time timestamp
        uint256 cliffDuration; // cliff period duration in seconds
        uint256 duration; // vesting duration in seconds
        uint256 vestingAmount; // total vested amount
        uint256 unvestedAmount; // total unvested amount
        uint256 unlockPercentage; // period unlock percentage
        uint256 periodDuration; // unlock period duration in seconds
        uint256 vestingType; //0 - team;  1 - treasury
        bool isEnded; // active vesting if true, if false vesting is end
    }

    struct User {
        uint256 lastUnvesting; // last  unvest timestamp
        uint256 totalVested; // total user vested amount
        uint256 totalUnvested; // total user unvested amount
    }

    address public vestingToken; // planetex token address
    address public tokenSale; // tokenSale contract address
    uint256 public vestingProgramsCounter; // quantity of vesting programs
    uint256 public immutable PRECISSION = 10000; // precission for math operation
    bool public isInitialized = false; // if true, the contract is initialized, if false, then not

    mapping(uint256 => VestingProgram) public vestingPrograms; // return VestingProgram info (0 - team, 1 - treasury)
    mapping(address => mapping(uint256 => User)) public userInfo; // return user info
    mapping(address => mapping(uint256 => bool)) public isVester; // bool if true then user is vesting member else not a member

    //// @errors

    //// @dev - cannot unvest 0;
    error ZeroAmountToUnvest(string err);
    //// @dev - unequal length of arrays
    error InvalidArrayLengths(string err);
    /// @dev - user is not a member of the vesting program
    error NotVester(string err);
    //// @dev - vesting program is ended
    error VestingIsEnd(string err);
    //// @dev - vesting program not started
    error VestingNotStarted(string err);
    //// @dev - there is no vesting program with this id
    error VestingProgramNotFound(string err);
    /// @dev - address to the zero;
    error ZeroAddress(string err);
    //// @dev - Cannot rescue 0;
    error RescueZeroValue(string err);
    //// @dev - cannot initialized contract again
    error ContractIsInited(string err);
    //// @dev - cannot call methods if contract not inited
    error ContractIsNotInited(string err);

    ////@notice emitted when the user has joined the vesting program
    event Vest(address user, uint256 vestAmount, uint256 vestingProgramId);
    ////@notice emitted when the user gets ownership of the tokens
    event Unvest(
        address user,
        uint256 unvestedAmount,
        uint256 vestingProgramId
    );
    /// @notice Transferring funds from the wallet еther of the selected token contract to the specified wallet
    event RescueToken(
        address indexed to,
        address indexed token,
        uint256 amount
    );

    function initialize(
        address _vestingToken, // planetex token contract address
        address _tokenSale, // tokenSale contract address
        uint256[] memory _durations, // array of vesting durations in seconds
        uint256[] memory _cliffDurations, // array of cliff period durations in the seconds
        uint256[] memory _unlockPercentages, // array of unlock percentages every unlock period
        uint256[] memory _totalSupplyPercentages, // array of percentages of tokens from totalSupply
        uint256[] memory _vestingTypes, // array of vesting types. 0 - team; 1 - treasury;
        uint256[] memory _periodDurations, // array of unlock period durations in secconds
        address[] memory _vesters // array of vesters adresses (0 - team address, 1 - treasury address)
    ) external onlyOwner isInited {
        if (
            _durations.length != _cliffDurations.length ||
            _durations.length != _unlockPercentages.length ||
            _durations.length != _totalSupplyPercentages.length ||
            _durations.length != _vestingTypes.length ||
            _durations.length != _periodDurations.length ||
            _durations.length != _vesters.length
        ) {
            revert InvalidArrayLengths("Vesting: Invalid array lengths");
        }
        if (_vestingToken == address(0) || _tokenSale == address(0)) {
            revert ZeroAddress("Vesting: Zero address");
        }

        vestingToken = _vestingToken;
        uint256 totalSupply = IERC20(_vestingToken).totalSupply();
        for (uint256 i; i <= _durations.length - 1; i++) {
            VestingProgram storage vestingProgram = vestingPrograms[i];
            vestingProgram.startTime =
                ITokenSale(_tokenSale).getRoundStartTime(0) +
                _cliffDurations[i];
            vestingProgram.endTime = vestingProgram.startTime + _durations[i];
            vestingProgram.duration = _durations[i];
            vestingProgram.cliffDuration = _cliffDurations[i];
            vestingProgram.vestingAmount =
                (_totalSupplyPercentages[i] * totalSupply) /
                PRECISSION;
            vestingProgram.unlockPercentage = _unlockPercentages[i];
            vestingProgram.periodDuration = _periodDurations[i];
            vestingProgram.vestingType = _vestingTypes[i];
            vestingProgram.unvestedAmount = 0;
            vestingProgram.isEnded = false;

            User storage userVestInfo = userInfo[_vesters[i]][i];
            userVestInfo.lastUnvesting = vestingProgram.startTime;
            userVestInfo.totalVested = vestingProgram.vestingAmount;
            userVestInfo.totalUnvested = vestingProgram.unvestedAmount;
            isVester[_vesters[i]][i] = true;
        }
        isInitialized = true;
        vestingProgramsCounter = _durations.length - 1;
    }

    /**
    @dev The modifier checks whether the vesting program has not expired.
    @param vestingId vesting program id.
    */
    modifier isEnded(uint256 vestingId) {
        VestingProgram storage vestingProgram = vestingPrograms[vestingId];
        if (vestingId > vestingProgramsCounter) {
            revert VestingProgramNotFound("Vesting: Program not found");
        }
        if (vestingProgram.isEnded) {
            revert VestingIsEnd("Vesting: Vesting is end");
        }
        _;
    }

    /**
    @dev The modifier checks whether the contract has been initialized.
    Prevents reinitialization.
    */
    modifier isInited() {
        if (isInitialized) {
            revert ContractIsInited("Vesting: Already initialized");
        }
        _;
    }

    /**
    @dev The modifier checks if the contract has been initialized. 
    Prevents functions from being called before the contract is initialized.
    */
    modifier notInited() {
        if (!isInitialized) {
            revert ContractIsNotInited("Vesting: Not inited");
        }
        _;
    }

    //// External functions

    /**
    @dev The function withdraws unlocked funds for the specified user. 
    Anyone can call instead of the user.
    @param vestingId vesting program id.
    @param userAddress user wallet address.
    */
    function unvestFor(uint256 vestingId, address userAddress)
        external
        notInited
        isEnded(vestingId)
    {
        _unvest(vestingId, userAddress);
    }

    /**
    @dev The function performs the withdrawal of unlocked funds.
    @param vestingId vesting program id.
    */
    function unvest(uint256 vestingId) external notInited isEnded(vestingId) {
        _unvest(vestingId, msg.sender);
    }

    /// @notice Transferring funds from the wallet of the selected token contract to the specified wallet
    /// @dev Used for the owner to withdraw funds
    /// @param to Address owner (Example)
    /// @param tokenAddress Token address from which tokens will be transferred
    /// @param amount Amount of transferred tokens
    function rescue(
        address to,
        address tokenAddress,
        uint256 amount
    ) external onlyOwner {
        if (to == address(0) || tokenAddress == address(0)) {
            revert ZeroAddress("Vesting: Cannot rescue to the zero address");
        }
        if (amount == 0) {
            revert RescueZeroValue("Vesting: Cannot rescue 0");
        }
        IERC20(tokenAddress).safeTransfer(to, amount);
        emit RescueToken(to, address(tokenAddress), amount);
    }

    //// Public functions

    /**
    @dev The function calculates the available amount of funds 
    for unvest for a certain user.
    @param vestingId vesting program id.
    @param userAddress user wallet address.
    @return unvestedAmount available amount of funds for unvest for a certain user.
    @return lastUserUnvesting timestamp when user do last unvest.
    @return totalUserUnvested the sum of all funds received user after unvest.
    @return totalUnvested the entire amount of funds of the vesting program that was withdrawn from vesting
    */
    function getUserUnvestedAmount(uint256 vestingId, address userAddress)
        public
        view
        notInited
        returns (
            uint256 unvestedAmount,
            uint256 lastUserUnvesting,
            uint256 totalUserUnvested,
            uint256 totalUnvested
        )
    {
        User storage user = userInfo[userAddress][vestingId];
        VestingProgram storage vestingProgram = vestingPrograms[vestingId];

        if (block.timestamp < vestingProgram.startTime) {
            revert VestingNotStarted("Vesting: Not started");
        }

        if (user.totalVested == 0) {
            revert NotVester("Vesting: Not a vester");
        }

        if (block.timestamp < vestingProgram.endTime) {
            uint256 userVestingTime = block.timestamp - user.lastUnvesting;
            uint256 payouts = userVestingTime / vestingProgram.periodDuration;
            unvestedAmount =
                ((user.totalVested * vestingProgram.unlockPercentage) /
                    PRECISSION) *
                payouts;
            lastUserUnvesting =
                user.lastUnvesting +
                (vestingProgram.periodDuration * payouts);
            totalUserUnvested = user.totalUnvested + unvestedAmount;
            totalUnvested = vestingProgram.unvestedAmount + unvestedAmount;
        } else {
            unvestedAmount = user.totalVested - user.totalUnvested;
            if (unvestedAmount > 0) {
                lastUserUnvesting = vestingProgram.endTime;
                totalUserUnvested = user.totalVested;
                totalUnvested = vestingProgram.unvestedAmount + unvestedAmount;
            }
        }
    }

    //// Internal functions

    /**
    @dev The function withdraws unlocked funds for the specified user. 
    Anyone can call instead of the user.
    @param vestingId vesting program id.
    @param userAddress user wallet address.
    */
    function _unvest(uint256 vestingId, address userAddress) internal {
        if (userAddress == address(0)) {
            revert ZeroAddress("Vesting: Zero address");
        }
        User storage user = userInfo[userAddress][vestingId];
        VestingProgram storage vestingProgram = vestingPrograms[vestingId];

        if (block.timestamp <= vestingProgram.startTime) {
            revert VestingNotStarted("Vesting: Not started");
        }

        if (!isVester[userAddress][vestingId]) {
            revert NotVester("Vesting: Zero balance");
        }

        (
            uint256 unvestedAmount,
            uint256 lastUserUnvesting,
            uint256 totalUserUnvested,
            uint256 totalUnvested
        ) = getUserUnvestedAmount(vestingId, userAddress);

        user.lastUnvesting = lastUserUnvesting;
        user.totalUnvested = totalUserUnvested;

        if (unvestedAmount == 0) {
            revert ZeroAmountToUnvest("Vesting: Zero unvest amount");
        } else {
            if (
                unvestedAmount + vestingProgram.unvestedAmount >=
                vestingProgram.vestingAmount
            ) {
                unvestedAmount =
                    vestingProgram.vestingAmount -
                    vestingProgram.unvestedAmount;
            }
            vestingProgram.unvestedAmount = totalUnvested;
            IERC20(vestingToken).safeTransfer(userAddress, unvestedAmount);
            emit Unvest(userAddress, unvestedAmount, vestingId);
        }

        if (vestingProgram.unvestedAmount == vestingProgram.vestingAmount) {
            vestingProgram.isEnded = true;
        }
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
pragma solidity 0.8.17;

interface ITokenSale {
    function userBalance(address, uint256) external view returns (uint256);

    function getRoundEndTime(uint256 roundId) external view returns (uint256);

    function getRoundStartTime(uint256 roundId) external view returns (uint256);

    function rounds(uint256)
        external
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256 duration,
            uint256 minAmount,
            uint256 maxAmount,
            uint256 purchasePrice,
            uint256 tokensSold,
            uint256 totalPurchaseAmount,
            uint256 tokenSaleType,
            uint256 paymentPercent,
            bool isPublic,
            bool isEnded
        );
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