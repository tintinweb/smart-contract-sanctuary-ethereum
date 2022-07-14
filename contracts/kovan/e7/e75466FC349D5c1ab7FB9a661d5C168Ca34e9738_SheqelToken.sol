/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// Part: Context

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

// Part: IUniswapV2Factory

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
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

// Part: IERC20Metadata

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

// Part: HolderRewarderDistributor

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

// Part: LiquidityManager

contract LiquidityManager {
    IERC20 public sheqelToken;
    IERC20 public USDC;
    IUniswapV2Router02 public uniswapV2Router;

    constructor(address _usdcAddress, address _spookySwapAddress) {
        sheqelToken = IERC20(msg.sender);
        USDC = IERC20(_usdcAddress);
        uniswapV2Router = IUniswapV2Router02(_spookySwapAddress);
    }

    modifier onlyToken() {
        require(msg.sender == address(sheqelToken), "Must be Sheqel Token");
        _;
    }

    /*function addToCurrentShqToLiquidity(uint256 _amount) onlyToken() public {
        currentShqToLiquidity += _amount;
    }*/

    function swapAndLiquify() onlyToken() public {
        uint256 currentShqToLiquidity = sheqelToken.balanceOf(address(this));
        // split the contract balance into halves
        uint256 half = currentShqToLiquidity / 2;
        uint256 otherHalf = currentShqToLiquidity - half;

        uint256 initialUSDCBalance = USDC.balanceOf(address(this));

        swapTokenToUSDC(address(this), otherHalf); // 


        uint256 newBalance = USDC.balanceOf(address(this)) - (initialUSDCBalance);

        // add liquidity to uniswap
        addLiquidity(half, newBalance);
    }

    function swapTokenToUSDC(address recipient, uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(sheqelToken);
        path[1] = address(USDC);
        sheqelToken.approve(address(uniswapV2Router), amount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            recipient,
            block.timestamp + 15
        );
    }

    function addLiquidity(uint256 _shqAmount, uint256 _usdcAmount) private {
        // approve token transfer to cover all possible scenarios
        USDC.approve(address(uniswapV2Router), _usdcAmount);
        sheqelToken.approve(address(uniswapV2Router), _shqAmount);
        // add the liquidity
        uniswapV2Router.addLiquidity(
            address(sheqelToken),
            address(USDC),
            _shqAmount,
            _usdcAmount,
            0, 
            0, 
            address(this),
            block.timestamp + 15
        );
    }
}

// Part: Reserve

