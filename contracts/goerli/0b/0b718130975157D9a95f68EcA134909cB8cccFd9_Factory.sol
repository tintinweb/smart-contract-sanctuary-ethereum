pragma solidity 0.8.12;

/**
 * @title Factory
 * @author @InsureDAO
 * @notice This contract is the functory contract that manages functions related to pool creation activities.
 * SPDX-License-Identifier: GPL-3.0
 */

import "./interfaces/IOwnership.sol";
import "./interfaces/IUniversalPool.sol";
import "./interfaces/IRegistry.sol";
import "./interfaces/IFactory.sol";

contract Factory is IFactory {
    event PoolCreated(
        address indexed pool,
        address indexed template,
        string _metaData,
        uint256[] conditions,
        address[] references
    );
    event TemplateApproval(IUniversalPool indexed template, bool approval, bool isOpen, bool duplicate);
    event ReferenceApproval(IUniversalPool indexed template, uint256 indexed slot, address target, bool approval);
    event ConditionApproval(IUniversalPool indexed template, uint256 indexed slot, uint256 target);

    struct Template {
        bool approval; //true if the template exists
        bool isOpen; //true if the pool allows anyone to create a pool
        bool allowDuplicate; //true if the pool with same ID is allowed
    }
    mapping(address => Template) public templates;
    //mapping of authorized pool template address

    mapping(address => mapping(uint256 => mapping(address => bool))) public reflist;
    //Authorized reference(address) list for pool pool template
    //Each template has different set of references
    //true if that address is authorized within the template
    // Example reference list for pool template v1
    // references[0] = target governance token address
    // references[1] = underlying token address
    // references[2] = registry
    // references[3] = parameter

    mapping(address => mapping(uint256 => uint256)) public conditionlist;
    //Authorized condition(uint256) list for pool temaplate
    //Each template has different set of conditions
    //true if that address is authorized within the template
    // Example condition list for pool template v1
    // conditions[0] = minimim deposit amount

    address public immutable registry;
    IOwnership public immutable ownership;

    modifier onlyOwner() {
        require(ownership.owner() == msg.sender, "Caller is not allowed to operate");
        _;
    }

    constructor(address _registry, address _ownership) {
        require(_registry != address(0), "ERROR: ZERO_ADDRESS");
        require(_ownership != address(0), "ERROR: ZERO_ADDRESS");

        registry = _registry;
        ownership = IOwnership(_ownership);
    }

    /**
     * @notice A function to approve or disapprove templates.
     * Only owner of the contract can operate.
     * @param _template template address, which must be registered
     * @param _approval true if a pool is allowed to create based on the template
     * @param _isOpen true if anyone can create a pool based on the template
     * @param _duplicate true if a pool with duplicate target id is allowed
     */
    function approveTemplate(IUniversalPool _template, bool _approval, bool _isOpen, bool _duplicate)
        external
        onlyOwner
    {
        require(address(_template) != address(0), "ERROR_ZERO_ADDRESS");
        Template memory approvedTemplate = Template(_approval, _isOpen, _duplicate);
        templates[address(_template)] = approvedTemplate;
        emit TemplateApproval(_template, _approval, _isOpen, _duplicate);
    }

    /**
     * @notice A function to preset reference.
     * Only owner of the contract can operate.
     * @param _template template address, which must be registered
     * @param _slot the index within reference array
     * @param _target the reference  address
     * @param _approval true if the reference is approved
     */
    function approveReference(IUniversalPool _template, uint256 _slot, address _target, bool _approval)
        external
        onlyOwner
    {
        require(templates[address(_template)].approval, "ERROR: UNAUTHORIZED_TEMPLATE");
        reflist[address(_template)][_slot][_target] = _approval;
        emit ReferenceApproval(_template, _slot, _target, _approval);
    }

    /**
     * @notice A function to preset reference.
     * Only owner of the contract can operate.
     * @param _template template address, which must be registered
     * @param _slot the index within condition array
     * @param _target the condition uint
     */
    function setCondition(IUniversalPool _template, uint256 _slot, uint256 _target) external onlyOwner {
        require(templates[address(_template)].approval, "ERROR: UNAUTHORIZED_TEMPLATE");
        conditionlist[address(_template)][_slot] = _target;
        emit ConditionApproval(_template, _slot, _target);
    }

    /**
     * @notice A function to create pools.
     * This function is pool model agnostic.
     * @param _template template address, which must be registered
     * @param _metaData arbitrary string to store pool information
     * @param _conditions array of conditions
     * @param _references array of references
     * @return . created pool address
     */
    function createPool(
        IUniversalPool _template,
        string calldata _metaData,
        uint256[] memory _conditions,
        address[] calldata _references
    ) external returns (address) {
        //check eligibility
        require(templates[address(_template)].approval, "ERROR: UNAUTHORIZED_TEMPLATE");
        if (!templates[address(_template)].isOpen) {
            require(ownership.owner() == msg.sender, "ERROR: UNAUTHORIZED_SENDER");
        }

        uint256 refLength = _references.length;
        for (uint256 i; i < refLength; ) {
            require(
                reflist[address(_template)][i][_references[i]] || reflist[address(_template)][i][address(0)],
                "ERROR: UNAUTHORIZED_REFERENCE"
            );
            unchecked {
                ++i;
            }
        }

        uint256 conLength = _conditions.length;
        for (uint256 i; i < conLength; ) {
            if (conditionlist[address(_template)][i] != 0) {
                _conditions[i] = conditionlist[address(_template)][i];
            }
            unchecked {
                ++i;
            }
        }

        address _registry = registry;
        if (!IRegistry(_registry).confirmExistence(address(_template), _references[0])) {
            IRegistry(_registry).setExistence(address(_template), _references[0]);
        } else if (!templates[address(_template)].allowDuplicate) {
            revert("ERROR: DUPLICATE_POOL");
        }

        //create pool
        IUniversalPool pool = IUniversalPool(_createClone(address(_template)));

        IRegistry(_registry).addPool(address(pool));

        //initialize
        pool.initialize(msg.sender, _metaData, _conditions, _references);

        emit PoolCreated(address(pool), address(_template), _metaData, _conditions, _references);

        return address(pool);
    }

    /**
     * @notice Template Code for the create clone method:
     * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1167.md
     */
    function _createClone(address target) internal returns (address result) {
        //convert address to bytes20 for assembly use
        bytes20 targetBytes = bytes20(target);

        assembly {
            // allocate clone memory
            let clone := mload(0x40)
            // store initial portion of the delegation contract code in bytes form
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            // store the provided address
            mstore(add(clone, 0x14), targetBytes)
            // store the remaining delegation contract code
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            // create the actual delegate contract reference and return its address
            result := create(0, clone, 0x37)
        }

        require(result != address(0), "ERROR: ZERO_ADDRESS");
    }
}

