/**
 ______    ______   ________   ______    ______   _______          ______   __    __  ______  _______    ______
 /      \  /      \ |        \ /      \  /      \ |       \        /      \ |  \  |  \|      \|       \  /      \
|  $$$$$$\|  $$$$$$\| $$$$$$$$|  $$$$$$\|  $$$$$$\| $$$$$$$\      |  $$$$$$\| $$  | $$ \$$$$$$| $$$$$$$\|  $$$$$$\
| $$   \$$| $$__| $$| $$__    | $$___\$$| $$__| $$| $$__| $$      | $$___\$$| $$__| $$  | $$  | $$__/ $$| $$__| $$
| $$      | $$    $$| $$  \    \$$    \ | $$    $$| $$    $$       \$$    \ | $$    $$  | $$  | $$    $$| $$    $$
| $$   __ | $$$$$$$$| $$$$$    _\$$$$$$\| $$$$$$$$| $$$$$$$\       _\$$$$$$\| $$$$$$$$  | $$  | $$$$$$$\| $$$$$$$$
| $$__/  \| $$  | $$| $$_____ |  \__| $$| $$  | $$| $$  | $$      |  \__| $$| $$  | $$ _| $$_ | $$__/ $$| $$  | $$
 \$$    $$| $$  | $$| $$     \ \$$    $$| $$  | $$| $$  | $$       \$$    $$| $$  | $$|   $$ \| $$    $$| $$  | $$
  \$$$$$$  \$$   \$$ \$$$$$$$$  \$$$$$$  \$$   \$$ \$$   \$$        \$$$$$$  \$$   \$$ \$$$$$$ \$$$$$$$  \$$   \$$


Website: http://wwww.caesarshibaavax.com
Telegram: https://t.me/caesarshibaavax
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './ERC20.sol';
import './JoeTrader.sol';
import './SafeMath.sol';

contract CaesarShiba is ERC20 {
    using SafeMath for uint256;

    // DEX router
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public chestAddress = 0x8F6Eef1Bd290177922Df0a4fe0E9D056C06EcA30;
    address payable public marketingAddress = payable(0x8F6Eef1Bd290177922Df0a4fe0E9D056C06EcA30);
    mapping (address => bool) public _isExcludedFromFee;
    address payable public _owner;
    bool public _manualSwap = true;
    uint public _feesLiquidity = 0;
    uint public _feesMarketing = 6;
    uint public _feesChest = 4;
    uint public _chestPercentWon = 50;
    uint toMint = 10 ** (18 + 8);
    uint public _minAmountToParticipate = toMint / 10000;
    uint minSwapAmount = toMint / 1000;
    uint maxSwapAmount = toMint / 100;
    uint public _maxWallet;
    // Chest infos
    uint public _maxChest;
    uint public _startTimeChest;
    uint public _minTimeHoldingChest = 30;
    address public _chestWonBy;
    address public _lastParticipantAddress;
    mapping (address => bool) private _isExcludedFromGame;
    // Presale
    bool public _presaleRunning = true;
    mapping (address => bool) _presale;

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Call authorized only for owner");
        _;
    }

    struct WinHistory {
        uint time;
        uint amount;
        address account;
    }

    WinHistory[] public _winningHistory;

    bool inSwapAndLiquify;
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() ERC20("CaesarShiba", "CSRSHIBA") {
        _owner = payable(msg.sender);

        address uniswapV2RouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddress);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _isExcludedFromFee[_owner] = true;
        _isExcludedFromFee[marketingAddress] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[chestAddress] = true;
        _isExcludedFromFee[address(0)] = true;
        _isExcludedFromFee[uniswapV2RouterAddress] = true;

        _isExcludedFromGame[chestAddress] = true;
        _isExcludedFromGame[address(this)] = true;
        _isExcludedFromGame[_owner] = true;
        _isExcludedFromGame[marketingAddress] = true;
        _isExcludedFromGame[address(0)] = true;
        _isExcludedFromGame[uniswapV2Pair] = true;
        _isExcludedFromGame[uniswapV2RouterAddress] = true;

        _presale[chestAddress] = true;
        _presale[address(this)] = true;
        _presale[_owner] = true;
        _presale[marketingAddress] = true;
        _presale[address(0)] = true;
        _presale[uniswapV2Pair] = true;
        _presale[uniswapV2RouterAddress] = true;

        _mint(msg.sender, toMint);
        _maxWallet = _totalSupply / 100;
        _maxChest = (_totalSupply / 100) * 3;
    }

    function launch() public onlyOwner{
        setManualSwap(false);
        setPresaleActivation(false);
    }

    function _addLiquidity(uint amountTokenDesired, uint amountETH) private
    {
        _approve(address(this), address(uniswapV2Router), amountTokenDesired);
        uniswapV2Router.addLiquidityETH{value: amountETH}(address(this), amountTokenDesired, 0, 0, _owner, block.timestamp);
    }

    function swapTokensForETH(uint amountToken) private
    {
        // Step 1 : approve
        _approve(address(this), address(uniswapV2Router), amountToken);

        // Step 2 : swapExactTokensForETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountToken, 0, path, address(this), block.timestamp + 1 minutes);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /*amount*/
    ) internal override
    {
        bool isBuying = from == uniswapV2Pair;
        if (_presaleRunning && isBuying) {
            require(_presale[to], "Buys are reserved to whitelisted addresses during presale");
        }

        bool isSelling = to == uniswapV2Pair;
        if (isSelling && !_manualSwap && !inSwapAndLiquify && balanceOf(uniswapV2Pair) > 0)
        {
            _swapAndLiquify();
        }
    }


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override
    {
        if (!_presaleRunning) {
            manageChest(from, to, amount);
        }

        bool isBuying = from == uniswapV2Pair;
        if (!_presaleRunning && !_isExcludedFromFee[from] && !_isExcludedFromFee[to] && balanceOf(uniswapV2Pair) > 0)
        {
            if ((_feesLiquidity + _feesMarketing + _feesChest) > 0) {
                // bool isSelling = to == uniswapV2Pair;
                uint feesPercentage = _feesLiquidity.add(_feesMarketing);
                // use isSelling ? condition if sell taxes != buy taxes
                uint256 contractFeesAmount = amount.mul(feesPercentage).div(100);
                uint chestFeeAmount = amount.mul(_feesChest).div(100);
                _balances[to] = _balances[to].sub(contractFeesAmount.add(chestFeeAmount));
                _balances[address(this)] = _balances[address(this)].add(contractFeesAmount);
                _balances[chestAddress] = _balances[chestAddress].add(chestFeeAmount);
                if (_balances[chestAddress] > _maxChest) {
                    uint overflow = _balances[chestAddress].sub(_maxChest);
                    _balances[address(this)] = _balances[address(this)].add(overflow);
                    _balances[chestAddress] = _balances[chestAddress].sub(overflow);
                }
            }
        }
        // Anti whale
        if (isBuying && !_isExcludedFromFee[to]) {
            require(_balances[to] <= _maxWallet, "Impossible to hold more than max wallet");
        }
    }

    function _swapAndLiquify() internal lockTheSwap
    {
        uint contractBalance = _balances[address(this)];
        if (contractBalance > minSwapAmount || _manualSwap)
        {
            if (contractBalance > maxSwapAmount && !_manualSwap)
            {
                contractBalance = maxSwapAmount;
            }

            uint totalFees = _feesMarketing.add(_feesLiquidity);
            uint marketingTokens = contractBalance.mul(_feesMarketing).div(totalFees == 0 ? 1 : totalFees);
            uint liquidityTokens = contractBalance.sub(marketingTokens);
            uint liquidityTokensHalf = liquidityTokens.div(2);
            uint liquidityTokensOtherHalf = liquidityTokens.sub(liquidityTokensHalf);

            swapTokensForETH(marketingTokens.add(liquidityTokensHalf));
            uint amountETHToLiquefy = address(this).balance.mul(liquidityTokensHalf).div(marketingTokens.add(liquidityTokensHalf));
            _addLiquidity(liquidityTokensOtherHalf, amountETHToLiquefy);
            (bool sent,) = marketingAddress.call{value : address(this).balance}("");
            require(sent, "Failed to send Ether");
        }
    }

    function swapAndLiquify() public onlyOwner
    {
        _swapAndLiquify();
    }

    function checkReward() public {
        if (!inSwapAndLiquify && _startTimeChest > 0 && block.timestamp > _startTimeChest + _minTimeHoldingChest * 1 minutes) {
            // We have a winner
            _startTimeChest = 0;
            uint amountWon = _balances[chestAddress].mul(_chestPercentWon).div(100);
            _balances[_lastParticipantAddress] = _balances[_lastParticipantAddress].add(amountWon);
            _balances[chestAddress] = _balances[chestAddress].sub(amountWon);
            _chestWonBy = _lastParticipantAddress;
            _lastParticipantAddress = 0x000000000000000000000000000000000000dEaD;
            // Store all victories
            WinHistory memory winHistory;
            winHistory.time = block.timestamp;
            winHistory.amount = amountWon;
            winHistory.account = _chestWonBy;
            _winningHistory.push(winHistory);
        }
    }

    function manageChest(address from, address to, uint amount) private {
        checkReward();

        bool isBuying = from == uniswapV2Pair;
        if (isBuying && amount >= _minAmountToParticipate && !_isExcludedFromGame[to] && _lastParticipantAddress != to) {
            // Buyer is now owner of the chest
            _startTimeChest = block.timestamp;
            _lastParticipantAddress = to;
        }
    }

    receive() external payable {}

    function chestAmount() public view returns (uint) { return _balances[chestAddress]; }
    function historySize() public view returns (uint) { return _winningHistory.length; }

    function setMinAmountToParticipate(uint value) public onlyOwner {
        _minAmountToParticipate = value;
    }
    function setMinSwapAmount(uint value) public onlyOwner {
        minSwapAmount = value;
    }
    function setMaxSwapAmount(uint value) public onlyOwner {
        maxSwapAmount = value;
    }
    function setMaxWalletAmount(uint value) public onlyOwner {
        _maxWallet = value;
    }
    function setMaxChestAmount(uint value) public onlyOwner {
        _maxChest = value;
    }
    function setChestPercentWon(uint value) public onlyOwner {
        _chestPercentWon = value;
    }

    function setFeeLiquidity(uint value) public onlyOwner {
        _feesLiquidity = value;
    }
    function setFeeMarketing(uint value) public onlyOwner {
        _feesMarketing = value;
    }
    function setFeeChest(uint value) public onlyOwner {
        _feesChest = value;
    }

    function setMinTimeHoldingChest(uint value) public onlyOwner {
        _minTimeHoldingChest = value;
    }

    function setManualSwap(bool value) public onlyOwner {
        _manualSwap = value;
    }
    function setGameParticipation(bool value, address add) public onlyOwner {
        _isExcludedFromGame[add] = value;
    }
    function setTaxContribution(bool value, address add) public onlyOwner {
        _isExcludedFromFee[add] = value;
    }
    function setPresaleActivation(bool value) public onlyOwner {
        _presaleRunning = value;
    }
    function addToPresale(address account) public onlyOwner {
        _presale[account] = true;
    }

    /**
     * HELPER FUNCTIONS
     */
    function changeOwner(address newOwner) public onlyOwner {
        _owner = payable(newOwner);
    }

    function addLiquidityInit(uint amountTokenDesired) public payable onlyOwner
    {
        _balances[address(this)] += amountTokenDesired;
        _balances[msg.sender] -= amountTokenDesired;
        _approve(address(this), address(uniswapV2Router), amountTokenDesired);
        uniswapV2Router.addLiquidityETH{value: msg.value}(address(this), amountTokenDesired, 0, 0, msg.sender, block.timestamp);
    }

    function retrieveETHFromContract() public onlyOwner {
        (bool sent,) = _owner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function getETHBalance(address account) public view onlyOwner returns (uint) {
        return account.balance;
    }

    function burn(uint256 amount) public onlyOwner {
        _burn(address(this), amount);
    }

    struct LockBoxStruct {
        uint balance;
        uint releaseTime;
    }

    LockBoxStruct[] public lockBoxStructs; // This could be a mapping by address, but these numbered lockBoxes support possibility of multiple tranches per address

    event LogLockBoxDeposit(address sender, uint amount, uint releaseTime);
    event LogLockBoxWithdrawal(address receiver, uint amount);

    // This function is used to lock LP tokens
    function lockLiquidityPool(uint amount, uint numSecondsToLock) public onlyOwner returns(bool success) {
        require(IERC20(uniswapV2Pair).transferFrom(msg.sender, address(this), amount));
        LockBoxStruct memory l;
        l.balance = amount;
        uint releaseTime = block.timestamp + numSecondsToLock;
        l.releaseTime = releaseTime;
        lockBoxStructs.push(l);
        emit LogLockBoxDeposit(msg.sender, amount, releaseTime);
        return true;
    }

    // This function is used to recover LP tokens after the lock delay is over
    function withdrawExpiredLock(uint lockBoxNumber) public onlyOwner returns(bool) {
        LockBoxStruct storage l = lockBoxStructs[lockBoxNumber];
        require(l.releaseTime <= block.timestamp); // This garranties the liquidity pool locking feature, it's impossible to recover your LP token if the release time is not reached.
        uint amount = l.balance;
        l.balance = 0;
        emit LogLockBoxWithdrawal(msg.sender, amount);
        require(IERC20(uniswapV2Pair).transfer(msg.sender, amount));
        return true;
    }

    function extendLockTime(uint lockBoxNumber, uint numSecondsToLock) public onlyOwner returns(bool) {
        LockBoxStruct storage l = lockBoxStructs[lockBoxNumber];
        require(block.timestamp + numSecondsToLock > l.releaseTime);
        l.releaseTime = block.timestamp + numSecondsToLock;
        return true;
    }

    function getRemainingLockTime(uint lockBoxNumber) public view returns(uint)
    {
        return lockBoxStructs[lockBoxNumber].releaseTime - block.timestamp;
    }

    function isChestWon() public view returns(bool)
    {
        return !inSwapAndLiquify && _startTimeChest > 0 && block.timestamp > _startTimeChest + _minTimeHoldingChest * 1 minutes;
    }
}