contract Reserve {
    IERC20 private sheqelToken;
    IERC20 private USDC;
    uint256 private shqToConvert;
    IUniswapV2Router02 private uniswapV2Router;
    address private WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address private teamAddress;
    bool shqAddressSet=false;

    event ShqBought(uint256 amountSHQ, uint256 amountUSDC);
    event ShqSold(uint256 amountSHQ, uint256 amountUSDC);



    constructor(address _spookyswapRouter, address _usdcAddress) {
        // Contract constructed by the Sheqel token
        USDC = IERC20(_usdcAddress);
        uniswapV2Router = IUniswapV2Router02(_spookyswapRouter);
        teamAddress = msg.sender;
        shqToConvert = 0;
    }

    modifier onlyToken() {
        require(msg.sender == address(sheqelToken), "Must be Sheqel Token");
        _;
    }

    modifier onlyTeam() {
        require(msg.sender == address(teamAddress), "Must be Sheqel Team");
        _;
    }

    function setSheqelTokenAddress(address _addr) public onlyTeam() {
        require(shqAddressSet == false, "Can only change the address once");
        sheqelToken = IERC20(_addr);
        shqAddressSet=true;
    }

    function addToShqToConvert(uint256 amount) public onlyToken() {
        shqToConvert += amount;
    }

    function buyPrice() public view returns (uint256) {
        uint256 usdcInReserve = USDC.balanceOf(address(this)) * (10 ** 6);
        uint256 shqOutsideReserve = (sheqelToken.totalSupply() - sheqelToken.balanceOf(address(this))) / (10 ** 12);

        return usdcInReserve / shqOutsideReserve; // Price in USDC (6 decimals)
    }

    function sellPrice() public view returns (uint256) {
        uint256 totalShq = sheqelToken.totalSupply();
        uint256 shqInReserve = sheqelToken.balanceOf(address(this));

        return ((totalShq * (buyPrice()))) / (shqInReserve - 1); // Price in USDC (6 decimals)
    }


    function buyShq(address _beneficiary, uint256 _shqAmount) external {
        require(_shqAmount > 0, "Amount of tokens purchased must be positive");
        _processPurchase(_beneficiary, _shqAmount);
    }

    function sellShq(address _beneficiary, uint256 _shqAmount) external {
        require(_shqAmount > 0, "Amount of tokens sold must be positive");
        _processSell(_beneficiary, _shqAmount);
    }

    function _processSell(address _beneficiary, uint256 _shqAmount) internal {
        // Converting shq to usdc
        uint256 usdcAmount = (_shqAmount * buyPrice()) / (10 ** 18);
    
        // Making the user pay
        require(sheqelToken.transferFrom(msg.sender, address(this), _shqAmount), "Deposit failed");

        // Delivering the tokens
        _deliverUsdc(_beneficiary, usdcAmount);

        emit ShqSold(usdcAmount, _shqAmount);

  }

    function _processPurchase(address _beneficiary, uint256 _shqAmount) internal {
        // Converting shq to usdc
        uint256 usdcAmount = (_shqAmount * sellPrice()) / (10 ** 18);
    
        // Making the user pay
        require(USDC.transferFrom(msg.sender, address(this), usdcAmount), "Deposit failed");

        // Delivering the tokens
        _deliverShq(_beneficiary, _shqAmount);

        emit ShqBought(_shqAmount, usdcAmount);
    }

    function _deliverShq(address _beneficiary, uint256 _shqAmount) internal {
        sheqelToken.transfer(_beneficiary, _shqAmount);
    }

    function _deliverUsdc(address _beneficiary, uint256 _usdcAmount) internal {
        USDC.transfer(_beneficiary, _usdcAmount);
    }
}

// File: SheqelToken.sol

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */

