//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >=0.8.4;

interface iOverloadResolver {
    function addr(bytes32 node, uint256 coinType) external view returns (bytes memory);
}

interface iResolver {
    function contenthash(bytes32 node) external view returns (bytes memory);
    function addr(bytes32 node) external view returns (address payable);
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);
    function text(bytes32 node, string calldata key) external view returns (string memory);
    function name(bytes32 node) external view returns (string memory);
}

/*
interface iCCIP {
    function resolve(bytes memory name, bytes memory data) external view returns (bytes memory);
}
*/

interface iERC20 {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

interface iENS {
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);
    event Transfer(bytes32 indexed node, address owner);
    event NewResolver(bytes32 indexed node, address resolver);
    event NewTTL(bytes32 indexed node, uint64 ttl);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns (bytes32);
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

interface iERC2981 {
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

interface iERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface iERC173 {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);
    function transferOwnership(address _newOwner) external;
}

interface iERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface iERC721Receiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data)
        external
        returns (bytes4);
}

interface iERC721Metadata {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface iENSCAT {
    function totalSupply() external view returns (uint256);
    function Dev() external view returns (address);
    function Namehash2ID(bytes32 node) external view returns (uint256);
    function ID2Label(uint256 id) external view returns (string calldata);
    function ownerOf(uint256 id) external view returns (address);
}

interface iToken {
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
}

//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >0.8.0 <0.9.0;

import "src/Interface.sol";
import "src/Util.sol";

/**
 * @dev : ENSCAT Resolver Base
 */
 
abstract contract ResolverBase {
    /// @dev : Modifier to allow only dev
    modifier onlyDev() {
        if (msg.sender != ENSCAT.Dev()) {
            revert OnlyDev(ENSCAT.Dev(), msg.sender);
        }
        _;
    }

    /// @dev : ENS Contract Interface
    iENS public ENS;

    /// @dev : ENSCAT Contract Interface
    iENSCAT public ENSCAT;

    mapping(bytes4 => bool) public supportsInterface;

    modifier isValidToken(uint256 id) {
        if (id >= ENSCAT.totalSupply()) {
            revert InvalidTokenID(id);
        }
        _;
    }

    /**
     * @dev : setInterface
     * @param sig : signature
     * @param value : boolean
     */
    function setInterface(bytes4 sig, bool value) external payable onlyDev {
        require(sig != 0xffffffff, "INVALID_INTERFACE_SELECTOR");
        supportsInterface[sig] = value;
    }

    /**
     * @dev : withdraw ether only to Dev (or multi-sig)
     */
    function withdrawEther() external payable {
        (bool ok,) = ENSCAT.Dev().call{value: address(this).balance}("");
        require(ok, "ETH_TRANSFER_FAILED");
    }

    /**
     * @dev : to be used in case some tokens get locked in the contract
     * @param token : token to release
     * @param bal : token balance to withdraw
     */
    function withdrawToken(address token, uint256 bal) external payable {
        iERC20(token).transferFrom(address(this), ENSCAT.Dev(), bal);
    }

    // @dev : Revert on fallback
    fallback() external payable {
        revert();
    }

    /// @dev : Revert on receive
    receive() external payable {
        revert();
    }

    error Unauthorized(address operator, address owner, uint256 id);
    error NotSubdomainOwner(address owner, address from, uint256 id);
    error OnlyDev(address _dev, address _you);
    error InvalidTokenID(uint256 id);
}

/**
 * @title ENSCAT Resolver
 */

contract Resolver is ResolverBase {
    using Util for uint256;
    using Util for bytes;

    /// @notice : encoder: https://gist.github.com/sshmatrix/6ed02d73e439a5773c5a2aa7bd0f90f9
    /// @dev : default contenthash (encoded from IPNS hash)
    //  IPNS : k51qzi5uqu5dkco782zzu13xwmoz6yijezzk326uo0097cr8tits04eryrf5n3
    function DefaultContenthash() external view returns (bytes memory) {
        return _contenthash[bytes32(0)];
    }

    constructor(address _enscat) {
        ENSCAT = iENSCAT(_enscat);
        ENS = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        supportsInterface[iResolver.addr.selector] = true;
        supportsInterface[iResolver.contenthash.selector] = true;
        supportsInterface[iResolver.pubkey.selector] = true;
        supportsInterface[iResolver.text.selector] = true;
        supportsInterface[iResolver.name.selector] = true;
        supportsInterface[iOverloadResolver.addr.selector] = true;

        _contenthash[bytes32(0)] =
            hex"e5010172002408011220a7448dcfc00e746c22e238de5c1e3b6fb97bae0949e47741b4e0ae8e929abd4f";
    }

    /**
     * @dev : sets default contenthash
     * @param _content : default contenthash to set
     */
    function setDefaultContenthash(bytes memory _content) external onlyDev {
        _contenthash[bytes32(0)] = _content;
    }

    /**
     * @dev : verify ownership of subdomain
     * @param node : subdomain
     */
    modifier onlyOwner(bytes32 node) {
        require(msg.sender == ENS.owner(node), "Resolver: NOT_AUTHORISED");
        _;
    }

    mapping(bytes32 => bytes) internal _contenthash;

    /**
     * @dev : return default contenhash if no contenthash set
     * @param node : subdomain
     */
    function contenthash(bytes32 node) public view returns (bytes memory _hash) {
        _hash = _contenthash[node];
        if (_hash.length == 0) {
            _hash = _contenthash[bytes32(0)];
        }
    }

    event ContenthashChanged(bytes32 indexed node, bytes _contenthash);

    /**
     * @dev : change contenthash of subdomain
     * @param node: subdomain
     * @param _hash: new contenthash
     */
    function setContenthash(bytes32 node, bytes memory _hash) external onlyOwner(node) {
        _contenthash[node] = _hash;
        emit ContenthashChanged(node, _hash);
    }

    mapping(bytes32 => mapping(uint256 => bytes)) internal _addrs;

    event AddressChanged(bytes32 indexed node, address addr);

    /**
     * @dev : change address of subdomain
     * @param node : subdomain
     * @param _addr : new address
     */
    function setAddress(bytes32 node, address _addr) external onlyOwner(node) {
        _addrs[node][60] = abi.encodePacked(_addr);
        emit AddressChanged(node, _addr);
    }

    event AddressChangedForCoin(bytes32 indexed node, uint256 coinType, bytes newAddress);

    /**
     * @dev : change address of subdomain for <coin>
     * @param node : subdomain
     * @param coinType : <coin>
     */
    function setAddress(bytes32 node, uint256 coinType, bytes memory _addr) external onlyOwner(node) {
        _addrs[node][coinType] = _addr;
        emit AddressChangedForCoin(node, coinType, _addr);
    }

    /**
     * @dev : default subdomain to owner if no address is set for Ethereum [60]
     * @param node : subdomain
     * @return : resolved address
     */
    function addr(bytes32 node) external view returns (address payable) {
        bytes memory _addr = _addrs[node][60];
        if (_addr.length == 0) {
            return payable(ENS.owner(node));
        }
        return payable(address(uint160(uint256(bytes32(_addr)))));
    }

    /**
     * @dev : resolve subdomain addresses for <coin>; if no ethereum address [60] is set, resolve to owner
     * @param node : subdomain
     * @param coinType : <coin>
     * @return _addr : resolved address
     */
    function addr(bytes32 node, uint256 coinType) external view returns (bytes memory _addr) {
        _addr = _addrs[node][coinType];
        if (_addr.length == 0 && coinType == 60) {
            _addr = abi.encodePacked(ENS.owner(node));
        }
    }

    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    mapping(bytes32 => PublicKey) public pubkey;

    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);

