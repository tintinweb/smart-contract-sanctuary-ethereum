//contracts/Organizer.sol
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./organizer/OperatorManager.sol";
import "./organizer/ApprovalMatrix.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title Organizer - A utility smart contract for DAOs to define and manage their Organizational structure.
/// @author Sriram Kasyap Meduri - <[email protected]>
/// @author Krishna Kant Sharma - <[email protected]>

contract Organizer is ApprovalMatrix, OperatorManager, Pausable {
  //  Events
  //  DAO Onboarded
  event DAOOnboarded(
    address indexed daoAddress,
    address[] indexed operators,
    address[] operators2
  );

  //  new DAO operator added
  //  DAO  Operators modified
  //  DAO  Operators removed
  //  Deal created
  //  Payout created
  //  Payout executed
  //  Payout cancelled
  //  Deal cancelled
  //  DAO Offboarded
  event DAOOffboarded(address indexed daoAddress);

  //  Onboard A DAO
  function onboard(address[] calldata _operators) external {
    address safeAddress = msg.sender;
    // TODO: verify that safeAddress is Gnosis Multisig

    require(_operators.length > 0, "CS000");

    address currentoperator = SENTINEL_ADDRESS;

    daos[safeAddress].operatorCount = 0;

    // Set Default Approval Matrix for native token : 1 approval required for 0-inf
    daos[safeAddress].approvalMatrices[address(0)].push(
      ApprovalLevel(0, type(uint256).max, 1)
    );

    for (uint256 i = 0; i < _operators.length; i++) {
      // operator address cannot be null.
      address operator = _operators[i];
      require(
        operator != address(0) &&
          operator != SENTINEL_ADDRESS &&
          operator != address(this) &&
          currentoperator != operator,
        "CS002"
      );
      // No duplicate operators allowed.
      require(daos[safeAddress].operators[operator] == address(0), "CS003");
      daos[safeAddress].operators[currentoperator] = operator;
      currentoperator = operator;

      // TODO: emit Operator added event
      daos[safeAddress].operatorCount++;
    }
    daos[safeAddress].operators[currentoperator] = SENTINEL_ADDRESS;
    emit DAOOnboarded(safeAddress, _operators, _operators);
  }

  // Off-board a DAO
  function offboard(address _safeAddress)
    external
    onlyOnboarded(_safeAddress)
    onlyOperatorOrMultisig(_safeAddress)
  {
    // Remove all operators in DAO
    address currentoperator = daos[_safeAddress].operators[SENTINEL_ADDRESS];
    while (currentoperator != SENTINEL_ADDRESS) {
      address nextoperator = daos[_safeAddress].operators[currentoperator];
      delete daos[_safeAddress].operators[currentoperator];
      currentoperator = nextoperator;
    }

    delete daos[_safeAddress];
    emit DAOOffboarded(_safeAddress);
  }
}

//contracts/Organizer.sol
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Modifiers.sol";

/// @title Operator Manager for Organizer Contract
abstract contract OperatorManager is Modifiers {
  // Events
  event OperatorAdded(address indexed safeAddress, address indexed operator);
  event OperatorRemoved(address indexed safeAddress, address indexed operator);

  // Get DAO operators
  function getOperators(address _safeAddress)
    public
    view
    returns (address[] memory)
  {
    address[] memory array = new address[](daos[_safeAddress].operatorCount);

    uint8 i = 0;
    address currentOp = daos[_safeAddress].operators[SENTINEL_ADDRESS];
    while (currentOp != SENTINEL_ADDRESS) {
      array[i] = currentOp;
      currentOp = daos[_safeAddress].operators[currentOp];
      i++;
    }

    return array;
  }

  // Get DAO operator count
  function getOperatorCount(address _safeAddress)
    external
    view
    returns (uint256)
  {
    return daos[_safeAddress].operatorCount;
  }

  //  Modify operators in a DAO
  function modifyOperators(
    address _safeAddress,
    address[] calldata _addressesToAdd,
    address[] calldata _addressesToRemove
  ) public onlyOnboarded(_safeAddress) onlyMultisig(_safeAddress) {
    for (uint256 i = 0; i < _addressesToAdd.length; i++) {
      address _addressToAdd = _addressesToAdd[i];
      require(
        _addressToAdd != address(0) &&
          _addressToAdd != SENTINEL_ADDRESS &&
          _addressToAdd != address(this) &&
          _addressToAdd != _safeAddress,
        "CS002"
      );
      require(
        daos[_safeAddress].operators[_addressToAdd] == address(0),
        "CS003"
      );

      _addOpreator(_safeAddress, _addressToAdd);
    }

    for (uint256 i = 0; i < _addressesToRemove.length; i++) {
      address _addressToRemove = _addressesToRemove[i];
      require(
        _addressToRemove != address(0) &&
          _addressToRemove != SENTINEL_ADDRESS &&
          _addressToRemove != address(this) &&
          _addressToRemove != _safeAddress,
        "CS002"
      );
      require(
        daos[_safeAddress].operators[_addressToRemove] != address(0),
        "CS018"
      );

      _removeOperator(_safeAddress, _addressToRemove);
    }
  }

  // Add an operator to a DAO
  function _addOpreator(address _safeAddress, address _operator) internal {
    daos[_safeAddress].operators[_operator] = daos[_safeAddress].operators[
      SENTINEL_ADDRESS
    ];
    daos[_safeAddress].operators[SENTINEL_ADDRESS] = _operator;
    daos[_safeAddress].operatorCount++;
    emit OperatorAdded(_safeAddress, _operator);
  }

  // Remove an operator from a DAO
  function _removeOperator(address _safeAddress, address _operator) internal {
    address cursor = SENTINEL_ADDRESS;
    while (daos[_safeAddress].operators[cursor] != _operator) {
      cursor = daos[_safeAddress].operators[cursor];
    }
    daos[_safeAddress].operators[cursor] = daos[_safeAddress].operators[
      _operator
    ];
    daos[_safeAddress].operators[_operator] = address(0);
    daos[_safeAddress].operatorCount--;
    emit OperatorRemoved(_safeAddress, _operator);
  }
}

