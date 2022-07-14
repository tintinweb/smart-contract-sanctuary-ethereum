/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// Part: IERC20

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

// Part: IUniswapV2Router01

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

// Part: Structures

interface Structures {
    struct Share {
        address holder;
        int256 amount;
        uint256 rewardDate;
    }
}

// Part: IUniswapV2Router02

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
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
    ) external returns (uint256 amountETH);

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

// Part: Queue

contract Queue is Structures {

    mapping(uint256 => Share) queue;
    uint256 first = 1;
    uint256 last = 0;

    address distributor;

    constructor() {
        distributor = msg.sender;
    }

    modifier onlyDistributor(){
        require(msg.sender == distributor, "Caller must be Distributor");
        _;
    }

    function enqueue(Share memory data) external onlyDistributor {
        last += 1;
        queue[last] = data;
    }

    function dequeue() external onlyDistributor returns (Share memory data) {
        require(last >= first);  // non-empty queue

        data  = queue[first];

        delete queue[first];
        first += 1;
    }

    function getFirst() external view onlyDistributor returns (Share memory data) {
        require(last >= first);  // non-empty queue

        data  = queue[first];
    }

    function isEmpty() external view onlyDistributor returns (bool) {
        return ! (last >= first);
    }
}

// File: Distributor.sol

