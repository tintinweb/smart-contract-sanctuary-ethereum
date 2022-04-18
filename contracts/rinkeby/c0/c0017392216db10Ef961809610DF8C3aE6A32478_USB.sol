//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./USBController.sol";
import "./USBPriceOracle/USBPriceOracle.sol";
import "./USBStabilityPool.sol";

contract USB is Initializable, 
                ERC20Upgradeable,
                AccessControlUpgradeable,
                ReentrancyGuardUpgradeable
{

    using SafeERC20Upgradeable for ERC20Upgradeable;

    /**
     * @dev address of USBController. 
     * @notice Contains all parameters of USB
     */
    USBController public usbController; 

    /**
     * @dev address of price oracle with interface of USBPriceOracle
     * @notice Neccesary for retrieving price and evaluations in USD
     */
    USBPriceOracle public usbPriceOracle;

    /**
     * @dev address of stability pool
     * @notice all stability fees are transfering to stability pool contract
     */
    USBStabilityPool public usbStabilityPool; 
    
    /** 
     * @notice handles the deposit positions
     * @dev user address => address of project token => deposit position
     */
    mapping(address => mapping(address => DepositPosition)) public depositPosition;

    /**
     * @notice handles the loanBody positions
     * @dev user address => address of project token => borrow position
     */
    mapping(address => mapping(address => BorrowPosition)) public borrowPosition;

    /**
     * @notice handles the current total borrow by project token collateral
     * @dev project token address => total borrow
     */
    mapping(address => uint256) public totalBorrow;
  
    /**
     * @dev used for calculating the accrual for borrow position 
     * @notice represent the sum of borrowRate`s 
     * [cumulativeBorrowRateMantissa] = %
     */
    uint256 public cumulativeBorrowRateMantissa;

    /**
     * @dev the number of last block when cumulativeBorrowRateMantissa was incremented;
     * [latestBlockCumulativeBorrowRateMantissa] = block
     */
    uint256 public latestBlockCumulativeBorrowRateMantissa;
    
    struct DepositPosition {
        uint256 deposited; // [deposited] = PRJ. Represents the total deposited amount;
        uint256 available; // [available] = PRJ. Represents the availale amount to operate;
        // should be equation available <= deposited
        // liquidated amount = deposited - available
    }

    struct BorrowPosition {
        uint256 loanBody;   // [loanBody] = USB
        uint256 accrual;    // [accrual] = USB
        uint256 instantCumulativeBorrowRateMantissa;   //[instantCumulativeBorrowRateMantissa] = % / block
        uint256 instantLatestBlockCumulativeBorrowRateMantissa; //[instantBlockCumulativeBorrowRateMantissa] = block
    }

    event Deposit(address indexed depositor, address indexed projectToken, uint256 projectTokenAmount);
    event Withdraw(address indexed withdrawer, address indexed projectToken, uint256 projectTokenAmount);
    event Borrow(address indexed minter, address indexed projectToken, uint256 borrowAmount, uint256 mintedToBorrowerUsbAmount);
    event Repay(address indexed repayer, address indexed borrower, address indexed projectToken, uint256 repaidLoanBody, uint256 repaidAccrual, bool isFullyRepaid);
    event Liquidate(address indexed liquidator, address indexed borrower, address indexed projectToken, uint256 projectTokenAmount);

    function initialize(
        address _usbPriceOracle,
        address _usbController,
        address _usbStabilityPool
    ) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init_unchained();
        __ERC20_init_unchained("USB stablecoin", "USB");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        usbController = USBController(_usbController);
        usbPriceOracle = USBPriceOracle(_usbPriceOracle);
        usbStabilityPool = USBStabilityPool(_usbStabilityPool);
        
        /**
         * Explanation why cumulativeBorrowRateMantissa starts from 10**18:
         * borrowRateMantissa have decimals equal 18, that means that calculation of accrual will be like 
         *   accrual += loanBody * (cumulativeBorrowRateMantissa - instantBorrowRateMantissa) / borrowRateMantissaMultiplier
         * The variables `cumulativeBorrowRateMantissa` and `instantBorrowRateMantissa` have multiplier `borrowRateMantissaMultiplier`;
         * By providing the start of cumulativeBorrowRateMantissa = borrowRateMantissaMultiplier, we solve the issue of accruing zero accrual
         */
        cumulativeBorrowRateMantissa = usbController.borrowRateMantissaMultiplier();
        latestBlockCumulativeBorrowRateMantissa = currentBlockNumber();
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "USB: Caller is not admin");
        _;
    }

    modifier isProjectTokenListed(address projectToken) {
        require(usbController.isProjectTokenListed(projectToken), "USB: projectToken is not listed");
        _;
    }

    modifier isProjectTokenPaused(address projectToken) {
        require(usbController.isProjectTokenPaused(projectToken), "USB: projectToken is not paused");
        _;
    }

    // /******************** Platform functions ******************** */

    function deposit(address projectToken, uint256 projectTokenAmount) public isProjectTokenListed(projectToken) isProjectTokenPaused(projectToken) nonReentrant {
        updateCumulativeBorrowRate();
        DepositPosition storage _depositPosition = depositPosition[msg.sender][projectToken];
        ERC20Upgradeable(projectToken).safeTransferFrom(msg.sender, address(this), projectTokenAmount);
        _depositPosition.deposited += projectTokenAmount;
        _depositPosition.available += projectTokenAmount;
        emit Deposit(msg.sender, projectToken, projectTokenAmount);
    }

    function withdraw(address projectToken, uint256 projectTokenAmount) public isProjectTokenListed(projectToken) isProjectTokenPaused(projectToken) nonReentrant {
        updateCumulativeBorrowRate();
        DepositPosition storage position = depositPosition[msg.sender][projectToken];
        require(projectTokenAmount <= position.available,"USB: try to withdraw more than exist in position");
        position.available -= projectTokenAmount;
        if (borrowPosition[msg.sender][projectToken].loanBody > 0) {
            //cant just withdraw collateral if  withdrawer have loanBody.
            updateBorrowPosition(msg.sender, projectToken);
            (uint256 healthFactorNumerator, uint256 healthFactorDenominator) = healthFactor(msg.sender, projectToken);
            if (healthFactorNumerator < healthFactorDenominator) {
                revert("USB: withdrawable amount makes healtFactor<1");
            }
        }
        _withdraw(projectToken, projectTokenAmount);
    }
    /** 
    function withdrawSigned(address projectToken, uint256 projectTokenAmount, uint256 priceMantissa, uint8 priceDecimals, uint256 validTo, bytes calldata signature) public nonReentrant {
        updateCumulativeBorrowRate();
        DepositPosition storage position = depositPosition[msg.sender][projectToken];
        require(projectTokenAmount <= position.available,"USB: try to withdraw more than exist in position");
        position.available -= projectTokenAmount;
        if (borrowPosition[msg.sender][projectToken].loanBody > 0) {
            //cant just withdraw collateral if  withdrawer have loanBody.
            updateBorrowPosition(msg.sender, projectToken);
            (uint256 healthFactorNumerator, uint256 healthFactorDenominator) = healthFactorForBorrowPositionSigned(msg.sender, projectToken, priceMantissa, priceDecimals, validTo, signature);
            if (healthFactorNumerator < healthFactorDenominator) {
                revert("USB: withdrawable amount makes healtFactor<1");
            }
        }
        _withdraw(projectToken, projectTokenAmount);
    }
    */
    function _withdraw(address projectToken, uint256 projectTokenAmount) private {
        depositPosition[msg.sender][projectToken].deposited -= projectTokenAmount;
        ERC20Upgradeable(projectToken).safeTransfer(msg.sender, projectTokenAmount);
        emit Withdraw(msg.sender, projectToken, projectTokenAmount);
    }

    function borrow(address projectToken, uint256 usbAmount) public nonReentrant returns (uint256 mintedUsbAmount, uint256 stabilityFeePaid) {
        if (usbAmount == type(uint256).max){
            usbAmount = pitRemaining(msg.sender, projectToken);
            return borrowInternal(projectToken, usbAmount);
        } else {
            require(usbAmount <= pitRemaining(msg.sender, projectToken) , "USB: usbAmount>pitRemaining");
            return borrowInternal(projectToken, usbAmount);
        }
    }

    /**
    function borrowSigned(
        address projectToken, 
        uint256 usbAmount
        ...
        ) public nonReentrant returns (uint256 mintedUsbAmount, uint256 stabilityFeePaid){

    }
     */

    function borrowInternal(address projectToken, uint256 usbAmount) internal returns (uint256 mintedUsbAmount, uint256 stabilityFeePaid) {
        updateCumulativeBorrowRate();
        uint256 stabilityFee = calculateStabilityFee(usbAmount);
        require(usbAmount >= stabilityFee && stabilityFee > 0, "USB: too low usbAmount");
        uint256 mintAmount = usbAmount - stabilityFee; 
        require(totalBorrow[projectToken] + usbAmount <= usbController.projectTokenBorrowCap(projectToken), "USB: totalBorrow exceeded borrowCap by this project token");
        _mint(msg.sender, mintAmount);
        _mint(address(usbStabilityPool), stabilityFee);
        BorrowPosition storage _borrowPosition = borrowPosition[msg.sender][projectToken];
        if (_borrowPosition.loanBody == 0) {
            _borrowPosition.instantCumulativeBorrowRateMantissa = cumulativeBorrowRateMantissa;
            _borrowPosition.instantLatestBlockCumulativeBorrowRateMantissa = currentBlockNumber();
        } else {
            _updateBorrowPosition(msg.sender, projectToken);
        }
        _borrowPosition.loanBody += usbAmount;
        totalBorrow[projectToken] += usbAmount; 
        emit Borrow(msg.sender, projectToken, usbAmount, mintAmount);
        return (mintAmount, stabilityFee);
    }

    function repay(address projectToken, uint256 usbAmount) public returns(uint256 repaidAmount, uint256 stabilityFeePaid) {
        return repayTo(msg.sender, projectToken, usbAmount);
    }

    function repayTo(address borrower, address projectToken, uint256 usbAmount) public isProjectTokenPaused(projectToken) nonReentrant returns(uint256 repaidAmount, uint256 stabilityFeePaid) { 
        if (usbAmount == type(uint256).max) {
            return repayAllTo(borrower, projectToken);
        } else {
            return repayPartTo(borrower, projectToken, usbAmount);
        }
    }

    function repayAllTo(address borrower, address projectToken) internal returns (uint256 repaidAmount, uint256 stabilityFeePaid) {
        updateBorrowPosition(borrower, projectToken);
        address repayer = msg.sender;
        uint256 _totalOutstanding = totalOutstanding(borrower, projectToken);
        require(_totalOutstanding <= balanceOf(repayer), "USB: insufficient amount to repay all borrow");
        uint256 _stabilityFee = calculateStabilityFee(_totalOutstanding);
        _transfer(repayer, address(usbStabilityPool), _stabilityFee);
        BorrowPosition storage _borrowPosition = borrowPosition[borrower][projectToken];
        uint256 rest = _totalOutstanding - _stabilityFee;
        if(rest > _borrowPosition.loanBody) {
            uint256 _accrual = rest - _borrowPosition.loanBody;
            _transfer(repayer, address(usbStabilityPool), _accrual); // transfer accrual to stability pool
            _burn(repayer, _borrowPosition.loanBody); // burn the loan body
        } else {
            _burn(repayer, rest); // burn the rest loan body
        }
        totalBorrow[projectToken] -= _borrowPosition.loanBody;
        emit Repay(repayer, borrower, projectToken, _borrowPosition.loanBody, _borrowPosition.accrual, true);
        borrowPosition[borrower][projectToken] = BorrowPosition(0,0,0,0);
        return (rest, _stabilityFee);
    }

    function repayPartTo(address borrower, address projectToken, uint256 usbAmount) internal returns(uint256 repaidAmount, uint256 stabilityFeePaid) {
        if (usbAmount >= totalOutstanding(borrower, projectToken)) {
            return repayAllTo(borrower, projectToken);
        }
        updateBorrowPosition(borrower, projectToken);
        address repayer = msg.sender;
        require(usbAmount <= balanceOf(repayer), "USB: usbAmount exceeded balance of repayer");
        uint256 stabilityFee = calculateStabilityFee(usbAmount);
        require(usbAmount > stabilityFee /**&& stabilityFee > 0*/, "USB: low usbAmount");
        if (stabilityFee > 0){
            _transfer(repayer, address(usbStabilityPool), stabilityFee);
        }
        uint256 rest = usbAmount - stabilityFee;
        uint256 repaidLoanBody;
        uint256 repaidAccrual;
        BorrowPosition storage _borrowPosition = borrowPosition[borrower][projectToken];
        if (rest > _borrowPosition.accrual) {
            // full repayment of accrual
            repaidAccrual = _borrowPosition.accrual;
            rest -= repaidAccrual;
            _transfer(repayer, address(usbStabilityPool), repaidAccrual);
        } else {
            // part repayment of accrual
            repaidLoanBody = 0;
            repaidAccrual = rest;
            _borrowPosition.accrual -= repaidAccrual;
            _transfer(repayer, address(usbStabilityPool), repaidAccrual);
            emit Repay(repayer, borrower, projectToken, repaidLoanBody, repaidAccrual, false);
            return (rest, stabilityFee);
        }
        _borrowPosition.accrual = 0;
        _borrowPosition.loanBody -= rest;
        repaidLoanBody = rest;
        totalBorrow[projectToken] -= repaidLoanBody;
        _burn(repayer, repaidLoanBody);
        emit Repay(repayer, borrower, projectToken, repaidLoanBody, repaidAccrual, false);
        return (repaidLoanBody + repaidAccrual, stabilityFee);
    }

    function liquidate(address borrower, address projectToken) public isProjectTokenPaused(projectToken) returns (uint256 projectTokenAmountLiquidated) {
        (uint256 healthFactorNumerator, uint256 healthFactorDenominator) = healthFactor(borrower, projectToken);
        if (healthFactorNumerator >= healthFactorDenominator) {
            revert("USB: healthFactor>1");
        }
        (uint256 repaid, uint256 stabilityFeePaid) = repayAllTo(borrower, projectToken);
        uint256 oneProjectToken = 1 * (10 ** ERC20Upgradeable(projectToken).decimals());
        uint256 projectTokenAmount = oneProjectToken * (repaid + stabilityFeePaid) / getProjectTokenEvaluation(projectToken, oneProjectToken);
        DepositPosition storage _depositPosition = depositPosition[borrower][projectToken];
        if (_depositPosition.available >= projectTokenAmount) {
            _depositPosition.available -= projectTokenAmount;
        } else {
            projectTokenAmount = _depositPosition.available;
            _depositPosition.available = 0;
        }
        address liquidator = msg.sender;
        ERC20Upgradeable(projectToken).safeTransfer(liquidator, projectTokenAmount);
        emit Liquidate(liquidator, borrower, projectToken, projectTokenAmount);
        return projectTokenAmount;
    }

    function updateBorrowPosition(address borrower, address projectToken) isProjectTokenPaused(projectToken) public {
        updateCumulativeBorrowRate();
        if (borrowPosition[borrower][projectToken].loanBody == 0) {
            revert("USB: no borrow position.");
        }
        _updateBorrowPosition(borrower, projectToken);
    }

    function _updateBorrowPosition(address borrower, address projectToken) private {
        BorrowPosition storage position = borrowPosition[borrower][projectToken];
        position.accrual += calculateAccrual(borrower, projectToken);
        position.instantCumulativeBorrowRateMantissa = cumulativeBorrowRateMantissa;
        position.instantLatestBlockCumulativeBorrowRateMantissa = currentBlockNumber();
    }

    function updateCumulativeBorrowRate() public {
        uint256 currentBlock = currentBlockNumber();
        if (currentBlock > latestBlockCumulativeBorrowRateMantissa) {
            uint256 blockDifference = currentBlock - latestBlockCumulativeBorrowRateMantissa;
            cumulativeBorrowRateMantissa += blockDifference * usbController.borrowRateMantissa();
            latestBlockCumulativeBorrowRateMantissa = currentBlock;
        }
    }

    /******************** VIEW FUNCTIONS ******************** */

    function decimals() public pure override returns(uint8) {
        return 6;
    }

    function currentBlockNumber() public view returns(uint256) {
        return block.number;
    }

    function calculateStabilityFee(uint256 usbAmount) public view returns(uint256 stabilityFee) {
        (uint256 stabilityFeeNumerator , uint256 stabilityFeeDenominator) = usbController.stabilityFee();
        stabilityFee = usbAmount * stabilityFeeNumerator / stabilityFeeDenominator;
    }

    function calculateAccrual(address borrower, address projectToken) public view returns(uint256 accrual){
        BorrowPosition memory position = borrowPosition[borrower][projectToken];
        uint256 currentBlock = currentBlockNumber();
        uint256 borrowRateMantissa = usbController.borrowRateMantissa();
        uint256 borrowRateMantissaMultiplier = usbController.borrowRateMantissaMultiplier();
        if (currentBlock > latestBlockCumulativeBorrowRateMantissa) { // cheking that we updated cumulativeBorrowRate
            uint256 blockDifference = currentBlock - position.instantLatestBlockCumulativeBorrowRateMantissa;
            accrual = position.loanBody * (cumulativeBorrowRateMantissa + (blockDifference * borrowRateMantissa) - position.instantCumulativeBorrowRateMantissa) / borrowRateMantissaMultiplier;
        } else {
            accrual = position.loanBody * (cumulativeBorrowRateMantissa - position.instantCumulativeBorrowRateMantissa)/ borrowRateMantissaMultiplier;
        }
    }

    function totalOutstanding(address borrower, address projectToken) public view returns(uint256 outstanding) {
        BorrowPosition memory position = borrowPosition[borrower][projectToken];
        return position.loanBody + position.accrual + calculateAccrual(borrower, projectToken);
    }

    function pit(address account, address projectToken) public view returns (uint256) {
        uint256 projectTokenAmount = depositPosition[account][projectToken].available;
        (uint256 loanToValueRatioNumerator, uint256 loanToValueRatioDenominator) = usbController.loanToValueRatio(projectToken);
        uint256 projectTokenEvaluation = getProjectTokenEvaluation(projectToken, projectTokenAmount);
        uint256 balanceOfPit = projectTokenEvaluation * loanToValueRatioNumerator / loanToValueRatioDenominator;
        return balanceOfPit;
    }

    function pitRemaining(address account, address projectToken) public view returns (uint256) {
        uint256 balanceOfPit = pit(account, projectToken);
        uint256 _totalOutstanding = totalOutstanding(account, projectToken);
        if (balanceOfPit >= _totalOutstanding) {
            return balanceOfPit - _totalOutstanding;
        } else {
            return 0;
        }
    }

    function healthFactor(address account, address projectToken) public view returns (uint256 numerator, uint256 denominator) {
        numerator = pit(account, projectToken);
        denominator = totalOutstanding(account, projectToken);
    }

    function getPosition(
        address account, 
        address projectToken
    ) public view returns (
        uint256 deposited,
        uint256 available,
        uint256 pit_,
        uint256 pitRemaining_,
        uint256 loanBody,
        uint256 accrual,
        uint256 healthFactorNumerator,
        uint256 healthFactorDenomintator
    ) {
        deposited = depositPosition[account][projectToken].deposited;
        available = depositPosition[account][projectToken].available;
        pit_ = pit(account, projectToken);
        pitRemaining_ = pitRemaining(account, projectToken);
        loanBody = borrowPosition[account][projectToken].loanBody;
        accrual = borrowPosition[account][projectToken].accrual + calculateAccrual(account, projectToken);
        (healthFactorNumerator, healthFactorDenomintator) = healthFactor(account, projectToken);
    }

    // /******** Price oracle contract functions calling ******** */
    
    function getProjectTokenEvaluation(address projectToken, uint256 projectTokenAmount) public view returns(uint256 evaluation) {
        evaluation = usbPriceOracle.getEvaluation(projectToken, projectTokenAmount);
    }

    // function getProjectTokenEvaluationSigned(address projectToken, uint256 projectTokenAmount, uint256 priceMantissa, uint8 priceDecimals, uint256 validTo, bytes memory signature) public view returns(uint256 evaluation) {
    //     evaluation = USBPriceOracle(usbPriceOracle).getEvaluationSigned(projectToken, projectTokenAmount, priceMantissa, priceDecimals, validTo, signature);
    // }

    /******** End Price oracle contract functions calling ******** */   
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./USB.sol";

