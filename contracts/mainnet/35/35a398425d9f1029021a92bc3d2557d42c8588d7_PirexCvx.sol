// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {ReentrancyGuard} from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {Bytes32AddressLib} from "@rari-capital/solmate/src/utils/Bytes32AddressLib.sol";
import {PirexCvxConvex} from "./PirexCvxConvex.sol";
import {PxCvx} from "./PxCvx.sol";
import {PirexFees} from "./PirexFees.sol";
import {UnionPirexVault} from "./vault/UnionPirexVault.sol";
import {ERC1155Solmate} from "./tokens/ERC1155Solmate.sol";
import {ERC1155PresetMinterSupply} from "./tokens/ERC1155PresetMinterSupply.sol";
import {IVotiumMultiMerkleStash} from "./interfaces/IVotiumMultiMerkleStash.sol";
import {ICvxLocker} from "./interfaces/ICvxLocker.sol";

/**
    For Jude 🐾 - kings never die. QmPXRvYyDSqiqk9Xj9zsoaLa3UMN2uL5A8J9CPQPHvPQ6i - kp
    Arise, you have nothing to lose but your barbed wire fences! - never
    Hakuna matata - greenbergz
    ZA WARUDO - seiji
    Why not both. The answer to all of life's questions. CVX locked or liquid? Crypto or childcare? - Percival
    Dreams are made of these... QmU6oGG8J1cKWKiuQU1y9YTiBF89LBUyojTjfvfzZ4GMif - funky
    🫡 - Sami
    Put cereal in my coffee, INNOVATING ON CHAIN & OFF CHAIN - Marcel
    Development will continue until morale improves - Alunara
    Imagine using a lame ass quote instead of ascii art - Benny
*/
contract PirexCvx is ReentrancyGuard, PirexCvxConvex {
    using SafeTransferLib for ERC20;
    using Bytes32AddressLib for address;

    /**
        @notice Data pertaining to an emergency migration
        @param  recipient  address    Recipient of the tokens (e.g. new PirexCvx contract)
        @param  tokens     address[]  Token addresses
     */
    struct EmergencyMigration {
        address recipient;
        address[] tokens;
    }

    // Users can choose between the two futures tokens when staking or initiating a redemption
    enum Futures {
        Vote,
        Reward
    }

    // Configurable contracts
    enum Contract {
        PxCvx,
        PirexFees,
        Votium,
        UpxCvx,
        SpxCvx,
        VpxCvx,
        RpxCvx,
        UnionPirexVault
    }

    // Configurable fees
    enum Fees {
        Reward,
        RedemptionMax,
        RedemptionMin,
        Developers
    }

    // Convex voting round duration (1,209,600 seconds)
    uint32 public constant EPOCH_DURATION = 2 weeks;

    // Fee denominator
    uint32 public constant FEE_DENOMINATOR = 1_000_000;

    // Fee maximum
    uint32 public constant FEE_MAX = 100_000;

    // Maximum wait time for a CVX redemption (10,281,600 seconds)
    uint32 public constant MAX_REDEMPTION_TIME = 17 weeks;

    // Unused ERC1155 `data` param value
    bytes private constant UNUSED_1155_DATA = "";

    PxCvx public pxCvx;
    PirexFees public pirexFees;
    IVotiumMultiMerkleStash public votiumMultiMerkleStash;
    ERC1155Solmate public upxCvx;
    ERC1155Solmate public spxCvx;
    ERC1155PresetMinterSupply public vpxCvx;
    ERC1155PresetMinterSupply public rpxCvx;
    UnionPirexVault public unionPirex;

    // Fees (e.g. 5000 / 1000000 = 0.5%)
    mapping(Fees => uint32) public fees;

    // Convex unlock timestamps mapped to amount being redeemed
    mapping(uint256 => uint256) public redemptions;

    // Developers who are eligible for incentives as part of the new initiative
    // to enable builders to sustainably build apps for the Pirex ecosystem
    mapping(address => bool) public developers;

    // Emergency migration data
    EmergencyMigration public emergencyMigration;

    // Non-Pirex multisig which has authority to fulfill emergency procedures
    address public emergencyExecutor;

    // In the case of a mass unlock by Convex, the current upxCVX would be deprecated
    // and should allow holders to immediately redeem their CVX by burning upxCVX
    bool public upxCvxDeprecated;

    event SetContract(Contract indexed c, address contractAddress);
    event SetFee(Fees indexed f, uint32 fee);
    event AddDeveloper(address developer);
    event RemoveDeveloper(address developer);
    event MintFutures(
        uint256 rounds,
        Futures indexed f,
        uint256 assets,
        address indexed receiver
    );
    event Deposit(
        uint256 assets,
        address indexed receiver,
        bool indexed shouldCompound,
        address indexed developer
    );
    event InitiateRedemptions(
        uint256[] lockIndexes,
        Futures indexed f,
        uint256[] assets,
        address indexed receiver
    );
    event Redeem(
        uint256[] unlockTimes,
        uint256[] assets,
        address indexed receiver,
        bool legacy
    );
    event Stake(
        uint256 rounds,
        Futures indexed f,
        uint256 assets,
        address indexed receiver
    );
    event Unstake(uint256 id, uint256 assets, address indexed receiver);
    event ClaimMiscRewards(uint256 timestamp, ConvexReward[] rewards);
    event ClaimVotiumReward(
        address indexed token,
        uint256 index,
        uint256 amount
    );
    event RedeemSnapshotRewards(
        uint256 indexed epoch,
        uint256[] rewardIndexes,
        address indexed receiver,
        uint256 snapshotBalance,
        uint256 snapshotSupply
    );
    event RedeemFuturesRewards(
        uint256 indexed epoch,
        address indexed receiver,
        bytes32[] rewards
    );
    event ExchangeFutures(
        uint256 indexed epoch,
        uint256 amount,
        address indexed receiver,
        Futures f
    );
    event InitializeEmergencyExecutor(address _emergencyExecutor);
    event SetEmergencyMigration(EmergencyMigration _emergencyMigration);
    event SetUpxCvxDeprecated(bool state);
    event ExecuteEmergencyMigration(address recipient, address[] tokens);

    error ZeroAmount();
    error BeforeUnlock();
    error InsufficientBalance();
    error AlreadyRedeemed();
    error InsufficientRedemptionAllowance();
    error PastExchangePeriod();
    error InvalidFee();
    error BeforeEffectiveTimestamp();
    error BeforeStakingExpiry();
    error InvalidEpoch();
    error EmptyArray();
    error MismatchedArrayLengths();
    error NoRewards();
    error RedeemClosed();
    error AlreadyInitialized();
    error NoEmergencyExecutor();
    error InvalidEmergencyMigration();
    error NotAuthorized();

    /**
        @param  _CVX                     address  CVX address    
        @param  _cvxLocker               address  CvxLocker address
        @param  _cvxDelegateRegistry     address  CvxDelegateRegistry address
        @param  _pxCvx                   address  PxCvx address
        @param  _upxCvx                  address  UpxCvx address
        @param  _spxCvx                  address  SpxCvx address
        @param  _vpxCvx                  address  VpxCvx address
        @param  _rpxCvx                  address  RpxCvx address
        @param  _pirexFees               address  PirexFees address
        @param  _votiumMultiMerkleStash  address  VotiumMultiMerkleStash address
     */
    constructor(
        address _CVX,
        address _cvxLocker,
        address _cvxDelegateRegistry,
        address _pxCvx,
        address _upxCvx,
        address _spxCvx,
        address _vpxCvx,
        address _rpxCvx,
        address _pirexFees,
        address _votiumMultiMerkleStash
    ) PirexCvxConvex(_CVX, _cvxLocker, _cvxDelegateRegistry) {
        // Init with paused state, should only unpause after fully perform the full setup
        _pause();

        if (_pxCvx == address(0)) revert ZeroAddress();
        if (_pirexFees == address(0)) revert ZeroAddress();
        if (_upxCvx == address(0)) revert ZeroAddress();
        if (_spxCvx == address(0)) revert ZeroAddress();
        if (_vpxCvx == address(0)) revert ZeroAddress();
        if (_rpxCvx == address(0)) revert ZeroAddress();
        if (_votiumMultiMerkleStash == address(0)) revert ZeroAddress();

        pxCvx = PxCvx(_pxCvx);
        pirexFees = PirexFees(_pirexFees);
        upxCvx = ERC1155Solmate(_upxCvx);
        spxCvx = ERC1155Solmate(_spxCvx);
        vpxCvx = ERC1155PresetMinterSupply(_vpxCvx);
        rpxCvx = ERC1155PresetMinterSupply(_rpxCvx);
        votiumMultiMerkleStash = IVotiumMultiMerkleStash(
            _votiumMultiMerkleStash
        );
    }

    /** 
        @notice Set a contract address
        @param  c                enum     Contract
        @param  contractAddress  address  Contract address    
     */
    function setContract(Contract c, address contractAddress)
        external
        onlyOwner
    {
        if (contractAddress == address(0)) revert ZeroAddress();

        emit SetContract(c, contractAddress);

        if (c == Contract.PxCvx) {
            pxCvx = PxCvx(contractAddress);
            return;
        }

        if (c == Contract.PirexFees) {
            pirexFees = PirexFees(contractAddress);
            return;
        }

        if (c == Contract.Votium) {
            votiumMultiMerkleStash = IVotiumMultiMerkleStash(contractAddress);
            return;
        }

        if (c == Contract.UpxCvx) {
            upxCvx = ERC1155Solmate(contractAddress);
            return;
        }

        if (c == Contract.SpxCvx) {
            spxCvx = ERC1155Solmate(contractAddress);
            return;
        }

        if (c == Contract.VpxCvx) {
            vpxCvx = ERC1155PresetMinterSupply(contractAddress);
            return;
        }

        if (c == Contract.RpxCvx) {
            rpxCvx = ERC1155PresetMinterSupply(contractAddress);
            return;
        }

        ERC20 pxCvxERC20 = ERC20(address(pxCvx));
        address oldUnionPirex = address(unionPirex);

        if (oldUnionPirex != address(0)) {
            pxCvxERC20.safeApprove(oldUnionPirex, 0);
        }

        unionPirex = UnionPirexVault(contractAddress);
        pxCvxERC20.safeApprove(address(unionPirex), type(uint256).max);
    }

    /** 
        @notice Set fee
        @param  f    enum    Fee
        @param  fee  uint32  Fee amount
     */
    function setFee(Fees f, uint32 fee) external onlyOwner {
        if (fee > FEE_MAX) revert InvalidFee();
        if (f == Fees.RedemptionMax && fee < fees[Fees.RedemptionMin])
            revert InvalidFee();
        if (f == Fees.RedemptionMin && fee > fees[Fees.RedemptionMax])
            revert InvalidFee();

        fees[f] = fee;

        emit SetFee(f, fee);
    }

    /** 
        @notice Add developer to whitelist mapping
        @param  developer  address  Developer
     */
    function addDeveloper(address developer) external onlyOwner {
        if (developer == address(0)) revert ZeroAddress();

        developers[developer] = true;

        emit AddDeveloper(developer);
    }

    /** 
        @notice Remove developer from whitelist mapping
        @param  developer  address  Developer
     */
    function removeDeveloper(address developer) external onlyOwner {
        if (developer == address(0)) revert ZeroAddress();

        developers[developer] = false;

        emit RemoveDeveloper(developer);
    }

    /**
        @notice Get current epoch
        @return uint256  Current epoch
     */
    function getCurrentEpoch() public view returns (uint256) {
        return (block.timestamp / EPOCH_DURATION) * EPOCH_DURATION;
    }

    /**
        @notice Mint futures tokens
        @param  rounds    uint256  Rounds (i.e. Convex voting rounds)
        @param  f         enum     Futures enum
        @param  assets    uint256  Futures amount
        @param  receiver  address  Receives futures
    */
    function _mintFutures(
        uint256 rounds,
        Futures f,
        uint256 assets,
        address receiver
    ) internal {
        emit MintFutures(rounds, f, assets, receiver);

        ERC1155PresetMinterSupply token = f == Futures.Vote ? vpxCvx : rpxCvx;
        uint256 startingEpoch = getCurrentEpoch() + EPOCH_DURATION;
        uint256[] memory tokenIds = new uint256[](rounds);
        uint256[] memory amounts = new uint256[](rounds);

        for (uint256 i; i < rounds; ++i) {
            tokenIds[i] = startingEpoch + i * EPOCH_DURATION;
            amounts[i] = assets;
        }

        token.mintBatch(receiver, tokenIds, amounts, UNUSED_1155_DATA);
    }

    /**
        @notice Redeem CVX for specified unlock times
        @param  unlockTimes  uint256[]  vlCVX unlock timestamps
        @param  assets       uint256[]  upxCVX amounts
        @param  receiver     address    Receives CVX
        @param  legacy       bool       Whether upxCVX has been deprecated
     */
    function _redeem(
        uint256[] calldata unlockTimes,
        uint256[] calldata assets,
        address receiver,
        bool legacy
    ) internal {
        uint256 unlockLen = unlockTimes.length;

        if (unlockLen == 0) revert EmptyArray();
        if (unlockLen != assets.length) revert MismatchedArrayLengths();
        if (receiver == address(0)) revert ZeroAddress();

        emit Redeem(unlockTimes, assets, receiver, legacy);

        uint256 totalAssets;

        for (uint256 i; i < unlockLen; ++i) {
            uint256 asset = assets[i];

            if (!legacy && unlockTimes[i] > block.timestamp)
                revert BeforeUnlock();
            if (asset == 0) revert ZeroAmount();

            totalAssets += asset;
        }

        // Perform unlocking and locking procedure to ensure enough CVX is available
        if (!legacy) {
            _lock();
        }

        // Subtract redemption amount from outstanding CVX amount
        outstandingRedemptions -= totalAssets;

        // Reverts if sender has an insufficient upxCVX balance for any `unlockTime` id
        upxCvx.burnBatch(msg.sender, unlockTimes, assets);

        // Validates `to`
        CVX.safeTransfer(receiver, totalAssets);
    }

    /**
        @notice Calculate rewards
        @param  feePercent       uint32   Reward fee percent
        @param  snapshotSupply   uint256  pxCVX supply for the current snapshot id
        @param  rpxCvxSupply     uint256  rpxCVX supply for the current epoch
        @param  received         uint256  Received amount
        @return rewardFee        uint256  Fee for protocol
        @return snapshotRewards  uint256  Rewards for pxCVX token holders
        @return futuresRewards   uint256  Rewards for futures token holders
    */
    function _calculateRewards(
        uint32 feePercent,
        uint256 snapshotSupply,
        uint256 rpxCvxSupply,
        uint256 received
    )
        internal
        pure
        returns (
            uint256 rewardFee,
            uint256 snapshotRewards,
            uint256 futuresRewards
        )
    {
        // Rewards paid to the protocol
        rewardFee = (received * feePercent) / FEE_DENOMINATOR;

        // Rewards distributed amongst snapshot and futures tokenholders
        uint256 rewards = received - rewardFee;

        // Rewards distributed to snapshotted tokenholders
        snapshotRewards =
            (rewards * snapshotSupply) /
            (snapshotSupply + rpxCvxSupply);

        // Rewards distributed to rpxCVX token holders
        futuresRewards = rewards - snapshotRewards;
    }

    /**
        @notice Deposit CVX
        @param  assets          uint256  CVX amount
        @param  receiver        address  Receives pxCVX
        @param  shouldCompound  bool     Whether to auto-compound
        @param  developer       address  Developer incentive receiver
     */
    function deposit(
        uint256 assets,
        address receiver,
        bool shouldCompound,
        address developer
    ) external whenNotPaused nonReentrant {
        if (assets == 0) revert ZeroAmount();
        if (receiver == address(0)) revert ZeroAddress();

        emit Deposit(assets, receiver, shouldCompound, developer);

        // Track amount of CVX waiting to be locked before `assets` is modified
        pendingLocks += assets;

        // Calculate the dev incentive, which will come out of the minted pxCVX
        uint256 developerIncentive = developer != address(0) &&
            developers[developer]
            ? (assets * fees[Fees.Developers]) / FEE_DENOMINATOR
            : 0;

        // Take snapshot if necessary
        pxCvx.takeEpochSnapshot();

        // Mint pxCVX sans developer incentive - recipient depends on shouldCompound
        pxCvx.mint(
            shouldCompound ? address(this) : receiver,
            assets - developerIncentive
        );

        // Transfer CVX to self in preparation for lock
        CVX.safeTransferFrom(msg.sender, address(this), assets);

        if (developerIncentive != 0) {
            // Mint pxCVX for the developer
            pxCvx.mint(developer, developerIncentive);
        }

        if (shouldCompound) {
            // Update assets to ensure only the appropriate amount is deposited in vault
            assets -= developerIncentive;

            // Deposit pxCVX into Union vault - user receives shares
            unionPirex.deposit(assets, receiver);
        }
    }

    /**
        @notice Initiate CVX redemption
        @param  lockData   ICvxLocker.LockedBalance  Locked balance index
        @param  f          enum                      Futures enum
        @param  assets     uint256                   pxCVX amount
        @param  receiver   address                   Receives upxCVX
        @param  feeMin     uint256                   Initiate redemption fee min
        @param  feeMax     uint256                   Initiate redemption fee max
        @return feeAmount  uint256                   Fee amount
     */
    function _initiateRedemption(
        ICvxLocker.LockedBalance memory lockData,
        Futures f,
        uint256 assets,
        address receiver,
        uint256 feeMin,
        uint256 feeMax
    ) internal returns (uint256 feeAmount) {
        if (assets == 0) revert ZeroAmount();
        if (receiver == address(0)) revert ZeroAddress();

        uint256 unlockTime = lockData.unlockTime;

        // Used for calculating the fee and conditionally adding a round
        uint256 waitTime = unlockTime - block.timestamp;

        if (feeMax != 0) {
            uint256 feePercent = feeMax -
                (((feeMax - feeMin) * waitTime) / MAX_REDEMPTION_TIME);

            feeAmount = (assets * feePercent) / FEE_DENOMINATOR;
        }

        uint256 postFeeAmount = assets - feeAmount;

        // Increment redemptions for this unlockTime to prevent over-redeeming
        redemptions[unlockTime] += postFeeAmount;

        // Check if there is any sufficient allowance after factoring in redemptions by others
        if (redemptions[unlockTime] > lockData.amount)
            revert InsufficientRedemptionAllowance();

        // Track assets that needs to remain unlocked for redemptions
        outstandingRedemptions += postFeeAmount;

        // Mint upxCVX with unlockTime as the id - validates `to`
        upxCvx.mint(receiver, unlockTime, postFeeAmount, UNUSED_1155_DATA);

        // Determine how many futures notes rounds to mint
        uint256 rounds = waitTime / EPOCH_DURATION;

        // Check if the lock was in the first week/half of an epoch
        // Handle case where remaining time is between 1 and 2 weeks
        if (
            rounds == 0 &&
            unlockTime % EPOCH_DURATION != 0 &&
            waitTime > (EPOCH_DURATION / 2)
        ) {
            // Rounds is 0 if waitTime is between 1 and 2 weeks
            // Increment by 1 since user should receive 1 round of rewards
            unchecked {
                ++rounds;
            }
        }

        // Mint vpxCVX or rpxCVX (using assets as we do not take a fee from this)
        _mintFutures(rounds, f, assets, receiver);

        return feeAmount;
    }

    /**
        @notice Initiate CVX redemptions
        @param  lockIndexes  uint256[]  Locked balance index
        @param  f            enum       Futures enum
        @param  assets       uint256[]  pxCVX amounts
        @param  receiver     address    Receives upxCVX
     */
    function initiateRedemptions(
        uint256[] calldata lockIndexes,
        Futures f,
        uint256[] calldata assets,
        address receiver
    ) external whenNotPaused nonReentrant {
        uint256 lockLen = lockIndexes.length;

        if (lockLen == 0) revert EmptyArray();
        if (lockLen != assets.length) revert MismatchedArrayLengths();

        emit InitiateRedemptions(lockIndexes, f, assets, receiver);

        (, , , ICvxLocker.LockedBalance[] memory lockData) = cvxLocker
            .lockedBalances(address(this));
        uint256 totalAssets;
        uint256 feeAmount;
        uint256 feeMin = fees[Fees.RedemptionMin];
        uint256 feeMax = fees[Fees.RedemptionMax];

        for (uint256 i; i < lockLen; ++i) {
            totalAssets += assets[i];
            feeAmount += _initiateRedemption(
                lockData[lockIndexes[i]],
                f,
                assets[i],
                receiver,
                feeMin,
                feeMax
            );
        }

        // Burn pxCVX - reverts if sender balance is insufficient
        pxCvx.burn(msg.sender, totalAssets - feeAmount);

        if (feeAmount != 0) {
            // Allow PirexFees to distribute fees directly from sender
            pxCvx.operatorApprove(msg.sender, address(pirexFees), feeAmount);

            // Distribute fees
            pirexFees.distributeFees(msg.sender, address(pxCvx), feeAmount);
        }
    }

    /**
        @notice Redeem CVX for specified unlock times
        @param  unlockTimes  uint256[]  CVX unlock timestamps
        @param  assets       uint256[]  upxCVX amounts
        @param  receiver     address    Receives CVX
     */
    function redeem(
        uint256[] calldata unlockTimes,
        uint256[] calldata assets,
        address receiver
    ) external whenNotPaused nonReentrant {
        if (upxCvxDeprecated) revert RedeemClosed();

        _redeem(unlockTimes, assets, receiver, false);
    }

    /**
        @notice Redeem CVX for deprecated upxCVX holders if enabled
        @param  unlockTimes  uint256[]  CVX unlock timestamps
        @param  assets       uint256[]  upxCVX amounts
        @param  receiver     address    Receives CVX
     */
    function redeemLegacy(
        uint256[] calldata unlockTimes,
        uint256[] calldata assets,
        address receiver
    ) external whenPaused nonReentrant {
        if (!upxCvxDeprecated) revert RedeemClosed();

        _redeem(unlockTimes, assets, receiver, true);
    }

    /**
        @notice Stake pxCVX
        @param  rounds    uint256  Rounds (i.e. Convex voting rounds)
        @param  f         enum     Futures enum
        @param  assets    uint256  pxCVX amount
        @param  receiver  address  Receives spxCVX
    */
    function stake(
        uint256 rounds,
        Futures f,
        uint256 assets,
        address receiver
    ) external whenNotPaused nonReentrant {
        if (rounds == 0) revert ZeroAmount();
        if (assets == 0) revert ZeroAmount();
        if (receiver == address(0)) revert ZeroAddress();

        // Burn pxCVX
        pxCvx.burn(msg.sender, assets);

        emit Stake(rounds, f, assets, receiver);

        // Mint spxCVX with the stake expiry timestamp as the id
        spxCvx.mint(
            receiver,
            getCurrentEpoch() + EPOCH_DURATION * rounds,
            assets,
            UNUSED_1155_DATA
        );

        _mintFutures(rounds, f, assets, receiver);
    }

    /**
        @notice Unstake pxCVX
        @param  id        uint256  spxCVX id (an epoch timestamp)
        @param  assets    uint256  spxCVX amount
        @param  receiver  address  Receives pxCVX
    */
    function unstake(
        uint256 id,
        uint256 assets,
        address receiver
    ) external whenNotPaused nonReentrant {
        if (id > block.timestamp) revert BeforeStakingExpiry();
        if (assets == 0) revert ZeroAmount();
        if (receiver == address(0)) revert ZeroAddress();

        // Mint pxCVX for receiver
        pxCvx.mint(receiver, assets);

        emit Unstake(id, assets, receiver);

        // Burn spxCVX from sender
        spxCvx.burn(msg.sender, id, assets);
    }

    /**
        @notice Claim multiple Votium rewards
        @param  votiumRewards  VotiumRewards[]  Votium rewards metadata
    */
    function claimVotiumRewards(
        IVotiumMultiMerkleStash.claimParam[] calldata votiumRewards
    ) external whenNotPaused nonReentrant {
        uint256 tLen = votiumRewards.length;

        if (tLen == 0) revert EmptyArray();

        // Take snapshot before claiming rewards, if necessary
        pxCvx.takeEpochSnapshot();

        uint256 epoch = getCurrentEpoch();
        (uint256 snapshotId, , , ) = pxCvx.getEpoch(epoch);
        uint256 rpxCvxSupply = rpxCvx.totalSupply(epoch);

        for (uint256 i; i < tLen; ++i) {
            address token = votiumRewards[i].token;
            uint256 index = votiumRewards[i].index;
            uint256 amount = votiumRewards[i].amount;
            bytes32[] memory merkleProof = votiumRewards[i].merkleProof;

            if (token == address(0)) revert ZeroAddress();
            if (amount == 0) revert ZeroAmount();

            emit ClaimVotiumReward(token, index, amount);

            ERC20 t = ERC20(token);

            // Used for calculating the actual token amount received
            uint256 prevBalance = t.balanceOf(address(this));

            // Validates `token`, `index`, `amount`, and `merkleProof`
            votiumMultiMerkleStash.claim(
                token,
                index,
                address(this),
                amount,
                merkleProof
            );

            (
                uint256 rewardFee,
                uint256 snapshotRewards,
                uint256 futuresRewards
            ) = _calculateRewards(
                    fees[Fees.Reward],
                    pxCvx.totalSupplyAt(snapshotId),
                    rpxCvxSupply,
                    t.balanceOf(address(this)) - prevBalance
                );

            // Add reward token address and snapshot/futuresRewards amounts (same index for all)
            pxCvx.addEpochRewardMetadata(
                epoch,
                token.fillLast12Bytes(),
                snapshotRewards,
                futuresRewards
            );

            // Distribute fees
            t.safeApprove(address(pirexFees), rewardFee);
            pirexFees.distributeFees(address(this), token, rewardFee);
        }
    }

    /**
        @notice Claim misc. rewards (e.g. emissions) and distribute to stakeholders
     */
    function claimMiscRewards() external nonReentrant {
        // Get claimable rewards and balances
        ConvexReward[] memory c = _claimableRewards();

        emit ClaimMiscRewards(block.timestamp, c);

        // Claim rewards from Convex
        _getReward();

        uint256 cLen = c.length;

        // Iterate over rewards and distribute to stakeholders (rlBTRFLY, Redacted, and Pirex)
        for (uint256 i; i < cLen; ++i) {
            if (c[i].amount == 0) continue;

            ERC20 t = ERC20(c[i].token);
            uint256 received = t.balanceOf(address(this)) - c[i].balance;

            // Distribute fees
            t.safeApprove(address(pirexFees), received);
            pirexFees.distributeFees(address(this), c[i].token, received);
        }
    }

    /**
        @notice Redeem multiple Snapshot rewards as a pxCVX holder
        @param  epoch          uint256    Epoch
        @param  rewardIndexes  uint256[]  Reward token indexes
        @param  receiver       address    Receives snapshot rewards
    */
    function redeemSnapshotRewards(
        uint256 epoch,
        uint256[] calldata rewardIndexes,
        address receiver
    ) external whenNotPaused nonReentrant {
        if (epoch == 0) revert InvalidEpoch();
        if (receiver == address(0)) revert ZeroAddress();

        uint256 rewardLen = rewardIndexes.length;

        if (rewardLen == 0) revert EmptyArray();

        (
            uint256 snapshotId,
            bytes32[] memory rewards,
            uint256[] memory snapshotRewards,

        ) = pxCvx.getEpoch(epoch);

        // Used to update the redeemed flag locally before updating to the storage all at once for gas efficiency
        uint256 redeemed = pxCvx.getEpochRedeemedSnapshotRewards(
            msg.sender,
            epoch
        );

        // Check whether msg.sender maintained a positive balance before the snapshot
        uint256 snapshotBalance = pxCvx.balanceOfAt(msg.sender, snapshotId);
        uint256 snapshotSupply = pxCvx.totalSupplyAt(snapshotId);

        if (snapshotBalance == 0) revert InsufficientBalance();

        emit RedeemSnapshotRewards(
            epoch,
            rewardIndexes,
            receiver,
            snapshotBalance,
            snapshotSupply
        );

        for (uint256 i; i < rewardLen; ++i) {
            uint256 index = rewardIndexes[i];
            uint256 indexRedeemed = (1 << index);

            if ((redeemed & indexRedeemed) != 0) revert AlreadyRedeemed();

            redeemed |= indexRedeemed;

            ERC20(address(uint160(bytes20(rewards[index])))).safeTransfer(
                receiver,
                (snapshotRewards[index] * snapshotBalance) / snapshotSupply
            );
        }

        // Update the redeemed rewards flag in storage to prevent double claimings
        pxCvx.setEpochRedeemedSnapshotRewards(msg.sender, epoch, redeemed);
    }

    /**
        @notice Redeem futures rewards for rpxCVX holders for an epoch
        @param  epoch     uint256  Epoch (ERC1155 token id)
        @param  receiver  address  Receives futures rewards
    */
    function redeemFuturesRewards(uint256 epoch, address receiver)
        external
        whenNotPaused
        nonReentrant
    {
        if (epoch == 0) revert InvalidEpoch();
        if (epoch > getCurrentEpoch()) revert InvalidEpoch();
        if (receiver == address(0)) revert ZeroAddress();

        // Prevent users from burning their futures notes before rewards are claimed
        (, bytes32[] memory rewards, , uint256[] memory futuresRewards) = pxCvx
            .getEpoch(epoch);

        if (rewards.length == 0) revert NoRewards();

        emit RedeemFuturesRewards(epoch, receiver, rewards);

        // Check sender rpxCVX balance
        uint256 rpxCvxBalance = rpxCvx.balanceOf(msg.sender, epoch);

        if (rpxCvxBalance == 0) revert InsufficientBalance();

        // Store rpxCVX total supply before burning
        uint256 rpxCvxTotalSupply = rpxCvx.totalSupply(epoch);

        // Burn rpxCVX tokens
        rpxCvx.burn(msg.sender, epoch, rpxCvxBalance);

        uint256 rLen = rewards.length;

        // Loop over rewards and transfer the amount entitled to the rpxCVX token holder
        for (uint256 i; i < rLen; ++i) {
            uint256 rewardAmount = (futuresRewards[i] * rpxCvxBalance) /
                rpxCvxTotalSupply;

            // Update reward amount by deducting the amount transferred to the receiver
            futuresRewards[i] -= rewardAmount;

            // Proportionate to the % of rpxCVX owned out of the rpxCVX total supply
            ERC20(address(uint160(bytes20(rewards[i])))).safeTransfer(
                receiver,
                rewardAmount
            );
        }

        // Update future rewards to reflect the amounts remaining post-redemption
        pxCvx.updateEpochFuturesRewards(epoch, futuresRewards);
    }

    /**
        @notice Exchange one futures token for another
        @param  epoch     uint256  Epoch (ERC1155 token id)
        @param  amount    uint256  Exchange amount
        @param  receiver  address  Receives futures token
        @param  f         enum     Futures enum
    */
    function exchangeFutures(
        uint256 epoch,
        uint256 amount,
        address receiver,
        Futures f
    ) external whenNotPaused {
        // Users can only exchange futures tokens for future epochs
        if (epoch <= getCurrentEpoch()) revert PastExchangePeriod();
        if (amount == 0) revert ZeroAmount();
        if (receiver == address(0)) revert ZeroAddress();

        ERC1155PresetMinterSupply futuresIn = f == Futures.Vote
            ? vpxCvx
            : rpxCvx;
        ERC1155PresetMinterSupply futuresOut = f == Futures.Vote
            ? rpxCvx
            : vpxCvx;

        emit ExchangeFutures(epoch, amount, receiver, f);

        // Validates `amount` (balance)
        futuresIn.burn(msg.sender, epoch, amount);

        // Validates `to`
        futuresOut.mint(receiver, epoch, amount, UNUSED_1155_DATA);
    }

    /*//////////////////////////////////////////////////////////////
                        EMERGENCY/MIGRATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /** 
        @notice Initialize the emergency executor address
        @param  _emergencyExecutor  address  Non-Pirex multisig
     */
    function initializeEmergencyExecutor(address _emergencyExecutor)
        external
        onlyOwner
        whenPaused
    {
        if (_emergencyExecutor == address(0)) revert ZeroAddress();
        if (emergencyExecutor != address(0)) revert AlreadyInitialized();

        emergencyExecutor = _emergencyExecutor;

        emit InitializeEmergencyExecutor(_emergencyExecutor);
    }

    /** 
        @notice Set the emergency migration data
        @param  _emergencyMigration  EmergencyMigration  Emergency migration data
     */
    function setEmergencyMigration(
        EmergencyMigration calldata _emergencyMigration
    ) external onlyOwner whenPaused {
        if (emergencyExecutor == address(0)) revert NoEmergencyExecutor();
        if (_emergencyMigration.recipient == address(0))
            revert InvalidEmergencyMigration();
        if (_emergencyMigration.tokens.length == 0)
            revert InvalidEmergencyMigration();

        emergencyMigration = _emergencyMigration;

        emit SetEmergencyMigration(_emergencyMigration);
    }

    /** 
        @notice Execute the emergency migration
     */
    function executeEmergencyMigration() external whenPaused {
        if (msg.sender != emergencyExecutor) revert NotAuthorized();

        address migrationRecipient = emergencyMigration.recipient;

        if (migrationRecipient == address(0))
            revert InvalidEmergencyMigration();

        address[] memory migrationTokens = emergencyMigration.tokens;
        uint256 tLen = migrationTokens.length;

        if (tLen == 0) revert InvalidEmergencyMigration();

        uint256 o = outstandingRedemptions;

        for (uint256 i; i < tLen; ++i) {
            ERC20 token = ERC20(migrationTokens[i]);
            uint256 balance = token.balanceOf(address(this));

            if (token == CVX) {
                // Transfer the diff between CVX balance and outstandingRedemptions
                balance = balance > o ? balance - o : 0;
            }

            token.safeTransfer(migrationRecipient, balance);
        }

        emit ExecuteEmergencyMigration(migrationRecipient, migrationTokens);
    }

    /**
        @notice Set whether the currently set upxCvx is deprecated or not
        @param  state  bool  Deprecation state
     */
    function setUpxCvxDeprecated(bool state) external onlyOwner whenPaused {
        upxCvxDeprecated = state;

        emit SetUpxCvxDeprecated(state);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
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

// SPDX-License-Identifier: AGPL-3.0-only
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
pragma solidity 0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {ICvxLocker} from "./interfaces/ICvxLocker.sol";
import {ICvxDelegateRegistry} from "./interfaces/ICvxDelegateRegistry.sol";

contract PirexCvxConvex is Ownable, Pausable {
    using SafeTransferLib for ERC20;

    /**
        @notice Convex reward details
        @param  token    address  Token
        @param  amount   uint256  Amount
        @param  balance  uint256  Balance (used for calculating the actual received amount)
     */
    struct ConvexReward {
        address token;
        uint256 amount;
        uint256 balance;
    }

    // Configurable contracts
    enum ConvexContract {
        CvxLocker,
        CvxDelegateRegistry
    }

    ERC20 public immutable CVX;

    ICvxLocker public cvxLocker;
    ICvxDelegateRegistry public cvxDelegateRegistry;

    // Convex Snapshot space
    bytes32 public delegationSpace = bytes32("cvx.eth");

    // The amount of CVX that needs to remain unlocked for redemptions
    uint256 public outstandingRedemptions;

    // The amount of new CVX deposits that is awaiting lock
    uint256 public pendingLocks;

    event SetConvexContract(ConvexContract c, address contractAddress);
    event SetDelegationSpace(string _delegationSpace, bool shouldClear);
    event SetVoteDelegate(address voteDelegate);
    event ClearVoteDelegate();

    error ZeroAddress();
    error EmptyString();

    /**
        @param  _CVX                  address  CVX address    
        @param  _cvxLocker            address  CvxLocker address
        @param  _cvxDelegateRegistry  address  CvxDelegateRegistry address
     */
    constructor(
        address _CVX,
        address _cvxLocker,
        address _cvxDelegateRegistry
    ) {
        if (_CVX == address(0)) revert ZeroAddress();
        if (_cvxLocker == address(0)) revert ZeroAddress();
        if (_cvxDelegateRegistry == address(0)) revert ZeroAddress();

        CVX = ERC20(_CVX);
        cvxLocker = ICvxLocker(_cvxLocker);
        cvxDelegateRegistry = ICvxDelegateRegistry(_cvxDelegateRegistry);

        // Max allowance for cvxLocker
        CVX.safeApprove(address(cvxLocker), type(uint256).max);
    }

    /** 
        @notice Set a contract address
        @param  c                enum     ConvexContract enum
        @param  contractAddress  address  Contract address    
     */
    function setConvexContract(ConvexContract c, address contractAddress)
        external
        onlyOwner
    {
        if (contractAddress == address(0)) revert ZeroAddress();

        emit SetConvexContract(c, contractAddress);

        if (c == ConvexContract.CvxLocker) {
            // Revoke approval from the old locker and add allowances to the new locker
            CVX.safeApprove(address(cvxLocker), 0);

            cvxLocker = ICvxLocker(contractAddress);

            CVX.safeApprove(contractAddress, type(uint256).max);
            return;
        }

        cvxDelegateRegistry = ICvxDelegateRegistry(contractAddress);
    }

    /**
        @notice Unlock CVX
     */
    function _unlock() internal {
        (, uint256 unlockable, , ) = cvxLocker.lockedBalances(address(this));

        if (unlockable != 0) cvxLocker.processExpiredLocks(false);
    }

    /**
        @notice Unlock CVX and relock excess
     */
    function _lock() internal {
        _unlock();

        uint256 balance = CVX.balanceOf(address(this));
        bool balanceGreaterThanRedemptions = balance > outstandingRedemptions;

        // Lock CVX if the balance is greater than outstanding redemptions or if there are pending locks
        if (balanceGreaterThanRedemptions || pendingLocks != 0) {
            uint256 balanceRedemptionsDifference = balanceGreaterThanRedemptions
                ? balance - outstandingRedemptions
                : 0;

            // Lock amount is the greater of the two: balanceRedemptionsDifference or pendingLocks
            // balanceRedemptionsDifference is greater if there is unlocked CVX that isn't reserved for redemptions + deposits
            // pendingLocks is greater if there are more new deposits than unlocked CVX that is reserved for redemptions
            cvxLocker.lock(
                address(this),
                balanceRedemptionsDifference > pendingLocks
                    ? balanceRedemptionsDifference
                    : pendingLocks,
                0
            );

            pendingLocks = 0;
        }
    }

    /**
        @notice Non-permissioned relock method
     */
    function lock() external whenNotPaused {
        _lock();
    }

    /**
        @notice Get claimable rewards and balances
        @return rewards  ConvexReward[]  Claimable rewards and balances
     */
    function _claimableRewards()
        internal
        view
        returns (ConvexReward[] memory rewards)
    {
        address addr = address(this);

        // Get claimable rewards
        ICvxLocker.EarnedData[] memory c = cvxLocker.claimableRewards(addr);

        uint256 cLen = c.length;
        rewards = new ConvexReward[](cLen);

        // Get the current balances for each token to calculate the amount received
        for (uint256 i; i < cLen; ++i) {
            rewards[i] = ConvexReward({
                token: c[i].token,
                amount: c[i].amount,
                balance: ERC20(c[i].token).balanceOf(addr)
            });
        }
    }

    /** 
        @notice Claim Convex rewards
     */
    function _getReward() internal {
        // Claim rewards from Convex
        cvxLocker.getReward(address(this), false);
    }

    /** 
        @notice Set delegationSpace
        @param  _delegationSpace  string  Convex Snapshot delegation space
        @param  shouldClear       bool    Whether to clear the vote delegate for current delegation space
     */
    function setDelegationSpace(
        string memory _delegationSpace,
        bool shouldClear
    ) external onlyOwner {
        if (shouldClear) {
            // Clear the delegation for the current delegation space
            clearVoteDelegate();
        }

        bytes memory d = bytes(_delegationSpace);

        if (d.length == 0) revert EmptyString();

        delegationSpace = bytes32(d);

        emit SetDelegationSpace(_delegationSpace, shouldClear);
    }

    /**
        @notice Set vote delegate
        @param  voteDelegate  address  Account to delegate votes to
     */
    function setVoteDelegate(address voteDelegate) external onlyOwner {
        if (voteDelegate == address(0)) revert ZeroAddress();

        emit SetVoteDelegate(voteDelegate);

        cvxDelegateRegistry.setDelegate(delegationSpace, voteDelegate);
    }

    /**
        @notice Remove vote delegate
     */
    function clearVoteDelegate() public onlyOwner {
        emit ClearVoteDelegate();

        cvxDelegateRegistry.clearDelegate(delegationSpace);
    }

    /*//////////////////////////////////////////////////////////////
                        EMERGENCY/MIGRATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /** 
        @notice Set the contract's pause state
        @param state  bool  Pause state
    */
    function setPauseState(bool state) external onlyOwner {
        if (state) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
        @notice Manually unlock CVX in the case of a mass unlock
     */
    function unlock() external whenPaused onlyOwner {
        cvxLocker.processExpiredLocks(false);
    }

    /**
        @notice Manually relock CVX with a new CvxLocker contract
     */
    function pausedRelock() external whenPaused onlyOwner {
        _lock();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ERC20SnapshotSolmate} from "./tokens/ERC20SnapshotSolmate.sol";

contract PxCvx is ERC20SnapshotSolmate("Pirex CVX", "pxCVX", 18), Ownable {
    /**
        @notice Epoch details
                Reward/snapshotRewards/futuresRewards indexes are associated with 1 reward
        @param  snapshotId               uint256    Snapshot id
        @param  rewards                  bytes32[]  Rewards
        @param  snapshotRewards          uint256[]  Snapshot reward amounts
        @param  futuresRewards           uint256[]  Futures reward amounts
        @param  redeemedSnapshotRewards  mapping    Redeemed snapshot rewards
     */
    struct Epoch {
        uint256 snapshotId;
        bytes32[] rewards;
        uint256[] snapshotRewards;
        uint256[] futuresRewards;
        mapping(address => uint256) redeemedSnapshotRewards;
    }

    // Address of currently assigned operator
    address public operator;

    // Epochs mapped to epoch details
    mapping(uint256 => Epoch) private epochs;

    event SetOperator(address operator);
    event UpdateEpochFuturesRewards(
        uint256 indexed epoch,
        uint256[] futuresRewards
    );

    error NotAuthorized();
    error NoOperator();
    error Paused();
    error ZeroAddress();
    error ZeroAmount();
    error InvalidEpoch();
    error InvalidFuturesRewards();
    error MismatchedFuturesRewards();

    modifier onlyOperator() {
        if (msg.sender != operator) revert NotAuthorized();
        _;
    }

    modifier onlyOperatorOrNotPaused() {
        address _operator = operator;

        // Ensure an operator is set
        if (_operator == address(0)) revert NoOperator();

        // This contract shares the same pause state as the operator
        if (msg.sender != _operator && Pausable(_operator).paused())
            revert Paused();
        _;
    }

    /** 
        @notice Set a new operator address
        @param  _operator  address  New operator address    
     */
    function setOperator(address _operator) external onlyOwner {
        if (_operator == address(0)) revert ZeroAddress();

        emit SetOperator(_operator);

        // If it's the first operator, also set up 1st epoch with snapshot id 1
        // and prevent reward claims until subsequent epochs
        if (operator == address(0)) {
            uint256 currentEpoch = getCurrentEpoch();
            epochs[currentEpoch].snapshotId = _snapshot();
        }

        operator = _operator;
    }

    /** 
        @notice Return the current snapshotId
        @return uint256  Current snapshot id
     */
    function getCurrentSnapshotId() external view returns (uint256) {
        return _getCurrentSnapshotId();
    }

    /**
        @notice Get current epoch
        @return uint256  Current epoch
     */
    function getCurrentEpoch() public view returns (uint256) {
        return (block.timestamp / 1209600) * 1209600;
    }

    /**
        @notice Get epoch
        @param  epoch            uint256    Epoch
        @return snapshotId       uint256    Snapshot id
        @return rewards          address[]  Reward tokens
        @return snapshotRewards  uint256[]  Snapshot reward amounts
        @return futuresRewards   uint256[]  Futures reward amounts
     */
    function getEpoch(uint256 epoch)
        external
        view
        returns (
            uint256 snapshotId,
            bytes32[] memory rewards,
            uint256[] memory snapshotRewards,
            uint256[] memory futuresRewards
        )
    {
        Epoch storage e = epochs[epoch];

        return (e.snapshotId, e.rewards, e.snapshotRewards, e.futuresRewards);
    }

    /**
        @notice Get redeemed snapshot rewards bitmap
        @param  account  address   Account
        @param  epoch    uint256   Epoch
        @return uint256  Redeemed snapshot bitmap
     */
    function getEpochRedeemedSnapshotRewards(address account, uint256 epoch)
        external
        view
        returns (uint256)
    {
        return epochs[epoch].redeemedSnapshotRewards[account];
    }

    /**
        @notice Add new epoch reward metadata
        @param  epoch           uint256  Epoch
        @param  token           address  Token address
        @param  snapshotReward  uint256  Snapshot reward amount
        @param  futuresReward   uint256  Futures reward amount
     */
    function addEpochRewardMetadata(
        uint256 epoch,
        bytes32 token,
        uint256 snapshotReward,
        uint256 futuresReward
    ) external onlyOperator {
        Epoch storage e = epochs[epoch];

        e.rewards.push(token);
        e.snapshotRewards.push(snapshotReward);
        e.futuresRewards.push(futuresReward);
    }

    /**
        @notice Set redeemed snapshot rewards bitmap
        @param  account   address  Account
        @param  epoch     uint256  Epoch
        @param  redeemed  uint256  Redeemed bitmap
     */
    function setEpochRedeemedSnapshotRewards(
        address account,
        uint256 epoch,
        uint256 redeemed
    ) external onlyOperator {
        epochs[epoch].redeemedSnapshotRewards[account] = redeemed;
    }

    /**
        @notice Update epoch futures rewards to reflect amounts remaining after redemptions
        @param  epoch           uint256    Epoch
        @param  futuresRewards  uint256[]  Futures rewards
     */
    function updateEpochFuturesRewards(
        uint256 epoch,
        uint256[] memory futuresRewards
    ) external onlyOperator {
        if (epoch == 0) revert InvalidEpoch();

        uint256 fLen = epochs[epoch].futuresRewards.length;

        if (fLen == 0) revert InvalidEpoch();
        if (futuresRewards.length == 0) revert InvalidFuturesRewards();
        if (futuresRewards.length != fLen) revert MismatchedFuturesRewards();

        epochs[epoch].futuresRewards = futuresRewards;

        emit UpdateEpochFuturesRewards(epoch, futuresRewards);
    }

    /** 
        @notice Mint the specified amount of tokens to the specified account
        @param  account  address  Receiver of the tokens
        @param  amount   uint256  Amount to be minted
     */
    function mint(address account, uint256 amount) external onlyOperator {
        if (account == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        _mint(account, amount);
    }

    /** 
        @notice Burn the specified amount of tokens from the specified account
        @param  account  address  Owner of the tokens
        @param  amount   uint256  Amount to be burned
     */
    function burn(address account, uint256 amount) external onlyOperator {
        if (account == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        _burn(account, amount);
    }

    /** 
        @notice Approve allowances by operator with specified accounts and amount
        @param  from    address  Owner of the tokens
        @param  to      address  Account to be approved
        @param  amount  uint256  Amount to be approved
     */
    function operatorApprove(
        address from,
        address to,
        uint256 amount
    ) external onlyOperator {
        if (from == address(0)) revert ZeroAddress();
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        _approve(from, to, amount);
    }

    /**
        @notice Snapshot token balances for the current epoch
     */
    function takeEpochSnapshot() external onlyOperatorOrNotPaused {
        uint256 currentEpoch = getCurrentEpoch();

        // If snapshot has not been set for current epoch, take snapshot
        if (epochs[currentEpoch].snapshotId == 0) {
            epochs[currentEpoch].snapshotId = _snapshot();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";

contract PirexFees is Ownable {
    using SafeTransferLib for ERC20;

    // Types of fee recipients
    enum FeeRecipient {
        Treasury,
        Contributors
    }

    uint8 public constant PERCENT_DENOMINATOR = 100;

    // Configurable fee recipient percent-share
    uint8 public treasuryPercent = 75;

    // Configurable fee recipient addresses
    address public treasury;
    address public contributors;

    event SetFeeRecipient(FeeRecipient f, address recipient);
    event SetTreasuryPercent(uint8 _treasuryPercent);
    event DistributeFees(address token, uint256 amount);

    error ZeroAddress();
    error InvalidFeePercent();

    /**
        @param  _treasury      address  Redacted treasury
        @param  _contributors  address  Pirex contributor multisig
     */
    constructor(address _treasury, address _contributors) {
        if (_treasury == address(0)) revert ZeroAddress();
        if (_contributors == address(0)) revert ZeroAddress();

        treasury = _treasury;
        contributors = _contributors;
    }

    /** 
        @notice Set a fee recipient address
        @param  f          enum     FeeRecipient enum
        @param  recipient  address  Fee recipient address
     */
    function setFeeRecipient(FeeRecipient f, address recipient)
        external
        onlyOwner
    {
        if (recipient == address(0)) revert ZeroAddress();

        emit SetFeeRecipient(f, recipient);

        if (f == FeeRecipient.Treasury) {
            treasury = recipient;
            return;
        }

        contributors = recipient;
    }

    /** 
        @notice Set treasury fee percent
        @param  _treasuryPercent  uint8  Treasury fee percent
     */
    function setTreasuryPercent(uint8 _treasuryPercent) external onlyOwner {
        // Treasury fee percent should never exceed 75
        if (_treasuryPercent > 75) revert InvalidFeePercent();

        treasuryPercent = _treasuryPercent;

        emit SetTreasuryPercent(_treasuryPercent);
    }

    /** 
        @notice Distribute fees
        @param  from    address  Fee source
        @param  token   address  Fee token
        @param  amount  uint256  Fee token amount
     */
    function distributeFees(
        address from,
        address token,
        uint256 amount
    ) external {
        emit DistributeFees(token, amount);

        ERC20 t = ERC20(token);
        uint256 treasuryDistribution = (amount * treasuryPercent) /
            PERCENT_DENOMINATOR;

        // Favoring push over pull to reduce accounting complexity for different tokens
        t.safeTransferFrom(from, treasury, treasuryDistribution);
        t.safeTransferFrom(from, contributors, amount - treasuryDistribution);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC4626} from "@rari-capital/solmate/src/mixins/ERC4626.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {FixedPointMathLib} from "@rari-capital/solmate/src/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {UnionPirexStaking} from "./UnionPirexStaking.sol";

contract UnionPirexVault is Ownable, ERC4626 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    UnionPirexStaking public strategy;

    uint256 public constant MAX_WITHDRAWAL_PENALTY = 500;
    uint256 public constant MAX_PLATFORM_FEE = 2000;
    uint256 public constant FEE_DENOMINATOR = 10000;

    uint256 public withdrawalPenalty = 300;
    uint256 public platformFee = 1000;
    address public platform;

    event Harvest(address indexed caller, uint256 value);
    event WithdrawalPenaltyUpdated(uint256 penalty);
    event PlatformFeeUpdated(uint256 fee);
    event PlatformUpdated(address indexed _platform);
    event StrategySet(address indexed _strategy);

    error ZeroAddress();
    error ExceedsMax();
    error AlreadySet();

    constructor(address pxCvx) ERC4626(ERC20(pxCvx), "Union Pirex", "uCVX") {}

    /**
        @notice Set the withdrawal penalty
        @param  penalty  uint256  Withdrawal penalty
     */
    function setWithdrawalPenalty(uint256 penalty) external onlyOwner {
        if (penalty > MAX_WITHDRAWAL_PENALTY) revert ExceedsMax();

        withdrawalPenalty = penalty;

        emit WithdrawalPenaltyUpdated(penalty);
    }

    /**
        @notice Set the platform fee
        @param  fee  uint256  Platform fee
     */
    function setPlatformFee(uint256 fee) external onlyOwner {
        if (fee > MAX_PLATFORM_FEE) revert ExceedsMax();

        platformFee = fee;

        emit PlatformFeeUpdated(fee);
    }

    /**
        @notice Set the platform
        @param  _platform  address  Platform
     */
    function setPlatform(address _platform) external onlyOwner {
        if (_platform == address(0)) revert ZeroAddress();

        platform = _platform;

        emit PlatformUpdated(_platform);
    }

    /**
        @notice Set the strategy
        @param  _strategy  address  Strategy
     */
    function setStrategy(address _strategy) external onlyOwner {
        if (_strategy == address(0)) revert ZeroAddress();
        if (address(strategy) != address(0)) revert AlreadySet();

        // Set new strategy contract and approve max allowance
        strategy = UnionPirexStaking(_strategy);

        asset.safeApprove(_strategy, type(uint256).max);

        emit StrategySet(_strategy);
    }

    /**
        @notice Get the pxCVX custodied by the UnionPirex contracts
        @return uint256  Assets
     */
    function totalAssets() public view override returns (uint256) {
        // Vault assets + rewards should always be stored in strategy until withdrawal-time
        (uint256 _totalSupply, uint256 rewards) = strategy
            .totalSupplyWithRewards();

        // Deduct the exact reward amount staked (after fees are deducted when calling `harvest`)
        return
            _totalSupply +
            (
                rewards == 0
                    ? 0
                    : (rewards - ((rewards * platformFee) / FEE_DENOMINATOR))
            );
    }

    /**
        @notice Withdraw assets from the staking contract to prepare for transfer to user
        @param  assets  uint256  Assets
     */
    function beforeWithdraw(uint256 assets, uint256) internal override {
        // Harvest rewards in the event where there is not enough staked assets to cover the withdrawal
        if (assets > strategy.totalSupply()) harvest();

        strategy.withdraw(assets);
    }

    /**
        @notice Stake assets so that rewards can be properly distributed
        @param  assets  uint256  Assets
     */
    function afterDeposit(uint256 assets, uint256) internal override {
        strategy.stake(assets);
    }

    /**
        @notice Preview the amount of assets a user would receive from redeeming shares
        @param  shares  uint256  Shares
        @return uint256  Assets
     */
    function previewRedeem(uint256 shares)
        public
        view
        override
        returns (uint256)
    {
        // Calculate assets based on a user's % ownership of vault shares
        uint256 assets = convertToAssets(shares);

        uint256 _totalSupply = totalSupply;

        // Calculate a penalty - zero if user is the last to withdraw
        uint256 penalty = (_totalSupply == 0 || _totalSupply - shares == 0)
            ? 0
            : assets.mulDivDown(withdrawalPenalty, FEE_DENOMINATOR);

        // Redeemable amount is the post-penalty amount
        return assets - penalty;
    }

    /**
        @notice Preview the amount of shares a user would need to redeem the specified asset amount
        @notice This modified version takes into consideration the withdrawal fee
        @param  assets  uint256  Assets
        @return uint256  Shares
     */
    function previewWithdraw(uint256 assets)
        public
        view
        override
        returns (uint256)
    {
        // Calculate shares based on the specified assets' proportion of the pool
        uint256 shares = convertToShares(assets);

        // Save 1 SLOAD
        uint256 _totalSupply = totalSupply;

        // Factor in additional shares to fulfill withdrawal if user is not the last to withdraw
        return
            (_totalSupply == 0 || _totalSupply - shares == 0)
                ? shares
                : (shares * FEE_DENOMINATOR) /
                    (FEE_DENOMINATOR - withdrawalPenalty);
    }

    /**
        @notice Harvest rewards
     */
    function harvest() public {
        // Claim rewards
        strategy.getReward();

        // Since we don't normally store pxCVX within the vault, a non-zero balance equals rewards
        uint256 rewards = asset.balanceOf(address(this));

        emit Harvest(msg.sender, rewards);

        if (rewards != 0) {
            // Fee for platform
            uint256 feeAmount = (rewards * platformFee) / FEE_DENOMINATOR;

            // Deduct fee from reward balance
            rewards -= feeAmount;

            // Claimed rewards should be in pxCVX
            asset.safeTransfer(platform, feeAmount);

            // Stake rewards sans fee
            strategy.stake(rewards);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/presets/ERC1155PresetMinterPauser.sol)

pragma solidity 0.8.12;

import {ERC1155} from "@rari-capital/solmate/src/tokens/ERC1155.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev {ERC1155} token, including:
 *
 *  - ability to check the total supply for a token id
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract ERC1155Solmate is AccessControl, ERC1155 {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event GrantMinterRole(address minter);
    event RevokeMinterRole(address minter);

    error ZeroAddress();
    error NotMinter();

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
        @notice Grant the minter role to an address
        @param  minter  address  Address to grant the minter role
     */
    function grantMinterRole(address minter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (minter == address(0)) revert ZeroAddress();

        _grantRole(MINTER_ROLE, minter);

        emit GrantMinterRole(minter);
    }

    /**
     @notice Revoke the minter role from an address
     @param  minter  address  Address to revoke the minter role
  */
    function revokeMinterRole(address minter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (hasRole(MINTER_ROLE, minter) == false) revert NotMinter();

        _revokeRole(MINTER_ROLE, minter);

        emit RevokeMinterRole(minter);
    }

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external onlyRole(MINTER_ROLE) {
        _mint(to, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external onlyRole(MINTER_ROLE) {
        _batchMint(to, ids, amounts, data);
    }

    function burnBatch(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyRole(MINTER_ROLE) {
        _batchBurn(from, ids, amounts);
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) {
        _burn(from, id, amount);
    }

    function uri(uint256 id) public view override returns (string memory) {}

    // Necessary override due to AccessControl having the same method
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(AccessControl, ERC1155)
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev {ERC1155} token, including:
 *
 *  - ability to check the total supply for a token id
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter role as well
 * as the default admin role, which will let it grant the minter role to other accounts.
 */
contract ERC1155PresetMinterSupply is
    Context,
    AccessControl,
    ERC1155Supply,
    ERC1155Burnable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` and `MINTER_ROLE` to the account that
     * deploys the contract.
     */
    constructor(string memory uri) ERC1155(uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC1155PresetMinterPauser: must have minter role to mint"
        );

        _mint(to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC1155PresetMinterPauser: must have minter role to mint"
        );

        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IVotiumMultiMerkleStash {
    struct claimParam {
        address token;
        uint256 index;
        uint256 amount;
        bytes32[] merkleProof;
    }

    function claim(
        address token,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface ICvxLocker {
    struct LockedBalance {
        uint112 amount;
        uint112 boosted;
        uint32 unlockTime;
    }
    struct EarnedData {
        address token;
        uint256 amount;
    }

    function lock(
        address _account,
        uint256 _amount,
        uint256 _spendRatio
    ) external;

    function lockedBalances(address _user)
        external
        view
        returns (
            uint256 total,
            uint256 unlockable,
            uint256 locked,
            LockedBalance[] memory lockData
        );

    function processExpiredLocks(bool _relock) external;

    function claimableRewards(address _account)
        external
        view
        returns (EarnedData[] memory userRewards);

    function getReward(address _account, bool _stake) external;

    function lockedBalanceOf(address _user)
        external
        view
        returns (uint256 amount);
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.12;

interface ICvxDelegateRegistry {
    function setDelegate(bytes32 id, address delegate) external;

    function clearDelegate(bytes32 id) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Snapshot.sol)

pragma solidity ^0.8.0;

import {Arrays} from "@openzeppelin/contracts/utils/Arrays.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

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

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        allowance[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _beforeTokenTransfer(msg.sender, to, amount);

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
        _beforeTokenTransfer(from, to, amount);

        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

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
            address recoveredAddress = ECDSA.recover(
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

            require(
                recoveredAddress != address(0) && recoveredAddress == owner,
                "INVALID_SIGNER"
            );

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
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
        _beforeTokenTransfer(address(0), to, amount);

        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        _beforeTokenTransfer(from, address(0), amount);

        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
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
}

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the begining of each new block. When overridding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

contract ERC20SnapshotSolmate is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {}

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId)
        public
        view
        virtual
        returns (uint256)
    {
        (bool snapshotted, uint256 value) = _valueAt(
            snapshotId,
            _accountBalanceSnapshots[account]
        );

        return snapshotted ? value : balanceOf[account];
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId)
        public
        view
        virtual
        returns (uint256)
    {
        (bool snapshotted, uint256 value) = _valueAt(
            snapshotId,
            _totalSupplySnapshots
        );

        return snapshotted ? value : totalSupply;
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots)
        private
        view
        returns (bool, uint256)
    {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(
            snapshotId <= _getCurrentSnapshotId(),
            "ERC20Snapshot: nonexistent id"
        );

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf[account]);
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply);
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue)
        private
    {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids)
        private
        view
        returns (uint256)
    {
        uint256 idsLen = ids.length;

        if (idsLen == 0) {
            return 0;
        } else {
            return ids[idsLen - 1];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";
import {SafeTransferLib} from "../utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "../utils/FixedPointMathLib.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
abstract contract ERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// https://docs.synthetix.io/contracts/source/contracts/StakingRewards/
// https://github.com/Synthetixio/synthetix/blob/v2.66.0/contracts/StakingRewards.sol
/**
  Modifications
    - Pin pragma to 0.8.12
    - Remove IStakingRewards, RewardsDistributionRecipient, and Pausable
    - Add and inherit from Ownable
    - Add `RewardsDistributionRecipient` logic to contract
    - Add `vault` state variable and `onlyVault` modifier
    - Add `onlyVault` modifier to `stake` method
    - Change `rewardsDuration` to 14 days
    - Update contract to support only the vault as a user
    - Remove SafeMath since pragma 0.8.0 has those checks built-in
    - Replace OpenZeppelin ERC20, ReentrancyGuard, and SafeERC20 with Solmate v6 (audited)
    - Consolidate `rewardsToken` and `stakingToken` since they're the same
    - Remove `onlyVault` modifier from getReward
    - Remove ReentrancyGuard as it is no longer needed
    - Add `totalSupplyWithRewards` method to save gas as _totalSupply + rewards are accessed by vault
    - Updated `notifyRewardsAmount`
        - Remove the method parameter and compute the reward amount inside the function
        - Remove the conditional logic since we will always distribute the rewards balance
        - Remove overflow check since the caller cannot pass in the reward amount
*/
contract UnionPirexStaking is Ownable {
    using SafeTransferLib for ERC20;

    /* ========== STATE VARIABLES ========== */

    address public immutable vault;
    ERC20 public immutable token;

    uint256 public constant rewardsDuration = 14 days;

    address public distributor;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public userRewardPerTokenPaid;
    uint256 public rewards;

    uint256 internal _totalSupply;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _token,
        address _distributor,
        address _vault
    ) {
        token = ERC20(_token);
        distributor = _distributor;
        vault = _vault;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function totalSupplyWithRewards() external view returns (uint256, uint256) {
        uint256 t = _totalSupply;

        return (
            t,
            ((t * (rewardPerToken() - userRewardPerTokenPaid)) / 1e18) + rewards
        );
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            ((((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate) *
                1e18) / _totalSupply);
    }

    function earned() public view returns (uint256) {
        return
            ((_totalSupply * (rewardPerToken() - userRewardPerTokenPaid)) /
                1e18) + rewards;
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * rewardsDuration;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external onlyVault updateReward(vault) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply += amount;
        token.safeTransferFrom(vault, address(this), amount);
        emit Staked(amount);
    }

    function withdraw(uint256 amount) external onlyVault updateReward(vault) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply -= amount;
        token.safeTransfer(vault, amount);
        emit Withdrawn(amount);
    }

    function getReward() external updateReward(vault) {
        uint256 reward = rewards;

        if (reward > 0) {
            rewards = 0;
            token.safeTransfer(vault, reward);
            emit RewardPaid(reward);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount()
        external
        onlyDistributor
        updateReward(address(0))
    {
        // Rewards transferred directly to this contract are not added to _totalSupply
        // To get the rewards w/o relying on a potentially incorrect passed in arg,
        // we can use the difference between the token balance and _totalSupply.
        // Additionally, to avoid re-distributing rewards, deduct the output of `earned`
        uint256 rewardBalance = token.balanceOf(address(this)) -
            _totalSupply -
            earned();

        rewardRate = rewardBalance / rewardsDuration;
        require(rewardRate != 0, "No rewards");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;

        emit RewardAdded(rewardBalance);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        require(
            tokenAddress != address(token),
            "Cannot withdraw the staking token"
        );
        ERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setDistributor(address _distributor) external onlyOwner {
        require(_distributor != address(0));
        distributor = _distributor;
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards = earned();
            userRewardPerTokenPaid = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(uint256 amount);
    event Withdrawn(uint256 amount);
    event RewardPaid(uint256 reward);
    event Recovered(address token, uint256 amount);

    modifier onlyDistributor() {
        require((msg.sender == distributor), "Distributor only");
        _;
    }

    modifier onlyVault() {
        require((msg.sender == vault), "Vault only");
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*///////////////////////////////////////////////////////////////
                            ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                             ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < idsLength; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        uint256 ownersLength = owners.length; // Saves MLOADs.

        require(ownersLength == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](ownersLength);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < ownersLength; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
interface ERC1155TokenReceiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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