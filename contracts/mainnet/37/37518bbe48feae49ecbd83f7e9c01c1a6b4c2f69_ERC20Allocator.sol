pragma solidity =0.8.13;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Timed} from "./../../utils/Timed.sol";
import {CoreRef} from "./../../refs/CoreRef.sol";
import {PCVDeposit} from "./../PCVDeposit.sol";
import {RateLimitedV2} from "./../../utils/RateLimitedV2.sol";
import {IERC20Allocator} from "./IERC20Allocator.sol";

/// @notice Contract to remove all excess funds past a target balance from a smart contract
/// and to add funds to that same smart contract when it is under the target balance.
/// First application is allocating funds from a PSM to a yield venue so that liquid reserves are minimized.
/// This contract should never hold PCV, however it has a sweep function, so if tokens get sent to it accidentally,
/// they can still be recovered.

/// This contract stores each PSM and maps it to the target balance and decimals normalizer for that token
/// PCV Deposits can then be linked to these PSM's which allows funds to be pushed and pulled
/// between these PCV deposits and their respective PSM's.
/// This design allows multiple PCV Deposits to be linked to a single PSM.

/// This contract enforces the assumption that all pcv deposits connected to a given PSM share
/// the same underlying token, otherwise the rate limited logic will not work as intended.
/// This assumption is encoded in the create and edit deposit functions as well as the
/// connect deposit function.

