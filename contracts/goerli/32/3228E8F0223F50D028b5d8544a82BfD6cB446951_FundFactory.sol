// SPDX-License-Identifier: ISC

// Solidity compiler version
pragma solidity 0.8.16;

// Imports

// Import this file to use console.log
//import "hardhat/console.sol"; // console.log("Block timestamp is %o", block.timestamp);
import {Fund} from "./Fund.sol";

// Contract factory -> contract to deploy
contract FundFactory {
  // All fund contracts created are stored here
  Fund[] public deployedFunds;

  event NewFund(address indexed fundAddress, string indexed name, string description, address indexed creator, uint256 createdAt);

  // Function to create new fund and store it in the factory
  function createFund(
    string memory _name,
    string memory _description,
    address[] memory _managers,
    bool _managersCanBeAddedOrRemoved,
    bool _managersCanTransferMoneyWithoutARequest,
    bool _requestsCanBeCreated,
    bool _onlyManagersCanCreateARequest,
    bool _onlyContributorsCanApproveARequest,
    uint256 _minimumContributionPercentageRequired,
    uint256 _minimumApprovalsPercentageRequired
  ) public {
    require(
      (_managersCanTransferMoneyWithoutARequest && _managers.length > 0) ||
        (_requestsCanBeCreated && (!_onlyManagersCanCreateARequest || _managers.length > 0)),
      "There would be no way to withdraw the money from the contract"
    );
    require(_minimumContributionPercentageRequired < 101, "Incorrect contribution percentage");
    require(_minimumApprovalsPercentageRequired < 101, "Incorrect approvals percentage");

    Fund _newFund = new Fund(
      _name,
      _description,
      msg.sender,
      _managers,
      _managersCanBeAddedOrRemoved,
      _managersCanTransferMoneyWithoutARequest,
      _requestsCanBeCreated,
      _onlyManagersCanCreateARequest,
      _onlyContributorsCanApproveARequest,
      _minimumContributionPercentageRequired,
      _minimumApprovalsPercentageRequired
    );
    deployedFunds.push(_newFund);

    emit NewFund(address(_newFund), _name, _description, msg.sender, block.timestamp);
  }

  function getDeployedFundsCount() public view returns (uint256) {
    return deployedFunds.length;
  }

  function getDeployedFunds() public view returns (Fund[] memory) {
    return deployedFunds;
  }
}

// SPDX-License-Identifier: ISC

// Solidity compiler version
pragma solidity 0.8.16;

