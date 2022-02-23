//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {CoreMembershipProxy} from "./CoreMembershipProxy.sol";
import {CoreCollectionProxy} from "./CoreCollectionProxy.sol";

import {ICoreMembership} from "../interfaces/ICoreMembership.sol";
import {ICoreCollection} from "../interfaces/ICoreCollection.sol";

contract CoreFactory {
    struct Project {
        uint256 id;
        address creator;
        address membership;
    }

    event NewProject(uint256 id, address creator);

    address public immutable membership;
    address public immutable collection;

    // project id => project
    mapping(uint256 => Project) public projects;

    // project creator => project ids
    mapping(address => uint256[]) public projectIds;

    // project id => collection
    mapping(uint256 => address[]) public collections;

    constructor(address _membership, address _collection) {
        membership = _membership;
        collection = _collection;
    }

    // ---------------- MODIFIER ----------------
    modifier onlyAvailable(uint256 _projectId) {
        require(
            projects[_projectId].creator == address(0),
            "CoreFactory: Unavailable project id"
        );
        _;
    }

    // ---------------- EXTERNAL ----------------
    function createProject(uint256 _projectId)
        external
        onlyAvailable(_projectId)
        returns (address)
    {
        address coreMembership = address(
            new CoreMembershipProxy{
                salt: keccak256(abi.encodePacked(_projectId))
            }()
        );

        Project memory project;
        project.id = _projectId;
        project.creator = msg.sender;
        project.membership = coreMembership;

        projects[_projectId] = project;
        projectIds[msg.sender].push(_projectId);

        return coreMembership;
    }

    function createCollection(
        string memory _collectionName,
        string memory _collectionSymbol,
        string memory _collectionURI,
        uint256 _maxSupply,
        uint256 _mintFee,
        uint256 _projectId,
        address _collateral
    ) external onlyAvailable(_projectId) returns (address) {
        address coreCollection = address(
            new CoreCollectionProxy{
                salt: keccak256(abi.encodePacked(_projectId))
            }()
        );

        ICoreCollection(coreCollection).initialize(
            _collectionName,
            _collectionSymbol,
            _collectionURI,
            _maxSupply,
            _mintFee,
            _collateral,
            projects[_projectId].membership
        );

        return coreCollection;
    }

    function createTeam(
        uint16 _producerAvailableMints,
        uint16 _collaboratorAvailableMints,
        uint16 _producers,
        uint256 _collaborators,
        uint256 _mintFee,
        uint256 _projectId,
        address _collateral
    ) external onlyAvailable(_projectId) {
        address coreMembership = projects[_projectId].membership;

        ICoreMembership(coreMembership).organizeTeam(
            _producerAvailableMints,
            _collaboratorAvailableMints,
            _producers,
            _collaborators,
            _mintFee,
            _collateral
        );

        // Transfer membership ownership to project creator
        ICoreMembership(coreMembership).transferOwnership(msg.sender);
    }

    // ---------------- VIEW ----------------
    function getProject(uint256 _projectId)
        external
        view
        returns (Project memory)
    {
        return projects[_projectId];
    }

    function getProjectIds(address _creator)
        external
        view
        returns (uint256[] memory)
    {
        return projectIds[_creator];
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {ICoreFactory} from "../interfaces/ICoreFactory.sol";

contract CoreMembershipProxy {
    address private immutable _membership;

    constructor() {
        _membership = ICoreFactory(msg.sender).membership();
    }

    fallback() external payable {
        address _impl = membership();
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    function membership() public view returns (address) {
        return _membership;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {ICoreFactory} from "../interfaces/ICoreFactory.sol";

contract CoreCollectionProxy {
    address private immutable _collection;

    constructor() {
        _collection = ICoreFactory(msg.sender).collection();
    }

    fallback() external payable {
        address _impl = collection();
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    function collection() public view returns (address) {
        return _collection;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICoreMembership {
    function transferOwnership(address) external;

    function initialize(string memory, string memory) external;

    function setURI(string memory, string memory) external;

    function setCollection(address) external;

    function addProducer(address) external returns (uint256);

    function addCollaborator(address) external returns (uint256);

    function buyMembership() external returns (uint256);

    function organizeTeam(
        uint16,
        uint16,
        uint16,
        uint256,
        uint256,
        address
    ) external;

    function decreaseUserAvailableMints(address) external returns (bool);

    function isProducer(address) external view returns (bool);

    function isCollaborator(address) external view returns (bool);

    function getUserAvailableMints(address) external view returns (uint256);

    function producerAvailableMints() external view returns (uint16);

    function collaboratorAvailableMints() external view returns (uint16);

    function producers() external view returns (uint16);

    function collaborators() external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICoreCollection {
    function transferOwnership(address) external;

    function initialize(
        string memory,
        string memory,
        string memory,
        uint256,
        uint256,
        address,
        address
    ) external;

    function freeMint() external returns (uint256);

    function paidMint() external returns (uint256);

    function batchFreeMints(uint256) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICoreFactory {
    function membership() external view returns (address);
    function collection() external view returns (address);
}