    /**
     * @dev : change public key record
     * @param node : subdomain
     * @param x : x-coordinate on elliptic curve
     * @param y : y-coordinate on elliptic curve
     */
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external onlyOwner(node) {
        pubkey[node] = PublicKey(x, y);
        emit PubkeyChanged(node, x, y);
    }

    mapping(bytes32 => mapping(string => string)) internal _text;

    event TextRecordChanged(bytes32 indexed node, string indexed key, string value);

    /**
     * @dev : change text record
     * @param node : subdomain
     * @param key : key to change
     * @param value : value to set
     */
    function setText(bytes32 node, string calldata key, string calldata value) external onlyOwner(node) {
        _text[node][key] = value;
        emit TextRecordChanged(node, key, value);
    }

    /**
     * @dev : set default text record <onlyDev>
     * @param key : key to change
     * @param value : value to set
     */
    function setDefaultText(string calldata key, string calldata value) external onlyDev {
        _text[bytes32(0)][key] = value;
        emit TextRecordChanged(bytes32(0), key, value);
    }

    /**
     * @dev : get text records
     * @param node : subdomain
     * @param key : key to query
     * @return value : value
     */
    function text(bytes32 node, string calldata key) external view returns (string memory value) {
        value = _text[node][key];
        if (bytes(value).length == 0) {
            if (bytes32(bytes(key)) == bytes32(bytes("avatar"))) {
                return string.concat(
                    "eip155:",
                    block.chainid.toString(),
                    "/erc721:",
                    abi.encodePacked(address(ENSCAT)).toHexString(),
                    "/",
                    ENSCAT.Namehash2ID(node).toString()
                );
            } else {
                return _text[bytes32(0)][key];
            }
        }
    }

