/*
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.17;

import "./BaseERC20.sol";
import "../uniswap/v2-core/interfaces/IUniswapV2Factory.sol";
import "../uniswap/v2-core/interfaces/IUniswapV2Pair.sol";
import "../uniswap/v2-periphery/interfaces/IUniswapV2Router02.sol";
import "../uniswap/v3-core/interfaces/IUniswapV3Factory.sol";
import "../uniswap/v3-core/interfaces/IUniswapV3Pool.sol";

abstract contract BaseBSKR is BaseERC20 {
    IUniswapV2Router02 internal immutable dexRouterV2;
    IUniswapV2Factory internal immutable dexFactoryV2;
    IUniswapV3Factory internal immutable dexFactoryV3;
    address internal immutable dexRouterV3Address; // SwapRouter
    address internal immutable nfPosManAddress; // NonfungiblePositionManager
    mapping(address => bool) internal _isAMMPair;

    constructor(
        string memory nameA,
        string memory symbolA,
        address[] memory sisterOAsA
    ) BaseERC20(nameA, symbolA, sisterOAsA) {
        IUniswapV2Router02 _dexRouterV2 = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D // TODO constructor arg / set before deploy
        );
        dexRouterV2 = _dexRouterV2;
        dexFactoryV2 = IUniswapV2Factory(_dexRouterV2.factory());

        dexFactoryV3 = IUniswapV3Factory(
            address(0x1F98431c8aD98523631AE4a59f267346ea31F984) // TODO constructor arg / set before deploy
        );
        dexRouterV3Address = 0xE592427A0AEce92De3Edee1F18E0157C05861564; // TODO constructor arg / set before deploy
        nfPosManAddress = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88; // TODO constructor arg / set before deploy

        _sisterOAs = sisterOAsA;
    }

    function isUniswapV2Pair(address target) internal view returns (bool) {
        // if (target.code.length == 0) {
        //     return false;
        // }

        IUniswapV2Pair pairContract = IUniswapV2Pair(target);

        address token0;
        address token1;

        try pairContract.token0() returns (address _token0) {
            token0 = _token0;
        } catch (bytes memory) {
            return false;
        }

        try pairContract.token1() returns (address _token1) {
            token1 = _token1;
        } catch (bytes memory) {
            return false;
        }

        return target == dexFactoryV2.getPair(token0, token1);
    }

    function isUniswapV3Pool(address target) internal view returns (bool) {
        // if (target.code.length == 0) {
        //     return false;
        // }

        IUniswapV3Pool poolContract = IUniswapV3Pool(target);

        address token0;
        address token1;
        uint24 fee;

        try poolContract.token0() returns (address _token0) {
            token0 = _token0;
        } catch (bytes memory) {
            return false;
        }

        try poolContract.token1() returns (address _token1) {
            token1 = _token1;
        } catch (bytes memory) {
            return false;
        }

        try poolContract.fee() returns (uint24 _fee) {
            fee = _fee;
        } catch (bytes memory) {
            return false;
        }

        return target == dexFactoryV3.getPool(token0, token1, fee);
    }
}

/*
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.17;

import "./Manageable.sol";
import "../openzeppelin/token/ERC20/IERC20.sol";
import "../openzeppelin/access/Ownable.sol";
import "../openzeppelin/utils/Address.sol";
import "../openzeppelin/security/Pausable.sol";

// TODO all public function - check if they can be made external
// TODO public function are more costlier on gas but external function cannot be used internally
// TODO add whenNotPaused to all the applicable functions
abstract contract BaseERC20 is
    Context,
    IERC20,
    Ownable,
    Manageable,
    // AccessControl,
    Pausable
{
    using Address for address;

    // bytes32 internal constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    string internal _name;
    string internal _symbol;

    uint256 internal constant MAX = ~uint256(0);
    uint8 private constant _DECIMALS = 18;
    // uint256 private constant _TOTAL_SUPPLY = (10 ** 12) * (10 ** _DECIMALS); // TODO 1 trillion for PulseChain
    uint256 internal constant _TOTAL_SUPPLY = (10**9) * (10**_DECIMALS); // 1 billion for Goerli
    uint16 internal constant _BIPS = 10**4; // bips or basis point divisor

    uint256 internal maxTxAmount = _TOTAL_SUPPLY / 25; // 4% of the total supply

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) internal _tBalance;

    // uint256 internal _tFeesAccrued;

    address[] internal _sisterOAs;
    uint8 private _oaIndex;

    // TODO remove debug events
    event debug01(
        address a1,
        address a2,
        string s1,
        string s2,
        uint256 u1,
        uint256 u2
    );

    constructor(
        string memory nameA,
        string memory symbolA,
        address[] memory sisterOAsA
    ) {
        _name = nameA;
        _symbol = symbolA;
        _sisterOAs = sisterOAsA;

        // _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // _grantRole(MANAGER_ROLE, msg.sender);

        emit Transfer(address(0), _msgSender(), _TOTAL_SUPPLY);
    }

    /**
     * @notice Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @notice Returns the symbol of the token
     */
    function symbol() public view returns (string memory) {
        return _symbol;
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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() public pure returns (uint256) {
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
    function transfer(address to, uint256 amount) public returns (bool) {
        address from = _msgSender();
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != owner() && to != owner())
            require(
                amount <= maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );

        _transferCustom(from, to, amount);
    }

    function _transferCustom(
        address from,
        address to,
        uint256 amount
    ) internal virtual;

    /**
     * @notice See {IERC20-allowance}.  TODO add description
     */
    function allowance(address from, address to)
        public
        view
        returns (uint256)
    {
        return _allowances[from][to];
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
    function approve(address to, uint256 amount) public returns (bool) {
        address from = _msgSender();
        _approve(from, to, amount);
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
    ) public returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @notice Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address from,
        address to,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(from, to);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(from, to, currentAllowance - amount);
            }
        }
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
    function increaseAllowance(address to, uint256 addedValue)
        public
        returns (bool)
    {
        address from = _msgSender();
        _approve(from, to, allowance(from, to) + addedValue);
        return true;
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
    function decreaseAllowance(address to, uint256 subtractedValue)
        public
        returns (bool)
    {
        address from = _msgSender();
        uint256 currentAllowance = allowance(from, to);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(from, to, currentAllowance - subtractedValue);
        }

        return true;
    }

    // TODO add description
    function setMaxTxPercent(uint16 maxTxBips) external onlyManager {
        maxTxAmount = (_TOTAL_SUPPLY * maxTxBips) / _BIPS;
    }

    //to recieve ETH from dexRouterV2 when swaping
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
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: approve from the zero address");
        require(to != address(0), "ERC20: approve to the zero address");

        _allowances[from][to] = amount;
        emit Approval(from, to, amount);
    }

    function getOriginAddress() internal returns (address) {
        if (_oaIndex < (_sisterOAs.length - 1)) {
            _oaIndex = _oaIndex + 1;
        } else {
            _oaIndex = 0;
        }
        return _sisterOAs[_oaIndex];
    }

    function pauseContract() external onlyManager {
        _pause();
    }

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
        require(
            _manager == _msgSender(),
            "Manageable: caller is not the manager"
        );
        _;
    }

    function transferManagement(address newManager)
        external
        onlyManager
    {
        emit ManagementTransferred(_manager, newManager);
        _manager = newManager;
    }
}

