// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IVotingEscrow} from "./interfaces/protocols/IVotingEscrow.sol";
import {IDillGauge} from "./interfaces/protocols/IDillGauge.sol";
import {IGaugeProxy} from "./interfaces/protocols/IGaugeProxy.sol";
import {IMinter} from "./interfaces/protocols/IMinter.sol";
import {IFeeDistributor} from "./interfaces/protocols/IFeeDistributor.sol";
import {IFeeHandler} from "./interfaces/protocols/IFeeHandler.sol";
import {IUpgradeSource} from "./interfaces/IUpgradeSource.sol";
import {IVault} from "./interfaces/IVault.sol";
import {EternalStorage} from "./lib/EternalStorage.sol";
import {Errors, _require} from "./lib/Errors.sol";
import {SafeTransferLib} from "./lib/SafeTransferLib.sol";
import {GovernableInit} from "./GovernableInit.sol";

/// @notice Beluga VeManager (Dill-like gauges)
/// @author Chainvisions
/// @notice A contract for managing veToken locking and gauge farming/boosting.

contract VeManagerDillLike is GovernableInit, IUpgradeSource, EternalStorage {
    using SafeTransferLib for IERC20;

    /// @notice Info for each reward gauge.
    struct GaugeInfo {
        uint16 lockNumerator;  // Percentage of rewards on this gauge to lock.
        uint16 kickbackNumerator;    // Percentage of rewards to distribute to the kickback pool.
        address strategy;   // Permitted strategy contract for using this gauge.
        address gauge;      // Gauge contract of the token.
    }

    /// @notice Mapping for information on each reward gauge.
    mapping(address => GaugeInfo) public gaugeInfo;

    /// @notice Addresses permitted to handle veToken voting power.
    mapping(address => bool) public governors;

    mapping(address => bool) private infoExistsForGauge;

    /// @notice Emitted when a new implementation upgrade is queued.
    event UpgradeAnnounced(address newImplementation);

    modifier onlyGovernors {
        _require(
            msg.sender == governance()
            || governors[msg.sender],
            Errors.GOVERNORS_ONLY
        );
        _;
    }

    /// @notice Initializes the VeManager contract.
    /// @param _store Storage contract for access control.
    /// @param _MAX_LOCK_TIME Max time for locking tokens into the escrow.
    /// @param _escrow veToken reward escrow for locking.
    /// @param _controller veToken Gauge Controller for casting votes.
    function __Manager_init(
        address _store,
        uint256 _MAX_LOCK_TIME,
        address _escrow,
        address _controller
    ) external initializer {
        __Governable_init_(_store);

        // Set max lock time.
        _setMaxLockTime(_MAX_LOCK_TIME);

        // Assign state.
        _setVotingEscrow(_escrow);
        _setRewardToken(IVotingEscrow(_escrow).token());
        _setGaugeController(_controller);
        _setUpgradeTimelock(12 hours);
    }

    /// @notice Locks reward tokens for veTokens.
    /// @param _amount Amount of tokens to lock.
    function lockTokens(uint256 _amount) external onlyGovernors {
        _lockRewards(_amount);
    }

    /// @notice Locks all reward tokens held for veTokens.
    function lockAllTokens() external onlyGovernors {
        _lockRewards(rewardToken().balanceOf(address(this)));
    }

    /// @notice Withdraws the veToken lock.
    function withdrawLock() external onlyGovernors {
        votingEscrow().withdraw();
        _setVeTokenLockActive(false);
    }

    /// @notice Votes for a specific reward gauge weight.
    /// @param _gauges Gauges to vote for the weight of.
    /// @param _weights Reward weights of the gauges.
    function voteForGauge(address[] calldata _gauges, uint256[] calldata _weights) external onlyGovernors {
        gaugeController().vote(_gauges, _weights);
    }

    /// @notice Executes a transaction on the VeMananger. Governance only.
    /// @param _to Address to call to.
    /// @param _value Value to call the address with.
    /// @param _data Data to call the address with.
    /// @return Whether or not the call succeeded and the return data.
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyGovernance returns (bool, bytes memory) {
        // Execute the transaction
        (bool success, bytes memory result) = _to.call{value: _value}(_data);

        // Return the results
        return (success, result);
    }

    /// @notice Deposits tokens into the VeManager contract.
    /// @param _token Token to deposit into the VeManager.
    /// @param _amount Amount of tokens to deposit.
    function depositGaugeTokens(address _token, uint256 _amount) external {
        // Read gauge data and store for reading the data of.
        GaugeInfo memory gaugeParams = gaugeInfo[_token];

        // Check if caller is the gauge's permitted strategy.
        _require(msg.sender == gaugeParams.strategy, Errors.CALLER_NOT_STRATEGY);

        // We can now transfer the tokens from the strategy and stake.
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(_token).safeApprove(gaugeParams.gauge, 0);
        IERC20(_token).safeApprove(gaugeParams.gauge, _amount);

        IDillGauge(gaugeParams.gauge).deposit(_amount);
    }

    /// @notice Withdraws tokens from the VeManager contract.
    /// @param _token Token to withdraw from the VeManager.
    /// @param _amount Amount to withdraw from the contract.
    function withdrawGaugeTokens(address _token, uint256 _amount) external {
        // Read gauge data and store for reading the data of.
        GaugeInfo memory gaugeParams = gaugeInfo[_token];

        // Check if caller is the gauge's permitted strategy.
        _require(msg.sender == gaugeParams.strategy, Errors.CALLER_NOT_STRATEGY);

        // We can now the transfer the gauge tokens to the strategy.
        IDillGauge(gaugeParams.gauge).withdraw(_amount);
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /// @notice Withdraws all tokens from the VeManager contract.
    /// @param _token Token to withdraw all stake from the gauge of.
    function divestAllGaugeTokens(address _token) external {
        // Read gauge data and store for reading the data of.
        GaugeInfo memory gaugeParams = gaugeInfo[_token];

        // Check if caller is the gauge's permitted strategy.
        _require(msg.sender == gaugeParams.strategy, Errors.CALLER_NOT_STRATEGY);

        // We can now divest the gauge tokens and send them to the strategy.
        IDillGauge(gaugeParams.gauge).exit();
        IERC20(_token).safeTransfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }

    /// @notice Claims rewards from a specified gauge and sends to the strategy.
    /// @param _token Token to claim the rewards from the gauge contract of.
    function claimGaugeRewards(address _token) external {
        // Read gauge data and store for reading the data of.
        GaugeInfo memory gaugeParams = gaugeInfo[_token];
        IERC20 _rewardToken = rewardToken();

        // Check if caller is the gauge's permitted strategy.
        _require(msg.sender == gaugeParams.strategy, Errors.CALLER_NOT_STRATEGY);

        // We can now collect and distribute any reward tokens earned.
        IDillGauge(gaugeParams.gauge).getReward();

        uint256 gaugeEarnings = _rewardToken.balanceOf(address(this));
        if(gaugeEarnings > 0) {
            uint256 toLock = 0;
            uint256 kickback = 0;
            if(gaugeParams.lockNumerator > 0) {
                toLock = (gaugeEarnings * gaugeParams.lockNumerator) / 10000;
                _lockRewards(toLock);
            }

            if(gaugeParams.kickbackNumerator > 0) {
                IVault _kickbackPool = kickbackPool();
                kickback = (gaugeEarnings * gaugeParams.kickbackNumerator) / 10000;
                _rewardToken.safeTransfer(address(_kickbackPool), kickback);
                _kickbackPool.notifyRewardAmount(address(_rewardToken), kickback);
            }

            _rewardToken.safeTransfer(msg.sender, (gaugeEarnings - (toLock + kickback)));
        }
    }

    /// @notice Claims earned fees from the FeeDistributor.
    function claimEarnedFees() external {
        IFeeDistributor _feeDistributor = feeDistributor();
        address handlerAddress = address(feeHandler());
        address[] memory rewardTokens = _feeDistributor.tokens();
        uint256[] memory rewardBalances = new uint256[](rewardTokens.length);

        // Perform claim.
        _feeDistributor.claim();

        // Send rewards to the handler.
        if(handlerAddress != address(0)) {
            for(uint256 i = 0; i < rewardTokens.length; i++) {
                address reward = rewardTokens[i];
                uint256 rewardBalance = IERC20(rewardTokens[i]).balanceOf(address(this));
                rewardBalances[i] = rewardBalance;

                IERC20(reward).safeTransfer(handlerAddress, rewardBalance);
            }
            IFeeHandler(handlerAddress).handleFees(rewardBalances);
        }
    }

    /// @notice Finalizes or cancels upgrades by setting the next implementation address to 0.
    function finalizeUpgrade() external override onlyGovernance {
        _setNextImplementation(address(0));
        _setNextImplementationTimestamp(0);
    }

    /// @notice Whether or not the proxy should upgrade.
    /// @return If the proxy can be upgraded and the new implementation address.
    function shouldUpgrade() external view override returns (bool, address) {
        return (
            nextImplementationTimestamp() != 0
                && block.timestamp > nextImplementationTimestamp()
                && nextImplementation() != address(0),
            nextImplementation()
        );
    }

    /// @notice Total amount of tokens staked in a specific gauge.
    /// @param _token Token to fetch the gauge stake of.
    /// @return The amount of `_token` staked into its respective gauge.
    function totalStakeForGauge(address _token) external view returns (uint256) {
        return IDillGauge(gaugeInfo[_token].gauge).balanceOf(address(this));
    }

    /// @notice Schedules an upgrade to the vault.
    /// @param _impl Address of the new implementation.
    function scheduleUpgrade(address _impl) public onlyGovernance {
        _setNextImplementation(_impl);
        _setNextImplementationTimestamp(block.timestamp + upgradeTimelock());
        emit UpgradeAnnounced(_impl);
    }

    /// @notice Recovers a specified token from the VeManager contract.
    /// @param _token Token to recover from the manager.
    /// @param _amount Amount to recover from the manager.
    function recoverToken(
        address _token, 
        uint256 _amount
    ) public onlyGovernance {
        IERC20(_token).safeTransfer(governance(), _amount);
    }

    /// @notice Adds a new gauge to the VeManager contract.
    /// @param _token Address of the token to add.
    /// @param _strategy Strategy that is permitted to use this gauge.
    /// @param _gauge Gauge of the token.
    /// @param _lockNumerator Percentage of gauge rewards to lock into veTokens.
    function addGauge(
        address _token,
        address _strategy,
        address _gauge,
        uint16 _lockNumerator,
        uint16 _kickbackNumerator
    ) public onlyGovernors {
        _require(!infoExistsForGauge[_token], Errors.GAUGE_INFO_ALREADY_EXISTS);
        // Create new GaugeInfo struct.
        GaugeInfo memory gaugeParams;
        gaugeParams.gauge = _gauge;
        gaugeParams.strategy = _strategy;
        gaugeParams.lockNumerator = _lockNumerator;
        gaugeParams.kickbackNumerator = _kickbackNumerator;

        // Set info.
        gaugeInfo[_token] = gaugeParams;
        infoExistsForGauge[_token] = true;
    }

    /// @notice Increases the VeManager's lock time.
    /// @param _increaseBy The time to increase the lock time by.
    function increaseLockTime(
        uint256 _increaseBy
    ) public onlyGovernors {
        IVotingEscrow _votingEscrow = votingEscrow();

        uint256 lockEnd = _votingEscrow.locked__end(address(this));
        _votingEscrow.increase_unlock_time((lockEnd + _increaseBy));
    }

    /// @notice Sets the strategy of a specified gauge.
    /// @param _token Token of the gauge to set the strategy of.
    /// @param _newStrategy New strategy for the gauge.
    function setGaugeStrategy(
        address _token,
        address _newStrategy
    ) public onlyGovernors {
        _require(infoExistsForGauge[_token], Errors.GAUGE_NON_EXISTENT);

        // Set strategy.
        GaugeInfo storage gaugeParams = gaugeInfo[_token];
        gaugeParams.strategy = _newStrategy;
    }

    /// @notice Sets the lock numerator of a specified gauge.
    /// @param _token Token of the gauge to set the strategy of.
    /// @param _newLockNumerator New lock numerator for the gauge.
    function setGaugeLockNumerator(
        address _token,
        uint16 _newLockNumerator
    ) public onlyGovernors {
        _require(infoExistsForGauge[_token], Errors.GAUGE_NON_EXISTENT);

        // Set lock numerator.
        GaugeInfo storage gaugeParams = gaugeInfo[_token];
        gaugeParams.lockNumerator = _newLockNumerator;
    }

    /// @notice Sets the kickback numerator of a specified gauge.
    /// @param _token Token of the gauge to set the kickback numerator of.
    /// @param _newKickbackNumerator New kickback numerator of the gauge.
    function setGaugeKickbackNumerator(
        address _token,
        uint16 _newKickbackNumerator
    ) public onlyGovernors {
        _require(infoExistsForGauge[_token], Errors.GAUGE_NON_EXISTENT);

        // Set kickback numerator.
        GaugeInfo storage gaugeParams = gaugeInfo[_token];
        gaugeParams.kickbackNumerator = _newKickbackNumerator;
    }

    /// @notice Sets the FeeDistributor contract for claiming fees.
    /// @param _feeDistributor FeeDistributor contract.
    function setFeeDistributor(
        address _feeDistributor
    ) public onlyGovernors {
        _setFeeDistributor(_feeDistributor);
    }

    /// @notice Sets the FeeHandler contract for fee conversion and handling.
    /// @param _feeHandler FeeHandler contract.
    function setFeeHandler(
        address _feeHandler
    ) public onlyGovernors {
        _setFeeHandler(_feeHandler);
    }

    /// @notice Sets the kickback pool contract for kickback rewards.
    /// @param _kickbackPool Kickback pool contract.
    function setKickbackPool(
        address _kickbackPool
    ) public onlyGovernors {
        _setKickbackPool(_kickbackPool);
    }

    /// @notice Adds a governor to the VeManager.
    /// @param _governor Governor to add from the manager.
    function addGovernor(
        address _governor
    ) public onlyGovernance {
        governors[_governor] = true;
    }

    /// @notice Removes a governor from the VeManager.
    /// @param _governor Governor to remove from the manager.
    function removeGovernor(
        address _governor
    ) public onlyGovernance {
        governors[_governor] = false;
    }

    /// @notice Amount of veTokens held by the VeManager.
    function netVeAssets() public view returns (uint256) {
        return IERC20(address(votingEscrow())).balanceOf(address(this));
    }

    /// @notice The VeManager's veToken lock expiration.
    function lockExpiration() public view returns (uint256) {
        return votingEscrow().locked__end(address(this));
    }

    /// @notice Next implementation contract for the proxy.
    function nextImplementation() public view returns (address) {
        return _getAddress("nextImplementation");
    }

    /// @notice Timestamp of when the next upgrade can be executed.
    function nextImplementationTimestamp() public view returns (uint256) {
        return _getUint256("nextImplementationTimestamp");
    }

    /// @notice Timelock for contract upgrades.
    function upgradeTimelock() public view returns (uint256) {
        return _getUint256("upgradeTimelock");
    }

    /// @notice Max lock time for locking for veTokens.
    function maxLockTime() public view returns (uint256) {
        return _getUint256("maxLockTime");
    }

    /// @notice veToken VotingEscrow contract.
    function votingEscrow() public view returns (IVotingEscrow) {
        return IVotingEscrow(_getAddress("votingEscrow"));
    }

    /// @notice Reward token to farm in gauges and lock.
    function rewardToken() public view returns (IERC20) {
        return IERC20(_getAddress("rewardToken"));
    }

    /// @notice Gauge controller contract for voting.
    function gaugeController() public view returns (IGaugeProxy) {
        return IGaugeProxy(_getAddress("gaugeController"));
    }

    /// @notice Fee distributor contract for claiming fees. Optional.
    function feeDistributor() public view returns (IFeeDistributor) {
        return IFeeDistributor(_getAddress("feeDistributor"));
    }

    /// @notice Beluga fee handler for handling claimed fees. Optional.
    function feeHandler() public view returns (IFeeHandler) {
        return IFeeHandler(_getAddress("feeHandler"));
    }

    /// @notice Whether or not a veToken lock is active on the escrow.
    function veTokenLockActive() public view returns (bool) {
        return _getBool("veTokenLockActive");
    }

    /// @notice Kickback pool for distributing kickback rewards.
    function kickbackPool() public view returns (IVault) {
        return IVault(_getAddress("kickbackPool"));
    }

    function _lockRewards(uint256 _amountToLock) internal {
        IERC20 _rewardToken = rewardToken();
        address escrowAddress = address(votingEscrow());

        _rewardToken.safeApprove(escrowAddress, 0);
        _rewardToken.safeApprove(escrowAddress, _amountToLock);

        if(veTokenLockActive()) {
            // We can simply increase the amount.
            IVotingEscrow(escrowAddress).increase_amount(_amountToLock);
        } else {
            // We need to create a new lock.
            IVotingEscrow(escrowAddress).create_lock(_amountToLock, (block.timestamp + maxLockTime()));
            _setVeTokenLockActive(true);
        }
    }

    function _setNextImplementation(address _address) internal {
        _setAddress("nextImplementation", _address);
    }

    function _setNextImplementationTimestamp(uint256 _value) internal {
        _setUint256("nextImplementationTimestamp", _value);
    }

    function _setUpgradeTimelock(uint256 _value) internal {
        _setUint256("upgradeTimelock", _value);
    }

    function _setMaxLockTime(uint256 _value) internal {
        _setUint256("maxLockTime", _value);
    }

    function _setVotingEscrow(address _value) internal {
        _setAddress("votingEscrow", _value);
    }

    function _setRewardToken(address _value) internal {
        _setAddress("rewardToken", _value);
    }

    function _setGaugeController(address _value) internal {
        _setAddress("gaugeController", _value);
    }

    function _setRewardMinter(address _value) internal {
        _setAddress("rewardMinter", _value);
    }

    function _setFeeDistributor(address _value) internal {
        _setAddress("feeDistributor", _value);
    }

    function _setFeeHandler(address _value) internal {
        _setAddress("feeHandler", _value);
    }

    function _setVeTokenLockActive(bool _value) internal {
        _setBool("veTokenLockActive", _value);
    }

    function _setKickbackPool(address _value) internal {
        _setAddress("kickbackPool", _value);
    }

    function findArrayItem(address[] memory _array, address _item) private pure returns (uint256) {
        for(uint256 i = 0; i < _array.length; i++) {
            if(_array[i] == _item) {
                return i;
            }
        }
        return type(uint256).max;
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

interface IVotingEscrow {
    function create_lock(uint256, uint256) external;
    function increase_amount(uint256) external;
    function increase_unlock_time(uint256) external;
    function withdraw() external;
    function token() external view returns (address);
    function locked() external view returns (uint256);
    function locked__end(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IDillGauge {
    function deposit(uint256) external;
    function depositFor(uint256, address) external;
    function depositAll() external;
    function withdraw(uint256) external;
    function withdrawAll() external;
    function exit() external;
    function getReward() external;
    function balanceOf(address) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IGaugeProxy {
    function collect() external;
    function deposit() external;
    function distribute() external;
    function vote(address[] memory, uint256[] memory) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

interface IMinter {
    function mint(address) external;
    function mint_for(address, address) external;
}

/// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

interface IFeeDistributor {
    function claim() external;
    function tokens() external view returns (address[] memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

interface IFeeHandler {
    function handleFees(uint256[] memory) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IUpgradeSource {
  function finalizeUpgrade() external;
  function shouldUpgrade() external view returns (bool, address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IVault {
    function underlyingBalanceInVault() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);

    function underlying() external view returns (address);
    function strategy() external view returns (address);

    function setStrategy(address) external;
    function setVaultFractionToInvest(uint256) external;

    function deposit(uint256) external;
    function depositFor(address, uint256) external;

    function withdrawAll() external;
    function withdraw(uint256) external;

    function getReward() external;
    function getRewardByToken(address) external;
    function notifyRewardAmount(address, uint256) external;

    function underlyingUnit() external view returns (uint256);
    function getPricePerFullShare() external view returns (uint256);
    function underlyingBalanceWithInvestmentForHolder(address) external view returns (uint256);

    // hard work should be callable only by the controller (by the hard worker) or by governance
    function doHardWork() external;
    function rebalance() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Eternal Storage Pattern.
/// @author Chainvisions
/// @notice A mapping-based storage pattern, allows for collision-less storage.

contract EternalStorage {
    mapping(bytes32 => uint256) private uint256Storage;
    mapping(bytes32 => address) private addressStorage;
    mapping(bytes32 => bool) private boolStorage;

    function _setUint256(string memory _key, uint256 _value) internal {
        uint256Storage[keccak256(abi.encodePacked(_key))] = _value;
    }

    function _setAddress(string memory _key, address _value) internal {
        addressStorage[keccak256(abi.encodePacked(_key))] = _value;
    }

    function _setBool(string memory _key, bool _value) internal {
        boolStorage[keccak256(abi.encodePacked(_key))] = _value;
    }

    function _getUint256(string memory _key) internal view returns (uint256) {
        return uint256Storage[keccak256(abi.encodePacked(_key))];
    }

    function _getAddress(string memory _key) internal view returns (address) {
        return addressStorage[keccak256(abi.encodePacked(_key))];
    }

    function _getBool(string memory _key) internal view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked(_key))];
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BEL#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "BEL#" part is a known constant
        // (0x42454C23): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(200, add(0x42454C23000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}


/// @title Beluga Errors Library
/// @author Chainvisions
/// @author Forked and modified from Balancer (https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/solidity-utils/contracts/helpers/BalancerErrors.sol)
/// @notice Library for efficiently handling errors on Beluga contracts with reduced bytecode size additions.

library Errors {
    // Vault
    uint256 internal constant NUMERATOR_ABOVE_MAX_BUFFER = 0;
    uint256 internal constant UNDEFINED_STRATEGY = 1;
    uint256 internal constant CALLER_NOT_WHITELISTED = 2;
    uint256 internal constant VAULT_HAS_NO_SHARES = 3;
    uint256 internal constant SHARES_MUST_NOT_BE_ZERO = 4;
    uint256 internal constant LOSSES_ON_DOHARDWORK = 5;
    uint256 internal constant CANNOT_UPDATE_STRATEGY = 6;
    uint256 internal constant NEW_STRATEGY_CANNOT_BE_EMPTY = 7;
    uint256 internal constant VAULT_AND_STRATEGY_UNDERLYING_MUST_MATCH = 8;
    uint256 internal constant STRATEGY_DOES_NOT_BELONG_TO_VAULT = 9;
    uint256 internal constant CALLER_NOT_GOV_OR_REWARD_DIST = 10;
    uint256 internal constant NOTIF_AMOUNT_INVOKES_OVERFLOW = 11;
    uint256 internal constant REWARD_INDICE_NOT_FOUND = 12;
    uint256 internal constant REWARD_TOKEN_ALREADY_EXIST = 13;
    uint256 internal constant DURATION_CANNOT_BE_ZERO = 14;
    uint256 internal constant REWARD_TOKEN_DOES_NOT_EXIST = 15;
    uint256 internal constant REWARD_PERIOD_HAS_NOT_ENDED = 16;
    uint256 internal constant CANNOT_REMOVE_LAST_REWARD_TOKEN = 17;
    uint256 internal constant DENOMINATOR_MUST_BE_GTE_NUMERATOR = 18;
    uint256 internal constant CANNOT_UPDATE_EXIT_FEE = 19;
    uint256 internal constant CANNOT_TRANSFER_IMMATURE_TOKENS = 20;
    uint256 internal constant CANNOT_DEPOSIT_ZERO = 21;
    uint256 internal constant HOLDER_MUST_BE_DEFINED = 22;

    // VeManager
    uint256 internal constant GOVERNORS_ONLY = 23;
    uint256 internal constant CALLER_NOT_STRATEGY = 24;
    uint256 internal constant GAUGE_INFO_ALREADY_EXISTS = 25;
    uint256 internal constant GAUGE_NON_EXISTENT = 26;

    // Strategies
    uint256 internal constant CALL_RESTRICTED = 27;
    uint256 internal constant STRATEGY_IN_EMERGENCY_STATE = 28;
    uint256 internal constant REWARD_POOL_UNDERLYING_MISMATCH = 29;
    uint256 internal constant UNSALVAGABLE_TOKEN = 30;

    // Strategy splitter.
    uint256 internal constant ARRAY_LENGTHS_DO_NOT_MATCH = 31;
    uint256 internal constant WEIGHTS_DO_NOT_ADD_UP = 32;
    uint256 internal constant REBALANCE_REQUIRED = 33;
    uint256 internal constant INDICE_DOES_NOT_EXIST = 34;

    // Strategy-specific
    uint256 internal constant WITHDRAWAL_WINDOW_NOT_ACTIVE = 35;

    // 0xDAO Partnership Staking.
    uint256 internal constant CANNOT_WITHDRAW_MORE_THAN_STAKE = 36;

    // Active management strategies.
    uint256 internal constant TX_ORIGIN_NOT_PERMITTED = 37;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Storage} from "./Storage.sol";

/**
 * @dev Contract for access control where the governance address specified
 * in the Storage contract can be granted access to specific functions
 * on a contract that inherits this contract.
 *
 * The difference between GovernableInit and Governable is that GovernableInit supports proxy
 * smart contracts.
 */

contract GovernableInit is Initializable {

  bytes32 internal constant _STORAGE_SLOT = 0xa7ec62784904ff31cbcc32d09932a58e7f1e4476e1d041995b37c917990b16dc;

  modifier onlyGovernance() {
    require(Storage(_storage()).isGovernance(msg.sender), "Governable: Not governance");
    _;
  }

  constructor() {
    assert(_STORAGE_SLOT == bytes32(uint256(keccak256("eip1967.governableInit.storage")) - 1));
  }

  function __Governable_init_(address _store) public initializer {
    _setStorage(_store);
  }

  function _setStorage(address newStorage) private {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newStorage)
    }
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "Governable: New storage shouldn't be empty");
    _setStorage(_store);
  }

  function _storage() internal view returns (address str) {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function governance() public view returns (address) {
    return Storage(_storage()).governance();
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

/*
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
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Storage {

  address public governance;
  address public controller;

  constructor() {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Storage: Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "Storage: New governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "Storage: New controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}