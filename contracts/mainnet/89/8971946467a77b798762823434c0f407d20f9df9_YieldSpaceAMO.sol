/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================== YieldSpaceAMO ===========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Jack Corddry: https://github.com/corddry
// Sam Kazemian: https://github.com/samkazemian
// Dennett: https://github.com/denett
// Alberto Cuesta Cañada: https://github.com/alcueca
// Devtooligan: https://github.com/devtooligan

// https://docs.synthetix.io/contracts/Owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor (address _owner) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

interface IFrax {
  function COLLATERAL_RATIO_PAUSER() external view returns (bytes32);
  function DEFAULT_ADMIN_ADDRESS() external view returns (address);
  function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
  function addPool(address pool_address ) external;
  function allowance(address owner, address spender ) external view returns (uint256);
  function approve(address spender, uint256 amount ) external returns (bool);
  function balanceOf(address account ) external view returns (uint256);
  function burn(uint256 amount ) external;
  function burnFrom(address account, uint256 amount ) external;
  function collateral_ratio_paused() external view returns (bool);
  function controller_address() external view returns (address);
  function creator_address() external view returns (address);
  function decimals() external view returns (uint8);
  function decreaseAllowance(address spender, uint256 subtractedValue ) external returns (bool);
  function eth_usd_consumer_address() external view returns (address);
  function eth_usd_price() external view returns (uint256);
  function frax_eth_oracle_address() external view returns (address);
  function frax_info() external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);
  function frax_pools(address ) external view returns (bool);
  function frax_pools_array(uint256 ) external view returns (address);
  function frax_price() external view returns (uint256);
  function frax_step() external view returns (uint256);
  function fxs_address() external view returns (address);
  function fxs_eth_oracle_address() external view returns (address);
  function fxs_price() external view returns (uint256);
  function genesis_supply() external view returns (uint256);
  function getRoleAdmin(bytes32 role ) external view returns (bytes32);
  function getRoleMember(bytes32 role, uint256 index ) external view returns (address);
  function getRoleMemberCount(bytes32 role ) external view returns (uint256);
  function globalCollateralValue() external view returns (uint256);
  function global_collateral_ratio() external view returns (uint256);
  function grantRole(bytes32 role, address account ) external;
  function hasRole(bytes32 role, address account ) external view returns (bool);
  function increaseAllowance(address spender, uint256 addedValue ) external returns (bool);
  function last_call_time() external view returns (uint256);
  function minting_fee() external view returns (uint256);
  function name() external view returns (string memory);
  function owner_address() external view returns (address);
  function pool_burn_from(address b_address, uint256 b_amount ) external;
  function pool_mint(address m_address, uint256 m_amount ) external;
  function price_band() external view returns (uint256);
  function price_target() external view returns (uint256);
  function redemption_fee() external view returns (uint256);
  function refreshCollateralRatio() external;
  function refresh_cooldown() external view returns (uint256);
  function removePool(address pool_address ) external;
  function renounceRole(bytes32 role, address account ) external;
  function revokeRole(bytes32 role, address account ) external;
  function setController(address _controller_address ) external;
  function setETHUSDOracle(address _eth_usd_consumer_address ) external;
  function setFRAXEthOracle(address _frax_oracle_addr, address _weth_address ) external;
  function setFXSAddress(address _fxs_address ) external;
  function setFXSEthOracle(address _fxs_oracle_addr, address _weth_address ) external;
  function setFraxStep(uint256 _new_step ) external;
  function setMintingFee(uint256 min_fee ) external;
  function setOwner(address _owner_address ) external;
  function setPriceBand(uint256 _price_band ) external;
  function setPriceTarget(uint256 _new_price_target ) external;
  function setRedemptionFee(uint256 red_fee ) external;
  function setRefreshCooldown(uint256 _new_cooldown ) external;
  function setTimelock(address new_timelock ) external;
  function symbol() external view returns (string memory);
  function timelock_address() external view returns (address);
  function toggleCollateralRatio() external;
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount ) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
  function weth_address() external view returns (address);
}

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

interface IJoin {
    /// @dev asset managed by this contract
    function asset() external view returns (address);

    /// @dev Add tokens to this contract.
    function join(address user, uint128 wad) external returns (uint128);

    /// @dev Remove tokens to this contract.
    function exit(address user, uint128 wad) external returns (uint128);
}

interface IFYToken is IERC20 {
    /// @dev Asset that is returned on redemption.
    function underlying() external view returns (address);

    /// @dev Source of redemption funds.
    function join() external view returns (IJoin);

