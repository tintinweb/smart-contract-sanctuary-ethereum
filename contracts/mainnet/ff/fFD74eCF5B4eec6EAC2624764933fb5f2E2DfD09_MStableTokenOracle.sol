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

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MassetStructs.sol";

interface IMasset is IERC20, MassetStructs {
    // Mint
    function mint(
        address _input,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external returns (uint256 mintOutput);

    function mintMulti(
        address[] calldata _inputs,
        uint256[] calldata _inputQuantities,
        uint256 _minOutputQuantity,
        address _recipient
    ) external returns (uint256 mintOutput);

    function getMintOutput(address _input, uint256 _inputQuantity) external view returns (uint256 mintOutput);

    function getMintMultiOutput(address[] calldata _inputs, uint256[] calldata _inputQuantities)
        external
        view
        returns (uint256 mintOutput);

    // Swaps
    function swap(
        address _input,
        address _output,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external returns (uint256 swapOutput);

    function getSwapOutput(
        address _input,
        address _output,
        uint256 _inputQuantity
    ) external view returns (uint256 swapOutput);

    // Redemption
    function redeem(
        address _output,
        uint256 _mAssetQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external returns (uint256 outputQuantity);

    function redeemMasset(
        uint256 _mAssetQuantity,
        uint256[] calldata _minOutputQuantities,
        address _recipient
    ) external returns (uint256[] memory outputQuantities);

    function redeemExactBassets(
        address[] calldata _outputs,
        uint256[] calldata _outputQuantities,
        uint256 _maxMassetQuantity,
        address _recipient
    ) external returns (uint256 mAssetRedeemed);

    function getRedeemOutput(address _output, uint256 _mAssetQuantity) external view returns (uint256 bAssetOutput);

    function getRedeemExactBassetsOutput(address[] calldata _outputs, uint256[] calldata _outputQuantities)
        external
        view
        returns (uint256 mAssetAmount);

    // Views
    function getBasket() external view returns (bool, bool);

    function getBasset(address _token) external view returns (BassetPersonal memory personal, BassetData memory data);

    function getBassets() external view returns (BassetPersonal[] memory personal, BassetData[] memory data);

    function bAssetIndexes(address) external view returns (uint8);

    // SavingsManager
    function collectInterest() external returns (uint256 swapFeesGained, uint256 newSupply);

    function collectPlatformInterest() external returns (uint256 mintAmount, uint256 newSupply);

    // Admin
    function setCacheSize(uint256 _cacheSize) external;

    function upgradeForgeValidator(address _newForgeValidator) external;

    function setFees(uint256 _swapFee, uint256 _redemptionFee) external;

    function setTransferFeesFlag(address _bAsset, bool _flag) external;

    function migrateBassets(address[] calldata _bAssets, address _newIntegration) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ISavingsContractV2 {
    function redeemCredits(uint256 _amount) external returns (uint256 underlyingReturned); // V2

    function exchangeRate() external view returns (uint256); // V1 & V2
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface MassetStructs {
    struct BassetPersonal {
        // Address of the bAsset
        address addr;
        // Address of the bAsset
        address integrator;
        // An ERC20 can charge transfer fee, for example USDT, DGX tokens.
        bool hasTxFee; // takes a byte in storage
        // Status of the bAsset
        BassetStatus status;
    }

    struct BassetData {
        // 1 Basset * ratio / ratioScale == x Masset (relative value)
        // If ratio == 10e8 then 1 bAsset = 10 mAssets
        // A ratio is divised as 10^(18-tokenDecimals) * measurementMultiple(relative value of 1 base unit)
        uint128 ratio;
        // Amount of the Basset that is held in Collateral
        uint128 vaultBalance;
    }

    // Status of the Basset - has it broken its peg?
    enum BassetStatus {
        Default,
        Normal,
        BrokenBelowPeg,
        BrokenAbovePeg,
        Blacklisted,
        Liquidating,
        Liquidated,
        Failed
    }

    struct BasketState {
        bool undergoingRecol;
        bool failed;
    }

    struct InvariantConfig {
        uint256 a;
        WeightLimits limits;
    }

    struct WeightLimits {
        uint128 min;
        uint128 max;
    }

    struct AmpData {
        uint64 initialA;
        uint64 targetA;
        uint64 rampStartTime;
        uint64 rampEndTime;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IOracle {
    /**
     * @notice Get USD (or equivalent) price of an asset
     * @param token_ The address of asset
     * @return _priceInUsd The USD price
     */
    function getPriceInUsd(address token_) external view returns (uint256 _priceInUsd);

    /**
     * @notice Get quote
     * @param tokenIn_ The address of assetIn
     * @param tokenOut_ The address of assetOut
     * @param amountIn_ Amount of input token
     * @return _amountOut Amount out
     */
    function quote(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) external view returns (uint256 _amountOut);

    /**
     * @notice Get quote in USD (or equivalent) amount
     * @param token_ The address of assetIn
     * @param amountIn_ Amount of input token.
     * @return amountOut_ Amount in USD
     */
    function quoteTokenToUsd(address token_, uint256 amountIn_) external view returns (uint256 amountOut_);

    /**
     * @notice Get quote from USD (or equivalent) amount to amount of token
     * @param token_ The address of assetOut
     * @param amountIn_ Input amount in USD
     * @return _amountOut Output amount of token
     */
    function quoteUsdToToken(address token_, uint256 amountIn_) external view returns (uint256 _amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ITokenOracle {
    /**
     * @notice Get USD (or equivalent) price of an asset
     * @param token_ The address of asset
     * @return _priceInUsd The USD price
     */
    function getPriceInUsd(address token_) external view returns (uint256 _priceInUsd);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../../interfaces/external/mstable/IMasset.sol";
import "../../interfaces/external/mstable/ISavingsContractV2.sol";
import "../../interfaces/periphery/IOracle.sol";
import "../../interfaces/periphery/ITokenOracle.sol";

/**
 * @title mStable's tokens oracle
 */
contract MStableTokenOracle is ITokenOracle {
    uint256 private constant RATIO_DENOMINATOR = 1e8;

    IMasset public constant MUSD = IMasset(0xe2f2a5C287993345a840Db3B0845fbC70f5935a5);
    ISavingsContractV2 public constant IMUSD = ISavingsContractV2(0x30647a72Dc82d7Fbb1123EA74716aB8A317Eac19);
    IMasset public constant MBTC = IMasset(0x945Facb997494CC2570096c74b5F66A3507330a1);
    ISavingsContractV2 public constant IMBTC = ISavingsContractV2(0x17d8CBB6Bce8cEE970a4027d1198F6700A7a6c24);

    /// @inheritdoc ITokenOracle
    function getPriceInUsd(address mAsset_) external view returns (uint256) {
        if (mAsset_ == address(MUSD)) return _mAssetUsdPrice(MUSD);
        if (mAsset_ == address(IMUSD)) return (IMUSD.exchangeRate() * _mAssetUsdPrice(MUSD)) / 1e18;
        if (mAsset_ == address(MBTC)) return _mAssetUsdPrice(MBTC);
        if (mAsset_ == address(IMBTC)) return (IMBTC.exchangeRate() * _mAssetUsdPrice(MBTC)) / 1e18;

        revert("invalid-token");
    }

    /// @notice Return mAsset price
    /// @dev Uses the `MasterOracle` (msg.sender) to get underlying assets' prices
    function _mAssetUsdPrice(IMasset mAsset_) private view returns (uint256) {
        (IMasset.BassetPersonal[] memory bAssetPersonal, IMasset.BassetData[] memory bAssetData) = mAsset_.getBassets();
        uint256 _totalValue;
        uint256 _len = bAssetData.length;
        for (uint256 i; i < _len; i++) {
            _totalValue +=
                ((uint256(bAssetData[i].vaultBalance * bAssetData[i].ratio)) / RATIO_DENOMINATOR) *
                // Note: `msg.sender` is the `MasterOracle` contract
                IOracle(msg.sender).getPriceInUsd(bAssetPersonal[i].addr);
        }

        return _totalValue / mAsset_.totalSupply();
    }
}