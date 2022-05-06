// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "@bancor/token-governance/contracts/ITokenGovernance.sol";

import "../utility/interfaces/ICheckpointStore.sol";
import "../utility/MathEx.sol";
import "../utility/Types.sol";
import "../utility/Time.sol";
import "../utility/Utils.sol";
import "../utility/Owned.sol";

import "../token/interfaces/IDSToken.sol";
import "../token/ReserveToken.sol";

import "../converter/interfaces/IConverterAnchor.sol";
import "../converter/interfaces/IConverter.sol";
import "../converter/interfaces/IConverterRegistry.sol";

import "./interfaces/ILiquidityProtection.sol";

interface ILiquidityPoolConverter is IConverter {
    function addLiquidity(
        IReserveToken[] memory reserveTokens,
        uint256[] memory reserveAmounts,
        uint256 minReturn
    ) external payable;

    function removeLiquidity(
        uint256 amount,
        IReserveToken[] memory reserveTokens,
        uint256[] memory reserveMinReturnAmounts
    ) external returns (uint256[] memory);

    function recentAverageRate(IReserveToken reserveToken) external view returns (uint256, uint256);
}

interface IBancorNetworkV3 {
    function migrateLiquidity(
        IReserveToken reserveToken,
        address provider,
        uint256 amount,
        uint256 availableAmount,
        uint256 originalAmount
    ) external payable;
}

/**
 * @dev This contract implements the liquidity protection mechanism.
 */
