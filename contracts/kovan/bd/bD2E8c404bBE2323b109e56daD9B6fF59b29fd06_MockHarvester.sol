//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../base/KeeperCompatibleHarvester.sol";

contract MockHarvester is KeeperCompatibleHarvester {
    uint256 public vaultCount = 1;
    bool public canHarvest = true;
    bool public shouldHarvest = true;
    bool public didHarvest = true;

    constructor(
        address _keeperRegistry,
        uint256 _performUpkeepGasLimit,
        uint256 _performUpkeepGasLimitBuffer,
        uint256 _vaultHarvestFunctionGasOverhead,
        uint256 _keeperRegistryGasOverhead
    )
        KeeperCompatibleHarvester(
            _keeperRegistry,
            _performUpkeepGasLimit,
            _performUpkeepGasLimitBuffer,
            _vaultHarvestFunctionGasOverhead,
            _keeperRegistryGasOverhead
        )
    {}

    function _getVaultAddresses()
        internal
        view
        override
        returns (address[] memory result)
    {
        result = new address[](vaultCount);
    }

    function _canHarvestVault(address) internal view override returns (bool) {
        return canHarvest;
    }

    function _shouldHarvestVault(address)
        internal
        view
        override
        returns (
            bool shouldHarvestVault,
            uint256 txCostWithPremium,
            uint256 callRewardAmount
        )
    {
        return (shouldHarvest, 0, 0);
    }

    function _getVaultHarvestGasOverhead(address)
        internal
        view
        override
        returns (uint256)
    {
        return
            _estimateSingleVaultHarvestGasOverhead(
                vaultHarvestFunctionGasOverhead
            );
    }

    function _harvestVault(address)
        internal
        view
        override
        returns (bool, uint256)
    {
        return (didHarvest, 0);
    }

    function setVaultCount(uint256 newVaultCount) public {
        vaultCount = newVaultCount;
    }

    function setCanHarvestVault(bool _canHarvest) public {
        canHarvest = _canHarvest;
    }

    function setShouldHarvestVault(bool _shouldHarvest) public {
        shouldHarvest = _shouldHarvest;
    }

    function setHarvestVault(bool _didHarvest) public {
        didHarvest = _didHarvest;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/UpkeepLibrary.sol";
import "../interfaces/IKeeperRegistry.sol";
import "../interfaces/IHarvester.sol";

abstract contract KeeperCompatibleHarvester is IHarvester, Ownable {
    using SafeERC20 for IERC20;

    // Contracts.
    IKeeperRegistry public keeperRegistry;

    // Configuration state variables.
    uint256 public performUpkeepGasLimit;
    uint256 public performUpkeepGasLimitBuffer;
    uint256 public vaultHarvestFunctionGasOverhead; // Estimated average gas cost of calling harvest()
    uint256 public keeperRegistryGasOverhead; // Gas cost of upstream contract that calls performUpkeep(). This is a private variable on KeeperRegistry.
    uint256 public chainlinkUpkeepTxPremiumFactor; // Tx premium factor/multiplier scaled by 1 gwei (10**9).
    address public callFeeRecipient;

    // State variables that will change across upkeeps.
    uint256 public startIndex;

    constructor(
        address _keeperRegistry,
        uint256 _performUpkeepGasLimit,
        uint256 _performUpkeepGasLimitBuffer,
        uint256 _vaultHarvestFunctionGasOverhead,
        uint256 _keeperRegistryGasOverhead
    ) {
        // Set contract references.
        keeperRegistry = IKeeperRegistry(_keeperRegistry);

        // Initialize state variables from initialize() arguments.
        performUpkeepGasLimit = _performUpkeepGasLimit;
        performUpkeepGasLimitBuffer = _performUpkeepGasLimitBuffer;
        vaultHarvestFunctionGasOverhead = _vaultHarvestFunctionGasOverhead;
        keeperRegistryGasOverhead = _keeperRegistryGasOverhead;

        // Initialize state variables derived from initialize() arguments.
        (uint32 paymentPremiumPPB, , , , , , ) = keeperRegistry.getConfig();
        chainlinkUpkeepTxPremiumFactor = uint256(paymentPremiumPPB);
    }

    /*             */
    /* checkUpkeep */
    /*             */

    function checkUpkeep(
        bytes calldata _checkData // unused
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory performData // array of vaults +
        )
    {
        _checkData; // dummy reference to get rid of unused parameter warning

        // get vaults to iterate over
        address[] memory vaults = _getVaultAddresses();

        // count vaults to harvest that will fit within gas limit
        (
            HarvestInfo[] memory harvestInfo,
            uint256 numberOfVaultsToHarvest,
            uint256 newStartIndex
        ) = _countVaultsToHarvest(vaults);
        if (numberOfVaultsToHarvest == 0)
            return (false, bytes("No vaults to harvest"));

        (
            address[] memory vaultsToHarvest,
            uint256 heuristicEstimatedTxCost,
            uint256 callRewards
        ) = _buildVaultsToHarvest(vaults, harvestInfo, numberOfVaultsToHarvest);

        uint256 nonHeuristicEstimatedTxCost = _calculateExpectedTotalUpkeepTxCost(
                numberOfVaultsToHarvest
            );

        performData = abi.encode(
            vaultsToHarvest,
            newStartIndex,
            heuristicEstimatedTxCost,
            nonHeuristicEstimatedTxCost,
            callRewards
        );

        return (true, performData);
    }

    function _buildVaultsToHarvest(
        address[] memory _vaults,
        HarvestInfo[] memory _willHarvestVaults,
        uint256 _numberOfVaultsToHarvest
    )
        internal
        view
        returns (
            address[] memory vaultsToHarvest,
            uint256 heuristicEstimatedTxCost,
            uint256 totalCallRewards
        )
    {
        uint256 vaultPositionInArray;
        vaultsToHarvest = new address[](_numberOfVaultsToHarvest);

        // create array of vaults to harvest. Could reduce code duplication from _countVaultsToHarvest via a another function parameter called _loopPostProcess
        for (uint256 offset; offset < _vaults.length; ++offset) {
            uint256 vaultIndexToCheck = UpkeepLibrary._getCircularIndex(
                startIndex,
                offset,
                _vaults.length
            );
            address vaultAddress = _vaults[vaultIndexToCheck];

            HarvestInfo memory harvestInfo = _willHarvestVaults[offset];

            if (harvestInfo.willHarvest) {
                vaultsToHarvest[vaultPositionInArray] = vaultAddress;
                heuristicEstimatedTxCost += harvestInfo.estimatedTxCost;
                totalCallRewards += harvestInfo.callRewardsAmount;
                vaultPositionInArray += 1;
            }

            // no need to keep going if we're past last index
            if (vaultPositionInArray == _numberOfVaultsToHarvest) break;
        }

        return (vaultsToHarvest, heuristicEstimatedTxCost, totalCallRewards);
    }

    function _countVaultsToHarvest(address[] memory _vaults)
        internal
        view
        returns (
            HarvestInfo[] memory harvestInfo,
            uint256 numberOfVaultsToHarvest,
            uint256 newStartIndex
        )
    {
        uint256 gasLeft = _calculateAdjustedGasCap();
        uint256 vaultIndexToCheck; // hoisted up to be able to set newStartIndex
        harvestInfo = new HarvestInfo[](_vaults.length);

        // count the number of vaults to harvest.
        for (uint256 offset; offset < _vaults.length; ++offset) {
            // _startIndex is where to start in the _vaultRegistry array, offset is position from start index (in other words, number of vaults we've checked so far),
            // then modulo to wrap around to the start of the array, until we've checked all vaults, or break early due to hitting gas limit
            // this logic is contained in _getCircularIndex()
            vaultIndexToCheck = UpkeepLibrary._getCircularIndex(
                startIndex,
                offset,
                _vaults.length
            );
            address vaultAddress = _vaults[vaultIndexToCheck];

            (
                bool willHarvest,
                uint256 estimatedTxCost,
                uint256 callRewardsAmount
            ) = _willHarvestVault(vaultAddress);

            if (willHarvest && gasLeft >= vaultHarvestFunctionGasOverhead) {
                gasLeft -= vaultHarvestFunctionGasOverhead;
                numberOfVaultsToHarvest += 1;
                harvestInfo[offset] = HarvestInfo(
                    true,
                    estimatedTxCost,
                    callRewardsAmount
                );
            }

            if (gasLeft < vaultHarvestFunctionGasOverhead) {
                break;
            }
        }

        newStartIndex = UpkeepLibrary._getCircularIndex(
            vaultIndexToCheck,
            1,
            _vaults.length
        );

        return (harvestInfo, numberOfVaultsToHarvest, newStartIndex);
    }

    function _willHarvestVault(address _vaultAddress)
        internal
        view
        returns (
            bool willHarvestVault,
            uint256,
            uint256
        )
    {
        (
            bool shouldHarvestVault,
            uint256 estimatedTxCost,
            uint256 callRewardAmount
        ) = _shouldHarvestVault(_vaultAddress);
        bool canHarvestVault = _canHarvestVault(_vaultAddress);

        willHarvestVault = canHarvestVault && shouldHarvestVault;

        return (willHarvestVault, estimatedTxCost, callRewardAmount);
    }

    function _canHarvestVault(address _vaultAddress)
        internal
        view
        virtual
        returns (bool canHarvest);

    function _shouldHarvestVault(address _vaultAddress)
        internal
        view
        virtual
        returns (
            bool shouldHarvestVault,
            uint256 txCostWithPremium,
            uint256 callRewardAmount
        );

    /*               */
    /* performUpkeep */
    /*               */

    function performUpkeep(bytes calldata _performData) external override {
        (
            address[] memory vaultsToHarvest,
            uint256 newStartIndex,
            uint256 heuristicEstimatedTxCost,
            uint256 nonHeuristicEstimatedTxCost,
            uint256 estimatedCallRewards
        ) = abi.decode(
                _performData,
                (address[], uint256, uint256, uint256, uint256)
            );

        _runUpkeep(
            vaultsToHarvest,
            newStartIndex,
            heuristicEstimatedTxCost,
            nonHeuristicEstimatedTxCost,
            estimatedCallRewards
        );
    }

    function _runUpkeep(
        address[] memory _vaults,
        uint256 _newStartIndex,
        uint256 _heuristicEstimatedTxCost,
        uint256 _nonHeuristicEstimatedTxCost,
        uint256 _estimatedCallRewards
    ) internal {
        // Make sure estimate looks good.
        if (_estimatedCallRewards < _nonHeuristicEstimatedTxCost) {
            emit HeuristicFailed(
                block.number,
                _heuristicEstimatedTxCost,
                _nonHeuristicEstimatedTxCost,
                _estimatedCallRewards
            );
        }

        uint256 gasBefore = gasleft();
        // multi harvest
        require(_vaults.length > 0, "No vaults to harvest");
        (
            uint256 numberOfSuccessfulHarvests,
            uint256 numberOfFailedHarvests,
            uint256 calculatedCallRewards
        ) = _multiHarvest(_vaults);

        // ensure _newStartIndex is valid and set startIndex
        uint256 vaultCount = _getVaultAddresses().length;
        require(
            _newStartIndex >= 0 && _newStartIndex < vaultCount,
            "_newStartIndex out of range."
        );
        startIndex = _newStartIndex;

        uint256 gasAfter = gasleft();
        uint256 gasUsedByPerformUpkeep = gasBefore - gasAfter;

        // split these into their own functions to avoid `Stack too deep`
        _reportProfitSummary(
            gasUsedByPerformUpkeep,
            _nonHeuristicEstimatedTxCost,
            _estimatedCallRewards,
            calculatedCallRewards
        );
        _reportHarvestSummary(
            _newStartIndex,
            gasUsedByPerformUpkeep,
            numberOfSuccessfulHarvests,
            numberOfFailedHarvests
        );
    }

    function _reportHarvestSummary(
        uint256 _newStartIndex,
        uint256 _gasUsedByPerformUpkeep,
        uint256 _numberOfSuccessfulHarvests,
        uint256 _numberOfFailedHarvests
    ) internal {
        emit HarvestSummary(
            block.number,
            // state variables
            startIndex,
            _newStartIndex,
            // gas metrics
            tx.gasprice,
            _gasUsedByPerformUpkeep,
            // summary metrics
            _numberOfSuccessfulHarvests,
            _numberOfFailedHarvests
        );
    }

    function _reportProfitSummary(
        uint256 _gasUsedByPerformUpkeep,
        uint256 _nonHeuristicEstimatedTxCost,
        uint256 _estimatedCallRewards,
        uint256 _calculatedCallRewards
    ) internal {
        uint256 estimatedTxCost = _nonHeuristicEstimatedTxCost; // use nonHeuristic here as its more accurate
        uint256 estimatedProfit = UpkeepLibrary._calculateProfit(
            _estimatedCallRewards,
            estimatedTxCost
        );

        uint256 calculatedTxCost = _calculateTxCostWithOverheadWithPremium(
            _gasUsedByPerformUpkeep
        );
        uint256 calculatedProfit = UpkeepLibrary._calculateProfit(
            _calculatedCallRewards,
            calculatedTxCost
        );

        emit ProfitSummary(
            // predicted values
            estimatedTxCost,
            _estimatedCallRewards,
            estimatedProfit,
            // calculated values
            calculatedTxCost,
            _calculatedCallRewards,
            calculatedProfit
        );
    }

    function _multiHarvest(address[] memory _vaults)
        internal
        returns (
            uint256 numberOfSuccessfulHarvests,
            uint256 numberOfFailedHarvests,
            uint256 cumulativeCallRewards
        )
    {
        bool[] memory isSuccessfulHarvest = new bool[](_vaults.length);
        for (uint256 i = 0; i < _vaults.length; ++i) {
            (bool didHarvest, uint256 callRewards) = _harvestVault(_vaults[i]);
            // Add rewards to cumulative tracker.
            if (didHarvest) {
                isSuccessfulHarvest[i] = true;
                cumulativeCallRewards += callRewards;
            }
        }

        (
            address[] memory successfulHarvests,
            address[] memory failedHarvests
        ) = _getSuccessfulAndFailedVaults(_vaults, isSuccessfulHarvest);

        emit SuccessfulHarvests(block.number, successfulHarvests);
        emit FailedHarvests(block.number, failedHarvests);

        numberOfSuccessfulHarvests = successfulHarvests.length;
        numberOfFailedHarvests = failedHarvests.length;
        return (
            numberOfSuccessfulHarvests,
            numberOfFailedHarvests,
            cumulativeCallRewards
        );
    }

    function _harvestVault(address _vault)
        internal
        virtual
        returns (bool didHarvest, uint256 callRewards);

    function _getSuccessfulAndFailedVaults(
        address[] memory _vaults,
        bool[] memory _isSuccessfulHarvest
    )
        internal
        pure
        returns (
            address[] memory successfulHarvests,
            address[] memory failedHarvests
        )
    {
        uint256 successfulCount;
        for (uint256 i = 0; i < _vaults.length; i++) {
            if (_isSuccessfulHarvest[i]) {
                successfulCount += 1;
            }
        }

        successfulHarvests = new address[](successfulCount);
        failedHarvests = new address[](_vaults.length - successfulCount);
        uint256 successfulHarvestsIndex;
        uint256 failedHarvestIndex;
        for (uint256 i = 0; i < _vaults.length; i++) {
            if (_isSuccessfulHarvest[i]) {
                successfulHarvests[successfulHarvestsIndex++] = _vaults[i];
            } else {
                failedHarvests[failedHarvestIndex++] = _vaults[i];
            }
        }

        return (successfulHarvests, failedHarvests);
    }

    /*     */
    /* Set */
    /*     */

    function setPerformUpkeepGasLimit(uint256 _performUpkeepGasLimit)
        external
        override
        onlyOwner
    {
        performUpkeepGasLimit = _performUpkeepGasLimit;
    }

    function setPerformUpkeepGasLimitBuffer(
        uint256 _performUpkeepGasLimitBuffer
    ) external override onlyOwner {
        performUpkeepGasLimitBuffer = _performUpkeepGasLimitBuffer;
    }

    function setHarvestGasConsumption(uint256 _harvestGasConsumption)
        external
        override
        onlyOwner
    {
        vaultHarvestFunctionGasOverhead = _harvestGasConsumption;
    }

    /*      */
    /* View */
    /*      */

    function _getVaultAddresses()
        internal
        view
        virtual
        returns (address[] memory);

    function _getVaultHarvestGasOverhead(address _vault)
        internal
        view
        virtual
        returns (uint256);

    function _calculateAdjustedGasCap()
        internal
        view
        returns (uint256 adjustedPerformUpkeepGasLimit)
    {
        return performUpkeepGasLimit - performUpkeepGasLimitBuffer;
    }

    function _calculateTxCostWithPremium(uint256 _gasOverhead)
        internal
        view
        returns (uint256 txCost)
    {
        return
            UpkeepLibrary._calculateUpkeepTxCost(
                tx.gasprice,
                _gasOverhead,
                chainlinkUpkeepTxPremiumFactor
            );
    }

    function _calculateTxCostWithOverheadWithPremium(
        uint256 _totalVaultHarvestOverhead
    ) internal view returns (uint256 txCost) {
        return
            UpkeepLibrary._calculateUpkeepTxCostFromTotalVaultHarvestOverhead(
                tx.gasprice,
                _totalVaultHarvestOverhead,
                keeperRegistryGasOverhead,
                chainlinkUpkeepTxPremiumFactor
            );
    }

    function _calculateExpectedTotalUpkeepTxCost(
        uint256 _numberOfVaultsToHarvest
    ) internal view returns (uint256 txCost) {
        uint256 totalVaultHarvestGasOverhead = vaultHarvestFunctionGasOverhead *
            _numberOfVaultsToHarvest;
        return
            UpkeepLibrary._calculateUpkeepTxCostFromTotalVaultHarvestOverhead(
                tx.gasprice,
                totalVaultHarvestGasOverhead,
                keeperRegistryGasOverhead,
                chainlinkUpkeepTxPremiumFactor
            );
    }

    function _estimateSingleVaultHarvestGasOverhead(
        uint256 _vaultHarvestFunctionGasOverhead
    ) internal view returns (uint256 totalGasOverhead) {
        totalGasOverhead =
            _vaultHarvestFunctionGasOverhead +
            keeperRegistryGasOverhead;
    }

    /*      */
    /* Misc */
    /*      */

    /**
     * @dev Rescues random funds stuck.
     * @param _token address of the token to rescue.
     */
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);

        uint256 amount = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, amount);
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

library UpkeepLibrary {
    uint256 public constant CHAINLINK_UPKEEPTX_PREMIUM_SCALING_FACTOR = 1 gwei;

    /**
     * @dev Rescues random funds stuck.
     */
    function _getCircularIndex(
        uint256 _index,
        uint256 _offset,
        uint256 _bufferLength
    ) internal pure returns (uint256 circularIndex) {
        circularIndex = (_index + _offset) % _bufferLength;
    }

    function _calculateUpkeepTxCost(
        uint256 _gasprice,
        uint256 _gasOverhead,
        uint256 _chainlinkUpkeepTxPremiumFactor
    ) internal pure returns (uint256 _upkeepTxCost) {
        _upkeepTxCost =
            (_gasprice * _gasOverhead * _chainlinkUpkeepTxPremiumFactor) /
            CHAINLINK_UPKEEPTX_PREMIUM_SCALING_FACTOR;
    }

    function _calculateUpkeepTxCostFromTotalVaultHarvestOverhead(
        uint256 _gasprice,
        uint256 _totalVaultHarvestOverhead,
        uint256 _keeperRegistryOverhead,
        uint256 _chainlinkUpkeepTxPremiumFactor
    ) internal pure returns (uint256 upkeepTxCost) {
        uint256 totalOverhead = _totalVaultHarvestOverhead +
            _keeperRegistryOverhead;

        upkeepTxCost = _calculateUpkeepTxCost(
            _gasprice,
            totalOverhead,
            _chainlinkUpkeepTxPremiumFactor
        );
    }

    function _calculateProfit(uint256 _revenue, uint256 _expenses)
        internal
        pure
        returns (uint256 profit)
    {
        profit = _revenue >= _expenses ? _revenue - _expenses : 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKeeperRegistry {
    event ConfigSet(
        uint32 paymentPremiumPPB,
        uint24 blockCountPerTurn,
        uint32 checkGasLimit,
        uint24 stalenessSeconds,
        uint16 gasCeilingMultiplier,
        uint256 fallbackGasPrice,
        uint256 fallbackLinkPrice
    );
    event FlatFeeSet(uint32 flatFeeMicroLink);
    event FundsAdded(uint256 indexed id, address indexed from, uint96 amount);
    event FundsWithdrawn(uint256 indexed id, uint256 amount, address to);
    event KeepersUpdated(address[] keepers, address[] payees);
    event OwnershipTransferRequested(address indexed from, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);
    event Paused(address account);
    event PayeeshipTransferRequested(
        address indexed keeper,
        address indexed from,
        address indexed to
    );
    event PayeeshipTransferred(
        address indexed keeper,
        address indexed from,
        address indexed to
    );
    event PaymentWithdrawn(
        address indexed keeper,
        uint256 indexed amount,
        address indexed to,
        address payee
    );
    event RegistrarChanged(address indexed from, address indexed to);
    event Unpaused(address account);
    event UpkeepCanceled(uint256 indexed id, uint64 indexed atBlockHeight);
    event UpkeepPerformed(
        uint256 indexed id,
        bool indexed success,
        address indexed from,
        uint96 payment,
        bytes performData
    );
    event UpkeepRegistered(
        uint256 indexed id,
        uint32 executeGas,
        address admin
    );

    function FAST_GAS_FEED() external view returns (address);

    function LINK() external view returns (address);

    function LINK_ETH_FEED() external view returns (address);

    function acceptOwnership() external;

    function acceptPayeeship(address keeper) external;

    function addFunds(uint256 id, uint96 amount) external;

    function cancelUpkeep(uint256 id) external;

    function checkUpkeep(uint256 id, address from)
        external
        returns (
            bytes memory performData,
            uint256 maxLinkPayment,
            uint256 gasLimit,
            uint256 adjustedGasWei,
            uint256 linkEth
        );

    function getCanceledUpkeepList() external view returns (uint256[] memory);

    function getConfig()
        external
        view
        returns (
            uint32 paymentPremiumPPB,
            uint24 blockCountPerTurn,
            uint32 checkGasLimit,
            uint24 stalenessSeconds,
            uint16 gasCeilingMultiplier,
            uint256 fallbackGasPrice,
            uint256 fallbackLinkPrice
        );

    function getFlatFee() external view returns (uint32);

    function getKeeperInfo(address query)
        external
        view
        returns (
            address payee,
            bool active,
            uint96 balance
        );

    function getKeeperList() external view returns (address[] memory);

    function getMaxPaymentForGas(uint256 gasLimit)
        external
        view
        returns (uint96 maxPayment);

    function getMinBalanceForUpkeep(uint256 id)
        external
        view
        returns (uint96 minBalance);

    function getRegistrar() external view returns (address);

    function getUpkeep(uint256 id)
        external
        view
        returns (
            address target,
            uint32 executeGas,
            bytes memory checkData,
            uint96 balance,
            address lastKeeper,
            address admin,
            uint64 maxValidBlocknumber
        );

    function getUpkeepCount() external view returns (uint256);

    function onTokenTransfer(
        address sender,
        uint256 amount,
        bytes memory data
    ) external;

    function owner() external view returns (address);

    function pause() external;

    function paused() external view returns (bool);

    function performUpkeep(uint256 id, bytes memory performData)
        external
        returns (bool success);

    function recoverFunds() external;

    function registerUpkeep(
        address target,
        uint32 gasLimit,
        address admin,
        bytes memory checkData
    ) external returns (uint256 id);

    function setConfig(
        uint32 paymentPremiumPPB,
        uint32 flatFeeMicroLink,
        uint24 blockCountPerTurn,
        uint32 checkGasLimit,
        uint24 stalenessSeconds,
        uint16 gasCeilingMultiplier,
        uint256 fallbackGasPrice,
        uint256 fallbackLinkPrice
    ) external;

    function setKeepers(address[] memory keepers, address[] memory payees)
        external;

    function setRegistrar(address registrar) external;

    function transferOwnership(address to) external;

    function transferPayeeship(address keeper, address proposed) external;

    function typeAndVersion() external view returns (string memory);

    function unpause() external;

    function withdrawFunds(uint256 id, address to) external;

    function withdrawPayment(address from, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

interface IHarvester is KeeperCompatibleInterface {
    struct HarvestInfo {
        bool willHarvest;
        uint256 estimatedTxCost;
        uint256 callRewardsAmount;
    }

    event HarvestSummary(
        uint256 indexed blockNumber,
        uint256 oldStartIndex,
        uint256 newStartIndex,
        uint256 gasPrice,
        uint256 gasUsedByPerformUpkeep,
        uint256 numberOfSuccessfulHarvests,
        uint256 numberOfFailedHarvests
    );
    event HeuristicFailed(
        uint256 indexed blockNumber,
        uint256 heuristicEstimatedTxCost,
        uint256 nonHeuristicEstimatedTxCost,
        uint256 estimatedCallRewards
    );
    event ProfitSummary(
        uint256 estimatedTxCost,
        uint256 estimatedCallRewards,
        uint256 estimatedProfit,
        uint256 calculatedTxCost,
        uint256 calculatedCallRewards,
        uint256 calculatedProfit
    );
    event SuccessfulHarvests(
        uint256 indexed blockNumber,
        address[] successfulVaults
    );
    event FailedHarvests(uint256 indexed blockNumber, address[] failedVaults);

    function setHarvestGasConsumption(uint256 harvestGasConsumption) external;

    function setPerformUpkeepGasLimit(uint256 performUpkeepGasLimit) external;

    function setPerformUpkeepGasLimitBuffer(
        uint256 performUpkeepGasLimitBuffer
    ) external;
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
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}