// Imports

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Fund contract -> they are deployed by the factory
contract Fund is Context, ReentrancyGuard {
  // Libraries

  using Counters for Counters.Counter;

  // Structs

  struct Request {
    string description;
    address petitioner;
    address recipient;
    uint256 valueToTransfer;
    uint256 transferredValue;
    bool complete;
    mapping(address => bool) approvals;
    Counters.Counter approvalsCount;
  }

  // Fund data

  string public name;
  string public description;
  address public creator;
  uint256 public createdAt = block.timestamp;

  // Managers data

  address[] public managers;
  mapping(address => bool) public isManager;
  bool public managersCanBeAddedOrRemoved;

  // Contributors data

  address[] public contributors;
  mapping(address => uint256) public contributions;
  uint256 public totalContributions;

  // Requests data

  bool public managersCanTransferMoneyWithoutARequest;

  Request[] public requests;
  bool public requestsCanBeCreated;
  bool public onlyManagersCanCreateARequest;
  bool public onlyContributorsCanApproveARequest;
  uint256 public minimumContributionPercentageRequired;
  uint256 public minimumApprovalsPercentageRequired;

  // Events

  event NewManager(address indexed manager);

  event RemoveManager(address indexed manager);

  event Contribute(address indexed contributor, uint256 value);

  event Transfer(address indexed sender, address indexed to, uint256 value);

  event NewRequest(string description, address indexed petitioner, address indexed recipient, uint256 valueToTransfer);

  event ApproveRequest(uint256 indexed requestIndex, address indexed approver);

  event FinalizeRequest(uint256 indexed requestIndex, uint256 transferredValue);

  // Modifiers

  modifier onlyManagers() {
    require(isManager[_msgSender()], "Only managers can access");
    _;
  }

  constructor(
    string memory _name,
    string memory _description,
    address _creator,
    address[] memory _managers,
    bool _managersCanBeAddedOrRemoved,
    bool _managersCanTransferMoneyWithoutARequest,
    bool _requestsCanBeCreated,
    bool _onlyManagersCanCreateARequest,
    bool _onlyContributorsCanApproveARequest,
    uint256 _minimumContributionPercentageRequired,
    uint256 _minimumApprovalsPercentageRequired
  ) {
    name = _name;
    description = _description;
    creator = _creator;
    _addManagers(_managers);
    managersCanBeAddedOrRemoved = _managersCanBeAddedOrRemoved;
    managersCanTransferMoneyWithoutARequest = _managersCanTransferMoneyWithoutARequest;
    requestsCanBeCreated = _requestsCanBeCreated;
    onlyManagersCanCreateARequest = _onlyManagersCanCreateARequest;
    onlyContributorsCanApproveARequest = _onlyContributorsCanApproveARequest;
    minimumContributionPercentageRequired = _minimumContributionPercentageRequired;
    minimumApprovalsPercentageRequired = _minimumApprovalsPercentageRequired;
  }

  // Public functions

  function addNewManagers(address[] memory _managers) public {
    require(managersCanBeAddedOrRemoved, "New managers can not be added");
    require(isManager[_msgSender()], "Only managers can access");
    require(_managers.length > 0, "You have to send one or more addresses");

    _addManagers(_managers);
  }

  function removeManager(uint256 _index) public {
    require(managersCanBeAddedOrRemoved, "Managers can not be removed");
    require(isManager[_msgSender()], "Only managers can access");
    uint256 _managersCount = managersCount();
    require(
      _managersCount > 1 || (requestsCanBeCreated && !onlyManagersCanCreateARequest),
      "There would be no way to withdraw the money from the contract"
    );

    address _manager = managers[_index];

    delete isManager[_manager];
    unchecked {
      for (uint256 i = _index; i < _managersCount - 1; i++) {
        managers[i] = managers[i + 1];
      }
    }
    managers.pop();

    emit RemoveManager(_manager);
  }

  function managersCount() public view returns (uint256) {
    return managers.length;
  }

  function getManagers() public view returns (address[] memory) {
    return managers;
  }

  function contribute() public payable {
    _contribute(_msgSender());
  }

  function contributeFor(address _for) public payable {
    _contribute(_for);
  }

  function contributorsCount() public view returns (uint256) {
    return contributors.length;
  }

  function getContributors() public view returns (address[] memory) {
    return contributors;
  }

  function balance() public view returns (uint256) {
    return address(this).balance;
  }

  function transfer(address _to, uint256 _value) public {
    require(managersCanTransferMoneyWithoutARequest, "Managers can not transfer money without a request");
    require(isManager[_msgSender()], "Only managers can access");

    payable(_to).transfer(_value);

    emit Transfer(_msgSender(), _to, _value);
  }

  function createRequest(
    string memory _description,
    address _recipient,
    uint256 _valueToTransfer
  ) public {
    require(requestsCanBeCreated, "Requests can not be created");

    bool _isManager = isManager[_msgSender()];
    require(
      !onlyManagersCanCreateARequest || (onlyManagersCanCreateARequest && _isManager),
      "Only managers can create a request"
    );

    Request storage newRequest = requests.push();

    newRequest.description = _description;
    newRequest.petitioner = _msgSender();
    newRequest.recipient = _recipient;
    newRequest.valueToTransfer = _valueToTransfer;

    emit NewRequest(_description, _msgSender(), _recipient, _valueToTransfer);
  }

  function requestsCount() public view returns (uint256) {
    return requests.length;
  }

  /*function getRequests() public view returns (Request[] memory) {
    return requests;
  }*/

  function approveRequest(uint256 _index) public {
    Request storage request = requests[_index];

    require(!request.complete, "The request has already been completed");
    require(
      (contributions[_msgSender()] / totalContributions) * 100 >= minimumContributionPercentageRequired ||
        (!onlyContributorsCanApproveARequest && isManager[_msgSender()]),
      "You can not approve a request"
    );
    require(!request.approvals[_msgSender()], "You have already approved this request");

    request.approvals[_msgSender()] = true;
    request.approvalsCount.increment();

    emit ApproveRequest(_index, _msgSender());
  }

  function finalizeRequest(uint256 _index) public nonReentrant {
    Request storage request = requests[_index];

    require(request.petitioner == _msgSender(), "You are not the petitioner of the request");
    require(!request.complete, "The request has already been completed");
    if (onlyContributorsCanApproveARequest) {
      require(
        (request.approvalsCount.current() / contributorsCount()) * 100 >= minimumApprovalsPercentageRequired,
        "The request has not been approved yet"
      );
    } else {
      require(
        (request.approvalsCount.current() / (managersCount() + contributorsCount())) * 100 >= minimumApprovalsPercentageRequired,
        "The request has not been approved yet"
      );
    }

    uint256 _valueToTransfer = request.valueToTransfer;
    if (_valueToTransfer > balance()) {
      _valueToTransfer = balance();
    }

    payable(request.recipient).transfer(_valueToTransfer);
    request.transferredValue = _valueToTransfer;
    request.complete = true;

    emit FinalizeRequest(_index, _valueToTransfer);
  }

  // Private functions

  function _addManagers(address[] memory _managers) private {
    for (uint256 i; i < _managers.length; ) {
      if (!isManager[_managers[i]]) {
        managers.push(_managers[i]);
        isManager[_managers[i]] = true;

        emit NewManager(_managers[i]);
      }

      unchecked {
        i++;
      }
    }
  }

  function _contribute(address _contributor) private {
    require(msg.value > 0, "The contribution must be greater than zero");

    if (contributions[_contributor] == 0) {
      contributors.push(_contributor);
    }
    contributions[_contributor] += msg.value;
    totalContributions += msg.value;

    emit Contribute(_contributor, msg.value);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}