contract LiquidityProtection is ILiquidityProtection, Utils, Owned, ReentrancyGuard, Time {
    using Math for uint256;
    using SafeMath for uint256;
    using ReserveToken for IReserveToken;
    using SafeERC20 for IERC20;
    using SafeERC20 for IDSToken;
    using SafeERC20Ex for IERC20;
    using Address for address payable;

    struct Position {
        address provider; // liquidity provider
        IDSToken poolToken; // pool token address
        IReserveToken reserveToken; // reserve token address
        uint256 poolAmount; // pool token amount
        uint256 reserveAmount; // reserve token amount
        uint256 reserveRateN; // rate of 1 protected reserve token in units of the other reserve token (numerator)
        uint256 reserveRateD; // rate of 1 protected reserve token in units of the other reserve token (denominator)
        uint256 timestamp; // timestamp
    }

    // various rates between the two reserve tokens. the rate is of 1 unit of the protected reserve token in units of the other reserve token
    struct PackedRates {
        uint128 addSpotRateN; // spot rate of 1 A in units of B when liquidity was added (numerator)
        uint128 addSpotRateD; // spot rate of 1 A in units of B when liquidity was added (denominator)
        uint128 removeSpotRateN; // spot rate of 1 A in units of B when liquidity is removed (numerator)
        uint128 removeSpotRateD; // spot rate of 1 A in units of B when liquidity is removed (denominator)
        uint128 removeAverageRateN; // average rate of 1 A in units of B when liquidity is removed (numerator)
        uint128 removeAverageRateD; // average rate of 1 A in units of B when liquidity is removed (denominator)
    }

    struct PositionList {
        IDSToken poolToken; // pool token address
        IReserveToken reserveToken; // reserve token address
        uint256[] positionIds; // position ids
    }

    uint256 internal constant MAX_UINT128 = 2**128 - 1;
    uint256 internal constant MAX_UINT256 = uint256(-1);

    IBancorNetworkV3 private immutable _networkV3;
    address payable private immutable _vaultV3;
    ILiquidityProtectionSettings private immutable _settings;
    ILiquidityProtectionStore private immutable _store;
    ILiquidityProtectionStats private immutable _stats;
    ILiquidityProtectionSystemStore private immutable _systemStore;
    ITokenHolder private immutable _wallet;
    IERC20 private immutable _networkToken;
    ITokenGovernance private immutable _networkTokenGovernance;
    IERC20 private immutable _govToken;
    ITokenGovernance private immutable _govTokenGovernance;
    ICheckpointStore private immutable _lastRemoveCheckpointStore;

    /**
     * @dev initializes a new LiquidityProtection contract
     */
    constructor(
        IBancorNetworkV3 networkV3,
        address payable vaultV3,
        ILiquidityProtectionSettings settings,
        ILiquidityProtectionStore store,
        ILiquidityProtectionStats stats,
        ILiquidityProtectionSystemStore systemStore,
        ITokenHolder wallet,
        ITokenGovernance networkTokenGovernance,
        ITokenGovernance govTokenGovernance,
        ICheckpointStore lastRemoveCheckpointStore
    ) public {
        _validAddress(address(networkV3));
        _validAddress(address(vaultV3));
        _validAddress(address(settings));
        _validAddress(address(store));
        _validAddress(address(stats));
        _validAddress(address(systemStore));
        _validAddress(address(wallet));
        _validAddress(address(lastRemoveCheckpointStore));

        _networkV3 = networkV3;
        _vaultV3 = vaultV3;
        _settings = settings;
        _store = store;
        _stats = stats;
        _systemStore = systemStore;
        _wallet = wallet;
        _networkTokenGovernance = networkTokenGovernance;
        _govTokenGovernance = govTokenGovernance;
        _lastRemoveCheckpointStore = lastRemoveCheckpointStore;

        _networkToken = networkTokenGovernance.token();
        _govToken = govTokenGovernance.token();
    }

    // ensures that the pool is supported and whitelisted
    modifier poolSupportedAndWhitelisted(IConverterAnchor poolAnchor) {
        _poolSupported(poolAnchor);
        _poolWhitelisted(poolAnchor);

        _;
    }

    // ensures that add liquidity is enabled
    modifier addLiquidityEnabled(IConverterAnchor poolAnchor, IReserveToken reserveToken) {
        _addLiquidityEnabled(poolAnchor, reserveToken);

        _;
    }

    // error message binary size optimization
    function _poolSupported(IConverterAnchor poolAnchor) internal view {
        require(_settings.isPoolSupported(poolAnchor), "ERR_POOL_NOT_SUPPORTED");
    }

    // error message binary size optimization
    function _poolWhitelisted(IConverterAnchor poolAnchor) internal view {
        require(_settings.isPoolWhitelisted(poolAnchor), "ERR_POOL_NOT_WHITELISTED");
    }

    // error message binary size optimization
    function _addLiquidityEnabled(IConverterAnchor poolAnchor, IReserveToken reserveToken) internal view {
        require(!_settings.addLiquidityDisabled(poolAnchor, reserveToken), "ERR_ADD_LIQUIDITY_DISABLED");
    }

    // error message binary size optimization
    function _verifyEthAmount(uint256 value) internal view {
        require(msg.value == value, "ERR_ETH_AMOUNT_MISMATCH");
    }

    /**
     * @dev returns the LP store
     */
    function store() external view override returns (ILiquidityProtectionStore) {
        return _store;
    }

    /**
     * @dev returns the LP stats
     */
    function stats() external view override returns (ILiquidityProtectionStats) {
        return _stats;
    }

    /**
     * @dev returns the LP settings
     */
    function settings() external view override returns (ILiquidityProtectionSettings) {
        return _settings;
    }

    /**
     * @dev accept ETH
     */
    receive() external payable {}

    /**
     * @dev transfers the ownership of the store
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract
     */
    function transferStoreOwnership(address newOwner) external ownerOnly {
        _store.transferOwnership(newOwner);
    }

    /**
     * @dev accepts the ownership of the store
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract
     */
    function acceptStoreOwnership() external ownerOnly {
        _store.acceptOwnership();
    }

    /**
     * @dev transfers the ownership of the wallet
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract
     */
    function transferWalletOwnership(address newOwner) external ownerOnly {
        _wallet.transferOwnership(newOwner);
    }

    /**
     * @dev accepts the ownership of the wallet
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract
     */
    function acceptWalletOwnership() external ownerOnly {
        _wallet.acceptOwnership();
    }

    /**
     * @dev adds protected liquidity to a pool for a specific recipient, mints new governance tokens for the caller
     * if the caller adds network tokens, and returns the new position id
     */
    function addLiquidityFor(
        address owner,
        IConverterAnchor poolAnchor,
        IReserveToken reserveToken,
        uint256 amount
    )
        external
        payable
        override
        nonReentrant
        validAddress(owner)
        poolSupportedAndWhitelisted(poolAnchor)
        addLiquidityEnabled(poolAnchor, reserveToken)
        greaterThanZero(amount)
        returns (uint256)
    {
        return _addLiquidity(owner, poolAnchor, reserveToken, amount);
    }

    /**
     * @dev adds protected liquidity to a pool, mints new governance tokens for the caller if the caller adds network
     * tokens, and returns the new position id
     */
    function addLiquidity(
        IConverterAnchor poolAnchor,
        IReserveToken reserveToken,
        uint256 amount
    )
        external
        payable
        override
        nonReentrant
        poolSupportedAndWhitelisted(poolAnchor)
        addLiquidityEnabled(poolAnchor, reserveToken)
        greaterThanZero(amount)
        returns (uint256)
    {
        return _addLiquidity(msg.sender, poolAnchor, reserveToken, amount);
    }

    /**
     * @dev adds protected liquidity to a pool for a specific recipient, mints new governance tokens for the caller if
     * the caller adds network tokens, and returns the new position id
     */
    function _addLiquidity(
        address owner,
        IConverterAnchor poolAnchor,
        IReserveToken reserveToken,
        uint256 amount
    ) private returns (uint256) {
        if (_isNetworkToken(reserveToken)) {
            _verifyEthAmount(0);

            return _addNetworkTokenLiquidity(owner, poolAnchor, amount);
        }

        // verify that ETH was passed with the call if needed
        _verifyEthAmount(reserveToken.isNativeToken() ? amount : 0);

        return _addBaseTokenLiquidity(owner, poolAnchor, reserveToken, amount);
    }

    /**
     * @dev adds network token liquidity to a pool, mints new governance tokens for the caller, and returns the new ]
     * position id
     */
    function _addNetworkTokenLiquidity(
        address owner,
        IConverterAnchor poolAnchor,
        uint256 amount
    ) internal returns (uint256) {
        IDSToken poolToken = IDSToken(address(poolAnchor));
        IReserveToken networkToken = IReserveToken(address(_networkToken));

        // get the rate between the pool token and the reserve
        Fraction memory poolRate = _poolTokenRate(poolToken, networkToken);

        // calculate the amount of pool tokens based on the amount of reserve tokens
        uint256 poolTokenAmount = _mulDivF(amount, poolRate.d, poolRate.n);

        // remove the pool tokens from the system's ownership (will revert if not enough tokens are available)
        _systemStore.decSystemBalance(poolToken, poolTokenAmount);

        // add the position for the recipient
        uint256 id = _addPosition(owner, poolToken, networkToken, poolTokenAmount, amount, _time());

        // burns the network tokens from the caller. we need to transfer the tokens to the contract itself, since only
        // token holders can burn their tokens
        _networkToken.safeTransferFrom(msg.sender, address(this), amount);
        _burnNetworkTokens(poolAnchor, amount);

        // mint governance tokens to the recipient
        _govTokenGovernance.mint(owner, amount);

        return id;
    }

    /**
     * @dev adds base token liquidity to a pool
     */
    function _addBaseTokenLiquidity(
        address owner,
        IConverterAnchor poolAnchor,
        IReserveToken baseToken,
        uint256 amount
    ) internal returns (uint256) {
        IDSToken poolToken = IDSToken(address(poolAnchor));
        IReserveToken networkToken = IReserveToken(address(_networkToken));

        // get the reserve balances
        ILiquidityPoolConverter converter = ILiquidityPoolConverter(payable(_ownedBy(poolAnchor)));
        (uint256 reserveBalanceBase, uint256 reserveBalanceNetwork) = _converterReserveBalances(
            converter,
            baseToken,
            networkToken
        );

        require(reserveBalanceNetwork >= _settings.minNetworkTokenLiquidityForMinting(), "ERR_NOT_ENOUGH_LIQUIDITY");

        // calculate and mint the required amount of network tokens for adding liquidity
        uint256 newNetworkLiquidityAmount = _mulDivF(amount, reserveBalanceNetwork, reserveBalanceBase);

        // get network token minting limit
        uint256 mintingLimit = _networkTokenMintingLimit(poolAnchor);

        uint256 newNetworkTokensMinted = _systemStore.networkTokensMinted(poolAnchor).add(newNetworkLiquidityAmount);
        require(newNetworkTokensMinted <= mintingLimit, "ERR_MAX_AMOUNT_REACHED");

        // issue new network tokens to the system
        _mintNetworkTokens(address(this), poolAnchor, newNetworkLiquidityAmount);

        // transfer the base tokens from the caller and approve the converter
        networkToken.ensureApprove(address(converter), newNetworkLiquidityAmount);

        if (!baseToken.isNativeToken()) {
            baseToken.safeTransferFrom(msg.sender, address(this), amount);
            baseToken.ensureApprove(address(converter), amount);
        }

        // add the liquidity to the converter
        _addLiquidity(converter, baseToken, networkToken, amount, newNetworkLiquidityAmount, msg.value);

        // transfer the new pool tokens to the wallet
        uint256 poolTokenAmount = poolToken.balanceOf(address(this));
        poolToken.safeTransfer(address(_wallet), poolTokenAmount);

        // the system splits the pool tokens with the caller
        // increase the system's pool token balance and add the position for the caller
        _systemStore.incSystemBalance(poolToken, poolTokenAmount - poolTokenAmount / 2); // account for rounding errors

        return _addPosition(owner, poolToken, baseToken, poolTokenAmount / 2, amount, _time());
    }

    /**
     * @dev returns the single-side staking base and network token limits of a given pool
     */
    function poolAvailableSpace(IConverterAnchor poolAnchor)
        external
        view
        poolSupportedAndWhitelisted(poolAnchor)
        returns (uint256, uint256)
    {
        return (_baseTokenAvailableSpace(poolAnchor), _networkTokenAvailableSpace(poolAnchor));
    }

    /**
     * @dev returns the base token staking limits of a given pool
     */
    function _baseTokenAvailableSpace(IConverterAnchor poolAnchor) internal view returns (uint256) {
        // get the pool converter
        ILiquidityPoolConverter converter = ILiquidityPoolConverter(payable(_ownedBy(poolAnchor)));

        // get the base token
        IReserveToken networkToken = IReserveToken(address(_networkToken));
        IReserveToken baseToken = _converterOtherReserve(converter, networkToken);

        // get the reserve balances
        (uint256 reserveBalanceBase, uint256 reserveBalanceNetwork) = _converterReserveBalances(
            converter,
            baseToken,
            networkToken
        );

        // get the network token minting limit
        uint256 mintingLimit = _networkTokenMintingLimit(poolAnchor);

        // get the amount of network tokens already minted for the pool
        uint256 networkTokensMinted = _systemStore.networkTokensMinted(poolAnchor);

        // get the amount of network tokens which can minted for the pool
        uint256 networkTokensCanBeMinted = Math.max(mintingLimit, networkTokensMinted) - networkTokensMinted;

        // return the maximum amount of base token liquidity that can be single-sided staked in the pool
        return _mulDivF(networkTokensCanBeMinted, reserveBalanceBase, reserveBalanceNetwork);
    }

    /**
     * @dev returns the network token staking limits of a given pool
     */
    function _networkTokenAvailableSpace(IConverterAnchor poolAnchor) internal view returns (uint256) {
        // get the pool token
        IDSToken poolToken = IDSToken(address(poolAnchor));
        IReserveToken networkToken = IReserveToken(address(_networkToken));

        // get the pool token rate
        Fraction memory poolRate = _poolTokenRate(poolToken, networkToken);

        // return the maximum amount of network token liquidity that can be single-sided staked in the pool
        return _systemStore.systemBalance(poolToken).mul(poolRate.n).add(poolRate.n).sub(1).div(poolRate.d);
    }

    /**
     * @dev returns the expected, actual, and network token compensation amounts the provider will receive for removing
     * liquidity
     *
     * note that it's also possible to provide the remove liquidity time to get an estimation for the return at that
     * given point
     */
    function removeLiquidityReturn(
        uint256 id,
        uint32 portion,
        uint256 removeTimestamp
    )
        external
        view
        validPortion(portion)
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        Position memory pos = _position(id);

        require(pos.provider != address(0), "ERR_INVALID_ID");
        require(removeTimestamp >= pos.timestamp, "ERR_INVALID_TIMESTAMP");

        // calculate the portion of the liquidity to remove
        if (portion != PPM_RESOLUTION) {
            (pos.poolAmount, pos.reserveAmount) = _portionAmounts(pos.poolAmount, pos.reserveAmount, portion);
        }

        // get the various rates between the reserves upon adding liquidity and now
        PackedRates memory packedRates = _packRates(
            pos.poolToken,
            pos.reserveToken,
            pos.reserveRateN,
            pos.reserveRateD
        );

        uint256 targetAmount = _removeLiquidityTargetAmount(
            pos.poolToken,
            pos.reserveToken,
            pos.poolAmount,
            pos.reserveAmount,
            packedRates,
            pos.timestamp,
            removeTimestamp
        );

        // for network token, the return amount is identical to the target amount
        if (_isNetworkToken(pos.reserveToken)) {
            return (targetAmount, targetAmount, 0);
        }

        // handle base token return

        // calculate the amount of pool tokens required for liquidation
        // note that the amount is doubled since it's not possible to liquidate one reserve only
        Fraction memory poolRate = _poolTokenRate(pos.poolToken, pos.reserveToken);
        uint256 poolAmount = _liquidationAmount(targetAmount, poolRate, pos.poolToken, pos.poolAmount);

        // calculate the base token amount received by liquidating the pool tokens
        // note that the amount is divided by 2 since the pool amount represents both reserves
        uint256 baseAmount = _mulDivF(poolAmount, poolRate.n, poolRate.d.mul(2));
        uint256 networkAmount = _networkCompensation(targetAmount, baseAmount, packedRates);

        return (targetAmount, baseAmount, networkAmount);
    }

    /**
     * @dev removes protected liquidity from a pool and also burns governance tokens from the caller if the caller
     * removes network tokens
     */
    function removeLiquidity(uint256 id, uint32 portion) external override nonReentrant validPortion(portion) {
        _removeLiquidity(msg.sender, id, portion);
    }

    /**
     * @dev removes a position from a pool and burns governance tokens from the caller if the caller removes network tokens
     */
    function _removeLiquidity(
        address payable provider,
        uint256 id,
        uint32 portion
    ) internal {
        // remove the position from the store and update the stats and the last removal checkpoint
        Position memory removedPos = _removePosition(provider, id, portion, false);

        // add the pool tokens to the system
        _systemStore.incSystemBalance(removedPos.poolToken, removedPos.poolAmount);

        // if removing network token liquidity, burn the governance tokens from the caller. we need to transfer the
        // tokens to the contract itself, since only token holders can burn their tokens
        if (_isNetworkToken(removedPos.reserveToken)) {
            _govToken.safeTransferFrom(provider, address(this), removedPos.reserveAmount);
            _govTokenGovernance.burn(removedPos.reserveAmount);
        }

        // get the various rates between the reserves upon adding liquidity and now
        PackedRates memory packedRates = _packRates(
            removedPos.poolToken,
            removedPos.reserveToken,
            removedPos.reserveRateN,
            removedPos.reserveRateD
        );

        // verify rate deviation as early as possible in order to reduce gas-cost for failing transactions
        _verifyRateDeviation(
            packedRates.removeSpotRateN,
            packedRates.removeSpotRateD,
            packedRates.removeAverageRateN,
            packedRates.removeAverageRateD
        );

        // get the target token amount
        uint256 targetAmount = _removeLiquidityTargetAmount(
            removedPos.poolToken,
            removedPos.reserveToken,
            removedPos.poolAmount,
            removedPos.reserveAmount,
            packedRates,
            removedPos.timestamp,
            _time()
        );

        // remove network token liquidity
        if (_isNetworkToken(removedPos.reserveToken)) {
            // mint network tokens for the caller and lock them
            _mintNetworkTokens(address(_wallet), removedPos.poolToken, targetAmount);
            _lockTokens(provider, targetAmount);
            return;
        }

        // remove base token liquidity

        // calculate the amount of pool tokens required for liquidation
        // note that the amount is doubled since it's not possible to liquidate one reserve only
        Fraction memory poolRate = _poolTokenRate(removedPos.poolToken, removedPos.reserveToken);
        uint256 poolAmount = _liquidationAmount(targetAmount, poolRate, removedPos.poolToken, 0);

        // withdraw the pool tokens from the wallet
        _withdrawPoolTokens(removedPos.poolToken, poolAmount);

        // remove liquidity
        _removeLiquidity(
            removedPos.poolToken,
            poolAmount,
            removedPos.reserveToken,
            IReserveToken(address(_networkToken))
        );

        // transfer the base tokens to the caller
        uint256 baseBalance = removedPos.reserveToken.balanceOf(address(this));
        removedPos.reserveToken.safeTransfer(provider, baseBalance);

        // compensate the caller with network tokens if still needed
        uint256 delta = _networkCompensation(targetAmount, baseBalance, packedRates);
        if (delta > 0) {
            // check if there's enough network token balance, otherwise mint more
            uint256 networkBalance = _networkToken.balanceOf(address(this));
            if (networkBalance < delta) {
                _networkTokenGovernance.mint(address(this), delta - networkBalance);
            }

            // lock network tokens for the caller
            _networkToken.safeTransfer(address(_wallet), delta);
            _lockTokens(provider, delta);
        }

        // if the contract still holds network tokens, burn them
        uint256 networkBalance = _networkToken.balanceOf(address(this));
        if (networkBalance > 0) {
            _burnNetworkTokens(removedPos.poolToken, networkBalance);
        }
    }

    /**
     * @dev migrates a set of position lists to v3
     *
     * Requirements:
     *
     * - the caller must be the owner of all of the positions
     */
    function migratePositions(PositionList[] calldata positionLists) external nonReentrant {
        uint256 length = positionLists.length;
        for (uint256 i = 0; i < length; ++i) {
            _migratePositions(positionLists[i]);
        }
    }

    /**
     * @dev migrates a list of positions to v3
     *
     * Requirements:
     *
     * - the caller must be the owner of all of the positions
     */
    function _migratePositions(PositionList calldata positionList) internal {
        IDSToken poolToken = positionList.poolToken;
        IReserveToken reserveToken = positionList.reserveToken;

        Fraction memory poolRate = _poolTokenRate(poolToken, reserveToken);

        (Fraction memory removeSpotRate, Fraction memory removeAverageRate) = _reserveTokenRates(
            poolToken,
            reserveToken
        );

        // verify rate deviation as early as possible in order to reduce gas-cost for failing transactions
        _verifyRateDeviation(removeSpotRate.n, removeSpotRate.d, removeAverageRate.n, removeAverageRate.d);

        uint256 poolTokenAmount = 0;
        uint256 originalAmount = 0;
        uint256 fullyProtectedAmount = 0;

        uint256 length = positionList.positionIds.length;
        for (uint256 i = 0; i < length; ++i) {
            Position memory removedPos = _removePosition(msg.sender, positionList.positionIds[i], PPM_RESOLUTION, true);
            require(
                removedPos.poolToken == poolToken && removedPos.reserveToken == reserveToken,
                "ERR_INVALID_POSITION_LIST"
            );

            // collect pool token amounts
            poolTokenAmount = poolTokenAmount.add(removedPos.poolAmount);

            // collect originally provided amounts
            originalAmount = originalAmount.add(removedPos.reserveAmount);

            // get the various rates between the reserves upon adding liquidity and now
            PackedRates memory packedRates = _packRates(
                removedPos.reserveRateN,
                removedPos.reserveRateD,
                removeSpotRate,
                removeAverageRate
            );

            // get the fully protected amount (+ fees)
            fullyProtectedAmount = fullyProtectedAmount.add(
                _removeLiquidityTargetAmount(
                    poolRate,
                    removedPos.poolAmount,
                    removedPos.reserveAmount,
                    packedRates,
                    Fraction({ n: 1, d: 1 })
                )
            );
        }

        // add the pool tokens to the system
        _systemStore.incSystemBalance(poolToken, poolTokenAmount);

        // remove network token liquidity
        if (_isNetworkToken(reserveToken)) {
            // mint the fully protected amount (+ fees) and migrate it
            _mintNetworkTokens(address(this), poolToken, fullyProtectedAmount);

            _networkToken.approve(address(_networkV3), fullyProtectedAmount);

            _networkV3.migrateLiquidity(
                IReserveToken(address(_networkToken)),
                msg.sender,
                fullyProtectedAmount,
                fullyProtectedAmount,
                originalAmount
            );

            return;
        }

        // remove base token liquidity

        // calculate the amount of pool tokens required for liquidation
        // note that the amount is doubled since it's not possible to liquidate one reserve only
        uint256 poolLiquidationAmount = _liquidationAmount(fullyProtectedAmount, poolRate, poolToken, 0);

        // withdraw the pool tokens from the wallet
        _withdrawPoolTokens(poolToken, poolLiquidationAmount);

        // remove liquidity
        _removeLiquidity(poolToken, poolLiquidationAmount, reserveToken, IReserveToken(address(_networkToken)));

        // migrate the received tokens
        uint256 removedAmount = reserveToken.balanceOf(address(this));
        uint256 value;
        if (reserveToken.isNativeToken()) {
            value = removedAmount;
        } else {
            IERC20(address(reserveToken)).safeApprove(address(_networkV3), removedAmount);
        }
        _networkV3.migrateLiquidity{ value: value }(
            reserveToken,
            msg.sender,
            fullyProtectedAmount,
            removedAmount,
            originalAmount
        );

        // if the contract still holds network tokens, burn them
        uint256 networkBalance = _networkToken.balanceOf(address(this));
        if (networkBalance > 0) {
            _burnNetworkTokens(poolToken, networkBalance);
        }
    }

    /**
     * @dev returns the amount the provider will receive for removing liquidity
     */
    function _removeLiquidityTargetAmount(
        IDSToken poolToken,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount,
        PackedRates memory packedRates,
        uint256 addTimestamp,
        uint256 removeTimestamp
    ) internal view returns (uint256) {
        // get the rate between the pool token and the reserve token
        Fraction memory poolRate = _poolTokenRate(poolToken, reserveToken);

        // calculate the protection level
        Fraction memory level = _protectionLevel(addTimestamp, removeTimestamp);

        return _removeLiquidityTargetAmount(poolRate, poolAmount, reserveAmount, packedRates, level);
    }

    /**
     * @dev returns the amount the provider will receive for removing liquidity
     */
    function _removeLiquidityTargetAmount(
        Fraction memory poolRate,
        uint256 poolAmount,
        uint256 reserveAmount,
        PackedRates memory packedRates,
        Fraction memory level
    ) internal pure returns (uint256) {
        // get the rate between the reserves upon adding liquidity and now
        Fraction memory addSpotRate = Fraction({ n: packedRates.addSpotRateN, d: packedRates.addSpotRateD });
        Fraction memory removeSpotRate = Fraction({ n: packedRates.removeSpotRateN, d: packedRates.removeSpotRateD });
        Fraction memory removeAverageRate = Fraction({
            n: packedRates.removeAverageRateN,
            d: packedRates.removeAverageRateD
        });

        // calculate the protected amount of reserve tokens plus accumulated fee before compensation
        uint256 total = _protectedAmountPlusFee(poolAmount, poolRate, addSpotRate, removeSpotRate);

        // calculate the impermanent loss
        Fraction memory loss = _impLoss(addSpotRate, removeAverageRate);

        // calculate the compensation amount
        return _compensationAmount(reserveAmount, Math.max(reserveAmount, total), loss, level);
    }

    /**
     * @dev transfers a position to a new provider
     *
     * Requirements:
     *
     * - the caller must be the owner of the position
     */
    function transferPosition(uint256 id, address newProvider)
        external
        override
        nonReentrant
        validAddress(newProvider)
        returns (uint256)
    {
        return _transferPosition(msg.sender, id, newProvider);
    }

    /**
     * @dev transfers a position to a new provider and optionally notifies another contract
     *
     * Requirements:
     *
     * - the caller must be the owner of the position
     */
    function transferPositionAndNotify(
        uint256 id,
        address newProvider,
        ITransferPositionCallback callback,
        bytes calldata data
    ) external override nonReentrant validAddress(newProvider) validAddress(address(callback)) returns (uint256) {
        uint256 newId = _transferPosition(msg.sender, id, newProvider);

        callback.onTransferPosition(newId, msg.sender, data);

        return newId;
    }

    /**
     * @dev migrates system pool tokens to v3
     *
     * Requirements:
     *
     * - the caller must be the owner of this contract
     */
    function migrateSystemPoolTokens(IConverterAnchor[] calldata poolAnchors) external nonReentrant ownerOnly {
        uint256 length = poolAnchors.length;
        for (uint256 i = 0; i < length; i++) {
            IDSToken poolToken = IDSToken(address(poolAnchors[i]));
            uint256 poolAmount = _systemStore.systemBalance(poolToken);

            _withdrawPoolTokens(poolToken, poolAmount);

            ILiquidityPoolConverter converter = ILiquidityPoolConverter(payable(_ownedBy(poolToken)));
            (IReserveToken[] memory reserveTokens, uint256[] memory minReturns) = _removeLiquidityInput(
                IReserveToken(address(_networkToken)),
                _converterOtherReserve(converter, IReserveToken(address(_networkToken)))
            );

            uint256[] memory reserveAmounts = converter.removeLiquidity(poolAmount, reserveTokens, minReturns);

            _burnNetworkTokens(poolAnchors[i], reserveAmounts[0]);
            if (reserveTokens[1].isNativeToken()) {
                _vaultV3.sendValue(reserveAmounts[1]);
            } else {
                reserveTokens[1].safeTransfer(_vaultV3, reserveAmounts[1]);
            }
        }
    }

    /**
     * @dev transfers a position to a new provider
     */
    function _transferPosition(
        address provider,
        uint256 id,
        address newProvider
    ) internal returns (uint256) {
        // remove the position from the store and update the stats and the last removal checkpoint
        Position memory removedPos = _removePosition(provider, id, PPM_RESOLUTION, false);

        // add the position to the store, update the stats, and return the new id
        return
            _addPosition(
                newProvider,
                removedPos.poolToken,
                removedPos.reserveToken,
                removedPos.poolAmount,
                removedPos.reserveAmount,
                removedPos.timestamp
            );
    }

    /**
     * @dev allows the caller to claim network token balance that is no longer locked
     *
     * note that the function can revert if the range is too large
     */
    function claimBalance(uint256 startIndex, uint256 endIndex) external nonReentrant {
        // get the locked balances from the store
        (uint256[] memory amounts, uint256[] memory expirationTimes) = _store.lockedBalanceRange(
            msg.sender,
            startIndex,
            endIndex
        );

        uint256 totalAmount = 0;
        uint256 length = amounts.length;
        assert(length == expirationTimes.length);

        // reverse iteration since we're removing from the list
        for (uint256 i = length; i > 0; i--) {
            uint256 index = i - 1;
            if (expirationTimes[index] > _time()) {
                continue;
            }

            // remove the locked balance item
            _store.removeLockedBalance(msg.sender, startIndex + index);
            totalAmount = totalAmount.add(amounts[index]);
        }

        if (totalAmount > 0) {
            // transfer the tokens to the caller in a single call
            _wallet.withdrawTokens(IReserveToken(address(_networkToken)), msg.sender, totalAmount);
        }
    }

    /**
     * @dev returns the ROI for removing liquidity in the current state after providing liquidity with the given args
     *
     * note that the function assumes full protection is in effect and that the return value is in PPM and can be
     * larger than PPM_RESOLUTION for positive ROI, 1M = 0% ROI
     */
    function poolROI(
        IDSToken poolToken,
        IReserveToken reserveToken,
        uint256 reserveAmount,
        uint256 poolRateN,
        uint256 poolRateD,
        uint256 reserveRateN,
        uint256 reserveRateD
    ) external view returns (uint256) {
        // calculate the amount of pool tokens based on the amount of reserve tokens
        uint256 poolAmount = _mulDivF(reserveAmount, poolRateD, poolRateN);

        // get the various rates between the reserves upon adding liquidity and now
        PackedRates memory packedRates = _packRates(poolToken, reserveToken, reserveRateN, reserveRateD);

        // get the current return
        uint256 protectedReturn = _removeLiquidityTargetAmount(
            poolToken,
            reserveToken,
            poolAmount,
            reserveAmount,
            packedRates,
            _time().sub(_settings.maxProtectionDelay()),
            _time()
        );

        // calculate the ROI as the ratio between the current fully protected return and the initial amount
        return _mulDivF(protectedReturn, PPM_RESOLUTION, reserveAmount);
    }

    /**
     * @dev adds the position to the store and updates the stats
     */
    function _addPosition(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount,
        uint256 timestamp
    ) internal returns (uint256) {
        // verify rate deviation as early as possible in order to reduce gas-cost for failing transactions
        (Fraction memory spotRate, Fraction memory averageRate) = _reserveTokenRates(poolToken, reserveToken);
        _verifyRateDeviation(spotRate.n, spotRate.d, averageRate.n, averageRate.d);

        _notifyEventSubscribersOnAddingLiquidity(provider, poolToken, reserveToken, poolAmount, reserveAmount);

        _stats.increaseTotalAmounts(provider, poolToken, reserveToken, poolAmount, reserveAmount);
        _stats.addProviderPool(provider, poolToken);

        return
            _store.addProtectedLiquidity(
                provider,
                poolToken,
                reserveToken,
                poolAmount,
                reserveAmount,
                spotRate.n,
                spotRate.d,
                timestamp
            );
    }

    /**
     * @dev removes the position from the store and updates the stats and the last removal checkpoint
     */
    function _removePosition(
        address provider,
        uint256 id,
        uint32 portion,
        bool isMigrating
    ) private returns (Position memory) {
        Position memory pos = _providerPosition(id, provider);

        // verify that the pool is whitelisted
        _poolWhitelisted(pos.poolToken);

        // verify that the position is not removed on the same block in which it was added
        require(pos.timestamp < _time(), "ERR_TOO_EARLY");

        if (portion == PPM_RESOLUTION) {
            _notifyEventSubscribersOnRemovingLiquidity(
                id,
                pos.provider,
                pos.poolToken,
                pos.reserveToken,
                pos.poolAmount,
                pos.reserveAmount
            );

            // remove the position from the provider
            _store.removeProtectedLiquidity(id);
        } else {
            // remove a portion of the position from the provider
            uint256 fullPoolAmount = pos.poolAmount;
            uint256 fullReserveAmount = pos.reserveAmount;
            (pos.poolAmount, pos.reserveAmount) = _portionAmounts(pos.poolAmount, pos.reserveAmount, portion);

            _notifyEventSubscribersOnRemovingLiquidity(
                id,
                pos.provider,
                pos.poolToken,
                pos.reserveToken,
                pos.poolAmount,
                pos.reserveAmount
            );

            _store.updateProtectedLiquidityAmounts(
                id,
                fullPoolAmount - pos.poolAmount,
                fullReserveAmount - pos.reserveAmount
            );
        }

        // update the statistics
        _stats.decreaseTotalAmounts(pos.provider, pos.poolToken, pos.reserveToken, pos.poolAmount, pos.reserveAmount);

        // update last liquidity removal checkpoint
        if (!isMigrating) {
            _lastRemoveCheckpointStore.addCheckpoint(provider);
        }

        return pos;
    }

    /**
     * @dev locks network tokens for the provider and emits the tokens locked event
     */
    function _lockTokens(address provider, uint256 amount) internal {
        uint256 expirationTime = _time().add(_settings.lockDuration());
        _store.addLockedBalance(provider, amount, expirationTime);
    }

    /**
     * @dev returns the rate of 1 pool token in reserve token units
     */
    function _poolTokenRate(IDSToken poolToken, IReserveToken reserveToken)
        internal
        view
        virtual
        returns (Fraction memory)
    {
        // get the pool token supply
        uint256 poolTokenSupply = poolToken.totalSupply();

        // get the reserve balance
        IConverter converter = IConverter(payable(_ownedBy(poolToken)));
        uint256 reserveBalance = converter.getConnectorBalance(reserveToken);

        // for standard pools, 50% of the pool supply value equals the value of each reserve
        return Fraction({ n: reserveBalance.mul(2), d: poolTokenSupply });
    }

    /**
     * @dev returns the spot rate and average rate of 1 reserve token in the other reserve token units
     */
    function _reserveTokenRates(IDSToken poolToken, IReserveToken reserveToken)
        internal
        view
        returns (Fraction memory, Fraction memory)
    {
        ILiquidityPoolConverter converter = ILiquidityPoolConverter(payable(_ownedBy(poolToken)));
        IReserveToken otherReserve = _converterOtherReserve(converter, reserveToken);

        (uint256 spotRateN, uint256 spotRateD) = _converterReserveBalances(converter, otherReserve, reserveToken);
        (uint256 averageRateN, uint256 averageRateD) = converter.recentAverageRate(reserveToken);

        return (Fraction({ n: spotRateN, d: spotRateD }), Fraction({ n: averageRateN, d: averageRateD }));
    }

    /**
     * @dev returns the various rates between the reserves
     */
    function _packRates(
        IDSToken poolToken,
        IReserveToken reserveToken,
        uint256 addSpotRateN,
        uint256 addSpotRateD
    ) internal view returns (PackedRates memory) {
        (Fraction memory removeSpotRate, Fraction memory removeAverageRate) = _reserveTokenRates(
            poolToken,
            reserveToken
        );

        assert((removeSpotRate.n | removeSpotRate.d | removeAverageRate.n | removeAverageRate.d) <= MAX_UINT128);

        return _packRates(addSpotRateN, addSpotRateD, removeSpotRate, removeAverageRate);
    }

    /**
     * @dev returns the various rates between the reserves
     */
    function _packRates(
        uint256 addSpotRateN,
        uint256 addSpotRateD,
        Fraction memory removeSpotRate,
        Fraction memory removeAverageRate
    ) internal pure returns (PackedRates memory) {
        assert((addSpotRateN | addSpotRateD) <= MAX_UINT128);

        return
            PackedRates({
                addSpotRateN: uint128(addSpotRateN),
                addSpotRateD: uint128(addSpotRateD),
                removeSpotRateN: uint128(removeSpotRate.n),
                removeSpotRateD: uint128(removeSpotRate.d),
                removeAverageRateN: uint128(removeAverageRate.n),
                removeAverageRateD: uint128(removeAverageRate.d)
            });
    }

    /**
     * @dev verifies that the deviation of the average rate from the spot rate is within the permitted range
     *
     * for example, if the maximum permitted deviation is 5%, then verify `95/100 <= average/spot <= 100/95`
     */
    function _verifyRateDeviation(
        uint256 spotRateN,
        uint256 spotRateD,
        uint256 averageRateN,
        uint256 averageRateD
    ) internal view {
        uint256 ppmDelta = PPM_RESOLUTION - _settings.averageRateMaxDeviation();
        uint256 min = spotRateN.mul(averageRateD).mul(ppmDelta).mul(ppmDelta);
        uint256 mid = spotRateD.mul(averageRateN).mul(ppmDelta).mul(PPM_RESOLUTION);
        uint256 max = spotRateN.mul(averageRateD).mul(PPM_RESOLUTION).mul(PPM_RESOLUTION);
        require(min <= mid && mid <= max, "ERR_INVALID_RATE");
    }

    /**
     * @dev utility to add liquidity to a converter
     */
    function _addLiquidity(
        ILiquidityPoolConverter converter,
        IReserveToken reserveToken1,
        IReserveToken reserveToken2,
        uint256 reserveAmount1,
        uint256 reserveAmount2,
        uint256 value
    ) internal {
        IReserveToken[] memory reserveTokens = new IReserveToken[](2);
        uint256[] memory amounts = new uint256[](2);
        reserveTokens[0] = reserveToken1;
        reserveTokens[1] = reserveToken2;
        amounts[0] = reserveAmount1;
        amounts[1] = reserveAmount2;
        converter.addLiquidity{ value: value }(reserveTokens, amounts, 1);
    }

    /**
     * @dev utility to remove liquidity from a converter
     */
    function _removeLiquidity(
        IDSToken poolToken,
        uint256 poolAmount,
        IReserveToken reserveToken1,
        IReserveToken reserveToken2
    ) internal {
        ILiquidityPoolConverter converter = ILiquidityPoolConverter(payable(_ownedBy(poolToken)));
        (IReserveToken[] memory reserveTokens, uint256[] memory minReturns) = _removeLiquidityInput(
            reserveToken1,
            reserveToken2
        );
        converter.removeLiquidity(poolAmount, reserveTokens, minReturns);
    }

    /**
     * @dev returns a position from the store
     */
    function _position(uint256 id) internal view returns (Position memory) {
        Position memory pos;
        (
            pos.provider,
            pos.poolToken,
            pos.reserveToken,
            pos.poolAmount,
            pos.reserveAmount,
            pos.reserveRateN,
            pos.reserveRateD,
            pos.timestamp
        ) = _store.protectedLiquidity(id);

        return pos;
    }

    /**
     * @dev returns a position from the store
     */
    function _providerPosition(uint256 id, address provider) internal view returns (Position memory) {
        Position memory pos = _position(id);
        require(pos.provider == provider, "ERR_ACCESS_DENIED");

        return pos;
    }

    /**
     * @dev returns the protected amount of reserve tokens plus accumulated fee before compensation
     */
    function _protectedAmountPlusFee(
        uint256 poolAmount,
        Fraction memory poolRate,
        Fraction memory addRate,
        Fraction memory removeRate
    ) internal pure returns (uint256) {
        uint256 n = MathEx.ceilSqrt(addRate.d.mul(removeRate.n)).mul(poolRate.n);
        uint256 d = MathEx.floorSqrt(addRate.n.mul(removeRate.d)).mul(poolRate.d);

        uint256 x = n * poolAmount;
        if (x / n == poolAmount) {
            return x / d;
        }

        (uint256 hi, uint256 lo) = n > poolAmount ? (n, poolAmount) : (poolAmount, n);
        (uint256 p, uint256 q) = MathEx.reducedRatio(hi, d, MAX_UINT256 / lo);
        uint256 min = (hi / d).mul(lo);

        if (q > 0) {
            return Math.max(min, (p * lo) / q);
        }
        return min;
    }

    /**
     * @dev returns the impermanent loss incurred due to the change in rates between the reserve tokens
     */
    function _impLoss(Fraction memory prevRate, Fraction memory newRate) internal pure returns (Fraction memory) {
        uint256 ratioN = newRate.n.mul(prevRate.d);
        uint256 ratioD = newRate.d.mul(prevRate.n);

        uint256 prod = ratioN * ratioD;
        uint256 root = prod / ratioN == ratioD
            ? MathEx.floorSqrt(prod)
            : MathEx.floorSqrt(ratioN) * MathEx.floorSqrt(ratioD);
        uint256 sum = ratioN.add(ratioD);

        // the arithmetic below is safe because `x + y >= sqrt(x * y) * 2`
        if (sum % 2 == 0) {
            sum /= 2;
            return Fraction({ n: sum - root, d: sum });
        }
        return Fraction({ n: sum - root * 2, d: sum });
    }

    /**
     * @dev returns the protection level based on the timestamp and protection delays
     */
    function _protectionLevel(uint256 addTimestamp, uint256 removeTimestamp) internal view returns (Fraction memory) {
        uint256 timeElapsed = removeTimestamp.sub(addTimestamp);
        uint256 minProtectionDelay = _settings.minProtectionDelay();
        uint256 maxProtectionDelay = _settings.maxProtectionDelay();
        if (timeElapsed < minProtectionDelay) {
            return Fraction({ n: 0, d: 1 });
        }

        if (timeElapsed >= maxProtectionDelay) {
            return Fraction({ n: 1, d: 1 });
        }

        return Fraction({ n: timeElapsed, d: maxProtectionDelay });
    }

    /**
     * @dev returns the compensation amount based on the impermanent loss and the protection level
     */
    function _compensationAmount(
        uint256 amount,
        uint256 total,
        Fraction memory loss,
        Fraction memory level
    ) internal pure returns (uint256) {
        uint256 levelN = level.n.mul(amount);
        uint256 levelD = level.d;
        uint256 maxVal = Math.max(Math.max(levelN, levelD), total);
        (uint256 lossN, uint256 lossD) = MathEx.reducedRatio(loss.n, loss.d, MAX_UINT256 / maxVal);
        return total.mul(lossD.sub(lossN)).div(lossD).add(lossN.mul(levelN).div(lossD.mul(levelD)));
    }

    function _networkCompensation(
        uint256 targetAmount,
        uint256 baseAmount,
        PackedRates memory packedRates
    ) internal view returns (uint256) {
        if (targetAmount <= baseAmount) {
            return 0;
        }

        // calculate the delta in network tokens
        uint256 delta = _mulDivF(
            targetAmount - baseAmount,
            packedRates.removeAverageRateN,
            packedRates.removeAverageRateD
        );

        // the delta might be very small due to precision loss
        // in which case no compensation will take place (gas optimization)
        if (delta >= _settings.minNetworkCompensation()) {
            return delta;
        }

        return 0;
    }

    /**
     * @dev utility to mint network tokens
     */
    function _mintNetworkTokens(
        address owner,
        IConverterAnchor poolAnchor,
        uint256 amount
    ) private {
        _systemStore.incNetworkTokensMinted(poolAnchor, amount);
        _networkTokenGovernance.mint(owner, amount);
    }

    /**
     * @dev utility to burn network tokens
     */
    function _burnNetworkTokens(IConverterAnchor poolAnchor, uint256 amount) private {
        _systemStore.decNetworkTokensMinted(poolAnchor, amount);
        _networkTokenGovernance.burn(amount);
    }

    /**
     * @dev notify event subscribers on adding liquidity
     */
    function _notifyEventSubscribersOnAddingLiquidity(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) private {
        address[] memory subscribers = _settings.subscribers();
        uint256 length = subscribers.length;
        for (uint256 i = 0; i < length; i++) {
            ILiquidityProvisionEventsSubscriber(subscribers[i]).onAddingLiquidity(
                provider,
                poolToken,
                reserveToken,
                poolAmount,
                reserveAmount
            );
        }
    }

    /**
     * @dev notify event subscribers on removing liquidity
     */
    function _notifyEventSubscribersOnRemovingLiquidity(
        uint256 id,
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) private {
        address[] memory subscribers = _settings.subscribers();
        uint256 length = subscribers.length;
        for (uint256 i = 0; i < length; i++) {
            ILiquidityProvisionEventsSubscriber(subscribers[i]).onRemovingLiquidity(
                id,
                provider,
                poolToken,
                reserveToken,
                poolAmount,
                reserveAmount
            );
        }
    }

    /**
     * @dev utility to get the reserve balances
     */
    function _converterReserveBalances(
        IConverter converter,
        IReserveToken reserveToken1,
        IReserveToken reserveToken2
    ) private view returns (uint256, uint256) {
        return (converter.getConnectorBalance(reserveToken1), converter.getConnectorBalance(reserveToken2));
    }

    /**
     * @dev utility to get the other reserve
     */
    function _converterOtherReserve(IConverter converter, IReserveToken thisReserve)
        private
        view
        returns (IReserveToken)
    {
        IReserveToken otherReserve = converter.connectorTokens(0);
        return otherReserve != thisReserve ? otherReserve : converter.connectorTokens(1);
    }

    /**
     * @dev utility to get the owner
     */
    function _ownedBy(IOwned owned) private view returns (address) {
        return owned.owner();
    }

    /**
     * @dev returns whether the provided reserve token is the network token
     */
    function _isNetworkToken(IReserveToken reserveToken) private view returns (bool) {
        return address(reserveToken) == address(_networkToken);
    }

    /**
     * @dev returns custom input for the `removeLiquidity` converter function
     */
    function _removeLiquidityInput(IReserveToken reserveToken1, IReserveToken reserveToken2)
        private
        pure
        returns (IReserveToken[] memory, uint256[] memory)
    {
        IReserveToken[] memory reserveTokens = new IReserveToken[](2);
        uint256[] memory minReturns = new uint256[](2);
        reserveTokens[0] = reserveToken1;
        reserveTokens[1] = reserveToken2;
        minReturns[0] = 1;
        minReturns[1] = 1;
        return (reserveTokens, minReturns);
    }

    /**
     * @dev returns the relative position amounts
     */
    function _portionAmounts(
        uint256 poolAmount,
        uint256 reserveAmount,
        uint256 portion
    ) private pure returns (uint256, uint256) {
        return (_mulDivF(poolAmount, portion, PPM_RESOLUTION), _mulDivF(reserveAmount, portion, PPM_RESOLUTION));
    }

    /**
     * @dev returns the network token minting limit
     */
    function _networkTokenMintingLimit(IConverterAnchor poolAnchor) private view returns (uint256) {
        uint256 mintingLimit = _settings.networkTokenMintingLimits(poolAnchor);
        return mintingLimit > 0 ? mintingLimit : _settings.defaultNetworkTokenMintingLimit();
    }

    /**
     * @dev returns the amount of pool tokens required for liquidation
     */
    function _liquidationAmount(
        uint256 targetAmount,
        Fraction memory poolRate,
        IDSToken poolToken,
        uint256 additionalAmount
    ) private view returns (uint256) {
        // note that the amount is doubled since it's not possible to liquidate one reserve only
        uint256 poolAmount = _mulDivF(targetAmount, poolRate.d.mul(2), poolRate.n);
        // limit the amount of pool tokens by the amount the system/caller holds
        return Math.min(poolAmount, _systemStore.systemBalance(poolToken).add(additionalAmount));
    }

    /**
     * @dev withdraw pool tokens from the wallet
     */
    function _withdrawPoolTokens(IDSToken poolToken, uint256 poolAmount) private {
        _systemStore.decSystemBalance(poolToken, poolAmount);
        _wallet.withdrawTokens(IReserveToken(address(poolToken)), address(this), poolAmount);
    }

    /**
     * @dev returns `x * y / z`
     */
    function _mulDivF(
        uint256 x,
        uint256 y,
        uint256 z
    ) private pure returns (uint256) {
        return x.mul(y).div(z);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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
pragma solidity >=0.6.12;

import "./IMintableToken.sol";

/// @title The interface for mintable/burnable token governance.
interface ITokenGovernance {
    // The address of the mintable ERC20 token.
    function token() external view returns (IMintableToken);

    /// @dev Mints new tokens.
    ///
    /// @param to Account to receive the new amount.
    /// @param amount Amount to increase the supply by.
    ///
    function mint(address to, uint256 amount) external;

    /// @dev Burns tokens from the caller.
    ///
    /// @param amount Amount to decrease the supply by.
    ///
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev Checkpoint store contract interface
 */
interface ICheckpointStore {
    function addCheckpoint(address target) external;

    function addPastCheckpoint(address target, uint256 timestamp) external;

    function addPastCheckpoints(address[] calldata targets, uint256[] calldata timestamps) external;

    function checkpoint(address target) external view returns (uint256);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev This library provides a set of complex math operations.
 */
library MathEx {
    uint256 private constant MAX_EXP_BIT_LEN = 4;
    uint256 private constant MAX_EXP = 2**MAX_EXP_BIT_LEN - 1;
    uint256 private constant MAX_UINT256 = uint256(-1);

    /**
     * @dev returns the largest integer smaller than or equal to the square root of a positive integer
     */
    function floorSqrt(uint256 num) internal pure returns (uint256) {
        uint256 x = num / 2 + 1;
        uint256 y = (x + num / x) / 2;
        while (x > y) {
            x = y;
            y = (x + num / x) / 2;
        }
        return x;
    }

    /**
     * @dev returns the smallest integer larger than or equal to the square root of a positive integer
     */
    function ceilSqrt(uint256 num) internal pure returns (uint256) {
        uint256 x = floorSqrt(num);

        return x * x == num ? x : x + 1;
    }

    /**
     * @dev computes the product of two given ratios
     */
    function productRatio(
        uint256 xn,
        uint256 yn,
        uint256 xd,
        uint256 yd
    ) internal pure returns (uint256, uint256) {
        uint256 n = mulDivC(xn, yn, MAX_UINT256);
        uint256 d = mulDivC(xd, yd, MAX_UINT256);
        uint256 z = n > d ? n : d;
        if (z > 1) {
            return (mulDivC(xn, yn, z), mulDivC(xd, yd, z));
        }
        return (xn * yn, xd * yd);
    }

    /**
     * @dev computes a reduced-scalar ratio
     */
    function reducedRatio(
        uint256 n,
        uint256 d,
        uint256 max
    ) internal pure returns (uint256, uint256) {
        (uint256 newN, uint256 newD) = (n, d);
        if (newN > max || newD > max) {
            (newN, newD) = normalizedRatio(newN, newD, max);
        }
        if (newN != newD) {
            return (newN, newD);
        }
        return (1, 1);
    }

    /**
     * @dev computes "scale * a / (a + b)" and "scale * b / (a + b)".
     */
    function normalizedRatio(
        uint256 a,
        uint256 b,
        uint256 scale
    ) internal pure returns (uint256, uint256) {
        if (a <= b) {
            return accurateRatio(a, b, scale);
        }
        (uint256 y, uint256 x) = accurateRatio(b, a, scale);
        return (x, y);
    }

    /**
     * @dev computes "scale * a / (a + b)" and "scale * b / (a + b)", assuming that "a <= b".
     */
    function accurateRatio(
        uint256 a,
        uint256 b,
        uint256 scale
    ) internal pure returns (uint256, uint256) {
        uint256 maxVal = MAX_UINT256 / scale;
        if (a > maxVal) {
            uint256 c = a / (maxVal + 1) + 1;
            a /= c; // we can now safely compute `a * scale`
            b /= c;
        }
        if (a != b) {
            uint256 newN = a * scale;
            uint256 newD = unsafeAdd(a, b); // can overflow
            if (newD >= a) {
                // no overflow in `a + b`
                uint256 x = roundDiv(newN, newD); // we can now safely compute `scale - x`
                uint256 y = scale - x;
                return (x, y);
            }
            if (newN < b - (b - a) / 2) {
                return (0, scale); // `a * scale < (a + b) / 2 < MAX_UINT256 < a + b`
            }
            return (1, scale - 1); // `(a + b) / 2 < a * scale < MAX_UINT256 < a + b`
        }
        return (scale / 2, scale / 2); // allow reduction to `(1, 1)` in the calling function
    }

    /**
     * @dev computes the nearest integer to a given quotient without overflowing or underflowing.
     */
    function roundDiv(uint256 n, uint256 d) internal pure returns (uint256) {
        return n / d + (n % d) / (d - d / 2);
    }

    /**
     * @dev returns the average number of decimal digits in a given list of positive integers
     */
    function geometricMean(uint256[] memory values) internal pure returns (uint256) {
        uint256 numOfDigits = 0;
        uint256 length = values.length;
        for (uint256 i = 0; i < length; ++i) {
            numOfDigits += decimalLength(values[i]);
        }
        return uint256(10)**(roundDivUnsafe(numOfDigits, length) - 1);
    }

    /**
     * @dev returns the number of decimal digits in a given positive integer
     */
    function decimalLength(uint256 x) internal pure returns (uint256) {
        uint256 y = 0;
        for (uint256 tmpX = x; tmpX > 0; tmpX /= 10) {
            ++y;
        }
        return y;
    }

    /**
     * @dev returns the nearest integer to a given quotient
     *
     * note the computation is overflow-safe assuming that the input is sufficiently small
     */
    function roundDivUnsafe(uint256 n, uint256 d) internal pure returns (uint256) {
        return (n + d / 2) / d;
    }

    /**
     * @dev returns the largest integer smaller than or equal to `x * y / z`
     */
    function mulDivF(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256) {
        (uint256 xyh, uint256 xyl) = mul512(x, y);

        // if `x * y < 2 ^ 256`
        if (xyh == 0) {
            return xyl / z;
        }

        // assert `x * y / z < 2 ^ 256`
        require(xyh < z, "ERR_OVERFLOW");

        uint256 m = mulMod(x, y, z); // `m = x * y % z`
        (uint256 nh, uint256 nl) = sub512(xyh, xyl, m); // `n = x * y - m` hence `n / z = floor(x * y / z)`

        // if `n < 2 ^ 256`
        if (nh == 0) {
            return nl / z;
        }

        uint256 p = unsafeSub(0, z) & z; // `p` is the largest power of 2 which `z` is divisible by
        uint256 q = div512(nh, nl, p); // `n` is divisible by `p` because `n` is divisible by `z` and `z` is divisible by `p`
        uint256 r = inv256(z / p); // `z / p = 1 mod 2` hence `inverse(z / p) = 1 mod 2 ^ 256`
        return unsafeMul(q, r); // `q * r = (n / p) * inverse(z / p) = n / z`
    }

    /**
     * @dev returns the smallest integer larger than or equal to `x * y / z`
     */
    function mulDivC(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256) {
        uint256 w = mulDivF(x, y, z);
        if (mulMod(x, y, z) > 0) {
            require(w < MAX_UINT256, "ERR_OVERFLOW");
            return w + 1;
        }
        return w;
    }

    /**
     * @dev returns the value of `x * y` as a pair of 256-bit values
     */
    function mul512(uint256 x, uint256 y) private pure returns (uint256, uint256) {
        uint256 p = mulModMax(x, y);
        uint256 q = unsafeMul(x, y);
        if (p >= q) {
            return (p - q, q);
        }
        return (unsafeSub(p, q) - 1, q);
    }

    /**
     * @dev returns the value of `2 ^ 256 * xh + xl - y`, where `2 ^ 256 * xh + xl >= y`
     */
    function sub512(
        uint256 xh,
        uint256 xl,
        uint256 y
    ) private pure returns (uint256, uint256) {
        if (xl >= y) {
            return (xh, xl - y);
        }
        return (xh - 1, unsafeSub(xl, y));
    }

    /**
     * @dev returns the value of `(2 ^ 256 * xh + xl) / pow2n`, where `xl` is divisible by `pow2n`
     */
    function div512(
        uint256 xh,
        uint256 xl,
        uint256 pow2n
    ) private pure returns (uint256) {
        uint256 pow2nInv = unsafeAdd(unsafeSub(0, pow2n) / pow2n, 1); // `1 << (256 - n)`
        return unsafeMul(xh, pow2nInv) | (xl / pow2n); // `(xh << (256 - n)) | (xl >> n)`
    }

    /**
     * @dev returns the inverse of `d` modulo `2 ^ 256`, where `d` is congruent to `1` modulo `2`
     */
    function inv256(uint256 d) private pure returns (uint256) {
        // approximate the root of `f(x) = 1 / x - d` using the newton–raphson convergence method
        uint256 x = 1;
        for (uint256 i = 0; i < 8; ++i) {
            x = unsafeMul(x, unsafeSub(2, unsafeMul(x, d))); // `x = x * (2 - x * d) mod 2 ^ 256`
        }
        return x;
    }

    /**
     * @dev returns `(x + y) % 2 ^ 256`
     */
    function unsafeAdd(uint256 x, uint256 y) private pure returns (uint256) {
        return x + y;
    }

    /**
     * @dev returns `(x - y) % 2 ^ 256`
     */
    function unsafeSub(uint256 x, uint256 y) private pure returns (uint256) {
        return x - y;
    }

    /**
     * @dev returns `(x * y) % 2 ^ 256`
     */
    function unsafeMul(uint256 x, uint256 y) private pure returns (uint256) {
        return x * y;
    }

    /**
     * @dev returns `x * y % (2 ^ 256 - 1)`
     */
    function mulModMax(uint256 x, uint256 y) private pure returns (uint256) {
        return mulmod(x, y, MAX_UINT256);
    }

    /**
     * @dev returns `x * y % z`
     */
    function mulMod(
        uint256 x,
        uint256 y,
        uint256 z
    ) private pure returns (uint256) {
        return mulmod(x, y, z);
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev This contract provides types which can be used by various contracts.
 */

struct Fraction {
    uint256 n; // numerator
    uint256 d; // denominator
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/*
    Time implementing contract
*/
contract Time {
    /**
     * @dev returns the current time
     */
    function _time() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Utilities & Common Modifiers
 */
contract Utils {
    uint32 internal constant PPM_RESOLUTION = 1000000;

    // verifies that a value is greater than zero
    modifier greaterThanZero(uint256 value) {
        _greaterThanZero(value);

        _;
    }

    // error message binary size optimization
    function _greaterThanZero(uint256 value) internal pure {
        require(value > 0, "ERR_ZERO_VALUE");
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address addr) {
        _validAddress(addr);

        _;
    }

    // error message binary size optimization
    function _validAddress(address addr) internal pure {
        require(addr != address(0), "ERR_INVALID_ADDRESS");
    }

    // ensures that the portion is valid
    modifier validPortion(uint32 _portion) {
        _validPortion(_portion);

        _;
    }

    // error message binary size optimization
    function _validPortion(uint32 _portion) internal pure {
        require(_portion > 0 && _portion <= PPM_RESOLUTION, "ERR_INVALID_PORTION");
    }

    // validates an external address - currently only checks that it isn't null or this
    modifier validExternalAddress(address addr) {
        _validExternalAddress(addr);

        _;
    }

    // error message binary size optimization
    function _validExternalAddress(address addr) internal view {
        require(addr != address(0) && addr != address(this), "ERR_INVALID_EXTERNAL_ADDRESS");
    }

    // ensures that the fee is valid
    modifier validFee(uint32 fee) {
        _validFee(fee);

        _;
    }

    // error message binary size optimization
    function _validFee(uint32 fee) internal pure {
        require(fee <= PPM_RESOLUTION, "ERR_INVALID_FEE");
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "./interfaces/IOwned.sol";

/**
 * @dev This contract provides support and utilities for contract ownership.
 */
contract Owned is IOwned {
    address private _owner;
    address private _newOwner;

    /**
     * @dev triggered when the owner is updated
     */
    event OwnerUpdate(address indexed prevOwner, address indexed newOwner);

    /**
     * @dev initializes a new Owned instance
     */
    constructor() public {
        _owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly() {
        _ownerOnly();

        _;
    }

    // error message binary size optimization
    function _ownerOnly() private view {
        require(msg.sender == _owner, "ERR_ACCESS_DENIED");
    }

    /**
     * @dev allows transferring the contract ownership
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract
     *
     * note the new owner still needs to accept the transfer
     */
    function transferOwnership(address newOwner) public override ownerOnly {
        require(newOwner != _owner, "ERR_SAME_OWNER");

        _newOwner = newOwner;
    }

    /**
     * @dev used by a new owner to accept an ownership transfer
     */
    function acceptOwnership() public override {
        require(msg.sender == _newOwner, "ERR_ACCESS_DENIED");

        emit OwnerUpdate(_owner, _newOwner);

        _owner = _newOwner;
        _newOwner = address(0);
    }

    /**
     * @dev returns the address of the current owner
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     * @dev returns the address of the new owner candidate
     */
    function newOwner() external view returns (address) {
        return _newOwner;
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../converter/interfaces/IConverterAnchor.sol";
import "../../utility/interfaces/IOwned.sol";

/**
 * @dev DSToken interface
 */
interface IDSToken is IConverterAnchor, IERC20 {
    function issue(address recipient, uint256 amount) external;

    function destroy(address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IReserveToken.sol";

import "./SafeERC20Ex.sol";

/**
 * @dev This library implements ERC20 and SafeERC20 utilities for reserve tokens, which can be either ERC20 tokens or ETH
 */
library ReserveToken {
    using SafeERC20 for IERC20;
    using SafeERC20Ex for IERC20;

    // the address that represents an ETH reserve
    IReserveToken public constant NATIVE_TOKEN_ADDRESS = IReserveToken(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /**
     * @dev returns whether the provided token represents an ERC20 or ETH reserve
     */
    function isNativeToken(IReserveToken reserveToken) internal pure returns (bool) {
        return reserveToken == NATIVE_TOKEN_ADDRESS;
    }

    /**
     * @dev returns the balance of the reserve token
     */
    function balanceOf(IReserveToken reserveToken, address account) internal view returns (uint256) {
        if (isNativeToken(reserveToken)) {
            return account.balance;
        }

        return toIERC20(reserveToken).balanceOf(account);
    }

    /**
     * @dev transfers a specific amount of the reserve token
     */
    function safeTransfer(
        IReserveToken reserveToken,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        if (isNativeToken(reserveToken)) {
            payable(to).transfer(amount);
        } else {
            toIERC20(reserveToken).safeTransfer(to, amount);
        }
    }

    /**
     * @dev transfers a specific amount of the reserve token from a specific holder using the allowance mechanism
     *
     * note that the function ignores a reserve token which represents an ETH reserve
     */
    function safeTransferFrom(
        IReserveToken reserveToken,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0 || isNativeToken(reserveToken)) {
            return;
        }

        toIERC20(reserveToken).safeTransferFrom(from, to, amount);
    }

    /**
     * @dev ensures that the spender has sufficient allowance
     *
     * note that this function ignores a reserve token which represents an ETH reserve
     */
    function ensureApprove(
        IReserveToken reserveToken,
        address spender,
        uint256 amount
    ) internal {
        if (isNativeToken(reserveToken)) {
            return;
        }

        toIERC20(reserveToken).ensureApprove(spender, amount);
    }

    /**
     * @dev utility function that converts an IReserveToken to an IERC20
     */
    function toIERC20(IReserveToken reserveToken) private pure returns (IERC20) {
        return IERC20(address(reserveToken));
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "../../utility/interfaces/IOwned.sol";

/**
 * @dev Converter Anchor interface
 */
interface IConverterAnchor is IOwned {

}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IConverterAnchor.sol";

import "../../utility/interfaces/IOwned.sol";

import "../../token/interfaces/IReserveToken.sol";

/**
 * @dev Converter interface
 */
interface IConverter is IOwned {
    function converterType() external pure returns (uint16);

    function anchor() external view returns (IConverterAnchor);

    function isActive() external view returns (bool);

    function targetAmountAndFee(
        IReserveToken sourceToken,
        IReserveToken targetToken,
        uint256 sourceAmount
    ) external view returns (uint256, uint256);

    function convert(
        IReserveToken sourceToken,
        IReserveToken targetToken,
        uint256 sourceAmount,
        address trader,
        address payable beneficiary
    ) external payable returns (uint256);

    function conversionFee() external view returns (uint32);

    function maxConversionFee() external view returns (uint32);

    function reserveBalance(IReserveToken reserveToken) external view returns (uint256);

    receive() external payable;

    function transferAnchorOwnership(address newOwner) external;

    function acceptAnchorOwnership() external;

    function setConversionFee(uint32 fee) external;

    function addReserve(IReserveToken token, uint32 weight) external;

    function transferReservesOnUpgrade(address newConverter) external;

    function onUpgradeComplete() external;

    // deprecated, backward compatibility
    function token() external view returns (IConverterAnchor);

    function transferTokenOwnership(address newOwner) external;

    function acceptTokenOwnership() external;

    function reserveTokenCount() external view returns (uint16);

    function reserveTokens() external view returns (IReserveToken[] memory);

    function connectors(IReserveToken reserveToken)
        external
        view
        returns (
            uint256,
            uint32,
            bool,
            bool,
            bool
        );

    function getConnectorBalance(IReserveToken connectorToken) external view returns (uint256);

    function connectorTokens(uint256 index) external view returns (IReserveToken);

    function connectorTokenCount() external view returns (uint16);

    /**
     * @dev triggered when the converter is activated
     */
    event Activation(uint16 indexed converterType, IConverterAnchor indexed anchor, bool indexed activated);

    /**
     * @dev triggered when a conversion between two tokens occurs
     */
    event Conversion(
        IReserveToken indexed sourceToken,
        IReserveToken indexed targetToken,
        address indexed trader,
        uint256 sourceAmount,
        uint256 targetAmount,
        int256 conversionFee
    );

    /**
     * @dev triggered when the rate between two tokens in the converter changes
     *
     * note that the event might be dispatched for rate updates between any two tokens in the converter
     */
    event TokenRateUpdate(address indexed token1, address indexed token2, uint256 rateN, uint256 rateD);

    /**
     * @dev triggered when the conversion fee is updated
     */
    event ConversionFeeUpdate(uint32 prevFee, uint32 newFee);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "../../token/interfaces/IReserveToken.sol";

import "./IConverterAnchor.sol";

/**
 * @dev Converter Registry interface
 */
interface IConverterRegistry {
    function getAnchorCount() external view returns (uint256);

    function getAnchors() external view returns (address[] memory);

    function getAnchor(uint256 index) external view returns (IConverterAnchor);

    function isAnchor(address value) external view returns (bool);

    function getLiquidityPoolCount() external view returns (uint256);

    function getLiquidityPools() external view returns (address[] memory);

    function getLiquidityPool(uint256 index) external view returns (IConverterAnchor);

    function isLiquidityPool(address value) external view returns (bool);

    function getConvertibleTokenCount() external view returns (uint256);

    function getConvertibleTokens() external view returns (address[] memory);

    function getConvertibleToken(uint256 index) external view returns (IReserveToken);

    function isConvertibleToken(address value) external view returns (bool);

    function getConvertibleTokenAnchorCount(IReserveToken convertibleToken) external view returns (uint256);

    function getConvertibleTokenAnchors(IReserveToken convertibleToken) external view returns (address[] memory);

    function getConvertibleTokenAnchor(IReserveToken convertibleToken, uint256 index)
        external
        view
        returns (IConverterAnchor);

    function isConvertibleTokenAnchor(IReserveToken convertibleToken, address value) external view returns (bool);

    function getLiquidityPoolByConfig(
        uint16 converterType,
        IReserveToken[] memory reserveTokens,
        uint32[] memory reserveWeights
    ) external view returns (IConverterAnchor);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "./ILiquidityProtectionStore.sol";
import "./ILiquidityProtectionStats.sol";
import "./ILiquidityProtectionSettings.sol";
import "./ILiquidityProtectionSystemStore.sol";
import "./ITransferPositionCallback.sol";

import "../../utility/interfaces/ITokenHolder.sol";

import "../../token/interfaces/IReserveToken.sol";

import "../../converter/interfaces/IConverterAnchor.sol";

/**
 * @dev Liquidity Protection interface
 */
interface ILiquidityProtection {
    function store() external view returns (ILiquidityProtectionStore);

    function stats() external view returns (ILiquidityProtectionStats);

    function settings() external view returns (ILiquidityProtectionSettings);

    function addLiquidityFor(
        address owner,
        IConverterAnchor poolAnchor,
        IReserveToken reserveToken,
        uint256 amount
    ) external payable returns (uint256);

    function addLiquidity(
        IConverterAnchor poolAnchor,
        IReserveToken reserveToken,
        uint256 amount
    ) external payable returns (uint256);

    function removeLiquidity(uint256 id, uint32 portion) external;

    function transferPosition(uint256 id, address newProvider) external returns (uint256);

    function transferPositionAndNotify(
        uint256 id,
        address newProvider,
        ITransferPositionCallback callback,
        bytes calldata data
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IClaimable.sol";

/// @title Mintable Token interface
interface IMintableToken is IERC20, IClaimable {
    function issue(address to, uint256 amount) external;

    function destroy(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

/// @title Claimable contract interface
interface IClaimable {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function acceptOwnership() external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev Owned interface
 */
interface IOwned {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function acceptOwnership() external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev This contract is used to represent reserve tokens, which are tokens that can either be regular ERC20 tokens or
 * native ETH (represented by the NATIVE_TOKEN_ADDRESS address)
 *
 * Please note that this interface is intentionally doesn't inherit from IERC20, so that it'd be possible to effectively
 * override its balanceOf() function in the ReserveToken library
 */
interface IReserveToken {

}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * @dev Extends the SafeERC20 library with additional operations
 */
library SafeERC20Ex {
    using SafeERC20 for IERC20;

    /**
     * @dev ensures that the spender has sufficient allowance
     */
    function ensureApprove(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        uint256 allowance = token.allowance(address(this), spender);
        if (allowance >= amount) {
            return;
        }

        if (allowance > 0) {
            token.safeApprove(spender, 0);
        }
        token.safeApprove(spender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "../../converter/interfaces/IConverterAnchor.sol";

import "../../token/interfaces/IDSToken.sol";
import "../../token/interfaces/IReserveToken.sol";

import "../../utility/interfaces/IOwned.sol";

/**
 * @dev Liquidity Protection Store interface
 */
interface ILiquidityProtectionStore is IOwned {
    function withdrawTokens(
        IReserveToken token,
        address recipient,
        uint256 amount
    ) external;

    function protectedLiquidity(uint256 id)
        external
        view
        returns (
            address,
            IDSToken,
            IReserveToken,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function addProtectedLiquidity(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount,
        uint256 reserveRateN,
        uint256 reserveRateD,
        uint256 timestamp
    ) external returns (uint256);

    function updateProtectedLiquidityAmounts(
        uint256 id,
        uint256 poolNewAmount,
        uint256 reserveNewAmount
    ) external;

    function removeProtectedLiquidity(uint256 id) external;

    function lockedBalance(address provider, uint256 index) external view returns (uint256, uint256);

    function lockedBalanceRange(
        address provider,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (uint256[] memory, uint256[] memory);

    function addLockedBalance(
        address provider,
        uint256 reserveAmount,
        uint256 expirationTime
    ) external returns (uint256);

    function removeLockedBalance(address provider, uint256 index) external;

    function systemBalance(IReserveToken poolToken) external view returns (uint256);

    function incSystemBalance(IReserveToken poolToken, uint256 poolAmount) external;

    function decSystemBalance(IReserveToken poolToken, uint256 poolAmount) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "../../converter/interfaces/IConverterAnchor.sol";

import "../../token/interfaces/IDSToken.sol";
import "../../token/interfaces/IReserveToken.sol";

/**
 * @dev Liquidity Protection Stats interface
 */
interface ILiquidityProtectionStats {
    function increaseTotalAmounts(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) external;

    function decreaseTotalAmounts(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) external;

    function addProviderPool(address provider, IDSToken poolToken) external returns (bool);

    function removeProviderPool(address provider, IDSToken poolToken) external returns (bool);

    function totalPoolAmount(IDSToken poolToken) external view returns (uint256);

    function totalReserveAmount(IDSToken poolToken, IReserveToken reserveToken) external view returns (uint256);

    function totalProviderAmount(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken
    ) external view returns (uint256);

    function providerPools(address provider) external view returns (IDSToken[] memory);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "../../converter/interfaces/IConverterAnchor.sol";

import "../../token/interfaces/IReserveToken.sol";

import "./ILiquidityProvisionEventsSubscriber.sol";

/**
 * @dev Liquidity Protection Settings interface
 */
interface ILiquidityProtectionSettings {
    function isPoolWhitelisted(IConverterAnchor poolAnchor) external view returns (bool);

    function poolWhitelist() external view returns (address[] memory);

    function subscribers() external view returns (address[] memory);

    function isPoolSupported(IConverterAnchor poolAnchor) external view returns (bool);

    function minNetworkTokenLiquidityForMinting() external view returns (uint256);

    function defaultNetworkTokenMintingLimit() external view returns (uint256);

    function networkTokenMintingLimits(IConverterAnchor poolAnchor) external view returns (uint256);

    function addLiquidityDisabled(IConverterAnchor poolAnchor, IReserveToken reserveToken) external view returns (bool);

    function minProtectionDelay() external view returns (uint256);

    function maxProtectionDelay() external view returns (uint256);

    function minNetworkCompensation() external view returns (uint256);

    function lockDuration() external view returns (uint256);

    function averageRateMaxDeviation() external view returns (uint32);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../converter/interfaces/IConverterAnchor.sol";

/**
 * @dev Liquidity Protection System Store interface
 */
interface ILiquidityProtectionSystemStore {
    function systemBalance(IERC20 poolToken) external view returns (uint256);

    function incSystemBalance(IERC20 poolToken, uint256 poolAmount) external;

    function decSystemBalance(IERC20 poolToken, uint256 poolAmount) external;

    function networkTokensMinted(IConverterAnchor poolAnchor) external view returns (uint256);

    function incNetworkTokensMinted(IConverterAnchor poolAnchor, uint256 amount) external;

    function decNetworkTokensMinted(IConverterAnchor poolAnchor, uint256 amount) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev Transfer position event callback interface
 */
interface ITransferPositionCallback {
    function onTransferPosition(
        uint256 newId,
        address provider,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "../../token/interfaces/IReserveToken.sol";

import "./IOwned.sol";

/**
 * @dev Token Holder interface
 */
interface ITokenHolder is IOwned {
    receive() external payable;

    function withdrawTokens(
        IReserveToken reserveToken,
        address payable to,
        uint256 amount
    ) external;

    function withdrawTokensMultiple(
        IReserveToken[] calldata reserveTokens,
        address payable to,
        uint256[] calldata amounts
    ) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "../../converter/interfaces/IConverterAnchor.sol";

import "../../token/interfaces/IReserveToken.sol";

/**
 * @dev Liquidity provision events subscriber interface
 */
interface ILiquidityProvisionEventsSubscriber {
    function onAddingLiquidity(
        address provider,
        IConverterAnchor poolAnchor,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) external;

    function onRemovingLiquidity(
        uint256 id,
        address provider,
        IConverterAnchor poolAnchor,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) external;
}