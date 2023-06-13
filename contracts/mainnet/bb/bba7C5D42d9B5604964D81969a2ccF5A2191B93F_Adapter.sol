// SPDX-License-Identifier: --DAO--

/**
 * @author René Hochmuth
 * @author Vitally Marinchenko
 */

pragma solidity =0.8.19;

import "./AdapterHelper.sol";

contract Adapter is AdapterHelper {

    constructor(
        address _tokenProfitAddress,
        address _uniV2RouterAddress,
        address _liquidNFTsRouterAddress,
        address _liquidNFTsWETHPool,
        address _liquidNFTsUSDCPool
    )
        AdapterDeclarations(
            _tokenProfitAddress,
            _uniV2RouterAddress,
            _liquidNFTsRouterAddress,
            _liquidNFTsWETHPool,
            _liquidNFTsUSDCPool
        )
    {
        admin = tx.origin;
        multisig = tx.origin;
    }

    /**
    * @dev Overview for services and ability to syncronize them
    */
    function syncServices()
        external
    {
        liquidNFTsUSDCPool.manualSyncPool();
        liquidNFTsWETHPool.manualSyncPool();
    }

    /**
    * @dev Allows admin to swap USDC for ETH using UniswapV2
    */
    function swapUSDCForETH(
        uint256 _amount,
        uint256 _minAmountOut
    )
        external
        onlyMultiSig
        returns (
            uint256 amountIn,
            uint256 amountOut
        )
    {
        address[] memory path = new address[](2);

        path[0] = USDC_ADDRESS;
        path[1] = WETH_ADDRESS;

        uint256[] memory amounts = _executeSwap(
            path,
            _amount,
            _minAmountOut
        );

        emit AdminSwap(
            USDC_ADDRESS,
            WETH_ADDRESS,
            amounts[0],
            amounts[1]
        );

        return (
            amounts[0],
            amounts[1]
        );
    }

    function _precisionWithFee()
        internal
        view
        returns (uint256)
    {
        return FEE_PRECISION + buyFee;
    }

    /**
    * @dev Calculates tokens to mint given exact ETH amount
    * input for the TokenProfit contract during mint
    */
    function getTokenAmountFromEthAmount(
        uint256 _ethAmount
    )
        external
        view
        returns (uint256)
    {
        return tokenProfit.totalSupply()
            * _ethAmount
            * FEE_PRECISION
            / _precisionWithFee()
            / _calculateTotalEthValue(
                0
            );
    }

    /**
    * @dev Calculates ETH amount necessary to pay to
    * receive fixed token amount from the TokenProfit contract
    */
    function getEthAmountFromTokenAmount(
        uint256 _tokenAmount,
        uint256 _msgValue
    )
        external
        view
        returns (uint256)
    {
        return _calculateTotalEthValue(
            _msgValue
        )
            * _tokenAmount
            * PRECISION_FACTOR
            * _precisionWithFee()
            / FEE_PRECISION
            / tokenProfit.totalSupply()
            / PRECISION_FACTOR;
    }

    function proposeNewMultisig(
        address _proposedMultisig
    )
        external
        onlyMultiSig
    {
        address oldProposedMultisig = proposedMultisig;
        proposedMultisig = _proposedMultisig;

        emit MultisigUpdateProposed(
            oldProposedMultisig,
            _proposedMultisig
        );
    }

    function claimMultisigOwnership()
        external
        onlyProposedMultisig
    {
        address oldMultisig = multisig;
        multisig = proposedMultisig;
        proposedMultisig = ZERO_ADDRESS;

        emit MultisigUpdate(
            oldMultisig,
            multisig
        );
    }

    /**
    * @dev Starts the process to change the admin address
    */
    function proposeNewAdmin(
        address _newProposedAdmin
    )
        external
        onlyMultiSig
    {
        address oldProposedAdmin = proposedAdmin;
        proposedAdmin = _newProposedAdmin;

        emit AdminUpdateProposed(
            oldProposedAdmin,
            _newProposedAdmin
        );
    }

    /**
    * @dev Finalize the change of the admin address
    */
    function claimAdminOwnership()
        external
        onlyProposedAdmin
    {
        address oldAdmin = admin;
        admin = proposedAdmin;
        proposedAdmin = ZERO_ADDRESS;

        emit AdminUpdate(
            oldAdmin,
            admin
        );
    }

    /**
    * @dev Ability for multisig to change the buy fee
    */
    function changeBuyFee(
        uint256 _newFeeValue
    )
        external
        onlyMultiSig
    {
        require(
            FEE_THRESHOLD > _newFeeValue,
            "Adapter: FEE_TOO_HIGH"
        );

        require(
            _newFeeValue > FEE_LOWER_BOUND,
            "Adapter: FEE_TOO_LOW"
        );

        uint256 oldValue = buyFee;
        buyFee = _newFeeValue;

        emit BuyFeeChanged(
            oldValue,
            _newFeeValue
        );
    }

    /**
    * @dev Allows multisig to swap ETH for USDC using UniswapV2
    */
    function swapETHforUSDC(
        uint256 _amount,
        uint256 _minAmountOut
    )
        external
        onlyMultiSig
        returns (
            uint256 amountIn,
            uint256 amountOut
        )
    {
        address[] memory path = new address[](2);

        path[0] = WETH_ADDRESS;
        path[1] = USDC_ADDRESS;

        uint256[] memory amounts = _executeSwapWithValue(
            path,
            _amount,
            _minAmountOut
        );

        emit AdminSwap(
            WETH_ADDRESS,
            USDC_ADDRESS,
            amounts[0],
            amounts[1]
        );

        return (
            amounts[0],
            amounts[1]
        );
    }

    /**
    * @dev Allows admin to deposit ETH into LiquidNFTs pool
    */
    function depositETHLiquidNFTs(
        uint256 _amount
    )
        external
        onlyAdmin
    {
        _wrapETH(
            _amount
        );

        _depositLiquidNFTsWrapper(
            liquidNFTsWETHPool,
            _amount
        );
    }

    /**
    * @dev Allows admin to deposit USDC into LiquidNFTs pool
    */
    function depositUSDCLiquidNFTs(
        uint256 _amount
    )
        external
        onlyAdmin
    {
        _depositLiquidNFTsWrapper(
            liquidNFTsUSDCPool,
            _amount
        );
    }

    /**
    * @dev Allows admin to withdraw USDC from LiquidNFTs pool
    */
    function withdrawUSDCLiquidNFTs(
        uint256 _amount
    )
        external
        onlyAdmin
    {
        _withdrawLiquidNFTsWrapper(
            liquidNFTsUSDCPool,
            _amount
        );
    }

    /**
    * @dev Allows admin to withdraw ETH from LiquidNFTs pool
    */
    function withdrawETHLiquidNFTs(
        uint256 _amount
    )
        external
        onlyAdmin
    {
        _withdrawLiquidNFTsWrapper(
            liquidNFTsWETHPool,
            _amount
        );

        _unwrapETH(
            WETH.balanceOf(
                TOKEN_PROFIT_ADDRESS
            )
        );
    }

    /**
    * @dev Allows admin to withdraw some ETH for 2023 budget
    */
    function withdraw2023Budget(
        uint256 _amount
    )
        external
        onlyAdmin
    {
        require(
            _amount == BUDGET_FOR_2023,
            "Adapter: INVALID_AMOUNT"
        );

        require(
            budgetWithdrawn == false,
            "Adapter: ALREADY_WITHDRAWN"
        );

        budgetWithdrawn = true;

        _withdrawLiquidNFTsWrapper(
            liquidNFTsWETHPool,
            _amount
        );

        tokenProfit.executeAdapterRequest(
            WETH_ADDRESS,
            abi.encodeWithSelector(
                WETH.transfer.selector,
                admin,
                BUDGET_FOR_2023
            )
        );
    }

    /**
    * @dev Allows TokenProfit contract to withdraw tokens from services
    */
    function assistWithdrawTokens(
        uint256 _index,
        uint256 _amount
    )
        external
        onlyTokenProfit
        returns (uint256)
    {
        if (tokens[_index].tokenERC20 == USDC) {
            return _USDCRoutine(
                _amount
            );
        }

        revert InvalidToken();
    }

    /**
    * @dev Allows TokenProfit contract to withdraw ETH from services
    */
    function assistWithdrawETH(
        uint256 _amount
    )
        external
        onlyTokenProfit
        returns (uint256)
    {
        return _WETHRoutine(
            _amount
        );
    }
}

