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

import "./uniswap/v2-core/interfaces/IUniswapV2Factory.sol";
import "./uniswap/v2-core/interfaces/IUniswapV2Pair.sol";
import "./uniswap/v2-periphery/interfaces/IUniswapV2Router02.sol";
import "./uniswap/v3-core/interfaces/IUniswapV3Factory.sol";
import "./uniswap/v3-core/interfaces/IUniswapV3Pool.sol";
import "./abstract/Manageable.sol";
import "./openzeppelin/token/ERC20/IERC20.sol";
import "./openzeppelin/access/Ownable.sol";
import "./openzeppelin/security/Pausable.sol";

// TODO optimize gas usage on remix and also resolve linter identified issues
contract BSKR is IERC20, Ownable, Manageable, Pausable {
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
        RfiFee,
        BurnFee,
        GrowthFee,
        PaydayFee,
        LPFee,
        TotalFee
    }

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private constant _DECIMALS = 18;

    uint16[] private curr = [uint16(200), 150, 100, 50, 200, 550];
    uint16[] private prev = new uint16[](6);

    IUniswapV2Router02 public immutable dexRouterV2;
    IUniswapV2Factory internal immutable dexFactoryV2;
    IUniswapV3Factory internal immutable dexFactoryV3;
    address internal immutable dexRouterV3Address; // SwapRouter
    address internal immutable nfPosManAddress; // NonfungiblePositionManager
    mapping(address => bool) internal _isAMMPair;
    address public immutable _ammBSKRPair;
    address public immutable _ammLBSKRPair;

    bool public addLPEnabled = true;

    uint256 private constant MAX = ~uint256(0);
    // uint256 private constant _TOTAL_SUPPLY = (10 ** 12) * (10 ** _DECIMALS); // TODO 1 trillion for PulseChain
    uint256 private constant _TOTAL_SUPPLY = (10**9) * (10**_DECIMALS); // 1 billion for Goerli
    uint16 private constant _BIPS = 10**4; // bips or basis point divisor

    uint256 public maxTxAmount = _TOTAL_SUPPLY / 25; // 4% of the total supply

    address[] private _noRfi;

    bool private addingLiquidity;

    mapping(address => bool) private _getsNoRfi;
    mapping(address => bool) private _paysNoFee;
    mapping(address => uint256) private _rBalances;

    uint256 private _rTotal = (MAX - (MAX % _TOTAL_SUPPLY));
    uint256 private numTokensForLP = _TOTAL_SUPPLY / 2000; // 0.05% of the total supply

    uint256 private _tFeesAccrued;

    address[] internal _sisterOAs;
    uint8 private _oaIndex;

    address private immutable _growthAddress; // 0x4F06FCcAa501B7BB9f9AFcEFb20f7862Be050B7d
    address private immutable _paydayAddress; // 0x13D44474B125B5582A42a826035A99e38a4962A7
    address private _LBSKRContract;

    // TODO remove debug events
    event debug01(
        address a1,
        address a2,
        string s1,
        string s2,
        uint256 u1,
        uint256 u2
    );

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    // event PairFound(address pair);

    modifier swapInProgress() {
        addingLiquidity = true;
        _;
        addingLiquidity = false;
    }

    constructor(
        string memory nameA,
        string memory symbolA,
        address growthAddressA,
        address paydayAddressA,
        address lbskrContractA,
        address[] memory sisterOAsA
    ) {
        _name = nameA;
        _symbol = symbolA;
	_growthAddress = growthAddressA;
        _paydayAddress = paydayAddressA;
        _LBSKRContract = lbskrContractA;
        _sisterOAs = sisterOAsA;
	_rBalances[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _TOTAL_SUPPLY);


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


        _ammBSKRPair = dexFactoryV2.createPair(
            address(this),
            dexRouterV2.WETH()
        );
        _isAMMPair[_ammBSKRPair] = true;
        _setNoRfi(_ammBSKRPair);

        _ammLBSKRPair = dexFactoryV2.createPair(address(this), _LBSKRContract);
        _isAMMPair[_ammLBSKRPair] = true;
        _setNoRfi(_ammLBSKRPair);

        //exclude owner and this contract from fee
        _paysNoFee[owner()] = true;
        _paysNoFee[address(this)] = true;
        _paysNoFee[dexRouterV3Address] = true;
        _paysNoFee[nfPosManAddress] = true;

        for (uint8 i = 0; i < _sisterOAs.length; i++) {
            _paysNoFee[_sisterOAs[i]] = true;
            _setNoRfi(_sisterOAs[i]);
        }

        _setNoRfi(_paydayAddress);
        _setNoRfi(_ammBSKRPair);
        _setNoRfi(_ammLBSKRPair);
        _setNoRfi(address(0));
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

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance > maxTxAmount) {
            contractTokenBalance = maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >= numTokensForLP;
        if (
            overMinTokenBalance &&
            !addingLiquidity &&
            from != _ammBSKRPair && // we don't need to check for other amm pairs
            addLPEnabled
        ) {
            contractTokenBalance = numTokensForLP;
            swapAndLiquify(contractTokenBalance); // Add liquidity
        }

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
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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

    /**
     * @notice See {IERC20-balanceOf}. // TODO add description
     */
    function balanceOf(address account) public view override returns (uint256) {
        if (_getsNoRfi[account]) return _balances[account];
        return tokenFromReflection(_rBalances[account]);
    }

    // TODO add description
    function excludeFromReward(address account) public onlyManager {
        require(!_getsNoRfi[account], "Excluded Account");
        if (_rBalances[account] > 0) {
            _balances[account] = tokenFromReflection(_rBalances[account]);
        }
        _setNoRfi(account);
    }

    function _setNoRfi(address account) private {
        _getsNoRfi[account] = true;
        _noRfi.push(account);
    }

    // TODO add description
    function isExcludedFromReward(address account) public view returns (bool) {
        return _getsNoRfi[account];
    }

    // TODO add description
    function excludeFromFee(address account) public onlyManager {
        _paysNoFee[account] = true;
    }

    // TODO add description
    function bestowReflection(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_getsNoRfi[sender], "Excluded Account");
        uint256[] memory response = _getValues(tAmount, false);
        _rBalances[sender] -= response[uint8(Field.rAmount)];
        _rTotal -= response[uint8(Field.rAmount)];
        _tFeesAccrued += tAmount;
    }

    // TODO add description
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _TOTAL_SUPPLY, "Amount too high");
        if (!deductTransferFee) {
            uint256[] memory response = _getValues(tAmount, false);
            return response[uint8(Field.rAmount)];
        } else {
            uint256[] memory response = _getValues(tAmount, false);
            return response[uint8(Field.rTransferAmount)];
        }
    }

    // TODO add description
    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(rAmount <= _rTotal, "Amount too high");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    // TODO add description
    function includeInReward(address account) external onlyManager {
        require(_getsNoRfi[account], "Excluded Account");
        for (uint256 i = 0; i < _noRfi.length; i++) {
            if (_noRfi[i] == account) {
                _noRfi[i] = _noRfi[_noRfi.length - 1];
                _balances[account] = 0;
                _getsNoRfi[account] = false;
                _noRfi.pop();
                break;
            }
        }
    }

    // TODO add description
    function includeInFee(address account) public onlyManager {
        _paysNoFee[account] = false;
    }

    // TODO add description
    function setRfiFeePercent(uint16 newRfiBips) external onlyManager {
        // _rfiFee = newRfiBips;
        curr[uint8(Fees.RfiFee)] = newRfiBips;
    }

    // TODO add description
    function setLPFeePercent(uint16 newLPBips) external onlyManager {
        // _lpFee = newLPBips;
        curr[uint8(Fees.LPFee)] = newLPBips;
    }

    // TODO add description
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyManager {
        addLPEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function _reflectFee(uint256 tFee, uint256 rFee) private {
        _rTotal -= rFee;
        _tFeesAccrued += tFee;
    }

    function _getValues(uint256 tAmount, bool reducedFees)
        private
        view
        returns (uint256[] memory)
    {
        uint8 feeDiv = 1;
        if (reducedFees) {
            feeDiv = 2;
        }

        uint256[] memory response = new uint256[](13);
        response[uint8(Field.tRfiFee)] =
            (tAmount * curr[uint8(Fees.RfiFee)]) /
            feeDiv /
            _BIPS;
        response[uint8(Field.tBurnFee)] =
            (tAmount * curr[uint8(Fees.BurnFee)]) /
            feeDiv /
            _BIPS;
        response[uint8(Field.tGrowthFee)] =
            (tAmount * curr[uint8(Fees.GrowthFee)]) /
            feeDiv /
            _BIPS;
        response[uint8(Field.tPaydayFee)] =
            (tAmount * curr[uint8(Fees.PaydayFee)]) /
            feeDiv /
            _BIPS;
        response[uint8(Field.tLPFee)] =
            (tAmount * curr[uint8(Fees.LPFee)]) /
            feeDiv /
            _BIPS;
        response[uint8(Field.tTransferAmount)] =
            tAmount -
            ((tAmount * curr[uint8(Fees.TotalFee)]) / feeDiv / _BIPS);

        uint256 currentRate = _getRate();

        response[uint8(Field.rAmount)] = (tAmount * currentRate);
        response[uint8(Field.rRfiFee)] = (response[uint8(Field.tRfiFee)] *
            currentRate);
        response[uint8(Field.rBurnFee)] = (response[uint8(Field.tBurnFee)] *
            currentRate);
        response[uint8(Field.rGrowthFee)] = (response[uint8(Field.tGrowthFee)] *
            currentRate);
        response[uint8(Field.rPaydayFee)] = (response[uint8(Field.tPaydayFee)] *
            currentRate);
        response[uint8(Field.rLPFee)] = (response[uint8(Field.tLPFee)] *
            currentRate);
        response[uint8(Field.rTransferAmount)] = (response[
            uint8(Field.tTransferAmount)
        ] * currentRate);

        return (response);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _TOTAL_SUPPLY;
        for (uint256 i = 0; i < _noRfi.length; i++) {
            if (
                _rBalances[_noRfi[i]] > rSupply || _balances[_noRfi[i]] > tSupply
            ) return (_rTotal, _TOTAL_SUPPLY);
            rSupply -= _rBalances[_noRfi[i]];
            tSupply -= _balances[_noRfi[i]];
        }
        if (rSupply < _rTotal / _TOTAL_SUPPLY) return (_rTotal, _TOTAL_SUPPLY);
        return (rSupply, tSupply);
    }

    function _takeFee(
        address target,
        uint256 tFee,
        uint256 rFee
    ) private {
        _rBalances[target] += rFee;
        if (_getsNoRfi[target]) _balances[target] += tFee;
    }

    function removeAllFee() private {
        if (
            curr[uint8(Fees.RfiFee)] == 0 &&
            curr[uint8(Fees.BurnFee)] == 0 &&
            curr[uint8(Fees.GrowthFee)] == 0 &&
            curr[uint8(Fees.PaydayFee)] == 0 &&
            curr[uint8(Fees.LPFee)] == 0
        ) return;

        (
            prev[uint8(Fees.RfiFee)],
            prev[uint8(Fees.BurnFee)],
            prev[uint8(Fees.GrowthFee)],
            prev[uint8(Fees.PaydayFee)],
            prev[uint8(Fees.PaydayFee)],
            prev[uint8(Fees.TotalFee)]
        ) = (
            curr[uint8(Fees.RfiFee)],
            curr[uint8(Fees.BurnFee)],
            curr[uint8(Fees.GrowthFee)],
            curr[uint8(Fees.PaydayFee)],
            curr[uint8(Fees.PaydayFee)],
            curr[uint8(Fees.TotalFee)]
        );

        (
            curr[uint8(Fees.RfiFee)],
            curr[uint8(Fees.BurnFee)],
            curr[uint8(Fees.GrowthFee)],
            curr[uint8(Fees.PaydayFee)],
            curr[uint8(Fees.PaydayFee)],
            curr[uint8(Fees.TotalFee)]
        ) = (0, 0, 0, 0, 0, 0);
    }

    function restoreAllFee() private {
        (
            curr[uint8(Fees.RfiFee)],
            curr[uint8(Fees.BurnFee)],
            curr[uint8(Fees.GrowthFee)],
            curr[uint8(Fees.PaydayFee)],
            curr[uint8(Fees.PaydayFee)],
            curr[uint8(Fees.TotalFee)]
        ) = (
            prev[uint8(Fees.RfiFee)],
            prev[uint8(Fees.BurnFee)],
            prev[uint8(Fees.GrowthFee)],
            prev[uint8(Fees.PaydayFee)],
            prev[uint8(Fees.PaydayFee)],
            prev[uint8(Fees.TotalFee)]
        );
    }

    // TODO add description
    // function isExcludedFromFee(address account) public view returns (bool) {
    //     return _paysNoFee[account];
    // }

    function swapAndLiquify(uint256 contractTokenBalance)
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
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouterV2.WETH();

        // dexFactoryV2.getPair(token0, token1)  // TODO may be we need to find the pair and approve as well
        _approve(address(this), address(dexRouterV2), tokenAmount);

        // make the swap
        dexRouterV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            // dexRouterV2.swapExactTokensForETH(
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

        if (_getsNoRfi[sender] && !_getsNoRfi[recipient]) {
            _transferTokens(sender, recipient, amount, true, false);
        } else if (!_getsNoRfi[sender] && _getsNoRfi[recipient]) {
            _transferTokens(sender, recipient, amount, false, true);
        } else if (_getsNoRfi[sender] && _getsNoRfi[recipient]) {
            _transferTokens(sender, recipient, amount, true, true);
        } else {
            _transferTokens(sender, recipient, amount, false, false);
        }

        if (!takeFee) restoreAllFee();
    }

    function _transferTokens(
        address sender,
        address recipient,
        uint256 tAmount,
        bool senderExcluded,
        bool recipientExcluded
    ) private {
        bool reducedFees = false;
        if (
            sender == _ammLBSKRPair ||
            recipient == _ammLBSKRPair ||
            isBSKRLBSKRV3Pool(sender) ||
            isBSKRLBSKRV3Pool(recipient)
        ) {
            reducedFees = true;
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
        _reflectFee(
            response[uint8(Field.tRfiFee)],
            response[uint8(Field.rRfiFee)]
        );
        _takeFee(
            address(0),
            response[uint8(Field.tBurnFee)],
            response[uint8(Field.rBurnFee)]
        );
        _takeFee(
            _growthAddress,
            response[uint8(Field.tGrowthFee)],
            response[uint8(Field.rGrowthFee)]
        );
        _takeFee(
            _paydayAddress,
            response[uint8(Field.tPaydayFee)],
            response[uint8(Field.rPaydayFee)]
        );
        _takeFee(
            address(this),
            response[uint8(Field.tLPFee)],
            response[uint8(Field.rLPFee)]
        );

        if (response[uint8(Field.tBurnFee)] > 0)
            emit Transfer(sender, address(0), response[uint8(Field.tBurnFee)]);
        if (response[uint8(Field.tPaydayFee)] > 0)
            emit Transfer(
                sender,
                _paydayAddress,
                response[uint8(Field.tPaydayFee)]
            );
        if (response[uint8(Field.tTransferAmount)] > 0)
            emit Transfer(
                sender,
                recipient,
                response[uint8(Field.tTransferAmount)]
            );
    }

    /**
     * Airdrop BSKR to sacrificers, deducted from owner's wallet
     */
    function _airdropTransfer(address account, uint256 amount) internal {
        _tokenTransfer(owner(), account, amount, false);
    }

    // TODO add description
    function setLBSKRContract(address newLBSKRContract) external onlyManager {
        _LBSKRContract = newLBSKRContract;
    }

    // TODO add description
    function getLBSKRContract() external view returns (address) {
        return _LBSKRContract;
    }

    function checkIfAMMPair(address target) private {
        if (target.code.length == 0) return;
        if (_getsNoRfi[target]) {
            _checkIfAMMPair(target, _balances[target]);
        } else {
            _checkIfAMMPair(target, _rBalances[target]);
        }
    }

    function _checkIfAMMPair(address target, uint256 balance) private {
        if (balance > 0 && !_isAMMPair[target]) {
            if (isUniswapV2Pair(target) || isUniswapV3Pool(target)) {
                _isAMMPair[target] = true;
                _setNoRfi(target);
                // emit PairFound(target);
            }
        }
    }

    function isBSKRLBSKRV3Pool(address target) private view returns (bool) {
        if (target.code.length == 0) {
            return false;
        }

        IUniswapV3Pool poolContract = IUniswapV3Pool(target);

        address token0 = address(this);
        address token1 = _LBSKRContract;
        uint24 fee;

        if (_LBSKRContract < address(this)) {
            token0 = _LBSKRContract;
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
    function totalFees() public view returns (uint256) {
        return _tFeesAccrued;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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