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
    address internal immutable _growthAddress;
    address[] internal _sisterOAs;
    bool isV3Enabled = false;
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
        require(owner != address(0), "BSKR: From zero zddress");
        require(spender != address(0), "BSKR: To zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _checkIfAMMPair(address target) internal {
        if (target.code.length == 0) return;
        // if (target == _DEXV2_ROUTER_ADDR) return;
        if (target == _dexRouterV2.WETH()) return; // to avoid reverts
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

    function _isPairPool(address target) internal view returns (bool isPair) {
        address token0 = _getToken0(target);
        if (token0 == address(0)) {
            return false;
        }

        address token1 = _getToken1(target);
        if (token1 == address(0)) {
            return false;
        }

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

    // to rename with _ prefix
    function v3PairInvolved(address from, address to)
        internal
        view
        returns (bool)
    {
        return (__v3PairInvolved(from) || __v3PairInvolved(to));
    }

    // to rename with _ prefix
    function __v3PairInvolved(address target) internal view returns (bool) {
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
        if (fee > 0) {
            return true;
        }

        return false;
    }
}

/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.17;

/**
 * @dev Interface of BSKR.
 */
interface IBSKR {
    function balanceOf(address account) external view returns (uint256);

    function stakeBurn(address from, uint256 amount) external returns (bool);

    function stakeTransfer(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function totalReflection() external view returns (uint256);
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

pragma solidity 0.8.17;

import "../openzeppelin/access/Ownable.sol";

contract Stakable is Ownable {
    struct Stake {
        address user;
        uint256 amountLBSKR;
        uint256 amountBSKR;
        uint256 sharesLBSKR;
        uint256 sharesBSKR;
        uint256 since;
    }

    struct Stakeholder {
        address user;
        Stake[] userStakes;
    }

    Stakeholder[] internal _stakeholders;
    mapping(address => uint256) internal _stakes;
    uint256 internal _totalBSKRShares;
    uint256 internal _totalBSKRStakes;
    uint256 internal _totalLBSKRShares;
    uint256 internal _totalLBSKRStakes;

    /**
     * @notice Staked event is triggered whenever a user stakes tokens, address is indexed to make it filterable
     */
    event Staked(
        address indexed user,
        uint256 amountLBSKR,
        uint256 amountBSKR,
        uint256 sharesLBSKR,
        uint256 sharesBSKR,
        uint256 stakeIndex,
        uint256 since
    );

    /**
     * @notice Unstaked event is triggered whenever a user unstakes tokens, address is indexed to make it filterable
     */
    event Unstaked(
        address indexed user,
        uint256 amountLBSKR,
        uint256 amountBSKR,
        uint256 sharesLBSKR,
        uint256 sharesBSKR,
        uint256 since,
        uint256 till
    );

    constructor() {
        // This push is needed so we avoid index 0 causing bug of index-1
        _stakeholders.push();
    }

    /**
     * @notice _addStakeholder takes care of adding a stakeholder to the _stakeholders array
     */
    function _addStakeholder(address staker) internal returns (uint256) {
        // Push a empty item to the Array to make space for our new stakeholder
        _stakeholders.push();
        // Calculate the index of the last item in the array by Len-1
        uint256 userIndex = _stakeholders.length - 1;
        // Assign the address to the new index
        _stakeholders[userIndex].user = staker;
        // Add index to the _stakeholders
        _stakes[staker] = userIndex;
        return userIndex;
    }

    function _getCurrStake(uint256 userIndex, uint256 stakeIndex)
        internal
        view
        returns (Stake memory currStake)
    {
        require(
            stakeIndex < _stakeholders[userIndex].userStakes.length,
            "LBSKR: Stake index incorrect!"
        );

        currStake = _stakeholders[userIndex].userStakes[stakeIndex];

        return currStake;
    }

    function _stake(
        uint256 amountLBSKR,
        uint256 amountBSKR,
        uint256 sharesLBSKR,
        uint256 sharesBSKR
    ) internal {
        // Simple check so that user does not stake 0
        require(amountLBSKR > 0, "Cannot stake nothing");

        // Mappings in solidity creates all values, but empty, so we can just check the address
        uint256 userIndex = _stakes[_msgSender()];
        uint256 since = block.timestamp;

        // See if the staker already has a staked index or if its the first time
        if (userIndex == 0) {
            // This stakeholder stakes for the first time
            // We need to add him to the _stakeholders and also map it into the Index of the stakes
            // The index returned will be the index of the stakeholder in the _stakeholders array
            userIndex = _addStakeholder(_msgSender());
        }

        // Use the index to push a new Stake
        // push a newly created Stake with the current block timestamp.
        _stakeholders[userIndex].userStakes.push(
            Stake(
                _msgSender(),
                amountLBSKR,
                amountBSKR,
                sharesLBSKR,
                sharesBSKR,
                since
            )
        );

        _totalLBSKRStakes += amountLBSKR;
        _totalBSKRStakes += amountBSKR;
        _totalLBSKRShares += sharesLBSKR;
        _totalBSKRShares += sharesBSKR;

        // Emit an event that the stake has occured
        emit Staked(
            _msgSender(),
            amountLBSKR,
            amountBSKR,
            sharesLBSKR,
            sharesBSKR,
            _stakeholders[userIndex].userStakes.length - 1,
            since
        );
    }

    function _withdrawStake(uint256 stakeIndex, uint256 unstakeAmount)
        internal
        returns (
            Stake memory currStake,
            uint256 lbskrShares2Deduct,
            uint256 bskrShares2Deduct
        )
    {
        uint256 userIndex = _stakes[_msgSender()];
        currStake = _getCurrStake(userIndex, stakeIndex);

        require(
            userIndex != 1 || stakeIndex != 0,
            "Stakable: Cannot remove the first stake"
        );

        require(
            currStake.amountLBSKR >= unstakeAmount,
            "Staking: Cannot withdraw more than you have staked"
        );

        // Remove by subtracting the money unstaked
        // Same fraction of shares to be deducted from both BSKR and LBSKR
        lbskrShares2Deduct =
            (unstakeAmount * currStake.sharesLBSKR) /
            currStake.amountLBSKR;
        uint256 bskrAmount2Deduct = (unstakeAmount * currStake.amountBSKR) /
            currStake.amountLBSKR;
        bskrShares2Deduct =
            (unstakeAmount * currStake.sharesBSKR) /
            currStake.amountLBSKR;

        if (currStake.amountLBSKR == unstakeAmount) {
            _stakeholders[userIndex].userStakes[stakeIndex] = _stakeholders[
                userIndex
            ].userStakes[_stakeholders[userIndex].userStakes.length - 1];
            // delete _stakeholders[userIndex].userStakes[_stakeholders[userIndex].userStakes.length - 1];
            _stakeholders[userIndex].userStakes.pop();
        } else {
            Stake storage updatedStake = _stakeholders[userIndex].userStakes[
                stakeIndex
            ];
            updatedStake.amountLBSKR -= unstakeAmount;
            updatedStake.amountBSKR -= bskrAmount2Deduct;
            updatedStake.sharesLBSKR -= lbskrShares2Deduct;
            updatedStake.sharesBSKR -= bskrShares2Deduct;
        }

        _totalLBSKRStakes -= unstakeAmount;
        _totalBSKRStakes -= bskrAmount2Deduct;
        _totalLBSKRShares -= lbskrShares2Deduct;
        _totalBSKRShares -= bskrShares2Deduct;

        emit Unstaked(
            _msgSender(),
            unstakeAmount,
            bskrAmount2Deduct,
            lbskrShares2Deduct,
            bskrShares2Deduct,
            currStake.since,
            block.timestamp
        );

        return (currStake, lbskrShares2Deduct, bskrShares2Deduct);
    }

    /**
     * @notice Returns the total number of stake holders
     */
    function getTotalStakeholders() external view returns (uint256) {
        return _stakeholders.length - 1;
    }

    /**
     * @notice A method to the aggregated stakes from all _stakeholders.
     * @return uint256 The aggregated stakes from all _stakeholders.
     */
    function getTotalStakes() external view returns (uint256) {
        uint256 __totalStakes = 0;
        for (uint256 s = 0; s < _stakeholders.length; s += 1) {
            __totalStakes = __totalStakes + _stakeholders[s].userStakes.length;
        }

        return __totalStakes;
    }

    /**
     * @notice Returns the stakes of a stakeholder
     */
    function stakesOf(address stakeholder)
        external
        view
        returns (Stake[] memory userStakes)
    {
        uint256 userIndex = _stakes[stakeholder];
        return _stakeholders[userIndex].userStakes;
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

import "./imports/BaseBSKR.sol";
import "./imports/IBSKR.sol";
import "./imports/Stakable.sol";
import "./lib/DSMath.sol";

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
// UniversalRouter: 0x4648a43B2C14Da09FdF82B161150d3F634f40491
// Permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3

// TODO add restriction to _inflationVaultAddress such that only this contract can withdraw
// TODO Recalculate the Token allocations to sacrificers
// TODO - adding liquidity is adding some to growth address
// TODO make all variabes private

// TODO evaluate each of these for our needs
// Stake function refundLockedBSKR(uint256 from, uint256 to) external onlyManager { TODO
// Stake function removeLockedRewards() external onlyManager { TODO do we need this?
// Stake function rewardForBSKR(address stakeholder, uint256 bskrAmount)
contract LBSKR is BaseBSKR, DSMath, Stakable {
    enum Field {
        tTransferAmount,
        tBurnFee,
        tGrowthFee
    }

    IBSKR private _BSKR;
    address private immutable _inflationAddress;
    bool private _initialRatioFlag;
    uint24 private constant _SECS_IN_FOUR_WEEKS = 2419200; // 3600 * 24 * 7 * 4
    uint256 private _burnFee = 10; // 0.1% burn fee
    uint256 private _growthFee = 10; // 0.1% growth fee
    uint256 private _lastDistTS;
    uint256 private constant _INF_RATE_HRLY = 0x33B2FEE4E1DEE6BDD000000; // ray (10E27 precision) value for 1.000008 (1 + 0.0008%)
    uint256 private constant _SECS_IN_AN_HOUR = 3600;

    modifier isInitialRatioNotSet() {
        require(!_initialRatioFlag, "LBSKR: Initial ratio set");
        _;
    }

    modifier isInitialRatioSet() {
        require(_initialRatioFlag, "LBSKR: Initial ratio not set");
        _;
    }

    constructor(
        string memory nameA,
        string memory symbolA,
        address growthAddressA,
        address inflationAddressA,
        address[] memory sisterOAsA
    ) BaseBSKR(nameA, symbolA, growthAddressA, sisterOAsA) {
        _inflationAddress = address(inflationAddressA);
        // TODO pre-distribute all allocations as per tokenomics
        _balances[_msgSender()] = _TOTAL_SUPPLY / 2;
        emit Transfer(address(0), _msgSender(), _TOTAL_SUPPLY / 2);

        _balances[_inflationAddress] = _TOTAL_SUPPLY / 2;
        emit Transfer(address(0), address(this), _TOTAL_SUPPLY / 2);

        address _ammLBSKRPair = _dexFactoryV2.createPair(
            address(this),
            _dexRouterV2.WETH()
        );
        _approve(_ammLBSKRPair, _ammLBSKRPair, type(uint256).max);
        _isAMMPair[_ammLBSKRPair] = true;

        for (uint8 i = 0; i < _sisterOAs.length; i++) {
            _paysNoFee[_sisterOAs[i]] = true;
        }
    }

    /**
     * Airdrop BSKR to sacrificers, deducted from owner's wallet
     */
    function _airdropTransfer(address account, uint256 amount) private {
        _transferTokens(owner(), account, amount, false);
    }

    function _calcInflation(uint256 nowTS)
        private
        view
        returns (uint256 inflation)
    {
        require(_lastDistTS > 0, "Inflation not yet started!");
        // Always count seconds at beginning of the hour
        uint256 hoursElapsed = uint256(
            (nowTS - _lastDistTS) / _SECS_IN_AN_HOUR
        );

        uint256 currBal = _balances[_inflationAddress];
        inflation = 0;
        if (hoursElapsed > 0) {
            uint256 infFracRay = rpow(_INF_RATE_HRLY, hoursElapsed);
            inflation = (currBal * infFracRay) / RAY - currBal;
        }

        return inflation;
    }

    function _creditInflation() private isInitialRatioSet {
        // Always count seconds at beginning of the hour
        uint256 nowTS = block.timestamp - (block.timestamp % _SECS_IN_AN_HOUR);
        if (nowTS > _lastDistTS) {
            uint256 inflation = _calcInflation(nowTS);

            if (inflation > 0) {
                _lastDistTS = nowTS;
                _balances[_inflationAddress] -= inflation;
                _balances[address(this)] += inflation;
            }
        }
    }

    function _getValues(uint256 tAmount, bool takeFee)
        private
        view
        returns (uint256[] memory)
    {
        uint256[] memory response = new uint256[](3);

        if (!takeFee) {
            response[uint8(Field.tBurnFee)] = 0;
            response[uint8(Field.tGrowthFee)] = 0;
            response[uint8(Field.tTransferAmount)] = tAmount;
        } else {
            response[uint8(Field.tBurnFee)] = (tAmount * _burnFee) / _BIPS;
            response[uint8(Field.tGrowthFee)] = (tAmount * _growthFee) / _BIPS;
            response[uint8(Field.tTransferAmount)] =
                tAmount -
                response[uint8(Field.tBurnFee)] -
                response[uint8(Field.tGrowthFee)];
        }

        return (response);
    }

    // Set the BSKR contract address
    function _setBSKRAddress(address newBSKRAddr) private {
        _BSKR = IBSKR(newBSKRAddr);
        address _ammBSKRPair = _dexFactoryV2.getPair(
            address(this),
            newBSKRAddr
        );

        if (_ammBSKRPair == address(0)) {
            _ammBSKRPair = _dexFactoryV2.createPair(address(this), newBSKRAddr);
        }

        if (_ammBSKRPair != address(0)) {
            _approve(_ammBSKRPair, _ammBSKRPair, type(uint256).max);
            _isAMMPair[_ammBSKRPair] = true;
        }
    }

    // Inflation starts at the start of the hour after enabled
    function _startInflation() private {
        _lastDistTS = block.timestamp - (block.timestamp % _SECS_IN_AN_HOUR);
    }

    function _swapTokensForTokens(address owner, uint256 tokenAmount)
        private
        returns (uint256 bskrAmount)
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(_BSKR);

        _approve(owner, owner, tokenAmount); // allow owner to spend his/her tokens
        _approve(owner, address(_dexRouterV2), tokenAmount); // allow router to spend owner's tokens

        uint256 balInfAddrBefore = _BSKR.balanceOf(_inflationAddress);

        // make the swap
        _dexRouterV2.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            _inflationAddress,
            block.timestamp + 15
        );

        // There is no good way to discount the reflection received as part of this swap
        // It will be small fraction and proportional to amount staked, so can be ignored
        return _BSKR.balanceOf(_inflationAddress) - balInfAddrBefore;
    }

    function _takeFee(address target, uint256 tFee) private {
        _balances[target] += tFee;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "LBSKR: From zero address");
        require(to != address(0), "LBSKR: To zero address");
        require(amount > 0, "LBSKR: Zero transfer amount");

        if (!isV3Enabled) {
            require(
                !v3PairInvolved(from, to),
                "BSKR: UniswapV3 is not supported!"
            );
        }

        _checkIfAMMPair(from);
        _checkIfAMMPair(to);

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

        //transfer amount, it will take tax, burn fee
        _transferTokens(from, to, amount, takeFee);
    }

    function _transferTokens(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        uint256[] memory response = _getValues(tAmount, takeFee);

        _balances[sender] -= tAmount;
        _balances[recipient] += response[uint8(Field.tTransferAmount)];

        if (response[uint8(Field.tBurnFee)] > 0) {
            _takeFee(address(0), response[uint8(Field.tBurnFee)]);
            emit Transfer(sender, address(0), response[uint8(Field.tBurnFee)]);
        }

        if (response[uint8(Field.tGrowthFee)] > 0) {
            _takeFee(_growthAddress, response[uint8(Field.tGrowthFee)]);
            emit Transfer(
                sender,
                _growthAddress,
                response[uint8(Field.tGrowthFee)]
            );
        }

        emit Transfer(
            sender,
            recipient,
            response[uint8(Field.tTransferAmount)]
        );
    }

    /**
     * @notice See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Returns the registered BSKR contract address
     * TODO do we need this function?isInitialRatioSet
     */
    function getBSKRAddress() external view returns (address) {
        return address(_BSKR);
    }

    /**
     * @notice Returns the amount of BSKR per share
     * TODO need to decide if we want to keep this function
     */
    function getBSKRPerShare()
        external
        view
        isInitialRatioSet
        returns (uint256 BSKR_Balance, uint256 Total_BSKR_Shares)
    {
        return (_BSKR.balanceOf(_inflationAddress), _totalBSKRShares);
    }

    /**
     * @notice Returns the current accumulated LBSKR rewards
     */
    function getCurrentBalances()
        external
        view
        isInitialRatioSet
        returns (uint256 lbskrBalance, uint256 bskrBalance)
    {
        uint256 inflation = _calcInflation(block.timestamp);
        return (
            (balanceOf(address(this)) + inflation),
            (_BSKR.balanceOf(_inflationAddress))
        );
    }

    /**
     * @notice Returns the amount of LBSKR per share
     * TODO need to decide if we want to keep this function
     */
    function getLBSKRPerShare()
        external
        view
        isInitialRatioSet
        returns (uint256 LBSKR_Balance, uint256 Total_LBSKR_Shares)
    {
        uint256 inflation = _calcInflation(block.timestamp);
        return ((balanceOf(address(this)) + inflation), _totalLBSKRShares);
    }

    /**
     * @notice Returns the total number of shares
     */
    function getTotalBSKRShares() external view returns (uint256) {
        return _totalBSKRShares;
    }

    /**
     * @notice Returns the total number of shares
     * TODO do we need this function?
     */
    function getTotalLBSKRShares() external view returns (uint256) {
        return _totalLBSKRShares;
    }

    /**
     * @notice Makes an account responsible for fees --  TODO do we need this?
     */
    // function includeInFee(address account) public onlyManager {
    //     _paysNoFee[account] = false;
    // }

    /**
     * @notice Calculates penalty basis points for given from and to timestamps in seconds since epoch
     */
    function penaltyFor(uint256 fromTimestamp, uint256 toTimestamp)
        public
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

    /**
     * @notice Calculates penalty amount for given stake if unstaked now
     */
    function penaltyIfUnstakedNow(address account, uint256 stakeIndex)
        external
        view
        returns (uint256 penaltyBasis)
    {
        uint256 userIndex = _stakes[account];
        Stake memory currStake = _getCurrStake(userIndex, stakeIndex);

        return penaltyFor(currStake.since, block.timestamp);
    }

    /**
     * @notice Refunds the locked BSKR
     */
    // function refundLockedBSKR(uint256 from, uint256 to) external onlyManager {
    //     // IT - Invalid `to` param
    //     require(to <= _stakeholders.length(), "LBSKR: Invalid recipient");
    //     _creditInflation();
    //     uint256 s;

    //     for (s = from; s < to; s += 1) {
    //         _totalStakes -= _stakeholderToStake[_stakeholders.at(s)]
    //             .stakedBSKR;

    //         // T - BSKR transfer failed
    //         // _approve(
    //         //     _msgSender(),
    //         //     _msgSender(),
    //         //     _stakeholderToStake[_stakeholders.at(s)].stakedLBSKR
    //         // );
    //         // _approve(
    //         //     _msgSender(),
    //         //     address(this),
    //         //     _stakeholderToStake[_stakeholders.at(s)].stakedLBSKR
    //         // );
    //         // _approve(
    //         //     address(this),
    //         //     _msgSender(),
    //         //     _stakeholderToStake[_stakeholders.at(s)].stakedLBSKR
    //         // );
    //         // _approve(
    //         //     address(this),
    //         //     address(this),
    //         //     _stakeholderToStake[_stakeholders.at(s)].stakedLBSKR
    //         // );
    //         require(
    //             // bskrERC20.transfer(
    //             transfer(
    //                 _stakeholders.at(s),
    //                 _stakeholderToStake[_stakeholders.at(s)].stakedBSKR
    //             ),
    //             "LBSKR: TransferFrom failed"
    //         );

    //         _stakeholderToStake[_stakeholders.at(s)].stakedBSKR = 0;
    //     }
    // }

    /**
     * @notice Removes the locked rewards
     */
    // function removeLockedRewards() external onlyManager {
    //     // HS - _stakeholders still have stakes
    //     require(_totalStakes == 0, "LBSKR: Stakes exist");
    //     _creditInflation();
    //     // uint256 balance = bskrERC20.balanceOf(address(this));
    //     uint256 balance = balanceOf(address(this));

    //     require(
    //         // bskrERC20.transfer(_msgSender(), balance),
    //         // T - BSKR transfer failed
    //         transfer(_msgSender(), balance),
    //         "TF3"
    //     );
    // }

    /**
     * @notice Calculates rewards for a stakeholder
     */
    function rewardsOf(address stakeholder, uint256 stakeIndex)
        external
        view
        returns (
            uint256 lbskrRewards,
            uint256 bskrRewards,
            uint256 eligibleBasis
        )
    {
        uint256 inflation = 0;
        if (_lastDistTS > 0) {
            inflation = _calcInflation(block.timestamp);
        }

        uint256 userIndex = _stakes[stakeholder];
        Stake memory currStake = _getCurrStake(userIndex, stakeIndex);

        eligibleBasis =
            _BIPS -
            penaltyFor(currStake.since, block.timestamp);

        if ((balanceOf(address(this)) + inflation) > 0) {
            uint256 lbskrBal = (((balanceOf(address(this)) +
                inflation +
                _totalLBSKRStakes) * currStake.sharesLBSKR) /
                _totalLBSKRShares); // LBSKR notional balance

            if (lbskrBal > currStake.amountLBSKR) {
                lbskrRewards =
                    ((lbskrBal - currStake.amountLBSKR) * eligibleBasis) /
                    _BIPS;
            }
        }

        if (_BSKR.balanceOf(_inflationAddress) > 0) {
            uint256 bskrBal = ((_BSKR.balanceOf(_inflationAddress) *
                currStake.sharesBSKR) / _totalBSKRShares);

            if (bskrBal > currStake.amountBSKR) {
                bskrRewards =
                    ((bskrBal - currStake.amountBSKR) * eligibleBasis) /
                    _BIPS;
            }
        }

        return (lbskrRewards, bskrRewards, eligibleBasis);
    }

    /**
     * @notice Set's the initial shares to stakes ratio and initializes
     * wallet (owner) needs LBSKR allowance for itself (spender)
     */
    function setInitialRatio(address newBSKRAddr, uint256 amountLBSKR)
        external
        onlyManager
        isInitialRatioNotSet
    {
        _setBSKRAddress(newBSKRAddr);

        require(
            _totalLBSKRShares == 0 && balanceOf(address(this)) == 0,
            "LBSKR: Non-zero balance"
        );

        _balances[_msgSender()] -= amountLBSKR;
        _balances[address(this)] += amountLBSKR;
        uint256 amountBSKR = _swapTokensForTokens(address(this), amountLBSKR);

        _stake(amountLBSKR, amountBSKR, amountLBSKR, amountBSKR); // For the first stake, the number of shares is the same as the amount

        _totalLBSKRStakes = amountLBSKR;
        _totalBSKRStakes = amountBSKR;
        _totalLBSKRShares = amountLBSKR;
        _totalBSKRShares = amountBSKR;

        _initialRatioFlag = true;

        _startInflation();
    }

    /**
     * @notice Create a new stake
     * wallet (owner) needs LBSKR allowance for itself (spender)
     * also maybe LBSKR (spender) needs LSBKR allowance for wallet (owner)
     */
    function stake(uint256 amountLBSKR)
        external
        whenNotPaused
        isInitialRatioSet
    {
        require(amountLBSKR > 0, "LBSKR: Cannot stake nothing");

        _creditInflation();
        // NAV value -> (_totalLBSKRStakes + balanceOf(address(this))) / _totalLBSKRShares
        // Divide the amountLBSKR by NAV
        uint256 sharesLBSKR = (amountLBSKR * _totalLBSKRShares) /
            (_totalLBSKRStakes + balanceOf(address(this)));

        _balances[_msgSender()] -= amountLBSKR;
        _balances[address(this)] += amountLBSKR;
        uint256 bskrBalBeforeSwap = _BSKR.balanceOf(_inflationAddress);
        uint256 amountBSKR = _swapTokensForTokens(address(this), amountLBSKR);
        uint256 sharesBSKR = (amountBSKR * _totalBSKRShares) /
            bskrBalBeforeSwap;

        _stake(amountLBSKR, amountBSKR, sharesLBSKR, sharesBSKR);
    }

    /**
     * @notice Removes an existing stake (unstake)
     */
    function unstake(uint256 stakeAmount, uint256 stakeIndex)
        external
        isInitialRatioSet
        whenNotPaused
    {
        _creditInflation();

        (
            Stake memory currStake,
            uint256 lbskrShares2Deduct,
            uint256 bskrShares2Deduct
        ) = _withdrawStake(stakeIndex, stakeAmount);

        uint256 eligibleBasis = _BIPS -
            penaltyFor(currStake.since, block.timestamp);

        uint256 lbskrToSend = 0;
        if (balanceOf(address(this)) > 0) {
            // stakeAmount never existed - it's notional
            uint256 lbskrWithRewards = ((((balanceOf(address(this)) +
                _totalLBSKRStakes) * lbskrShares2Deduct) / _totalLBSKRShares) -
                stakeAmount);

            lbskrToSend = (lbskrWithRewards * eligibleBasis) / _BIPS;
            if (lbskrToSend > 0) {
                _balances[address(this)] -= lbskrToSend;
                _balances[_msgSender()] += lbskrToSend;
                emit Transfer(address(this), _msgSender(), lbskrToSend);
            }

            if (eligibleBasis < _BIPS) {
                uint256 lbskrToBurn = (lbskrWithRewards *
                    (_BIPS - eligibleBasis)) / _BIPS;

                if (lbskrToBurn > 0) {
                    _balances[address(this)] -= lbskrToBurn;
                    _balances[address(0)] += lbskrToBurn;

                    emit Transfer(address(this), address(0), lbskrToBurn);
                }
            }
        }

        uint256 bskrToSend = 0;
        if (_BSKR.balanceOf(_inflationAddress) > 0) {
            uint256 bskrWithRewards = (_BSKR.balanceOf(_inflationAddress) *
                bskrShares2Deduct) / _totalBSKRShares;
            bskrToSend = (bskrWithRewards * eligibleBasis) / _BIPS;

            if (bskrToSend > 0) {
                require(
                    _BSKR.stakeTransfer(
                        _inflationAddress,
                        _msgSender(),
                        bskrToSend
                    ),
                    "LBSKR: BSKR transfer failed"
                );
            }

            if (eligibleBasis < _BIPS) {
                uint256 bskrToBurn = (bskrWithRewards *
                    (_BIPS - eligibleBasis)) / _BIPS;

                if (bskrToBurn > 0) {
                    require(
                        _BSKR.stakeBurn(_inflationAddress, bskrToBurn),
                        "LBSKR: BSKR burn failed"
                    );
                }
            }
        }
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