// SPDX-License-Identifier: --DAO--

/**
 * @author René Hochmuth
 * @author Vitally Marinchenko
 */

pragma solidity =0.8.19;

import "./AdapterDeclarations.sol";

error SlippageTooBig();
error ChainLinkOffline();

abstract contract AdapterHelper is AdapterDeclarations {

    /**
    * @dev Tells TokenProfit contract to perform a swap through UniswapV2 starting with ETH
    */
    function _executeSwapWithValue(
        address[] memory _path,
        uint256 _amount,
        uint256 _minAmountOut
    )
        internal
        returns (uint256[] memory)
    {
        if (_minAmountOut == 0) {
            revert SlippageTooBig();
        }

        bytes memory callbackData = tokenProfit.executeAdapterRequestWithValue(
            UNIV2_ROUTER_ADDRESS,
            abi.encodeWithSelector(
                IUniswapV2.swapExactETHForTokens.selector,
                _minAmountOut,
                _path,
                TOKEN_PROFIT_ADDRESS,
                block.timestamp
            ),
            _amount
        );

        return abi.decode(
            callbackData,
            (
                uint256[]
            )
        );
    }

    /**
    * @dev checks if chainLink price feeds are still operating
    */
    function isChainlinkOffline()
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < TOKENS; i++) {

            IChainLink feed = tokens[i].feedLink;

            (   ,
                ,
                ,
                uint256 upd
                ,
            ) = feed.latestRoundData();

            upd = block.timestamp > upd
                ? block.timestamp - upd
                : block.timestamp;

            if (upd > chainLinkHeartBeat[address(feed)]) return true;
        }

        return false;
    }

    /**
    * @dev Calculates ETH and token balances available for services
    * --------------------------------
    * availableEther is ETH balance of the TokenProfit contract
    * availableTokens is balances of all tokens in TokenProfit contract
    * etherAmount is availableEther + ETH deposited in other services
    * tokenAmounts is availableTokens + tokens deposited in other services
    */
    function getTokenAmounts()
        public
        view
        returns (
            uint256 etherAmount,
            uint256[] memory tokensAmounts,
            uint256 availableEther,
            uint256[] memory availableAmounts
        )
    {
        uint256[] memory tokenAmounts = new uint256[](TOKENS);
        uint256[] memory availableTokens = new uint256[](TOKENS);

        (
            availableEther,
            availableTokens
        ) = _getAvailableFunds();

        for (uint256 i = 0; i < TOKENS; i++) {
            tokenAmounts[i] = _getReservesByToken(
                tokens[i].tokenERC20
            ) + availableTokens[i];
        }

        etherAmount = _calculateAmountFromShares(
            liquidNFTsWETHPool,
            TOKEN_PROFIT_ADDRESS
        ) + availableEther;

        return (
            etherAmount,
            tokenAmounts,
            availableEther,
            availableTokens
        );
    }

    function _calculateTotalEthValue(
        uint256 _msgValue
    )
        internal
        view
        returns (uint256)
    {
        if (isChainlinkOffline() == true) {
            revert ChainLinkOffline();
        }

        (
            uint256 etherAmount,
            uint256[] memory tokensAmounts,
            ,
        ) = getTokenAmounts();

        for (uint256 i = 0; i < TOKENS; i++) {

            TokenData memory token = tokens[i];
            IChainLink feed = token.feedLink;

            uint256 latestAnswer = feed.latestAnswer();

            require(
                latestAnswer > 0,
                "AdapterHelper: CHAINLINK_OFFLINE"
            );

            etherAmount += feed.latestAnswer()
                * PRECISION_FACTOR
                * tokensAmounts[i]
                / (10 ** token.tokenDecimals)
                / (10 ** token.feedDecimals);
        }

        return etherAmount
            - _msgValue;
    }

    /**
    * @dev Tells TokenProfit contract to perform
    * a swap through UniswapV2 starting with Tokens
    */
    function _executeSwap(
        address[] memory _path,
        uint256 _amount,
        uint256 _minAmountOut
    )
        internal
        returns (uint256[] memory)
    {
        if (_minAmountOut == 0) {
            revert SlippageTooBig();
        }

        bytes memory callbackData = tokenProfit.executeAdapterRequest(
            UNIV2_ROUTER_ADDRESS,
            abi.encodeWithSelector(
                IUniswapV2.swapExactTokensForETH.selector,
                _amount,
                _minAmountOut,
                _path,
                TOKEN_PROFIT_ADDRESS,
                block.timestamp
            )
        );

        return abi.decode(
            callbackData,
            (
                uint256[]
            )
        );
    }

    /**
    * @dev Tells TokenProfit contract to convert WETH to ETH
    */
    function _unwrapETH(
        uint256 _amount
    )
        internal
    {
        tokenProfit.executeAdapterRequest(
            WETH_ADDRESS,
            abi.encodeWithSelector(
                IWETH.withdraw.selector,
                _amount
            )
        );
    }

    /**
    * @dev Tells TokenProfit contract to convert ETH to WETH
    */
    function _wrapETH(
        uint256 _amount
    )
        internal
    {
        tokenProfit.executeAdapterRequestWithValue(
            WETH_ADDRESS,
            abi.encodeWithSelector(
                IWETH.deposit.selector
            ),
            _amount
        );
    }

    /**
    * @dev Tells TokenProfit contract to deposit funds into LiquidNFTs pool
    */
    function _depositLiquidNFTsWrapper(
        ILiquidNFTsPool _pool,
        uint256 _amount
    )
        internal
    {
        tokenProfit.executeAdapterRequest(
            LIQUID_NFT_ROUTER_ADDRESS,
            abi.encodeWithSelector(
                ILiquidNFTsRouter.depositFunds.selector,
                _amount,
                _pool
            )
        );
    }

    /**
    * @dev Tells TokenProfit contract to withdraw funds from LiquidNFTs pool
    */
    function _withdrawLiquidNFTsWrapper(
        ILiquidNFTsPool _pool,
        uint256 _amount
    )
        internal
    {
        tokenProfit.executeAdapterRequest(
            LIQUID_NFT_ROUTER_ADDRESS,
            abi.encodeWithSelector(
                ILiquidNFTsRouter.withdrawFunds.selector,
                _calculateSharesFromAmount(
                    _pool,
                    _amount
                ),
                _pool
            )
        );
    }

    /**
    * @dev Routine used to deal with all services withdrawing USDC
    */
    function _USDCRoutine(
        uint256 _amount
    )
        internal
        returns (uint256)
    {
        uint256 balanceBefore = USDC.balanceOf(
            TOKEN_PROFIT_ADDRESS
        );

        _withdrawLiquidNFTsWrapper(
            liquidNFTsUSDCPool,
            _amount
        );

        uint256 balanceAfter = USDC.balanceOf(
            TOKEN_PROFIT_ADDRESS
        );

        return balanceAfter - balanceBefore;
    }

    /**
    * @dev Routine used to deal with all services withdrawing ETH
    */
    function _WETHRoutine(
        uint256 _amount
    )
        internal
        returns (uint256)
    {
        _withdrawLiquidNFTsWrapper(
            liquidNFTsWETHPool,
            _amount
        );

        uint256 balance = WETH.balanceOf(
            TOKEN_PROFIT_ADDRESS
        );

        _unwrapETH(
            balance
        );

        return balance;
    }

    /**
    * @dev Returns balances of TokenProfit contract - tokens and ETH
    */
    function _getAvailableFunds()
        internal
        view
        returns (
            uint256,
            uint256[] memory
        )
    {
        uint256[] memory availableTokens = new uint256[](TOKENS);

        for (uint256 i = 0; i < TOKENS; i++) {
            IERC20 token = tokens[i].tokenERC20;
            availableTokens[i] = token.balanceOf(
                TOKEN_PROFIT_ADDRESS
            );
        }

        uint256 availableEther = TOKEN_PROFIT_ADDRESS.balance;

        return (
            availableEther,
            availableTokens
        );
    }

    /**
    * @dev Returns balances locked in servcies based on token
    */
    function _getReservesByToken(
        IERC20 _token
    )
        internal
        view
        returns (uint256)
    {
        if (_token == USDC) {
            return _calculateAmountFromShares(
                liquidNFTsUSDCPool,
                TOKEN_PROFIT_ADDRESS
            );
        }

        return 0;
    }

    /**
    * @dev Helper function to calculate shares from amount for LiquidNFTs pool
    */
    function _calculateSharesFromAmount(
        ILiquidNFTsPool _pool,
        uint256 _amount
    )
        internal
        view
        returns (uint256)
    {
        return _amountSharesCalculationWrapper(
            _pool.totalInternalShares(),
            _pool.pseudoTotalTokensHeld(),
            _amount
        );
    }

    /**
    * @dev Helper function to calculate amount from shares for LiquidNFTs pool
    */
    function _calculateAmountFromShares(
        ILiquidNFTsPool _pool,
        address _sharesHolder
    )
        internal
        view
        returns (uint256)
    {
        return _amountSharesCalculationWrapper(
            _pool.pseudoTotalTokensHeld(),
            _pool.totalInternalShares(),
            _pool.internalShares(
                _sharesHolder
            )
        );
    }

    /**
    * @dev Calculates ratios based on shares and amount
    */
    function _amountSharesCalculationWrapper(
        uint256 _totalValue,
        uint256 _correspondingTotalValue,
        uint256 _amountValue
    )
        internal
        pure
        returns (uint256)
    {
        return _totalValue
            * _amountValue
            / _correspondingTotalValue;
    }
}

