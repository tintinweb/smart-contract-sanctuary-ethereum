/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

/**
 *
*/

/**
 *
*/

/**
 *
*/

/**
 *
*/

/**
 *
*/

/**
 *
*/

/**
 *
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
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
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
}

contract MummyInu is IBEP20, Auth {
    using SafeMath for uint256;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    string constant _name = "MummyInu";
    string constant _symbol = "MUMMYINU";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1 * 10**6 * (10**_decimals);

    //max wallet holding of 3% supply
    uint256 public _maxWalletToken = (_totalSupply * 3) / 100;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    // diff pairs which will be taxed
    mapping(address => bool) pairs;
    mapping(address => bool) isFeeExempt;
    //whitelist CEX which list us to hold more than max wallet
    mapping(address => bool) isMaxWalletExempt;

    // this fee is what is used after contract sells
    uint256 public marketingAmount = 3;
    uint256 public devAmount = 2;
    uint256 public totalAmountDivider = 5;
    bool public feesOn = true;
    bool public antisnipe = true;
    bool public tradingEnabled = false;

    //buying fee
    uint256 public totalFee = 4;
    // selling fee
    uint256 public totalSellFee = 4;
    uint256 public totalTransferFee = 0;
    uint256 feeDenominator = 100;

    address public marketingAmountReceiver;
    address public projectMaintenanceReceiver;

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;

    bool public swapEnabled = true;
    uint256 public swapThreshold = (_totalSupply * 8) / 1000; // 0.2% of supply
    //burn is always less than swap threshold.
    uint256 public taxBurnAmount = swapThreshold.div(10); // 0.02% of the supply

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Auth(msg.sender) {
        launchedAt = block.timestamp;

        marketingAmountReceiver = 0x1a8394f104F4D79f91Eb65fba30e4150141819fe;
        projectMaintenanceReceiver = 0x1a8394f104F4D79f91Eb65fba30e4150141819fe;

        //Testnet: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        //Mainet: 0x10ED43C718714eb63d5aA57B78B54704E256024E
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        // exempted from tax
        isFeeExempt[msg.sender] = true;
        isFeeExempt[marketingAmountReceiver] = true;
        isFeeExempt[projectMaintenanceReceiver] = true;
        isFeeExempt[DEAD] = true;
        isFeeExempt[address(this)] = true;

        // exempted for max wallet
        isMaxWalletExempt[msg.sender] = true;
        isMaxWalletExempt[marketingAmountReceiver] = true;
        isMaxWalletExempt[projectMaintenanceReceiver] = true;
        isMaxWalletExempt[DEAD] = true;
        isMaxWalletExempt[address(this)] = true;
        isMaxWalletExempt[pair] = true;

        // add to pairs for taxes.
        pairs[pair] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (!authorizations[sender]) {
            require(tradingEnabled, "Trading not open yet");
        }

        // max wallet code
        if (!isMaxWalletExempt[recipient]) {
            uint256 heldTokens = balanceOf(recipient);
            require(
                (heldTokens + amount) <= _maxWalletToken,
                "Max wallet reached."
            );
        }

        if (shouldSwapBack()) {
            swapBack();
            //burn extra tax
            uint256 taxUnsold = balanceOf(address(this));
            if (taxUnsold > taxBurnAmount) {
                _basicTransfer(address(this), DEAD, taxBurnAmount);
            }
        }

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 amountReceived = !isFeeExempt[sender] && feesOn
            ? takeFee(sender, amount, recipient)
            : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(
        address sender,
        uint256 amount,
        address recipient
    ) internal returns (uint256) {
        uint256 feeAmount;

        if (antisnipe) {
            feeAmount = amount.mul(99).div(100);
        } else {
            //buying
            if (pairs[sender]) {
                feeAmount = amount.mul(totalFee).div(feeDenominator);
            }
            //selling
            else if (pairs[recipient]) {
                feeAmount = amount.mul(totalSellFee).div(feeDenominator);
            }
            // transfer 1% tax
            else {
                feeAmount = amount.mul(totalTransferFee).div(feeDenominator);
            }
        }

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    /**
     * Only swaps back if these conditions are met, during sells and when the
     * threshold is reached or when the time has reached for the swap.
     */
    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold.mul(2);
    }

    /**
     * Swaps the tax collected for fees sent to marketing and dev. The swap only swaps the threshold amount.
     */
    function swapBack() internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapThreshold,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance;
        uint256 amountBNBMarketing = amountBNB.mul(marketingAmount).div(
            totalAmountDivider
        );
        (bool tmpSuccess, ) = payable(marketingAmountReceiver).call{
            value: amountBNBMarketing
        }("");
        (bool tmpSuccess2, ) = payable(projectMaintenanceReceiver).call{
            value: amountBNB.sub(amountBNBMarketing)
        }("");
        // suppresses warning
        tmpSuccess2 = false;
        tmpSuccess = false;
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function addPairTax(address pairAddress, bool taxed) external authorized {
        pairs[pairAddress] = taxed;
    }

    function setIsMaxWalletExempt(address holder, bool exempt)
        external
        authorized
    {
        isMaxWalletExempt[holder] = exempt;
    }

    /**
     * Setup the fee recevers for marketing and dev
     */
    function setFeeReceivers(
        address _marketingAmountReceiver,
        address _projectMaintenanceReceiver
    ) external onlyOwner {
        marketingAmountReceiver = _marketingAmountReceiver;
        projectMaintenanceReceiver = _projectMaintenanceReceiver;
    }

    /**
     * Sets if tokens collected in tax should be sold for marketing and dev fees, 
     and burn amount to burn extra tax. Amounts are in token amounts without decimals.
     */
    function setSwapBackSettings(
        bool _enabled,
        uint256 _amount,
        uint256 _taxBurnAmount
    ) external authorized {
        require(
            _amount > _taxBurnAmount,
            "Swap threshold must be more than amount burned"
        );
        swapEnabled = _enabled;
        swapThreshold = _amount * 10**9;
        taxBurnAmount = _taxBurnAmount * 10**9;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function setMaxWalletPercent(uint256 percent) external onlyOwner {
        //prevent hp
        require(percent >= 1, "Max wallet can only be more than 1%");
        _maxWalletToken = _totalSupply.mul(percent).div(100);
    }

    function setFeesOn(bool _feesOn) external onlyOwner {
        feesOn = _feesOn;
    }

    function setFees(
        uint256 _totalFee,
        uint256 _totalSellFee,
        uint256 _totalTransferFee
    ) external onlyOwner {
        require(_totalFee < feeDenominator / 5);
        require(_totalSellFee < feeDenominator / 5);
        require(_totalTransferFee < feeDenominator / 10);
        totalFee = _totalFee;
        totalSellFee = _totalSellFee;
        totalTransferFee = _totalTransferFee;
    }

    function setTradingEnabled() external onlyOwner {
        tradingEnabled = true;
    }

    function removeAntiSnipe() external onlyOwner {
        antisnipe = false;
    }
}