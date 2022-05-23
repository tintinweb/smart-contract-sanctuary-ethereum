// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./BalancerSampler.sol";
import "./BalancerV2Sampler.sol";
import "./CurveSampler.sol";
import "./DODOSampler.sol";
import "./DODOV2Sampler.sol";
import "./UniswapV2Sampler.sol";
import "./UniswapV3Sampler.sol";
import "./MakerPSMSampler.sol";
// import "./BancorSampler.sol";
// import "./KyberSampler.sol";
import "./NativeOrderSampler.sol";
//import "./KyberDmmSampler.sol";

contract ERC20BridgeSampler is
    BalancerSampler,
    BalancerV2Sampler,
    CurveSampler,
    DODOSampler,
    DODOV2Sampler,
    UniswapV2Sampler,
    UniswapV3Sampler,
    MakerPSMSampler,
    // BancorSampler,
    // KyberSampler,
    //KyberDmmSampler,
    NativeOrderSampler
{
    struct CallResults {
        bytes data;
        bool success;
    }

    /// @dev Call multiple public functions on this contract in a single transaction.
    /// @param callDatas ABI-encoded call data for each function call.
    /// @return callResults ABI-encoded results data for each call.
    function batchCall(bytes[] calldata callDatas)
        external
        returns (CallResults[] memory callResults)
    {
        callResults = new CallResults[](callDatas.length);
        for (uint256 i = 0; i != callDatas.length; ++i) {
            callResults[i].success = true;
            if (callDatas[i].length == 0) {
                continue;
            }
            (callResults[i].success, callResults[i].data) = address(this).call(
                callDatas[i]
            );
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

interface IExchange {
    enum OrderStatus {
        INVALID,
        FILLABLE,
        FILLED,
        CANCELLED,
        EXPIRED
    }

    /// @dev A standard OTC or OO limit order.
    struct LimitOrder {
        IERC20 makerToken;
        IERC20 takerToken;
        uint128 makerAmount;
        uint128 takerAmount;
        uint128 takerTokenFeeAmount;
        address maker;
        address taker;
        address sender;
        address feeRecipient;
        bytes32 pool;
        uint64 expiry;
        uint256 salt;
    }

    /// @dev Info on a limit or RFQ order.
    struct OrderInfo {
        bytes32 orderHash;
        OrderStatus status;
        uint128 takerTokenFilledAmount;
    }

    /// @dev Allowed signature types.
    enum SignatureType {
        ILLEGAL,
        INVALID,
        EIP712,
        ETHSIGN
    }

    /// @dev Encoded EC signature.
    struct Signature {
        // How to validate the signature.
        SignatureType signatureType;
        // EC Signature data.
        uint8 v;
        // EC Signature data.
        bytes32 r;
        // EC Signature data.
        bytes32 s;
    }

    /// @dev Get order info, fillable amount, and signature validity for a limit order.
    ///      Fillable amount is determined using balances and allowances of the maker.
    /// @param order The limit order.
    /// @param signature The order signature.
    /// @return orderInfo Info about the order.
    /// @return actualFillableTakerTokenAmount How much of the order is fillable
    ///         based on maker funds, in taker tokens.
    /// @return isSignatureValid Whether the signature is valid.
    function getLimitOrderRelevantState(
        LimitOrder memory order,
        Signature calldata signature
    )
        external
        view
        returns (
            OrderInfo memory orderInfo,
            uint128 actualFillableTakerTokenAmount,
            bool isSignatureValid
        );
}

contract NativeOrderSampler {
    using SafeMath for uint256;
    using Math for uint256;

    /// @dev Gas limit for calls to `getOrderFillableTakerAmount()`.
    uint256 internal constant DEFAULT_CALL_GAS = 200e3; // 200k

    /// @dev Queries the fillable taker asset amounts of native orders.
    ///      Effectively ignores orders that have empty signatures or
    ///      maker/taker asset amounts (returning 0).
    /// @param orders Native limit orders to query.
    /// @param orderSignatures Signatures for each respective order in `orders`.
    /// @param exchange The V4 exchange.
    /// @return orderFillableTakerAssetAmounts How much taker asset can be filled
    ///         by each order in `orders`.
    function getLimitOrderFillableTakerAssetAmounts(
        IExchange.LimitOrder[] memory orders,
        IExchange.Signature[] memory orderSignatures,
        IExchange exchange
    ) public view returns (uint256[] memory orderFillableTakerAssetAmounts) {
        orderFillableTakerAssetAmounts = new uint256[](orders.length);
        for (uint256 i = 0; i != orders.length; i++) {
            try
                this.getLimitOrderFillableTakerAmount{gas: DEFAULT_CALL_GAS}(
                    orders[i],
                    orderSignatures[i],
                    exchange
                )
            returns (uint256 amount) {
                orderFillableTakerAssetAmounts[i] = amount;
            } catch (bytes memory) {
                // Swallow failures, leaving all results as zero.
                orderFillableTakerAssetAmounts[i] = 0;
            }
        }
    }

    /// @dev Queries the fillable taker asset amounts of native orders.
    ///      Effectively ignores orders that have empty signatures or
    /// @param orders Native orders to query.
    /// @param orderSignatures Signatures for each respective order in `orders`.
    /// @param exchange The V4 exchange.
    /// @return orderFillableMakerAssetAmounts How much maker asset can be filled
    ///         by each order in `orders`.
    function getLimitOrderFillableMakerAssetAmounts(
        IExchange.LimitOrder[] memory orders,
        IExchange.Signature[] memory orderSignatures,
        IExchange exchange
    ) public view returns (uint256[] memory orderFillableMakerAssetAmounts) {
        orderFillableMakerAssetAmounts = getLimitOrderFillableTakerAssetAmounts(
            orders,
            orderSignatures,
            exchange
        );
        // `orderFillableMakerAssetAmounts` now holds taker asset amounts, so
        // convert them to maker asset amounts.
        for (uint256 i = 0; i < orders.length; ++i) {
            if (orderFillableMakerAssetAmounts[i] != 0) {
                orderFillableMakerAssetAmounts[
                    i
                ] = orderFillableMakerAssetAmounts[i]
                    .mul(orders[i].makerAmount)
                    .ceilDiv(orders[i].takerAmount);
            }
        }
    }

    /// @dev Get the fillable taker amount of an order, taking into account
    ///      order state, maker fees, and maker balances.
    function getLimitOrderFillableTakerAmount(
        IExchange.LimitOrder memory order,
        IExchange.Signature memory signature,
        IExchange exchange
    ) public view virtual returns (uint256 fillableTakerAmount) {
        if (
            signature.signatureType == IExchange.SignatureType.ILLEGAL ||
            signature.signatureType == IExchange.SignatureType.INVALID ||
            order.makerAmount == 0 ||
            order.takerAmount == 0
        ) {
            return 0;
        }

        (
            IExchange.OrderInfo memory orderInfo,
            uint128 remainingFillableTakerAmount,
            bool isSignatureValid
        ) = exchange.getLimitOrderRelevantState(order, signature);

        if (
            orderInfo.status != IExchange.OrderStatus.FILLABLE ||
            !isSignatureValid ||
            order.makerToken == IERC20(address(0))
        ) {
            return 0;
        }

        fillableTakerAmount = uint256(remainingFillableTakerAmount);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IPSM {
    // @dev Get the fee for selling USDC to DAI in PSM
    // @return tin toll in [wad]
    function tin() external view returns (uint256);

    // @dev Get the fee for selling DAI to USDC in PSM
    // @return tout toll out [wad]
    function tout() external view returns (uint256);

    // @dev Get the address of the PSM state Vat
    // @return address of the Vat
    function vat() external view returns (address);

    // @dev Get the address of the underlying vault powering PSM
    // @return address of gemJoin contract
    function gemJoin() external view returns (address);

    // @dev Get the address of DAI
    // @return address of DAI contract
    function dai() external view returns (address);

    // @dev Sell USDC for DAI
    // @param usr The address of the account trading USDC for DAI.
    // @param gemAmt The amount of USDC to sell in USDC base units
    function sellGem(address usr, uint256 gemAmt) external;

    // @dev Buy USDC for DAI
    // @param usr The address of the account trading DAI for USDC
    // @param gemAmt The amount of USDC to buy in USDC base units
    function buyGem(address usr, uint256 gemAmt) external;
}

interface IVAT {
    // @dev Get a collateral type by identifier
    // @param ilkIdentifier bytes32 identifier. Example: ethers.utils.formatBytes32String("PSM-USDC-A")
    // @return ilk
    // @return ilk.Art Total Normalised Debt in wad
    // @return ilk.rate Accumulated Rates in ray
    // @return ilk.spot Price with Safety Margin in ray
    // @return ilk.line Debt Ceiling in rad
    // @return ilk.dust Urn Debt Floor in rad
    function ilks(bytes32 ilkIdentifier)
        external
        view
        returns (
            uint256 Art,
            uint256 rate,
            uint256 spot,
            uint256 line,
            uint256 dust
        );
}

contract MakerPSMSampler {
    using SafeMath for uint256;

    /// @dev Information about which PSM module to use
    struct MakerPsmInfo {
        address psmAddress;
        bytes32 ilkIdentifier;
        address gemTokenAddress;
    }

    /// @dev Gas limit for MakerPsm calls.
    uint256 private constant MAKER_PSM_CALL_GAS = 300e3; // 300k

    // Maker units
    // wad: fixed point decimal with 18 decimals (for basic quantities, e.g. balances)
    uint256 private constant WAD = 10**18;
    // ray: fixed point decimal with 27 decimals (for precise quantites, e.g. ratios)
    uint256 private constant RAY = 10**27;
    // rad: fixed point decimal with 45 decimals (result of integer multiplication with a wad and a ray)
    uint256 private constant RAD = 10**45;

    // See https://github.com/makerdao/dss/blob/master/DEVELOPING.m

    /// @dev Sample sell quotes from Maker PSM
    function sampleSellsFromMakerPsm(
        MakerPsmInfo memory psmInfo,
        address takerToken,
        address makerToken,
        uint256[] memory takerTokenAmounts
    ) public view returns (uint256[] memory makerTokenAmounts) {
        IPSM psm = IPSM(psmInfo.psmAddress);
        IVAT vat = IVAT(psm.vat());

        uint256 numSamples = takerTokenAmounts.length;
        makerTokenAmounts = new uint256[](numSamples);

        if (makerToken != psm.dai() && takerToken != psm.dai()) {
            return makerTokenAmounts;
        }

        for (uint256 i = 0; i < numSamples; i++) {
            uint256 buyAmount = _samplePSMSell(
                psmInfo,
                makerToken,
                takerToken,
                takerTokenAmounts[i],
                psm,
                vat
            );

            if (buyAmount == 0) {
                break;
            }
            makerTokenAmounts[i] = buyAmount;
        }
    }

    function _samplePSMSell(
        MakerPsmInfo memory psmInfo,
        address makerToken,
        address takerToken,
        uint256 takerTokenAmount,
        IPSM psm,
        IVAT vat
    ) private view returns (uint256) {
        (
            uint256 totalDebtInWad,
            ,
            ,
            uint256 debtCeilingInRad,
            uint256 debtFloorInRad
        ) = vat.ilks(psmInfo.ilkIdentifier);
        uint256 gemTokenBaseUnit = uint256(1e6);

        if (takerToken == psmInfo.gemTokenAddress) {
            // Simulate sellGem
            // Selling USDC to the PSM, increasing the total debt
            // Convert USDC 6 decimals to 18 decimals [wad]
            uint256 takerTokenAmountInWad = takerTokenAmount.mul(1e12);

            uint256 newTotalDebtInRad = totalDebtInWad
                .add(takerTokenAmountInWad)
                .mul(RAY);

            // PSM is too full to fit
            if (newTotalDebtInRad >= debtCeilingInRad) {
                return 0;
            }

            uint256 feeInWad = takerTokenAmountInWad.mul(psm.tin()).div(WAD);
            uint256 makerTokenAmountInWad = takerTokenAmountInWad.sub(feeInWad);

            return makerTokenAmountInWad;
        } else if (makerToken == psmInfo.gemTokenAddress) {
            // Simulate buyGem
            // Buying USDC from the PSM, decreasing the total debt
            // Selling DAI for USDC, already in 18 decimals [wad]
            uint256 takerTokenAmountInWad = takerTokenAmount;
            if (takerTokenAmountInWad > totalDebtInWad) {
                return 0;
            }
            uint256 newTotalDebtInRad = totalDebtInWad
                .sub(takerTokenAmountInWad)
                .mul(RAY);

            // PSM is empty, not enough USDC to buy from it
            if (newTotalDebtInRad <= debtFloorInRad) {
                return 0;
            }

            uint256 feeDivisorInWad = WAD.add(psm.tout()); // eg. 1.001 * 10 ** 18 with 0.1% tout;
            uint256 makerTokenAmountInGemTokenBaseUnits = takerTokenAmountInWad
                .mul(gemTokenBaseUnit)
                .div(feeDivisorInWad);

            return makerTokenAmountInGemTokenBaseUnits;
        }

        return 0;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IUniswapV3Quoter {
    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }
        function quoteExactInputSingle(QuoteExactInputSingleParams memory params)
        external returns (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );
}

interface IUniswapV3Pool {
    function fee() external view returns (uint24);
}

contract UniswapV3Sampler {
    /// @dev Gas limit for UniswapV3 calls. This is 100% a guess.
    uint256 private constant QUOTE_GAS = 300e3;
    struct UniswapV3SamplerOpts{
        IUniswapV3Quoter quoter;
        IUniswapV3Pool pool;
    }

    /// @dev Sample sell quotes from UniswapV3.
    /// @param opts UniswapV3Sampler Quoter contract.
    /// @param takerTokenAmounts Taker token sell amount for each sample.
    /// @return makerTokenAmounts Maker amounts bought at each taker token
    ///         amount.
    function sampleSellsFromUniswapV3(
        UniswapV3SamplerOpts memory opts,
        address takerToken,
        address makerToken,
        uint256[] memory takerTokenAmounts
    ) public returns (uint256[] memory makerTokenAmounts) {
        makerTokenAmounts = new uint256[](takerTokenAmounts.length);

        uint24 fee = opts.pool.fee();
        for (uint256 i = 0; i < takerTokenAmounts.length; ++i) {
            // Pick the best result from all the paths.
            (uint256 topBuyAmount, , ,) = opts.quoter.quoteExactInputSingle{gas: QUOTE_GAS}(
                IUniswapV3Quoter.QuoteExactInputSingleParams({
                        tokenIn: takerToken,
                        tokenOut: makerToken,
                        fee: fee,
                        amountIn: takerTokenAmounts[i],
                        sqrtPriceLimitX96: 0
                    })
            );
            // Break early if we can't complete the buys.
            if (topBuyAmount == 0) {
                break;
            }
            makerTokenAmounts[i] = topBuyAmount;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IUniswapV2Router01.sol";

contract UniswapV2Sampler {
    /// @dev Gas limit for UniswapV2 calls.
    uint256 private constant UNISWAPV2_CALL_GAS = 150e3; // 150k

    /// @dev Sample sell quotes from UniswapV2.
    /// @param router Router to look up tokens and amounts
    /// @param path Token route. Should be takerToken -> makerToken
    /// @param takerTokenAmounts Taker token sell amount for each sample.
    /// @return makerTokenAmounts Maker amounts bought at each taker token
    ///         amount.
    function sampleSellsFromUniswapV2(
        address router,
        address[] memory path,
        uint256[] memory takerTokenAmounts
    ) public view returns (uint256[] memory makerTokenAmounts) {
        uint256 numSamples = takerTokenAmounts.length;
        makerTokenAmounts = new uint256[](numSamples);
        for (uint256 i = 0; i < numSamples; i++) {
            try
                IUniswapV2Router01(router).getAmountsOut{
                    gas: UNISWAPV2_CALL_GAS
                }(takerTokenAmounts[i], path)
            returns (uint256[] memory amounts) {
                makerTokenAmounts[i] = amounts[path.length - 1];
                // Break early if there are 0 amounts
                if (makerTokenAmounts[i] == 0) {
                    break;
                }
            } catch (bytes memory) {
                // Swallow failures, leaving all results as zero.
                break;
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IDODOV2Registry {
    function getDODOPool(address baseToken, address quoteToken)
        external
        view
        returns (address[] memory machines);
}

interface IDODOV2Pool {
    function querySellBase(address trader, uint256 payBaseAmount)
        external
        view
        returns (uint256 receiveQuoteAmount, uint256 mtFee);

    function querySellQuote(address trader, uint256 payQuoteAmount)
        external
        view
        returns (uint256 receiveBaseAmount, uint256 mtFee);
}

contract DODOV2Sampler {
    /// @dev Gas limit for DODO V2 calls.
    uint256 private constant DODO_V2_CALL_GAS = 300e3; // 300k
    struct DODOV2SamplerOpts {
        address pool;
        bool sellBase;
    }

    /// @dev Sample sell quotes from DODO V2.
    /// @param opts dodov2 sampler options.
    /// @param takerTokenAmounts Taker token sell amount for each sample.
    /// @return makerTokenAmounts Maker amounts bought at each taker token
    ///         amount.
    function sampleSellsFromDODOV2(
        DODOV2SamplerOpts memory opts,
        address ,
        address ,
        uint256[] memory takerTokenAmounts
    ) public view returns (uint256[] memory makerTokenAmounts) {

        uint256 numSamples = takerTokenAmounts.length;
        makerTokenAmounts = new uint256[](numSamples);

        for (uint256 i = 0; i < numSamples; i++) {
            if (opts.sellBase) {
                (makerTokenAmounts[i], ) = IDODOV2Pool(opts.pool).querySellBase{
                    gas: DODO_V2_CALL_GAS
                }(address(0), takerTokenAmounts[i]);
            } else {
                (makerTokenAmounts[i], ) = IDODOV2Pool(opts.pool)
                    .querySellQuote{gas: DODO_V2_CALL_GAS}(
                    address(0),
                    takerTokenAmounts[i]
                );
            }
            // Break early if there are 0 amounts
            if (makerTokenAmounts[i] == 0) {
                break;
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IDODOZoo {
    function getDODO(address baseToken, address quoteToken)
        external
        view
        returns (address);
}

interface IDODOHelper {
    function querySellQuoteToken(address dodo, uint256 amount)
        external
        view
        returns (uint256);
}

interface IDODO {
    function querySellBaseToken(uint256 amount) external view returns (uint256);

    function _TRADE_ALLOWED_() external view returns (bool);
}

contract DODOSampler {
    /// @dev Gas limit for DODO calls.
    uint256 private constant DODO_CALL_GAS = 300e3; // 300k
    struct DODOSamplerOpts {
        address pool;
        bool sellBase;
        address helper;
    }

    /// @dev Sample sell quotes from DODO.
    /// @param opts DODOSamplerOpts DODO Registry and helper addresses
    /// @param takerTokenAmounts Taker token sell amount for each sample.
    /// @return makerTokenAmounts Maker amounts bought at each taker token
    ///         amount.
    function sampleSellsFromDODO(
        DODOSamplerOpts memory opts,
        address ,
        address ,
        uint256[] memory takerTokenAmounts
    ) public view returns (uint256[] memory makerTokenAmounts) {
        uint256 numSamples = takerTokenAmounts.length;
        makerTokenAmounts = new uint256[](numSamples);

        // DODO Pool has been disabled
        if (!IDODO(opts.pool)._TRADE_ALLOWED_()) {
            return makerTokenAmounts;
        }

        for (uint256 i = 0; i < numSamples; i++) {
            if (opts.sellBase) {
                makerTokenAmounts[i] = IDODO(opts.pool).querySellBaseToken{
                    gas: DODO_CALL_GAS
                }(takerTokenAmounts[i]);
            } else {
                makerTokenAmounts[i] = IDODOHelper(opts.helper)
                    .querySellQuoteToken{gas: DODO_CALL_GAS}(
                    opts.pool,
                    takerTokenAmounts[i]
                );
            }
            // Break early if there are 0 amounts
            if (makerTokenAmounts[i] == 0) {
                break;
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./interfaces/ICurve.sol";

interface CurvePool {
    function get_dy_underlying(
        int128,
        int128,
        uint256
    ) external view returns (uint256);

    function get_dy(
        int128,
        int128,
        uint256
    ) external view returns (uint256);
}

interface CryptoPool {
    function get_dy_underlying(
        uint256,
        uint256,
        uint256
    ) external view returns (uint256);

    function get_dy(
        uint256,
        uint256,
        uint256
    ) external view returns (uint256);
}

interface CryptoRegistry {
    function get_coin_indices(
        address pool,
        address from,
        address to
    ) external view returns (uint256, uint256);
}

interface CurveRegistry {
    function get_coin_indices(
        address pool,
        address from,
        address to
    )
        external
        view
        returns (
            int128,
            int128,
            bool
        );
}

contract CurveSampler {
    /// @dev Information for sampling from curve sources.

    /// @dev Base gas limit for Curve calls. Some Curves have multiple tokens
    ///      So a reasonable ceil is 150k per token. Biggest Curve has 4 tokens.
    uint256 private constant CURVE_CALL_GAS = 2000e3; // Was 600k for Curve but SnowSwap is using 1500k+
    address private constant CURVE_REGISTRY =
        0x90E00ACe148ca3b23Ac1bC8C240C2a7Dd9c2d7f5;
    address private constant CURVE_FACTORY =
        0xB9fC157394Af804a3578134A6585C0dc9cc990d4;
    address private constant CRYPTO_REGISTRY =
        0x8F942C20D02bEfc377D41445793068908E2250D0;
    address private constant CRYPTO_FACTORY =
        0xF18056Bbd320E96A48e3Fbf8bC061322531aac99;

    /// @dev Sample sell quotes from Curve.
    /// @param poolAddress Curve information specific to this token pair.
    /// @param fromToken Index of the taker token (what to sell).
    /// @param toToken Index of the maker token (what to buy).
    /// @param takerTokenAmounts Taker token sell amount for each sample.
    /// @return makerTokenAmounts Maker amounts bought at each taker token
    ///         amount.
    function sampleSellsFromCurve(
        address poolAddress,
        address fromToken,
        address toToken,
        uint256[] memory takerTokenAmounts
    ) public view returns (uint256[] memory makerTokenAmounts) {
        uint256 numSamples = takerTokenAmounts.length;
        makerTokenAmounts = new uint256[](numSamples);
        for (uint256 i = 0; i < numSamples; i++) {
            (
                uint256 fromTokenIdx,
                uint256 toTokenIdx,
                bool useUnderlying
            ) = getCoinIndices(poolAddress, fromToken, toToken);
            bytes4 selector;
            bytes4 selectorV2;
            if (useUnderlying) {
                selector = CurvePool.get_dy_underlying.selector;
                selectorV2 = CryptoPool.get_dy_underlying.selector;
            } else {
                selector = CurvePool.get_dy.selector;
                selectorV2 = CryptoPool.get_dy.selector;
            }
            uint256 buyAmount = 0;
            if (useUnderlying) {
                buyAmount = getBuyAmountUnderlying(
                    poolAddress,
                    fromTokenIdx,
                    toTokenIdx,
                    takerTokenAmounts[i]
                );
            } else {
                buyAmount = getBuyAmount(
                    poolAddress,
                    fromTokenIdx,
                    toTokenIdx,
                    takerTokenAmounts[i]
                );
            }

            makerTokenAmounts[i] = buyAmount;
            // Break early if there are 0 amounts
            if (makerTokenAmounts[i] == 0) {
                break;
            }
        }
    }

    function getCoinIndices(
        address poolAddress,
        address fromToken,
        address toToken
    )
        internal
        view
        returns (
            uint256 fromTokenIdx,
            uint256 toTokenIdx,
            bool useUnderlying
        )
    {
        useUnderlying = false;
        // getinfo from registry or factory
        (bool success0, bytes memory resultDatas0) = CURVE_REGISTRY.staticcall(
            abi.encodeWithSelector(
                CurveRegistry.get_coin_indices.selector,
                poolAddress,
                fromToken,
                toToken
            )
        );
        (bool success1, bytes memory resultDatas1) = CURVE_FACTORY.staticcall(
            abi.encodeWithSelector(
                CurveRegistry.get_coin_indices.selector,
                poolAddress,
                fromToken,
                toToken
            )
        );
        (bool success2, bytes memory resultDatas2) = CRYPTO_REGISTRY.staticcall(
            abi.encodeWithSelector(
                CryptoRegistry.get_coin_indices.selector,
                poolAddress,
                fromToken,
                toToken
            )
        );
        (bool success3, bytes memory resultDatas3) = CRYPTO_FACTORY.staticcall(
            abi.encodeWithSelector(
                CryptoRegistry.get_coin_indices.selector,
                poolAddress,
                fromToken,
                toToken
            )
        );
        if (success0) {
            (
                int128 _fromTokenIdx,
                int128 _toTokenIdx,
                bool _useUnderlying
            ) = abi.decode(resultDatas0, (int128, int128, bool));
            fromTokenIdx = uint256(int256(_fromTokenIdx));
            toTokenIdx = uint256(int256(_toTokenIdx));
            useUnderlying = _useUnderlying;
        } else if (success1) {
            (
                int128 _fromTokenIdx,
                int128 _toTokenIdx,
                bool _useUnderlying
            ) = abi.decode(resultDatas1, (int128, int128, bool));
            fromTokenIdx = uint256(int256(_fromTokenIdx));
            toTokenIdx = uint256(int256(_toTokenIdx));
            useUnderlying = _useUnderlying;
        } else if (success2) {
            (fromTokenIdx, toTokenIdx) = abi.decode(
                resultDatas2,
                (uint256, uint256)
            );
        } else {
            require(success3, "getCoinIndices Error");
            (fromTokenIdx, toTokenIdx) = abi.decode(
                resultDatas3,
                (uint256, uint256)
            );
        }
    }

    function getBuyAmount(
        address poolAddress,
        uint256 fromTokenIdx,
        uint256 toTokenIdx,
        uint256 sellAmount
    ) internal view returns (uint256 buyAmount) {
        try
            CryptoPool(poolAddress).get_dy(fromTokenIdx, toTokenIdx, sellAmount)
        returns (uint256 _buyAmount) {
            buyAmount = _buyAmount;
        } catch {
            int128 _fromTokenIdx = int128(int256(fromTokenIdx));
            int128 _toTokenIdx = int128(int256(toTokenIdx));
            buyAmount = CurvePool(poolAddress).get_dy(
                _fromTokenIdx,
                _toTokenIdx,
                sellAmount
            );
        }
    }

    function getBuyAmountUnderlying(
        address poolAddress,
        uint256 fromTokenIdx,
        uint256 toTokenIdx,
        uint256 sellAmount
    ) internal view returns (uint256 buyAmount) {
        try
            CryptoPool(poolAddress).get_dy_underlying(
                fromTokenIdx,
                toTokenIdx,
                sellAmount
            )
        returns (uint256 _buyAmount) {
            buyAmount = _buyAmount;
        } catch {
            int128 _fromTokenIdx = int128(int256(fromTokenIdx));
            int128 _toTokenIdx = int128(int256(toTokenIdx));
            buyAmount = CurvePool(poolAddress).get_dy_underlying(
                _fromTokenIdx,
                _toTokenIdx,
                sellAmount
            );
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/// @dev Minimal Balancer V2 Vault interface
///      for documentation refer to https://github.com/balancer-labs/balancer-core-v2/blob/master/contracts/vault/interfaces/IVault.sol
interface IBalancerV2Vault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] calldata swaps,
        IAsset[] calldata assets,
        FundManagement calldata funds
    ) external returns (int256[] memory assetDeltas);
}

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

interface IPool{
    function getPoolId()external view returns (bytes32);
}

contract BalancerV2Sampler {
    struct BalancerV2PoolInfo {
        address pool;
        address vault;
    }

    /// @dev Sample sell quotes from Balancer V2.
    /// @param poolInfo Struct with pool related data
    /// @param takerToken Address of the taker token (what to sell).
    /// @param makerToken Address of the maker token (what to buy).
    /// @param takerTokenAmounts Taker token sell amount for each sample.
    /// @return makerTokenAmounts Maker amounts bought at each taker token
    ///         amount.
    function sampleSellsFromBalancerV2(
        BalancerV2PoolInfo memory poolInfo,
        address takerToken,
        address makerToken,
        uint256[] memory takerTokenAmounts
    ) public returns (uint256[] memory makerTokenAmounts) {
        IBalancerV2Vault vault = IBalancerV2Vault(poolInfo.vault);
        IAsset[] memory swapAssets = new IAsset[](2);
        swapAssets[0] = IAsset(takerToken);
        swapAssets[1] = IAsset(makerToken);

        uint256 numSamples = takerTokenAmounts.length;
        makerTokenAmounts = new uint256[](numSamples);
        IBalancerV2Vault.FundManagement memory swapFunds = createSwapFunds();

        for (uint256 i = 0; i < numSamples; i++) {
            IBalancerV2Vault.BatchSwapStep[] memory swapSteps = createSwapSteps(
                poolInfo,
                takerTokenAmounts[i]
            );

            // For sells we specify the takerToken which is what the vault will receive from the trade
            int256[] memory amounts = vault.queryBatchSwap(
                IBalancerV2Vault.SwapKind.GIVEN_IN,
                swapSteps,
                swapAssets,
                swapFunds
            );
            int256 amountOutFromPool = amounts[1] * -1;
            if (amountOutFromPool <= 0) {
                break;
            }
            makerTokenAmounts[i] = uint256(amountOutFromPool);
        }
    }

    function createSwapSteps(BalancerV2PoolInfo memory poolInfo, uint256 amount)
        private
        view
        returns (IBalancerV2Vault.BatchSwapStep[] memory)
    {
        IBalancerV2Vault.BatchSwapStep[]
            memory swapSteps = new IBalancerV2Vault.BatchSwapStep[](1);

        bytes32 poolId = IPool(poolInfo.pool).getPoolId();
        swapSteps[0] = IBalancerV2Vault.BatchSwapStep({
            poolId: poolId,
            assetInIndex: 0,
            assetOutIndex: 1,
            amount: amount,
            userData: ""
        });

        return swapSteps;
    }

    function createSwapFunds()
        private
        view
        returns (IBalancerV2Vault.FundManagement memory)
    {
        return
            IBalancerV2Vault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            });
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IBalancer.sol";

contract BalancerSampler {
    /// @dev Base gas limit for Balancer calls.
    uint256 private constant BALANCER_CALL_GAS = 300e3; // 300k

    // Balancer math constants
    // https://github.com/balancer-labs/balancer-core/blob/master/contracts/BConst.sol
    uint256 private constant BONE = 10**18;
    uint256 private constant MAX_IN_RATIO = BONE / 2;
    uint256 private constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;

    struct BalancerState {
        uint256 takerTokenBalance;
        uint256 makerTokenBalance;
        uint256 takerTokenWeight;
        uint256 makerTokenWeight;
        uint256 swapFee;
    }

    /// @dev Sample sell quotes from Balancer.
    /// @param poolAddress Address of the Balancer pool to query.
    /// @param takerToken Address of the taker token (what to sell).
    /// @param makerToken Address of the maker token (what to buy).
    /// @param takerTokenAmounts Taker token sell amount for each sample.
    /// @return makerTokenAmounts Maker amounts bought at each taker token
    ///         amount.
    function sampleSellsFromBalancer(
        address poolAddress,
        address takerToken,
        address makerToken,
        uint256[] memory takerTokenAmounts
    ) public view returns (uint256[] memory makerTokenAmounts) {
        IBalancer pool = IBalancer(poolAddress);
        uint256 numSamples = takerTokenAmounts.length;
        makerTokenAmounts = new uint256[](numSamples);
        if (!pool.isBound(takerToken) || !pool.isBound(makerToken)) {
            return makerTokenAmounts;
        }

        BalancerState memory poolState;
        poolState.takerTokenBalance = pool.getBalance(takerToken);
        poolState.makerTokenBalance = pool.getBalance(makerToken);
        poolState.takerTokenWeight = pool.getDenormalizedWeight(takerToken);
        poolState.makerTokenWeight = pool.getDenormalizedWeight(makerToken);
        poolState.swapFee = pool.getSwapFee();

        for (uint256 i = 0; i < numSamples; i++) {
            makerTokenAmounts[i] = pool.calcOutGivenIn{gas: BALANCER_CALL_GAS}(
                poolState.takerTokenBalance,
                poolState.takerTokenWeight,
                poolState.makerTokenBalance,
                poolState.makerTokenWeight,
                takerTokenAmounts[i],
                poolState.swapFee
            );
            // Break early if there are 0 amounts
            if (makerTokenAmounts[i] == 0) {
                break;
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.0;

// solhint-disable func-name-mixedcase
interface ICurve {
    /// @dev Sell `sellAmount` of `fromToken` token and receive `toToken` token.
    ///      This function exists on later versions of Curve (USDC/DAI/USDT)
    /// @param i The token index being sold.
    /// @param j The token index being bought.
    /// @param sellAmount The amount of token being bought.
    /// @param minBuyAmount The minimum buy amount of the token being bought.
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) external;

    /// @dev Get the amount of `toToken` by selling `sellAmount` of `fromToken`
    /// @param i The token index being sold.
    /// @param j The token index being bought.
    /// @param sellAmount The amount of token being bought.
    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 sellAmount
    ) external returns (uint256 dy);

    /// @dev Get the amount of `fromToken` by buying `buyAmount` of `toToken`
    ///      This function exists on later versions of Curve (USDC/DAI/USDT)
    /// @param i The token index being sold.
    /// @param j The token index being bought.
    /// @param buyAmount The amount of token being bought.
    function get_dx_underlying(
        int128 i,
        int128 j,
        uint256 buyAmount
    ) external returns (uint256 dx);

    /// @dev Get the underlying token address from the token index
    /// @param i The token index.
    function underlying_coins(int128 i) external returns (address tokenAddress);
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.0;

interface IBalancer {
    function isBound(address t) external view returns (bool);

    function getDenormalizedWeight(address token)
        external
        view
        returns (uint256);

    function getBalance(address token) external view returns (uint256);

    function getSwapFee() external view returns (uint256);

    function calcOutGivenIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);

    function calcInGivenOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountIn);
}