// SPDX-License-Identifier: --DAO--

/**
 * @author René Hochmuth
 * @author Vitally Marinchenko
 */

pragma solidity =0.8.19;

import "./AdapterInterfaces.sol";

error InvalidFeed();
error InvalidToken();
error InvalidDecimals();

contract AdapterDeclarations {

    struct TokenData {
        IERC20 tokenERC20;
        IChainLink feedLink;
        uint8 feedDecimals;
        uint8 tokenDecimals;
    }

    uint256 constant TOKENS = 1;
    TokenData[TOKENS] public tokens;

    IERC20 public immutable WETH;
    IERC20 public immutable USDC;

    address public immutable WETH_ADDRESS;
    address public immutable USDC_ADDRESS;

    address public immutable TOKEN_PROFIT_ADDRESS;
    address public immutable UNIV2_ROUTER_ADDRESS;
    address public immutable LIQUID_NFT_ROUTER_ADDRESS;

    ITokenProfit public immutable tokenProfit;
    ILiquidNFTsPool public immutable liquidNFTsWETHPool;
    ILiquidNFTsPool public immutable liquidNFTsUSDCPool;

    address public admin;
    address public multisig;
    address public proposedMultisig;
    address public proposedAdmin;

    uint256 public buyFee = 1000;

    uint256 constant public FEE_PRECISION = 1E4;
    uint256 constant public FEE_THRESHOLD = 50000;
    uint256 constant public FEE_LOWER_BOUND = 10;
    uint256 constant public PRECISION_FACTOR = 1E18;

    bool public budgetWithdrawn;
    uint256 constant public BUDGET_FOR_2023 = 115E18;

    uint80 constant MAX_ROUND_COUNT = 50;
    address constant ZERO_ADDRESS = address(0x0);
    uint256 constant UINT256_MAX = type(uint256).max;

    mapping(address => uint256) public chainLinkHeartBeat;

    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "AdapterDeclarations: NOT_ADMIN"
        );
        _;
    }

    modifier onlyTokenProfit() {
        require(
            msg.sender == TOKEN_PROFIT_ADDRESS,
            "AdapterDeclarations: NOT_TOKEN_PROFIT"
        );
        _;
    }

    modifier onlyProposedMultisig() {
        require(
            msg.sender == proposedMultisig,
            "AdapterDeclarations: NOT_PROPOSED_MULTISIG"
        );
        _;
    }

    modifier onlyProposedAdmin() {
        require(
            msg.sender == proposedAdmin,
            "AdapterDeclarations: NOT_PROPOSED_ADMIN"
        );
        _;
    }

    modifier onlyMultiSig() {
        require(
            msg.sender == multisig,
            "AdapterDeclarations: NOT_MULTISIG"
        );
        _;
    }

    event AdminSwap(
        address indexed from,
        address indexed to,
        uint256 amountIn,
        uint256 amountOut
    );

    event BuyFeeChanged(
        uint256 indexed oldFee,
        uint256 indexed newFee
    );

    event MultisigUpdate(
        address oldMultisig,
        address newMultisig
    );

    event MultisigUpdateProposed(
        address oldProposedMultisig,
        address newProposedMultisig
    );

    event AdminUpdate(
        address oldAdmin,
        address newAdmin
    );

    event AdminUpdateProposed(
        address oldProposedAdmin,
        address newProposedAdmin
    );

    constructor(
        address _tokenProfitAddress,
        address _uniV2RouterAddress,
        address _liquidNFTsRouterAddress,
        address _liquidNFTsWETHPool,
        address _liquidNFTsUSDCPool
    ) {
        // --- liquidNFTs group ---

        liquidNFTsWETHPool = ILiquidNFTsPool(
            _liquidNFTsWETHPool
        );

        liquidNFTsUSDCPool = ILiquidNFTsPool(
            _liquidNFTsUSDCPool
        );

        LIQUID_NFT_ROUTER_ADDRESS = _liquidNFTsRouterAddress;

        // --- token group ---

        USDC_ADDRESS = liquidNFTsUSDCPool.poolToken();
        WETH_ADDRESS = liquidNFTsWETHPool.poolToken();

        USDC = IERC20(
            USDC_ADDRESS
        );

        WETH = IWETH(
            WETH_ADDRESS
        );

        IChainLink chainLinkFeed = IChainLink(
            0x986b5E1e1755e3C2440e960477f25201B0a8bbD4
        );

        tokens[0] = TokenData({
            tokenERC20: USDC,
            feedLink: chainLinkFeed,
            feedDecimals: chainLinkFeed.decimals(),
            tokenDecimals: USDC.decimals()
        });

        _validateData();

        // --- tokenProfit group ---

        tokenProfit = ITokenProfit(
            _tokenProfitAddress
        );

        TOKEN_PROFIT_ADDRESS = _tokenProfitAddress;
        UNIV2_ROUTER_ADDRESS = _uniV2RouterAddress;
    }

    function _validateData()
        private
    {
        for (uint256 i = 0; i < TOKENS; i++) {

            TokenData memory token = tokens[i];

            if (token.tokenDecimals == 0) {
                revert InvalidDecimals();
            }

            if (token.feedDecimals == 0) {
                revert InvalidDecimals();
            }

            if (token.tokenERC20 == IERC20(ZERO_ADDRESS)) {
                revert InvalidToken();
            }

            if (token.feedLink == IChainLink(ZERO_ADDRESS)) {
                revert InvalidFeed();
            }

            string memory expectedFeedName = string.concat(
                token.tokenERC20.symbol(),
                " / "
                "ETH"
            );

            string memory chainLinkFeedName = token.feedLink.description();

            require(
                keccak256(abi.encodePacked(expectedFeedName)) ==
                keccak256(abi.encodePacked(chainLinkFeedName)),
                "AdapterDeclarations: INVALID_CHAINLINK_FEED"
            );

            recalibrate(
                address(token.feedLink)
            );
        }
    }

    /**
     * @dev Determines info for the heartbeat update
     *  mechanism for chainlink oracles (roundIds)
     */
    function getLatestAggregatorRoundId(
        IChainLink _feed
    )
        public
        view
        returns (uint80)
    {
        (
            uint80 roundId,
            ,
            ,
            ,
        ) = _feed.latestRoundData();

        return uint64(roundId);
    }

    /**
     * @dev Determines number of iterations necessary during recalibrating
     * heartbeat.
     */
    function _getIterationCount(
        uint80 _latestAggregatorRoundId
    )
        internal
        pure
        returns (uint80)
    {
        return _latestAggregatorRoundId > MAX_ROUND_COUNT
            ? MAX_ROUND_COUNT
            : _latestAggregatorRoundId;
    }

    /**
     * @dev fetches timestamp of a byteshifted aggregatorRound with specific
     * phaseID. For more info see chainlink historical price data documentation
     */
    function _getRoundTimestamp(
        IChainLink _feed,
        uint16 _phaseId,
        uint80 _aggregatorRoundId
    )
        internal
        view
        returns (uint256)
    {
        (
            ,
            ,
            ,
            uint256 timestamp,
        ) = _feed.getRoundData(
            getRoundIdByByteShift(
                _phaseId,
                _aggregatorRoundId
            )
        );

        return timestamp;
    }

    /**
     * @dev Determines info for the heartbeat update mechanism for chainlink
     * oracles (shifted round Ids)
     */
    function getRoundIdByByteShift(
        uint16 _phaseId,
        uint80 _aggregatorRoundId
    )
        public
        pure
        returns (uint80)
    {
        return uint80(uint256(_phaseId) << 64 | _aggregatorRoundId);
    }

    /**
     * @dev Function to recalibrate the heartbeat for a specific feed
     */
    function recalibrate(
        address _feed
    )
        public
    {
        chainLinkHeartBeat[_feed] = recalibratePreview(
            IChainLink(_feed)
        );
    }

    /**
    * @dev View function to determine the heartbeat for a specific feed
    * Looks at the maximal last 50 rounds and takes second highest value to
    * avoid counting offline time of chainlink as valid heartbeat
    */
    function recalibratePreview(
        IChainLink _feed
    )
        public
        view
        returns (uint256)
    {
        uint80 latestAggregatorRoundId = getLatestAggregatorRoundId(
            _feed
        );

        uint80 iterationCount = _getIterationCount(
            latestAggregatorRoundId
        );

        if (iterationCount < 2) {
            revert("LiquidRouter: SMALL_SAMPLE");
        }

        uint16 phaseId = _feed.phaseId();
        uint256 latestTimestamp = _getRoundTimestamp(
            _feed,
            phaseId,
            latestAggregatorRoundId
        );

        uint256 currentDiff;
        uint256 currentBiggest;
        uint256 currentSecondBiggest;

        for (uint80 i = 1; i < iterationCount; i++) {

            uint256 currentTimestamp = _getRoundTimestamp(
                _feed,
                phaseId,
                latestAggregatorRoundId - i
            );

            currentDiff = latestTimestamp - currentTimestamp;

            latestTimestamp = currentTimestamp;

            if (currentDiff >= currentBiggest) {
                currentSecondBiggest = currentBiggest;
                currentBiggest = currentDiff;
            } else if (currentDiff > currentSecondBiggest && currentDiff < currentBiggest) {
                currentSecondBiggest = currentDiff;
            }
        }

        return currentSecondBiggest;
    }

    function setApprovals()
        external
    {
        address[2] memory spenders = [
            UNIV2_ROUTER_ADDRESS,
            LIQUID_NFT_ROUTER_ADDRESS
        ];

        for (uint256 i = 0; i < spenders.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                tokenProfit.executeAdapterRequest(
                    address(tokens[j].tokenERC20),
                    abi.encodeWithSelector(
                        IERC20.approve.selector,
                        spenders[i],
                        UINT256_MAX
                    )
                );
            }
            tokenProfit.executeAdapterRequest(
                WETH_ADDRESS,
                abi.encodeWithSelector(
                    IERC20.approve.selector,
                    spenders[i],
                    UINT256_MAX
                )
            );
        }
    }
}