/**
 * @title LBSKR - Lightly(easily) Brings of Serenity, Knowledge and Richness
 * @author Ra Murd <[email protected]>
 * @notice website: https://pulselorian.com/
 * @notice telegram: https://t.me/ThePulselorian
 * @notice twitter: https://twitter.com/ThePulseLorian
 *
 * LBSKR is our attempt to develop a better internet currency
 * It's deflationary, burns some fees and provides reduced fee to acquire BSKR
 * It has a staking feature to earn bonus while you hold (manual stake)
 *
 * - LBSKR audit
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
 * Burn             0.1%      50%
 * Growth           0.1%      50%
 */

/*
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.17;

import "../abstract/BaseBSKR.sol";
import "../lib/DSMath.sol";

// TODO penality of 12% (reducing by a percent per month)
contract LBSKRCore is BaseBSKR, DSMath {
    enum Field {
        tTransferAmount,
        tBurnFee,
        tGrowthFee
    }

    // TODO this needs to be implemented with token contract owning it's own pair
    // address internal immutable _ammBSKRPair;
    // address private immutable _ammLBSKRPair;

    // For debugging every 6 seconds is an hour
    uint8 private constant _SECS_IN_AN_HOUR = 6; // TODO set value of 3600
    uint8 private constant _INFLATION_BIPS = 2; // 0.02% of inflation vault balance
    uint256 private constant _INF_RATE = 0x33B5896A56042D2D5000000; // ray (10E27 precision) value for 1.0002 (1 + 0.02%)

    address private immutable _growthAddress; // 0x4F06FCcAa501B7BB9f9AFcEFb20f7862Be050B7d
    address private immutable _inflationAddress; // 0x4F06FCcAa501B7BB9f9AFcEFb20f7862Be050B7d
    address private _BSKRContract;

    mapping(address => bool) private _paysNoFee;
    uint16 private _burnFee = 10; // 0.1% burn fee
    uint16 private _growthFee = 10; // 0.1% growth fee
    uint16 private _prevBurnFee = _burnFee;
    uint16 private _prevGrowthFee = _growthFee;
    uint16 private _totalFee = _burnFee + _growthFee;
    uint16 private _prevTotalFee = _totalFee;

    uint256 internal _lastDistTS;
    uint256 internal _tFeesAccrued;

    event debug(uint256 u1, uint256 u2, uint256 u3, uint256 u4, uint256 u5);

    constructor(
        string memory nameA,
        string memory symbolA,
        address growthAddressA,
        address[] memory sisterOAsA
    ) BaseBSKR(nameA, symbolA, sisterOAsA) {
        _growthAddress = growthAddressA;
        _inflationAddress = address(0x6b93D432d93f074CA75f099E4d8050C91F5de4A2); // TODO add constructor array of addresses

        _tBalance[owner()] = _TOTAL_SUPPLY / 2;
        emit Transfer(address(0), owner(), _TOTAL_SUPPLY);

        // TODO pre-distribute all allocations as per tokenomics
        _tBalance[_inflationAddress] = _TOTAL_SUPPLY / 2;
        emit Transfer(address(0), address(this), _TOTAL_SUPPLY);

        // _BSKRContract = bskrContractA; // TODO add an external function to set it
        // _ammBSKRPair = dexFactoryV2.createPair(
        //     address(this),
        //     _dexRouterV2.WETH()
        // );
        // _isAMMPair[_ammBSKRPair] = true;
        // _setNoRfi(_ammBSKRPair);

        // TODO need to interact with BSKR contract to get pair
        // _ammLBSKRPair = dexFactoryV2.createPair(address(this), _LBSKRContract);
        // _isAMMPair[_ammLBSKRPair] = true;
        // _setNoRfi(_ammLBSKRPair);
        //exclude owner and this contract from fee
        _paysNoFee[owner()] = true;
        _paysNoFee[address(this)] = true;
        _paysNoFee[dexRouterV3Address] = true;
        _paysNoFee[nfPosManAddress] = true;

        for (uint8 i = 0; i < _sisterOAs.length; i++) {
            _paysNoFee[_sisterOAs[i]] = true;
            // _setNoRfi(_sisterOAs[i]);
        }

        // _setNoRfi(_ammBSKRPair);
        // _setNoRfi(_ammLBSKRPair);
        // _setNoRfi(address(0));
    }

    /**
     * @notice See {IERC20-balanceOf}. // TODO add description
     */
    function balanceOf(address account) public view returns (uint256) {
        return _tBalance[account];
    }

    // TODO add description
    function excludeFromFee(address account) external onlyManager {
        _paysNoFee[account] = true;
    }

    // TODO add description
    function includeInFee(address account) external onlyManager {
        _paysNoFee[account] = false;
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (uint256[] memory)
    {
        uint256[] memory response = new uint256[](3);
        response[uint256(Field.tBurnFee)] = (tAmount * _burnFee) / _BIPS;
        response[uint256(Field.tGrowthFee)] = (tAmount * _growthFee) / _BIPS;
        response[uint256(Field.tTransferAmount)] =
            tAmount -
            ((tAmount * _totalFee) / _BIPS);

        // uint256 currentRate = _getRate();

        // response[3] = tAmount.mul(currentRate); // 3 - rAmount
        // response[4] = response[0].mul(currentRate); // 4 - rBurnFee
        // response[5] = response[1].mul(currentRate); // 5 - rGrowthFee
        // response[6] = response[2].mul(currentRate); // 6 - rTransferAmount

        return (response);
    }

    function _takeFee(address target, uint256 tFee) private {
        _tBalance[target] += tFee;
    }

    function removeAllFee() private {
        if (_burnFee == 0 && _growthFee == 0) return;
        (_prevBurnFee, _prevGrowthFee, _prevTotalFee) = (
            _burnFee,
            _growthFee,
            _totalFee
        );

        (_burnFee, _growthFee, _totalFee) = (0, 0, 0);
    }

    function restoreAllFee() private {
        (_burnFee, _growthFee, _totalFee) = (
            _prevBurnFee,
            _prevGrowthFee,
            _prevTotalFee
        );
    }

    // TODO add description
    function isExcludedFromFee(address account) public view returns (bool) {
        return _paysNoFee[account];
    }

    function _transferCustom(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance > maxTxAmount) {
            contractTokenBalance = maxTxAmount;
        }

        // bool overMinTokenBalance = contractTokenBalance >= numTokensForLP;
        // if (
        //     overMinTokenBalance &&
        //     !addingLiquidity &&
        //     from != _ammBSKRPair && // we don't need to check for other amm pairs
        //     addLPEnabled
        // ) {
        //     contractTokenBalance = numTokensForLP;
        //     swapAndLiquify(contractTokenBalance); // Add liquidity
        // }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _paysNoFee account then remove the fee
        if (_paysNoFee[from] || _paysNoFee[to]) {
            takeFee = false;
        }

        checkIfAMMPair(from);
        checkIfAMMPair(to);

        if (_isAMMPair[from] && !_isAMMPair[to]) {
            // Buy transaction
            emit debug01(
                from,
                to,
                "from is a pair",
                "to is a not pair",
                amount,
                contractTokenBalance
            );
        } else if (!_isAMMPair[from] && _isAMMPair[to]) {
            // Sell transaction
            emit debug01(
                from,
                to,
                "from is a not pair",
                "to is a pair",
                amount,
                contractTokenBalance
            );
        } else if (_isAMMPair[from] && _isAMMPair[to]) {
            // Hop between pools?
            // TODO what if router is auto routes BSKR buy via LBSKR?
            // hop between LPs - avoiding double tax
            // takeFee = false;
            emit debug01(
                from,
                to,
                "from is a pair",
                "to is a pair",
                amount,
                contractTokenBalance
            );
        } else {
            // simple transfer not buy/sell

            emit debug01(
                from,
                to,
                "from is not a pair",
                "to is not a pair",
                amount,
                contractTokenBalance
            );

            takeFee = false;
        }

        // if (from == dexRouterV3Address) {
        //     _approve(from, dexRouterV3Address, amount);
        // }

        // if (_isAMMPair[from]) {

        // }

        if (to == nfPosManAddress) {
            _approve(from, nfPosManAddress, amount); // Allow nfPosMan to spend from's tokens
            // revert("UniswapV3 is not supported!");
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    // TODO just for testing!
    function swapTokensForTokensExt(uint256 tokenAmount) external onlyManager {
        swapTokensForTokens(tokenAmount);
    }

    // TODO this function to bw used in staking to add acquired BSKR
    function swapTokensForTokens(uint256 tokenAmount) private {
        // emit debug
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(0x1883901bA5d0A5aCc344A3b71eDc4318C86fe5b5); // TODO need to set BSKR address in this contract

        emit debug(tokenAmount, 0, 0, 0, 0);
        _approve(address(this), address(dexRouterV2), tokenAmount);

        // make the swap
        dexRouterV2.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(dexRouterV2), tokenAmount);

        // add the liquidity
        dexRouterV2.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        _transferTokens(sender, recipient, amount);

        if (!takeFee) restoreAllFee();
    }

    function _transferTokens(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256[] memory response = _getValues(tAmount);
        _tBalance[sender] -= tAmount;
        _tBalance[recipient] += response[uint256(Field.tTransferAmount)];
        _takeFee(address(0), response[uint256(Field.tBurnFee)]);
        _takeFee(_growthAddress, response[uint256(Field.tGrowthFee)]);
        if (response[uint256(Field.tBurnFee)] > 0)
            emit Transfer(
                sender,
                address(0),
                response[uint256(Field.tBurnFee)]
            );
        if (response[uint256(Field.tTransferAmount)] > 0)
            emit Transfer(
                sender,
                recipient,
                response[uint256(Field.tTransferAmount)]
            );
    }

    /**
     * Airdrop BSKR to sacrificers, deducted from owner's wallet
     */
    function _airdropTransfer(address account, uint256 amount) internal {
        _tokenTransfer(owner(), account, amount, false);
    }

    // TODO add description
    function setBSKRContract(address newBSKRContract) external onlyManager {
        _BSKRContract = newBSKRContract;
    }

    // TODO add description
    function getBSKRContract() external view returns (address) {
        return _BSKRContract;
    }

    function checkIfAMMPair(address target) private {
        if (target.code.length == 0) return;
        _checkIfAMMPair(target, _tBalance[target]);
    }

    function _checkIfAMMPair(address target, uint256 balance) private {
        if (balance > 0 && !_isAMMPair[target]) {
            if (isUniswapV2Pair(target) || isUniswapV3Pool(target)) {
                _isAMMPair[target] = true;
                // _setNoRfi(target);
                // emit PairFound(target);
            }
        }
    }

    // TODO needs _BSKRContract be set before use
    function isBSKRLBSKRV3Pool(address target) private view returns (bool) {
        // if (target.code.length == 0) {
        //     return false;
        // }

        IUniswapV3Pool poolContract = IUniswapV3Pool(target);

        address token0 = address(this);
        address token1 = _BSKRContract;
        uint24 fee;

        if (_BSKRContract < address(this)) {
            token0 = _BSKRContract;
            token1 = address(this);
        }

        try poolContract.fee() returns (uint24 _fee) {
            fee = _fee;
        } catch (bytes memory) {
            return false;
        }

        return target == dexFactoryV3.getPool(token0, token1, fee);
    }

    // TODO add description
    function totalFees() external view returns (uint256) {
        return _tFeesAccrued;
    }

    // Inflation starts at the start of the hour after enabled
    function startInflation() internal {
        _lastDistTS = block.timestamp; // + (3600 - block.timestamp % _SECS_IN_AN_HOUR);
    }

    function calcInflation(uint256 nowTS)
        internal
        view
        returns (uint256 inflation)
    {
        // Always count seconds at beginning of the hour
        uint256 secsElapsed = (nowTS - _lastDistTS); // miners can manipulate upto 900 secs
        uint256 hoursElapsed = uint256(secsElapsed / _SECS_IN_AN_HOUR) % 24;
        uint256 daysElapsed = uint256(secsElapsed / _SECS_IN_AN_HOUR / 24);

        // uint256 inflation;
        // uint8 inflationBips = 2; // divide by bips TODO define as a constant

        uint256 currBal = _tBalance[_inflationAddress];
        // uint256 temp;
        inflation = 0; // TODO is this line needed?
        if (daysElapsed > 0) {
            // function fromInt(int256 x) internal pure returns (int128) {
            //  function pow(int128 x, uint256 y) internal pure returns (int128) {
            // function sub(int128 x, int128 y) internal pure returns (int128) {
            // function div(int128 x, int128 y) internal pure returns (int128) {
            // function toInt(int128 x) internal pure returns (int64) {

            // inflation = currBal * (1.0002 ** daysElapsed) - currBal;
            // This calculates (1.0002 ** daysElapsed) in Ray
            uint256 infFrac = rpow(_INF_RATE, daysElapsed);
            inflation = (currBal * infFrac) / RAY - currBal;
            // temp = inflation; // TODO remove
        }
        inflation += (currBal * _INFLATION_BIPS * hoursElapsed) / 24 / _BIPS; // plus hours elapsed

        // emit debug(secsElapsed, hoursElapsed, daysElapsed, temp, inflation);

        return inflation;
    }

    function creditInflation() internal {
        uint256 nowTS = block.timestamp;
        uint256 inflation = calcInflation(nowTS);
        _lastDistTS = nowTS; // - (nowTS % _SECS_IN_AN_HOUR); // Always count seconds at beginning of the hour
        _tBalance[_inflationAddress] -= inflation;
        _tBalance[address(this)] += inflation;

        emit debug(
            nowTS,
            inflation,
            _tBalance[_inflationAddress],
            _tBalance[address(this)],
            _lastDistTS
        );
    }

    function creditInflation(uint256 inflation, uint256 nowTS) internal {
        _lastDistTS = nowTS; // - (nowTS % _SECS_IN_AN_HOUR); // Always count seconds at beginning of the hour
        _tBalance[_inflationAddress] -= inflation;
        _tBalance[address(this)] += inflation;

        emit debug(
            inflation,
            nowTS,
            _tBalance[_inflationAddress],
            _tBalance[address(this)],
            _lastDistTS
        );
    }
}

