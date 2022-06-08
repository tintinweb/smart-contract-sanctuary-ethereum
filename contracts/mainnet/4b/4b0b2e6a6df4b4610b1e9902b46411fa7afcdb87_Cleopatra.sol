// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import './TickMath.sol';
import './ERC20.sol';
import './Ownable.sol';
import './TransferHelper.sol';
import './INonfungiblePositionManager.sol';
import './ISwapRouter.sol';

interface IUniswapV3PoolState {
      function slot0() external view returns (uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked);
}

contract Cleopatra is ERC20, Ownable {

    // struct to store queued walls update
    struct QueuedWallsUpdate {
        bool inQueue;
        int24[2][] newLiquidityWallsRanges;
        uint[] newLiquidityWallsRatios; 
        bool[] newLiquidityWallsInToken;
    }

    // token id and liquidity for each wall id
    struct WallInfo {
        uint tokenId;
        uint128 liquidity;
    }

    // fees
    uint baseFeesAmount; // base fees amount on each buy (base 10000)
    uint baseFeesAmountForRefferal; // base fees amount when referral is used(replace baseFeesAmount) (base 10000)
    uint feesAmountRatioForRefferer; // ratio (percent) of baseFeesAmountForRefferal gived to refferer when refferal is used (base 10000)
    uint PRPLL_fees; // ratio (percent) of base fees used to PRPLL (the rest is transferrer to the development address) (base 10000)
    mapping (address => bool) public feesExcludedAddresses;
    mapping (address => bool) public taxedPool; // mapping of taxed pool

    // liquidity walls
    int24[2][] public liquidityWallsRanges; // price range where each liquidity wall will be between
    uint[] public liquidityWallsRatios; // percent of all liquidity owned by the contract which will be placed in the walls
    bool[] public liquidityWallsInToken; // mapping of liquidity wall type (true for wall in Cleopatra and false for wall in WETH)
    QueuedWallsUpdate public queuedWalls; // store queued wall update
    mapping (uint => WallInfo) public liquidityWallsTokenIds; // associate each wall id in array to WallInfo
    uint sellThresholdAmount; // token balance required to sell Cleopatra

    // external address
    INonfungiblePositionManager public nonfungiblePositionManager;
    IUniswapV3PoolState public pairPool;
    uint24 public mainPoolFee;
    ISwapRouter public swapRouter;
    address public pairToken;

    // referral
    mapping (address => uint) refferalCodeByAddress;
    mapping (uint => address) reffererAddressByRefferalCode;
    mapping (address => bool) public usedRefferal;
    uint public tokensNeededForRefferalNumber; // minimum token required to generate a refferal code
    uint constant public maxRefferalCode = 999999999999999999;

    // bootstrap
    address public bootstrapToken;
    bool public allowBridge;
    uint public totalTokenDepositedToBridge;

    bool initialized;

    constructor(string memory _name, string memory _symbol, address _pairToken, INonfungiblePositionManager _nonfungiblePositionManager, ISwapRouter _swapRouter) ERC20(_name, _symbol) {
        _mint(msg.sender, 21000000e18);

        pairToken = _pairToken;

        nonfungiblePositionManager = _nonfungiblePositionManager;
        swapRouter = _swapRouter;
    }

    // OPERATOR FUNCTIONS

    // update external address to keep the smart contract functional in case of address changes
    function updateExternalAddressAndPoolFee(INonfungiblePositionManager _nonfungiblePositionManager, ISwapRouter _swapRouter, address _pairToken, IUniswapV3PoolState _pairPool, uint24 _mainPoolFee) external onlyOwner {
        nonfungiblePositionManager = _nonfungiblePositionManager;
        swapRouter = _swapRouter;
        pairToken = _pairToken;
        pairPool = _pairPool;
        mainPoolFee = _mainPoolFee;
    }

    function setFeesExcludedAddress(address _account, bool _isExcluded) external onlyOwner {
        feesExcludedAddresses[_account] = _isExcluded;
    }

    function setTaxedPool(address _pool, bool _isTaxed) external onlyOwner {
        taxedPool[_pool] = _isTaxed;
    }

    function setFeesAmount(uint _baseFeesAmount, uint _baseFeesAmountForRefferal, uint _feesAmountRatioForRefferer, uint _PRPLL_fees) external onlyOwner {
        require(_baseFeesAmount <= 5000);
        require(_baseFeesAmountForRefferal <= 5000);
        require(_feesAmountRatioForRefferer <= 5000);
        require(_PRPLL_fees <= 10000);
        baseFeesAmount = _baseFeesAmount;
        baseFeesAmountForRefferal = _baseFeesAmountForRefferal;
        feesAmountRatioForRefferer = _feesAmountRatioForRefferer;
        PRPLL_fees = _PRPLL_fees;
    }

    // put new liquidity wall in queue
    function queueLiquidityWallsParameters(int24[2][] calldata _liquidityWallsRanges, uint[] calldata _liquidityWallsRatios, bool[] calldata _liquidityWallsInToken) external onlyOwner {
        require(_liquidityWallsRanges.length == _liquidityWallsRatios.length && _liquidityWallsRatios.length == _liquidityWallsInToken.length);

        queuedWalls = QueuedWallsUpdate(true, _liquidityWallsRanges, _liquidityWallsRatios, _liquidityWallsInToken);
    }

    function setSellThresholdAmount(uint _sellThresholdAmount) external onlyOwner {
        sellThresholdAmount = _sellThresholdAmount;
    }

    function setTokensNeededForRefferalNumber(uint _tokensNeededForRefferalNumber) external onlyOwner {
        tokensNeededForRefferalNumber = _tokensNeededForRefferalNumber;
    }

    function approveUniswap() external onlyOwner {
        TransferHelper.safeApprove(address(this), address(nonfungiblePositionManager), uint(-1));
        TransferHelper.safeApprove(pairToken, address(nonfungiblePositionManager), uint(-1));
        TransferHelper.safeApprove(address(this), address(swapRouter), uint(-1));
        TransferHelper.safeApprove(pairToken, address(swapRouter), uint(-1));
    }

    function setBootstrap(address _bootstrapToken, bool _allowBridge) public {
        bootstrapToken = _bootstrapToken;
        allowBridge = _allowBridge;
    }

    // BOOTSTRAP FUNCTIONS

    // bridge all bootstrapToken to CLEO
    function bridgeToCLEO() external {
        uint amount = IERC20(bootstrapToken).balanceOf(msg.sender);
        IERC20(bootstrapToken).transferFrom(msg.sender, address(this), amount);
        transfer(msg.sender, amount);
    }

    function addReserveToBridge() external onlyOwner {
        uint amount = balanceOf(msg.sender);
        transferFrom(msg.sender, address(this), amount);
        totalTokenDepositedToBridge += amount;
    }

    function retrieveCLEO() external onlyOwner {
        transfer(msg.sender, totalTokenDepositedToBridge);
        totalTokenDepositedToBridge = 0;
    }

    // OVERRIDE FUNCTIONS

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transferWithFees(sender, recipient, amount);
        _approve(sender, msg.sender, allowance(sender, msg.sender) - amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transferWithFees(msg.sender, recipient, amount);
        return true;
    }

    function _transferWithFees(address from, address to, uint256 amount) internal returns (bool) {
        if ((feesExcludedAddresses[from] == false && feesExcludedAddresses[to] == false) && taxedPool[from]) { // if the transfer is in a buy tx and "from" and "to" aren't excluded from fees
            uint feesAmount;
            
            uint referralCode = getReferralCodeFromTokenAmount(amount);

            if (usedRefferal[to] == false && isReferralCodeValid(referralCode) && getReffererAddressFromRefferalCode(referralCode) != tx.origin) {
                usedRefferal[to] = true;
                feesAmount = (amount * baseFeesAmountForRefferal) / 10000;
                uint feesAmountForRefferer = (feesAmount * feesAmountRatioForRefferer) / 10000;
                _transfer(from, getReffererAddressFromRefferalCode(referralCode), feesAmountForRefferer);
                feesAmount -= feesAmountForRefferer;
            } else {
                feesAmount = (amount * baseFeesAmount) / 10000;
            }
            
            uint feesForPRPLL = (feesAmount * PRPLL_fees) / 10000;
            uint feesForDevelopement = feesAmount - feesForPRPLL;
                
            _transfer(from, to, amount - feesAmount);
            _transfer(from, address(this), feesForPRPLL);
            _transfer(from, owner(), feesForDevelopement);
        } else {
            _transfer(from, to, amount);
        }

        handleNewBalance(to, balanceOf(to));

        return true;
    }

    // MAIN FUNCTIONS

    function init() external onlyOwner {
        require(initialized == false, "Already initialized");
        initialized = true;

        // get updated data
        (, int24 currentTick , , , , ,) = pairPool.slot0();
        uint quoteAmount = IERC20(pairToken).balanceOf(address(this));
        uint cleoAmount = balanceOf(address(this));

        // update walls configuration before adding new walls
        updateWallsIfQueued();

        // iterate each liquidity walls parameters and add it
        uint liquidityAmount;
        for (uint i=0; i < liquidityWallsRanges.length; i++) {
            if (liquidityWallsInToken[i]) {
                liquidityAmount = (liquidityWallsRatios[i] * cleoAmount) / 10000;

                if (liquidityAmount > 0) { // if there is enough liquidity to add
                    (uint tokenId, uint128 liquidity) = addLiquidity(currentTick + liquidityWallsRanges[i][0], currentTick + liquidityWallsRanges[i][1], liquidityAmount, 0);
                    liquidityWallsTokenIds[i] = WallInfo(tokenId, liquidity);
                } else 
                    liquidityWallsTokenIds[i] = WallInfo(0, 0);
            }
            else {
                liquidityAmount = (liquidityWallsRatios[i] * quoteAmount) / 10000;

                if (liquidityAmount > 0) { // if there is enough liquidity to add
                    (uint tokenId, uint128 liquidity) = addLiquidity(currentTick + liquidityWallsRanges[i][0], currentTick + liquidityWallsRanges[i][1], 0, liquidityAmount);
                    liquidityWallsTokenIds[i] = WallInfo(tokenId,liquidity);
                } else 
                    liquidityWallsTokenIds[i] = WallInfo(0, 0);
            }
        }
    }

    function reorganize(bool removeOldWalls) external onlyOwner {
        // Sell all CLEO from fees
        if (balanceOf(address(this)) >= sellThresholdAmount)
            _sellCleo(1000);

        // Remove liquidity from old walls
        if (removeOldWalls) {
            for (uint i=0; i < liquidityWallsRanges.length; i++) {
                if (liquidityWallsTokenIds[i].tokenId != 0) {
                    removeLiquidity(liquidityWallsTokenIds[i]);
                    collectFees(liquidityWallsTokenIds[i]);
                }
            }
        }

        // get updated data
        (, int24 currentTick , , , , ,) = pairPool.slot0();
        uint quoteAmount = IERC20(pairToken).balanceOf(address(this));
        uint cleoAmount = balanceOf(address(this));

        // update walls configuration before adding new walls
        updateWallsIfQueued();

        // iterate each liquidity walls parameters and add it
        uint liquidityAmount;
        for (uint i=0; i < liquidityWallsRanges.length; i++) {
            if (liquidityWallsInToken[i]) {
                liquidityAmount = (liquidityWallsRatios[i] * cleoAmount) / 10000;

                if (liquidityAmount > 0) { // if there is enough liquidity to add
                    (uint tokenId, uint128 liquidity) = addLiquidity(currentTick + liquidityWallsRanges[i][0], currentTick + liquidityWallsRanges[i][1], liquidityAmount, 0);
                    liquidityWallsTokenIds[i] = WallInfo(tokenId, liquidity);
                } else 
                    liquidityWallsTokenIds[i] = WallInfo(0, 0);
            }
            else {
                liquidityAmount = (liquidityWallsRatios[i] * quoteAmount) / 10000;

                if (liquidityAmount > 0) { // if there is enough liquidity to add
                    (uint tokenId, uint128 liquidity) = addLiquidity(currentTick + liquidityWallsRanges[i][0], currentTick + liquidityWallsRanges[i][1], 0, liquidityAmount);
                    liquidityWallsTokenIds[i] = WallInfo(tokenId,liquidity);
                } else 
                    liquidityWallsTokenIds[i] = WallInfo(0, 0);
            }
        }
    }

    // INTERNAL AND PRIVATE UTILS FUNCTIONS

    function removeLiquidity(WallInfo memory _wall) private {
        INonfungiblePositionManager.DecreaseLiquidityParams memory params =
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: _wall.tokenId,
                liquidity: _wall.liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

        nonfungiblePositionManager.decreaseLiquidity(params);
    }

    function collectFees(WallInfo memory _wall) private {
        INonfungiblePositionManager.CollectParams memory params =
            INonfungiblePositionManager.CollectParams({
                tokenId: _wall.tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        nonfungiblePositionManager.collect(params);
    }

    function sellCleo(uint _sellAmount) external onlyOwner {
        _sellCleo(_sellAmount);
    }

    function _sellCleo(uint _sellAmount) private {
        // _sellAmount between > 0 and 1000
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(this),
                tokenOut: pairToken,
                fee: mainPoolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: (balanceOf(address(this)) * _sellAmount) / 1000,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        swapRouter.exactInputSingle(params);
    }

    function addLiquidity(int24 minTick, int24 maxTick, uint amountCleo, uint amountQuote) private returns (uint tokenId, uint128 liquidity) {
        minTick = nearestUsableTick(minTick);
        maxTick = nearestUsableTick(maxTick);

        address token0;
        address token1;
        uint token0Amount;
        uint token1Amount;

        if (address(this) < pairToken) {
            token0 = address(this);
            token1 = pairToken;
            token0Amount = amountCleo;
            token1Amount = amountQuote;
        } else {
            token0 = pairToken;
            token1 = address(this);
            token0Amount = amountQuote;
            token1Amount = amountCleo;
        }

        INonfungiblePositionManager.MintParams memory params =
            INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: mainPoolFee,
                tickLower: minTick,
                tickUpper: maxTick,
                amount0Desired: token0Amount,
                amount1Desired: token1Amount,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });

        (tokenId, liquidity, ,) = nonfungiblePositionManager.mint(params);
    }

    function updateWallsIfQueued() private {
        if (queuedWalls.inQueue) {
            liquidityWallsRanges = queuedWalls.newLiquidityWallsRanges;
            liquidityWallsRatios = queuedWalls.newLiquidityWallsRatios;
            liquidityWallsInToken = queuedWalls.newLiquidityWallsInToken;

            queuedWalls.inQueue = false;
        }
    }

    // REFERRAL FUNCTIONS

    function randomRefferal() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.gaslimit))) % maxRefferalCode;
    }

    function handleNewBalance(address account, uint256 balance) private {
        //already registered
        if(refferalCodeByAddress[account] != 0) {
            return;
        }
        //not enough tokens
        if(balance < tokensNeededForRefferalNumber) {
            return;
        }

        uint _refferalCode = randomRefferal();

        refferalCodeByAddress[account] = _refferalCode;
        reffererAddressByRefferalCode[_refferalCode] = account;
    }

    function getReferralCodeFromTokenAmount(uint256 tokenAmount) public pure returns (uint256) {
        uint256 decimals = 18;

        uint256 numberAfterDecimals = tokenAmount % (10**decimals);

        uint256 checkDecimals = 3;

        while(checkDecimals < decimals) {
            uint256 factor = 10**(decimals - checkDecimals);
            //check if number is all 0s after the decimalth decimal
            if(numberAfterDecimals % factor == 0) {
                return numberAfterDecimals / factor;
            }
            checkDecimals++;
        }

        return numberAfterDecimals;
    }

    function getRefferalCodeFromAddress(address account) public view returns (uint256) {
        return refferalCodeByAddress[account];
    }

    function getReffererAddressFromRefferalCode(uint refferalCode) public view returns (address) {
        return reffererAddressByRefferalCode[refferalCode];
    }

    function isReferralCodeValid(uint refferalCode) public view returns (bool) {
        if (getReffererAddressFromRefferalCode(refferalCode) != address(0)) return true;
        return false;
    }

    // TICK CALCULATION FUNCTIONS

    function nearestUsableTick(int24 _tick) pure public returns (int24) {
        if (_tick < 0) {
            return -_nearestNumber(-_tick, 60);
        } else {
            return _nearestNumber(_tick, 60);
        }
    }

    function _nearestNumber(int24 _tick, int24 _tickInterval) pure private returns (int24) {
        int24 high = ((_tick + _tickInterval - 1) / _tickInterval) * _tickInterval;
        int24 low = high - _tickInterval;
        if (abs(_tick - high) < abs(_tick - low)) return high;
        else return low;
    }

    function abs(int x) pure private returns (uint) {
        return uint(x >= 0 ? x : -x);
    }
}