// SPDX-License-Identifier: --DAO--

/**
 * @author René Hochmuth
 * @author Vitally Marinchenko
 */

pragma solidity =0.8.19;

import "./IERC20.sol";

interface IChainLink {

    function decimals()
        external
        view
        returns (uint8);

    function latestAnswer()
        external
        view
        returns (uint256);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answerdInRound
        );

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function phaseId()
        external
        view
        returns(
            uint16 phaseId
        );

    function aggregator()
        external
        view
        returns (address);

    function description()
        external
        view
        returns (string memory);
}

interface ITokenProfit {

    function getAvailableMint()
        external
        view
        returns (uint256);

    function executeAdapterRequest(
        address _contractToCall,
        bytes memory _callBytes
    )
        external
        returns (bytes memory);

    function executeAdapterRequestWithValue(
        address _contractToCall,
        bytes memory _callBytes,
        uint256 _value
    )
        external
        returns (bytes memory);

    function totalSupply()
        external
        view
        returns (uint256);
}

interface ILiquidNFTsRouter {

    function depositFunds(
        uint256 _amount,
        address _pool
    )
        external;

    function withdrawFunds(
        uint256 _amount,
        address _pool
    )
        external;
}

interface ILiquidNFTsPool {

    function pseudoTotalTokensHeld()
        external
        view
        returns (uint256);

