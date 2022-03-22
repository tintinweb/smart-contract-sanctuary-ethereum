// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./libraries/Authorizable.sol";
import "./interfaces/IDeploymentValidator.sol";

contract DeploymentValidator is IDeploymentValidator, Authorizable {
    // a mapping of wrapped position contracts deployed by Element
    mapping(address => bool) public wrappedPositions;
    // a mapping of pool contracts deployed by Element
    mapping(address => bool) public pools;
    // a mapping of wrapped position + pool pairs that are deployed by Element
    // we keccak256 hash these tuples together to serve as the mapping keys
    mapping(bytes32 => bool) public pairs;

    /// @notice Constructs this contract and stores needed data
    /// @param _owner The contract owner authorized to validate addresses
    constructor(address _owner) {
        // authorize the owner address to be able to execute the validations
        _authorize(_owner);
    }

    /// @notice adds a wrapped position address to the mapping
    /// @param wrappedPosition The wrapped position contract address
    function validateWPAddress(address wrappedPosition)
        public
        override
        onlyAuthorized
    {
        // add address to mapping to indicating it was deployed by Element
        wrappedPositions[wrappedPosition] = true;
    }

    /// @notice adds a wrapped position address to the mapping
    /// @param pool the pool contract address
    function validatePoolAddress(address pool) public override onlyAuthorized {
        // add address to mapping to indicating it was deployed by Element
        pools[pool] = true;
    }

    /// @notice adds a wrapped position + pool pair of addresses to mapping
    /// @param wrappedPosition the wrapped position contract address
    /// @param pool the pool contract address
    function validateAddresses(address wrappedPosition, address pool)
        external
        override
        onlyAuthorized
    {
        // add to pool validation mapping
        validatePoolAddress(pool);
        // add to wp validation mapping
        validateWPAddress(wrappedPosition);
        // hash together the contract addresses
        bytes32 data = keccak256(abi.encodePacked(wrappedPosition, pool));
        // add the hashed pair into the mapping
        pairs[data] = true;
    }

    /// @notice checks to see if the address has been validated
    /// @param wrappedPosition the address to check
    /// @return true if validated, false if not
    function checkWPValidation(address wrappedPosition)
        external
        view
        override
        returns (bool)
    {
        return wrappedPositions[wrappedPosition];
    }

    /// @notice checks to see if the address has been validated
    /// @param pool the address to check
    /// @return true if validated, false if not
    function checkPoolValidation(address pool)
        external
        view
        override
        returns (bool)
    {
        return pools[pool];
    }

    /// @notice checks to see if the pair of addresses have been validated
    /// @param wrappedPosition the wrapped position address to check
    /// @param pool the pool address to check
    /// @return true if validated, false if not
    function checkPairValidation(address wrappedPosition, address pool)
        external
        view
        override
        returns (bool)
    {
        bytes32 data = keccak256(abi.encodePacked(wrappedPosition, pool));
        return pairs[data];
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0;

contract Authorizable {
    // This contract allows a flexible authorization scheme

    // The owner who can change authorization status
    address public owner;
    // A mapping from an address to its authorization status
    mapping(address => bool) public authorized;

    /// @dev We set the deployer to the owner
    constructor() {
        owner = msg.sender;
    }

    /// @dev This modifier checks if the msg.sender is the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not owner");
        _;
    }

    /// @dev This modifier checks if an address is authorized
    modifier onlyAuthorized() {
        require(isAuthorized(msg.sender), "Sender not Authorized");
        _;
    }

    /// @dev Returns true if an address is authorized
    /// @param who the address to check
    /// @return true if authorized false if not
    function isAuthorized(address who) public view returns (bool) {
        return authorized[who];
    }

    /// @dev Privileged function authorize an address
    /// @param who the address to authorize
    function authorize(address who) external onlyOwner {
        _authorize(who);
    }

    /// @dev Privileged function to de authorize an address
    /// @param who The address to remove authorization from
    function deauthorize(address who) external onlyOwner {
        authorized[who] = false;
    }

    /// @dev Function to change owner
    /// @param who The new owner address
    function setOwner(address who) public onlyOwner {
        owner = who;
    }

    /// @dev Inheritable function which authorizes someone
    /// @param who the address to authorize
    function _authorize(address who) internal {
        authorized[who] = true;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IDeploymentValidator {
    function validateWPAddress(address wrappedPosition) external;

    function validatePoolAddress(address pool) external;

    function validateAddresses(address wrappedPosition, address pool) external;

    function checkWPValidation(address wrappedPosition)
        external
        view
        returns (bool);

    function checkPoolValidation(address pool) external view returns (bool);

    function checkPairValidation(address wrappedPosition, address pool)
        external
        view
        returns (bool);
}