// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LibPriceConsumer} from "./LibPriceConsumer.sol";
import {LibPriceConsumerStorage} from "./LibPriceConsumerStorage.sol";
import {LibClaimTokenStorage} from "./../../facets/claimtoken/LibClaimTokenStorage.sol";
import {LibProtocolStorage} from "./../../facets/protocolRegistry/LibProtocolStorage.sol";
import {Modifiers} from "./../../shared/libraries/LibAppStorage.sol";
import {LibMeta} from "./../../shared/libraries/LibMeta.sol";
import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import "./../../interfaces/IDexFactory.sol";
import {IDexPair} from "./../../interfaces/IDexPair.sol";
import "./../../interfaces/IERC20Extras.sol";
import "./../../interfaces/IPriceConsumer.sol";
import "./../../interfaces/IUniswapV2Router02.sol";
import "./../../interfaces/IProtocolRegistry.sol";
import "./../../interfaces/IClaimToken.sol";

/// @dev contract for getting the price of ERC20 tokens from the chainlink and AMM Dexes like uniswap etc..
contract PriceConsumerFacet is Modifiers {
    function priceConsumerFacetInit(address _swapRouterv2) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        require(msg.sender == ds.contractOwner, "Must own the contract.");

        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();

        es.swapRouterv2 = IUniswapV2Router02(_swapRouterv2);
    }

    /// @dev Adds a new token for which getLatestUsdPrice or getLatestUsdPrices can be called.
    /// param _tokenAddress The new token for price feed.
    /// param _chainlinkFeedAddress chainlink feed address
    /// param _enabled    if true then enabled
    /// param _decimals decimals of the chainlink price feed

    function addTokenChainlinkFeed(
        address _tokenAddress,
        address _chainlinkFeedAddress,
        bool _enabled,
        uint256 _decimals
    ) public onlyAddTokenRole(LibMeta.msgSender()) {
        require(
            !LibPriceConsumer._isAddedChainlinkFeedAddress(
                _chainlinkFeedAddress
            ),
            "GPC: already added price feed"
        );
        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();

        es.usdPriceAggrigators[_tokenAddress] = LibPriceConsumerStorage
            .ChainlinkDataFeed(
                AggregatorV3Interface(_chainlinkFeedAddress),
                _enabled,
                _decimals
            );
        es.allFeedContractsChainlink.push(_chainlinkFeedAddress);
        es.allFeedTokenAddress.push(_tokenAddress);

        emit LibPriceConsumer.PriceFeedAdded(
            _tokenAddress,
            _chainlinkFeedAddress,
            _enabled,
            _decimals
        );
    }

    /// @dev Adds a new tokens in bulk for getlatestPrice or getLatestUsdPrices can be called
    /// @param _tokenAddress the new tokens for the price feed
    /// @param _chainlinkFeedAddress The contract address of the chainlink aggregator
    /// @param  _enabled price feed enabled or not
    /// @param  _decimals of the chainlink feed address

    function addBatchTokenChainlinkFeed(
        address[] memory _tokenAddress,
        address[] memory _chainlinkFeedAddress,
        bool[] memory _enabled,
        uint256[] memory _decimals
    ) external onlyAddTokenRole(LibMeta.msgSender()) {
        require(
            (_tokenAddress.length == _chainlinkFeedAddress.length) &&
                (_enabled.length == _decimals.length) &&
                (_enabled.length == _tokenAddress.length)
        );
        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            addTokenChainlinkFeed(
                _tokenAddress[i],
                _chainlinkFeedAddress[i],
                _enabled[i],
                _decimals[i]
            );
        }
        emit LibPriceConsumer.PriceFeedAddedBulk(
            _tokenAddress,
            _chainlinkFeedAddress,
            _enabled,
            _decimals
        );
    }

    /// @dev enable or disable a token for which getLatestUsdPrice or getLatestUsdPrices can not be called now.
    /// @param _tokenAddress The token for price feed.

    function updateAggregatorTokenStatus(address _tokenAddress, bool _status)
        external
        onlyAddTokenRole(LibMeta.msgSender())
    {
        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();

        require(
            es.usdPriceAggrigators[_tokenAddress].enabled != _status,
            "GPC: already in desired state"
        );
        es.usdPriceAggrigators[_tokenAddress].enabled = _status;
        emit LibPriceConsumer.PriceFeedStatusUpdated(_tokenAddress, _status);
    }

    ///@dev set the swap router v2 address
    function setSwapRouter(address _swapRouterV2) external onlyOwner {
        require(_swapRouterV2 != address(0), "router null address");
        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();
        es.swapRouterv2 = IUniswapV2Router02(_swapRouterV2);
    }

    /// @dev Use chainlink PriceAggrigator to fetch prices of the already added feeds.
    /// @param priceFeedToken address of the price feed token
    /// @return int256 price of the token in usd
    /// @return uint8 decimals of the price token

    function getTokenPriceFromChainlink(address priceFeedToken)
        external
        view
        returns (int256, uint8)
    {
        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();

        (, int256 price, , , ) = es
            .usdPriceAggrigators[priceFeedToken]
            .usdPriceAggrigator
            .latestRoundData();
        uint8 decimals = es
            .usdPriceAggrigators[priceFeedToken]
            .usdPriceAggrigator
            .decimals();

        return (price, decimals);
    }

    /// @dev multiple token prices fetch
    /// @param priceFeedToken multi token price fetch
    /// @return tokens returns the token address of the pricefeed token addresses
    /// @return prices returns the prices of each token in array
    /// @return decimals returns the token decimals in array
    function getTokensPriceFromChainlink(address[] memory priceFeedToken)
        external
        view
        returns (
            address[] memory tokens,
            int256[] memory prices,
            uint8[] memory decimals
        )
    {
        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();

        decimals = new uint8[](priceFeedToken.length);
        tokens = new address[](priceFeedToken.length);
        prices = new int256[](priceFeedToken.length);
        for (uint256 i = 0; i < priceFeedToken.length; i++) {
            (, int256 price, , , ) = es
                .usdPriceAggrigators[priceFeedToken[i]]
                .usdPriceAggrigator
                .latestRoundData();
            decimals[i] = es
                .usdPriceAggrigators[priceFeedToken[i]]
                .usdPriceAggrigator
                .decimals();
            tokens[i] = priceFeedToken[i];
            prices[i] = price;
        }
        return (tokens, prices, decimals);
    }

    /// @dev How  much worth alt is in terms of stable coin passed (e.g. X ALT =  ? STABLE COIN)
    /// @param _stable address of stable coin
    /// @param _alt address of alt coin
    /// @param _amount address of alt
    /// @return uint256 returns the token price of _alt in stable decimals
    function getTokenPriceFromDex(
        address _stable,
        address _alt,
        uint256 _amount,
        address _dexRouter
    ) external view returns (uint256) {
        LibPriceConsumerStorage.PairReservesDecimals
            memory pairReserveDecimals = LibPriceConsumer
                .getPairAndReservesDecimals(_alt, _stable, _dexRouter);
        if (address(0) == address(pairReserveDecimals.pair)) {
            pairReserveDecimals = LibPriceConsumer.getPairAndReservesDecimals(
                _alt,
                wethAddress(),
                _dexRouter
            );
            if (address(pairReserveDecimals.pair) == address(0)) return 0;
            //identify the WETH address out  of token0 and token1, get price of altcoin in WETH
            uint256 collateralInWeth = LibPriceConsumer.convertToStableOrWeth(
                pairReserveDecimals,
                _amount,
                _stable
            );

            pairReserveDecimals = LibPriceConsumer.getPairAndReservesDecimals(
                _stable,
                wethAddress(),
                _dexRouter
            );
            return
                LibPriceConsumer.convertToStableOrWeth(
                    pairReserveDecimals,
                    collateralInWeth,
                    _stable
                );
        } else {
            //stable pair exists fetch price directly
            return
                LibPriceConsumer.convertToStableOrWeth(
                    pairReserveDecimals,
                    _amount,
                    _stable
                );
        }
    }

    /// @dev this function will get the price of native token and will assign the price according to the derived SUN tokens
    /// @param _claimToken address of the approved claim token
    /// @param _sunToken address of the SUN token
    /// @return uint256 returns the sun token price in stable token

    function getSunTokenInStable(
        address _claimToken,
        address _stable,
        address _sunToken,
        uint256 _amount
    ) external view returns (uint256) {
        LibClaimTokenStorage.ClaimTokenData memory claimTokenData = IClaimToken(
            address(this)
        ).getClaimTokensData(_claimToken);

        uint256 pegTokensPricePercentage;
        uint256 claimTokenPrice = this.getTokenPriceFromDex(
            _stable,
            _claimToken,
            _amount,
            claimTokenData.dexRouter
        );
        uint256 lengthPegTokens = claimTokenData.pegTokens.length;
        for (uint256 i = 0; i < lengthPegTokens; i++) {
            if (claimTokenData.pegTokens[i] == _sunToken) {
                pegTokensPricePercentage = claimTokenData
                    .pegTokensPricePercentage[i];
            }
        }

        return (claimTokenPrice * pegTokensPricePercentage) / 10000;
    }

    function getStableInSunToken(
        address _stable,
        address _claimToken,
        address _sunToken,
        uint256 _amount
    ) external view returns (uint256) {
        LibClaimTokenStorage.ClaimTokenData memory claimTokenData = IClaimToken(
            address(this)
        ).getClaimTokensData(_claimToken);

        uint256 pegTokensPricePercentage;
        //getting price of satble tokens in terms of sun token
        uint256 claimTokenPrice = this.getTokenPriceFromDex(
            _claimToken,
            _stable,
            _amount,
            claimTokenData.dexRouter
        );

        uint256 lengthPegTokens = claimTokenData.pegTokens.length;
        for (uint256 i = 0; i < lengthPegTokens; i++) {
            if (claimTokenData.pegTokens[i] == _sunToken) {
                pegTokensPricePercentage = claimTokenData
                    .pegTokensPricePercentage[i];
            }
        }

        return (claimTokenPrice * pegTokensPricePercentage) / 10000;
    }

    /// @dev function to get the amountIn and amountOut from the DEX
    /// @param _collateralToken collateral address being use while creating token market loan
    /// @param _collateralAmount collateral amount in create loan function
    /// @param _borrowStableCoin stable coin address DAI, USDT, etc...
    /// @return amountIn uint256 returns amountIn from the dex
    /// @return amountOut uint256 returns amountOut from the dex

    // TODO: will removed this function for mainnet, because we will be using 1inch swap
    function getSwapData(
        address _collateralToken,
        uint256 _collateralAmount,
        address _borrowStableCoin
    ) external view returns (uint256, uint256) {
        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();

        LibProtocolStorage.Market memory marketData = IProtocolRegistry(
            address(this)
        ).getSingleApproveToken(_collateralToken);

        LibPriceConsumerStorage.PairReservesDecimals
            memory pairReserveDecimals = LibPriceConsumer
                .getPairAndReservesDecimals(
                    _collateralToken,
                    _borrowStableCoin,
                    marketData.dexRouter
                );

        // swap router address uniswap or sushiswap or any uniswap like modal dex
        IUniswapV2Router02 swapRouter;

        if (marketData.dexRouter != address(0x0)) {
            swapRouter = IUniswapV2Router02(marketData.dexRouter);
        } else {
            swapRouter = IUniswapV2Router02(es.swapRouterv2);
        }

        uint256 amountOut = swapRouter.getAmountOut(
            _collateralAmount,
            pairReserveDecimals.reserve0,
            pairReserveDecimals.reserve1
        );
        uint256 amountIn = swapRouter.getAmountIn(
            amountOut,
            pairReserveDecimals.reserve0,
            pairReserveDecimals.reserve1
        );
        return (amountIn, amountOut);
    }

    /// @dev get the dex router address for the approved collateral token address
    /// @param _approvedCollateralToken approved collateral token address
    /// @return address address of the dex router
    // TODO: will removed this function for mainnet, because we will be using 1inch swap

    function getSwapInterface(address _approvedCollateralToken)
        external
        view
        returns (address)
    {
        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();

        LibProtocolStorage.Market memory marketData = IProtocolRegistry(
            address(this)
        ).getSingleApproveToken(_approvedCollateralToken);

        if (marketData.dexRouter != address(0)) {
            // swap router address uniswap or sushiswap or any uniswap like modal dex
            return marketData.dexRouter;
        } else {
            return address(es.swapRouterv2);
        }
    }

    /// @dev function checking if token price feed is enabled for chainlink or not
    /// @param _tokenAddress token address of the chainlink feed
    /// @return bool returns true or false value
    function isChainlinkFeedEnabled(address _tokenAddress)
        external
        view
        returns (bool)
    {
        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();
        return es.usdPriceAggrigators[_tokenAddress].enabled;
    }

    /// @dev get token price feed chainlink data
    function getAggregatorData(address _tokenAddress)
        external
        view
        returns (LibPriceConsumerStorage.ChainlinkDataFeed memory)
    {
        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();
        return es.usdPriceAggrigators[_tokenAddress];
    }

    /// @dev get all approved chainlink aggregator addresses
    function getAggregators() external view returns (address[] memory) {
        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();
        return es.allFeedContractsChainlink;
    }

    /// @dev get list of all gov aggregators erc20 tokens
    function getGovAggregatorTokens() external view returns (address[] memory) {
        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();
        return es.allFeedTokenAddress;
    }

    /// @dev get Wrapped ETH/BNB address from the uniswap v2 router
    function wethAddress() public view returns (address) {
        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();
        return es.swapRouterv2.WETH();
    }

    /// @dev Calculates LTV based on dex token price
    /// @param _stakedCollateralAmounts ttoken amounts
    /// @param _stakedCollateralTokens token contracts.
    /// @param _loanAmount total borrower loan amount in borrowed token.

    function calculateLTV(
        uint256[] memory _stakedCollateralAmounts,
        address[] memory _stakedCollateralTokens,
        address _borrowedToken,
        uint256 _loanAmount
    ) external view returns (uint256) {
        uint256 totalCollateralInBorrowedToken;

        for (uint256 i = 0; i < _stakedCollateralAmounts.length; i++) {
            uint256 collatetralInBorrowed;
            address claimToken = IClaimToken(address(this))
                .getClaimTokenofSUNToken(_stakedCollateralTokens[i]);

            if (IClaimToken(address(this)).isClaimToken(claimToken)) {
                collatetralInBorrowed =
                    collatetralInBorrowed +
                    (
                        this.getSunTokenInStable(
                            claimToken,
                            _borrowedToken,
                            _stakedCollateralTokens[i],
                            _stakedCollateralAmounts[i]
                        )
                    );
            } else {
                collatetralInBorrowed =
                    collatetralInBorrowed +
                    (
                        this.getCollateralPriceinStable(
                            _borrowedToken,
                            _stakedCollateralTokens[i],
                            _stakedCollateralAmounts[i]
                        )
                    );
            }

            totalCollateralInBorrowedToken =
                totalCollateralInBorrowedToken +
                collatetralInBorrowed;
        }
        return (totalCollateralInBorrowedToken * 100) / _loanAmount;
    }

    /// @dev function to get altcoin amount in stable coin.
    /// @param _stableCoin of the altcoin
    /// @param _altCoin address of the stable
    /// @param _collateralAmount amount of altcoin

    function getCollateralPriceinStable(
        address _stableCoin,
        address _altCoin,
        uint256 _collateralAmount
    ) external view returns (uint256) {
        if (
            this.isChainlinkFeedEnabled(_altCoin) &&
            this.isChainlinkFeedEnabled(_stableCoin)
        ) {
            (int256 collateralInUsd, ) = this.getTokenPriceFromChainlink(
                _altCoin
            );
            (int256 stableInUsd, ) = this.getTokenPriceFromChainlink(
                _stableCoin
            );
            uint256 collateralDecimals = IERC20Extras(_altCoin).decimals();
            uint256 stableDecimals = IERC20Extras(_stableCoin).decimals();
            uint256 altRateInStable = (uint256(collateralInUsd) *
                10**stableDecimals) / uint256(stableInUsd);
            return
                (_collateralAmount * altRateInStable) / 10**collateralDecimals;
        } else {
            LibProtocolStorage.Market memory marketData = IProtocolRegistry(
                address(this)
            ).getSingleApproveToken(_altCoin);
            return (
                this.getTokenPriceFromDex(
                    _stableCoin,
                    _altCoin,
                    _collateralAmount,
                    marketData.dexRouter
                )
            );
        }
    }

    /// @dev function to get stablecoin price in altcoin
    /// using this function is the liqudation autosell off
    function getStablePriceInCollateral(
        address _altCoin,
        address _stableCoin,
        uint256 _stableCoinAmount
    ) external view returns (uint256) {
        if (
            this.isChainlinkFeedEnabled(_altCoin) &&
            this.isChainlinkFeedEnabled(_stableCoin)
        ) {
            (int256 collateralInUsd, ) = this.getTokenPriceFromChainlink(
                _altCoin
            );
            (int256 stableInUsd, ) = this.getTokenPriceFromChainlink(
                _stableCoin
            );
            uint256 stableDecimals = IERC20Extras(_stableCoin).decimals();
            uint256 collateralDecimals = IERC20Extras(this.wethAddress())
                .decimals();
            uint256 stableRateInAltcoin = (uint256(stableInUsd) *
                10**collateralDecimals) / uint256(collateralInUsd);
            return
                (_stableCoinAmount * stableRateInAltcoin) / 10**stableDecimals;
        } else {
            LibProtocolStorage.Market memory marketData = IProtocolRegistry(
                address(this)
            ).getSingleApproveToken(_altCoin);
            return (
                this.getTokenPriceFromDex(
                    _altCoin,
                    _stableCoin,
                    _stableCoinAmount,
                    marketData.dexRouter
                )
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IERC20Extras {
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IDexFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IDexPair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {LibPriceConsumerStorage} from "./../facets/oracle/LibPriceConsumerStorage.sol";

interface IPriceConsumer {
    /// @dev Use chainlink PriceAggrigator to fetch prices of the already added feeds.
    /// @param priceFeedToken price fee token address for getting the price
    /// @return int256 returns the price value  from the chainlink
    /// @return uint8 returns the decimal of the price feed toekn
    function getTokenPriceFromChainlink(address priceFeedToken)
        external
        view
        returns (int256, uint8);

    /// @dev multiple token prices fetch
    /// @param priceFeedToken multi token price fetch
    /// @return tokens returns the token address of the pricefeed token addresses
    /// @return prices returns the prices of each token in array
    /// @return decimals returns the token decimals in array
    function getTokensPriceFromChainlink(address[] memory priceFeedToken)
        external
        view
        returns (
            address[] memory tokens,
            int256[] memory prices,
            uint8[] memory decimals
        );

    /// @dev get the dex router swap data
    /// @param _collateralToken  collateral token address
    /// @param _collateralAmount collatera token amount in decimals
    /// @param _borrowStableCoin stable coin token address
    function getSwapData(
        address _collateralToken,
        uint256 _collateralAmount,
        address _borrowStableCoin
    ) external view returns (uint256, uint256);

    /// @dev get the swap interface contract address of the collateral token
    /// @return address returns the swap router contract
    function getSwapInterface(address _collateralTokenAddress)
        external
        view
        returns (address);

    /// @dev How much worth alt is in terms of stable coin passed (e.g. X ALT =  ? STABLE COIN)
    /// @param _stable address of stable coin
    /// @param _alt address of alt coin
    /// @param _amount address of alt
    /// @return uint256 returns the price of alt coin in stable in stable coin decimals
    function getTokenPriceFromDex(
        address _stable,
        address _alt,
        uint256 _amount,
        address _dexRouter
    ) external view returns (uint256);

    /// @dev check wether token feed for this token is enabled or not
    function isChainlinkFeedEnabled(address _tokenAddress)
        external
        view
        returns (bool);

    /// @dev get the chainlink Data feed of the token address
    /// @param _tokenAddress token address
    /// @return ChainlinkDataFeed returns the details chainlink data feed
    function getAggregatorData(address _tokenAddress)
        external
        view
        returns (LibPriceConsumerStorage.ChainlinkDataFeed memory);

    /// @dev get all the chainlink aggregators contract address
    /// @return address[] returns the array of the contract address
    function getAggregators() external view returns (address[] memory);

    /// @dev get all the gov aggregator tokens approved
    /// @return address[] returns the array of the gov aggregators contracts
    function getGovAggregatorTokens() external view returns (address[] memory);

    /// @dev returns the weth contract address
    function wethAddress() external view returns (address);

    /// @dev get the altcoin price in stable address
    /// @param _stableCoin address of the stable token address
    /// @param _altCoin address of the altcoin token address
    /// @param _collateralAmount collateral token amount in decimals
    /// @return uint256 returns the price of collateral in stable
    function getCollateralPriceinStable(
        address _stableCoin,
        address _altCoin,
        uint256 _collateralAmount
    ) external view returns (uint256);

    function getStablePriceInCollateral(
        address _altcoin,
        address _stableCoin,
        uint256 _stableCoinAmount
    ) external view returns (uint256);

    /// @dev returns the calculated ltv percentage
    /// @param _stakedCollateralAmounts staked collateral amounts array
    /// @param _stakedCollateralTokens collateral token addresses
    /// @param _borrowedToken stable coin address
    /// @param _loanAmount loan amount in stable coin decimals
    /// @return uint256 returns the calculated ltv percentage

    function calculateLTV(
        uint256[] memory _stakedCollateralAmounts,
        address[] memory _stakedCollateralTokens,
        address _borrowedToken,
        uint256 _loanAmount
    ) external view returns (uint256);

    /// @dev get the sun token price
    /// @param _claimToken address of the claim token
    /// @param _stable stable token address
    /// @param _sunToken address of the sun token
    /// @param _amount amount of sun token in decimals
    /// @return uint256 returns the price of the sun token
    function getSunTokenInStable(
        address _claimToken,
        address _stable,
        address _sunToken,
        uint256 _amount
    ) external view returns (uint256);

    function getStableInSunToken(
        address _stable,
        address _claimToken,
        address _sunToken,
        uint256 _amount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./../facets/protocolRegistry/LibProtocolStorage.sol";

interface IProtocolRegistry {
    /// @dev check function if Token Contract address is already added
    /// @param _tokenAddress token address
    /// @return bool returns the true or false value
    function isTokenApproved(address _tokenAddress)
        external
        view
        returns (bool);

    /// @dev check fundtion token enable for staking as collateral
    /// @param _tokenAddress address of the collateral token address
    /// @return bool returns true or false value

    function isTokenEnabledForCreateLoan(address _tokenAddress)
        external
        view
        returns (bool);

    function getGovPlatformFee() external view returns (uint256);

    function getThresholdPercentage() external view returns (uint256);

    function getAutosellPercentage() external view returns (uint256);

    function getSingleApproveToken(address _tokenAddress)
        external
        view
        returns (LibProtocolStorage.Market memory);

    function getSingleApproveTokenData(address _tokenAddress)
        external
        view
        returns (
            address,
            bool,
            uint256
        );

    function isSyntheticMintOn(address _token) external view returns (bool);

    function getTokenMarket() external view returns (address[] memory);

    function getSingleTokenSps(address _tokenAddress)
        external
        view
        returns (address[] memory);

    function isAddedSPWallet(address _tokenAddress, address _walletAddress)
        external
        view
        returns (bool);

    function isStableApproved(address _stable) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {LibClaimTokenStorage} from "./../facets/claimtoken/LibClaimTokenStorage.sol";

interface IClaimToken {
    function isClaimToken(address _claimTokenAddress)
        external
        view
        returns (bool);

    function getClaimTokensData(address _claimTokenAddress)
        external
        view
        returns (LibClaimTokenStorage.ClaimTokenData memory);

    function getClaimTokenofSUNToken(address _sunToken)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library LibClaimTokenStorage {
    bytes32 constant CLAIMTOKEN_STORAGE_POSITION =
        keccak256("diamond.standard.CLAIMTOKEN.storage");

    struct ClaimTokenData {
        uint256 tokenType; // token type is used for token type sun or peg token
        address[] pegTokens; // addresses of the peg and sun tokens
        uint256[] pegTokensPricePercentage; // peg or sun token price percentages
        address dexRouter; //this address will get the price from the AMM DEX (uniswap, sushiswap etc...)
    }

    struct ClaimStorage {
        mapping(address => bool) approvedClaimTokens; // dev mapping for enable or disbale the claimToken
        mapping(address => ClaimTokenData) claimTokens;
        mapping(address => address) claimTokenofSUN; //sun token mapping to the claimToken
        address[] sunTokens;
    }

    function claimTokenStorage()
        internal
        pure
        returns (ClaimStorage storage es)
    {
        bytes32 position = CLAIMTOKEN_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {LibPriceConsumerStorage} from "./LibPriceConsumerStorage.sol";
import {IDexPair} from "./../../interfaces/IDexPair.sol";
import {IUniswapV2Router02} from "./../../interfaces/IUniswapV2Router02.sol";
import {IDexFactory} from "./../../interfaces/IDexFactory.sol";
import "./../../interfaces/IERC20Extras.sol";

library LibPriceConsumer {
    event PriceFeedAdded(
        address indexed token,
        address indexed usdPriceAggrigator,
        bool enabled,
        uint256 decimals
    );
    event PriceFeedAddedBulk(
        address[] indexed tokens,
        address[] indexed chainlinkFeedAddress,
        bool[] enabled,
        uint256[] decimals
    );
    event PriceFeedStatusUpdated(address indexed token, bool indexed status);

    event PathAdded(address _tokenAddress, address[] indexed _pathRoute);

    /// @dev chainlink feed token address check if it's already added
    /// @param _chainlinkFeedAddress chainlink token feed address
    function _isAddedChainlinkFeedAddress(address _chainlinkFeedAddress)
        internal
        view
        returns (bool)
    {
        LibPriceConsumerStorage.PriceConsumerStorage
            storage s = LibPriceConsumerStorage.priceConsumerStorage();
        uint256 length = s.allFeedContractsChainlink.length;
        for (uint256 i = 0; i < length; i++) {
            if (s.allFeedContractsChainlink[i] == _chainlinkFeedAddress) {
                return true;
            }
        }
        return false;
    }

    function getPair(
        address _token0,
        address _token1,
        address _dexRouter
    ) internal view returns (address pair) {
        LibPriceConsumerStorage.PriceConsumerStorage
            storage s = LibPriceConsumerStorage.priceConsumerStorage();

        IUniswapV2Router02 swapRouter;

        if (_dexRouter != address(0x0)) {
            swapRouter = IUniswapV2Router02(_dexRouter);
        } else {
            swapRouter = s.swapRouterv2;
        }
        pair = IDexFactory(swapRouter.factory()).getPair(_token0, _token1);
    }

    function getPairAndReservesDecimals(
        address _token0,
        address _token1,
        address _dexRouter
    )
        internal
        view
        returns (
            LibPriceConsumerStorage.PairReservesDecimals
                memory pairReservesDecimals
        )
    {
        pairReservesDecimals.pair = IDexPair(
            getPair(_token0, _token1, _dexRouter)
        );
        if (address(pairReservesDecimals.pair) != address(0)) {
            (
                pairReservesDecimals.reserve0,
                pairReservesDecimals.reserve1,

            ) = IDexPair(pairReservesDecimals.pair).getReserves();

            pairReservesDecimals.decimal0 = IERC20Extras(
                IDexPair(pairReservesDecimals.pair).token0()
            ).decimals();
            pairReservesDecimals.decimal1 = IERC20Extras(
                IDexPair(pairReservesDecimals.pair).token1()
            ).decimals();
            return pairReservesDecimals;
        } else {
            return pairReservesDecimals;
        }
    }

    function convertToStableOrWeth(
        LibPriceConsumerStorage.PairReservesDecimals
            memory _pairReserveDecimals,
        uint256 _amount,
        address _stable
    ) internal view returns (uint256 price) {
        if (_pairReserveDecimals.pair.token0() == _stable) {
            price =
                (_amount *
                    ((_pairReserveDecimals.reserve0 *
                        (10**_pairReserveDecimals.decimal1)) /
                        (_pairReserveDecimals.reserve1))) /
                (10**_pairReserveDecimals.decimal1);
        } else {
            price =
                (_amount *
                    ((_pairReserveDecimals.reserve1 *
                        (10**_pairReserveDecimals.decimal0)) /
                        (_pairReserveDecimals.reserve0))) /
                (10**_pairReserveDecimals.decimal0);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {LibDiamond} from "./../../shared/libraries/LibDiamond.sol";
import {LibAdminStorage} from "./../../facets/admin/LibAdminStorage.sol";
import {LibLiquidatorStorage} from "./../../facets/liquidator/LibLiquidatorStorage.sol";
import {LibProtocolStorage} from "./../../facets/protocolRegistry/LibProtocolStorage.sol";
import {LibPausable} from "./../../shared/libraries/LibPausable.sol";

struct AppStorage {
    address govToken;
    address govGovToken;
}

library LibAppStorage {
    function appStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlySuperAdmin(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(es.approvedAdminRoles[admin].superAdmin, "not super admin");
        _;
    }

    /// @dev modifer only admin with edit admin access can call functions
    modifier onlyEditTierLevelRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(
            es.approvedAdminRoles[admin].editGovAdmin,
            "not edit tier role"
        );
        _;
    }

    modifier onlyLiquidator(address _admin) {
        LibLiquidatorStorage.LiquidatorStorage storage es = LibLiquidatorStorage
            .liquidatorStorage();
        require(es.whitelistLiquidators[_admin], "not liquidator");
        _;
    }

    //modifier: only admin with AddTokenRole can add Token(s) or NFT(s)
    modifier onlyAddTokenRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(es.approvedAdminRoles[admin].addToken, "not add token role");
        _;
    }

    //modifier: only admin with EditTokenRole can update or remove Token(s)/NFT(s)
    modifier onlyEditTokenRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(es.approvedAdminRoles[admin].editToken, "not edit token role");
        _;
    }

    //modifier: only admin with AddSpAccessRole can add SP Wallet
    modifier onlyAddSpRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();
        require(es.approvedAdminRoles[admin].addSp, "not add sp role");
        _;
    }

    //modifier: only admin with EditSpAccess can update or remove SP Wallet
    modifier onlyEditSpRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();
        require(es.approvedAdminRoles[admin].editSp, "not edit sp role");
        _;
    }

    modifier whenNotPaused() {
        LibPausable.enforceNotPaused();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library LibMeta {
    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library LibProtocolStorage {
    bytes32 constant PROTOCOLREGISTRY_STORAGE_POSITION =
        keccak256("diamond.standard.PROTOCOLREGISTRY.storage");

    enum TokenType {
        ISDEX,
        ISELITE,
        ISVIP
    }

    // Token Market Data
    struct Market {
        address dexRouter;
        address gToken;
        bool isMint;
        TokenType tokenType;
        bool isTokenEnabledAsCollateral;
    }

    struct ProtocolStorage {
        uint256 govPlatformFee;
        uint256 govAutosellFee;
        uint256 govThresholdFee;
        mapping(address => address[]) approvedSps; // tokenAddress => spWalletAddress
        mapping(address => Market) approvedTokens; // tokenContractAddress => Market struct
        mapping(address => bool) approveStable; // stable coin address enable or disable in protocol registry
        address[] allApprovedSps; // array of all approved SP Wallet Addresses
        address[] allapprovedTokenContracts; // array of all Approved ERC20 Token Contracts
    }

    function protocolRegistryStorage()
        internal
        pure
        returns (ProtocolStorage storage es)
    {
        bytes32 position = PROTOCOLREGISTRY_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IERC165} from "../interfaces/IERC165.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import {LibMeta} from "./LibMeta.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferredDiamond(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferredDiamond(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            LibMeta.msgSender() == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    function addDiamondFunctions(
        address _diamondCutFacet,
        address _diamondLoupeFacet,
        address _ownershipFacet
    ) internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        functionSelectors = new bytes4[](5);
        functionSelectors[0] = IDiamondLoupe.facets.selector;
        functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facetAddress.selector;
        functionSelectors[4] = IERC165.supportsInterface.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: _diamondLoupeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        functionSelectors = new bytes4[](2);
        functionSelectors[0] = IERC173.transferOwnership.selector;
        functionSelectors[1] = IERC173.owner.selector;
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: _ownershipFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        diamondCut(cut, address(0), "");
    }

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint16 selectorPosition = uint16(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(
                _facetAddress,
                "LibDiamondCut: New facet has no code"
            );
            ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
                selector
            );
            ds
                .selectorToFacetAndPosition[selector]
                .facetAddress = _facetAddress;
            ds
                .selectorToFacetAndPosition[selector]
                .functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint16 selectorPosition = uint16(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(
                _facetAddress,
                "LibDiamondCut: New facet has no code"
            );
            ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(oldFacetAddress, selector);
            // add function
            ds
                .selectorToFacetAndPosition[selector]
                .functionSelectorPosition = selectorPosition;
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
                selector
            );
            ds
                .selectorToFacetAndPosition[selector]
                .facetAddress = _facetAddress;
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint16(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = uint16(facetAddressPosition);
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (success == false) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize != 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./../../interfaces/IPriceConsumer.sol";
import "./../../interfaces/IUniswapV2Router02.sol";
import "./../../interfaces/IPriceConsumer.sol";
import "./../../interfaces/IClaimToken.sol";
import "./../../interfaces/IDexPair.sol";
import {IProtocolRegistry} from "./../../interfaces/IProtocolRegistry.sol";

library LibPriceConsumerStorage {
    bytes32 constant PRICECONSUMER_STORAGE_POSITION =
        keccak256("diamond.standard.PRICECONSUMER.storage");

    struct PairReservesDecimals {
        IDexPair pair;
        uint256 reserve0;
        uint256 reserve1;
        uint256 decimal0;
        uint256 decimal1;
    }

    struct ChainlinkDataFeed {
        AggregatorV3Interface usdPriceAggrigator;
        bool enabled;
        uint256 decimals;
    }

    struct PriceConsumerStorage {
        mapping(address => ChainlinkDataFeed) usdPriceAggrigators;
        address[] allFeedContractsChainlink; //chainlink feed contract addresses
        address[] allFeedTokenAddress; //chainlink feed ERC20 token contract addresses
        IUniswapV2Router02 swapRouterv2;
    }

    function priceConsumerStorage()
        internal
        pure
        returns (PriceConsumerStorage storage es)
    {
        bytes32 position = PRICECONSUMER_STORAGE_POSITION;
        assembly {
            es.slot := position
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

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

pragma solidity ^0.8.10;

import {LibMeta} from "./../../shared/libraries/LibMeta.sol";

/**
 * @dev Library version of the OpenZeppelin Pausable contract with Diamond storage.
 * See: https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable
 * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol
 */
library LibPausable {
    struct Storage {
        bool paused;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256("diamond.standard.Pausable.storage");

    /**
     * @dev Returns the storage.
     */
    function _storage() private pure returns (Storage storage s) {
        bytes32 slot = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := slot
        }
    }

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Reverts when paused.
     */
    function enforceNotPaused() internal view {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Reverts when not paused.
     */
    function enforcePaused() internal view {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() internal view returns (bool) {
        return _storage().paused;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal {
        _storage().paused = true;
        emit Paused(LibMeta.msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal {
        _storage().paused = false;
        emit Unpaused(LibMeta.msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library LibAdminStorage {
    bytes32 constant ADMINREGISTRY_STORAGE_POSITION =
        keccak256("diamond.standard.ADMINREGISTRY.storage");

    struct AdminAccess {
        //access-modifier variables to add projects to gov-intel
        bool addGovIntel;
        bool editGovIntel;
        //access-modifier variables to add tokens to gov-world protocol
        bool addToken;
        bool editToken;
        //access-modifier variables to add strategic partners to gov-world protocol
        bool addSp;
        bool editSp;
        //access-modifier variables to add gov-world admins to gov-world protocol
        bool addGovAdmin;
        bool editGovAdmin;
        //access-modifier variables to add bridges to gov-world protocol
        bool addBridge;
        bool editBridge;
        //access-modifier variables to add pools to gov-world protocol
        bool addPool;
        bool editPool;
        //superAdmin role assigned only by the super admin
        bool superAdmin;
    }

    struct AdminStorage {
        mapping(address => AdminAccess) approvedAdminRoles; // approve admin roles for each address
        mapping(uint8 => mapping(address => AdminAccess)) pendingAdminRoles; // mapping of admin role keys to admin addresses to admin access roles
        mapping(uint8 => mapping(address => address[])) areByAdmins; // list of admins approved by other admins, for the specific key
        //admin role keys
        uint8 PENDING_ADD_ADMIN_KEY;
        uint8 PENDING_EDIT_ADMIN_KEY;
        uint8 PENDING_REMOVE_ADMIN_KEY;
        uint8[] PENDING_KEYS; // ADD: 0, EDIT: 1, REMOVE: 2
        address[] allApprovedAdmins; //list of all approved admin addresses
        address[][] pendingAdminKeys; //list of pending addresses for each key
        address superAdmin;
    }

    function adminRegistryStorage()
        internal
        pure
        returns (AdminStorage storage es)
    {
        bytes32 position = ADMINREGISTRY_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library LibLiquidatorStorage {
    bytes32 constant LIQUIDATOR_STORAGE =
        keccak256("diamond.standard.LIQUIDATOR.storage");
    struct LiquidatorStorage {
        mapping(address => bool) whitelistLiquidators; // list of already approved liquidators.
        mapping(address => mapping(address => uint256)) liquidatedSUNTokenbalances; //mapping of wallet address to track the approved claim token balances when loan is liquidated // wallet address lender => sunTokenAddress => balanceofSUNToken
        address[] whitelistedLiquidators; // list of all approved liquidator addresses. Stores the key for mapping approvedLiquidators
        address aggregator1Inch;
        bool isInitializedLiquidator;
    }

    function liquidatorStorage()
        internal
        pure
        returns (LiquidatorStorage storage ls)
    {
        bytes32 position = LIQUIDATOR_STORAGE;
        assembly {
            ls.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}