//contracts/organizer/ApprovalMatrix.sol
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Modifiers.sol";

contract ApprovalMatrix is Modifiers {
  // Approval Matrix allows DAOs to define their approval matrix for deals and payouts
  // The approval matrix is a list of approval levels with the following properties:
  // 1. Each approval level has a minimum amount and a maximum amount
  // 2. Each approval level has a number of approvals required
  // 3. The approval matrix is sorted by minimum amount in ascending order
  //
  // Methods
  //
  //  Generate approval Matrix
  function _generateApprovalMatrix(
    uint256[] calldata _minAmounts,
    uint256[] calldata _maxAmounts,
    uint8[] calldata _approvalsRequired
  ) internal pure returns (ApprovalLevel[] memory) {
    require(
      _maxAmounts.length > 0 &&
        _minAmounts.length > 0 &&
        _approvalsRequired.length > 0,
      "CS026"
    );

    require(
      _minAmounts.length == _maxAmounts.length &&
        _minAmounts.length == _approvalsRequired.length,
      "CS020"
    );

    ApprovalLevel[] memory approvalMatrix = new ApprovalLevel[](
      _minAmounts.length
    );

    for (uint256 i = 0; i < _minAmounts.length; i++) {
      require(_minAmounts[i] < _maxAmounts[i], "CS021");
      require(_approvalsRequired[i] > 0, "CS022");

      approvalMatrix[i] = ApprovalLevel(
        _minAmounts[i],
        _maxAmounts[i],
        _approvalsRequired[i]
      );
    }

    return approvalMatrix;
  }

  // Set Approval Matrix on a DAO
  function setApprovalMatrix(
    address _safeAddress,
    address _tokenAddress,
    uint256[] calldata _minAmounts,
    uint256[] calldata _maxAmounts,
    uint8[] calldata _approvalsRequired
  ) public onlyOnboarded(_safeAddress) onlyOperatorOrMultisig(_safeAddress) {
    ApprovalLevel[] memory _approvalMatrix = _generateApprovalMatrix(
      _minAmounts,
      _maxAmounts,
      _approvalsRequired
    );

    // Loop because Copying of type struct memory[] to storage not yet supported
    for (uint256 i = 0; i < _approvalMatrix.length; i++) {
      if (
        daos[_safeAddress].approvalMatrices[_tokenAddress].length > i &&
        daos[_safeAddress].approvalMatrices[_tokenAddress][i].maxAmount > 0
      ) {
        daos[_safeAddress].approvalMatrices[_tokenAddress][i] = _approvalMatrix[
          i
        ];
      } else {
        daos[_safeAddress].approvalMatrices[_tokenAddress].push(
          _approvalMatrix[i]
        );
      }
    }
  }

  // Bulk set Approval Matrices on a DAO
  function bulkSetApprovalMatrices(
    address _safeAddress,
    address[] calldata _tokenAddresses,
    uint256[][] calldata _minAmounts,
    uint256[][] calldata _maxAmounts,
    uint8[][] calldata _approvalsRequired
  ) public onlyOnboarded(_safeAddress) onlyOperatorOrMultisig(_safeAddress) {
    require(
      _tokenAddresses.length == _minAmounts.length &&
        _tokenAddresses.length == _maxAmounts.length &&
        _tokenAddresses.length == _approvalsRequired.length,
      "CS024"
    );

    for (uint256 i = 0; i < _tokenAddresses.length; i++) {
      setApprovalMatrix(
        _safeAddress,
        _tokenAddresses[i],
        _minAmounts[i],
        _maxAmounts[i],
        _approvalsRequired[i]
      );
    }
  }

  // Get Approval Matrix of DAO
  function getApprovalMatrix(address _safeAddress, address _tokenAddress)
    external
    view
    returns (ApprovalLevel[] memory)
  {
    return daos[_safeAddress].approvalMatrices[_tokenAddress];
  }

  //   Get Required Approval count for a payout
  function getRequiredApprovalCount(
    address _safeAddress,
    address _tokenAddress,
    uint256 _amount
  ) external view returns (uint256 requiredApprovalCount) {
    requiredApprovalCount = _getRequiredApprovalCount(
      _safeAddress,
      _tokenAddress,
      _amount
    );
    require(requiredApprovalCount > 0, "CS025");
  }

  //   Get Required Approval count for a payout
  function _getRequiredApprovalCount(
    address _safeAddress,
    address _tokenAddress,
    uint256 _amount
  ) internal view returns (uint256 requiredApprovalCount) {
    ApprovalLevel[] memory approvalMatrix = daos[_safeAddress].approvalMatrices[
      _tokenAddress
    ];

    require(approvalMatrix.length > 0, "CS023");

    for (uint256 i = 0; i < approvalMatrix.length; i++) {
      if (
        _amount >= approvalMatrix[i].minAmount &&
        _amount <= approvalMatrix[i].maxAmount
      ) {
        requiredApprovalCount = approvalMatrix[i].approvalsRequired;
        break;
      }
    }
  }

  // Remove an approval matrix from a DAO
  function removeApprovalMatrix(address _safeAddress, address _tokenAddress)
    external
    onlyOnboarded(_safeAddress)
    onlyOperatorOrMultisig(_safeAddress)
  {
    require(
      daos[_safeAddress].approvalMatrices[_tokenAddress].length > 0,
      "CS023"
    );
    delete daos[_safeAddress].approvalMatrices[_tokenAddress];
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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

//contracts/Organizer.sol
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Validators.sol";

/// @title Modifiers for Organizer Contract
abstract contract Modifiers is Validators {
  //
  //  Modifiers
  //
  //  Only Onboarded can do this
  modifier onlyOnboarded(address _safeAddress) {
    require(isDAOOnboarded(_safeAddress), "CS014");
    _;
  }

  //  Only Multisig can do this
  modifier onlyMultisig(address _safeAddress) {
    require(msg.sender == _safeAddress, "CS015");
    _;
  }

  //  Only Operators
  modifier onlyOperator(address _safeAddress) {
    require(isOperator(_safeAddress, msg.sender), "CS016");
    _;
  }

  modifier onlyOperatorOrMultisig(address _safeAddress) {
    require(
      isOperator(_safeAddress, msg.sender) || msg.sender == _safeAddress,
      "CS017"
    );
    _;
  }
}

//contracts/Organizer.sol
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Storage.sol";

/// @title Validators for Organizer Contract
abstract contract Validators is Storage {
  // Is operator?
  function isOperator(address _safeAddress, address _addressToCheck)
    public
    view
    returns (bool)
  {
    require(isDAOOnboarded(_safeAddress), "CS014");
    return daos[_safeAddress].operators[_addressToCheck] != address(0);
  }

  // Is DAO onboarded?
  function isDAOOnboarded(address _addressToCheck) public view returns (bool) {
    return daos[_addressToCheck].operatorCount > 0;
  }
}

//contracts/Organizer.sol
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Storage for Organizer Contract
abstract contract Storage {
  //  Structs
  struct DAO {
    uint256 operatorCount;
    mapping(address => address) operators;
    //  Approval Matrices : Token Address => ApprovalMatrix
    mapping(address => ApprovalLevel[]) approvalMatrices;
  }

  struct ApprovalLevel {
    uint256 minAmount;
    uint256 maxAmount;
    uint8 approvalsRequired;
  }

  enum Operation {
    Call,
    DelegateCall
  }

  //  //  Storage

  // Deal Nonce : Unique across all DAOs
  uint256 dealNonce;

  //  List of DAOs using the organizer
  //  Safe Address => DAO
  mapping(address => DAO) daos;

  // Deals
  // Safe Address => Deal Nonce => Current Payout Nonce
  mapping(address => mapping(uint256 => mapping(uint256 => uint256))) deals;

  // Payout Nonces
  // Deal Nonce => Payout Nonce => Is Used
  mapping(uint256 => mapping(uint256 => bool)) payouts;

  //  Sentrinel to use with linked lists
  address internal constant SENTINEL_ADDRESS = address(0x1);
  uint256 internal constant SENTINEL_UINT = 1;
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