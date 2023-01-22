// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;

/*
  __  __   U _____ u  _____
U|' \/ '|u \| ___"|/ |___"/u
\| |\/| |/  |  _|"   U_|_ \/
 | |  | |   | |___    ___) |
 |_|  |_|   |_____|  |____/
<<,-,,-.    <<   >>   _// \\
 (./  \.)  (__) (__) (__)(__)

 _______     ________    _________   ______     __ __ __     ________     __  __
/______/\   /_______/\  /________/\ /_____/\   /_//_//_/\   /_______/\   /_/\/_/\
\::::__\/__ \::: _  \ \ \__.::.__\/ \::::_\/_  \:\\:\\:\ \  \::: _  \ \  \ \ \ \ \
 \:\ /____/\ \::(_)  \ \   \::\ \    \:\/___/\  \:\\:\\:\ \  \::(_)  \ \  \:\_\ \ \
  \:\\_  _\/  \:: __  \ \   \::\ \    \::___\/_  \:\\:\\:\ \  \:: __  \ \  \::::_\/
   \:\_\ \ \   \:.\ \  \ \   \::\ \    \:\____/\  \:\\:\\:\ \  \:.\ \  \ \   \::\ \
    \_____\/    \__\/\__\/    \__\/     \_____\/   \_______\/   \__\/\__\/    \__\/ beta

what
	> join the beta and register your project today

from
	> charchar.me3.eth
	> brendan.me3.eth*/

import {Owned} from "solmate/auth/Owned.sol";
import {IRegistrar} from "./Registrar.sol";
import {IAuthoriser} from "./IAuthoriser.sol";
import {IRulesEngine} from "./IRulesEngine.sol";
import {Utilities} from "./Utils.sol";

