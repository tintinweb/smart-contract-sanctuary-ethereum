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

        require(
            !_lockedBot[from] && !_lockedBot[to],
            "Invalid account - contact EGT admin!"
        );

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

    function manualSwapAndLiquify(uint256 tokenAmountToSwap)
        external
        onlyRole(ADMIN_AUTH)
    {
        if (!inSwapAndLiquify && !inSplitShares) {
            uint256 contractTokenBalance = balanceOf(address(this)).sub(
                _deltaLPReserve
            );

            require(
                contractTokenBalance >= tokenAmountToSwap,
                "Invalid amount"
            );

            uint256 contractTokenValue = getSellValue(tokenAmountToSwap);
            if (contractTokenValue >= minimumTokensValueBeforeSwap) {
                swapAndLiquify(tokenAmountToSwap, contractTokenValue);
            }
        }
    }

    function manualWithdrawTokens(uint256 tokenAmount)
        external
        onlyRole(ADMIN_AUTH)
    {
        require(!inSwapAndLiquify && !inSplitShares, "In autoswap");

        uint256 contractTokenBalance = balanceOf(address(this));

        require(tokenAmount <= contractTokenBalance, "Invalid tokenamount");

        uint256 contractTokenBalanceSubDelta = contractTokenBalance.sub(
            _deltaLPReserve
        );

        if (tokenAmount > contractTokenBalanceSubDelta) {
            uint256 overBalanceAmount = tokenAmount.sub(
                contractTokenBalanceSubDelta
            );
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
        if (ETHAmount == 0) {
            return 0;
        }
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        return uniswapV2Router.getAmountsIn(ETHAmount, path)[0];
    }

    function getSellValue(uint256 tokenAmount) internal view returns (uint256) {
        if (tokenAmount == 0) {
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

    function enableBlockedBotAccount(address account)
        external
        onlyRole(ADMIN_AUTH)
    {
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
    function setDevelopmentAddress(address payable _developmentAddress)
        external
        onlyRole(ADMIN_AUTH)
    {
        address prevDevelopment = developmentAddress;
        developmentAddress = _developmentAddress;
        excludedFromFee[developmentAddress] = true;
        excludedFromFee[prevDevelopment] = false;
        emit UpdateOperationWallet(
            prevDevelopment,
            developmentAddress,
            "development"
        );
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
        emit UpdateOperationWallet(
            prevDevelopment,
            developmentAddress,
            "development"
        );
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

    function setBuyBackShare(uint256 buyBackShare)
        external
        onlyRole(ADMIN_AUTH)
    {
        uint256 totalShare = buyBackShare
            .add(_marketingShare)
            .add(_devShare)
            .add(_lpShare);
        require(totalShare <= 100, "Cannot set share higher than 100%");
        _marketingShare = buyBackShare;
    }

    function setMarketingShare(uint256 marketingShare)
        external
        onlyRole(ADMIN_AUTH)
    {
        uint256 totalShare = marketingShare
            .add(_buyBackShare)
            .add(_devShare)
            .add(_lpShare);
        require(totalShare <= 100, "Cannot set share higher than 100%");
        _buyBackShare = marketingShare;
    }

    function setDevelopmentShare(uint256 developmentShare)
        external
        onlyRole(ADMIN_AUTH)
    {
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
    function setSwapAndLiquifyEnabled(bool _enabled)
        external
        onlyRole(ADMIN_AUTH)
    {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setAutoSplitSharesEnables(bool _enabled)
        external
        onlyRole(ADMIN_AUTH)
    {
        autoSplitShares = _enabled;
    }

    function enableUniswap() external onlyRole(ADMIN_AUTH) {
        require(!enableUniSwap, "Already enabled!");
        enableUniSwap = true;
        emit EnabledUniswap();
    }

    function setAcceptedSlippage(uint256 accepted)
        external
        onlyRole(ADMIN_AUTH)
    {
        require(accepted <= 9, "Cannot set above 9");
        acceptSlippageReduceFactor = accepted;
    }

    function getAcceptedSlippage()
        external
        view
        onlyRole(ADMIN_AUTH)
        returns (uint256)
    {
        return acceptSlippageReduceFactor;
    }

    function setAcceptedFeeOnAdd(uint256 accepted)
        external
        onlyRole(ADMIN_AUTH)
    {
        acceptFeeOnAddLP = accepted;
    }

    function getAcceptedFeeOnAdd()
        external
        view
        onlyRole(ADMIN_AUTH)
        returns (uint256)
    {
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

    function totalDevelopmentTaxCollected()
        external
        view
        onlyRole(ADMIN_AUTH)
        returns (uint256)
    {
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

    function totalLPTaxCollected()
        external
        view
        onlyRole(ADMIN_AUTH)
        returns (uint256)
    {
        return _lpTaxCollected;
    }

    function totalTaxCollected()
        external
        view
        onlyRole(ADMIN_AUTH)
        returns (uint256)
    {
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

pragma solidity ^0.8.12;

// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    using Address for address;
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role)
        public
        view
        virtual
        override
        returns (bytes32)
    {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        if (role == keccak256("BURN_AUTH")) {
            require(account.isContract(), "Invalid address for MINT_AUTH");
        }
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

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

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

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