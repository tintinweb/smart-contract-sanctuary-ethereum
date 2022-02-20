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
pragma solidity ^0.8.4;

interface IAddressRegistry {
  function register(string calldata _name, address _address) external;

  function updateController(address _newController) external;

  function get(string calldata _name) external view returns (address);

  function getController() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../loans/ILoanNFT.sol";

abstract contract LoanUpdateExecutor {
  event LoanFailedToUpdate(uint256 _loanID);

  function execute(address _loanNFTAddress, uint256[] calldata _loanIDs) external {
    for (uint256 i = 0; i < _loanIDs.length; i++) {
      uint256 loanID = _loanIDs[i];
      address lpAddress = (ILoanNFT(_loanNFTAddress)).getLoanOwner(loanID);
      if (!_processLoan(loanID, lpAddress)) {
        emit LoanFailedToUpdate(loanID);
      }
    }
  }

  function _processLoan(uint256 _loanID, address _lpAddress) internal virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../../loans/ILoanNFT.sol";
import "../executors/LoanUpdateExecutor.sol";
import "../../../IAddressRegistry.sol";

abstract contract LoanUpdateJobResolver is Ownable {
  uint256 public maxLoansToUpdate;
  IAddressRegistry public addressRegistry;

  constructor(address _addressRegistry, uint256 _maxLoansToUpdate) {
    addressRegistry = IAddressRegistry(_addressRegistry);
    maxLoansToUpdate = _maxLoansToUpdate;
  }

  function setMaxLoansToUpdate(uint256 _maxLoansToUpdate) external onlyOwner {
    maxLoansToUpdate = _maxLoansToUpdate;
  }

  function checker() external view returns (bool, bytes memory) {
    address loanNFTAddress = addressRegistry.get("LoanNFT");
    ILoanNFT loanNFT = ILoanNFT(loanNFTAddress);
    uint256 numLoans = loanNFT.getNumLoans();
    uint256[] memory loanIDs = new uint256[](maxLoansToUpdate);
    uint256 numLoansToUpdate = 0;
    uint256 currLoanID = 0;

    while (numLoansToUpdate < loanIDs.length && currLoanID < numLoans) {
      if (_shouldUpdateLoan(currLoanID, loanNFT)) {
        loanIDs[numLoansToUpdate] = currLoanID;
        numLoansToUpdate += 1;
      }
      currLoanID += 1;
    }
    return (numLoansToUpdate > 0, abi.encodeWithSelector(LoanUpdateExecutor.execute.selector, loanNFTAddress, loanIDs));
  }

  function _shouldUpdateLoan(uint256 _loanID, ILoanNFT _loanNFT) internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LoanUpdateJobResolver.sol";

contract LoanValueUpdateResolver is LoanUpdateJobResolver {
  constructor(address _addressRegistry, uint256 _maxLoansToUpdate)
    LoanUpdateJobResolver(_addressRegistry, _maxLoansToUpdate)
  {}

  function _shouldUpdateLoan(uint256 _loanID, ILoanNFT _loanNFT) internal view override returns (bool) {
    Loan memory loan = _loanNFT.getLoan(_loanID);
    return
      loan.status == LoanStatus.DISBURSED &&
      (loan.balances.lastUpdatedAt == 0 || block.timestamp >= loan.balances.lastUpdatedAt + 1 days);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct LoanRegistrationParams {
  uint256 repaymentDate;
  uint256 principal;
  uint256 lateFee;
  uint256 timeDisbursed;
  uint256 dailyRate;
  address borrowerAddress;
  string purpose;
  string description;
}

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
  function mintNewLoan(LoanRegistrationParams calldata _loanParams) external returns (uint256);

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