//contracts/Organizer.sol
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./organizer/TeamManager.sol";
import "./organizer/OperatorManager.sol";
import "./organizer/DealManager.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title Organizer - A utility smart contract for DAOs to define and manage their Organizational structure.
/// @author Sriram Kasyap Meduri - <[email protected]>
/// @author Krishna Kant Sharma - <[email protected]>

contract Organizer is TeamManager, OperatorManager, DealManager, Pausable {
  //  Events
  //  DAO Onboarded
  //  new DAO operator added
  //  DAO  Operators modified
  //  New team Created in DAO
  //  New Reviewers added to Team
  //  Reviewers modified in Team
  //  Reviewers delete from Team
  //  New Contributors added to Team
  //  Contributors Modified in team
  //  Contributors deleted from team

  // Constructor
  constructor() ERC1155("DAO Member") {}

  //
  //  Functions
  //

  //  Onboard A DAO
  function onboard(address[] calldata _operators, uint256 _teamCount) external {
    address safeAddress = msg.sender;
    // TODO: verify that safeAddress is Gnosis Multisig

    require(_operators.length > 0, "CS000");
    require(_teamCount > 0, "CS001");

    address currentoperator = SENTINEL_ADDRESS;
    uint256 currentTeamId = SENTINEL_UINT;

    daos[safeAddress].operatorCount = 0;
    daos[safeAddress].teamCount = _teamCount;

    // Create Team reviewer and contributor identifiers
    for (uint256 i = 0; i < _teamCount; i++) {
      daos[safeAddress].teams[currentTeamId] = tcounter;

      reviewerIdentifiers[tcounter] = mcounter;
      mcounter++;

      contributorIdentifiers[tcounter] = mcounter;
      mcounter++;

      currentTeamId = tcounter;
      tcounter++;

      // TODO: emit Team Created event
    }
    daos[safeAddress].teams[currentTeamId] = SENTINEL_UINT;

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
  }

  // Off-board a DAO
  function offboard(address _safeAddress)
    external
    onlyOnboarded(_safeAddress)
    onlyOperator(_safeAddress)
  {
    delete daos[_safeAddress];
  }

  // Allow only operators to transfer
}

//contracts/Organizer.sol
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./MemberManager.sol";

/// @title Team Manager for Organizer Contract
abstract contract TeamManager is MemberManager {
  // Add Team to DAO
  function addTeam(
    address _safeAddress,
    address[] memory _reviewers,
    address[] memory _contributors
  )
    public
    onlyOnboarded(_safeAddress)
    onlyOperator(_safeAddress)
    returns (uint256)
  {
    daos[_safeAddress].teams[tcounter] = daos[_safeAddress].teams[
      SENTINEL_UINT
    ];
    daos[_safeAddress].teams[SENTINEL_UINT] = tcounter;
    daos[_safeAddress].teamCount++;

    reviewerIdentifiers[tcounter] = mcounter;
    mcounter++;
    contributorIdentifiers[tcounter] = mcounter;
    mcounter++;

    addReviewers(tcounter, _reviewers);
    addContributors(tcounter, _contributors);

    tcounter++;
    return tcounter - 1;
  }

  // Get DAO team count
  function getTeamCount(address _safeAddress) external view returns (uint256) {
    return daos[_safeAddress].teamCount;
  }

  // Get DAO teams
  function getTeams(address _safeAddress)
    public
    view
    returns (uint256[] memory)
  {
    if (daos[_safeAddress].teamCount > 0) {
      uint256[] memory array = new uint256[](daos[_safeAddress].teamCount);

      uint256 i = 0;
      uint256 currentTeam = daos[_safeAddress].teams[SENTINEL_UINT];
      while (currentTeam != SENTINEL_UINT) {
        array[i] = currentTeam;
        currentTeam = daos[_safeAddress].teams[currentTeam];
        i++;
      }

      return array;
    } else {
      revert("CS011");
    }
  }

  // Remove Team From DAO
}

//contracts/Organizer.sol
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Modifiers.sol";

