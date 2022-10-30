// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Ownable.sol";
import "./interfaces/IEthListNode.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract EthListDAO is Ownable {
    event GeoNodeAdded(
        address indexed node,
        string name,
        string tag,
        string childrenTag
    );

    address public nodeTemplate;
    string[] public allGeoNames;
    mapping(string => address) public getGeoNode;

    constructor(address nodeTemplate_, address owner_) {
        nodeTemplate = nodeTemplate_;
        owner = owner_;
    }

    function addGeoNode(string memory name, string memory childrenTag)
        external
        onlyOwner
        returns (address)
    {
        require(getGeoNode[name] == address(0), "node exists");
        address geoNode = Clones.clone(nodeTemplate);
        IEthListNode(geoNode).initialize(
            address(this),
            address(this),
            nodeTemplate,
            name,
            "GEO",
            childrenTag
        );
        getGeoNode[name] = geoNode;
        allGeoNames.push(name);
        emit GeoNodeAdded(geoNode, name, "GEO", childrenTag);
        return geoNode;
    }

    function addSubNode(
        address parentNode,
        string memory nodeName,
        string memory nodeChildrenTag
    ) external onlyOwner {
        IEthListNode parent = IEthListNode(parentNode);
        require(parent.dao() == address(this), "invalid dao");
        parent.addChild(nodeName, nodeChildrenTag);
    }

    function addSubNodes(
        address parentNode,
        string[] memory nodeNames,
        string memory nodeChildrenTag
    ) external onlyOwner {
        IEthListNode parent = IEthListNode(parentNode);
        require(parent.dao() == address(this), "invalid dao");
        parent.addChildren(nodeNames, nodeChildrenTag);
    }

    function setOfferList(address leafNode, address offerList)
        external
        onlyOwner
    {
        IEthListNode leaf = IEthListNode(leafNode);
        require(leaf.dao() == address(this), "invalid dao");
        leaf.setOfferList(offerList);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Ownable {
    event NewOwner(address indexed oldOwner, address indexed newOwner);
    event NewPendingOwner(
        address indexed oldPendingOwner,
        address indexed newPendingOwner
    );

    address public owner;
    address public pendingOwner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: REQUIRE_OWNER");
        _;
    }

    function setPendingOwner(address newPendingOwner) external onlyOwner {
        require(pendingOwner != newPendingOwner, "Ownable: ALREADY_SET");
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner, "Ownable: REQUIRE_PENDING_OWNER");
        address oldOwner = owner;
        address oldPendingOwner = pendingOwner;
        owner = pendingOwner;
        pendingOwner = address(0);
        emit NewOwner(oldOwner, owner);
        emit NewPendingOwner(oldPendingOwner, pendingOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEthListNode {
    event ChildAdded(
        address indexed child,
        address indexed parent,
        string name,
        string childrenTag,
        string grandchildrenTag,
        uint256 id
    );
    event OfferListChanged(
        address indexed oldOfferList,
        address indexed newOfferList
    );

    function dao() external view returns (address);

    function parent() external view returns (address);

    function template() external view returns (address);

    function offerList() external view returns (address);

    function isLeaf() external view returns (bool);

    function name() external view returns (string memory);

    function currentTag() external view returns (string memory);

    function childrenTag() external view returns (string memory);

    function getChild(string memory) external view returns (address);

    function allChildrenNames(uint256 index)
        external
        view
        returns (string memory);

    function initialize(
        address dao_,
        address parent_,
        address template_,
        string memory name_,
        string memory currentTag_,
        string memory childrenTag_
    ) external;

    function addChild(string memory childName, string memory grandchildrenTag)
        external
        returns (address);

    function addChildren(
        string[] memory childrenNames,
        string memory grandchildrenTag
    ) external returns (address[] memory);

    function setOfferList(address offerList_) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}