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

    /**
     * @notice Transfers the management of the contract to a new manager
     */
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

import "./abstract/Manageable.sol";
import "./lib/DSMath.sol";
import "./openzeppelin/access/Ownable.sol";
import "./openzeppelin/security/Pausable.sol";
import "./openzeppelin/token/ERC20/IERC20.sol";
import "./openzeppelin/utils/structs/EnumerableSet.sol";
import "./uniswap/v2-core/interfaces/IUniswapV2Factory.sol";
import "./uniswap/v2-core/interfaces/IUniswapV2Pair.sol";
import "./uniswap/v2-periphery/interfaces/IUniswapV2Router02.sol";
import "./uniswap/v3-core/interfaces/IUniswapV3Factory.sol";
import "./uniswap/v3-core/interfaces/IUniswapV3Pool.sol";

// Uniswap addresses in play
// UniswapV2Pair: dynamic, created on demand for a pair
// UniswapV2Router02: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
// UniswapV2Factory: 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
// SwapRouter02: 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
// WETH9: 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6

// TODO add inflation from reserved _inflationVaultAddress
// TODO add restriction to _inflationVaultAddress such that only this contract can withdraw
// TODO Recalculate the Token allocations to sacrificers
// TODO add staking and unstaking

// TODO - adding liquidity is adding some to growth address
// TODO penality of 12% (reducing by a percent per month)
// TODO this needs to be implemented with token contract owning it's own pair