    /// @dev Unix time at which redemption of fyToken for underlying are possible
    function maturity() external view returns (uint256);

    /// @dev Record price data at maturity
    function mature() external;

    /// @dev Mint fyToken providing an equal amount of underlying to the protocol
    function mintWithUnderlying(address to, uint256 amount) external;

    /// @dev Burn fyToken after maturity for an amount of underlying.
    function redeem(address to, uint256 amount) external returns (uint256);

    /// @dev Mint fyToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param to Wallet to mint the fyToken in.
    /// @param fyTokenAmount Amount of fyToken to mint.
    function mint(address to, uint256 fyTokenAmount) external;

    /// @dev Burn fyToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param from Wallet to burn the fyToken from.
    /// @param fyTokenAmount Amount of fyToken to burn.
    function burn(address from, uint256 fyTokenAmount) external;
}

interface IOracle {
    /**
     * @notice Doesn't refresh the price, but returns the latest value available without doing any transactional operations:
     * @return value in wei
     */
    function peek(
        bytes32 base,
        bytes32 quote,
        uint256 amount
    ) external view returns (uint256 value, uint256 updateTime);

    /**
     * @notice Does whatever work or queries will yield the most up-to-date price, and returns it.
     * @return value in wei
     */
    function get(
        bytes32 base,
        bytes32 quote,
        uint256 amount
    ) external returns (uint256 value, uint256 updateTime);
}

library DataTypes {
    struct Series {
        IFYToken fyToken; // Redeemable token for the series.
        bytes6 baseId; // Asset received on redemption.
        uint32 maturity; // Unix time at which redemption becomes possible.
        // bytes2 free
    }

    struct Debt {
        uint96 max; // Maximum debt accepted for a given underlying, across all series
        uint24 min; // Minimum debt accepted for a given underlying, across all series
        uint8 dec; // Multiplying factor (10**dec) for max and min
        uint128 sum; // Current debt for a given underlying, across all series
    }

    struct SpotOracle {
        IOracle oracle; // Address for the spot price oracle
        uint32 ratio; // Collateralization ratio to multiply the price for
        // bytes8 free
    }

    struct Vault {
        address owner;
        bytes6 seriesId; // Each vault is related to only one series, which also determines the underlying.
        bytes6 ilkId; // Asset accepted as collateral
    }

    struct Balances {
        uint128 art; // Debt amount
        uint128 ink; // Collateral amount
    }
}

interface ICauldron {
    /// @dev Variable rate lending oracle for an underlying
    function lendingOracles(bytes6 baseId) external view returns (IOracle);

    /// @dev An user can own one or more Vaults, with each vault being able to borrow from a single series.
    function vaults(bytes12 vault)
        external
        view
        returns (DataTypes.Vault memory);

    /// @dev Series available in Cauldron.
    function series(bytes6 seriesId)
        external
        view
        returns (DataTypes.Series memory);

    /// @dev Assets available in Cauldron.
    function assets(bytes6 assetsId) external view returns (address);

    /// @dev Each vault records debt and collateral balances_.
    function balances(bytes12 vault)
        external
        view
        returns (DataTypes.Balances memory);

    /// @dev Max, min and sum of debt per underlying and collateral.
    function debt(bytes6 baseId, bytes6 ilkId)
        external
        view
        returns (DataTypes.Debt memory);

    // @dev Spot price oracle addresses and collateralization ratios
    function spotOracles(bytes6 baseId, bytes6 ilkId)
        external
        returns (DataTypes.SpotOracle memory);

    /// @dev Create a new vault, linked to a series (and therefore underlying) and up to 5 collateral types
    function build(
        address owner,
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 ilkId
    ) external returns (DataTypes.Vault memory);

    /// @dev Destroy an empty vault. Used to recover gas costs.
    function destroy(bytes12 vault) external;

    /// @dev Change a vault series and/or collateral types.
    function tweak(
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 ilkId
    ) external returns (DataTypes.Vault memory);

    /// @dev Give a vault to another user.
    function give(bytes12 vaultId, address receiver)
        external
        returns (DataTypes.Vault memory);

    /// @dev Move collateral and debt between vaults.
    function stir(
        bytes12 from,
        bytes12 to,
        uint128 ink,
        uint128 art
    ) external returns (DataTypes.Balances memory, DataTypes.Balances memory);

    /// @dev Manipulate a vault debt and collateral.
    function pour(
        bytes12 vaultId,
        int128 ink,
        int128 art
    ) external returns (DataTypes.Balances memory);

