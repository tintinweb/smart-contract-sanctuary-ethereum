// SPDX-License-Identifier: MIT

// *************************************************************************************************************************************
// *************************************************************************************************************************************
// *****************.     .,*/**********************************************************************************************************
// ************                 ,*******************************************************************************************************
// *********.          .         **********************************************************************/********************************
// ********      ############ ,**********&@@@@@@@@@@@@@@@@/****@@@@@@@@@@@@@@@@@@%/**%@&*************/@@****&@@@@@@@@@@@@@@@@@@@&/******
// *******     #############*   ********@@***************/*****@@**************/*@@**%@&**************@@*************%@&****************
// *****/     #####**(###(**    .*******@@@********************@@****************%@@*%@&**************@@*************%@&****************
// ******     ####********/##     *********&@@@@@#/************@@***************/@@**%@&**************@@*************%@&****************
// ******.    ###***/****/####    *****************%@@@@@/*****@@@@@@@@@@@@@@@@@@****%@&**************@@*************%@&****************
// *******     /**####**(###%.    ***********************@@@***@@********************%@&**************@@*************%@&****************
// ********,  .(############,     ************************@@***@@*********************@@**************@@*************%@&****************
// ********** (###########..     *******@@@@@@@@@@@@@@@@@@@****@@**********************@@@@@@@@@%(****@@*************%@&****************
// *******,           .       .*************/((((((((/*********//*************************************/*********************************
// ********.                .***********************************************************************************************************
// *************.     .,****************************************************************************************************************
// *************************************************************************************************************************************
// *************************************************************************************************************************************

pragma solidity 0.8.13;

interface IFlashLender {
    function flashLoan(address receiver, address token, uint256 amount, bytes calldata data) external returns (bool);
}

interface ILendingPool {
    function flashLoanSimple(address receiverAddress, address asset, uint256 amount, bytes calldata params, uint16 referralCode) external;
}

