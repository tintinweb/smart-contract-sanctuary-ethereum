/**
 *
 * @title BSKR - Brings Serenity, Knowledge and Richness
 * @author Ra Murd <[email protected]>
 * @notice website: https://pulselorian.com/
 * @notice telegram: https://t.me/ThePulselorian
 * @notice twitter: https://twitter.com/ThePulseLorian
 *
 * BSKR is our attempt to develop a better internet currency
 * It's deflationary, burns some fees, reflects some fees and adds some fees to liquidity pool
 * It may also pay quarterly bonus to net buyers
 *
 * - BSKR audit
 *      <TODO Audit report link to be added here>
 *
 *
 *    (   (  (  (     (   (( (   .  (   (    (( (   ((
 *    )\  )\ )\ )\    )\ (\())\   . )\  )\   ))\)\  ))\
 *   ((_)((_)(_)(_)  ((_))(_)(_)   ((_)((_)(((_)_()((_)))
 *   | _ \ | | | |  / __| __| |   / _ \| _ \_ _|   \ \| |
 *   |  _/ |_| | |__\__ \ _|| |__| (_) |   /| || - | .  |
 *   |_|  \___/|____|___/___|____|\___/|_|_\___|_|_|_|\_|
 *
 * Tokenomics:
 *
 * Reflection       2.0%      36.36%
 * Burn             1.5%      27.27%
 * Growth           1.0%      18.18%
 * Liquidity        0.5%       9.09%
 * Payday           0.5%       9.09%
 */

/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.17;

import "./imports/BaseBSKR.sol";

// Uniswap V2 addresses in play
// UniswapV2Pair: dynamic, created on demand for a pair
// UniswapV2Router02: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
// UniswapV2Factory: 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
// WETH: 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6

// Uniswap V3 addresses in play
// UniswapV3Pool: dynamic, created on demand for a pair and fee
// SwapRouter: 0xE592427A0AEce92De3Edee1F18E0157C05861564
// UniswapV3Factory: 0x1F98431c8aD98523631AE4a59f267346ea31F984
// WETH9: 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6

// SwapRouter02: 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
// NonfungiblePositionManager: 0xC36442b4a4522E871399CD717aBDD847Ab11FE88