    event NameChanged(bytes32 indexed node, string name);

    /**
     * @dev : change name record
     * @param node : subdomain
     * @param _name : new name
     */
    function setName(bytes32 node, string calldata _name) external onlyOwner(node) {
        _text[node]["name"] = _name;
        emit NameChanged(node, _name);
    }

    /**
     * @dev : get default name at mint
     * @param node : subdomain
     * @return _name : default name
     */
    function name(bytes32 node) external view returns (string memory _name) {
        _name = _text[node]["name"];
        if (bytes(_name).length == 0) {
            return string.concat(ENSCAT.Namehash2ID(node).toString(), ".100kcat.eth");
        }
    }
}

//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >0.8.0 <0.9.0;

// Utility functions
library Util {
    /**
     * @dev Check if string is purely numeric
     * @param str : string
     * @return : bool
     */
    function isNumeric(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if(b.length > 13) return false;
        for(uint i; i < b.length;){
            bytes1 char = b[i];
            if(
                !(char >= 0x30 && char <= 0x39) //9-0
            )
                return false;
            unchecked { i++; }
        }
        return true;
    }

    /**
     * @dev Convert numeric string to integer
     * @param _value : string
     * @return _ret : integer
     */
    function parseInt(string memory _value)
        public
        pure
        returns (uint _ret) {
        bytes memory _bytesValue = bytes(_value);
        uint j = 1;
        for(uint i = _bytesValue.length-1; i >= 0 && i < _bytesValue.length;) {
            assert(uint8(_bytesValue[i]) >= 48 && uint8(_bytesValue[i]) <= 57);
            _ret += (uint8(_bytesValue[i]) - 48)*j;
            j*=10;
            unchecked { i--; }
        }
    }

    /**
     * @dev Get length of a string
     * @param s : string
     * @return : length
     */
    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for(len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if(b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }

    /**
     * @dev Convert uint value to string
     * @param value : uint value to be converted
     * @return : decimal number as string
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
     * @dev
     * @param buffer : bytes to be converted to hex
     * @return : hex string
     */
    function toHexString(bytes memory buffer) internal pure returns (string memory) {
        bytes memory converted = new bytes(buffer.length * 2);
        bytes memory _base = "0123456789abcdef";
        for (uint256 i; i < buffer.length;) {
            converted[i * 2] = _base[uint8(buffer[i]) / 16];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % 16];
            unchecked { i++; }
        }
        return string(abi.encodePacked("0x", converted));
    }
}