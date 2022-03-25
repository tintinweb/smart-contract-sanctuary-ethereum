// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IZDAOCore.sol";
import "./interfaces/IZNSHub.sol";

/*
zDAO
  - ID ~ Primary Key (increments for each new zDAO) (zDAO id)
  - snapshotId uint256
  - zNA uint256[]
  - ..... metadata and what not
*/

/* @feedback:

zNA association process:

Transaction 1: (By the owner of a zNA)*:
  - Make a request to associate zNA to zDAO
  - Store this request in this contract

Transaction 2: (By the Gnosis Safe)*:
  - Accepts the request to associate zNA to zDAO
  - Adds the zNA to the list + sets up any mappings

*for testing/debugging/initial development, these transactions can also
  be done by the contract owner (.owner())


-----

zNA disassociation:

Either the owner of zNA or the Gnosis Safe of a zDAO*:
  - Can make a transaction to remove the association from zNA <-> zDAO

*for testing/debugging/initial development, these transactions can also
  be done by the contract owner (.owner())

*/

//@feedback: These contracts need to be upgradeable using OZ upgrade pattern
contract ZDAOCore is IZDAOCore, OwnableUpgradeable {
  // @feedback: use uint256 instead of strings
  // https://docs.ens.domains/contract-api-reference/name-processing
  // zNA's work a similar way
  using Counters for Counters.Counter;

  Counters.Counter private daoCounter;

  IZNSHub public znsHub;
  uint256[] private ensHashes; // to fetch data from snapshot
  mapping(uint256 => bool) public ensPresence;

  mapping(uint256 => DAO) private zDAOs;
  mapping(uint256 => uint256) public zNATozDAO;

  function initialize(address _znsHub) external initializer {
    __Ownable_init();

    znsHub = IZNSHub(_znsHub);
    daoCounter.increment(); // Starting from 1
  }

  function setZNSHub(address _znsHub) external onlyOwner {
    znsHub = IZNSHub(_znsHub);
  }

  function getEnsHashes() external view returns (uint256[] memory) {
    return ensHashes;
  }

  function getZDAO(uint256 daoId)
    external
    view
    onlyValidDAOId(daoId)
    returns (
      uint256,
      uint256,
      address,
      uint256[] memory
    )
  {
    DAO storage dao = zDAOs[daoId];
    return (dao.id, dao.ens, dao.gnosis, dao.zNAs);
  }

  // @feedback: Create ZDAO
  // Add new entry into the list of zDAO's assigns an id
  // Require gnosis safe address
  // Only callable by owner
  function addNewDAO(uint256 ens, address gnosis) external onlyOwner {
    require(!ensPresence[ens], "Already added");

    ensHashes.push(ens);
    ensPresence[ens] = true;
    uint256 current = daoCounter.current();

    DAO storage dao = zDAOs[current];
    dao.id = current;
    dao.ens = ens;
    dao.gnosis = gnosis;

    daoCounter.increment();

    emit DAOCreated(current, ens);
  }

  function addZNAAssociation(uint256 daoId, uint256 zNA)
    external
    onlyValidDAOId(daoId)
    onlyZNAOwner(zNA)
  {
    uint256 currentDAO = zNATozDAO[zNA];
    require(currentDAO != daoId, "Already added");

    if (currentDAO > 0) {
      // remove current DAO
      _removeZNAAssociation(currentDAO, zNA);
    }

    zNATozDAO[zNA] = daoId;
    zDAOs[daoId].zNAs.push(zNA);

    emit LinkAdded(daoId, zNA);
  }

  function removeZNAAssociation(uint256 daoId, uint256 zNA)
    external
    onlyValidDAOId(daoId)
    onlyZNAOwner(zNA)
  {
    uint256 currentDAO = zNATozDAO[zNA];
    require(currentDAO == daoId, "Not associated yet");

    _removeZNAAssociation(daoId, zNA);
  }

  function _removeZNAAssociation(uint256 daoId, uint256 zNA) internal {
    DAO storage dao = zDAOs[daoId];
    uint256 length = zDAOs[daoId].zNAs.length;

    for (uint256 i = 0; i < length; i++) {
      if (dao.zNAs[i] == zNA) {
        dao.zNAs[i] = dao.zNAs[length - 1];
        dao.zNAs.pop();
        zNATozDAO[zNA] = 0;

        emit LinkRemoved(daoId, zNA);
        break;
      }
    }
  }

  modifier onlyZNAOwner(uint256 zNA) {
    require(znsHub.ownerOf(zNA) == msg.sender, "Not zNA owner");
    _;
  }

  modifier onlyValidDAOId(uint256 daoId) {
    require(daoId > 0 && daoId < daoCounter.current(), "Invalid daoId");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IZDAOCore {
  struct DAO {
    uint256 id;
    uint256 ens; // ENS record for now
    address gnosis;
    uint256[] zNAs;
    // @feedback: Include a gnosis safe address as a member
    // @feedback: Drop an admin concept of a zDAO
    // @feedback: Instead require certain methods to be called by the zDAO gnosis safe
  }

  //@feedback: Make sure events happen for any transaction that causes state change
  // ie: LinkRequested, LinkAccepted, LinkRemoved, DAOCreated
  event DAOCreated(uint256 indexed daoId, uint256 ens);
  event LinkAdded(uint256 indexed daoId, uint256 indexed zNA);
  event LinkRemoved(uint256 indexed daoId, uint256 indexed zNA);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
Addresses:
  Rinkeby: 0x90098737eB7C3e73854daF1Da20dFf90d521929a
*/

interface IZNSHub {
  // Returns the owner of a zNA given by `domainId`
  function ownerOf(uint256 domainId) external view returns (address);
}

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
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

pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}