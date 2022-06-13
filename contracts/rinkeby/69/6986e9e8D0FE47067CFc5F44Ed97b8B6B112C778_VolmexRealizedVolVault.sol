// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "../../libraries/WrappedAuction.sol";
import "../../storage/VolmexRealizedVolVaultStorage.sol";
import "./base/VolmexVault.sol";
import "../../interfaces/IVToken.sol";
import "../../interfaces/IPriceOracle.sol";

/**
 * @title Volmex RealizedVol vault
 * @author volmex.finance [[email protected]]
 */
contract VolmexRealizedVolVault is VolmexVault, VolmexRealizedVolVaultStorage {
    using SafeMathUpgradeable for uint256;

    // The minimum duration for an option auction.
    uint256 private constant MIN_AUCTION_DURATION = 5 minutes;

    // Address of VToken contract template used to deploy minimal proxy
    address public vTokenTemplate;

    // close time for commitClose
    uint256 public closeTime;

    // vaults duration
    uint256 public vaultsDuration;

    // Store the PnL on current VToken
    mapping(address => uint256) public vTokenPnL;

    /**
     * @notice Initialization parameters for the vault.
     * @param _owner is the owner of the vault with critical permissions
     * @param _feeRecipient is the address to recieve vault performance and management fees
     * @param _managementFee is the management fee pct.
     * @param _performanceFee is the perfomance fee pct.
     * @param _tokenName is the name of the token
     * @param _tokenSymbol is the symbol of the token
     * @param _auctionDuration is the duration of the auction
     */
    struct InitParams {
        address _owner;
        address _keeper;
        address _feeRecipient;
        uint256 _managementFee;
        uint256 _performanceFee;
        string _tokenName;
        string _tokenSymbol;
        string _tokenExpiry;
        uint256 _expiryTimestamp;
        uint256 _auctionDuration;
    }

    event AuctionDurationSet(
        uint256 auctionDuration,
        uint256 newAuctionDuration
    );

    event VaultsDurationSet(uint256 newVaultsDuration);

    event InstantWithdraw(
        address indexed account,
        uint256 amount,
        uint256 round
    );

    event OpenShort(
        address indexed newVToken,
        uint256 depositAmount,
        address indexed manager
    );

    event VTokenRedeemed(address indexed account, uint256 amountToBeWithdraw);

    event NextVTokenRolled(
        uint256 indexed round,
        uint256 minVaultDeposit,
        uint256 minVtokenPremium,
        uint256 assetPrice,
        uint256 vTokenAmount,
        bool isAuctionStart
    );

    event VTokenRoundClosed(
        address indexed vTokenAddress,
        uint256 indexed round,
        uint256 premium,
        uint256 delta,
        uint256 vTokenPrice,
        uint256 nextVTokenReadyAt
    );

    /**
     * @notice Initializes the Vault contract with storage variables.
     *
     * @param _usdc is the USDC contract
     * @param _auction is the contract address that facilitates auctions
     * @param _vTokenTemplate is the VToken contract template
     * @param _priceOracle is the address of Oracle contract
     * @param _controller address of controller contract
     * @param _minVaultDeposit minimum amount deposit in vault
     * @param _initParams is the struct with vault initialization parameters
     * @param _vaultParams is the struct with vault general data
     */
    function initialize(
        address _usdc,
        address _auction,
        address _vTokenTemplate,
        address _priceOracle,
        address _controller,
        uint256 _minVaultDeposit,
        InitParams calldata _initParams,
        Vault.VaultParams calldata _vaultParams
    ) external initializer {
        __VolmexVault_init(
            _usdc,
            _auction,
            _controller,
            _initParams._owner,
            _initParams._keeper,
            _initParams._feeRecipient,
            _initParams._managementFee,
            _initParams._performanceFee,
            _initParams._tokenName,
            _initParams._tokenSymbol,
            _initParams._tokenExpiry,
            _initParams._expiryTimestamp,
            _vaultParams
        );
        require(
            _vTokenTemplate != address(0),
            "VolmexRealizedVolVault: Zero address provided for template"
        );
        require(
            _priceOracle != address(0),
            "VolmexRealizedVolVault: Zero address provided for price oracle"
        );
        vTokenTemplate = _vTokenTemplate;
        priceOracle = _priceOracle;

        require(
            _initParams._auctionDuration >= MIN_AUCTION_DURATION,
            "VolmexRealizedVolVault: !_auctionDuration"
        );
        require(
            _minVaultDeposit > 0,
            "VolmexRealizedVolVault: !minVaultDeposit"
        );
        auctionDuration = _initParams._auctionDuration;
        minVaultDeposit[vaultState.round] = _minVaultDeposit;
        vTokenState.nextVToken = VaultLifecycle.cloneVToken(
            string(
                abi.encodePacked(
                    "VToken ",
                    _initParams._tokenName
                )
            ),
            string(
                abi.encodePacked("v", _initParams._tokenSymbol)
            ),
            vTokenTemplate,
            vaultParams,
            0
        );
    }

    /************************************************
     *  SETTERS
     ***********************************************/

    /**
     * @notice Sets the new auction duration
     * @param _newAuctionDuration is the auction duration
     */
    function setAuctionDuration(uint256 _newAuctionDuration)
        external
        onlyOwner
    {
        require(
            _newAuctionDuration >= MIN_AUCTION_DURATION,
            "VolmexRealizedVolVault: Invalid auction duration"
        );

        emit AuctionDurationSet(auctionDuration, _newAuctionDuration);

        auctionDuration = _newAuctionDuration;
    }

    /**
     * @notice Sets the new vaults duration
     * @param _newVaultsDuration is the auction duration
     */
    function setVaultsDuration(uint256 _newVaultsDuration) external onlyKeeper {
        require(
            _newVaultsDuration > 0,
            "VolmexRealizedVolVault: vaults duration can't be zero"
        );

        emit VaultsDurationSet(_newVaultsDuration);

        vaultsDuration = _newVaultsDuration;
    }

    function setPriceOracle(address _newPriceOracle) external {
        priceOracle = _newPriceOracle;
    }

    /************************************************
     *  VAULT OPERATIONS
     ***********************************************/

    /**
     * @notice Withdraws the assets on the vault using the outstanding `DepositReceipt.amount`
     * @param _amount is the amount to withdraw
     */
    function withdrawInstantly(uint256 _amount) external nonReentrant {
        Vault.DepositReceipt storage depositReceipt = depositReceipts[
            msg.sender
        ];

        uint256 currentRound = vaultState.round;
        require(_amount > 0, "VolmexRealizedVolVault: !amount");
        require(
            depositReceipt.round == currentRound,
            "VolmexRealizedVolVault: Invalid round"
        );

        uint256 receiptAmount = depositReceipt.amount;
        require(
            receiptAmount >= _amount,
            "VolmexRealizedVolVault: Exceed amount"
        );

        // Subtraction underflow checks already ensure it is smaller than uint104
        depositReceipt.amount = uint104(receiptAmount.sub(_amount));
        vaultState.totalPending = uint128(
            uint256(vaultState.totalPending).sub(_amount)
        );
        uint256 sharesToBeBurn = previewDeposit(_amount);
        _burn(msg.sender, sharesToBeBurn);
        emit InstantWithdraw(msg.sender, _amount, currentRound);

        transferAsset(msg.sender, _amount);
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     */
    function completeWithdraw() external nonReentrant {
        uint256 withdrawAmount = _completeWithdraw();
        lastQueuedWithdrawAmount = uint128(
            uint256(lastQueuedWithdrawAmount).sub(withdrawAmount)
        );
    }

    /**
     * @notice close the existing vToken and calculates PnL for vaultSharePrice.
     * input false and 0 for auctioning through vaults auction contract.
     */
    function commitAndClose()
        external
        onlyKeeper
        nonReentrant
    {
        require(
            block.timestamp >= closeTime,
            "VolmexVault: Duration of vault is not over yet"
        );
        address oldVToken = vTokenState.currentVToken;

        VaultLifecycle.CloseParams memory closeParams = VaultLifecycle
            .CloseParams({
                vTokenTemplate: vTokenTemplate,
                USDC: USDC,
                currentVToken: oldVToken,
                delay: DELAY,
                performanceFee: performanceFee
            });

        (address vTokenAddress, uint256 premium, uint256 delta) = VaultLifecycle
            .commitAndClose(
                feeRecipient,
                priceOracle,
                closeParams,
                vaultParams,
                AUCTION,
                vTokenAuctionID
            );
        uint256 assetDelta = (delta.mul(10**6)).div(10**6);
        ShareMath.assertUint104(premium);
        currentVTokenPremium = uint104(premium);
        vTokenState.delta = assetDelta;
        vTokenState.nextVToken = vTokenAddress;
        vaultState.isAuctionStart = false;
        vaultState.nextRollOverTime = block.timestamp + PERIOD;

        uint256 vTokenPrice = 0;
        vTokenPrice = VaultLifecycle.getVTokenPrice(AUCTION, vTokenAuctionID);
        uint256 round = vaultState.round;
        if (assetDelta > vTokenPrice) {
            vTokenPnL[oldVToken] = assetDelta.sub(vTokenPrice) > vTokenPrice
                ? 0
                : assetDelta.sub(vTokenPrice);
            vaultSharePrice[round] =
                minVaultDeposit[round] +
                assetDelta.sub(vTokenPrice);
        } else {
            vTokenPnL[oldVToken] = vTokenPrice + vTokenPrice.sub(assetDelta);
            vaultSharePrice[round] =
                minVaultDeposit[round] -
                vTokenPrice.sub(assetDelta);
        }

        uint256 nextVTokenReady = block.timestamp.add(DELAY);
        require(
            nextVTokenReady <= type(uint32).max,
            "VolmexRealizedVolVault: Overflow nextOptionReady"
        );
        vTokenState.nextVTokenReadyAt = uint32(nextVTokenReady);
        emit VTokenRoundClosed(
            vTokenAddress,
            round,
            premium,
            delta,
            vTokenPrice,
            vTokenState.nextVTokenReadyAt
        );
        _closeShort(oldVToken);
    }

    function redeemByMarketMaker(address _vToken, uint256 _amount) external {
        require(_amount > 0, "VolmexRealizedVolVault: shares cannot be zero");
        require(
            _vToken != address(0),
            "VolmexRealizedVolVault: address cannot be zero"
        );
        require(
            _amount <= IVToken(_vToken).balanceOf(msg.sender),
            "VolmexRealizedVolVault: Insufficient balance"
        );
        require(
            vTokenPnL[_vToken] != 0, "VolmexRealizedVolVault: ROund not closed"
        );
        uint256 amountToBeWithdraw = ShareMath.sharesToAsset(
            _amount,
            vTokenPnL[_vToken],
            vaultParams.decimals
        );

        emit VTokenRedeemed(msg.sender, amountToBeWithdraw);

        IVToken(_vToken).burn(msg.sender, _amount);

        require(
            amountToBeWithdraw > 0,
            "VolmexRealizedVolVault: !withdrawAmount"
        );
        transferAsset(msg.sender, amountToBeWithdraw);
    }

    /**
     * @notice Claims the vTokens belonging to the market makers
     * @param _auctionSellOrder is the sell order of the bid
     * @param _auction is the address of the auction contract
     holding custody to the funds
     * @param _volmexRealizedVault is the address of the vault
     */
    function claimAuctionVTokens(
        Vault.AuctionSellOrder memory _auctionSellOrder,
        address _auction,
        address _volmexRealizedVault
    ) external {
        WrappedAuction.claimAuctionVTokens(
            _auctionSellOrder,
            _auction,
            _volmexRealizedVault
        );
    }

    /**
     * @notice Rolls the vault's funds into a new short position.
     * input false for start auction from vaults
     * @param _minVaultDeposit minimum amount for deposit in vault
     * @param _minVtokenPremium minimum vToken premium user have to bid
     */
    function rollToNextVtoken(
        uint256 _minVaultDeposit,
        uint256 _minVtokenPremium
    ) external onlyKeeper nonReentrant {
        (
            address newVToken,
            uint256 lockedBalance,
            uint256 queuedWithdrawAmount
        ) = _rollToNext(uint256(lastQueuedWithdrawAmount));

        lastQueuedWithdrawAmount = queuedWithdrawAmount;

        ShareMath.assertUint104(lockedBalance);
        vaultState.lockedAmount = uint104(lockedBalance);

        emit OpenShort(newVToken, lockedBalance, msg.sender);
        uint16 currentRound = vaultState.round;
        uint256 vTokenAmount = ShareMath.assetToShares(
            lockedBalance,
            minVaultDeposit[currentRound],
            vaultParams.decimals
        );

        IVToken(newVToken).mint(vTokenAmount);
        closeTime = block.timestamp + vaultsDuration;
        vaultState.round = currentRound + 1;
        minVaultDeposit[currentRound + 1] = _minVaultDeposit;
        vTokenState.vTokenMinBidPremium = _minVtokenPremium;
        vaultParams.assetPrice = IPriceOracle(priceOracle).latestAnswer(
            vaultParams.oracleIndex
        );
        vaultState.isAuctionStart = true;
        emit NextVTokenRolled(
            vaultState.round,
            minVaultDeposit[currentRound],
            vTokenState.vTokenMinBidPremium,
            vaultParams.assetPrice,
            vTokenAmount,
            vaultState.isAuctionStart
        );

        _startAuction(_minVtokenPremium);
    }

    /**
     * @notice Initiate the auction.
     */
    function startAuction() external onlyKeeper nonReentrant {
        _startAuction(vTokenState.vTokenMinBidPremium);
    }

    /**
     * @notice Burn the remaining vTokens left over from auction.
     */
    function burnRemainingVTokens() external onlyKeeper nonReentrant {
        IVToken currentVToken = IVToken(vTokenState.currentVToken);
        uint256 leftVTokenAmount = currentVToken.balanceOf(
            address(this)
        );
        uint256 unlockedAssetAmount = ShareMath.sharesToAsset(
            leftVTokenAmount,
            minVaultDeposit[vaultState.round],
            vaultParams.decimals
        );
        vaultState.lockedAmount = uint104(
            uint256(vaultState.lockedAmount).sub(unlockedAssetAmount)
        );

        currentVToken.burn(address(this), leftVTokenAmount);
    }

    function _startAuction(uint256 _minBidPerVtoken) private {
        WrappedAuction.AuctionDetails memory auctionDetails;

        auctionDetails.vTokenAddress = vTokenState.currentVToken;
        auctionDetails.auction = AUCTION;
        auctionDetails.asset = vaultParams.asset;
        auctionDetails.assetDecimals = vaultParams.decimals;
        auctionDetails.duration = auctionDuration;
        auctionDetails.minVtokenPremium = _minBidPerVtoken;

        vTokenAuctionID = VaultLifecycle.startAuction(auctionDetails);
    }

    /**
     * @notice Closes the existing short position for the vault.
     * @param _oldVToken address of old vToken
     */
    function _closeShort(address _oldVToken) private {
        uint256 lockedAmount = vaultState.lockedAmount;
        if (_oldVToken != address(0)) {
            vaultState.lastLockedAmount = uint104(lockedAmount);
        }
        vaultState.lockedAmount = 0;

        vTokenState.currentVToken = address(0);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../vendor/DSMath.sol";
import "./Vault.sol";
import "../interfaces/IAuction.sol";
import "../interfaces/IVolmexRealizedVolVault.sol";

library WrappedAuction {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event InitiateWrappedAuction(
        address indexed auctioningToken,
        address indexed biddingToken,
        uint256 auctionCounter,
        address indexed manager
    );

    event PlaceAuctionBid(
        uint256 auctionId,
        address indexed auctioningToken,
        uint256 sellAmount,
        uint256 buyAmount,
        address indexed bidder
    );

    struct AuctionDetails {
        address vTokenAddress;
        address auction;
        address asset;
        uint256 assetDecimals;
        uint256 duration;
        uint256 minVtokenPremium;
    }

    struct BidDetails {
        address vTokenAddress;
        address auction;
        address asset;
        uint256 assetDecimals;
        uint256 auctionId;
        uint256 lockedBalance;
        uint256 vTokenAllocation;
        uint256 vTokenPremium;
        address bidder;
    }

    /**
     * @notice Starts the new auction
     * @param _auctionDetails is the struct which contains auction data
     */
    function startAuction(AuctionDetails memory _auctionDetails)
        internal
        returns (uint256 auctionID)
    {
        uint256 vTokenSellAmount = getVTokenSellAmount(
            _auctionDetails.vTokenAddress
        );

        IERC20Upgradeable(_auctionDetails.vTokenAddress).safeApprove(
            _auctionDetails.auction,
            vTokenSellAmount
        );

        // minBidAmount is total vTokens to sell * premium per vToken
        // shift decimals to correspond to decimals of USDC for puts
        // and underlying for calls
        uint256 minBidAmount = DSMath.wmul(
            vTokenSellAmount,
            _auctionDetails.minVtokenPremium
        );

        minBidAmount = _auctionDetails.assetDecimals > 18
            ? minBidAmount.mul(10**(_auctionDetails.assetDecimals.sub(18)))
            : minBidAmount.div(
                10**(uint256(18).sub(_auctionDetails.assetDecimals))
            );
        require(
            minBidAmount <= type(uint96).max,
            "WrappedAuction: vTokenSellAmount > type(uint96) max value!"
        );

        uint256 auctionEnd = block.timestamp.add(_auctionDetails.duration);
        auctionID = IAuction(_auctionDetails.auction).initiateAuction(
            // address of vToken we minted and are selling
            _auctionDetails.vTokenAddress,
            // address of asset we want in exchange for vTokens. Should match vault `asset`
            _auctionDetails.asset,
            // orders can be cancelled at any time during the auction
            auctionEnd,
            // order will last for `duration`
            auctionEnd,
            // we are selling all of the vtokens minus a fee taken by auction
            uint96(vTokenSellAmount),
            // the minimum we are willing to sell all the vTokens for.
            uint96(minBidAmount),
            // the minimum bidding amount must be 1 * 10 ** -assetDecimals
            1,
            // the min funding threshold
            0,
            // no atomic closure
            false,
            // access manager contract
            address(0),
            // bytes for storing info like a whitelist for who can bid
            bytes("")
        );

        emit InitiateWrappedAuction(
            _auctionDetails.vTokenAddress,
            _auctionDetails.asset,
            auctionID,
            msg.sender
        );
    }

    /**
     * @notice Claims auction vTokens by market makers
     * @param _auctionSellOrder is the struct which contains sell order data
     * @param _auction address of auction contract
     * @param _volmexRealizedVault address of realized vault contract
     */
    function claimAuctionVTokens(
        Vault.AuctionSellOrder memory _auctionSellOrder,
        address _auction,
        address _volmexRealizedVault
    ) internal {
        bytes32 order = encodeOrder(
            _auctionSellOrder.userId,
            _auctionSellOrder.buyAmount,
            _auctionSellOrder.sellAmount
        );
        bytes32[] memory orders = new bytes32[](1);
        orders[0] = order;
        IAuction(_auction).claimFromParticipantOrder(
            IVolmexRealizedVolVault(_volmexRealizedVault).vTokenAuctionID(),
            orders
        );
    }

    /**
     * @notice returns the vToken sell amount
     * @param _vTokenAddress is the address of vtoken
     */
    function getVTokenSellAmount(address _vTokenAddress)
        internal
        view
        returns (uint256)
    {
        // We take our current vToken balance. That will be our sell amount
        // but vtokens will be transferred to auction contract.
        uint256 vTokenSellAmount = IERC20Upgradeable(_vTokenAddress).balanceOf(
            address(this)
        );

        require(
            vTokenSellAmount <= type(uint96).max,
            "WrappedAuction: vTokenSellAmount > type(uint96) max value!"
        );

        return vTokenSellAmount;
    }

    /**
     * @notice encode the order in bytes
     * @param _userId is the id of user
     * @param _buyAmount is the buyAmount by user
     * @param _sellAmount sellAmount of user
     */
    function encodeOrder(
        uint64 _userId,
        uint96 _buyAmount,
        uint96 _sellAmount
    ) internal pure returns (bytes32) {
        return
            bytes32(
                (uint256(_userId) << 192) +
                    (uint256(_buyAmount) << 96) +
                    uint256(_sellAmount)
            );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

abstract contract VolmexRealizedVolVaultStorageV1 {
    // Current vToken premium
    uint256 public currentVTokenPremium;
    // Auction duration
    uint256 public auctionDuration;
    // Auction id of current vToken
    uint256 public vTokenAuctionID;
    // Oracle contract address
    address public priceOracle;
    // Amount locked for scheduled withdrawals last week;
    uint256 public lastQueuedWithdrawAmount;
}

// We are following Compound's method of upgrading new contract implementation
abstract contract VolmexRealizedVolVaultStorage is
    VolmexRealizedVolVaultStorageV1
{

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "../../../libraries/Vault.sol";
import "../../../libraries/VaultLifecycle.sol";
import "../../../libraries/ShareMath.sol";
import "../../../interfaces/IVolmexVault.sol";
import "../../../interfaces/IVaultsRegistry.sol";
import "../../../interfaces/IVaultsController.sol";
import "../../../interfaces/IERC20Detailed.sol";

contract VolmexVault is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ERC20Upgradeable,
    IVolmexVault
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using ShareMath for Vault.DepositReceipt;

    /************************************************
     *  NON UPGRADEABLE STORAGE
     ***********************************************/

    /// @notice Stores the user's pending deposit for the round
    mapping(address => Vault.DepositReceipt) public depositReceipts;

    /// @notice On every round's close, the pricePerShare value of an vault share token is stored
    /// This is used to determine the number of shares to be returned
    /// to a user with their DepositReceipt.depositAmount
    mapping(uint256 => uint256) public minVaultDeposit;

    // store the vault share price after commit and close method
    mapping(uint256 => uint256) public vaultSharePrice;

    /// @notice Stores pending user withdrawals
    mapping(address => Vault.Withdrawal) public withdrawals;

    /// @notice Vault's parameters like cap, decimals
    Vault.VaultParams public vaultParams;

    /// @notice Vault's lifecycle state like round and locked amounts
    Vault.VaultState public vaultState;

    /// @notice Vault's state of the vTokens sold
    Vault.VTokenState public vTokenState;

    /// @notice Fee recipient for the performance and management fees
    address public feeRecipient;

    /// @notice role in charge of weekly vault operations such as rollToNext and burnRemainingVTokens
    // no access to critical vault changes
    address public keeper;

    /// @notice role in charge of users methods
    address public controller;

    /// @notice Performance fee charged on premiums earned in rollToNext. Only charged when there is no loss.
    uint256 public performanceFee;

    /// @notice Management fee charged on entire AUM in rollToNext. Only charged when there is no loss.
    uint256 public managementFee;

    /// @notice USDC 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    address public USDC;

    /// @notice Deprecated: 15 minute timelock between commitAndClose and rollToNext.
    uint256 public constant DELAY = 0;

    /// @notice 7 day period between each vTokens sale.
    uint256 public constant PERIOD = 7 days;

    // Number of weeks per year = 52.142857 weeks * FEE_MULTIPLIER = 52142857
    // Dividing by weeks per year requires doing num.mul(FEE_MULTIPLIER).div(WEEKS_PER_YEAR)
    uint256 private constant WEEKS_PER_YEAR = 52142857;

    // AUCTION is Wrapped protocol's contract for initiating auctions and placing bids
    address public AUCTION;

    // Timestamp of the Vaults expiry
    uint256 public expiryTimestamp;

    /**
     * @dev Throws if the vaultls is expired.
     */
    modifier isExpired() {
        require(expiryTimestamp >= block.timestamp, "VolmexVault: Vault expired");
        _;
    }

    /**
     * @notice Initializes the Vault contract with storage variables.
     *
     * @param _usdc is the USDC contract
     * @param _auction is the contract address that facilitates auctions
     * @param _owner is the address of the Owner or multisig
     * @param _keeper is the address of the multisig which handles VToken burn and rollover
     * @param _feeRecipient is the address of the contract which will receive the fee
     * @param _managementFee is the amount of management fee deducted on yearly basis
     * @param _performanceFee is the amount of fees charged on premium earned
     * @param _tokenName is the name of the Vault token
     * @param _tokenSymbol is the symbol of Vault token
     */
    function __VolmexVault_init(
        address _usdc,
        address _auction,
        address _controller,
        address _owner,
        address _keeper,
        address _feeRecipient,
        uint256 _managementFee,
        uint256 _performanceFee,
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _tokenExpiry,
        uint256 _expiryTimestamp,
        Vault.VaultParams calldata _vaultParams
    ) internal initializer {
        require(_usdc != address(0), "VolmexVault: !_usdc");
        require(_auction != address(0), "VolmexVault: !_auction");
        require(_controller != address(0), "VolmexVault: !_controller");

        USDC = _usdc;
        AUCTION = _auction;
        controller = _controller;

        VaultLifecycle.verifyInitializerParams(
            _owner,
            _keeper,
            _feeRecipient,
            _performanceFee,
            _managementFee,
            _tokenName,
            _tokenSymbol,
            _vaultParams
        );

        __ReentrancyGuard_init();
        __ERC20_init(
            string(abi.encodePacked("Volmex ", _tokenName, "-", _tokenExpiry)),
            string(abi.encodePacked(_tokenSymbol, "-", _tokenExpiry))
        );
        __Ownable_init_unchained();
        transferOwnership(_owner);

        keeper = _keeper;

        feeRecipient = _feeRecipient;
        performanceFee = _performanceFee;
        managementFee = _managementFee.mul(Vault.FEE_MULTIPLIER).div(
            WEEKS_PER_YEAR
        );
        expiryTimestamp = _expiryTimestamp;
        vaultParams = _vaultParams;

        uint256 assetBalance = IERC20Upgradeable(vaultParams.asset).balanceOf(
            address(this)
        );
        ShareMath.assertUint104(assetBalance);
        vaultState.lastLockedAmount = uint104(assetBalance);

        vaultState.round = 1;
    }

    /**
     * @dev Throws if called by any account other than the keeper.
     */
    modifier onlyKeeper() {
        require(msg.sender == keeper, "VolmexVault: !keeper");
        _;
    }

    /**
     * @dev Throws if called by any account other than the controller.
     */
    modifier onlyVaultsController() {
        require(
            msg.sender == controller,
            "VolmexVault: Caller is not controller contract"
        );
        _;
    }

    /************************************************
     *  SETTERS
     ***********************************************/

    /**
     * @notice Sets the new keeper
     * @param _newKeeper is the address of the new keeper
     */
    function setNewKeeper(address _newKeeper) external onlyOwner {
        require(_newKeeper != address(0), "VolmexVault: !newKeeper");
        keeper = _newKeeper;
    }

    /**
     * @notice Sets the new fee recipient
     * @param _newFeeRecipient is the address of the new fee recipient
     */
    function setFeeRecipient(address _newFeeRecipient) external onlyOwner {
        require(
            _newFeeRecipient != address(0),
            "VolmexVault: !newFeeRecipient"
        );
        require(
            _newFeeRecipient != feeRecipient,
            "VolmexVault: Must be new feeRecipient"
        );
        feeRecipient = _newFeeRecipient;
    }

    /**
     * @notice Sets the management fee for the vault
     * @param _newManagementFee is the management fee (6 decimals). ex: 2 * 10 ** 6 = 2%
     */
    function setManagementFee(uint256 _newManagementFee) external onlyOwner {
        require(
            _newManagementFee < 100 * Vault.FEE_MULTIPLIER,
            "VolmexVault: Invalid management fee"
        );

        // We are dividing annualized management fee by num weeks in a year
        uint256 weeklyManagementFee = _newManagementFee
            .mul(Vault.FEE_MULTIPLIER)
            .div(WEEKS_PER_YEAR);

        emit ManagementFeeSet(managementFee, weeklyManagementFee);

        managementFee = weeklyManagementFee;
    }

    /**
     * @notice Sets the performance fee for the vault
     * @param _newPerformanceFee is the performance fee (6 decimals). ex: 20 * 10 ** 6 = 20%
     */
    function setPerformanceFee(uint256 _newPerformanceFee) external onlyOwner {
        require(
            _newPerformanceFee < 100 * Vault.FEE_MULTIPLIER,
            "VolmexVault: Invalid performance fee"
        );

        emit PerformanceFeeSet(performanceFee, _newPerformanceFee);

        performanceFee = _newPerformanceFee;
    }

    /**
     * @notice Sets a new cap for deposits
     * @param _newCap is the new cap for deposits
     */
    function setCap(uint256 _newCap) external onlyOwner {
        require(_newCap > 0, "VolmexVault: !newCap");
        ShareMath.assertUint104(_newCap);
        emit CapSet(vaultParams.cap, _newCap);
        vaultParams.cap = uint104(_newCap);
    }

    /************************************************
     *  DEPOSIT & WITHDRAWALS
     ***********************************************/

    /**
     * @notice Deposits the `asset` from msg.sender.
     * @param _amount is the amount of `asset` to deposit
     * @param _sender address of depositor
     */
    function deposit(uint256 _amount, address _sender)
        external
        nonReentrant
        onlyVaultsController
        isExpired
    {
        require(
            _amount >= minVaultDeposit[vaultState.round],
            "VolmexVault: !minVaultDeposit"
        );

        _depositFor(_amount, _sender);
        uint256 currentShares = ShareMath.assetToShares(
            _amount,
            minVaultDeposit[vaultState.round],
            vaultParams.decimals
        );

        // An approve() by the msg.sender is required beforehand

        IVaultsController(controller).transferAssetToVault(
            IERC20Detailed(vaultParams.asset),
            _sender,
            _amount
        );
        _mint(_sender, currentShares);
    }

    /**
     * @notice Mints the shares and receives the asset amount
     * @param _shares is the amount of vault share
     */
    function mint(uint256 _shares, address _receiver)
        external
        nonReentrant
        onlyVaultsController
        isExpired
    {
        uint256 assets = ShareMath.sharesToAsset(
            _shares,
            minVaultDeposit[vaultState.round],
            vaultParams.decimals
        );
        require(
            assets >= minVaultDeposit[vaultState.round],
            "VolmexVault: !minVaultDeposit"
        );

        _depositFor(assets, _receiver);

        // An approve() by the msg.sender is required beforehand
        IVaultsController(controller).transferAssetToVault(
            IERC20Detailed(vaultParams.asset),
            _receiver,
            assets
        );
        _mint(_receiver, _shares);
    }

    /**
     * @notice Deposits the `asset` from msg.sender added to `creditor`'s deposit.
     * @notice Used for vault -> vault deposits on the user's behalf
     * @param _amount is the amount of `asset` to deposit
     * @param _creditor is the address who deposited asset for reciever
     * @param _receiver is the address who can claim shares
     */
    function depositFor(
        uint256 _amount,
        address _creditor,
        address _receiver
    ) external nonReentrant onlyVaultsController isExpired {
        require(
            _amount >= minVaultDeposit[vaultState.round],
            "VolmexVault: !minVaultDeposit"
        );
        require(
            _receiver != address(0),
            "VolmexVault: address of receiver cannot be zero"
        );

        _depositFor(_amount, _receiver);
        uint256 currentShares = ShareMath.assetToShares(
            _amount,
            minVaultDeposit[vaultState.round],
            vaultParams.decimals
        );

        // An approve() by the msg.sender is required beforehand
        IVaultsController(controller).transferAssetToVault(
            IERC20Detailed(vaultParams.asset),
            _creditor,
            _amount
        );
        _mint(_receiver, currentShares);
    }

    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param _numShares is the number of shares to withdraw
     */
    function initiateWithdraw(uint256 _numShares) external nonReentrant {
        require(
            _numShares <= balanceOf(msg.sender),
            "VolmexVault: !enough shares"
        );
        require(_numShares > 0, "VolmexVault: !numShares");

        // We do a max redeem before initiating a withdrawal
        // But we check if they must first have unredeemed shares
        if (
            depositReceipts[msg.sender].amount > 0 ||
            depositReceipts[msg.sender].unredeemedShares > 0
        ) {
            _redeem(0, true);
        }

        // This caches the `round` variable used in shareBalances
        uint256 currentRound = vaultState.round - 1;
        Vault.Withdrawal storage withdrawal = withdrawals[msg.sender];

        bool withdrawalIsSameRound = withdrawal.round == currentRound;

        emit InitiateWithdraw(msg.sender, _numShares, currentRound);

        uint256 existingShares = uint256(withdrawal.shares);

        uint256 withdrawalShares;
        if (withdrawalIsSameRound) {
            withdrawalShares = existingShares.add(_numShares);
        } else {
            require(existingShares == 0, "VolmexVault: Existing withdraw");
            withdrawalShares = _numShares;
            withdrawals[msg.sender].round = uint16(currentRound);
        }
        ShareMath.assertUint128(withdrawalShares);
        withdrawals[msg.sender].shares = uint128(withdrawalShares);

        uint256 newQueuedWithdrawShares = uint256(
            vaultState.queuedWithdrawShares
        ).add(_numShares);
        ShareMath.assertUint128(newQueuedWithdrawShares);
        vaultState.queuedWithdrawShares = uint128(newQueuedWithdrawShares);
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param _numShares is the number of shares to redeem
     */
    function redeem(uint256 _numShares) external nonReentrant {
        require(_numShares > 0, "VolmexVault: !numShares");
        _redeem(_numShares, false);
    }

    /**
     * @notice Redeems the entire unredeemedShares balance that is owed to the account
     */
    function maxRedeem() external nonReentrant {
        _redeem(0, true);
    }

    /************************************************
     *  GETTERS
     ***********************************************/

    /**
     * @notice Getter for returning the account's share balance including unredeemed shares
     * @param _account is the account to lookup share balance for
     * @return the share balance
     */
    function shares(address _account) public view returns (uint256) {
        (uint256 heldByAccount, uint256 heldByVault) = shareBalances(_account);
        return heldByAccount.add(heldByVault);
    }

    /**
     * @notice Getter for returning the account's share balance split between account and vault holdings
     * @param _account is the account to lookup share balance for
     * @return heldByAccount is the shares held by account
     * @return heldByVault is the shares held on the vault (unredeemedShares)
     */
    function shareBalances(address _account)
        public
        view
        returns (uint256 heldByAccount, uint256 heldByVault)
    {
        Vault.DepositReceipt memory depositReceipt = depositReceipts[_account];

        if (depositReceipt.round < ShareMath.PLACEHOLDER_UINT) {
            return (balanceOf(_account), 0);
        }

        uint256 unredeemedShares = depositReceipt.getSharesFromReceipt(
            vaultState.round,
            minVaultDeposit[depositReceipt.round],
            vaultParams.decimals
        );

        return (balanceOf(_account), unredeemedShares);
    }

    /**
     * @notice The price of a unit of share denominated in the `asset`
     */
    function pricePerShare(uint256 round) external view returns (uint256) {
        return minVaultDeposit[round];
    }

    /**
     * @notice retuning the vaults cap
     */
    function cap() external view returns (uint256) {
        return vaultParams.cap;
    }

    /**
     * @notice The vaults next vToken ready at this timestamp
     */
    function nextVTokenReadyAt() external view returns (uint256) {
        return vTokenState.nextVTokenReadyAt;
    }

    /**
     *@notice getter for returning current vToken
     * @return vaults current vToken
     */
    function currentVToken() external view returns (address) {
        return vTokenState.currentVToken;
    }

    /**
     *@notice returning the next vToken
     * @return vaults next vtoken
     */
    function nextVToken() external view returns (address) {
        return vTokenState.nextVToken;
    }

    /**
     * @notice getter for returning total pending amount
     * @return total pending amount
     */
    function totalPending() external view returns (uint256) {
        return vaultState.totalPending;
    }

    /**
     * @notice getter for returning next rollover timestamp
     * @return total pending amount
     */
    function getNextRollOver() external view returns (uint256) {
        return vaultState.nextRollOverTime - block.timestamp;
    }

    /**
     * @notice max amount user can deposit
     */
    function maxDeposit(address) external view virtual returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @notice max amount user can mint
     */
    function maxMint(address) external view virtual returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @notice getter for returning the max withdraw
     * @param owner address of account
     * @return asset amount
     */
    function maxWithdraw(address owner)
        external
        view
        virtual
        returns (uint256)
    {
        return
            ShareMath.sharesToAsset(
                balanceOf(owner),
                vaultSharePrice[vaultState.round - 1],
                vaultParams.decimals
            );
    }

    /**
     * @notice getter for returning the max redeem amount
     * @param owner address of account
     * @return shares amount
     */
    function maxRedeemShares(address owner) external view virtual returns (uint256) {
        return balanceOf(owner);
    }

    /**
     * @notice Returns the vault's total balance, including the amounts locked into a short position
     * @return total balance of the vault, including the amounts locked in third party protocols
     */
    function totalAssets() public view returns (uint256) {
        return
            uint256(vaultState.lockedAmount).add(
                IERC20Upgradeable(vaultParams.asset).balanceOf(address(this))
            );
    }

    /**
     * @notice Returns the token decimals
     */
    function decimals() public view override returns (uint8) {
        return vaultParams.decimals;
    }

    /**
     * @notice Getter for returning the share to asset amount
     * @param _assets is the amount in usdc
     * @return shares amount received
     */
    function previewDeposit(uint256 _assets)
        public
        view
        virtual
        returns (uint256)
    {
        return
            ShareMath.assetToShares(
                _assets,
                minVaultDeposit[vaultState.round],
                vaultParams.decimals
            );
    }

    /**
     * @notice Getter for returning the share to asset amount
     * @param _shares is the amount of shares
     * @return asset amount
     */
    function previewMint(uint256 _shares)
        public
        view
        virtual
        returns (uint256)
    {
        return
            ShareMath.sharesToAsset(
                _shares,
                minVaultDeposit[vaultState.round],
                vaultParams.decimals
            );
    }

    /**
     * @notice Getter for returning the asset to shares amount
     * @param _assets is the account to lookup share
     * @return shares amount
     */
    function previewWithdraw(uint256 _assets)
        public
        view
        virtual
        returns (uint256)
    {
        return
            ShareMath.assetToShares(
                _assets,
                vaultState.round == 1
                    ? minVaultDeposit[vaultState.round]
                    : vaultSharePrice[vaultState.round - 1],
                vaultParams.decimals
            );
    }

    /**
     * @notice Getter for returning the account's eligiblity if initiate withdraw
     * @param _redeemer is the account to lookup share
     * @return bool value
     */
    function previewInitiate(address _redeemer)
        public
        view
        virtual
        returns (bool)
    {
        Vault.Withdrawal memory withdrawal = withdrawals[_redeemer];
        uint256 ownedShares = balanceOf(_redeemer);
        uint256 withdrawalShare = withdrawal.shares;
        uint256 withdrawalRound = withdrawal.round;
        if (
            (withdrawalShare < ownedShares &&
                withdrawalRound != vaultState.round - 1)
        ) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Getter for returning the account's balance for complete withdraw
     * @param _redeemer is the account to lookup share
     * @return bool value
     */
    function previewRedeem(address _redeemer)
        public
        view
        virtual
        returns (uint256)
    {
        Vault.Withdrawal memory withdrawal = withdrawals[_redeemer];
        uint256 withdrawalShares = withdrawal.shares;
        uint256 withdrawalRound = withdrawal.round;
        if (vaultSharePrice[withdrawalRound + 1] == 0) {
            return 0;
        } else {
            return
                ShareMath.sharesToAsset(
                    withdrawalShares,
                    vaultSharePrice[withdrawalRound + 1],
                    vaultParams.decimals
                );
        }
    }

    /************************************************
     *  INTERNALs
     ***********************************************/

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     * @return withdrawAmount the current withdrawal amount
     */
    function _completeWithdraw() internal returns (uint256) {
        Vault.Withdrawal storage withdrawal = withdrawals[msg.sender];

        uint256 withdrawalShares = withdrawal.shares;
        uint256 withdrawalRound = withdrawal.round;

        // This checks if there is a withdrawal
        require(withdrawalShares > 0, "VolmexVault: Not initiated");

        require(
            withdrawalRound < vaultState.round - 1,
            "VolmexVault: Round not closed"
        );

        // We leave the round number as non-zero to save on gas for subsequent writes
        withdrawals[msg.sender].shares = 0;
        vaultState.queuedWithdrawShares = uint128(
            uint256(vaultState.queuedWithdrawShares).sub(withdrawalShares)
        );
        require(
            vaultSharePrice[withdrawalRound + 1] > 0,
            "VolmexVault: Withdraw in next round"
        );
        uint256 withdrawAmount = ShareMath.sharesToAsset(
            withdrawalShares,
            vaultSharePrice[withdrawalRound + 1],
            vaultParams.decimals
        );

        emit Withdraw(msg.sender, withdrawAmount, withdrawalShares);

        _burn(msg.sender, withdrawalShares);

        require(withdrawAmount != 0, "VolmexVault: !withdrawAmount");
        transferAsset(msg.sender, withdrawAmount);

        return withdrawAmount;
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param _numShares is the number of shares to redeem, could be 0 when isMax=true
     * @param _isMax is flag for when callers do a max redemption
     */
    function _redeem(uint256 _numShares, bool _isMax) internal {
        Vault.DepositReceipt memory depositReceipt = depositReceipts[
            msg.sender
        ];

        // This handles the null case when depositReceipt.round = 0
        // Because we start with round = 1 at `initialize`
        uint256 currentRound = vaultState.round;

        uint256 unredeemedShares = depositReceipt.getSharesFromReceipt(
            currentRound,
            minVaultDeposit[depositReceipt.round],
            vaultParams.decimals
        );

        _numShares = _isMax ? unredeemedShares : _numShares;
        if (_numShares == 0) {
            return;
        }
        require(
            _numShares <= unredeemedShares,
            "VolmexVault: Exceeds available"
        );

        // If we have a depositReceipt on the same round, BUT we have some unredeemed shares
        // we debit from the unredeemedShares, but leave the amount field intact
        // If the round has past, with no new deposits, we just zero it out for new deposits.
        if (depositReceipt.round < currentRound) {
            depositReceipts[msg.sender].amount = 0;
        }

        ShareMath.assertUint128(_numShares);
        depositReceipts[msg.sender].unredeemedShares = uint128(
            unredeemedShares.sub(_numShares)
        );

        emit Redeem(msg.sender, _numShares, depositReceipt.round);
    }

    /**
     * @notice Helper function that performs most administrative tasks
     * such as setting next vToken, minting new shares, getting vault fees, etc.
     * @param _lastQueuedWithdrawAmount is old queued withdraw amount
     * @return newVToken is the new vToken address
     * @return lockedBalance is the new balance used to calculate next vToken mint size or collateral size
     * @return queuedWithdrawAmount is the new queued withdraw amount for this round
     */
    function _rollToNext(uint256 _lastQueuedWithdrawAmount)
        internal
        returns (
            address newVToken,
            uint256 lockedBalance,
            uint256 queuedWithdrawAmount
        )
    {
        require(
            block.timestamp >= vTokenState.nextVTokenReadyAt,
            "VolmexVault: !ready"
        );

        newVToken = vTokenState.nextVToken;
        require(newVToken != address(0), "VolmexVault: !newVToken");

        uint256 currentRound = vaultState.round;
        address recipient = feeRecipient;
        uint256 totalVaultFee;
        uint256 newAssetBalance = IERC20Upgradeable(vaultParams.asset)
            .balanceOf(address(this));
        {
            (
                lockedBalance,
                queuedWithdrawAmount,
                totalVaultFee
            ) = VaultLifecycle.rollover(
                vaultState,
                VaultLifecycle.RolloverParams(
                    vaultParams.decimals,
                    newAssetBalance,
                    totalSupply(),
                    _lastQueuedWithdrawAmount,
                    minVaultDeposit[currentRound],
                    managementFee
                )
            );

            vTokenState.currentVToken = newVToken;
            vTokenState.nextVToken = address(0);

            emit CollectVaultFees(totalVaultFee, currentRound, recipient);

            if (newAssetBalance > vaultParams.cap) {
                vaultState.totalPending = newAssetBalance - vaultParams.cap;
            }
            vaultState.totalPending = 0;
        }

        if (totalVaultFee > 0) {
            transferAsset(payable(recipient), totalVaultFee);
        }

        return (newVToken, lockedBalance, queuedWithdrawAmount);
    }

    /**
     * @notice Helper function to make either an ETH transfer or ERC20 transfer
     * @param _recipient is the receiving address
     * @param _amount is the transfer amount
     */
    function transferAsset(address _recipient, uint256 _amount) internal {
        address asset = vaultParams.asset;
        IERC20Upgradeable(asset).safeTransfer(_recipient, _amount);
    }

    /**
     * @notice Mints the vault shares to the creditor
     * @param _amount is the amount of `asset` deposited
     * @param _creditor is the address to receieve the deposit
     */
    function _depositFor(uint256 _amount, address _creditor) private {
        uint256 currentRound = vaultState.round;
        uint256 totalWithDepositedAmount = totalAssets().add(_amount);

        require(
            totalWithDepositedAmount >= vaultParams.minimumSupply,
            "VolmexVault: Insufficient balance"
        );

        emit Deposit(_creditor, _amount, currentRound);

        Vault.DepositReceipt memory depositReceipt = depositReceipts[_creditor];

        // If we have an unprocessed pending deposit from the previous rounds, we have to process it.
        uint256 unredeemedShares = depositReceipt.getSharesFromReceipt(
            currentRound,
            minVaultDeposit[depositReceipt.round],
            vaultParams.decimals
        );

        uint256 depositAmount = _amount;

        // If we have a pending deposit in the current round, we add on to the pending deposit
        if (currentRound == depositReceipt.round) {
            uint256 newAmount = uint256(depositReceipt.amount).add(_amount);
            depositAmount = newAmount;
        }

        ShareMath.assertUint104(depositAmount);

        depositReceipts[_creditor] = Vault.DepositReceipt({
            round: uint16(currentRound),
            amount: uint104(depositAmount),
            unredeemedShares: uint128(unredeemedShares)
        });

        uint256 newTotalPending = uint256(vaultState.totalPending).add(_amount);
        ShareMath.assertUint128(newTotalPending);

        vaultState.totalPending = uint128(newTotalPending);
    }

    // Gap is left to avoid storage collisions.
    uint256[30] private ____gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IVToken is IERC20Upgradeable {

    //getter
    function auth() external view returns (address);
    function asset() external view returns (address);
    function isShort() external view returns (bool);

    //setters
    function mint(uint256 _supply) external;
    function burn(address _account, uint256 _amount) external;
    function __VToken_init(
        string memory _name,
        string memory _symbol,
        address _assetToken,
        bool _isShort
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IPriceOracle {
    event AggregatorsSet(address[] aggregators);

    //setter
    function setAggregators(address[] calldata _aggregators) external;

    // getters
    function decimals(uint8 _index) external view returns (uint256);
    function latestAnswer(uint8 _index) external view returns (uint256);
    function priceFeeds(uint8 _index) external returns (AggregatorV3Interface);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: BUSL-1.1

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >0.4.13;

library DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    //rounds to zero if x*y < WAD / 2
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    //rounds to zero if x*y < WAD / 2
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    //rounds to zero if x*y < RAY / 2
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

library Vault {
    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    // Fees are 6-decimal places. For example: 20 * 10**6 = 20%
    uint256 internal constant FEE_MULTIPLIER = 10**6;

    // Premium discount has 1-decimal place. For example: 80 * 10**1 = 80%. Which represents a 20% discount.
    uint256 internal constant PREMIUM_DISCOUNT_MULTIPLIER = 10;

    // vTokens have 8 decimal places.
    uint256 internal constant VTOKEN_DECIMALS = 18;

    // Percentage of funds allocated to vTokens is 2 decimal places. 10 * 10**2 = 10%
    uint256 internal constant ALLOCATION_MULTIPLIER = 10**2;

    // Placeholder uint value to prevent cold writes
    uint256 internal constant PLACEHOLDER_UINT = 1;

    struct VaultParams {
        // vTokens type the vault is selling
        bool isShort;
        // Token decimals for vault shares
        uint8 decimals;
        // Asset used in Vault
        address asset;
        // Underlying asset of the vTokens sold by vault
        address underlying;
        // Minimum supply of the vault shares issued, for ETH it's 10**10
        uint56 minimumSupply;
        // Vault cap
        uint256 cap;
        // Price of asset at the time auction starts
        uint256 assetPrice;
        // Oracle index of the current asset
        uint8 oracleIndex;
    }

    struct VTokenState {
        // vTokens that the vault is shorting / longing in the next cycle
        address nextVToken;
        // vTokens that the vault is currently shorting / longing
        address currentVToken;
        // The timestamp when the `nextvTokens` can be used by the vault
        uint32 nextVTokenReadyAt;
        // The movement of the bid asset price
        uint256 delta;
        // minimum amount of vToken
        uint256 vTokenMinBidPremium;
    }

    struct VaultState {
        // 32 byte slot 1
        //  Current round number. `round` represents the number of `period`s elapsed.
        uint16 round;
        // Amount that is currently locked for selling vTokens
        uint256 lockedAmount;
        // Amount that was locked for selling vTokens in the previous round
        // used for calculating performance fee deduction
        uint256 lastLockedAmount;
        // 32 byte slot 2
        // Stores the total tally of how much of `asset` there is
        // to be used to mint rTHETA tokens
        uint256 totalPending;
        // Amount locked for scheduled withdrawals;
        uint256 queuedWithdrawShares;
        // time after which next roll over happen
        uint256 nextRollOverTime;
        // boolean flag for auction status
        bool isAuctionStart;
    }

    struct DepositReceipt {
        // Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        // Deposit amount, max 20,282,409,603,651 or 20 trillion ETH deposit
        uint256 amount;
        // Unredeemed shares balance
        uint256 unredeemedShares;
    }

    struct Withdrawal {
        // Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        // Number of shares withdrawn
        uint256 shares;
    }

    struct AuctionSellOrder {
        // Amount of `asset` token offered in auction
        uint96 sellAmount;
        // Amount of vToken requested in auction
        uint96 buyAmount;
        // User Id of delta vault in latest auction
        uint64 userId;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

library AuctionType {
    struct AuctionData {
        IERC20Upgradeable auctioningToken;
        IERC20Upgradeable biddingToken;
        uint256 orderCancellationEndDate;
        uint256 auctionEndDate;
        bytes32 initialAuctionOrder;
        uint256 minimumBiddingAmountPerOrder;
        uint256 interimSumBidAmount;
        bytes32 interimOrder;
        bytes32 clearingPriceOrder;
        uint96 volumeClearingPriceOrder;
        bool minFundingThresholdNotReached;
        bool isAtomicClosureAllowed;
        uint256 feeNumerator;
        uint256 minFundingThreshold;
    }
}

interface IAuction {

    // getters
    function initiateAuction(
        address _auctioningToken,
        address _biddingToken,
        uint256 orderCancellationEndDate,
        uint256 auctionEndDate,
        uint96 _auctionedSellAmount,
        uint96 _minBidAmount,
        uint256 minimumBiddingAmountPerOrder,
        uint256 minFundingThreshold,
        bool isAtomicClosureAllowed,
        address accessManagerContract,
        bytes memory accessManagerContractData
    ) external returns (uint256);
    function auctionCounter() external view returns (uint256);
    function auctionData(uint256 auctionId)
        external
        view
        returns (AuctionType.AuctionData memory);
    function auctionAccessManager(uint256 auctionId)
        external
        view
        returns (address);
    function auctionAccessData(uint256 auctionId)
        external
        view
        returns (bytes memory);
    function FEE_DENOMINATOR() external view returns (uint256);
    function feeNumerator() external view returns (uint256);

    //setters
    function placeSellOrders(
        uint256 auctionId,
        uint96[] memory _minBuyAmounts,
        uint96[] memory _sellAmounts,
        bytes32[] memory _prevSellOrders,
        bytes calldata allowListCallData
    ) external;

    function placeSellOrdersOnBehalf(
        uint256 auctionId,
        uint96[] memory _minBuyAmounts,
        uint96[] memory _sellAmounts,
        bytes32[] memory _prevSellOrders,
        bytes calldata allowListCallData,
        address orderSubmitter
    ) external;

    function cancelSellOrders(uint256 auctionId, bytes32[] memory _sellOrders)
        external;

    function precalculateSellAmountSum(
        uint256 auctionId,
        uint256 iterationSteps
    ) external;

    function settleAuction(uint256 auctionId) external;

    function claimFromParticipantOrder(
        uint256 auctionId,
        bytes32[] memory orders
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import {Vault} from "../libraries/Vault.sol";
import "./IVolmexVault.sol";

interface IVolmexRealizedVolVault is IVolmexVault {

    function vaultParams() external view returns (Vault.VaultParams memory);
    function vaultState() external view returns (Vault.VaultState memory);
    function vTokenState() external view returns (Vault.VTokenState memory);
    function vTokenAuctionID() external view returns (uint256);
    function setAuctionDuration(uint256 newAuctionDuration) external;
    function setVaultsDuration(uint256 newVaultsDuration) external;
    function withdrawInstantly(uint256 amount) external;
    function completeWithdraw() external;
    function commitAndClose() external;
    function redeemByMarketMaker(address vToken, uint256 shares) external;
    function claimAuctionVTokens(
        Vault.AuctionSellOrder memory auctionSellOrder,
        address auction,
        address counterpartyThetaVault
    ) external;
    function rollToNextVtoken(
        uint256 _minVaultDeposit,
        uint256 _minVtokenPremium
    ) external;
    function startAuction() external;
    function burnRemainingVTokens() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import {Vault} from "../libraries/Vault.sol";

interface IVolmexVault {
    //events
    event Deposit(address indexed account, uint256 amount, uint256 round);

    event InitiateWithdraw(
        address indexed account,
        uint256 shares,
        uint256 round
    );

    event Redeem(address indexed account, uint256 share, uint256 round);

    event ManagementFeeSet(uint256 managementFee, uint256 newManagementFee);

    event PerformanceFeeSet(uint256 performanceFee, uint256 newPerformanceFee);

    event CapSet(uint256 oldCap, uint256 newCap);

    event Withdraw(address indexed account, uint256 amount, uint256 shares);

    event CollectVaultFees(
        uint256 vaultFee,
        uint256 round,
        address indexed feeRecipient
    );

    // getters
    function pricePerShare(uint256 round) external view returns (uint256);
    function minVaultDeposit(uint256 round) external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function nextVTokenReadyAt() external view returns (uint256);
    function currentVToken() external view returns (address);
    function nextVToken() external view returns (address);
    function keeper() external view returns (address);
    function controller() external view returns (address);
    function feeRecipient() external view returns (address);
    function performanceFee() external view returns (uint256);
    function managementFee() external view returns (uint256);
    function expiryTimestamp() external view returns (uint256);
    function totalPending() external view returns (uint256);
    function previewDeposit(uint256 _assets) external view returns (uint256);
    function previewMint(uint256 _shares) external view returns (uint256);
    function previewWithdraw(uint256 _assets) external view returns (uint256);
    function previewRedeem(address _redeemer) external view returns (uint256);
    function previewInitiate(address _redeemer) external view returns (bool);
    function maxDeposit(address) external view returns (uint256);
    function maxMint(address) external view returns (uint256);
    function maxWithdraw(address owner) external view returns (uint256);
    function maxRedeemShares(address owner) external view returns (uint256);
    function shares(address _account) external view returns (uint256);
    function getNextRollOver() external view returns (uint256);
    function shareBalances(address _account)
        external
        view
        returns (uint256 heldByAccount, uint256 heldByVault);

    // setters
    function deposit(uint256 amount, address sender) external;
    function cap() external view returns (uint256);
    function depositFor(uint256 amount, address creditor, address receiver) external;
    function setNewKeeper(address newKeeper) external;
    function setFeeRecipient(address newFeeRecipient) external;
    function setManagementFee(uint256 newManagementFee) external;
    function setPerformanceFee(uint256 newPerformanceFee) external;
    function setCap(uint256 newCap) external;
    function mint(uint256 _shares, address _receiver) external;
    function initiateWithdraw(uint256 _numShares) external;
    function redeem(uint256 _numShares) external;
    function maxRedeem() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

import "./Vault.sol";
import "./ShareMath.sol";
import "./WrappedAuction.sol";
import "../interfaces/IERC20Detailed.sol";
import "../interfaces/IAuction.sol";
import "../interfaces/IVToken.sol";
import "../interfaces/IPriceOracle.sol";

library VaultLifecycle {
    using SafeMathUpgradeable for uint256;

    struct CloseParams {
        address vTokenTemplate;
        address USDC;
        address currentVToken;
        uint256 delay;
        uint256 performanceFee;
    }

    struct RolloverParams {
        uint256 decimals;
        uint256 totalBalance;
        uint256 currentShareSupply;
        uint256 lastQueuedWithdrawAmount;
        uint256 minVaultDeposit;
        uint256 managementFee;
    }

    /**
     * @notice Sets the next vtoken and closing the existing position
     * @param _feeRecipient address of fee receiver
     * @param _priceOracle address of price oracle
     * @param _closeParams is the struct with details of vToken
     * @param _vaultParams is the struct with vault general data
     * @param _auction address of auction contract
     * @param _auctionID index of auction
     * @return vTokenAddress is the address of the new vtoken
     * @return premium is the premium of the new vtoken
     * @return delta is the delta of the new vtoken
     */
    function commitAndClose(
        address _feeRecipient,
        address _priceOracle,
        CloseParams memory _closeParams,
        Vault.VaultParams storage _vaultParams,
        address _auction,
        uint256 _auctionID
    )
        external
        returns (
            address vTokenAddress,
            uint256 premium,
            uint256 delta
        )
    {
        uint256 preAssetPrice = _vaultParams.assetPrice;
        uint256 assetPrice = IPriceOracle(_priceOracle).latestAnswer(
            _vaultParams.oracleIndex
        );
        delta = assetPrice > preAssetPrice
            ? assetPrice - preAssetPrice
            : preAssetPrice - assetPrice;

        uint256 premiumBeforeFee = _getPremium(_auction, _auctionID);
        uint256 performanceFeeInAsset = _closeParams.performanceFee > 0
            ? premiumBeforeFee.mul(_closeParams.performanceFee).div(
                100 * Vault.FEE_MULTIPLIER
            )
            : 0;
        premium = premiumBeforeFee - performanceFeeInAsset;
        IERC20Upgradeable(_vaultParams.asset).transfer(
            _feeRecipient,
            performanceFeeInAsset
        );

        vTokenAddress = cloneVToken(
            string(
                abi.encodePacked(
                    "VToken ",
                    IERC20Detailed(address(this)).symbol()
                )
            ),
            string(
                abi.encodePacked("v", IERC20Detailed(address(this)).symbol())
            ),
            _closeParams.vTokenTemplate,
            _vaultParams,
            _auctionID
        );

        return (vTokenAddress, premium, delta);
    }

    /**
     * @notice Calculate the shares to mint, new price per share, and
      amount of funds to re-allocate as collateral for the new round
     * @param _vaultState is the storage variable vaultState passed from VolmexVault
     * @param _params is the rollover parameters passed to compute the next state
     * @return newLockedAmount is the amount of funds to allocate for the new round
     * @return queuedWithdrawAmount is the amount of funds set aside for withdrawal
     * @return totalVaultFee is the total amount of fee charged by vault
     */
    function rollover(
        Vault.VaultState storage _vaultState,
        RolloverParams memory _params
    )
        external
        view
        returns (
            uint256 newLockedAmount,
            uint256 queuedWithdrawAmount,
            uint256 totalVaultFee
        )
    {
        uint256 currentBalance = _params.totalBalance;
        uint256 pendingAmount = _vaultState.totalPending;
        uint256 queuedWithdrawShares = _vaultState.queuedWithdrawShares;

        uint256 balanceForVaultFees;
        {
            uint256 queuedWithdrawBeforeFee = _params.currentShareSupply > 0
                ? ShareMath.sharesToAsset(
                    queuedWithdrawShares,
                    _params.minVaultDeposit,
                    _params.decimals
                )
                : 0;

            // Deduct the difference between the newly scheduled withdrawals
            // and the older withdrawals
            // so we can charge them fees before they leave
            uint256 withdrawAmountDiff = queuedWithdrawBeforeFee >
                _params.lastQueuedWithdrawAmount
                ? queuedWithdrawBeforeFee.sub(_params.lastQueuedWithdrawAmount)
                : 0;

            balanceForVaultFees = currentBalance
                .sub(queuedWithdrawBeforeFee)
                .add(withdrawAmountDiff);
        }

        {
            (, totalVaultFee) = VaultLifecycle.getVaultFees(
                balanceForVaultFees,
                _vaultState.lastLockedAmount,
                pendingAmount,
                _params.managementFee
            );
        }

        // Take into account the fee
        currentBalance = currentBalance.sub(totalVaultFee);

        {
            queuedWithdrawAmount = _params.currentShareSupply > 0
                ? ShareMath.sharesToAsset(
                    queuedWithdrawShares,
                    _params.minVaultDeposit,
                    _params.decimals
                )
                : 0;
        }

        return (
            currentBalance.sub(queuedWithdrawAmount), // new locked balance subtracts the queued withdrawals
            queuedWithdrawAmount,
            totalVaultFee
        );
    }

    /**
     * @notice Calculates the performance and management fee for this week's round
     * @param _currentBalance is the balance of funds held on the vault after closing short
     * @param _lastLockedAmount is the amount of funds locked from the previous round
     * @param _pendingAmount is the pending deposit amount
     * @param _managementFeePercent is the management fee pct.
     * @return managementFeeInAsset is the management fee
     * @return vaultFee is the total fees
     */
    function getVaultFees(
        uint256 _currentBalance,
        uint256 _lastLockedAmount,
        uint256 _pendingAmount,
        uint256 _managementFeePercent
    ) internal pure returns (uint256 managementFeeInAsset, uint256 vaultFee) {
        // At the first round, currentBalance=0, pendingAmount>0
        // so we just do not charge anything on the first round
        uint256 lockedBalanceSansPending = _currentBalance > _pendingAmount
            ? _currentBalance.sub(_pendingAmount)
            : 0;

        // Take management fee ONLY if difference between
        // last week and this week's vault deposits, taking into account pending
        // deposits and withdrawals, is positive. If it is negative, last week's
        // vault expired ITM past breakeven, and the vault took a loss so we
        // do not collect performance fee for last week
        if (lockedBalanceSansPending > _lastLockedAmount) {
            managementFeeInAsset = _managementFeePercent > 0
                ? lockedBalanceSansPending.mul(_managementFeePercent).div(
                    100 * Vault.FEE_MULTIPLIER
                )
                : 0;

            vaultFee = managementFeeInAsset;
        }
    }

    /**
     * @notice Starts the auction
     * @param _auctionDetails is the struct with all the custom parameters of the auction
     * @return the auction id of the newly created auction
     */
    function startAuction(WrappedAuction.AuctionDetails memory _auctionDetails)
        external
        returns (uint256)
    {
        return WrappedAuction.startAuction(_auctionDetails);
    }

    /**
     * @notice Verify the constructor _params satisfy requirements
     * @param _owner is the owner of the vault with critical permissions
     * @param _keeper addres of keeper
     * @param _feeRecipient is the address to recieve vault performance and management fees
     * @param _performanceFee is the perfomance fee pct.
     * @param _managementFee is the management fee pct.
     * @param _tokenName is the name of the token
     * @param _tokenSymbol is the symbol of the token
     * @param _vaultParams is the struct with vault general data
     */
    function verifyInitializerParams(
        address _owner,
        address _keeper,
        address _feeRecipient,
        uint256 _performanceFee,
        uint256 _managementFee,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams memory _vaultParams
    ) public pure {
        require(_owner != address(0), "VaultLifecycle: !owner");
        require(_keeper != address(0), "VaultLifecycle: !keeper");
        require(_feeRecipient != address(0), "VaultLifecycle: !_feeRecipient");
        require(
            _performanceFee < 100 * Vault.FEE_MULTIPLIER,
            "VaultLifecycle: performanceFee >= 100%"
        );
        require(
            _managementFee < 100 * Vault.FEE_MULTIPLIER,
            "VaultLifecycle: managementFee >= 100%"
        );
        require(bytes(_tokenName).length > 0, "VaultLifecycle: !tokenName");
        require(bytes(_tokenSymbol).length > 0, "VaultLifecycle: !tokenSymbol");

        require(_vaultParams.asset != address(0), "VaultLifecycle: !asset");
        require(
            _vaultParams.underlying != address(0),
            "VaultLifecycle: !underlying"
        );
        require(
            _vaultParams.minimumSupply > 0,
            "VaultLifecycle: !minimumSupply"
        );
        require(_vaultParams.cap > 0, "VaultLifecycle: !cap");
        require(
            _vaultParams.cap > _vaultParams.minimumSupply,
            "VaultLifecycle: cap has to be higher than minimumSupply"
        );
    }

    /**
     * @notice Verify the constructor _params satisfy requirements
     * @param _auction is the address of auction contract
     * @param _auctionID is the index of auction
     * @return vTokenPrice from auction
     */
    function getVTokenPrice(address _auction, uint256 _auctionID)
        public
        view
        returns (uint256)
    {
        AuctionType.AuctionData memory auctionData = IAuction(_auction)
            .auctionData(_auctionID);

        uint256 vTokenPrice;
        (, uint256 buyAmount, uint256 sellAmount) = _decodeOrder(
            auctionData.clearingPriceOrder
        );
        vTokenPrice = (sellAmount) / (buyAmount / 10**18);

        return vTokenPrice;
    }

    /**
     * @notice Clones the vToken
     * @param _name is the name of the token
     * @param _symbol is the symbol of the token
     * @param _template is the address of clonable Token
     * @param _vaultParams is the struct with vault general data
     * @param _auctionID is the index of auction
     * @return address of vToken
     */
    function cloneVToken(
        string memory _name,
        string memory _symbol,
        address _template,
        Vault.VaultParams storage _vaultParams,
        uint256 _auctionID
    ) public returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_name, _symbol, _auctionID));
        IVToken newVToken = IVToken(
            ClonesUpgradeable.cloneDeterministic(_template, salt)
        );
        newVToken.__VToken_init(
            _name,
            _symbol,
            _vaultParams.asset,
            _vaultParams.isShort
        );
        return address(newVToken);
    }

    /**
     * @notice Gets the next vToken expiry timestamp
     * @param _timestamp is the expiry timestamp of the current vToken
     * Examples:
     * getNextFriday(week 1 thursday) -> week 1 friday
     * getNextFriday(week 1 friday) -> week 2 friday
     * getNextFriday(week 1 saturday) -> week 2 friday
     */
    function getNextFriday(uint256 _timestamp) public pure returns (uint256) {
        // dayOfWeek = 0 (sunday) - 6 (saturday)
        uint256 dayOfWeek = ((_timestamp / 1 days) + 4) % 7;
        uint256 nextFriday = _timestamp + ((7 + 5 - dayOfWeek) % 7) * 1 days;
        uint256 friday8am = nextFriday - (nextFriday % (24 hours)) + (8 hours);

        // If the passed timestamp is day=Friday hour>8am, we simply increment it by a week to next Friday
        if (_timestamp >= friday8am) {
            friday8am += 7 days;
        }
        return friday8am;
    }

    function _getPremium(address _auction, uint256 _auctionID)
        private
        view
        returns (uint256)
    {
        AuctionType.AuctionData memory auctionData = IAuction(_auction)
            .auctionData(_auctionID);

        uint96 buyAmount;
        uint96 sellAmount;
        (, buyAmount, sellAmount) = _decodeOrder(
            auctionData.clearingPriceOrder
        );
        return uint256(sellAmount);
    }

    function _decodeOrder(bytes32 _orderData)
        private
        pure
        returns (
            uint64 userId,
            uint96 buyAmount,
            uint96 sellAmount
        )
    {
        // Note: converting to uint discards the binary digits that do not fit
        // the type.
        userId = uint64(uint256(_orderData) >> 192);
        buyAmount = uint96(uint256(_orderData) >> 96);
        sellAmount = uint96(uint256(_orderData));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "./Vault.sol";

library ShareMath {
    using SafeMathUpgradeable for uint256;

    uint256 internal constant PLACEHOLDER_UINT = 1;

    /**
     * @notice Returns the shares amount in exhange for asset
     * @param _assetAmount amount of usdc
     * @param _assetPerShare price of vault share
     * @param _decimals is the number of _decimals the asset/shares use
     * @return shares amount in exhange of asset amount
     */
    function assetToShares(
        uint256 _assetAmount,
        uint256 _assetPerShare,
        uint256 _decimals
    ) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(
            _assetPerShare > PLACEHOLDER_UINT,
            "ShareMath: Invalid assetPerShare"
        );

        return _assetAmount.mul(10**_decimals).div(_assetPerShare);
    }

    /**
     * @notice Returns the asset amount in exchange for shares
     * @param _shares amount of vault share
     * @param _assetPerShare price of vault share
     * @param _decimals is the number of _decimals the asset/shares us
     */
    function sharesToAsset(
        uint256 _shares,
        uint256 _assetPerShare,
        uint256 _decimals
    ) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(
            _assetPerShare > PLACEHOLDER_UINT,
            "ShareMath: Invalid _assetPerShare"
        );

        return _shares.mul(_assetPerShare).div(10**_decimals);
    }

    /**
     * @notice Returns the shares unredeemed by the user given their DepositReceipt
     * @param _depositReceipt is the user's deposit receipt
     * @param _currentRound is the `round` stored on the vault
     * @param _assetPerShare is the price in asset per share
     * @param _decimals is the number of _decimals the asset/shares use
     * @return unredeemedShares is the user's virtual balance of shares that are owed
     */
    function getSharesFromReceipt(
        Vault.DepositReceipt memory _depositReceipt,
        uint256 _currentRound,
        uint256 _assetPerShare,
        uint256 _decimals
    ) internal pure returns (uint256 unredeemedShares) {
        if (
            _depositReceipt.round > 0 && _depositReceipt.round < _currentRound
        ) {
            uint256 sharesFromRound = assetToShares(
                _depositReceipt.amount,
                _assetPerShare,
                _decimals
            );

            return
                uint256(_depositReceipt.unredeemedShares).add(sharesFromRound);
        }
        return _depositReceipt.unredeemedShares;
    }

    /************************************************
     *  HELPERS
     ***********************************************/

    function assertUint104(uint256 _num) internal pure {
        require(_num <= type(uint104).max, "ShareMath: Overflow uint104");
    }

    function assertUint128(uint256 _num) internal pure {
        require(_num <= type(uint128).max, "ShareMath: Overflow uint128");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import {Vault} from "../libraries/Vault.sol";

interface IVaultsRegistry {
    //event
    event VaultsRegistered(uint256 indexed _lastIndex, address[] _vault);
    
    function index() external view returns (uint256);
    //setter
    function registerVaults(address[] calldata _vaults) external;

    //getters
    function whiteListVaults(address _vault) external view returns (bool);
    function getVaults(uint256 _index) external view returns (address);
    function getVaultParams(address _vault)
        external
        view
        returns (Vault.VaultParams memory);
    function getVaultState(address _vault)
        external
        view
        returns (Vault.VaultState memory);
    function getVTokenState(address _vault)
        external
        view
        returns (Vault.VTokenState memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "./IERC20Detailed.sol";

interface IVaultsController {

    function deposit(uint256 _amount, address _vault) external;
    function depositFor(
        uint256 _amount,
        address _creditor,
        address _receiver,
        address _vault
    ) external;
    function mint(uint256 _shares, address _vault) external;
    function getVault(uint256 _index) external view returns (address);
    function isVaultExpired(address _vault) external view returns (bool, uint256);
    function getUnExpiredVaults() external view returns (address[] memory);
    function transferAssetToVault(
        IERC20Detailed _token,
        address _account,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20Detailed is IERC20Upgradeable {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string calldata);

    function name() external view returns (string calldata);
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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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