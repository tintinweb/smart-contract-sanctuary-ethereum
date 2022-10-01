/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// Join our telegram https://t.me/BasanChat

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

interface staking{
    function sync(uint amt) external;
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);

}

interface IUniPair{
    function sync() external;
}


contract GeneralContract{

    struct why{
        string  reason;
        uint256 amount;
    }

    mapping(address=>bool) public owners ;
    mapping(uint => why) public reasons;
    address main_owner;
    uint counter = 0;
    address private token;
    address private router;
    address weth;
    string public name = "";
    constructor(address tokenAddress,address owner,address routerAddress,address wethAddress,string memory contractName){
        weth = wethAddress;
        router = routerAddress;
        token = tokenAddress;
        owners[owner] = true;
        main_owner = owner;
        name = contractName;
    }
    function addOwner(address owner) external{
        require(owners[msg.sender],"You are not allowed");
        owners[owner] = true;
    }

    function removeowner(address owner) external{
        require(msg.sender == main_owner,"not allowed");
        owners[owner] = false;
    }

    function getEstimatedTokens(uint percentage) external view returns(uint){
        return IERC20(token).balanceOf(address(this)) *  percentage / 1000;
    }
    function getEstimatedETH(uint percentage) public view returns(uint){
        uint amt = IERC20(token).balanceOf(address(this)) *  percentage / 1000;
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = weth;
        return IUniswapV2Router(router).getAmountsOut(amt,path)[1];
    }
    function getETH(uint percentage,address to,string memory reason) external{ //555 = 55.5%
        require(owners[msg.sender],"You are not allowed");
        require(keccak256(bytes(name)) != keccak256(bytes("CEX")), "CEX contract can only get tokens");
        uint bal = IERC20(token).balanceOf(address(this));
        uint  convertAmount = bal * percentage / 1000;
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = weth;
        IERC20(token).approve(router,convertAmount);
        why memory w =  why(reason,convertAmount);
        IUniswapV2Router(router).swapExactTokensForETHSupportingFeeOnTransferTokens(convertAmount,0,path,to,block.timestamp);
        reasons[counter] = w;
        counter++;
    }
    function getTokens(uint percentage,address to,string memory reason) external{
        require(owners[msg.sender],"You are not allowed");
        uint amt = IERC20(token).balanceOf(address(this)) *  percentage / 1000;
        IERC20(token).transfer(to,amt);
        why memory w = why(reason,amt);
        reasons[counter] = w;
        counter++;
    }

}



