//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IENS.sol";
import "./IResolver.sol";
import "./IERC721.sol";
import "./ERC721.sol";

/**
 * A registrar that allocates subdomains reserved subdomains to authorized NFT holders
 */
contract AllFrensRegistrar is ERC721 {
    /* STORAGE */
    address registrarController;
    address feeRecipient;
    address ens = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
    address publicResolver = 0x4B1488B7a6B320d2D721406204aBc3eeAa9AD329;
    uint256 FEE = 0.05 ether;
    mapping(address => bytes32) public rootNodeForCollection;
    mapping(address => mapping(uint256 => bytes32)) public nodehashForNFT;
    mapping(uint256 => bytes32) labelForId;
    mapping(uint256 => bytes32) rootNodeForId;
    bool public enabled = false;

    modifier hodler(address collection, uint256 id) {
        require(IERC721(collection).ownerOf(id) == msg.sender, "Not NFT Owner");
        _;
    }

    modifier controllerOnly() {
        require(msg.sender == registrarController);
        _;
    }

    constructor() ERC721("allfrENS", "frENS") {
        registrarController = msg.sender;
    }

    function transferFrom(address from, address to, uint256 id) public override {
        super.transferFrom(from, to, id);
        // take temporary ownership in order to set resolver addr
        IENS(ens).setSubnodeOwner(rootNodeForId[id], labelForId[id], address(this));
        IResolver(publicResolver).setAddr(bytes32(id), to);
        IENS(ens).setSubnodeOwner(rootNodeForId[id], labelForId[id], to);
    }

    function safeTransferFrom(address from, address to, uint256 id) public override {
        super.safeTransferFrom(from, to, id);
        // take temporary ownership in order to set resolver addr
        IENS(ens).setSubnodeOwner(rootNodeForId[id], labelForId[id], address(this));
        IResolver(publicResolver).setAddr(bytes32(id), to);
        IENS(ens).setSubnodeOwner(rootNodeForId[id], labelForId[id], to);
    }

    function setRootNodeForCollection(address collection, bytes32 rootNode) controllerOnly external {
        rootNodeForCollection[collection] = rootNode;
    }

    function setEnabled(bool _enabled) controllerOnly external {
        enabled = _enabled;
    }

    function setFee(uint256 _fee) controllerOnly external {
        FEE = _fee;
    }

    function chargeFee() internal {
        require(msg.value >= FEE, "FEE NOT PAID");
        if (msg.value > FEE) {
            payable(msg.sender).transfer(msg.value - FEE);
        }
        payable(feeRecipient).transfer(FEE);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /**
     * Register a name, or reclaim an existing registration.
     */
    function register(bytes32 label, address collection, uint256 id) payable public hodler(collection, id) {
        require(enabled, "DISABLED");

        // delete current record if it exists
        bytes32 currentNode = nodehashForNFT[collection][id];
        if (currentNode != bytes32(0)) {
            IENS(ens).setSubnodeRecord(rootNodeForId[uint256(currentNode)], labelForId[uint256(currentNode)], address(0), address(0), 0);
        }

        // get rootNode that was set up for collection
        bytes32 rootNode = rootNodeForCollection[collection];
        require(rootNode != bytes32(0), "NO ROOT NODE");

        // calculate nodehash
        bytes32 nodehash = keccak256(abi.encodePacked(rootNode, label));

        // check name is available
        require(!IENS(ens).recordExists(nodehash), "TAKEN");

        chargeFee();

        // store state (maybe should be a struct?)
        nodehashForNFT[collection][id] = nodehash;
        labelForId[uint256(nodehash)] = label;
        rootNodeForId[uint256(nodehash)] = rootNode;

        // issue subdomain
        IENS(ens).setSubnodeRecord(rootNode, label, address(this), publicResolver, 5);
        string memory avatarStr = string(abi.encodePacked("eip155:1/erc721:0x", toAsciiString(collection), "/", uint2str(id)));
        IResolver(publicResolver).setAddr(nodehash, msg.sender);
        IResolver(publicResolver).setText(nodehash, "avatar", avatarStr);
        IENS(ens).setSubnodeOwner(rootNode, label, msg.sender);
        _mint(msg.sender, uint256(nodehash));
    }

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IENS {
    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function setApprovalForAll(address operator, bool approved) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
    function recordExists(bytes32 node) external view returns (bool);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IResolver {
    function setABI(bytes32 node, uint256 contentType, bytes calldata data) external;
    function setAddr(bytes32 node, address addr) external;
    function setAddr(bytes32 node, uint coinType, bytes calldata a) external;
    function setContenthash(bytes32 node, bytes calldata hash) external;
    function setDnsrr(bytes32 node, bytes calldata data) external;
    function setName(bytes32 node, string calldata _name) external;
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external;
    function setText(bytes32 node, string calldata key, string calldata value) external;
    function setInterface(bytes32 node, bytes4 interfaceID, address implementer) external;
    function multicall(bytes[] calldata data) external returns(bytes[] memory results);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd;
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}