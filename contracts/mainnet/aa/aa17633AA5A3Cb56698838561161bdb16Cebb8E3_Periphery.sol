// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

interface ERC20Like {
    function mint(address, uint256) external;
}

contract MultiMint {
    address public owner;
    constructor() {
        owner = msg.sender;
    }

    /// @dev Assumes this contract has authority over the passed in tokens
    function mint(address[] calldata _tokens, uint256[] calldata _amounts, address _user) external {
        require(msg.sender == owner, "ONLY_OWNER");
        require(_tokens.length == _amounts.length, "ARRAY_LENGTH_MISMATCH");

        for (uint256 i = 0; i < _tokens.length; i++) {
            ERC20Like(_tokens[i]).mint(_user, _amounts[i]);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity  0.8.15;

contract Versioning {
    string public version;
    constructor(string memory _version){
        version = _version;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@sense-finance/v1-core/src/Divider.sol";
import "@sense-finance/v1-core/src/Periphery.sol";
import "@sense-finance/v1-core/src/adapters/abstract/BaseAdapter.sol";
import "@sense-finance/v1-core/src/adapters/implementations/compound/CFactory.sol";
import "@sense-finance/v1-core/src/adapters/implementations/fuse/FFactory.sol";
import "@sense-finance/v1-core/src/adapters/implementations/lido/WstETHAdapter.sol";
import "@sense-finance/v1-core/src/adapters/abstract/factories/ERC4626Factory.sol";
import "@sense-finance/v1-core/src/adapters/abstract/factories/ERC4626CropsFactory.sol";
import "@sense-finance/v1-core/src/adapters/abstract/factories/ERC4626CropFactory.sol";
import "@sense-finance/v1-core/src/adapters/implementations/oracles/ChainlinkPriceOracle.sol";
import "@sense-finance/v1-core/src/adapters/implementations/oracles/MasterPriceOracle.sol";
import "@sense-finance/v1-core/src/tests/test-helpers/mocks/fuse/MockOracle.sol";
import "@sense-finance/v1-core/src/tests/test-helpers/mocks/fuse/MockComptroller.sol";
import "@sense-finance/v1-core/src/tests/test-helpers/mocks/fuse/MockFuseDirectory.sol";
import "@sense-finance/v1-core/src/tests/test-helpers/mocks/MockAdapter.sol";
import "@sense-finance/v1-core/src/tests/test-helpers/mocks/MockToken.sol";
import "@sense-finance/v1-core/src/tests/test-helpers/mocks/MockTarget.sol";
import "@sense-finance/v1-core/src/tests/test-helpers/mocks/MockFactory.sol";
import { CAdapter } from "@sense-finance/v1-core/src/adapters/implementations/compound/CAdapter.sol";
import { FAdapter } from "@sense-finance/v1-core/src/adapters/implementations/fuse/FAdapter.sol";
import { PoolManager } from "@sense-finance/v1-fuse/src/PoolManager.sol";
import { NoopPoolManager } from "@sense-finance/v1-fuse/src/NoopPoolManager.sol";
import { EmergencyStop } from "@sense-finance/v1-utils/src/EmergencyStop.sol";
import { MockERC4626 } from "solmate/src/test/utils/mocks/MockERC4626.sol";

import { EulerERC4626WrapperFactory } from "@sense-finance/v1-core/src/adapters/abstract/erc4626/yield-daddy/euler/EulerERC4626WrapperFactory.sol";
import { RewardsDistributor } from "../lib/morpho-core-v1/contracts/common/rewards-distribution/RewardsDistributor.sol";

import "./Versioning.sol";

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import "../../../lib/solmate/src/utils/SafeTransferLib.sol";

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Morpho Rewards Distributor.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice This contract allows Morpho users to claim their rewards. This contract is largely inspired by Euler Distributor's contract: https://github.com/euler-xyz/euler-contracts/blob/master/contracts/mining/EulDistributor.sol.
contract RewardsDistributor is Ownable {
    using SafeTransferLib for ERC20;

    /// STORAGE ///

    ERC20 public immutable MORPHO;
    bytes32 public currRoot; // The merkle tree's root of the current rewards distribution.
    bytes32 public prevRoot; // The merkle tree's root of the previous rewards distribution.
    mapping(address => uint256) public claimed; // The rewards already claimed. account -> amount.

    /// EVENTS ///

    /// @notice Emitted when the root is updated.
    /// @param newRoot The new merkle's tree root.
    event RootUpdated(bytes32 newRoot);

    /// @notice Emitted when MORPHO tokens are withdrawn.
    /// @param to The address of the recipient.
    /// @param amount The amount of MORPHO tokens withdrawn.
    event MorphoWithdrawn(address to, uint256 amount);

    /// @notice Emitted when an account claims rewards.
    /// @param account The address of the claimer.
    /// @param amount The amount of rewards claimed.
    event RewardsClaimed(address account, uint256 amount);

    /// ERRORS ///

    /// @notice Thrown when the proof is invalid or expired.
    error ProofInvalidOrExpired();

    /// @notice Thrown when the claimer has already claimed the rewards.
    error AlreadyClaimed();

    /// CONSTRUCTOR ///

    /// @notice Constructs Morpho's RewardsDistributor contract.
    /// @param _morpho The address of the MORPHO token to distribute.
    constructor(address _morpho) {
        MORPHO = ERC20(_morpho);
    }

    /// EXTERNAL ///

    /// @notice Updates the current merkle tree's root.
    /// @param _newRoot The new merkle tree's root.
    function updateRoot(bytes32 _newRoot) external onlyOwner {
        prevRoot = currRoot;
        currRoot = _newRoot;
        emit RootUpdated(_newRoot);
    }

    /// @notice Withdraws MORPHO tokens to a recipient.
    /// @param _to The address of the recipient.
    /// @param _amount The amount of MORPHO tokens to transfer.
    function withdrawMorphoTokens(address _to, uint256 _amount) external onlyOwner {
        uint256 morphoBalance = MORPHO.balanceOf(address(this));
        uint256 toWithdraw = morphoBalance < _amount ? morphoBalance : _amount;
        MORPHO.safeTransfer(_to, toWithdraw);
        emit MorphoWithdrawn(_to, toWithdraw);
    }

    /// @notice Claims rewards.
    /// @param _account The address of the claimer.
    /// @param _claimable The overall claimable amount of token rewards.
    /// @param _proof The merkle proof that validates this claim.
    function claim(
        address _account,
        uint256 _claimable,
        bytes32[] calldata _proof
    ) external {
        bytes32 candidateRoot = MerkleProof.processProof(
            _proof,
            keccak256(abi.encodePacked(_account, _claimable))
        );
        if (candidateRoot != currRoot && candidateRoot != prevRoot) revert ProofInvalidOrExpired();

        uint256 alreadyClaimed = claimed[_account];
        if (_claimable <= alreadyClaimed) revert AlreadyClaimed();

        uint256 amount;
        unchecked {
            amount = _claimable - alreadyClaimed;
        }

        claimed[_account] = _claimable;

        MORPHO.safeTransfer(_account, amount);
        emit RewardsClaimed(_account, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// External references
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";
import { ReentrancyGuard } from "solmate/src/utils/ReentrancyGuard.sol";
import { DateTime } from "./external/DateTime.sol";
import { FixedMath } from "./external/FixedMath.sol";

// Internal references
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";

import { Levels } from "@sense-finance/v1-utils/src/libs/Levels.sol";
import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";
import { YT } from "./tokens/YT.sol";
import { Token } from "./tokens/Token.sol";
import { BaseAdapter as Adapter } from "./adapters/abstract/BaseAdapter.sol";

/// @title Sense Divider: Divide Assets in Two
/// @author fedealconada + jparklev
/// @notice You can use this contract to issue, combine, and redeem Sense ERC20 Principal and Yield Tokens
contract Divider is Trust, ReentrancyGuard, Pausable {
    using SafeTransferLib for ERC20;
    using FixedMath for uint256;
    using Levels for uint256;

    /* ========== PUBLIC CONSTANTS ========== */

    /// @notice Buffer before and after the actual maturity in which only the sponsor can settle the Series
    uint256 public constant SPONSOR_WINDOW = 3 hours;

    /// @notice Buffer after the sponsor window in which anyone can settle the Series
    uint256 public constant SETTLEMENT_WINDOW = 3 hours;

    /// @notice 5% issuance fee cap
    uint256 public constant ISSUANCE_FEE_CAP = 0.05e18;

    /* ========== PUBLIC MUTABLE STORAGE ========== */

    address public periphery;

    /// @notice Sense community multisig
    address public immutable cup;

    /// @notice Principal/Yield tokens deployer
    address public immutable tokenHandler;

    /// @notice Permissionless flag
    bool public permissionless;

    /// @notice Guarded launch flag
    bool public guarded = true;

    /// @notice Number of adapters (including turned off)
    uint248 public adapterCounter;

    /// @notice adapter ID -> adapter address
    mapping(uint256 => address) public adapterAddresses;

    /// @notice adapter data
    mapping(address => AdapterMeta) public adapterMeta;

    /// @notice adapter -> maturity -> Series
    mapping(address => mapping(uint256 => Series)) public series;

    /// @notice adapter -> maturity -> user -> lscale (last scale)
    mapping(address => mapping(uint256 => mapping(address => uint256))) public lscales;

    /* ========== DATA STRUCTURES ========== */

    struct Series {
        // Principal ERC20 token
        address pt;
        // Timestamp of series initialization
        uint48 issuance;
        // Yield ERC20 token
        address yt;
        // % of underlying principal initially reserved for Yield
        uint96 tilt;
        // Actor who initialized the Series
        address sponsor;
        // Tracks fees due to the series' settler
        uint256 reward;
        // Scale at issuance
        uint256 iscale;
        // Scale at maturity
        uint256 mscale;
        // Max scale value from this series' lifetime
        uint256 maxscale;
    }

    struct AdapterMeta {
        // Adapter ID
        uint248 id;
        // Adapter enabled/disabled
        bool enabled;
        // Max amount of Target allowed to be issued
        uint256 guard;
        // Adapter level
        uint248 level;
    }

    constructor(address _cup, address _tokenHandler) Trust(msg.sender) {
        cup = _cup;
        tokenHandler = _tokenHandler;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Enable an adapter
    /// @dev when permissionless is disabled, only the Periphery can onboard adapters
    /// @dev after permissionless is enabled, anyone can onboard adapters
    /// @param adapter Adapter's address
    function addAdapter(address adapter) external whenNotPaused {
        if (!permissionless && msg.sender != periphery) revert Errors.OnlyPermissionless();
        if (adapterMeta[adapter].id > 0 && !adapterMeta[adapter].enabled) revert Errors.InvalidAdapter();
        _setAdapter(adapter, true);
    }

    /// @notice Initializes a new Series
    /// @dev Deploys two ERC20 contracts, one for PTs and the other one for YTs
    /// @dev Transfers some fixed amount of stake asset to this contract
    /// @param adapter Adapter to associate with the Series
    /// @param maturity Maturity date for the new Series, in units of unix time
    /// @param sponsor Sponsor of the Series that puts up a token stake and receives the issuance fees
    function initSeries(
        address adapter,
        uint256 maturity,
        address sponsor
    ) external nonReentrant whenNotPaused returns (address pt, address yt) {
        if (periphery != msg.sender) revert Errors.OnlyPeriphery();
        if (!adapterMeta[adapter].enabled) revert Errors.InvalidAdapter();
        if (_exists(adapter, maturity)) revert Errors.DuplicateSeries();
        if (!_isValid(adapter, maturity)) revert Errors.InvalidMaturity();

        // Transfer stake asset stake from caller to adapter
        (address target, address stake, uint256 stakeSize) = Adapter(adapter).getStakeAndTarget();

        // Deploy Principal & Yield Tokens for this new Series
        (pt, yt) = TokenHandler(tokenHandler).deploy(adapter, adapterMeta[adapter].id, maturity);

        // Initialize the new Series struct
        uint256 scale = Adapter(adapter).scale();

        series[adapter][maturity].pt = pt;
        series[adapter][maturity].issuance = uint48(block.timestamp);
        series[adapter][maturity].yt = yt;
        series[adapter][maturity].tilt = uint96(Adapter(adapter).tilt());
        series[adapter][maturity].sponsor = sponsor;
        series[adapter][maturity].iscale = scale;
        series[adapter][maturity].maxscale = scale;

        ERC20(stake).safeTransferFrom(msg.sender, adapter, stakeSize);

        emit SeriesInitialized(adapter, maturity, pt, yt, sponsor, target);
    }

    /// @notice Settles a Series and transfers the settlement reward to the caller
    /// @dev The Series' sponsor has a grace period where only they can settle the Series
    /// @dev After that, the reward becomes MEV
    /// @param adapter Adapter to associate with the Series
    /// @param maturity Maturity date for the new Series
    function settleSeries(address adapter, uint256 maturity) external nonReentrant whenNotPaused {
        if (!adapterMeta[adapter].enabled) revert Errors.InvalidAdapter();
        if (!_exists(adapter, maturity)) revert Errors.SeriesDoesNotExist();
        if (_settled(adapter, maturity)) revert Errors.AlreadySettled();
        if (!_canBeSettled(adapter, maturity)) revert Errors.OutOfWindowBoundaries();

        // The maturity scale value is all a Series needs for us to consider it "settled"
        uint256 mscale = Adapter(adapter).scale();
        series[adapter][maturity].mscale = mscale;

        if (mscale > series[adapter][maturity].maxscale) {
            series[adapter][maturity].maxscale = mscale;
        }

        // Reward the caller for doing the work of settling the Series at around the correct time
        (address target, address stake, uint256 stakeSize) = Adapter(adapter).getStakeAndTarget();
        ERC20(target).safeTransferFrom(adapter, msg.sender, series[adapter][maturity].reward);
        ERC20(stake).safeTransferFrom(adapter, msg.sender, stakeSize);

        emit SeriesSettled(adapter, maturity, msg.sender);
    }

    /// @notice Mint Principal & Yield Tokens of a specific Series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series [unix time]
    /// @param tBal Balance of Target to deposit
    /// @dev The balance of PTs and YTs minted will be the same value in units of underlying (less fees)
    function issue(
        address adapter,
        uint256 maturity,
        uint256 tBal
    ) external nonReentrant whenNotPaused returns (uint256 uBal) {
        if (!adapterMeta[adapter].enabled) revert Errors.InvalidAdapter();
        if (!_exists(adapter, maturity)) revert Errors.SeriesDoesNotExist();
        if (_settled(adapter, maturity)) revert Errors.IssueOnSettle();

        uint256 level = adapterMeta[adapter].level;
        if (level.issueRestricted() && msg.sender != adapter) revert Errors.IssuanceRestricted();

        ERC20 target = ERC20(Adapter(adapter).target());

        // Take the issuance fee out of the deposited Target, and put it towards the settlement reward
        uint256 issuanceFee = Adapter(adapter).ifee();
        if (issuanceFee > ISSUANCE_FEE_CAP) revert Errors.IssuanceFeeCapExceeded();
        uint256 fee = tBal.fmul(issuanceFee);

        unchecked {
            // Safety: bounded by the Target's total token supply
            series[adapter][maturity].reward += fee;
        }
        uint256 tBalSubFee = tBal - fee;

        // Ensure the caller won't hit the issuance cap with this action
        unchecked {
            // Safety: bounded by the Target's total token supply
            if (guarded && target.balanceOf(adapter) + tBal > adapterMeta[address(adapter)].guard)
                revert Errors.GuardCapReached();
        }

        // Update values on adapter
        Adapter(adapter).notify(msg.sender, tBalSubFee, true);

        uint256 scale = level.collectDisabled() ? series[adapter][maturity].iscale : Adapter(adapter).scale();

        // Determine the amount of Underlying equal to the Target being sent in (the principal)
        uBal = tBalSubFee.fmul(scale);

        // If the caller has not collected on YT before, use the current scale, otherwise
        // use the harmonic mean of the last and the current scale value
        lscales[adapter][maturity][msg.sender] = lscales[adapter][maturity][msg.sender] == 0
            ? scale
            : _reweightLScale(
                adapter,
                maturity,
                YT(series[adapter][maturity].yt).balanceOf(msg.sender),
                uBal,
                msg.sender,
                scale
            );

        // Mint equal amounts of PT and YT
        Token(series[adapter][maturity].pt).mint(msg.sender, uBal);
        YT(series[adapter][maturity].yt).mint(msg.sender, uBal);

        target.safeTransferFrom(msg.sender, adapter, tBal);

        emit Issued(adapter, maturity, uBal, msg.sender);
    }

    /// @notice Reconstitute Target by burning PT and YT
    /// @dev Explicitly burns YTs before maturity, and implicitly does it at/after maturity through `_collect()`
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param uBal Balance of PT and YT to burn
    function combine(
        address adapter,
        uint256 maturity,
        uint256 uBal
    ) external nonReentrant whenNotPaused returns (uint256 tBal) {
        if (!adapterMeta[adapter].enabled) revert Errors.InvalidAdapter();
        if (!_exists(adapter, maturity)) revert Errors.SeriesDoesNotExist();

        uint256 level = adapterMeta[adapter].level;
        if (level.combineRestricted() && msg.sender != adapter) revert Errors.CombineRestricted();

        // Burn the PT
        Token(series[adapter][maturity].pt).burn(msg.sender, uBal);

        // Collect whatever excess is due
        uint256 collected = _collect(msg.sender, adapter, maturity, uBal, uBal, address(0));

        uint256 cscale = series[adapter][maturity].mscale;
        bool settled = _settled(adapter, maturity);
        if (!settled) {
            // If it's not settled, then YT won't be burned automatically in `_collect()`
            YT(series[adapter][maturity].yt).burn(msg.sender, uBal);
            // If collect has been restricted, use the initial scale, otherwise use the current scale
            cscale = level.collectDisabled()
                ? series[adapter][maturity].iscale
                : lscales[adapter][maturity][msg.sender];
        }

        // Convert from units of Underlying to units of Target
        tBal = uBal.fdiv(cscale);
        ERC20(Adapter(adapter).target()).safeTransferFrom(adapter, msg.sender, tBal);

        // Notify only when Series is not settled as when it is, the _collect() call above would trigger a _redeemYT which will call notify
        if (!settled) Adapter(adapter).notify(msg.sender, tBal, false);
        unchecked {
            // Safety: bounded by the Target's total token supply
            tBal += collected;
        }
        emit Combined(adapter, maturity, tBal, msg.sender);
    }

    /// @notice Burn PT of a Series once it's been settled
    /// @dev The balance of redeemable Target is a function of the change in Scale
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param uBal Amount of PT to burn, which should be equivalent to the amount of Underlying owed to the caller
    function redeem(
        address adapter,
        uint256 maturity,
        uint256 uBal
    ) external nonReentrant whenNotPaused returns (uint256 tBal) {
        // If a Series is settled, we know that it must have existed as well, so that check is unnecessary
        if (!_settled(adapter, maturity)) revert Errors.NotSettled();

        uint256 level = adapterMeta[adapter].level;
        if (level.redeemRestricted() && msg.sender != adapter) revert Errors.RedeemRestricted();

        // Burn the caller's PT
        Token(series[adapter][maturity].pt).burn(msg.sender, uBal);

        // Principal Token holder's share of the principal = (1 - part of the principal that belongs to Yield)
        uint256 zShare = FixedMath.WAD - series[adapter][maturity].tilt;

        // If Principal Token are at a loss and Yield have some principal to help cover the shortfall,
        // take what we can from Yield Token's principal
        if (series[adapter][maturity].mscale.fdiv(series[adapter][maturity].maxscale) >= zShare) {
            tBal = (uBal * zShare) / series[adapter][maturity].mscale;
        } else {
            tBal = uBal.fdiv(series[adapter][maturity].maxscale);
        }

        if (!level.redeemHookDisabled()) {
            Adapter(adapter).onRedeem(uBal, series[adapter][maturity].mscale, series[adapter][maturity].maxscale, tBal);
        }

        ERC20(Adapter(adapter).target()).safeTransferFrom(adapter, msg.sender, tBal);
        emit PTRedeemed(adapter, maturity, tBal);
    }

    function collect(
        address usr,
        address adapter,
        uint256 maturity,
        uint256 uBalTransfer,
        address to
    ) external nonReentrant onlyYT(adapter, maturity) whenNotPaused returns (uint256 collected) {
        uint256 uBal = YT(msg.sender).balanceOf(usr);
        return _collect(usr, adapter, maturity, uBal, uBalTransfer > 0 ? uBalTransfer : uBal, to);
    }

    /// @notice Collect YT excess before, at, or after maturity
    /// @dev If `to` is set, we copy the lscale value from usr to this address
    /// @param usr User who's collecting for their YTs
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param uBal yield Token balance
    /// @param uBalTransfer original transfer value
    /// @param to address to set the lscale value from usr
    function _collect(
        address usr,
        address adapter,
        uint256 maturity,
        uint256 uBal,
        uint256 uBalTransfer,
        address to
    ) internal returns (uint256 collected) {
        if (!_exists(adapter, maturity)) revert Errors.SeriesDoesNotExist();

        // If the adapter is disabled, its Yield Token can only collect
        // if associated Series has been settled, which implies that an admin
        // has backfilled it
        if (!adapterMeta[adapter].enabled && !_settled(adapter, maturity)) revert Errors.InvalidAdapter();

        Series memory _series = series[adapter][maturity];

        // Get the scale value from the last time this holder collected (default to maturity)
        uint256 lscale = lscales[adapter][maturity][usr];

        uint256 level = adapterMeta[adapter].level;
        if (level.collectDisabled()) {
            // If this Series has been settled, we ensure everyone's YT will
            // collect yield accrued since issuance
            if (_settled(adapter, maturity)) {
                lscale = series[adapter][maturity].iscale;
                // If the Series is not settled, we ensure no collections can happen
            } else {
                return 0;
            }
        }

        // If the Series has been settled, this should be their last collect, so redeem the user's Yield Tokens for them
        if (_settled(adapter, maturity)) {
            _redeemYT(usr, adapter, maturity, uBal);
        } else {
            // If we're not settled and we're past maturity + the sponsor window,
            // anyone can settle this Series so revert until someone does
            if (block.timestamp > maturity + SPONSOR_WINDOW) {
                revert Errors.CollectNotSettled();
                // Otherwise, this is a valid pre-settlement collect and we need to determine the scale value
            } else {
                uint256 cscale = Adapter(adapter).scale();
                // If this is larger than the largest scale we've seen for this Series, use it
                if (cscale > _series.maxscale) {
                    _series.maxscale = cscale;
                    lscales[adapter][maturity][usr] = cscale;
                    // If not, use the previously noted max scale value
                } else {
                    lscales[adapter][maturity][usr] = _series.maxscale;
                }
            }
        }

        // Determine how much underlying has accrued since the last time this user collected, in units of Target.
        // (Or take the last time as issuance if they haven't yet)
        //
        // Reminder: `Underlying / Scale = Target`
        // So the following equation is saying, for some amount of Underlying `u`:
        // "Balance of Target that equaled `u` at the last collection _minus_ Target that equals `u` now"
        //
        // Because maxscale must be increasing, the Target balance needed to equal `u` decreases, and that "excess"
        // is what Yield holders are collecting
        uint256 tBalNow = uBal.fdivUp(_series.maxscale); // preventive round-up towards the protocol
        uint256 tBalPrev = uBal.fdiv(lscale);
        unchecked {
            collected = tBalPrev > tBalNow ? tBalPrev - tBalNow : 0;
        }
        ERC20(Adapter(adapter).target()).safeTransferFrom(adapter, usr, collected);
        Adapter(adapter).notify(usr, collected, false); // Distribute reward tokens

        // If this collect is a part of a token transfer to another address, set the receiver's
        // last collection to a synthetic scale weighted based on the scale on their last collect,
        // the time elapsed, and the current scale
        if (to != address(0)) {
            uint256 ytBal = YT(_series.yt).balanceOf(to);
            // If receiver holds yields, we set lscale to a computed "synthetic" lscales value that,
            // for the updated yield balance, still assigns the correct amount of yield.
            lscales[adapter][maturity][to] = ytBal > 0
                ? _reweightLScale(adapter, maturity, ytBal, uBalTransfer, to, _series.maxscale)
                : _series.maxscale;
            uint256 tBalTransfer = uBalTransfer.fdiv(_series.maxscale);
            Adapter(adapter).notify(usr, tBalTransfer, false);
            Adapter(adapter).notify(to, tBalTransfer, true);
        }
        series[adapter][maturity] = _series;

        emit Collected(adapter, maturity, collected);
    }

    /// @notice calculate the harmonic mean of the current scale and the last scale,
    /// weighted by amounts associated with each
    function _reweightLScale(
        address adapter,
        uint256 maturity,
        uint256 ytBal,
        uint256 uBal,
        address receiver,
        uint256 scale
    ) internal view returns (uint256) {
        // Target Decimals * 18 Decimals [from fdiv] / (Target Decimals * 18 Decimals [from fdiv] / 18 Decimals)
        // = 18 Decimals, which is the standard for scale values
        return (ytBal + uBal).fdiv((ytBal.fdiv(lscales[adapter][maturity][receiver]) + uBal.fdiv(scale)));
    }

    function _redeemYT(
        address usr,
        address adapter,
        uint256 maturity,
        uint256 uBal
    ) internal {
        // Burn the users's YTs
        YT(series[adapter][maturity].yt).burn(usr, uBal);

        // Default principal for a YT
        uint256 tBal = 0;

        // Principal Token holder's share of the principal = (1 - part of the principal that belongs to Yield Tokens)
        uint256 zShare = FixedMath.WAD - series[adapter][maturity].tilt;

        // If PTs are at a loss and YTs had their principal cut to help cover the shortfall,
        // calculate how much YTs have left
        if (series[adapter][maturity].mscale.fdiv(series[adapter][maturity].maxscale) >= zShare) {
            tBal = uBal.fdiv(series[adapter][maturity].maxscale) - (uBal * zShare) / series[adapter][maturity].mscale;
            ERC20(Adapter(adapter).target()).safeTransferFrom(adapter, usr, tBal);
        }

        // Always notify the Adapter of the full Target balance that will no longer
        // have its rewards distributed
        Adapter(adapter).notify(usr, uBal.fdivUp(series[adapter][maturity].maxscale), false);

        emit YTRedeemed(adapter, maturity, tBal);
    }

    /* ========== ADMIN ========== */

    /// @notice Enable or disable a adapter
    /// @param adapter Adapter's address
    /// @param isOn Flag setting this adapter to enabled or disabled
    function setAdapter(address adapter, bool isOn) public requiresTrust {
        _setAdapter(adapter, isOn);
    }

    /// @notice Set adapter's guard
    /// @param adapter Adapter address
    /// @param cap The max target that can be deposited on the Adapter
    function setGuard(address adapter, uint256 cap) external requiresTrust {
        adapterMeta[adapter].guard = cap;
        emit GuardChanged(adapter, cap);
    }

    /// @notice Set guarded mode
    /// @param _guarded bool
    function setGuarded(bool _guarded) external requiresTrust {
        guarded = _guarded;
        emit GuardedChanged(_guarded);
    }

    /// @notice Set periphery's contract
    /// @param _periphery Target address
    function setPeriphery(address _periphery) external requiresTrust {
        periphery = _periphery;
        emit PeripheryChanged(_periphery);
    }

    /// @notice Set paused flag
    /// @param _paused boolean
    function setPaused(bool _paused) external requiresTrust {
        _paused ? _pause() : _unpause();
    }

    /// @notice Set permissioless mode
    /// @param _permissionless bool
    function setPermissionless(bool _permissionless) external requiresTrust {
        permissionless = _permissionless;
        emit PermissionlessChanged(_permissionless);
    }

    /// @notice Backfill a Series' Scale value at maturity if keepers failed to settle it
    /// @param adapter Adapter's address
    /// @param maturity Maturity date for the Series
    /// @param mscale Value to set as the Series' Scale value at maturity
    /// @param _usrs Values to set on lscales mapping
    /// @param _lscales Values to set on lscales mapping
    function backfillScale(
        address adapter,
        uint256 maturity,
        uint256 mscale,
        address[] calldata _usrs,
        uint256[] calldata _lscales
    ) external requiresTrust {
        if (!_exists(adapter, maturity)) revert Errors.SeriesDoesNotExist();

        uint256 cutoff = maturity + SPONSOR_WINDOW + SETTLEMENT_WINDOW;
        // Admin can never backfill before maturity
        if (block.timestamp <= cutoff) revert Errors.OutOfWindowBoundaries();

        // Set user's last scale values the Series (needed for the `collect` method)
        for (uint256 i = 0; i < _usrs.length; i++) {
            lscales[adapter][maturity][_usrs[i]] = _lscales[i];
        }

        if (mscale > 0) {
            Series memory _series = series[adapter][maturity];
            // Set the maturity scale for the Series (needed for `redeem` methods)
            series[adapter][maturity].mscale = mscale;
            if (mscale > _series.maxscale) {
                series[adapter][maturity].maxscale = mscale;
            }

            (address target, address stake, uint256 stakeSize) = Adapter(adapter).getStakeAndTarget();

            address stakeDst = adapterMeta[adapter].enabled ? cup : _series.sponsor;
            ERC20(target).safeTransferFrom(adapter, cup, _series.reward);
            series[adapter][maturity].reward = 0;
            ERC20(stake).safeTransferFrom(adapter, stakeDst, stakeSize);
        }

        emit Backfilled(adapter, maturity, mscale, _usrs, _lscales);
    }

    /* ========== INTERNAL VIEWS ========== */

    function _exists(address adapter, uint256 maturity) internal view returns (bool) {
        return series[adapter][maturity].pt != address(0);
    }

    function _settled(address adapter, uint256 maturity) internal view returns (bool) {
        return series[adapter][maturity].mscale > 0;
    }

    function _canBeSettled(address adapter, uint256 maturity) internal view returns (bool) {
        uint256 cutoff = maturity + SPONSOR_WINDOW + SETTLEMENT_WINDOW;
        // If the sender is the sponsor for the Series
        if (msg.sender == series[adapter][maturity].sponsor) {
            return maturity - SPONSOR_WINDOW <= block.timestamp && cutoff >= block.timestamp;
        } else {
            return maturity + SPONSOR_WINDOW < block.timestamp && cutoff >= block.timestamp;
        }
    }

    function _isValid(address adapter, uint256 maturity) internal view returns (bool) {
        (uint256 minm, uint256 maxm) = Adapter(adapter).getMaturityBounds();
        if (maturity < block.timestamp + minm || maturity > block.timestamp + maxm) return false;
        (, , uint256 day, uint256 hour, uint256 minute, uint256 second) = DateTime.timestampToDateTime(maturity);

        if (hour != 0 || minute != 0 || second != 0) return false;
        uint256 mode = Adapter(adapter).mode();
        if (mode == 0) {
            return day == 1;
        }
        if (mode == 1) {
            return DateTime.getDayOfWeek(maturity) == 1;
        }
        return false;
    }

    /* ========== INTERNAL UTILS ========== */

    function _setAdapter(address adapter, bool isOn) internal {
        AdapterMeta memory am = adapterMeta[adapter];
        if (am.enabled == isOn) revert Errors.ExistingValue();
        am.enabled = isOn;

        // If this adapter is being added for the first time
        if (isOn && am.id == 0) {
            am.id = ++adapterCounter;
            adapterAddresses[am.id] = adapter;
        }

        // Set level and target (can only be done once);
        am.level = uint248(Adapter(adapter).level());
        adapterMeta[adapter] = am;
        emit AdapterChanged(adapter, am.id, isOn);
    }

    /* ========== PUBLIC GETTERS ========== */

    /// @notice Returns address of Principal Token
    function pt(address adapter, uint256 maturity) public view returns (address) {
        return series[adapter][maturity].pt;
    }

    /// @notice Returns address of Yield Token
    function yt(address adapter, uint256 maturity) public view returns (address) {
        return series[adapter][maturity].yt;
    }

    function mscale(address adapter, uint256 maturity) public view returns (uint256) {
        return series[adapter][maturity].mscale;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyYT(address adapter, uint256 maturity) {
        if (series[adapter][maturity].yt != msg.sender) revert Errors.OnlyYT();
        _;
    }

    /* ========== LOGS ========== */

    /// @notice Admin
    event Backfilled(
        address indexed adapter,
        uint256 indexed maturity,
        uint256 mscale,
        address[] _usrs,
        uint256[] _lscales
    );
    event GuardChanged(address indexed adapter, uint256 cap);
    event AdapterChanged(address indexed adapter, uint256 indexed id, bool indexed isOn);
    event PeripheryChanged(address indexed periphery);

    /// @notice Series lifecycle
    /// *---- beginning
    event SeriesInitialized(
        address adapter,
        uint256 indexed maturity,
        address pt,
        address yt,
        address indexed sponsor,
        address indexed target
    );
    /// -***- middle
    event Issued(address indexed adapter, uint256 indexed maturity, uint256 balance, address indexed sender);
    event Combined(address indexed adapter, uint256 indexed maturity, uint256 balance, address indexed sender);
    event Collected(address indexed adapter, uint256 indexed maturity, uint256 collected);
    /// ----* end
    event SeriesSettled(address indexed adapter, uint256 indexed maturity, address indexed settler);
    event PTRedeemed(address indexed adapter, uint256 indexed maturity, uint256 redeemed);
    event YTRedeemed(address indexed adapter, uint256 indexed maturity, uint256 redeemed);
    /// *----* misc
    event GuardedChanged(bool indexed guarded);
    event PermissionlessChanged(bool indexed permissionless);
}

contract TokenHandler is Trust {
    /// @notice Program state
    address public divider;

    constructor() Trust(msg.sender) {}

    function init(address _divider) external requiresTrust {
        if (divider != address(0)) revert Errors.AlreadyInitialized();
        divider = _divider;
    }

    function deploy(
        address adapter,
        uint248 id,
        uint256 maturity
    ) external returns (address pt, address yt) {
        if (msg.sender != divider) revert Errors.OnlyDivider();

        ERC20 target = ERC20(Adapter(adapter).target());
        uint8 decimals = target.decimals();
        string memory symbol = target.symbol();
        (string memory d, string memory m, string memory y) = DateTime.toDateString(maturity);
        string memory date = DateTime.format(maturity);
        string memory datestring = string(abi.encodePacked(d, "-", m, "-", y));
        string memory adapterId = DateTime.uintToString(id);
        pt = address(
            new Token(
                string(abi.encodePacked(date, " ", symbol, " Sense Principal Token, A", adapterId)),
                string(abi.encodePacked("sP-", symbol, ":", datestring, ":", adapterId)),
                decimals,
                divider
            )
        );

        yt = address(
            new YT(
                adapter,
                maturity,
                string(abi.encodePacked(date, " ", symbol, " Sense Yield Token, A", adapterId)),
                string(abi.encodePacked("sY-", symbol, ":", datestring, ":", adapterId)),
                decimals,
                divider
            )
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// External references
import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";
import { FixedMath } from "./external/FixedMath.sol";
import { BalancerVault, IAsset } from "./external/balancer/Vault.sol";
import { BalancerPool } from "./external/balancer/Pool.sol";
import { IERC3156FlashBorrower } from "./external/flashloan/IERC3156FlashBorrower.sol";

// Internal references
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { Levels } from "@sense-finance/v1-utils/src/libs/Levels.sol";
import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";
import { BaseAdapter as Adapter } from "./adapters/abstract/BaseAdapter.sol";
import { BaseFactory as AdapterFactory } from "./adapters/abstract/factories/BaseFactory.sol";
import { Divider } from "./Divider.sol";
import { PoolManager } from "@sense-finance/v1-fuse/src/PoolManager.sol";

interface SpaceFactoryLike {
    function create(address, uint256) external returns (address);

    function pools(address adapter, uint256 maturity) external view returns (address);
}

/// @title Periphery
contract Periphery is Trust, IERC3156FlashBorrower {
    using FixedMath for uint256;
    using SafeTransferLib for ERC20;
    using Levels for uint256;

    /* ========== PUBLIC CONSTANTS ========== */

    /// @notice Lower bound on the amount of Claim tokens one can swap in for Target
    uint256 public constant MIN_YT_SWAP_IN = 0.000001e18;

    /// @notice Acceptable error when estimating the tokens resulting from a specific swap
    uint256 public constant PRICE_ESTIMATE_ACCEPTABLE_ERROR = 0.00000001e18;

    /* ========== PUBLIC IMMUTABLES ========== */

    /// @notice Sense core Divider address
    Divider public immutable divider;

    /// @notice Sense core Divider address
    BalancerVault public immutable balancerVault;

    /* ========== PUBLIC MUTABLE STORAGE ========== */

    /// @notice Sense core Divider address
    PoolManager public poolManager;

    /// @notice Sense core Divider address
    SpaceFactoryLike public spaceFactory;

    /// @notice adapter factories -> is supported
    mapping(address => bool) public factories;

    /// @notice adapter -> bool
    mapping(address => bool) public verified;

    /* ========== DATA STRUCTURES ========== */

    struct PoolLiquidity {
        ERC20[] tokens;
        uint256[] amounts;
        uint256 minBptOut;
    }

    constructor(
        address _divider,
        address _poolManager,
        address _spaceFactory,
        address _balancerVault
    ) Trust(msg.sender) {
        divider = Divider(_divider);
        poolManager = PoolManager(_poolManager);
        spaceFactory = SpaceFactoryLike(_spaceFactory);
        balancerVault = BalancerVault(_balancerVault);
    }

    /* ========== SERIES / ADAPTER MANAGEMENT ========== */

    /// @notice Sponsor a new Series in any adapter previously onboarded onto the Divider
    /// @dev Called by an external address, initializes a new series in the Divider
    /// @param adapter Adapter to associate with the Series
    /// @param maturity Maturity date for the Series, in units of unix time
    /// @param withPool Whether to deploy a Space pool or not (only works for unverified adapters)
    function sponsorSeries(
        address adapter,
        uint256 maturity,
        bool withPool
    ) external returns (address pt, address yt) {
        (, address stake, uint256 stakeSize) = Adapter(adapter).getStakeAndTarget();

        // Transfer stakeSize from sponsor into this contract
        ERC20(stake).safeTransferFrom(msg.sender, address(this), stakeSize);

        // Approve divider to withdraw stake assets
        ERC20(stake).safeApprove(address(divider), stakeSize);

        (pt, yt) = divider.initSeries(adapter, maturity, msg.sender);

        // Space pool is always created for verified adapters whilst is optional for unverified ones.
        // Automatically queueing series is only for verified adapters
        if (verified[adapter]) {
            if (address(poolManager) == address(0)) {
                spaceFactory.create(adapter, maturity);
            } else {
                poolManager.queueSeries(adapter, maturity, spaceFactory.create(adapter, maturity));
            }
        } else {
            if (withPool) {
                spaceFactory.create(adapter, maturity);
            }
        }
        emit SeriesSponsored(adapter, maturity, msg.sender);
    }

    /// @notice Deploy and onboard a Adapter
    /// @dev Called by external address, deploy a new Adapter via an Adapter Factory
    /// @param f Factory to use
    /// @param target Target to onboard
    /// @param data Additional encoded data needed to deploy the adapter
    function deployAdapter(
        address f,
        address target,
        bytes memory data
    ) external returns (address adapter) {
        if (!factories[f]) revert Errors.FactoryNotSupported();
        adapter = AdapterFactory(f).deployAdapter(target, data);
        emit AdapterDeployed(adapter);
        _verifyAdapter(adapter, true);
        _onboardAdapter(adapter, true);
    }

    /* ========== LIQUIDITY UTILS ========== */

    /// @notice Swap Target to Principal Tokens of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param tBal Balance of Target to sell
    /// @param minAccepted Min accepted amount of PT
    /// @return ptBal amount of PT received
    function swapTargetForPTs(
        address adapter,
        uint256 maturity,
        uint256 tBal,
        uint256 minAccepted
    ) external returns (uint256 ptBal) {
        ERC20(Adapter(adapter).target()).safeTransferFrom(msg.sender, address(this), tBal); // pull target
        return _swapTargetForPTs(adapter, maturity, tBal, minAccepted);
    }

    /// @notice Swap Underlying to Principal Tokens of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param uBal Balance of Underlying to sell
    /// @param minAccepted Min accepted amount of PT
    /// @return ptBal amount of PT received
    function swapUnderlyingForPTs(
        address adapter,
        uint256 maturity,
        uint256 uBal,
        uint256 minAccepted
    ) external returns (uint256 ptBal) {
        ERC20 underlying = ERC20(Adapter(adapter).underlying());
        underlying.safeTransferFrom(msg.sender, address(this), uBal); // pull underlying
        uint256 tBal = Adapter(adapter).wrapUnderlying(uBal); // wrap underlying into target
        ptBal = _swapTargetForPTs(adapter, maturity, tBal, minAccepted);
    }

    /// @notice Swap Target to Yield Tokens of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param targetIn Balance of Target to sell
    /// @param targetToBorrow Balance of Target to borrow
    /// @param minOut Min accepted amount of YT
    /// @return targetBal amount of Target sent back
    /// @return ytBal amount of YT received
    function swapTargetForYTs(
        address adapter,
        uint256 maturity,
        uint256 targetIn,
        uint256 targetToBorrow,
        uint256 minOut
    ) external returns (uint256 targetBal, uint256 ytBal) {
        ERC20(Adapter(adapter).target()).safeTransferFrom(msg.sender, address(this), targetIn);
        (targetBal, ytBal) = _flashBorrowAndSwapToYTs(adapter, maturity, targetIn, targetToBorrow, minOut);
        ERC20(Adapter(adapter).target()).safeTransfer(msg.sender, targetBal);
        ERC20(divider.yt(adapter, maturity)).safeTransfer(msg.sender, ytBal);
    }

    /// @notice Swap Underlying to Yield of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param underlyingIn Balance of Underlying to sell
    /// @param targetToBorrow Balance of Target to borrow
    /// @param minOut Min accepted amount of YT
    /// @return targetBal amount of Target sent back
    /// @return ytBal amount of YT received
    function swapUnderlyingForYTs(
        address adapter,
        uint256 maturity,
        uint256 underlyingIn,
        uint256 targetToBorrow,
        uint256 minOut
    ) external returns (uint256 targetBal, uint256 ytBal) {
        ERC20 underlying = ERC20(Adapter(adapter).underlying());
        underlying.safeTransferFrom(msg.sender, address(this), underlyingIn); // Pull Underlying
        // Wrap Underlying into Target and swap it for YTs
        uint256 targetIn = Adapter(adapter).wrapUnderlying(underlyingIn);
        (targetBal, ytBal) = _flashBorrowAndSwapToYTs(adapter, maturity, targetIn, targetToBorrow, minOut);
        ERC20(Adapter(adapter).target()).safeTransfer(msg.sender, targetBal);
        ERC20(divider.yt(adapter, maturity)).safeTransfer(msg.sender, ytBal);
    }

    /// @notice Swap Principal Tokens for Target of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param ptBal Balance of PT to sell
    /// @param minAccepted Min accepted amount of Target
    function swapPTsForTarget(
        address adapter,
        uint256 maturity,
        uint256 ptBal,
        uint256 minAccepted
    ) external returns (uint256 tBal) {
        tBal = _swapPTsForTarget(adapter, maturity, ptBal, minAccepted); // swap Principal Tokens for target
        ERC20(Adapter(adapter).target()).safeTransfer(msg.sender, tBal); // transfer target to msg.sender
    }

    /// @notice Swap Principal Tokens for Underlying of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param ptBal Balance of PT to sell
    /// @param minAccepted Min accepted amount of Target
    function swapPTsForUnderlying(
        address adapter,
        uint256 maturity,
        uint256 ptBal,
        uint256 minAccepted
    ) external returns (uint256 uBal) {
        uint256 tBal = _swapPTsForTarget(adapter, maturity, ptBal, minAccepted); // swap Principal Tokens for target
        uBal = Adapter(adapter).unwrapTarget(tBal); // unwrap target into underlying
        ERC20(Adapter(adapter).underlying()).safeTransfer(msg.sender, uBal); // transfer underlying to msg.sender
    }

    /// @notice Swap YT for Target of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param ytBal Balance of Yield Tokens to swap
    function swapYTsForTarget(
        address adapter,
        uint256 maturity,
        uint256 ytBal
    ) external returns (uint256 tBal) {
        tBal = _swapYTsForTarget(msg.sender, adapter, maturity, ytBal);
        ERC20(Adapter(adapter).target()).safeTransfer(msg.sender, tBal);
    }

    /// @notice Swap YT for Underlying of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param ytBal Balance of Yield Tokens to swap
    function swapYTsForUnderlying(
        address adapter,
        uint256 maturity,
        uint256 ytBal
    ) external returns (uint256 uBal) {
        uint256 tBal = _swapYTsForTarget(msg.sender, adapter, maturity, ytBal);
        uBal = Adapter(adapter).unwrapTarget(tBal);
        ERC20(Adapter(adapter).underlying()).safeTransfer(msg.sender, uBal);
    }

    /// @notice Adds liquidity providing target
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param tBal Balance of Target to provide
    /// @param mode 0 = issues and sell YT, 1 = issue and hold YT
    /// @param minBptOut Minimum BPT the user will accept out for this transaction
    /// @dev see return description of _addLiquidity
    function addLiquidityFromTarget(
        address adapter,
        uint256 maturity,
        uint256 tBal,
        uint8 mode,
        uint256 minBptOut
    )
        external
        returns (
            uint256 tAmount,
            uint256 issued,
            uint256 lpShares
        )
    {
        ERC20(Adapter(adapter).target()).safeTransferFrom(msg.sender, address(this), tBal);
        (tAmount, issued, lpShares) = _addLiquidity(adapter, maturity, tBal, mode, minBptOut);
    }

    /// @notice Adds liquidity providing underlying
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param uBal Balance of Underlying to provide
    /// @param mode 0 = issues and sell YT, 1 = issue and hold YT
    /// @param minBptOut Minimum BPT the user will accept out for this transaction
    /// @dev see return description of _addLiquidity
    function addLiquidityFromUnderlying(
        address adapter,
        uint256 maturity,
        uint256 uBal,
        uint8 mode,
        uint256 minBptOut
    )
        external
        returns (
            uint256 tAmount,
            uint256 issued,
            uint256 lpShares
        )
    {
        ERC20 underlying = ERC20(Adapter(adapter).underlying());
        underlying.safeTransferFrom(msg.sender, address(this), uBal);
        // Wrap Underlying into Target
        uint256 tBal = Adapter(adapter).wrapUnderlying(uBal);
        (tAmount, issued, lpShares) = _addLiquidity(adapter, maturity, tBal, mode, minBptOut);
    }

    /// @notice Removes liquidity providing an amount of LP tokens and returns target
    /// @dev More info on `minAmountsOut`: https://github.com/balancer-labs/docs-developers/blob/main/resources/joins-and-exits/pool-exits.md#minamountsout
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param lpBal Balance of LP tokens to provide
    /// @param minAmountsOut minimum accepted amounts of PTs and Target given the amount of LP shares provided
    /// @param minAccepted only used when removing liquidity on/after maturity and its the min accepted when swapping Principal Tokens to underlying
    /// @param intoTarget if true, it will try to swap PTs into Target. Will revert if there's not enough liquidity to perform the swap.
    /// @return tBal amount of target received and ptBal amount of Principal Tokens (in case it's called after maturity and redeem is restricted)
    function removeLiquidity(
        address adapter,
        uint256 maturity,
        uint256 lpBal,
        uint256[] memory minAmountsOut,
        uint256 minAccepted,
        bool intoTarget
    ) external returns (uint256 tBal, uint256 ptBal) {
        (tBal, ptBal) = _removeLiquidity(adapter, maturity, lpBal, minAmountsOut, minAccepted, intoTarget);
        ERC20(Adapter(adapter).target()).safeTransfer(msg.sender, tBal); // Send Target back to the User
    }

    /// @notice Removes liquidity providing an amount of LP tokens and returns underlying
    /// @dev More info on `minAmountsOut`: https://github.com/balancer-labs/docs-developers/blob/main/resources/joins-and-exits/pool-exits.md#minamountsout
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param lpBal Balance of LP tokens to provide
    /// @param minAmountsOut minimum accepted amounts of PTs and Target given the amount of LP shares provided
    /// @param minAccepted only used when removing liquidity on/after maturity and its the min accepted when swapping Principal Tokens to underlying
    /// @param intoTarget if true, it will try to swap PTs into Target. Will revert if there's not enough liquidity to perform the swap.
    /// @return uBal amount of underlying received and ptBal Principal Tokens (in case it's called after maturity and redeem is restricted or intoTarget is false)
    function removeLiquidityAndUnwrapTarget(
        address adapter,
        uint256 maturity,
        uint256 lpBal,
        uint256[] memory minAmountsOut,
        uint256 minAccepted,
        bool intoTarget
    ) external returns (uint256 uBal, uint256 ptBal) {
        uint256 tBal;
        (tBal, ptBal) = _removeLiquidity(adapter, maturity, lpBal, minAmountsOut, minAccepted, intoTarget);
        ERC20(Adapter(adapter).underlying()).safeTransfer(msg.sender, uBal = Adapter(adapter).unwrapTarget(tBal)); // Send Underlying back to the User
    }

    /// @notice Migrates liquidity position from one series to another
    /// @dev More info on `minAmountsOut`: https://github.com/balancer-labs/docs-developers/blob/main/resources/joins-and-exits/pool-exits.md#minamountsout
    /// @param srcAdapter Adapter address for the source Series
    /// @param dstAdapter Adapter address for the destination Series
    /// @param srcMaturity Maturity date for the source Series
    /// @param dstMaturity Maturity date for the destination Series
    /// @param lpBal Balance of LP tokens to provide
    /// @param minAmountsOut Minimum accepted amounts of PTs and Target given the amount of LP shares provided
    /// @param minAccepted Min accepted amount of target when swapping Principal Tokens (only used when removing liquidity on/after maturity)
    /// @param mode 0 = issues and sell YT, 1 = issue and hold YT
    /// @param intoTarget if true, it will try to swap PTs into Target. Will revert if there's not enough liquidity to perform the swap
    /// @param minBptOut Minimum BPT the user will accept out for this transaction
    /// @dev see return description of _addLiquidity. It also returns amount of PTs (in case it's called after maturity and redeem is restricted or inttoTarget is false)
    function migrateLiquidity(
        address srcAdapter,
        address dstAdapter,
        uint256 srcMaturity,
        uint256 dstMaturity,
        uint256 lpBal,
        uint256[] memory minAmountsOut,
        uint256 minAccepted,
        uint8 mode,
        bool intoTarget,
        uint256 minBptOut
    )
        external
        returns (
            uint256 tAmount,
            uint256 issued,
            uint256 lpShares,
            uint256 ptBal
        )
    {
        if (Adapter(srcAdapter).target() != Adapter(dstAdapter).target()) revert Errors.TargetMismatch();
        uint256 tBal;
        (tBal, ptBal) = _removeLiquidity(srcAdapter, srcMaturity, lpBal, minAmountsOut, minAccepted, intoTarget);
        (tAmount, issued, lpShares) = _addLiquidity(dstAdapter, dstMaturity, tBal, mode, minBptOut);
    }

    /* ========== ADMIN ========== */

    /// @notice Enable or disable a factory
    /// @param f Factory's address
    /// @param isOn Flag setting this factory to enabled or disabled
    function setFactory(address f, bool isOn) external requiresTrust {
        if (factories[f] == isOn) revert Errors.ExistingValue();
        factories[f] = isOn;
        emit FactoryChanged(f, isOn);
    }

    /// @notice Update the address for the Space Factory
    /// @param newSpaceFactory The Space Factory addresss to set
    function setSpaceFactory(address newSpaceFactory) external requiresTrust {
        emit SpaceFactoryChanged(address(spaceFactory), newSpaceFactory);
        spaceFactory = SpaceFactoryLike(newSpaceFactory);
    }

    /// @notice Update the address for the Pool Manager
    /// @param newPoolManager The Pool Manager addresss to set
    function setPoolManager(address newPoolManager) external requiresTrust {
        emit PoolManagerChanged(address(poolManager), newPoolManager);
        poolManager = PoolManager(newPoolManager);
    }

    /// @dev Verifies an Adapter and optionally adds the Target to the money market
    /// @param adapter Adapter to verify
    function verifyAdapter(address adapter, bool addToPool) public requiresTrust {
        _verifyAdapter(adapter, addToPool);
    }

    function _verifyAdapter(address adapter, bool addToPool) private {
        verified[adapter] = true;
        if (addToPool && address(poolManager) != address(0)) poolManager.addTarget(Adapter(adapter).target(), adapter);
        emit AdapterVerified(adapter);
    }

    /// @notice Onboard a single Adapter w/o needing a factory
    /// @dev Called by a trusted address, approves Target for issuance, and onboards adapter to the Divider
    /// @param adapter Adapter to onboard
    /// @param addAdapter Whether to call divider.addAdapter or not (useful e.g when upgrading Periphery)
    function onboardAdapter(address adapter, bool addAdapter) public {
        if (!divider.permissionless() && !isTrusted[msg.sender]) revert Errors.OnlyPermissionless();
        _onboardAdapter(adapter, addAdapter);
    }

    function _onboardAdapter(address adapter, bool addAdapter) private {
        ERC20 target = ERC20(Adapter(adapter).target());
        target.safeApprove(address(divider), type(uint256).max);
        target.safeApprove(address(adapter), type(uint256).max);
        ERC20(Adapter(adapter).underlying()).safeApprove(address(adapter), type(uint256).max);
        if (addAdapter) divider.addAdapter(adapter);
        emit AdapterOnboarded(adapter);
    }

    /* ========== INTERNAL UTILS ========== */

    function _swap(
        address assetIn,
        address assetOut,
        uint256 amountIn,
        bytes32 poolId,
        uint256 minAccepted
    ) internal returns (uint256 amountOut) {
        // approve vault to spend tokenIn
        ERC20(assetIn).safeApprove(address(balancerVault), amountIn);

        BalancerVault.SingleSwap memory request = BalancerVault.SingleSwap({
            poolId: poolId,
            kind: BalancerVault.SwapKind.GIVEN_IN,
            assetIn: IAsset(assetIn),
            assetOut: IAsset(assetOut),
            amount: amountIn,
            userData: hex""
        });

        BalancerVault.FundManagement memory funds = BalancerVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        amountOut = balancerVault.swap(request, funds, minAccepted, type(uint256).max);
        emit Swapped(msg.sender, poolId, assetIn, assetOut, amountIn, amountOut, msg.sig);
    }

    function _swapPTsForTarget(
        address adapter,
        uint256 maturity,
        uint256 ptBal,
        uint256 minAccepted
    ) internal returns (uint256 tBal) {
        address principalToken = divider.pt(adapter, maturity);
        ERC20(principalToken).safeTransferFrom(msg.sender, address(this), ptBal); // pull principal
        BalancerPool pool = BalancerPool(spaceFactory.pools(adapter, maturity));
        tBal = _swap(principalToken, Adapter(adapter).target(), ptBal, pool.getPoolId(), minAccepted); // swap Principal Tokens for underlying
    }

    function _swapTargetForPTs(
        address adapter,
        uint256 maturity,
        uint256 tBal,
        uint256 minAccepted
    ) internal returns (uint256 ptBal) {
        address principalToken = divider.pt(adapter, maturity);
        BalancerPool pool = BalancerPool(spaceFactory.pools(adapter, maturity));
        ptBal = _swap(Adapter(adapter).target(), principalToken, tBal, pool.getPoolId(), minAccepted); // swap target for Principal Tokens
        ERC20(principalToken).safeTransfer(msg.sender, ptBal); // transfer bought principal to user
    }

    function _swapYTsForTarget(
        address sender,
        address adapter,
        uint256 maturity,
        uint256 ytBal
    ) internal returns (uint256 tBal) {
        address yt = divider.yt(adapter, maturity);

        // Because there's some margin of error in the pricing functions here, smaller
        // swaps will be unreliable. Tokens with more than 18 decimals are not supported.
        if (ytBal * 10**(18 - ERC20(yt).decimals()) <= MIN_YT_SWAP_IN) revert Errors.SwapTooSmall();
        BalancerPool pool = BalancerPool(spaceFactory.pools(adapter, maturity));

        // Transfer YTs into this contract if needed
        if (sender != address(this)) ERC20(yt).safeTransferFrom(msg.sender, address(this), ytBal);

        // Calculate target to borrow by calling AMM
        bytes32 poolId = pool.getPoolId();
        (uint256 pti, uint256 targeti) = pool.getIndices();
        (ERC20[] memory tokens, uint256[] memory balances, ) = balancerVault.getPoolTokens(poolId);
        // Determine how much Target we'll need in to get `ytBal` balance of PT out
        // (space doesn't directly use of the fields from `SwapRequest` beyond `poolId`, so the values after are placeholders)
        uint256 targetToBorrow = BalancerPool(pool).onSwap(
            BalancerPool.SwapRequest({
                kind: BalancerVault.SwapKind.GIVEN_OUT,
                tokenIn: tokens[targeti],
                tokenOut: tokens[pti],
                amount: ytBal,
                poolId: poolId,
                lastChangeBlock: 0,
                from: address(0),
                to: address(0),
                userData: ""
            }),
            balances[targeti],
            balances[pti]
        );

        // Flash borrow target (following actions in `onFlashLoan`)
        tBal = _flashBorrowAndSwapFromYTs(adapter, maturity, ytBal, targetToBorrow);
    }

    /// @return tAmount if mode = 0, target received from selling YTs, otherwise, returns 0
    /// @return issued returns amount of YTs issued (and received) except first provision which returns 0
    /// @return lpShares Space LP shares received given the liquidity added
    function _addLiquidity(
        address adapter,
        uint256 maturity,
        uint256 tBal,
        uint8 mode,
        uint256 minBptOut
    )
        internal
        returns (
            uint256 tAmount,
            uint256 issued,
            uint256 lpShares
        )
    {
        // (1) compute target, issue PTs & YTs & add liquidity to space
        (issued, lpShares) = _computeIssueAddLiq(adapter, maturity, tBal, minBptOut);

        if (issued > 0) {
            // issue = 0 means that we are on the first pool provision or that the pt:target ratio is 0:target
            if (mode == 0) {
                // (2) Sell YTs
                tAmount = _swapYTsForTarget(address(this), adapter, maturity, issued);
                // (3) Send remaining Target back to the User
                ERC20(Adapter(adapter).target()).safeTransfer(msg.sender, tAmount);
            } else {
                // (4) Send YTs back to the User
                ERC20(divider.yt(adapter, maturity)).safeTransfer(msg.sender, issued);
            }
        }
    }

    /// @dev Calculates amount of Principal Tokens in target terms (see description on `_computeTarget`) then issues
    /// PTs and YTs with the calculated amount and finally adds liquidity to space with the PTs issued
    /// and the diff between the target initially passed and the calculated amount
    function _computeIssueAddLiq(
        address adapter,
        uint256 maturity,
        uint256 tBal,
        uint256 minBptOut
    ) internal returns (uint256 issued, uint256 lpShares) {
        BalancerPool pool = BalancerPool(spaceFactory.pools(adapter, maturity));
        // Compute target
        (ERC20[] memory tokens, uint256[] memory balances, ) = balancerVault.getPoolTokens(pool.getPoolId());
        (uint256 pti, uint256 targeti) = pool.getIndices(); // Ensure we have the right token Indices

        // We do not add Principal Token liquidity if it haven't been initialized yet
        bool ptInitialized = balances[pti] != 0;
        uint256 ptBalInTarget = ptInitialized ? _computeTarget(adapter, balances[pti], balances[targeti], tBal) : 0;

        // Issue PT & YT (skip if first pool provision)
        issued = ptBalInTarget > 0 ? divider.issue(adapter, maturity, ptBalInTarget) : 0;

        // Add liquidity to Space & send the LP Shares to recipient
        uint256[] memory amounts = new uint256[](2);
        amounts[targeti] = tBal - ptBalInTarget;
        amounts[pti] = issued;
        lpShares = _addLiquidityToSpace(pool, PoolLiquidity(tokens, amounts, minBptOut));
    }

    /// @dev Based on pt:target ratio from current pool reserves and tBal passed
    /// calculates amount of tBal needed so as to issue PTs that would keep the ratio
    function _computeTarget(
        address adapter,
        uint256 ptiBal,
        uint256 targetiBal,
        uint256 tBal
    ) internal returns (uint256 tBalForIssuance) {
        return
            tBal.fmul(
                ptiBal.fdiv(
                    Adapter(adapter).scale().fmul(FixedMath.WAD - Adapter(adapter).ifee()).fmul(targetiBal) + ptiBal
                )
            );
    }

    function _removeLiquidity(
        address adapter,
        uint256 maturity,
        uint256 lpBal,
        uint256[] memory minAmountsOut,
        uint256 minAccepted,
        bool intoTarget
    ) internal returns (uint256 tBal, uint256 ptBal) {
        address target = Adapter(adapter).target();
        address pt = divider.pt(adapter, maturity);
        BalancerPool pool = BalancerPool(spaceFactory.pools(adapter, maturity));
        bytes32 poolId = pool.getPoolId();

        // (0) Pull LP tokens from sender
        ERC20(address(pool)).safeTransferFrom(msg.sender, address(this), lpBal);

        // (1) Remove liquidity from Space
        uint256 _ptBal;
        (tBal, _ptBal) = _removeLiquidityFromSpace(poolId, pt, target, minAmountsOut, lpBal);
        if (divider.mscale(adapter, maturity) > 0) {
            if (uint256(Adapter(adapter).level()).redeemRestricted()) {
                ptBal = _ptBal;
            } else {
                // (2) Redeem Principal Tokens for Target
                tBal += divider.redeem(adapter, maturity, _ptBal);
            }
        } else {
            // (2) Sell Principal Tokens for Target (if there are)
            if (_ptBal > 0 && intoTarget) {
                tBal += _swap(pt, target, _ptBal, poolId, minAccepted);
            } else {
                ptBal = _ptBal;
            }
        }
        if (ptBal > 0) ERC20(pt).safeTransfer(msg.sender, ptBal); // Send PT back to the User
    }

    /// @notice Initiates a flash loan of Target, swaps target amount to PTs and combines
    /// @param adapter adapter
    /// @param maturity maturity
    /// @param ytBalIn YT amount the user has sent in
    /// @param amountToBorrow target amount to borrow
    /// @return tBal amount of Target obtained from a sale of YTs
    function _flashBorrowAndSwapFromYTs(
        address adapter,
        uint256 maturity,
        uint256 ytBalIn,
        uint256 amountToBorrow
    ) internal returns (uint256 tBal) {
        ERC20 target = ERC20(Adapter(adapter).target());
        uint256 decimals = target.decimals();
        uint256 acceptableError = decimals < 9 ? 1 : PRICE_ESTIMATE_ACCEPTABLE_ERROR / 10**(18 - decimals);
        bytes memory data = abi.encode(adapter, uint256(maturity), ytBalIn, ytBalIn - acceptableError, true);
        bool result = Adapter(adapter).flashLoan(this, address(target), amountToBorrow, data);
        if (!result) revert Errors.FlashBorrowFailed();

        tBal = target.balanceOf(address(this));
    }

    /// @notice Initiates a flash loan of Target, issues PTs/YTs and swaps the PTs to Target
    /// @param adapter adapter
    /// @param maturity taturity
    /// @param targetIn Target amount the user has sent in
    /// @param amountToBorrow Target amount to borrow
    /// @param minOut minimum amount of Target accepted out for the issued PTs
    /// @return targetBal amount of Target remaining after the flashloan has been paid back
    /// @return ytBal amount of YTs issued with the borrowed Target and the Target sent in
    function _flashBorrowAndSwapToYTs(
        address adapter,
        uint256 maturity,
        uint256 targetIn,
        uint256 amountToBorrow,
        uint256 minOut
    ) internal returns (uint256 targetBal, uint256 ytBal) {
        bytes memory data = abi.encode(adapter, uint256(maturity), targetIn, minOut, false);
        bool result = Adapter(adapter).flashLoan(this, Adapter(adapter).target(), amountToBorrow, data);
        if (!result) revert Errors.FlashBorrowFailed();

        targetBal = ERC20(Adapter(adapter).target()).balanceOf(address(this));
        ytBal = ERC20(divider.yt(adapter, maturity)).balanceOf(address(this));
        emit YTsPurchased(msg.sender, adapter, maturity, targetIn, targetBal, ytBal);
    }

    /// @dev ERC-3156 Flash loan callback
    function onFlashLoan(
        address initiator,
        address, /* token */
        uint256 amountBorrrowed,
        uint256, /* fee */
        bytes calldata data
    ) external returns (bytes32) {
        (address adapter, uint256 maturity, uint256 amountIn, uint256 minOut, bool ytToTarget) = abi.decode(
            data,
            (address, uint256, uint256, uint256, bool)
        );

        if (msg.sender != address(adapter)) revert Errors.FlashUntrustedBorrower();
        if (initiator != address(this)) revert Errors.FlashUntrustedLoanInitiator();
        BalancerPool pool = BalancerPool(spaceFactory.pools(adapter, maturity));

        if (ytToTarget) {
            ERC20 target = ERC20(Adapter(adapter).target());

            // Swap Target for PTs
            uint256 ptBal = _swap(
                address(target),
                divider.pt(adapter, maturity),
                target.balanceOf(address(this)),
                pool.getPoolId(),
                minOut // min pt out
            );

            // Combine PTs and YTs
            divider.combine(adapter, maturity, ptBal < amountIn ? ptBal : amountIn);
        } else {
            // Issue PTs and YTs
            divider.issue(adapter, maturity, amountIn + amountBorrrowed);
            ERC20 pt = ERC20(divider.pt(adapter, maturity));

            // Swap PTs for Target
            _swap(
                address(pt),
                Adapter(adapter).target(),
                pt.balanceOf(address(this)),
                pool.getPoolId(),
                minOut // min Target out
            ); // minOut should be close to amountBorrrowed so that minimal Target dust is sent back to the caller

            // Flashloaner contract will revert if not enough Target has been swapped out to pay back the loan
        }

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function _addLiquidityToSpace(BalancerPool pool, PoolLiquidity memory liq) internal returns (uint256 lpBal) {
        bytes32 poolId = pool.getPoolId();
        IAsset[] memory assets = _convertERC20sToAssets(liq.tokens);
        for (uint8 i; i < liq.tokens.length; i++) {
            // Tokens and amounts must be in same order
            liq.tokens[i].safeApprove(address(balancerVault), liq.amounts[i]);
        }

        // Behaves like EXACT_TOKENS_IN_FOR_BPT_OUT, user sends precise quantities of tokens,
        // and receives an estimated but unknown (computed at run time) quantity of BPT
        BalancerVault.JoinPoolRequest memory request = BalancerVault.JoinPoolRequest({
            assets: assets,
            maxAmountsIn: liq.amounts,
            userData: abi.encode(liq.amounts, liq.minBptOut),
            fromInternalBalance: false
        });
        balancerVault.joinPool(poolId, address(this), msg.sender, request);
        lpBal = ERC20(address(pool)).balanceOf(msg.sender);
    }

    function _removeLiquidityFromSpace(
        bytes32 poolId,
        address pt,
        address target,
        uint256[] memory minAmountsOut,
        uint256 lpBal
    ) internal returns (uint256 tBal, uint256 ptBal) {
        // ExitPoolRequest params
        (ERC20[] memory tokens, , ) = balancerVault.getPoolTokens(poolId);
        IAsset[] memory assets = _convertERC20sToAssets(tokens);
        BalancerVault.ExitPoolRequest memory request = BalancerVault.ExitPoolRequest({
            assets: assets,
            minAmountsOut: minAmountsOut,
            userData: abi.encode(lpBal),
            toInternalBalance: false
        });
        balancerVault.exitPool(poolId, address(this), payable(address(this)), request);

        tBal = ERC20(target).balanceOf(address(this));
        ptBal = ERC20(pt).balanceOf(address(this));
    }

    /// @notice From: https://github.com/balancer-labs/balancer-examples/blob/master/packages/liquidity-provision/contracts/LiquidityProvider.sol#L33
    /// @dev This helper function is a fast and cheap way to convert between IERC20[] and IAsset[] types
    function _convertERC20sToAssets(ERC20[] memory tokens) internal pure returns (IAsset[] memory assets) {
        assembly {
            assets := tokens
        }
    }

    /* ========== LOGS ========== */

    event FactoryChanged(address indexed factory, bool indexed isOn);
    event SpaceFactoryChanged(address oldSpaceFactory, address newSpaceFactory);
    event PoolManagerChanged(address oldPoolManager, address newPoolManager);
    event SeriesSponsored(address indexed adapter, uint256 indexed maturity, address indexed sponsor);
    event AdapterDeployed(address indexed adapter);
    event AdapterOnboarded(address indexed adapter);
    event AdapterVerified(address indexed adapter);
    event YTsPurchased(
        address indexed sender,
        address adapter,
        uint256 maturity,
        uint256 targetIn,
        uint256 targetReturned,
        uint256 ytOut
    );
    event Swapped(
        address indexed sender,
        bytes32 indexed poolId,
        address assetIn,
        address assetOut,
        uint256 amountIn,
        uint256 amountOut,
        bytes4 indexed sig
    );
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// External reference
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { Bytes32AddressLib } from "solmate/src/utils/Bytes32AddressLib.sol";
import { PriceOracle } from "./external/PriceOracle.sol";
import { BalancerOracle } from "./external/BalancerOracle.sol";

// Internal references
import { UnderlyingOracle } from "./oracles/Underlying.sol";
import { TargetOracle } from "./oracles/Target.sol";
import { PTOracle } from "./oracles/PT.sol";
import { LPOracle } from "./oracles/LP.sol";

import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { Divider } from "@sense-finance/v1-core/src/Divider.sol";
import { BaseAdapter as Adapter } from "@sense-finance/v1-core/src/adapters/abstract/BaseAdapter.sol";

interface FuseDirectoryLike {
    function deployPool(
        string memory name,
        address implementation,
        bool enforceWhitelist,
        uint256 closeFactor,
        uint256 liquidationIncentive,
        address priceOracle
    ) external returns (uint256, address);
}

interface ComptrollerLike {
    /// Deploy cToken, add the market to the markets mapping, and set it as listed and set the collateral factor
    /// Admin function to deploy cToken, set isListed, and add support for the market and set the collateral factor
    function _deployMarket(
        bool isCEther,
        bytes calldata constructorData,
        uint256 collateralFactorMantissa
    ) external returns (uint256);

    /// Accepts transfer of admin rights. msg.sender must be pendingAdmin
    function _acceptAdmin() external returns (uint256);

    /// All cTokens addresses mapped by their underlying token addresses
    function cTokensByUnderlying(address underlying) external view returns (address);

    /// A list of all markets
    function markets(address cToken) external view returns (bool, uint256);

    /// Pause borrowing for a specific market
    function _setBorrowPaused(address cToken, bool state) external returns (bool);
}

interface MasterOracleLike {
    function initialize(
        address[] memory underlyings,
        PriceOracle[] memory _oracles,
        PriceOracle _defaultOracle,
        address _restrictedAdmin,
        bool _canAdminOverwrite
    ) external;

    function add(address[] calldata underlyings, PriceOracle[] calldata _oracles) external;

    function getUnderlyingPrice(address cToken) external view returns (uint256);
}

/// @title Fuse Pool Manager
/// @notice Consolidated Fuse interactions
contract PoolManager is Trust {
    /* ========== PUBLIC IMMUTABLES ========== */

    /// @notice Implementation of Fuse's comptroller
    address public immutable comptrollerImpl;

    /// @notice Implementation of Fuse's cERC20
    address public immutable cERC20Impl;

    /// @notice Fuse's pool directory
    address public immutable fuseDirectory;

    /// @notice Sense core Divider address
    address public immutable divider;

    /// @notice Implementation of Fuse's master oracle that routes to individual asset oracles
    address public immutable oracleImpl;

    /// @notice Sense oracle for SEnse Targets
    address public immutable targetOracle;

    /// @notice Sense oracle for Sense Principal Tokens
    address public immutable ptOracle;

    /// @notice Sense oracle for Space LP Shares
    address public immutable lpOracle;

    /// @notice Sense oracle for Underlying assets
    address public immutable underlyingOracle;

    /* ========== PUBLIC MUTABLE STORAGE ========== */

    /// @notice Fuse comptroller for the Sense pool
    address public comptroller;

    /// @notice Master oracle for Sense's assets deployed on Fuse
    address public masterOracle;

    /// @notice Fuse param config
    AssetParams public targetParams;
    AssetParams public ptParams;
    AssetParams public lpTokenParams;

    /// @notice Series Pools: adapter -> maturity -> (series status (pt/lp shares), AMM pool)
    mapping(address => mapping(uint256 => Series)) public sSeries;

    /* ========== ENUMS ========== */

    enum SeriesStatus {
        NONE,
        QUEUED,
        ADDED
    }

    /* ========== DATA STRUCTURES ========== */

    struct AssetParams {
        address irModel;
        uint256 reserveFactor;
        uint256 collateralFactor;
    }

    struct Series {
        // Series addition status
        SeriesStatus status;
        // Space pool for this Series
        address pool;
    }

    constructor(
        address _fuseDirectory,
        address _comptrollerImpl,
        address _cERC20Impl,
        address _divider,
        address _oracleImpl
    ) Trust(msg.sender) {
        fuseDirectory = _fuseDirectory;
        comptrollerImpl = _comptrollerImpl;
        cERC20Impl = _cERC20Impl;
        divider = _divider;
        oracleImpl = _oracleImpl;

        targetOracle = address(new TargetOracle());
        ptOracle = address(new PTOracle());
        lpOracle = address(new LPOracle());
        underlyingOracle = address(new UnderlyingOracle());
    }

    function deployPool(
        string calldata name,
        uint256 closeFactor,
        uint256 liqIncentive,
        address fallbackOracle
    ) external requiresTrust returns (uint256 _poolIndex, address _comptroller) {
        masterOracle = Clones.cloneDeterministic(oracleImpl, Bytes32AddressLib.fillLast12Bytes(address(this)));
        MasterOracleLike(masterOracle).initialize(
            new address[](0),
            new PriceOracle[](0),
            PriceOracle(fallbackOracle), // default oracle used if asset prices can't be found otherwise
            address(this), // admin
            true // admin can override existing oracle routes
        );

        (_poolIndex, _comptroller) = FuseDirectoryLike(fuseDirectory).deployPool(
            name,
            comptrollerImpl,
            false, // `whitelist` is always false
            closeFactor,
            liqIncentive,
            masterOracle
        );

        uint256 err = ComptrollerLike(_comptroller)._acceptAdmin();
        if (err != 0) revert Errors.FailedBecomeAdmin();
        comptroller = _comptroller;

        emit PoolDeployed(name, _comptroller, _poolIndex, closeFactor, liqIncentive);
    }

    function addTarget(address target, address adapter) external requiresTrust returns (address cTarget) {
        if (comptroller == address(0)) revert Errors.PoolNotDeployed();
        if (targetParams.irModel == address(0)) revert Errors.TargetParamsNotSet();

        address underlying = Adapter(adapter).underlying();

        address[] memory underlyings = new address[](2);
        underlyings[0] = target;
        underlyings[1] = underlying;

        PriceOracle[] memory oracles = new PriceOracle[](2);
        oracles[0] = PriceOracle(targetOracle);
        oracles[1] = PriceOracle(underlyingOracle);

        UnderlyingOracle(underlyingOracle).setUnderlying(underlying, adapter);
        TargetOracle(targetOracle).setTarget(target, adapter);
        MasterOracleLike(masterOracle).add(underlyings, oracles);

        bytes memory constructorData = abi.encode(
            target,
            comptroller,
            targetParams.irModel,
            ERC20(target).name(),
            ERC20(target).symbol(),
            cERC20Impl,
            hex"", // calldata sent to becomeImplementation (empty bytes b/c it's currently unused)
            targetParams.reserveFactor,
            0 // no admin fee
        );

        // Trying to deploy the same market twice will fail
        uint256 err = ComptrollerLike(comptroller)._deployMarket(false, constructorData, targetParams.collateralFactor);
        if (err != 0) revert Errors.FailedAddTargetMarket();

        cTarget = ComptrollerLike(comptroller).cTokensByUnderlying(target);

        emit TargetAdded(target, cTarget);
    }

    /// @notice queues a set of (Principal Tokens, LPShare) for a Fuse pool to be deployed once the TWAP is ready
    /// @dev called by the Periphery, which will know which pool address to set for this Series
    function queueSeries(
        address adapter,
        uint256 maturity,
        address pool
    ) external requiresTrust {
        if (Divider(divider).pt(adapter, maturity) == address(0)) revert Errors.SeriesDoesNotExist();
        if (sSeries[adapter][maturity].status != SeriesStatus.NONE) revert Errors.DuplicateSeries();

        address cTarget = ComptrollerLike(comptroller).cTokensByUnderlying(Adapter(adapter).target());
        if (cTarget == address(0)) revert Errors.TargetNotInFuse();

        (bool isListed, ) = ComptrollerLike(comptroller).markets(cTarget);
        if (!isListed) revert Errors.TargetNotInFuse();

        sSeries[adapter][maturity] = Series({ status: SeriesStatus.QUEUED, pool: pool });

        emit SeriesQueued(adapter, maturity, pool);
    }

    /// @notice open method to add queued Principal Tokens and LPShares to Fuse pool
    /// @dev this can only be done once the yield space pool has filled its buffer and has a TWAP
    function addSeries(address adapter, uint256 maturity) external returns (address cPT, address cLPToken) {
        if (sSeries[adapter][maturity].status != SeriesStatus.QUEUED) revert Errors.SeriesNotQueued();
        if (ptParams.irModel == address(0)) revert Errors.PTParamsNotSet();
        if (lpTokenParams.irModel == address(0)) revert Errors.PoolParamsNotSet();

        address pt = Divider(divider).pt(adapter, maturity);
        address pool = sSeries[adapter][maturity].pool;

        (, , , , , , uint256 sampleTs) = BalancerOracle(pool).getSample(BalancerOracle(pool).getTotalSamples() - 1);
        // Prevent this market from being deployed on Fuse if we're unable to read a TWAP
        if (sampleTs == 0) revert Errors.OracleNotReady();

        address[] memory underlyings = new address[](2);
        underlyings[0] = pt;
        underlyings[1] = pool;

        PriceOracle[] memory oracles = new PriceOracle[](2);
        oracles[0] = PriceOracle(ptOracle);
        oracles[1] = PriceOracle(lpOracle);

        PTOracle(ptOracle).setPrincipal(pt, pool);
        MasterOracleLike(masterOracle).add(underlyings, oracles);

        bytes memory constructorDataPrincipal = abi.encode(
            pt,
            comptroller,
            ptParams.irModel,
            ERC20(pt).name(),
            ERC20(pt).symbol(),
            cERC20Impl,
            hex"",
            ptParams.reserveFactor,
            0 // no admin fee
        );

        uint256 errPrincipal = ComptrollerLike(comptroller)._deployMarket(
            false,
            constructorDataPrincipal,
            ptParams.collateralFactor
        );
        if (errPrincipal != 0) revert Errors.FailedToAddPTMarket();

        // LP Share pool token
        bytes memory constructorDataLpToken = abi.encode(
            pool,
            comptroller,
            lpTokenParams.irModel,
            ERC20(pool).name(),
            ERC20(pool).symbol(),
            cERC20Impl,
            hex"",
            lpTokenParams.reserveFactor,
            0 // no admin fee
        );

        uint256 errLpToken = ComptrollerLike(comptroller)._deployMarket(
            false,
            constructorDataLpToken,
            lpTokenParams.collateralFactor
        );
        if (errLpToken != 0) revert Errors.FailedAddLpMarket();

        cPT = ComptrollerLike(comptroller).cTokensByUnderlying(pt);
        cLPToken = ComptrollerLike(comptroller).cTokensByUnderlying(pool);

        ComptrollerLike(comptroller)._setBorrowPaused(cLPToken, true);

        sSeries[adapter][maturity].status = SeriesStatus.ADDED;

        emit SeriesAdded(pt, pool);
    }

    /* ========== ADMIN ========== */

    function setParams(bytes32 what, AssetParams calldata data) external requiresTrust {
        if (what == "PT_PARAMS") ptParams = data;
        else if (what == "LP_TOKEN_PARAMS") lpTokenParams = data;
        else if (what == "TARGET_PARAMS") targetParams = data;
        else revert Errors.InvalidParam();
        emit ParamsSet(what, data);
    }

    function execute(
        address to,
        uint256 value,
        bytes memory data,
        uint256 txGas
    ) external requiresTrust returns (bool success) {
        assembly {
            success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    /* ========== LOGS ========== */

    event ParamsSet(bytes32 indexed what, AssetParams data);
    event PoolDeployed(string name, address comptroller, uint256 poolIndex, uint256 closeFactor, uint256 liqIncentive);
    event TargetAdded(address indexed target, address indexed cTarget);
    event SeriesQueued(address indexed adapter, uint256 indexed maturity, address indexed pool);
    event SeriesAdded(address indexed pt, address indexed lpToken);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// Pool manager implementation with no restrictions where every function is a no-op. Refer to "PoolManager.sol"
// for an exemplar of a normal Pool Manager.
contract NoopPoolManager {
    function deployPool(
        string calldata name,
        uint256 closeFactor,
        uint256 liqIncentive,
        address fallbackOracle
    ) external returns (uint256 _poolIndex, address _comptroller) {}

    function addTarget(address target, address adapter) external returns (address cTarget) {}

    function queueSeries(
        address adapter,
        uint256 maturity,
        address pool
    ) external {}

    function addSeries(address adapter, uint256 maturity) external returns (address, address) {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// Internal references
import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";
import { Divider } from "@sense-finance/v1-core/src/Divider.sol";

/// @notice Unsets multiple adapters on the divider
contract EmergencyStop is Trust {
    address public immutable divider;

    constructor(address _divider) Trust(msg.sender) {
        divider = _divider;
    }

    function stop(address[] memory adapters) external virtual requiresTrust {
        Divider(divider).setPermissionless(false);
        for (uint256 i = 0; i < adapters.length; i++) {
            Divider(divider).setAdapter(adapters[i], false);
            emit Stopped(adapters[i]);
        }
    }

    event Stopped(address indexed adapter);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// External references
import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";
import { IERC3156FlashLender } from "../../external/flashloan/IERC3156FlashLender.sol";
import { IERC3156FlashBorrower } from "../../external/flashloan/IERC3156FlashBorrower.sol";

// Internal references
import { Divider } from "../../Divider.sol";
import { Crop } from "./extensions/Crop.sol";
import { Crops } from "./extensions/Crops.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";

/// @title Assign value to Target tokens
abstract contract BaseAdapter is IERC3156FlashLender {
    using SafeTransferLib for ERC20;

    /* ========== CONSTANTS ========== */

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    /* ========== PUBLIC IMMUTABLES ========== */

    /// @notice Sense core Divider address
    address public immutable divider;

    /// @notice Target token to divide
    address public immutable target;

    /// @notice Underlying for the Target
    address public immutable underlying;

    /// @notice Issuance fee
    uint128 public immutable ifee;

    /// @notice adapter params
    AdapterParams public adapterParams;

    /* ========== DATA STRUCTURES ========== */

    struct AdapterParams {
        /// @notice Oracle address
        address oracle;
        /// @notice Token to stake at issuance
        address stake;
        /// @notice Amount to stake at issuance
        uint256 stakeSize;
        /// @notice Min maturity (seconds after block.timstamp)
        uint256 minm;
        /// @notice Max maturity (seconds after block.timstamp)
        uint256 maxm;
        /// @notice WAD number representing the percentage of the total
        /// principal that's set aside for Yield Tokens (e.g. 0.1e18 means that 10% of the principal is reserved).
        /// @notice If `0`, it means no principal is set aside for Yield Tokens
        uint64 tilt;
        /// @notice The number this function returns will be used to determine its access by checking for binary
        /// digits using the following scheme: <onRedeem(y/n)><collect(y/n)><combine(y/n)><issue(y/n)>
        /// (e.g. 0101 enables `collect` and `issue`, but not `combine`)
        uint48 level;
        /// @notice 0 for monthly, 1 for weekly
        uint16 mode;
    }

    /* ========== METADATA STORAGE ========== */

    string public name;

    string public symbol;

    constructor(
        address _divider,
        address _target,
        address _underlying,
        uint128 _ifee,
        AdapterParams memory _adapterParams
    ) {
        divider = _divider;
        target = _target;
        underlying = _underlying;
        ifee = _ifee;
        adapterParams = _adapterParams;

        name = string(abi.encodePacked(ERC20(_target).name(), " Adapter"));
        symbol = string(abi.encodePacked(ERC20(_target).symbol(), "-adapter"));

        ERC20(_target).safeApprove(divider, type(uint256).max);
        ERC20(_adapterParams.stake).safeApprove(divider, type(uint256).max);
    }

    /// @notice Loan `amount` target to `receiver`, and takes it back after the callback.
    /// @param receiver The contract receiving target, needs to implement the
    /// `onFlashLoan(address user, address adapter, uint256 maturity, uint256 amount)` interface.
    /// @param amount The amount of target lent.
    /// @param data (encoded adapter address, maturity and YT amount the use has sent in)
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address, /* fee */
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        if (Divider(divider).periphery() != msg.sender) revert Errors.OnlyPeriphery();
        ERC20(target).safeTransfer(address(receiver), amount);
        bytes32 keccak = IERC3156FlashBorrower(receiver).onFlashLoan(msg.sender, target, amount, 0, data);
        if (keccak != CALLBACK_SUCCESS) revert Errors.FlashCallbackFailed();
        ERC20(target).safeTransferFrom(address(receiver), address(this), amount);
        return true;
    }

    /* ========== REQUIRED VALUE GETTERS ========== */

    /// @notice Calculate and return this adapter's Scale value for the current timestamp. To be overriden by child contracts
    /// @dev For some Targets, such as cTokens, this is simply the exchange rate, or `supply cToken / supply underlying`
    /// @dev For other Targets, such as AMM LP shares, specialized logic will be required
    /// @dev This function _must_ return a WAD number representing the current exchange rate
    /// between the Target and the Underlying.
    /// @return value WAD Scale value
    function scale() external virtual returns (uint256);

    /// @notice Cached scale value getter
    /// @dev For situations where you need scale from a view function
    function scaleStored() external view virtual returns (uint256);

    /// @notice Returns the current price of the underlying in ETH terms
    function getUnderlyingPrice() external view virtual returns (uint256);

    /* ========== REQUIRED UTILITIES ========== */

    /// @notice Deposits underlying `amount`in return for target. Must be overriden by child contracts
    /// @param amount Underlying amount
    /// @return amount of target returned
    function wrapUnderlying(uint256 amount) external virtual returns (uint256);

    /// @notice Deposits target `amount`in return for underlying. Must be overriden by child contracts
    /// @param amount Target amount
    /// @return amount of underlying returned
    function unwrapTarget(uint256 amount) external virtual returns (uint256);

    function flashFee(address token, uint256) external view returns (uint256) {
        if (token != target) revert Errors.TokenNotSupported();
        return 0;
    }

    function maxFlashLoan(address token) external view override returns (uint256) {
        return ERC20(token).balanceOf(address(this));
    }

    /* ========== OPTIONAL HOOKS ========== */

    /// @notice Notification whenever the Divider adds or removes Target
    function notify(
        address, /* usr */
        uint256, /* amt */
        bool /* join */
    ) public virtual {
        return;
    }

    /// @notice Hook called whenever a user redeems PT
    function onRedeem(
        uint256, /* uBal */
        uint256, /* mscale */
        uint256, /* maxscale */
        uint256 /* tBal */
    ) public virtual {
        return;
    }

    /* ========== PUBLIC STORAGE ACCESSORS ========== */

    function getMaturityBounds() external view virtual returns (uint256, uint256) {
        return (adapterParams.minm, adapterParams.maxm);
    }

    function getStakeAndTarget()
        external
        view
        returns (
            address,
            address,
            uint256
        )
    {
        return (target, adapterParams.stake, adapterParams.stakeSize);
    }

    function mode() external view returns (uint256) {
        return adapterParams.mode;
    }

    function tilt() external view returns (uint256) {
        return adapterParams.tilt;
    }

    function level() external view returns (uint256) {
        return adapterParams.level;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// Internal references
import { CropFactory } from "../../abstract/factories/CropFactory.sol";
import { CAdapter, ComptrollerLike } from "./CAdapter.sol";
import { BaseAdapter } from "../../abstract/BaseAdapter.sol";
import { ExtractableReward } from "../../abstract/extensions/ExtractableReward.sol";
import { Divider } from "../../../Divider.sol";

// External references
import { Bytes32AddressLib } from "solmate/src/utils/Bytes32AddressLib.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";

interface CTokenLike {
    function underlying() external view returns (address);
}

contract CFactory is CropFactory {
    using Bytes32AddressLib for address;

    address public constant COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant CETH = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    address public constant COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;

    constructor(
        address _divider,
        address _restrictedAdmin,
        address _rewardsRecipient,
        FactoryParams memory _factoryParams,
        address _reward
    ) CropFactory(_divider, _restrictedAdmin, _rewardsRecipient, _factoryParams, _reward) {}

    function deployAdapter(address _target, bytes memory) external override returns (address adapter) {
        // Sanity check
        if (Divider(divider).periphery() != msg.sender) revert Errors.OnlyPeriphery();

        (bool isListed, , ) = ComptrollerLike(COMPTROLLER).markets(_target);
        if (!isListed) revert Errors.TargetNotSupported();

        // Use the CREATE2 opcode to deploy a new Adapter contract.
        // This will revert if a CAdapter with the provided target has already
        // been deployed, as the salt would be the same and we can't deploy with it twice.
        BaseAdapter.AdapterParams memory adapterParams = BaseAdapter.AdapterParams({
            oracle: factoryParams.oracle,
            stake: factoryParams.stake,
            stakeSize: factoryParams.stakeSize,
            minm: factoryParams.minm,
            maxm: factoryParams.maxm,
            mode: factoryParams.mode,
            tilt: factoryParams.tilt,
            level: DEFAULT_LEVEL
        });
        adapter = address(
            new CAdapter{ salt: _target.fillLast12Bytes() }(
                divider,
                _target,
                _target == CETH ? WETH : CTokenLike(_target).underlying(),
                rewardsRecipient,
                factoryParams.ifee,
                adapterParams,
                reward
            )
        );

        _setGuard(adapter);

        ExtractableReward(adapter).setIsTrusted(restrictedAdmin, true);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// Internal references
import { FAdapter, FComptrollerLike, RewardsDistributorLike } from "./FAdapter.sol";
import { BaseFactory } from "../../abstract/factories/BaseFactory.sol";
import { BaseAdapter } from "../../abstract/BaseAdapter.sol";
import { ExtractableReward } from "../../abstract/extensions/ExtractableReward.sol";
import { Divider } from "../../../Divider.sol";

// External references
import { Bytes32AddressLib } from "solmate/src/utils/Bytes32AddressLib.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";

interface FTokenLike {
    function underlying() external view returns (address);

    function isCEther() external view returns (bool);
}

interface FusePoolLensLike {
    function poolExists(address comptroller) external view returns (bool);
}

contract FFactory is BaseFactory {
    using Bytes32AddressLib for address;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant FUSE_POOL_DIRECTORY = 0x835482FE0532f169024d5E9410199369aAD5C77E;

    constructor(
        address _divider,
        address _restrictedAdmin,
        address _rewardsRecipient,
        FactoryParams memory _factoryParams
    ) BaseFactory(_divider, _restrictedAdmin, _rewardsRecipient, _factoryParams) {}

    function deployAdapter(address _target, bytes memory data) external override returns (address adapter) {
        address comptroller = abi.decode(data, (address));

        /// Sanity checks
        if (Divider(divider).periphery() != msg.sender) revert Errors.OnlyPeriphery();
        if (!FusePoolLensLike(FUSE_POOL_DIRECTORY).poolExists(comptroller)) revert Errors.InvalidParam();
        (bool isListed, ) = FComptrollerLike(comptroller).markets(_target);
        if (!isListed) revert Errors.TargetNotSupported();

        // Initialize rewardTokens by calling getRewardsDistributors() -> rewardToken()
        address[] memory rewardsDistributors = FComptrollerLike(comptroller).getRewardsDistributors();
        address[] memory rewardTokens = new address[](rewardsDistributors.length);
        address[] memory targetRewardsDistributors = new address[](rewardsDistributors.length);

        uint256 idx;
        for (uint256 i = 0; i < rewardsDistributors.length; i++) {
            (, uint32 lastUpdatedTimestamp) = RewardsDistributorLike(rewardsDistributors[i]).marketState(_target);
            if (lastUpdatedTimestamp > 0) {
                rewardTokens[idx] = RewardsDistributorLike(rewardsDistributors[i]).rewardToken();
                targetRewardsDistributors[idx] = rewardsDistributors[i];
                idx = idx + 1;
            }
        }

        address underlying = FTokenLike(_target).underlying();
        BaseAdapter.AdapterParams memory adapterParams = BaseAdapter.AdapterParams({
            oracle: factoryParams.oracle,
            stake: factoryParams.stake,
            stakeSize: factoryParams.stakeSize,
            minm: factoryParams.minm,
            maxm: factoryParams.maxm,
            mode: factoryParams.mode,
            tilt: factoryParams.tilt,
            level: DEFAULT_LEVEL
        });
        // Use the CREATE2 opcode to deploy a new Adapter contract.
        // This will revert if a FAdapter with the provided target has already
        // been deployed, as the salt would be the same and we can't deploy with it twice.
        adapter = address(
            new FAdapter{ salt: _target.fillLast12Bytes() }(
                divider,
                _target,
                FTokenLike(_target).isCEther() ? WETH : underlying,
                rewardsRecipient,
                factoryParams.ifee,
                comptroller,
                adapterParams,
                rewardTokens,
                targetRewardsDistributors
            )
        );

        _setGuard(adapter);

        ExtractableReward(adapter).setIsTrusted(restrictedAdmin, true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "../../../tokens/ERC20.sol";
import {ERC4626} from "../../../mixins/ERC4626.sol";

contract MockERC4626 is ERC4626 {
    uint256 public beforeWithdrawHookCalledCounter = 0;
    uint256 public afterDepositHookCalledCounter = 0;

    constructor(
        ERC20 _underlying,
        string memory _name,
        string memory _symbol
    ) ERC4626(_underlying, _name, _symbol) {}

    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function beforeWithdraw(uint256, uint256) internal override {
        beforeWithdrawHookCalledCounter++;
    }

    function afterDeposit(uint256, uint256) internal override {
        afterDepositHookCalledCounter++;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// External references
import { FixedMath } from "../../../external/FixedMath.sol";

// Internal references
import { BaseAdapter } from "../../abstract/BaseAdapter.sol";
import { ExtractableReward } from "../../abstract/extensions/ExtractableReward.sol";
import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";

interface WstETHLike {
    /// @notice Exchanges wstETH to stETH
    function unwrap(uint256 _wstETHAmount) external returns (uint256);

    /// @notice Exchanges stETH to wstETH
    function wrap(uint256 _stETHAmount) external returns (uint256);
}

interface StETHLike {
    /// @notice Get amount of stETH for a one wstETH
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);
}

interface PriceOracleLike {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

/// @notice Adapter contract for wstETH
contract WstETHAdapter is BaseAdapter, ExtractableReward {
    using FixedMath for uint256;
    using SafeTransferLib for ERC20;

    address public constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant STETH_USD_PRICEFEED = 0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8; // Chainlink stETH-USD price feed
    address public constant ETH_USD_PRICEFEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // Chainlink ETH-USD price feed

    /// @notice Cached scale value from the last call to `scale()`
    uint256 public override scaleStored;

    constructor(
        address _divider,
        address _target,
        address _rewardsRecipient,
        uint128 _ifee,
        BaseAdapter.AdapterParams memory _adapterParams
    ) BaseAdapter(_divider, _target, STETH, _ifee, _adapterParams) ExtractableReward(_rewardsRecipient) {
        // approve wstETH contract to pull stETH (used on wrapUnderlying())
        ERC20(STETH).approve(WSTETH, type(uint256).max);
        // set an inital cached scale value
        scaleStored = StETHLike(STETH).getPooledEthByShares(1 ether);
    }

    /// @return exRate Eth per wstEtH (natively in 18 decimals)
    function scale() external virtual override returns (uint256 exRate) {
        exRate = StETHLike(STETH).getPooledEthByShares(1 ether);

        if (exRate != scaleStored) {
            // update value only if different than the previous
            scaleStored = exRate;
        }
    }

    /// @dev To calculate stETH-ETH price we use Chainlink's stETH-USD and ETH-USD price feeds.
    function getUnderlyingPrice() external view override returns (uint256 price) {
        (, int256 stethPrice, , uint256 stethUpdatedAt, ) = PriceOracleLike(STETH_USD_PRICEFEED).latestRoundData();
        (, int256 ethPrice, , uint256 ethUpdatedAt, ) = PriceOracleLike(ETH_USD_PRICEFEED).latestRoundData();
        if (block.timestamp - stethUpdatedAt > 2 hours) revert Errors.InvalidPrice();
        if (block.timestamp - ethUpdatedAt > 2 hours) revert Errors.InvalidPrice();
        price = uint256(stethPrice).fdiv(uint256(ethPrice));
        if (price < 0) revert Errors.InvalidPrice();
    }

    function unwrapTarget(uint256 amount) external override returns (uint256 stETH) {
        ERC20(WSTETH).safeTransferFrom(msg.sender, address(this), amount); // pull wstETH
        // unwrap wstETH into stETH and transfer it back to sender
        ERC20(STETH).safeTransfer(msg.sender, stETH = WstETHLike(WSTETH).unwrap(amount));
    }

    function wrapUnderlying(uint256 amount) external override returns (uint256 wstETH) {
        ERC20(STETH).safeTransferFrom(msg.sender, address(this), amount); // pull STETH
        // wrap stETH into wstETH and transfer it back to sender
        ERC20(WSTETH).safeTransfer(msg.sender, wstETH = WstETHLike(WSTETH).wrap(amount));
    }

    function _isValid(address _token) internal override returns (bool) {
        return (_token != target && _token != adapterParams.stake);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// Internal references
import { Divider } from "../../../Divider.sol";
import { ERC4626CropsAdapter } from "../erc4626/ERC4626CropsAdapter.sol";
import { BaseAdapter } from "../../abstract/BaseAdapter.sol";
import { BaseFactory } from "./BaseFactory.sol";
import { ExtractableReward } from "../../abstract/extensions/ExtractableReward.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";

// External references
import { Bytes32AddressLib } from "solmate/src/utils/Bytes32AddressLib.sol";

contract ERC4626CropsFactory is BaseFactory {
    using Bytes32AddressLib for address;

    mapping(address => bool) public supportedTargets;

    constructor(
        address _divider,
        address _restrictedAdmin,
        address _rewardsRecipient,
        FactoryParams memory _factoryParams
    ) BaseFactory(_divider, _restrictedAdmin, _rewardsRecipient, _factoryParams) {}

    /// @notice Deploys an ERC4626Adapter contract
    /// @param _target The target address
    /// @param data ABI encoded data
    function deployAdapter(address _target, bytes memory data) external override returns (address adapter) {
        address[] memory rewardTokens = abi.decode(data, (address[]));

        /// Sanity checks
        if (Divider(divider).periphery() != msg.sender) revert Errors.OnlyPeriphery();
        if (!Divider(divider).permissionless() && !supportedTargets[_target]) revert Errors.TargetNotSupported();

        BaseAdapter.AdapterParams memory adapterParams = BaseAdapter.AdapterParams({
            oracle: factoryParams.oracle,
            stake: factoryParams.stake,
            stakeSize: factoryParams.stakeSize,
            minm: factoryParams.minm,
            maxm: factoryParams.maxm,
            mode: factoryParams.mode,
            tilt: factoryParams.tilt,
            level: DEFAULT_LEVEL
        });

        // Use the CREATE2 opcode to deploy a new Adapter contract.
        // This will revert if am ERC4626 adapter with the provided target has already
        // been deployed, as the salt would be the same and we can't deploy with it twice.
        adapter = address(
            new ERC4626CropsAdapter{ salt: _target.fillLast12Bytes() }(
                divider,
                _target,
                rewardsRecipient,
                factoryParams.ifee,
                adapterParams,
                rewardTokens
            )
        );

        _setGuard(adapter);

        ExtractableReward(adapter).setIsTrusted(restrictedAdmin, true);
    }

    /// @notice (Un)support target
    /// @param _target The target address
    /// @param supported Whether the target should be supported or not
    function supportTarget(address _target, bool supported) external requiresTrust {
        supportedTargets[_target] = supported;
        emit TargetSupported(_target, supported);
    }

    /// @notice (Un)support multiple target at once
    /// @param _targets Array of target addresses
    /// @param supported Whether the targets should be supported or not
    function supportTargets(address[] memory _targets, bool supported) external requiresTrust {
        for (uint256 i = 0; i < _targets.length; i++) {
            supportedTargets[_targets[i]] = supported;
            emit TargetSupported(_targets[i], supported);
        }
    }

    /* ========== LOGS ========== */

    event TargetSupported(address indexed target, bool indexed supported);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// Internal references
import { Divider } from "../../../Divider.sol";
import { ERC4626Adapter } from "../erc4626/ERC4626Adapter.sol";
import { BaseAdapter } from "../../abstract/BaseAdapter.sol";
import { ExtractableReward } from "../../abstract/extensions/ExtractableReward.sol";
import { BaseFactory } from "./BaseFactory.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";

// External references
import { Bytes32AddressLib } from "solmate/src/utils/Bytes32AddressLib.sol";

contract ERC4626Factory is BaseFactory {
    using Bytes32AddressLib for address;

    mapping(address => bool) public supportedTargets;

    constructor(
        address _divider,
        address _restrictedAdmin,
        address _rewardsRecipient,
        FactoryParams memory _factoryParams
    ) BaseFactory(_divider, _restrictedAdmin, _rewardsRecipient, _factoryParams) {}

    /// @notice Deploys an ERC4626Adapter contract
    /// @param _target The target address
    /// @param data ABI encoded reward tokens address array
    function deployAdapter(address _target, bytes memory data) external override returns (address adapter) {
        /// Sanity checks
        if (Divider(divider).periphery() != msg.sender) revert Errors.OnlyPeriphery();
        if (!Divider(divider).permissionless() && !supportedTargets[_target]) revert Errors.TargetNotSupported();

        BaseAdapter.AdapterParams memory adapterParams = BaseAdapter.AdapterParams({
            oracle: factoryParams.oracle,
            stake: factoryParams.stake,
            stakeSize: factoryParams.stakeSize,
            minm: factoryParams.minm,
            maxm: factoryParams.maxm,
            mode: factoryParams.mode,
            tilt: factoryParams.tilt,
            level: DEFAULT_LEVEL
        });

        // Use the CREATE2 opcode to deploy a new Adapter contract.
        // This will revert if an ERC4626 adapter with the provided target has already
        // been deployed, as the salt would be the same and we can't deploy with it twice.
        adapter = address(
            new ERC4626Adapter{ salt: _target.fillLast12Bytes() }(
                divider,
                _target,
                rewardsRecipient,
                factoryParams.ifee,
                adapterParams
            )
        );

        _setGuard(adapter);

        ExtractableReward(adapter).setIsTrusted(restrictedAdmin, true);
    }

    /// @notice (Un)support target
    /// @param _target The target address
    /// @param supported Whether the target should be supported or not
    function supportTarget(address _target, bool supported) external requiresTrust {
        supportedTargets[_target] = supported;
        emit TargetSupported(_target, supported);
    }

    /// @notice (Un)support multiple target at once
    /// @param _targets Array of target addresses
    /// @param supported Whether the targets should be supported or not
    function supportTargets(address[] memory _targets, bool supported) external requiresTrust {
        for (uint256 i = 0; i < _targets.length; i++) {
            supportedTargets[_targets[i]] = supported;
            emit TargetSupported(_targets[i], supported);
        }
    }

    /* ========== LOGS ========== */

    event TargetSupported(address indexed target, bool indexed supported);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// Internal references
import { Divider } from "../../../Divider.sol";
import { ERC4626CropAdapter } from "../erc4626/ERC4626CropAdapter.sol";
import { BaseAdapter } from "../../abstract/BaseAdapter.sol";
import { ExtractableReward } from "../../abstract/extensions/ExtractableReward.sol";
import { CropFactory } from "./CropFactory.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";

// External references
import { Bytes32AddressLib } from "solmate/src/utils/Bytes32AddressLib.sol";

contract ERC4626CropFactory is CropFactory {
    using Bytes32AddressLib for address;

    mapping(address => bool) public supportedTargets;

    constructor(
        address _divider,
        address _restrictedAdmin,
        address _rewardsRecipient,
        FactoryParams memory _factoryParams
    ) CropFactory(_divider, _restrictedAdmin, _rewardsRecipient, _factoryParams, address(0)) {}

    /// @notice Deploys an ERC4626Adapter contract
    /// @param _target The target address
    /// @param data ABI encoded data
    function deployAdapter(address _target, bytes memory data) external override returns (address adapter) {
        address reward = abi.decode(data, (address));

        /// Sanity checks
        if (Divider(divider).periphery() != msg.sender) revert Errors.OnlyPeriphery();
        if (!Divider(divider).permissionless() && !supportedTargets[_target]) revert Errors.TargetNotSupported();

        BaseAdapter.AdapterParams memory adapterParams = BaseAdapter.AdapterParams({
            oracle: factoryParams.oracle,
            stake: factoryParams.stake,
            stakeSize: factoryParams.stakeSize,
            minm: factoryParams.minm,
            maxm: factoryParams.maxm,
            mode: factoryParams.mode,
            tilt: factoryParams.tilt,
            level: DEFAULT_LEVEL
        });

        // Use the CREATE2 opcode to deploy a new Adapter contract.
        // This will revert if am ERC4626 adapter with the provided target has already
        // been deployed, as the salt would be the same and we can't deploy with it twice.
        adapter = address(
            new ERC4626CropAdapter{ salt: _target.fillLast12Bytes() }(
                divider,
                _target,
                rewardsRecipient,
                factoryParams.ifee,
                adapterParams,
                reward
            )
        );

        _setGuard(adapter);

        ExtractableReward(adapter).setIsTrusted(restrictedAdmin, true);
    }

    /// @notice (Un)support target
    /// @param _target The target address
    /// @param supported Whether the target should be supported or not
    function supportTarget(address _target, bool supported) external requiresTrust {
        supportedTargets[_target] = supported;
        emit TargetSupported(_target, supported);
    }

    /// @notice (Un)support multiple target at once
    /// @param _targets Array of target addresses
    /// @param supported Whether the targets should be supported or not
    function supportTargets(address[] memory _targets, bool supported) external requiresTrust {
        for (uint256 i = 0; i < _targets.length; i++) {
            supportedTargets[_targets[i]] = supported;
            emit TargetSupported(_targets[i], supported);
        }
    }

    /* ========== LOGS ========== */

    event TargetSupported(address indexed target, bool indexed supported);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { IPriceFeed } from "../../abstract/IPriceFeed.sol";
import { FixedMath } from "../../../external/FixedMath.sol";

interface FeedRegistryLike {
    function latestRoundData(address base, address quote)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function decimals(address base, address quote) external view returns (uint8);
}

/// @title ChainlinkPriceOracle
/// @notice Returns prices from Chainlink.
/// @dev Implements `IPricefeed` and `Trust`.
/// @author Inspired by: https://github.com/Rari-Capital/fuse-v1/blob/development/src/oracles/ChainlinkPriceOracleV3.sol
contract ChainlinkPriceOracle is IPriceFeed, Trust {
    using FixedMath for uint256;

    // Chainlink's denominations
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
    address public constant USD = address(840);

    // The maxmimum number of seconds elapsed since the round was last updated before the price is considered stale. If set to 0, no limit is enforced.
    uint256 public maxSecondsBeforePriceIsStale;

    FeedRegistryLike public feedRegistry = FeedRegistryLike(0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf); // Chainlink feed registry contract

    constructor(uint256 _maxSecondsBeforePriceIsStale) public Trust(msg.sender) {
        maxSecondsBeforePriceIsStale = _maxSecondsBeforePriceIsStale;
    }

    /// @dev Internal function returning the price in ETH of `underlying`.
    function _price(address underlying) internal view returns (uint256) {
        // Return 1e18 for WETH
        if (underlying == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) return 1e18;

        // Try token/ETH to get token/ETH
        try feedRegistry.latestRoundData(underlying, ETH) returns (
            uint80,
            int256 tokenEthPrice,
            uint256,
            uint256 updatedAt,
            uint80
        ) {
            if (tokenEthPrice <= 0) return 0;
            _validatePrice(updatedAt);
            return uint256(tokenEthPrice).fmul(1e18).fdiv(10**uint256(feedRegistry.decimals(underlying, ETH)));
        } catch Error(string memory reason) {
            if (keccak256(abi.encodePacked(reason)) != keccak256(abi.encodePacked("Feed not found")))
                revert Errors.AttemptFailed();
        }

        // Try token/USD to get token/ETH
        try feedRegistry.latestRoundData(underlying, USD) returns (
            uint80,
            int256 tokenUsdPrice,
            uint256,
            uint256 updatedAt,
            uint80
        ) {
            if (tokenUsdPrice <= 0) return 0;
            _validatePrice(updatedAt);

            int256 ethUsdPrice;
            (, ethUsdPrice, , updatedAt, ) = feedRegistry.latestRoundData(ETH, USD);
            if (ethUsdPrice <= 0) return 0;
            _validatePrice(updatedAt);
            return
                uint256(tokenUsdPrice).fmul(1e26).fdiv(10**uint256(feedRegistry.decimals(underlying, USD))).fdiv(
                    uint256(ethUsdPrice)
                );
        } catch Error(string memory reason) {
            if (keccak256(abi.encodePacked(reason)) != keccak256(abi.encodePacked("Feed not found")))
                revert Errors.AttemptFailed();
        }

        // Try token/BTC to get token/ETH
        try feedRegistry.latestRoundData(underlying, BTC) returns (
            uint80,
            int256 tokenBtcPrice,
            uint256,
            uint256 updatedAt,
            uint80
        ) {
            if (tokenBtcPrice <= 0) return 0;
            _validatePrice(updatedAt);

            int256 btcEthPrice;
            (, btcEthPrice, , updatedAt, ) = feedRegistry.latestRoundData(BTC, ETH);
            if (btcEthPrice <= 0) return 0;
            _validatePrice(updatedAt);

            return
                uint256(tokenBtcPrice).fmul(uint256(btcEthPrice)).fdiv(
                    10**uint256(feedRegistry.decimals(underlying, BTC))
                );
        } catch Error(string memory reason) {
            if (keccak256(abi.encodePacked(reason)) != keccak256(abi.encodePacked("Feed not found")))
                revert Errors.AttemptFailed();
        }

        // Revert if all else fails
        revert Errors.PriceOracleNotFound();
    }

    /// @dev validates the price returned from Chainlink
    function _validatePrice(uint256 _updatedAt) internal view {
        if (maxSecondsBeforePriceIsStale > 0 && block.timestamp > _updatedAt + maxSecondsBeforePriceIsStale)
            revert Errors.InvalidPrice();
    }

    /// @dev Returns the price in ETH of `underlying` (implements `BasePriceOracle`).
    function price(address underlying) external view override returns (uint256) {
        return _price(underlying);
    }

    /// @dev Sets the `maxSecondsBeforePriceIsStale`.
    function setMaxSecondsBeforePriceIsStale(uint256 _maxSecondsBeforePriceIsStale) public requiresTrust {
        maxSecondsBeforePriceIsStale = _maxSecondsBeforePriceIsStale;
        emit MaxSecondsBeforePriceIsStaleChanged(maxSecondsBeforePriceIsStale);
    }

    /* ========== LOGS ========== */
    event MaxSecondsBeforePriceIsStaleChanged(uint256 indexed maxSecondsBeforePriceIsStale);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { IPriceFeed } from "../../abstract/IPriceFeed.sol";

/// @notice This contract gets prices from an available oracle address which must implement IPriceFeed.sol
/// If there's no oracle set, it will try getting the price from Chainlink's Oracle.
/// @author Inspired by: https://github.com/Rari-Capital/fuse-v1/blob/development/src/oracles/MasterPriceOracle.sol
contract MasterPriceOracle is IPriceFeed, Trust {
    address public senseChainlinkPriceOracle;

    /// @dev Maps underlying token addresses to oracle addresses.
    mapping(address => address) public oracles;

    /// @dev Constructor to initialize state variables.
    /// @param _chainlinkOracle The underlying ERC20 token addresses to link to `_oracles`.
    /// @param _underlyings The underlying ERC20 token addresses to link to `_oracles`.
    /// @param _oracles The `PriceOracle` contracts to be assigned to `underlyings`.
    constructor(
        address _chainlinkOracle,
        address[] memory _underlyings,
        address[] memory _oracles
    ) public Trust(msg.sender) {
        senseChainlinkPriceOracle = _chainlinkOracle;

        // Input validation
        if (_underlyings.length != _oracles.length) revert Errors.InvalidParam();

        // Initialize state variables
        for (uint256 i = 0; i < _underlyings.length; i++) oracles[_underlyings[i]] = _oracles[i];
    }

    /// @dev Sets `_oracles` for `underlyings`.
    /// Caller of this function must make sure that the oracles being added return non-stale, greater than 0
    /// prices for all underlying tokens.
    function add(address[] calldata _underlyings, address[] calldata _oracles) external requiresTrust {
        if (_underlyings.length <= 0 || _underlyings.length != _oracles.length) revert Errors.InvalidParam();

        for (uint256 i = 0; i < _underlyings.length; i++) {
            oracles[_underlyings[i]] = _oracles[i];
        }
    }

    /// @dev Attempts to return the price in ETH of `underlying` (implements `BasePriceOracle`).
    function price(address underlying) external view override returns (uint256) {
        if (underlying == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) return 1e18; // Return 1e18 for WETH

        address oracle = oracles[underlying];
        if (oracle != address(0)) {
            return IPriceFeed(oracle).price(underlying);
        } else {
            // Try token/ETH from Sense's Chainlink Oracle
            try IPriceFeed(senseChainlinkPriceOracle).price(underlying) returns (uint256 price) {
                return price;
            } catch {
                revert Errors.PriceOracleNotFound();
            }
        }
    }

    /// @dev Sets the `senseChainlinkPriceOracle`.
    function setSenseChainlinkPriceOracle(address _senseChainlinkPriceOracle) public requiresTrust {
        senseChainlinkPriceOracle = _senseChainlinkPriceOracle;
        emit SenseChainlinkPriceOracleChanged(senseChainlinkPriceOracle);
    }

    /* ========== LOGS ========== */
    event SenseChainlinkPriceOracleChanged(address indexed senseChainlinkPriceOracle);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// External references
import { ERC20 } from "solmate/src/tokens/ERC20.sol";

// Internal references
import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";

contract MockToken is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimal
    ) ERC20(_name, _symbol, _decimal) {}

    function mint(address account, uint256 amount) external virtual {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external virtual {
        _burn(account, amount);
    }
}

contract AuthdMockToken is ERC20, Trust {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimal
    ) ERC20(_name, _symbol, _decimal) Trust(msg.sender) {}

    function mint(address account, uint256 amount) external virtual requiresTrust {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external virtual requiresTrust {
        _burn(account, amount);
    }
}

// Non-ERC20 token

abstract contract NonERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

contract MockNonERC20Token is NonERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimal
    ) NonERC20(_name, _symbol, _decimal) {}

    function mint(address account, uint256 amount) external virtual {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external virtual {
        _burn(account, amount);
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public onlyPayloadSize(2 * 32) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    /**
     * @dev Fix for the ERC20 short address attack.
     */
    modifier onlyPayloadSize(uint256 size) {
        require(!(msg.data.length < size + 4));
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { BaseAdapter } from "../../../adapters/abstract/BaseAdapter.sol";
import { Crops } from "../../../adapters/abstract/extensions/Crops.sol";
import { Crop } from "../../../adapters/abstract/extensions/Crop.sol";
import { ExtractableReward } from "../../../adapters/abstract/extensions/ExtractableReward.sol";
import { ERC4626Adapter } from "../../../adapters/abstract/erc4626/ERC4626Adapter.sol";
import { FixedMath } from "../../../external/FixedMath.sol";
import { Divider } from "../../../Divider.sol";
import { YT } from "../../../tokens/YT.sol";
import { MockTarget } from "./MockTarget.sol";
import { MockToken } from "./MockToken.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";

// Mock adapter
contract MockAdapter is BaseAdapter, ExtractableReward {
    using FixedMath for uint256;
    using SafeTransferLib for ERC20;

    uint256 internal scaleOverride;
    uint256 public INITIAL_VALUE = 1e18;
    uint256 internal GROWTH_PER_SECOND = 792744799594; // 25% APY
    uint256 public onRedeemCalls;
    uint256 public scalingFactor;

    struct LScale {
        // Timestamp of the last scale value
        uint256 timestamp;
        // Last scale value
        uint256 value;
    }

    /// @notice Cached scale value from the last call to `scale()`
    LScale public lscale;

    constructor(
        address _divider,
        address _target,
        address _underlying,
        address _rewardsRecipient,
        uint128 _ifee,
        AdapterParams memory _adapterParams
    ) BaseAdapter(_divider, _target, _underlying, _ifee, _adapterParams) ExtractableReward(_rewardsRecipient) {
        uint256 tDecimals = MockTarget(_target).decimals();
        uint256 uDecimals = MockTarget(_underlying).decimals();
        scalingFactor = 10**(tDecimals > uDecimals ? tDecimals - uDecimals : uDecimals - tDecimals);
    }

    function scale() external virtual override returns (uint256 _scale) {
        if (scaleOverride > 0) {
            _scale = scaleOverride;
            lscale.value = scaleOverride;
            lscale.timestamp = block.timestamp;
        } else {
            uint256 gps = GROWTH_PER_SECOND.fmul(99 * (10**(18 - 2)));
            uint256 timeDiff = block.timestamp - lscale.timestamp;
            _scale = lscale.value > 0 ? (gps * timeDiff).fmul(lscale.value) + lscale.value : INITIAL_VALUE;

            if (_scale != lscale.value) {
                // update value only if different than the previous
                lscale.value = _scale;
                lscale.timestamp = block.timestamp;
            }
        }
    }

    function scaleStored() external view virtual override returns (uint256) {
        return lscale.value == 0 ? INITIAL_VALUE : lscale.value;
    }

    function wrapUnderlying(uint256 uBal) public virtual override returns (uint256) {
        MockTarget target = MockTarget(target);
        MockToken underlying = MockToken(target.underlying());
        underlying.transferFrom(msg.sender, address(this), uBal);
        uint256 mintAmount = uBal.fdivUp(lscale.value);
        mintAmount = underlying.decimals() > target.decimals()
            ? mintAmount / scalingFactor
            : mintAmount * scalingFactor;
        target.mint(msg.sender, mintAmount);
        return mintAmount;
    }

    function unwrapTarget(uint256 tBal) external virtual override returns (uint256) {
        MockTarget target = MockTarget(target);
        MockToken underlying = MockToken(target.underlying());
        target.transferFrom(msg.sender, address(this), tBal); // pull target
        uint256 mintAmount = tBal.fmul(lscale.value);
        mintAmount = underlying.decimals() > target.decimals()
            ? mintAmount * scalingFactor
            : mintAmount / scalingFactor;
        MockToken(target.underlying()).mint(msg.sender, mintAmount);
        return mintAmount;
    }

    function getUnderlyingPrice() external view virtual override returns (uint256) {
        return 1e18;
    }

    function _isValid(address _token) internal override returns (bool) {
        return (_token != target && _token != adapterParams.stake);
    }

    function onRedeem(
        uint256, /* uBal */
        uint256, /* mscale */
        uint256, /* maxscale */
        uint256 /* tBal */
    ) public virtual override {
        onRedeemCalls++;
    }

    function setScale(uint256 _scaleOverride) external {
        scaleOverride = _scaleOverride;
    }
}

// Mock crop adapter
contract MockCropAdapter is BaseAdapter, Crop, ExtractableReward {
    using FixedMath for uint256;
    using SafeTransferLib for ERC20;

    uint256 internal scaleOverride;
    uint256 public INITIAL_VALUE = 1e18;
    uint256 internal GROWTH_PER_SECOND = 792744799594; // 25% APY
    uint256 public onRedeemCalls;
    uint256 public scalingFactor;

    struct LScale {
        // Timestamp of the last scale value
        uint256 timestamp;
        // Last scale value
        uint256 value;
    }

    /// @notice Cached scale value from the last call to `scale()`
    LScale public lscale;

    constructor(
        address _divider,
        address _target,
        address _underlying,
        address _rewardsRecipient,
        uint128 _ifee,
        AdapterParams memory _adapterParams,
        address _reward
    )
        Crop(_divider, _reward)
        BaseAdapter(_divider, _target, _underlying, _ifee, _adapterParams)
        ExtractableReward(_rewardsRecipient)
    {
        uint256 tDecimals = MockTarget(_target).decimals();
        uint256 uDecimals = MockTarget(_underlying).decimals();
        scalingFactor = 10**(tDecimals > uDecimals ? tDecimals - uDecimals : uDecimals - tDecimals);
    }

    function notify(
        address _usr,
        uint256 amt,
        bool join
    ) public override(BaseAdapter, Crop) {
        super.notify(_usr, amt, join);
    }

    function scale() external virtual override returns (uint256 _scale) {
        if (scaleOverride > 0) {
            _scale = scaleOverride;
            lscale.value = scaleOverride;
            lscale.timestamp = block.timestamp;
        } else {
            uint256 gps = GROWTH_PER_SECOND.fmul(99 * (10**(18 - 2)));
            uint256 timeDiff = block.timestamp - lscale.timestamp;
            _scale = lscale.value > 0 ? (gps * timeDiff).fmul(lscale.value) + lscale.value : INITIAL_VALUE;

            if (_scale != lscale.value) {
                // update value only if different than the previous
                lscale.value = _scale;
                lscale.timestamp = block.timestamp;
            }
        }
    }

    function scaleStored() external view virtual override returns (uint256) {
        return lscale.value == 0 ? INITIAL_VALUE : lscale.value;
    }

    function _claimReward() internal virtual override {
        super._claimReward();
    }

    function wrapUnderlying(uint256 uBal) public virtual override returns (uint256) {
        MockTarget target = MockTarget(target);
        MockToken underlying = MockToken(target.underlying());
        underlying.transferFrom(msg.sender, address(this), uBal);
        uint256 mintAmount = uBal.fdivUp(lscale.value);
        mintAmount = underlying.decimals() > target.decimals()
            ? mintAmount / scalingFactor
            : mintAmount * scalingFactor;
        target.mint(msg.sender, mintAmount);
        return mintAmount;
    }

    function unwrapTarget(uint256 tBal) external virtual override returns (uint256) {
        MockTarget target = MockTarget(target);
        MockToken underlying = MockToken(target.underlying());
        target.transferFrom(msg.sender, address(this), tBal); // pull target
        uint256 mintAmount = tBal.fmul(lscale.value);
        mintAmount = underlying.decimals() > target.decimals()
            ? mintAmount * scalingFactor
            : mintAmount / scalingFactor;
        MockToken(target.underlying()).mint(msg.sender, mintAmount);
        return mintAmount;
    }

    function getUnderlyingPrice() external view virtual override returns (uint256) {
        return 1e18;
    }

    function _isValid(address _token) internal override returns (bool) {
        return (_token != target && _token != adapterParams.stake && _token != reward);
    }

    function onRedeem(
        uint256, /* uBal */
        uint256, /* mscale */
        uint256, /* maxscale */
        uint256 /* tBal */
    ) public virtual override {
        onRedeemCalls++;
    }

    function setScale(uint256 _scaleOverride) external {
        scaleOverride = _scaleOverride;
    }
}

// Mock crops adapter
contract MockCropsAdapter is BaseAdapter, Crops, ExtractableReward {
    using FixedMath for uint256;
    using SafeTransferLib for ERC20;

    uint256 internal scaleOverride;
    uint256 public INITIAL_VALUE = 1e18;
    uint256 internal GROWTH_PER_SECOND = 792744799594; // 25% APY
    uint256 public onRedeemCalls;
    uint256 public scalingFactor;

    struct LScale {
        // Timestamp of the last scale value
        uint256 timestamp;
        // Last scale value
        uint256 value;
    }

    /// @notice Cached scale value from the last call to `scale()`
    LScale public lscale;

    constructor(
        address _divider,
        address _target,
        address _underlying,
        address _rewardsRecipient,
        uint128 _ifee,
        AdapterParams memory _adapterParams,
        address[] memory _rewardTokens
    )
        Crops(_divider, _rewardTokens)
        BaseAdapter(_divider, _target, _underlying, _ifee, _adapterParams)
        ExtractableReward(_rewardsRecipient)
    {
        uint256 tDecimals = MockTarget(_target).decimals();
        uint256 uDecimals = MockTarget(_underlying).decimals();
        scalingFactor = 10**(tDecimals > uDecimals ? tDecimals - uDecimals : uDecimals - tDecimals);
    }

    function notify(
        address _usr,
        uint256 amt,
        bool join
    ) public override(BaseAdapter, Crops) {
        super.notify(_usr, amt, join);
    }

    function scale() external virtual override returns (uint256 _scale) {
        if (scaleOverride > 0) {
            _scale = scaleOverride;
            lscale.value = scaleOverride;
            lscale.timestamp = block.timestamp;
        } else {
            uint256 gps = GROWTH_PER_SECOND.fmul(99 * (10**(18 - 2)));
            uint256 timeDiff = block.timestamp - lscale.timestamp;
            _scale = lscale.value > 0 ? (gps * timeDiff).fmul(lscale.value) + lscale.value : INITIAL_VALUE;

            if (_scale != lscale.value) {
                // update value only if different than the previous
                lscale.value = _scale;
                lscale.timestamp = block.timestamp;
            }
        }
    }

    function scaleStored() external view virtual override returns (uint256) {
        return lscale.value == 0 ? INITIAL_VALUE : lscale.value;
    }

    function _claimRewards() internal virtual override {
        super._claimRewards();
    }

    function wrapUnderlying(uint256 uBal) public virtual override returns (uint256) {
        MockTarget target = MockTarget(target);
        MockToken underlying = MockToken(target.underlying());
        underlying.transferFrom(msg.sender, address(this), uBal);
        uint256 mintAmount = uBal.fdivUp(lscale.value);
        mintAmount = underlying.decimals() > target.decimals()
            ? mintAmount / scalingFactor
            : mintAmount * scalingFactor;
        target.mint(msg.sender, mintAmount);
        return mintAmount;
    }

    function unwrapTarget(uint256 tBal) external virtual override returns (uint256) {
        MockTarget target = MockTarget(target);
        MockToken underlying = MockToken(target.underlying());
        target.transferFrom(msg.sender, address(this), tBal); // pull target
        uint256 mintAmount = tBal.fmul(lscale.value);
        mintAmount = underlying.decimals() > target.decimals()
            ? mintAmount * scalingFactor
            : mintAmount / scalingFactor;
        MockToken(target.underlying()).mint(msg.sender, mintAmount);
        return mintAmount;
    }

    function getUnderlyingPrice() external view virtual override returns (uint256) {
        return 1e18;
    }

    function _isValid(address _token) internal override returns (bool) {
        for (uint256 i = 0; i < rewardTokens.length; ) {
            if (_token == rewardTokens[i]) return false;
            unchecked {
                ++i;
            }
        }

        // Check that token is neither the target nor the stake
        return (_token != target && _token != adapterParams.stake);
    }

    function onRedeem(
        uint256, /* uBal */
        uint256, /* mscale */
        uint256, /* maxscale */
        uint256 /* tBal */
    ) public virtual override {
        onRedeemCalls++;
    }

    function setScale(uint256 _scaleOverride) external {
        scaleOverride = _scaleOverride;
    }
}

// Mock ERC4626 crop adapter
contract Mock4626Adapter is ERC4626Adapter {
    using FixedMath for uint256;

    uint256 public onRedeemCalls;

    constructor(
        address _divider,
        address _target,
        address _underlying,
        address _rewardsRecipient,
        uint128 _ifee,
        AdapterParams memory _adapterParams
    ) ERC4626Adapter(_divider, _target, _rewardsRecipient, _ifee, _adapterParams) {}

    function lscale() external returns (uint256, uint256) {
        return (0, IERC4626(target).convertToAssets(BASE_UINT));
    }

    function onRedeem(
        uint256, /* uBal */
        uint256, /* mscale */
        uint256, /* maxscale */
        uint256 /* tBal */
    ) public virtual override {
        onRedeemCalls++;
    }
}

// Mock ERC4626 crop adapter
contract Mock4626CropAdapter is ERC4626Adapter, Crop {
    using FixedMath for uint256;
    using SafeTransferLib for ERC20;

    uint256 public onRedeemCalls;

    constructor(
        address _divider,
        address _target,
        address _underlying,
        address _rewardsRecipient,
        uint128 _ifee,
        AdapterParams memory _adapterParams,
        address _reward
    ) ERC4626Adapter(_divider, _target, _rewardsRecipient, _ifee, _adapterParams) Crop(_divider, _reward) {}

    function notify(
        address _usr,
        uint256 amt,
        bool join
    ) public override(BaseAdapter, Crop) {
        super.notify(_usr, amt, join);
    }

    function lscale() external returns (uint256, uint256) {
        return (0, IERC4626(target).convertToAssets(BASE_UINT));
    }

    function _isValid(address _token) internal override returns (bool) {
        return (_token != target && _token != adapterParams.stake && _token != reward);
    }

    function onRedeem(
        uint256, /* uBal */
        uint256, /* mscale */
        uint256, /* maxscale */
        uint256 /* tBal */
    ) public virtual override {
        onRedeemCalls++;
    }
}

// Mock ERC4626 crops adapter
contract Mock4626CropsAdapter is ERC4626Adapter, Crops {
    using FixedMath for uint256;
    using SafeTransferLib for ERC20;

    uint256 public onRedeemCalls;
    uint256 public scalingFactor;

    constructor(
        address _divider,
        address _target,
        address _underlying,
        address _rewardsRecipient,
        uint128 _ifee,
        AdapterParams memory _adapterParams,
        address[] memory _rewardTokens
    ) ERC4626Adapter(_divider, _target, _rewardsRecipient, _ifee, _adapterParams) Crops(_divider, _rewardTokens) {
        uint256 tDecimals = MockTarget(_target).decimals();
        uint256 uDecimals = MockTarget(_underlying).decimals();
        scalingFactor = 10**(tDecimals > uDecimals ? tDecimals - uDecimals : uDecimals - tDecimals);
    }

    function notify(
        address _usr,
        uint256 amt,
        bool join
    ) public override(BaseAdapter, Crops) {
        super.notify(_usr, amt, join);
    }

    function _isValid(address _token) internal override returns (bool) {
        for (uint256 i = 0; i < rewardTokens.length; ) {
            if (_token == rewardTokens[i]) return false;
            unchecked {
                ++i;
            }
        }

        // Check that token is neither the target nor the stake
        return (_token != target && _token != adapterParams.stake);
    }

    function onRedeem(
        uint256, /* uBal */
        uint256, /* mscale */
        uint256, /* maxscale */
        uint256 /* tBal */
    ) public virtual override {
        onRedeemCalls++;
    }
}

// Mock base adapter
contract MockBaseAdapter is BaseAdapter, ExtractableReward {
    using SafeTransferLib for ERC20;

    constructor(
        address _divider,
        address _target,
        address _underlying,
        address _rewardsRecipient,
        uint128 _ifee,
        AdapterParams memory _adapterParams
    ) BaseAdapter(_divider, _target, _underlying, _ifee, _adapterParams) ExtractableReward(_rewardsRecipient) {}

    function scale() external virtual override returns (uint256 _value) {
        return 100e18;
    }

    function scaleStored() external view virtual override returns (uint256) {
        return 100e18;
    }

    function wrapUnderlying(uint256 amount) external override returns (uint256) {
        return 0;
    }

    function unwrapTarget(uint256 amount) external override returns (uint256) {
        return 0;
    }

    function getUnderlyingPrice() external view override returns (uint256) {
        return 1e18;
    }

    function _isValid(address _token) internal override returns (bool) {
        return (_token != target && _token != adapterParams.stake);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// Internal references
import { BaseFactory } from "../../../adapters/abstract/factories/BaseFactory.sol";
import { CropFactory } from "../../../adapters/abstract/factories/CropFactory.sol";
import { ERC4626Factory } from "../../../adapters/abstract/factories/ERC4626Factory.sol";
import { ExtractableReward } from "../../../adapters/abstract/extensions/ExtractableReward.sol";
import { Divider } from "../../../Divider.sol";
import { MockAdapter, MockCropsAdapter, MockCropAdapter, Mock4626Adapter, Mock4626CropAdapter, Mock4626CropsAdapter } from "./MockAdapter.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { BaseAdapter } from "../../../adapters/abstract/BaseAdapter.sol";

// External references
import { Bytes32AddressLib } from "solmate/src/utils/Bytes32AddressLib.sol";

interface MockTargetLike {
    function underlying() external view returns (address);

    function asset() external view returns (address);
}

// -- Non-4626 factories -- //

contract MockFactory is BaseFactory {
    using Bytes32AddressLib for address;

    mapping(address => bool) public targets;

    constructor(
        address _divider,
        address _restrictedAdmin,
        address _rewardsRecipient,
        BaseFactory.FactoryParams memory _factoryParams
    ) BaseFactory(_divider, _restrictedAdmin, _rewardsRecipient, _factoryParams) {}

    function supportTarget(address _target, bool status) external {
        targets[_target] = status;
    }

    function deployAdapter(address _target, bytes memory data) external virtual override returns (address adapter) {
        if (!targets[_target]) revert Errors.TargetNotSupported();
        if (Divider(divider).periphery() != msg.sender) revert Errors.OnlyPeriphery();

        // Use the CREATE2 opcode to deploy a new Adapter contract.
        // This will revert if a MockAdapter with the provided target has already
        // been deployed, as the salt would be the same and we can't deploy with it twice.
        BaseAdapter.AdapterParams memory adapterParams = BaseAdapter.AdapterParams({
            oracle: factoryParams.oracle,
            stake: factoryParams.stake,
            stakeSize: factoryParams.stakeSize,
            minm: factoryParams.minm,
            maxm: factoryParams.maxm,
            mode: factoryParams.mode,
            tilt: factoryParams.tilt,
            level: DEFAULT_LEVEL
        });

        adapter = address(
            new MockAdapter{ salt: _target.fillLast12Bytes() }(
                divider,
                _target,
                MockTargetLike(_target).underlying(),
                rewardsRecipient,
                factoryParams.ifee,
                adapterParams
            )
        );

        // We only want to execute this if divider is guarded
        if (Divider(divider).guarded()) {
            Divider(divider).setGuard(adapter, type(uint256).max);
        }

        ExtractableReward(adapter).setIsTrusted(restrictedAdmin, true);
    }
}

contract MockCropFactory is CropFactory {
    using Bytes32AddressLib for address;

    mapping(address => bool) public targets;

    constructor(
        address _divider,
        address _restrictedAdmin,
        address _rewardsRecipient,
        BaseFactory.FactoryParams memory _factoryParams,
        address _reward
    ) CropFactory(_divider, _restrictedAdmin, _rewardsRecipient, _factoryParams, _reward) {}

    function supportTarget(address _target, bool status) external {
        targets[_target] = status;
    }

    function deployAdapter(address _target, bytes memory data) external virtual override returns (address adapter) {
        if (!targets[_target]) revert Errors.TargetNotSupported();
        if (Divider(divider).periphery() != msg.sender) revert Errors.OnlyPeriphery();

        // Use the CREATE2 opcode to deploy a new Adapter contract.
        // This will revert if a MockCropsAdapter with the provided target has already
        // been deployed, as the salt would be the same and we can't deploy with it twice.
        BaseAdapter.AdapterParams memory adapterParams = BaseAdapter.AdapterParams({
            oracle: factoryParams.oracle,
            stake: factoryParams.stake,
            stakeSize: factoryParams.stakeSize,
            minm: factoryParams.minm,
            maxm: factoryParams.maxm,
            mode: factoryParams.mode,
            tilt: factoryParams.tilt,
            level: DEFAULT_LEVEL
        });

        adapter = address(
            new MockCropAdapter{ salt: _target.fillLast12Bytes() }(
                divider,
                _target,
                MockTargetLike(_target).underlying(),
                rewardsRecipient,
                factoryParams.ifee,
                adapterParams,
                reward
            )
        );

        _setGuard(adapter);

        ExtractableReward(adapter).setIsTrusted(restrictedAdmin, true);
    }
}

contract MockCropsFactory is BaseFactory {
    using Bytes32AddressLib for address;

    mapping(address => bool) public targets;
    address[] rewardTokens;

    constructor(
        address _divider,
        address _restrictedAdmin,
        address _rewardsRecipient,
        BaseFactory.FactoryParams memory _factoryParams,
        address[] memory _rewardTokens
    ) BaseFactory(_divider, _restrictedAdmin, _rewardsRecipient, _factoryParams) {
        rewardTokens = _rewardTokens;
    }

    function supportTarget(address _target, bool status) external {
        targets[_target] = status;
    }

    function deployAdapter(address _target, bytes memory data) external override returns (address adapter) {
        if (!targets[_target]) revert Errors.TargetNotSupported();
        if (Divider(divider).periphery() != msg.sender) revert Errors.OnlyPeriphery();

        // Use the CREATE2 opcode to deploy a new Adapter contract.
        // This will revert if a MockCropsAdapter with the provided target has already
        // been deployed, as the salt would be the same and we can't deploy with it twice.
        BaseAdapter.AdapterParams memory adapterParams = BaseAdapter.AdapterParams({
            oracle: factoryParams.oracle,
            stake: factoryParams.stake,
            stakeSize: factoryParams.stakeSize,
            minm: factoryParams.minm,
            maxm: factoryParams.maxm,
            mode: factoryParams.mode,
            tilt: factoryParams.tilt,
            level: DEFAULT_LEVEL
        });

        adapter = address(
            new MockCropsAdapter{ salt: _target.fillLast12Bytes() }(
                divider,
                _target,
                MockTargetLike(_target).underlying(),
                rewardsRecipient,
                factoryParams.ifee,
                adapterParams,
                rewardTokens
            )
        );

        _setGuard(adapter);

        ExtractableReward(adapter).setIsTrusted(restrictedAdmin, true);
    }
}

// -- 4626 factories -- //

contract Mock4626CropFactory is CropFactory {
    using Bytes32AddressLib for address;

    mapping(address => bool) public targets;
    bool public is4626Target;

    constructor(
        address _divider,
        address _restrictedAdmin,
        address _rewardsRecipient,
        BaseFactory.FactoryParams memory _factoryParams,
        address _reward
    ) CropFactory(_divider, _restrictedAdmin, _rewardsRecipient, _factoryParams, _reward) {}

    function supportTarget(address _target, bool status) external {
        targets[_target] = status;
    }

    function deployAdapter(address _target, bytes memory data) external virtual override returns (address adapter) {
        if (!targets[_target]) revert Errors.TargetNotSupported();
        if (Divider(divider).periphery() != msg.sender) revert Errors.OnlyPeriphery();

        // Use the CREATE2 opcode to deploy a new Adapter contract.
        // This will revert if a MockAdapter with the provided target has already
        // been deployed, as the salt would be the same and we can't deploy with it twice.
        BaseAdapter.AdapterParams memory adapterParams = BaseAdapter.AdapterParams({
            oracle: factoryParams.oracle,
            stake: factoryParams.stake,
            stakeSize: factoryParams.stakeSize,
            minm: factoryParams.minm,
            maxm: factoryParams.maxm,
            mode: factoryParams.mode,
            tilt: factoryParams.tilt,
            level: DEFAULT_LEVEL
        });

        adapter = address(
            new Mock4626CropAdapter{ salt: _target.fillLast12Bytes() }(
                divider,
                _target,
                MockTargetLike(_target).asset(),
                rewardsRecipient,
                factoryParams.ifee,
                adapterParams,
                reward
            )
        );

        ExtractableReward(adapter).setIsTrusted(restrictedAdmin, true);
    }
}

contract Mock4626CropsFactory is BaseFactory {
    using Bytes32AddressLib for address;

    mapping(address => bool) public targets;
    address[] rewardTokens;

    constructor(
        address _divider,
        address _restrictedAdmin,
        address _rewardsRecipient,
        BaseFactory.FactoryParams memory _factoryParams,
        address[] memory _rewardTokens
    ) BaseFactory(_divider, _restrictedAdmin, _rewardsRecipient, _factoryParams) {
        rewardTokens = _rewardTokens;
    }

    function supportTarget(address _target, bool status) external {
        targets[_target] = status;
    }

    function deployAdapter(address _target, bytes memory data) external override returns (address adapter) {
        if (!targets[_target]) revert Errors.TargetNotSupported();
        if (Divider(divider).periphery() != msg.sender) revert Errors.OnlyPeriphery();

        // Use the CREATE2 opcode to deploy a new Adapter contract.
        // This will revert if a MockCropsAdapter with the provided target has already
        // been deployed, as the salt would be the same and we can't deploy with it twice.
        BaseAdapter.AdapterParams memory adapterParams = BaseAdapter.AdapterParams({
            oracle: factoryParams.oracle,
            stake: factoryParams.stake,
            stakeSize: factoryParams.stakeSize,
            minm: factoryParams.minm,
            maxm: factoryParams.maxm,
            mode: factoryParams.mode,
            tilt: factoryParams.tilt,
            level: DEFAULT_LEVEL
        });

        adapter = address(
            new Mock4626CropsAdapter{ salt: _target.fillLast12Bytes() }(
                divider,
                _target,
                MockTargetLike(_target).asset(),
                rewardsRecipient,
                factoryParams.ifee,
                adapterParams,
                rewardTokens
            )
        );

        _setGuard(adapter);

        ExtractableReward(adapter).setIsTrusted(restrictedAdmin, true);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// External references
import { MockToken, AuthdMockToken, MockNonERC20Token } from "./MockToken.sol";
import { ERC20 as ZeppelinERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockTarget is MockToken {
    address public underlying;

    constructor(
        address _underlying,
        string memory _name,
        string memory _symbol,
        uint8 _decimal
    ) MockToken(_name, _symbol, _decimal) {
        underlying = _underlying;
    }
}

contract AuthdMockTarget is AuthdMockToken {
    address public underlying;

    constructor(
        address _underlying,
        string memory _name,
        string memory _symbol,
        uint8 _decimal
    ) AuthdMockToken(_name, _symbol, _decimal) {
        underlying = _underlying;
    }
}

contract MockNonERC20Target is MockNonERC20Token {
    address public underlying;

    constructor(
        address _underlying,
        string memory _name,
        string memory _symbol,
        uint8 _decimal
    ) MockNonERC20Token(_name, _symbol, _decimal) {
        underlying = _underlying;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// External references
import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";

// Internal references
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { BaseAdapter } from "../../abstract/BaseAdapter.sol";
import { Crop } from "../../abstract/extensions/Crop.sol";
import { ExtractableReward } from "../../abstract/extensions/ExtractableReward.sol";

interface WETHLike {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

interface CTokenLike {
    /// @notice cToken is convertible into an ever increasing quantity of the underlying asset, as interest accrues in
    /// the market. This function returns the exchange rate between a cToken and the underlying asset.
    /// @dev returns the current exchange rate as an uint, scaled by 1 * 10^(18 - 8 + Underlying Token Decimals).
    function exchangeRateCurrent() external returns (uint256);

    /// @notice Calculates the exchange rate from the underlying to the CToken
    /// @dev This function does not accrue interest before calculating the exchange rate
    /// @return Calculated exchange rate scaled by 1e18
    function exchangeRateStored() external view returns (uint256);

    function decimals() external view returns (uint8);

    function underlying() external view returns (address);

    /// The mint function transfers an asset into the protocol, which begins accumulating interest based
    /// on the current Supply Rate for the asset. The user receives a quantity of cTokens equal to the
    /// underlying tokens supplied, divided by the current Exchange Rate.
    /// @param mintAmount The amount of the asset to be supplied, in units of the underlying asset.
    /// @return 0 on success, otherwise an Error code
    function mint(uint256 mintAmount) external returns (uint256);

    /// The redeem function converts a specified quantity of cTokens into the underlying asset, and returns
    /// them to the user. The amount of underlying tokens received is equal to the quantity of cTokens redeemed,
    /// multiplied by the current Exchange Rate. The amount redeemed must be less than the user's Account Liquidity
    /// and the market's available liquidity.
    /// @param redeemTokens The number of cTokens to be redeemed.
    /// @return 0 on success, otherwise an Error code
    function redeem(uint256 redeemTokens) external returns (uint256);
}

interface CETHTokenLike {
    ///@notice Send Ether to CEther to mint
    function mint() external payable;
}

interface ComptrollerLike {
    /// @notice Claim all the comp accrued by holder in the specified markets
    /// @param holder The address to claim COMP for
    /// @param cTokens The list of markets to claim COMP in
    function claimComp(address holder, address[] memory cTokens) external;

    function markets(address target)
        external
        returns (
            bool isListed,
            uint256 collateralFactorMantissa,
            bool isComped
        );

    function oracle() external returns (address);
}

interface PriceOracleLike {
    /// @notice Get the price of an underlying asset.
    /// @param target The target asset to get the underlying price of.
    /// @return The underlying asset price in ETH as a mantissa (scaled by 1e18).
    /// Zero means the price is unavailable.
    function getUnderlyingPrice(address target) external view returns (uint256);

    function price(address underlying) external view returns (uint256);
}

/// @notice Adapter contract for cTokens
contract CAdapter is BaseAdapter, Crop, ExtractableReward {
    using SafeTransferLib for ERC20;

    address public constant COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant CETH = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    bool public immutable isCETH;
    uint8 public immutable uDecimals;

    uint256 internal lastRewardedBlock;

    constructor(
        address _divider,
        address _target,
        address _underlying,
        address _rewardsRecipient,
        uint128 _ifee,
        AdapterParams memory _adapterParams,
        address _reward
    )
        Crop(_divider, _reward)
        BaseAdapter(_divider, _target, _underlying, _ifee, _adapterParams)
        ExtractableReward(_rewardsRecipient)
    {
        isCETH = _target == CETH;
        ERC20(_underlying).safeApprove(_target, type(uint256).max);
        uDecimals = CTokenLike(_underlying).decimals();
    }

    function notify(
        address _usr,
        uint256 amt,
        bool join
    ) public override(BaseAdapter, Crop) {
        super.notify(_usr, amt, join);
    }

    /// @return Exchange rate from Target to Underlying using Compound's `exchangeRateCurrent()`, normed to 18 decimals
    function scale() external override returns (uint256) {
        uint256 exRate = CTokenLike(target).exchangeRateCurrent();
        return _to18Decimals(exRate);
    }

    function scaleStored() external view override returns (uint256) {
        uint256 exRate = CTokenLike(target).exchangeRateStored();
        return _to18Decimals(exRate);
    }

    function _claimReward() internal virtual override {
        // Avoid calling _claimReward more than once per block
        if (lastRewardedBlock != block.number) {
            lastRewardedBlock = block.number;
            address[] memory cTokens = new address[](1);
            cTokens[0] = target;
            ComptrollerLike(COMPTROLLER).claimComp(address(this), cTokens);
        }
    }

    function getUnderlyingPrice() external view override returns (uint256 price) {
        price = isCETH ? 1e18 : PriceOracleLike(adapterParams.oracle).price(underlying);
    }

    function wrapUnderlying(uint256 uBal) external override returns (uint256 tBal) {
        ERC20 t = ERC20(target);

        ERC20(underlying).safeTransferFrom(msg.sender, address(this), uBal); // pull underlying
        if (isCETH) WETHLike(WETH).withdraw(uBal); // unwrap WETH into ETH

        // Mint target
        uint256 tBalBefore = t.balanceOf(address(this));
        if (isCETH) {
            CETHTokenLike(target).mint{ value: uBal }();
        } else {
            if (CTokenLike(target).mint(uBal) != 0) revert Errors.MintFailed();
        }
        uint256 tBalAfter = t.balanceOf(address(this));

        // Transfer target to sender
        t.safeTransfer(msg.sender, tBal = tBalAfter - tBalBefore);
    }

    function unwrapTarget(uint256 tBal) external override returns (uint256 uBal) {
        ERC20 u = ERC20(underlying);
        ERC20(target).safeTransferFrom(msg.sender, address(this), tBal); // pull target

        // Redeem target for underlying
        uint256 uBalBefore = isCETH ? address(this).balance : u.balanceOf(address(this));
        if (CTokenLike(target).redeem(tBal) != 0) revert Errors.RedeemFailed();
        uint256 uBalAfter = isCETH ? address(this).balance : u.balanceOf(address(this));
        unchecked {
            uBal = uBalAfter - uBalBefore;
        }

        if (isCETH) {
            // Deposit ETH into WETH contract
            (bool success, ) = WETH.call{ value: uBal }("");
            if (!success) revert Errors.TransferFailed();
        }

        // Transfer underlying to sender
        ERC20(underlying).safeTransfer(msg.sender, uBal);
    }

    function _isValid(address _token) internal override returns (bool) {
        return (_token != target && _token != adapterParams.stake && _token != reward);
    }

    function _to18Decimals(uint256 exRate) internal view returns (uint256) {
        // From the Compound docs:
        // "exchangeRateCurrent() returns the exchange rate, scaled by 1 * 10^(18 - 8 + Underlying Token Decimals)"
        //
        // The equation to norm an asset to 18 decimals is:
        // `num * 10**(18 - decimals)`
        //
        // So, when we try to norm exRate to 18 decimals, we get the following:
        // `exRate * 10**(18 - exRateDecimals)`
        // -> `exRate * 10**(18 - (18 - 8 + uDecimals))`
        // -> `exRate * 10**(8 - uDecimals)`
        // -> `exRate / 10**(uDecimals - 8)`
        return uDecimals >= 8 ? exRate / 10**(uDecimals - 8) : exRate * 10**(8 - uDecimals);
    }

    fallback() external payable {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// External references
import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";

// Internal references
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { Crops } from "../../abstract/extensions/Crops.sol";
import { ExtractableReward } from "../../abstract/extensions/ExtractableReward.sol";
import { BaseAdapter } from "../../abstract/BaseAdapter.sol";
import { CTokenLike } from "../compound/CAdapter.sol";

interface WETHLike {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

interface FETHTokenLike {
    ///@notice Send Ether to CEther to mint
    function mint() external payable;
}

interface FTokenLike {
    function isCEther() external view returns (bool);
}

interface FComptrollerLike {
    function markets(address target) external returns (bool isListed, uint256 collateralFactorMantissa);

    function oracle() external returns (address);

    function getRewardsDistributors() external view returns (address[] memory);
}

interface RewardsDistributorLike {
    ///
    /// @notice Claim all the rewards accrued by holder in the specified markets
    /// @param holder The address to claim rewards for
    ///
    function claimRewards(address holder) external;

    function marketState(address marker) external view returns (uint224 index, uint32 lastUpdatedTimestamp);

    function rewardToken() external view returns (address rewardToken);
}

interface PriceOracleLike {
    /// @notice Get the price of an underlying asset.
    /// @param target The target asset to get the underlying price of.
    /// @return The underlying asset price in ETH as a mantissa (scaled by 1e18).
    /// Zero means the price is unavailable.
    function getUnderlyingPrice(address target) external view returns (uint256);

    function price(address underlying) external view returns (uint256);
}

/// @notice Adapter contract for fTokens
contract FAdapter is BaseAdapter, Crops, ExtractableReward {
    using SafeTransferLib for ERC20;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant FETH = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    mapping(address => address) public rewardsDistributorsList; // rewards distributors for reward token

    address public immutable comptroller;
    bool public immutable isFETH;
    uint8 public immutable uDecimals;

    uint256 internal lastRewardedBlock;

    constructor(
        address _divider,
        address _target,
        address _underlying,
        address _rewardsRecipient,
        uint128 _ifee,
        address _comptroller,
        AdapterParams memory _adapterParams,
        address[] memory _rewardTokens,
        address[] memory _rewardsDistributorsList
    )
        Crops(_divider, _rewardTokens)
        BaseAdapter(_divider, _target, _underlying, _ifee, _adapterParams)
        ExtractableReward(_rewardsRecipient)
    {
        rewardTokens = _rewardTokens;
        comptroller = _comptroller;
        isFETH = FTokenLike(_target).isCEther();

        ERC20(_underlying).safeApprove(_target, type(uint256).max);
        uDecimals = CTokenLike(_underlying).decimals();

        // Initialize rewardsDistributorsList mapping
        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            rewardsDistributorsList[_rewardTokens[i]] = _rewardsDistributorsList[i];
        }
    }

    function notify(
        address _usr,
        uint256 amt,
        bool join
    ) public override(BaseAdapter, Crops) {
        super.notify(_usr, amt, join);
    }

    /// @return Exchange rate from Target to Underlying using Compound's `exchangeRateCurrent()`, normed to 18 decimals
    function scale() external override returns (uint256) {
        uint256 exRate = CTokenLike(target).exchangeRateCurrent();
        return _to18Decimals(exRate);
    }

    function scaleStored() external view override returns (uint256) {
        uint256 exRate = CTokenLike(target).exchangeRateStored();
        return _to18Decimals(exRate);
    }

    function _claimRewards() internal virtual override {
        // Avoid calling _claimRewards more than once per block
        if (lastRewardedBlock != block.number) {
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                if (rewardTokens[i] != address(0))
                    RewardsDistributorLike(rewardsDistributorsList[rewardTokens[i]]).claimRewards(address(this));
            }
        }
    }

    function getUnderlyingPrice() external view override returns (uint256 price) {
        price = isFETH ? 1e18 : PriceOracleLike(adapterParams.oracle).price(underlying);
    }

    function wrapUnderlying(uint256 uBal) external override returns (uint256 tBal) {
        ERC20 t = ERC20(target);

        ERC20(underlying).safeTransferFrom(msg.sender, address(this), uBal); // pull underlying
        if (isFETH) WETHLike(WETH).withdraw(uBal); // unwrap WETH into ETH

        // Mint target
        uint256 tBalBefore = t.balanceOf(address(this));
        if (isFETH) {
            FETHTokenLike(target).mint{ value: uBal }();
        } else {
            if (CTokenLike(target).mint(uBal) != 0) revert Errors.MintFailed();
        }
        uint256 tBalAfter = t.balanceOf(address(this));

        // Transfer target to sender
        t.safeTransfer(msg.sender, tBal = tBalAfter - tBalBefore);
    }

    function unwrapTarget(uint256 tBal) external override returns (uint256 uBal) {
        ERC20 u = ERC20(underlying);
        ERC20(target).safeTransferFrom(msg.sender, address(this), tBal); // pull target

        // Redeem target for underlying
        uint256 uBalBefore = isFETH ? address(this).balance : u.balanceOf(address(this));
        if (CTokenLike(target).redeem(tBal) != 0) revert Errors.RedeemFailed();
        uint256 uBalAfter = isFETH ? address(this).balance : u.balanceOf(address(this));
        unchecked {
            uBal = uBalAfter - uBalBefore;
        }

        if (isFETH) {
            // Deposit ETH into WETH contract
            (bool success, ) = WETH.call{ value: uBal }("");
            if (!success) revert Errors.TransferFailed();
        }

        // Transfer underlying to sender
        ERC20(underlying).safeTransfer(msg.sender, uBal);
    }

    function _isValid(address _token) internal override returns (bool) {
        for (uint256 i = 0; i < rewardTokens.length; ) {
            if (_token == rewardTokens[i]) return false;
            unchecked {
                ++i;
            }
        }

        // Check that token is neither the target nor the stake
        return (_token != target && _token != adapterParams.stake);
    }

    /* ========== ADMIN ========== */

    /// @notice Overrides both the rewardTokens and the rewardsDistributorsList arrays.
    /// @param _rewardTokens New reward tokens array
    /// @param _rewardsDistributorsList New rewards distributors list array
    function setRewardTokens(address[] memory _rewardTokens, address[] memory _rewardsDistributorsList)
        public
        virtual
        requiresTrust
    {
        super.setRewardTokens(_rewardTokens);
        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            rewardsDistributorsList[_rewardTokens[i]] = _rewardsDistributorsList[i];
        }
        emit RewardsDistributorsChanged(_rewardsDistributorsList);
    }

    /* ========== INTERNAL UTILS ========== */

    function _to18Decimals(uint256 exRate) internal view returns (uint256) {
        // From the Compound docs:
        // "exchangeRateCurrent() returns the exchange rate, scaled by 1 * 10^(18 - 8 + Underlying Token Decimals)"
        //
        // The equation to norm an asset to 18 decimals is:
        // `num * 10**(18 - decimals)`
        //
        // So, when we try to norm exRate to 18 decimals, we get the following:
        // `exRate * 10**(18 - exRateDecimals)`
        // -> `exRate * 10**(18 - (18 - 8 + uDecimals))`
        // -> `exRate * 10**(8 - uDecimals)`
        // -> `exRate / 10**(uDecimals - 8)`
        return uDecimals >= 8 ? exRate / 10**(uDecimals - 8) : exRate * 10**(8 - uDecimals);
    }

    /* ========== LOGS ========== */

    event RewardsDistributorsChanged(address[] indexed rewardsDistributorsList);

    /* ========== FALLBACK ========== */

    fallback() external payable {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import { PriceOracle } from "@sense-finance/v1-fuse/src/external/PriceOracle.sol";
import { CToken } from "@sense-finance/v1-fuse/src/external/CToken.sol";

contract MockOracle is PriceOracle {
    uint256 public _price = 1e18;

    function getUnderlyingPrice(CToken) external view override returns (uint256) {
        return _price;
    }

    function price(address) external view override returns (uint256) {
        return _price;
    }

    function setPrice(uint256 price_) external {
        _price = price_;
    }

    function initialize(
        address[] memory,
        PriceOracle[] memory,
        PriceOracle,
        address,
        bool
    ) external {
        return;
    }

    function add(address[] calldata underlyings, PriceOracle[] calldata _oracles) external {
        return;
    }

    function setZero(address zero, address pool) external {
        return;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// External references
import { ERC20 } from "solmate/src/tokens/ERC20.sol";

contract MockComptroller {
    mapping(address => address) public ctokens;
    mapping(address => address) public underlyings;
    uint256 public nonce;

    struct Market {
        bool isListed;
        uint256 collateralFactorMantissa;
    }

    function _deployMarket(
        bool isCEther,
        bytes calldata constructorData,
        uint256 collateralFactorMantissa
    ) external virtual returns (uint256) {
        (address token, , , , , , , , ) = abi.decode(
            constructorData,
            (address, address, address, string, string, address, bytes, uint256, uint256)
        );
        require(ctokens[token] == address(0));
        ctokens[token] = address(uint160(uint256(keccak256(abi.encodePacked(++nonce, blockhash(block.number))))));
        underlyings[ctokens[token]] = token;
        return 0;
    }

    function _acceptAdmin() external virtual returns (uint256) {
        return 0;
    }

    function cTokensByUnderlying(address token) external virtual returns (address) {
        if (ctokens[token] != address(0)) {
            return ctokens[token];
        }
        return address(0);
    }

    function markets(address token) external virtual returns (Market memory) {
        return Market({ isListed: underlyings[token] != address(0), collateralFactorMantissa: 0 });
    }
}

contract MockComptrollerRejectAdmin is MockComptroller {
    function _acceptAdmin() external override returns (uint256) {
        return 1;
    }
}

contract MockComptrollerFailAddMarket is MockComptroller {
    function _deployMarket(
        bool isCEther,
        bytes calldata constructorData,
        uint256 collateralFactorMantissa
    ) external override returns (uint256) {
        return 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// External references
import { ERC20 } from "solmate/src/tokens/ERC20.sol";

contract MockFuseDirectory {
    address public comptroller;

    constructor(address _comptroller) {
        comptroller = _comptroller;
    }

    function deployPool(
        string memory name,
        address implementation,
        bool enforceWhitelist,
        uint256 closeFactor,
        uint256 liquidationIncentive,
        address priceOracle
    ) external returns (uint256, address) {
        return (0, comptroller);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { ERC4626 } from "solmate/src/mixins/ERC4626.sol";
import { IEulerMarkets } from "../../../../../../lib/yield-daddy/src/euler/external/IEulerMarkets.sol";
import { IEulerEToken } from "../../../../../../lib/yield-daddy/src/euler/external/IEulerEToken.sol";
import { EulerERC4626Factory } from "../../../../../../lib/yield-daddy/src/euler/EulerERC4626Factory.sol";
import { ERC4626Factory } from "../../../../../../lib/yield-daddy/src/base/ERC4626Factory.sol";

import { EulerERC4626 } from "./EulerERC4626.sol";
import { ERC4626WrapperFactory } from "../base/ERC4626WrapperFactory.sol";

/// @title EulerERC4626WrapperFactory
/// @author Yield Daddy (Timeless Finance)
/// @notice This is NOT an adapter factory, it is a wrapper factory which allows one to
/// create ERC4626 wrappers for eTokens (Euler tokens)
contract EulerERC4626WrapperFactory is EulerERC4626Factory, ERC4626WrapperFactory {
    constructor(
        address _euler,
        IEulerMarkets _markets,
        address _restrictedAdmin,
        address _rewardsRecipient
    ) EulerERC4626Factory(_euler, _markets) ERC4626WrapperFactory(_restrictedAdmin, _rewardsRecipient) {}

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    function createERC4626(ERC20 asset)
        external
        virtual
        override(EulerERC4626Factory, ERC4626Factory)
        returns (ERC4626 vault)
    {
        address eTokenAddress = markets.underlyingToEToken(address(asset));
        if (eTokenAddress == address(0)) {
            revert EulerERC4626Factory__ETokenNonexistent();
        }

        vault = new EulerERC4626{ salt: bytes32(0) }(asset, euler, IEulerEToken(eTokenAddress), rewardsRecipient);
        EulerERC4626(address(vault)).setIsTrusted(restrictedAdmin, true);

        emit CreateERC4626(asset, vault);
    }

    function computeERC4626Address(ERC20 asset)
        external
        view
        virtual
        override(EulerERC4626Factory, ERC4626Factory)
        returns (ERC4626 vault)
    {
        vault = ERC4626(
            _computeCreate2Address(
                keccak256(
                    abi.encodePacked(
                        // Deployment bytecode:
                        type(EulerERC4626).creationCode,
                        // Constructor arguments:
                        abi.encode(
                            asset,
                            euler,
                            IEulerEToken(markets.underlyingToEToken(address(asset))),
                            rewardsRecipient
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

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
        ERC20 token,
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
                // returned exactly 1 (not just any non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the addition in the
                // order of operations or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
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
                // returned exactly 1 (not just any non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the addition in the
                // order of operations or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
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
                // returned exactly 1 (not just any non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the addition in the
                // order of operations or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
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

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(4, from) // Append the "from" argument.
            mstore(36, to) // Append the "to" argument.
            mstore(68, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because that's the total length of our calldata (4 + 32 * 3)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 100, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;

/// @notice Ultra minimal authorization logic for smart contracts.
/// @author From https://github.com/Rari-Capital/solmate/blob/fab107565a51674f3a3b5bfdaacc67f6179b1a9b/src/auth/Trust.sol
abstract contract Trust {
    event UserTrustUpdated(address indexed user, bool trusted);

    mapping(address => bool) public isTrusted;

    constructor(address initialUser) {
        isTrusted[initialUser] = true;

        emit UserTrustUpdated(initialUser, true);
    }

    function setIsTrusted(address user, bool trusted) public virtual requiresTrust {
        isTrusted[user] = trusted;

        emit UserTrustUpdated(user, trusted);
    }

    modifier requiresTrust() {
        require(isTrusted[msg.sender], "UNTRUSTED");

        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

library Errors {
    // Auth
    error CombineRestricted();
    error IssuanceRestricted();
    error NotAuthorized();
    error OnlyYT();
    error OnlyDivider();
    error OnlyPeriphery();
    error OnlyPermissionless();
    error RedeemRestricted();
    error Untrusted();

    // Adapters
    error TokenNotSupported();
    error FlashCallbackFailed();
    error SenderNotEligible();
    error TargetMismatch();
    error TargetNotSupported();
    error InvalidAdapterType();
    error PriceOracleNotFound();

    // Divider
    error AlreadySettled();
    error CollectNotSettled();
    error GuardCapReached();
    error IssuanceFeeCapExceeded();
    error IssueOnSettle();
    error NotSettled();

    // Input & validations
    error AlreadyInitialized();
    error DuplicateSeries();
    error ExistingValue();
    error InvalidAdapter();
    error InvalidMaturity();
    error InvalidParam();
    error NotImplemented();
    error OutOfWindowBoundaries();
    error SeriesDoesNotExist();
    error SwapTooSmall();
    error TargetParamsNotSet();
    error PoolParamsNotSet();
    error PTParamsNotSet();
    error AttemptFailed();
    error InvalidPrice();
    error BadContractInteration();

    // Periphery
    error FactoryNotSupported();
    error FlashBorrowFailed();
    error FlashUntrustedBorrower();
    error FlashUntrustedLoanInitiator();
    error UnexpectedSwapAmount();
    error TooMuchLeftoverTarget();

    // Fuse
    error AdapterNotSet();
    error FailedBecomeAdmin();
    error FailedAddTargetMarket();
    error FailedToAddPTMarket();
    error FailedAddLpMarket();
    error OracleNotReady();
    error PoolAlreadyDeployed();
    error PoolNotDeployed();
    error PoolNotSet();
    error SeriesNotQueued();
    error TargetExists();
    error TargetNotInFuse();

    // Tokens
    error MintFailed();
    error RedeemFailed();
    error TransferFailed();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// External references
import { ERC20 } from "solmate/src/tokens/ERC20.sol";

// Internal references
import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";

/// @title Base Token
contract Token is ERC20, Trust {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _trusted
    ) ERC20(_name, _symbol, _decimals) Trust(_trusted) {}

    /// @param usr The address to send the minted tokens
    /// @param amount The amount to be minted
    function mint(address usr, uint256 amount) public requiresTrust {
        _mint(usr, amount);
    }

    /// @param usr The address from where to burn tokens from
    /// @param amount The amount to be burned
    function burn(address usr, uint256 amount) public requiresTrust {
        _burn(usr, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;

library Levels {
    uint256 private constant _INIT_BIT = 0x1;
    uint256 private constant _ISSUE_BIT = 0x2;
    uint256 private constant _COMBINE_BIT = 0x4;
    uint256 private constant _COLLECT_BIT = 0x8;
    uint256 private constant _REDEEM_BIT = 0x10;
    uint256 private constant _REDEEM_HOOK_BIT = 0x20;

    function initRestricted(uint256 level) internal pure returns (bool) {
        return level & _INIT_BIT != _INIT_BIT;
    }

    function issueRestricted(uint256 level) internal pure returns (bool) {
        return level & _ISSUE_BIT != _ISSUE_BIT;
    }

    function combineRestricted(uint256 level) internal pure returns (bool) {
        return level & _COMBINE_BIT != _COMBINE_BIT;
    }

    function collectDisabled(uint256 level) internal pure returns (bool) {
        return level & _COLLECT_BIT != _COLLECT_BIT;
    }

    function redeemRestricted(uint256 level) internal pure returns (bool) {
        return level & _REDEEM_BIT != _REDEEM_BIT;
    }

    function redeemHookDisabled(uint256 level) internal pure returns (bool) {
        return level & _REDEEM_HOOK_BIT != _REDEEM_HOOK_BIT;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

/// @title Fixed point arithmetic library
/// @author Taken from https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol
library FixedMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256) {
        return mulDivDown(x, y, baseUnit); // Equivalent to (x * y) / baseUnit rounded down.
    }

    function fmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function fmulUp(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256) {
        return mulDivUp(x, y, baseUnit); // Equivalent to (x * y) / baseUnit rounded up.
    }

    function fmulUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256) {
        return mulDivDown(x, baseUnit, y); // Equivalent to (x * baseUnit) / y rounded down.
    }

    function fdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function fdivUp(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256) {
        return mulDivUp(x, baseUnit, y); // Equivalent to (x * baseUnit) / y rounded up.
    }

    function fdivUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }
}

pragma solidity 0.8.15;

/// @author Taken from: https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
library DateTime {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day,
            uint256 hour,
            uint256 minute,
            uint256 second
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function toDateString(uint256 _timestamp)
        internal
        pure
        returns (
            string memory d,
            string memory m,
            string memory y
        )
    {
        (uint256 year, uint256 month, uint256 day) = timestampToDate(_timestamp);
        d = uintToString(day);
        m = uintToString(month);
        y = uintToString(year);
        // append a 0 to numbers < 10 so we should, e.g, 01 instead of just 1
        if (day < 10) d = string(abi.encodePacked("0", d));
        if (month < 10) m = string(abi.encodePacked("0", m));
    }

    function format(uint256 _timestamp) internal pure returns (string memory datestring) {
        string[12] memory months = [
            "Jan",
            "Feb",
            "Mar",
            "Apr",
            "May",
            "June",
            "July",
            "Aug",
            "Sept",
            "Oct",
            "Nov",
            "Dec"
        ];
        (uint256 year, uint256 month, uint256 day) = timestampToDate(_timestamp);
        uint256 last = day % 10;
        string memory suffix = "th";
        if (day < 11 || day > 20) {
            if (last == 1) suffix = "st";
            if (last == 2) suffix = "nd";
            if (last == 3) suffix = "rd";
        }
        return string(abi.encodePacked(uintToString(day), suffix, " ", months[month - 1], " ", uintToString(year)));
    }

    function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    /// Taken from https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity
    function uintToString(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day -
            32075 +
            (1461 * (_year + 4800 + (_month - 14) / 12)) /
            4 +
            (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
            12 -
            (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
            4 -
            OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// Internal references
import { Divider } from "../Divider.sol";
import { Token } from "./Token.sol";

/// @title Yield Token
/// @notice Strips off excess before every transfer
contract YT is Token {
    address public immutable adapter;
    address public immutable divider;
    uint256 public immutable maturity;

    constructor(
        address _adapter,
        uint256 _maturity,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _divider
    ) Token(_name, _symbol, _decimals, _divider) {
        adapter = _adapter;
        maturity = _maturity;
        divider = _divider;
    }

    function collect() external returns (uint256 _collected) {
        return Divider(divider).collect(msg.sender, adapter, maturity, 0, address(0));
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        Divider(divider).collect(msg.sender, adapter, maturity, value, to);
        return super.transfer(to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        if (value > 0) Divider(divider).collect(from, adapter, maturity, value, to);
        return super.transferFrom(from, to, value);
    }
}

pragma solidity ^0.8.0;

interface IERC3156FlashBorrower {
    /// @dev Receive a flash loan.
    /// @param initiator The initiator of the loan.
    /// @param token The loan currency.
    /// @param amount The amount of tokens lent.
    /// @param fee The additional amount of tokens to repay.
    /// @param data Arbitrary data structure, intended to contain user-defined parameters.
    /// @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

pragma solidity ^0.8.0;
import "./IERC3156FlashBorrower.sol";

interface IERC3156FlashLender {
    /// @dev The amount of currency available to be lent.
    /// @param token The loan currency.
    /// @return The amount of `token` that can be borrowed.
    function maxFlashLoan(address token) external view returns (uint256);

    /// @dev The fee to be charged for a given loan.
    /// @param token The loan currency.
    /// @param amount The amount of tokens lent.
    /// @return The amount of `token` to be charged for the loan, on top of the returned principal.
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /// @dev Initiate a flash loan.
    /// @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
    /// @param token The loan currency.
    /// @param amount The amount of tokens lent.
    /// @param data Arbitrary data structure, intended to contain user-defined parameters.
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// External references
import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";

// Internal references
import { Divider } from "../../../Divider.sol";
import { BaseAdapter } from "../BaseAdapter.sol";
import { IClaimer } from "../IClaimer.sol";
import { FixedMath } from "../../../external/FixedMath.sol";
import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";

/// @notice This is meant to be used with BaseAdapter.sol
abstract contract Crop is Trust {
    using SafeTransferLib for ERC20;
    using FixedMath for uint256;

    /// @notice Program state
    address public claimer; // claimer address
    address public reward;
    uint256 public shares; // accumulated reward token per collected target
    uint256 public rewardBal; // last recorded balance of reward token
    uint256 public totalTarget; // total target accumulated by all users
    mapping(address => uint256) public tBalance; // target balance per user
    mapping(address => uint256) public rewarded; // reward token per user
    mapping(address => uint256) public reconciledAmt; // reconciled target amount per user
    mapping(address => mapping(uint256 => bool)) public reconciled; // whether a user has been reconciled for a given maturity

    constructor(address _divider, address _reward) {
        setIsTrusted(_divider, true);
        reward = _reward;
    }

    /// @notice Distribute the rewards tokens to the user according to their shares
    /// @dev The reconcile amount allows us to prevent diluting other users' rewards
    function notify(
        address _usr,
        uint256 amt,
        bool join
    ) public virtual requiresTrust {
        _distribute(_usr);
        if (amt > 0) {
            if (join) {
                totalTarget += amt;
                tBalance[_usr] += amt;
            } else {
                uint256 uReconciledAmt = reconciledAmt[_usr];
                if (uReconciledAmt > 0) {
                    if (amt < uReconciledAmt) {
                        unchecked {
                            uReconciledAmt -= amt;
                        }
                        amt = 0;
                    } else {
                        unchecked {
                            amt -= uReconciledAmt;
                        }
                        uReconciledAmt = 0;
                    }
                    reconciledAmt[_usr] = uReconciledAmt;
                }
                if (amt > 0) {
                    totalTarget -= amt;
                    tBalance[_usr] -= amt;
                }
            }
        }
        rewarded[_usr] = tBalance[_usr].fmulUp(shares, FixedMath.RAY);
    }

    /// @notice Reconciles users target balances to zero by distributing rewards on their holdings,
    /// to avoid dilution of next Series' YT holders.
    /// This function should be called right after a Series matures and will save the user's YT balance
    /// (in target terms) on reconciledAmt[usr]. When `notify()` is triggered, we take that amount and
    /// subtract it from the user's target balance (`tBalance`) which will fix (or reconcile)
    /// his position to prevent dilution.
    /// @param _usrs Users to reconcile
    /// @param _maturities Maturities of the series that we want to reconcile users on.
    function reconcile(address[] calldata _usrs, uint256[] calldata _maturities) public {
        Divider divider = Divider(BaseAdapter(address(this)).divider());
        for (uint256 j = 0; j < _maturities.length; j++) {
            for (uint256 i = 0; i < _usrs.length; i++) {
                address usr = _usrs[i];
                uint256 ytBal = ERC20(divider.yt(address(this), _maturities[j])).balanceOf(usr);
                // We don't want to reconcile users if maturity has not been reached or if they have already been reconciled
                if (_maturities[j] <= block.timestamp && ytBal > 0 && !reconciled[usr][_maturities[j]]) {
                    _distribute(usr);
                    uint256 tBal = ytBal.fdiv(divider.lscales(address(this), _maturities[j], usr));
                    totalTarget -= tBal;
                    tBalance[usr] -= tBal;
                    reconciledAmt[usr] += tBal; // We increase reconciledAmt with the user's YT balance in target terms
                    reconciled[usr][_maturities[j]] = true;
                    emit Reconciled(usr, tBal, _maturities[j]);
                }
            }
        }
    }

    /// @notice Distributes rewarded tokens to users proportionally based on their `tBalance`
    /// @param _usr User to distribute reward tokens to
    function _distribute(address _usr) internal {
        _claimReward();

        uint256 crop = ERC20(reward).balanceOf(address(this)) - rewardBal;
        if (totalTarget > 0) shares += (crop.fdiv(totalTarget, FixedMath.RAY));

        uint256 last = rewarded[_usr];
        uint256 curr = tBalance[_usr].fmul(shares, FixedMath.RAY);
        if (curr > last) {
            unchecked {
                ERC20(reward).safeTransfer(_usr, curr - last);
            }
        }
        rewardBal = ERC20(reward).balanceOf(address(this));
        emit Distributed(_usr, reward, curr > last ? curr - last : 0);
    }

    /// @notice Some protocols don't airdrop reward tokens, instead users must claim them.
    /// This method may be overriden by child contracts to claim a protocol's rewards
    function _claimReward() internal virtual {
        if (claimer != address(0)) {
            ERC20 target = ERC20(BaseAdapter(address(this)).target());
            uint256 tBal = ERC20(target).balanceOf(address(this));

            if (tBal > 0) {
                // We send all the target balance to the claimer contract to it can claim rewards
                ERC20(target).transfer(claimer, tBal);

                // Make claimer to claim rewards
                IClaimer(claimer).claim();

                // Get the target back
                if (ERC20(target).balanceOf(address(this)) < tBal) revert Errors.BadContractInteration();
            }
        }
    }

    /// @notice Overrides the rewardToken address.
    /// @param _reward New reward token address
    function setRewardToken(address _reward) public requiresTrust {
        _claimReward();
        reward = _reward;
        emit RewardTokenChanged(reward);
    }

    /// @notice Sets `claimer`.
    /// @param _claimer New claimer contract address
    function setClaimer(address _claimer) public requiresTrust {
        claimer = _claimer;
        emit ClaimerChanged(claimer);
    }

    /* ========== LOGS ========== */

    event Distributed(address indexed usr, address indexed token, uint256 amount);
    event Reconciled(address indexed usr, uint256 tBal, uint256 maturity);
    event RewardTokenChanged(address indexed reward);
    event ClaimerChanged(address indexed claimer);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// External references
import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";

// Internal references
import { Divider } from "../../../Divider.sol";
import { BaseAdapter } from "../BaseAdapter.sol";
import { IClaimer } from "../IClaimer.sol";
import { FixedMath } from "../../../external/FixedMath.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";

/// @notice This is meant to be used with BaseAdapter.sol
abstract contract Crops is Trust {
    using SafeTransferLib for ERC20;
    using FixedMath for uint256;

    /// @notice Program state
    address public claimer; // claimer address
    uint256 public totalTarget; // total target accumulated by all users
    mapping(address => uint256) public tBalance; // target balance per user
    mapping(address => uint256) public reconciledAmt; // reconciled target amount per user
    mapping(address => mapping(uint256 => bool)) public reconciled; // whether a user has been reconciled for a given maturity

    address[] public rewardTokens; // reward tokens addresses
    mapping(address => Crop) public data;

    struct Crop {
        // Accumulated reward token per collected target
        uint256 shares;
        // Last recorded balance of reward token
        uint256 rewardBal;
        // Rewarded token per user
        mapping(address => uint256) rewarded;
    }

    constructor(address _divider, address[] memory _rewardTokens) {
        setIsTrusted(_divider, true);
        rewardTokens = _rewardTokens;
    }

    function notify(
        address _usr,
        uint256 amt,
        bool join
    ) public virtual requiresTrust {
        _distribute(_usr);
        if (amt > 0) {
            if (join) {
                totalTarget += amt;
                tBalance[_usr] += amt;
            } else {
                uint256 uReconciledAmt = reconciledAmt[_usr];
                if (uReconciledAmt > 0) {
                    if (amt < uReconciledAmt) {
                        unchecked {
                            uReconciledAmt -= amt;
                        }
                        amt = 0;
                    } else {
                        unchecked {
                            amt -= uReconciledAmt;
                        }
                        uReconciledAmt = 0;
                    }
                    reconciledAmt[_usr] = uReconciledAmt;
                }
                if (amt > 0) {
                    totalTarget -= amt;
                    tBalance[_usr] -= amt;
                }
            }
        }
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            data[rewardTokens[i]].rewarded[_usr] = tBalance[_usr].fmulUp(data[rewardTokens[i]].shares, FixedMath.RAY);
        }
    }

    /// @notice Reconciles users target balances to zero by distributing rewards on their holdings,
    /// to avoid dilution of next Series' YT holders.
    /// This function should be called right after a Series matures and will save the user's YT balance
    /// (in target terms) on reconciledAmt[usr]. When `notify()` is triggered for on a new Series, we will
    /// take that amount and subtract it from the user's target balance (`tBalance`) which will fix (or reconcile)
    /// his position to prevent dilution.
    /// @param _usrs Users to reconcile
    /// @param _maturities Maturities of the series that we want to reconcile users on.
    function reconcile(address[] calldata _usrs, uint256[] calldata _maturities) public {
        Divider divider = Divider(BaseAdapter(address(this)).divider());
        for (uint256 j = 0; j < _maturities.length; j++) {
            for (uint256 i = 0; i < _usrs.length; i++) {
                address usr = _usrs[i];
                uint256 ytBal = ERC20(divider.yt(address(this), _maturities[j])).balanceOf(usr);
                // We don't want to reconcile users if maturity has not been reached or if they have already been reconciled
                if (_maturities[j] <= block.timestamp && ytBal > 0 && !reconciled[usr][_maturities[j]]) {
                    _distribute(usr);
                    uint256 tBal = ytBal.fdiv(divider.lscales(address(this), _maturities[j], usr));
                    totalTarget -= tBal;
                    tBalance[usr] -= tBal;
                    reconciledAmt[usr] += tBal; // We increase reconciledAmt with the user's YT balance in target terms
                    reconciled[usr][_maturities[j]] = true;
                    emit Reconciled(usr, tBal, _maturities[j]);
                }
            }
        }
    }

    /// @notice Distributes rewarded tokens to users proportionally based on their `tBalance`
    /// @param _usr User to distribute reward tokens to
    function _distribute(address _usr) internal {
        _claimRewards();

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            uint256 crop = ERC20(rewardTokens[i]).balanceOf(address(this)) - data[rewardTokens[i]].rewardBal;
            if (totalTarget > 0) data[rewardTokens[i]].shares += (crop.fdiv(totalTarget, FixedMath.RAY));

            uint256 last = data[rewardTokens[i]].rewarded[_usr];
            uint256 curr = tBalance[_usr].fmul(data[rewardTokens[i]].shares, FixedMath.RAY);
            if (curr > last) {
                unchecked {
                    ERC20(rewardTokens[i]).safeTransfer(_usr, curr - last);
                }
            }
            data[rewardTokens[i]].rewardBal = ERC20(rewardTokens[i]).balanceOf(address(this));
            emit Distributed(_usr, rewardTokens[i], curr > last ? curr - last : 0);
        }
    }

    /// @notice Some protocols don't airdrop reward tokens, instead users must claim them.
    /// This method may be overriden by child contracts to claim a protocol's rewards
    function _claimRewards() internal virtual {
        if (claimer != address(0)) {
            ERC20 target = ERC20(BaseAdapter(address(this)).target());
            uint256 tBal = ERC20(target).balanceOf(address(this));

            if (tBal > 0) {
                // We send all the target balance to the claimer contract to it can claim rewards
                ERC20(target).transfer(claimer, tBal);

                // Make claimer to claim rewards
                IClaimer(claimer).claim();

                // Get the target back
                if (ERC20(target).balanceOf(address(this)) < tBal) revert Errors.BadContractInteration();
            }
        }
    }

    /// @notice Overrides the rewardTokens array with a new one.
    /// @dev Calls _claimRewards() in case the new array contains less reward tokens than the old one.
    /// @param _rewardTokens New reward tokens array
    function setRewardTokens(address[] memory _rewardTokens) public requiresTrust {
        _claimRewards();
        rewardTokens = _rewardTokens;
        emit RewardTokensChanged(rewardTokens);
    }

    /// @notice Sets `claimer`.
    /// @param _claimer New claimer contract address
    function setClaimer(address _claimer) public requiresTrust {
        claimer = _claimer;
        emit ClaimerChanged(claimer);
    }

    /* ========== LOGS ========== */

    event Distributed(address indexed usr, address indexed token, uint256 amount);
    event RewardTokensChanged(address[] indexed rewardTokens);
    event Reconciled(address indexed usr, uint256 tBal, uint256 maturity);
    event ClaimerChanged(address indexed claimer);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

interface IClaimer {
    /// @dev Claims rewards on protocol.
    function claim() external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import { ERC20 } from "solmate/src/tokens/ERC20.sol";

interface IAsset {}

interface BalancerVault {
    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }
    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }
    enum PoolSpecialization {
        GENERAL,
        MINIMAL_SWAP_INFO,
        TWO_TOKEN
    }
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            ERC20[] memory tokens,
            uint256[] memory balances,
            uint256 maxBlockNumber
        );

    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { BalancerVault } from "./Vault.sol";

interface BalancerPool {
    function getTimeWeightedAverage(OracleAverageQuery[] memory queries)
        external
        view
        returns (uint256[] memory results);

    enum Variable {
        PAIR_PRICE,
        BPT_PRICE,
        INVARIANT
    }
    struct OracleAverageQuery {
        Variable variable;
        uint256 secs;
        uint256 ago;
    }

    function getSample(uint256 index)
        external
        view
        returns (
            int256 logPairPrice,
            int256 accLogPairPrice,
            int256 logBptPrice,
            int256 accLogBptPrice,
            int256 logInvariant,
            int256 accLogInvariant,
            uint256 timestamp
        );

    function getPoolId() external view returns (bytes32);

    function getVault() external view returns (address);

    function totalSupply() external view returns (uint256);

    struct SwapRequest {
        BalancerVault.SwapKind kind;
        ERC20 tokenIn;
        ERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }

    function onSwap(
        SwapRequest memory swapRequest,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut
    ) external returns (uint256 amount);

    function getIndices() external view returns (uint256 pti, uint256 targeti);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// Internal references
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { BaseAdapter } from "../BaseAdapter.sol";
import { Divider } from "../../../Divider.sol";
import { FixedMath } from "../../../external/FixedMath.sol";
import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";

interface ERC20 {
    function decimals() external view returns (uint256 decimals);
}

interface ChainlinkOracleLike {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function decimals() external view returns (uint256 decimals);
}

abstract contract BaseFactory is Trust {
    using FixedMath for uint256;

    /* ========== CONSTANTS ========== */

    address public constant ETH_USD_PRICEFEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // Chainlink ETH-USD price feed

    /// @notice Sets level to `31` by default, which keeps all Divider lifecycle methods public
    /// (`issue`, `combine`, `collect`, etc), but not the `onRedeem` hook.
    uint48 public constant DEFAULT_LEVEL = 31;

    /* ========== PUBLIC IMMUTABLES ========== */

    /// @notice Sense core Divider address
    address public immutable divider;

    /// @notice Adapter admin address
    address public restrictedAdmin;

    /// @notice Rewards recipient
    address public rewardsRecipient;

    /// @notice params for adapters deployed with this factory
    FactoryParams public factoryParams;

    /* ========== DATA STRUCTURES ========== */

    struct FactoryParams {
        address oracle; // oracle address
        address stake; // token to stake at issuance
        uint256 stakeSize; // amount to stake at issuance
        uint256 minm; // min maturity (seconds after block.timstamp)
        uint256 maxm; // max maturity (seconds after block.timstamp)
        uint128 ifee; // issuance fee
        uint16 mode; // 0 for monthly, 1 for weekly
        uint64 tilt; // tilt
        uint256 guard; // adapter guard (in usd, 18 decimals)
    }

    constructor(
        address _divider,
        address _restrictedAdmin,
        address _rewardsRecipient,
        FactoryParams memory _factoryParams
    ) Trust(msg.sender) {
        divider = _divider;
        restrictedAdmin = _restrictedAdmin;
        rewardsRecipient = _rewardsRecipient;
        factoryParams = _factoryParams;
    }

    /* ========== REQUIRED DEPLOY ========== */

    /// @notice Deploys both an adapter and a target wrapper for the given _target
    /// @param _target Address of the Target token
    /// @param _data Additional data needed to deploy the adapter
    function deployAdapter(address _target, bytes memory _data) external virtual returns (address adapter) {}

    /// Set adapter's guard to $100`000 in target
    /// @notice if Underlying-ETH price feed returns 0, we set the guard to 100000 target.
    function _setGuard(address _adapter) internal {
        // We only want to execute this if divider is guarded
        if (Divider(divider).guarded()) {
            BaseAdapter adapter = BaseAdapter(_adapter);

            // Get Underlying-ETH price (18 decimals)
            try adapter.getUnderlyingPrice() returns (uint256 underlyingPriceInEth) {
                // Get ETH-USD price from Chainlink (8 decimals)
                (, int256 ethPrice, , uint256 ethUpdatedAt, ) = ChainlinkOracleLike(ETH_USD_PRICEFEED)
                    .latestRoundData();

                if (block.timestamp - ethUpdatedAt > 2 hours) revert Errors.InvalidPrice();

                // Calculate Underlying-USD price (normalised to 18 deicmals)
                uint256 price = underlyingPriceInEth.fmul(uint256(ethPrice), 1e8);

                // Calculate Target-USD price (scale and price are in 18 decimals)
                price = adapter.scale().fmul(price);

                // Calculate guard with factory guard (18 decimals) and target price (18 decimals)
                // normalised to target decimals and set it
                Divider(divider).setGuard(
                    _adapter,
                    factoryParams.guard.fdiv(price, 10**ERC20(adapter.target()).decimals())
                );
            } catch {}
        }
    }

    function setRestrictedAdmin(address _restrictedAdmin) external requiresTrust {
        emit RestrictedAdminChanged(restrictedAdmin, _restrictedAdmin);
        restrictedAdmin = _restrictedAdmin;
    }

    /// Set factory rewards recipient
    /// @notice all future deployed adapters will have the new rewards recipient
    /// @dev existing adapters rewards recipients will not be changed and can be
    /// done through `setRewardsRecipient` on each adapter contract
    function setRewardsRecipient(address _recipient) external requiresTrust {
        emit RewardsRecipientChanged(rewardsRecipient, _recipient);
        rewardsRecipient = _recipient;
    }

    /* ========== LOGS ========== */

    event RewardsRecipientChanged(address indexed oldRecipient, address indexed newRecipient);
    event RestrictedAdminChanged(address indexed oldAdmin, address indexed newAdmin);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Library for converting between addresses and bytes32 values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/Bytes32AddressLib.sol)
library Bytes32AddressLib {
    function fromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function fillLast12Bytes(address addressValue) internal pure returns (bytes32) {
        return bytes32(bytes20(addressValue));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import { CToken } from "./CToken.sol";

/// @title Price Oracle
/// @author Compound
/// @notice The minimum interface a contract must implement in order to work as an oracle for Fuse with Sense
/// Original from: https://github.com/Rari-Capital/compound-protocol/blob/fuse-final/contracts/PriceOracle.sol
abstract contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /// @notice Get the underlying price of a cToken asset
    /// @param cToken The cToken to get the underlying price of
    /// @return The underlying asset price mantissa (scaled by 1e18).
    /// 0 means the price is unavailable.
    function getUnderlyingPrice(CToken cToken) external view virtual returns (uint256);

    /// @notice Get the price of an underlying asset.
    /// @param underlying The underlying asset to get the price of.
    /// @return The underlying asset price in ETH as a mantissa (scaled by 1e18).
    /// 0 means the price is unavailable.
    function price(address underlying) external view virtual returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

interface BalancerOracle {
    function getTimeWeightedAverage(OracleAverageQuery[] memory queries)
        external
        view
        returns (uint256[] memory results);

    enum Variable {
        PAIR_PRICE,
        BPT_PRICE,
        INVARIANT
    }
    struct OracleAverageQuery {
        Variable variable;
        uint256 secs;
        uint256 ago;
    }

    function getSample(uint256 index)
        external
        view
        returns (
            int256 logPairPrice,
            int256 accLogPairPrice,
            int256 logBptPrice,
            int256 accLogBptPrice,
            int256 logInvariant,
            int256 accLogInvariant,
            uint256 timestamp
        );

    function getPoolId() external view returns (bytes32);

    function getVault() external view returns (address);

    function getIndices() external view returns (uint256 _pti, uint256 _targeti);

    function totalSupply() external view returns (uint256);

    function getTotalSamples() external pure returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// External references
import { PriceOracle } from "../external/PriceOracle.sol";
import { CToken } from "../external/CToken.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";

// Internal references
import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";
import { Token } from "@sense-finance/v1-core/src/tokens/Token.sol";
import { FixedMath } from "@sense-finance/v1-core/src/external/FixedMath.sol";
import { BaseAdapter as Adapter } from "@sense-finance/v1-core/src/adapters/abstract/BaseAdapter.sol";

contract TargetOracle is PriceOracle, Trust {
    using FixedMath for uint256;

    /// @notice target address -> adapter address
    mapping(address => address) public adapters;

    constructor() Trust(msg.sender) {}

    function setTarget(address target, address adapter) external requiresTrust {
        adapters[target] = adapter;
    }

    function getUnderlyingPrice(CToken cToken) external view override returns (uint256) {
        // For the sense Fuse pool, the underlying will be the Target. The semantics here can be a little confusing
        // as we now have two layers of underlying, cToken -> Target (cToken's underlying) -> Target's underlying
        Token target = Token(cToken.underlying());
        return _price(address(target));
    }

    function price(address target) external view override returns (uint256) {
        return _price(target);
    }

    function _price(address target) internal view returns (uint256) {
        address adapter = adapters[address(target)];
        if (adapter == address(0)) revert Errors.AdapterNotSet();

        // Use the cached scale for view function compatibility
        uint256 scale = Adapter(adapter).scaleStored();

        // `Target / Target's underlying` * `Target's underlying / ETH` = `Price of Target in ETH`
        //
        // `scale` and the value returned by `getUnderlyingPrice` are expected to be WADs
        return scale.fmul(Adapter(adapter).getUnderlyingPrice());
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// External references
import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { PriceOracle } from "../external/PriceOracle.sol";
import { CToken } from "../external/CToken.sol";
import { BalancerVault } from "@sense-finance/v1-core/src/external/balancer/Vault.sol";
import { BalancerPool } from "@sense-finance/v1-core/src/external/balancer/Pool.sol";

// Internal references
import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";
import { FixedMath } from "@sense-finance/v1-core/src/external/FixedMath.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { BaseAdapter as Adapter } from "@sense-finance/v1-core/src/adapters/abstract/BaseAdapter.sol";

interface SpaceLike {
    function getFairBPTPrice(uint256 ptTwapDuration) external view returns (uint256);

    function adapter() external view returns (address);
}

contract LPOracle is PriceOracle, Trust {
    using FixedMath for uint256;

    /// @notice PT address -> pool address for oracle reads
    mapping(address => address) public pools;
    uint256 public twapPeriod;

    constructor() Trust(msg.sender) {
        twapPeriod = 5.5 hours;
    }

    function setTwapPeriod(uint256 _twapPeriod) external requiresTrust {
        twapPeriod = _twapPeriod;
    }

    function getUnderlyingPrice(CToken cToken) external view override returns (uint256) {
        // The underlying here will be an LP Token
        return _price(cToken.underlying());
    }

    function price(address pt) external view override returns (uint256) {
        return _price(pt);
    }

    function _price(address _pool) internal view returns (uint256) {
        SpaceLike pool = SpaceLike(_pool);
        address target = Adapter(pool.adapter()).target();

        // Price per BPT in ETH terms, where the PT side of the pool is valued using the TWAP oracle
        return pool.getFairBPTPrice(twapPeriod).fmul(PriceOracle(msg.sender).price(target));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// External references
import { PriceOracle } from "../external/PriceOracle.sol";
import { CToken } from "../external/CToken.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";

// Internal references
import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";
import { FixedMath } from "@sense-finance/v1-core/src/external/FixedMath.sol";
import { BaseAdapter as Adapter } from "@sense-finance/v1-core/src/adapters/abstract/BaseAdapter.sol";

contract UnderlyingOracle is PriceOracle, Trust {
    using FixedMath for uint256;

    /// @notice underlying address -> adapter address
    mapping(address => address) public adapters;

    constructor() Trust(msg.sender) {}

    function setUnderlying(address underlying, address adapter) external requiresTrust {
        adapters[underlying] = adapter;
    }

    function getUnderlyingPrice(CToken cToken) external view override returns (uint256) {
        return _price(address(cToken.underlying()));
    }

    function price(address underlying) external view override returns (uint256) {
        return _price(underlying);
    }

    function _price(address underlying) internal view returns (uint256) {
        address adapter = adapters[address(underlying)];
        if (adapter == address(0)) revert Errors.AdapterNotSet();

        return Adapter(adapter).getUnderlyingPrice();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// External references
import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { PriceOracle } from "../external/PriceOracle.sol";
import { CToken } from "../external/CToken.sol";
import { BalancerOracle } from "../external/BalancerOracle.sol";
import { BalancerVault } from "@sense-finance/v1-core/src/external/balancer/Vault.sol";

// Internal references
import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { Token } from "@sense-finance/v1-core/src/tokens/Token.sol";
import { FixedMath } from "@sense-finance/v1-core/src/external/FixedMath.sol";
import { BaseAdapter as Adapter } from "@sense-finance/v1-core/src/adapters/abstract/BaseAdapter.sol";

interface SpaceLike {
    function getImpliedRateFromPrice(uint256 pTPriceInTarget) external view returns (uint256);

    function getPriceFromImpliedRate(uint256 impliedRate) external view returns (uint256);

    function getTotalSamples() external pure returns (uint256);

    function adapter() external view returns (address);
}

contract PTOracle is PriceOracle, Trust {
    using FixedMath for uint256;

    /// @notice PT address -> pool address for oracle reads
    mapping(address => address) public pools;
    /// @notice Minimum implied rate this oracle will tolerate for PTs
    uint256 public floorRate;
    uint256 public twapPeriod;

    constructor() Trust(msg.sender) {
        floorRate = 3e18; // 300%
        twapPeriod = 5.5 hours;
    }

    function setFloorRate(uint256 _floorRate) external requiresTrust {
        floorRate = _floorRate;
    }

    function setTwapPeriod(uint256 _twapPeriod) external requiresTrust {
        twapPeriod = _twapPeriod;
    }

    function setPrincipal(address pt, address pool) external requiresTrust {
        pools[pt] = pool;
    }

    function getUnderlyingPrice(CToken cToken) external view override returns (uint256) {
        // The underlying here will be a Principal Token
        return _price(cToken.underlying());
    }

    function price(address pt) external view override returns (uint256) {
        return _price(pt);
    }

    function _price(address pt) internal view returns (uint256) {
        BalancerOracle pool = BalancerOracle(pools[address(pt)]);
        if (pool == BalancerOracle(address(0))) revert Errors.PoolNotSet();

        // if getSample(buffer_size) returns 0s, the oracle buffer is not full yet and a price can't be read
        // https://dev.balancer.fi/references/contracts/apis/pools/weightedpool2tokens#api
        (, , , , , , uint256 sampleTs) = pool.getSample(SpaceLike(address(pool)).getTotalSamples() - 1);
        // Revert if the pool's oracle can't be used yet, preventing this market from being deployed
        // on Fuse until we're able to read a TWAP
        if (sampleTs == 0) revert Errors.OracleNotReady();

        BalancerOracle.OracleAverageQuery[] memory queries = new BalancerOracle.OracleAverageQuery[](1);
        // The BPT price slot in Space carries the implied rate TWAP
        queries[0] = BalancerOracle.OracleAverageQuery({
            variable: BalancerOracle.Variable.BPT_PRICE,
            secs: twapPeriod,
            ago: 1 hours // take the oracle from 1 hour ago plus twapPeriod ago to 1 hour ago
        });

        uint256[] memory results = pool.getTimeWeightedAverage(queries);
        // note: impliedRate is pulled from the BPT price slot in BalancerOracle.OracleAverageQuery
        uint256 impliedRate = results[0];

        if (impliedRate > floorRate) {
            impliedRate = floorRate;
        }

        address target = Adapter(SpaceLike(address(pool)).adapter()).target();

        // `Principal Token / target` * `target / ETH` = `Price of Principal Token in ETH`
        //
        // Assumes the caller is the master oracle, which will have its own strategy for getting the underlying price
        return
            SpaceLike(address(pool)).getPriceFromImpliedRate(impliedRate).fmul(PriceOracle(msg.sender).price(target));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

/// @title Price Oracle
/// @author Compound
interface CToken {
    function underlying() external view returns (address);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// Internal references
import { Crop } from "../extensions/Crop.sol";
import { BaseFactory } from "./BaseFactory.sol";

abstract contract CropFactory is BaseFactory {
    address public reward;

    constructor(
        address _divider,
        address _restrictedAdmin,
        address _rewardsRecipient,
        FactoryParams memory _factoryParams,
        address _reward
    ) BaseFactory(_divider, _restrictedAdmin, _rewardsRecipient, _factoryParams) {
        reward = _reward;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";
import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";

/// @title ExtractableReward
/// @notice Allows to extract rewards from the contract to the `rewardsRecepient`
abstract contract ExtractableReward is Trust {
    /// -----------------------------------------------------------------------
    /// Libraries usage
    /// -----------------------------------------------------------------------

    using SafeTransferLib for ERC20;

    /// @notice Rewards recipient
    address public rewardsRecipient;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(address _rewardsRecipient) Trust(msg.sender) {
        rewardsRecipient = _rewardsRecipient;
    }

    /// -----------------------------------------------------------------------
    /// Rewards extractor
    /// -----------------------------------------------------------------------

    /// @notice Receives a token address and returns whether it is an
    /// extractable token or not
    /// @dev To be overriden by the inheriting contract
    function _isValid(address _token) internal virtual returns (bool);

    /// @notice Transfers reward tokens from the adapter to Sense's reward container
    function extractToken(address token) external {
        if (!_isValid(token)) revert Errors.TokenNotSupported();
        ERC20 t = ERC20(token);
        uint256 tBal = t.balanceOf(address(this));
        t.safeTransfer(rewardsRecipient, t.balanceOf(address(this)));
        emit RewardsClaimed(token, rewardsRecipient, tBal);
    }

    /// -----------------------------------------------------------------------
    /// Admin functions
    /// -----------------------------------------------------------------------
    function setRewardsRecipient(address recipient) external requiresTrust {
        emit RewardsRecipientChanged(rewardsRecipient, recipient);
        rewardsRecipient = recipient;
    }

    /// -----------------------------------------------------------------------
    /// Logs
    /// -----------------------------------------------------------------------
    event RewardsRecipientChanged(address indexed oldRecipient, address indexed newRecipient);
    event RewardsClaimed(address indexed token, address indexed recipient, uint256 indexed amount);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";
import {SafeTransferLib} from "../utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "../utils/FixedPointMathLib.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
abstract contract ERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Equivalent to x to the power of y because x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)
        return expWad((lnWad(x) * y) / int256(WAD)); // Using ln(x) means x must be greater than 0.
    }

    function expWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) return 0;

            // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
            // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
            if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5**18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
            x = x - k * 54916777467707473351141471128;

            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation.
            // p is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by:
            // * the scale factor s = ~6.031367120.
            // * the 2**k factor from the range reduction.
            // * the 1e18 / 2**96 factor for base conversion.
            // We do this all at once, with an intermediate result in 2**213
            // basis, so the final right shift is always by a positive amount.
            r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
        }
    }

    function lnWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            require(x > 0, "UNDEFINED");

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            int256 k = int256(log2(uint256(x))) - 96;
            x <<= uint256(159 - k);
            x = int256(uint256(x) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function log2(uint256 x) internal pure returns (uint256 r) {
        require(x > 0, "UNDEFINED");

        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // z will equal 0 if y is 0, unlike in Solidity where it will revert.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // z will equal 0 if y is 0, unlike in Solidity where it will revert.
            z := div(x, y)
        }
    }

    /// @dev Will return 0 instead of reverting if y is zero.
    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Add 1 to x * y if x % y > 0.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import { ERC4626Adapter } from "./ERC4626Adapter.sol";
import { BaseAdapter } from "../BaseAdapter.sol";
import { Crops } from "../extensions/Crops.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";

/// @notice Adapter contract for ERC4626 Vaults
contract ERC4626CropsAdapter is ERC4626Adapter, Crops {
    using SafeTransferLib for ERC20;

    constructor(
        address _divider,
        address _target,
        address _rewardsRecipient,
        uint128 _ifee,
        AdapterParams memory _adapterParams,
        address[] memory _rewardTokens
    ) ERC4626Adapter(_divider, _target, _rewardsRecipient, _ifee, _adapterParams) Crops(_divider, _rewardTokens) {}

    function notify(
        address _usr,
        uint256 amt,
        bool join
    ) public override(BaseAdapter, Crops) {
        super.notify(_usr, amt, join);
    }

    function _isValid(address _token) internal override returns (bool) {
        for (uint256 i = 0; i < rewardTokens.length; ) {
            if (_token == rewardTokens[i]) return false;
            unchecked {
                ++i;
            }
        }

        // Check that token is neither the target nor the stake
        return (_token != target && _token != adapterParams.stake);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// External references
import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { ERC4626 } from "solmate/src/mixins/ERC4626.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";

// Internal references
import { MasterPriceOracle } from "../../implementations/oracles/MasterPriceOracle.sol";
import { FixedMath } from "../../../external/FixedMath.sol";
import { BaseAdapter } from "../BaseAdapter.sol";
import { ExtractableReward } from "../extensions/ExtractableReward.sol";

/// @notice Adapter contract for ERC4626 Vaults
contract ERC4626Adapter is BaseAdapter, ExtractableReward {
    using SafeTransferLib for ERC20;
    using FixedMath for uint256;

    address public constant RARI_MASTER_ORACLE = 0x1887118E49e0F4A78Bd71B792a49dE03504A764D;

    uint256 public immutable BASE_UINT;
    uint256 public immutable SCALE_FACTOR;

    constructor(
        address _divider,
        address _target,
        address _rewardsRecipient,
        uint128 _ifee,
        AdapterParams memory _adapterParams
    )
        BaseAdapter(_divider, _target, address(ERC4626(_target).asset()), _ifee, _adapterParams)
        ExtractableReward(_rewardsRecipient)
    {
        BASE_UINT = 10**ERC4626(target).decimals();
        SCALE_FACTOR = 10**(18 - ERC4626(underlying).decimals()); // we assume targets decimals <= 18
        ERC20(underlying).safeApprove(target, type(uint256).max);
    }

    function scale() external override returns (uint256) {
        return ERC4626(target).convertToAssets(BASE_UINT) * SCALE_FACTOR;
    }

    function scaleStored() external view override returns (uint256) {
        return ERC4626(target).convertToAssets(BASE_UINT) * SCALE_FACTOR;
    }

    function getUnderlyingPrice() external view override returns (uint256 price) {
        price = MasterPriceOracle(adapterParams.oracle).price(underlying);
        if (price == 0) {
            revert Errors.InvalidPrice();
        }
    }

    function wrapUnderlying(uint256 assets) external override returns (uint256 _shares) {
        ERC20(underlying).safeTransferFrom(msg.sender, address(this), assets);
        _shares = ERC4626(target).deposit(assets, msg.sender);
    }

    function unwrapTarget(uint256 shares) external override returns (uint256 _assets) {
        _assets = ERC4626(target).redeem(shares, msg.sender, msg.sender);
    }

    function _isValid(address _token) internal virtual override returns (bool) {
        return (_token != target && _token != adapterParams.stake);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

/// @title IPriceFeed
/// @notice Returns prices of underlying tokens
/// @author Taken from: https://github.com/Rari-Capital/fuse-v1/blob/development/src/oracles/BasePriceOracle.sol
interface IPriceFeed {
    /// @notice Get the price of an underlying asset.
    /// @param underlying The underlying asset to get the price of.
    /// @return price The underlying asset price in ETH as a mantissa (scaled by 1e18).
    /// Zero means the price is unavailable.
    function price(address underlying) external view returns (uint256 price);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import { ERC4626Adapter } from "./ERC4626Adapter.sol";
import { BaseAdapter } from "../BaseAdapter.sol";
import { Crop } from "../extensions/Crop.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";

/// @notice Adapter contract for ERC4626 Vaults
contract ERC4626CropAdapter is ERC4626Adapter, Crop {
    using SafeTransferLib for ERC20;

    constructor(
        address _divider,
        address _target,
        address _rewardsRecipient,
        uint128 _ifee,
        AdapterParams memory _adapterParams,
        address _reward
    ) ERC4626Adapter(_divider, _target, _rewardsRecipient, _ifee, _adapterParams) Crop(_divider, _reward) {}

    function notify(
        address _usr,
        uint256 amt,
        bool join
    ) public override(BaseAdapter, Crop) {
        super.notify(_usr, amt, join);
    }

    function _isValid(address _token) internal override returns (bool) {
        return (_token != target && _token != adapterParams.stake && _token != reward);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {ERC4626} from "solmate/src/mixins/ERC4626.sol";

import {EulerERC4626} from "./EulerERC4626.sol";
import {IEulerEToken} from "./external/IEulerEToken.sol";
import {ERC4626Factory} from "../base/ERC4626Factory.sol";
import {IEulerMarkets} from "./external/IEulerMarkets.sol";

/// @title EulerERC4626Factory
/// @author zefram.eth
/// @notice Factory for creating EulerERC4626 contracts
contract EulerERC4626Factory is ERC4626Factory {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    /// @notice Thrown when trying to deploy an EulerERC4626 vault using an asset without an eToken
    error EulerERC4626Factory__ETokenNonexistent();

    /// -----------------------------------------------------------------------
    /// Immutable params
    /// -----------------------------------------------------------------------

    /// @notice The Euler main contract address
    /// @dev Target of ERC20 approval when depositing
    address public immutable euler;

    /// @notice The Euler markets module address
    IEulerMarkets public immutable markets;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(address euler_, IEulerMarkets markets_) {
        euler = euler_;
        markets = markets_;
    }

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    /// @inheritdoc ERC4626Factory
    function createERC4626(ERC20 asset) external virtual override returns (ERC4626 vault) {
        address eTokenAddress = markets.underlyingToEToken(address(asset));
        if (eTokenAddress == address(0)) {
            revert EulerERC4626Factory__ETokenNonexistent();
        }

        vault = new EulerERC4626{salt: bytes32(0)}(asset, euler, IEulerEToken(eTokenAddress));

        emit CreateERC4626(asset, vault);
    }

    /// @inheritdoc ERC4626Factory
    function computeERC4626Address(ERC20 asset) external view virtual override returns (ERC4626 vault) {
        vault = ERC4626(
            _computeCreate2Address(
                keccak256(
                    abi.encodePacked(
                        // Deployment bytecode:
                        type(EulerERC4626).creationCode,
                        // Constructor arguments:
                        abi.encode(asset, euler, IEulerEToken(markets.underlyingToEToken(address(asset))))
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {ERC4626} from "solmate/src/mixins/ERC4626.sol";
import {Bytes32AddressLib} from "solmate/src/utils/Bytes32AddressLib.sol";

/// @title ERC4626Factory
/// @author zefram.eth
/// @notice Abstract base contract for deploying ERC4626 wrappers
/// @dev Uses CREATE2 deterministic deployment, so there can only be a single
/// vault for each asset.
abstract contract ERC4626Factory {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using Bytes32AddressLib for bytes32;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @notice Emitted when a new ERC4626 vault has been created
    /// @param asset The base asset used by the vault
    /// @param vault The vault that was created
    event CreateERC4626(ERC20 indexed asset, ERC4626 vault);

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    /// @notice Creates an ERC4626 vault for an asset
    /// @dev Uses CREATE2 deterministic deployment, so there can only be a single
    /// vault for each asset. Will revert if a vault has already been deployed for the asset.
    /// @param asset The base asset used by the vault
    /// @return vault The vault that was created
    function createERC4626(ERC20 asset) external virtual returns (ERC4626 vault);

    /// @notice Computes the address of the ERC4626 vault corresponding to an asset. Returns
    /// a valid result regardless of whether the vault has already been deployed.
    /// @param asset The base asset used by the vault
    /// @return vault The vault corresponding to the asset
    function computeERC4626Address(ERC20 asset) external view virtual returns (ERC4626 vault);

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    /// @notice Computes the address of a contract deployed by this factory using CREATE2, given
    /// the bytecode hash of the contract. Can also be used to predict addresses of contracts yet to
    /// be deployed.
    /// @dev Always uses bytes32(0) as the salt
    /// @param bytecodeHash The keccak256 hash of the creation code of the contract being deployed concatenated
    /// with the ABI-encoded constructor arguments.
    /// @return The address of the deployed contract
    function _computeCreate2Address(bytes32 bytecodeHash) internal view virtual returns (address) {
        return keccak256(abi.encodePacked(bytes1(0xFF), address(this), bytes32(0), bytecodeHash))
            // Prefix:
            // Creator:
            // Salt:
            // Bytecode hash:
            .fromLast20Bytes(); // Convert the CREATE2 hash into an address.
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;

/// @notice Activating and querying markets, and maintaining entered markets lists
interface IEulerMarkets {
    /// @notice Given an underlying, lookup the associated EToken
    /// @param underlying Token address
    /// @return EToken address, or address(0) if not activated
    function underlyingToEToken(address underlying) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;

/// @notice Tokenised representation of assets
interface IEulerEToken {
    /// @notice Balance of a particular account, in underlying units (increases as interest is earned)
    function balanceOfUnderlying(address account) external view returns (uint256);

    /// @notice Transfer underlying tokens from sender to the Euler pool, and increase account's eTokens
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 for full underlying token balance)
    function deposit(uint256 subAccountId, uint256 amount) external;

    /// @notice Transfer underlying tokens from Euler pool to sender, and decrease account's eTokens
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 for full pool balance)
    function withdraw(uint256 subAccountId, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { IEulerEToken } from "../../../../../../lib/yield-daddy/src/euler/external/IEulerEToken.sol";
import { EulerERC4626 as Base } from "../../../../../../lib/yield-daddy/src/euler/EulerERC4626.sol";
import { ExtractableReward } from "../../../extensions/ExtractableReward.sol";

/// @title EulerERC4626
/// @author forked from Yield Daddy (Timeless Finance)
/// @notice ERC4626 wrapper for Euler Finance
contract EulerERC4626 is Base, ExtractableReward {
    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------
    constructor(
        ERC20 _asset,
        address _euler,
        IEulerEToken _eToken,
        address _rewardsRecipient
    ) Base(_asset, _euler, _eToken) ExtractableReward(_rewardsRecipient) {}

    /// -----------------------------------------------------------------------
    /// Overrides
    /// -----------------------------------------------------------------------
    function _isValid(address _token) internal override returns (bool) {
        return _token != address(eToken);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";
import { ERC4626Factory } from "../../../../../../lib/yield-daddy/src/base/ERC4626Factory.sol";

/// @title ERC4626WrapperFactory
/// @notice Adds restrictedAdmin and rewardsRecipient to ERC4626Factory from yield-daddy
abstract contract ERC4626WrapperFactory is ERC4626Factory, Trust {
    /// -----------------------------------------------------------------------
    /// Params
    /// -----------------------------------------------------------------------

    /// @notice Wrapper admin
    address public restrictedAdmin;

    /// @notice Rewards recipient
    address public rewardsRecipient;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(address _restrictedAdmin, address _rewardsRecipient) Trust(msg.sender) {
        restrictedAdmin = _restrictedAdmin;
        rewardsRecipient = _rewardsRecipient;
    }

    /// -----------------------------------------------------------------------
    /// Admin functions
    /// -----------------------------------------------------------------------
    function setRestrictedAdmin(address _restrictedAdmin) external requiresTrust {
        emit RestrictedAdminChanged(restrictedAdmin, _restrictedAdmin);
        restrictedAdmin = _restrictedAdmin;
    }

    function setRewardsRecipient(address _recipient) external requiresTrust {
        emit RewardsRecipientChanged(rewardsRecipient, _recipient);
        rewardsRecipient = _recipient;
    }

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event RestrictedAdminChanged(address indexed restrictedAdmin, address indexed newRestrictedAdmin);
    event RewardsRecipientChanged(address indexed oldRecipient, address indexed newRecipient);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {ERC4626} from "solmate/src/mixins/ERC4626.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

import {IEulerEToken} from "./external/IEulerEToken.sol";

/// @title EulerERC4626
/// @author zefram.eth
/// @notice ERC4626 wrapper for Euler Finance
contract EulerERC4626 is ERC4626 {
    /// -----------------------------------------------------------------------
    /// Libraries usage
    /// -----------------------------------------------------------------------

    using SafeTransferLib for ERC20;

    /// -----------------------------------------------------------------------
    /// Immutable params
    /// -----------------------------------------------------------------------

    /// @notice The Euler main contract address
    /// @dev Target of ERC20 approval when depositing
    address public immutable euler;

    /// @notice The Euler eToken contract
    IEulerEToken public immutable eToken;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(ERC20 asset_, address euler_, IEulerEToken eToken_)
        ERC4626(asset_, _vaultName(asset_), _vaultSymbol(asset_))
    {
        euler = euler_;
        eToken = eToken_;
    }

    /// -----------------------------------------------------------------------
    /// ERC4626 overrides
    /// -----------------------------------------------------------------------

    function totalAssets() public view virtual override returns (uint256) {
        return eToken.balanceOfUnderlying(address(this));
    }

    function beforeWithdraw(uint256 assets, uint256 /*shares*/ ) internal virtual override {
        /// -----------------------------------------------------------------------
        /// Withdraw assets from Euler
        /// -----------------------------------------------------------------------

        eToken.withdraw(0, assets);
    }

    function afterDeposit(uint256 assets, uint256 /*shares*/ ) internal virtual override {
        /// -----------------------------------------------------------------------
        /// Deposit assets into Euler
        /// -----------------------------------------------------------------------

        // approve to euler
        asset.safeApprove(address(euler), assets);

        // deposit into eToken
        eToken.deposit(0, assets);
    }

    function maxWithdraw(address owner) public view override returns (uint256) {
        uint256 cash = asset.balanceOf(euler);
        uint256 assetsBalance = convertToAssets(balanceOf[owner]);
        return cash < assetsBalance ? cash : assetsBalance;
    }

    function maxRedeem(address owner) public view override returns (uint256) {
        uint256 cash = asset.balanceOf(euler);
        uint256 cashInShares = convertToShares(cash);
        uint256 shareBalance = balanceOf[owner];
        return cashInShares < shareBalance ? cashInShares : shareBalance;
    }

    /// -----------------------------------------------------------------------
    /// ERC20 metadata generation
    /// -----------------------------------------------------------------------

    function _vaultName(ERC20 asset_) internal view virtual returns (string memory vaultName) {
        vaultName = string.concat("ERC4626-Wrapped Euler ", asset_.symbol());
    }

    function _vaultSymbol(ERC20 asset_) internal view virtual returns (string memory vaultSymbol) {
        vaultSymbol = string.concat("we", asset_.symbol());
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;

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
    // 'SNS#{errorCode}'
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

        // With the individual characters, we can now construct the full string. The "SNS#" part is a known constant
        // (0x3f534e5323): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(200, add(0x3f534e5323000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

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

library Errors {
    // Space (using error codes as Space uses ^0.7.0)
    uint256 internal constant CALLER_NOT_VAULT = 100;
    uint256 internal constant INVALID_G1 = 101;
    uint256 internal constant INVALID_G2 = 102;
    uint256 internal constant INVALID_POOL_ID = 103;
    uint256 internal constant POOL_ALREADY_EXISTS = 104;
    uint256 internal constant POOL_PAST_MATURITY = 105;
    uint256 internal constant SWAP_TOO_SMALL = 106;
    uint256 internal constant NEGATIVE_RATE = 107;
    uint256 internal constant BPT_OUT_MIN_AMOUNT = 108;
    uint256 internal constant INVALID_SERIES = 109;
}