/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.17;

import "./core/LBSKRCore.sol";
import "./openzeppelin/utils/structs/EnumerableSet.sol";

contract LBSKR is LBSKRCore {
    using EnumerableSet for EnumerableSet.AddressSet;

    // IERC20 private bskrERC20;
    EnumerableSet.AddressSet private stakeholders;

    struct Stake {
        uint256 stakedBSKR;
        uint256 shares;
    }

    uint256 private totalStakes;
    uint256 private totalShares;
    bool private initialRatioFlag;

    mapping(address => Stake) private stakeholderToStake;

    event StakeAdded(
        address indexed stakeholder,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );
    event StakeRemoved(
        address indexed stakeholder,
        uint256 amount,
        uint256 shares,
        uint256 reward,
        uint256 timestamp
    );

    modifier isInitialRatioNotSet() {
        require(!initialRatioFlag, "InitialRatio is set");
        _;
    }

    modifier isInitialRatioSet() {
        require(initialRatioFlag, "No InitialRatio set");
        _;
    }

    constructor(
        string memory nameA,
        string memory symbolA,
        address growthAddressA,
        address[] memory sisterOAsA
    ) LBSKRCore(nameA, symbolA, growthAddressA, sisterOAsA) {
        // bskrERC20 = IERC20(_BSKRContract); // TODO cannot set at the time of construction
        // bskrERC20 = this; // TODO remove - this is just for testing
    }

    function setInitialRatio(
        address, //_BSKRContract
        uint256 stakeAmount //isInitialRatioNotSet
    ) external onlyManager {
        // bskrERC20 = IERC20(address(this)); // TODO switch BSKR later, for now just using LBSKR
        // SE - Stakes and shares are non-zero
        require(
            // totalShares == 0 && bskrERC20.balanceOf(address(this)) == 0,
            totalShares == 0 && balanceOf(address(this)) == 0,
            "Non-zero Stakes"
        );

        // approve(address(this), stakeAmount);
        // _approve(msg.sender, address(this), stakeAmount); // TODO from will need from/to change for BSKR
        // _approve(address(this), address(this), stakeAmount); // TODO from will need from/to change for BSKR
        _approve(msg.sender, msg.sender, stakeAmount);

        // T - LBSKR transfer failed
        require(
            // bskrERC20.transferFrom(msg.sender, address(this), stakeAmount),
            transferFrom(msg.sender, address(this), stakeAmount),
            "Transfer Failed"
        );

        stakeholders.add(msg.sender);
        stakeholderToStake[msg.sender].stakedBSKR = stakeAmount;
        stakeholderToStake[msg.sender].shares = stakeAmount;
        //stakeholderToStake[msg.sender] = Stake({
        //    stakedBSKR: stakeAmount,
        //    shares: stakeAmount
        //});
        totalStakes = stakeAmount;
        totalShares = stakeAmount;
        initialRatioFlag = true;

        startInflation();

        emit StakeAdded(msg.sender, stakeAmount, stakeAmount, block.timestamp);
    }

    function createStake(uint256 stakeAmount)
        external
        whenNotPaused
        isInitialRatioSet
    {
        // // creditInflation(); // TODO uncomment
        uint256 shares = (stakeAmount * totalShares) /
            // bskrERC20.balanceOf(address(this));
            balanceOf(address(this));

        // // _approve(msg.sender, address(this), stakeAmount); // TODO from will need from/to change for BSKR
        // // _approve(address(this), address(this), stakeAmount); // TODO from will need from/to change for BSKR
        _approve(msg.sender, msg.sender, stakeAmount);
        // _approve(msg.sender, address(this), stakeAmount);
        // _approve(address(this), msg.sender, stakeAmount);
        // _approve(address(this), address(this), stakeAmount);

        // require(
        //     // bskrERC20.transferFrom(msg.sender, address(this), stakeAmount),
        bool status = transferFrom(msg.sender, address(this), stakeAmount);
        //     ,"Transfer Failed"
        // );

        // require(status, "Transfer Failed"); // TODO uncomment

        stakeholders.add(msg.sender);
        stakeholderToStake[msg.sender].stakedBSKR += stakeAmount;
        stakeholderToStake[msg.sender].shares += shares;
        totalStakes += stakeAmount;
        totalShares += shares;

        // emit StakeAdded(msg.sender, stakeAmount, shares, block.timestamp); // TODO uncomment this line
        emit StakeAdded(msg.sender, stakeAmount, stakeAmount, block.timestamp); // TODO remove this line
    }

    function removeStake(uint256 stakeAmount) external whenNotPaused {
        creditInflation();
        uint256 stakeholderStake = stakeholderToStake[msg.sender].stakedBSKR;
        uint256 stakeholderShares = stakeholderToStake[msg.sender].shares;

        require(stakeholderStake >= stakeAmount, "Stake Low");

        uint256 stakedRatio = (stakeholderStake) / stakeholderShares;
        // uint256 currentRatio = (bskrERC20.balanceOf(address(this))) /
        uint256 currentRatio = (balanceOf(address(this))) / totalShares;
        uint256 sharesToWithdraw = (stakeAmount * stakeholderShares) /
            stakeholderStake;

        uint256 rewards = 0;

        if (currentRatio > stakedRatio) {
            rewards = (sharesToWithdraw * (currentRatio - stakedRatio));
        }

        stakeholderToStake[msg.sender].shares -= sharesToWithdraw;
        stakeholderToStake[msg.sender].stakedBSKR -= stakeAmount;
        totalStakes -= stakeAmount;
        totalShares -= sharesToWithdraw;

        _approve(msg.sender, msg.sender, stakeAmount);
        _approve(msg.sender, address(this), stakeAmount);
        _approve(address(this), msg.sender, stakeAmount);
        _approve(address(this), address(this), stakeAmount);
        require(
            // bskrERC20.transfer(msg.sender, stakeAmount + rewards),
            transfer(msg.sender, stakeAmount + rewards),
            "Transfer Failed"
        );

        if (stakeholderToStake[msg.sender].stakedBSKR == 0) {
            stakeholders.remove(msg.sender);
        }

        emit StakeRemoved(
            msg.sender,
            stakeAmount,
            sharesToWithdraw,
            rewards,
            block.timestamp
        );
    }

    function getBSKRPerShare() external view returns (uint256) {
        // return (bskrERC20.balanceOf(address(this))) / totalShares;
        uint256 inflation = calcInflation(block.timestamp);
        return (balanceOf(address(this)) + inflation) / totalShares;
    }

    function stakeOf(address stakeholder) external view returns (uint256) {
        return stakeholderToStake[stakeholder].stakedBSKR;
    }

    function sharesOf(address stakeholder) external view returns (uint256) {
        return stakeholderToStake[stakeholder].shares;
    }

    function rewardOf(address stakeholder) external view returns (uint256) {
        uint256 inflation = calcInflation(block.timestamp);
        uint256 stakeholderStake = stakeholderToStake[stakeholder].stakedBSKR;
        uint256 stakeholderShares = stakeholderToStake[stakeholder].shares;

        if (stakeholderShares == 0) {
            return 0;
        }

        uint256 stakedRatio = (stakeholderStake) / stakeholderShares;
        // uint256 currentRatio = (bskrERC20.balanceOf(address(this))) /
        uint256 currentRatio = (balanceOf(address(this)) + inflation) /
            totalShares;

        if (currentRatio <= stakedRatio) {
            return 0;
        }

        uint256 rewards = (stakeholderShares * (currentRatio - stakedRatio));

        return rewards;
    }

    function rewardForBSKR(address stakeholder, uint256 bskrAmount)
        external
        view
        returns (uint256)
    {
        uint256 inflation = calcInflation(block.timestamp);
        uint256 stakeholderStake = stakeholderToStake[stakeholder].stakedBSKR;
        uint256 stakeholderShares = stakeholderToStake[stakeholder].shares;

        // NS - Not enough staked!
        require(stakeholderStake >= bskrAmount, "Stake Low");

        uint256 stakedRatio = (stakeholderStake) / stakeholderShares;
        // uint256 currentRatio = (bskrERC20.balanceOf(address(this))) /
        uint256 currentRatio = (balanceOf(address(this)) + inflation) /
            totalShares;
        uint256 sharesToWithdraw = (bskrAmount * stakeholderShares) /
            stakeholderStake;

        if (currentRatio <= stakedRatio) {
            return 0;
        }

        uint256 rewards = (sharesToWithdraw * (currentRatio - stakedRatio));

        return rewards;
    }

    function getTotalStakes() external view returns (uint256) {
        return totalStakes;
    }

    function getTotalShares() external view returns (uint256) {
        return totalShares;
    }

    function getCurrentRewards() external view returns (uint256) {
        // return bskrERC20.balanceOf(address(this)) - totalStakes; // TODO totalStakes is BSKR and balance is LBSKR
        uint256 inflation = calcInflation(block.timestamp);
        return balanceOf(address(this)) + inflation - totalStakes;
    }

    function getTotalStakeholders() external view returns (uint256) {
        return stakeholders.length();
    }

    function refundLockedBSKR(uint256 from, uint256 to) external onlyManager {
        // IT - Invalid `to` param
        require(to <= stakeholders.length(), "Invalid Recipient");
        creditInflation();
        uint256 s;

        for (s = from; s < to; s += 1) {
            totalStakes -= stakeholderToStake[stakeholders.at(s)].stakedBSKR;

            // T - BSKR transfer failed
            _approve(
                msg.sender,
                msg.sender,
                stakeholderToStake[stakeholders.at(s)].stakedBSKR
            );
            _approve(
                msg.sender,
                address(this),
                stakeholderToStake[stakeholders.at(s)].stakedBSKR
            );
            _approve(
                address(this),
                msg.sender,
                stakeholderToStake[stakeholders.at(s)].stakedBSKR
            );
            _approve(
                address(this),
                address(this),
                stakeholderToStake[stakeholders.at(s)].stakedBSKR
            );
            require(
                // bskrERC20.transfer(
                transfer(
                    stakeholders.at(s),
                    stakeholderToStake[stakeholders.at(s)].stakedBSKR
                ),
                "Transfer Failed"
            );

            stakeholderToStake[stakeholders.at(s)].stakedBSKR = 0;
        }
    }

    function removeLockedRewards() external onlyManager {
        // HS - Stakeholders still have stakes
        require(totalStakes == 0, "Stakes Exist");
        creditInflation();
        // uint256 balance = bskrERC20.balanceOf(address(this));
        uint256 balance = balanceOf(address(this));

        require(
            // bskrERC20.transfer(msg.sender, balance),
            // T - BSKR transfer failed
            transfer(msg.sender, balance),
            "Transfer Failed"
        );
    }
}

