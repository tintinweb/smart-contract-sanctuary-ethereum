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

contract BSKR_VX is BaseBSKR {
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

    address private _LBSKRAddr; // needs this address to provide discounts
    address private _ammBSKRPair; // BSKR-ETH pair address
    address private _paydayAddress;
    address[] private _noRfi;
    bool private _addLPEnabled; // = true;
    bool private _addingLiquidity;
    mapping(address => bool) private _getsNoRfi;
    mapping(address => bool) private _isMyTokensPair;
    mapping(address => uint256) private _rBalances;
    uint256 private _rTotal; //= (type(uint256).max - (type(uint256).max % _TOTAL_SUPPLY));
    uint256 private constant _MAX_TX_AMOUNT = _TOTAL_SUPPLY / 25; // 4% of the total supply
    uint256 private constant _NUM_TOKENS_FOR_LP = _TOTAL_SUPPLY / 1000; // 0.1% of the total supply
    uint256 private totalReflection;
    uint32[6] private _currFees; //= [200, 150, 100, 50, 50, 550];

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event AddLPEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    // modifier swapInProgress() {
    //     _addingLiquidity = true;
    //     _;
    //     _addingLiquidity = false;
    // }

    // modifier onlyLBSKR() {
    //     require(msg.sender == _LBSKRAddr);
    //     _;
    // }

    function __BSKR_VX_init(
        uint8 version,
        string memory nameA,
        string memory symbolA,
        address growthAddressA,
        address paydayAddressA,
        address lbskrAddrA,
        address[] memory sisterOAsA
    ) external reinitializer(version) {
        __BaseBSKR_init(nameA, symbolA, growthAddressA, sisterOAsA);
        _addLPEnabled = true;
        // _rTotal = (type(uint256).max - (type(uint256).max % _TOTAL_SUPPLY)); // this might have changed and we want to preserve it
        _currFees = [200, 150, 100, 50, 50, 550];
        _paydayAddress = paydayAddressA;
        _LBSKRAddr = lbskrAddrA;

        _balances[_msgSender()] = _TOTAL_SUPPLY;

        // _excludeFromRfi(_msgSender()); // Use this function to exclude any wallet from Rfi
        // _excludeFromRfi(address(this));

        // _rBalances[_msgSender()] = _rTotal;

        // _ammBSKRPair = _dexFactoryV2.createPair(
        //     address(this),
        //     wethAddr
        // );
        // _approve(_ammBSKRPair, _ammBSKRPair, type(uint256).max);
        // _isAMMPair[_ammBSKRPair] = true;
        // _setNoRfi(_ammBSKRPair);

        // address _ammLBSKRPair = _dexFactoryV2.createPair(
        //     address(this),
        //     _LBSKRAddr
        // );
        // _approve(_ammLBSKRPair, _ammLBSKRPair, type(uint256).max);
        // _isAMMPair[_ammLBSKRPair] = true;
        // _setNoRfi(_ammLBSKRPair);

        // for (uint256 index = 0; index < _sisterOAs.length; ++index) {
        //     _paysNoFee[_sisterOAs[index]] = true;
        //     _setNoRfi(_sisterOAs[index]);
        // }

        // _setNoRfi(_msgSender());
        // _setNoRfi(address(this));
        // _setNoRfi(_DEXV2_ROUTER_ADDR); // UniswapV2
        // _setNoRfi(_DEXV3_ROUTER_ADDR); // Uniswapv3
        // _setNoRfi(_NFPOSMAN_ADDR); // Uniswapv3
        // _setNoRfi(_paydayAddress);
        // _setNoRfi(address(0));

        // emit Transfer(address(0), _msgSender(), _TOTAL_SUPPLY);
    }

    function _airdropTokens(address to, uint256 amount) internal override {
        _transferTokens(
            owner(),
            to,
            amount,
            false,
            true, // owner does not get Rfi
            _getsNoRfi[to]
        );
    }

    // function _excludeFromRfi(address wallet) private {
    //     if (_rBalances[wallet] > 0) {
    //         require(
    //             _rBalances[wallet] <= _rTotal,
    //             "B: Wallet must be < total Rfi"
    //         );
    //         _balances[wallet] = _rBalances[wallet] / _getRate();
    //     }
    //     _getsNoRfi[wallet] = true;
    //     _noRfi.push(wallet);
    // }

    function _getRate() private view returns (uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _TOTAL_SUPPLY;
        for (uint256 index = 0; index < _noRfi.length; ++index) {
            if (
                _rBalances[_noRfi[index]] > rSupply ||
                _balances[_noRfi[index]] > tSupply
            ) return (_rTotal / _TOTAL_SUPPLY);
            rSupply -= _rBalances[_noRfi[index]];
            tSupply -= _balances[_noRfi[index]];
        }
        if (rSupply < _rTotal / _TOTAL_SUPPLY) return (_rTotal / _TOTAL_SUPPLY);
        return rSupply / tSupply;
    }

    function _getValues(uint256 tAmount, uint256 feeMultiplier)
        private
        view
        returns (uint256[] memory)
    {
        uint256[] memory response = new uint256[](13);

        uint256 currentRate = _getRate();
        response[uint256(Field.rAmount)] = (tAmount * currentRate);

        if (feeMultiplier == 0) {
            response[uint256(Field.tRfiFee)] = 0;
            response[uint256(Field.tBurnFee)] = 0;
            response[uint256(Field.tGrowthFee)] = 0;
            response[uint256(Field.tPaydayFee)] = 0;
            response[uint256(Field.tLPFee)] = 0;
            response[uint256(Field.tTransferAmount)] = tAmount;

            response[uint256(Field.rRfiFee)] = 0;
            response[uint256(Field.rBurnFee)] = 0;
            response[uint256(Field.rGrowthFee)] = 0;
            response[uint256(Field.rPaydayFee)] = 0;
            response[uint256(Field.rLPFee)] = 0;
            response[uint256(Field.rTransferAmount)] = tAmount * currentRate;
        } else {
            response[uint256(Field.tRfiFee)] =
                (((tAmount * _currFees[uint256(Fees.RfiFee)]) / _BIPS) *
                    feeMultiplier) /
                10;
            response[uint256(Field.tBurnFee)] =
                (((tAmount * _currFees[uint256(Fees.BurnFee)]) / _BIPS) *
                    feeMultiplier) /
                10;
            response[uint256(Field.tGrowthFee)] =
                (((tAmount * _currFees[uint256(Fees.GrowthFee)]) / _BIPS) *
                    feeMultiplier) /
                10;
            response[uint256(Field.tPaydayFee)] =
                (((tAmount * _currFees[uint256(Fees.PaydayFee)]) / _BIPS) *
                    feeMultiplier) /
                10;
            response[uint256(Field.tLPFee)] =
                (((tAmount * _currFees[uint256(Fees.LPFee)]) / _BIPS) *
                    feeMultiplier) /
                10;
            response[uint256(Field.tTransferAmount)] =
                tAmount -
                ((((tAmount * _currFees[uint256(Fees.GrossFees)]) / _BIPS) *
                    feeMultiplier) / 10);

            response[uint256(Field.rRfiFee)] = (response[uint256(Field.tRfiFee)] *
                currentRate);
            response[uint256(Field.rBurnFee)] = (response[uint256(Field.tBurnFee)] *
                currentRate);
            response[uint256(Field.rGrowthFee)] = (response[
                uint256(Field.tGrowthFee)
            ] * currentRate);
            response[uint256(Field.rPaydayFee)] = (response[
                uint256(Field.tPaydayFee)
            ] * currentRate);
            response[uint256(Field.rLPFee)] = (response[uint256(Field.tLPFee)] *
                currentRate);
            response[uint256(Field.rTransferAmount)] = (response[
                uint256(Field.tTransferAmount)
            ] * currentRate);
        }

        return (response);
    }

    // function _includeInRfi(address wallet) private {
    //     require(_getsNoRfi[wallet], "B: Already gets Rfi");
    //     for (uint256 index = 0; index < _noRfi.length; index++) {
    //         if (_noRfi[index] == wallet) {
    //             _noRfi[index] = _noRfi[_noRfi.length - 1];
    //             _balances[wallet] = 0;
    //             _getsNoRfi[wallet] = false;
    //             _noRfi.pop();
    //             break;
    //         }
    //     }
    // }

    function _isLBSKRPair(address target) internal returns (bool) {
        if (_isAMMPair[target]) {
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
                return true;
            }
        }

        return false;
    }

    function _setNoRfi(address wallet) private {
        if (!_getsNoRfi[wallet]) {
            _getsNoRfi[wallet] = true;
            _noRfi.push(wallet);
        }
    }

    function _takeFee(
        address target,
        uint256 tFee,
        uint256 rFee
    ) private {
        _rBalances[target] += rFee;
        if (_getsNoRfi[target]) _balances[target] += tFee;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal whenNotPaused override {
        require(from != address(0), "B: From 0 addr");
        require(to != address(0), "B: To 0 addr");
        require(amount != 0, "B: 0 amount");

        if (from != owner() && to != owner()) {
            require(
                amount <= _MAX_TX_AMOUNT,
                "B: Exceeds max tx size"
            );
        }

        if (!isV3Enabled) {
            require(
                !v3PairInvolved(from, to),
                "B: UniV3 is not supported!"
            );
        }

        _checkIfAMMPair(from);
        if (_isAMMPair[from]) {
            _setNoRfi(from);
        }
        _checkIfAMMPair(to);
        if (_isAMMPair[to]) {
            _setNoRfi(to);
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        // if (contractTokenBalance > _MAX_TX_AMOUNT) {
        //     contractTokenBalance = _MAX_TX_AMOUNT;
        // }

        /* is the token balance of this contract address over the min number of
         * tokens that we need to initiate a swap + liquidity lock?
         * also, don't get caught in a circular liquidity event.
         * also, don't swap & liquify if sender is uniswap pair (Buy transaction).
         */
        if (
            (contractTokenBalance >= _NUM_TOKENS_FOR_LP) &&
            !_addingLiquidity &&
            from != _ammBSKRPair &&
            _addLPEnabled
        ) {
            _addingLiquidity = true;

            /* split the contract balance into halves */
            uint256 amount2Eth = _NUM_TOKENS_FOR_LP >> 1; // divide by 2
            uint256 tokenAmount = _NUM_TOKENS_FOR_LP - amount2Eth;

            /* Check balance before swap */
            uint256 initialBalance = address(this).balance;

            /* swap tokens for ETH */
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = wethAddr;

            _approve(address(this), address(this), amount2Eth); // allow address(this) to spend its tokens
            _approve(address(this), address(_dexRouterV2), amount2Eth);

            _dexRouterV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount2Eth,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp + 15
            );

            /* Determine ETH from the swap */
            uint256 ethAmount = address(this).balance - initialBalance;

            /* add liquidity to uniswap */
            _approve(address(this), address(_dexRouterV2), tokenAmount);

            _dexRouterV2.addLiquidityETH{value: ethAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                _getOriginAddress(),
                block.timestamp + 15
            );

            // Prevent ETH dust from getting locked in the contract forever
            payable(owner()).transfer(address(this).balance);

            emit SwapAndLiquify(amount2Eth, ethAmount, tokenAmount);
            _addingLiquidity = false;
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any wallet belongs to _paysNoFee wallet then remove the fee
        if (_paysNoFee[from] || _paysNoFee[to]) {
            takeFee = false;
        }

        if (_isAMMPair[from] && !_isAMMPair[to]) {
            // Buy transaction
        } else if (!_isAMMPair[from] && _isAMMPair[to]) {
            // Sell transaction
        } else if (_isAMMPair[from] && _isAMMPair[to]) {
            // hop between LPs - potentially double taxes
        } else {
            // simple transfer not buy/sell, take no fees
            takeFee = false;
        }

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
        uint256 reducedFees = 10;

        if (!takeFee) {
            reducedFees = 0;
        } else if (_isLBSKRPair(sender) || _isLBSKRPair(recipient)) {
            reducedFees = 5;
        }

        uint256[] memory response = _getValues(tAmount, reducedFees);

        if (senderExcluded) {
            _balances[sender] -= tAmount;
        }
        _rBalances[sender] -= response[uint256(Field.rAmount)];

        if (recipientExcluded) {
            _balances[recipient] += response[uint256(Field.tTransferAmount)];
        }
        _rBalances[recipient] += response[uint256(Field.rTransferAmount)];

        if (response[uint256(Field.tRfiFee)] != 0) {
            _rTotal -= response[uint256(Field.rRfiFee)];
            totalReflection += response[uint256(Field.tRfiFee)];
            // cannot emit transfer event
        }

        if (response[uint256(Field.tBurnFee)] != 0) {
            _takeFee(
                address(0),
                response[uint256(Field.tBurnFee)],
                response[uint256(Field.rBurnFee)]
            );
            emit Transfer(sender, address(0), response[uint256(Field.tBurnFee)]);
        }

        if (response[uint256(Field.tGrowthFee)] != 0) {
            _takeFee(
                _growthAddress,
                response[uint256(Field.tGrowthFee)],
                response[uint256(Field.rGrowthFee)]
            );
            emit Transfer(
                sender,
                _growthAddress,
                response[uint256(Field.tGrowthFee)]
            );
        }

        if (response[uint256(Field.tPaydayFee)] != 0) {
            _takeFee(
                _paydayAddress,
                response[uint256(Field.tPaydayFee)],
                response[uint256(Field.rPaydayFee)]
            );
            emit Transfer(
                sender,
                _paydayAddress,
                response[uint256(Field.tPaydayFee)]
            );
        }

        if (response[uint256(Field.tLPFee)] != 0) {
            _takeFee(
                address(this),
                response[uint256(Field.tLPFee)],
                response[uint256(Field.rLPFee)]
            );
            emit Transfer(sender, address(this), response[uint256(Field.tLPFee)]);
        }

        emit Transfer(
            sender,
            recipient,
            response[uint256(Field.tTransferAmount)]
        );
    }

    // /**
    //  * Airdrop BSKR to sacrificers, deducted from owner's wallet
    //  */
    // function airdrop(Airdrop[] calldata receivers) external override onlyOwner {
    //     for (uint256 index; index < receivers.length; ++index) {
    //         if (
    //             receivers[index].user != address(0) &&
    //             receivers[index].amount != 0
    //         ) {
    //             _transferTokens(
    //                 owner(),
    //                 receivers[index].user,
    //                 receivers[index].amount,
    //                 false,
    //                 true, // owner does not get Rfi
    //                 _getsNoRfi[receivers[index].user]
    //             );
    //         }
    //     }
    // }

    /**
     * Calculates the wallet balance taking into wallet Rfi received
     */
    function balanceOf(address wallet) public view override returns (uint256) {
        if (_getsNoRfi[wallet]) return _balances[wallet];

        require(_rBalances[wallet] <= _rTotal, "B: Amount too large");
        uint256 currentRate = _getRate();
        return _rBalances[wallet] / currentRate;
    }

    /**
     * @notice Gift reflection to the BSKR community
     * TODO do we need this function?
     */
    function giftReflection(uint256 tAmount) external whenNotPaused {
        require(tAmount != 0, "B: Zero gift amount");
        address sender = _msgSender();
        require(!_getsNoRfi[sender], "B: Excluded wallet");
        uint256[] memory response = _getValues(tAmount, 10);
        require(
            _rBalances[sender] > response[uint256(Field.rAmount)],
            "B: Gift too large"
        );
        _rBalances[sender] -= response[uint256(Field.rAmount)];
        _rTotal -= response[uint256(Field.rAmount)];
        totalReflection += tAmount;
    }

    /**
     * @notice Enable or disable auto liquidity feature - for manager only in case of issues
     */
    function setSwapAndLiquifyEnabled(bool _enabled) external onlyManager {
        _addLPEnabled = _enabled;
        emit AddLPEnabledUpdated(_enabled);
    }

    /**
     * @notice Transfer the unstaked token while unstaking.
     * Only LBSKR contract may call this function
     */
    function stakeTransfer(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(msg.sender == _LBSKRAddr);
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
}

/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.17;

import "../lib/Utils.sol";
import "../openzeppelin/access/OwnableUpgradeable.sol";
import "../openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import "../openzeppelin/security/PausableUpgradeable.sol";
import "../openzeppelin/token/ERC20/IERC20Upgradeable.sol";
import "../uniswap/v2-core/interfaces/IUniswapV2Factory.sol";
import "../uniswap/v2-core/interfaces/IUniswapV2Pair.sol";
import "../uniswap/v2-periphery/interfaces/IUniswapV2Router02.sol";
import "../uniswap/v3-core/interfaces/IUniswapV3Factory.sol";
import "../uniswap/v3-core/interfaces/IUniswapV3Pool.sol";
import "./Manageable.sol";

// TODO do we want to add reentrancy guard for any functions?
// TODO do we want to add permit to our contracts
// TODO make name, symbol, decimal as public and remove getters
abstract contract BaseBSKR is
    Utils,
    OwnableUpgradeable,
    UUPSUpgradeable,
    PausableUpgradeable,
    IERC20Upgradeable,
    Manageable
{
    struct Airdrop {
        address user;
        uint256 amount;
    }

    IUniswapV2Factory internal _dexFactoryV2;
    IUniswapV2Router02 internal _dexRouterV2;
    // IUniswapV3Factory internal _dexFactoryV3;
    address internal _growthAddress;
    // address internal constant _DEXV2_ROUTER_ADDR =
    //     0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // UniswapV2Router02
    // address internal constant _DEXV3_FACTORY_ADDR =
    //     0x1F98431c8aD98523631AE4a59f267346ea31F984; // UniswapV3Factory
    // address internal constant _DEXV3_ROUTER_ADDR =
    //     0xE592427A0AEce92De3Edee1F18E0157C05861564; // SwapRouter
    // address internal constant _NFPOSMAN_ADDR =
    //     0xC36442b4a4522E871399CD717aBDD847Ab11FE88; // NonfungiblePositionManager
    address public wethAddr;
    address[] internal _sisterOAs;
    bool isV3Enabled;
    mapping(address => bool) internal _isAMMPair;
    mapping(address => bool) internal _paysNoFee;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) internal _balances;
    string private _name;
    string private _symbol;
    uint256 internal constant _BIPS = 10**4; // bips or basis point divisor
    uint256 internal constant _TOTAL_SUPPLY = (10**9) * (10**_DECIMALS); // 1 billion for Goerli
    // uint256 private constant _TOTAL_SUPPLY = (10 ** 12) * (10 ** _DECIMALS); // 1 trillion for PulseChain
    uint256 internal _oaIndex;
    uint256 private constant _DECIMALS = 18;

    function __BaseBSKR_init(
        string memory nameA,
        string memory symbolA,
        address growthAddressA,
        address[] memory sisterOAsA
    ) public onlyInitializing {
        __Ownable_init();
        __Pausable_init();
        __Manageable_init();

        _name = nameA;
        _symbol = symbolA;
        _growthAddress = growthAddressA;
        _sisterOAs = sisterOAsA;

        if (block.chainid == 56) {
            // BSC Mainnet - PancakeRouter
            _dexRouterV2 = IUniswapV2Router02(
                0x10ED43C718714eb63d5aA57B78B54704E256024E
            );
        } else if (block.chainid == 97) {
            // BSC Testnet - PancakeRouter
            _dexRouterV2 = IUniswapV2Router02(
                0xD99D1c33F9fC3444f8101754aBC46c52416550D1
            );
        } else if (
            // ETH - UniswapV2Router02
            block.chainid == 1 || // Mainnet
            block.chainid == 5 // Goerli
        ) {
            _dexRouterV2 = IUniswapV2Router02(
                0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
            );
        } else if (block.chainid == 43114) {
            // Avalanche C-Chain - JoeRouter02
            _dexRouterV2 = IUniswapV2Router02(
                0x60aE616a2155Ee3d9A68541Ba4544862310933d4
            );
        } else if (block.chainid == 250) {
            // Fantom Opera - SpookySwap
            _dexRouterV2 = IUniswapV2Router02(
                0xF491e7B69E4244ad4002BC14e878a34207E38c29
            );
        } else if (block.chainid == 137) {
            // Polygon - QuickSwap
            _dexRouterV2 = IUniswapV2Router02(
                0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff
            );
        } else if (
            // block.chainid == 369 || // PLS Mainnet
            // block.chainid == 942 || // PLS Testnet3
            block.chainid == 941 // PLS Testnet2B
        ) {
            // Pulsechain - PulseXRouter03
            _dexRouterV2 = IUniswapV2Router02(
                0xb4A7633D8932de086c9264D5eb39a8399d7C0E3A
            );
        } else {
            revert();
        }

        if (
            // block.chainid == 369 || // PLS Mainnet
            // block.chainid == 942 || // PLS Testnet3
            block.chainid == 941 // PLS Testnet2B
        ) {
            wethAddr = _dexRouterV2.WPLS();
        } else {
            wethAddr = _dexRouterV2.WETH();
        }

        _dexFactoryV2 = IUniswapV2Factory(_dexRouterV2.factory());
        // _dexFactoryV3 = IUniswapV3Factory(_DEXV3_FACTORY_ADDR);

        _paysNoFee[_msgSender()] = true;
        _paysNoFee[address(this)] = true;
        // _paysNoFee[_DEXV2_ROUTER_ADDR] = true; // UniswapV2
        // _paysNoFee[_DEXV3_ROUTER_ADDR] = true; // Uniswapv3
        // _paysNoFee[_NFPOSMAN_ADDR] = true; // Uniswapv3
    }

    //to recieve ETH from _dexRouterV2 when swaping
    receive() external payable {}

    fallback() external payable {}

    function __v3PairInvolved(address target) internal view returns (bool) {
        if (target == address(_dexRouterV2)) return false; // to avoid orange reverts
        if (target == wethAddr) return false; // to avoid orange reverts
        if (_isAMMPair[target]) {
            return false; // if V3 is disabled, only V2 pairs are registered
        }

        address token0 = _getToken0(target);
        if (token0 == address(0)) {
            return false;
        }

        address token1 = _getToken1(target);
        if (token1 == address(0)) {
            return false;
        }

        uint24 fee = _getFee(target);
        if (fee != 0) {
            return true;
        }

        return false;
    }

    function _airdropTokens(address to, uint256 amount) internal virtual;

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
        require(owner != address(0), "BB: From 0 addr");
        require(spender != address(0), "BB: To 0 addr");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _checkIfAMMPair(address target) internal {
        if (target.code.length == 0) return;
        if (target == address(_dexRouterV2)) return; // to avoid orange reverts
        if (target == wethAddr) return; // to avoid orange reverts
        if (!_isAMMPair[target]) {
            address token0 = _getToken0(target);
            if (token0 == address(0)) {
                return;
            }

            address token1 = _getToken1(target);
            if (token1 == address(0)) {
                return;
            }

            _approve(target, target, type(uint256).max);
            _isAMMPair[target] = true;
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

    function _transfer(
        address owner,
        address to,
        uint256 amount
    ) internal virtual;

    /**
     * Airdrop BSKR to sacrificers, deducted from owner's wallet
     */
    function airdrop(Airdrop[] calldata receivers) external onlyOwner {
        for (uint256 index; index < receivers.length; ++index) {
            if (
                receivers[index].user != address(0) &&
                receivers[index].amount != 0
            ) {
                _airdropTokens(receivers[index].user, receivers[index].amount);
            }
        }
    }

    /**
     * @notice Sets allowance for spender for owner's tokens
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
     * @notice Sets allowance for spender to use msgsender's tokens
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        external
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
        if (contractAddr.code.length > 0) { // only contract would have non-zero code length
            _approve(contractAddr, spender, amount);
        }
        return true;
    }

    /**
     * @notice Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     */
    function decimals() external pure returns (uint256) {
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
        external
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue, // TODO may be smarter to just set the allowance to zero if it hits this exception
            "BB: Decrease below 0"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @notice Disables UniswapV3
     */
    function disableUniswapV3() external onlyManager {
        isV3Enabled = false;
    }

    /**
     * @notice Enables UniswapV3
     */
    function enableUniswapV3() external onlyManager {
        isV3Enabled = true;
    }

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
        external
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @notice Returns the name of the token.
     */
    function name() external view returns (string memory) {
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
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Returns the amount of tokens in existence.
     */
    function totalSupply() external pure override returns (uint256) {
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
        external
        override
        returns (bool) // TODO do we want reentrancy check
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @notice Transfers tokens 'from' to 'to' address provided there is enough allowance
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
    ) external override returns (bool) {
        address spender = _msgSender();
        uint256 currentAllowance = allowance(from, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "BB: Insufficient allowance");
            unchecked {
                _approve(from, spender, currentAllowance - amount);
            }
        }
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @notice Unpauses the contract's features
     */
    function unPauseContract() external onlyManager {
        _unpause();
    }

    // to rename with _ prefix
    function v3PairInvolved(address from, address to)
        internal
        view
        returns (bool)
    {
        return (__v3PairInvolved(from) || __v3PairInvolved(to));
    }

    // TODO Adding this function jeopardizes decentralization, tokens in the contract are not in control
    // function withdrawToken(address _tokenContract, uint256 _amount)
    //     external
    //     onlyManager
    // {
    //     IERC20Upgradeable tokenContract = IERC20Upgradeable(_tokenContract);
    //     tokenContract.transfer(msg.sender, _amount);
    // }
}

/*
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.17;

import "../openzeppelin/utils/ContextUpgradeable.sol";

abstract contract Manageable is ContextUpgradeable {
    address private _manager;

    event ManagementTransferred(
        address indexed previousManager,
        address indexed newManager
    );

    function __Manageable_init() public onlyInitializing {
        // address msgSender = _msgSender();
        _manager = _msgSender();
        emit ManagementTransferred(address(0), _msgSender());
    }

    function manager() external view returns (address) {
        return _manager;
    }

    modifier onlyManager() {
        require(_manager == _msgSender(), "M: Caller not manager");
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
    uint24 private constant _SECS_IN_FOUR_WEEKS = 2419200; // 3600 * 24 * 7 * 4
    
    function _bytes32ToString(bytes32 x) internal pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint256 charCount = 0;
        for (uint256 index = 0; index < 32; ++index) {
            bytes1 char = x[index];
            if (char != 0) {
                bytesString[charCount] = char;
                ++charCount;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 index = 0; index < charCount; ++index) {
            bytesStringTrimmed[index] = bytesString[index];
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

    /**
     * @notice Calculates penalty basis points for given from and to timestamps in seconds since epoch
     */
    function _penaltyFor(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 penaltyBasis)
    {
        penaltyBasis = 0;
        if (fromTimestamp + 52 weeks > toTimestamp) {
            uint256 fourWeeksElapsed = (toTimestamp - fromTimestamp) /
                _SECS_IN_FOUR_WEEKS;
            if (fourWeeksElapsed < 13) {
                penaltyBasis = ((13 - fourWeeksElapsed) * 100); // If one four weeks have elapsed - penalty is 12% or 1200/10000
            }
        }
        return penaltyBasis;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is 0 addr");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the 0 addr");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    // /**
    //  * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
    //  * `recipient`, forwarding all available gas and reverting on errors.
    //  *
    //  * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
    //  * of certain opcodes, possibly making contracts go over the 2300 gas limit
    //  * imposed by `transfer`, making them unable to receive funds via
    //  * `transfer`. {sendValue} removes this limitation.
    //  *
    //  * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
    //  *
    //  * IMPORTANT: because control is transferred to `recipient`, care must be
    //  * taken to not create reentrancy vulnerabilities. Consider using
    //  * {ReentrancyGuard} or the
    //  * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
    //  */
    // function sendValue(address payable recipient, uint256 amount) internal {
    //     require(address(this).balance >= amount, "Address: insufficient balance");

    //     (bool success, ) = recipient.call{value: amount}("");
    //     require(success, "Address: unable to send value, recipient may have reverted");
    // }

    // /**
    //  * @dev Performs a Solidity function call using a low level `call`. A
    //  * plain `call` is an unsafe replacement for a function call: use this
    //  * function instead.
    //  *
    //  * If `target` reverts with a revert reason, it is bubbled up by this
    //  * function (like regular Solidity function calls).
    //  *
    //  * Returns the raw returned data. To convert to the expected return value,
    //  * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
    //  *
    //  * Requirements:
    //  *
    //  * - `target` must be a contract.
    //  * - calling `target` with `data` must not revert.
    //  *
    //  * _Available since v3.1._
    //  */
    // function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    //     return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    // }

    // /**
    //  * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
    //  * `errorMessage` as a fallback revert reason when `target` reverts.
    //  *
    //  * _Available since v3.1._
    //  */
    // function functionCall(
    //     address target,
    //     bytes memory data,
    //     string memory errorMessage
    // ) internal returns (bytes memory) {
    //     return functionCallWithValue(target, data, 0, errorMessage);
    // }

    // /**
    //  * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
    //  * but also transferring `value` wei to `target`.
    //  *
    //  * Requirements:
    //  *
    //  * - the calling contract must have an ETH balance of at least `value`.
    //  * - the called Solidity function must be `payable`.
    //  *
    //  * _Available since v3.1._
    //  */
    // function functionCallWithValue(
    //     address target,
    //     bytes memory data,
    //     uint256 value
    // ) internal returns (bytes memory) {
    //     return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    // }

    // /**
    //  * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
    //  * with `errorMessage` as a fallback revert reason when `target` reverts.
    //  *
    //  * _Available since v3.1._
    //  */
    // function functionCallWithValue(
    //     address target,
    //     bytes memory data,
    //     uint256 value,
    //     string memory errorMessage
    // ) internal returns (bytes memory) {
    //     require(address(this).balance >= value, "Address: insufficient balance for call");
    //     (bool success, bytes memory returndata) = target.call{value: value}(data);
    //     return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    // }

    // /**
    //  * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
    //  * but performing a static call.
    //  *
    //  * _Available since v3.3._
    //  */
    // function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    //     return functionStaticCall(target, data, "Address: low-level static call failed");
    // }

    // /**
    //  * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
    //  * but performing a static call.
    //  *
    //  * _Available since v3.3._
    //  */
    // function functionStaticCall(
    //     address target,
    //     bytes memory data,
    //     string memory errorMessage
    // ) internal view returns (bytes memory) {
    //     (bool success, bytes memory returndata) = target.staticcall(data);
    //     return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    // }

    // /**
    //  * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
    //  * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
    //  *
    //  * _Available since v4.8._
    //  */
    // function verifyCallResultFromTarget(
    //     address target,
    //     bool success,
    //     bytes memory returndata,
    //     string memory errorMessage
    // ) internal view returns (bytes memory) {
    //     if (success) {
    //         if (returndata.length == 0) {
    //             // only check isContract if the call was successful and the return data is empty
    //             // otherwise we already know that it was a contract
    //             require(isContract(target), "Address: call to non-contract");
    //         }
    //         return returndata;
    //     } else {
    //         _revert(returndata, errorMessage);
    //     }
    // }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    // struct Bytes32Slot {
    //     bytes32 value;
    // }

    // struct Uint256Slot {
    //     uint256 value;
    // }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    // /**
    //  * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
    //  */
    // function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
    //     /// @solidity memory-safe-assembly
    //     assembly {
    //         r.slot := slot
    //     }
    // }

    // /**
    //  * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
    //  */
    // function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
    //     /// @solidity memory-safe-assembly
    //     assembly {
    //         r.slot := slot
    //     }
    // }
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
    function WPLS() external pure returns (address);

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