contract HolderRewarderDistributor is Structures {
    //Atributes // TODO change visibility
    IERC20 private sheqelToken;
    IERC20 private USDC;
    address public WFTM;
    address public reserve;

    uint256 public lastDistribution;

    uint256 public currentShqToRewards;
    uint256 public currentUSDCToRewards;
    uint256 public currentShqToUBR;
    uint256 public currentUSDCToUBR;

    IUniswapV2Router02 private uniswapV2Router;

    //Holders
    address[] public holders;
    uint256 nbOfHolders = 0;
    mapping(address => int256) holdersToRewardsBalance;
    mapping(address => bool) public isHolder;

    // UBR
    uint256 UBRthreshold = 10; // TODO: calculate the best threshold
    uint256 nbOfEligibleHoldersToUBR = 0;
    mapping(address => bool) public isEligibleToUBR;

    //Shares
    Queue private pendingTransactions;

    // Events
    event DistributedRewards(uint256 totalDistributedUSDC);



    //Constructor

    constructor(address _router, address _reserve, address _deployer, int _amount, address _usdcAddress) {
        uniswapV2Router = IUniswapV2Router02(_router);
        //sheqelToken = IERC20(msg.sender);
        pendingTransactions = new Queue();
        reserve = _reserve;

        USDC = IERC20(_usdcAddress);

        //setup init mint
        //holders.push(_deployer);
        isHolder[_deployer] = true;
        nbOfHolders++;        
        isEligibleToUBR[_deployer] = true;
        nbOfEligibleHoldersToUBR++;        
        holdersToRewardsBalance[_deployer] = _amount;

    }

    // TODO: only for debug! In production contract must be created by token
    function setShq(address _addr) external {
        sheqelToken = IERC20(_addr);
    }

    //Modifiers

    modifier onlyToken() {
        require(msg.sender == address(sheqelToken), "Must be Sheqel Token");
        _;
    }

    modifier onlyNotNullAmount(int256 amount) {
        require(amount != 0, "Must transfer non null amount");
        _;
    }

    modifier onlyNotNullHolder(address holder) {
        require(
            holder > address(0),
            "Holder must have a non null positive address"
        );
        _;
    }

    modifier onlyHolder(address holder) {
        require(isHolder[holder] == true);
        _;
    }

    //Functions

    //Distributor
    function addToCurrentShqToUBR(uint256 amount) external onlyToken {
        currentShqToUBR += amount;
    }

    function addToCurrentShqToRewards(uint256 amount)
        external
        onlyToken
    {
        currentShqToRewards += amount;
    }

    //Holder management

    function addHolder(address holder) private onlyNotNullHolder(holder) {
        require(isHolder[holder] == false);
        holders.push(holder);
        isHolder[holder] = true;
        nbOfHolders++;
    }

    /**
     Removes holder, sets attribute to false and decrements number of holder to false 
     */
    function removeHolder(address holder) private onlyNotNullHolder(holder) {
        require(isHolder[holder] == true);
        isHolder[holder] = false;
        nbOfHolders--;
        removeFromEligibleUBR(holder);
    }

    // UBR Managment
    /**
     Sets the holder eligible to UBR reward and increments the number of eligible hodlers 
     */
    function addToEligibleUBR(address holder)
        private
        onlyNotNullHolder(holder)
    {
        require(isEligibleToUBR[holder] == false);
        require(holdersToRewardsBalance[holder] >= int (UBRthreshold));
        isEligibleToUBR[holder] = true;
        nbOfEligibleHoldersToUBR++;
    }

    /**
     Sets the holder not eligible to UBR reward and decrements the number of eligible hodlers 
     */
    function removeFromEligibleUBR(address holder)
        private
        onlyNotNullHolder(holder)
    {
        require(isEligibleToUBR[holder] == true);
        require(holdersToRewardsBalance[holder] < int (UBRthreshold));
        isEligibleToUBR[holder] = false;
        nbOfEligibleHoldersToUBR--;
    }

    //Share management
    function transferShare(address holder, int256 amount)
        public
        onlyToken
        onlyNotNullAmount(amount)
        onlyNotNullHolder(holder)
    {
        uint256 rewardDate = block.timestamp + 1 days;
        pendingTransactions.enqueue(Share(holder, amount, rewardDate));
    }

    /*
    Process the pendingTransactions queue,
    updates holder rewards balance
    */
    function processPendingTransactions() private returns (bool) {
        if(!pendingTransactions.isEmpty()){
            Share memory share = pendingTransactions.getFirst();
            while (share.rewardDate <= block.timestamp) {
                address holder = share.holder;
                int256 amount = share.amount;

                holdersToRewardsBalance[holder] += amount;

                if(amount > 0) {
                    if (isHolder[holder] == false) {
                        addHolder(holder);
                    }

                    if (isEligibleToUBR[holder] == false && holdersToRewardsBalance[holder]  >= int (UBRthreshold)) {
                        addToEligibleUBR(holder);
                    }
                }
                else {
                    if (isHolder[holder] == true && int(holdersToRewardsBalance[holder]) <= 0) {
                        removeHolder(holder);
                    } else if (isEligibleToUBR[holder] == true && int(holdersToRewardsBalance[holder]) < int(UBRthreshold)) {
                        removeFromEligibleUBR(holder);
                    }
                }


                pendingTransactions.dequeue();
                // Verify that queue is not empty
                if(pendingTransactions.isEmpty()){
                    break;
                }
                else{
                    share = pendingTransactions.getFirst();
                }
            }
            return true;
            }
            else{
                return false;
            }
    }


    function computeReward(address holder, uint256 totalShqInCirculation)
        public //TODO: PRIVATE
        view
        returns (uint256)
    {
        uint256 balance = uint(holdersToRewardsBalance[holder]);
        if(holdersToRewardsBalance[holder] < 0){
            balance = 0;
        }
        uint256 reward = (balance * (10 ** 24)) / totalShqInCirculation;

        return reward;
    }

    function computeUBR()
        public //TODO: PRIVATE
        view
        returns (uint256)
    {
        return currentUSDCToUBR / nbOfHolders;
    }

    // Will process all rewards including UBR
    function processAllRewards() external {
        require(block.timestamp >= lastDistribution + 1 days, "Cannot distribute two times in a day");
        processPendingTransactions();
        if((currentShqToRewards > 0|| currentShqToUBR > 0|| currentUSDCToRewards > 0|| currentUSDCToUBR> 0 )){
            uint256 totalUSDC = 0;
            uint256 totalShqInCirculation = sheqelToken.totalSupply();

            // Swapping SHQ to USDC
            if(currentShqToRewards > 0){
                currentUSDCToRewards += swapTokenToUSDC(currentShqToRewards);
                currentShqToRewards = 0;
            }
            if(currentShqToUBR > 0){
                currentUSDCToUBR += swapTokenToUSDC(currentShqToUBR);
                currentShqToUBR = 0;
            }   


            for (uint256 i = 0; i < holders.length; i++) {
                address holder = holders[i];

                // Setting Reward and UBR
                uint256 UBRToSend = 0;
                uint256 rewardToSend = 0;

                // Check if holder is eligible to get the rewards
                if (isHolder[holder] == true) {
                    rewardToSend =
                        (computeReward(holder, totalShqInCirculation) *
                        currentUSDCToRewards) / (10 ** 24);
                    currentUSDCToRewards -= rewardToSend;

                    // Calculating if the balance is over the UBR threshold
                    if (isEligibleToUBR[holder] == true) {
                        UBRToSend = computeUBR();
                        currentUSDCToUBR -= UBRToSend;
                    }

                    uint256 totalReward = rewardToSend + UBRToSend;
                    totalUSDC += totalReward;
                    if(totalReward > 0){
                        USDC.transfer(holder, totalReward);
                    }


                }
            }

            // Sending leftover to the reserve if there is any
            if(sheqelToken.balanceOf(address(this)) > 0){
                sheqelToken.transfer(reserve, sheqelToken.balanceOf(address(this)));
            }
            if(USDC.balanceOf(address(this)) > 0){
                USDC.transfer(reserve, USDC.balanceOf(address(this)));
                currentUSDCToRewards = 0;
                currentShqToUBR = 0;
            }

            lastDistribution = block.timestamp;


            emit DistributedRewards(totalUSDC);
        }
        
    }

    function swapTokenToUSDC(uint256 amount) internal returns(uint256){
        address[] memory path = new address[](2);
        path[0] = address(sheqelToken);
        path[1] = address(USDC);
        sheqelToken.approve(address(uniswapV2Router), amount);
        uint256 balancePreswapUSDC = USDC.balanceOf(address(this));
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp + 15
        );

        return USDC.balanceOf(address(this)) - balancePreswapUSDC;
    }

    function rewardsBalanceOf(address _addr) public view returns (int256) {
        return holdersToRewardsBalance[_addr];
    }
}