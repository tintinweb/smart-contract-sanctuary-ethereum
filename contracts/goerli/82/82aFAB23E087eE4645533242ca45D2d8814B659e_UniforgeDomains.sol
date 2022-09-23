//SPDX-License-Identifier: CC-BY-1.0
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Counters.sol";

contract UniforgeDomains {
  address payable public owner;
  uint256 private _deployCost;

  using Counters for Counters.Counter;
  Counters.Counter private _domainIds;

  struct Domain {
    uint256 id;
    string name;
    string hash;
    address owner;
  }

  /* lookups for domains by id and domains by ipfs hash */
  mapping(uint256 => Domain) private idToDomain;
  mapping(string => Domain) private hashToDomain;

  /* Events */
  event DomainCreated(uint256 id, string name, string hash, address owner);
  event DomainUpdated(uint256 id, string name, string hash);
  event NewDomainOwner(uint256 id, address newOwner);

  /* Set Contract Ownership */
  constructor() {
    owner = payable(msg.sender);
    _deployCost = 1 ether;
  }

  function withdraw(uint256 _amount) public onlyOwner {
    owner.transfer(_amount);
  }

  function setDeployPrice(uint256 price) public onlyOwner {
    _deployCost = price * (1 ether);
  }

  /* fetches an individual domain by the content hash */
  function getDomainByHash(string memory hash)
    public
    view
    returns (Domain memory)
  {
    return hashToDomain[hash];
  }

  /* fetches all domains */
  function getAllDomains() public view returns (Domain[] memory) {
    uint256 itemCount = _domainIds.current();

    Domain[] memory domains = new Domain[](itemCount);
    for (uint256 i = 0; i < itemCount; i++) {
      uint256 currentId = i + 1;
      Domain storage currentItem = idToDomain[currentId];
      domains[i] = currentItem;
    }
    return domains;
  }

  /* checks if domain already exists */
  function getDomainByName(string memory name)
    public
    view
    returns (bool, Domain memory)
  {
    uint256 itemCount = _domainIds.current();
    Domain memory currentDomain;
    for (uint256 i = 0; i < itemCount; i++) {
      uint256 currentId = i + 1;
      currentDomain = idToDomain[currentId];
      if (keccak256(bytes(currentDomain.name)) == keccak256(bytes(name))) {
        return (true, currentDomain);
      }
    }
    return (false, currentDomain);
  }

  /* creates a new domain */
  function createDomain(string memory name, string memory hash) public payable {
    (bool domainExists, ) = getDomainByName(name);
    require(!domainExists, "Domain already exists");
    require(msg.value >= _deployCost, "Insuficient amount");
    owner.transfer(msg.value);
    _domainIds.increment();
    uint256 domainId = _domainIds.current();
    Domain storage domain = idToDomain[domainId];
    domain.id = domainId;
    domain.name = name;
    domain.hash = hash;
    domain.owner = msg.sender;
    hashToDomain[hash] = domain;
    emit DomainCreated(domainId, name, hash, msg.sender);
  }

  /* updates an existing domain */
  function updateDomain(
    uint256 domainId,
    string memory name,
    string memory hash
  ) public {
    (bool domainExists, ) = getDomainByName(name);
    require(!domainExists, "Domain already exists");
    Domain storage domain = idToDomain[domainId];
    require(domain.owner == msg.sender);
    domain.name = name;
    domain.hash = hash;
    idToDomain[domainId] = domain;
    hashToDomain[hash] = domain;
    emit DomainUpdated(domain.id, name, hash);
  }

  /* transfers an existing domain */
  function updateDomain(uint256 domainId, address newOwner) public {
    Domain storage domain = idToDomain[domainId];
    require(
      domain.owner == msg.sender,
      "You must be the domain owner in order to transfer domain ownership"
    );
    domain.owner = newOwner;
    emit NewDomainOwner(domainId, newOwner);
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
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