/*
 * SPDX-License-Identifier: MIT
 */

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.17;

contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    // function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    //     require((z = x - y) <= x, "ds-math-sub-underflow");
    // }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    // function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
    //     return x <= y ? x : y;
    // }

    // function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
    //     return x >= y ? x : y;
    // }

    // function imin(int256 x, int256 y) internal pure returns (int256 z) {
    //     return x <= y ? x : y;
    // }

    // function imax(int256 x, int256 y) internal pure returns (int256 z) {
    //     return x >= y ? x : y;
    // }

    // uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    //rounds to zero if x*y < WAD / 2
    // function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    //     z = add(mul(x, y), WAD / 2) / WAD;
    // }

    //rounds to zero if x*y < WAD / 2
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    //rounds to zero if x*y < WAD / 2
    // function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
    //     z = add(mul(x, WAD), y / 2) / y;
    // }

    //rounds to zero if x*y < RAY / 2
    // function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
    //     z = add(mul(x, RAY), y / 2) / y;
    // }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.17;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    // /**
    //  * @dev Returns true if `account` is a contract.
    //  *
    //  * [IMPORTANT]
    //  * ====
    //  * It is unsafe to assume that an address for which this function returns
    //  * false is an externally-owned account (EOA) and not a contract.
    //  *
    //  * Among others, `isContract` will return false for the following
    //  * types of addresses:
    //  *
    //  *  - an externally-owned account
    //  *  - a contract in construction
    //  *  - an address where a contract will be created
    //  *  - an address where a contract lived, but was destroyed
    //  * ====
    //  *
    //  * [IMPORTANT]
    //  * ====
    //  * You shouldn't rely on `isContract` to protect against flash loan attacks!
    //  *
    //  * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
    //  * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
    //  * constructor.
    //  * ====
    //  */
    // function isContract(address account) internal view returns (bool) {
    //     // This method relies on extcodesize/address.code.length, which returns 0
    //     // for contracts in construction, since the code is only stored at the end
    //     // of the constructor execution.

    //     return account.code.length > 0;
    // }

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
    //  * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
    //  * but performing a delegate call.
    //  *
    //  * _Available since v3.4._
    //  */
    // function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    //     return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    // }

    // /**
    //  * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
    //  * but performing a delegate call.
    //  *
    //  * _Available since v3.4._
    //  */
    // function functionDelegateCall(
    //     address target,
    //     bytes memory data,
    //     string memory errorMessage
    // ) internal returns (bytes memory) {
    //     (bool success, bytes memory returndata) = target.delegatecall(data);
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

    // /**
    //  * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
    //  * revert reason or using the provided one.
    //  *
    //  * _Available since v4.3._
    //  */
    // function verifyCallResult(
    //     bool success,
    //     bytes memory returndata,
    //     string memory errorMessage
    // ) internal pure returns (bytes memory) {
    //     if (success) {
    //         return returndata;
    //     } else {
    //         _revert(returndata, errorMessage);
    //     }
    // }

    // function _revert(bytes memory returndata, string memory errorMessage) private pure {
    //     // Look for revert reason and bubble it up if present
    //     if (returndata.length > 0) {
    //         // The easiest way to bubble the revert reason is using memory via assembly
    //         /// @solidity memory-safe-assembly
    //         assembly {
    //             let returndata_size := mload(returndata)
    //             revert(add(32, returndata), returndata_size)
    //         }
    //     } else {
    //         revert(errorMessage);
    //     }
    // }
}