/// @title me3 Beta Gateway
/// @author charchar.eth
/// @notice Beta Gateway allowing any project to signup to our subdomain registrar
/// @dev 0.1.0
contract GatewayBeta is Owned(msg.sender) {
    IRegistrar private registrar;

    /// @notice the cost to signup
    uint256 public cost = 0;

    constructor(address registrarContract) {
        registrar = IRegistrar(registrarContract);
    }

    /// @notice Register a project with the me3 subdomain registrar
    /// @param node The namehashed ENS node of the project, eg namehash(me3.eth)
    /// @param authoriser The authorisation contract
    /// @param rules The rules around availability, validity, and usage
    function register(bytes32 node, IAuthoriser authoriser, IRulesEngine rules) external payable {
        require(msg.value == cost, "Please pay exactly");

        registrar.setProjectNode(node, authoriser, rules, true, msg.sender);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;

interface IAuthoriser {
    // function forEditing(address, string memory) external view returns (bool);
    function canRegister(bytes32 node, address sender, bytes[] memory blob) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;

/// @title Rules Engine Interface
/// @author charchar.eth
/// @notice Functions that a RulesEngine contract should support
interface IRulesEngine {
    /// @notice Determine if a label meets a projects minimum requirements
    /// @param node Fully qualified, namehashed ENS name
    /// @param label The 'best' in 'best.bob.eth'
    /// @return True if label is valid, false otherwise
    function isLabelValid(bytes32 node, string memory label) external view returns (bool);

    /// @notice Determine who should own the subnode
    /// @param registrant The address that is registereing a subnode
    /// @return The address that should own the subnode
    function subnodeOwner(address registrant) external view returns (address);

    /// @notice Determine the resolver contract to use for project profiles
    /// @param node Fully qualified, namehashed ENS name
    /// @param label The 'best' in 'best.bob.eth'
    /// @param registrant The address that is registereing a subnode
    /// @return The address of the resolver
    function profileResolver(bytes32 node, string memory label, address registrant) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;

/*
  __  __   U _____ u  _____
U|' \/ '|u \| ___"|/ |___"/u
\| |\/| |/  |  _|"   U_|_ \/
 | |  | |   | |___    ___) |
 |_|  |_|   |_____|  |____/
<<,-,,-.    <<   >>   _// \\
 (./  \.)  (__) (__) (__)(__)

 ______     ______    _______    ________   ______   _________   ______     ________    ______
/_____/\   /_____/\  /______/\  /_______/\ /_____/\ /________/\ /_____/\   /_______/\  /_____/\
\:::_ \ \  \::::_\/_ \::::__\/__\__.::._\/ \::::_\/ \__.::.__\/ \:::_ \ \  \::: _  \ \ \:::_ \ \
 \:(_) ) )_ \:\/___/\ \:\ /____/\  \::\ \   \:\/___/\  \::\ \    \:(_) ) )_ \::(_)  \ \ \:(_) ) )_
  \: __ `\ \ \::___\/_ \:\\_  _\/  _\::\ \__ \_::._\:\  \::\ \    \: __ `\ \ \:: __  \ \ \: __ `\ \
   \ \ `\ \ \ \:\____/\ \:\_\ \ \ /__\::\__/\  /____\:\  \::\ \    \ \ `\ \ \ \:.\ \  \ \ \ \ `\ \ \
    \_\/ \_\/  \_____\/  \_____\/ \________\/  \_____\/   \__\/     \_\/ \_\/  \__\/\__\/  \_\/ \_\/

what
	> register subdomains for your NFT, DAO, or frenclub

from
	> charchar.me3.eth
	> brendan.me3.eth*/

import {Owned} from "solmate/auth/Owned.sol";

import {IAuthoriser} from "./IAuthoriser.sol";
import {IRulesEngine} from "./IRulesEngine.sol";
import {Utilities} from "./Utils.sol";

interface IENS {
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // https://docs.ens.domains/contract-api-reference/ens#set-subdomain-record
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl)
        external
        virtual;

    // https://docs.ens.domains/contract-api-reference/ens#get-owner
    function owner(bytes32 node) external view returns (address);
}

interface IRegistrar {
    /// @notice Register a subdomain under node
    /// @param node The project node to use
    /// @param label The subdomain text, eg the 'hopeless' in hopeless.abc.eth
    /// @param authData Additional data to help the authoriser authorise
    function register(bytes32 node, string memory label, address owner, bytes[] memory authData) external;

    /// @notice Check if a label is valid for a project
    /// @param node The project node
    /// @param label The subdomain label to validate
    /// @return True if the label is valid, according to the project rules, false otherwise
    function valid(bytes32 node, string memory label) external view returns (bool);

    /// @notice Register a project as a subdomain provider
    /// @param node The fully qualified, namehashed ENS name
    /// @param authoriser The contract that will perform authorisation
    /// @param rules The contract that will provide rules and validation
    /// @param enable Allow project auth and rules to run
    /// @param projectOwner The owner of the project and the address which is authorised to make updates
    function setProjectNode(bytes32 node, IAuthoriser authoriser, IRulesEngine rules, bool enable, address projectOwner)
        external;
}

/// @title me3 Subdomain Registrar
/// @author charchar.eth
/// @notice Provides third-party projects with a common subdomain registration function
/// @dev 0.1.0
contract Registrar is IRegistrar, Owned(msg.sender) {
    IENS private ens;
    address private gateway;

    /// @notice Lookup enabled/disabled state by project node
    mapping(bytes32 => bool) public nodeEnabled;

    /// @notice Lookup authoriser contract by project node
    mapping(bytes32 => IAuthoriser) public nodeAuthorisers;

    /// @notice Lookup rules contract by project node
    mapping(bytes32 => IRulesEngine) public nodeRules;

    /// @notice Lookup owner address by project node
    mapping(bytes32 => address) public nodeOwners;

    /// @notice A subnode has been registered
    /// @param node The fully qualified, namehashed ENS name for the project
    /// @param label The registered label as keccack256
    /// @param owner The registered owner
    /// @param registrant The address that requested registration
    event SubnodeRegistered(bytes32 indexed node, bytes32 indexed label, address owner, address registrant);

    /// @notice A project has been enabled/disabled
    /// @param node The fully qualified, namehashed ENS name for the project
    /// @param authoriser The address of the authorising contract
    /// @param rules The address of the rules engine contract
    /// @param enabled True if the project is now enabled, false if now disabled
    event ProjectStateChanged(bytes32 indexed node, address authoriser, address rules, bool enabled);

    modifier isAuthorised(bytes32 node, address user, bytes[] memory blob) {
        IAuthoriser authoriser = nodeAuthorisers[node];

        require(authoriser.canRegister(node, user, blob), "User is not authorised");
        _;
    }

    modifier permissionedCaller() {
        require(gateway != address(0x0), "Gateway must be set");
        require(msg.sender == owner || msg.sender == gateway, "Caller does not have permission");
        _;
    }

    modifier registeredNode(bytes32 node) {
        require(nodeEnabled[node], "Node is not enabled");
        _;
    }

    constructor(address _registry) {
        ens = IENS(_registry);
    }

    /// @notice Change the address of the gateway which can register nodes
    /// @param _gateway The new address
    /// @dev Setting the gateway to address(0) will disable any project node registrations
    function setGateway(address _gateway) external onlyOwner {
        gateway = _gateway;
    }

    /// @notice Add a new project to the directory
    /// @param node The project node that subdomains will be based on
    /// @param authoriser The authorisation contract
    /// @param rules The rules around availability, validity, and usage
    /// @param enable Turn the project on or off
    /// @param projectOwner The owner of the project and the address which is authorised to make updates
    function setProjectNode(bytes32 node, IAuthoriser authoriser, IRulesEngine rules, bool enable, address projectOwner)
        external
        permissionedCaller
    {
        address currentOwner = nodeOwners[node];
        require(currentOwner == projectOwner || currentOwner == address(0x0), "Project owner mismatch");
        emit ProjectStateChanged(node, address(authoriser), address(rules), enable);

        nodeOwners[node] = projectOwner;
        nodeAuthorisers[node] = authoriser;
        nodeRules[node] = rules;
        nodeEnabled[node] = enable;
    }

    /// @notice Register a subdomain under node
    /// @param node The project node to use
    /// @param label The subdomain text, eg the 'hopeless' in hopeless.abc.eth
    /// @param owner Who will own the subdomain
    function register(bytes32 node, string memory label, address owner, bytes[] memory blob)
        public
        registeredNode(node)
        isAuthorised(node, msg.sender, blob)
    {
        require(valid(node, label), "Invalid according to project");
        require(available(node, label), "Label unavailable to register");

        bytes32 hashedLabel = Utilities.labelhash(label);
        address owner = nodeRules[node].subnodeOwner(msg.sender);
        address resolver = nodeRules[node].profileResolver(node, label, msg.sender);
        require(resolver != address(0x0), "Resolver must be set by project");

        emit SubnodeRegistered(node, hashedLabel, owner, msg.sender);
        ens.setSubnodeRecord(node, hashedLabel, owner, resolver, 86400);
    }

    /// @notice Check if a label is valid for a project
    /// @param node The project node
    /// @param label The subdomain label to validate
    /// @return bool True if the label is valid, according to the project rules, false otherwise
    function valid(bytes32 node, string memory label) public view returns (bool) {
        return nodeRules[node].isLabelValid(node, label);
    }

    function available(bytes32 node, string memory label) internal view returns (bool) {
        bytes32 fullNode = Utilities.namehash(node, Utilities.labelhash(label));
        return ens.owner(fullNode) == address(0x0);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;

/// @title Utilities
/// @author charchar.eth
/// @notice Central location for shared functions in me3
library Utilities {
    /// @notice Hash a label for ENS use
    /// @param label The 'oops' in 'oops.bob.eth', or the 'bob' in 'bob.eth'
    /// @return Hashed label
    function labelhash(string memory label) internal pure returns (bytes32) {
        return keccak256(bytes(label));
    }

    /// @notice Create a namehash, the combination of a namehashed node and a hashed label
    /// @param node Fully qualified, namehashed ENS name ('bob.eth')
    /// @param label The 'oops' in 'oops.bob.eth', or the 'bob' in 'bob.eth'
    /// @return Hashed ENS name
    function namehash(bytes32 node, bytes32 label) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(node, label));
    }
}