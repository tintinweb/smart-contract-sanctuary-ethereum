// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IBatchTransferContract.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BatchTransferContract is IBatchTransferContract, ReentrancyGuard {
    using SafeERC20 for IERC20;

    function batchTransferERC20(
        IERC20 Token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external override nonReentrant returns (bool status) {
        // Ensure both array lengths are the same
        require(recipients.length == amounts.length, "Length mismatch");

        for (uint256 i = 0; i < amounts.length; i++) {
            Token.safeTransferFrom(msg.sender, recipients[i], amounts[i]);
        }
        return true;
    }

    function batchTransferETH(
        address payable[] calldata recipients,
        uint256[] calldata amounts
    ) external payable override nonReentrant returns (bool status) {
        // Ensure both array lengths are the same
        require(recipients.length == amounts.length, "Length mismatch");
        uint256 amountTransferred;
        for (uint256 i = 0; i < amounts.length; i++) {
            (bool sent, ) = recipients[i].call{value: amounts[i]}("");
            require(sent, "eth transfer failed");
            amountTransferred += amounts[i];
        }
        require(msg.value == amountTransferred, "Amount mismatch");
        return true;
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBatchTransferContract {
    /// @notice Allows the batch transfer of a given ERC20 token
    /// @dev The length of both arrays must match in order to batch transfer
    /// @dev This function will run out of gas and fail if too many recipients are specified
    /// @param Token  The given ERC20 token to Batch transfer
    /// @param recipients  An array of addresses to send the batch transfer amounts to
    /// @param amounts  An equal lengthed array of amounts to transfer
    /// @return status Returns a boolean value indicating whether the operation succeeded.
    function batchTransferERC20(
        IERC20 Token,
        address[] memory recipients,
        uint256[] memory amounts
    ) external returns (bool status);

    /// @notice Allows the batch transfer of ETH
    /// @dev The length of both arrays must match in order to batch transfer
    /// @dev This function will run out of gas and fail if too many recipients are specified
    /// @param recipients  An array of addresses to send the batch transfer amounts to
    /// @param amounts  An equal lengthed array of amounts to transfer
    /// @return status Returns a boolean value indicating whether the operation succeeded.
    function batchTransferETH(
        address payable[] memory recipients,
        uint256[] memory amounts
    ) external payable returns (bool status);
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
pragma solidity 0.8.11;

import "../interfaces/ITokenController.sol";
import "../interfaces/IRevolutToken.sol";
import "./RevolutToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

/// @notice This contract implements a set of functions to manage token minting according to a schedule for 1 or more recipients
contract TokenController is
    ITokenController,
    KeeperCompatibleInterface,
    AccessControl
{
    /// ### Constants
    uint256 private constant NUMBER_OF_RECIPIENT_TYPES = 4;

    /// Roles
    bytes32 public constant RECIPIENT_MANAGER = keccak256("RECIPIENT_MANAGER");
    bytes32 public constant SCHEDULE_MANAGER = keccak256("SCHEDULE_MANAGER");
    bytes32 public constant UPKEEP_MANAGER = keccak256("UPKEEP_MANAGER");

    /// ### State

    address public immutable override tokenAddress;

    // Block at which emissions will begin
    uint96 public immutable override emissionStartBlock;

    uint32 public override upkeepRate;

    // Block number of the last upkeep
    uint96 public override lastUpkeepBlock;

    // Contains schedule records. RecipientType corresponds to the index of the schedule for that recipient
    ScheduleRecord[NUMBER_OF_RECIPIENT_TYPES] public override schedule;

    // Contains reduction details. RecipientType corresponds to the index of that recipient's reduction event
    ReductionEvent[NUMBER_OF_RECIPIENT_TYPES] public override reductions;

    /// ### Functions

    /// @notice Sets the contract's initial state on deployment
    constructor(
        Recipient[] memory recipients,
        ScheduleCreation[] memory initialSchedules,
        ConstructorParams memory parameters
    ) {
        require(
            parameters.superAdmin != address(0),
            "admin cannot be 0 address"
        );
        require(
            parameters.managerAddress != address(0),
            "manager cannot be 0 address"
        );
        require(
            parameters.rewardTokenAddress != address(0),
            "token cannot be 0 address"
        );
        require(
            recipients.length == NUMBER_OF_RECIPIENT_TYPES,
            "Invalid amount of schedules"
        );
        require(
            recipients.length == initialSchedules.length,
            "Schedules are missing"
        );

        uint96 startingBlock = uint96(
            block.number + parameters.emissionStartOffset
        );
        require(parameters.initialUpkeepRate > 0, "invalid upkeep rate");
        upkeepRate = parameters.initialUpkeepRate;
        emissionStartBlock = startingBlock;
        tokenAddress = parameters.rewardTokenAddress;
        lastUpkeepBlock = startingBlock;
        uint256 requestedEmissionAmount = 0;
        bool[] memory recipientDuplicateCheck = new bool[](
            NUMBER_OF_RECIPIENT_TYPES
        );
        for (uint256 i = 0; i < NUMBER_OF_RECIPIENT_TYPES; i++) {
            require(
                initialSchedules[i].recipientIndex ==
                    recipients[i].recipientType,
                "Out of sync"
            );
            require(
                !recipientDuplicateCheck[
                    uint256(initialSchedules[i].recipientIndex)
                ],
                "Cannot repeat recipient types"
            );
            require(
                recipients[i].recipient != address(0),
                "Bad recipient address"
            );

            recipientDuplicateCheck[
                uint256(initialSchedules[i].recipientIndex)
            ] = true;
            ScheduleRecord memory record;
            record.delayPeriod = initialSchedules[i].delayPeriod;
            record.perBlockEmission = initialSchedules[i].perBlockEmission;
            record.recipient = recipients[i].recipient;
            record.maxEmission = initialSchedules[i].maxEmission;
            if (initialSchedules[i].halvingEventBlockCount > 0) {
                record.hasReduction = true;
                reductions[i] = ReductionEvent(
                    initialSchedules[i].halvingEventBlockCount,
                    startingBlock + record.delayPeriod
                );
            }
            schedule[i] = record;
            requestedEmissionAmount += record.maxEmission;
        }

        require(
            parameters.totalScheduleEmissionAmount == (requestedEmissionAmount),
            "emissions != schedule emissions"
        );

        // Setup access controls
        _setupRole(DEFAULT_ADMIN_ROLE, parameters.superAdmin);
        _setupRole(SCHEDULE_MANAGER, parameters.managerAddress);
        _setupRole(RECIPIENT_MANAGER, parameters.managerAddress);
        _setupRole(UPKEEP_MANAGER, parameters.managerAddress);

        require(
            IRevolutToken(parameters.rewardTokenAddress).maxMintableAmount() ==
                requestedEmissionAmount +
                    IRevolutToken(parameters.rewardTokenAddress).amountMinted(),
            "max amount != scheduled amount"
        );
        require(
            RevolutToken(parameters.rewardTokenAddress).owner() ==
                address(this),
            "invalid token owner"
        );
    }

    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = _isUpkeepRequired();
    }

    /// @notice Checks if upkeep is required
    /// @return whether upkeep is required or not
    function _isUpkeepRequired() internal view returns (bool) {
        return
            (block.number >= lastUpkeepBlock + upkeepRate) &&
            (IRevolutToken(tokenAddress).maxMintableAmount() >
                IRevolutToken(tokenAddress).amountMinted());
    }

    function performUpkeep(bytes calldata performData) external override {
        require(_isUpkeepRequired(), "Upkeep not required");

        uint256[] memory amounts = new uint256[](NUMBER_OF_RECIPIENT_TYPES);
        address[] memory recipients = new address[](NUMBER_OF_RECIPIENT_TYPES);

        uint256 mintableAmount = IRevolutToken(tokenAddress)
            .maxMintableAmount() - IRevolutToken(tokenAddress).amountMinted();

        for (uint256 i = 0; i < NUMBER_OF_RECIPIENT_TYPES; i++) {
            (
                ScheduleRecord memory record,
                uint256 mintAmount,
                uint96 previousReductionBlock
            ) = _processScheduleRecord(RecipientType(i));
            amounts[i] = mintAmount;
            recipients[i] = record.recipient;
            if (previousReductionBlock > 0) {
                reductions[i].previousReductionBlock = previousReductionBlock;
            }
            // Mint emission amount
            if (mintableAmount == 0) {
                break;
            }
            if (amounts[i] > 0) {
                if (mintableAmount < amounts[i]) {
                    amounts[i] = mintableAmount;
                }
                record.amountEmitted += amounts[i];
                schedule[i] = record;
                IRevolutToken(tokenAddress).mint(recipients[i], amounts[i]);
                mintableAmount -= amounts[i];
            }
        }

        lastUpkeepBlock = uint96(block.number);
        emit UpkeepPerformed(recipients, amounts);
    }

    /// @notice Calculates the amount to emit for the range of blocks between the current block and the block upkeep was last processed
    /// @param lastReductionBlock  the last block in which a reduction occurred. The algorithm expects that this block has already been emitted
    /// @param lastUpkeep  The block that upkeep was last performed
    /// @param currentBlock  The current block number
    /// @param eventPeriod  The number of blocks between halving events. Halving happens on the first block of a new period
    /// @param currentEmissionRate  the current amount of tokens being emitted
    /// @return amountToEmit  The amount to mint for the range of blocks (currentBlock - lastUpkeepBlock)
    /// @return finalReductionBlock  The last block within the range that a reduction event occurred on
    /// @return newEmissionRate  The new emission rate for future blocks
    function _calculateHalvingAmount(
        uint256 lastReductionBlock,
        uint256 lastUpkeep,
        uint256 currentBlock,
        uint256 eventPeriod,
        uint256 currentEmissionRate
    )
        internal
        pure
        returns (
            uint256 amountToEmit,
            uint256 finalReductionBlock,
            uint256 newEmissionRate
        )
    {
        require(eventPeriod > 0, "Invalid period");
        newEmissionRate = currentEmissionRate;
        finalReductionBlock = lastReductionBlock;
        uint256 blocksRemaining = currentBlock - lastUpkeep;
        uint256 lastBlockInPeriod = lastReductionBlock + eventPeriod;
        if (lastBlockInPeriod > currentBlock) {
            // We're in the middle of a halving period. Rate doesn't change
            amountToEmit += blocksRemaining * newEmissionRate;
            return (amountToEmit, finalReductionBlock, newEmissionRate);
        } else {
            // Last block in current period is <= current block, thus finalising this halving period
            amountToEmit += newEmissionRate * (lastBlockInPeriod - lastUpkeep);
            blocksRemaining -= lastBlockInPeriod - lastUpkeep;
            finalReductionBlock += eventPeriod;
            if (lastBlockInPeriod == currentBlock) {
                newEmissionRate -= newEmissionRate / 2;
            }
        }
        if (lastBlockInPeriod < currentBlock) {
            // We've gone past at least 1 halving boundary
            uint256 periods = (currentBlock - lastBlockInPeriod) / eventPeriod;
            uint256 remainder = blocksRemaining - (eventPeriod * periods);
            if (periods > 0) {
                for (uint256 i = 0; i < periods; i++) {
                    newEmissionRate -= newEmissionRate / 2;
                    amountToEmit += eventPeriod * newEmissionRate;
                }

                finalReductionBlock =
                    lastReductionBlock +
                    (periods * eventPeriod);
                if (remainder > 0) {
                    finalReductionBlock += eventPeriod;
                }
            }
            if (remainder > 0) {
                newEmissionRate -= newEmissionRate / 2;
                amountToEmit += remainder * newEmissionRate;
            }
        }
        return (amountToEmit, finalReductionBlock, newEmissionRate);
    }

    function getPendingMintAmounts(RecipientType recipient)
        external
        view
        override
        returns (uint256 mintAmount)
    {
        (, mintAmount, ) = _processScheduleRecord(recipient);
    }

    /// @notice Processes a schedule record for upkeep, updating perBlockEmission amount, and reduction details as required
    /// @param recipient  The schedule to update
    /// @return record  The updated record
    /// @return mintAmount  The amount to be minted for this recipient in this upkeep
    function _processScheduleRecord(RecipientType recipient)
        internal
        view
        returns (
            ScheduleRecord memory record,
            uint256 mintAmount,
            uint96 previousReductionBlock
        )
    {
        record = schedule[uint256(recipient)];
        uint256 lastUpkeep = lastUpkeepBlock >
            emissionStartBlock + record.delayPeriod
            ? lastUpkeepBlock
            : emissionStartBlock + record.delayPeriod;
        uint256 mintableAmount = record.maxEmission > record.amountEmitted
            ? record.maxEmission - record.amountEmitted
            : 0;
        if (mintableAmount == 0) {
            return (record, 0, 0);
        }
        if (emissionStartBlock + record.delayPeriod < block.number) {
            if (record.hasReduction) {
                ReductionEvent memory reduction = reductions[
                    uint256(recipient)
                ];
                (
                    uint256 amountToEmit,
                    uint256 finalReductionBlock,
                    uint256 newEmissionRate
                ) = _calculateHalvingAmount(
                        reduction.previousReductionBlock,
                        lastUpkeep,
                        block.number,
                        reduction.eventPeriod,
                        record.perBlockEmission
                    );

                mintAmount = amountToEmit;
                record.perBlockEmission = newEmissionRate;
                previousReductionBlock = uint96(finalReductionBlock);
            } else {
                mintAmount =
                    (block.number - lastUpkeep) *
                    record.perBlockEmission;
            }

            mintAmount = mintAmount <= mintableAmount
                ? mintAmount
                : mintableAmount;
        } else {
            mintAmount = 0;
        }
    }

    function calculateHalvingAmount(
        uint256 lastReductionBlock,
        uint256 lastUpkeep,
        uint256 currentBlock,
        uint256 eventPeriod,
        uint256 currentEmissionRate
    )
        external
        pure
        override
        returns (
            uint256 amountToEmit,
            uint256 finalReductionBlock,
            uint256 newEmissionRate
        )
    {
        return
            _calculateHalvingAmount(
                lastReductionBlock,
                lastUpkeep,
                currentBlock,
                eventPeriod,
                currentEmissionRate
            );
    }

    function setSchedule(ScheduleChangeRequest[] calldata newSchedules)
        external
        override
        onlyRole(SCHEDULE_MANAGER)
    {
        uint256 newMaxAmount;
        uint256 oldMaxAmount;

        ScheduleRecord memory record;
        for (uint256 i = 0; i < newSchedules.length; i++) {
            require(
                newSchedules[i].recipientIndex !=
                    RecipientType.KEY_CONTRIBUTORS,
                "Key contributors sched. is fixed"
            );
            require(
                newSchedules[i].recipientIndex != RecipientType.TEAM_ADVISORS,
                "Team & Advisors sched. is fixed"
            );
            record = schedule[uint256(newSchedules[i].recipientIndex)];
            require(
                newSchedules[i].maxEmission >= record.amountEmitted,
                "max emission < emitted amount"
            );
            if (newSchedules[i].disableReduction) {
                reductions[
                    uint256(newSchedules[i].recipientIndex)
                ] = ReductionEvent(0, 0);
                record.hasReduction = false;
            }

            record.maxEmission = newSchedules[i].maxEmission;
            record.perBlockEmission = newSchedules[i].perBlockEmission;

            oldMaxAmount += schedule[uint256(newSchedules[i].recipientIndex)]
                .maxEmission;
            schedule[uint256(newSchedules[i].recipientIndex)] = record;
            newMaxAmount += newSchedules[i].maxEmission;
            emit SetSchedule(newSchedules[i]);
        }
        require(newMaxAmount == oldMaxAmount, "Invalid max emission amounts");
    }

    function setRecipients(Recipient[] calldata recipients)
        external
        override
        onlyRole(RECIPIENT_MANAGER)
    {
        uint8[] memory recipientTypes = new uint8[](recipients.length);
        address[] memory recipientAddresses = new address[](recipients.length);
        bool[] memory recipientTypeCheck = new bool[](
            NUMBER_OF_RECIPIENT_TYPES
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            require(
                recipients[i].recipientType != RecipientType.TEAM_ADVISORS,
                "Can't update the team address"
            );
            require(
                recipients[i].recipient != address(0),
                "Cannot be 0 address"
            );

            require(
                !recipientTypeCheck[uint256(recipients[i].recipientType)],
                "Cannot repeat recipient types"
            );
            recipientTypeCheck[uint256(recipients[i].recipientType)] = true;
            schedule[uint256(recipients[i].recipientType)]
                .recipient = recipients[i].recipient;
            recipientTypes[i] = uint8(recipients[i].recipientType);
            recipientAddresses[i] = recipients[i].recipient;
        }
        emit SetRecipients(recipientTypes, recipientAddresses);
    }

    function setUpkeepRate(uint32 initialUpkeepRate)
        external
        override
        onlyRole(UPKEEP_MANAGER)
    {
        require(initialUpkeepRate > 0, "Upkeep rate is zero");

        emit SetUpkeepRate(initialUpkeepRate, upkeepRate);

        upkeepRate = initialUpkeepRate;
    }

    function getSchedules()
        external
        view
        override
        returns (ScheduleRecord[] memory schedules)
    {
        schedules = new ScheduleRecord[](NUMBER_OF_RECIPIENT_TYPES);
        for (uint256 i = 0; i < NUMBER_OF_RECIPIENT_TYPES; i++) {
            schedules[i] = schedule[i];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ITokenController {
    /// Structs & Enums
    enum RecipientType {
        COMMUNITY_GROWTH,
        ECOSYSTEM_GRANTS,
        KEY_CONTRIBUTORS,
        TEAM_ADVISORS
    }

    struct Recipient {
        RecipientType recipientType;
        address recipient;
    }

    struct ReductionEvent {
        uint64 eventPeriod; // The length of a halving event in blocks.
        uint96 previousReductionBlock; // The last block that a reduction event occurred on
    }

    struct ScheduleRecord {
        address recipient; // The address that this schedule's tokens will be sent to
        uint32 delayPeriod; /// The number of blocks to wait before starting emissions
        bool hasReduction; ///
        uint256 maxEmission; // The maximum amount of tokens that can be minted for this schedule recipient
        uint256 amountEmitted; // The amount of tokens that this schedule recipient has received so far
        uint256 perBlockEmission; /// The amount of tokens to emit per block
    }

    struct ScheduleCreation {
        RecipientType recipientIndex;
        uint256 perBlockEmission;
        uint256 maxEmission;
        uint32 delayPeriod;
        uint64 halvingEventBlockCount; // The halving event period for this schedule
    }

    struct ScheduleChangeRequest {
        RecipientType recipientIndex; /// The recipient who will receive the tokens
        uint256 perBlockEmission;
        uint256 maxEmission;
        bool disableReduction; /// If this is true, it will permanently disable the halving event for this recipient
    }

    struct ConstructorParams {
        uint256 totalScheduleEmissionAmount;
        uint256 emissionStartOffset;
        address rewardTokenAddress;
        uint32 initialUpkeepRate;
        address superAdmin;
        address managerAddress;
    }

    /// Events

    /// @notice Event used to signify that one or more schedules have been changed
    /// @param newSchedule  The details of the new schedule, including the recipient
    event SetSchedule(ScheduleChangeRequest newSchedule);

    /// @notice Event used to signify that the recipients have had their addresses changed
    /// @dev The index of the first parameter aligns with the value in the second parameter
    /// @param recipientTypes The type of recipient that was updated
    /// @param recipients The new addresses for the recipient types
    event SetRecipients(uint8[] recipientTypes, address[] recipients);

    /// @notice Event used to signify that the upkeep rate has been changed
    /// @param newRate  The new upkeep rate
    /// @param oldRate  The old upkeep rate
    event SetUpkeepRate(uint32 newRate, uint32 oldRate);

    /// @notice Event used to signal that upkeep has been performed
    /// @param recipients  The recipient addresses that received tokens
    /// @param amounts  The amounts each recipient received. The index in this array corresponds to the address in the recipients array.
    event UpkeepPerformed(address[] recipients, uint256[] amounts);

    /// Functions

    /// @notice Sets the token emission schedule for all recipients
    /// @dev A schedule for all recipient types must be provided
    /// @dev This cannot be used to update the Key Contributors schedule
    /// @param schedules The new emission schedules for each recipient type
    function setSchedule(ScheduleChangeRequest[] calldata schedules) external;

    /// @notice Sets the recipient address for each recipient type
    /// @dev This can be used to set an address for 1 or more recipients
    /// @dev This cannot be used to change the Team and Advisors recipient address
    /// @param recipients  The addresses to set
    function setRecipients(Recipient[] calldata recipients) external;

    /// @notice Sets the number of blocks that have to elapse before an upkeep can be performed
    /// @param upkeepRate  the number of blocks that must elapse
    function setUpkeepRate(uint32 upkeepRate) external;

    /// @notice Returns the schedules, and their recipients
    /// @return schedules  The schedules for token emissions in the system
    function getSchedules()
        external
        view
        returns (ScheduleRecord[] memory schedules);

    /// @notice Calculates the amount of tokens that can be minted for a schedule that halves at regular intervals
    /// @param lastUpkeep  The block that upkeep was last performed
    /// @param currentBlock  The current block number
    /// @param eventPeriod  The number of blocks between halving events. Halving happens on the first block of a new period
    /// @param currentEmissionRate  the current amount of tokens being emitted
    /// @return amountToEmit  The amount to mint for the range of blocks (currentBlock - lastUpkeepBlock)
    /// @return finalReductionBlock  The last block within the range that a reduction event occurred on
    /// @return newEmissionRate  The new emission rate for future blocks
    function calculateHalvingAmount(
        uint256 lastReductionBlock,
        uint256 lastUpkeep,
        uint256 currentBlock,
        uint256 eventPeriod,
        uint256 currentEmissionRate
    )
        external
        pure
        returns (
            uint256 amountToEmit,
            uint256 finalReductionBlock,
            uint256 newEmissionRate
        );

    /// @notice Returns the amount of tokens that can be minted for a given schedule
    /// @param recipient  The recipient schedule to check
    /// @return mintAmount  The amount of tokens that can be minted
    function getPendingMintAmounts(RecipientType recipient)
        external
        view
        returns (uint256 mintAmount);

    /// Autogenerated getter function definitions

    /// @notice Autogenerated getter functions for state variable
    function upkeepRate() external view returns (uint32);

    /// @notice Autogenerated getter functions for state variable
    function emissionStartBlock() external view returns (uint96);

    /// @notice Autogenerated getter functions for state variable
    function lastUpkeepBlock() external view returns (uint96);

    /// @notice Autogenerated getter functions for state variable
    function tokenAddress() external view returns (address);

    /// @notice Autogenerated getter functions for state variable
    function reductions(uint256 recipient)
        external
        view
        returns (uint64 eventPeriod, uint96 previousReductionBlock);

    /// @notice Autogenerated getter functions for state variable
    function schedule(uint256 recipientType)
        external
        returns (
            address recipient,
            uint32 delayPeriod,
            bool hasReduction,
            uint256 maxEmission,
            uint256 amountEmitted,
            uint256 perBlockEmission
            // ReductionEvent memory reduction
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRevolutToken is IERC20 {
    /// @notice Mints an amount of tokens to the given address
    /// @dev This will only mint up to the maximum mintable amount set in the constructor
    /// @dev The contract will perform a partial mint if the amount requested is less than the amount available to be minted.
    /// @dev This is secured with the Ownable onlyOwner modifier
    /// @param to  The address that will receive the new tokens
    /// @param amount  The amount of tokens to create
    function mint(address to, uint256 amount) external;

    /// @notice Autogenerated getter functions for state variable
    function maxMintableAmount() external view returns (uint256);

    /// @notice Autogenerated getter functions for state variable
    function amountMinted() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IRevolutToken.sol";

contract RevolutToken is ERC20, Ownable, ERC20Burnable, IRevolutToken {
    uint256 public immutable override maxMintableAmount;
    uint256 public override amountMinted = 0;

    constructor(
        uint256 maximumSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) ERC20(tokenName, tokenSymbol) {
        maxMintableAmount = maximumSupply;
    }

    function mint(address to, uint256 amount) external override onlyOwner {
        require(amountMinted < maxMintableAmount, "max token amount reached");

        uint256 mintableAmount = amount;

        if ((maxMintableAmount - amountMinted) < amount) {
            mintableAmount = maxMintableAmount - amountMinted;
        }
        amountMinted += mintableAmount;
        _mint(to, mintableAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IIntermediaryHoldingContract.sol";
import "../implementations/RevolutToken.sol";

contract IntermediaryHoldingContract is
    IIntermediaryHoldingContract,
    AccessControl
{
    /// ### Dependents
    RevolutToken public immutable token;

    /// ### Roles
    bytes32 public constant BURN_TOKENS = keccak256("BURN_TOKENS");
    bytes32 public constant WITHDRAW_TOKENS = keccak256("WITHDRAW_TOKENS");

    bytes32 public constant BURN_ADMIN = keccak256("BURN_ADMIN");
    bytes32 public constant WITHDRAW_ADMIN = keccak256("WITHDRAWAL_ADMIN");

    /// @notice Sets the contract's initial state on deployment
    constructor(
        RevolutToken tokenAddress,
        address burnAdmin,
        address withdrawalAdmin
    ) {
        require(address(tokenAddress) != address(0), "invalid token address");
        require(burnAdmin != address(0), "invalid burn admin address");
        require(
            withdrawalAdmin != address(0),
            "invalid withdraw admin address"
        );
        token = tokenAddress;

        // Setup access controls
        _setupRole(BURN_TOKENS, burnAdmin);
        _setupRole(BURN_ADMIN, burnAdmin);

        _setupRole(WITHDRAW_TOKENS, withdrawalAdmin);
        _setupRole(WITHDRAW_ADMIN, withdrawalAdmin);

        // Establish the BURN_ADMIN role as the admin role for BURN_TOKENS
        _setRoleAdmin(BURN_TOKENS, BURN_ADMIN);
        _setRoleAdmin(WITHDRAW_TOKENS, WITHDRAW_ADMIN);
    }

    function burn(uint256 amount)
        external
        override
        onlyRole(BURN_TOKENS)
        returns (bool status)
    {
        token.burn(amount);
        status = true;
    }

    function withdraw(uint256 amount)
        external
        override
        onlyRole(WITHDRAW_TOKENS)
        returns (bool status)
    {
        require(token.transfer(msg.sender, amount), "Transfer failed");
        status = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IIntermediaryHoldingContract {
    /// @notice Burns a given amount of tokens that are being held by the IntermediaryHoldingContract
    /// @dev The balance of the IntermediaryHoldingContract must be >= amount
    /// @param amount  The amount of tokens to burn
    /// @return status Returns a boolean value indicating whether the operation succeeded.
    function burn(uint256 amount) external returns (bool status);

    /// @notice Withdraws a given amount of tokens that are being held by the IntermediaryHoldingContract
    /// @dev The balance of the IntermediaryHoldingContract must be >= amount
    /// @param amount  The amount of tokens to withdraw
    /// @return status Returns a boolean value indicating whether the operation succeeded.
    function withdraw(uint256 amount) external returns (bool status);
}