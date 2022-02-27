//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {CoreMembershipProxy} from "./CoreMembershipProxy.sol";
import {CoreCollectionProxy} from "./CoreCollectionProxy.sol";
import "./CoreTierStorage.sol";

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
    address public immutable chestr;

    // project id => project
    mapping(uint256 => Project) public projects;

    // project creator => project ids
    mapping(address => uint256[]) public projectIds;

    // collection id => collection address
    mapping(uint256 => address) public collections;

    constructor(
        address _membership,
        address _collection,
        address _chestr
    ) {
        membership = _membership;
        collection = _collection;
        chestr = _chestr;
    }

    // ---------------- MODIFIER ----------------
    modifier onlyAvailableProject(uint256 _projectId) {
        require(
            projects[_projectId].creator == address(0),
            "CoreFactory: Unavailable project id"
        );
        _;
    }

    modifier onlyAvailableCollection(uint256 _collectionId) {
        require(
            collections[_collectionId] == address(0),
            "CoreFactory: Unavailable collection id"
        );
        _;
    }

    // ---------------- EXTERNAL ----------------
    function createProject(
        uint256 _projectId,
        address _collateral,
        Tier[] memory _tiers
    ) external onlyAvailableProject(_projectId) returns (address) {
        require(isValidTiers(_tiers), "CoreFactory: Invalid Tiers");

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

        ICoreMembership(coreMembership).createTeam(chestr, _collateral, _tiers);
        ICoreMembership(coreMembership).addMember(msg.sender, getFounderTier(_tiers));
        ICoreMembership(coreMembership).transferOwnership(msg.sender);

        return coreMembership;
    }

    function createCollection(
        string memory _collectionName,
        string memory _collectionSymbol,
        string memory _collectionURI,
        uint256 _maxSupply,
        uint256 _mintFee,
        uint256 _projectId,
        uint256 _collectionId,
        address _collateral
    ) external onlyAvailableCollection(_collectionId) returns (address) {
        require(projects[_projectId].creator != address(0), "CoreFactory: Invalid project id");

        address coreCollection = address(
            new CoreCollectionProxy{
                salt: keccak256(abi.encodePacked(_collectionId))
            }()
        );

        collections[_collectionId] = coreCollection;

        address coreMembership = projects[_projectId].membership;

        ICoreCollection(coreCollection).initialize(
            _collectionName,
            _collectionSymbol,
            _collectionURI,
            _maxSupply,
            _mintFee,
            _collateral,
            coreMembership
        );

        ICoreMembership(coreMembership).addCollection(coreCollection);

        return coreCollection;
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

    function isValidTiers(Tier[] memory _tiers) public pure returns (bool) {
        if (_tiers.length == 0) return false;

        uint256 founders = 0;
        for (uint256 i = 0; i < _tiers.length; i++) {
            if (_tiers[i].isFounder) {
                founders++;
            }
        }

        return founders == 1;
    }

    function getFounderTier(Tier[] memory _tiers) public pure returns (uint256) {
        for (uint256 i = 0; i < _tiers.length; i++) {
            if (_tiers[i].isFounder) {
                return i;
            }
        }

        return 0;
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

    fallback() external {
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

    fallback() external {
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

struct Tier {
    bool isForSale; // for sale
    bool isFounder; // great role person
    uint256 size; // size
    uint256 fee; // mint fee
    uint256 freeMints; // available free mints
    string uri; // membership nft uri
}

contract CoreTierStorage {}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../contracts/CoreTierStorage.sol";

interface ICoreMembership {
    function transferOwnership(address) external;

    function addCollection(address) external;

    function addMember(address, uint256) external returns (uint256);

    function createTeam(
        address,
        address,
        Tier[] memory
    ) external;

    function decreaseUserAvailableMints(address) external returns (bool);

    function getTiers() external view returns (Tier[] memory);

    function isProducer(address) external view returns (bool);

    function getUserAvailableMints(address) external view returns (uint256);

    function reservedMints() external view returns (uint256);
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
    function chestr() external view returns (address);
}