/// @title Operator Manager for Organizer Contract
abstract contract OperatorManager is Modifiers {
  // Get DAO operators
  function getOperators(address _safeAddress)
    external
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

      daos[_safeAddress].operators[_addressToAdd] = daos[_safeAddress]
        .operators[SENTINEL_ADDRESS];
      daos[_safeAddress].operators[SENTINEL_ADDRESS] = _addressToAdd;
      daos[_safeAddress].operatorCount++;
    }
    // daos[safeAddress].operators[currentoperator] = SENTINEL_ADDRESS;

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

      address cursor = SENTINEL_ADDRESS;
      while (daos[_safeAddress].operators[cursor] != _addressToRemove) {
        cursor = daos[_safeAddress].operators[cursor];
      }
      daos[_safeAddress].operators[cursor] = daos[_safeAddress].operators[
        _addressToRemove
      ];
      daos[_safeAddress].operators[_addressToRemove] = address(0);
      daos[_safeAddress].operatorCount--;
    }
  }
}

//contracts/Organizer.sol
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Modifiers.sol";
import "./Validators.sol";
import "./Enum.sol";
import "./VerifySignature.sol";

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

/// @title Deal Manager for Organizer Contract
abstract contract DealManager is Modifiers, VerifySignature {
  event DealCreated(
    address recipient,
    address reviewer,
    address dao,
    uint256 dealId,
    address operator
  );

  function createDeal(
    address _recipient,
    address _reviewer,
    address dao,
    uint256 teamId
  ) external onlyOperator(dao) {
    require(_recipient != address(0), "CS004");
    require(_reviewer != address(0), "CS004");

    require(dao != address(0), "CS004");

    require(isReviewer(teamId, _reviewer), "CS005");
    require(isContributor(teamId, _recipient), "CS006");

    uint256 dealId = daos[dao].dealNonce;

    Deal memory deal = Deal(_recipient, _reviewer, msg.sender, dealId, teamId);

    deals[dao][dealId] = deal;

    daos[dao].dealNonce++;

    emit DealCreated(_recipient, _reviewer, dao, dealId, msg.sender);
  }

  function verifyAndExecute(
    address payable _recipient,
    uint256 _amount,
    address tokenAddress,
    uint256 workReportId,
    uint256 dealId,
    uint256 teamId,
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
      deals[dao][dealId].recipient
    );

    bool isValidReviewer = verify(
      messageHash,
      reviewerSignature,
      deals[dao][dealId].reviewer
    );

    require(isValidContributor && isValidReviewer, "CS007");
    require(
      isContributor(teamId, deals[dao][dealId].recipient) &&
        isReviewer(teamId, deals[dao][dealId].reviewer),
      "CS008"
    );

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
        "CS009"
      );
    } else {
      bytes memory data = abi.encodeWithSignature(
        "transfer(address,uint256)",
        to,
        amount
      );
      require(
        safe.execTransactionFromModule(token, 0, data, Enum.Operation.Call),
        "CS010"
      );
    }
  }

  function getDeal(uint256 dealId, address dao)
    public
    view
    returns (
      address,
      address,
      uint256,
      address,
      uint256
    )
  {
    return (
      deals[dao][dealId].recipient,
      deals[dao][dealId].reviewer,
      deals[dao][dealId].dealId,
      deals[dao][dealId].operator,
      deals[dao][dealId].teamId
    );
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
import "./Modifiers.sol";

/// @title Member Manager for Organizer Contract
abstract contract MemberManager is Modifiers {
  function addContributors(uint256 _teamId, address[] memory _contributorsToAdd)
    internal
  {
    for (uint256 i = 0; i < _contributorsToAdd.length; i++) {
      require(!isContributor(_teamId, _contributorsToAdd[i]), "CS012");
      _mint(_contributorsToAdd[i], contributorIdentifiers[_teamId], 1, "");
    }
  }

  function addReviewers(uint256 _teamId, address[] memory _reviewersToAdd)
    internal
  {
    for (uint256 i = 0; i < _reviewersToAdd.length; i++) {
      require(!isReviewer(_teamId, _reviewersToAdd[i]), "CS013");
      _mint(_reviewersToAdd[i], reviewerIdentifiers[_teamId], 1, "");
    }
  }

  //  Add Reviewers to a Team
  function addReviewersToTeam(
    address _safeAddress,
    uint256 _teamId,
    address[] memory _reviewersToAdd
  )
    public
    onlyOnboarded(_safeAddress)
    onlyOperator(_safeAddress)
    teamExists(_safeAddress, _teamId)
  {
    addReviewers(_teamId, _reviewersToAdd);
  }

  //  Add contributors to a Team
  function addContributorsToTeam(
    address _safeAddress,
    uint256 _teamId,
    address[] memory _contributorsToAdd
  )
    public
    onlyOnboarded(_safeAddress)
    onlyOperator(_safeAddress)
    teamExists(_safeAddress, _teamId)
  {
    addContributors(_teamId, _contributorsToAdd);
  }

  //  Modify Contributors in a Team
  function modifyContributors(
    address _safeAddress,
    uint256 _teamId,
    address[] calldata _contributorsToAdd,
    address[] calldata _contributorsToRemove
  )
    public
    onlyOnboarded(_safeAddress)
    onlyOperator(_safeAddress)
    teamExists(_safeAddress, _teamId)
  {
    if (_contributorsToAdd.length > 0 && _contributorsToRemove.length > 0) {
      uint256 transferCount = _contributorsToAdd.length >=
        _contributorsToRemove.length
        ? _contributorsToRemove.length
        : _contributorsToAdd.length;

      uint256 burnCount = _contributorsToRemove.length >
        _contributorsToAdd.length
        ? _contributorsToRemove.length - _contributorsToAdd.length
        : 0;

      uint256 mintCount = _contributorsToAdd.length >
        _contributorsToRemove.length
        ? _contributorsToAdd.length - _contributorsToRemove.length
        : 0;

      uint256 cursor = 0;
      while (cursor < transferCount) {
        require(isContributor(_teamId, _contributorsToRemove[cursor]), "CS006");
        require(!isContributor(_teamId, _contributorsToAdd[cursor]), "CS012");
        safeTransferFrom(
          _contributorsToRemove[cursor],
          _contributorsToAdd[cursor],
          _teamId,
          1,
          ""
        );
        cursor++;
      }

      for (uint256 j = 0; j < burnCount; j++) {
        require(isContributor(_teamId, _contributorsToRemove[cursor]), "CS006");
        _burn(_contributorsToRemove[cursor], _teamId, 1);
        cursor++;
      }

      for (uint256 j = 0; j < mintCount; j++) {
        require(!isContributor(_teamId, _contributorsToAdd[cursor]), "CS012");
        _mint(_contributorsToAdd[cursor], _teamId, 1, "");
        cursor++;
      }
    }
  }

  //  Modify Reviewers in a Team
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

  // Only if team Exists
  modifier teamExists(address safeAddress, uint256 teamId) {
    require(
      teamId != 0 &&
        daos[safeAddress].teams[teamId] != 0 &&
        reviewerIdentifiers[teamId] != 0 &&
        contributorIdentifiers[teamId] != 0,
      "CS017"
    );
    _;
  }
}

//contracts/Organizer.sol
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Storage.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/// @title Validators for Organizer Contract
abstract contract Validators is Storage, ERC1155 {
  // Is operator?
  function isOperator(address _safeAddress, address _addressToCheck)
    public
    view
    returns (bool)
  {
    require(isDAOOnboarded(_safeAddress), "CS014");
    return daos[_safeAddress].operators[_addressToCheck] != address(0);
  }

  // Is reviewer of team?
  function isReviewer(uint256 teamId, address _addressToCheck)
    public
    view
    returns (bool)
  {
    return balanceOf(_addressToCheck, reviewerIdentifiers[teamId]) > 0;
  }

  // Is contributor of team?
  function isContributor(uint256 teamId, address _addressToCheck)
    public
    view
    returns (bool)
  {
    return balanceOf(_addressToCheck, contributorIdentifiers[teamId]) > 0;
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
    uint256 teamCount;
    mapping(address => address) operators;
    mapping(uint256 => uint256) teams;
    uint256 dealNonce;
  }

  struct Deal {
    address recipient;
    address reviewer;
    address operator;
    uint256 dealId;
    uint256 teamId;
  }

  enum Operation {
    Call,
    DelegateCall
  }

  //  //  Storage
  //  //  List of DAOs using the organizer
  //  Safe Address => DAO
  mapping(address => DAO) daos;

  // Safe Address => Deals
  mapping(address => mapping(uint256 => Deal)) deals;

  //  Team Nonce
  uint256 tcounter = 2;

  //  Member Nonce
  uint256 mcounter = 1;

  // Reviewer identifiers
  mapping(uint256 => uint256) reviewerIdentifiers;

  // Contributor identifiers
  mapping(uint256 => uint256) contributorIdentifiers;

  //  Sentrinel to use with linked lists
  address internal constant SENTINEL_ADDRESS = address(0x1);
  uint256 internal constant SENTINEL_UINT = 1;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.9;

contract Enum {
  enum Operation {
    Call,
    DelegateCall
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
    require(sig.length == 65, "CS019");

    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }
  }
}