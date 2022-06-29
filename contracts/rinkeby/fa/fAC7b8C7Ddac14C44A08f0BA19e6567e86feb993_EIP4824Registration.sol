// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title EIP-4824 DAOs
/// @dev See <https://eips.ethereum.org/EIPS/eip-4824>
interface EIP4824 {
    /// @notice A distinct Uniform Resource Identifier (URI) pointing to a JSON object following the "EIP-4824 DAO JSON-LD Schema". This JSON file splits into four URIs: membersURI, proposalsURI, activityLogURI, and governanceURI. The membersURI should point to a JSON file that conforms to the "EIP-4824 Members JSON-LD Schema". The proposalsURI should point to a JSON file that conforms to the "EIP-4824 Proposals JSON-LD Schema". The activityLogURI should point to a JSON file that conforms to the "EIP-4824 Activity Log JSON-LD Schema". The governanceURI should point to a flatfile, normatively a .md file. Each of the JSON files named above can be statically-hosted or dynamically-generated.
    function daoURI() external view returns (string memory _daoURI);
}

error NotOwner();
error AlreadyInitialized();

contract EIP4824Registration is EIP4824 {
    string private _daoURI;
    address daoAddress;

    event NewURI(string daoURI);

    constructor() {
        daoAddress = address(0xdead);
    }

    function initialize(address _daoAddress, string memory daoURI_) external {
        if (daoAddress != address(0)) revert AlreadyInitialized();
        daoAddress = _daoAddress;
        _daoURI = daoURI_;
    }

    function setURI(string memory daoURI_) external {
        if (msg.sender != daoAddress) revert NotOwner();
        _daoURI = daoURI_;
        emit NewURI(daoURI_);
    }

    function daoURI() external view returns (string memory daoURI_) {
        return _daoURI;
    }
}

contract CloneFactory {
    // implementation of eip-1167 - see https://eips.ethereum.org/EIPS/eip-1167
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }
}

contract EIP4824RegistrationFactory is CloneFactory {
    event NewRegistration(
        address indexed daoAddress,
        string daoURI,
        address registration
    );

    address public template; /*Template contract to clone*/

    constructor(address _template) public {
        template = _template;
    }

    function summonRegistration(string calldata daoURI_) external {
        EIP4824Registration reg = EIP4824Registration(createClone(template)); /*Create a new clone of the template*/
        reg.initialize(msg.sender, daoURI_);
        emit NewRegistration(msg.sender, daoURI_, address(reg));
    }
}