    function totalInternalShares()
        external
        view
        returns (uint256);

    function manualSyncPool()
        external;

    function internalShares(
        address _user
    )
        external
        view
        returns (uint256);

    function poolToken()
        external
        view
        returns (address);

    function chainLinkETH()
        external
        view
        returns (address);
}

interface IUniswapV2 {

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
      external
      payable
      returns (uint256[] memory amounts);

    function swapExactTokensForETH(
       uint256 amountIn,
       uint256 amountOutMin,
       address[] calldata path,
       address to,
       uint256 deadline
   )
       external
       returns (uint256[] memory amounts);
}

interface IWETH is IERC20 {

    function deposit()
        payable
        external;

    function withdraw(
        uint256 _amount
    )
        external;
}

// SPDX-License-Identifier: --DAO--

/**
 * @author René Hochmuth
 * @author Vitally Marinchenko
 */

pragma solidity =0.8.19;

interface IERC20 {

    function transfer(
        address _to,
        uint256 _amount
    )
        external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )
        external;

    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256);

    function approve(
        address _spender,
        uint256 _amount
    )
        external;

    function allowance(
        address _user,
        address _spender
    )
        external
        view
        returns (uint256);

    function decimals()
        external
        view
        returns (uint8);

    function symbol()
        external
        view
        returns (string memory);
}