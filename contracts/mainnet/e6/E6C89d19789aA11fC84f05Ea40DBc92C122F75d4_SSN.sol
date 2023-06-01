/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

//telegram: https://t.me/+NMgIVH7gywc5ZTRh


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

    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * Function modifier to require caller to be contract deployer
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!Owner"); _;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Transfer ownership to new address. Caller must be deployer. Leaves old deployer authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
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


contract SSN is IERC20, Auth {
    using SafeMath for uint256;

    address private WETH;

    string private constant  _name = "Social Security Number";
    string private constant _symbol = "SSN";
    uint8 public constant _decimals = 18;

    uint256 private _totalSupply = 1000000000000 * (10 ** _decimals); 

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private cooldown;
    mapping (address => int) public tickets;

    mapping (address => bool) private isFeeExempt;
    mapping (address => bool) private isBot;
            
    uint256 public buyFee = 25;
    uint256 public sellFee = 25;
    uint256 private feeDenominator = 100;

    address payable public teamWallet = payable(0x98FC43C83F1A135Db9E30c4f51d96687720aa45f);
    uint256 public swapThresholdAmount = 10000000000 * (10**_decimals);

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;
    bool private tradingOpen;
    bool private buyLimit = true;
    uint256 private maxBuy = 10000000001 * (10 ** _decimals);
    

    bool public blacklistEnabled = false;
    bool private inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (
        address _owner
    ) Auth(_owner) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);        
        WETH = router.WETH();        
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        approve(address(router), type(uint).max);
        IERC20(pair).approve(address(router), type(uint).max);  
        
        _allowances[address(this)][address(router)] = type(uint256).max;

        isFeeExempt[_owner] = true;
        isFeeExempt[teamWallet] = true; 
        isFeeExempt[address(this)] = true;            
        
        isBot[0x6b75d8AF000000e20B7a7DDf000Ba900b4009A80] = true;

        _balances[_owner] = _totalSupply;
    
        emit Transfer(address(0), _owner, _totalSupply);
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

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (!tradingOpen) {
            require (sender == owner ||  sender == address (this));
            return _basicTransfer(sender, recipient, amount);
        }
        
        if (blacklistEnabled) {
            require (!isBot[sender] && !isBot[recipient], "Bot!");
        }
        if (buyLimit) { 
            require (amount<=maxBuy, "Too much sir");        
        }

        if (sender == pair && recipient != address(router) && !isFeeExempt[recipient]) {
            require (cooldown[recipient] < block.timestamp);
            cooldown[recipient] = block.timestamp + 60 seconds;
            if (block.number <= (launchedAt + 1)) { 
                isBot[recipient] = true;
            }
        }        
       
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }    

        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >= swapThresholdAmount;
    
        bool shouldSwapBack = (overMinTokenBalance && recipient==pair && balanceOf(address(this)) > 0);
        if(shouldSwapBack){ swapBack(); }  

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, amount) : amount;
        
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

 
    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return ( !(isFeeExempt[sender] || isFeeExempt[recipient]) &&  (sender == pair || recipient == pair) );
   }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount;
        if(sender != pair) {
            feeAmount = amount.mul(sellFee).div(feeDenominator);
        }
        else {
            feeAmount = amount.mul(buyFee).div(feeDenominator);
        }
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);   

        return amount.sub(feeAmount);
    }

   
function swapBack() internal swapping {
        uint256 contractTokenBalance = balanceOf(address(this));

        uint256 amountToSwap;

        if (contractTokenBalance >= swapThresholdAmount) {
            amountToSwap = swapThresholdAmount;
        }
            else {
                amountToSwap = contractTokenBalance;
        }
              
        swapTokensForEth(amountToSwap);

        uint256 contractETHBalance = address(this).balance;
             
        payable(teamWallet).transfer(contractETHBalance);          
    }

    

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    
    function launch() external onlyOwner {
      
        router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp
        );       

        launchedAt = block.number;
        tradingOpen = true;
    }    

    function removeBuyLimit() external onlyOwner {
        buyLimit = false;
    }

    function setBuyFee (uint256 _fee) external onlyOwner {
        require(buyFee != 0); //once set to 0, fee can't be increased
        buyFee = _fee;
    }

     function setSellFee (uint256 _fee) external onlyOwner {
        require(sellFee != 0); //once set to 0, fee can't be increased
        sellFee = _fee;
    }   

    function setTeamWallet(address _teamWallet) external onlyOwner {
        teamWallet = payable(_teamWallet);
    } 

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setBlacklistEnabled() external onlyOwner {
        require (blacklistEnabled == false, "can only be called once");
        blacklistEnabled = true;
    }
    
    function setBot(address _address, bool toggle) public onlyOwner {
        isBot[_address] = toggle;
    }

    function checkBot(address account) public view returns (bool) {
        return isBot[account];
    }

    function blacklistArray (address[] calldata bots) external onlyOwner {
        require (bots.length > 0);
        uint i =0;
        while (i < bots.length) {
            setBot(bots[i],  true);
            i++;
        }
    }

    function setSwapThresholdAmount (uint256 amount) external onlyOwner {
        swapThresholdAmount = _totalSupply.mul(amount).div(1000);
    } 
  
    function manualSend() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        payable(teamWallet).transfer(contractETHBalance);
    }
  
}