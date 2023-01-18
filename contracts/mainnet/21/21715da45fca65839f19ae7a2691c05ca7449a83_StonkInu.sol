/*
 * @author Stonk Inu
 * @notice It seems the right time to stonk.
 */

// Website: https://stonkinuerc.com/
// Telegram: https://t.me/stonkgram
// Twitter: https://twitter.com/stonkerc

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IDEXFactory.sol";
import "./IDEXRouter.sol";
import "./IERC20.sol";

contract StonkInu is IERC20, Ownable {
    using SafeMath for uint256;
    address routerAdress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Stonk Inu";
    string constant _symbol = "Stonk";
    uint8 constant _decimals = 18;
    uint256 _totalSupply = 100_000_000_0 * (10 ** _decimals);

    uint256 public _maxWalletAmount = (_totalSupply * 2) / 100;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;
    mapping(address => bool) isStopExempt;
    uint256 liquidityFee = 0;

    // 3% of taxes. We'll stonk you with rewards and great marketing.
    uint256 marketingFee = 30;
    uint256 totalFee = liquidityFee + marketingFee;
    uint256 feeDenominator = 1000;

    address public marketingFeeReceiver =
        0x6fecdc40538fC84ec0DC7415C00D405f1FE904B0;

    IDEXRouter public router;
    address public pair;

    bool public stonkModeEnabled = false;
    uint256 public swapThreshold = (_totalSupply / 10000) * 100; // 1%
    bool inSwap;

    modifier stonkMode() {
        stonkModeEnabled = true;
        _;
        stonkModeEnabled = false;
    }

    constructor() Ownable(msg.sender) {
        router = IDEXRouter(routerAdress);
        pair = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;
        //NO FEES FOR DEPLOYER
        isFeeExempt[0x6fecdc40538fC84ec0DC7415C00D405f1FE904B0] = true;
        //DEPLOYER CAN BUY WITH TRADING STOPPED
        isStopExempt[0x6fecdc40538fC84ec0DC7415C00D405f1FE904B0] = true;
        isStopExempt[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true;
        isStopExempt[pair] = true;
        isStopExempt[_owner] = true;
        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[DEAD] = true;

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
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

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
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
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal returns (bool) {
        require(
            stonkModeEnabled || (amIStopExempt(_recipient)),
            "Trading is currentrly stopped."
        );
        if (inSwap) {
            return _basicTransfer(_sender, _recipient, _amount);
        }

        if (_recipient != pair && _recipient != DEAD) {
            require(
                isTxLimitExempt[_recipient] ||
                    _balances[_recipient] + _amount <= _maxWalletAmount,
                "You're trying to Stonk too much!"
            );
        }
        if (shouldSwapBack()) {
            swapBack();
        }

        _balances[_sender] = _balances[_sender].sub(
            _amount,
            "Insufficient Balance"
        );

        uint256 amountReceived = shouldTakeFee(_sender)
            ? takeFee(_sender, _amount)
            : _amount;
        _balances[_recipient] = _balances[_recipient].add(amountReceived);

        emit Transfer(_sender, _recipient, amountReceived);
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

    /*
     * @notice This function enable the trading.
               Once the trading mode is active it cannot be stopped.
               It's time to STONK!
     */
    function enableStonking() external onlyOwner {
        stonkModeEnabled = true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    /*
     * @notice The dev can disable fee for the stonkers.
     */
    function disableFee(address _stonker) external onlyOwner {
        isFeeExempt[_stonker] = true;
    }

    /*
     * @notice The dev can allow some Stonker to buy when stonkMode is not started yet.
     */
    function disableStop(address _stonker) external onlyOwner {
        isStopExempt[_stonker] = true;
    }

    /*
     * @notice The following function returns a bool if the Stonker can buy when stonkMode is still stopped.
     */
    function amIStopExempt(address _request) public view returns (bool) {
        return isStopExempt[_request];
    }

    function takeFee(
        address sender,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal stonkMode {
        uint256 contractTokenBalance = swapThreshold;
        uint256 amountToLiquify = contractTokenBalance
            .mul(liquidityFee)
            .div(totalFee)
            .div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));
        uint256 amountETHLiquidity = amountETH
            .mul(liquidityFee)
            .div(totalETHFee)
            .div(2);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(
            totalETHFee
        );

        (bool MarketingSuccess /* bytes memory data */, ) = payable(
            marketingFeeReceiver
        ).call{value: amountETHMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                DEAD,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

    function buyTokens(uint256 amount, address to) internal stonkMode {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(0, path, to, block.timestamp);
    }

    function clearStuckTBalance() external {
        _basicTransfer(
            address(this),
            marketingFeeReceiver,
            balanceOf(address(this))
        );
    }

    function setWalletLimit(uint256 amountPercent) external onlyOwner {
        _maxWalletAmount = (_totalSupply * amountPercent) / 1000;
    }

    function setSwapThreshold(uint256 _swapThreshold) external onlyOwner {
        swapThreshold = (_totalSupply / 100000) * _swapThreshold;
    }

    event AutoLiquify(uint256 amountETH, uint256 amountSTONK);
}