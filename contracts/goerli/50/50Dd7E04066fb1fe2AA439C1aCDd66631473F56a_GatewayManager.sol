// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "./Interface.sol";

/**
 * @title CCIP2ETH Gateway Manager
 * @author freetib.eth, sshmatrix.eth
 * Github : https://github.com/namesys-eth/ccip2-eth-resolver
 * Docs : htpps://ccip2.eth.limo
 * Client : htpps://namesys.eth.limo
 */
contract GatewayManager is iERC173, iGatewayManager {
    /// @dev - Events
    event AddGateway(string indexed domain);
    event RemoveGateway(string indexed domain);
    event UpdateFuncFile(bytes4 _func, string _name);

    /// @dev - Errors
    error ContenthashNotImplemented(bytes1 _type);
    error ResolverFunctionNotImplemented(bytes4 func);

    /// @dev - Contract owner/multisig address
    address public owner;

    /// @dev - Modifer to allow only dev/admin access
    modifier onlyDev() {
        require(msg.sender == owner, "ONLY_DEV");
        _;
    }

    address immutable THIS = address(this);
    /// @dev - Primary IPFS gateway domain, ipfs2.eth.limo
    string public PrimaryGateway = "ipfs2.eth.limo";

    /// @dev - List of secondary gateway domains
    string[] public Gateways;
    /// @dev - Resolver function bytes4 selector → Off-chain record filename <name>.json
    mapping(bytes4 => string) public funcMap;

    /// @dev - Constructor
    constructor() {
        /// @dev - Set owner of contract
        owner = payable(msg.sender);
        /// @dev - Define all default records
        funcMap[iResolver.addr.selector] = "address/60";
        funcMap[iResolver.pubkey.selector] = "pubkey";
        funcMap[iResolver.name.selector] = "name";
        funcMap[iResolver.contenthash.selector] = "contenthash";
        funcMap[iResolver.zonehash.selector] = "dns/zone";
        /// @dev - Set initial list of secondary gateways
        Gateways.push("dweb.link");
        emit AddGateway("dweb.link");
        Gateways.push("ipfs.io");
        emit AddGateway("ipfs.io");
    }

    /**
     * @dev Selects and construct random gateways for CCIP resolution
     * @param _recordhash - global recordhash for record storage
     * @param _path - full path for records.json
     * @param k - pseudo random seeding
     * @return gateways - pseudo random list of gateway URLs for CCIP-Read
     * gateway URL e.g. https://gateway.tld/ipns/f<ipns-hash-hex>/.well-known/eth/virgil/<records>.json?t1=0x0123456789
     */
    function randomGateways(bytes calldata _recordhash, string memory _path, uint256 k)
        public
        view
        returns (string[] memory gateways)
    {
        unchecked {
            uint256 gLen = Gateways.length;
            uint256 len = (gLen / 2) + 2;
            if (len > 4) len = 4;
            gateways = new string[](len);
            uint256 i;
            if (bytes8(_recordhash[:8]) == bytes8("https://")) {
                gateways[0] = string.concat(string(_recordhash), _path, ".json?t={data}");
                return gateways;
            }
            if (bytes(PrimaryGateway).length > 0) {
                gateways[i++] = string.concat(
                    "https://", formatSubdomain(_recordhash), ".", PrimaryGateway, _path, ".json?t={data}"
                );
            }
            string memory _fullPath;
            bytes1 _prefix = _recordhash[0];
            if (_prefix == 0xe2) {
                _fullPath = string.concat(
                    "/api/v0/dag/get?arg=f", bytesToHexString(_recordhash, 2), _path, ".json?t={data}&format=dag-cbor"
                );
            } else if (_prefix == 0xe5) {
                _fullPath = string.concat("/ipns/f", bytesToHexString(_recordhash, 2), _path, ".json?t={data}");
            } else if (_prefix == 0xe3) {
                _fullPath = string.concat("/ipfs/f", bytesToHexString(_recordhash, 2), _path, ".json?t={data}");
            } else if (_prefix == bytes1("k")) {
                _fullPath = string.concat("/ipns/", string(_recordhash), _path, ".json?t={data}");
            } else if (bytes2(_recordhash[:2]) == bytes2("ba")) {
                _fullPath = string.concat("/ipfs/", string(_recordhash), _path, ".json?t={data}");
            } else {
                revert("UNSUPPORTED_RECORDHASH");
            }
            while (i < len) {
                k = uint256(keccak256(abi.encodePacked(block.number * i, k)));
                gateways[i++] = string.concat("https://", Gateways[k % gLen], _fullPath);
            }
        }
    }

    /**
     */
    function __fallback(bytes4) external view returns (address signer, bytes memory result) {
        revert("NOT_YET_IMPLEMENTED");
    }

    /**
     * @dev Converts queried resolver function to off-chain record filename
     * @param data - full path for records.json
     * @return _jsonPath - path to JSON file containing the queried record
     */

    function funcToJson(bytes calldata data) public view returns (string memory _jsonPath) {
        bytes4 func = bytes4(data[:4]);
        if (bytes(funcMap[func]).length > 0) {
            _jsonPath = funcMap[func];
        } else if (func == iResolver.text.selector) {
            _jsonPath = string.concat("text/", abi.decode(data[36:], (string)));
        } else if (func == iOverloadResolver.addr.selector) {
            _jsonPath = string.concat("address/", uintToString(abi.decode(data[36:], (uint256))));
        } else if (func == iResolver.interfaceImplementer.selector) {
            _jsonPath =
                string.concat("interface/0x", bytesToHexString(abi.encodePacked(abi.decode(data[36:], (bytes4))), 0));
        } else if (func == iResolver.ABI.selector) {
            _jsonPath = string.concat("abi/", uintToString(abi.decode(data[36:], (uint256))));
        } else if (func == iResolver.dnsRecord.selector || func == iOverloadResolver.dnsRecord.selector) {
            // e.g, `.well-known/eth/domain/dns/<resource>.json`
            uint256 resource;
            if (data.length == 100) {
                // 4+32+32+32
                (, resource) = abi.decode(data[36:], (bytes32, uint256)); // actual uint16
            } else {
                (, resource) = abi.decode(data[36:], (bytes, uint256));
            }
            _jsonPath = string.concat("dns/", uintToString(resource));
        } else {
            revert ResolverFunctionNotImplemented(func);
        }
    }

    /**
     * @dev Converts overflowing recordhash to valid subdomain label
     * @param _recordhash - overflowing recordhash to convert
     * @return result - valid subdomain label
     * Compatible with *.ipfs2.eth.limo gateway only
     */
    function formatSubdomain(bytes calldata _recordhash) public pure returns (string memory result) {
        if (_recordhash[0] == bytes1("k") || _recordhash[0] == bytes1("b")) {
            return string(_recordhash);
        }
        uint256 len = _recordhash.length;
        uint256 pointer = len % 16;
        result = string.concat(bytesToHexString(_recordhash[:pointer], 0));
        while (pointer < len) {
            result = string.concat(result, ".", bytesToHexString(_recordhash[pointer:pointer += 16], 0));
        }
    }

    /**
     * @dev UINT to number string
     * @param value - UINT value
     * @return - string formatted UINT
     */
    function uintToString(uint256 value) public pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        unchecked {
            while (temp != 0) {
                ++digits;
                temp /= 10;
            }
            bytes memory buffer = new bytes(digits);
            while (value != 0) {
                buffer[--digits] = bytes1(uint8(48 + (value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }

    /**
     * @dev Converts address to checksummed address string
     * @param _addr - address
     * @return - checksum address string
     */
    function toChecksumAddress(address _addr) public pure returns (string memory) {
        bytes memory _buffer = abi.encodePacked(_addr);
        bytes memory result = new bytes(40); //bytes20 * 2
        bytes memory B16 = "0123456789ABCDEF";
        bytes memory b16 = "0123456789abcdef";
        bytes32 hash = keccak256(abi.encodePacked(bytesToHexString(_buffer, 0)));
        uint256 high;
        uint256 low;
        for (uint256 i; i < 20; i++) {
            high = uint8(_buffer[i]) / 16;
            low = uint8(_buffer[i]) % 16;
            result[i * 2] = uint8(hash[i]) / 16 > 7 ? B16[high] : b16[high];
            result[i * 2 + 1] = uint8(hash[i]) % 16 > 7 ? B16[low] : b16[low];
        }
        return string.concat("0x", string(result));
    }

    /**
     * @dev Convert range of bytes to hex string
     * @param _buffer - bytes buffer
     * @param _start - index to start conversion at (continues till the end)
     * @return - hex string
     */
    function bytesToHexString(bytes memory _buffer, uint256 _start) public pure returns (string memory) {
        uint256 len = _buffer.length - _start;
        bytes memory result = new bytes((len) * 2);
        bytes memory b16 = bytes("0123456789abcdef");
        uint8 _b;
        for (uint256 i = 0; i < len; i++) {
            _b = uint8(_buffer[i + _start]);
            result[i * 2] = b16[_b / 16];
            result[(i * 2) + 1] = b16[_b % 16];
        }
        return string(result);
    }

    /// @dev - Gateway Management Functions
    /**
     * @dev Adds a new record type by adding its bytes4-to-filename mapping
     * @param _func - bytes4 of new record type to add
     * @param _name - string formatted label of function, must start with "/"
     */
    function addFuncMap(bytes4 _func, string calldata _name) external onlyDev {
        funcMap[_func] = _name;
        emit UpdateFuncFile(_func, _name);
    }

    /**
     * @dev Shows list of all available gateways
     * @return list - list of gateways
     */
    function listGateways() external view returns (string[] memory list) {
        return Gateways;
    }

    /**
     * @dev Add single gateway
     * @param _domain - new gateway domain
     */
    function addGateway(string calldata _domain) external onlyDev {
        Gateways.push(_domain);
        emit AddGateway(_domain);
    }

    /**
     * @dev Remove single gateway
     * @param _index - gateway index to remove
     */
    function removeGateway(uint256 _index) external onlyDev {
        require(Gateways.length > 1, "Last Gateway");
        emit RemoveGateway(Gateways[_index]);
        Gateways[_index] = Gateways[Gateways.length - 1];
        Gateways.pop();
    }

    /**
     * @dev Replace single gateway
     * @param _index : gateway index to replace
     * @param _domain : new gateway domain.tld
     */
    function replaceGateway(uint256 _index, string calldata _domain) external onlyDev {
        emit RemoveGateway(Gateways[_index]);
        Gateways[_index] = _domain;
        emit AddGateway(_domain);
    }

    /**
     * @dev Transfer ownership of resolver contract
     * @param _newOwner - address of new owner/multisig
     */

    function transferOwnership(address _newOwner) external onlyDev {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /**
     * @dev Withdraw Ether to owner; to be used for tips or in case some Ether gets locked in the contract
     */
    function withdraw() external {
        payable(owner).transfer(THIS.balance);
    }

    /**
     * @dev To be used for tips or in case some fungible tokens get locked in the contract
     * @param _token - token address
     * @param _balance - amount to release
     */
    function withdraw(address _token, uint256 _balance) external {
        iToken(_token).transferFrom(THIS, owner, _balance);
    }

    /**
     * @dev To be used for tips or in case some non-fungible tokens get locked in the contract
     * @param _token - token address
     * @param _id - token ID to release
     */
    function safeWithdraw(address _token, uint256 _id) external {
        iToken(_token).safeTransferFrom(THIS, owner, _id);
    }

    function chunk(bytes calldata _b, uint256 _start, uint256 _end) external pure returns (bytes memory) {
        return _b[_start:(_end > _start ? _end : _b.length)];
    }
}

// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

interface iERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface iERC173 {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);
    function transferOwnership(address _newOwner) external;
}

interface iENS {
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
    function recordExists(bytes32 node) external view returns (bool);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface iENSIP10 {
    function resolve(bytes memory _name, bytes memory _data) external view returns (bytes memory);

    error OffchainLookup(address _to, string[] _gateways, bytes _data, bytes4 _callbackFunction, bytes _extradata);
}

interface iCCIP2ETH is iENSIP10 {
    function __callback(bytes calldata _response, bytes calldata _extraData)
        external
        view
        returns (bytes memory _result);

    function signedBy(string calldata _signRequest, bytes calldata _signature)
        external
        view
        returns (address _signer);
    function setRecordhash(bytes32 _node, bytes calldata _contenthash) external;
    function recordhash(bytes32 _node) external view returns (bytes memory _contenthash);
}

interface iGatewayManager is iERC173 {
    function randomGateways(bytes calldata _recordhash, string memory _path, uint256 k)
        external
        view
        returns (string[] memory gateways);
    function uintToString(uint256 value) external pure returns (string memory);
    function bytesToHexString(bytes calldata _buffer, uint256 _start) external pure returns (string memory);
    function funcToJson(bytes calldata data) external view returns (string memory _jsonPath);
    function listGateways() external view returns (string[] memory list);
    function toChecksumAddress(address _addr) external pure returns (string memory);
    //
    function __fallback(bytes4 _type) external view returns (address signer, bytes memory result);
    function chunk(bytes calldata _b, uint256 _start, uint256 _end) external pure returns (bytes memory);
    /// write functions
    function addFuncMap(bytes4 _func, string calldata _name) external;
    function addGateway(string calldata _domain) external;
    // function addGateways(string[] calldata _domains) external;
    function removeGateway(uint256 _index) external;
    //function removeGateways(uint256[] memory _indexes) external;
    function replaceGateway(uint256 _index, string calldata _domain) external;
    //function replaceGateways(uint256[] calldata _indexes, string[] calldata _domains) external;
}

interface iUtils {}

interface iResolver {
    function contenthash(bytes32 node) external view returns (bytes memory);
    function addr(bytes32 node) external view returns (address payable);
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);
    function text(bytes32 node, string calldata key) external view returns (string memory value);
    function name(bytes32 node) external view returns (string memory);
    function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory);
    function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view returns (address);
    function zonehash(bytes32 node) external view returns (bytes memory);
    function dnsRecord(bytes32 node, bytes32 name, uint16 resource) external view returns (bytes memory);
    function recordVersions(bytes32 node) external view returns (uint64);
    function approved(bytes32 _node, address _signer) external view returns (bool);
}

interface iOverloadResolver {
    function addr(bytes32 node, uint256 coinType) external view returns (bytes memory);
    function dnsRecord(bytes32 node, bytes memory name, uint16 resource) external view returns (bytes memory);
}

interface iToken {
    function ownerOf(uint256 id) external view returns (address);
    function transferFrom(address from, address to, uint256 bal) external;
    function safeTransferFrom(address from, address to, uint256 bal) external;
    //function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    //function setApprovalForAll(address _operator, bool _approved) external;
    //event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    //event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
}
// owner = owner of domain.eth
// manager = on chain approved by owner
// signer = record's result signer

interface iCallbackType {
    function signedRecord(
        address recordSigner, // owner || onchain approved signer || offchain approved signer
        bytes memory recordSignature, // signature from record signer for result value
        bytes memory approvedSignature, // bytes1(..) IF record signer is owner or onchain approved signer
        bytes memory result // abi encoded result
    ) external view returns (bytes memory);

    function signedRedirect(
        address recordSigner, // owner || onchain approved signer || offchain approved signer
        bytes memory recordSignature, // signature from record signer for redirect value
        bytes memory approvedSignature, // bytes1(..) IF record signer is owner or onchain approved signer
        bytes memory redirect // ABI encoded recordhash OR DNS encoded domain.eth to redirect
    ) external view returns (bytes memory);
}