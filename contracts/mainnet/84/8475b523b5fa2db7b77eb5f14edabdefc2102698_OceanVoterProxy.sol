// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IDeposit.sol";
import "./interfaces/IFeeDistro.sol";
import "./interfaces/ocean/IVeAllocate.sol";
import "./interfaces/ocean/IVeOcean.sol";
import "./interfaces/ocean/IVeFeeDistributor.sol";
import "./interfaces/ocean/IDFRewards.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title VoterProxy
 * @author Convex / H2O
 *
 * Contract that is holding all gathered veOcean, being responsible for all interaction with veOcean and related to veOcean,
 * like voting, claiming rewards or claiming fees. The only contract, that should not be upgradeable in whole protocol.
 */
contract OceanVoterProxy {
    using SafeERC20 for IERC20;

    /* ============ State Variables ============ */

    address public immutable ocean; // address of Ocean token contract
    address public immutable escrow; // address of Ocean veOcean contract
    address public immutable allocate; // address of Ocean veAllocate contract
    address public immutable rewards; // address of Ocean DFRewards contract

    // Permissions
    address public owner;
    address public operator; // Contract, that is responsible for handling fees/rewards - ie. Booster
    address public depositor; // Contract, that is entry/exit for Ocean flowing into the system - ie. OceanDepositor

    /* ============ Modifiers ============ */

    modifier onlyOwner() {
        require(msg.sender == owner, "auth!");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "auth!");
        _;
    }

    modifier onlyDepositor() {
        require(msg.sender == depositor, "auth!");
        _;
    }

    /* ============ Constructor ============ */

    /**
     * Sets various contract addresses
     *
     * @param _ocean                 Address of Ocean token contract
     * @param _escrow                Address of Ocean veOcean contract
     * @param _allocate              Address of Ocean veAllocate contra
     * @param _rewards               Address of Ocean DFRewards contract
     */
    constructor(
        address _ocean,
        address _escrow,
        address _allocate,
        address _rewards
    ) {
        owner = msg.sender;
        ocean = _ocean;
        escrow = _escrow;
        allocate = _allocate;
        rewards = _rewards;
    }

    /* ============ External Functions ============ */

    /* ====== Getters ====== */
    function getName() external pure returns (string memory) {
        return "OceanVoterProxy";
    }

    /* ====== Setters ====== */

    /**
     * Sets new owner of the contract
     *
     * @param _owner                 Address of the new owner
     */
    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    /**
     * Sets new operator of the contract
     *
     * @param _operator                 Address of the new operator
     */
    function setOperator(address _operator) external onlyOwner {
        require(
            operator == address(0) || IDeposit(operator).isShutdown() == true,
            "needs shutdown"
        );

        //require isShutdown interface
        require(
            IDeposit(_operator).isShutdown() == false,
            "New operator not in shutdown"
        );

        operator = _operator;
    }

    /**
     * Sets new depositor of the contract
     *
     * @param _depositor                 Address of the new depositor
     */
    function setDepositor(address _depositor) external onlyOwner {
        depositor = _depositor;
    }

    /* ====== Actions ====== */

    /**
     * Creates initial lock on veOcean
     *
     * @param _value                Amount of Ocean to lock in veOcean
     * @param _unlockTime           Time of unlocking veOcean
     *
     * @return True if call was successfull
     */
    function createLock(uint256 _value, uint256 _unlockTime)
        external
        onlyDepositor
        returns (bool)
    {
        IERC20(ocean).safeApprove(escrow, 0);
        IERC20(ocean).safeApprove(escrow, _value);

        IVeOcean(escrow).create_lock(_value, _unlockTime);
        return true;
    }

    /**
     * Increases amount of Ocean locked in veOcean
     *
     * @param _value                Amount of new Ocean to lock in veOcean
     *
     * @return True if call was successfull
     */
    function increaseAmount(uint256 _value)
        external
        onlyDepositor
        returns (bool)
    {
        IERC20(ocean).safeApprove(escrow, 0);
        IERC20(ocean).safeApprove(escrow, _value);
        IVeOcean(escrow).increase_amount(_value);
        return true;
    }

    /**
     * Increases time lock of locked Ocean in veOcean contract
     *
     * @param _value                A new time, untill which Ocean is locked in veOcean
     *
     * @return True if call was successfull
     */
    function increaseTime(uint256 _value)
        external
        onlyDepositor
        returns (bool)
    {
        IVeOcean(escrow).increase_unlock_time(_value);
        return true;
    }

    /**
     * Withdraws all Ocean from veOcean in the event of lock getting expired on veOcean side
     *
     * @return True if call was successfull
     */
    function release() external onlyDepositor returns (bool) {
        IVeOcean(escrow).withdraw();
        return true;
    }

    /**
     * Votes on selected Data NFTs on veAllocate contract, called every 1 week after snapshot vote
     * Needs to remove old allocations, if they are not included in the new vote.
     * Length of each array needs to be the same, as particular index in arrays corresponds to single allocation.
     *
     * @param amount                Array of shares, that we want to allocate to given Data Nft
     * @param nft                   Array of addresses of selected Data Nfts
     * @param chainId               Array of chain ids of selected Data Nfts
     *
     * @return True if call was successfull
     */
    function voteAllocations(
        uint256[] calldata amount,
        address[] calldata nft,
        uint256[] calldata chainId
    ) external onlyOperator returns (bool) {
        //vote
        IVeAllocate(allocate).setBatchAllocation(amount, nft, chainId);
        return true;
    }

    /**
     * Collects rewards from DFRewards contract and transfers to the requested contract - usually
     * Booster contract, which is responsible for distributing rewards to relevant RewardPools
     *
     * @param _token               Address of reward token, that was distributed
     * @param _claimTo             Address of receipient of rewards tokens, that will distribute it further to relevant RewardPools
     *
     * @return True if call was successfull
     */
    function claimRewards(address _token, address _claimTo)
        external
        onlyOperator
        returns (bool)
    {
        IDFRewards(rewards).claimFor(address(this), _token);
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(_claimTo, _balance);
        return true;
    }

    /**
     * Collects rewards from veFeeDistributor contract and transfers to the requested contract - usually
     * Booster contract, which is responsible for distributing fees to relevant RewardPools
     *
     * @param _distroContract      Address of veFeeDistributor
     * @param _token               Address of fee token, that was distributed
     * @param _claimTo             Address of receipient of fee tokens, that will distribute it further to relevant RewardPools
     *
     * @return balance of token, that were claimed during this action
     */
    function claimFees(
        address _distroContract,
        address _token,
        address _claimTo
    ) external onlyOperator returns (uint256) {
        IFeeDistro(_distroContract).claim();
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(_claimTo, _balance);
        return _balance;
    }

    /**
     * Function to execute any arbitrary external contract call
     *
     * @param _to                  Address of contract to call
     * @param _value               Amount of ether to send
     * @param _data                Data to send to selected contract
     *
     * @return status and result of given contract call
     */
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOperator returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);

        return (success, result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IDeposit {
    function isShutdown() external view returns (bool);

    function balanceOf(address _account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function rewardClaimed(
        uint256,
        address,
        uint256
    ) external;

    function withdrawTo(
        uint256,
        uint256,
        address
    ) external;

    function claimRewards(uint256, address) external returns (bool);

    function owner() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IFeeDistro {
    function claim() external;

    function token() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IVeOcean {
    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    // State view functions

    function token() external view returns (address);

    function supply() external view returns (uint256);

    // mapping(address => LockedBalance) locked;
    function locked(address addr) external view returns (LockedBalance memory);

    function epoch() external view returns (uint256);

    // Aragon's view methods for compatibility
    function controller() external view returns (address);

    function transfersEnabled() external view returns (bool);

    // ERC20
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function version() external view returns (string memory);

    function decimals() external view returns (uint256);

    // Checker for whitelisted (smart contract) wallets which are allowed to deposit
    // The goal is to prevent tokenizing the escrow
    function smart_wallet_checker() external view returns (address);

    function future_smart_wallet_checker() external view returns (address);

    function admin() external view returns (address);

    function future_admin() external view returns (address);

    /**
     * @notice Get the most recently recorded rate of voting power decrease for `addr`
     * @param addr Address of the user wallet
     * @return Value of the slope
     */
    function get_last_user_slope(address addr) external view returns (int128);

    /**
     * @notice Get the timestamp for checkpoint `_idx` for `_addr`
     * @param _addr User wallet address
     * @param _idx User epoch number
     * @return Epoch time of the checkpoint
     */
    function user_point_history__ts(address _addr, uint256 _idx)
        external
        view
        returns (uint256);

    /**
     * @notice Get timestamp when `_addr`'s lock finishes
     * @param _addr User wallet
     * @return Epoch time of the lock end
     */
    function locked__end(address _addr) external view returns (uint256);

    /**
     * @notice Get the current voting power for `addr`
     * @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
     * @param addr User wallet address
     * @param _t Epoch time to return voting power at
     * @return User voting power
     */
    function balanceOf(address addr, uint256 _t)
        external
        view
        returns (uint256);

    /**
     * @notice Measure voting power of `addr` at block height `_block`
     * @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
     * @param addr User's wallet address
     * @param _block Block to calculate the voting power at
     * @return Voting power
     */
    function balanceOfAt(address addr, uint256 _block)
        external
        view
        returns (uint256);

    /**
     * @notice Calculate total voting power
     * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
     * @return Total voting power
     */
    function totalSupply(uint256 t) external view returns (uint256);

    /**
     * @notice Calculate total voting power at some point in the past
     * @param _block Block to calculate the total voting power at
     * @return Total voting power at `_block`
     */
    function totalSupplyAt(uint256 _block) external view returns (uint256);

    /**
     * @notice Deposit `_value` tokens for `_addr` and add to the lock
     * @dev Anyone (even a smart contract) can deposit for someone else, but
         cannot extend their locktime and deposit for a brand new user
     * @param _addr User's wallet address
     * @param _value Amount to add to user's lock
     */
    function deposit_for(address _addr, uint256 _value) external;

    /**
     * @notice Withdraw all tokens for `msg.sender`
     * @dev Only possible if the lock has expired
     */
    function withdraw() external;

    /**
     * @notice Deposit `_value` tokens for `msg.sender` and lock until `_unlock_time`
     * @param _value Amount to deposit
     * @param _unlock_time Epoch time when tokens unlock, rounded down to whole weeks
     */
    function create_lock(uint256 _value, uint256 _unlock_time) external;

    /**
     * @notice Deposit `_value` additional tokens for `msg.sender`
            without modifying the unlock time
     * @param _value Amount of tokens to deposit and add to the lock
     */
    function increase_amount(uint256 _value) external;

    /**
     * @notice Extend the unlock time for `msg.sender` to `_unlock_time`
     * @param _unlock_time New epoch time for unlocking
     */
    function increase_unlock_time(uint256 _unlock_time) external;

    function changeController(address _newController) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IVeAllocate {
    function getveAllocation(
        address user,
        address nft,
        uint256 chainid
    ) external view returns (uint256);

    function getTotalAllocation(address user) external view returns (uint256);

    function setAllocation(
        uint256 amount,
        address nft,
        uint256 chainId
    ) external;

    function setBatchAllocation(
        uint256[] calldata amount,
        address[] calldata nft,
        uint256[] calldata chainId
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IDFRewards {
    event Allocated(address[] tos, uint256[] values, address tokenAddress);
    event Claimed(address to, uint256 value, address tokenAddress);
    event StrategyAdded(address strategy);
    event StrategyRetired(address strategy);

    function claimable(address _to, address tokenAddress)
        external
        view
        returns (uint256);

    function claimFor(address _to, address tokenAddress)
        external
        returns (uint256);

    function withdrawERCToken(uint256 amount, address _token) external;

    function claimForStrat(address _to, address tokenAddress)
        external
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IVeFeeDistributor {
    function token() external view returns (address);

    /**
     * @notice Update the token checkpoint
     * @dev Calculates the total number of tokens to be distributed in a given week.
            During setup for the initial distribution this function is only callable
            by the contract owner. Beyond initial distro, it can be enabled for anyone
            to call.
     */
    function checkpoint_token() external;

    /**
     * @notice Get the veOCEAN balance for `_user` at `_timestamp`
     * @param _user Address to query balance for
     * @param _timestamp Epoch time
     * @return uint256 veOCEAN balance
     */
    function ve_for_at(address _user, uint256 _timestamp)
        external
        view
        returns (uint256);

    /**
     * @notice Update the veOCEAN total supply checkpoint
     * @dev The checkpoint is also updated by the first claimant each
            new epoch week. This function may be called independently
            of a claim, to reduce claiming gas costs.
     */
    function checkpoint_total_supply() external;

    /**
     * @notice Claim fees for `_addr`
     * @dev Each call to claim look at a maximum of 50 user veOCEAN points.
            For accounts with many veOCEAN related actions, this function
            may need to be called more than once to claim all available
            fees. In the `Claimed` event that fires, if `claim_epoch` is
            less than `max_epoch`, the account may claim again.
     * @param _addr Address to claim fees for
     * @return uint256 Amount of fees claimed in the call
     */
    function claim(address _addr) external returns (uint256);

    /**
     * @notice Make multiple fee claims in a single call
     * @dev Used to claim for many accounts at once, or to make
            multiple claims for the same address when that address
            has significant veOCEAN history
     * @param _receivers List of addresses to claim for. Claiming
                      terminates at the first `ZERO_ADDRESS`.
     * @return bool success
     */
    function claim_many(address[] memory _receivers) external returns (bool);

    /**
     * @notice Receive OCEAN into the contract and trigger a token checkpoint
     * @param _coin Address of the coin being received (must be OCEAN)
     * @return bool success
     */
    function burn(address _coin) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}