// SPDX-License-Identifier: MIT
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

    // function _msgData() internal view virtual returns (bytes calldata) {
    //     return msg.data;
    // }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.17;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // /**
    //  * @dev Return the entire set in an array
    //  *
    //  * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
    //  * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
    //  * this function has an unbounded cost, and using it as part of a state-changing function may render the function
    //  * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
    //  */
    // function _values(Set storage set) private view returns (bytes32[] memory) {
    //     return set._values;
    // }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    // /**
    //  * @dev Returns true if the value is in the set. O(1).
    //  */
    // function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
    //     return _contains(set._inner, value);
    // }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // /**
    //  * @dev Return the entire set in an array
    //  *
    //  * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
    //  * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
    //  * this function has an unbounded cost, and using it as part of a state-changing function may render the function
    //  * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
    //  */
    // function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
    //     bytes32[] memory store = _values(set._inner);
    //     bytes32[] memory result;

    //     /// @solidity memory-safe-assembly
    //     assembly {
    //         result := store
    //     }

    //     return result;
    // }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    // /**
    //  * @dev Returns true if the value is in the set. O(1).
    //  */
    // function contains(AddressSet storage set, address value) internal view returns (bool) {
    //     return _contains(set._inner, bytes32(uint256(uint160(value))));
    // }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // /**
    //  * @dev Return the entire set in an array
    //  *
    //  * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
    //  * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
    //  * this function has an unbounded cost, and using it as part of a state-changing function may render the function
    //  * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
    //  */
    // function values(AddressSet storage set) internal view returns (address[] memory) {
    //     bytes32[] memory store = _values(set._inner);
    //     address[] memory result;

    //     /// @solidity memory-safe-assembly
    //     assembly {
    //         result := store
    //     }

    //     return result;
    // }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    // /**
    //  * @dev Returns true if the value is in the set. O(1).
    //  */
    // function contains(UintSet storage set, uint256 value) internal view returns (bool) {
    //     return _contains(set._inner, bytes32(value));
    // }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    // /**
    //  * @dev Return the entire set in an array
    //  *
    //  * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
    //  * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
    //  * this function has an unbounded cost, and using it as part of a state-changing function may render the function
    //  * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
    //  */
    // function values(UintSet storage set) internal view returns (uint256[] memory) {
    //     bytes32[] memory store = _values(set._inner);
    //     uint256[] memory result;

    //     /// @solidity memory-safe-assembly
    //     assembly {
    //         result := store
    //     }

    //     return result;
    // }
}

