pragma solidity >=0.8.4;

interface IReverseRegistrar {
    function setDefaultResolver(address resolver) external;

    function claim(address owner) external returns (bytes32);

    function claimForAddr(
        address addr,
        address owner,
        address resolver
    ) external returns (bytes32);

    function claimWithResolver(address owner, address resolver)
        external
        returns (bytes32);

    function setName(string memory name) external returns (bytes32);

    function setNameForAddr(
        address addr,
        address owner,
        address resolver,
        string memory name
    ) external returns (bytes32);

    function node(address addr) external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IENS {
    struct Record {
        address owner;
        address resolver;
        uint64 ttl;
    }

    function owner(bytes32 _node) external view returns (address);

    function resolver(bytes32 _node) external view returns (address);

    function ttl(bytes32 _node) external view returns (uint64);

    function setOwner(bytes32 _node, address _owner) external;

    function setSubnodeRecord(
        bytes32 _node,
        bytes32 _label,
        address _owner,
        address _resolver,
        uint64 _ttl
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// @dev Interface for TNSRegister target contract
interface ITNSRegister {
    function setSubnode(
        bytes32 _node,
        bytes32 _label,
        address _owner,
        address _resolver,
        uint64 _ttl
    ) external;

    function setName(string memory _name) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IENS} from "../interfaces/IENS.sol";
import {IReverseRegistrar} from "@ensdomains/contracts/registry/IReverseRegistrar.sol";
import {ITNSRegister} from "../interfaces/ITNSRegister.sol";

/// @title TNSRegister
/// @author Tessera
/// @notice Target contract for registering subdomains of ENS parent nodes
contract TNSRegister is ITNSRegister {
    /// @notice Address of ENSRegistry contract
    address public immutable ens;
    /// @notice Address of ReverseRegistrar contract
    address public immutable reverse;

    /// @notice Initializes ENS contracts
    constructor(address _ens, address _reverse) {
        ens = _ens;
        reverse = _reverse;
    }

    /// @notice Sets the subnode domain of an ENS node
    /// @param _node Hash of the ENS parent node
    /// @param _label Hash of the subdomain
    /// @param _owner Address of the registration owner
    /// @param _resolver Address of the Resolve contract
    /// @param _ttl Time to live of the subdomain
    function setSubnode(
        bytes32 _node,
        bytes32 _label,
        address _owner,
        address _resolver,
        uint64 _ttl
    ) external {
        IENS(ens).setSubnodeRecord(_node, _label, _owner, _resolver, _ttl);
    }

    /// @notice Sets the primary name of the vault to the ENS identifier
    /// @param _name Identifier of the ENS domain
    function setName(string memory _name) external {
        IReverseRegistrar(reverse).setName(_name);
    }
}