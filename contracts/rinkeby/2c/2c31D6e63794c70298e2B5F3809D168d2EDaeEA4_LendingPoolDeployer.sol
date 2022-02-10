// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../lendingPool/LendingPool.sol";
import "../lendingPool/ILendingPoolRegistry.sol";
import "../tokens/CopToken.sol";

contract LendingPoolDeployer {
  struct PoolDeploymentParams {
    string lendingPoolUri;
    address baseTokenAddress;
    uint256 minReserve;
    uint256 maxReserve;
    uint256 minPoolJuniorTranchePercentage;
    uint256 maxPoolSize;
    uint256 dailySeniorYield;
  }

  event LendingPoolDeployed(
    address indexed _lpAddress,
    address indexed _originator,
    string _lendingPoolUri,
    address _baseTokenAddress,
    uint256 _minReserve,
    uint256 _maxReserve,
    uint256 _minPoolJuniorTranchePercentage,
    uint256 _maxPoolSize,
    uint256 _dailySeniorYield
  );

  address public copraGlobal;
  address public copTokenAddress;
  address public lendingPoolRegistry;

  constructor(
    address _copraGlobal,
    address _lendingPoolRegistry,
    address _copToken
  ) {
    copraGlobal = _copraGlobal;
    lendingPoolRegistry = _lendingPoolRegistry;
    copTokenAddress = _copToken;
  }

  // Might have to do abi encode and decode here
  function deploy(bytes calldata _deployParams) external {
    (
      string memory lendingPoolUri,
      address baseTokenAddress,
      uint256 minReserve,
      uint256 maxReserve,
      uint256 minPoolJuniorTranchePercentage,
      uint256 maxPoolSize,
      uint256 dailySeniorYield
    ) = abi.decode(_deployParams, (string, address, uint256, uint256, uint256, uint256, uint256));
    LendingPool lp = new LendingPool(
      lendingPoolUri,
      lendingPoolRegistry,
      baseTokenAddress,
      minReserve,
      maxReserve,
      minPoolJuniorTranchePercentage,
      maxPoolSize,
      dailySeniorYield
    );
    (ILendingPoolRegistry(lendingPoolRegistry)).registerPool(address(lp));
    lp.transferOwnership(msg.sender);

    CopToken(copTokenAddress).burnFrom(msg.sender, ICopraGlobal(copraGlobal).getExpenses().proposePool);

    emit LendingPoolDeployed(
      address(lp),
      msg.sender,
      lendingPoolUri,
      baseTokenAddress,
      minReserve,
      maxReserve,
      minPoolJuniorTranchePercentage,
      maxPoolSize,
      dailySeniorYield
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 *  LendingPools will have 2 LPTokens to represent the jCPR and sCPR tokens.  They will also own these token contracts
 *  and will be the only entity that can mint and burn tokens.
 */
interface ILPToken is IERC20 {
  function mintTokens(address _to, uint256 _amount) external;

  function burnTokens(address _owner, uint256 _amount) external;

  function transferContractOwner(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract CopToken is ERC20Burnable, ERC20Permit, ERC20Votes {
  constructor(uint256 _initialSupply) ERC20("Copra", "COP") ERC20Permit("Copra") {
    _mint(_msgSender(), _initialSupply);
  }

  // The functions below are overrides required by Solidity.

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20, ERC20Votes) {
    super._afterTokenTransfer(from, to, amount);
  }

  function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._mint(to, amount);
  }

  function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._burn(account, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ILoanNFT.sol";
import "../library/DSMath.sol";
import "../library/PercentLib.sol";
import "../lendingPool/ILendingPool.sol";
import "../lendingPool/ILendingPoolRegistry.sol";
import "../ICopraGlobal.sol";

/**
 *  The LoanNFT contract is responsible for holding the loan assets that belong to a LendingPool.  Each LendingPool owns an instance
 *  of this contract and is the only entity that can mint new loan NFTs.
 */
contract LoanNFT is ERC721URIStorage, ILoanNFT {
  using Counters for Counters.Counter;
  using DSMath for uint256;
  using PercentLib for uint256;

  Counters.Counter private loanIDs;

  mapping(address => uint256) public totalLoanValues;
  mapping(address => bool) public lpHasLoan;

  Loan[] public loans;
  address public copraGlobal;
  address public lendingPoolRegistry;

  event LoanCreated(address _lendingPoolAddress, uint256 _loanID);
  event LoanPaidAmountUpdated(uint256 _loanID, uint256 _amountRepaid);
  event LoanDisbursed(uint256 _loanID);
  event LoanUpdated(uint256 _loanID, uint256 _newLoanValue, address indexed _loanOwner, uint256 _newTotalPoolValue);

  constructor(address _copraGlobal, address _lendingPoolRegistry) ERC721("Loan NFT", "COPNFT") {
    copraGlobal = _copraGlobal;
    lendingPoolRegistry = _lendingPoolRegistry;
  }

  function updateAmountPaid(uint256 _loanID, uint256 _loanRepaymentAmount)
    external
    override
    returns (
      uint256 _amountToPool,
      uint256 _amountToOriginator,
      uint256 _amountToTreasury
    )
  {
    _checkIsLoanOwner(_loanID);
    Loan memory loan = loans[_loanID];
    if (loan.status == LoanStatus.DISBURSED) {
      uint256 feeRepayment = _loanRepaymentAmount.wmul(loan.balances.fee).wdiv(
        loan.balances.pool.add(loan.balances.fee)
      );
      loan.balances.fee = feeRepayment >= loan.balances.fee ? 0 : loan.balances.fee.sub(feeRepayment);

      if (_loanRepaymentAmount > loan.balances.outstanding) {
        uint256 paymentToLateFee = _loanRepaymentAmount.sub(loan.balances.outstanding);
        loan.balances.late = paymentToLateFee >= loan.balances.late ? 0 : loan.balances.late.sub(paymentToLateFee);
        loan.balances.outstanding = 0;
      } else {
        loan.balances.outstanding = loan.balances.outstanding.sub(_loanRepaymentAmount);
      }

      loan.amountRepaid = loan.amountRepaid.add(_loanRepaymentAmount);
      loans[_loanID] = loan;

      _recalculateLoanNetValue(_loanID, loan);

      if (loan.balances.netValue == 0) {
        loans[_loanID].status = LoanStatus.CLOSED;
      }

      (, uint256 originatorFee, uint256 governanceFee) = (ICopraGlobal(copraGlobal)).getFees();

      uint256 totalFees = originatorFee.add(governanceFee);
      _amountToPool = (_loanRepaymentAmount.sub(feeRepayment));
      _amountToOriginator = feeRepayment.wmul(originatorFee).wdiv(totalFees);
      _amountToTreasury = feeRepayment.sub(_amountToOriginator);

      emit LoanPaidAmountUpdated(_loanID, _loanRepaymentAmount);
    }
  }

  function disburse(uint256 _loanID) external override {
    _checkIsLoanOwner(_loanID);
    require(loans[_loanID].status == LoanStatus.REGISTERED, "LoanNFT: Already disbursed");
    loans[_loanID].actualTimeDisbursed = block.timestamp;
    loans[_loanID].status = LoanStatus.DISBURSED;
    _updateLoanValue(_loanID);
    emit LoanDisbursed(_loanID);
  }

  function updateMultipleLoanValues(uint256[] calldata _loanIDs) external override {
    for (uint256 i = 0; i < _loanIDs.length; i++) {
      _updateLoanValue(_loanIDs[i]);
    }
  }

  function updateLoanValue(uint256 _loanID) external override {
    _updateLoanValue(_loanID);
  }

  function _updateLoanValue(uint256 _loanID) internal {
    _checkIsLoanOwner(_loanID);
    _checkValidLoan(_loanID);
    Loan memory loan = loans[_loanID];
    uint256 maxLateDays = (ICopraGlobal(copraGlobal)).getMaxLateDays();
    if (block.timestamp >= loan.repaymentDate + maxLateDays * 1 days) {
      loans[_loanID].status = LoanStatus.DEFAULTED;
    } else if (loan.status == LoanStatus.DISBURSED) {
      loan = _updateLoanBalances(loan);
      _recalculateLoanNetValue(_loanID, loan);
    }
  }

  function _updateLoanBalances(Loan memory _loan) internal view returns (Loan memory) {
    if (block.timestamp == _loan.actualTimeDisbursed) {
      _loan.balances.outstanding = _loan.principal;
    } else {
      uint256 daysSinceLastUpdate;
      if (_loan.balances.lastUpdatedAt == 0) {
        daysSinceLastUpdate = 1;
      } else {
        daysSinceLastUpdate = (block.timestamp - _loan.balances.lastUpdatedAt) / 1 days;
      }
      (, uint256 originatorFee, uint256 governanceFee) = (ICopraGlobal(copraGlobal)).getFees();

      for (uint256 i = 0; i < daysSinceLastUpdate; i++) {
        _loan.balances.outstanding = _loan.balances.outstanding.add(_loan.balances.outstanding.wmul(_loan.dailyRate));
        _loan.balances.fee = _loan.balances.fee.add(
          _loan.balances.outstanding.wmul(_loan.dailyRate).wmul(originatorFee.add(governanceFee))
        );
        if (_loan.balances.lastUpdatedAt + (i * 1 days) > _loan.repaymentDate) {
          _loan.balances.late = _loan.balances.late.add(_loan.balances.outstanding.wmul(_loan.lateFee));
        }
        _loan.balances.balance = _loan.balances.outstanding.add(_loan.balances.late);
        _loan.balances.pool = _loan.balances.balance.sub(_loan.balances.fee);
      }
    }
    _loan.balances.lastUpdatedAt = block.timestamp;
    return _loan;
  }

  function _recalculateLoanNetValue(uint256 _loanID, Loan memory _loan) internal {
    uint256 prevNetValue = _loan.balances.netValue;
    _loan.balances.netValue = _calculateLoanValue(_loan);

    if (_loan.balances.netValue < prevNetValue) {
      uint256 netValueDelta = prevNetValue.sub(_loan.balances.netValue);
      if (totalLoanValues[ownerOf(_loanID)] <= netValueDelta) {
        totalLoanValues[ownerOf(_loanID)] = 0;
      } else {
        totalLoanValues[ownerOf(_loanID)] = totalLoanValues[ownerOf(_loanID)].sub(netValueDelta);
      }
    } else {
      totalLoanValues[ownerOf(_loanID)] = totalLoanValues[ownerOf(_loanID)].add(
        _loan.balances.netValue.sub(prevNetValue)
      );
    }

    loans[_loanID] = _loan;
    emit LoanUpdated(_loanID, _loan.balances.netValue, ownerOf(_loanID), totalLoanValues[ownerOf(_loanID)]);
  }

  function mintNewLoan(bytes calldata _loan) external override returns (uint256) {
    ILendingPoolRegistry lpRegistry = ILendingPoolRegistry(lendingPoolRegistry);
    require(
      lpRegistry.isWhitelisted(_msgSender()) && (lpRegistry.isRegisteredPool(_msgSender())),
      "LoanNFT: pool not registered or whitelisted"
    );

    (
      uint256 _repaymentDate,
      uint256 _principal,
      uint256 _lateFee,
      uint256 _timeDisbursed,
      uint256 _dailyRate,
      address _borrowerAddress,
      string memory _tokenURI
    ) = abi.decode(_loan, (uint256, uint256, uint256, uint256, uint256, address, string));
    LoanBalances memory initialBalances = LoanBalances({
      fee: 0,
      late: 0,
      outstanding: 0,
      pool: 0,
      netValue: 0,
      lastUpdatedAt: 0,
      balance: 0
    });
    Loan memory loan = Loan({
      repaymentDate: _repaymentDate,
      principal: _principal,
      amountRepaid: 0,
      lateFee: _lateFee.toPercent(),
      borrower: _borrowerAddress,
      disbursementDate: _timeDisbursed,
      actualTimeDisbursed: 0,
      dailyRate: _dailyRate.toPercent(),
      balances: initialBalances,
      status: LoanStatus.REGISTERED
    });
    require(block.timestamp < loan.repaymentDate, "LoanNFT: invalid repayment date");
    uint256 newloanID = loanIDs.current();
    _mint(_msgSender(), newloanID);
    _setTokenURI(newloanID, _tokenURI);
    loanIDs.increment();
    loans.push(loan);

    if (!lpHasLoan[msg.sender]) {
      totalLoanValues[msg.sender] = 0;
      lpHasLoan[msg.sender] = true;
    }

    emit LoanCreated(_msgSender(), newloanID);
    return newloanID;
  }

  function getLoan(uint256 _loanID) external view override returns (Loan memory) {
    return loans[_loanID];
  }

  function getTotalLoanValue(address _loanOwner) public view override returns (uint256) {
    if (!lpHasLoan[_loanOwner]) {
      return 0;
    }
    return totalLoanValues[_loanOwner];
  }

  function _calculateLoanValue(Loan memory _loan) internal view returns (uint256) {
    uint256 loanBalance = _loan.balances.outstanding.add(_loan.balances.late);
    uint256 loanValue = loanBalance < _loan.balances.fee ? 0 : loanBalance.sub(_loan.balances.fee);
    uint256 loanLateDays = block.timestamp < _loan.repaymentDate
      ? 0
      : ((block.timestamp - _loan.repaymentDate) / 1 days).toWAD();
    uint256 maxLateDays = (ICopraGlobal(copraGlobal)).getMaxLateDays().toWAD();
    uint256 multiplier = uint256(1).toWAD().sub(loanLateDays.wdiv(maxLateDays));
    return loanValue.wmul(multiplier);
  }

  function setStatus(uint256 _loanID, LoanStatus _newStatus) external override {
    _checkIsLoanOwner(_loanID);
    loans[_loanID].status = _newStatus;
  }

  function getNumLoans() external view override returns (uint256) {
    return loanIDs.current();
  }

  function getLoanOwner(uint256 _loanID) external view override returns (address) {
    return ownerOf(_loanID);
  }

  function _checkValidLoan(uint256 _loanID) internal view {
    require(_loanID < loans.length, "LoanNFT: Invalid loanID");
  }

  function _checkIsLoanOwner(uint256 _loanID) internal view {
    require(_msgSender() == ownerOf(_loanID), "LoanNFT: Not loan owner");
  }

  // Override parent contract functions to prevent transferring closed and invalid loans

  function transferFrom(
    address, /** _from **/
    address, /** _to **/
    uint256 /** _loanID **/
  ) public pure override {
    // Do nothing as LoanNFTs are not tradeable
  }

  function safeTransferFrom(
    address, /** _from **/
    address, /** _to **/
    uint256 /** _loanID **/
  ) public pure override {
    // Do nothing as LoanNFTs are not tradeable
  }

  function safeTransferFrom(
    address, /** _from **/
    address, /** _to **/
    uint256, /** _loanID **/
    bytes memory /** _data **/
  ) public pure override {
    // Do nothing as LoanNFTs are not tradeable
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct LoanBalances {
  uint256 outstanding;
  uint256 fee;
  uint256 late;
  uint256 pool;
  uint256 balance;
  uint256 netValue;
  uint256 lastUpdatedAt;
}

enum LoanStatus {
  REGISTERED,
  DISBURSED,
  CLOSED,
  DEFAULTED,
  FAILED_TO_DISBURSE
}

struct Loan {
  uint256 repaymentDate;
  uint256 principal;
  uint256 amountRepaid;
  uint256 lateFee;
  uint256 disbursementDate;
  uint256 actualTimeDisbursed;
  uint256 dailyRate;
  address borrower;
  LoanBalances balances;
  LoanStatus status;
}

interface ILoanNFT {
  function mintNewLoan(bytes calldata _loan) external returns (uint256);

  function updateMultipleLoanValues(uint256[] calldata _loanIDs) external;

  function updateLoanValue(uint256 _loanID) external;

  function getTotalLoanValue(address _loanOwner) external view returns (uint256);

  function getLoan(uint256 _loanId) external view returns (Loan memory);

  function updateAmountPaid(uint256 _loanId, uint256 _loanRepayment)
    external
    returns (
      uint256 _amountToPool,
      uint256 _amountToOriginator,
      uint256 _amountToGovernance
    );

  function disburse(uint256 _loanID) external;

  function setStatus(uint256 _loanID, LoanStatus _newStatus) external;

  function getNumLoans() external view returns (uint256);

  function getLoanOwner(uint256 _loanID) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./DSMath.sol";

library PercentLib {
  using DSMath for uint256;

  function toPercent(uint256 _num) internal pure returns (uint256) {
    return _num.wdiv(uint256(100).toWAD());
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.4.13;

library DSMath {
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
  }

  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
  }

  function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
    return x <= y ? x : y;
  }

  function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
    return x >= y ? x : y;
  }

  function imin(int256 x, int256 y) internal pure returns (int256 z) {
    return x <= y ? x : y;
  }

  function imax(int256 x, int256 y) internal pure returns (int256 z) {
    return x >= y ? x : y;
  }

  uint256 constant WAD = 10**18;
  uint256 constant RAY = 10**27;

  function toWAD(uint256 a) internal pure returns (uint256 b) {
    b = a * WAD;
  }

  //rounds to zero if x*y < WAD / 2
  function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, y), WAD / 2) / WAD;
  }

  //rounds to zero if x*y < WAD / 2
  function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, y), RAY / 2) / RAY;
  }

  //rounds to zero if x*y < WAD / 2
  function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, WAD), y / 2) / y;
  }

  //rounds to zero if x*y < RAY / 2
  function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, RAY), y / 2) / y;
  }

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
pragma solidity ^0.8.4;

