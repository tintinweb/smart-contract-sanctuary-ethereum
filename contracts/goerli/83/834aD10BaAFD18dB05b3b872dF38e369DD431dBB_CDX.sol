/**
 *Submitted for verification at Etherscan.io on 2022-12-30
*/

// File: @uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol


pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// File: https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/ISwapRouter.sol


pragma solidity >=0.7.5;
pragma abicoder v2;


/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// File: contracts/CDX,sol.sol



pragma solidity >=0.7.0 <0.9.0;




interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface IPriceFeed {
    function description() external view returns (string memory);
    function aggregator() external view returns (address);
    function latestAnswer() external view returns (int256);
    function latestRound() external view returns (uint80);
    function getRoundData(uint80 roundId) external view returns (uint80, int256, uint256, uint256, uint80);
}

/**
 * @title  产品购买合约模板
 * @author ldc
 * @notice 每个合约是独立的且必须所有资金到位，合约方可正式开始
 * @dev    提供了存储/获取资金方法，提供其他相关方法
 */
contract CDX {
    address public constant routerAddress =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    ISwapRouter public immutable swapRouter = ISwapRouter(routerAddress);

    address public constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address public constant USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    address public constant ETHUSD = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e;

    uint24 public constant poolFee = 3000;

    //日志事件
    event Log(string funName, address from, uint256 value, bytes data);
    //给合约转钱
    event Deposit(address _ads, uint256 amount);

    //购买合同用户钱包地址
    address immutable participant;
    //管理账户钱包地址
    address ownerAddress;

    //合同模板类型枚举
    //BuyBelow 买进低于指定值，SellAbove 卖出高于指定值
    enum TypeStatus {
        BuyBelow,
        SellAbove
    }

    //合约的进度枚举
    //Pending 合约准备中等待打钱，Progress 合约进行中，Completed 合约完成
    enum ProgressStatus {
        Pending,
        Progress,
        Completed
    }


    // 合同模板选择类型
    TypeStatus typeStatus;
    // 合同模板进行状态
    ProgressStatus progressStatus; 
    //置换币种数量
    uint256 public permutationNum;
    //赌约金额币种
    int256 conditionAmount;
    //赌约金额
    uint256 public betAmount;
    //赔付金额
    uint256 public paidAmount = 0;
    /** 
     * @notice 合约的构造函数
     * @param participant_: 购买合约者的钱包地址
     * @param typeStatus_: 合约状态类型
     * @param conditionAmount_: 规定触发条件的金额
     * @param betAmount_: 赌约金额
     * @param paidAmount_: 赌约金额
     * @param permutationNum_: 置换币种数量
     * @dev   初始化合约相关数值
     */
    constructor(address participant_, TypeStatus typeStatus_, int256 conditionAmount_, uint256 betAmount_, uint256 paidAmount_, uint256 permutationNum_) payable{
        participant = participant_;
        typeStatus = typeStatus_;
        conditionAmount = conditionAmount_;
        progressStatus = ProgressStatus.Pending;
        betAmount = betAmount_;
        paidAmount = paidAmount_;
        permutationNum = permutationNum_;
        ownerAddress = payable(msg.sender);
    }

    /**
     * @notice 全局条件判断，是否是很拥有者在操作
     */
    modifier onlyOwner() {
        require(msg.sender == ownerAddress,"The operator must be the contract owner");
        _;
    }

    /**
     * @notice 给合约打钱
     * @dev   打款金额必须大于等于触发金额，合约正式进行
     */
    receive() external payable {
        require(progressStatus != ProgressStatus.Completed, "Contract completed");
        emit Deposit(msg.sender, msg.value);    
        emit Log("receive", msg.sender,msg.value,msg.data);
    }


    /**
     * @notice 查看当前合同账户指定币种余额
     */ 
    function getBalanceof(address token) public view returns (uint256){
        IERC20 tokenInToken = IERC20(token);
        return tokenInToken.balanceOf(address(this));
    }


    /** 
     * @notice 查看合同进行状态
     */
    function getProgressStatus() public view onlyOwner returns (uint256) {
        return uint256(progressStatus);
    }

    /** 
     * @notice 获取实时指定货币价格
     */
    function getTokenPrice(address token_) public view returns (int256) {
        IPriceFeed priceFeed = IPriceFeed(token_);
        int256 price = priceFeed.latestAnswer();
        require(price > 0, "VaultPriceFeed: invalid price");
        return price;
    }

    /** 
     * @notice 判断是否达成赌约
     */
    function judgment() public onlyOwner returns (bool) {
        //require(ProgressStatus.Progress == progressStatus, "Contract not commenced");
        //require(paidAmountStatus == 1, "The contract payment has not arrived");
        int256 currentValue = this.getTokenPrice(ETHUSD);
        if(currentValue >= conditionAmount){
            this.dealAboveEvent(WETH);
        }else{
            this.dealBelowEvent(WETH);
        }
        
        return true;
    }


    /** 
     * @notice 处理区块值高于约定条件的情况
     */
    function dealAboveEvent(address coinAddress) external {
        //赌约币种
        //IERC20 tokenInToken = IERC20(coinAddress);
        //用户输入币种
        IERC20 tokenInUSDC = IERC20(USDC);
        if(TypeStatus.BuyBelow == typeStatus){
            //退款结束合约
            this.compensation(tokenInUSDC,tokenInUSDC);
            this.dealAccountBalance(coinAddress);
            progressStatus = ProgressStatus.Completed;
            selfdestruct(payable(ownerAddress));
        }
        if(TypeStatus.SellAbove == typeStatus){
            //代卖指定币
            this.swapExactInputSingle(betAmount,WETH,USDC,address(this));
            tokenInUSDC.transfer(participant, permutationNum);
            this.dealAccountBalance(coinAddress);
            progressStatus = ProgressStatus.Completed;
            selfdestruct(payable(ownerAddress));
        }
    }



    /** 
     * @notice 处理区块值低于约定条件的情况
     */
    function dealBelowEvent(address coinAddress) external {
        //赌约币种
        IERC20 tokenInETH = IERC20(coinAddress);
        //用户输入币种
        IERC20 tokenInUSDC = IERC20(USDC);
        if(TypeStatus.BuyBelow == typeStatus){
            //代买指定的币
            this.swapExactOutputSingle(permutationNum,betAmount,USDC,coinAddress,participant);
            this.dealAccountBalance(coinAddress);
            progressStatus = ProgressStatus.Completed;
            selfdestruct(payable(ownerAddress));
        }
        if(TypeStatus.SellAbove == typeStatus){
            //退款结束合约
            this.compensation(tokenInETH,tokenInUSDC);
            this.dealAccountBalance(coinAddress);
            progressStatus = ProgressStatus.Completed;
            selfdestruct(payable(ownerAddress));
        }
    }

    function compensation(IERC20 tokenInUser,IERC20 tokenInOwner) external {
        tokenInUser.transfer(participant, betAmount);
        tokenInOwner.transfer(participant, paidAmount);
    }

    function dealAccountBalance(address coinAddress) external {
        //赌约币种
        IERC20 tokenInETH = IERC20(coinAddress);
        //用户输入币种
        IERC20 tokenInUser = IERC20(USDC);
        //合同拥有者输入币种
        IERC20 tokenInOwner = IERC20(USDC);
        tokenInETH.transfer(ownerAddress, uint256(getBalanceof(coinAddress)));
        tokenInUser.transfer(ownerAddress, uint256(getBalanceof(USDC)));
        tokenInOwner.transfer(ownerAddress, uint256(getBalanceof(USDC)));
    }


    function swapExactInputSingle(uint256 amountIn,address tokenIn_,address tokenOut_,address recipient_)
        external
        returns (uint256 amountOut)
    {
        IERC20 tokenInToken = IERC20(tokenIn_);
        tokenInToken.approve(address(swapRouter), amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn_,
                tokenOut: tokenOut_,
                fee: poolFee,
                recipient: recipient_,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
    }

    function swapExactOutputSingle(uint256 amountOut, uint256 amountInMaximum,address tokenIn_,address tokenOut_,address recipient_)
        external
        returns (uint256 amountIn)
    {
        IERC20 tokenInToken = IERC20(tokenIn_);
        tokenInToken.approve(address(swapRouter), amountInMaximum);
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: tokenIn_,
                tokenOut: tokenOut_,
                fee: poolFee,
                recipient: recipient_,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        amountIn = swapRouter.exactOutputSingle(params);

        if (amountIn < amountInMaximum) {
            tokenInToken.approve(address(swapRouter), 0);
            tokenInToken.transfer(address(this), amountInMaximum - amountIn);
        }
    }
}