contract USBController is Initializable, AccessControlUpgradeable {

    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");

    address public usb;             // address of USB token
    address public usbPriceOracle;  // address of price oracle contract
    address public usbStabilityPool;// address of staking contract

    address[] public projectTokens; // all listed project tokens;

    mapping(address => bool) public isProjectTokenListed; // address of project token => is project token listed (true - listed, false - not listed)

    mapping(address => bool) public isProjectTokenPaused; // address of project token => is paused (true - paused, false - not paused)

    mapping(address => Ratio) public loanToValueRatio; // address of project token => loan to value ratio

    mapping(address => Ratio) public liquidationThresholdRatio; // address of project token => liquidation treshold ratio

    mapping(address => Ratio) public liquidationIncentiveRatio; // address of project token => liquidation incentive ratio

    mapping(address => uint256) public projectTokenBorrowCap; // address of project token => borrowCap in USB

    /**
     * @dev borrowRateMantissa accrues every block
     */
    uint256 public borrowRateMantissaMultiplier;    
    uint256 public borrowRateMantissa;

    Ratio public stabilityFee;

    struct Ratio {
        uint256 numerator;
        uint256 denominator;
    }

    event SetBorrowRateMantissa(address indexed who, uint256 oldBorrowRateMantissa, uint256 newBorrowRateMantissa);
    event SetStabilityFeeMantissa(address indexed who, uint256 stabilityFeeNumerator, uint256 stabilityFeeDenominator);
    event SetLiquidatorIncentiveMantissa(address indexed who, uint256 oldLiquidatorFee, uint256 newLiquidatorFee);
    event AddProjectToken(address indexed who, address indexed projectToken, uint256 indexOfProjectToken);
    event SetLoanToValueRatio(address indexed who, address indexed projectToken, uint8 numerator, uint8 denominator);
    event SetLiquidationTresholdFactor(address indexed who, address indexed projectToken, uint8 numerator, uint8 denominator);

    function initialize() public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE , msg.sender);

        borrowRateMantissa = 23782; // [borrowRateMantissa] = %/block
        borrowRateMantissaMultiplier = 10 ** 12;
        // generalized: borrowRateAPY=x% => borrowRatePerBlock = (x/100) * borrowRateMantissaMultiplier / (blocks in year in blockchain)
        // borrowRateAPY=0.1% => borrowRatePerBlock = 0.001 * 10**12 / 2102400 = 475
        // borrowRateAPY=5% => borrowRatePerBlock = 0.05 * 10**12 / 2102400 = 23782

        stabilityFee = Ratio(2,100); // 2/100 = 0.02 = 2%
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller in no admin");
        _;
    }

    modifier onlyDao() {
        require(hasRole(DAO_ROLE, msg.sender), "Caller in not dao");
        _;
    }

    modifier onlyListedProjectToken(address projectToken) {
        require(isProjectTokenListed[projectToken], "USBController: projectToken is not listed");
        _;
    }

    /********************** ADMIN FUNCTIONS ********************** */

    function grandDaoRole(address _dao) public onlyAdmin {
        grantRole(DAO_ROLE, _dao);
    }

    function revokeDaoRole(address _dao) public onlyAdmin {
        revokeRole(DAO_ROLE, _dao);
    }

    function setUsb(address _usb) public onlyAdmin {
        require(usb == address(0), "USBController: usb address is instantiated");
        usb = _usb;
    }

    function setUsbStabilityPool(address _usbStabilityPool) public onlyAdmin {
        require(usbStabilityPool == address(0), "USBController: usbStabilityPool address is instantiated");
        usbStabilityPool = _usbStabilityPool;
    }

    function setUsbPriceOracle(address _usbPriceOracle) public onlyAdmin {
        usbPriceOracle = _usbPriceOracle;
    }
    /********************** END ADMIN FUNCTIONS ********************** */
    
    /********************** DAO FUNCTIONS ********************** */

    function setBorrowRateMantissa(uint256 newBorrowRareMantissa, uint256 newBorrowRateMantissaMultiplier) public onlyDao {
        require(newBorrowRareMantissa > 0, "USBController: invalid newBorrowRareMantissa");
        emit SetBorrowRateMantissa(msg.sender, borrowRateMantissa, newBorrowRareMantissa);
        if (usb != address(0)) {
            USB(usb).updateCumulativeBorrowRate();
        } 
        borrowRateMantissa = newBorrowRareMantissa;
        borrowRateMantissaMultiplier = newBorrowRateMantissaMultiplier;
    }

    function setStabilityFeeMantissa(uint256 stabilityFeeNumerator, uint256 stabilityFeeDenominator) public onlyDao {
        require(stabilityFeeNumerator <= stabilityFeeDenominator, "USBController: invalid stability fee");
        emit SetStabilityFeeMantissa(msg.sender, stabilityFeeNumerator, stabilityFeeDenominator);
        stabilityFee = Ratio(stabilityFeeNumerator, stabilityFeeDenominator);
    }

    function addProjectTokenAndInitialize(
        address projectToken,
        uint256 loanToValueRatioNumerator,
        uint256 loanToValueRatioDenominator,
        uint256 liquidationThresholdRatioNumerator,
        uint256 liquidationThresholdRatioDenominator,
        uint256 liquidationIncentiveRatioNumerator,
        uint256 liquidationIncentiveRatioDenominator,
        uint256 borrowCap,
        bool pause
    ) public onlyDao {
        addProjectToken(projectToken);
        setLoanToValueRatio(projectToken, loanToValueRatioNumerator, loanToValueRatioDenominator);
        setLiquidationThresholdRatio(projectToken, liquidationThresholdRatioNumerator, liquidationThresholdRatioDenominator);
        setLiquidationIncentiveRatio(projectToken, liquidationIncentiveRatioNumerator, liquidationIncentiveRatioDenominator);
        setProjectTokenBorrowCap(projectToken, borrowCap);
        setProjectTokenPause(projectToken, pause);
    }

    function addProjectToken(address projectToken) internal {
        require(projectToken != address(0),"USBController: projectToken is zero address");
        emit AddProjectToken(msg.sender, projectToken, projectTokens.length);
        projectTokens.push(projectToken);
        isProjectTokenListed[projectToken] = true;
    }

    function setLoanToValueRatio(
        address projectToken, 
        uint256 loanToValueRatioNumerator, 
        uint256 loanToValueRatioDenominator
    ) public onlyListedProjectToken(projectToken) onlyDao {
        require(loanToValueRatioNumerator <= loanToValueRatioDenominator, "USBController: invalid loanToValueRatio");
        loanToValueRatio[projectToken] = Ratio(loanToValueRatioNumerator, loanToValueRatioDenominator);
    }

    function setLiquidationThresholdRatio(
        address projectToken,
        uint256 liquidationThresholdRatioNumerator,
        uint256 liquidationThresholdRatioDenominator
    ) public onlyListedProjectToken(projectToken) onlyDao {
        require(liquidationThresholdRatioNumerator >= liquidationThresholdRatioDenominator, "USBController: invalid liquidationThreshold");
        liquidationThresholdRatio[projectToken] = Ratio(liquidationThresholdRatioNumerator, liquidationThresholdRatioDenominator);
    }

    function setLiquidationIncentiveRatio(
        address projectToken,
        uint256 liquidationIncentiveRatioNumerator,
        uint256 liquidationIncentiveRatioDenominator
    ) public onlyListedProjectToken(projectToken) onlyDao {
        require(liquidationIncentiveRatioNumerator >= liquidationIncentiveRatioDenominator, "USBController: invalid liquidationIncentive");
        liquidationIncentiveRatio[projectToken] = Ratio(liquidationIncentiveRatioNumerator, liquidationIncentiveRatioDenominator);
    }

    function setProjectTokenBorrowCap(
        address projectToken, 
        uint256 borrowCap
    ) public onlyListedProjectToken(projectToken) onlyDao {
        require(borrowCap > 0, "USBController: borrowCap=0");
        projectTokenBorrowCap[projectToken] = borrowCap;
    }

    function setProjectTokenPause(
        address projectToken, 
        bool pause
    ) public onlyListedProjectToken(projectToken) onlyDao {
        isProjectTokenPaused[projectToken] = pause;
    }

    /********************** END DAO FUNCTIONS ********************** */

    /********************** VIEW FUNCTIONS ********************** */

    function getProjectTokenLength() public view returns(uint256) {
        return projectTokens.length;
    }

    function getAllProjectTokens() public view returns(address[] memory){
        return projectTokens;
    }
 

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PriceProviderAggregator.sol";