contract LBSKR is IERC20, Ownable, Manageable, Pausable, DSMath {
    using EnumerableSet for EnumerableSet.AddressSet;

    enum Field {
        tTransferAmount,
        tBurnFee,
        tGrowthFee
    }

    struct Stake {
        uint256 stakedBSKR;
        uint256 shares;
    }

    uint8 private constant _DECIMALS = 18;

    uint16 private constant _BIPS = 10**4; // bips or basis point divisor
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _INF_RATE = 0x33B5896A56042D2D5000000; // ray (10E27 precision) value for 1.0002 (1 + 0.02%)
    // uint256 private constant _TOTAL_SUPPLY = (10**12) * (10**_DECIMALS); // TODO 1 trillion for PulseChain
    uint256 private constant _TOTAL_SUPPLY = (10**9) * (10**_DECIMALS); // 1 billion for Goerli
    uint8 private constant _INFLATION_BIPS = 2; // 0.02% of inflation vault balance
    uint8 private constant _SECS_IN_AN_HOUR = 6; // TODO set value of 3600

    IUniswapV2Factory public immutable dexFactoryV2;
    IUniswapV2Router02 public immutable dexRouterV2;
    IUniswapV3Factory private immutable dexFactoryV3;
    address private immutable _growthAddress; // 0x4F06FCcAa501B7BB9f9AFcEFb20f7862Be050B7d
    address private immutable _inflationAddress; // 0x4F06FCcAa501B7BB9f9AFcEFb20f7862Be050B7d
    address private immutable dexRouterV3Address; // SwapRouter
    address private immutable nfPosManAddress; // NonfungiblePositionManager
    address public _ammBSKRPair; // TODO set this
    address public immutable _ammLBSKRPair;

    EnumerableSet.AddressSet private stakeholders;
    address private _BSKRContract;
    address[] public _sisterOAs; // TODO make private
    bool private initialRatioFlag;
    mapping(address => Stake) private stakeholderToStake;
    mapping(address => bool) private _isAMMPair;
    mapping(address => bool) private _paysNoFee;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
    string private _name;
    string private _symbol;
    uint16 private _burnFee = 10; // 0.1% burn fee
    uint16 private _growthFee = 10; // 0.1% growth fee
    uint16 private _prevBurnFee = _burnFee;
    uint16 private _prevGrowthFee = _growthFee;
    // uint16 private _grossFees = _burnFee + _growthFee;
    // uint16 private _prevGrossFees = _grossFees;
    uint256 private _lastDistTS;
    uint256 private totalShares;
    uint256 private totalStakes;
    // uint256 public maxTxAmount = _TOTAL_SUPPLY / 25; // 4% of the total supply
    uint8 private _oaIndex;

    // TODO remove debug events
    event debug01(
        address from,
        address to,
        string isFromPair,
        string isToPair,
        uint256 transferAmount,
        uint256 contractBal,
        bool doTakeFee,
        bool fromNoFee,
        bool toNoFee
    );

    event Log(string message);
    event LogBytes(bytes data);

    event debug(uint256 u1, uint256 u2, uint256 u3, uint256 u4, uint256 u5);

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

    event PairFound(address pair);
    event isAPair(address pair);
    event isNotAPair(address pair);

    event amounts(
        uint256 tTransferAmount,
        uint256 tBurnFee,
        uint256 tGrowthFee
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
    ) {
        _name = nameA;
        _symbol = symbolA;
        _growthAddress = growthAddressA;
        _inflationAddress = address(0x6b93D432d93f074CA75f099E4d8050C91F5de4A2); // TODO add constructor array of addresses
        _sisterOAs = sisterOAsA;

        // TODO pre-distribute all allocations as per tokenomics
        _balances[_msgSender()] = _TOTAL_SUPPLY / 2;
        emit Transfer(address(0), _msgSender(), _TOTAL_SUPPLY);

        _balances[_inflationAddress] = _TOTAL_SUPPLY / 2;
        emit Transfer(address(0), address(this), _TOTAL_SUPPLY);

        IUniswapV2Router02 _dexRouterV2 = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D // TODO constructor arg / set before deploy
        );
        dexRouterV2 = _dexRouterV2;
        dexFactoryV2 = IUniswapV2Factory(_dexRouterV2.factory());

        dexFactoryV3 = IUniswapV3Factory(
            address(0x1F98431c8aD98523631AE4a59f267346ea31F984) // TODO constructor arg / set before deploy
        );
        dexRouterV3Address = 0xE592427A0AEce92De3Edee1F18E0157C05861564; // TODO needed? constructor arg / set before deploy
        nfPosManAddress = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88; // TODO needed? constructor arg / set before deploy

        _ammLBSKRPair = dexFactoryV2.createPair(
            address(this),
            dexRouterV2.WETH()
        );
        _approve(_ammLBSKRPair, _ammLBSKRPair, MAX);
        _isAMMPair[_ammLBSKRPair] = true;

        // _ammBSKRPair = dexFactoryV2.createPair(address(this), _BSKRContract); // TODO move to where BSKR contract is set
        // _approve(_ammBSKRPair, _ammBSKRPair, MAX);
        // _isAMMPair[_ammBSKRPair] = true;

        // exclude owner and this contract from fee -- TODO do we need to add more?
        _paysNoFee[_msgSender()] = true;
        _paysNoFee[address(this)] = true;
        _paysNoFee[dexRouterV3Address] = true;
        _paysNoFee[nfPosManAddress] = true;

        for (uint8 i = 0; i < _sisterOAs.length; i++) {
            _paysNoFee[_sisterOAs[i]] = true;
        }

        // bskrERC20 = IERC20(_BSKRContract); // TODO cannot set at the time of construction
        // bskrERC20 = this; // TODO remove - this is just for testing
    }

    //to recieve ETH from dexRouterV2 when swaping
    receive() external payable {}

    fallback() external payable {}

    /**
     * Airdrop BSKR to sacrificers, deducted from owner's wallet
     */
    function _airdropTransfer(address account, uint256 amount) internal {
        _transferTokens(owner(), account, amount, false);
    }

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

    function _checkIfAMMPair(address target) private {
        if (target.code.length == 0) return;
        if (
            //_balances[target] > 0 && // TODO why do we need to check balance?
            !_isAMMPair[target]
        ) {
            emit isNotAPair(target);
            // if (isUniswapV2Pair(target) || isUniswapV3Pool(target)) { // TODO to be enabled later
            if (isUniswapV2Pair(target)) {
                // TODO removed v3 for now
                _isAMMPair[target] = true;
                emit PairFound(target);
            }
        } else {
            emit isAPair(target);
        }
    }

    function _getValues(uint256 tAmount)
        private
        // view TODO enable view
        returns (uint256[] memory)
    {
        uint256[] memory response = new uint256[](3);
        response[uint8(Field.tBurnFee)] = (tAmount * _burnFee) / _BIPS;
        response[uint8(Field.tGrowthFee)] = (tAmount * _growthFee) / _BIPS;
        response[uint8(Field.tTransferAmount)] =
            tAmount -
            response[uint8(Field.tBurnFee)] -
            response[uint8(Field.tGrowthFee)];
        // ((tAmount * _grossFees) / _BIPS);

        emit amounts(response[0], response[1], response[2]);

        return (response);
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

    function _takeFee(address target, uint256 tFee) private {
        _balances[target] += tFee;
    }

    //this method is responsible for taking all fee, if takeFee is true
    // function _tokenTransfer(
    //     address sender,
    //     address recipient,
    //     uint256 amount,
    //     bool takeFee
    // ) private {
    //     if (!takeFee) removeAllFee();

    //     _transferTokens(sender, recipient, amount);

    //   if (!takeFee) restoreAllFee();
    // }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        // if (from != owner() && to != owner())
        //     require(
        //         amount <= maxTxAmount,
        //         "Transfer amount exceeds the maxTxAmount."
        //     );

        // // addLPPairs();
        // emit Log("About to call _checkIfAMMPair for from & to");
        // _checkIfAMMPair(from);
        // _checkIfAMMPair(to);
        // emit Log("Called _checkIfAMMPair for both from & to");

        // // // is the token balance of this contract address over the min number of
        // // // tokens that we need to initiate a swap + liquidity lock?
        // // // also, don't get caught in a circular liquidity event.
        // // // also, don't swap & liquify if sender is uniswap pair.
        // uint256 contractTokenBalance = balanceOf(address(this));

        // // if (contractTokenBalance > maxTxAmount) {
        // //     contractTokenBalance = maxTxAmount;
        // // }

        // // bool overMinTokenBalance = contractTokenBalance >= numTokensForLP;
        // // if (
        // //     overMinTokenBalance &&
        // //     !addingLiquidity &&
        // //     from != _ammBSKRPair && // we don't need to check for other amm pairs
        // //     addLPEnabled
        // // ) {
        // //     contractTokenBalance = numTokensForLP;
        // //     swapAndLiquify(contractTokenBalance); // Add liquidity
        // // }

        // //indicates if fee should be deducted from transfer
        // bool takeFee = true;

        // //if any account belongs to _paysNoFee account then remove the fee
        // if (_paysNoFee[from] || _paysNoFee[to]) {
        //     takeFee = false;
        // }

        // if (_isAMMPair[from] && !_isAMMPair[to]) {
        //     // Buy transaction
        //     emit debug01(
        //         from,
        //         to,
        //         "from is a pair",
        //         "to is a not pair",
        //         amount,
        //         contractTokenBalance,
        //         takeFee,
        //         _paysNoFee[from],
        //         _paysNoFee[to]
        //     );
        // } else if (!_isAMMPair[from] && _isAMMPair[to]) {
        //     // Sell transaction
        //     emit debug01(
        //         from,
        //         to,
        //         "from is a not pair",
        //         "to is a pair",
        //         amount,
        //         contractTokenBalance,
        //         takeFee,
        //         _paysNoFee[from],
        //         _paysNoFee[to]
        //     );
        // } else if (_isAMMPair[from] && _isAMMPair[to]) {
        //     // Hop between pools?
        //     // TODO what if router is auto routes BSKR buy via LBSKR?
        //     // hop between LPs - avoiding double tax
        //     takeFee = false;
        //     emit debug01(
        //         from,
        //         to,
        //         "from is a pair",
        //         "to is a pair",
        //         amount,
        //         contractTokenBalance,
        //         takeFee,
        //         _paysNoFee[from],
        //         _paysNoFee[to]
        //     );
        // } else {
        //     // simple transfer not buy/sell

        //     emit debug01(
        //         from,
        //         to,
        //         "from is not a pair",
        //         "to is not a pair",
        //         amount,
        //         contractTokenBalance,
        //         takeFee,
        //         _paysNoFee[from],
        //         _paysNoFee[to]
        //     );

        //     takeFee = false;
        // }

        // if (to == nfPosManAddress) {
        //     _approve(from, nfPosManAddress, amount); // Allow nfPosMan to spend from's tokens
        //     // revert("UniswapV3 is not supported!");
        // }

        //transfer amount, it will take tax, burn, liquidity fee
        // _transferTokens(from, to, amount, takeFee);
         _transferTokens(from, to, amount, false); // disabled fees for testing
    }

    function _transferTokens(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        uint256[] memory response = _getValues(tAmount);
        _balances[sender] -= tAmount;
        _balances[recipient] += response[uint8(Field.tTransferAmount)];
        _takeFee(address(0), response[uint8(Field.tBurnFee)]);
        _takeFee(_growthAddress, response[uint8(Field.tGrowthFee)]);
        if (response[uint8(Field.tBurnFee)] > 0)
            emit Transfer(sender, address(0), response[uint8(Field.tBurnFee)]);
        // if (response[uint8(Field.tTransferAmount)] > 0)
        emit Transfer(
            sender,
            recipient,
            response[uint8(Field.tTransferAmount)]
        );

        if (!takeFee) restoreAllFee();
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
     * @notice See {IERC20-balanceOf}. // TODO add description
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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

        uint256 currBal = _balances[_inflationAddress];
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

    // function checkIfAMMPair(address target) private {
    //     if (target.code.length == 0) return;
    //     _checkIfAMMPair(target, _balances[target]);
    // }

    /**
     * @notice Create a new stake
     */
    function createStake(uint256 stakeAmount)
        external
        whenNotPaused
        isInitialRatioSet
    {
        creditInflation(); // TODO uncomment
        uint256 shares = (stakeAmount * totalShares) /
            // bskrERC20.balanceOf(address(this));
            balanceOf(address(this));

        // // _approve(_msgSender(), address(this), stakeAmount); // TODO from will need from/to change for BSKR
        // // _approve(address(this), address(this), stakeAmount); // TODO from will need from/to change for BSKR
        // _approve(_msgSender(), _msgSender(), stakeAmount);
        // _approve(_msgSender(), address(this), stakeAmount);
        // _approve(address(this), _msgSender(), stakeAmount);
        // _approve(address(this), address(this), stakeAmount);

        // require(
        //     // bskrERC20.transferFrom(_msgSender(), address(this), stakeAmount),
        bool status = transferFrom(_msgSender(), address(this), stakeAmount);
        //     ,"Transfer Failed"
        // );

        require(status, "Transfer Failed"); // TODO uncomment

        stakeholders.add(_msgSender());
        stakeholderToStake[_msgSender()].stakedBSKR += stakeAmount;
        stakeholderToStake[_msgSender()].shares += shares;
        totalStakes += stakeAmount;
        totalShares += shares;

        // emit StakeAdded(_msgSender(), stakeAmount, shares, block.timestamp); // TODO uncomment this line
        emit StakeAdded(
            _msgSender(),
            stakeAmount,
            stakeAmount,
            block.timestamp
        ); // TODO remove this line
    }

    function creditInflation() internal {
        uint256 nowTS = block.timestamp;
        uint256 inflation = calcInflation(nowTS);
        _lastDistTS = nowTS; // - (nowTS % _SECS_IN_AN_HOUR); // Always count seconds at beginning of the hour
        _balances[_inflationAddress] -= inflation;
        _balances[address(this)] += inflation;

        emit debug(
            nowTS,
            inflation,
            _balances[_inflationAddress],
            _balances[address(this)],
            _lastDistTS
        );
    }

    function creditInflation(uint256 inflation, uint256 nowTS) internal {
        _lastDistTS = nowTS; // - (nowTS % _SECS_IN_AN_HOUR); // Always count seconds at beginning of the hour
        _balances[_inflationAddress] -= inflation;
        _balances[address(this)] += inflation;

        emit debug(
            inflation,
            nowTS,
            _balances[_inflationAddress],
            _balances[address(this)],
            _lastDistTS
        );
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
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @notice Waives off fees for an address -- TODO probably we do not need this
     */
    // function excludeFromFee(address account) public onlyManager {
    //     _paysNoFee[account] = true;
    // }

    /**
     * @notice Returns the registered BSKR contract address
     */
    function getBSKRContract() external view returns (address) {
        return _BSKRContract;
    }

    /**
     * @notice Returns the amount of BSKR per share
     */
    function getBSKRPerShare() external view returns (uint256) {
        // return (bskrERC20.balanceOf(address(this))) / totalShares;
        uint256 inflation = calcInflation(block.timestamp);
        return (balanceOf(address(this)) + inflation) / totalShares;
    }

    /**
     * @notice Returns the current accumulated LBSKR rewards
     */
    function getCurrentRewards() external view returns (uint256) {
        // return bskrERC20.balanceOf(address(this)) - totalStakes; // TODO totalStakes is BSKR and balance is LBSKR
        uint256 inflation = calcInflation(block.timestamp);
        return balanceOf(address(this)) + inflation - totalStakes;
    }

    function getOriginAddress() internal returns (address) {
        if (_oaIndex < (_sisterOAs.length - 1)) {
            _oaIndex = _oaIndex + 1;
        } else {
            _oaIndex = 0;
        }
        return _sisterOAs[_oaIndex];
    }

    /**
     * @notice Returns the total number of shares
     */
    function getTotalShares() external view returns (uint256) {
        return totalShares;
    }

    /**
     * @notice Returns the total number of stake holders
     */
    function getTotalStakeholders() external view returns (uint256) {
        return stakeholders.length();
    }

    /**
     * @notice Returns the total number of stakes
     */
    function getTotalStakes() external view returns (uint256) {
        return totalStakes;
    }

    /**
     * @notice Makes an account responsible for fees --  TODO do we need this?
     */
    // function includeInFee(address account) public onlyManager {
    //     _paysNoFee[account] = false;
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

    // TODO needs _BSKRContract be set before use, revert?
    function isBSKRLBSKRV3Pool(address target) private view returns (bool) {
        // if (target.code.length == 0) {
        //     return false;
        // }
        if (target == _ammBSKRPair || target == _ammLBSKRPair) return false; // TODO this hasn't worked yet

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

    /**
     * @notice Checks if an account is excluded from fees - TODO do we need this?
     */
    // function isExcludedFromFee(address account) public view returns (bool) {
    //     return _paysNoFee[account];
    // }

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

    // function isUniswapV3Pool(address target) internal view returns (bool) {
    //     // if (target.code.length == 0) {
    //     //     return false;
    //     // }

    //     IUniswapV3Pool poolContract = IUniswapV3Pool(target);

    //     address token0;
    //     address token1;
    //     uint24 fee;

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

    //     return target == dexFactoryV3.getPool(token0, token1, fee);
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
     * @notice Refunds the locked BSKR
     */
    function refundLockedBSKR(uint256 from, uint256 to) external onlyManager {
        // IT - Invalid `to` param
        require(to <= stakeholders.length(), "Invalid Recipient");
        creditInflation();
        uint256 s;

        for (s = from; s < to; s += 1) {
            totalStakes -= stakeholderToStake[stakeholders.at(s)].stakedBSKR;

            // T - BSKR transfer failed
            // _approve(
            //     _msgSender(),
            //     _msgSender(),
            //     stakeholderToStake[stakeholders.at(s)].stakedBSKR
            // );
            // _approve(
            //     _msgSender(),
            //     address(this),
            //     stakeholderToStake[stakeholders.at(s)].stakedBSKR
            // );
            // _approve(
            //     address(this),
            //     _msgSender(),
            //     stakeholderToStake[stakeholders.at(s)].stakedBSKR
            // );
            // _approve(
            //     address(this),
            //     address(this),
            //     stakeholderToStake[stakeholders.at(s)].stakedBSKR
            // );
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

    function removeAllFee() private {
        if (_burnFee == 0 && _growthFee == 0) return;

        (
            _prevBurnFee,
            _prevGrowthFee
            // , _prevGrossFees
        ) = (
            _burnFee,
            _growthFee
            // , _grossFees
        );

        (
            _burnFee,
            _growthFee
            // , _grossFees
        ) = (
            0,
            0
            // , 0
        );
    }

    /**
     * @notice Removes the locked rewards
     */
    function removeLockedRewards() external onlyManager {
        // HS - Stakeholders still have stakes
        require(totalStakes == 0, "Stakes Exist");
        creditInflation();
        // uint256 balance = bskrERC20.balanceOf(address(this));
        uint256 balance = balanceOf(address(this));

        require(
            // bskrERC20.transfer(_msgSender(), balance),
            // T - BSKR transfer failed
            transfer(_msgSender(), balance),
            "Transfer Failed"
        );
    }

    /**
     * @notice Removes an existing stake (unstake)
     */
    function removeStake(uint256 stakeAmount) external whenNotPaused {
        creditInflation();
        uint256 stakeholderStake = stakeholderToStake[_msgSender()].stakedBSKR;
        uint256 stakeholderShares = stakeholderToStake[_msgSender()].shares;

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

        stakeholderToStake[_msgSender()].shares -= sharesToWithdraw;
        stakeholderToStake[_msgSender()].stakedBSKR -= stakeAmount;
        totalStakes -= stakeAmount;
        totalShares -= sharesToWithdraw;

        // _approve(_msgSender(), _msgSender(), stakeAmount);
        // _approve(_msgSender(), address(this), stakeAmount);
        // _approve(address(this), _msgSender(), stakeAmount);
        // _approve(address(this), address(this), stakeAmount);
        require(
            // bskrERC20.transfer(_msgSender(), stakeAmount + rewards),
            transfer(_msgSender(), stakeAmount + rewards),
            "Transfer Failed"
        );

        if (stakeholderToStake[_msgSender()].stakedBSKR == 0) {
            stakeholders.remove(_msgSender());
        }

        emit StakeRemoved(
            _msgSender(),
            stakeAmount,
            sharesToWithdraw,
            rewards,
            block.timestamp
        );
    }

    function restoreAllFee() private {
        (
            _burnFee,
            _growthFee
            //, _grossFees
        ) = (
            _prevBurnFee,
            _prevGrowthFee
            // ,_prevGrossFees
        );
    }

    /**
     * @notice Calculates reward for BSKR
     */
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

    /**
     * @notice Calculates rewards for a stakeholder
     */
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

    // Set the BSKR contract address
    function setBSKRContract(address newBSKRContract) external onlyManager {
        _BSKRContract = newBSKRContract;
        _ammBSKRPair = dexFactoryV2.createPair(address(this), _BSKRContract);
        _approve(_ammBSKRPair, _ammBSKRPair, MAX);
        _isAMMPair[_ammBSKRPair] = true;
    }

    // TODO eliminate this function and initialize automatically in constructor
    /**
     * @notice Set's the initial shares to stakes ratio and initializes
     */
    function setInitialRatio(address newBSKRContract, uint256 stakeAmount)
        external
        onlyManager
        isInitialRatioNotSet
    {
        _BSKRContract = newBSKRContract;
        _ammBSKRPair = dexFactoryV2.createPair(address(this), _BSKRContract);
        _approve(_ammBSKRPair, _ammBSKRPair, MAX);
        _isAMMPair[_ammBSKRPair] = true;

        // bskrERC20 = IERC20(address(this)); // TODO switch BSKR later, for now just using LBSKR
        // SE - Stakes and shares are non-zero
        require(
            // totalShares == 0 && bskrERC20.balanceOf(address(this)) == 0,
            totalShares == 0 && balanceOf(address(this)) == 0,
            "Non-zero Stakes"
        );

        // approve(address(this), stakeAmount);
        // _approve(_msgSender(), address(this), stakeAmount); // TODO from will need from/to change for BSKR
        // _approve(address(this), address(this), stakeAmount); // TODO from will need from/to change for BSKR

        _approve(_msgSender(), _msgSender(), stakeAmount); // TODO works if enabled!

        // T - LBSKR transfer failed
        require(
            // bskrERC20.transferFrom(_msgSender(), address(this), stakeAmount),
            transferFrom(_msgSender(), address(this), stakeAmount),
            "Transfer Failed"
        );

        stakeholders.add(_msgSender());
        stakeholderToStake[_msgSender()].stakedBSKR = stakeAmount;
        stakeholderToStake[_msgSender()].shares = stakeAmount;
        //stakeholderToStake[_msgSender()] = Stake({
        //    stakedBSKR: stakeAmount,
        //    shares: stakeAmount
        //});
        totalStakes = stakeAmount;
        totalShares = stakeAmount;
        initialRatioFlag = true;

        startInflation();

        emit StakeAdded(
            _msgSender(),
            stakeAmount,
            stakeAmount,
            block.timestamp
        );
    }

    /**
     * @notice Sets max transaction size for LBSKR - TODO we are not limiting LBSKR?
     */
    // function setMaxTxPercent(uint16 maxTxBips) external onlyManager {
    //     maxTxAmount = (_TOTAL_SUPPLY * maxTxBips) / _BIPS;
    // }

    /**
     * @notice Returns the shares of a stakeholder
     */
    function sharesOf(address stakeholder) external view returns (uint256) {
        return stakeholderToStake[stakeholder].shares;
    }

    /**
     * @notice Returns the stakes of a stakeholder
     */
    function stakeOf(address stakeholder) external view returns (uint256) {
        return stakeholderToStake[stakeholder].stakedBSKR;
    }

    // Inflation starts at the start of the hour after enabled
    function startInflation() internal {
        _lastDistTS = block.timestamp; // + (3600 - block.timestamp % _SECS_IN_AN_HOUR);
    }

    // TODO this function to be used in staking to add acquired BSKR
    function swapTokensForTokens(uint256 tokenAmount) private {
        // emit debug
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(_BSKRContract); // TODO need to set BSKR address in this contract

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

    // TODO just for testing!
    function swapTokensForTokensExt(uint256 tokenAmount) external onlyManager {
        swapTokensForTokens(tokenAmount);
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

    function _approveManager(
        address owner,
        address spender,
        uint256 amount
    ) external onlyManager {
        _approve(owner, spender, amount);
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function allPairsLength() external view returns (uint);
    function allPairs(uint) external view returns (address pair);
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