// TODO - these are important checks
//  need to set all access correctly - manage access control is broken
//  verify that all the functions that should have reentrancy check
//  update all the require messages with contract name
//  optimize gas usage on remix and also resolve linter identified issues
//  all public function - check if they can be made external - public function are more costlier on gas but external function cannot be used internally
//  add whenNotPaused to all the applicable functions
//  add functionality to remove liquidity from sisterOA - currently failing
//  review private, internal, public, external, constant modifiers
//  review naming conventions, function args have A suffix, constants are capital, private start with _, ...
//  make all variabes private
contract BSKR is BaseBSKR {
    enum Field {
        tTransferAmount,
        rAmount,
        rTransferAmount,
        tRfiFee,
        tBurnFee,
        tGrowthFee,
        tPaydayFee,
        tLPFee,
        rRfiFee,
        rBurnFee,
        rGrowthFee,
        rPaydayFee,
        rLPFee
    }

    enum Fees {
        RfiFee, // 200 or 2.0%
        BurnFee, // 150 or 1.5%
        GrowthFee, // 100 or 1.0%
        PaydayFee, // 50 or 0.5%
        LPFee, // 50 or 0.5%
        GrossFees // 550 or 5.5%
    }
    address private immutable _paydayAddress; // 0x13D44474B125B5582A42a826035A99e38a4962A7
    address private _LBSKRAddr;

    address[] private _noRfi;

    bool private _addingLiquidity;
    bool private _addLPEnabled = true;
    mapping(address => bool) private _getsNoRfi;
    mapping(address => bool) private _isMyTokensPair;
    mapping(address => uint256) private _rBalances;
    uint256[6] private _currFees = [200, 150, 100, 50, 50, 550];
    uint256 private _rTotal = (type(uint256).max -
        (type(uint256).max % _TOTAL_SUPPLY));
    uint256 private _tRfiFeesSum;
    uint256 private _numTokensForLP = _TOTAL_SUPPLY / 1000; // 0.1% of the total supply
    uint256 private _maxTxAmount = _TOTAL_SUPPLY / 25; // 4% of the total supply

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event AddLPEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier swapInProgress() {
        _addingLiquidity = true;
        _;
        _addingLiquidity = false;
    }

    modifier onlyLBSKR() {
        require(msg.sender == _LBSKRAddr);
        _;
    }

    constructor(
        string memory nameA,
        string memory symbolA,
        address growthAddressA,
        address paydayAddressA,
        address lbskrAddrA,
        address[] memory sisterOAsA
    ) BaseBSKR(nameA, symbolA, growthAddressA, sisterOAsA) {
        _paydayAddress = paydayAddressA;
        _LBSKRAddr = lbskrAddrA;

        // TODO pre-distribute all allocations as per tokenomics
        _rBalances[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _TOTAL_SUPPLY);

        _ammBSKRPair = _dexFactoryV2.createPair(
            address(this),
            _dexRouterV2.WETH()
        );
        _approve(_ammBSKRPair, _ammBSKRPair, type(uint256).max);
        _isAMMPair[_ammBSKRPair] = true;
        _setNoRfi(_ammBSKRPair);

        address _ammLBSKRPair = _dexFactoryV2.createPair(
            address(this),
            _LBSKRAddr
        );
        _approve(_ammLBSKRPair, _ammLBSKRPair, type(uint256).max); // TODO LBSKR contract may also need to do this?
        _isAMMPair[_ammLBSKRPair] = true;
        _setNoRfi(_ammLBSKRPair);

        for (uint8 i = 0; i < _sisterOAs.length; i++) {
            _paysNoFee[_sisterOAs[i]] = true;
            _setNoRfi(_sisterOAs[i]);
        }

        _setNoRfi(_paydayAddress);
        _setNoRfi(_ammBSKRPair);
        _setNoRfi(_ammLBSKRPair);
        _setNoRfi(address(0));

        // routers do not hold balances - but could be in transition
        // TODO may be enable the following
        // _setNoRfi(_DEXV2_ROUTER_ADDR);
        // _setNoRfi(_DEXV3_ROUTER_ADDR);
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_dexRouterV2), tokenAmount);

        // add the liquidity
        _dexRouterV2.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _getOriginAddress(),
            // owner(),
            block.timestamp + 15
        );

        // Prevent ETH dust from getting locked in the contract forever
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * Airdrop BSKR to sacrificers, deducted from owner's wallet
     */
    function _airdropTransfer(address account, uint256 amount) private {
        _transferTokens(owner(), account, amount, false, true, true);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _TOTAL_SUPPLY;
        for (uint256 i = 0; i < _noRfi.length; i++) {
            if (
                _rBalances[_noRfi[i]] > rSupply ||
                _balances[_noRfi[i]] > tSupply
            ) return (_rTotal, _TOTAL_SUPPLY);
            rSupply -= _rBalances[_noRfi[i]];
            tSupply -= _balances[_noRfi[i]];
        }
        if (rSupply < _rTotal / _TOTAL_SUPPLY) return (_rTotal, _TOTAL_SUPPLY);
        return (rSupply, tSupply);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getValues(uint256 tAmount, uint8 feeMultiplier)
        private
        view
        returns (uint256[] memory)
    {
        uint256[] memory response = new uint256[](13);

        uint256 currentRate = _getRate();
        response[uint8(Field.rAmount)] = (tAmount * currentRate);

        if (feeMultiplier == 0) {
            response[uint8(Field.tRfiFee)] = 0;
            response[uint8(Field.tBurnFee)] = 0;
            response[uint8(Field.tGrowthFee)] = 0;
            response[uint8(Field.tPaydayFee)] = 0;
            response[uint8(Field.tLPFee)] = 0;
            response[uint8(Field.tTransferAmount)] = tAmount;

            response[uint8(Field.rRfiFee)] = 0;
            response[uint8(Field.rBurnFee)] = 0;
            response[uint8(Field.rGrowthFee)] = 0;
            response[uint8(Field.rPaydayFee)] = 0;
            response[uint8(Field.rLPFee)] = 0;
            response[uint8(Field.rTransferAmount)] = tAmount * currentRate;
        } else {
            response[uint8(Field.tRfiFee)] =
                (((tAmount * _currFees[uint8(Fees.RfiFee)]) / _BIPS) *
                    feeMultiplier) /
                10;
            response[uint8(Field.tBurnFee)] =
                (((tAmount * _currFees[uint8(Fees.BurnFee)]) / _BIPS) *
                    feeMultiplier) /
                10;
            response[uint8(Field.tGrowthFee)] =
                (((tAmount * _currFees[uint8(Fees.GrowthFee)]) / _BIPS) *
                    feeMultiplier) /
                10;
            response[uint8(Field.tPaydayFee)] =
                (((tAmount * _currFees[uint8(Fees.PaydayFee)]) / _BIPS) *
                    feeMultiplier) /
                10;
            response[uint8(Field.tLPFee)] =
                (((tAmount * _currFees[uint8(Fees.LPFee)]) / _BIPS) *
                    feeMultiplier) /
                10;
            response[uint8(Field.tTransferAmount)] =
                tAmount -
                ((((tAmount * _currFees[uint8(Fees.GrossFees)]) / _BIPS) *
                    feeMultiplier) / 10);

            response[uint8(Field.rRfiFee)] = (response[uint8(Field.tRfiFee)] *
                currentRate);
            response[uint8(Field.rBurnFee)] = (response[uint8(Field.tBurnFee)] *
                currentRate);
            response[uint8(Field.rGrowthFee)] = (response[
                uint8(Field.tGrowthFee)
            ] * currentRate);
            response[uint8(Field.rPaydayFee)] = (response[
                uint8(Field.tPaydayFee)
            ] * currentRate);
            response[uint8(Field.rLPFee)] = (response[uint8(Field.tLPFee)] *
                currentRate);
            response[uint8(Field.rTransferAmount)] = (response[
                uint8(Field.tTransferAmount)
            ] * currentRate);
        }

        return (response);
    }

    function _isLBSKRPair(address target) internal returns (bool) {
        if (!_isAMMPair[target]) {
            return false;
        }
        if (_isMyTokensPair[target]) {
            return true;
        }
        address token0 = _getToken0(target);
        if (token0 == _LBSKRAddr) {
            _isMyTokensPair[target] = true;
            return true;
        }

        address token1 = _getToken1(target);
        if (token1 == _LBSKRAddr) {
            _isMyTokensPair[target] = true;
            return false;
        }

        return false;
    }

    // function _isBSKRLBSKRV3Pool(address target) private view returns (bool) {
    //     //if (target == _ammBSKRPair || target == _ammLBSKRPair) return false; // TODO this hasn't worked yet

    //     address token0 = address(this);
    //     address token1 = _LBSKRAddr;

    //     // int24 targetTickSpacing = _callAndParseInt24Return(
    //     //     target,
    //     //     hex"d0c93a7c"
    //     // );
    //     // emit Log02B(targetTickSpacing);

    //     // if (targetTickSpacing == 0) {
    //     //     return false;
    //     // }

    //     IUniswapV3Pool poolContract = IUniswapV3Pool(target);

    //     uint24 fee;

    //     if (_LBSKRAddr < address(this)) {
    //         token0 = _LBSKRAddr;
    //         token1 = address(this);
    //     }

    //     try poolContract.fee() returns (uint24 _fee) {
    //         fee = _fee;
    //     } catch (bytes memory) {
    //         return false;
    //     }

    //     return target == _dexFactoryV3.getPool(token0, token1, fee);
    // }

    function _reflectFee(uint256 tFee, uint256 rFee) private {
        _rTotal -= rFee;
        _tRfiFeesSum += tFee;
    }

    function _setNoRfi(address account) private {
        if (!_getsNoRfi[account]) {
            _getsNoRfi[account] = true;
            _noRfi.push(account);
        }
    }

    function _swapAndLiquify(uint256 contractTokenBalance)
        private
        swapInProgress
    {
        // split the contract balance into halves
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        _swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;

        // add liquidity to uniswap
        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _dexRouterV2.WETH();

        // _dexFactoryV2.getPair(token0, token1)  // TODO may be we need to find the pair and approve as well
        _approve(address(this), address(_dexRouterV2), tokenAmount);

        // make the swap
        _dexRouterV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _takeFee(
        address target,
        uint256 tFee,
        uint256 rFee
    ) private {
        _rBalances[target] += rFee;
        if (_getsNoRfi[target]) _balances[target] += tFee;
    }

    /**
     * @notice Test function - converts reflection amount to actual reward value - TODO do we need this?
     */
    function _tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(rAmount <= _rTotal, "BSKR: Amount too large");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "BSKR: From Zero Address");
        require(to != address(0), "BSKR: To Zero Address");
        require(amount > 0, "BSKR: Zero transfer amount");

        if (from != owner() && to != owner()) {
            require(
                amount <= _maxTxAmount,
                "BSKR: Exceeds max transaction size"
            );
        }

        // emit LogB("About to call _checkIfAMMPair for from & to");
        _checkIfAMMPair(from);
        if (_isAMMPair[from]) {
            _setNoRfi(from);
        }
        _checkIfAMMPair(to);
        if (_isAMMPair[to]) {
            _setNoRfi(to);
        }
        // emit LogB("Called _checkIfAMMPair for both from & to");

        // // is the token balance of this contract address over the min number of
        // // tokens that we need to initiate a swap + liquidity lock?
        // // also, don't get caught in a circular liquidity event.
        // // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance > _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        if (
            (contractTokenBalance >= _numTokensForLP) &&
            !_addingLiquidity &&
            from != _ammBSKRPair && // we don't need to check for other amm pairs
            _addLPEnabled
        ) {
            _swapAndLiquify(_numTokensForLP); // Add liquidity
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _paysNoFee account then remove the fee
        if (_paysNoFee[from] || _paysNoFee[to]) {
            takeFee = false;
        }

        if (_isAMMPair[from] && !_isAMMPair[to]) {
            // Buy transaction
        } else if (!_isAMMPair[from] && _isAMMPair[to]) {
            // Sell transaction
        } else if (_isAMMPair[from] && _isAMMPair[to]) {
            // hop between LPs - potentially double taxes - but ok, discourage this
            // takeFee = false;
        } else {
            // simple transfer not buy/sell, take no fees
            takeFee = false;
        }

        // Works for uniswap v3
        // if (to == _NFPOSMAN_ADDR) {
        //     _approve(from, _NFPOSMAN_ADDR, amount); // Allow nfPosMan to spend from's tokens
        //     // revert("UniswapV3 is not supported!");
        // }

        //transfer amount, it will take tax, burn, liquidity fee
        _transferTokens(
            from,
            to,
            amount,
            takeFee,
            _getsNoRfi[from],
            _getsNoRfi[to]
        );
    }

    function _transferTokens(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool senderExcluded,
        bool recipientExcluded
    ) private {
        uint8 reducedFees = 10;

        if (!takeFee) {
            reducedFees = 0;
        } else if (_isLBSKRPair(sender) || _isLBSKRPair(recipient)) {
            reducedFees = 5;
        }

        uint256[] memory response = _getValues(tAmount, reducedFees);

        if (senderExcluded) {
            _balances[sender] -= tAmount;
        }
        _rBalances[sender] -= response[uint8(Field.rAmount)];

        if (recipientExcluded) {
            _balances[recipient] += response[uint8(Field.tTransferAmount)];
        }
        _rBalances[recipient] += response[uint8(Field.rTransferAmount)];

        if (response[uint8(Field.tRfiFee)] > 0) {
            _reflectFee(
                response[uint8(Field.tRfiFee)],
                response[uint8(Field.rRfiFee)]
            );
            // cannot emit transfer event
        }

        if (response[uint8(Field.tBurnFee)] > 0) {
            _takeFee(
                address(0),
                response[uint8(Field.tBurnFee)],
                response[uint8(Field.rBurnFee)]
            );
            emit Transfer(sender, address(0), response[uint8(Field.tBurnFee)]);
        }

        if (response[uint8(Field.tGrowthFee)] > 0) {
            _takeFee(
                _growthAddress,
                response[uint8(Field.tGrowthFee)],
                response[uint8(Field.rGrowthFee)]
            );
            emit Transfer(
                sender,
                _growthAddress,
                response[uint8(Field.tGrowthFee)]
            );
        }

        if (response[uint8(Field.tPaydayFee)] > 0) {
            _takeFee(
                _paydayAddress,
                response[uint8(Field.tPaydayFee)],
                response[uint8(Field.rPaydayFee)]
            );
            emit Transfer(
                sender,
                _paydayAddress,
                response[uint8(Field.tPaydayFee)]
            );
        }

        if (response[uint8(Field.tLPFee)] > 0) {
            _takeFee(
                address(this),
                response[uint8(Field.tLPFee)],
                response[uint8(Field.rLPFee)]
            );
            emit Transfer(sender, address(this), response[uint8(Field.tLPFee)]);
        }

        emit Transfer(
            sender,
            recipient,
            response[uint8(Field.tTransferAmount)]
        );
    }

    /**
     * Sets the uniswapV2 pair (router & factory) for swapping and liquifying tokens
     */
    // function addBSKRLPAddress(address bskrLPAddress) external onlyManager {
    //     // TODO validation and then add BSKR LP _LPpairs
    //     // TODO also create a function to remove LP pair - may be not needed
    //     // TODO add a getter
    // }

    /**
     * Calculates the account balance taking into account reflection received
     */
    function balanceOf(address account) public view override returns (uint256) {
        if (_getsNoRfi[account]) return _balances[account];
        return _tokenFromReflection(_rBalances[account]);
    }

    /**
     * @notice Excludes an account from reflection rewards - TODO do we need this?
     */
    // function excludeFromReward(address account) external onlyManager {
    //     require(!_getsNoRfi[account], "BSKR: Already excluded");
    //     if (_rBalances[account] > 0) {
    //         _balances[account] = tokenFromReflection(_rBalances[account]);
    //     }
    //     _setNoRfi(account);
    // }

    /**
     * @notice Returns the LBSKR contract address
     */
    function getLBSKRAddress() external view returns (address) {
        return _LBSKRAddr;
    }

    /**
     * @notice Gift reflection to the BSKR community
     */
    function giftReflection(uint256 tAmount) external {
        address sender = _msgSender();
        require(!_getsNoRfi[sender], "BSKR: Excluded account");
        uint256[] memory response = _getValues(tAmount, 10);
        _rBalances[sender] -= response[uint8(Field.rAmount)];
        _rTotal -= response[uint8(Field.rAmount)];
        _tRfiFeesSum += tAmount;
    }

    /**
     * @notice Makes an account responsible for fees --  TODO do we need this?
     */
    // function includeInFee(address account) external onlyManager {
    //     _paysNoFee[account] = false;
    // }

    /**
     * @notice Makes an account eligible for reflection rewards -- TODO do we need this?
     */
    // function includeInReward(address account) external onlyManager {
    //     require(_getsNoRfi[account], "BSKR: Already receives rewards");
    //     for (uint256 i = 0; i < _noRfi.length; i++) {
    //         if (_noRfi[i] == account) {
    //             _noRfi[i] = _noRfi[_noRfi.length - 1];
    //             _balances[account] = 0;
    //             _getsNoRfi[account] = false;
    //             _noRfi.pop();
    //             break;
    //         }
    //     }
    // }

    /**
     * @notice Checks if an account is excluded from reflection rewards -- TODO do we need this?
     */
    // function isExcludedFromReward(address account) external view returns (bool) {
    //     return _getsNoRfi[account];
    // }

    // /**
    //  * @notice Calculates reflection for a given amount -- TODO do we need this?
    //  */
    // function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
    //     external
    //     returns (
    //         view
    //         uint256
    //     )
    // {
    //     require(tAmount <= _TOTAL_SUPPLY, "BSKR: Amount too large");
    //     if (!deductTransferFee) {
    //         uint256[] memory response = _getValues(tAmount, 10);
    //         return response[uint8(Field.rAmount)];
    //     } else {
    //         uint256[] memory response = _getValues(tAmount, 10);
    //         return response[uint8(Field.rTransferAmount)];
    //     }
    // }

    /**
     * @notice Set the LBSKR contract address
     */
    function setLBSKRAddress(address newLBSKRAddrA) external onlyManager {
        _LBSKRAddr = newLBSKRAddrA;
        // _ammLBSKRPair = _dexFactoryV2.createPair(address(this), _LBSKRAddr);
        address _ammLBSKRPair = _dexFactoryV2.getPair(
            address(this),
            _LBSKRAddr
        );

        if (_ammLBSKRPair == address(0)) {
            _ammLBSKRPair = _dexFactoryV2.createPair(address(this), _LBSKRAddr);
        }

        if (_ammLBSKRPair != address(0)) {
            _approve(_ammLBSKRPair, _ammLBSKRPair, type(uint256).max);
            _isAMMPair[_ammLBSKRPair] = true;
        }
    }

    /**
     * Sets the uniswapV2 pair (router & factory) for swapping and liquifying tokens
     */
    // function setLBSKRLPAddress(address lbskrLPAddress) external onlyManager {
    //     // TODO validation and then set LBSKR LP _LBSKRPair
    //     // TODO add a getter
    // }

    /**
     * @notice Sets a new liquidity fee
     */
    // function setLPFeePercent(uint256 newLPBips) external onlyManager {
    //     // _lpFee = newLPBips;
    //     _currFees[uint8(Fees.LPFee)] = newLPBips;
    // }

    /**
     * @notice Sets a new max transaction limit
     */
    function setMaxTxPercent(uint256 maxTxBips) external onlyManager {
        _maxTxAmount = (_TOTAL_SUPPLY * maxTxBips) / _BIPS;
    }

    /**
     * @notice Sets a new reflection fee
     */
    // function setRfiFeePercent(uint256 newRfiBips) external onlyManager {
    //     // _rfiFee = newRfiBips;
    //     _currFees[uint8(Fees.RfiFee)] = newRfiBips;
    // }

    /**
     * @notice Enable or disable auto liquidity feature - for manager only in case of issues
     */
    function setSwapAndLiquifyEnabled(bool _enabled) external onlyManager {
        _addLPEnabled = _enabled;
        emit AddLPEnabledUpdated(_enabled);
    }

    /**
     * @notice Burns the penalty portion of stake while unstaking.
     * Only LBSKR contract may call this function
     */
    function stakeBurn(address from, uint256 amount)
        external
        onlyLBSKR
        returns (bool)
    {
        _transferTokens(
            from,
            address(0),
            amount,
            false,
            _getsNoRfi[from],
            _getsNoRfi[address(0)]
        );
        return true;
    }

    /**
     * @notice Transfer the unstaked token while unstaking.
     * Only LBSKR contract may call this function
     */
    function stakeTransfer(
        address from,
        address to,
        uint256 amount
    ) external onlyLBSKR returns (bool) {
        _transferTokens(
            from,
            to,
            amount,
            false,
            _getsNoRfi[from],
            _getsNoRfi[to]
        );
        return true;
    }

    /**
     * @notice Check the total reflection distributed till date
     */
    function totalReflection() external view returns (uint256) {
        return _tRfiFeesSum;
    }
}

