/**
 *Submitted for verification at Etherscan.io on 2023-01-21
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;


interface IERC20 {
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
   
    function allowance(address owner, address spender) external view returns (uint256);
   
    function approve(address spender, uint256 amount) external returns (bool);
   
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;



interface IERC20Metadata is IERC20 {
    
    function name() external view returns (string memory);

   
    function symbol() external view returns (string memory);

   
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;


library SafeMath {
   
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
  
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
   
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
  
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
  
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
  
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
   
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
 
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
  
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
   
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;



abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
 
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
 
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
   
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: MMT.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;


interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

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

contract ModernMoneyTech is IERC20Metadata, Ownable {
    using SafeMath for uint256;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "Modern Money Tech";
    string constant _symbol = "MMT";
    uint8 constant _decimals = 18;
 
    uint256 _totalSupply =  1000000000000000 * (10 ** 18);

    uint256 public maxTx = _totalSupply.div(100);
    uint256 public maxWallet = _totalSupply.div(50);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isMaxWalletExempt;

    uint256 public teamFee = 100;
    uint256 public marketingFee = 200;
    uint256 public DevFee = 200;
    uint256 public liquidityFee = 100;
    uint256 public totalFee = 600;
    uint256 public feeDenominator = 10000;

    address public teamRcvr;
    address public marketingRcvr;
    address public DevRcvr;
    address public liquidityRcvr;

    IDEXRouter public UNISWAPRouter;
    address ETHPair;

    uint256 public launchedAt;

    bool public liquifyEnabled = false;
    bool public swapEnabled = false;

    uint256 public swapThreshold = _totalSupply.div(200);
    bool public inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    
    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
    event Launched(uint256 blockNumber, uint256 timestamp);
    event SwapBackSuccess(uint256 amount);
    event SwapBackFailed(string message);

    constructor () Ownable() {
        
        UNISWAPRouter = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        ETHPair = IDEXFactory(UNISWAPRouter.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(UNISWAPRouter)] = ~uint256(0);

        address owner_ = msg.sender;

        teamRcvr = owner_;
        marketingRcvr = owner_;
        DevRcvr = owner_;
        liquidityRcvr = owner_;


        isMaxWalletExempt[owner_] = true;
        isMaxWalletExempt[address(ETHPair)] = true;
        isMaxWalletExempt[address(this)] = true;

        isFeeExempt[owner_] = true;
        isFeeExempt[address(this)] = true;

        isTxLimitExempt[owner_] = true;
        isTxLimitExempt[address(this)] = true;

        approve(address(UNISWAPRouter), _totalSupply);
        _balances[owner_] = _totalSupply;
        emit Transfer(address(0), owner_, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender_, uint256 amount_) public override returns (bool) {
        _allowances[msg.sender][spender_] = amount_;
        emit Approval(msg.sender, spender_, amount_);
        return true;
    }

    function approveMax(address spender_) external returns (bool) {
        return approve(spender_, ~uint256(0));
    }

    function clearStuckETH(address wallet_) external onlyOwner {
        payable(wallet_).transfer(address(this).balance);
    }

    function transfer(address recipient_, uint256 amount_) external override returns (bool) {
        return _transferFrom(msg.sender, recipient_, amount_);
    }

    function transferFrom(address sender_, address recipient_, uint256 amount_) external override returns (bool) {
        if(_allowances[sender_][msg.sender] != ~uint256(0)){
            _allowances[sender_][msg.sender] = _allowances[sender_][msg.sender].sub(amount_, "Insufficient Allowance");
        }

        return _transferFrom(sender_, recipient_, amount_);
    }

    function _transferFrom(address sender_, address recipient_, uint256 amount_) internal returns (bool) {
        require(sender_ != address(0) && recipient_ != address(0), "Zero Address Transfer");
        require(passLimitChecks(sender_, recipient_, amount_), "Over TX or Wallet Limit");

        if(inSwap){ return _basicTransfer(sender_, recipient_, amount_); }
        
        if(shouldSwapBack()){ swapBack(); }

        if(!launched() && recipient_ == ETHPair) { require(_balances[sender_] > 0); launch(); }

        _balances[sender_] = _balances[sender_].sub(amount_, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender_, recipient_) ? takeFee(sender_, amount_) : amount_;
        _balances[recipient_] = _balances[recipient_].add(amountReceived);
        
        emit Transfer(sender_, recipient_, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender_, address recipient_, uint256 amount_) internal returns (bool) {
        _balances[sender_] = _balances[sender_].sub(amount_, "Insufficient Balance");
        _balances[recipient_] = _balances[recipient_].add(amount_);
        emit Transfer(sender_, recipient_, amount_);
        return true;
    }

    function passLimitChecks(address sender_, address recipient_, uint256 amount_) internal view returns (bool) {
        if(amount_ > maxTx && !isTxLimitExempt[sender_]) { return false; }
        if(sender_ == ETHPair && _balances[recipient_].add(amount_) > maxWallet) { return false; }
        return true;
    }

    function shouldTakeFee(address sender_, address recipient_) internal view returns (bool) {
        if (isFeeExempt[sender_] || isFeeExempt[recipient_] || !launched()) return false;
        if (sender_ == ETHPair || recipient_ == ETHPair) return true;
        return false;
    }

    function takeFee(address sender_, uint256 amount_) internal returns (uint256) {
        uint256 feeAmount = amount_.mul(totalFee).div(feeDenominator);
        
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender_, address(this), feeAmount);

        return amount_.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != ETHPair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 swapLiquidityFee = liquifyEnabled ? liquidityFee : 0;
        uint256 amountToLiquify = swapThreshold.mul(swapLiquidityFee).div(totalFee).div(2);

        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uint256 balanceBefore = address(this).balance;

        try UNISWAPRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        ) {

            uint256 amountETH = address(this).balance.sub(balanceBefore);

            uint256 totalETHFee = totalFee.sub(swapLiquidityFee.div(2));

            uint256 amountETHLiquidity = amountETH.mul(swapLiquidityFee).div(totalETHFee).div(2);
            uint256 amountETHTeam = amountETH.mul(teamFee).div(totalETHFee);
            uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);
            uint256 amountETHDev = amountETH.mul(DevFee).div(totalETHFee);
           

            payable(address(teamRcvr)).transfer(amountETHTeam);
            payable(address(marketingRcvr)).transfer(amountETHMarketing);
            payable(address(DevRcvr)).transfer(amountETHDev);
           
        
            if(amountToLiquify > 0){
                try UNISWAPRouter.addLiquidityETH{ value: amountETHLiquidity }(
                    address(this),
                    amountToLiquify,
                    0,
                    0,
                    liquidityRcvr,
                    block.timestamp
                ) {
                    emit AutoLiquify(amountToLiquify, amountETHLiquidity);
                } catch {
                    emit AutoLiquify(0, 0);
                }
            }

            emit SwapBackSuccess(amountToSwap);
        } catch Error(string memory e) {
            emit SwapBackFailed(string(abi.encodePacked("SwapBack failed with error ", e)));
        } catch {
            emit SwapBackFailed("SwapBack failed without an error message from pancakeSwap");
        }
    }

    function launch() internal {
        launchedAt = block.number;
        emit Launched(block.number, block.timestamp);
    }
    
   
    function setIsFeeExempt(address holder_, bool exempt_) external onlyOwner {
        isFeeExempt[holder_] = exempt_;
    }

    function setIsTxLimitExempt(address holder_, bool exempt_) external onlyOwner {
        isTxLimitExempt[holder_] = exempt_;
    }


    function setIsMaxWalletExempt(address holder_, bool exempt_) external onlyOwner {
        isMaxWalletExempt[holder_] = exempt_;
    }

        function setTeamReceiver(address teamRcvr_) external onlyOwner {
        teamRcvr = teamRcvr_;
    }

    function setMarketingReceiver(address marketingRcvr_) external onlyOwner {
        marketingRcvr = marketingRcvr_;
    }

    function setDevReceiver(address DevRcvr_) external onlyOwner {
        DevRcvr = DevRcvr_;
    } 

    // Swap and Auto-LP
    function setSwapBackSettings(bool enabled_, uint256 amount_) external onlyOwner {
        swapEnabled = enabled_;
        swapThreshold = amount_;
    }
    
    function setLiquifyEnabled(bool enabled_) external onlyOwner {
        liquifyEnabled = enabled_;
    }

    
    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

}