// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./Investor.sol";
import "../interfaces/revManager/IRevenueManager.sol";
import "../libraries/PoolRateCalculator.sol";
import {ONE_YEAR} from "../Globals.sol";
import "../interfaces/newInterfaces/investor/IpoolInvestor.sol";
import "../testing/TestToken.sol";      /// todo replace with real token one day
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {POOL_INVESTOR_VERSION} from "../ContractVersions.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PoolInvestor
 * @author Carson Case [[email protected]]
 * @dev TestToken will eventually be replaced with ERC-20
 */
contract PoolInvestor is IpoolInvestor, Investor, ERC20, Ownable {
    using PoolRateCalculator for uint;

    // config vars
    uint256 public override tradeAmount = 1 ether / 100;
    uint256 public override margin = 1 ether / 1000;
    uint256 public override reserveRate = ONE_HUNDRED_PERCENT;

    uint256 public poolValue;

    mapping(address => uint) public override stakeTimes;
    // Events
    event LiquidityDeposited(uint256 timestamp, address indexed pool, address indexed depositor, uint indexed amountDeposited);
    event LiquidityWithdrawn(uint256 timestamp, address indexed pool, address indexed withdrawer, uint indexed amountWithdrawn);
    event InterestRateAnnualSet(uint256 timestamp, address indexed pool, uint256 indexed interestRate);
    event ReserveRateSet(uint256 timestamp, address indexed pool, uint256 indexed reserveRate);
    event StakingRewardClaimed(uint256 timestamp, address indexed staker, uint256 indexed rewards);
    
    constructor(
        IAddressBook _addressBook,
        address _token,
        bytes1 _prefix,
        bytes1 _postfix
    ) Investor(_addressBook, IERC20(_token))
        ERC20(
        "Roci Debt Token",
        string(
            abi.encodePacked(_prefix, sIERC20(_token).symbol(), _postfix)
        )
    )
    Ownable()
    {
        token = IERC20(_token);
        _updateApprovals();
    }

    /**
     * @dev owner can set interestRateAnnual
     * @param _interestRateAnnual new interestRateAnnual
     */
    function setInterestRateAnnual(uint256 _interestRateAnnual)
        external
        override
        onlyRole(Role.admin)
    {
        require(_interestRateAnnual > 0, "Interest rate have to be positive");
        interestRateAnnual = _interestRateAnnual;
        emit InterestRateAnnualSet(block.timestamp, address(this), _interestRateAnnual);
    }

    /**
    * @dev function for dev to update approvals if addresses have changed
    * but for now this is the way this is being done. I'm sorry. I'm not even going to try and explain this
    * just ask to talk with Carson if you need to understand it right now
     */
    function updateApprovals() external onlyRole(Role.admin){
        _updateApprovals();
    }

    /// @dev setter for reserve rate
    function setReserveRate(uint _new) external override onlyOwner{
        reserveRate = _new;
        emit ReserveRateSet(block.timestamp, address(this), _new);
    }

    /**
    * @dev Returns debt token price
     */
    function getDebtTokensToMintAmount(uint _amount) public view returns (uint256 toMint) {
        IRevenueManager revManager = IRevenueManager(lookup(Role.revManager));
        if(totalSupply() == 0){
            return toMint = _amount;
        }
        require(poolValue > 0, "Error. PoolInvestor: Pool value = 0");
        toMint = (_amount * totalSupply()) / poolValue;
        
    }

    function getWithdrawalTokenReturnAmount(uint _amount) public view returns(uint256 toReturn){
        IRevenueManager revManager = IRevenueManager(lookup(Role.revManager));
        
        require(totalSupply() > 0, "Error. PoolInvestor: totalSupply() = 0");
        toReturn = (_amount * poolValue) / totalSupply();
    }

    /**
    * @dev deposits stablecoins for some rate of rTokens
    * NOTE ideally should send stright to revManager, but user would need to approve it
     */
    function depositPool(uint _amount, string memory version) 
        external 
        override 
        whenNotPaused
        checkVersion(version){

        uint toMint = getDebtTokensToMintAmount(_amount);

        poolValue += _amount;
        // note this is a bit inneficient. But easier for FE guys.....  Not sure what's better
        token.transferFrom(msg.sender, address(this), _amount);
        _sendAllToRevManager();

        stakeTimes[msg.sender] = block.timestamp;
        _mint(msg.sender, toMint);

        emit LiquidityDeposited(block.timestamp, address(this), msg.sender, _amount);
    }

    /**
    * @dev function to exchange rToken back for stablecoins
     */
    function withdrawalPool(uint _amount, string memory version)
        external
        override
        whenNotPaused
        checkVersion(version)
    {
        IRevenueManager revManager = IRevenueManager(lookup(Role.revManager));
        uint toReturn = getWithdrawalTokenReturnAmount(_amount);
        _burn(msg.sender, _amount);
        revManager.requestFunds(address(token), toReturn);
        poolValue -= toReturn;
        token.transfer(msg.sender, toReturn);
        stakeTimes[msg.sender] = block.timestamp;

        emit LiquidityWithdrawn(block.timestamp, address(this), msg.sender, _amount);
    }

    /**
    * @dev same as function in Investor. But we count accrued interest and 
    * send all funds to RevenuManager after
     */
    function collect(uint256[] memory _ids, string memory version)
        public
        virtual
        override(Investor, Iinvestor)
        whenNotPaused
        checkVersion(version)
    {
        IBonds bonds = IBonds(lookup(Role.bonds));

        IERC20CollateralPayment paymentc = IERC20CollateralPayment(
        lookup(Role.paymentContract)
        );
        
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            uint256 stakeIndex = stakingIndexes[_id];
            
            (,,,uint balBefore,) = bonds.getStakingAt(address(this), stakeIndex);
            // unstake bonds to collect interest
            bonds.unstake(stakeIndex);
            uint256 bal = bonds.balanceOf(address(this), _id);
            require(bal >= balBefore, "ERROR. PoolInvestor.collect(): Bonds were lost in unstaking");
            // accrue pool value with interest
            poolValue += bal - balBefore;

            // withdrawal profit
            uint256 awaitingCollection = paymentc.loanLookup(_id).awaitingCollection;
            if (bal >= awaitingCollection) {
                paymentc.withdrawl(_id, awaitingCollection, address(this));
                bal = bonds.balanceOf(address(this), _id);
            }
            // stake remaining bonds again
            stakeIndex = bonds.stake(_id, bal);
        }
        _sendAllToRevManager();
    }    

    /**
    * @dev liquidators liquidate through a loan's investor for incentives
    *   also ensures we can track funds lost
     */
    function liquidate(uint _id) external{
        IERC20CollateralPayment paymentc = IERC20CollateralPayment(
        lookup(Role.paymentContract)
        );
        // unstake so we own some bonds and can liquidate
        uint256 stakeIndex = stakingIndexes[_id];
        IBonds(lookup(Role.bonds)).unstake(stakeIndex);

        poolValue -= Loan.getOutstanding(paymentc.loanLookup(_id));
        // liquidate
        paymentc.liquidate(_id, address(this));
        
        //todo swap the collateral liquidated for token. Add that to pool value

        // also add incentive for caller
    }
    
    /**
     * @dev function to send funds to borrowers. Used to fulfill loans
     * @param _receiver is the receiver of the funds
     * @param _amount is the amount to send
     * NOTE this is meant to be overriden in order to contain logic for storing funds in other contracts
     */
    function _sendFunds(address _receiver, uint256 _amount) internal override {
        IRevenueManager revManager = IRevenueManager(lookup(Role.revManager));

        revManager.requestFunds(address(token), _amount);
        super._sendFunds(_receiver, _amount);
    }

    /**
     * @dev function helps check to make sure a loan is available before it's fulfilled
     *   thus saving the user the gas of a failed fullfilment
     */
    function _checkAvailable(uint256 _amount) internal override {
        IRevenueManager revManager = IRevenueManager(lookup(Role.revManager));

        uint available = revManager.balanceAvailable(address(this), address(token));
        require(available >= _amount,
            "There are not enough funds available to fulfill this loan"
        );

        require((totalSupply() * reserveRate) / ONE_HUNDRED_PERCENT <= available - _amount, "Cannot borrow at this time, the contract needs more funds to finance loans");

        super._checkAvailable(_amount);
    }

    /**
     * @dev helper function to send all funds to rev manager
     */
    function _sendAllToRevManager() internal {
        IRevenueManager revManager = IRevenueManager(lookup(Role.revManager));

        uint256 bal = token.balanceOf(address(this));
        revManager.payment(address(token), bal);
    }

    function _updateApprovals() internal{
        IBonds bonds = IBonds(lookup(Role.bonds));
        IERC20CollateralPayment paymentc = IERC20CollateralPayment(lookup(Role.paymentContract));
        IRevenueManager revManager = IRevenueManager(lookup(Role.revManager));

        bonds.setApprovalForAll(address(paymentc), true);
        token.approve(address(revManager), uint256(2**256 - 1));
    }

    /**
     * @notice returns the current version of the contract.
     */
    function currentVersion() public pure override returns (string memory) {
        return POOL_INVESTOR_VERSION;
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../interfaces/newInterfaces/payment/IERC20CollateralPayment.sol";
import "../interfaces/newInterfaces/investor/Iinvestor.sol";
import "../interfaces/IBonds.sol";
import "../utilities/AddressHandler.sol";
import { ScoreDBV2Interface } from "../interfaces/ScoreDBV2Interface.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ONE_HUNDRED_PERCENT} from "../Globals.sol";
import {IAddressBook} from "../interfaces/IAddressBook.sol";
import {Version} from "../Version/Version.sol";

/**
 * @title sIERC20
 * @dev just adds the symbol function to IERC20
 */
interface sIERC20 is IERC20 {
  function symbol() external returns (string memory);
}

/**
 * @title Investor
 * @author Carson Case [[email protected]]
 */
abstract contract Investor is
  Iinvestor,
  ERC1155Holder,
  AddressHandler,
  Pausable,
  Version
{
  using SafeERC20 for IERC20;
  uint256 public override interestRateAnnual = 10 ether;
  string investorsAddressLookupCategory;

  /// NOTE token is not upgradeable through address book. This is to prevent making a big mistake, as this should never change
  IERC20 public token;

  // map loan ids to staking indexes
  mapping(uint256 => uint256) stakingIndexes;
  // Events
  event BorrowSuccessful(
    uint256 timestamp,
    address indexed borrower,
    uint256 indexed loanId,
    uint256 indexed amount,
    uint256 duration,
    address collateralToken,
    uint256 collateralAmount
  );

  constructor(IAddressBook _addressBook, IERC20 _token)
    AddressHandler(_addressBook, "NewDeploy")
  {
    token = _token;
  }

  /**
   * @dev function to combine the entire borrowing process in one function.
   *   1). configure
   *   2). mint
   *   3). exchange
   *
   * NOTE: the user will need to sign with the address of this and the ID of the loan. This is how they get their
   *   new loan's id before calling:
   *       id = getId(_borrower, getNumberOfLoans(address _borrower));
   *
   * @param args is an object of all the params for borrowing
   */
  function borrow(Structs.BorrowArgs calldata args, string memory version)
    external
    override
    whenNotPaused
    checkVersion(version)
  {
    IBonds bonds = IBonds(lookup(Role.bonds));
    IERC20CollateralPayment paymentc = IERC20CollateralPayment(
      lookup(Role.paymentContract)
    );

    // set up loan config here
    _checkAvailable(args._amount);
    uint256 accrualPeriod = 60 * 60 * 24 * 30;
    uint256 periodsInYear = 12;
    uint256 id = paymentc.configureNew(
      address(token),
      msg.sender,
      0,
      args._NFCSID,
      addressBook.getMaturityDate(),
      args._amount,
      interestRateAnnual / periodsInYear,
      accrualPeriod
    );

    // collect collateral
    /// NOTE borrower must approve the Collateral Manager to spend these funds NOT the investor
    if (args._collateralAmount > 0) {
      paymentc.addCollateral(
        msg.sender,
        args._collateral,
        args._collateralAmount
      );
    }

    // check score here
    /// todo add score check however it is we decide to do that
    /// note try and have this taken care of in NFCS....

    // begin fulfilling the loan
    // this function calls the issue function which requires non-delinquency
    bonds.newLoan(address(paymentc), id, args._hash, args._signature);

    require(
      bonds.balanceOf(address(this), id) == args._amount,
      "Issue minting bonds"
    );

    // stake the bonds to start collecting interest
    stakingIndexes[id] = bonds.stake(id, args._amount);

    // fulfill loan to borrower of loan
    _sendFunds(msg.sender, args._amount);
    // Event
    emit BorrowSuccessful(
      block.timestamp,
      paymentc.loanLookup(id).borrower,
      id,
      paymentc.loanLookup(id).principal,
      paymentc.loanLookup(id).maturityDate,
      args._collateral,
      args._collateralAmount
    );
  }

  /**
   * @dev collects an array of loan id's payments to this
   * @param _ids to collect on
   */
  function collect(uint256[] memory _ids, string memory version)
    public
    virtual
    override
    whenNotPaused
    checkVersion(version)
  {
    IBonds bonds = IBonds(lookup(Role.bonds));

    IERC20CollateralPayment paymentc = IERC20CollateralPayment(
      lookup(Role.paymentContract)
    );
    for (uint256 i = 0; i < _ids.length; i++) {
      uint256 _id = _ids[i];
      uint256 stakeIndex = stakingIndexes[_id];

      // unstake bonds to collect interest
      bonds.unstake(stakeIndex);
      uint256 bal = bonds.balanceOf(address(this), _id);
      // withdrawal profit
      // note this implies this Investor is the ONLY lender of this loan
      uint256 awaitingCollection = paymentc.loanLookup(_id).awaitingCollection;
      
      // if the bond balance is >= awaiting collection then collect what we can
      if (bal >= awaitingCollection) {
        paymentc.withdrawl(_id, awaitingCollection, address(this));
        bal = bonds.balanceOf(address(this), _id);
      // otherwise collect all we have in bonds. This should only be in the case of a mistake of the borrower paying too much
      }else{
        paymentc.withdrawl(_id, bal, address(this));
        bal = bonds.balanceOf(address(this), _id);
      }
      // stake remaining bonds again
      stakeIndex = bonds.stake(_id, bal);
    }
  }

  /**
   * @dev function to send funds to borrowers. Used to fulfill loans
   * @param _receiver is the receiver of the funds
   * @param _amount is the amount to send
   * NOTE this is meant to be overriden in order to contain logic for storing funds in other contracts
   */
  function _sendFunds(address _receiver, uint256 _amount) internal virtual {
    token.safeTransfer(_receiver, _amount);
  }

  /**
   * @dev function helps check to make sure a loan is available before it's fulfilled
   *   thus saving the user the gas of a failed fullfilment
   */
  function _checkAvailable(uint256 _amount) internal virtual {
    require(_amount > 0, "Cannot borrow an amount of 0");
    // check the oracle is not paused if pause functionality is added
  }

  function pause() public onlyRole(Role.admin) {
    _pause();
  }

  function unpause() public onlyRole(Role.admin) {
    _unpause();
  }
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./IPaymentSplitter.sol";

interface IRevenueManager is IPaymentSplitter{

    function balanceAvailable(address, address) external view returns(uint);

    function requestFunds(address, uint) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {ONE_HUNDRED_PERCENT} from "../Globals.sol";

/**
* @title ReserveBondingCurve
* @author Carson Case ([email protected])
* @dev library contract to allow for easy reserve ratios enabled by bonding curves. Does the math for ERC20s
 */
library PoolRateCalculator {

    /**
    * @dev returns the amount of debt tokens to be given for the amount of payment tokens input
     */
    function getDepositAmount(uint _amount, uint _paymentTokenReserve, uint _debtTokenTotalSupply, uint _reserveRate) internal pure returns(uint out){
        out = _getAmountOut(
            _amount,
            _paymentTokenReserve,                        // payment token is reserve in
            _debtTokenTotalSupply,                       // debt token is reserve out
            _reserveRate,
            true
        );
    }

    /**
    * @dev returns the amount of payment tokens to be given for the amount of payment tokens input
     */
    function getWithdrawalAmount(uint _amount, uint _paymentTokenReserve, uint _debtTokenTotalSupply, uint _reserveRate) internal pure returns(uint out){
        out = _getAmountOut(
            _amount, 
            _debtTokenTotalSupply,                      // debt token supply is reserve in, 
            _paymentTokenReserve,                       // payment token is reserve out
            _reserveRate,
            false
        );
    }

    /**
    * @dev function with the uniswap bonding curve logic but with the reserve ratio logic thrown in
        reserve ratio is for payment tokens.
        so a reserver ratio of 20% means that 20% of the debt token supply must be stored in this contract for exchange 1:1
    *
    * Formula for Debt Tokens Out = Reserve Ratio * ((stablesIn * Total Debt) / Total Liquidity + StablesIn(1- Reserve Ratio))
    *
    * Formula for Stablecoins Out = 1/Reserve Ratio * ((Debt In * Total Liquidity) / Total Debt + Debt In(1- Reserve Ratio))
     */
    function _getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint _reserveRatio, bool purchaseIn) private pure returns(uint){
        uint amountInWithFee = amountIn;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = ((reserveIn) + (((ONE_HUNDRED_PERCENT - _reserveRatio) * amountInWithFee) / ONE_HUNDRED_PERCENT));
        return purchaseIn ? 
        (numerator * _reserveRatio) / ((denominator) * ONE_HUNDRED_PERCENT) : 
        (numerator * ONE_HUNDRED_PERCENT) / ((denominator) * _reserveRatio); 
    }

}

// SPDX-License-Identifier: None
uint constant ONE_HUNDRED_PERCENT = 100 ether;      // NOTE This CAN NOT exceed 2^256/2 -1 as type casting to int occurs
uint constant LATE_PENALTY = 200 ether;
uint constant ONE_YEAR = 31556926;
uint constant APY_CONST = 3000000000 gwei;
uint constant SCORE_VALIDITY_PERIOD = 900;

address constant DEAD = 0x000000000000000000000000000000000000dEaD;

uint16 constant MIN_SCORE = 10;
uint16 constant MAX_SCORE = 1;
uint16 constant NOT_GENERATED = 0;
uint16 constant GENERATION_ERROR = 1000;

uint8 constant APY_PENALTY_MULTIPLIER = 2;
uint128 constant GRACE_PERIOD = 10 * 60 * 60 * 24;

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./Iinvestor.sol";
import {IVersion} from "../../../Version/IVersion.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title PoolInvestor
 * @author Carson Case [[email protected]]
 * @dev TestToken will eventually be replaced with ERC-20
 */
interface IpoolInvestor is IVersion, Iinvestor, IERC20 {
    enum addresses_PoolInvestor{
        token,
        bonds,
        paymentContract,
        trader,
        revManager
    }
    // state variables
    function tradeAmount() external returns(uint256);
    function margin() external returns(uint256);
    function reserveRate() external returns(uint256);
    function stakeTimes(address) external returns(uint256);

    /**
     * @dev owner can set interestRateAnnual
     * @param _interestRateAnnual new interestRateAnnual
     */
    function setInterestRateAnnual(uint256 _interestRateAnnual) external;

    /// @dev setter for reserve rate
    function setReserveRate(uint _new) external;

    /**
    * @dev deposits stablecoins for some rate of rTokens
    * NOTE ideally should send stright to revManager, but user would need to approve it
     */
    function depositPool(uint _amount, string memory _version) external;

    /**
    * @dev function to exchange rToken back for stablecoins
     */
    function withdrawalPool(uint _amount, string memory _version) external;

}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20{

    

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol){
        _mint(msg.sender, 10000000000 ether);
    }

    // function setAllowance(address owner, address spender,uint256 amount) public {
    //     // super._allowances[owner][spender]=amount;

    // }

    function setAllowance(address owner,address spender, uint256 value) public virtual returns (bool) {
        _approve(owner, spender,  value);
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
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
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

// SPDX-License-Identifier: None
string constant NFCS_VERSION = "1.0.0";
string constant POOL_INVESTOR_VERSION = "1.0.0";
string constant ROCI_PAYMENT_VERSION = "1.0.0";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./IERC20PaymentStandard.sol";
import "../../../Version/IVersion.sol";

/**
 * @title IERC20PaymentStandard
 * @author Carson Case
 * @dev 
 * ERC20CollateralPayment should only deal with adding collateral to the existing payment system. 
 * CollateralPayment changes the definition of delinquent loans to be loans that don’t meat LTV/LT requirements 
 * as defined by a loan’s NFCS. Collateral payment also allows for liquidations by liquidators. 
 * However, collateralPayment does not hold any collateral and instead delegates the holding of collateral to a manager. 
 * CollateralPayment only handles logic for collateral and it’s relation to a loan’s status. 
*/
interface IERC20CollateralPayment is IVersion, IERC20PaymentStandard {
    // more addresses for address book
    enum addresses_Collateral{
        bondContract,
        NFCS,
        collateralManager,
        priceFeed,
        oracle
    }

    // addresses removed in favor of addressBook.

    /**
     * @notice addCollateral must be called before issuing loan
     * @param _ERC20Contract address of the ERC20 you want to have as collaterall. DOES NOT have to be equal to payment ERC20
     * @param _amount is the ammount to add as collateral
     */
    function addCollateral(
        address _from,
        address _ERC20Contract,
        uint256 _amount
    ) external;

    // NOTE no need for changing manager or price feed since they're in addressBook

    /**
    * @dev liquidate function callable by bond holders
    */
    function liquidate(uint256 _id, address _receiver) external;

    /*
     * @notice function for user to claim their collateral as they go. Must be within their LTV
     * @param _token to collect
     * @param _amount to withdrawal
     */
    function claimCollateral(address _token, uint256 _amount, string memory version) external;

    // NOTE removed liquidate by admin

}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import {IAddressBook} from "../../IAddressBook.sol";
import {IVersion} from "../../../Version/IVersion.sol";
import "../../../libraries/Structs.sol";

/**
 * @title Investor
 * @author Carson Case [[email protected]]
 * @dev is an ERC20
 */
interface Iinvestor is IVersion {
    /*
    State variables
     */
    function interestRateAnnual() external returns(uint256);
    // note addresses are replaced with address book
    // enum is the index in the array returned by addressBook's function
    enum addresses_Investor{
        token,
        bonds,
        paymentContract
    }

    function borrow(Structs.BorrowArgs calldata, string memory) external;

    /**
     * @dev collects an array of loan id's payments to this
     * @param _ids to collect on
     */
    function collect(uint256[] memory _ids, string memory _version) external;

}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IBonds is IERC1155{
    function IDToContract(uint256) external returns(address);

    function head() external returns(uint256);

    function llTail(address) external returns(uint256);
    
    function getStakingAt(address, uint256) external view returns(uint, uint, uint256, uint256, uint256);

    function newLoan(address, uint256, bytes32, bytes memory) external;
    
    function stake(uint256, uint256) external returns(uint);

    function unstake(uint256) external returns(bool);    

    function getAccruances(address, uint256) external view returns(uint256);

    function getInterest(address, uint256, uint256, uint256) external view returns(uint256);

}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import {IAddressBook} from "../interfaces/IAddressBook.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AddressHandler{
    string internal _category;
    enum Role{
        token,
        bonds,
        paymentContract,
        trader,
        revManager,
        NFCS,
        collateralManager,
        priceFeed,
        oracle,
        admin
    }

    IAddressBook public addressBook;

    constructor(IAddressBook _addressBook, string memory _startingCategory){
        addressBook = _addressBook;
        _category = _startingCategory;
    }

    modifier onlyRole(Role _role){
        require(msg.sender == lookup(_role),
                string(
                    abi.encodePacked(
                        "AddressHandler: account ",
                        Strings.toHexString(uint160(msg.sender), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(_role), 32)
                    )
                )
            );
        _;
    }

    function changeCateogory(string memory _newCategory) external onlyRole(Role.admin){
        _category = _newCategory;
    }

    function lookup(Role _role) internal view returns(address contractAddress){
        contractAddress = addressBook.addressList(_category)[uint(_role)];
        require(contractAddress != address(0), 
            string(
                abi.encodePacked("AddressHandler: lookup failed for role: ", 
                Strings.toHexString(uint256(_role), 32)
                )
            )
        );
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../libraries/Structs.sol";
import "./IScoreConfigs.sol";

/// @notice Interface for the ScoreDB contract.

interface ScoreDBV2Interface is IScoreConfigs {
    // Returns the current scored for the token from the on-chain storage.
    function getScore(uint256 tokenId)
        external
        view
        returns (Structs.Score memory);

    // Called by the lending contract, initiates logic to update score and fulfill loan.
    function pause() external;

    // UnPauses the contract [OWNER]
    function unpause() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

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

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IAddressBook{
    function addressList(string memory _category) external view returns(address[] memory);
    function getDailyLimit() external  view returns (uint128);
    function getGlobalLimit() external view returns (uint128);
    function setDailyLimit(uint128 newLimit) external;
    function setGlobalLimit(uint128 newLimit) external;
    function getMaturityDate() external view returns (uint256);
    function setLoanDuration(uint256 _newLoanDuration) external;

    function getUserDailyLimit() external  view returns (uint128);
    function getUserGlobalLimit() external view returns (uint128);
    function setUserDailyLimit(uint128 newLimit) external;
    function setUserGlobalLimit(uint128 newLimit) external;
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;
import {IVersion} from "./IVersion.sol";

/// @title  Abstract contract for implementing versioning functionality
/// @author Konstantin Samarin
/// @notice Used to mark backwards-incompatible changes to the contract logic.
///         checkVersion modifier should be applied to all external mutating methods

abstract contract Version is IVersion {
    /**
     * @notice converts string to bytes32
     */
    function getVersionAsBytes(string memory v) public pure override returns (bytes32 result) {
        if (bytes(v).length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(v, 32))
        }
    }

    /**
     * @notice 
     * Controls the call of mutating methods in versioned contract.
     * The following modifier reverts unless the value of the `versionToCheck` argument
     * matches the one provided in currentVersion method.
     */
    modifier checkVersion(string memory versionToCheck) {
        require(
            getVersionAsBytes(this.currentVersion()) == getVersionAsBytes(versionToCheck),
            "Incorrect version"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import {IAddressBook} from "../../IAddressBook.sol";
import "../../../libraries/Loan.sol";
import {IVersion} from "../../../Version/IVersion.sol";

/**
 * @title IERC20PaymentStandard
 * @author Carson Case
 * @dev
 * Payment Standard is meant to be the bare minimum of payment logic required to interact with Bonds 
 * and the rest of the ecosystem. 
 * Payment contract should only have logic for starting loans (configure and issue), 
 * making payments, collecting interest, and retrieving getting loan info.
 *
 * There should also only be **one** Payment contract. The key difference here for Payment Standard is that it is no 
 * longer unique to each investor. And instead will share it’s logic with all of them. 
 * Payment Standard also should be marked abstract enforcing that it is inherited by it’s child.
 * This means removing all the limits logic and moving it to a child contract like collateral or a specific RociPayment contract.
 */
 
interface IERC20PaymentStandard is IVersion {
    // NOTE 154 Bonds.sol 
    // (uint256 interest, ) = pc.getLoanInfo(id);
    // this function is removed. Use loanLookup in Bonds

    // ---------------
    // State Variables
    // ---------------
    function MAXIMUM_BORROW_LIMIT() external returns(uint);
    
    // note addresses are replaced with address book
    // enum is the index in the array returned by addressBook's function
    enum addresses_Payment{
        bondContract,
        NFCS
    }

    function investorsAddressLookupCategory() external returns(string memory);

    // Two mappings. One to get the loans for a user. And the other to get the the loans based off id
    
    // note these are removed as they're mappings and mess with the inheritance. If needed replace with getter functions
    function loanLookup(uint _id) external view returns(Loan.loan memory);
    // function loanIDs(address) external returns(uint[] memory);


    /**
     * @notice called when bonds are issued so as to make sure lender can only mint bonds once.
     * @param _id loan ID
     * @return the loan principal (so bonds knows how many NFTs to mint)
     * @return the borrowers address (so bonds can make sure borrower is calling this function)
     */
    function issueBonds(uint256 _id)
        external
        returns (uint256, address);

    /**
     * @notice gets the number of loans a person has
     * @param _who is who to look up
     * @return length
     */
    function getNumberOfLoans(address _who)
        external
        view
        returns (uint256);

    /**
     * @notice Called each time new NFTs are minted by staking
     * @param _am the amount of interest to add
     * @param _id is the id of the loan
     * @return true if added. Will not add interest if payment has been completed.
     *This prevents lenders from refusing to end a loan when it is rightfully over by forever
     *increasing the totalPaymentsValue through interest staking and never fully collecting payment.
     *This also means that if lenders do not realize interest gains soon enough they may not be able to collect them before
     *the borrower can complete the loan.
     */
    function addInterest(uint256 _am, uint256 _id)
        external
        returns (bool);


    /**
     * @param _id is the hash id of the loan. Same as bond ERC1155 ID as well
     * @return if delinquent or not. Meaning missed a payment
     */
    function isDelinquent(uint256 _id) external view returns (bool);

    /**
     * @notice contract must be configured before bonds are issued. Pushes new loan to array for user
     * @param _erc20 is the ERC20 contract address that will be used for payments
     * @param _borrower is the borrower loan is being configured for. Keep in mind. ONLY this borrower can mint bonds to start the loan
     * @param _NFCSID is the user's NFCS NFT ID from Roci's Credit scoring system
     * @param _minPayment is the minimum payment that must be made before the payment period ends
     * @param _maturityDate payment must be made by this time or delinquent function will return true
     * @param _principal the origional loan value before interest
     * @param _interestRate the interest rate expressed as inverse. 2% = 1/5 = inverse of 5
     * @param _accrualPeriod the time it takes for interest to accrue in seconds
     * @return the id it just created
     */
    function configureNew(
        address _erc20,
        address _borrower,
        uint256 _minPayment,
        uint256 _NFCSID,
        uint256 _maturityDate,
        uint256 _principal,
        uint256 _interestRate,
        uint256 _accrualPeriod
    ) external returns (uint256);

    /**
     * @notice MUST approve this contract to spend your ERC1155s in bonds. Used to have this auto handled by the on received function.
     * However that was not a good idea as a hacker could create fake bonds.
     * @param _id is the id of the bond to send in
     * @param _amm is the amount to send
     * @param _receiver is the receiver of erc20 tokens
     */
    function withdrawl(
        uint256 _id,
        uint256 _amm,
        address _receiver
    ) external;

    /**
     * @notice function handles the payment of the loan. Does not have to be borrower
     *as payment comes in. The contract holds it until collection by bond owners. MUST APPROVE FIRST in ERC20 contract first
     * @param _id to pay off
     * @param _erc20Amount is amount in loan's ERC20 to pay
     */
    function payment(uint256 _id, uint256 _erc20Amount, string memory version)
        external;

    /**
     * @notice helper function
     * @param _id of loan to check
     * @return return if the contract is payed off or not as bool
     */
    function isComplete(uint256 _id) external view returns (bool);

    /**
     * @notice Returns the ID for a loan given the borrower and index in the array
     * @param _borrower is borrower
     * @param _index is the index in the borrowers loan array
     * @return the loan ID
     */
    //
    function getId(address _borrower, uint256 _index)
        external
        view
        returns (uint256);

    /**
    * @dev function to get a user's total outstanding balance (By NFCS ID)  
    * @param _nfcsId NFCS ID
    * @return total Oustanding balance
    */
    function getNFCSTotalOustanding(uint _nfcsId) external view returns(uint);

 /**
    * @dev function to get a system total outstanding balance  
    * @return total Oustanding balance
    */
    function getTotalOustanding() external view returns(uint);

}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

/// @title  Interface for implementing versioning of contracts
/// @author Konstantin Samarin
/// @notice Used to mark backwards-incompatible changes to the contract logic.
///         All interfaces of versioned contracts should inherit this interface

interface IVersion {
    /**
     * @notice returns the current version of the contract
     */
    function currentVersion() external pure returns(string memory);

    /**
     * @notice converts string to bytes32
     */
    function getVersionAsBytes(string memory v) external pure returns (bytes32 result);
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import {APY_PENALTY_MULTIPLIER} from "../Globals.sol";

/**
* @title Loan
* @author Carson Case
* @dev Library to abstract out edits to Loan object to help with global variable tracking
    NOTE
    In this library the function paramaters may seem confusing
    This is because there are special global/local instances of these loan objects

    _ln is an individual loan
    _user is a user's global amount in this payment contract
    _global is the payment contracts total sums
 */
library Loan{
    uint constant public DAY = 60*60*24;
    //Loan object. Stores lots of info about each loan
    enum Status{UNISSUED, NEW, APPROVED, PAIDPART, CLOSED, PAIDLATE, LIQUIDATED}
    struct loan {
        Status status;
        address ERC20Address;
        address borrower;
        uint256 nfcsID;
        uint256 maturityDate;
        uint128 issueDate;
        uint256 minPayment;
        uint256 interestRate;
        uint256 accrualPeriod;
        uint256 principal;
        uint256 totalPaymentsValue;
        uint256 awaitingCollection;
        uint256 paymentComplete;
        uint256 ltv;
        uint256 lt;
    }

    struct globalInfo{
        uint256 principal;
        uint256 totalPaymentsValue;
        uint256 awaitingCollection;
        uint256 paymentComplete;
        uint128 borrowedToday;
        uint128 lastBorrowTimestamp;
    }

    struct limits{
        uint128 totalLimit;
        uint128 dailyLimit;
        uint128 userTotalLimit;
        uint128 userDailyLimit;
    }

    /**
    * @dev onPayment function to check and handle updates to struct for payments
    * @param _ln individual loan
    * @param _user global loan for user
    * @param _global global loan for the whole contract
     */
    function onPayment(loan storage _ln, globalInfo storage _user, globalInfo storage _global, uint _erc20Amount) internal{
        require(
            _erc20Amount >= _ln.minPayment || //Payment must be more than min payment
                (
                getOutstanding(_ln) < _ln.minPayment  //Exception for the last payment (remainder)
                &&
                _erc20Amount >= getOutstanding(_ln)  // Exception is only valid if user is paying the loan off in full on this transaction
                ),
            "You must make the minimum payment"
        );

        _ln.awaitingCollection += _erc20Amount;
        _user.awaitingCollection += _erc20Amount;
        _global.awaitingCollection += _erc20Amount;


        _ln.paymentComplete += _erc20Amount; //Increase paymentComplete
        _user.paymentComplete += _erc20Amount;
        _global.paymentComplete += _erc20Amount;

        // do a status update for anything payment dependant
        if(isComplete(_ln)){
            _ln.status = Status.CLOSED;
        }else if(_erc20Amount > 0 && !isLate(_ln)){
            _ln.status = Status.PAIDPART;
        }else if(isLate(_ln)){
            _ln.status = Status.PAIDLATE;
        }

        _updateLoanDay(_user);
    }

    function onWithdrawal(loan storage _ln, globalInfo storage _user, globalInfo storage _global, uint _erc20Amount) internal{
        _ln.awaitingCollection -= _erc20Amount;
        _user.awaitingCollection -= _erc20Amount;
        _global.awaitingCollection -= _erc20Amount;
    }

    function onLiquidate(loan storage _ln) internal{
        _ln.status = Status.LIQUIDATED;
    }

    function limitCheck(loan storage _ln, globalInfo storage _user, globalInfo storage _system, limits memory _limits
        , uint _userTotalOutstanding, uint _totalOutstanding) internal{
        if(_limits.dailyLimit != 0) {
            _updateLoanDay(_system);
            require(_system.borrowedToday + _ln.principal <= _limits.dailyLimit, "Exceeds daily borrow limit");
            _system.borrowedToday += uint128(_ln.principal);
        }
        if(_limits.userDailyLimit != 0) {
            _updateLoanDay(_user);
            require(_user.borrowedToday + _ln.principal <= _limits.userDailyLimit, "Exceeds your daily borrow limit");
            _user.borrowedToday += uint128(_ln.principal);
        }
        if(_limits.userTotalLimit != 0) {
            require(_userTotalOutstanding <= _limits.userTotalLimit, "Exceeds your total borrow limit");
        }
        if(_limits.totalLimit != 0) {
            require(_totalOutstanding <= _limits.totalLimit, "Exceeds total borrow limit");
        }
    }

    /**
    * @dev function increases the total payment value on the loan for interest accrual
    * @param _ln individual loan
    * @param _user global loan for user
    * @param _global global loan for the whole contract
     */

    function increaseTotalPaymentsValue(loan storage _ln, globalInfo storage _user, globalInfo storage _global, uint _am) internal{
        // if loan is late we give an APR multiplier
        uint am = _am;
        if(isLate(_ln)){
            am = _am * APY_PENALTY_MULTIPLIER;
        }

        _ln.totalPaymentsValue += am;
        _user.totalPaymentsValue += am;
        _global.totalPaymentsValue += am;
    }

    /// @dev function to issue a loan
    function issue(loan storage _ln, globalInfo storage _user, globalInfo storage _global) internal{
        require(
            _ln.status == Status.NEW,
            "cannot issue a loan that is already issued, or not configured"
        );

        _ln.status = Status.APPROVED;
        _ln.issueDate = uint128(block.timestamp);

        _user.principal += _ln.principal;
        _user.totalPaymentsValue += _ln.totalPaymentsValue;
        _user.awaitingCollection += _ln.awaitingCollection;
        _user.paymentComplete += _ln.paymentComplete;

        _global.principal += _ln.principal;
        _global.totalPaymentsValue += _ln.totalPaymentsValue;
        _global.awaitingCollection += _ln.awaitingCollection;
        _global.paymentComplete += _ln.paymentComplete;

    }

    /// @dev helper function returns if loan is complete
    function isComplete(loan storage _ln) internal view returns (bool) {
        return
            _ln.paymentComplete >=
            _ln.totalPaymentsValue;
    }

    /// @dev function returns if loan is late
    function isLate(loan storage _ln) internal view returns (bool) {
        return (block.timestamp >= _ln.maturityDate);
    }

    function getOutstanding(loan memory _ln) internal pure returns(uint){
        if(_ln.paymentComplete > _ln.totalPaymentsValue){
            return 0;
        }
        return(_ln.totalPaymentsValue - _ln.paymentComplete);
    }
    function getOutstanding(globalInfo memory _global) internal pure returns(uint){
        if(_global.paymentComplete > _global.totalPaymentsValue){
            return 0;
        }
        return(_global.totalPaymentsValue - _global.paymentComplete);
    }
    function _updateLoanDay(globalInfo storage _user) private{
        if((block.timestamp - _user.lastBorrowTimestamp) >= DAY){
            _user.borrowedToday = 0;
        }
        _user.lastBorrowTimestamp = uint128(block.timestamp);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Structs {
    struct Score {
        uint256 tokenId;
        uint256 timestamp;
        uint16 creditScore;
    }

    /**
        * @param _amount to borrow
        * @param _duration of loan in seconds
        * @param _NFCSID is the user's NFCS NFT ID from Roci's Credit scoring system
        * @param _collateralAmount is the amount of collateral to send in
        * @param _collateral is the ERC20 address of the collateral
        * @param _hash is the hash of this address and the loan ID. See Bonds.sol for more info on this @newLoan()
        * @param _signature is the signature of the data hashed for hash
    */
    struct BorrowArgs{
        uint256 _amount;
        uint256 _NFCSID;
        uint256 _collateralAmount;
        address _collateral;
        bytes32 _hash;
        bytes _signature;
    }

    /// @notice collateral info is stored in a struct/mapping pair
    struct collateral {
        uint256 creationTimestamp;
        address ERC20Contract;
        uint256 amount;
    }

    // Share struct that decides the share of each address
    struct Share{
        address payee;
        uint share;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
* @title ScoreConfigs
* @author Carson Case ([email protected])
* @dev abstract contract to hold information the scores translate too such as LTV and LV
 */
interface IScoreConfigs{
    function LTV(address _token, uint16 _score) external view returns(uint256);

    function LT(address _token, uint16 _score) external view returns(uint256);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IPaymentSplitter{

    function payment(address, uint) external;

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