pragma solidity 0.8.12;

interface IRegistry {
    function isListed(address _market) external view returns (bool);

    function getReserve(address _address) external view returns (address);

    function confirmExistence(address _template, address _target) external view returns (bool);

    //onlyOwner
    function setFactory(address _factory) external;

    function addPool(address _market) external;

    function setExistence(address _template, address _target) external;

    function setReserve(address _address, address _reserve) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./IUniversalPool.sol";

interface IFactory {
    function approveTemplate(IUniversalPool _template, bool _approval, bool _isOpen, bool _duplicate) external;

    function approveReference(IUniversalPool _template, uint256 _slot, address _target, bool _approval) external;

    function setCondition(IUniversalPool _template, uint256 _slot, uint256 _target) external;

    function createPool(
        IUniversalPool _template,
        string memory _metaData,
        uint256[] memory _conditions,
        address[] memory _references
    ) external returns (address);
}

pragma solidity 0.8.12;

interface IUniversalPool {
    function initialize(
        address _depositor,
        string calldata _metaData,
        uint256[] calldata _conditions,
        address[] calldata _references
    ) external;

    //onlyOwner
    function setPaused(bool state) external;

    function changeMetadata(string calldata _metadata) external;
}

pragma solidity 0.8.12;

//SPDX-License-Identifier: MIT

interface IOwnership {
    function owner() external view returns (address);

    function futureOwner() external view returns (address);

    function commitTransferOwnership(address newOwner) external;

    function acceptTransferOwnership() external;
}