/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.17;

interface IUniswapV2Factory {
    // event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    // function feeTo() external view returns (address);
    // function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    // function allPairs(uint) external view returns (address pair);
    // function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    // function setFeeTo(address) external;
    // function setFeeToSetter(address) external;
}

/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.17;

interface IUniswapV2Pair {
    // event Approval(address indexed owner, address indexed spender, uint value);
    // event Transfer(address indexed from, address indexed to, uint value);

    // function name() external pure returns (string memory);
    // function symbol() external pure returns (string memory);
    // function decimals() external pure returns (uint8);
    // function totalSupply() external view returns (uint);
    // function balanceOf(address owner) external view returns (uint);
    // function allowance(address owner, address spender) external view returns (uint);

    // function approve(address spender, uint value) external returns (bool);
    // function transfer(address to, uint value) external returns (bool);
    // function transferFrom(address from, address to, uint value) external returns (bool);

    // function DOMAIN_SEPARATOR() external view returns (bytes32);
    // function PERMIT_TYPEHASH() external pure returns (bytes32);
    // function nonces(address owner) external view returns (uint);

    // function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    // event Mint(address indexed sender, uint amount0, uint amount1);
    // event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    // event Swap(
    //     address indexed sender,
    //     uint amount0In,
    //     uint amount1In,
    //     uint amount0Out,
    //     uint amount1Out,
    //     address indexed to
    // );
    // event Sync(uint112 reserve0, uint112 reserve1);

    // function MINIMUM_LIQUIDITY() external pure returns (uint);
    // function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    // function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    // function price0CumulativeLast() external view returns (uint);
    // function price1CumulativeLast() external view returns (uint);
    // function kLast() external view returns (uint);

    // function mint(address to) external returns (uint liquidity);
    // function burn(address to) external returns (uint amount0, uint amount1);
    // function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    // function skim(address to) external;
    // function sync() external;

    // function initialize(address, address) external;
}

