/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @ensdomains/ens/contracts/ENS.sol

pragma solidity >=0.8.4;

interface ENS {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external returns (bytes32);

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address owner) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function setApprovalForAll(address operator, bool approved) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function ttl(bytes32 node) external view returns (uint64);

    function recordExists(bytes32 node) external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// File: contracts/SubClaim.sol





pragma solidity ^0.8.4;







contract SubClaim {

    address admin;

    mapping(address => uint8) public register_count;

    uint8 public count = 5;

    ENS public ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

    bytes32 public rootNode;

    address public resolver = 0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41;

    constructor() {

        admin = msg.sender;

    }

    modifier onlyOwner() {

        require(msg.sender == admin, "Unauthorized");

        _;

    }



    function register_subdomain() external returns (bool, uint8) {

        require(register_count[msg.sender] < 5, "Claim max amount reached");

        require(count < 1750, "Max whitelist");



        try ens.setSubnodeRecord(rootNode, keccak256(abi.encodePacked(Strings.toString(count))), msg.sender, resolver, 0) { 

            register_count[msg.sender] += 1;

            uint8 _count = count;

            count += 1;

            return (true, _count);

        } catch Error(string memory reason) { // catch failing revert() and require()

            revert(reason);

        } catch (bytes memory _reason) { // catch failing assert()

            revert(string(abi.encodePacked(_reason)));

        }

    }



    function change_admin(address _admin) public onlyOwner returns (bool) {

        admin = _admin;

        return true;

    }



    function set_root_node(bytes32 _rootNode) public onlyOwner returns (bool) {

        require(address(this) == ens.owner(_rootNode), "Unauthorized");

        rootNode = _rootNode;

        return true;

    }



    function admin_claim(uint8 _count, address _to) public onlyOwner returns (bool) {

        try ens.setSubnodeRecord(rootNode, keccak256(abi.encodePacked(Strings.toString(_count))), _to, resolver, 0) {

            register_count[_to] += 1;

            return true;

        } catch Error(string memory reason) { // catch failing revert() and require()

            revert(reason);

        } catch (bytes memory _reason) { // catch failing assert()

            revert(string(abi.encodePacked(_reason)));

        }

    }



}