/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.17;

import "../lib/Utils.sol";
import "../openzeppelin/access/Ownable.sol";
import "../openzeppelin/security/Pausable.sol";
import "../openzeppelin/token/ERC20/IERC20.sol";
import "../uniswap/v2-core/interfaces/IUniswapV2Factory.sol";
import "../uniswap/v2-core/interfaces/IUniswapV2Pair.sol";
import "../uniswap/v2-periphery/interfaces/IUniswapV2Router02.sol";
import "../uniswap/v3-core/interfaces/IUniswapV3Factory.sol";
import "../uniswap/v3-core/interfaces/IUniswapV3Pool.sol";
import "./Manageable.sol";

abstract contract BaseBSKR is IERC20, Ownable, Manageable, Pausable, Utils {
    address private constant _DEXV2_ROUTER_ADDR =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // UniswapV2Router02
    address private constant _DEXV3_FACTORY_ADDR =
        0x1F98431c8aD98523631AE4a59f267346ea31F984; // UniswapV3Factory
    address private constant _DEXV3_ROUTER_ADDR =
        0xE592427A0AEce92De3Edee1F18E0157C05861564; // SwapRouter
    address private constant _NFPOSMAN_ADDR =
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88; // NonfungiblePositionManager
    uint8 private constant _DECIMALS = 18;

    uint256 internal constant _BIPS = 10**4; // bips or basis point divisor
    // uint256 private constant _TOTAL_SUPPLY = (10 ** 12) * (10 ** _DECIMALS); // 1 trillion for PulseChain
    uint256 internal constant _TOTAL_SUPPLY = (10**9) * (10**_DECIMALS); // 1 billion for Goerli

    IUniswapV2Factory internal immutable _dexFactoryV2;
    IUniswapV2Router02 internal immutable _dexRouterV2;
    IUniswapV3Factory internal immutable _dexFactoryV3;
    address internal immutable _growthAddress; // 0x4F06FCcAa501B7BB9f9AFcEFb20f7862Be050B7d
    address internal _ammBSKRPair;
    // address internal _ammLBSKRPair;

    address[] internal _sisterOAs;
    mapping(address => bool) internal _isAMMPair;    
    mapping(address => bool) internal _paysNoFee;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) internal _balances;
    string private _name;
    string private _symbol;
    uint8 internal _oaIndex;

    constructor(
        string memory nameA,
        string memory symbolA,
        address growthAddressA,
        address[] memory sisterOAsA
    ) {
        _name = nameA;
        _symbol = symbolA;
        _growthAddress = growthAddressA;
        _sisterOAs = sisterOAsA;

        _dexRouterV2 = IUniswapV2Router02(_DEXV2_ROUTER_ADDR);
        _dexFactoryV2 = IUniswapV2Factory(_dexRouterV2.factory());

        _dexFactoryV3 = IUniswapV3Factory(_DEXV3_FACTORY_ADDR);

        // exclude owner and this contract from fee -- TODO do we need to add more?
        _paysNoFee[_msgSender()] = true;
        _paysNoFee[address(this)] = true;
        _paysNoFee[_DEXV2_ROUTER_ADDR] = true; // UniswapV2
        _paysNoFee[_DEXV3_ROUTER_ADDR] = true; // Uniswapv3 TODO do we need to add factories as well?
        _paysNoFee[_NFPOSMAN_ADDR] = true; // Uniswapv3
    }

    //to recieve ETH from _dexRouterV2 when swaping
    receive() external payable {}

    fallback() external payable {}

    /**
     * @notice Sets `amount` as the allowance of `spender` over the `owner` s tokens.
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
        require(owner != address(0), "BSKR: From Zero Address");
        require(spender != address(0), "BSKR: To Zero Address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _checkIfAMMPair(address target) internal {
        if (target.code.length == 0) return;
        // if (target == _DEXV2_ROUTER_ADDR) return;
        if (!_isAMMPair[target]) {
            if (_isPairPool(target)) {
                _approve(target, target, type(uint256).max);
                _isAMMPair[target] = true;
            }
        }
    }

    function _getOriginAddress() internal returns (address) {
        if (_oaIndex < (_sisterOAs.length - 1)) {
            _oaIndex = _oaIndex + 1;
        } else {
            _oaIndex = 0;
        }
        return _sisterOAs[_oaIndex];
    }

    function _isPairPool(address target)
        internal
        view
        returns (bool isPair)
    // returns (bool isPair, bool isV3Pool)
    {
        address token0 = _getToken0(target);
        if (token0 == address(0)) {
            // return (false, false);
            return false;
        }

        address token1 = _getToken1(target);
        if (token1 == address(0)) {
            // return (false, false);
            return false;
        }

        return true;

        // uint24 fee = _getFee(target);

        // if (fee == 0) {
        //     return (true, false);
        // } else {
        //     return (true, true);
        // }
    }

    // function isBSKRLBSKRV3Pool(address target, address otherToken)
    //     private
    //     view
    //     returns (bool)
    // {
    //     address token0 = address(this);
    //     address token1 = otherToken;

    //     // 0x0dfe1681 token0()

    //     int24 targetTickSpacing = _callAndParseInt24Return(
    //         target,
    //         hex"d0c93a7c"
    //     );

    //     if (targetTickSpacing == 0) {
    //         return false;
    //     }

    //     IUniswapV3Pool poolContract = IUniswapV3Pool(target);

    //     uint24 fee;

    //     if (otherToken < address(this)) {
    //         token0 = otherToken;
    //         token1 = address(this);
    //     }

    //     try poolContract.fee() returns (uint24 _fee) {
    //         fee = _fee;
    //     } catch (bytes memory) {
    //         return false;
    //     }

    //     return target == _dexFactoryV3.getPool(token0, token1, fee);
    // }

    // function _isUniswapV2Pair(address target) internal view returns (bool) {
    //     address token0;
    //     address token1;

    //     string memory targetSymbol = _callAndParseStringReturn(
    //         target,
    //         hex"95d89b41"
    //     );

    //     if (bytes(targetSymbol).length == 0) {
    //         return false;
    //     }

    //     if (_compare(targetSymbol, "UNI-V2")) {
    //         IUniswapV2Pair pairContract = IUniswapV2Pair(target);

    //         try pairContract.token0() returns (address _token0) {
    //             token0 = _token0;
    //         } catch Error(
    //             string memory //reason
    //         ) {
    //             return false;
    //         } catch (
    //             bytes memory //reason
    //         ) {
    //             return false;
    //         }

    //         try pairContract.token1() returns (address _token1) {
    //             token1 = _token1;
    //         } catch Error(
    //             string memory //reason
    //         ) {
    //             return false;
    //         } catch (
    //             bytes memory //reason
    //         ) {
    //             return false;
    //         }
    //     } else {
    //         return false;
    //     }

    //     return target == _dexFactoryV2.getPair(token0, token1);
    // }

    // function _isUniswapV3Pool(address target) private view returns (bool) {
    //     int24 targetTickSpacing = _callAndParseInt24Return(
    //         target,
    //         hex"d0c93a7c" // tickSpacing()
    //     );

    //     if (targetTickSpacing == 0) {
    //         return false;
    //     }

    //     address token0;
    //     address token1;
    //     uint24 fee;
    //     IUniswapV3Pool poolContract = IUniswapV3Pool(target);

    //     try poolContract.token0() returns (address _token0) {
    //         token0 = _token0;
    //     } catch (bytes memory) {
    //         return false;
    //     }

    //     try poolContract.token1() returns (address _token1) {
    //         token1 = _token1;
    //     } catch (bytes memory) {
    //         return false;
    //     }

    //     try poolContract.fee() returns (uint24 _fee) {
    //         fee = _fee;
    //     } catch (bytes memory) {
    //         return false;
    //     }

    //     return target == _dexFactoryV3.getPool(token0, token1, fee);
    // }

    /**
     * @notice Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "BSKR: Insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transfer(
        address owner,
        address to,
        uint256 amount
    ) internal virtual;

    /**
     * @notice See {IERC20-allowance}.  TODO add description
     */
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @notice See {IERC20-approve}. TODO add description
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * Access to _approve for manager to allow approvals on behalf of contracts when needed
     */
    function approveContract(
        address contractAddr,
        address spender,
        uint256 amount
    ) external onlyManager returns (bool) {
        _approve(contractAddr, spender, amount);
        return true;
    }

    /**
     * @notice Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     */
    function decimals() public pure returns (uint8) {
        return _DECIMALS;
    }

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "BSKR: Decreases below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @notice Waives off fees for an address -- TODO probably we do not need this
     */
    // function excludeFromFee(address account) external onlyManager {
    //     _paysNoFee[account] = true;
    // }

    /**
     * @notice Atomically increases the allowance granted to `spender` by the caller.
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @notice Checks if an account is excluded from fees - TODO do we need this?
     */
    // function isExcludedFromFee(address account) external view returns (bool) {
    //     return _paysNoFee[account];
    // }

    /**
     * @notice Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @notice Pauses this contract features
     */
    function pauseContract() external onlyManager {
        _pause();
    }

    /**
     * @notice Returns the symbol of the token
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Returns the amount of tokens in existence.
     */
    function totalSupply() public pure override returns (uint256) {
        return _TOTAL_SUPPLY;
    }

    /**
     * @notice See {IERC20-transfer}.    TODO add description
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @notice See {IERC20-transferFrom}. TODO add description
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @notice Unpauses the contract's features
     */
    function unPauseContract() external onlyManager {
        _unpause();
    }
}

