//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {Storage} from "./Storage.sol";
import {Ownable} from "@synthetixio/core-contracts/contracts/ownership/Ownable.sol";
import {UUPSImplementation} from "@synthetixio/core-contracts/contracts/proxy/UUPSImplementation.sol";

contract CannonRegistry is Storage, Ownable, UUPSImplementation {
  error Unauthorized();
  error InvalidUrl(string url);
  error InvalidName(bytes32 name);

  event ProtocolPublish(bytes32 indexed name, bytes32 indexed version, bytes32[] indexed tags, string url, address owner);

  uint public constant MIN_PACKAGE_NAME_LENGTH = 3;

  function upgradeTo(address newImplementation) public override onlyOwner {
    _upgradeTo(newImplementation);
  }

  function validatePackageName(bytes32 name) public pure returns (bool) {
    // each character must be in the supported charset

    for (uint i = 0; i < 32; i++) {
      if (name[i] == bytes1(0)) {
        // must be long enough
        if (i < MIN_PACKAGE_NAME_LENGTH) {
          return false;
        }

        // last character cannot be `-`
        if (name[i - 1] == "-") {
          return false;
        }

        break;
      }

      // must be in valid character set
      if (
        (name[i] < "0" || name[i] > "9") &&
        (name[i] < "a" || name[i] > "z") &&
        // first character cannot be `-`
        (i == 0 || name[i] != "-")
      ) {
        return false;
      }
    }

    return true;
  }

  function publish(
    bytes32 _name,
    bytes32 _version,
    bytes32[] memory _tags,
    string memory _url
  ) external {
    Store storage s = _store();

    if (bytes(_url).length == 0) {
      revert InvalidUrl(_url);
    }

    if (s.owners[_name] != address(0) && s.owners[_name] != msg.sender) {
      revert Unauthorized();
    }

    if (s.owners[_name] == address(0)) {
      if (!validatePackageName(_name)) {
        revert InvalidName(_name);
      }

      s.owners[_name] = msg.sender;
      s.packages.push(_name);
    }

    if (bytes(s.urls[_name][_version]).length == 0) {
      s.versions[_name].push(_version);
    }

    s.urls[_name][_version] = _url;

    for (uint i = 0; i < _tags.length; i++) {
      s.urls[_name][_tags[i]] = _url;
    }

    emit ProtocolPublish(_name, _version, _tags, _url, msg.sender);
  }

  function nominatePackageOwner(bytes32 _name, address _newOwner) external {
    Store storage s = _store();

    if (s.owners[_name] != msg.sender) {
      revert Unauthorized();
    }

    s.nominatedOwner[_name] = _newOwner;
  }

  function acceptPackageOwnership(bytes32 _name) external {
    Store storage s = _store();

    address newOwner = s.nominatedOwner[_name];

    if (msg.sender != newOwner) {
      revert Unauthorized();
    }

    s.owners[_name] = newOwner;
    s.nominatedOwner[_name] = address(0);
  }

  function getPackageNominatedOwner(bytes32 _protocolName) external view returns (address) {
    return _store().nominatedOwner[_protocolName];
  }

  function getPackages() external view returns (bytes32[] memory) {
    return _store().packages;
  }

  function getPackageVersions(bytes32 _protocolName) external view returns (bytes32[] memory) {
    return _store().versions[_protocolName];
  }

  function getPackageUrl(bytes32 _protocolName, bytes32 _protocolVersion) external view returns (string memory) {
    return _store().urls[_protocolName][_protocolVersion];
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Storage {
    struct Store {
        bytes32[] packages;
        mapping(bytes32 => mapping(bytes32 => string)) urls;
        mapping(bytes32 => address) owners;
        mapping(bytes32 => bytes32[]) versions;
        mapping(bytes32 => address) nominatedOwner;
    }

    function _store() internal pure returns (Store storage store) {
        assembly {
            // bytes32(uint(keccak256("usecannon.cannon-registry")) - 1)
            store.slot := 0xd386b53009e5ad6d6853d9184c05c992a989289c1761a6d9dd1cdfd204098522
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableMixin.sol";
import "../interfaces/IOwnable.sol";
import "../errors/AddressError.sol";
import "../errors/ChangeError.sol";

contract Ownable is IOwnable, OwnableMixin {
    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);

    error NotNominated(address addr);

    function acceptOwnership() public override {
        OwnableStore storage store = _ownableStore();

        address currentNominatedOwner = store.nominatedOwner;
        if (msg.sender != currentNominatedOwner) {
            revert NotNominated(msg.sender);
        }

        emit OwnerChanged(store.owner, currentNominatedOwner);
        store.owner = currentNominatedOwner;

        store.nominatedOwner = address(0);
    }

    function nominateNewOwner(address newNominatedOwner) public override onlyOwnerIfSet {
        OwnableStore storage store = _ownableStore();

        if (newNominatedOwner == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (newNominatedOwner == store.nominatedOwner) {
            revert ChangeError.NoChange();
        }

        store.nominatedOwner = newNominatedOwner;
        emit OwnerNominated(newNominatedOwner);
    }

    function renounceNomination() external override {
        OwnableStore storage store = _ownableStore();

        if (store.nominatedOwner != msg.sender) {
            revert NotNominated(msg.sender);
        }

        store.nominatedOwner = address(0);
    }

    function owner() external view override returns (address) {
        return _ownableStore().owner;
    }

    function nominatedOwner() external view override returns (address) {
        return _ownableStore().nominatedOwner;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IUUPSImplementation.sol";
import "../errors/AddressError.sol";
import "../errors/ChangeError.sol";
import "../utils/AddressUtil.sol";
import "./ProxyStorage.sol";

abstract contract UUPSImplementation is IUUPSImplementation, ProxyStorage {
    event Upgraded(address implementation);

    error ImplementationIsSterile(address implementation);
    error UpgradeSimulationFailed();

    function _upgradeTo(address newImplementation) internal virtual {
        if (newImplementation == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (!AddressUtil.isContract(newImplementation)) {
            revert AddressError.NotAContract(newImplementation);
        }

        ProxyStore storage store = _proxyStore();

        if (newImplementation == store.implementation) {
            revert ChangeError.NoChange();
        }

        if (!store.simulatingUpgrade && _implementationIsSterile(newImplementation)) {
            revert ImplementationIsSterile(newImplementation);
        }

        store.implementation = newImplementation;

        emit Upgraded(newImplementation);
    }

    function _implementationIsSterile(address candidateImplementation) internal virtual returns (bool) {
        (bool simulationReverted, bytes memory simulationResponse) = address(this).delegatecall(
            abi.encodeCall(this.simulateUpgradeTo, (candidateImplementation))
        );

        return
            !simulationReverted &&
            keccak256(abi.encodePacked(simulationResponse)) == keccak256(abi.encodePacked(UpgradeSimulationFailed.selector));
    }

    function simulateUpgradeTo(address newImplementation) public override {
        ProxyStore storage store = _proxyStore();

        store.simulatingUpgrade = true;

        address currentImplementation = store.implementation;
        store.implementation = newImplementation;

        (bool rollbackSuccessful, ) = newImplementation.delegatecall(
            abi.encodeCall(this.upgradeTo, (currentImplementation))
        );

        if (!rollbackSuccessful || _proxyStore().implementation != currentImplementation) {
            revert UpgradeSimulationFailed();
        }

        store.simulatingUpgrade = false;

        // solhint-disable-next-line reason-string
        revert();
    }

    function getImplementation() external view override returns (address) {
        return _proxyStore().implementation;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableStorage.sol";
import "../errors/AccessError.sol";

contract OwnableMixin is OwnableStorage {
    modifier onlyOwner() {
        _onlyOwner();

        _;
    }

    modifier onlyOwnerIfSet() {
        address owner = _getOwner();

        // if owner is set then check if msg.sender is the owner
        if (owner != address(0)) {
            _onlyOwner();
        }

        _;
    }

    function _onlyOwner() internal view {
        if (msg.sender != _getOwner()) {
            revert AccessError.Unauthorized(msg.sender);
        }
    }

    function _getOwner() internal view returns (address) {
        return _ownableStore().owner;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOwnable {
    function acceptOwnership() external;

    function nominateNewOwner(address newNominatedOwner) external;

    function renounceNomination() external;

    function owner() external view returns (address);

    function nominatedOwner() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AddressError {
    error ZeroAddress();
    error NotAContract(address contr);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ChangeError {
    error NoChange();
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OwnableStorage {
    struct OwnableStore {
        bool initialized;
        address owner;
        address nominatedOwner;
    }

    function _ownableStore() internal pure returns (OwnableStore storage store) {
        assembly {
            // bytes32(uint(keccak256("io.synthetix.ownable")) - 1)
            store.slot := 0x66d20a9eef910d2df763b9de0d390f3cc67f7d52c6475118cd57fa98be8cf6cb
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AccessError {
    error Unauthorized(address addr);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUUPSImplementation {
    function upgradeTo(address newImplementation) external;

    function simulateUpgradeTo(address newImplementation) external;

    function getImplementation() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AddressUtil {
    function isContract(address account) internal view returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(account)
        }

        return size > 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProxyStorage {
    struct ProxyStore {
        address implementation;
        bool simulatingUpgrade;
    }

    function _proxyStore() internal pure returns (ProxyStore storage store) {
        assembly {
            // bytes32(uint(keccak256("io.synthetix.v3.proxy")) - 1)
            store.slot := 0x32402780481dd8149e50baad867f01da72e2f7d02639a6fe378dbd80b6bb446e
        }
    }
}