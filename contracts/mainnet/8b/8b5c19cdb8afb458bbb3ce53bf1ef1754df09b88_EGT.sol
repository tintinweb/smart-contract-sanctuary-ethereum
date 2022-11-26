/*
##########################################################################################################################
##########################################################################################################################

Copyright CryptIT GmbH

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

##########################################################################################################################
##########################################################################################################################

*/
import "./Utils.sol";

pragma solidity ^0.8.12;

// SPDX-License-Identifier: Apache-2.0

contract EGT is Context, IERC20, AccessControl {
    using SafeMath for uint256;
    using Address for address;

    bytes32 public constant ADMIN_AUTH = keccak256("ADMIN_AUTH");
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private excludedFromFee;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint256 private _deltaLPReserve;

    uint256 private _marketingShare;
    uint256 private _buyBackShare;
    uint256 private _devShare;
    uint256 private _lpShare;

    uint256 private _buyTax;
    uint256 private _sellTax;

    uint256 private _marketingTaxCollected;
    uint256 private _buyBackTaxCollected;
    uint256 private _developmentTaxCollected;
    uint256 private _lpTaxCollected;

    uint256 private minimumTokensValueBeforeSwap;
    uint256 private minimumETHToTransfer;

    uint256 private acceptSlippageReduceFactor;
    uint256 private acceptFeeOnAddLP;

    address payable public marketingAddress;
    address payable public buyBackAddress;
    address payable public developmentAddress;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool public enableUniSwap;

    bool inSwapAndLiquify;
    bool inSplitShares;
    bool public swapAndLiquifyEnabled;
    bool public autoSplitShares;
    bool public taxesEnabled;

    mapping(address => bool) private _lockedBot;

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event EnabledUniswap();
    event UpdateOperationWallet(
        address previousAddress,
        address newAddress,
        string operation
    );

    modifier lockForSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier lockForSplitShare() {
        inSplitShares = true;
        _;
        inSplitShares = false;
    }

    function initialize() external {
        require(getRoleAdmin(ADMIN_AUTH) == 0x00, "Invalid init");

        _setupRole(ADMIN_AUTH, _msgSender());
        _setRoleAdmin(ADMIN_AUTH, ADMIN_AUTH);

        _name = "ElonGoat";
        _symbol = "EGT";
        _totalSupply = 9 * 10**9 * 10**9;
        _deltaLPReserve = 2 * 10**7 * 10**9;

        _marketingShare = 40;
        _buyBackShare = 20;
        _devShare = 20;
        _lpShare = 20;

        _buyTax = 100;
        _sellTax = 200;

        _marketingTaxCollected;
        _buyBackTaxCollected;
        _developmentTaxCollected;
        _lpTaxCollected;

        minimumTokensValueBeforeSwap = 3 * 10**15;
        minimumETHToTransfer = 1 * 10**16;

        acceptSlippageReduceFactor = 7;
        acceptFeeOnAddLP = 110;

        swapAndLiquifyEnabled = true;
        autoSplitShares = true;
        enableUniSwap = false;
        taxesEnabled = true;

        uint256 initialBalance = _totalSupply.sub(_deltaLPReserve);
        _balances[_msgSender()] = initialBalance;
        _balances[address(this)] = _deltaLPReserve;
        excludedFromFee[_msgSender()] = true;
        excludedFromFee[address(this)] = true;
        //UNISWAP V2
        _setRouterAddress(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _setOperatorsAddresses(
            payable(0x4cC2B3336692E1EF68FA2381eb8c7fFa73B8f604),
            payable(0x70fBFbA38623259c02167691B988235fbF40CC28),
            payable(0xc0f4F07D5c1619d0237E2231703C30822A04E29C)
        );

        emit Transfer(address(0), _msgSender(), initialBalance);
        emit Transfer(address(0), address(this), _deltaLPReserve);
    }

    // Start ERC-20 standard functions

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return 9;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    // End ERC-20 standart functions

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        require(!_lockedBot[from] && !_lockedBot[to], "Invalid account - contact EGT admin!");

        if (amount == 0) {
            emit Transfer(from, to, 0);
            return;
        }

        if (!taxesEnabled || excludedFromFee[from] || excludedFromFee[to]) {
            _transferStandard(from, to, amount);
            return;
        }

        bool isToPair = to == uniswapV2Pair; //means sell or provide LP
        bool isFromPair = from == uniswapV2Pair; //means buy or remove LP

        if (!isToPair && !isFromPair) {
            _transferStandard(from, to, amount);
            return;
        }

        require(enableUniSwap, "Uniswap not enabled yet");

        if (isToPair) {
            _transferToPair(from, to, amount);
        } else {
            _transferFromPair(from, to, amount);
        }

        bool hasSwapped = false;
        
        if (!inSwapAndLiquify && !inSplitShares && swapAndLiquifyEnabled) {
            uint256 contractTokenBalance = balanceOf(address(this)).sub(
                _deltaLPReserve
            );
            IUniswapV2Pair(uniswapV2Pair).sync();
            uint256 contractTokenValue = getSellValue(contractTokenBalance);
            if (contractTokenValue >= minimumTokensValueBeforeSwap) {
                swapAndLiquify(contractTokenBalance, contractTokenValue);
                hasSwapped = true;
            }
        }
        
        //Check if we have ETH to split to receivers
        if (
            !hasSwapped &&
            !inSplitShares &&
            !inSwapAndLiquify &&
            autoSplitShares &&
            address(this).balance >= minimumETHToTransfer
        ) {
            _distributeTax();
        }
    }
    
    function safeTransferETH(address to, uint256 value) internal {
        (bool sentETH, ) = payable(to).call{value: value}("");
        require(sentETH, "Failed to send ETH");
    }

    function manualSwapAndLiquify() external onlyRole(ADMIN_AUTH) {
        if (!inSwapAndLiquify && !inSplitShares) {
            uint256 contractTokenBalance = balanceOf(address(this)).sub(
                _deltaLPReserve
            );
            uint256 contractTokenValue = getSellValue(contractTokenBalance);
            if (contractTokenValue >= minimumTokensValueBeforeSwap) {
                swapAndLiquify(contractTokenBalance, contractTokenValue);
            }
        }
    }

    function manualSwapAndLiquify(uint256 tokenAmountToSwap) external onlyRole(ADMIN_AUTH) {
        if (!inSwapAndLiquify && !inSplitShares) {
            uint256 contractTokenBalance = balanceOf(address(this)).sub(
                _deltaLPReserve
            );

            require(contractTokenBalance >= tokenAmountToSwap, "Invalid amount");

            uint256 contractTokenValue = getSellValue(tokenAmountToSwap);
            if (contractTokenValue >= minimumTokensValueBeforeSwap) {
                swapAndLiquify(tokenAmountToSwap, contractTokenValue);
            }
        }
    }

    function manualWithdrawTokens(uint256 tokenAmount) external onlyRole(ADMIN_AUTH) {
        require(!inSwapAndLiquify && !inSplitShares, "In autoswap");

        uint256 contractTokenBalance = balanceOf(address(this));

        require(tokenAmount <= contractTokenBalance, "Invalid tokenamount");

        uint256 contractTokenBalanceSubDelta = contractTokenBalance.sub(
            _deltaLPReserve
        );

        if(tokenAmount > contractTokenBalanceSubDelta){
            uint256 overBalanceAmount = tokenAmount.sub(contractTokenBalanceSubDelta);
            _deltaLPReserve = _deltaLPReserve.sub(overBalanceAmount);
        }

        _transferStandard(address(this), _msgSender(), tokenAmount);
    }

    /**
     * @dev Handles all autoswap to ETH
     *
     * @param tokensToSwap the amount that will be swapped
     *
     * NOTE: will never be called if swapAndLiquify = false!.
     */
    function swapAndLiquify(uint256 tokensToSwap, uint256 outAmount)
        internal
        lockForSwap
    {
        swapTokensForEth(
            tokensToSwap,
            outAmount.mul(acceptSlippageReduceFactor).div(10)
        );
    }

    /**
     * @dev Handles swaping tokens stored on the contract, half of the {amount} for ETH and adding it with the other hald of tokens to LP
     *
     * @param ETHAmount amount of ETH to provide LP for
     * @return addedLP true on successful readd, false if not enought delta tokens
     *
     */
    function reAddLiquidity(uint256 ETHAmount, uint256 tokenAmount)
        internal
        returns (bool)
    {
        uint256 amountToken = addLiquidity(tokenAmount, ETHAmount);

        if (amountToken != 0) {
            _deltaLPReserve = _deltaLPReserve.sub(amountToken);
            return true;
        }
        return false;
    }

    /**
     * @dev Handles add {tokenAmount} and {ETHAmount} to LP
     *
     * @param tokenAmount amount of tokens to be added to LP
     * @param ETHAmount amount of ETH to be added to LP
     *
     * NOTE: LP tokens will be sent to the owner address.
     *
     */
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount)
        internal
        returns (uint256)
    {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        try
            uniswapV2Router.addLiquidityETH{value: ETHAmount}(
                address(this),
                tokenAmount,
                0,
                0,
                buyBackAddress,
                block.timestamp
            )
        returns (uint256 amountToken, uint256, uint256) {
            return amountToken;
        } catch {
            return 0;
        }
    }

    /**
     * @dev Handles selling of {tokenAmount}
     *
     * @param tokenAmount the amount of tokens to swap for ETH
     *
     */
    function swapTokensForEth(uint256 tokenAmount, uint256 expectedOutput)
        internal
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            expectedOutput,
            path,
            address(this),
            block.timestamp
        );
    }

    function getBuyValue(uint256 ETHAmount) internal view returns (uint256) {
        if(ETHAmount == 0){
            return 0;
        }
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        return uniswapV2Router.getAmountsIn(ETHAmount, path)[0];
    }

    function getSellValue(uint256 tokenAmount) internal view returns (uint256) {
        if(tokenAmount == 0){
            return 0;
        }
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        return uniswapV2Router.getAmountsOut(tokenAmount, path)[1];
    }

    function _distributeTax() internal lockForSplitShare {
        uint256 total = address(this).balance;
        uint256 mShare = total.mul(_marketingShare).div(100);
        uint256 sShare = total.mul(_buyBackShare).div(100);
        uint256 lpShare = total.mul(_lpShare).div(100);
        uint256 tShare = total.sub(mShare).sub(sShare).sub(lpShare);

        bool sentLP;
        IUniswapV2Pair(uniswapV2Pair).sync();
        uint256 tokenAmount = getBuyValue(lpShare).mul(acceptFeeOnAddLP).div(
            100
        );

        if (_deltaLPReserve < tokenAmount) {
            tShare = tShare.add(lpShare);
        } else {
            sentLP = reAddLiquidity(lpShare, tokenAmount);

            if (!sentLP) {
                tShare = tShare.add(lpShare);
                sentLP = true;
            } else {
                _lpTaxCollected = _lpTaxCollected.add(lpShare);
            }
        }

        safeTransferETH(marketingAddress, mShare);
        safeTransferETH(buyBackAddress, sShare);
        safeTransferETH(developmentAddress, tShare);

        _marketingTaxCollected = _marketingTaxCollected.add(mShare);
        _buyBackTaxCollected = _buyBackTaxCollected.add(sShare);
        _developmentTaxCollected = _developmentTaxCollected.add(tShare);
    }

    function distributeTax() external onlyRole(ADMIN_AUTH) {
        _distributeTax();
    }

    function provideLP(uint256 tokenAmount) external payable {
        uint256 initBalance = balanceOf(_msgSender());
        require(initBalance >= tokenAmount, "Insufficient token balance");

        _balances[_msgSender()] = _balances[_msgSender()].sub(tokenAmount);
        _balances[address(this)] = _balances[address(this)].add(tokenAmount);
        emit Transfer(_msgSender(), address(this), tokenAmount);

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            tokenAmount,
            tokenAmount,
            msg.value,
            _msgSender(),
            block.timestamp + 10 minutes
        );
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function _transferToPair(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        _transferWithTax(sender, recipient, amount, _sellTax);
    }

    function _transferFromPair(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        _transferWithTax(sender, recipient, amount, _buyTax);
    }

    function _transferWithTax(
        address sender,
        address recipient,
        uint256 amount,
        uint256 tax
    ) internal {
        _balances[sender] = _balances[sender].sub(amount);

        uint256 taxAmount = amount.mul(tax).div(1000);
        uint256 receiveAmount = amount.sub(taxAmount);
        _balances[address(this)] = _balances[address(this)].add(taxAmount);
        _balances[recipient] = _balances[recipient].add(receiveAmount);

        emit Transfer(sender, recipient, receiveAmount);
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return excludedFromFee[account];
    }

    function includeInFee(address account) external onlyRole(ADMIN_AUTH) {
        excludedFromFee[account] = false;
    }

    function excludeFromFee(address account) external onlyRole(ADMIN_AUTH) {
        excludedFromFee[account] = true;
    }

    function isBlockedBotAccount(address account) external view returns (bool) {
        return _lockedBot[account];
    }

    function enableBlockedBotAccount(address account) external onlyRole(ADMIN_AUTH) {
        _lockedBot[account] = false;
    }

    function blockBotAccount(address account) external onlyRole(ADMIN_AUTH) {
        _lockedBot[account] = true;
    }
    

    /**
     * @dev owner only function to set the marketing address
     *
     * Emits an {UpdateOperationWallet} event.
     *
     */
    function setMarketingAddress(address payable _marketingAddress)
        external
        onlyRole(ADMIN_AUTH)
    {
        address prevMarketing = marketingAddress;
        marketingAddress = _marketingAddress;
        excludedFromFee[marketingAddress] = true;
        excludedFromFee[prevMarketing] = false;
        emit UpdateOperationWallet(
            prevMarketing,
            marketingAddress,
            "marketing"
        );
    }

    /**
     * @dev owner only function to set the support organizations address
     *
     * Emits an {UpdateOperationWallet} event.
     *
     */
    function setBuyBackAddress(address payable _buyBackAddress)
        external
        onlyRole(ADMIN_AUTH)
    {
        address prevBuyBack = buyBackAddress;
        buyBackAddress = _buyBackAddress;
        excludedFromFee[buyBackAddress] = true;
        excludedFromFee[prevBuyBack] = false;
        emit UpdateOperationWallet(prevBuyBack, buyBackAddress, "buyBack");
    }

    /**
     * @dev owner only function to set the employees address
     *
     * Emits an {UpdateOperationWallet} event.
     *
     */
    function setDevelopmentAddress(address payable _developmentAddress) external onlyRole(ADMIN_AUTH) {
        address prevDevelopment = developmentAddress;
        developmentAddress = _developmentAddress;
        excludedFromFee[developmentAddress] = true;
        excludedFromFee[prevDevelopment] = false;
        emit UpdateOperationWallet(prevDevelopment, developmentAddress, "development");
    }

    function _setOperatorsAddresses(
        address payable _marketingAddress,
        address payable _buyBackAddress,
        address payable _developmentAddress
    ) internal {
        address prevMarketing = marketingAddress;
        address prevBuyBack = buyBackAddress;
        address prevDevelopment = developmentAddress;
        marketingAddress = _marketingAddress;
        buyBackAddress = _buyBackAddress;
        developmentAddress = _developmentAddress;
        excludedFromFee[marketingAddress] = true;
        excludedFromFee[buyBackAddress] = true;
        excludedFromFee[developmentAddress] = true;
        excludedFromFee[prevMarketing] = false;
        excludedFromFee[prevBuyBack] = false;
        excludedFromFee[prevDevelopment] = false;
        emit UpdateOperationWallet(
            prevMarketing,
            marketingAddress,
            "marketing"
        );
        emit UpdateOperationWallet(prevBuyBack, buyBackAddress, "buyBack");
        emit UpdateOperationWallet(prevDevelopment, developmentAddress, "development");
    }

    function setOperatorsAddresses(
        address payable _marketingAddress,
        address payable _buyBackAddress,
        address payable _developmentAddress
    ) external onlyRole(ADMIN_AUTH) {
        _setOperatorsAddresses(
            _marketingAddress,
            _buyBackAddress,
            _developmentAddress
        );
    }

    function setBuyBackShare(uint256 buyBackShare) external onlyRole(ADMIN_AUTH) {
        uint256 totalShare = buyBackShare
            .add(_marketingShare)
            .add(_devShare)
            .add(_lpShare);
        require(totalShare <= 100, "Cannot set share higher than 100%");
        _marketingShare = buyBackShare;
    }

    function setMarketingShare(uint256 marketingShare) external onlyRole(ADMIN_AUTH) {
        uint256 totalShare = marketingShare
            .add(_buyBackShare)
            .add(_devShare)
            .add(_lpShare);
        require(totalShare <= 100, "Cannot set share higher than 100%");
        _buyBackShare = marketingShare;
    }

    function setDevelopmentShare(uint256 developmentShare) external onlyRole(ADMIN_AUTH) {
        uint256 totalShare = developmentShare
            .add(_marketingShare)
            .add(_buyBackShare)
            .add(_lpShare);
        require(totalShare <= 100, "Cannot set share higher than 100%");
        _devShare = developmentShare;
    }

    function setLPShare(uint256 lpShare) external onlyRole(ADMIN_AUTH) {
        uint256 totalShare = lpShare
            .add(_marketingShare)
            .add(_buyBackShare)
            .add(_devShare);
        require(totalShare <= 100, "Cannot set share higher than 100%");
        _lpShare = lpShare;
    }

    function setBuyTax(uint256 buyTax) external onlyRole(ADMIN_AUTH) {
        require(buyTax <= 250, "Cannot set fees higher than 25%!");
        _buyTax = buyTax;
    }

    function getBuyTax() external view returns (uint256) {
        return _buyTax;
    }

    function setSellTax(uint256 sellTax) external onlyRole(ADMIN_AUTH) {
        require(sellTax <= 250, "Cannot set fees higher than 25%!");
        _sellTax = sellTax;
    }

    function getSellTax() external view returns (uint256) {
        return _sellTax;
    }

    /**
     * @dev public function to read the limiter on when the contract will auto convert to ETH
     *
     */
    function getTokenAutoSwapLimit() external view returns (uint256) {
        return minimumTokensValueBeforeSwap;
    }

    /**
     * @dev owner only function to set the limit of tokens to sell for ETH when reached
     *
     * @param _minimumTokensValueBeforeSwap the amount tokens ETH value when to sell from the contract
     *
     */
    function setTokenAutoSwapLimit(uint256 _minimumTokensValueBeforeSwap)
        external
        onlyRole(ADMIN_AUTH)
    {
        minimumTokensValueBeforeSwap = _minimumTokensValueBeforeSwap;
    }

    function getETHAutoTransferLimit() external view returns (uint256) {
        return minimumETHToTransfer;
    }

    function setETHAutoTransferLimit(uint256 _minimumETHToTransfer)
        external
        onlyRole(ADMIN_AUTH)
    {
        minimumETHToTransfer = _minimumETHToTransfer;
    }

    /**
     * @dev owner only function to control if the autoswap to ETH should happen
     *
     * Emits an {SwapAndLiquifyEnabledUpdated} event.
     *
     */
    function setSwapAndLiquifyEnabled(bool _enabled) external onlyRole(ADMIN_AUTH) {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setAutoSplitSharesEnables(bool _enabled) external onlyRole(ADMIN_AUTH) {
        autoSplitShares = _enabled;
    }

    function enableUniswap() external onlyRole(ADMIN_AUTH) {
        require(!enableUniSwap, "Already enabled!");
        enableUniSwap = true;
        emit EnabledUniswap();
    }

    function setAcceptedSlippage(uint256 accepted) external onlyRole(ADMIN_AUTH) {
        require(accepted <= 9, "Cannot set above 9");
        acceptSlippageReduceFactor = accepted;
    }

    function getAcceptedSlippage() external view onlyRole(ADMIN_AUTH) returns (uint256) {
        return acceptSlippageReduceFactor;
    }

    function setAcceptedFeeOnAdd(uint256 accepted) external onlyRole(ADMIN_AUTH) {
        acceptFeeOnAddLP = accepted;
    }

    function getAcceptedFeeOnAdd() external view onlyRole(ADMIN_AUTH) returns (uint256) {
        return acceptFeeOnAddLP;
    }

    function _setRouterAddress(address newRouter) internal {
        IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(newRouter);
        IUniswapV2Factory factory = IUniswapV2Factory(
            _newPancakeRouter.factory()
        );

        address existingPair = factory.getPair(
            address(this),
            _newPancakeRouter.WETH()
        );

        if (existingPair == address(0)) {
            uniswapV2Pair = factory.createPair(
                address(this),
                _newPancakeRouter.WETH()
            );
        } else {
            uniswapV2Pair = existingPair;
        }
        uniswapV2Router = _newPancakeRouter;
    }

    /**
     * @dev owner only function to set a new router address and create a new pair.
     *
     */
    function setRouterAddress(address newRouter) external onlyRole(ADMIN_AUTH) {
        _setRouterAddress(newRouter);
    }

    function totalDevelopmentTaxCollected() external view onlyRole(ADMIN_AUTH) returns (uint256) {
        return _developmentTaxCollected;
    }

    function totalMarketingTaxCollected()
        external
        view
        onlyRole(ADMIN_AUTH)
        returns (uint256)
    {
        return _marketingTaxCollected;
    }

    function totalBuyBackTaxCollected()
        external
        view
        onlyRole(ADMIN_AUTH)
        returns (uint256)
    {
        return _buyBackTaxCollected;
    }

    function totalLPTaxCollected() external view onlyRole(ADMIN_AUTH) returns (uint256) {
        return _lpTaxCollected;
    }

    function totalTaxCollected() external view onlyRole(ADMIN_AUTH) returns (uint256) {
        return
            _marketingTaxCollected +
            _developmentTaxCollected +
            _buyBackTaxCollected +
            _lpTaxCollected;
    }

    function getDeltaReserve() external view returns (uint256) {
        return _deltaLPReserve;
    }

    function depositIntoReserve(uint256 amount) external {
        require(balanceOf(_msgSender()) >= amount, "Insufficient balance");
        _balances[_msgSender()] = _balances[_msgSender()].sub(amount);
        _deltaLPReserve = _deltaLPReserve.add(amount);
        _balances[address(this)] = _balances[address(this)].add(amount);
        emit Transfer(_msgSender(), address(this), amount);
    }

    function burn(uint256 amount) external {
        require(balanceOf(_msgSender()) >= amount, "Insufficient balance");
        _balances[_msgSender()] = _balances[_msgSender()].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(_msgSender(), address(0), amount);
    }

    function O_BuyValue(uint256 ETHAmount) external view returns (uint256) {
        return getBuyValue(ETHAmount);
    }

    function O_SellValue(uint256 tokenAmount) external view returns (uint256) {
        return getSellValue(tokenAmount);
    }

    receive() external payable {}
}