/*
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.17;

import "../openzeppelin/utils/Context.sol";

abstract contract Manageable is Context {
    address private _manager;

    event ManagementTransferred(
        address indexed previousManager,
        address indexed newManager
    );

    constructor() {
        address msgSender = _msgSender();
        _manager = msgSender;
        emit ManagementTransferred(address(0), msgSender);
    }

    function manager() public view returns (address) {
        return _manager;
    }

    modifier onlyManager() {
        require(_manager == _msgSender(), "Manageable: Caller not manager");
        _;
    }

    /**
     * @notice Transfers the management of the contract to a new manager
     */
    function transferManagement(address newManager) external onlyManager {
        emit ManagementTransferred(_manager, newManager);
        _manager = newManager;
    }
}

/*
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.17;

contract Utils {
    function _bytes32ToString(bytes32 x) internal pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint256 charCount = 0;
        for (uint256 j = 0; j < 32; j++) {
            bytes1 char = x[j];
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    function _callAndParseAddressReturn(address token, bytes4 selector)
        internal
        view
        returns (address)
    {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(selector)
        );

        // if not implemented, or returns empty data, return empty string
        if (!success || data.length == 0) {
            return address(0);
        }

        // if implemented, or returns data, return decoded int24 else return 0
        if (data.length == 32) {
            return abi.decode(data, (address));
        }

        return address(0);
    }

    function _callAndParseUint24Return(address token, bytes4 selector)
        internal
        view
        returns (uint24)
    {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(selector)
        );

        // if not implemented, or returns empty data, return empty string
        if (!success || data.length == 0) {
            return 0;
        }

        // if implemented, or returns data, return decoded int24 else return 0
        if (data.length == 32) {
            return abi.decode(data, (uint24));
        }

        return 0;
    }

    function _callAndParseStringReturn(address token, bytes4 selector)
        internal
        view
        returns (string memory)
    {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(selector)
        );

        // if not implemented, or returns empty data, return empty string
        if (!success || data.length == 0) {
            return "";
        }

        // bytes32 data always has length 32
        if (data.length == 32) {
            bytes32 decoded = abi.decode(data, (bytes32));
            return _bytes32ToString(decoded);
        } else if (data.length > 64) {
            return abi.decode(data, (string));
        }
        return "";
    }

    function _compare(string memory str1, string memory str2)
        internal
        pure
        returns (bool)
    {
        if (bytes(str1).length != bytes(str2).length) {
            return false;
        }
        return
            keccak256(abi.encodePacked(str1)) ==
            keccak256(abi.encodePacked(str2));
    }

    function _getFee(address target) internal view returns (uint24 targetFee) {
        targetFee = _callAndParseUint24Return(
            target,
            hex"ddca3f43" // fee()
        );

        return targetFee;
    }

    function _getToken0(address target)
        internal
        view
        returns (address targetToken0)
    {
        targetToken0 = _callAndParseAddressReturn(
            target,
            hex"0dfe1681" // token0()
        );

        return targetToken0;
    }

    function _getToken1(address target)
        internal
        view
        returns (address targetToken1)
    {
        targetToken1 = _callAndParseAddressReturn(
            target,
            hex"d21220a7" // token1()
        );

        return targetToken1;
    }
}

/*
 * SPDX-License-Identifier: MIT
 */
 
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.17;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "CNO");
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
        require(newOwner != address(0), "NOZA");
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

/*
 * SPDX-License-Identifier: MIT
 */
 
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.17;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: Paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: Not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

/*
 * SPDX-License-Identifier: MIT
 */
 
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

/*
 * SPDX-License-Identifier: MIT
 */
 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.17;

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

/*
 * SPDX-License-Identifier: MIT
 */
 
pragma solidity ^0.8.17;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function allPairsLength() external view returns (uint);
    function allPairs(uint) external view returns (address pair);
}

/*
 * SPDX-License-Identifier: MIT
 */
 
pragma solidity ^0.8.17;

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

/*
 * SPDX-License-Identifier: MIT
 */
 
pragma solidity ^0.8.17;

interface IUniswapV2Router01 {
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
}

/*
 * SPDX-License-Identifier: MIT
 */
 
pragma solidity ^0.8.17;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import './pool/IUniswapV3PoolImmutables.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);
}