contract USBPriceOracle is PriceProviderAggregator
{

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";


contract USBStabilityPool is  Initializable,
                              PausableUpgradeable,
                              AccessControlUpgradeable
{
    using SafeERC20Upgradeable for ERC20Upgradeable;

    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");

    address public usbController;

    address public usb;

    function initialize() public initializer {
        __AccessControl_init();
        __Pausable_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE , msg.sender);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller in not admin");
        _;
    }

    modifier onlyDao() {
        require(hasRole(DAO_ROLE, msg.sender), "Caller in not DAO");
        _;
    }

    modifier checkSufficency(address token, uint256 tokenAmount) {
        require(tokenAmount <= ERC20Upgradeable(token).balanceOf(address(this)), "USBStabilityPool: tokenAmount exceeded balance of USBStabilityPool contract");
        _;
    }

    /********************** ADMIN FUNCTIONS ********************** */

    function grandDaoRole(address _dao) public onlyAdmin {
        grantRole(DAO_ROLE, _dao);
    }

    function revokeDaoRole(address _dao) public onlyAdmin {
        revokeRole(DAO_ROLE, _dao);
    }

    function setUsb(address _usb) public onlyAdmin {
        require(_usb != address(0), "USBStabilityPool: invalid _usb");
        require(usb == address(0), "USBStabilityPool: usb is initialized");
        usb = _usb;
    }

    function setUsbController(address _usbController) public onlyAdmin {
        require(_usbController != address(0), "USBStabilityPool: invalid _usbController");
        require(usbController == address(0), "USBStabilityPool: usbController is initialized");
        usbController = _usbController;
    }

    function removeReserves(address token, uint256 tokenAmount) public checkSufficency(token, tokenAmount) onlyAdmin {
        ERC20Upgradeable(token).safeTransfer(msg.sender, tokenAmount);
    }

    /********************** END ADMIN FUNCTIONS ********************** */

    /********************** DAO FUNCTIONS ********************** */

    function transferToken(address token, address recipient, uint256 tokenAmount) public checkSufficency(token, tokenAmount) onlyDao {
        ERC20Upgradeable(token).safeTransfer(recipient, tokenAmount);
    }

    /********************** END DAO FUNCTIONS ********************** */

    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./priceproviders/PriceProvider.sol";

contract PriceProviderAggregator is Initializable,
                                    AccessControlUpgradeable
{

    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    
    uint8 public usdDecimals;

    mapping(address => PriceProviderInfo) public tokenPriceProvider; // address of project token => priceProvider address

    struct PriceProviderInfo {
        address priceProvider;
        bool hasSignedFunction;
    }

    event GrandModeratorRole(address indexed who, address indexed newModerator);
    event RevokeModeratorRole(address indexed who, address indexed moderator);
    event SetTokenAndPriceProvider(address indexed who, address indexed token, address indexed priceProvider);
    event ChangeActive(address indexed who, address indexed priceProvider, address indexed token, bool active);

    function initialize() public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MODERATOR_ROLE, msg.sender);
        usdDecimals = 6;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not the Admin");
        _;
    }

    modifier onlyModerator() {
        require(hasRole(MODERATOR_ROLE, msg.sender), "Caller is not the Moderator");
        _;
    }

    /****************** Admin functions ****************** */

    function grandModerator(address newModerator) public onlyAdmin {
        grantRole(MODERATOR_ROLE, newModerator);
        emit GrandModeratorRole(msg.sender, newModerator);
    }

    function revokeModerator(address moderator) public onlyAdmin {
        revokeRole(MODERATOR_ROLE, moderator);
        emit RevokeModeratorRole(msg.sender, moderator);
    }    

    /****************** end Admin functions ****************** */

    /****************** Moderator functions ****************** */

    /**
     * @dev sets price provider to `token`
     * @param token the address of token
     * @param priceProvider the address of price provider. Should implememnt the interface of `PriceProvider`
     * @param hasFunctionWithSign true - if price provider has function with signatures
     *                            false - if price provider does not have function with signatures
     */
    function setTokenAndPriceProvider(address token, address priceProvider, bool hasFunctionWithSign) public onlyModerator {
        require(token != address(0), "USBPriceOracle: invalid token");
        require(priceProvider != address(0), "USBPriceOracle: invalid priceProvider");
        PriceProviderInfo storage priceProviderInfo = tokenPriceProvider[token];
        priceProviderInfo.priceProvider = priceProvider;
        priceProviderInfo.hasSignedFunction = hasFunctionWithSign;
        emit SetTokenAndPriceProvider(msg.sender, token, priceProvider);
    }

    function changeActive(address priceProvider, address token, bool active) public onlyModerator {
        require(tokenPriceProvider[token].priceProvider == priceProvider, "USBPriceOracle: mismatch token`s price provider");
        PriceProvider(priceProvider).changeActive(token, active);
        emit ChangeActive(msg.sender, priceProvider, token, active);
    }

    /****************** main functions ****************** */

    /**
     * @dev returns tuple (priceMantissa, priceDecimals)
     * @notice price = priceMantissa / (10 ** priceDecimals)
     * @param token the address of token wich price is to return
     */
    function getPrice(address token) public view returns(uint256 priceMantissa, uint8 priceDecimals){
        PriceProviderInfo memory priceProviderInfo = tokenPriceProvider[token];
        require(priceProviderInfo.hasSignedFunction == false, "USBPriceOracle: call getPriceWithSign()");
        return PriceProvider(priceProviderInfo.priceProvider).getPrice(token);
    }

    /**
     * @dev returns the tupple (priceMantissa, priceDecimals) of token multiplied by 10 ** priceDecimals given by price provider.
     * price can be calculated as  priceMantissa / (10 ** priceDecimals)
     * i.e. price = priceMantissa / (10 ** priceDecimals)
     * @param token the address of token
     * @param priceMantissa - the price of token (used in verifying the signature)
     * @param validTo - the timestamp in seconds (used in verifying the signature)
     * @param signature - the backend signature of secp256k1. length is 65 bytes
     */
    function getPriceSigned(address token, uint256 priceMantissa, uint256 validTo, bytes memory signature) public view returns(uint256 priceMantissa_, uint8 priceDecimals){
        PriceProviderInfo memory priceProviderInfo = tokenPriceProvider[token];
        if (priceProviderInfo.hasSignedFunction) {
            return PriceProvider(priceProviderInfo.priceProvider).getPriceSigned(token, priceMantissa, validTo, signature);
        } else {
            return PriceProvider(priceProviderInfo.priceProvider).getPrice(token);
        }
    }

    /**
     * @dev returns the USD evaluation of token by its `tokenAmount`
     * @param token the address of token to evaluate
     * @param tokenAmount the amount of token to evaluate
     */
    function getEvaluation(address token, uint256 tokenAmount) public view returns(uint256 evaluation){
        PriceProviderInfo memory priceProviderInfo = tokenPriceProvider[token];
        require(priceProviderInfo.hasSignedFunction == false, "USBPriceOracle: call getEvaluationWithSign()");
        return PriceProvider(priceProviderInfo.priceProvider).getEvaluation(token, tokenAmount);
    }
    
    /**
     * @dev returns the USD evaluation of token by its `tokenAmount`
     * @param token the address of token
     * @param tokenAmount the amount of token including decimals
     * @param priceMantissa - the price of token (used in verifying the signature)
     * @param validTo - the timestamp in seconds (used in verifying the signature)
     * @param signature - the backend signature of secp256k1. length is 65 bytes
     */
    function getEvaluationSigned(address token, uint256 tokenAmount, uint256 priceMantissa, uint256 validTo, bytes memory signature) public view returns(uint256 evaluation){
        PriceProviderInfo memory priceProviderInfo = tokenPriceProvider[token];
        if (priceProviderInfo.hasSignedFunction) {
            return PriceProvider(priceProviderInfo.priceProvider).getEvaluationSigned(token, tokenAmount, priceMantissa, validTo, signature);
        } else {
            return PriceProvider(priceProviderInfo.priceProvider).getEvaluation(token, tokenAmount);
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

abstract contract PriceProvider {

    function changeActive(address token, bool active) public virtual {}

    /****************** view functions ****************** */

    function isActive(address token) public virtual view returns(bool) {}

    function isListed(address token) public virtual view returns(bool) {}

    function getPrice(address token) public virtual view returns(uint256 priceMantissa, uint8 priceDecimals) {}

    function getPriceSigned(address token, uint256 priceMantissa, uint256 validTo, bytes memory signature) public virtual view returns(uint256 _priceMantissa, uint8 _priceDecimals) {}

    function getEvaluation(address token, uint256 tokenAmount) public virtual view returns(uint256 evaluation) {}
    
    /**
     * @dev return the evaluation in $ of `tokenAmount` with signed price
     * @param token the address of token to get evaluation in $
     * @param tokenAmount the amount of token to get evaluation. Amount is scaled by 10 in power token decimals
     * @param priceMantissa the price multiplied by priceDecimals. The dimension of priceMantissa should be $/token
     * @param validTo the timestamp in seconds, when price is gonna be not valid.
     * @param signature the ECDSA sign on eliptic curve secp256k1.        
     */
    function getEvaluationSigned(address token, uint256 tokenAmount, uint256 priceMantissa, uint256 validTo, bytes memory signature) public virtual view returns(uint256 evaluation) {}

    function getPriceDecimals() public virtual view returns (uint8 priceDecimals) {}

}