    /// @dev Change series and debt of a vault.
    /// The module calling this function also needs to buy underlying in the pool for the new series, and sell it in pool for the old series.
    function roll(
        bytes12 vaultId,
        bytes6 seriesId,
        int128 art
    ) external returns (DataTypes.Vault memory, DataTypes.Balances memory);

    /// @dev Reduce debt and collateral from a vault, ignoring collateralization checks.
    function slurp(
        bytes12 vaultId,
        uint128 ink,
        uint128 art
    ) external returns (DataTypes.Balances memory);

    // ==== Helpers ====

    /// @dev Convert a debt amount for a series from base to fyToken terms.
    /// @notice Think about rounding if using, since we are dividing.
    function debtFromBase(bytes6 seriesId, uint128 base)
        external
        returns (uint128 art);

    /// @dev Convert a debt amount for a series from fyToken to base terms
    function debtToBase(bytes6 seriesId, uint128 art)
        external
        returns (uint128 base);

    // ==== Accounting ====

    /// @dev Record the borrowing rate at maturity for a series
    function mature(bytes6 seriesId) external;

    /// @dev Retrieve the rate accrual since maturity, maturing if necessary.
    function accrual(bytes6 seriesId) external returns (uint256);

    /// @dev Return the collateralization level of a vault. It will be negative if undercollateralized.
    function level(bytes12 vaultId) external returns (int256);
}

interface ILadle {
    function joins(bytes6) external view returns (IJoin);

    function pools(bytes6) external returns (address);

    function cauldron() external view returns (ICauldron);

    function build(
        bytes6 seriesId,
        bytes6 ilkId,
        uint8 salt
    ) external returns (bytes12 vaultId, DataTypes.Vault memory vault);

    function destroy(bytes12 vaultId) external;

    function pour(
        bytes12 vaultId,
        address to,
        int128 ink,
        int128 art
    ) external payable;

    function serve(
        bytes12 vaultId,
        address to,
        uint128 ink,
        uint128 base,
        uint128 max
    ) external payable returns (uint128 art);

    function close(
        bytes12 vaultId,
        address to,
        int128 ink,
        int128 art
    ) external;
}

// Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
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
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
}

interface IPool is IERC20, IERC2612 {
    function ts() external view returns(int128);
    function g1() external view returns(int128);
    function g2() external view returns(int128);
    function maturity() external view returns(uint32);
    function scaleFactor() external view returns(uint96);
    function getCache() external view returns (uint112, uint112, uint32);
    function base() external view returns(IERC20);
    function fyToken() external view returns(IFYToken);
    function getBaseBalance() external view returns(uint112);
    function getFYTokenBalance() external view returns(uint112);
    function retrieveBase(address to) external returns(uint128 retrieved);
    function retrieveFYToken(address to) external returns(uint128 retrieved);
    function sellBase(address to, uint128 min) external returns(uint128);
    function buyBase(address to, uint128 baseOut, uint128 max) external returns(uint128);
    function sellFYToken(address to, uint128 min) external returns(uint128);
    function buyFYToken(address to, uint128 fyTokenOut, uint128 max) external returns(uint128);
    function sellBasePreview(uint128 baseIn) external view returns(uint128);
    function buyBasePreview(uint128 baseOut) external view returns(uint128);
    function sellFYTokenPreview(uint128 fyTokenIn) external view returns(uint128);
    function buyFYTokenPreview(uint128 fyTokenOut) external view returns(uint128);
    function mint(address to, address remainder, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256, uint256);
    function mintWithBase(address to, address remainder, uint256 fyTokenToBuy, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256, uint256);
    function burn(address baseTo, address fyTokenTo, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256, uint256);
    function burnForBase(address to, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256);
    function cumulativeBalancesRatio() external view returns (uint256);
}

