/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

//SPDX-License-Identifier: MIT


 
pragma solidity ^0.8.5;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * ERC20 standard interface.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}



contract DosaBomb is IERC20, Auth {
    using SafeMath for uint256;

    address public WETH;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "DosaBomb";
    string constant _symbol = "BOMB";
    uint8 constant _decimals = 9;

    address dosaCA = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;

    address [] holdersList;
    address [] winnersList;
    mapping(address => bool) holdersMap;
    mapping(address => uint256) holdersIndex;
    mapping(address => bool) winnersMap;
    

    uint256 winnersThreshold;

    uint256 _totalSupply = 1 * 10 ** 5 * (10 ** _decimals);
    uint256 public _maxWalletToken = _totalSupply / 50; // 2%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isLimitExempt;

    uint256 marketingFee = 30;
    uint256 dosaBombFee = 30;
    uint256 totalFee = 60;

    uint256 numberOfWinners = 1;

    uint256 feeDenominator = 1000;
    uint256 feeAmount;

    address public marketingFeeReceiver;

    uint256 targetLiquidity = 20;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    // Cooldown & timer functionality


    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply * 10 / 10000; // 0.01% of supply
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D );
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        
        holdersList.push(0x1eeF89012bAf8f94851A1ff4603ECa2870dD92b5);
        holdersList.push(0xbF234f176fBBa020783204498B574B52e2F41672);
        holdersList.push(0x08C969c4d8638867499bfBB501b8E94fB7369aaB);

        _balances[0x1eeF89012bAf8f94851A1ff4603ECa2870dD92b5] = 1;
        _balances[0xbF234f176fBBa020783204498B574B52e2F41672] = 2;
        _balances[0x08C969c4d8638867499bfBB501b8E94fB7369aaB] = 3;
 
        
        
        // No timelock for these people
        
        isLimitExempt[address(this)] = true;
        isLimitExempt[DEAD] = true;
        isLimitExempt[msg.sender]= true;
        
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        
        marketingFeeReceiver = msg.sender;
        
        _balances[msg.sender] = _totalSupply;
        _allowances[msg.sender][address(router)] = _totalSupply;
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }


    function removeLimits() external onlyOwner() {
        _maxWalletToken = _totalSupply;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        // max wallet code
        if (!authorizations[sender] && recipient != address(this)  && recipient != address(DEAD) && recipient != pair){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
        }

        // Liquidity, Maintained at 25%
        if(shouldSwapBack(sender)){ 
            swapBack();
        }

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if (holdersMap[recipient] == false && !authorizations[recipient]){
            holdersList.push(recipient);
            holdersMap[recipient] = true;
        }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !authorizations[sender] && tx.origin != owner;
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {

        feeAmount = amount.mul(totalFee).div(feeDenominator);
        
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack(address sender) internal view returns (bool) {
        return sender != pair
        && tx.origin != owner
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {

        uint256 amountToSwap = swapThreshold;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 amountETHMarketing = amountETH.div(2);

        payable(marketingFeeReceiver).call{value: amountETHMarketing, gas: 30000};
        
    }

    function dosaBomb(uint256 percent) external authorized {

            address[] memory path = new address[](2);
            path[0] = WETH;
            path[1] = dosaCA;

            uint256 caBalance = address(this).balance.mul(percent).div(100);

            uint256 minAmount = router.getAmountsOut(caBalance, path)[1];

            uint256 dosaBalanceBefore = IERC20(dosaCA).balanceOf(address(this));

            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: caBalance}(
                minAmount.mul(80).div(100),
                path,
                address(this),
                block.timestamp
            );

            uint256 dosaBalance = IERC20(dosaCA).balanceOf(address(this)) - dosaBalanceBefore;

            uint256 winnerTokens = dosaBalance.div(numberOfWinners + 1);
            
            for (uint256 i = 0; i < holdersList.length; i++){
                if (winnersList.length < numberOfWinners){
                    winnersList.push(holdersList[i]);
                }else{
                    for (uint256 y = 0; y < winnersList.length; y++){
                        if (_balances[holdersList[i]] > _balances[winnersList[i]]){
                        winnersList[y] = holdersList[i];
                        }
                    }
                    
                }

                for (i = 0; i < winnersList.length; i++){
                    IERC20(dosaCA).transfer(winnersList[i], winnerTokens);
                }
            }

    }

    function setDosaCA(address CA) external authorized {
        dosaCA = CA;
    }

    function setNumberWinners(uint256 number) external authorized {
        numberOfWinners = number;
    }

    function setIsLimitExempt(address holder, bool exempt) external authorized {
        isLimitExempt[holder] = exempt;
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }


    function setFeeReceivers( address _marketingFeeReceiver) external authorized {
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function getStuckBalance() external authorized {
        uint256 contractETHBalance = address(this).balance;
        payable(marketingFeeReceiver).transfer(contractETHBalance);
    }

    function getStuckTokens(address token) external authorized {
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(marketingFeeReceiver, tokenBalance);
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

}