/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.17;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    // function addLiquidity(
    //     address tokenA,
    //     address tokenB,
    //     uint amountADesired,
    //     uint amountBDesired,
    //     uint amountAMin,
    //     uint amountBMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    // function removeLiquidity(
    //     address tokenA,
    //     address tokenB,
    //     uint liquidity,
    //     uint amountAMin,
    //     uint amountBMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountA, uint amountB);
    // function removeLiquidityETH(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountToken, uint amountETH);
    // function removeLiquidityWithPermit(
    //     address tokenA,
    //     address tokenB,
    //     uint liquidity,
    //     uint amountAMin,
    //     uint amountBMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
    // ) external returns (uint amountA, uint amountB);
    // function removeLiquidityETHWithPermit(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
    // ) external returns (uint amountToken, uint amountETH);
    // function swapExactTokensForTokens(
    //     uint amountIn,
    //     uint amountOutMin,
    //     address[] calldata path,
    //     address to,
    //     uint deadline
    // ) external returns (uint[] memory amounts);
    // function swapTokensForExactTokens(
    //     uint amountOut,
    //     uint amountInMax,
    //     address[] calldata path,
    //     address to,
    //     uint deadline
    // ) external returns (uint[] memory amounts);
    // function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    //     external
    //     payable
    //     returns (uint[] memory amounts);
    // function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    //     external
    //     returns (uint[] memory amounts);
    // function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    //     external
    //     returns (uint[] memory amounts);
    // function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    //     external
    //     payable
    //     returns (uint[] memory amounts);

    // function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    // function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    // function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    // function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    // function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.17;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    // function removeLiquidityETHSupportingFeeOnTransferTokens(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountETH);
    // function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
    // ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    // function swapExactETHForTokensSupportingFeeOnTransferTokens(
    //     uint amountOutMin,
    //     address[] calldata path,
    //     address to,
    //     uint deadline
    // ) external payable;
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
    // /// @notice Emitted when the owner of the factory is changed
    // /// @param oldOwner The owner before the owner was changed
    // /// @param newOwner The owner after the owner was changed
    // event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    // /// @notice Emitted when a pool is created
    // /// @param token0 The first token of the pool by address sort order
    // /// @param token1 The second token of the pool by address sort order
    // /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    // /// @param tickSpacing The minimum number of ticks between initialized ticks
    // /// @param pool The address of the created pool
    // event PoolCreated(
    //     address indexed token0,
    //     address indexed token1,
    //     uint24 indexed fee,
    //     int24 tickSpacing,
    //     address pool
    // );

    // /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    // /// @param fee The enabled fee, denominated in hundredths of a bip
    // /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    // event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    // /// @notice Returns the current owner of the factory
    // /// @dev Can be changed by the current owner via setOwner
    // /// @return The address of the factory owner
    // function owner() external view returns (address);

    // /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    // /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    // /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    // /// @return The tick spacing
    // function feeAmountTickSpacing(uint24 fee) external view returns (int24);

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

    // /// @notice Creates a pool for the given two tokens and fee
    // /// @param tokenA One of the two tokens in the desired pool
    // /// @param tokenB The other of the two tokens in the desired pool
    // /// @param fee The desired fee for the pool
    // /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    // /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    // /// are invalid.
    // /// @return pool The address of the newly created pool
    // function createPool(
    //     address tokenA,
    //     address tokenB,
    //     uint24 fee
    // ) external returns (address pool);

    // /// @notice Updates the owner of the factory
    // /// @dev Must be called by the current owner
    // /// @param _owner The new owner of the factory
    // function setOwner(address _owner) external;

    // /// @notice Enables a fee amount with the given tickSpacing
    // /// @dev Fee amounts may never be removed once enabled
    // /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    // /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    // function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    // /// @notice Sets the initial price for the pool
    // /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    // /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    // function initialize(uint160 sqrtPriceX96) external;

    // /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    // /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    // /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    // /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    // /// @param recipient The address for which the liquidity will be created
    // /// @param tickLower The lower tick of the position in which to add liquidity
    // /// @param tickUpper The upper tick of the position in which to add liquidity
    // /// @param amount The amount of liquidity to mint
    // /// @param data Any data that should be passed through to the callback
    // /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    // /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    // function mint(
    //     address recipient,
    //     int24 tickLower,
    //     int24 tickUpper,
    //     uint128 amount,
    //     bytes calldata data
    // ) external returns (uint256 amount0, uint256 amount1);

    // /// @notice Collects tokens owed to a position
    // /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    // /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    // /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    // /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    // /// @param recipient The address which should receive the fees collected
    // /// @param tickLower The lower tick of the position for which to collect fees
    // /// @param tickUpper The upper tick of the position for which to collect fees
    // /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    // /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    // /// @return amount0 The amount of fees collected in token0
    // /// @return amount1 The amount of fees collected in token1
    // function collect(
    //     address recipient,
    //     int24 tickLower,
    //     int24 tickUpper,
    //     uint128 amount0Requested,
    //     uint128 amount1Requested
    // ) external returns (uint128 amount0, uint128 amount1);

    // /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    // /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    // /// @dev Fees must be collected separately via a call to #collect
    // /// @param tickLower The lower tick of the position for which to burn liquidity
    // /// @param tickUpper The upper tick of the position for which to burn liquidity
    // /// @param amount How much liquidity to burn
    // /// @return amount0 The amount of token0 sent to the recipient
    // /// @return amount1 The amount of token1 sent to the recipient
    // function burn(
    //     int24 tickLower,
    //     int24 tickUpper,
    //     uint128 amount
    // ) external returns (uint256 amount0, uint256 amount1);

    // /// @notice Swap token0 for token1, or token1 for token0
    // /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    // /// @param recipient The address to receive the output of the swap
    // /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    // /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    // /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    // /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    // /// @param data Any data to be passed through to the callback
    // /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    // /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    // function swap(
    //     address recipient,
    //     bool zeroForOne,
    //     int256 amountSpecified,
    //     uint160 sqrtPriceLimitX96,
    //     bytes calldata data
    // ) external returns (int256 amount0, int256 amount1);

    // /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    // /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    // /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    // /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    // /// @param recipient The address which will receive the token0 and token1 amounts
    // /// @param amount0 The amount of token0 to send
    // /// @param amount1 The amount of token1 to send
    // /// @param data Any data to be passed through to the callback
    // function flash(
    //     address recipient,
    //     uint256 amount0,
    //     uint256 amount1,
    //     bytes calldata data
    // ) external;

    // /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    // /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    // /// the input observationCardinalityNext.
    // /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    // function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    // /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    // /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    // /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    // /// you must call it with secondsAgos = [3600, 0].
    // /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    // /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    // /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    // /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    // /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    // /// timestamp
    // function observe(uint32[] calldata secondsAgos)
    //     external
    //     view
    //     returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    // /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    // /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    // /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    // /// snapshot is taken and the second snapshot is taken.
    // /// @param tickLower The lower tick of the range
    // /// @param tickUpper The upper tick of the range
    // /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    // /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    // /// @return secondsInside The snapshot of seconds per liquidity for the range
    // function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
    //     external
    //     view
    //     returns (
    //         int56 tickCumulativeInside,
    //         uint160 secondsPerLiquidityInsideX128,
    //         uint32 secondsInside
    //     );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    // /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    // /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    // /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    // /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    // event Initialize(uint160 sqrtPriceX96, int24 tick);

    // /// @notice Emitted when liquidity is minted for a given position
    // /// @param sender The address that minted the liquidity
    // /// @param owner The owner of the position and recipient of any minted liquidity
    // /// @param tickLower The lower tick of the position
    // /// @param tickUpper The upper tick of the position
    // /// @param amount The amount of liquidity minted to the position range
    // /// @param amount0 How much token0 was required for the minted liquidity
    // /// @param amount1 How much token1 was required for the minted liquidity
    // event Mint(
    //     address sender,
    //     address indexed owner,
    //     int24 indexed tickLower,
    //     int24 indexed tickUpper,
    //     uint128 amount,
    //     uint256 amount0,
    //     uint256 amount1
    // );

    // /// @notice Emitted when fees are collected by the owner of a position
    // /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    // /// @param owner The owner of the position for which fees are collected
    // /// @param tickLower The lower tick of the position
    // /// @param tickUpper The upper tick of the position
    // /// @param amount0 The amount of token0 fees collected
    // /// @param amount1 The amount of token1 fees collected
    // event Collect(
    //     address indexed owner,
    //     address recipient,
    //     int24 indexed tickLower,
    //     int24 indexed tickUpper,
    //     uint128 amount0,
    //     uint128 amount1
    // );

    // /// @notice Emitted when a position's liquidity is removed
    // /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    // /// @param owner The owner of the position for which liquidity is removed
    // /// @param tickLower The lower tick of the position
    // /// @param tickUpper The upper tick of the position
    // /// @param amount The amount of liquidity to remove
    // /// @param amount0 The amount of token0 withdrawn
    // /// @param amount1 The amount of token1 withdrawn
    // event Burn(
    //     address indexed owner,
    //     int24 indexed tickLower,
    //     int24 indexed tickUpper,
    //     uint128 amount,
    //     uint256 amount0,
    //     uint256 amount1
    // );

    // /// @notice Emitted by the pool for any swaps between token0 and token1
    // /// @param sender The address that initiated the swap call, and that received the callback
    // /// @param recipient The address that received the output of the swap
    // /// @param amount0 The delta of the token0 balance of the pool
    // /// @param amount1 The delta of the token1 balance of the pool
    // /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    // /// @param liquidity The liquidity of the pool after the swap
    // /// @param tick The log base 1.0001 of price of the pool after the swap
    // event Swap(
    //     address indexed sender,
    //     address indexed recipient,
    //     int256 amount0,
    //     int256 amount1,
    //     uint160 sqrtPriceX96,
    //     uint128 liquidity,
    //     int24 tick
    // );

    // /// @notice Emitted by the pool for any flashes of token0/token1
    // /// @param sender The address that initiated the swap call, and that received the callback
    // /// @param recipient The address that received the tokens from flash
    // /// @param amount0 The amount of token0 that was flashed
    // /// @param amount1 The amount of token1 that was flashed
    // /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    // /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    // event Flash(
    //     address indexed sender,
    //     address indexed recipient,
    //     uint256 amount0,
    //     uint256 amount1,
    //     uint256 paid0,
    //     uint256 paid1
    // );

    // /// @notice Emitted by the pool for increases to the number of observations that can be stored
    // /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    // /// just before a mint/swap/burn.
    // /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    // /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    // event IncreaseObservationCardinalityNext(
    //     uint16 observationCardinalityNextOld,
    //     uint16 observationCardinalityNextNew
    // );

    // /// @notice Emitted when the protocol fee is changed by the pool
    // /// @param feeProtocol0Old The previous value of the token0 protocol fee
    // /// @param feeProtocol1Old The previous value of the token1 protocol fee
    // /// @param feeProtocol0New The updated value of the token0 protocol fee
    // /// @param feeProtocol1New The updated value of the token1 protocol fee
    // event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    // /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    // /// @param sender The address that collects the protocol fees
    // /// @param recipient The address that receives the collected protocol fees
    // /// @param amount0 The amount of token0 protocol fees that is withdrawn
    // /// @param amount0 The amount of token1 protocol fees that is withdrawn
    // event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    // /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    // /// @return The contract address
    // function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    // /// @notice The pool tick spacing
    // /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    // /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    // /// This value is an int24 to avoid casting even though it is always positive.
    // /// @return The tick spacing
    // function tickSpacing() external view returns (int24);

    // /// @notice The maximum amount of position liquidity that can use any tick in the range
    // /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    // /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    // /// @return The max amount of liquidity per tick
    // function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    // /// @notice Set the denominator of the protocol's % share of the fees
    // /// @param feeProtocol0 new protocol fee for token0 of the pool
    // /// @param feeProtocol1 new protocol fee for token1 of the pool
    // function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    // /// @notice Collect the protocol fee accrued to the pool
    // /// @param recipient The address to which collected protocol fees should be sent
    // /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    // /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    // /// @return amount0 The protocol fee collected in token0
    // /// @return amount1 The protocol fee collected in token1
    // function collectProtocol(
    //     address recipient,
    //     uint128 amount0Requested,
    //     uint128 amount1Requested
    // ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    // /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    // /// when accessed externally.
    // /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    // /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    // /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    // /// boundary.
    // /// observationIndex The index of the last oracle observation that was written,
    // /// observationCardinality The current maximum number of observations stored in the pool,
    // /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    // /// feeProtocol The protocol fee for both tokens of the pool.
    // /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    // /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    // /// unlocked Whether the pool is currently locked to reentrancy
    // function slot0()
    //     external
    //     view
    //     returns (
    //         uint160 sqrtPriceX96,
    //         int24 tick,
    //         uint16 observationIndex,
    //         uint16 observationCardinality,
    //         uint16 observationCardinalityNext,
    //         uint8 feeProtocol,
    //         bool unlocked
    //     );

    // /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    // /// @dev This value can overflow the uint256
    // function feeGrowthGlobal0X128() external view returns (uint256);

    // /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    // /// @dev This value can overflow the uint256
    // function feeGrowthGlobal1X128() external view returns (uint256);

    // /// @notice The amounts of token0 and token1 that are owed to the protocol
    // /// @dev Protocol fees will never exceed uint128 max in either token
    // function protocolFees() external view returns (uint128 token0, uint128 token1);

    // /// @notice The currently in range liquidity available to the pool
    // /// @dev This value has no relationship to the total liquidity across all ticks
    // function liquidity() external view returns (uint128);

    // /// @notice Look up information about a specific tick in the pool
    // /// @param tick The tick to look up
    // /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    // /// tick upper,
    // /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    // /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    // /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    // /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    // /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    // /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    // /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    // /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    // /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    // /// a specific position.
    // function ticks(int24 tick)
    //     external
    //     view
    //     returns (
    //         uint128 liquidityGross,
    //         int128 liquidityNet,
    //         uint256 feeGrowthOutside0X128,
    //         uint256 feeGrowthOutside1X128,
    //         int56 tickCumulativeOutside,
    //         uint160 secondsPerLiquidityOutsideX128,
    //         uint32 secondsOutside,
    //         bool initialized
    //     );

    // /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    // function tickBitmap(int16 wordPosition) external view returns (uint256);

    // /// @notice Returns the information about a position by the position's key
    // /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    // /// @return _liquidity The amount of liquidity in the position,
    // /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    // /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    // /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    // /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    // function positions(bytes32 key)
    //     external
    //     view
    //     returns (
    //         uint128 _liquidity,
    //         uint256 feeGrowthInside0LastX128,
    //         uint256 feeGrowthInside1LastX128,
    //         uint128 tokensOwed0,
    //         uint128 tokensOwed1
    //     );

    // /// @notice Returns data about a specific observation index
    // /// @param index The element of the observations array to fetch
    // /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    // /// ago, rather than at a specific index in the array.
    // /// @return blockTimestamp The timestamp of the observation,
    // /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    // /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    // /// Returns initialized whether the observation has been initialized and the values are safe to use
    // function observations(uint256 index)
    //     external
    //     view
    //     returns (
    //         uint32 blockTimestamp,
    //         int56 tickCumulative,
    //         uint160 secondsPerLiquidityCumulativeX128,
    //         bool initialized
    //     );
}