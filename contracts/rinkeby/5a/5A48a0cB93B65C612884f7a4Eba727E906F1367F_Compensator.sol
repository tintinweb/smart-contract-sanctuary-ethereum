// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./VerifySignature.sol";
import "./Enum.sol";

interface GnosisSafe {
  /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
  /// @param to Destination address of module transaction.
  /// @param value Ether value of module transaction.
  /// @param data Data payload of module transaction.
  /// @param operation Operation type of module transaction.
  function execTransactionFromModule(
    address to,
    uint256 value,
    bytes calldata data,
    Enum.Operation operation
  ) external returns (bool success);
}

contract Compensator is Ownable, Pausable, VerifySignature {
  struct Deal {
    address recipient;
    address reviewer;
    address operator;
    uint256 dealId;
  }

  enum Operation {
    Call,
    DelegateCall
  }

  struct Dao {
    uint256 timelock;
    mapping(address => address) operators;
    uint256 operatorCount;
    mapping(uint256 => Deal) deals;
    uint256 nonce;
  }

  event DealCreated(
    address recipient,
    address reviewer,
    address dao,
    uint256 dealId,
    address operator,
    uint256 timelock
  );

  address internal constant SENTINEL_OWNERS = address(0x1);

  mapping(address => Dao) public daos;

  constructor() Pausable() {}

  function setup(
    address dao,
    address[] memory _operators,
    uint256 timelock
  ) external whenNotPaused {
    // verifying dao address
    require(dao != address(0), "Should not be a zero address");

    // Setting up operators for dao
    require(_operators.length != 0, "Should be atleast on operator");

    address currentOwner = SENTINEL_OWNERS;
    for (uint256 i = 0; i < _operators.length; i++) {
      // Owner address cannot be null.
      address owner = _operators[i];
      require(
        owner != address(0) &&
          owner != SENTINEL_OWNERS &&
          owner != address(this) &&
          currentOwner != owner,
        "GS203"
      );
      // No duplicate owners allowed.
      require(daos[dao].operators[owner] == address(0), "Not");
      daos[dao].operators[currentOwner] = owner;
      currentOwner = owner;
    }

    daos[dao].operators[currentOwner] = SENTINEL_OWNERS;
    daos[dao].operatorCount = _operators.length;
    daos[dao].timelock = timelock;
  }

  function createDeal(
    address _recipient,
    address _reviewer,
    address dao
  ) external onlyOperator(dao) {
    require(_recipient != address(0), "not address zero");
    require(_reviewer != address(0), "not address zero");
    require(dao != address(0), "not address zero");

    uint256 dealId = daos[dao].nonce;

    Deal memory deal = Deal(_recipient, _reviewer, msg.sender, dealId);

    daos[dao].deals[dealId] = deal;

    daos[dao].nonce++;

    emit DealCreated(
      _recipient,
      _reviewer,
      dao,
      dealId,
      msg.sender,
      daos[dao].timelock
    );
  }

  function verifyAndExecute(
    address payable _recipient,
    uint256 _amount,
    address tokenAddress,
    uint256 workReportId,
    uint256 dealId,
    address dao,
    bytes memory contributorSignature,
    bytes memory reviewerSignature
  ) external {
    bytes32 messageHash = getMessageHash(
      _recipient,
      _amount,
      tokenAddress,
      workReportId,
      dealId
    );

    bool isValidContributor = verify(
      messageHash,
      contributorSignature,
      daos[dao].deals[dealId].recipient
    );

    bool isValidReviewer = verify(
      messageHash,
      reviewerSignature,
      daos[dao].deals[dealId].reviewer
    );
    require(isValidContributor && isValidReviewer, "break");

    transfer(dao, tokenAddress, _recipient, _amount);
  }

  function transfer(
    address _safe,
    address token,
    address payable to,
    uint256 amount
  ) private {
    GnosisSafe safe = GnosisSafe(_safe);
    if (token == address(0)) {
      // solium-disable-next-line security/no-send

      require(
        safe.execTransactionFromModule(to, amount, "", Enum.Operation.Call),
        "Could not execute ether transfer"
      );
    } else {
      bytes memory data = abi.encodeWithSignature(
        "transfer(address,uint256)",
        to,
        amount
      );
      require(
        safe.execTransactionFromModule(token, 0, data, Enum.Operation.Call),
        "Could not execute token transfer"
      );
    }
  }

  function getOperators(address dao) public view returns (address[] memory) {
    address[] memory array = new address[](daos[dao].operatorCount);

    // populate return array
    uint256 index = 0;
    address currentOwner = daos[dao].operators[SENTINEL_OWNERS];
    while (currentOwner != SENTINEL_OWNERS) {
      array[index] = currentOwner;
      currentOwner = daos[dao].operators[currentOwner];
      index++;
    }
    return array;
  }

  function getDeal(address dao, uint256 dealId)
    external
    view
    returns (Deal memory)
  {
    return daos[dao].deals[dealId];
  }

  modifier onlyOperator(address dao) {
    require(
      daos[dao].operators[msg.sender] != address(0) &&
        msg.sender != SENTINEL_OWNERS,
      "Only Operator"
    );
    _;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract VerifySignature {
  function getMessageHash(
    address _to,
    uint256 _amount,
    address token,
    uint256 workReportId,
    uint256 _nonce
  ) public pure returns (bytes32) {
    return
      keccak256(abi.encodePacked(_to, _amount, token, workReportId, _nonce));
  }

  function getEthSignedMessageHash(bytes32 _messageHash)
    public
    pure
    returns (bytes32)
  {
    return
      keccak256(
        abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
      );
  }

  function verify(
    bytes32 messageHash,
    bytes memory signature,
    address _signer
  ) public pure returns (bool) {
    bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

    return recoverSigner(ethSignedMessageHash, signature) == _signer;
  }

  function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
    public
    pure
    returns (address)
  {
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

    return ecrecover(_ethSignedMessageHash, v, r, s);
  }

  function splitSignature(bytes memory sig)
    public
    pure
    returns (
      bytes32 r,
      bytes32 s,
      uint8 v
    )
  {
    require(sig.length == 65, "invalid signature length");

    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }
  }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.9;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
  enum Operation {
    Call,
    DelegateCall
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