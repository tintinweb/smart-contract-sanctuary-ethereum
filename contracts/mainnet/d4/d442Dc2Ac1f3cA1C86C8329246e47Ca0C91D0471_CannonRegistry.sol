//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {Storage} from "./Storage.sol";
import {Ownable} from "@synthetixio/core-contracts/contracts/ownership/Ownable.sol";
import {UUPSImplementation} from "@synthetixio/core-contracts/contracts/proxy/UUPSImplementation.sol";

contract CannonRegistry is Storage, Ownable, UUPSImplementation {
  error Unauthorized();
  error InvalidUrl(string url);
  error InvalidName(bytes32 name);
  error TooManyTags();
  error PackageNotFound();

  event PackagePublish(bytes32 indexed name, bytes32 indexed version, bytes32[] indexed tags, string url, address owner);
  event PackageVerify(bytes32 indexed name, address indexed verifier);
  event PackageUnverify(bytes32 indexed name, address indexed verifier);

  uint public constant MIN_PACKAGE_NAME_LENGTH = 3;

  function upgradeTo(address _newImplementation) public override onlyOwner {
    _upgradeTo(_newImplementation);
  }

  function validatePackageName(bytes32 _name) public pure returns (bool) {
    // each character must be in the supported charset

    for (uint i = 0; i < 32; i++) {
      if (_name[i] == bytes1(0)) {
        // must be long enough
        if (i < MIN_PACKAGE_NAME_LENGTH) {
          return false;
        }

        // last character cannot be `-`
        if (_name[i - 1] == "-") {
          return false;
        }

        break;
      }

      // must be in valid character set
      if (
        (_name[i] < "0" || _name[i] > "9") &&
        (_name[i] < "a" || _name[i] > "z") &&
        // first character cannot be `-`
        (i == 0 || _name[i] != "-")
      ) {
        return false;
      }
    }

    return true;
  }

  function publish(
    bytes32 _packageName,
    bytes32 _packageVersionName,
    bytes32[] memory _packageTags,
    string memory _packageVersionUrl
  ) external {
    if (_packageTags.length > 5) {
      revert TooManyTags();
    }

    if (bytes(_packageVersionUrl).length == 0) {
      revert InvalidUrl(_packageVersionUrl);
    }

    Package storage _p = _store().packages[_packageName];

    if (_p.owner != address(0) && _p.owner != msg.sender) {
      revert Unauthorized();
    }

    if (_p.owner == address(0)) {
      if (!validatePackageName(_packageName)) {
        revert InvalidName(_packageName);
      }

      _p.owner = msg.sender;
    }

    if (bytes(_p.versionUrls[_packageVersionName]).length == 0) {
      _p.versions.push(_packageVersionName);
    }

    _p.versionUrls[_packageVersionName] = _packageVersionUrl;

    for (uint i = 0; i < _packageTags.length; i++) {
      bytes32 _tag = _packageTags[i];

      if (bytes(_p.versionUrls[_tag]).length == 0) {
        _p.versions.push(_tag);
      }

      _p.versionUrls[_tag] = _packageVersionUrl;
    }

    emit PackagePublish(_packageName, _packageVersionName, _packageTags, _packageVersionUrl, msg.sender);
  }

  function nominatePackageOwner(bytes32 _packageName, address _newPackageOwner) external {
    Package storage _p = _store().packages[_packageName];

    if (_p.owner != msg.sender) {
      revert Unauthorized();
    }

    _p.nominatedOwner = _newPackageOwner;
  }

  function acceptPackageOwnership(bytes32 _packageName) external {
    Package storage _p = _store().packages[_packageName];

    address newOwner = _p.nominatedOwner;

    if (msg.sender != newOwner) {
      revert Unauthorized();
    }

    _p.owner = newOwner;
    _p.nominatedOwner = address(0);
  }

  function verifyPackage(bytes32 _packageName) external {
    if (_store().packages[_packageName].owner == address(0)) {
      revert PackageNotFound();
    }

    emit PackageVerify(_packageName, msg.sender);
  }

  function unverifyPackage(bytes32 _packageName) external {
    if (_store().packages[_packageName].owner == address(0)) {
      revert PackageNotFound();
    }

    emit PackageUnverify(_packageName, msg.sender);
  }

  function getPackageOwner(bytes32 _packageName) external view returns (address) {
    return _store().packages[_packageName].owner;
  }

  function getPackageNominatedOwner(bytes32 _packageName) external view returns (address) {
    return _store().packages[_packageName].nominatedOwner;
  }

  function getPackageVersions(bytes32 _packageName) external view returns (bytes32[] memory) {
    return _store().packages[_packageName].versions;
  }

  function getPackageUrl(bytes32 _packageName, bytes32 _packageVersionName) external view returns (string memory) {
    return _store().packages[_packageName].versionUrls[_packageVersionName];
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Storage {
  struct Store {
    mapping(bytes32 => Package) packages;
    mapping(address => bool) verifiers;
  }

  struct Package {
    address owner;
    address nominatedOwner;
    bytes32[] versions;
    mapping(bytes32 => string) versionUrls;
  }

  function _store() internal pure returns (Store storage store) {
    assembly {
      // bytes32(uint(keccak256("usecannon.cannon.registry")) - 1)
      store.slot := 0xc1d43f226fc86c5ffbb0bdc2447f5a3d1ab534c239d7dc14b283a49f5d5dbd2a
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