// MAY need to be updated
interface IFraxAMOMinter {
  function FRAX() external view returns(address);
  function FXS() external view returns(address);
  function acceptOwnership() external;
  function addAMO(address amo_address, bool sync_too) external;
  function allAMOAddresses() external view returns(address[] memory);
  function allAMOsLength() external view returns(uint256);
  function amos(address) external view returns(bool);
  function amos_array(uint256) external view returns(address);
  function burnFraxFromAMO(uint256 frax_amount) external;
  function burnFxsFromAMO(uint256 fxs_amount) external;
  function col_idx() external view returns(uint256);
  function collatDollarBalance() external view returns(uint256);
  function collatDollarBalanceStored() external view returns(uint256);
  function collat_borrow_cap() external view returns(int256);
  function collat_borrowed_balances(address) external view returns(int256);
  function collat_borrowed_sum() external view returns(int256);
  function collateral_address() external view returns(address);
  function collateral_token() external view returns(address);
  function correction_offsets_amos(address, uint256) external view returns(int256);
  function custodian_address() external view returns(address);
  function dollarBalances() external view returns(uint256 frax_val_e18, uint256 collat_val_e18);
  // function execute(address _to, uint256 _value, bytes _data) external returns(bool, bytes);
  function fraxDollarBalanceStored() external view returns(uint256);
  function fraxTrackedAMO(address amo_address) external view returns(int256);
  function fraxTrackedGlobal() external view returns(int256);
  function frax_mint_balances(address) external view returns(int256);
  function frax_mint_cap() external view returns(int256);
  function frax_mint_sum() external view returns(int256);
  function fxs_mint_balances(address) external view returns(int256);
  function fxs_mint_cap() external view returns(int256);
  function fxs_mint_sum() external view returns(int256);
  function giveCollatToAMO(address destination_amo, uint256 collat_amount) external;
  function min_cr() external view returns(uint256);
  function mintFraxForAMO(address destination_amo, uint256 frax_amount) external;
  function mintFxsForAMO(address destination_amo, uint256 fxs_amount) external;
  function missing_decimals() external view returns(uint256);
  function nominateNewOwner(address _owner) external;
  function nominatedOwner() external view returns(address);
  function oldPoolCollectAndGive(address destination_amo) external;
  function oldPoolRedeem(uint256 frax_amount) external;
  function old_pool() external view returns(address);
  function owner() external view returns(address);
  function pool() external view returns(address);
  function receiveCollatFromAMO(uint256 usdc_amount) external;
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
  function removeAMO(address amo_address, bool sync_too) external;
  function setAMOCorrectionOffsets(address amo_address, int256 frax_e18_correction, int256 collat_e18_correction) external;
  function setCollatBorrowCap(uint256 _collat_borrow_cap) external;
  function setCustodian(address _custodian_address) external;
  function setFraxMintCap(uint256 _frax_mint_cap) external;
  function setFraxPool(address _pool_address) external;
  function setFxsMintCap(uint256 _fxs_mint_cap) external;
  function setMinimumCollateralRatio(uint256 _min_cr) external;
  function setTimelock(address new_timelock) external;
  function syncDollarBalances() external;
  function timelock_address() external view returns(address);
}

library CastU256U128 {
    /// @dev Safely cast an uint256 to an uint128
    function u128(uint256 x) internal pure returns (uint128 y) {
        require (x <= type(uint128).max, "Cast overflow");
        y = uint128(x);
    }
}

library CastU128I128 {
    /// @dev Safely cast an uint128 to an int128
    function i128(uint128 x) internal pure returns (int128 y) {
        require (x <= uint128(type(int128).max), "Cast overflow");
        y = int128(x);
    }
}