/// @author Elliot Friedman
contract ERC20Allocator is IERC20Allocator, CoreRef, RateLimitedV2 {
    using Address for address payable;
    using SafeERC20 for IERC20;
    using SafeCast for *;

    /// @notice container that stores information on all psm's and their respective deposits
    struct PSMInfo {
        /// @notice target token address to send
        address token;
        /// @notice only skim if balance of target is greater than targetBalance
        /// only drip if balance of target is less than targetBalance
        uint248 targetBalance;
        /// @notice decimal normalizer to ensure buffer is updated uniformly across all deposits
        int8 decimalsNormalizer;
    }

    /// @notice map the psm address to the corresponding target balance information
    /// excess tokens past target balance will be pulled from the PSM
    /// if PSM has less than the target balance, tokens will be sent to the PSM
    mapping(address => PSMInfo) public allPSMs;

    /// @notice map the pcv deposit address to a peg stability module
    mapping(address => address) public pcvDepositToPSM;

    /// @notice ERC20 Allocator constructor
    /// @param _core Volt Core for reference
    /// @param _maxRateLimitPerSecond maximum rate limit per second that governance can set
    /// @param _rateLimitPerSecond starting rate limit per second
    /// @param _bufferCap cap on buffer size for this rate limited instance
    constructor(
        address _core,
        uint256 _maxRateLimitPerSecond,
        uint128 _rateLimitPerSecond,
        uint128 _bufferCap
    )
        CoreRef(_core)
        RateLimitedV2(_maxRateLimitPerSecond, _rateLimitPerSecond, _bufferCap)
    {}

    /// ----------- Governor Only API -----------

    /// @notice connect a new PSM
    /// @param psm Peg Stability Module to add
    /// @param targetBalance target amount of tokens for the PSM to hold
    /// @param decimalsNormalizer decimal normalizer to ensure buffer is depleted and replenished properly
    function connectPSM(
        address psm,
        uint248 targetBalance,
        int8 decimalsNormalizer
    ) external override onlyGovernor {
        address token = PCVDeposit(psm).balanceReportedIn();

        require(
            allPSMs[psm].token == address(0),
            "ERC20Allocator: cannot overwrite existing deposit"
        );

        PSMInfo memory newPSM = PSMInfo({
            token: token,
            targetBalance: targetBalance,
            decimalsNormalizer: decimalsNormalizer
        });
        allPSMs[psm] = newPSM;

        emit PSMConnected(psm, token, targetBalance, decimalsNormalizer);
    }

    /// @notice edit an existing PSM
    /// @param psm Peg Stability Module for this deposit
    /// @param targetBalance target amount of tokens for the PSM to hold
    /// cannot manually change the underlying token, as this is pulled from the PSM
    /// underlying token is immutable in both pcv deposit and
    function editPSMTargetBalance(address psm, uint248 targetBalance)
        external
        override
        onlyGovernor
    {
        address token = PCVDeposit(psm).balanceReportedIn();
        address storedToken = allPSMs[psm].token;
        require(
            storedToken != address(0),
            "ERC20Allocator: cannot edit non-existent deposit"
        );
        require(token == storedToken, "ERC20Allocator: psm changed underlying");

        PSMInfo storage psmToEdit = allPSMs[psm];
        psmToEdit.targetBalance = targetBalance;

        emit PSMTargetBalanceUpdated(psm, targetBalance);
    }

    /// @notice disconnect an existing deposit from the allocator
    /// @param psm Peg Stability Module to remove from allocation
    function disconnectPSM(address psm) external override onlyGovernor {
        delete allPSMs[psm];

        emit PSMDeleted(psm);
    }

    /// @notice function to connect deposit to a PSM
    /// this then allows the pulling of funds between the deposit and the PSM permissionlessly
    /// as defined by the target balance set in allPSM's
    /// this function does not check if the pcvDepositToPSM has already been connected
    /// as only the governor can call and create, and overwriting with the same data (no op) is fine
    /// @param psm peg stability module
    /// @param pcvDeposit deposit to connect to psm
    function connectDeposit(address psm, address pcvDeposit)
        external
        override
        onlyGovernor
    {
        address pcvToken = allPSMs[psm].token;

        /// assert pcv deposit and psm share same denomination
        require(
            PCVDeposit(pcvDeposit).balanceReportedIn() == pcvToken,
            "ERC20Allocator: token mismatch"
        );
        require(pcvToken != address(0), "ERC20Allocator: invalid underlying");

        pcvDepositToPSM[pcvDeposit] = psm;

        emit DepositConnected(psm, pcvDeposit);
    }

    /// @notice delete an existing deposit
    /// @param pcvDeposit PCV Deposit to remove connection to PSM
    function deleteDeposit(address pcvDeposit) external override onlyGovernor {
        delete pcvDepositToPSM[pcvDeposit];

        emit DepositDeleted(pcvDeposit);
    }

    /// @notice sweep target token, this shouldn't ever be needed as this contract
    /// does not hold tokens
    /// @param token to sweep
    /// @param to recipient
    /// @param amount of token to be sent
    function sweep(
        address token,
        address to,
        uint256 amount
    ) external onlyGovernor {
        IERC20(token).safeTransfer(to, amount);
    }

    /// ----------- Permissionless PCV Allocation APIs -----------

    /// @notice pull ERC20 tokens from PSM and send to PCV Deposit
    /// if the amount of tokens held in the PSM is above
    /// the target balance.
    /// @param pcvDeposit deposit to send excess funds to
    function skim(address pcvDeposit) external whenNotPaused {
        address psm = pcvDepositToPSM[pcvDeposit];
        require(psm != address(0), "ERC20Allocator: invalid PCVDeposit");

        _skim(psm, pcvDeposit);
    }

    /// helper function that does the skimming
    /// @param psm peg stability module to skim funds from
    /// @param pcvDeposit pcv deposit to send funds to
    function _skim(address psm, address pcvDeposit) internal {
        /// Check

        /// note this check is redundant, as calculating amountToPull will revert
        /// if pullThreshold is greater than the current balance of psm
        /// however, we like to err on the side of verbosity
        require(
            _checkSkimCondition(psm),
            "ERC20Allocator: skim condition not met"
        );

        (uint256 amountToSkim, uint256 adjustedAmountToSkim) = getSkimDetails(
            pcvDeposit
        );

        /// Effects

        _replenishBuffer(adjustedAmountToSkim);

        /// Interactions

        /// pull funds from pull target and send to push target
        /// automatically pulls underlying token
        PCVDeposit(psm).withdraw(pcvDeposit, amountToSkim);

        /// deposit pulled funds into the selected yield venue
        PCVDeposit(pcvDeposit).deposit();

        emit Skimmed(amountToSkim, pcvDeposit);
    }

    /// @notice push ERC20 tokens to PSM by pulling from a PCV deposit
    /// flow of funds: PCV Deposit -> PSM
    /// @param pcvDeposit to pull funds from and send to corresponding PSM
    function drip(address pcvDeposit) external whenNotPaused {
        address psm = pcvDepositToPSM[pcvDeposit];
        require(psm != address(0), "ERC20Allocator: invalid PCVDeposit");

        _drip(psm, PCVDeposit(pcvDeposit));
    }

    /// helper function that does the dripping
    /// @param psm peg stability module to drip to
    /// @param pcvDeposit pcv deposit to pull funds from
    function _drip(address psm, PCVDeposit pcvDeposit) internal {
        /// Check
        require(
            _checkDripCondition(psm, pcvDeposit),
            "ERC20Allocator: drip condition not met"
        );

        (uint256 amountToDrip, uint256 adjustedAmountToDrip) = getDripDetails(
            psm,
            pcvDeposit
        );

        /// Effects

        /// deplete buffer with adjusted amount so that it gets
        /// depleted uniformly across all assets and deposits
        _depleteBuffer(adjustedAmountToDrip);

        /// Interaction

        /// drip amount to pcvDeposit psm so that it has targetBalance amount of tokens
        pcvDeposit.withdraw(psm, amountToDrip);
        emit Dripped(amountToDrip, psm);
    }

    /// @notice does an action if any are available
    /// @param pcvDeposit whose corresponding peg stability module action will be run on
    function doAction(address pcvDeposit) external whenNotPaused {
        address psm = pcvDepositToPSM[pcvDeposit];
        require(psm != address(0), "ERC20Allocator: invalid PCVDeposit");

        /// don't check buffer != 0 as that will happen in drip function on effects
        if (_checkDripCondition(psm, PCVDeposit(pcvDeposit))) {
            _drip(psm, PCVDeposit(pcvDeposit));
        } else if (_checkSkimCondition(psm)) {
            _skim(psm, pcvDeposit);
        }
    }

    /// ----------- PURE & VIEW Only APIs -----------

    /// @notice returns the target balance for a given PSM
    function targetBalance(address psm) external view returns (uint256) {
        return allPSMs[psm].targetBalance;
    }

    /// @notice function to get the adjusted amount out
    /// @param amountToDrip the amount to adjust
    /// @param decimalsNormalizer the amount of decimals to adjust amount by
    function getAdjustedAmount(uint256 amountToDrip, int8 decimalsNormalizer)
        public
        pure
        returns (uint256 adjustedAmountToDrip)
    {
        if (decimalsNormalizer == 0) {
            adjustedAmountToDrip = amountToDrip;
        } else if (decimalsNormalizer > 0) {
            uint256 scalingFactor = 10**decimalsNormalizer.toUint256();
            adjustedAmountToDrip = amountToDrip * scalingFactor;
        } else {
            uint256 scalingFactor = 10**(-1 * decimalsNormalizer).toUint256();
            adjustedAmountToDrip = amountToDrip / scalingFactor;
        }
    }

    /// @notice return the amount that can be skimmed off a given PSM
    /// @param pcvDeposit pcv deposit whose corresponding psm will have skim amount checked
    /// returns amount that can be skimmed, adjusted amount to skim and target to send proceeds
    /// reverts if not skim eligbile
    function getSkimDetails(address pcvDeposit)
        public
        view
        returns (uint256 amountToSkim, uint256 adjustedAmountToSkim)
    {
        address psm = pcvDepositToPSM[pcvDeposit];
        PSMInfo memory toSkim = allPSMs[psm];

        address token = toSkim.token;
        /// underflows when not skim eligble and reverts
        amountToSkim = IERC20(token).balanceOf(psm) - toSkim.targetBalance;

        /// adjust amount to skim based on the decimals normalizer to replenish buffer
        adjustedAmountToSkim = getAdjustedAmount(
            amountToSkim,
            toSkim.decimalsNormalizer
        );
    }

    /// @notice return the amount that can be dripped to a given PSM
    /// @param psm peg stability module to check drip amount on
    /// @param pcvDeposit pcv deposit to drip from
    /// returns amount that can be dripped, adjusted amount to drip and target
    /// reverts if not drip eligbile
    function getDripDetails(address psm, PCVDeposit pcvDeposit)
        public
        view
        returns (uint256 amountToDrip, uint256 adjustedAmountToDrip)
    {
        PSMInfo memory toDrip = allPSMs[psm];

        /// direct balanceOf call is cheaper than calling balance on psm
        /// underflows when not drip eligble and reverts
        uint256 targetBalanceDelta = toDrip.targetBalance -
            IERC20(toDrip.token).balanceOf(psm);

        /// drip min between target drip amount and pcv deposit being pulled from
        /// to prevent edge cases when a venue runs out of liquidity
        /// only drip the lowest between amount and the buffer,
        /// as dripping more than the buffer will result in a revert in the _drip function

        /// example: usdc deposits
        /// decimal normalizer = 12
        /// target balance delta = 10,000e6
        /// pcvDeposit.balance = 5,000e6
        /// buffer = 1,000e18

        /// getAdjustedAmount(1,000e18, -12) = 1,000e6

        /// amountToDrip = 1,000e6

        amountToDrip = Math.min(
            Math.min(targetBalanceDelta, pcvDeposit.balance()),
            /// adjust for decimals here as buffer is 1e18 scaled,
            /// and if token is not scaled by 1e18, then this amountToDrip could be over the buffer
            /// because buffer is 1e18 adjusted, and decimals normalizer is used to adjust up to the buffer
            /// need to invert decimals normalizer for this to work properly
            getAdjustedAmount(buffer(), toDrip.decimalsNormalizer * -1)
        );

        /// adjust amount to drip based on the decimals normalizer to deplete buffer
        adjustedAmountToDrip = getAdjustedAmount(
            amountToDrip,
            toDrip.decimalsNormalizer
        );
    }

    /// @notice function that returns whether the amount of tokens held
    /// are below the target and funds should flow from PCV Deposit -> PSM
    /// returns false when paused
    /// @param pcvDeposit pcv deposit whose corresponding peg stability module to check drip condition
    function checkDripCondition(address pcvDeposit)
        external
        view
        override
        returns (bool)
    {
        /// if paused or buffer empty, cannot drip
        if (paused() == true || buffer() == 0) {
            return false;
        }

        address psm = pcvDepositToPSM[pcvDeposit];
        return _checkDripCondition(psm, PCVDeposit(pcvDeposit));
    }

    /// @notice function that returns whether the amount of tokens held
    /// are above the target and funds should flow from PSM -> PCV Deposit
    /// returns false when paused
    function checkSkimCondition(address pcvDeposit)
        external
        view
        override
        returns (bool)
    {
        if (paused() == true) {
            return false;
        }

        address psm = pcvDepositToPSM[pcvDeposit];
        return _checkSkimCondition(psm);
    }

    /// @notice returns whether an action is allowed
    /// returns false when paused
    function checkActionAllowed(address pcvDeposit)
        external
        view
        override
        returns (bool)
    {
        /// if paused, no actions allowed
        if (paused() == true) {
            return false;
        }

        address psm = pcvDepositToPSM[pcvDeposit];
        /// cannot drip with an empty buffer
        return
            (buffer() != 0 &&
                _checkDripCondition(psm, PCVDeposit(pcvDeposit))) ||
            _checkSkimCondition(psm);
    }

    function _checkDripCondition(address psm, PCVDeposit pcvDeposit)
        internal
        view
        returns (bool)
    {
        /// direct balanceOf call is cheaper than calling balance on psm
        /// also cannot drip if balance in underlying venue is 0
        return
            IERC20(allPSMs[psm].token).balanceOf(psm) <
            allPSMs[psm].targetBalance &&
            pcvDeposit.balance() != 0;
    }

    function _checkSkimCondition(address psm) internal view returns (bool) {
        /// direct balanceOf call is cheaper than calling balance on psm
        return
            IERC20(allPSMs[psm].token).balanceOf(psm) >
            allPSMs[psm].targetBalance;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title an abstract contract for timed events
/// @author Fei Protocol
abstract contract Timed {
    /// @notice the start timestamp of the timed period
    uint256 public startTime;

    /// @notice the duration of the timed period
    uint256 public duration;

    event DurationUpdate(uint256 oldDuration, uint256 newDuration);

    event TimerReset(uint256 startTime);

    constructor(uint256 _duration) {
        _setDuration(_duration);
    }

    modifier duringTime() {
        require(isTimeStarted(), "Timed: time not started");
        require(!isTimeEnded(), "Timed: time ended");
        _;
    }

    modifier afterTime() {
        require(isTimeEnded(), "Timed: time not ended");
        _;
    }

    modifier afterTimeInit() {
        require(isTimeEnded(), "Timed: time not ended, init");
        _;
        _initTimed();
    }

    /// @notice return true if time period has ended
    function isTimeEnded() public view returns (bool) {
        return remainingTime() == 0;
    }

    /// @notice number of seconds remaining until time is up
    /// @return remaining
    function remainingTime() public view returns (uint256) {
        return duration - timeSinceStart(); // duration always >= timeSinceStart which is on [0,d]
    }

    /// @notice number of seconds since contract was initialized
    /// @return timestamp
    /// @dev will be less than or equal to duration
    function timeSinceStart() public view returns (uint256) {
        if (!isTimeStarted()) {
            return 0; // uninitialized
        }
        uint256 _duration = duration;
        uint256 timePassed = block.timestamp - startTime; // block timestamp always >= startTime
        return timePassed > _duration ? _duration : timePassed;
    }

    function isTimeStarted() public view returns (bool) {
        return startTime != 0;
    }

    function _initTimed() internal {
        startTime = block.timestamp;

        emit TimerReset(block.timestamp);
    }

    function _setDuration(uint256 newDuration) internal {
        require(newDuration != 0, "Timed: zero duration");

        uint256 oldDuration = duration;
        duration = newDuration;
        emit DurationUpdate(oldDuration, newDuration);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./ICoreRef.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title A Reference to Core
/// @author Fei Protocol
/// @notice defines some modifiers and utilities around interacting with Core
abstract contract CoreRef is ICoreRef, Pausable {
    ICore private immutable _core;
    IVolt private immutable _volt;
    IERC20 private immutable _vcon;

    /// @notice a role used with a subset of governor permissions for this contract only
    bytes32 public override CONTRACT_ADMIN_ROLE;

    constructor(address coreAddress) {
        _core = ICore(coreAddress);

        _volt = ICore(coreAddress).volt();
        _vcon = ICore(coreAddress).vcon();

        _setContractAdminRole(ICore(coreAddress).GOVERN_ROLE());
    }

    function _initialize() internal {} // no-op for backward compatibility

    modifier ifMinterSelf() {
        if (_core.isMinter(address(this))) {
            _;
        }
    }

    modifier onlyMinter() {
        require(_core.isMinter(msg.sender), "CoreRef: Caller is not a minter");
        _;
    }

    modifier onlyBurner() {
        require(_core.isBurner(msg.sender), "CoreRef: Caller is not a burner");
        _;
    }

    modifier onlyPCVController() {
        require(
            _core.isPCVController(msg.sender),
            "CoreRef: Caller is not a PCV controller"
        );
        _;
    }

    modifier onlyGovernorOrAdmin() {
        require(
            _core.isGovernor(msg.sender) || isContractAdmin(msg.sender),
            "CoreRef: Caller is not a governor or contract admin"
        );
        _;
    }

    modifier onlyGovernor() {
        require(
            _core.isGovernor(msg.sender),
            "CoreRef: Caller is not a governor"
        );
        _;
    }

    modifier onlyGuardianOrGovernor() {
        require(
            _core.isGovernor(msg.sender) || _core.isGuardian(msg.sender),
            "CoreRef: Caller is not a guardian or governor"
        );
        _;
    }

    modifier onlyGovernorOrGuardianOrAdmin() {
        require(
            _core.isGovernor(msg.sender) ||
                _core.isGuardian(msg.sender) ||
                isContractAdmin(msg.sender),
            "CoreRef: Caller is not governor or guardian or admin"
        );
        _;
    }

    // Named onlyTribeRole to prevent collision with OZ onlyRole modifier
    modifier onlyTribeRole(bytes32 role) {
        require(_core.hasRole(role, msg.sender), "UNAUTHORIZED");
        _;
    }

    // Modifiers to allow any combination of roles
    modifier hasAnyOfTwoRoles(bytes32 role1, bytes32 role2) {
        require(
            _core.hasRole(role1, msg.sender) ||
                _core.hasRole(role2, msg.sender),
            "UNAUTHORIZED"
        );
        _;
    }

    modifier hasAnyOfThreeRoles(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3
    ) {
        require(
            _core.hasRole(role1, msg.sender) ||
                _core.hasRole(role2, msg.sender) ||
                _core.hasRole(role3, msg.sender),
            "UNAUTHORIZED"
        );
        _;
    }

    modifier hasAnyOfFourRoles(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3,
        bytes32 role4
    ) {
        require(
            _core.hasRole(role1, msg.sender) ||
                _core.hasRole(role2, msg.sender) ||
                _core.hasRole(role3, msg.sender) ||
                _core.hasRole(role4, msg.sender),
            "UNAUTHORIZED"
        );
        _;
    }

    modifier hasAnyOfFiveRoles(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3,
        bytes32 role4,
        bytes32 role5
    ) {
        require(
            _core.hasRole(role1, msg.sender) ||
                _core.hasRole(role2, msg.sender) ||
                _core.hasRole(role3, msg.sender) ||
                _core.hasRole(role4, msg.sender) ||
                _core.hasRole(role5, msg.sender),
            "UNAUTHORIZED"
        );
        _;
    }

    modifier onlyVolt() {
        require(msg.sender == address(_volt), "CoreRef: Caller is not VOLT");
        _;
    }

    /// @notice sets a new admin role for this contract
    function setContractAdminRole(bytes32 newContractAdminRole)
        external
        override
        onlyGovernor
    {
        _setContractAdminRole(newContractAdminRole);
    }

    /// @notice returns whether a given address has the admin role for this contract
    function isContractAdmin(address _admin)
        public
        view
        override
        returns (bool)
    {
        return _core.hasRole(CONTRACT_ADMIN_ROLE, _admin);
    }

    /// @notice set pausable methods to paused
    function pause() public override onlyGuardianOrGovernor {
        _pause();
    }

    /// @notice set pausable methods to unpaused
    function unpause() public override onlyGuardianOrGovernor {
        _unpause();
    }

    /// @notice address of the Core contract referenced
    /// @return ICore implementation address
    function core() public view override returns (ICore) {
        return _core;
    }

    /// @notice address of the Fei contract referenced by Core
    /// @return IFei implementation address
    function volt() public view override returns (IVolt) {
        return _volt;
    }

    /// @notice address of the Tribe contract referenced by Core
    /// @return IERC20 implementation address
    function vcon() public view override returns (IERC20) {
        return _vcon;
    }

    /// @notice volt balance of contract
    /// @return volt amount held
    function voltBalance() public view override returns (uint256) {
        return _volt.balanceOf(address(this));
    }

    /// @notice vcon balance of contract
    /// @return vcon amount held
    function vconBalance() public view override returns (uint256) {
        return _vcon.balanceOf(address(this));
    }

    function _burnVoltHeld() internal {
        _volt.burn(voltBalance());
    }

    function _mintVolt(address to, uint256 amount) internal virtual {
        if (amount != 0) {
            _volt.mint(to, amount);
        }
    }

    function _setContractAdminRole(bytes32 newContractAdminRole) internal {
        bytes32 oldContractAdminRole = CONTRACT_ADMIN_ROLE;
        CONTRACT_ADMIN_ROLE = newContractAdminRole;
        emit ContractAdminRoleUpdate(
            oldContractAdminRole,
            newContractAdminRole
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../core/ICore.sol";

/// @title CoreRef interface
/// @author Fei Protocol
interface ICoreRef {
    // ----------- Events -----------

    event CoreUpdate(address indexed oldCore, address indexed newCore);

    event ContractAdminRoleUpdate(
        bytes32 indexed oldContractAdminRole,
        bytes32 indexed newContractAdminRole
    );

    // ----------- Governor only state changing api -----------

    function setContractAdminRole(bytes32 newContractAdminRole) external;

    // ----------- Governor or Guardian only state changing api -----------

    function pause() external;

    function unpause() external;

    // ----------- Getters -----------

    function core() external view returns (ICore);

    function volt() external view returns (IVolt);

    function vcon() external view returns (IERC20);

    function voltBalance() external view returns (uint256);

    function vconBalance() external view returns (uint256);

    function CONTRACT_ADMIN_ROLE() external view returns (bytes32);

    function isContractAdmin(address admin) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import {IPermissions} from "./IPermissions.sol";
import {IVolt, IERC20} from "../volt/IVolt.sol";

/// @title Core Interface
/// @author Fei Protocol
interface ICore is IPermissions {
    // ----------- Events -----------
    event VoltUpdate(IERC20 indexed _volt);
    event VconUpdate(IERC20 indexed _vcon);

    // ----------- Getters -----------

    function volt() external view returns (IVolt);

    function vcon() external view returns (IERC20);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IPermissionsRead.sol";

/// @title Permissions interface
/// @author Fei Protocol
interface IPermissions is IAccessControl, IPermissionsRead {
    // ----------- Governor only state changing api -----------

    function createRole(bytes32 role, bytes32 adminRole) external;

    function grantMinter(address minter) external;

    function grantBurner(address burner) external;

    function grantPCVController(address pcvController) external;

    function grantGovernor(address governor) external;

    function grantGuardian(address guardian) external;

    function revokeMinter(address minter) external;

    function revokeBurner(address burner) external;

    function revokePCVController(address pcvController) external;

    function revokeGovernor(address governor) external;

    function revokeGuardian(address guardian) external;

    // ----------- Revoker only state changing api -----------

    function revokeOverride(bytes32 role, address account) external;

    // ----------- Getters -----------

    function GUARDIAN_ROLE() external view returns (bytes32);

    function GOVERN_ROLE() external view returns (bytes32);

    function BURNER_ROLE() external view returns (bytes32);

    function MINTER_ROLE() external view returns (bytes32);

    function PCV_CONTROLLER_ROLE() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title Permissions Read interface
/// @author Fei Protocol
interface IPermissionsRead {
    // ----------- Getters -----------

    function isBurner(address _address) external view returns (bool);

    function isMinter(address _address) external view returns (bool);

    function isGovernor(address _address) external view returns (bool);

    function isGuardian(address _address) external view returns (bool);

    function isPCVController(address _address) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title FEI stablecoin interface
/// @author Fei Protocol
interface IVolt is IERC20 {
    // ----------- Events -----------

    event Minting(
        address indexed _to,
        address indexed _minter,
        uint256 _amount
    );

    event Burning(
        address indexed _to,
        address indexed _burner,
        uint256 _amount
    );

    event IncentiveContractUpdate(
        address indexed _incentivized,
        address indexed _incentiveContract
    );

    // ----------- State changing api -----------

    function burn(uint256 amount) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // ----------- Minter only state changing api -----------

    function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../refs/CoreRef.sol";
import "./IPCVDeposit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title abstract contract for withdrawing ERC-20 tokens using a PCV Controller
/// @author Fei Protocol
abstract contract PCVDeposit is IPCVDeposit, CoreRef {
    using SafeERC20 for IERC20;

    /// @notice withdraw ERC20 from the contract
    /// @param token address of the ERC20 to send
    /// @param to address destination of the ERC20
    /// @param amount quantity of ERC20 to send
    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) public virtual override onlyPCVController {
        _withdrawERC20(token, to, amount);
    }

    function _withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) internal {
        IERC20(token).safeTransfer(to, amount);
        emit WithdrawERC20(msg.sender, token, to, amount);
    }

    /// @notice withdraw ETH from the contract
    /// @param to address to send ETH
    /// @param amountOut amount of ETH to send
    function withdrawETH(address payable to, uint256 amountOut)
        external
        virtual
        override
        onlyPCVController
    {
        Address.sendValue(to, amountOut);
        emit WithdrawETH(msg.sender, to, amountOut);
    }

    function balance() public view virtual override returns (uint256);

    function resistantBalanceAndVolt()
        public
        view
        virtual
        override
        returns (uint256, uint256)
    {
        return (balance(), 0);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IPCVDepositBalances.sol";

/// @title a PCV Deposit interface
/// @author Fei Protocol
interface IPCVDeposit is IPCVDepositBalances {
    // ----------- Events -----------
    event Deposit(address indexed _from, uint256 _amount);

    event Withdrawal(
        address indexed _caller,
        address indexed _to,
        uint256 _amount
    );

    event WithdrawERC20(
        address indexed _caller,
        address indexed _token,
        address indexed _to,
        uint256 _amount
    );

    event WithdrawETH(
        address indexed _caller,
        address indexed _to,
        uint256 _amount
    );

    // ----------- State changing api -----------

    function deposit() external;

    // ----------- PCV Controller only state changing api -----------

    function withdraw(address to, uint256 amount) external;

    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external;

    function withdrawETH(address payable to, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title a PCV Deposit interface for only balance getters
/// @author Fei Protocol
interface IPCVDepositBalances {
    // ----------- Getters -----------

    /// @notice gets the effective balance of "balanceReportedIn" token if the deposit were fully withdrawn
    function balance() external view returns (uint256);

    /// @notice gets the token address in which this deposit returns its balance
    function balanceReportedIn() external view returns (address);

    /// @notice gets the resistant token balance and protocol owned fei of this deposit
    function resistantBalanceAndVolt() external view returns (uint256, uint256);
}

pragma solidity =0.8.13;

import {CoreRef} from "../refs/CoreRef.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @title abstract contract for putting a rate limit on how fast a contrac
/// can perform an action e.g. Minting
/// @author Elliot Friedman
abstract contract RateLimitedV2 is CoreRef {
    using SafeCast for *;

    /// @notice maximum rate limit per second governance can set for this contract
    uint256 public immutable MAX_RATE_LIMIT_PER_SECOND;

    /// ------------- First Storage Slot -------------

    /// @notice the rate per second for this contract
    uint128 public rateLimitPerSecond;

    /// @notice the cap of the buffer that can be used at once
    uint128 public bufferCap;

    /// ------------- Second Storage Slot -------------

    /// @notice the last time the buffer was used by the contract
    uint32 public lastBufferUsedTime;

    /// @notice the buffer at the timestamp of lastBufferUsedTime
    uint224 public bufferStored;

    /// @notice event emitted when buffer gets eaten into
    event BufferUsed(uint256 amountUsed, uint256 bufferRemaining);

    /// @notice event emitted when buffer gets replenished
    event BufferReplenished(uint256 amountReplenished, uint256 bufferRemaining);

    /// @notice event emitted when buffer cap is updated
    event BufferCapUpdate(uint256 oldBufferCap, uint256 newBufferCap);

    /// @notice event emitted when rate limit per second is updated
    event RateLimitPerSecondUpdate(
        uint256 oldRateLimitPerSecond,
        uint256 newRateLimitPerSecond
    );

    /// @notice RateLimitedV2 constructor
    /// @param _maxRateLimitPerSecond maximum rate limit per second that governance can set
    /// @param _rateLimitPerSecond starting rate limit per second
    /// @param _bufferCap cap on buffer size for this rate limited instance
    constructor(
        uint256 _maxRateLimitPerSecond,
        uint128 _rateLimitPerSecond,
        uint128 _bufferCap
    ) {
        lastBufferUsedTime = block.timestamp.toUint32();

        _setBufferCap(_bufferCap);
        bufferStored = _bufferCap;

        require(
            _rateLimitPerSecond <= _maxRateLimitPerSecond,
            "RateLimited: rateLimitPerSecond too high"
        );
        _setRateLimitPerSecond(_rateLimitPerSecond);

        MAX_RATE_LIMIT_PER_SECOND = _maxRateLimitPerSecond;
    }

    /// @notice set the rate limit per second
    function setRateLimitPerSecond(uint128 newRateLimitPerSecond)
        external
        virtual
        onlyGovernor
    {
        require(
            newRateLimitPerSecond <= MAX_RATE_LIMIT_PER_SECOND,
            "RateLimited: rateLimitPerSecond too high"
        );
        _updateBufferStored();

        _setRateLimitPerSecond(newRateLimitPerSecond);
    }

    /// @notice set the buffer cap
    function setBufferCap(uint128 newBufferCap) external virtual onlyGovernor {
        _setBufferCap(newBufferCap);
    }

    /// @notice the amount of action used before hitting limit
    /// @dev replenishes at rateLimitPerSecond per second up to bufferCap
    function buffer() public view returns (uint256) {
        uint256 elapsed = block.timestamp.toUint32() - lastBufferUsedTime;
        return
            Math.min(bufferStored + (rateLimitPerSecond * elapsed), bufferCap);
    }

    /** 
        @notice the method that enforces the rate limit. Decreases buffer by "amount". 
        If buffer is <= amount either
        1. Does a partial mint by the amount remaining in the buffer or
        2. Reverts
        Depending on whether doPartialAction is true or false
    */
    function _depleteBuffer(uint256 amount) internal {
        uint256 newBuffer = buffer();

        require(newBuffer != 0, "RateLimited: no rate limit buffer");
        require(amount <= newBuffer, "RateLimited: rate limit hit");

        bufferStored = (newBuffer - amount).toUint224();

        lastBufferUsedTime = block.timestamp.toUint32();

        emit BufferUsed(amount, bufferStored);
    }

    /// @notice function to replenish buffer
    /// @param amount to increase buffer by if under buffer cap
    function _replenishBuffer(uint256 amount) internal {
        uint256 newBuffer = buffer();

        uint256 _bufferCap = bufferCap; /// gas opti, save an SLOAD

        /// cannot replenish any further if already at buffer cap
        if (newBuffer == _bufferCap) {
            /// save an SSTORE + some stack operations if buffer cannot be increased.
            /// last buffer used time doesn't need to be updated as buffer cannot
            /// increase past the buffer cap
            return;
        }

        lastBufferUsedTime = block.timestamp.toUint32();

        /// ensure that bufferStored cannot be gt buffer cap
        bufferStored = Math.min(newBuffer + amount, _bufferCap).toUint224();

        emit BufferReplenished(amount, bufferStored);
    }

    function _setRateLimitPerSecond(uint128 newRateLimitPerSecond) internal {
        uint256 oldRateLimitPerSecond = rateLimitPerSecond;
        rateLimitPerSecond = newRateLimitPerSecond;

        emit RateLimitPerSecondUpdate(
            oldRateLimitPerSecond,
            newRateLimitPerSecond
        );
    }

    function _setBufferCap(uint128 newBufferCap) internal {
        _updateBufferStored();

        uint256 oldBufferCap = bufferCap;
        bufferCap = newBufferCap;

        emit BufferCapUpdate(oldBufferCap, newBufferCap);
    }

    function _updateBufferStored() internal {
        uint224 newBufferStored = buffer().toUint224();
        uint32 newBlockTimestamp = block.timestamp.toUint32();

        bufferStored = newBufferStored;
        lastBufferUsedTime = newBlockTimestamp;
    }
}

pragma solidity =0.8.13;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Timed} from "./../../utils/Timed.sol";
import {CoreRef} from "./../../refs/CoreRef.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Contract to remove all excess funds past a certain threshold from a smart contract
/// used to allocate funds from a PSM to a yield venue so that liquid reserves are minimized
/// This contract should never hold PCV, however it has a sweep function, so if tokens get sent to it,
/// they can still be recovered.
/// @author Volt Protocol
interface IERC20Allocator {
    /// ----------- Events -----------

    /// @notice event emitted when tokens are sent to the pushTarget from the pullTarget
    event Skimmed(uint256 amount, address target);

    /// @notice event emitted when tokens are sent to the pullTarget from the pushTarget
    event Dripped(uint256 amount, address target);

    /// @notice emitted when a new PSM is connected
    event PSMConnected(
        address psm,
        address token,
        uint248 targetBalance,
        int8 decimalsNormalizer
    );

    /// @notice emitted when an existing PSM is updated
    event PSMTargetBalanceUpdated(address psm, uint248 targetBalance);

    /// @notice emitted when a psm is connected to a PCV Deposit
    event DepositConnected(address psm, address pcvDeposit);

    /// @notice emitted when an existing deposit is deleted
    event DepositDeleted(address deposit);

    /// @notice emitted when a PSM is deleted
    event PSMDeleted(address psm);

    /// ----------- Governor Only API -----------

    /// @notice create a new deposit
    /// @param psm Peg Stability Module for this deposit
    /// @param targetBalance target amount of tokens for the PSM to hold
    /// @param decimalsNormalizer decimal normalizer to ensure buffer is depleted and replenished properly
    function connectPSM(
        address psm,
        uint248 targetBalance,
        int8 decimalsNormalizer
    ) external;

    /// @notice edit an existing deposit
    /// @param psm Peg Stability Module for this deposit
    /// @param targetBalance target amount of tokens for the PSM to hold
    function editPSMTargetBalance(address psm, uint248 targetBalance) external;

    /// @notice delete an existing deposit
    /// @param psm Peg Stability Module to remove from allocation
    function disconnectPSM(address psm) external;

    /// @notice establish connection between PSM and a PCV Deposit
    function connectDeposit(address psm, address pcvDeposit) external;

    /// @notice delete connection between PSM and a PCV Deposit
    function deleteDeposit(address pcvDeposit) external;

    /// @notice pull ERC20 tokens from pull target and send to push target
    /// if and only if the amount of tokens held in the contract is above
    /// the threshold.
    function skim(address psm) external;

    /// @notice push ERC20 tokens to PSM by pulling from a PCV deposit
    /// flow of funds: PCV Deposit -> PSM
    function drip(address psm) external;

    /// @notice function that returns whether the amount of tokens held
    /// are above the target and funds should flow from PSM -> PCV Deposit
    function checkSkimCondition(address psm) external view returns (bool);

    /// @notice function that returns whether the amount of tokens held
    /// are below the target and funds should flow from PCV Deposit -> PSM
    function checkDripCondition(address psm) external view returns (bool);

    /// @notice returns whether an action is allowed
    function checkActionAllowed(address psm) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    function _pause() internal virtual whenNotPaused {
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
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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