// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Base.sol";

contract PrefixFoundryValidator is BaseFoundryValidator {
  struct Criterion {
    string prefix;
    bool approve;
  }

  Criterion[] public criteria;

  event CriteriaCreated(uint256 id, string prefix, bool approve);

  function createCriteria(string calldata prefix, bool approve)
    external
    returns (uint256)
  {
    criteria.push(Criterion(prefix, approve));
    uint256 newId = criteria.length - 1;

    // Emit the event
    emit CriteriaCreated(newId, prefix, approve);

    return newId;
  }

  function validate(uint256 id, string calldata label)
    external
    view
    override
    returns (bool)
  {
    require(id < criteria.length, "Criteria does not exist.");

    // Check if label starts with the prefix
    if (startsWith(label, criteria[id].prefix)) {
      return criteria[id].approve;
    }
    return !criteria[id].approve;
  }

  function startsWith(string memory str, string memory prefix)
    internal
    pure
    returns (bool)
  {
    bytes memory strBytes = bytes(str);
    bytes memory prefixBytes = bytes(prefix);

    if (prefixBytes.length > strBytes.length) {
      return false;
    }

    for (uint256 i = 0; i < prefixBytes.length; i++) {
      if (strBytes[i] != prefixBytes[i]) {
        return false;
      }
    }

    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Interface.sol";

contract BaseFoundryValidator is FoundryValidatorInterface {
  function validate(uint256, string calldata)
    external
    view
    virtual
    override
    returns (bool)
  {
    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface FoundryValidatorInterface {
  function validate(uint256 id, string calldata label)
    external
    view
    returns (bool);
}