contract SplitRouter {

    struct SwapData {
        uint256 volume;
        uint256 minOut;
        uint256 slippage;
        uint256 slPrice;
        uint256 tpPrice;
        uint256 trailingDelta;
        uint256 orderType;
        uint256 arbVolume;
        uint256 burnAmount;
        bytes32 tailPool;
        bytes32 partner;
        address swapRouter;
        address trader;
        address fromToken;
        address toToken;
        bool isCross;
        bytes swapInputData;
    }

    struct RpcSwapData {
        uint256 volume;
        uint256 arbVolume;
        bytes32 partner;
        address swapRouter;
        address trader;
        address fromToken;
        bool isSimple;
        bytes swapInputData;
    }

    struct CompletedOrder {
        uint256 volume;
        uint256 amountOut;
        uint256 orderType;
        address trader;
        address fromToken;
        address toToken;
    }

    error CompleteTransferError(uint256);
    error TailSwapError(uint256);

    event Reward(address indexed trader, address indexed partner, uint256 reward, uint256 collectorReward);
    event TxFee(address indexed trader, uint256 txfee);
    event Swap(address indexed trader, address indexed fromToken, address indexed toToken, uint256 volume, uint256 amountOut, uint256 slippage, uint256 slPrice, uint256 tpPrice, uint256 trailingDelta, bytes32 partner);
    event MinProfitChanged(uint256 profitMin);

    address private deployer;
    uint256 private entryStatus;
    address private arbChecker;
    address private arbRunner;
    address private profitCollector;
    uint256 public minProfit;
    uint256 private profitSlot;
    mapping(address => bool) private isWorker;
    mapping(address => bool) private isAllowedSwapSource;
    mapping(address => CompletedOrder[]) private orderHistory;
    address public SPLX_TOKEN;
    address public immutable FL_POOL;
    address private immutable WETH;
    uint256 private immutable CHAIN_ID;
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant HEXFF = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
    uint256 private constant SWAP_FEE_DENOM = 1000000000;
    uint256 private constant MAX_BURN_AMOUNT = 1e20;

    modifier onlyOwner() {
        require(msg.sender == deployer, "Split: Not allowed");
        _;
    }

    modifier onlyWorker() {
        require(isWorker[msg.sender], "Split: Not worker");
        _;
    }

    modifier nonReentrant() {
        require(entryStatus == 0, "Split: Re-entered");
        entryStatus = 1;
        _;
        entryStatus = 0;
    }

    modifier onlyFLPool() {
        require(msg.sender == FL_POOL, "Split: Not allowed");
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), "Split: Not allowed");
        _;
    }

    constructor(address _weth, uint256 _chainID, uint256 _minProfit, address _flPool, address _splxToken, address _arbChecker, address _arbRunner, address _profitCollector) {
        deployer = msg.sender;
        WETH = _weth;
        CHAIN_ID = _chainID;
        FL_POOL = _flPool;
        SPLX_TOKEN = _splxToken;
        arbChecker = _arbChecker;
        arbRunner = _arbRunner;
        minProfit = _minProfit;
        profitCollector = _profitCollector;
    }

    receive() external payable {

    }

    fallback() external payable {

    }

    function setTokenSPLX(address _splxToken) external onlyOwner {
        SPLX_TOKEN = _splxToken;
    }

    function getReserveData() external view returns (uint256 flReserve) {
        address weth = WETH;
        address flpool = FL_POOL;
        uint256 chid = CHAIN_ID;
        assembly {
            let ptr := mload(0x40)
            if or(eq(chid, 1), eq(chid, 56)) {
                mstore(ptr, shl(0xe0, 0x613255ab))
                mstore(add(ptr, 0x04), weth)
                if iszero(staticcall(gas(), flpool, ptr, 0x24, ptr, 0x20)) { revert(0, 0) }
                flReserve := mload(ptr)
            }
            if and(iszero(eq(chid, 1)), iszero(eq(chid, 56))) {
                mstore(ptr, shl(0xe0, 0x35ea6a75))
                mstore(add(ptr, 0x04), weth)
                if iszero(staticcall(gas(), flpool, ptr, 0x24, ptr, 0x40)) { revert(0, 0) }
                flReserve := mload(add(ptr, 0x20))
            }
        }
    }

    function getOrderHistoryPagesCount(address trader) external view returns (uint256 pagesCount) {
        uint256 orderHistorySize = orderHistory[trader].length;
        pagesCount = orderHistorySize / 10;
        if (orderHistorySize % 10 > 0) {
            pagesCount++;
        }
    }

    function getOrderHistoryPage(uint256 pageID, address trader) external view returns (uint256[] memory volumes, uint256[] memory amountsOut, uint256[] memory orderTypes, address[] memory fromTokens, address[] memory toTokens) {
        volumes = new uint256[](10);
        amountsOut = new uint256[](10);
        orderTypes = new uint256[](10);
        fromTokens = new address[](10);
        toTokens = new address[](10);
        uint256 orderHistorySize = orderHistory[trader].length;
        uint256 pstart = orderHistorySize - (pageID * 10) - 1;
        for (uint256 i = 0; i < 10; i++) {
            CompletedOrder memory orderData = orderHistory[trader][pstart];
            (volumes[i], amountsOut[i], orderTypes[i], fromTokens[i], toTokens[i]) = (orderData.volume, orderData.amountOut, orderData.orderType, orderData.fromToken, orderData.toToken);
            if (pstart > 0) {
                pstart--;
            } else {
                break;
            }
        }
    }

    function getUserBalances(address user, address[] calldata tokens) external view returns (uint256[] memory balances) {
        balances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i] = _balanceOf(user, tokens[i]);
        }
    }

    function setSwapSourceStatus(bool status, address[] calldata swapSources) external onlyOwner {
        for (uint256 i = 0; i < swapSources.length; i++) {
            isAllowedSwapSource[swapSources[i]] = status;
        }
    }

    function setWorkerStatus(bool status, address[] calldata workers) external onlyOwner {
        for (uint256 i = 0; i < workers.length; i++) {
            isWorker[workers[i]] = status;
        }
    }

    function setMinProfit(uint256 _minProfit) external onlyOwner {
        minProfit = _minProfit;
        emit MinProfitChanged(_minProfit);
    }

    function setProfitCollector(address _profitCollector) external onlyOwner {
        profitCollector = _profitCollector;
    }

    function destroySelf() external onlyOwner {
        assembly {
            selfdestruct(caller())
        }
    }

    function rescueFunds(address token) external onlyOwner {
        assembly {
            if eq(token, ETH) {
                if iszero(call(gas(), caller(), balance(address()), 0, 0, 0, 0)) { revert(0, 0) }
            }
            if iszero(eq(token, ETH)) {
                let ptr := mload(0x40)
                mstore(ptr, shl(0xe0, 0x70a08231))
                mstore(add(ptr, 0x04), address())
                if iszero(staticcall(gas(), token, ptr, 0x24, ptr, 0x20)) { revert(0, 0) }
                let amount := mload(ptr)
                mstore(ptr, shl(0xe0, 0xa9059cbb))
                mstore(add(ptr, 0x04), caller())
                mstore(add(ptr, 0x24), amount)
                if iszero(call(gas(), token, 0, ptr, 0x44, 0, 0)) { revert(0, 0) }
            }
        }
    }

    function transferOwnership(address _owner) external onlyOwner {
        deployer = _owner;
    }

    function setArbitrageParams(address arbAddr, bool isRunner) external onlyOwner {
        if (isRunner) {
            arbRunner = arbAddr;
        } else {
            arbChecker = arbAddr;
        }
    }

    function wrap() external payable nonReentrant {
        require(msg.value > 0, "Split: volume is zero");
        address weth = WETH;
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, shl(0xe0, 0xd0e30db0))
            if iszero(call(gas(), weth, callvalue(), ptr, 0x04, 0, 0)) { revert(0, 0) }
            mstore(ptr, shl(0xe0, 0xa9059cbb))
            mstore(add(ptr, 0x04), caller())
            mstore(add(ptr, 0x24), callvalue())
            if iszero(call(gas(), weth, 0, ptr, 0x44, 0, 0)) { revert(0, 0) }
        }
    }

    function unwrap(uint256 volume) external nonReentrant {
        require(volume > 0, "Split: volume is zero");
        address weth = WETH;
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, shl(0xe0, 0x23b872dd))
            mstore(add(ptr, 0x04), caller())
            mstore(add(ptr, 0x24), address())
            mstore(add(ptr, 0x44), volume)
            if iszero(call(gas(), weth, 0, ptr, 0x64, 0, 0)) { revert(0, 0) }
            mstore(ptr, shl(0xe0, 0x2e1a7d4d))
            mstore(add(ptr, 0x04), volume)
            if iszero(call(gas(), weth, 0, ptr, 0x24, 0, 0)) { revert(0, 0) }
            if iszero(call(gas(), caller(), volume, 0, 0, 0, 0)) { revert(0, 0) }
        }
    }

    function unwrapGL(uint256 txfee, uint256 volume, bytes32 partner, address trader) external onlyWorker {
        require(volume > txfee, "Split: volume is less than fee");
        address weth = WETH;
        uint256 ltxfee;
        assembly {
            let partnerShare := div(partner, HEXFF)
            let p := sub(mod(partner, HEXFF), partnerShare)
            let ptxfee := div(mul(txfee, partnerShare), 100)
            ltxfee := sub(txfee, ptxfee)
            let ptr := mload(0x40)
            mstore(ptr, shl(0xe0, 0x23b872dd))
            mstore(add(ptr, 0x04), trader)
            mstore(add(ptr, 0x24), address())
            mstore(add(ptr, 0x44), volume)
            if iszero(call(gas(), weth, 0, ptr, 0x64, 0, 0)) { revert(0, 0) }
            mstore(ptr, shl(0xe0, 0x2e1a7d4d))
            mstore(add(ptr, 0x04), volume)
            if iszero(call(gas(), weth, 0, ptr, 0x24, 0, 0)) { revert(0, 0) }
            if gt(ptxfee, 0) {
                if iszero(call(gas(), p, ptxfee, 0, 0, 0, 0)) { revert(0, 0) }
            }
            if iszero(call(gas(), caller(), ltxfee, 0, 0, 0, 0)) { revert(0, 0) }
            if iszero(call(gas(), trader, sub(volume, txfee), 0, 0, 0, 0)) { revert(0, 0) }
        }
        emit TxFee(trader, ltxfee);
    }

    function swapETH(bytes calldata dataBytes, bytes calldata chainBytes) external payable nonReentrant {
        SwapData memory swapData = abi.decode(dataBytes, (SwapData));
        require(isAllowedSwapSource[swapData.swapRouter], "Split: this source is unsafe");
        require(swapData.trader == msg.sender, "Split: malicious sender");
        require(msg.value > 0 && swapData.volume == msg.value, "Split: volume is bad or zero");
        require(swapData.fromToken == ETH, "Split: fromToken is not native");
        require(swapData.fromToken != swapData.toToken || swapData.isCross, "Split: same tokens");
        require(swapData.toToken != WETH, "Split: wrap not allowed");
        uint256 toBeforeBalance = (swapData.isCross) ? 0 : _balanceOf(msg.sender, swapData.toToken);
        {
            (bool success, bytes memory data) = swapData.swapRouter.call{value: msg.value}(swapData.swapInputData);
            if (!success) {
                if (data.length == 0) {
                    revert("Split: swapRouter tx failed");
                } else {
                    assembly {
                        revert(add(data, 32), mload(data))
                    }
                }
            }
        }
        if (!swapData.isCross) {
            uint256 outAmount;
            {
                uint256 toAfterBalance = _balanceOf(msg.sender, swapData.toToken);
                require(toAfterBalance > toBeforeBalance, "Split: after less than before");
                assembly {
                    outAmount := sub(toAfterBalance, toBeforeBalance)
                }
                require(outAmount >= swapData.minOut, "Split: slippage too high");
            }
            {
                CompletedOrder memory completedOrderData = CompletedOrder(swapData.volume, outAmount, swapData.orderType, msg.sender, swapData.fromToken, swapData.toToken);
                orderHistory[msg.sender].push(completedOrderData);
            }
            emit Swap(msg.sender, swapData.fromToken, swapData.toToken, swapData.volume, outAmount, swapData.slippage, swapData.slPrice, swapData.tpPrice, swapData.trailingDelta, swapData.partner);
        }
        if (chainBytes.length > 4) {
            (bool checkSuccess, bytes memory checkData) = arbChecker.staticcall(chainBytes);
            if (checkSuccess) {
                uint256 profit = abi.decode(checkData, (uint256));
                if (profit >= minProfit) {
                    address(this).call{value: 0}(abi.encodeWithSelector(0x04c5a9ff, swapData.arbVolume, swapData.burnAmount, 0, swapData.partner, msg.sender, address(0), chainBytes));
                }
            }
        }
    }

    function swap(bytes calldata dataBytes, bytes calldata chainBytes) external nonReentrant {
        SwapData memory swapData = abi.decode(dataBytes, (SwapData));
        require(isAllowedSwapSource[swapData.swapRouter], "Split: this source is unsafe");
        require(swapData.trader == msg.sender, "Split: malicious sender");
        require(swapData.volume > 0, "Split: volume is zero");
        require(swapData.fromToken != ETH, "Split: fromToken is native");
        require(swapData.fromToken != swapData.toToken || swapData.isCross, "Split: same tokens");
        if (swapData.fromToken == WETH) {
            require(swapData.toToken != ETH, "Split: unwrap not allowed");
        }
        {
            address fromToken = swapData.fromToken;
            uint256 volume = swapData.volume;
            address swaprouter = swapData.swapRouter;
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, shl(0xe0, 0x23b872dd))
                mstore(add(ptr, 0x04), caller())
                mstore(add(ptr, 0x24), address())
                mstore(add(ptr, 0x44), volume)
                if iszero(call(gas(), fromToken, 0, ptr, 0x64, 0, 0)) { revert(0, 0) }
                mstore(ptr, shl(0xe0, 0x095ea7b3))
                mstore(add(ptr, 0x04), swaprouter)
                mstore(add(ptr, 0x24), volume)
                if iszero(call(gas(), fromToken, 0, ptr, 0x44, 0, 0)) { revert(0, 0) }
            }
        }
        uint256 toBeforeBalance = (swapData.isCross) ? 0 : _balanceOf(msg.sender, swapData.toToken);
        {
            (bool success, bytes memory data) = swapData.swapRouter.call{value: 0}(swapData.swapInputData);
            if (!success) {
                if (data.length == 0) {
                    revert("Split: swapRouter tx failed");
                } else {
                    assembly {
                        revert(add(data, 32), mload(data))
                    }
                }
            }
        }
        if (!swapData.isCross) {
            uint256 outAmount;
            {
                uint256 toAfterBalance = _balanceOf(msg.sender, swapData.toToken);
                require(toAfterBalance > toBeforeBalance, "Split: after less than before");
                assembly {
                    outAmount := sub(toAfterBalance, toBeforeBalance)
                }
                require(outAmount >= swapData.minOut, "Split: slippage too high");
            }
            {
                CompletedOrder memory completedOrderData = CompletedOrder(swapData.volume, outAmount, swapData.orderType, msg.sender, swapData.fromToken, swapData.toToken);
                orderHistory[msg.sender].push(completedOrderData);
            }
            emit Swap(msg.sender, swapData.fromToken, swapData.toToken, swapData.volume, outAmount, swapData.slippage, swapData.slPrice, swapData.tpPrice, swapData.trailingDelta, swapData.partner);
        }
        if (chainBytes.length > 4) {
            (bool checkSuccess, bytes memory checkData) = arbChecker.staticcall(chainBytes);
            if (checkSuccess) {
                uint256 profit = abi.decode(checkData, (uint256));
                if (profit >= minProfit) {
                    address(this).call{value: 0}(abi.encodeWithSelector(0x04c5a9ff, swapData.arbVolume, swapData.burnAmount, 0, swapData.partner, msg.sender, address(0), chainBytes));
                }
            }
        }
    }

    function swapGL(uint256 txfee, bytes calldata dataBytes, bytes calldata chainBytes) external onlyWorker {
        SwapData memory swapData = abi.decode(dataBytes, (SwapData));
        require(swapData.volume > txfee, "Split: volume is less than fee");
        require(swapData.fromToken != ETH, "Split: fromToken is native");
        require(swapData.fromToken != swapData.toToken || swapData.isCross, "Split: same tokens");
        {
            address fromToken = swapData.fromToken;
            address trader = swapData.trader;
            uint256 volume = swapData.volume;
            address swaprouter = swapData.swapRouter;
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, shl(0xe0, 0x23b872dd))
                mstore(add(ptr, 0x04), trader)
                mstore(add(ptr, 0x24), address())
                mstore(add(ptr, 0x44), volume)
                if iszero(call(gas(), fromToken, 0, ptr, 0x64, 0, 0)) { revert(0, 0) }
                mstore(ptr, shl(0xe0, 0x095ea7b3))
                mstore(add(ptr, 0x04), swaprouter)
                mstore(add(ptr, 0x24), volume)
                if iszero(call(gas(), fromToken, 0, ptr, 0x44, 0, 0)) { revert(0, 0) }
            }
        }
        _tailSwap(txfee, swapData.tailPool, swapData.partner, swapData.fromToken, swapData.trader);
        uint256 toBeforeBalance = (swapData.isCross) ? 0 : _balanceOf(swapData.trader, swapData.toToken);
        {
            (bool success, bytes memory data) = swapData.swapRouter.call{value: 0}(swapData.swapInputData);
            if (!success) {
                if (data.length == 0) {
                    revert("Split: swapRouter tx failed");
                } else {
                    assembly {
                        revert(add(data, 32), mload(data))
                    }
                }
            }
        }
        if (!swapData.isCross) {
            uint256 outAmount;
            {
                uint256 toAfterBalance = _balanceOf(swapData.trader, swapData.toToken);
                require(toAfterBalance > toBeforeBalance, "Split: after less than before");
                assembly {
                    outAmount := sub(toAfterBalance, toBeforeBalance)
                }
                require(outAmount >= swapData.minOut, "Split: slippage too high");
            }
            {
                CompletedOrder memory completedOrderData = CompletedOrder(swapData.volume, outAmount, swapData.orderType, swapData.trader, swapData.fromToken, swapData.toToken);
                orderHistory[swapData.trader].push(completedOrderData);
            }
            emit Swap(swapData.trader, swapData.fromToken, swapData.toToken, swapData.volume, outAmount, swapData.slippage, swapData.slPrice, swapData.tpPrice, swapData.trailingDelta, swapData.partner);
        }
        if (chainBytes.length > 4) {
            (bool checkSuccess, bytes memory checkData) = arbChecker.staticcall(chainBytes);
            if (checkSuccess) {
                uint256 profit = abi.decode(checkData, (uint256));
                if (profit >= minProfit) {
                    address(this).call{value: 0}(abi.encodeWithSelector(0x04c5a9ff, swapData.arbVolume, swapData.burnAmount, 0, swapData.partner, swapData.trader, msg.sender, chainBytes));
                }
            }
        }
    }

    function rpcTx(uint256 txfee, address[] calldata usedTokens, bytes calldata dataBytes, bytes calldata chainBytes) external onlyWorker {
        RpcSwapData memory rpcData = abi.decode(dataBytes, (RpcSwapData));
        require(rpcData.fromToken != ETH, "Split: fromToken is native");
        if (rpcData.isSimple) {
            uint256 volume = rpcData.volume;
            address fromToken = rpcData.fromToken;
            address trader = rpcData.trader;
            address swaprouter = rpcData.swapRouter;
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, shl(0xe0, 0x23b872dd))
                mstore(add(ptr, 0x04), trader)
                mstore(add(ptr, 0x24), address())
                mstore(add(ptr, 0x44), volume)
                if iszero(call(gas(), fromToken, 0, ptr, 0x64, 0, 0)) { revert(0, 0) }
                mstore(ptr, shl(0xe0, 0x095ea7b3))
                mstore(add(ptr, 0x04), swaprouter)
                mstore(add(ptr, 0x24), volume)
                if iszero(call(gas(), fromToken, 0, ptr, 0x44, 0, 0)) { revert(0, 0) }
            }
        }
        {
            (bool execSuccess, bytes memory execData) = address(this).call{value: 0}(abi.encodeWithSelector(0x69aac991, !rpcData.isSimple, usedTokens, dataBytes));
            if (!execSuccess) {
                assembly {
                    revert(add(execData, 32), mload(execData))
                }
            }
        }
        require(chainBytes.length > 4, "Split: bad chain");
        {
            (bool checkSuccess, bytes memory checkData) = arbChecker.staticcall(chainBytes);
            require(checkSuccess, "Split: arb check failed");
            uint256 profit = abi.decode(checkData, (uint256));
            require(profit >= minProfit, "Split: not profitable");
        }
        (bool runSuccess, bytes memory runData) = address(this).call{value: 0}(abi.encodeWithSelector(0x04c5a9ff, rpcData.arbVolume, 0, txfee, rpcData.partner, rpcData.trader, msg.sender, chainBytes));
        if (!runSuccess) {
            assembly {
                revert(add(runData, 32), mload(runData))
            }
        }
    }

    function execTx(bool needFromTransfer, address[] calldata usedTokens, bytes calldata dataBytes) external onlySelf {
        RpcSwapData memory rpcData = abi.decode(dataBytes, (RpcSwapData));
        uint256[] memory usedTokensStartBalances = new uint256[](usedTokens.length);
        address trader = rpcData.trader;
        for (uint256 i = 0; i < usedTokens.length; i++) {
            address usedToken = usedTokens[i];
            uint256 usedTokenStartBalance;
            address swaprouter = rpcData.swapRouter;
            assembly {
                function bof(ptr, account, token) -> bal {
                    mstore(ptr, shl(0xe0, 0x70a08231))
                    mstore(add(ptr, 0x04), account)
                    if iszero(staticcall(gas(), token, ptr, 0x24, ptr, 0x20)) { revert(0, 0) }
                    bal := mload(ptr)
                }

                if eq(usedToken, ETH) {
                    usedTokenStartBalance := balance(address())
                }
                if iszero(eq(usedToken, ETH)) {
                    let ptr := mload(0x40)
                    usedTokenStartBalance := bof(ptr, address(), usedToken)
                    if needFromTransfer {
                        let usedTokenTraderBalance := bof(ptr, trader, usedToken)
                        if gt(usedTokenTraderBalance, 0) {
                            mstore(ptr, shl(0xe0, 0x23b872dd))
                            mstore(add(ptr, 0x04), trader)
                            mstore(add(ptr, 0x24), address())
                            mstore(add(ptr, 0x44), usedTokenTraderBalance)
                            if call(gas(), usedToken, 0, ptr, 0x64, 0, 0) {
                                mstore(ptr, shl(0xe0, 0x095ea7b3))
                                mstore(add(ptr, 0x04), swaprouter)
                                mstore(add(ptr, 0x24), usedTokenTraderBalance)
                                if iszero(call(gas(), usedToken, 0, ptr, 0x44, 0, 0)) { revert(0, 0) }
                            }
                        }
                    }
                }
            }
            usedTokensStartBalances[i] = usedTokenStartBalance;
        }
        (bool success, bytes memory rpdata) = rpcData.swapRouter.call{value: 0}(rpcData.swapInputData);
        if (!success) {
            if (rpdata.length == 0) {
                revert("Split: swapRouter tx failed");
            } else {
                assembly {
                    revert(add(rpdata, 32), mload(rpdata))
                }
            }
        }
        for (uint256 i = 0; i < usedTokens.length; i++) {
            address usedToken = usedTokens[i];
            uint256 usedTokenStartBalance = usedTokensStartBalances[i];
            assembly {
                function bof(ptr, account, token) -> bal {
                    mstore(ptr, shl(0xe0, 0x70a08231))
                    mstore(add(ptr, 0x04), account)
                    if iszero(staticcall(gas(), token, ptr, 0x24, ptr, 0x20)) { revert(0, 0) }
                    bal := mload(ptr)
                }

                if eq(usedToken, ETH) {
                    let usedTokenBalance := balance(address())
                    if gt(usedTokenBalance, usedTokenStartBalance) {
                        if iszero(call(gas(), trader, sub(usedTokenBalance, usedTokenStartBalance), 0, 0, 0, 0)) { revert(0, 0) }
                    }
                }
                if iszero(eq(usedToken, ETH)) {
                    let ptr := mload(0x40)
                    let usedTokenBalance := bof(ptr, address(), usedToken)
                    if gt(usedTokenBalance, usedTokenStartBalance) {
                        mstore(ptr, shl(0xe0, 0xa9059cbb))
                        mstore(add(ptr, 0x04), trader)
                        mstore(add(ptr, 0x24), sub(usedTokenBalance, usedTokenStartBalance))
                        if iszero(call(gas(), usedToken, 0, ptr, 0x44, 0, 0)) { revert(0, 0) }
                    }
                }
            }
        }
    }

    function executeArb(uint256 arbVolume, uint256 burnAmount, uint256 txfee, bytes32 partner, address trader, address splxworker, bytes calldata chainBytes) external onlySelf {
        if (CHAIN_ID == 1 || CHAIN_ID == 56) {
            IFlashLender(FL_POOL).flashLoan(address(this), WETH, arbVolume, chainBytes);
        } else {
            ILendingPool(FL_POOL).flashLoanSimple(address(this), WETH, arbVolume, chainBytes, 0);
        }
        uint256 profit = profitSlot;
        profitSlot = 0;
        uint256 burntAmount = _burnTokens(trader, burnAmount);
        if (txfee > 0) {
            profit = _sendTxFee(profit, txfee, partner, trader, splxworker);
        }
        uint256 collectorAmount = _completeTransfers(profit, burntAmount, partner, trader);
        address partnerAddr;
        assembly {
            let partnerShare := div(partner, HEXFF)
            partnerAddr := sub(mod(partner, HEXFF), partnerShare)
        }
        emit Reward(trader, partnerAddr, profit, collectorAmount);
    }

    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata params) external onlyFLPool returns (bool) {
        _onFL(asset, amount, premium, params);
        return true;
    }

    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data) external onlyFLPool returns (bytes32) {
        _onFL(token, amount, fee, data);
        return keccak256('ERC3156FlashBorrower.onFlashLoan');
    }

    function _sendTxFee(uint256 txprofit, uint256 txfee, bytes32 partnerData, address trader, address splxworker) internal returns (uint256 profit) {
        require(txprofit > txfee, "Split: profit less than txfee");
        bytes4 errorSelector = CompleteTransferError.selector;
        address weth = WETH;
        address runner = arbRunner;
        uint256 ltxfee;
        assembly {
            function revertWithCode(ptr, errsig, errcode) {
                mstore(ptr, errsig)
                mstore(add(ptr, 0x04), errcode)
                revert(ptr, 0x24)
            }

            let partnerShare := div(partnerData, HEXFF)
            let partner := sub(mod(partnerData, HEXFF), partnerShare)
            let ptxfee := div(mul(txfee, partnerShare), 100)
            ltxfee := sub(txfee, ptxfee)
            let ptr := mload(0x40)
            mstore(ptr, shl(0xe0, 0x23b872dd))
            mstore(add(ptr, 0x04), runner)
            mstore(add(ptr, 0x24), address())
            mstore(add(ptr, 0x44), txfee)
            if iszero(call(gas(), weth, 0, ptr, 0x64, 0, 0)) { revertWithCode(ptr, errorSelector, 1) }
            mstore(ptr, shl(0xe0, 0x2e1a7d4d))
            mstore(add(ptr, 0x04), txfee)
            if iszero(call(gas(), weth, 0, ptr, 0x24, 0, 0)) { revertWithCode(ptr, errorSelector, 2) }
            if gt(ptxfee, 0) {
                if iszero(call(gas(), partner, ptxfee, 0, 0, 0, 0)) { revertWithCode(ptr, errorSelector, 4) }
            }
            if iszero(call(gas(), splxworker, ltxfee, 0, 0, 0, 0)) { revertWithCode(ptr, errorSelector, 3) }
            profit := sub(txprofit, txfee)
        }
        emit TxFee(trader, ltxfee);
    }

    function _completeTransfers(uint256 profit, uint256 burntAmount, bytes32 partner, address trader) internal returns (uint256 collectorAmount) {
        address weth = WETH;
        address collector = profitCollector;
        address runner = arbRunner;
        bytes4 errorSelector = CompleteTransferError.selector;
        assembly {
            function revertWithCode(ptr, errsig, errcode) {
                mstore(ptr, errsig)
                mstore(add(ptr, 0x04), errcode)
                revert(ptr, 0x24)
            }

            function wtfrom(ptr, s, r, t, vol, errsig, errcode) {
                mstore(ptr, shl(0xe0, 0x23b872dd))
                mstore(add(ptr, 0x04), s)
                mstore(add(ptr, 0x24), r)
                mstore(add(ptr, 0x44), vol)
                if iszero(call(gas(), t, 0, ptr, 0x64, 0, 0)) { revertWithCode(ptr, errsig, errcode) }
            }
            
            let ptr := mload(0x40)
            if eq(sub(mod(partner, HEXFF), div(partner, HEXFF)), trader) {
                wtfrom(ptr, runner, trader, weth, add(div(profit, 2), mul(div(profit, 1000), div(burntAmount, exp(10, 18)))), errorSelector, 6)
            }
            if iszero(eq(sub(mod(partner, HEXFF), div(partner, HEXFF)), trader)) {
                if eq(div(partner, HEXFF), 0) {
                    wtfrom(ptr, runner, trader, weth, add(div(profit, 2), mul(div(profit, 1000), div(burntAmount, exp(10, 18)))), errorSelector, 5)
                }
                if iszero(eq(div(partner, HEXFF), 0)) {
                    let partnerAmount := div(mul(profit, div(partner, HEXFF)), 100)
                    wtfrom(ptr, runner, sub(mod(partner, HEXFF), div(partner, HEXFF)), weth, partnerAmount, errorSelector, 8)
                    let traderAmount := sub(add(div(profit, 2), mul(div(profit, 1000), div(burntAmount, exp(10, 18)))), partnerAmount)
                    if gt(traderAmount, 0) {
                        wtfrom(ptr, runner, trader, weth, traderAmount, errorSelector, 7)
                    }
                }
            }
            collectorAmount := sub(profit, add(div(profit, 2), mul(div(profit, 1000), div(burntAmount, exp(10, 18)))))
            wtfrom(ptr, runner, collector, weth, collectorAmount, errorSelector, 9)
        }
    }

    function _onFL(address token, uint256 amount, uint256 fee, bytes memory chainBytes) internal {
        address runner = arbRunner;
        uint256 callres1;
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, shl(0xe0, 0xa9059cbb))
            mstore(add(ptr, 0x04), runner)
            mstore(add(ptr, 0x24), amount)
            callres1 := call(gas(), token, 0, ptr, 0x44, 0, 0)
        }
        require(callres1 == 1, "Split: transfer to run failed");
        (bool success, bytes memory data) = arbRunner.call{value: 0}(chainBytes);
        require(success, "Split: runner call failed");
        uint256 profit = abi.decode(data, (uint256));
        require(profit >= (minProfit + fee));
        profitSlot = profit - fee;
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, shl(0xe0, 0x23b872dd))
            mstore(add(ptr, 0x04), runner)
            mstore(add(ptr, 0x24), address())
            mstore(add(ptr, 0x44), add(amount, fee))
            let callres2 := call(gas(), token, 0, ptr, 0x64, 0, 0)
            if iszero(callres2) {
                callres1 := 2
            }
            if callres2 {
                mstore(ptr, shl(0xe0, 0x095ea7b3))
                mstore(add(ptr, 0x04), caller())
                mstore(add(ptr, 0x24), add(amount, fee))
                let callres3 := call(gas(), token, 0, ptr, 0x44, 0, 0)
                if iszero(callres3) {
                    callres1 := 3
                }
            }
        }
        require(callres1 != 2, "Split: backtrns run to rou fail");
        require(callres1 != 3, "Split: approve to flpool failed");
    }

    function _balanceOf(address account, address token) internal view returns (uint256 bal) {
        assembly {
            if eq(token, ETH) {
                bal := balance(account)
            }
            if iszero(eq(token, ETH)) {
                let ptr := mload(0x40)
                mstore(ptr, shl(0xe0, 0x70a08231))
                mstore(add(ptr, 0x04), account)
                if iszero(staticcall(gas(), token, ptr, 0x24, ptr, 0x20)) { revert(0, 0) }
                bal := mload(ptr)
            }
        }
    }

    function _tailSwap(uint256 txfee, bytes32 tailPool, bytes32 partnerData, address fromToken, address trader) internal {
        address weth = WETH;
        bytes4 errorSelector = TailSwapError.selector;
        uint256 ltxfee;
        assembly {
            function revertWithCode(ptr, errsig, errcode) {
                mstore(ptr, errsig)
                mstore(add(ptr, 0x04), errcode)
                revert(ptr, 0x24)
            }

            let partnerShare := div(partnerData, HEXFF)
            let partner := sub(mod(partnerData, HEXFF), partnerShare)
            let ptr := mload(0x40)
            if eq(fromToken, weth) {
                let ptxfee := div(mul(txfee, partnerShare), 100)
                ltxfee := sub(txfee, ptxfee)
                mstore(ptr, shl(0xe0, 0x2e1a7d4d))
                mstore(add(ptr, 0x04), txfee)
                if iszero(call(gas(), weth, 0, ptr, 0x24, 0, 0)) { revertWithCode(ptr, errorSelector, 1) }
                if gt(ptxfee, 0) {
                    if iszero(call(gas(), partner, ptxfee, 0, 0, 0, 0)) { revertWithCode(ptr, errorSelector, 8) }
                }
                if iszero(call(gas(), caller(), ltxfee, 0, 0, 0, 0)) { revertWithCode(ptr, errorSelector, 2) }
            }
            if iszero(eq(fromToken, weth)) {
                let tsfee := div(tailPool, HEXFF)
                let tpool := sub(mod(tailPool, HEXFF), tsfee)
                mstore(ptr, shl(0xe0, 0xa9059cbb))
                mstore(add(ptr, 0x04), tpool)
                mstore(add(ptr, 0x24), txfee)
                if iszero(call(gas(), fromToken, 0, ptr, 0x44, 0, 0)) { revertWithCode(ptr, errorSelector, 3) }
                mstore(ptr, shl(0xe0, 0x0902f1ac))
                if iszero(staticcall(gas(), tpool, ptr, 0x04, ptr, 0x40)) { revertWithCode(ptr, errorSelector, 4) }
                let r0 := mload(ptr)
                let r1 := mload(add(ptr, 0x20))
                let ttxfee := mul(tsfee, txfee)
                mstore(ptr, shl(0xe0, 0x022c0d9f))
                if lt(fromToken, weth) {
                    ttxfee := div(mul(ttxfee, r1), add(mul(r0, SWAP_FEE_DENOM), ttxfee))
                    mstore(add(ptr, 0x04), 0)
                    mstore(add(ptr, 0x24), ttxfee)
                }
                if lt(weth, fromToken) {
                    ttxfee := div(mul(ttxfee, r0), add(mul(r1, SWAP_FEE_DENOM), ttxfee))
                    mstore(add(ptr, 0x04), ttxfee)
                    mstore(add(ptr, 0x24), 0)
                }
                mstore(add(ptr, 0x44), address())
                mstore(add(ptr, 0x64), 0x80)
                mstore(add(ptr, 0x84), 0)
                if iszero(call(gas(), tpool, 0, ptr, 0xa4, 0, 0)) { revertWithCode(ptr, errorSelector, 5) }
                let ptxfee := div(mul(ttxfee, partnerShare), 100)
                ltxfee := sub(ttxfee, ptxfee)
                mstore(ptr, shl(0xe0, 0x2e1a7d4d))
                mstore(add(ptr, 0x04), ttxfee)
                if iszero(call(gas(), weth, 0, ptr, 0x24, 0, 0)) { revertWithCode(ptr, errorSelector, 6) }
                if gt(ptxfee, 0) {
                    if iszero(call(gas(), partner, ptxfee, 0, 0, 0, 0)) { revertWithCode(ptr, errorSelector, 9) }
                }
                if iszero(call(gas(), caller(), ltxfee, 0, 0, 0, 0)) { revertWithCode(ptr, errorSelector, 7) }
            }
        }
        emit TxFee(trader, ltxfee);
    }

    function _burnTokens(address trader, uint256 burnAmount) internal returns (uint256 finalBurnAmount) {
        address splx = SPLX_TOKEN;
        if (splx != address(0)) {
            assembly {
                if burnAmount {
                    let ptr := mload(0x40)
                    mstore(ptr, shl(0xe0, 0x70a08231))
                    mstore(add(ptr, 0x04), trader)
                    if staticcall(gas(), splx, ptr, 0x24, ptr, 0x20) {
                        let traderTokenBalance := mload(ptr)
                        if traderTokenBalance {
                            let amountToBurn := traderTokenBalance
                            if lt(burnAmount, traderTokenBalance) {
                                amountToBurn := burnAmount
                            }
                            if lt(MAX_BURN_AMOUNT, amountToBurn) {
                                amountToBurn := MAX_BURN_AMOUNT
                            }
                            mstore(ptr, shl(0xe0, 0x79cc6790))
                            mstore(add(ptr, 0x04), trader)
                            mstore(add(ptr, 0x24), amountToBurn)
                            if call(gas(), splx, 0, ptr, 0x44, 0, 0) {
                                finalBurnAmount := amountToBurn
                            }
                        }
                    }
                }
            }
        }
    }
}