contract YieldSpaceAMO is Owned {
    using CastU256U128 for uint256;
    using CastU128I128 for uint128;

    /* =========== CONSTANTS =========== */
    bytes6 public constant FRAX_ILK_ID = 0x313800000000;

    /* =========== DATA TYPES =========== */
    struct Series {
        bytes12 vaultId; /// @notice The AMO's debt & collateral record for this series
        IFYToken fyToken;
        IPool pool;
        uint96 maturity;
    }

    /* =========== STATE VARIABLES =========== */

    // Frax
    IFrax private immutable FRAX;
    IFraxAMOMinter private amoMinter;
    address public timelockAddress;
    address public custodianAddress;

    // Yield Protocol
    ILadle public ladle;
    ICauldron public immutable cauldron;
    address public immutable fraxJoin;
    mapping(bytes6 => Series) public series;
    bytes6[] internal _seriesIterator;

    // AMO
    uint256 public currentAMOmintedFRAX; /// @notice The amount of FRAX tokens minted by the AMO
    uint256 public currentAMOmintedFyFRAX;

    /* ============= CONSTRUCTOR ============= */
    constructor(
        address _ownerAddress,
        address _amoMinterAddress,
        address _yieldLadle,
        address _yieldFraxJoin,
        address _frax
    ) Owned(_ownerAddress) {
        FRAX = IFrax(_frax);
        amoMinter = IFraxAMOMinter(_amoMinterAddress);
        timelockAddress = amoMinter.timelock_address();

        ladle = ILadle(_yieldLadle);
        cauldron = ICauldron(ladle.cauldron());
        fraxJoin = _yieldFraxJoin;

        currentAMOmintedFRAX = 0;
        currentAMOmintedFyFRAX = 0;
    }

    /* ============== MODIFIERS ============== */
    modifier onlyByOwnGov() {
        require(msg.sender == timelockAddress || msg.sender == owner, "Not owner or timelock");
        _;
    }

    modifier onlyByMinter() {
        require(msg.sender == address(amoMinter), "Not minter");
        _;
    }

    /* ================ VIEWS ================ */

    function showAllocations(bytes6 seriesId) public view returns (uint256[6] memory) {
        Series storage _series = series[seriesId];
        require(_series.vaultId != bytes12(0), "Series not found");
        uint256 supply = _series.pool.totalSupply();
        uint256 fraxInContract = FRAX.balanceOf(address(this));
        uint256 fraxAsCollateral = cauldron.balances(_series.vaultId).ink;
        uint256 fraxInLP = supply == 0
            ? 0
            : (FRAX.balanceOf(address(_series.pool)) * _series.pool.balanceOf(address(this))) /
                _series.pool.totalSupply();
        uint256 fyFraxInContract = _series.fyToken.balanceOf(address(this));
        uint256 fyFraxInLP = supply == 0
            ? 0
            : (_series.fyToken.balanceOf(address(_series.pool)) * _series.pool.balanceOf(address(this))) /
                _series.pool.totalSupply();
        uint256 LPOwned = _series.pool.balanceOf(address(this));
        return [
            fraxInContract, // [0] Unallocated Frax
            fraxAsCollateral, // [1] Frax being used as collateral to borrow fyFrax
            fraxInLP, // [2] The Frax our LP tokens can lay claim to
            fyFraxInContract, // [3] fyFrax sitting in AMO, should be 0
            fyFraxInLP, // [4] fyFrax our LP can claim
            LPOwned // [5] number of LP tokens
        ];
    }

    /// @notice Return the Frax value of a fyFrax amount, considering a debt repayment if possible.
    function fraxValue(bytes6 seriesId, uint256 fyFraxAmount) public view returns (uint256 fraxAmount) {
        Series storage _series = series[seriesId];

        // After maturity, it's 1:1
        if (block.timestamp > _series.maturity) {
            fraxAmount = fyFraxAmount;
        } else {
            uint256 debt = cauldron.balances(_series.vaultId).art;
            if (debt > fyFraxAmount) {
                // For as long as there is debt, it's 1:1
                fraxAmount = fyFraxAmount;
            } else {
                // The fyFrax over the debt, we would need to sell it.
                try _series.pool.sellFYTokenPreview((fyFraxAmount - debt).u128()) returns (uint128 fraxBought) {
                    fraxAmount = debt + fraxBought;
                } catch (bytes memory) {
                    // If for some reason the fyFrax can't be sold, we value it at zero
                    fraxAmount = debt;
                }
            }
        }
    }

    /// @notice Return the value of all AMO assets in Frax terms.
    function currentFrax() public view returns (uint256 fraxAmount) {
        // Add value from Frax in the AMO
        fraxAmount = FRAX.balanceOf(address(this));

        // Add up the amount of FRAX in LP positions
        // Add up the value in Frax from all fyFRAX LP positions
        uint256 activeSeries = _seriesIterator.length;
        for (uint256 s; s < activeSeries; ++s) {
            bytes6 seriesId = _seriesIterator[s];
            Series storage _series = series[seriesId];
            uint256 supply = _series.pool.totalSupply();
            uint256 poolShare = supply == 0 ? 0 : (1e18 * _series.pool.balanceOf(address(this))) / supply;

            // Add value from Frax in LP positions
            fraxAmount += (FRAX.balanceOf(address(_series.pool)) * poolShare) / 1e18;

            // Add value from fyFrax in the AMO and LP positions
            uint256 fyFraxAmount = _series.fyToken.balanceOf(address(this));
            fyFraxAmount += (_series.fyToken.balanceOf(address(_series.pool)) * poolShare) / 1e18;
            fraxAmount += fraxValue(seriesId, fyFraxAmount);
        }
    }

    /// @notice returns the collateral balance of the AMO for calculating FRAX’s global collateral ratio
    function dollarBalances() public view returns (uint256 valueAsFrax, uint256 valueAsCollateral) {
        valueAsFrax = currentFrax();
        valueAsCollateral = (valueAsFrax * FRAX.global_collateral_ratio()) / 1e6; // This assumes that FRAX.global_collateral_ratio() has 6 decimals
    }

    /// @notice returns entire _seriesIterator array.
    /// @dev Solcurity Standard https://github.com/Rari-Capital/solcurity:
    /// V9 - If it's a public array, is a separate function provided to return the full array
    /// Also useful for testing.
    function seriesIterator() external view returns (bytes6[] memory seriesIterator_) {
        seriesIterator_ = _seriesIterator;
    }

    /* ========= RESTRICTED FUNCTIONS ======== */
    /// @notice register a new series in the AMO
    /// @param seriesId the series being added
    function addSeries(
        bytes6 seriesId,
        IFYToken fyToken,
        IPool pool
    ) public onlyByOwnGov {
        require(ladle.pools(seriesId) == address(pool), "Mismatched pool");
        require(cauldron.series(seriesId).fyToken == fyToken, "Mismatched fyToken");

        (bytes12 vaultId, ) = ladle.build(seriesId, FRAX_ILK_ID, 0);
        series[seriesId] = Series({
            vaultId: vaultId,
            fyToken: fyToken,
            pool: pool,
            maturity: uint96(fyToken.maturity()) // Will work for a while.
        });

        _seriesIterator.push(seriesId);

        emit SeriesAdded(seriesId);
    }

    /// @notice remove a new series in the AMO, to keep gas costs in place
    /// @param seriesId the series being removed
    /// @param seriesIndex the index in the _seriesIterator for the series being removed
    function removeSeries(bytes6 seriesId, uint256 seriesIndex) public onlyByOwnGov {
        Series memory _series = series[seriesId];
        require(_series.vaultId != bytes12(0), "Series not found");
        require(seriesId == _seriesIterator[seriesIndex], "Index mismatch");
        require(_series.fyToken.balanceOf(address(this)) == 0, "Outstanding fyToken balance");
        require(_series.pool.balanceOf(address(this)) == 0, "Outstanding pool balance");

        delete series[seriesId];

        // Remove the seriesId from the iterator, by replacing for the tail and popping.
        uint256 activeSeries = _seriesIterator.length;
        if (seriesIndex < activeSeries - 1) {
            _seriesIterator[seriesIndex] = _seriesIterator[activeSeries - 1];
        }
        _seriesIterator.pop();

        emit SeriesRemoved(seriesId);
    }

    /// @notice mint fyFrax using FRAX as collateral 1:1 Frax to fyFrax
    /// @dev The Frax to work with needs to be in the AMO already.
    /// @param seriesId fyFrax series being minted
    /// @param fraxAmount amount of Frax being used to mint fyFrax at 1:1
    function mintFyFrax(bytes6 seriesId, uint128 fraxAmount) public onlyByOwnGov returns (uint128 fyFraxMinted) {
        Series memory _series = series[seriesId];
        require(_series.vaultId != bytes12(0), "Series not found");
        fyFraxMinted = _mintFyFrax(_series, address(this), fraxAmount);
    }

    /// @notice mint fyFrax using FRAX as collateral 1:1 Frax to fyFrax
    /// @dev The Frax to work with needs to be in the AMO already.
    /// If there is any fyFrax in the AMO for the right series, it's used first.
    /// @param _series fyFrax series being minted
    /// @param to destination for the fyFrax
    /// @param fraxAmount amount of Frax being used to mint fyFrax at 1:1
    function _mintFyFrax(
        Series memory _series,
        address to,
        uint128 fraxAmount
    ) internal returns (uint128 fyFraxMinted) {
        uint128 fyFraxAvailable = _series.fyToken.balanceOf(address(this)).u128();

        if (fyFraxAvailable > fraxAmount) {
            // If we don't need to mint, then we don't do it.
            _series.fyToken.transfer(to, fraxAmount);
        } else if (fyFraxAvailable > 0) {
            // We have some fyFrax, but we need to mint more.
            fyFraxMinted = fraxAmount - fyFraxAvailable;
            _series.fyToken.transfer(to, fyFraxAvailable);
        } else {
            // We need to mint the whole lot
            fyFraxMinted = fraxAmount;
        }

        if (fyFraxMinted > 0) {
            int128 fyFraxMinted_ = fyFraxMinted.i128();
            //Transfer FRAX to the FRAX Join, add it as collateral, and borrow.
            FRAX.transfer(fraxJoin, fyFraxMinted);
            ladle.pour(_series.vaultId, to, fyFraxMinted_, fyFraxMinted_);
        }
    }

    /// @notice recover Frax from an amount of fyFrax, repaying or redeeming.
    /// Before maturity, if there isn't enough debt to convert all the fyFrax into Frax, the surplus
    /// will be stored in the AMO. Calling this function after maturity will redeem the surplus.
    /// @dev The fyFrax to work with needs to be in the AMO already.
    /// @param seriesId fyFrax series being burned
    /// @param fyFraxAmount amount of fyFrax being burned
    /// @return fraxAmount amount of Frax recovered
    /// @return fyFraxStored amount of fyFrax stored in the AMO
    function burnFyFrax(bytes6 seriesId, uint128 fyFraxAmount)
        public
        onlyByOwnGov
        returns (uint256 fraxAmount, uint128 fyFraxStored)
    {
        Series memory _series = series[seriesId];
        require(_series.vaultId != bytes12(0), "Series not found");

        (fraxAmount, fyFraxStored) = _burnFyFrax(_series, address(this), fyFraxAmount);
    }

    /// @notice recover Frax from an amount of fyFrax, repaying or redeeming.
    /// Before maturity, if there isn't enough debt to convert all the fyFrax into Frax, the surplus
    /// will be stored in the AMO. Calling this function after maturity will redeem the surplus.
    /// @dev The fyFrax to work with needs to be in the AMO already.
    /// @param _series fyFrax series being burned
    /// @param to destination for the frax recovered
    /// @param fyFraxAmount amount of fyFrax being burned
    /// @return fraxAmount amount of Frax recovered
    /// @return fyFraxStored amount of fyFrax stored in the AMO
    function _burnFyFrax(
        Series memory _series,
        address to,
        uint128 fyFraxAmount
    ) internal returns (uint256 fraxAmount, uint128 fyFraxStored) {
        if (_series.maturity < block.timestamp) {
            // At maturity, forget about debt and redeem at 1:1
            _series.fyToken.transfer(address(_series.fyToken), fyFraxAmount);
            fraxAmount = _series.fyToken.redeem(to, fyFraxAmount);
        } else {
            // Before maturity, repay as much debt as possible, and keep any surplus fyFrax
            uint256 debt = cauldron.balances(_series.vaultId).art;
            (fraxAmount, fyFraxStored) = debt > fyFraxAmount ? (fyFraxAmount, 0) : (debt, (fyFraxAmount - debt).u128());
            // When repaying with fyFrax, we don't need to approve anything
            ladle.pour(_series.vaultId, to, -(fraxAmount.u128().i128()), -(fraxAmount.u128().i128()));
        }
    }

    /// @notice mint new fyFrax to sell into the AMM to push up rates
    /// @dev The Frax to work with needs to be in the AMO already.
    /// @param seriesId fyFrax series we are increasing the rates for
    /// @param fraxAmount amount of Frax being converted to fyFrax and sold
    /// @param minFraxReceived minimum amount of Frax to receive in the sale
    /// @return fraxReceived amount of Frax received in the sale
    function increaseRates(
        bytes6 seriesId,
        uint128 fraxAmount,
        uint128 minFraxReceived
    ) public onlyByOwnGov returns (uint256 fraxReceived) {
        Series storage _series = series[seriesId];
        require(_series.vaultId != bytes12(0), "Series not found");

        // Mint fyFRAX into the pool, and sell it.
        _mintFyFrax(_series, address(_series.pool), fraxAmount);
        fraxReceived = _series.pool.sellFYToken(address(this), minFraxReceived);
        emit RatesIncreased(fraxAmount, fraxReceived);
    }

    /// @notice buy fyFrax from the AMO and burn it to push down rates
    /// @dev The Frax to work with needs to be in the AMO already.
    /// @param seriesId fyFrax series we are decreasing the rates for
    /// @param fraxAmount amount of Frax being sold for fyFrax
    /// @param minFyFraxReceived minimum amount of fyFrax in the sale
    /// @return fraxReceived amount of Frax received after selling and burning
    /// @return fyFraxStored amount of fyFrax stored in the AMO, if any
    function decreaseRates(
        bytes6 seriesId,
        uint128 fraxAmount,
        uint128 minFyFraxReceived
    ) public onlyByOwnGov returns (uint256 fraxReceived, uint256 fyFraxStored) {
        Series memory _series = series[seriesId];
        require(_series.vaultId != bytes12(0), "Series not found");

        //Transfer FRAX into the pool, sell it for fyFRAX into the fyFRAX contract, repay debt and withdraw FRAX collateral.
        FRAX.transfer(address(_series.pool), fraxAmount);

        uint256 fyFraxReceived = _series.pool.sellBase(address(this), minFyFraxReceived);
        (fraxReceived, fyFraxStored) = _burnFyFrax(_series, address(this), fyFraxReceived.u128());

        emit RatesDecreased(fraxAmount, fraxReceived);
    }

    /// @notice mint fyFrax tokens, pair with FRAX and provide liquidity
    /// @dev The Frax to work with needs to be in the AMO already for both fraxAmount and fyFraxAmount
    /// @param seriesId fyFrax series we are adding liquidity for
    /// @param fraxAmount Frax being provided as liquidity
    /// @param fyFraxAmount amount of fyFrax being provided as liquidity - this amount of frax also needs to be in AMO already
    /// @param minRatio minimum Frax/fyFrax ratio accepted in the pool
    /// @param maxRatio maximum Frax/fyFrax ratio accepted in the pool
    /// @return fraxUsed amount of Frax used for minting, it could be less than `fraxAmount`
    /// @return poolMinted amount of pool tokens minted
    function addLiquidityToAMM(
        bytes6 seriesId,
        uint128 fraxAmount,
        uint128 fyFraxAmount,
        uint256 minRatio,
        uint256 maxRatio
    ) public onlyByOwnGov returns (uint256 fraxUsed, uint256 poolMinted) {
        Series storage _series = series[seriesId];
        require(_series.vaultId != bytes12(0), "Series not found");
        //Transfer FRAX into the pool. Transfer FRAX into the FRAX Join. Borrow fyFRAX into the pool. Add liquidity.
        _mintFyFrax(_series, address(_series.pool), fyFraxAmount);
        FRAX.transfer(address(_series.pool), fraxAmount);
        (fraxUsed, , poolMinted) = _series.pool.mint(address(this), address(this), minRatio, maxRatio); //Second param receives remainder
        emit LiquidityAdded(fraxUsed, poolMinted);
    }

    /// @notice remove liquidity and burn fyTokens
    /// @dev The pool tokens to work with need to be in the AMO already.
    /// @param seriesId fyFrax series we are adding liquidity for
    /// @param poolAmount amount of pool tokens being removed as liquidity
    /// @param minRatio minimum Frax/fyFrax ratio accepted in the pool
    /// @param maxRatio maximum Frax/fyFrax ratio accepted in the pool
    /// @return fraxReceived amount of Frax received after removing liquidity and burning
    /// @return fyFraxStored amount of fyFrax stored in the AMO, if any
    function removeLiquidityFromAMM(
        bytes6 seriesId,
        uint256 poolAmount,
        uint256 minRatio,
        uint256 maxRatio
    ) public onlyByOwnGov returns (uint256 fraxReceived, uint256 fyFraxStored) {
        Series storage _series = series[seriesId];
        require(_series.vaultId != bytes12(0), "Series not found");
        //Transfer pool tokens into the pool. Burn pool tokens, with the fyFRAX coming into this contract and then burned.
        //Instruct the Ladle to repay as much debt as fyFRAX from the burn, and withdraw the same amount of collateral.
        _series.pool.transfer(address(_series.pool), poolAmount);
        (, , uint256 fyFraxAmount) = _series.pool.burn(address(this), address(this), minRatio, maxRatio);
        (fraxReceived, fyFraxStored) = _burnFyFrax(_series, address(this), fyFraxAmount.u128());
        emit LiquidityRemoved(fraxReceived, poolAmount);
    }

    /* === RESTRICTED GOVERNANCE FUNCTIONS === */
    function setAMOMinter(IFraxAMOMinter _amoMinter) external onlyByOwnGov {
        amoMinter = _amoMinter;

        // Get the timelock addresses from the minter
        timelockAddress = _amoMinter.timelock_address();

        // Make sure the new addresses are not address(0)
        require(timelockAddress != address(0), "Invalid timelock");
        emit AMOMinterSet(address(_amoMinter));
    }

    /// @notice Replace the Ladle
    function setLadle(ILadle _ladle) external onlyByOwnGov {
        ladle = _ladle;

        emit LadleSet(address(_ladle));
    }

    /// @notice generic proxy
    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external onlyByOwnGov returns (bool, bytes memory) {
        (bool success, bytes memory result) = to.call{value: value}(data);
        return (success, result);
    }

    /* ================ EVENTS =============== */
    event LiquidityAdded(uint256 fraxUsed, uint256 poolMinted);
    event LiquidityRemoved(uint256 fraxReceived, uint256 poolBurned);
    event RatesIncreased(uint256 fraxUsed, uint256 fraxReceived);
    event RatesDecreased(uint256 fraxUsed, uint256 fraxReceived);
    event AMOMinterSet(address amoMinterAddress);
    event LadleSet(address ladleAddress);
    event SeriesAdded(bytes6 seriesId);
    event SeriesRemoved(bytes6 seriesId);
}