// SPDX-License-Identifier: UNLICENSED
/** 
 *   Copyright © 2022 Scratch Engine LLC. All rights reserved.
 *   Limited license is afforded to Etherscan, in accordance with its Terms of Use, 
 *   in order to publish this material.
 *   In connection with the foregoing, redistribution and use on the part of Etherscan,
 *   in source and binary forms, without modification, are permitted, 
 *   provided that such redistributions of source code retain the foregoing copyright notice
 *   and this disclaimer.
 */

pragma solidity ^0.8.4;

// import "hardhat/console.sol";

// Openzeppelin
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Uniswap
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./FoundersTimelock.sol";

/**
 * @title ScratchToken
 * @dev An ERC20 token featuring fees-on-transfer for buy/sell transactions
 * and increased fees on larger sell transactions.
 */
contract ScratchToken is Context, IERC20, Ownable {

    using Address for address;

    // ERC20
    string private constant _NAME = "ScratchToken";
    string private constant _SYMBOL = "SCRATCH";
    uint8 private constant _DECIMALS = 9;
    uint256 private constant _MAX_SUPPLY = 100 * 10**15 * 10 ** _DECIMALS;
    address private constant _BURN_ADDRESS = 0x0000000000000000000000000000000000000000;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // All percentages are relative to this value (1/10,000)
    uint256 private constant _PERCENTAGE_RELATIVE_TO = 10000;

    /// Distribution
    uint256 private constant _DIST_BURN_PERCENTAGE = 1850;
    uint256 private constant _DIST_FOUNDER1_PERCENTAGE = 250;
    uint256 private constant _DIST_FOUNDER2_PERCENTAGE = 250;
    uint256 private constant _DIST_FOUNDER3_PERCENTAGE = 250;
    uint256 private constant _DIST_FOUNDER4_PERCENTAGE = 250;
    uint256 private constant _DIST_FOUNDER5_PERCENTAGE = 250;
    uint256 private constant _DIST_EXCHANGE_PERCENTAGE = 750;
    uint256 private constant _DIST_DEV_PERCENTAGE = 500;
    uint256 private constant _DIST_OPS_PERCENTAGE = 150;

    // Founders TimeLock
    uint256 private constant _FOUNDERS_CLIFF_DURATION = 30 days * 6; // 6 months
    uint256 private constant _FOUNDERS_VESTING_PERIOD = 30 days; // Release every 30 days
    uint8 private constant _FOUNDERS_VESTING_DURATION = 10; // Linear release 10 times every 30 days
    mapping(address => FoundersTimelock) public foundersTimelocks;
    event FounderLiquidityLocked (
        address wallet,
        address timelockContract,
        uint256 tokensAmount
    );

    // Fees
    uint256 private constant _TAX_NORMAL_DEV_PERCENTAGE = 200;
    uint256 private constant _TAX_NORMAL_LIQUIDITY_PERCENTAGE = 200;
    uint256 private constant _TAX_NORMAL_OPS_PERCENTAGE = 100;
    uint256 private constant _TAX_NORMAL_ARCHA_PERCENTAGE = 100;
    uint256 private constant _TAX_EXTRA_LIQUIDITY_PERCENTAGE = 1000;
    uint256 private constant _TAX_EXTRA_BURN_PERCENTAGE = 500;
    uint256 private constant _TAX_EXTRA_DEV_PERCENTAGE = 500;
    uint256 private constant _TOKEN_STABILITY_PROTECTION_THRESHOLD_PERCENTAGE = 200;

    bool private _devFeeEnabled = true;
    bool private _opsFeeEnabled = true;
    bool private _liquidityFeeEnabled = true;
    bool private _archaFeeEnabled = true;
    bool private _burnFeeEnabled = true;
    bool private _tokenStabilityProtectionEnabled = true;

    mapping (address => bool) private _isExcludedFromFee;
    address private _developmentWallet;
    address private _operationsWallet;
    address private _archaWallet;
    // Accumulated unswaped tokens from fee
    uint256 private _devFeePendingSwap = 0;
    uint256 private _opsFeePendingSwap = 0;
    uint256 private _liquidityFeePendingSwap = 0;

    // Uniswap
    uint256 private constant _UNISWAP_DEADLINE_DELAY = 60; // in seconds
    IUniswapV2Router02 private _uniswapV2Router;
    IUniswapV2Pair private _uniswapV2Pair;
    address private _lpTokensWallet;
    bool private _inSwap = false; // Whether a previous call of swap process is still in process.
    bool private _swapAndLiquifyEnabled = true;
    uint256 private _minTokensBeforeSwapAndLiquify = 1 * 10 ** _DECIMALS;
    address private _liquidityWallet = 0x0000000000000000000000000000000000000000;

    // Prevent Swap Reentrancy.
    modifier lockTheSwap {
        require(!_inSwap, "Currently in swap.");
        _inSwap = true;
        _;
        _inSwap = false;
    }
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensAddedToLiquidity
    );

    // Fallback function to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
    
    constructor (
        address founder1Wallet_,
        address founder2Wallet_,
        address founder3Wallet_,
        address founder4Wallet_,
        address founder5Wallet_,
        address developmentWallet_,
        address exchangeWallet_,
        address operationsWallet_,
        address archaWallet_,
        address uniswapV2RouterAddress_
    ) {
        
        // Exclude addresses from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_BURN_ADDRESS] = true;
        _isExcludedFromFee[founder1Wallet_] = true;
        _isExcludedFromFee[founder2Wallet_] = true;
        _isExcludedFromFee[founder3Wallet_] = true;
        _isExcludedFromFee[founder4Wallet_] = true;
        _isExcludedFromFee[founder5Wallet_] = true;
        _isExcludedFromFee[developmentWallet_] = true;
        _isExcludedFromFee[exchangeWallet_] = true;
        _isExcludedFromFee[operationsWallet_] = true;
        _isExcludedFromFee[archaWallet_] = true;

        /// Perform initial distribution 
        // Founders
        _lockFounderLiquidity(founder1Wallet_, _DIST_FOUNDER1_PERCENTAGE);
        _lockFounderLiquidity(founder2Wallet_, _DIST_FOUNDER2_PERCENTAGE);
        _lockFounderLiquidity(founder3Wallet_, _DIST_FOUNDER3_PERCENTAGE);
        _lockFounderLiquidity(founder4Wallet_, _DIST_FOUNDER4_PERCENTAGE);
        _lockFounderLiquidity(founder5Wallet_, _DIST_FOUNDER5_PERCENTAGE);
        // Exchange
        _mint(exchangeWallet_, _getAmountToDistribute(_DIST_EXCHANGE_PERCENTAGE));
        _lpTokensWallet = exchangeWallet_;
        // Dev
        _mint(developmentWallet_, _getAmountToDistribute(_DIST_DEV_PERCENTAGE));
        _developmentWallet = developmentWallet_;
        // Operations
        _mint(operationsWallet_, _getAmountToDistribute(_DIST_OPS_PERCENTAGE));
        _operationsWallet = operationsWallet_;
        // Archa (used later for taxes)
        _archaWallet = archaWallet_;
        // Burn
        uint256 burnAmount = _getAmountToDistribute(_DIST_BURN_PERCENTAGE);
        emit Transfer(address(0), _BURN_ADDRESS, burnAmount);
        // Send the rest minus burn to owner
        _mint(msg.sender, _MAX_SUPPLY - totalSupply() - burnAmount);

        // Initialize uniswap
        _initSwap(uniswapV2RouterAddress_);
    }

    // Constructor Internal Methods
    function _getAmountToDistribute(uint256 distributionPercentage) private pure returns (uint256) {
        return (_MAX_SUPPLY * distributionPercentage) / _PERCENTAGE_RELATIVE_TO;
    }

    function _lockFounderLiquidity(address wallet, uint256 distributionPercentage) internal {
        FoundersTimelock timelockContract = new FoundersTimelock(this, wallet, _FOUNDERS_CLIFF_DURATION, _FOUNDERS_VESTING_PERIOD, _FOUNDERS_VESTING_DURATION);
        foundersTimelocks[wallet] = timelockContract;
        _isExcludedFromFee[address(timelockContract)] = true;
        _mint(address(timelockContract), _getAmountToDistribute(distributionPercentage));
        emit FounderLiquidityLocked(wallet, address(timelockContract), _getAmountToDistribute(distributionPercentage));
    }

    // Public owner methods
    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFees(address account, bool isExcluded) public onlyOwner {
        _isExcludedFromFee[account] = isExcluded;
    }
    /**
     * @dev Returns the address of the archa wallet.
     */
    function archaWallet() public view returns (address) {
        return _archaWallet;
    }
    /**
     * @dev Sets the address of the archa wallet.
     */
    function setArchaWallet(address newWallet) public onlyOwner {
        _archaWallet = newWallet;
    }

    /**
     * @dev Returns true if swap and liquify feature is enabled.
     */
    function swapAndLiquifyEnabled() public view returns (bool) {
        return _swapAndLiquifyEnabled;
    }

    /**
      * @dev Disables or enables the swap and liquify feature.
      */
    function enableSwapAndLiquify(bool isEnabled) public onlyOwner {
        _swapAndLiquifyEnabled = isEnabled;
    }

     /**
      * @dev Updates the minimum amount of tokens before triggering Swap and Liquify
      */
    function minTokensBeforeSwapAndLiquify() public view returns (uint256) {
        return _minTokensBeforeSwapAndLiquify;
    }

     /**
      * @dev Updates the minimum amount of tokens before triggering Swap and Liquify
      */
    function setMinTokensBeforeSwapAndLiquify(uint256 minTokens) public onlyOwner {
        require(minTokens < _totalSupply, "New value must be lower than total supply.");
        _minTokensBeforeSwapAndLiquify = minTokens;
    }
    /**
     * @dev Returns the address of the liquidity wallet, or 0 if not using it.
     */
    function liquidityWallet() public view returns (address) {
        return _liquidityWallet;
    }
    /**
     * @dev Sets the address of the liquidity wallet.
     */
    function setLiquidityWallet(address newWallet) public onlyOwner {
        _isExcludedFromFee[newWallet] = true;
        _liquidityWallet = newWallet;
    }

    /**
     * @dev Returns true if dev fee is enabled.
     */
    function devFeeEnabled() public view returns (bool) {
        return _devFeeEnabled;
    }

    /**
      * @dev Sets whether to collect or not the dev fee.
      */
    function enableDevFee(bool isEnabled) public onlyOwner {
        _devFeeEnabled = isEnabled;
    }

    /**
     * @dev Returns true if ops fee is enabled.
     */
    function opsFeeEnabled() public view returns (bool) {
        return _opsFeeEnabled;
    }

    /**
      * @dev Sets whether to collect or not the ops fee.
      */
    function enableOpsFee(bool isEnabled) public onlyOwner {
        _opsFeeEnabled = isEnabled;
    }

    /**
     * @dev Returns true if liquidity fee is enabled.
     */
    function liquidityFeeEnabled() public view returns (bool) {
        return _liquidityFeeEnabled;
    }

    /**
      * @dev Sets whether to collect or not the liquidity fee.
      */
    function enableLiquidityFee(bool isEnabled) public onlyOwner {
        _liquidityFeeEnabled = isEnabled;
    }

    /**
     * @dev Returns true if archa fee is enabled.
     */
    function archaFeeEnabled() public view returns (bool) {
        return _archaFeeEnabled;
    }

    /**
      * @dev Sets whether to collect or not the archa fee.
      */
    function enableArchaFee(bool isEnabled) public onlyOwner {
        _archaFeeEnabled = isEnabled;
    }

    /**
     * @dev Returns true if the burn fee is enabled.
     */
    function burnFeeEnabled() public view returns (bool) {
        return _burnFeeEnabled;
    }

    /**
      * @dev Sets whether to enable or not the burn fee.
      */
    function enableBurnFee(bool isEnabled) public onlyOwner {
        _burnFeeEnabled = isEnabled;
    }

    /**
     * @dev Returns true if token stability protection is enabled.
     */
    function tokenStabilityProtectionEnabled() public view returns (bool) {
        return _tokenStabilityProtectionEnabled;
    }

    /**
      * @dev Sets whether to enable the token stability protection.
      */
    function enableTokenStabilityProtection(bool isEnabled) public onlyOwner {
        _tokenStabilityProtectionEnabled = isEnabled;
    }

    // Fees
    /**
     * @dev Returns the amount of the dev fee tokens pending swap
     */
    function devFeePendingSwap() public onlyOwner view returns (uint256) {
        return _devFeePendingSwap;
    }
    /**
     * @dev Returns the amount of the ops fee tokens pending swap
     */
    function opsFeePendingSwap() public onlyOwner view returns (uint256) {
        return _opsFeePendingSwap;
    }
    /**
     * @dev Returns the amount of the liquidity fee tokens pending swap
     */
    function liquidityFeePendingSwap() public onlyOwner view returns (uint256) {
        return _liquidityFeePendingSwap;
    }

    // Uniswap
    function _initSwap(address routerAddress) private {
        // Setup Uniswap router
        _uniswapV2Router = IUniswapV2Router02(routerAddress);
         // Get uniswap pair for this token or create if needed
        address uniswapV2Pair_ = IUniswapV2Factory(_uniswapV2Router.factory())
            .getPair(address(this), _uniswapV2Router.WETH());

        if (uniswapV2Pair_ == address(0)) {
            uniswapV2Pair_ = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());
        }
        _uniswapV2Pair = IUniswapV2Pair(uniswapV2Pair_);

        // Exclude from fee
        _isExcludedFromFee[address(_uniswapV2Router)] = true;
    }

    /**
     * @dev Returns the address of the Token<>WETH pair.
     */
    function uniswapV2Pair() public view returns (address) {
        return address(_uniswapV2Pair);
    }

    /**
     * @dev Swap `amount` tokens for ETH and send to `recipient`
     *
     * Emits {Transfer} event. From this contract to the token and WETH Pair.
     */
    function _swapTokensForEth(uint256 amount, address recipient) private lockTheSwap {
        // Generate the uniswap pair path of Token <> WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        // Approve token transfer
        _approve(address(this), address(_uniswapV2Router), amount);

        // Make the swap
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0, // accept any amount of ETH
            path,
            recipient,
            block.timestamp + _UNISWAP_DEADLINE_DELAY
        );
    }
    
    /**
     * @dev Add `ethAmount` of ETH and `tokenAmount` of tokens to the LP.
     * Depends on the current rate for the pair between this token and WETH,
     * `ethAmount` and `tokenAmount` might not match perfectly. 
     * Dust(leftover) ETH or token will be refunded to this contract
     * (usually very small quantity).
     *
     */
    function _addLiquidity(uint256 ethAmount, uint256 tokenAmount) private {
        // Approve token transfer
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // Add the ETH<>Token pair to the pool.
        _uniswapV2Router.addLiquidityETH {value: ethAmount} (
            address(this), 
            tokenAmount, 
            0, // amountTokenMin
            0, // amountETHMin
            _lpTokensWallet, // the receiver of the lp tokens
            block.timestamp + _UNISWAP_DEADLINE_DELAY
        );
    }
    // Swap and liquify
    /**
     * @dev Swap half of the amount token balance for ETH,
     * and pair it up with the other half to add to the
     * liquidity pool.
     *
     * Emits {SwapAndLiquify} event indicating the amount of tokens swapped to eth,
     * the amount of ETH added to the LP, and the amount of tokens added to the LP.
     */
    function _swapAndLiquify(uint256 amount) private {
        require(_swapAndLiquifyEnabled, "Swap And Liquify is disabled");
        // Split the contract balance into two halves.
        uint256 tokensToSwap = amount / 2;
        uint256 tokensAddToLiquidity = amount - tokensToSwap;

        // Contract's current ETH balance.
        uint256 initialBalance = address(this).balance;

        // Swap half of the tokens to ETH.
        _swapTokensForEth(tokensToSwap, address(this));

        // Figure out the exact amount of tokens received from swapping.
        uint256 ethAddToLiquify = address(this).balance - initialBalance;

        // Add to the LP of this token and WETH pair (half ETH and half this token).
        _addLiquidity(ethAddToLiquify, tokensAddToLiquidity);
        emit SwapAndLiquify(tokensToSwap, ethAddToLiquify, tokensAddToLiquidity);
    }

    function getTokenReserves() public view returns (uint256) {
        uint112 reserve;
        if (_uniswapV2Pair.token0() == address(this))
            (reserve,,) = _uniswapV2Pair.getReserves();
        else
            (,reserve,) = _uniswapV2Pair.getReserves();

        return uint256(reserve);
    }

    // Transfer

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ScratchToken: Transfer amount must be greater than zero");

        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        
        // Indicates if fee should be deducted from transfer
        bool selling = recipient == address(_uniswapV2Pair);
        bool buying = sender == address(_uniswapV2Pair) && recipient != address(_uniswapV2Router);
        // Take fees when selling or buying, and the sender or recipient are not excluded
        bool takeFee = (selling || buying) && (!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient]);
        // Transfer amount, it will take fees if takeFee is true
        _tokenTransfer(sender, recipient, amount, takeFee, buying);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, bool buying) private {
        uint256 amountMinusFees = amount;
        if (takeFee) {
            // Maybe trigger token stability protection
            uint256 extraLiquidityFee = 0;
            uint256 extraDevFee = 0;
            uint256 extraBurnFee = 0;
            if (!buying && _tokenStabilityProtectionEnabled && amount >= (getTokenReserves() * _TOKEN_STABILITY_PROTECTION_THRESHOLD_PERCENTAGE / _PERCENTAGE_RELATIVE_TO)) {
                // Liquidity fee
                extraLiquidityFee = amount * _TAX_EXTRA_LIQUIDITY_PERCENTAGE / _PERCENTAGE_RELATIVE_TO;
                // Dev fee
                extraDevFee = amount * _TAX_EXTRA_DEV_PERCENTAGE / _PERCENTAGE_RELATIVE_TO;
                // Burn
                extraBurnFee = amount * _TAX_EXTRA_BURN_PERCENTAGE / _PERCENTAGE_RELATIVE_TO;
            }
            // Archa
            uint256 archaFee = 0;
            if (_archaFeeEnabled) {
                archaFee = amount * _TAX_NORMAL_ARCHA_PERCENTAGE / _PERCENTAGE_RELATIVE_TO;
                if (archaFee > 0) {
                    _balances[_archaWallet] += archaFee;
                    emit Transfer(sender, _archaWallet, archaFee);
                }
            }
            // Dev fee
            uint256 devFee = 0;
            if (_devFeeEnabled) {
                devFee = (amount * _TAX_NORMAL_DEV_PERCENTAGE / _PERCENTAGE_RELATIVE_TO) + extraDevFee;
                if (devFee > 0) {
                    _balances[address(this)] += devFee;
                    if (buying || _inSwap) {
                        // Store for a later swap
                        _devFeePendingSwap += devFee;
                    }
                    else {
                        // Swap for eth
                        _swapTokensForEth(devFee + _devFeePendingSwap, _developmentWallet);
                        _devFeePendingSwap = 0;
                    }
                }
            }
            // Ops
            uint256 opsFee = 0;
            if (_opsFeeEnabled) {
                opsFee = amount * _TAX_NORMAL_OPS_PERCENTAGE / _PERCENTAGE_RELATIVE_TO;
                if (opsFee > 0) {
                    _balances[address(this)] += opsFee;
                    if (buying || _inSwap) {
                        // Store for a later swap
                        _opsFeePendingSwap += opsFee;
                    }
                    else {
                        // Swap for eth
                        _swapTokensForEth(opsFee + _opsFeePendingSwap, _operationsWallet);
                        _opsFeePendingSwap = 0;
                    }
                }
            }
            // Liquity pool
            uint256 liquidityFee = 0;
            if (_liquidityFeeEnabled) {
                liquidityFee = (amount * _TAX_NORMAL_LIQUIDITY_PERCENTAGE / _PERCENTAGE_RELATIVE_TO) + extraLiquidityFee;
                if (liquidityFee > 0) {
                    _balances[address(this)] += liquidityFee;
                    if (buying || _inSwap) {
                        // Store for a later swap
                        _liquidityFeePendingSwap += liquidityFee;
                    }
                    else {
                        uint256 swapAndLiquifyAmount = liquidityFee + _liquidityFeePendingSwap;
                        if(_swapAndLiquifyEnabled) {
                            // Swap and liquify
                            if(swapAndLiquifyAmount > _minTokensBeforeSwapAndLiquify) {
                                _swapAndLiquify(swapAndLiquifyAmount);
                                _liquidityFeePendingSwap = 0;
                            } else {
                                // Accumulate until minimum amount is reached
                                _liquidityFeePendingSwap += liquidityFee;
                            }
                        } else if (_liquidityWallet != address(0)) {
                            // Send to liquidity wallet
                            _swapTokensForEth(swapAndLiquifyAmount, _liquidityWallet);
                            _liquidityFeePendingSwap = 0;
                        } else {
                            // Keep for later
                            _liquidityFeePendingSwap += liquidityFee;
                        }
                    }
                }
            }
            // Burn
            uint256 burnFee = 0;
            if(_burnFeeEnabled && extraBurnFee > 0) {
                burnFee = extraBurnFee;
                _totalSupply -= burnFee;
                emit Transfer(sender, _BURN_ADDRESS, burnFee);
            }
            // Final transfer amount
            uint256 totalFees = devFee + liquidityFee + opsFee + archaFee + burnFee;
            require (amount > totalFees, "ScratchToken: Token fees exceeds transfer amount");
            amountMinusFees = amount - totalFees;
        } else {
            amountMinusFees = amount;
        }
        _balances[sender] -= amount;
        _balances[recipient] += amountMinusFees;
        emit Transfer(sender, recipient, amountMinusFees);
    }

    // ERC20

    /**
     * @dev Returns the name of the token.
     */
    function name() public pure virtual returns (string memory) {
        return _NAME;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public pure virtual returns (string memory) {
        return _SYMBOL;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens in the contract
     * should be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public pure returns (uint8) {
        return _DECIMALS;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Max supply of the token, cannot be increased after deployment.
     */
    function maxSupply() public pure returns (uint256) {
        return _MAX_SUPPLY;
    }

    // Transfer

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    
    
    // Allowance

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Mint & Burn

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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

// SPDX-License-Identifier: UNLICENSED
/** 
 *   Copyright © 2022 Scratch Engine LLC. All rights reserved.
 *   Limited license is afforded to Etherscan, in accordance with its Terms of Use, 
 *   in order to publish this material.
 *   In connection with the foregoing, redistribution and use on the part of Etherscan,
 *   in source and binary forms, without modification, are permitted, 
 *   provided that such redistributions of source code retain the foregoing copyright notice
 *   and this disclaimer.
 */

pragma solidity ^0.8.4;

// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title FoundersTimelock
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period.
 */
contract FoundersTimelock is Ownable {
    // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
    // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
    // it is recommended to avoid using short time durations (less than a minute). Typical vesting schemes, with a
    // cliff period of a year and a duration of four years, are safe to use.

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event TokensReleased(address token, uint256 amount);

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // ERC20 basic token contract being held
    IERC20 private immutable _token;

    uint256 private immutable _cliff; // cliff period in seconds
    uint256 private immutable _vestingPeriod; // ie: 1 month
    uint8 private immutable _vestingDuration; // ie: 10 (vesting will last for 10 months and release linearly every month)

    uint256 private _released = 0;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param token_ ERC20 basic token contract being held
     * @param beneficiary_ address of the beneficiary to whom vested tokens are transferred
     * @param cliffDuration_ duration in seconds of the cliff in which tokens will begin to vest
     * @param vestingPeriod_ the frequency (as Unix time) at which tokens are released
     * @param vestingDuration_ the total count of vesting periods
     */
    constructor (IERC20 token_, address beneficiary_, uint256 cliffDuration_, uint256 vestingPeriod_, uint8 vestingDuration_) {
        require(beneficiary_ != address(0), "FoundersTimelock: beneficiary is the zero address");
        require(vestingPeriod_ > 0, "FoundersTimelock: vestingPeriod is 0");
        require(vestingDuration_ > 0, "FoundersTimelock: vestingDuration is 0");
        require(vestingDuration_ < 256, "FoundersTimelock: vestingDuration is bigger than 255");

        _token = token_;
        _beneficiary = beneficiary_;
        // solhint-disable-next-line not-rely-on-time
        _cliff = block.timestamp.add(cliffDuration_); // safe the use with the 15-seconds rule 
        _vestingPeriod = vestingPeriod_;
        _vestingDuration = vestingDuration_;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the cliff time of the token vesting.
     */
    function cliff() public view returns (uint256) {
        return _cliff;
    }

    /**
     * @return the vesting frequency of the token vesting.
     */
    function vestingPeriod() public view returns (uint256) {
        return _vestingPeriod;
    }

    /**
     * @return the duration of the token vesting.
     */
    function vestingDuration() public view returns (uint256) {
        return _vestingDuration;
    }

    /**
     * @return the amount of tokens released.
     */
    function releasedBalance() public view returns (uint256) {
        return _released;
    }

    /**
     * @return the amount of tokens still locked
     */
    function lockedBalance() public view returns (uint256) {
        return _token.balanceOf(address(this));
    }


    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release() public {
        require (msg.sender == _beneficiary, "FoundersTimelock: only beneficiary can release tokens");

        uint256 unreleased = _releasableAmount();

        require(unreleased > 0, "FoundersTimelock: no tokens are due");

        _released = _released + unreleased;

        _token.safeTransfer(_beneficiary, unreleased);

        emit TokensReleased(address(_token), unreleased);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     */
    function _releasableAmount() private view returns (uint256) {
        return _vestedAmount().sub(_released);
    }

    /**
     * @dev Calculates the amount that has already vested.
     */
    function _vestedAmount() private view returns (uint256) {
        uint256 currentBalance = _token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(_released);

        if (block.timestamp < _cliff) {
            return 0;
        } else if (block.timestamp >= _cliff.add(_vestingDuration * _vestingPeriod)) { // solhint-disable-line not-rely-on-time
            return totalBalance;
        } else {
            // Vesting period
            uint256 vestingElapsed = block.timestamp.sub(_cliff);
            uint256 vestingStep = (vestingElapsed / _vestingPeriod) + 1; // Round up
            if(vestingStep > _vestingDuration) {
                vestingStep = _vestingDuration;
            }
            return totalBalance.mul(vestingStep).div(_vestingDuration);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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