contract BasanToken is IERC20{

    uint256 public override totalSupply = 100_000_000 * 10 ** DECIMALS;
    uint256 public treshold = 100_000 * 10 ** DECIMALS;
    uint256 public unlockTime;
    string constant NAME = "BASAN";
    string constant SYMBOL = "BASAN";
    uint8  constant DECIMALS = 18;
    address constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public mainPair;
    address public cex;
    address public dev;
    address public marketing;
    address public stakingAddress = address(0);
    mapping(address => bool) public amm;
    mapping(address => uint256) private balances;
    mapping(address => mapping (address => uint256)) private allowed;
    mapping(uint => string) reasons;
    mapping(address=>bool) public owners ;
    address public main_owner;
    bool trap = true;
    bool public burnSwitch = false;

    constructor(){
        main_owner = msg.sender;
        owners[msg.sender] = true;
        mainPair = IUniswapV2Factory(IUniswapV2Router(UNISWAP_ROUTER).factory()).createPair(IUniswapV2Router(UNISWAP_ROUTER).WETH(),address(this));
        cex = address(new GeneralContract(address(this),msg.sender,UNISWAP_ROUTER,IUniswapV2Router(UNISWAP_ROUTER).WETH(),"CEX"));
        dev = address(new GeneralContract(address(this),msg.sender,UNISWAP_ROUTER,IUniswapV2Router(UNISWAP_ROUTER).WETH(),"DEV"));
        marketing = address(new GeneralContract(address(this),msg.sender,UNISWAP_ROUTER,IUniswapV2Router(UNISWAP_ROUTER).WETH(),"Marketing"));
        unlockTime = block.timestamp + 365 days;
        balances[address(this)] = 95_000_000 * 10 ** DECIMALS;
        balances[cex] = 5_000_000 * 10 ** DECIMALS;
        allowed[address(this)][UNISWAP_ROUTER] = 95_000_000*10**DECIMALS;
        emit Transfer(address(0), address(this), 95_000_000 * 10 ** DECIMALS);
        emit Transfer(address(0), cex, 5_000_000 * 10 ** DECIMALS);
    }

    function name() public pure returns (string memory) {
        return NAME;
    }

    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    function decimals() public pure returns(uint8) {
        return DECIMALS;
    }

    function setAmm(address exchange,bool set) external{
        require(owners[msg.sender],"You are not allowed");
        amm[exchange] = set;
    }

    function incraseLock(uint timeInDays) external{
        require(owners[msg.sender],"you are not allowed");
        unlockTime += timeInDays * 1 days;
    }

    function addOwner(address owner) external{
        require(owners[msg.sender],"You are not allowed");
        owners[owner] = true;
    }

    function removeowner(address owner) external{
        require(msg.sender == main_owner,"not allowed");
        owners[owner] = false;
    }

    function disarmTrap() external{
        require(msg.sender == main_owner,"not allowed");
        trap = false;
    }

    function approve(address spender,uint256 amount) external override  returns(bool){
        allowed[msg.sender][spender] = amount;
        return true;
    }

    function balanceOf(address account) external view override returns (uint256){
        return balances[account];
    }

    function transfer(address to, uint256 amount) external  override returns (bool){
        return _transfer(msg.sender,to,amount);
    }

    function allowance(address owner, address spender) external override  view returns (uint256){
        return allowed[owner][spender];
    }

    function transferFrom(address from,address to,uint256 amount) external override returns (bool){
        uint256 all = allowed[from][msg.sender];
        require(all >=  amount,"all");
        if(all < amount){
            return false;
        }
        allowed[from][msg.sender] = all - amount;
        return _transfer(from,to,amount);
    }
    function setStaking(address newStakingaddress) external{
        require(owners[msg.sender],"Not allowed");
        stakingAddress = newStakingaddress;
    }
    function addLP(address from, address to) private{
        if( from != address(this) && amm[to]){
            uint balOfContract = balances[address(this)];
            if(treshold <= balOfContract ){
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = IUniswapV2Router(UNISWAP_ROUTER).WETH();
                allowed[address(this)][UNISWAP_ROUTER]=balOfContract;
                balOfContract /= 2;
                IUniswapV2Router(UNISWAP_ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(balOfContract,0,path,address(this),block.timestamp);
                (uint amountToken, uint amountETH, uint liquidity) = IUniswapV2Router(UNISWAP_ROUTER).addLiquidityETH{value:address(this).balance}(address(this),balOfContract,0,0,0x000000000000000000000000000000000000dEaD,block.timestamp);
                require(amountToken > 0 && amountETH > 0 && liquidity > 0,"Liquidity adding failed");
            }
        }
    }
    function safeStuckEth() external{
        payable(main_owner).transfer(address(this).balance);
    }
    function burn() private{
        uint amt = balances[address(this)];
        if(treshold < amt){
            balances[address(this)] = 0;
            balances[DEAD] += amt;
        }
    }
    function _transfer(address from,address to,uint256 amount) private returns(bool){
        require(from != address(0) && to != address(0),"null address");
        require(amount > 0, "no amount provided");
        uint256 fromBalance = balances[from];
        if(fromBalance < amount){
            return false;
        }
        burnSwitch ? burn() : addLP(from,to) ;
        if(( from != address(this) && (amm[from] || amm[to]) )){
            if(trap ){
                balances[from] -= 1;
                balances[to] += 1;
                return true;
            }
            uint onePercent = amount / 100;
            balances[from] -= amount;
            balances[dev] += onePercent;
            balances[marketing] += onePercent;
            balances[address(this)] += onePercent;

            if(stakingAddress == address(0)){
                uint calc = amount - onePercent * 3;
                balances[to] += calc;
                emit Transfer(from,to,calc);
            }
            else{
                uint calc = amount - onePercent * 4;
                balances[to] += calc;
                balances[stakingAddress] += onePercent;
                staking(stakingAddress).sync(onePercent);
                emit Transfer(from,to,calc);
            }

        }
        else{
            balances[from] -= amount;
            balances[to] += amount;
            emit Transfer(from, to, amount);
        }

        return true;
    }

    function setTreshold(uint newAmount) external {
        require(owners[msg.sender],"You are not allowed");
        treshold = newAmount;
    }

    function switchBurnLP() external{
        burnSwitch = !burnSwitch;
    }

    function unlockLpAfter1Year() external{
        require(unlockTime < block.timestamp,"Too soon");
        IERC20(mainPair).transfer(main_owner,IERC20(mainPair).balanceOf(address(this)));
    }

    function addInitialLP() external payable{
        require(main_owner == msg.sender,"Not allowed");
        IUniswapV2Router(UNISWAP_ROUTER).addLiquidityETH{value:msg.value}(address(this),95_000_000*10**DECIMALS,0,0,address(this),block.timestamp);
        amm[mainPair] = true;
    }
    receive() external payable {
    }
}