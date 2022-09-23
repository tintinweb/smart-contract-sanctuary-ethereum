// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {RedeemableERC20} from "../redeemableERC20/RedeemableERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./SaleEscrow.sol";

/// Escrow contract for ERC20 tokens to be deposited and withdrawn against
/// redeemableERC20 tokens from a specific `Sale`.
///
/// When some token is deposited the running total of that token against the
/// trust is incremented by the deposited amount. When some `redeemableERC20`
/// token holder calls `withdraw` they are sent the full balance they have not
/// previously claimed, multiplied by their fraction of the redeemable token
/// supply that they currently hold. As redeemable tokens are frozen after
/// distribution there are no issues with holders manipulating withdrawals by
/// transferring tokens to claim multiple times.
///
/// As redeemable tokens can be burned it is possible for the total supply to
/// decrease over time, which naively would result in claims being larger
/// retroactively (prorata increases beyond what can be paid).
///
/// For example:
/// - Alice and Bob hold 50 rTKN each, 100 total supply
/// - 100 TKN is deposited
/// - Alice withdraws 50% of 100 TKN => alice holds 50 TKN escrow holds 50 TKN
/// - Alice burns her 50 rTKN
/// - Bob attempts to withdraw his 50 rTKN which is now 100% of supply
/// - Escrow tries to pay 100% of 100 TKN deposited and fails as the escrow
///   only holds 50 TKN (alice + bob = 150%).
///
/// To avoid the escrow allowing more withdrawals than deposits we include the
/// total rTKN supply in the key of each deposit mapping, and include it in the
/// emmitted event. Alice and Bob must read the events offchain and make a
/// withdrawal relative to the rTKN supply as it was at deposit time. Many
/// deposits can be made under a single rTKN supply and will all combine to a
/// single withdrawal but deposits made across different supplies will require
/// multiple withdrawals.
///
/// Alice or Bob could burn their tokens before withdrawing and would simply
/// withdraw zero or only some of the deposited TKN. This hurts them
/// individually, so they SHOULD check their indexer for claimable assets in
/// the escrow before considering a burn. But neither of them can cause the
/// other to be able to withdraw more or less relative to the supply as it was
/// at the time of TKN being deposited, or to trick the escrow into overpaying
/// more TKN than was deposited under a given `Sale`.
///
/// A griefer could attempt to flood the escrow with many dust deposits under
/// many different supplies in an attempt to confuse alice/bob. They are free
/// to filter out events in their indexer that come from an unknown depositor
/// or fall below some dust value threshold.
///
/// Tokens may also exit the escrow as an `undeposit` call where the depositor
/// receives back the tokens they deposited. As above the depositor must
/// provide the rTKN supply from `deposit` time in order to `undeposit`.
///
/// As `withdraw` and `undeposit` both represent claims on the same tokens they
/// are mutually exclusive outcomes, hence the need for an escrow. The escrow
/// will process `withdraw` only if the `Sale` is reporting a complete and
/// successful raise. Similarly `undeposit` will only return tokens after the
/// `Sale` completes and reports failure. While the `Sale` is in active
/// distribution neither `withdraw` or `undeposit` will move tokens. This is
/// necessary in part because it is only safe to calculate entitlements once
/// the redeemable tokens are fully distributed and frozen.
///
/// Because much of the redeemable token supply will never be sold, and then
/// burned, `depositPending` MUST be called rather than `deposit` while the
/// raise is active. When the raise completes anon can call `sweepPending`
/// which will calculate and emit a `Deposit` event for a useful `supply`.
///
/// Any supported ERC20 token can be deposited at any time BUT ONLY under a
/// `Sale` contract that is the child of the `TrustFactory` that the escrow
/// is deployed for. `TrustEscrow` is used to prevent a `Sale` from changing
/// the pass/fail outcome once it is known due to a bug/attempt to double
/// spend escrow funds.
///
/// This mechanism is very similar to the native burn mechanism on
/// `redeemableERC20` itself under `redeem` but without requiring any tokens to
/// be burned in the process. Users can claim the same token many times safely,
/// simply receiving 0 tokens if there is nothing left to claim.
///
/// This does NOT support rebase/elastic token _balance_ mechanisms on the
/// escrowed token as the escrow has no way to track deposits/withdrawals other
/// than 1:1 conservation of input/output. For example, if 100 tokens are
/// deposited under two different trusts and then that token rebases all
/// balances to half, there will be 50 tokens in the escrow but the escrow will
/// attempt transfers up to 100 tokens between the two trusts. Essentially the
/// first 50 tokens will send and the next 50 tokens will fail because the
/// trust literally doesn't have 100 tokens at that point.
///
/// Elastic _supply_ tokens are supported as every token to be withdrawn must
/// be first deposited, with the caveat that if some mechanism can
/// mint/burn/transfer tokens out from under the escrow contract directly, this
/// will break internal accounting much like the rebase situation.
///
/// Using a real-world example, stETH from LIDO would be NOT be supported as
/// the balance changes every day to reflect incoming ETH from validators, but
/// wstETH IS supported as balances remain static while the underlying assets
/// per unit of wstETH increase each day. This is of course exactly why wstETH
/// was created in the first place.
///
/// Every escrowed token has a separate space in the deposited/withdrawn
/// mappings so that some broken/malicious/hacked token that leads to incorrect
/// token movement in/out of the escrow cannot impact other tokens, even for
/// the same trust and redeemable.
contract RedeemableERC20ClaimEscrow is SaleEscrow {
    using Math for uint256;
    using SafeERC20 for IERC20;

    /// Emitted for every successful pending deposit.
    /// @param sender Anon `msg.sender` depositing the token.
    /// @param sale `ISale` contract deposit is under.
    /// @param redeemable Redeemable token that can claim this deposit.
    /// Implicitly snapshots the redeemable so malicious `Trust` cannot
    /// redirect funds later.
    /// @param token `IERC20` token being deposited.
    /// @param amount Amount of token deposited.
    event PendingDeposit(
        address sender,
        address sale,
        address redeemable,
        address token,
        uint256 amount
    );

    /// Emitted every time a pending deposit is swept to a full deposit.
    /// @param sender Anon `msg.sender` sweeping the deposit.
    /// @param depositor Anon `msg.sender` who originally deposited the token.
    /// @param sale `ISale` contract deposit is under.
    /// @param redeemable Redeemable token first reported by the trust.
    /// @param token `IERC20` token being swept into a deposit.
    /// @param amount Amount of token being swept into a deposit.
    event Sweep(
        address sender,
        address depositor,
        address sale,
        address redeemable,
        address token,
        uint256 amount
    );

    /// Emitted for every successful deposit.
    /// @param sender Anon `msg.sender` triggering the deposit.
    /// MAY NOT be the `depositor` in the case of a pending sweep.
    /// @param depositor Anon `msg.sender` who originally deposited the token.
    /// MAY NOT be the current `msg.sender` in the case of a pending sweep.
    /// @param sale `ISale` contract deposit is under.
    /// @param redeemable Redeemable token that can claim this deposit.
    /// @param token `IERC20` token being deposited.
    /// @param supply rTKN supply at moment of deposit.
    /// @param amount Amount of token deposited.
    event Deposit(
        address sender,
        address depositor,
        address sale,
        address redeemable,
        address token,
        uint256 supply,
        uint256 amount
    );

    /// Emitted for every successful undeposit.
    /// @param sender Anon `msg.sender` undepositing the token.
    /// @param sale `ISale` contract undeposit is from.
    /// @param redeemable Redeemable token that is being undeposited against.
    /// @param token `IERC20` token being undeposited.
    /// @param supply rTKN supply at moment of deposit.
    /// @param amount Amount of token undeposited.
    event Undeposit(
        address sender,
        address sale,
        address redeemable,
        address token,
        uint256 supply,
        uint256 amount
    );

    /// Emitted for every successful withdrawal.
    /// @param withdrawer Anon `msg.sender` withdrawing the token.
    /// @param sale `ISale` contract withdrawal is from.
    /// @param redeemable Redeemable token used to withdraw.
    /// @param token `IERC20` token being withdrawn.
    /// @param supply rTKN supply at moment of deposit.
    /// @param amount Amount of token withdrawn.
    event Withdraw(
        address withdrawer,
        address sale,
        address redeemable,
        address token,
        uint256 supply,
        uint256 amount
    );

    /// Every time an address calls `withdraw` their withdrawals increases to
    /// match the current `totalDeposits` for that trust/token combination.
    /// The token amount they actually receive is only their prorata share of
    /// that deposited balance. The prorata scaling calculation happens inline
    /// within the `withdraw` function.
    /// trust => withdrawn token =>  rTKN supply => withdrawer => amount
    mapping(address => mapping(address => mapping(uint256 => mapping(address => uint256))))
        internal withdrawals;

    /// Deposits during an active raise are desirable to trustlessly prove to
    /// raise participants that they will in fact be able to access the TKN
    /// after the raise succeeds. Deposits during the pending stage are set
    /// aside with no rTKN supply mapping, to be swept into a real deposit by
    /// anon once the raise completes.
    mapping(address => mapping(address => mapping(address => uint256)))
        internal pendingDeposits;

    /// Every time an address calls `deposit` their deposited trust/token
    /// combination is increased. If they call `undeposit` when the raise has
    /// failed they will receive the full amount they deposited back. Every
    /// depositor must call `undeposit` for themselves.
    /// trust => deposited token => depositor => rTKN supply => amount
    mapping(address => mapping(address => mapping(address => mapping(uint256 => uint256))))
        internal deposits;

    /// Every time an address calls `deposit` the amount is added to that
    /// trust/token/supply combination. This increase becomes the
    /// "high water mark" that withdrawals move up to with each `withdraw`
    /// call.
    /// trust => deposited token => rTKN supply => amount
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        internal totalDeposits;

    /// Redundant tracking of deposits withdrawn.
    /// Counts aggregate deposits down as users withdraw, while their own
    /// individual withdrawal counters count up.
    /// Guards against buggy/malicious redeemable tokens that don't correctly
    /// freeze their balances, hence opening up double spends.
    /// trust => deposited token => rTKN supply => amount
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        internal remainingDeposits;

    /// Depositor can set aside tokens during pending raise status to be swept
    /// into a real deposit later.
    /// The problem with doing a normal deposit while the raise is still active
    /// is that the `Sale` will burn all unsold tokens when the raise ends. If
    /// we captured the token supply mid-raise then many deposited TKN would
    /// be allocated to unsold rTKN. Instead we set aside TKN so that raise
    /// participants can be sure that they will be claimable upon raise success
    /// but they remain unbound to any rTKN supply until `sweepPending` is
    /// called.
    /// `depositPending` is a one-way function, there is no way to `undeposit`
    /// until after the raise fails. Strongly recommended that depositors do
    /// NOT call `depositPending` until raise starts, so they know it will also
    /// end.
    /// @param sale_ The `Sale` to assign this deposit to.
    /// @param token_ The `IERC20` token to deposit to the escrow.
    /// @param amount_ The amount of token to despoit. Requires depositor has
    /// approved at least this amount to succeed.
    function depositPending(
        address sale_,
        address token_,
        uint256 amount_
    ) external {
        require(amount_ > 0, "ZERO_DEPOSIT");
        require(escrowStatus(sale_) == EscrowStatus.Pending, "NOT_PENDING");
        pendingDeposits[sale_][token_][msg.sender] += amount_;
        // Important to snapshot the token from the trust here so it can't be
        // changed later by the trust.
        address redeemable_ = token(sale_);

        emit PendingDeposit(msg.sender, sale_, redeemable_, token_, amount_);

        IERC20(token_).safeTransferFrom(msg.sender, address(this), amount_);
    }

    /// Internal accounting for a deposit.
    /// Identical for both a direct deposit and sweeping a pending deposit.
    /// @param sale_ The sale to register a deposit under.
    /// @param token_ The token being deposited.
    /// @param depositor_ The depositor address to register the deposit under.
    /// @param amount_ The size of the deposit denominated in `token_`.
    function registerDeposit(
        address sale_,
        address token_,
        address depositor_,
        uint256 amount_
    ) private {
        require(escrowStatus(sale_) > EscrowStatus.Pending, "PENDING");
        require(amount_ > 0, "ZERO_DEPOSIT");

        address redeemable_ = token(sale_);
        uint256 supply_ = IERC20(redeemable_).totalSupply();
        // Zero supply means the escrow is at best useless (no recipients) and
        // at worst dangerous (tokens trapped behind a divide by zero).
        require(supply_ > 0, "ZERO_SUPPLY");

        deposits[sale_][token_][depositor_][supply_] += amount_;
        totalDeposits[sale_][token_][supply_] += amount_;
        remainingDeposits[sale_][token_][supply_] += amount_;

        emit Deposit(
            msg.sender,
            depositor_,
            sale_,
            redeemable_,
            token_,
            supply_,
            amount_
        );
    }

    /// Anon can convert any existing pending deposit to a deposit with known
    /// rTKN supply once the escrow has moved out of pending status.
    /// As `sweepPending` is anon callable, raise participants know that the
    /// depositor cannot later prevent a sweep, and depositor knows that raise
    /// participants cannot prevent a sweep. As per normal deposits, the output
    /// of swept tokens depends on success/fail state allowing `undeposit` or
    /// `withdraw` to be called subsequently.
    /// Partial sweeps are NOT supported, to avoid griefers splitting a deposit
    /// across many different `supply_` values.
    /// @param sale_ The sale to sweep all pending deposits for.
    /// @param token_ The token to sweep into registered deposits.
    /// @param depositor_ The depositor to sweep registered deposits under.
    function sweepPending(
        address sale_,
        address token_,
        address depositor_
    ) external {
        uint256 amount_ = pendingDeposits[sale_][token_][depositor_];
        delete pendingDeposits[sale_][token_][depositor_];
        emit Sweep(
            msg.sender,
            depositor_,
            sale_,
            token(sale_),
            token_,
            amount_
        );
        registerDeposit(sale_, token_, depositor_, amount_);
    }

    /// Any address can deposit any amount of its own `IERC20` under a `Sale`.
    /// The `Sale` MUST be a child of the trusted factory.
    /// The deposit will be accounted for under both the depositor individually
    /// and the trust in aggregate. The aggregate value is used by `withdraw`
    /// and the individual value by `undeposit`.
    /// The depositor is responsible for approving the token for this contract.
    /// `deposit` is still enabled after the distribution ends; `undeposit` is
    /// always allowed in case of a fail and disabled on success. Multiple
    /// `deposit` calls before and after a success result are supported. If a
    /// depositor deposits when a raise has failed they will need to undeposit
    /// it again manually.
    /// Delegated `deposit` is not supported. Every depositor is directly
    /// responsible for every `deposit`.
    /// WARNING: As `undeposit` can only be called when the `Sale` reports
    /// failure, `deposit` should only be called when the caller is sure the
    /// `Sale` will reach a clear success/fail status. For example, when a
    /// `Sale` has not yet been seeded it may never even start the raise so
    /// depositing at this point is dangerous. If the `Sale` never starts the
    /// raise it will never fail the raise either.
    /// @param sale_ The `Sale` to assign this deposit to.
    /// @param token_ The `IERC20` token to deposit to the escrow.
    /// @param amount_ The amount of token to deposit. Requires depositor has
    /// approved at least this amount to succeed.
    function deposit(
        address sale_,
        address token_,
        uint256 amount_
    ) external {
        registerDeposit(sale_, token_, msg.sender, amount_);
        IERC20(token_).safeTransferFrom(msg.sender, address(this), amount_);
    }

    /// The inverse of `deposit`.
    /// In the case of a failed distribution the depositors can claim back any
    /// tokens they deposited in the escrow.
    /// Ideally the distribution is a success and this does not need to be
    /// called but it is important that we can walk back deposits and try again
    /// for some future raise if needed.
    /// Delegated `undeposit` is not supported, only the depositor can wind
    /// back their original deposit.
    /// `amount_` must be non-zero.
    /// If several tokens have been deposited against a given trust for the
    /// depositor then each token must be individually undeposited. There is
    /// no onchain tracking or bulk processing for the depositor, they are
    /// expected to know what they have previously deposited and if/when to
    /// process an `undeposit`.
    /// @param sale_ The `Sale` to undeposit from.
    /// @param token_ The token to undeposit.
    /// @param supply_ The total supply of the sale token associated with the
    /// deposit being undeposited.
    /// @param amount_ The amount to undeposit.
    function undeposit(
        address sale_,
        address token_,
        uint256 supply_,
        uint256 amount_
    ) external {
        // Can only undeposit when the `Trust` reports failure.
        require(escrowStatus(sale_) == EscrowStatus.Fail, "NOT_FAIL");
        require(amount_ > 0, "ZERO_AMOUNT");

        deposits[sale_][token_][msg.sender][supply_] -= amount_;
        // Guard against outputs exceeding inputs.
        // Last undeposit gets a gas refund.
        totalDeposits[sale_][token_][supply_] -= amount_;
        remainingDeposits[sale_][token_][supply_] -= amount_;

        emit Undeposit(
            msg.sender,
            sale_,
            // Include this in the event so that indexer consumers see a
            // consistent world view even if the trust_ changes its answer
            // about the redeemable.
            token(sale_),
            token_,
            supply_,
            amount_
        );

        IERC20(token_).safeTransfer(msg.sender, amount_);
    }

    /// The successful handover of a `deposit` to a recipient.
    /// When a redeemable token distribution is successful the redeemable token
    /// holders are automatically and immediately eligible to `withdraw` any
    /// and all tokens previously deposited against the relevant `Sale`.
    /// The `withdraw` can only happen if/when the relevant `Sale` reaches the
    /// success distribution status.
    /// Delegated `withdraw` is NOT supported. Every redeemable token holder is
    /// directly responsible for being aware of and calling `withdraw`.
    /// If a redeemable token holder calls `redeem` they also burn their claim
    /// on any tokens held in escrow so they MUST first call `withdraw` THEN
    /// `redeem`.
    /// It is expected that the redeemable token holder knows about the tokens
    /// that they will be withdrawing. This information is NOT tracked onchain
    /// or exposed for bulk processing.
    /// Partial `withdraw` is not supported, all tokens allocated to the caller
    /// are withdrawn`. 0 amount withdrawal is an error, if the prorata share
    /// of the token being claimed is small enough to round down to 0 then the
    /// withdraw will revert.
    /// Multiple withdrawals across multiple deposits is supported and is
    /// equivalent to a single withdraw after all relevant deposits.
    /// @param sale_ The trust to `withdraw` against.
    /// @param token_ The token to `withdraw`.
    /// @param supply_ The total supply of the sale token at time of deposit
    /// to process this withdrawal against.
    function withdraw(
        address sale_,
        address token_,
        uint256 supply_
    ) external {
        // Can only withdraw when the `Trust` reports success.
        require(escrowStatus(sale_) == EscrowStatus.Success, "NOT_SUCCESS");

        uint256 totalDeposited_ = totalDeposits[sale_][token_][supply_];
        uint256 withdrawn_ = withdrawals[sale_][token_][supply_][msg.sender];
        withdrawals[sale_][token_][supply_][msg.sender] = totalDeposited_;

        RedeemableERC20 redeemable_ = RedeemableERC20(token(sale_));

        uint256 amount_ = (// Underflow MUST error here (should not be possible).
        (totalDeposited_ - withdrawn_) *
            // prorata share of `msg.sender`'s current balance vs. supply
            // as at the time deposit was made. If nobody burns they will
            // all get a share rounded down by integer division. 100 split
            // 3 ways will be 33 tokens each, leaving 1 TKN as escrow dust,
            // for example. If someone burns before withdrawing they will
            // receive less, so 0/33/33 from 100 with 34 TKN as escrow
            // dust, for example.
            redeemable_.balanceOf(msg.sender)) / supply_;

        // Guard against outputs exceeding inputs.
        // For example a malicious `Trust` could report a `redeemable_` token
        // that does NOT freeze balances. In this case token holders can double
        // spend their withdrawals by simply shuffling the same token around
        // between accounts.
        remainingDeposits[sale_][token_][supply_] -= amount_;

        require(amount_ > 0, "ZERO_WITHDRAW");
        emit Withdraw(
            msg.sender,
            sale_,
            address(redeemable_),
            token_,
            supply_,
            amount_
        );
        IERC20(token_).safeTransfer(msg.sender, amount_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {ERC20Config} from "../erc20/ERC20Config.sol";
import "../erc20/ERC20Redeem.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ITierV2} from "../tier/ITierV2.sol";
import {TierReport} from "../tier/libraries/TierReport.sol";

import {Phased} from "../phased/Phased.sol";

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

/// Everything required by the `RedeemableERC20` constructor.
/// @param reserve Reserve token that the associated `Trust` or equivalent
/// raise contract will be forwarding to the `RedeemableERC20` contract.
/// @param erc20Config ERC20 config forwarded to the ERC20 constructor.
/// @param tier Tier contract to compare statuses against on transfer.
/// @param minimumTier Minimum tier required for transfers in `Phase.ZERO`.
/// Can be `0`.
/// @param distributionEndForwardingAddress Optional address to send rTKN to at
/// the end of the distribution phase. If `0` address then all undistributed
/// rTKN will burn itself at the end of the distribution.
struct RedeemableERC20Config {
    address reserve;
    ERC20Config erc20Config;
    address tier;
    uint256 minimumTier;
    address distributionEndForwardingAddress;
}

/// @title RedeemableERC20
/// @notice This is the ERC20 token that is minted and distributed.
///
/// During `Phase.ZERO` the token can be traded and so compatible with the
/// Balancer pool mechanics.
///
/// During `Phase.ONE` the token is frozen and no longer able to be traded on
/// any AMM or transferred directly.
///
/// The token can be redeemed during `Phase.ONE` which burns the token in
/// exchange for pro-rata erc20 tokens held by the `RedeemableERC20` contract
/// itself.
///
/// The token balances can be used indirectly for other claims, promotions and
/// events as a proof of participation in the original distribution by token
/// holders.
///
/// The token can optionally be restricted by the `ITierV2` contract to only
/// allow receipients with a specified membership status.
///
/// @dev `RedeemableERC20` is an ERC20 with 2 phases.
///
/// `Phase.ZERO` is the distribution phase where the token can be freely
/// transfered but not redeemed.
/// `Phase.ONE` is the redemption phase where the token can be redeemed but no
/// longer transferred.
///
/// Redeeming some amount of `RedeemableERC20` burns the token in exchange for
/// some other tokens held by the contract. For example, if the
/// `RedeemableERC20` token contract holds 100 000 USDC then a holder of the
/// redeemable token can burn some of their tokens to receive a % of that USDC.
/// If they redeemed (burned) an amount equal to 10% of the redeemable token
/// supply then they would receive 10 000 USDC.
///
/// To make the treasury assets discoverable anyone can call `newTreasuryAsset`
/// to emit an event containing the treasury asset address. As malicious and/or
/// spam users can emit many treasury events there is a need for sensible
/// indexing and filtering of asset events to only trusted users. This contract
/// is agnostic to how that trust relationship is defined for each user.
///
/// Users must specify all the treasury assets they wish to redeem to the
/// `redeem` function. After `redeem` is called the redeemed tokens are burned
/// so all treasury assets must be specified and claimed in a batch atomically.
/// Note: The same amount of `RedeemableERC20` is burned, regardless of which
/// treasury assets were specified. Specifying fewer assets will NOT increase
/// the proportion of each that is returned.
///
/// `RedeemableERC20` has several owner administrative functions:
/// - Owner can add senders and receivers that can send/receive tokens even
///   during `Phase.ONE`
/// - Owner can end `Phase.ONE` during `Phase.ZERO` by specifying the address
///   of a distributor, which will have any undistributed tokens burned.
/// The owner should be a `Trust` not an EOA.
///
/// The redeem functions MUST be used to redeem and burn RedeemableERC20s
/// (NOT regular transfers).
///
/// `redeem` will simply revert if called outside `Phase.ONE`.
/// A `Redeem` event is emitted on every redemption (per treasury asset) as
/// `(redeemer, asset, redeemAmount)`.
contract RedeemableERC20 is Initializable, Phased, ERC20Redeem {
    using SafeERC20 for IERC20;

    /// @dev Phase constants.
    /// Contract is not yet initialized.
    uint256 private constant PHASE_UNINITIALIZED = 0;
    /// @dev Token is in the distribution phase and can be transferred freely
    /// subject to tier requirements.
    uint256 private constant PHASE_DISTRIBUTING = 1;
    /// @dev Token is frozen and cannot be transferred unless the
    /// sender/receiver is authorized as a sender/receiver.
    uint256 private constant PHASE_FROZEN = 2;

    /// @dev Bits for a receiver.
    uint256 private constant RECEIVER = 0x1;
    /// @dev Bits for a sender.
    uint256 private constant SENDER = 0x2;

    /// @dev To be clear, this admin is NOT intended to be an EOA.
    /// This contract is designed assuming the admin is a `Sale` or equivalent
    /// contract that itself does NOT have an admin key.
    address private admin;
    /// @dev Tracks addresses that can always send/receive regardless of phase.
    /// sender/receiver => access bits
    mapping(address => uint256) private access;

    /// Results of initializing.
    /// @param sender `msg.sender` of initialize.
    /// @param config Initialization config.
    event Initialize(address sender, RedeemableERC20Config config);

    /// A new token sender has been added.
    /// @param sender `msg.sender` that approved the token sender.
    /// @param grantedSender address that is now a token sender.
    event Sender(address sender, address grantedSender);

    /// A new token receiver has been added.
    /// @param sender `msg.sender` that approved the token receiver.
    /// @param grantedReceiver address that is now a token receiver.
    event Receiver(address sender, address grantedReceiver);

    /// RedeemableERC20 uses the standard/default 18 ERC20 decimals.
    /// The minimum supply enforced by the constructor is "one" token which is
    /// `10 ** 18`.
    /// The minimum supply does not prevent subsequent redemption/burning.
    uint256 private constant MINIMUM_INITIAL_SUPPLY = 10**18;

    /// Tier contract that produces the report that `minimumTier` is checked
    /// against.
    /// Public so external contracts can interface with the required tier.
    ITierV2 public tier;

    /// The minimum status that a user must hold to receive transfers during
    /// `Phase.ZERO`.
    /// The tier contract passed to `TierByConstruction` determines if
    /// the status is held during `_beforeTokenTransfer`.
    /// Public so external contracts can interface with the required tier.
    uint256 public minimumTier;

    /// Optional address to send rTKN to at the end of the distribution phase.
    /// If `0` address then all undistributed rTKN will burn itself at the end
    /// of the distribution.
    address private distributionEndForwardingAddress;

    constructor() {
        _disableInitializers();
    }

    /// Mint the full ERC20 token supply and configure basic transfer
    /// restrictions. Initializes all base contracts.
    /// @param config_ Initialized configuration.
    function initialize(RedeemableERC20Config calldata config_)
        external
        initializer
    {
        initializePhased();

        tier = ITierV2(config_.tier);

        require(
            ERC165Checker.supportsInterface(
                config_.tier,
                type(ITierV2).interfaceId
            ),
            "ERC165_TIERV2"
        );

        __ERC20_init(config_.erc20Config.name, config_.erc20Config.symbol);

        require(
            config_.erc20Config.initialSupply >= MINIMUM_INITIAL_SUPPLY,
            "MINIMUM_INITIAL_SUPPLY"
        );
        minimumTier = config_.minimumTier;
        distributionEndForwardingAddress = config_
            .distributionEndForwardingAddress;

        // Minting and burning must never fail.
        access[address(0)] = RECEIVER | SENDER;

        // Admin receives full supply.
        access[config_.erc20Config.distributor] = RECEIVER;

        // Forwarding address must be able to receive tokens.
        if (distributionEndForwardingAddress != address(0)) {
            access[distributionEndForwardingAddress] = RECEIVER;
        }

        admin = config_.erc20Config.distributor;

        // Need to mint after assigning access.
        _mint(
            config_.erc20Config.distributor,
            config_.erc20Config.initialSupply
        );

        // The reserve must always be one of the treasury assets.
        newTreasuryAsset(config_.reserve);

        emit Initialize(msg.sender, config_);

        schedulePhase(PHASE_DISTRIBUTING, block.timestamp);
    }

    /// Require a function is only admin callable.
    modifier onlyAdmin() {
        require(msg.sender == admin, "ONLY_ADMIN");
        _;
    }

    /// Check that an address is a receiver.
    /// A sender is also a receiver.
    /// @param maybeReceiver_ account to check.
    /// @return True if account is a receiver.
    function isReceiver(address maybeReceiver_) public view returns (bool) {
        return access[maybeReceiver_] & RECEIVER > 0;
    }

    /// Admin can grant an address receiver rights.
    /// @param newReceiver_ The account to grand receiver.
    function grantReceiver(address newReceiver_) external onlyAdmin {
        // Using `|` preserves sender if previously granted.
        access[newReceiver_] |= RECEIVER;
        emit Receiver(msg.sender, newReceiver_);
    }

    /// Check that an address is a sender.
    /// @param maybeSender_ account to check.
    /// @return True if account is a sender.
    function isSender(address maybeSender_) public view returns (bool) {
        return access[maybeSender_] & SENDER > 0;
    }

    /// Admin can grant an addres sender rights.
    /// @param newSender_ The account to grant sender.
    function grantSender(address newSender_) external onlyAdmin {
        // Uinsg `|` preserves receiver if previously granted.
        access[newSender_] |= SENDER;
        emit Sender(msg.sender, newSender_);
    }

    /// The admin can forward or burn all tokens of a single address to end
    /// `PHASE_DISTRIBUTING`.
    /// The intent is that during `PHASE_DISTRIBUTING` there is some contract
    /// responsible for distributing the tokens.
    /// The admin specifies the distributor to end `PHASE_DISTRIBUTING` and the
    /// forwarding address set during initialization is used. If the forwarding
    /// address is `0` the rTKN will be burned, otherwise the entire balance of
    /// the distributor is forwarded to the nominated address. In practical
    /// terms the forwarding allows for escrow depositors to receive a prorata
    /// claim on unsold rTKN if they forward it to themselves, otherwise raise
    /// participants will receive a greater share of the final escrowed tokens
    /// due to the burn reducing the total supply.
    /// The distributor is NOT set during the constructor because it may not
    /// exist at that point. For example, Balancer needs the paired erc20
    /// tokens to exist before the trading pool can be built.
    /// @param distributor_ The distributor according to the admin.
    /// BURN the tokens if `address(0)`.
    function endDistribution(address distributor_)
        external
        onlyPhase(PHASE_DISTRIBUTING)
        onlyAdmin
    {
        schedulePhase(PHASE_FROZEN, block.timestamp);
        address forwardTo_ = distributionEndForwardingAddress;
        uint256 distributorBalance_ = balanceOf(distributor_);
        if (distributorBalance_ > 0) {
            if (forwardTo_ == address(0)) {
                _burn(distributor_, distributorBalance_);
            } else {
                _transfer(distributor_, forwardTo_, distributorBalance_);
            }
        }
    }

    /// Wraps `_redeem` from `ERC20Redeem`.
    /// Very thin wrapper so be careful when calling!
    /// @param treasuryAssets_ The treasury assets to redeem for. If this is
    /// empty or incomplete then tokens will be permanently burned for no
    /// reason by the caller and the remaining funds will be effectively
    /// redistributed to everyone else.
    function redeem(IERC20[] calldata treasuryAssets_, uint256 redeemAmount_)
        external
        onlyPhase(PHASE_FROZEN)
    {
        _redeem(treasuryAssets_, redeemAmount_);
    }

    /// Apply phase sensitive transfer restrictions.
    /// During `Phase.ZERO` only tier requirements apply.
    /// During `Phase.ONE` all transfers except burns are prevented.
    /// If a transfer involves either a sender or receiver with the SENDER
    /// or RECEIVER role, respectively, it will bypass these restrictions.
    /// @inheritdoc ERC20Upgradeable
    function _beforeTokenTransfer(
        address sender_,
        address receiver_,
        uint256 amount_
    ) internal virtual override {
        super._beforeTokenTransfer(sender_, receiver_, amount_);

        // Sending tokens to this contract (e.g. instead of redeeming) is
        // always an error.
        require(receiver_ != address(this), "TOKEN_SEND_SELF");

        // Some contracts may attempt a preflight (e.g. Balancer) of a 0 amount
        // transfer.
        // We don't want to accidentally cause external errors due to zero
        // value transfers.
        if (
            amount_ > 0 &&
            // The sender and receiver lists bypass all access restrictions.
            !(isSender(sender_) || isReceiver(receiver_))
        ) {
            // During `PHASE_DISTRIBUTING` transfers are only restricted by the
            // tier of the recipient. Every other phase only allows senders and
            // receivers as above.
            require(currentPhase() == PHASE_DISTRIBUTING, "FROZEN");

            // Receivers act as "hubs" that can send to "spokes".
            // i.e. any address of the minimum tier.
            // Spokes cannot send tokens another "hop" e.g. to each other.
            // Spokes can only send back to a receiver (doesn't need to be
            // the same receiver they received from).
            require(isReceiver(sender_), "2SPOKE");
            require(
                TierReport.tierAtTimeFromReport(
                    tier.report(receiver_, new uint256[](0)),
                    block.timestamp
                ) >= minimumTier,
                "MIN_TIER"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
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

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import "../sale/ISale.sol";

/// Represents the 3 possible statuses an escrow could care about.
/// Either the escrow takes no action or consistently allows a success/fail
/// action.
enum EscrowStatus {
    /// The underlying `Sale` has not reached a definitive pass/fail state.
    /// Important this is the first item in the enum as inequality is used to
    /// check pending vs. pass/fail in security sensitive code.
    Pending,
    /// The underlying `Sale` distribution failed.
    Fail,
    /// The underlying `Sale` distribution succeeded.
    Success
}

/// @title SaleEscrow
/// An escrow that is designed to work with untrusted `Sale` bytecode.
/// `escrowStatus` wraps `Sale` functions to guarantee that results do not
/// change. Reserve and token addresses never change for a given `Sale` and
/// a pass/fail result is one-way. Even if some bug in the `Sale` causes the
/// pass/fail status to flip, this will not result in the escrow double
/// spending or otherwise changing the direction that it sends funds.
contract SaleEscrow {
    /// ISale address => reserve address.
    mapping(address => address) internal reserves;
    /// ISale address => token address.
    mapping(address => address) internal tokens;
    /// ISale address => status.
    mapping(address => EscrowStatus) internal escrowStatuses;

    /// Immutable wrapper around `ISale.reserve`.
    /// Once a `Sale` reports a reserve address the `SaleEscrow` never asks
    /// again. Prevents a malicious `Sale` from changing the reserve at some
    /// point to break internal escrow accounting.
    /// @param sale_ The ISale to fetch reserve for.
    function reserve(address sale_) internal returns (address) {
        address reserve_ = reserves[sale_];
        if (reserve_ == address(0)) {
            address saleReserve_ = address(ISale(sale_).reserve());
            require(saleReserve_ != address(0), "0_RESERVE");
            reserves[sale_] = saleReserve_;
            reserve_ = saleReserve_;
        }
        return reserve_;
    }

    /// Immutable wrapper around `ISale.token`.
    /// Once a `Sale` reports a token address the `SaleEscrow` never asks
    /// again. Prevents a malicious `Sale` from changing the token at some
    /// point to divert escrow payments after assets have already been set
    /// aside.
    /// @param sale_ The ISale to fetch token for.
    function token(address sale_) internal returns (address) {
        address token_ = tokens[sale_];
        if (token_ == address(0)) {
            address saleToken_ = address(ISale(sale_).token());
            require(saleToken_ != address(0), "0_TOKEN");
            tokens[sale_] = saleToken_;
            token_ = saleToken_;
        }
        return token_;
    }

    /// Read the one-way, one-time transition from pending to success/fail.
    /// We never change our opinion of a success/fail outcome.
    /// If a buggy/malicious `ISale` somehow changes success/fail state then
    /// that is obviously bad as the escrow will release funds in the wrong
    /// direction. But if we were to change our opinion that would be worse as
    /// claims/refunds could potentially be "double spent" somehow.
    /// @param sale_ The sale to get the escrow status for.
    function escrowStatus(address sale_) internal returns (EscrowStatus) {
        EscrowStatus escrowStatus_ = escrowStatuses[sale_];
        // Short circuit and ignore the `ISale` if we previously saved a value.
        if (escrowStatus_ > EscrowStatus.Pending) {
            return escrowStatus_;
        }
        // We have never seen a success/fail outcome so need to ask the `ISale`
        // for the distribution status.
        else {
            SaleStatus saleStatus_ = ISale(sale_).saleStatus();
            // Success maps to success.
            if (saleStatus_ == SaleStatus.Success) {
                escrowStatuses[sale_] = EscrowStatus.Success;
                return EscrowStatus.Success;
            }
            // Fail maps to fail.
            else if (saleStatus_ == SaleStatus.Fail) {
                escrowStatuses[sale_] = EscrowStatus.Fail;
                return EscrowStatus.Fail;
            }
            // Everything else is still pending.
            else {
                return EscrowStatus.Pending;
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

/// Constructor config for standard Open Zeppelin ERC20.
/// @param name Name as defined by Open Zeppelin ERC20.
/// @param symbol Symbol as defined by Open Zeppelin ERC20.
/// @param distributor Distributor address of the initial supply.
/// MAY be zero.
/// @param initialSupply Initial supply to mint.
/// MAY be zero.
struct ERC20Config {
    string name;
    string symbol;
    address distributor;
    uint256 initialSupply;
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

contract ERC20Redeem is ERC20BurnableUpgradeable {
    using SafeERC20 for IERC20;

    /// Anon has burned their tokens in exchange for some treasury assets.
    /// Emitted once per redeemed asset.
    /// @param sender `msg.sender` is burning.
    /// @param treasuryAsset Treasury asset being sent to redeemer.
    /// @param redeemAmount Amount of token being burned.
    /// @param assetAmount Amount of treasury asset being sent.
    event Redeem(
        address sender,
        address treasuryAsset,
        uint256 redeemAmount,
        uint256 assetAmount
    );

    /// Anon can notify the world that they are adding treasury assets to the
    /// contract. Indexers are strongly encouraged to ignore untrusted anons.
    /// @param sender `msg.sender` adding a treasury asset.
    /// @param asset The treasury asset being added.
    event TreasuryAsset(address sender, address asset);

    /// Anon can emit a `TreasuryAsset` event to notify token holders that
    /// an asset could be redeemed by burning `RedeemableERC20` tokens.
    /// As this is callable by anon the events should be filtered by the
    /// indexer to those from trusted entities only.
    /// @param newTreasuryAsset_ The asset to log.
    function newTreasuryAsset(address newTreasuryAsset_) public {
        emit TreasuryAsset(msg.sender, newTreasuryAsset_);
    }

    /// Burn tokens for a prorata share of the current treasury.
    ///
    /// The assets to be redeemed for must be specified as an array. This keeps
    /// the redeem functionality:
    /// - Gas efficient as we avoid tracking assets in storage
    /// - Decentralised as any user can deposit any asset to be redeemed
    /// - Error resistant as any individual asset reverting can be avoided by
    ///   redeeming againt sans the problematic asset.
    /// It is also a super sharp edge if someone burns their tokens prematurely
    /// or with an incorrect asset list. Implementing contracts are strongly
    /// encouraged to implement additional safety rails to prevent high value
    /// mistakes.
    /// Only "vanilla" erc20 token balances are supported as treasury assets.
    /// I.e. if the balance is changing such as due to a rebasing token or
    /// other mechanism then the WRONG token amounts will be redeemed. The
    /// redemption calculation is very simple and naive in that it takes the
    /// current balance of this contract of the assets being claimed via
    /// redemption to calculate the "prorata" entitlement. If the contract's
    /// balance of the claimed token is changing between redemptions (other
    /// than due to the redemption itself) then each redemption will send
    /// incorrect amounts.
    /// @param treasuryAssets_ The list of assets to redeem.
    /// @param redeemAmount_ The amount of redeemable token to burn.
    function _redeem(IERC20[] memory treasuryAssets_, uint256 redeemAmount_)
        internal
    {
        uint256 assetsLength_ = treasuryAssets_.length;

        // Calculate everything before any balances change.
        uint256[] memory amounts_ = new uint256[](assetsLength_);

        // The fraction of the assets we release is the fraction of the
        // outstanding total supply of the redeemable being burned.
        // Every treasury asset is released in the same proportion.
        // Guard against no asset redemptions and log all events before we
        // change any contract state or call external contracts.
        require(assetsLength_ > 0, "EMPTY_ASSETS");
        uint256 supply_ = IERC20(address(this)).totalSupply();
        uint256 amount_ = 0;
        for (uint256 i_ = 0; i_ < assetsLength_; i_++) {
            amount_ =
                (treasuryAssets_[i_].balanceOf(address(this)) * redeemAmount_) /
                supply_;
            require(amount_ > 0, "ZERO_AMOUNT");
            emit Redeem(
                msg.sender,
                address(treasuryAssets_[i_]),
                redeemAmount_,
                amount_
            );
            amounts_[i_] = amount_;
        }

        // Burn FIRST (reentrancy safety).
        _burn(msg.sender, redeemAmount_);

        // THEN send all assets.
        for (uint256 i_ = 0; i_ < assetsLength_; i_++) {
            treasuryAssets_[i_].safeTransfer(msg.sender, amounts_[i_]);
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

/// @title ITierV2
/// @notice `ITierV2` is a simple interface that contracts can implement to
/// provide membership lists for other contracts.
///
/// There are many use-cases for a time-preserving conditional membership list.
///
/// Some examples include:
///
/// - Self-serve whitelist to participate in fundraising
/// - Lists of users who can claim airdrops and perks
/// - Pooling resources with implied governance/reward tiers
/// - POAP style attendance proofs allowing access to future exclusive events
///
/// @dev Standard interface to a tiered membership.
///
/// A "membership" can represent many things:
/// - Exclusive access.
/// - Participation in some event or process.
/// - KYC completion.
/// - Combination of sub-memberships.
/// - Etc.
///
/// The high level requirements for a contract implementing `ITierV2`:
/// - MUST represent held tiers as a `uint`.
/// - MUST implement `report`.
///   - The report is a `uint256` that SHOULD represent the time each tier has
///     been continuously held since encoded as `uint32`.
///   - The encoded tiers start at `1`; Tier `0` is implied if no tier has ever
///     been held.
///   - Tier `0` is NOT encoded in the report, it is simply the fallback value.
///   - If a tier is lost the time data is erased for that tier and will be
///     set if/when the tier is regained to the new time.
///   - If a tier is held but the historical time information is not available
///     the report MAY return `0x00000000` for all held tiers.
///   - Tiers that are lost or have never been held MUST return `0xFFFFFFFF`.
///   - Context can be a list of numbers that MAY pairwise define tiers such as
///     minimum thresholds, or MAY simply provide global context such as a
///     relevant NFT ID for example.
/// - MUST implement `reportTimeForTier`
///   - Functions exactly as `report` but only returns a single time for a
///     single tier
///   - MUST return the same time value `report` would for any given tier and
///     context combination.
///
/// So the four possible states and report values are:
/// - Tier is held and time is known: Timestamp is in the report
/// - Tier is held but time is NOT known: `0` is in the report
/// - Tier is NOT held: `0xFF..` is in the report
/// - Tier is unknown: `0xFF..` is in the report
///
/// The reason `context` is specified as a list of values rather than arbitrary
/// bytes is to allow clear and efficient compatibility with VM stacks. Some N
/// values can be taken from a VM stack and used directly as a context, which
/// would be difficult or impossible to ensure is safe for arbitrary bytes.
interface ITierV2 {
    /// Same as report but only returns the time for a single tier.
    /// Often the implementing contract can calculate a single tier more
    /// efficiently than all 8 tiers. If the consumer only needs one or a few
    /// tiers it MAY be much cheaper to request only those tiers individually.
    /// This DOES NOT apply to all contracts, an obvious example is token
    /// balance based tiers which always return `ALWAYS` or `NEVER` for all
    /// tiers so no efficiency is gained.
    /// The return value is a `uint256` for gas efficiency but the values will
    /// be bounded by `type(uint32).max` as no single tier can report a value
    /// higher than this.
    function reportTimeForTier(
        address account,
        uint256 tier,
        uint256[] calldata context
    ) external view returns (uint256 time);

    /// Same as `ITier` but with a list of values for `context` which allows a
    /// single underlying state to present many different reports dynamically.
    ///
    /// For example:
    /// - Staking ledgers can calculate different tier thresholds
    /// - NFTs can give different tiers based on different IDs
    /// - Snapshot ERC20s can give different reports based on snapshot ID
    ///
    /// `context` supercedes `setTier` function and `TierChange` event from
    /// `ITier` at the interface level.
    function report(address account, uint256[] calldata context)
        external
        view
        returns (uint256 report);
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {ITierV2} from "../ITierV2.sol";
import "./TierConstants.sol";

/// @title TierReport
/// @notice `TierReport` implements several pure functions that can be
/// used to interface with reports.
/// - `tierAtTimeFromReport`: Returns the highest status achieved relative to
/// a block timestamp and report. Statuses gained after that block are ignored.
/// - `tierTime`: Returns the timestamp that a given tier has been held
/// since according to a report.
/// - `truncateTiersAbove`: Resets all the tiers above the reference tier.
/// - `updateTimesForTierRange`: Updates a report with a timestamp for every
///    tier in a range.
/// - `updateReportWithTierAtTime`: Updates a report to a new tier.
/// @dev Utilities to consistently read, write and manipulate tiers in reports.
/// The low-level bit shifting can be difficult to get right so this
/// factors that out.
library TierReport {
    /// Enforce upper limit on tiers so we can do unchecked math.
    /// @param tier_ The tier to enforce bounds on.
    modifier maxTier(uint256 tier_) {
        require(tier_ <= TierConstants.MAX_TIER, "MAX_TIER");
        _;
    }

    /// Returns the highest tier achieved relative to a block timestamp
    /// and report.
    ///
    /// Note that typically the report will be from the _current_ contract
    /// state, i.e. `block.timestamp` but not always. Tiers gained after the
    /// reference time are ignored.
    ///
    /// When the `report` comes from a later block than the `timestamp_` this
    /// means the user must have held the tier continuously from `timestamp_`
    /// _through_ to the report block.
    /// I.e. NOT a snapshot.
    ///
    /// @param report_ A report as per `ITierV2`.
    /// @param timestamp_ The timestamp to check the tiers against.
    /// @return tier_ The highest tier held since `timestamp_` as per `report`.
    function tierAtTimeFromReport(uint256 report_, uint256 timestamp_)
        internal
        pure
        returns (uint256 tier_)
    {
        unchecked {
            for (tier_ = 0; tier_ < 8; tier_++) {
                if (uint32(uint256(report_ >> (tier_ * 32))) > timestamp_) {
                    break;
                }
            }
        }
    }

    /// Returns the timestamp that a given tier has been held since from a
    /// report.
    ///
    /// The report MUST encode "never" as 0xFFFFFFFF. This ensures
    /// compatibility with `tierAtTimeFromReport`.
    ///
    /// @param report_ The report to read a timestamp from.
    /// @param tier_ The Tier to read the timestamp for.
    /// @return timestamp_ The timestamp the tier has been held since.
    function reportTimeForTier(uint256 report_, uint256 tier_)
        internal
        pure
        maxTier(tier_)
        returns (uint256 timestamp_)
    {
        unchecked {
            // ZERO is a special case. Everyone has always been at least ZERO,
            // since block 0.
            if (tier_ == 0) {
                return 0;
            }

            uint256 offset_ = (tier_ - 1) * 32;
            timestamp_ = uint256(uint32(uint256(report_ >> offset_)));
        }
    }

    /// Resets all the tiers above the reference tier to 0xFFFFFFFF.
    ///
    /// @param report_ Report to truncate with high bit 1s.
    /// @param tier_ Tier to truncate above (exclusive).
    /// @return Truncated report.
    function truncateTiersAbove(uint256 report_, uint256 tier_)
        internal
        pure
        maxTier(tier_)
        returns (uint256)
    {
        unchecked {
            uint256 offset_ = tier_ * 32;
            uint256 mask_ = (TierConstants.NEVER_REPORT >> offset_) << offset_;
            return report_ | mask_;
        }
    }

    /// Updates a report with a timestamp for a given tier.
    /// More gas efficient than `updateTimesForTierRange` if only a single
    /// tier is being modified.
    /// The tier at/above the given tier is updated. E.g. tier `0` will update
    /// the time for tier `1`.
    /// @param report_ Report to use as the baseline for the updated report.
    /// @param tier_ The tier level to update.
    /// @param timestamp_ The new block number for `tier_`.
    /// @return updatedReport_ The newly updated `report_`.
    function updateTimeAtTier(
        uint256 report_,
        uint256 tier_,
        uint256 timestamp_
    ) internal pure maxTier(tier_) returns (uint256 updatedReport_) {
        unchecked {
            uint256 offset_ = tier_ * 32;
            updatedReport_ =
                (report_ &
                    ~uint256(uint256(TierConstants.NEVER_TIME) << offset_)) |
                uint256(timestamp_ << offset_);
        }
    }

    /// Updates a report with a block number for every tier in a range.
    ///
    /// Does nothing if the end status is equal or less than the start tier.
    /// @param report_ The report to update.
    /// @param startTier_ The tier at the start of the range (exclusive).
    /// @param endTier_ The tier at the end of the range (inclusive).
    /// @param timestamp_ The timestamp to set for every tier in the range.
    /// @return updatedReport_ The updated report.
    function updateTimesForTierRange(
        uint256 report_,
        uint256 startTier_,
        uint256 endTier_,
        uint256 timestamp_
    ) internal pure maxTier(endTier_) returns (uint256 updatedReport_) {
        unchecked {
            uint256 offset_;
            for (uint256 i_ = startTier_; i_ < endTier_; i_++) {
                offset_ = i_ * 32;
                report_ =
                    (report_ &
                        ~uint256(
                            uint256(TierConstants.NEVER_TIME) << offset_
                        )) |
                    uint256(timestamp_ << offset_);
            }
            updatedReport_ = report_;
        }
    }

    /// Updates a report to a new status.
    ///
    /// Internally dispatches to `truncateTiersAbove` and
    /// `updateBlocksForTierRange`.
    /// The dispatch is based on whether the new tier is above or below the
    /// current tier.
    /// The `startTier_` MUST match the result of `tierAtBlockFromReport`.
    /// It is expected the caller will know the current tier when
    /// calling this function and need to do other things in the calling scope
    /// with it.
    ///
    /// @param report_ The report to update.
    /// @param startTier_ The tier to start updating relative to. Data above
    /// this tier WILL BE LOST so probably should be the current tier.
    /// @param endTier_ The new highest tier held, at the given block number.
    /// @param timestamp_ The timestamp_ to update the highest tier to, and
    /// intermediate tiers from `startTier_`.
    /// @return updatedReport_ The updated report.
    function updateReportWithTierAtTime(
        uint256 report_,
        uint256 startTier_,
        uint256 endTier_,
        uint256 timestamp_
    ) internal pure returns (uint256 updatedReport_) {
        updatedReport_ = endTier_ < startTier_
            ? truncateTiersAbove(report_, endTier_)
            : updateTimesForTierRange(
                report_,
                startTier_,
                endTier_,
                timestamp_
            );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

/// @title Phased
/// @notice `Phased` is an abstract contract that defines up to `9` phases that
/// an implementing contract moves through.
///
/// Phase `0` is always the first phase and does not, and cannot, be set
/// expicitly. Effectively it is implied that phase `0` has been active
/// since block zero.
///
/// Each subsequent phase `1` through `8` must be scheduled sequentially and
/// explicitly at a block timestamp.
///
/// Only the immediate next phase can be scheduled with `scheduleNextPhase`,
/// it is not possible to schedule multiple phases ahead.
///
/// Multiple phases can be scheduled in a single second if each scheduled phase
/// is scheduled for the current block OR the contract is operating on a chain
/// with sub-second block times. I.e. if uniqueness of block timestamps is NOT
/// enforced by a chain then phases scheduling can share a timstamp across
/// multiple transactions. To enforce uniqueness of timestamps across
/// transactions on subsecond blockchains, simply schedule the final phase
/// shift of a transaction in the future.
///
/// Several utility functions and modifiers are provided.
///
/// One event `PhaseShiftScheduled` is emitted each time a phase shift is
/// scheduled (not when the scheduled phase is reached).
///
/// @dev `Phased` contracts have a defined timeline with available
/// functionality grouped into phases.
/// Every `Phased` contract starts at `0` and moves sequentially
/// through phases `1` to `8`.
/// Every `Phase` other than `0` is optional, there is no requirement
/// that all 9 phases are implemented.
/// Phases can never be revisited, the inheriting contract always moves through
/// each achieved phase linearly.
/// This is enforced by only allowing `scheduleNextPhase` to be called once per
/// phase.
/// It is possible to call `scheduleNextPhase` several times in a single second
/// but the `block.timestamp` for each phase must be reached each time to
/// schedule the next phase.
/// Importantly there are events and several modifiers and checks available to
/// ensure that functionality is limited to the current phase.
/// The full history of each phase shift block is recorded as a fixed size
/// array of `uint32`.
contract Phased {
    /// @dev Every phase block starts uninitialized.
    /// Only uninitialized blocks can be set by the phase scheduler.
    uint32 private constant UNINITIALIZED = type(uint32).max;
    /// @dev This is how many phases can fit in a `uint256`.
    uint256 private constant MAX_PHASE = 8;

    /// `PhaseScheduled` is emitted when the next phase is scheduled.
    /// @param sender `msg.sender` that scheduled the next phase.
    /// @param newPhase The next phase being scheduled.
    /// @param scheduledTime The timestamp the phase will be achieved.
    event PhaseScheduled(
        address sender,
        uint256 newPhase,
        uint256 scheduledTime
    );

    /// 8 phases each as 32 bits to fit a single 32 byte word.
    uint32[MAX_PHASE] public phaseTimes;

    /// Initialize the blocks at "never".
    /// All phase blocks are initialized to `UNINITIALIZED`.
    /// i.e. not fallback solidity value of `0`.
    function initializePhased() internal {
        // Reinitialization is a bug.
        // Only need to check the first block as all times are about to be set
        // to `UNINITIALIZED`.
        assert(phaseTimes[0] < 1);
        uint32[MAX_PHASE] memory phaseTimes_ = [
            UNINITIALIZED,
            UNINITIALIZED,
            UNINITIALIZED,
            UNINITIALIZED,
            UNINITIALIZED,
            UNINITIALIZED,
            UNINITIALIZED,
            UNINITIALIZED
        ];
        phaseTimes = phaseTimes_;
        // 0 is always the timestamp for implied phase 0.
        emit PhaseScheduled(msg.sender, 0, 0);
    }

    /// Pure function to reduce an array of phase times and block timestamp to
    /// a specific `Phase`.
    /// The phase will be the highest attained even if several phases have the
    /// same timestamp.
    /// If every phase block is after the timestamp then `0` is returned.
    /// If every phase block is before the timestamp then `MAX_PHASE` is
    /// returned.
    /// @param phaseTimes_ Fixed array of phase times to compare against.
    /// @param timestamp_ Determine the relevant phase relative to this time.
    /// @return phase_ The "current" phase relative to the timestamp and phase
    /// times list.
    function phaseAtTime(
        uint32[MAX_PHASE] memory phaseTimes_,
        uint256 timestamp_
    ) public pure returns (uint256 phase_) {
        for (phase_ = 0; phase_ < MAX_PHASE; phase_++) {
            if (timestamp_ < phaseTimes_[phase_]) {
                break;
            }
        }
    }

    /// Pure function to reduce an array of phase times and phase to a
    /// specific timestamp.
    /// `Phase.ZERO` will always return block `0`.
    /// Every other phase will map to a time in `phaseTimes_`.
    /// @param phaseTimes_ Fixed array of phase blocks to compare against.
    /// @param phase_ Determine the relevant block number for this phase.
    /// @return timestamp_ The timestamp for the phase according to
    /// `phaseTimes_`.
    function timeForPhase(uint32[MAX_PHASE] memory phaseTimes_, uint256 phase_)
        public
        pure
        returns (uint256 timestamp_)
    {
        timestamp_ = phase_ > 0 ? phaseTimes_[phase_ - 1] : 0;
    }

    /// Impure read-only function to return the "current" phase from internal
    /// contract state.
    /// Simply wraps `phaseAtTime` for current values of `phaseTimes`
    /// and `block.timestamp`.
    function currentPhase() public view returns (uint256 phase_) {
        phase_ = phaseAtTime(phaseTimes, block.timestamp);
    }

    /// Modifies functions to only be callable in a specific phase.
    /// @param phase_ Modified functions can only be called during this phase.
    modifier onlyPhase(uint256 phase_) {
        require(currentPhase() == phase_, "BAD_PHASE");
        _;
    }

    /// Modifies functions to only be callable in a specific phase OR if the
    /// specified phase has passed.
    /// @param phase_ Modified function only callable during or after this
    /// phase.
    modifier onlyAtLeastPhase(uint256 phase_) {
        require(currentPhase() >= phase_, "MIN_PHASE");
        _;
    }

    /// Writes the timestamp for the next phase.
    /// Only uninitialized times can be written to.
    /// Only the immediate next phase relative to `currentPhase` can be written
    /// to. It is still required to specify the `phase_` so that it is explicit
    /// and clear in the calling code which phase is being moved to.
    /// Emits `PhaseShiftScheduled` with the phase timestamp.
    /// @param phase_ The phase being scheduled.
    /// @param timestamp_ The timestamp for the phase.
    function schedulePhase(uint256 phase_, uint256 timestamp_) internal {
        require(block.timestamp <= timestamp_, "NEXT_TIME_PAST");
        require(timestamp_ < UNINITIALIZED, "NEXT_TIME_UNINITIALIZED");
        // Don't need to check for underflow as the index will be used as a
        // fixed array index below. Implies that scheduling phase `0` is NOT
        // supported.
        uint256 index_;
        unchecked {
            index_ = phase_ - 1;
        }
        // Bit of a hack to check the current phase against the index to
        // save calculating the subtraction twice.
        require(currentPhase() == index_, "NEXT_PHASE");

        require(UNINITIALIZED == phaseTimes[index_], "NEXT_TIME_SET");

        // Cannot exceed UNINITIALIZED (see above) so don't need to check
        // overflow on downcast.
        unchecked {
            phaseTimes[index_] = uint32(timestamp_);
        }

        emit PhaseScheduled(msg.sender, phase_, timestamp_);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
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
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

/// @title TierConstants
/// @notice Constants for use with tier logic.
library TierConstants {
    /// NEVER is 0xFF.. as it is infinitely in the future.
    /// NEVER for an entire report.
    uint256 internal constant NEVER_REPORT = type(uint256).max;
    /// NEVER for a single tier time.
    uint32 internal constant NEVER_TIME = type(uint32).max;

    /// Always is 0 as it is the genesis block.
    /// Tiers can't predate the chain but they can predate an `ITierV2`
    /// contract.
    uint256 internal constant ALWAYS = 0;

    /// Account has never held a tier.
    uint256 internal constant TIER_ZERO = 0;

    /// Magic number for tier one.
    uint256 internal constant TIER_ONE = 1;
    /// Magic number for tier two.
    uint256 internal constant TIER_TWO = 2;
    /// Magic number for tier three.
    uint256 internal constant TIER_THREE = 3;
    /// Magic number for tier four.
    uint256 internal constant TIER_FOUR = 4;
    /// Magic number for tier five.
    uint256 internal constant TIER_FIVE = 5;
    /// Magic number for tier six.
    uint256 internal constant TIER_SIX = 6;
    /// Magic number for tier seven.
    uint256 internal constant TIER_SEVEN = 7;
    /// Magic number for tier eight.
    uint256 internal constant TIER_EIGHT = 8;
    /// Maximum tier is `TIER_EIGHT`.
    uint256 internal constant MAX_TIER = TIER_EIGHT;
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

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

/// An `ISale` can be in one of 4 possible states and a linear progression is
/// expected from an "in flight" status to an immutable definitive outcome.
/// - Pending: The sale is deployed onchain but cannot be interacted with yet.
/// - Active: The sale can now be bought into and otherwise interacted with.
/// - Success: The sale has ended AND reached its minimum raise target.
/// - Fail: The sale has ended BUT NOT reached its minimum raise target.
/// Once an `ISale` reaches `Active` it MUST NOT return `Pending` ever again.
/// Once an `ISale` reaches `Success` or `Fail` it MUST NOT return any other
/// status ever again.
enum SaleStatus {
    Pending,
    Active,
    Success,
    Fail
}

interface ISale {
    /// Returns the address of the token being sold in the sale.
    /// MUST NOT change during the lifecycle of the sale contract.
    function token() external view returns (address);

    /// Returns the address of the token that sale prices are denominated in.
    /// MUST NOT change during the lifecycle of the sale contract.
    function reserve() external view returns (address);

    /// Returns the current `SaleStatus` of the sale.
    /// Represents a linear progression of the sale through its major lifecycle
    /// events.
    function saleStatus() external view returns (SaleStatus);
}