// Sheqel Token Contract0
contract SheqelToken is Context, IERC20, IERC20Metadata {
    address public admin;
    bool liqTransaction = true;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    uint256 public _totalSupply;

    string private _name;
    string private _symbol;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    HolderRewarderDistributor public distributor;

    address public reserveAddress;
    Reserve public reserveContract;
    LiquidityManager liquidityManager;
    address public spookySwapAddress; //0xF491e7B69E4244ad4002BC14e878a34207E38c29; FTM
    address public MDOAddress;
    address public teamAddress;

    address public WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;// 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; FTM
    IERC20 public USDC;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(address _reserveAddress, address _MDOAddress, uint256 _tSupply, address _spookyswapAddress, address _USDCAddress) {
        // Setting up the variables
        _name = "Sheqel";
        _symbol = "SHQ";
        _totalSupply = _tSupply;
        _balances[msg.sender] = _totalSupply;

        reserveAddress = _reserveAddress;
        reserveContract = Reserve(reserveAddress);
        spookySwapAddress = _spookyswapAddress;
        MDOAddress = _MDOAddress;
        teamAddress = msg.sender;

        USDC = IERC20(_USDCAddress); //IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75); FTM


        liquidityManager = new LiquidityManager(_USDCAddress, _spookyswapAddress);


        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            spookySwapAddress
        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), address(USDC));

        uniswapV2Router = _uniswapV2Router;

        //distributor = new HolderRewarderDistributor(spookySwapAddress, _reserveAddress);

        _isExcludedFromFee[address(this)] = true;


    }
    //TODO: for debug only!
    function setDistributor(address _addr) external {
        distributor = HolderRewarderDistributor(_addr);
        // Setup initial mint
        //distributor.transferShare(_deployer, _amount);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        unchecked {
                _balances[sender] = senderBalance - amount;
        }

        if(recipient != uniswapV2Pair/*!liqTransaction*/ && recipient != reserveAddress && recipient != address(uniswapV2Router)){
            distributor.transferShare(sender, - int(amount));


            // Taking the tax and returning the amount left
            
            uint256 amountRecieved = _takeTax(amount);

            distributor.transferShare(recipient, int(amountRecieved));

            _balances[recipient] += amountRecieved;
            emit Transfer(sender, recipient, amountRecieved);


        }
        else {
            _balances[recipient] += amount;

            if(sender != teamAddress) {
                distributor.transferShare(sender, - int(amount));
            }

            if(recipient == reserveAddress){
                distributor.transferShare(recipient, int(amount));

            }
            emit Transfer(sender, recipient, amount);

        }


        //_afterTokenTransfer(sender, recipient, amountRecieved);
    }

    /** @dev Creates `amount` tokens and takes all the necessary taxes for the account.
     */
    function _takeTax(uint256 amount)
        internal
        returns (uint256 amountRecieved)
    {
        // Calculating the tax
        uint256 reserve = (amount * 197) / 10000;
        uint256 rewards = (amount * 267) / 10000;
        uint256 MDO = (amount * 75) / 10000;
        uint256 UBR = (amount * 86) / 10000;
        uint256 liquidity = (amount * 75) / 10000;

        // Adding the liquidity to the contract
        _addToLiquidity(liquidity); 

        // Sending the tokens to the reserve
        _sendToReserve(reserve);

        // Sending the MDO wallet
        _sendToMDO(MDO);

        // Adding to the Universal Basic Reward pool
        _addToUBR(UBR);

        // Adding to the rewards pool
        _addToRewards(rewards);

        return (amount - (reserve + rewards + MDO + UBR + liquidity));
    }

    function _addToRewards(uint256 amount) private {
        _balances[address(distributor)] = _balances[address(distributor)] + (amount);
        //swapTokenToUSDC(address(distributor), amount);

        distributor.addToCurrentShqToRewards(amount);
    }

    function _addToUBR(uint256 amount) private {
        _balances[address(distributor)] = _balances[address(distributor)] + (amount);
        //swapTokenToUSDC(address(distributor), amount);

        distributor.addToCurrentShqToUBR(amount);
    }

    function _addToLiquidity(uint256 amount) private {
        _balances[address(liquidityManager)] = _balances[address(liquidityManager)] + (amount);
        //liquidityManager.addToCurrentShqToLiquidity(amount);
    }

    function _sendToReserve(uint256 amount) private {
        _balances[address(this)] = _balances[address(this)] + (amount);
        swapTokenToUSDC(address(reserveAddress), amount);

        //swapTokenToUSDC(reserveAddress, amount); // Sending the USDC to the reserve
    }

    function _sendToMDO(uint256 amount) private {
        _balances[address(this)] = _balances[address(this)] + (amount);

        swapTokenToUSDC(MDOAddress, amount); // Sending the USDC to the reserve
    }


    function swapTokenToUSDC(address recipient, uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(USDC);
        _approve(address(this), address(uniswapV2Router), amount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            recipient,
            block.timestamp + 15
        );
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    // Will be called by a Keeper every day and will add to tokens taxed to the liquidity
    function initiateLiquidityProviding() public {
        liquidityManager.swapAndLiquify();
    }

    function convertAllShqToUSDC() public {
        require(msg.sender == teamAddress);
        //reserveContract.swapTokenToUSDC();
        
    }

    function getDistributor() public view returns(address){
        return address(distributor);
    }
    // TODO: make it only accessible for the team
    function processAllRewards() public {
        distributor.processAllRewards();
    }
}