struct LendingPoolConstraints {
  uint256 minReservePercentage;
  uint256 maxReservePercentage;
  uint256 minPoolJuniorTranchePercentage;
  uint256 maxPoolSize;
}

struct LendingPoolStateData {
  uint256 dailySeniorYield;
  uint256 seniorObligation;
  uint256 juniorValue;
  uint256 seniorValue;
  uint256 sCopTokenPrice;
  uint256 jCopTokenPrice;
  uint256 lastTimeSeniorObligationUpdated;
  bool isPoolActive;
  address baseTokenAddress;
  address jCopTokenAddress;
  address sCopTokenAddress;
  address loanNFTAddress;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../ILendingPool.sol";
import "../../tokens/ILPToken.sol";
import "../../library/DSMath.sol";
import "./types.sol";
import "./LendingPoolStateLogic.sol";
import "../../ICopraGlobal.sol";

library TrancheTransactionLogic {
  using DSMath for uint256;
  using LendingPoolStateLogic for LendingPoolStateData;

  function depositToTranche(
    LendingPoolStateData memory _self,
    uint256 _amount,
    Tranche _tranche
  ) public returns (uint256) {
    (ERC20(_self.baseTokenAddress)).transferFrom(msg.sender, address(this), _amount);
    address lpTokenAddress = _tranche == Tranche.JUNIOR ? _self.jCopTokenAddress : _self.sCopTokenAddress;
    ILPToken lpToken = ILPToken(lpTokenAddress);
    uint256 amountLpTokensToReceive = _amount.wdiv(_self.getExchangeRate(_tranche));
    lpToken.mintTokens(msg.sender, amountLpTokensToReceive);
    return amountLpTokensToReceive;
  }

  function withdrawFromTranche(
    LendingPoolStateData memory _self,
    uint256 _amountLpTokens,
    Tranche _tranche,
    address _copraGlobal
  ) public returns (uint256) {
    (uint256 withdrawalFee, , ) = (ICopraGlobal(_copraGlobal)).getFees();
    address treasuryAddress = (ICopraGlobal(_copraGlobal)).getTreasuryAddress();
    uint256 totalTokensToGetBack = _amountLpTokens.wmul(_self.getExchangeRate(_tranche));

    uint256 tokensToTreasury = totalTokensToGetBack.wmul(withdrawalFee);
    uint256 tokensToUser = totalTokensToGetBack.sub(tokensToTreasury);

    // Burn LP Tokens
    address lpTokenAddress = _tranche == Tranche.JUNIOR ? _self.jCopTokenAddress : _self.sCopTokenAddress;
    ILPToken lpToken = ILPToken(lpTokenAddress);
    lpToken.burnTokens(msg.sender, _amountLpTokens);

    // Send tokens to user
    (ERC20(_self.baseTokenAddress)).transfer(msg.sender, tokensToUser);

    // Send tokens to treasury
    (ERC20(_self.baseTokenAddress)).transfer(treasuryAddress, tokensToTreasury);
    return totalTokensToGetBack;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./types.sol";
import "../../loans/ILoanNFT.sol";
import "../../ICopraGlobal.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../library/DSMath.sol";

library LoanTransactionLogic {
  using DSMath for uint256;

  function update(LendingPoolStateData memory _self, uint256 _loanID) public {
    ILoanNFT loanNFT = ILoanNFT(_self.loanNFTAddress);
    loanNFT.updateLoanValue(_loanID);
  }

  function disburse(LendingPoolStateData memory _self, uint256 _loanID) public returns (uint256) {
    ILoanNFT loanNFT = ILoanNFT(_self.loanNFTAddress);
    Loan memory loan = loanNFT.getLoan(_loanID);
    address borrower = loan.borrower;
    require(_canLoanBeDisbursed(loan), "LoanTransactionLogic: Loan cannot be disbursed");

    if (IERC20(_self.baseTokenAddress).balanceOf(address(this)) < loan.principal) {
      loanNFT.setStatus(_loanID, LoanStatus.FAILED_TO_DISBURSE);
      return 0;
    } else {
      IERC20 baseToken = IERC20(_self.baseTokenAddress);
      baseToken.transfer(borrower, loan.principal);
      loanNFT.disburse(_loanID);
      return loan.principal;
    }
  }

  function payLoan(
    LendingPoolStateData memory _self,
    uint256 _loanID,
    uint256 _amountPaid,
    address _copraGlobal,
    address _originator
  )
    public
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    Loan memory loan = ILoanNFT(_self.loanNFTAddress).getLoan(_loanID);
    require(loan.status == LoanStatus.DISBURSED, "LoanTransactionLogic: loan not in disbursed state");
    // Prevent user from overpaying
    _amountPaid = _amountPaid > loan.balances.balance ? loan.balances.balance : _amountPaid;
    (uint256 amountToPool, uint256 amountToOriginator, uint256 amountToTreasury) = (ILoanNFT(_self.loanNFTAddress))
      .updateAmountPaid(_loanID, _amountPaid);

    // Transfer full repayment to pool first
    (IERC20(_self.baseTokenAddress)).transferFrom(loan.borrower, address(this), _amountPaid);

    // Transfer fees from pool to treasury and originator
    _payFees(amountToTreasury, amountToOriginator, _self.baseTokenAddress, _copraGlobal, _originator);

    return (amountToPool, amountToTreasury, amountToOriginator);
  }

  function _canLoanBeDisbursed(Loan memory _loan) private view returns (bool) {
    return block.timestamp >= _loan.disbursementDate && _loan.actualTimeDisbursed == 0;
  }

  function _payFees(
    uint256 _amountToTreasury,
    uint256 _amountToOriginator,
    address _baseTokenAddress,
    address _copraGlobal,
    address _originator
  ) internal {
    if (_amountToTreasury > 0) {
      ICopraGlobal copraGlobalContract = ICopraGlobal(_copraGlobal);
      address treasuryAddress = copraGlobalContract.getTreasuryAddress();
      (IERC20(_baseTokenAddress)).transfer(treasuryAddress, _amountToTreasury);
    }

    if (_amountToOriginator > 0) {
      (IERC20(_baseTokenAddress)).transfer(_originator, _amountToOriginator);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./types.sol";
import "../../library/DSMath.sol";
import "../ILendingPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../tokens/ILPToken.sol";
import "../../loans/LoanNFT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LendingPoolStateLogic {
  using DSMath for uint256;

  function activate(LendingPoolStateData storage _self) public {
    if (!_self.isPoolActive) {
      _self.isPoolActive = true;
    }
  }

  function updateLPTokenValues(LendingPoolStateData storage _self, LendingPoolConstraints memory _constraints) public {
    uint256 poolValue = _getTotalValue(_self);
    require(poolValue > 0, "LendingPoolStateLogic: Pool must have a non zero value");

    _self.seniorValue = _self.seniorObligation > poolValue ? poolValue : _self.seniorObligation;
    _self.juniorValue = poolValue > _self.seniorValue ? poolValue.sub(_self.seniorValue) : 0;

    // Error if new tranche values break the min pool junior tranche percentage constraint
    satisfiesMinPoolJunior(_constraints, _self.juniorValue, poolValue);

    ILPToken sCopTokenContract = ILPToken(_self.sCopTokenAddress);
    uint256 sCopSupply = sCopTokenContract.totalSupply();
    if (sCopSupply > 0) {
      _self.sCopTokenPrice = _self.seniorValue.wdiv(sCopSupply);
    }

    ILPToken jCopTokenContract = ILPToken(_self.jCopTokenAddress);
    uint256 jCopSupply = jCopTokenContract.totalSupply();
    if (jCopSupply > 0) {
      _self.jCopTokenPrice = _self.juniorValue.wdiv(jCopSupply);
    }
  }

  function updateSeniorObligation(LendingPoolStateData storage _self) public {
    uint256 daysSinceLastUpdate = _self.lastTimeSeniorObligationUpdated == 0
      ? 1
      : ((block.timestamp - _self.lastTimeSeniorObligationUpdated) / 1 days);

    if (daysSinceLastUpdate <= 0) {
      return;
    }

    uint256 oneWAD = uint256(1).toWAD();
    for (uint256 i = 0; i < daysSinceLastUpdate; i++) {
      uint256 utilizationRatio = _getUtilization(
        _self,
        (ILoanNFT(_self.loanNFTAddress).getTotalLoanValue(address(this)))
      );
      uint256 multiplier = oneWAD.add(utilizationRatio.wmul(_self.dailySeniorYield));
      _self.lastTimeSeniorObligationUpdated = block.timestamp;
      _self.seniorObligation = _self.seniorObligation.wmul(multiplier);
    }
  }

  function _getTotalValue(LendingPoolStateData memory _self) internal view returns (uint256) {
    uint256 poolLoanValue = address(_self.loanNFTAddress) == address(0)
      ? 0
      : (ILoanNFT(_self.loanNFTAddress)).getTotalLoanValue(address(this));
    ERC20 baseToken = ERC20(_self.baseTokenAddress);
    uint256 poolReserve = (baseToken.balanceOf(address(this)));
    return poolLoanValue.add(poolReserve);
  }

  function _getUtilization(LendingPoolStateData storage _self, uint256 _loanValue) internal view returns (uint256) {
    uint256 totalValue = _getTotalValue(_self);
    if (totalValue == 0) {
      return 0;
    }
    return _loanValue.wdiv(totalValue);
  }

  function getReservePercentage(LendingPoolStateData memory _self) public view returns (uint256) {
    uint256 totalValue = _getTotalValue(_self);
    require(_self.baseTokenAddress != address(0), "LendingPoolStateLogic: Base token address is missing");
    address lpAddress = address(this);
    uint256 reserves = (IERC20(_self.baseTokenAddress)).balanceOf(lpAddress);
    return reserves.wdiv(totalValue);
  }

  function getExchangeRate(LendingPoolStateData memory _self, Tranche _tranche) public pure returns (uint256) {
    return _tranche == Tranche.JUNIOR ? _self.jCopTokenPrice : _self.sCopTokenPrice;
  }

  function satisfiesMinPoolJunior(
    LendingPoolConstraints memory _constraints,
    uint256 _juniorValue,
    uint256 _poolValue
  ) public pure {
    require(
      _juniorValue.wdiv(_poolValue) >= _constraints.minPoolJuniorTranchePercentage,
      "LendingPoolStateLogic: Insufficient junior tranche value"
    );
  }

  function satisfiesMaxPoolSize(LendingPoolConstraints memory _constraints, uint256 _totalLoanValue) public pure {
    require(_totalLoanValue < _constraints.maxPoolSize, "LendingPoolStateLogic: Pool size too large");
  }

  function satisfiesMinReserve(LendingPoolConstraints memory _constraints, uint256 _lpReservePercentage) public pure {
    require(
      _lpReservePercentage >= _constraints.minReservePercentage,
      "LendingPoolStateLogic: Cannot be below pool minReserve"
    );
  }

  function satisfiesMaxReserve(
    LendingPoolConstraints memory _constraints,
    LendingPoolStateData memory _selfData,
    uint256 _reservePercentage
  ) public view {
    if (_selfData.isPoolActive) {
      require(
        _reservePercentage <= _constraints.maxReservePercentage,
        "LendingPoolStateLogic: Cannot be above maxReserve"
      );
    } else {
      require(
        _getTotalValue(_selfData) < _constraints.maxReservePercentage.wmul(_constraints.maxPoolSize),
        "LendingPoolStateLogic: Cannot be above maxReserve"
      );
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../tokens/ILPToken.sol";
import "./ILendingPool.sol";
import "./ILendingPoolRegistry.sol";
import "../library/DSMath.sol";
import "../library/PercentLib.sol";
import "../loans/ILoanNFT.sol";
import "./libraries//TrancheTransactionLogic.sol";
import "./libraries/LoanTransactionLogic.sol";
import "../tokens/CopToken.sol";

contract LendingPool is Ownable, ILendingPool {
  using DSMath for uint256;
  using PercentLib for uint256;

  string public lendingPoolUri;
  address private copraGlobal;
  address public copTokenAddress;
  address public lendingPoolRegistry;

  LendingPoolConstraints public constraints;
  LendingPoolStateData public state;

  event LendingPoolInitialized(
    address lpAddress,
    address jCopTokenAddress,
    address sCopTokenAddress,
    address copraGlobal
  );
  event LiquiditySupplied(address indexed _provider, uint256 _amount, uint256 _amountLPToken, Tranche tranche);
  event LiquidityWithdrawn(address indexed _withdrawer, uint256 _amount, uint256 _amountLPToken, Tranche tranche);
  event LoanDisbursed(uint256 _loanID, uint256 _amount);
  event LoanFailedToDisburse(uint256 _loanID);
  event LoanPaid(
    uint256 _loanID,
    address payer,
    address loanOwner,
    uint256 amountToPool,
    uint256 amountToTreasury,
    uint256 amountToOriginator
  );
  event LoanListed(uint256 _loanID);
  event LendingPoolStateUpdated(
    uint256 _juniorValue,
    uint256 _seniorValue,
    uint256 _jCopPrice,
    uint256 _sCopPrice,
    uint256 _seniorObligation
  );

  constructor(
    string memory _lpURI,
    address _lendingPoolRegistry,
    address _baseTokenAddress,
    uint256 _minReserve,
    uint256 _maxReserve,
    uint256 _minPoolJuniorTranchePercentage,
    uint256 _maxPoolSize,
    uint256 _dailySeniorYield
  ) {
    constraints = LendingPoolConstraints({
      maxPoolSize: _maxPoolSize,
      minReservePercentage: _minReserve.toPercent(),
      maxReservePercentage: _maxReserve.toPercent(),
      minPoolJuniorTranchePercentage: _minPoolJuniorTranchePercentage.toPercent()
    });
    state = LendingPoolStateData({
      dailySeniorYield: _dailySeniorYield.toPercent(),
      lastTimeSeniorObligationUpdated: 0,
      seniorObligation: 0,
      juniorValue: 0,
      seniorValue: 0,
      isPoolActive: false,
      sCopTokenPrice: 10**18,
      jCopTokenPrice: 10**18,
      baseTokenAddress: _baseTokenAddress,
      jCopTokenAddress: address(0),
      sCopTokenAddress: address(0),
      loanNFTAddress: address(0)
    });

    lendingPoolRegistry = _lendingPoolRegistry;
    lendingPoolUri = _lpURI;
  }

  function _checkWhitelisted() internal view {
    ILendingPoolRegistry lpRegistry = ILendingPoolRegistry(lendingPoolRegistry);
    require(lpRegistry.isWhitelisted(address(this)), "Pool is not whitelisted");
  }

  function init(
    address _jCopToken,
    address _sCopToken,
    address _copraGlobal,
    address _copToken,
    address _loanNFTAddress
  ) external override {
    _checkWhitelisted();
    require(
      state.jCopTokenAddress == address(0) && state.sCopTokenAddress == address(0),
      "Lending pool has already been initialized"
    );

    state.jCopTokenAddress = _jCopToken;
    state.sCopTokenAddress = _sCopToken;
    state.loanNFTAddress = _loanNFTAddress;
    copraGlobal = _copraGlobal;
    copTokenAddress = _copToken;
    emit LendingPoolInitialized(address(this), _jCopToken, _sCopToken, _copraGlobal);
  }

  function registerLoan(bytes calldata _loan) external override onlyOwner {
    _checkWhitelisted();
    uint256 loanID = ILoanNFT(state.loanNFTAddress).mintNewLoan(_loan);

    CopToken copToken = CopToken(copTokenAddress);
    copToken.burnFrom(_msgSender(), ICopraGlobal(copraGlobal).getExpenses().listLoan);

    emit LoanListed(loanID);
  }

  function payLoan(uint256 _loanID, uint256 _amountPaid) external override {
    (uint256 amountToPool, uint256 amountToTreasury, uint256 amountToOriginator) = LoanTransactionLogic.payLoan(
      state,
      _loanID,
      _amountPaid,
      copraGlobal,
      owner()
    );
    emit LoanPaid(_loanID, _msgSender(), address(this), amountToPool, amountToTreasury, amountToOriginator);
  }

  function updateLoan(uint256 _loanID) external override {
    LoanTransactionLogic.update(state, _loanID);
    _updateLPTokenValues();
  }

  function disburseLoan(uint256 _loanID) external override {
    uint256 amountDisbursed = LoanTransactionLogic.disburse(state, _loanID);
    uint256 reservePercentage = LendingPoolStateLogic.getReservePercentage(state);
    LendingPoolStateLogic.satisfiesMinReserve(constraints, reservePercentage);
    LendingPoolStateLogic.satisfiesMaxReserve(constraints, state, reservePercentage);
    LendingPoolStateLogic.activate(state);
    if (amountDisbursed > 0) {
      emit LoanDisbursed(_loanID, amountDisbursed);
    } else {
      emit LoanFailedToDisburse(_loanID);
    }
  }

  function deposit(Tranche _tranche, uint256 _amount) external override {
    _checkWhitelisted();
    uint256 amountLpTokens = TrancheTransactionLogic.depositToTranche(state, _amount, _tranche);
    if (_tranche == Tranche.SENIOR) {
      state.seniorObligation = state.seniorObligation.add(_amount);
    }
    uint256 reservePercentage = LendingPoolStateLogic.getReservePercentage(state);
    LendingPoolStateLogic.satisfiesMaxReserve(constraints, state, reservePercentage);
    _updateLPTokenValues();
    emit LiquiditySupplied(_msgSender(), _amount, amountLpTokens, _tranche);
  }

  function withdraw(Tranche _tranche, uint256 _amountLpTokens) external override {
    _checkWhitelisted();
    uint256 totalTokensToGetBack = TrancheTransactionLogic.withdrawFromTranche(
      state,
      _amountLpTokens,
      _tranche,
      copraGlobal
    );
    // Check constraints
    if (_tranche == Tranche.SENIOR) {
      state.seniorObligation = state.seniorObligation.sub(totalTokensToGetBack);
    }
    uint256 reservePercentage = LendingPoolStateLogic.getReservePercentage(state);
    LendingPoolStateLogic.satisfiesMinReserve(constraints, reservePercentage);
    _updateLPTokenValues();
    emit LiquidityWithdrawn(_msgSender(), totalTokensToGetBack, _amountLpTokens, _tranche);
  }

  function updateSeniorObligation() external override {
    LendingPoolStateLogic.updateSeniorObligation(state);
    _updateLPTokenValues();
  }

  function _updateLPTokenValues() internal {
    LendingPoolStateLogic.updateLPTokenValues(state, constraints);
    emit LendingPoolStateUpdated(
      state.juniorValue,
      state.seniorValue,
      state.jCopTokenPrice,
      state.sCopTokenPrice,
      state.seniorObligation
    );
  }

  function getJCopBalance(address account) public view returns (uint256) {
    require(state.jCopTokenAddress != address(0), "jCPR contract not initialized yet");
    return (ILPToken(state.jCopTokenAddress)).balanceOf(account);
  }

  function getSCopBalance(address account) public view returns (uint256) {
    require(state.sCopTokenAddress != address(0), "sCPR contract not initialized yet");
    return (ILPToken(state.sCopTokenAddress)).balanceOf(account);
  }

  function getOriginator() external view override returns (address) {
    return owner();
  }

  function getLastUpdatedAt() external view override returns (uint256) {
    return state.lastTimeSeniorObligationUpdated;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILendingPoolRegistry {
  function whitelistPool(
    address _lpAddress,
    string calldata _jCopName,
    string calldata _jCopSymbol,
    string calldata _sCopName,
    string calldata _sCopSymbol
  ) external;

  function closePool(address _lpAddress) external;

  function openPool(address _lpAddress) external;

  function registerPool(address _lpAddress) external;

  function isWhitelisted(address _lpAddress) external view returns (bool);

  function getNumWhitelistedPools() external view returns (uint256);

  function getPools() external view returns (address[] memory);

  function isRegisteredPool(address _lpAddress) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

enum Tranche {
  JUNIOR,
  SENIOR
}

interface ILendingPool {
  function init(
    address _jCopToken,
    address _sCopToken,
    address _copraGlobal,
    address _copToken,
    address _loanNFT
  ) external;

  function registerLoan(bytes calldata _loan) external;

  function payLoan(uint256 _loanID, uint256 _amount) external;

  function disburseLoan(uint256 _loanID) external;

  function updateLoan(uint256 _loanID) external;

  function deposit(Tranche _tranche, uint256 _amount) external;

  function withdraw(Tranche _tranche, uint256 _amount) external;

  function getOriginator() external view returns (address);

  function updateSeniorObligation() external;

  function getLastUpdatedAt() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICopraGlobal {
  struct Expenses {
    uint256 listLoan;
    uint256 proposePool;
  }

  function getFees()
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  function getExpenses() external returns (Expenses memory);

  function getTreasuryAddress() external returns (address);

  function getMaxLateDays() external view returns (uint256);

  function setMaxLateDays(uint256 _maxLateDays) external;

  function setWithdrawalFee(uint256 _withdrawalFee) external;

  function setOriginatorFee(uint256 _originatorFee) external;

  function setGovernanceFee(uint256 _governanceFee) external;

  function setProposePoolExpense(uint256 _proposePoolExpense) external;

  function setListLoanExpense(uint256 _listLoanExpense) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./draft-ERC20Permit.sol";
import "../../../utils/math/Math.sol";
import "../../../utils/math/SafeCast.sol";
import "../../../utils/cryptography/ECDSA.sol";

/**
 * @dev Extension of ERC20 to support Compound-like voting and delegation. This version is more generic than Compound's,
 * and supports token supply up to 2^224^ - 1, while COMP is limited to 2^96^ - 1.
 *
 * NOTE: If exact COMP compatibility is required, use the {ERC20VotesComp} variant of this module.
 *
 * This extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotes} and {getPastVotes}.
 *
 * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
 * requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked.
 * Enabling self-delegation can easily be done by overriding the {delegates} function. Keep in mind however that this
 * will significantly increase the base gas cost of transfers.
 *
 * _Available since v4.2._
 */
abstract contract ERC20Votes is ERC20Permit {
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to an account's voting power.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCast.toUint32(_checkpoints[account].length);
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function delegates(address account) public view virtual returns (address) {
        return _delegates[account];
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function getVotes(address account) public view returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
     * It is but NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].votes;
    }

    /**
     * @dev Delegate votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual {
        return _delegate(_msgSender(), delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(block.timestamp <= expiry, "ERC20Votes: signature expired");
        address signer = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "ERC20Votes: invalid nonce");
        return _delegate(signer, delegatee);
    }

    /**
     * @dev Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
     */
    function _maxSupply() internal view virtual returns (uint224) {
        return type(uint224).max;
    }

    /**
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
        require(totalSupply() <= _maxSupply(), "ERC20Votes: total supply risks overflowing votes");

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
    }

    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);

        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {DelegateVotesChanged} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        _moveVotingPower(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = SafeCast.toUint224(newWeight);
        } else {
            ckpts.push(Checkpoint({fromBlock: SafeCast.toUint32(block.number), votes: SafeCast.toUint224(newWeight)}));
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}