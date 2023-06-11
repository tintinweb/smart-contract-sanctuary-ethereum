// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "./Interface.sol";
import "./GatewayManager.sol";

/**
 * @title Off-Chain ENS Records Manager
 * @author freetib.eth, sshmatrix.eth
 * Github : https://github.com/namesys-eth/ccip2-eth-resolver
 * Client : htpps://ccip2.eth.limo
 */
contract CCIP2ETH is iCCIP2ETH {
    /// @dev - ONLY TESTNET
    /// TODO - Remove before Mainnet deployment
    function immolate() external {
        address _owner = gateway.owner();
        require(msg.sender == _owner, "NOT_OWNER");
        selfdestruct(payable(_owner));
    }

    /// @dev - Revert on fallback
    fallback() external payable {
        revert();
    }

    /// @dev - Receive donation
    receive() external payable {
        emit ThankYou(msg.sender, msg.value);
    }

    /// Events
    event ThankYou(address indexed addr, uint256 indexed value);
    event UpdateGatewayManager(address indexed oldAddr, address indexed newAddr);
    event RecordhashChanged(address indexed owner, bytes32 indexed node, bytes contenthash);
    event UpdateWrapper(address indexed newAddr, bool indexed status);
    event Approved(address owner, bytes32 indexed node, address indexed delegate, bool indexed approved);
    event UpdateSupportedInterface(bytes4 indexed sig, bool indexed status);

    /// Errors

    error InvalidSignature(string message);
    error NotAuthorized(bytes32 node, address addr);
    error ContenthashNotSet(bytes32 node);

    /// @dev - ENS Legacy Registry
    iENS public immutable ENS = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    /// @dev - CCIP-Read Gateways
    GatewayManager public gateway;
    /// Mappings
    /// @dev - Global contenthash storing all other records; could be contenthash in base32/36 string URL format
    mapping(bytes32 => bytes) public recordhash;
    /// @dev - On-chain singular manager for all records of a name
    //mapping(bytes32 => bool) public manager;
    /// @dev - List of all application wrapping contracts to be declared in contructor
    mapping(address => bool) public isWrapper;
    /// Interfaces
    mapping(bytes4 => bool) public supportsInterface;

    /// @dev - Constructor
    constructor() {
        gateway = new GatewayManager(msg.sender);

        /// @dev - Sets ENS Mainnet wrapper as Wrapper
        isWrapper[0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401] = true;
        emit UpdateWrapper(0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401, true);

        /// @dev - Sets ENS Goerli wrapper as Wrapper; remove before Mainnet deploy [?]
        //isWrapper[0x114D4603199df73e7D157787f8778E21fCd13066] = true;
        //emit UpdateWrapper(0x114D4603199df73e7D157787f8778E21fCd13066, true);

        /// @dev - Set necessary interfaces
        supportsInterface[iERC165.supportsInterface.selector] = true;
        supportsInterface[iENSIP10.resolve.selector] = true;
        supportsInterface[type(iERC173).interfaceId] = true;
        supportsInterface[iCCIP2ETH.recordhash.selector] = true;
        supportsInterface[iCCIP2ETH.setRecordhash.selector] = true;
    }

    function isAuthorized(bytes32 node, address _owner, address _manager) public view returns (bool) {
        return (isApprovedFor[_owner][node][_manager] || ENS.isApprovedForAll(_owner, _manager));
    }

    /**
     * @dev Set new Gateway Manager Contract
     * @param _gateway - address of new Gateway Manager Contract
     */
    function updateGatewayManager(address _gateway) external {
        require(msg.sender == gateway.owner(), "ONLY_DEV");
        require(msg.sender == GatewayManager(_gateway).owner(), "BAD_GATEWAY");
        require(address(this) == address(GatewayManager(_gateway).ccip2eth()), "BAD_SETUP");
        emit UpdateGatewayManager(address(gateway), _gateway);
        gateway = GatewayManager(_gateway);
    }

    /**
     * @dev Sets recordhash for a node, only ENS owner/approved address can set
     * @param _node - namehash of ENS (node)
     * @param _recordhash - contenthash to set as recordhash
     */
    function setRecordhash(bytes32 _node, bytes calldata _recordhash) external {
        address _owner = ENS.owner(_node);
        if (isWrapper[_owner]) {
            _owner = iToken(_owner).ownerOf(uint256(_node));
        }
        require(msg.sender == _owner || isApprovedFor[_owner][_node][msg.sender], "NOT_AUTHORIZED");
        recordhash[_node] = _recordhash;
        emit RecordhashChanged(msg.sender, _node, _recordhash);
    }

    /**
     * @dev Sets SUB recordhash for a node, only ENS owner/approved address can set
     * @param _sub - string subdomain prefix
     * @param _node - namehash of ENS (node)
     * @param _recordhash - contenthash to set as recordhash
     */
    function setSubRecordhash(string calldata _sub, bytes32 _node, bytes calldata _recordhash) external {
        address _owner = ENS.owner(_node);
        if (isWrapper[_owner]) {
            _owner = iToken(_owner).ownerOf(uint256(_node));
        }
        if (msg.sender == _owner || isApprovedFor[_owner][_node][msg.sender]) {
            bytes32 _namehash = keccak256(abi.encodePacked(_node, keccak256(bytes(_sub))));
            recordhash[_namehash] = _recordhash;
            emit RecordhashChanged(msg.sender, _namehash, _recordhash);
        } else {
            revert NotAuthorized(_node, msg.sender);
        }
    }

    /**
     * @dev Sets Deep sub.sub.domain recordhash for a node, only ENS owner/approved address can set
     * @param _subs - array of string for subdomain prefix
     * @param _node - namehash of ENS (node)
     * @param _recordhash - contenthash to set as recordhash
     * a.b.c.domain.eth = _subs[a, b, c]
     */
    function setDeepRecordhash(string[] calldata _subs, bytes32 _node, bytes calldata _recordhash) external {
        address _owner = ENS.owner(_node);
        if (isWrapper[_owner]) {
            _owner = iToken(_owner).ownerOf(uint256(_node));
        }
        require(msg.sender == _owner || isApprovedFor[_owner][_node][msg.sender], "NOT_AUTHORIZED");
        uint256 len = _subs.length;
        bytes32 _namehash = _node;
        unchecked {
            while (len > 0) {
                _namehash = keccak256(abi.encodePacked(_namehash, keccak256(bytes(_subs[--len]))));
            }
        }
        recordhash[_namehash] = _recordhash;
        emit RecordhashChanged(msg.sender, _namehash, _recordhash);
    }

    /**
     * @dev EIP-2544/EIP-3668 core resolve() function; aka CCIP-Read
     * @param name - ENS name to resolve; must be DNS encoded
     * @param request - request encoding specific function to resolve
     * @return result - triggers Off-chain Lookup; return value is stashed
     */
    function resolve(bytes calldata name, bytes calldata request) external view returns (bytes memory result) {
        unchecked {
            /// @dev - DNSDecode() routine
            uint256 index = 1;
            uint256 n = 1;
            uint256 len = uint8(bytes1(name[:1]));
            bytes[] memory _labels = new bytes[](42);
            _labels[0] = name[1:n += len];
            string memory _path = string(_labels[0]);
            string memory _domain = _path;
            while (name[n] > 0x0) {
                len = uint8(bytes1(name[n:++n]));
                _labels[index] = name[n:n += len];
                _domain = string.concat(_domain, ".", string(_labels[index]));
                _path = string.concat(string(_labels[index++]), "/", _path);
            }
            bytes32 _namehash = keccak256(abi.encodePacked(bytes32(0), keccak256(_labels[--index])));
            bytes32 _node;
            bytes memory _recordhash;
            while (index > 0) {
                _namehash = keccak256(abi.encodePacked(_namehash, keccak256(_labels[--index])));
                if (ENS.recordExists(_namehash)) {
                    _node = _namehash;
                    _recordhash = recordhash[_node];
                } else if (bytes(recordhash[_namehash]).length > 0) {
                    _recordhash = recordhash[_namehash];
                }
            }

            if (_recordhash.length == 0) {
                if (bytes4(request[:4]) == iResolver.contenthash.selector) {
                    // 404 page?profile page, resolver is set but missing recordhash
                    return abi.encode(recordhash[bytes32(uint256(404))]);
                }
                revert("RECORD_NOT_SET");
            }
            string memory _recType = gateway.funcToJson(request); // filename for the record
            address _owner = ENS.owner(_node);
            if (isWrapper[_owner]) {
                _owner = iToken(_owner).ownerOf(uint256(_node));
            }
            bytes32 _checkHash = keccak256(
                abi.encodePacked(this, blockhash(block.number - 1), _owner, _domain, _path, request, _recType)
            );
            revert OffchainLookup(
                address(this), // callback contract/ same for this case
                gateway.randomGateways(
                    _recordhash, string.concat("/.well-known/", _path, "/", _recType), uint256(_checkHash)
                ), // generate pseudo random list of gateways for resolution
                abi.encodePacked(uint16(block.timestamp / 60)), //60 seconds cache
                iCCIP2ETH.__callback.selector, // callback function
                abi.encode(_node, block.number - 1, _namehash, _checkHash, _domain, _path, request)
            );
        }
    }

    function redirectDAppService(bytes calldata _encodedName, bytes calldata _requested)
        external
        view
        returns (bytes4 _selector, bytes32 _namehash, bytes memory _reRequest, string memory domain)
    {
        uint256 index = 1;
        uint256 n = 1;
        uint256 len = uint8(bytes1(_encodedName[:1]));
        bytes[] memory _labels = new bytes[](42);
        _labels[0] = _encodedName[1:n += len];
        domain = string(_labels[0]);
        while (_encodedName[n] > 0x0) {
            len = uint8(bytes1(_encodedName[n:++n]));
            _labels[index] = _encodedName[n:n += len];
            domain = string.concat(domain, ".", string(_labels[index]));
        }
        bytes32 _ownedNode;
        _namehash = keccak256(abi.encodePacked(bytes32(0), keccak256(_labels[--index])));
        while (index > 0) {
            _namehash = keccak256(abi.encodePacked(_namehash, keccak256(_labels[--index])));
            if (ENS.recordExists(_namehash)) {
                _ownedNode = _namehash;
            }
        }
        require(_ownedNode != bytes32(0), "NOT_REGD");
        _selector = bytes4(_requested[:4]);
        _reRequest = abi.encodePacked(_selector, _namehash, _requested.length > 36 ? _requested[36:] : bytes(""));
        _namehash = _ownedNode;
    }

    function offchainApproved(
        address _owner,
        address _approvedSigner,
        bytes32 _node,
        bytes memory _signature,
        string memory _domain
    ) public view returns (bool) {
        address _signedBy = iCCIP2ETH(this).signedBy(
            string.concat(
                "Requesting Signature To Approve ENS Records Signer\n",
                "\nENS Domain: ",
                _domain,
                "\nApproved Signer: eip155:1:",
                gateway.toChecksumAddress(_approvedSigner),
                "\nOwner: eip155:1:",
                gateway.toChecksumAddress(_owner)
            ),
            _signature
        );
        return (_signedBy == _owner || isApprovedFor[_owner][_node][_signedBy]);
    }

    /**
     * @dev Callback function
     * @param response - response of CCIP-Read call
     * @param extradata - extra data used by callback
     */
    function __callback(bytes calldata response, bytes calldata extradata)
        external
        view
        returns (bytes memory result)
    {
        (
            bytes32 _node, // owned node/namehash on ENS
            uint256 _blocknumber,
            bytes32 _namehash, //namehash of node with recordhash
            bytes32 _checkHash, // extra checkhash
            string memory _domain, // full *.domain.eth
            string memory _path, // reverse path eth/domain/*
            bytes memory _request // bytes4+ requested namehash +?if other data
        ) = abi.decode(extradata, (bytes32, uint256, bytes32, bytes32, string, string, bytes));
        address _owner = ENS.owner(_node);
        if (isWrapper[_owner]) {
            _owner = iToken(_owner).ownerOf(uint256(_node));
        }
        string memory _recType = gateway.funcToJson(_request);
        /// @dev - timeout in 4 blocks
        require(
            block.number < _blocknumber + 5
                && _checkHash
                    == keccak256(abi.encodePacked(this, blockhash(_blocknumber), _owner, _domain, _path, _request, _recType)),
            "INVALID_CHECKSUM/TIMEOUT"
        );
        // signer could be owner
        // OR on-chain approved manager
        // OR off-chain approved signer key
        address _signer;
        // signature for record/result
        bytes memory _recordSig;
        /// @dev - Init off-chain manager signature request string
        string memory signRequest;
        /// @dev - Get signer-type from response identifier
        bytes4 _type = bytes4(response[:4]);
        bytes memory _approvedSig; // approved sig for record signer if it's not owner or on-chain approved
        //address _signedBy;
        (_signer, _recordSig, _approvedSig, result) = abi.decode(response[4:], (address, bytes, bytes, bytes));
        if (_approvedSig.length < 64) {
            require(_signer == _owner || isApprovedFor[_owner][_node][_signer], "INVALID_CALLBACK");
        } else {
            require(offchainApproved(_owner, _signer, _node, _approvedSig, _domain), "BAD_RECORD_APPROVAL");
        }
        if (_type == iCallbackType.signedRecord.selector) {
            signRequest = string.concat(
                "Requesting Signature To Update ENS Record\n",
                "\nENS Domain: ",
                _domain,
                "\nRecord Type: ",
                _recType,
                "\nExtradata: 0x",
                gateway.bytesToHexString(abi.encodePacked(keccak256(result)), 0),
                "\nSigned By: eip155:1:",
                gateway.toChecksumAddress(_signer)
            );
            require(_signer == iCCIP2ETH(this).signedBy(signRequest, _recordSig), "BAD_SIGNED_RECORD");
        } else if (_type == iCallbackType.signedRedirect.selector) {
            if (result[0] == 0x0) {
                signRequest = string.concat(
                    "Requesting Signature To Redirect ENS Records\n",
                    "\nENS Domain: ",
                    _domain, // <dapp>.domain.eth
                    "\nExtradata: ",
                    gateway.bytesToHexString(abi.encodePacked(keccak256(result)), 0),
                    "\nSigned By: eip155:1:",
                    gateway.toChecksumAddress(_signer)
                );
                require(_signer == iCCIP2ETH(this).signedBy(signRequest, _recordSig), "BAD_DAPP_SIGNATURE");
                // Signed IPFS redirect
                /// TODO: fix 2nd callback format
                revert OffchainLookup(
                    address(this),
                    gateway.randomGateways(
                        abi.decode(result, (bytes)), // abi decode as recordhash to redirect
                        string.concat("/.well-known/", _path, "/", _recType),
                        uint256(_checkHash)
                    ),
                    abi.encodePacked(uint16(block.timestamp / 60)),
                    CCIP2ETH.__callback2.selector, // 2nd callback
                    abi.encode(_node, block.number - 1, _namehash, _checkHash, _domain, _path, _request)
                );
            }
            // Direct ENS dapp redirect
            // result is DNS encoded, it's NOT abi encoded
            // last byte is 0x00 = end of DNS encoded
            require(result[result.length - 1] == 0x0, "BAD_ENS_ENCODED");
            (bytes4 _sig, bytes32 _rNamehash, bytes memory _rRequest, string memory _rDomain) =
                CCIP2ETH(this).redirectDAppService(result, _request);
            signRequest = string.concat(
                "Requesting Signature To Install DApp Service\n",
                "\nENS Domain: ",
                _domain, // eg, ens.domain.eth
                "\nDApp Service: ",
                _rDomain, // eg, app.ens.eth
                "\nSigned By: eip155:1:",
                gateway.toChecksumAddress(_signer)
            );
            require(_signer == iCCIP2ETH(this).signedBy(signRequest, _recordSig), "BAD_DAPP_SIGNATURE");
            address _resolver = ENS.resolver(_rNamehash); //owned node
            if (iERC165(_resolver).supportsInterface(iENSIP10.resolve.selector)) {
                return iENSIP10(_resolver).resolve(result, _rRequest);
            } else if (iERC165(_resolver).supportsInterface(_sig)) {
                bool ok;
                (ok, result) = _resolver.staticcall(_rRequest);
                require(ok, "BAD_RESOLVER_TYPE");
                require(result.length > 32 || bytes32(result) > bytes32(0), "RECORD_NOT_SET");
            } else {
                revert("BAD_RESOLVER_FUNCTION");
            }
        } else {
            //gateway.__fallback(_owner, _data);
            //revert InvalidSignature("BAD_PREFIX");
        }
    }

    function __callback2(bytes calldata response, bytes calldata extradata) external view returns (bytes memory) {
        // not again
    }

    /**
     * @dev Checks if a signature is valid
     * @param signRequest - string message that was signed
     * @param signature - compact signature to verify
     * @return signer - signer of message
     * @notice - Signature Format:
     * a) 64 bytes - bytes32(r) + bytes32(vs) ~ compact, or
     * b) 65 bytes - bytes32(r) + bytes32(s) + uint8(v) ~ packed, or
     * c) 96 bytes - bytes32(r) + bytes32(s) + uint256(v) ~ longest
     */
    function signedBy(string calldata signRequest, bytes calldata signature) external view returns (address signer) {
        bytes32 r = bytes32(signature[:32]);
        bytes32 s;
        uint8 v;
        uint256 len = signature.length;
        if (len == 64) {
            bytes32 vs = bytes32(signature[32:]);
            s = vs & bytes32(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            v = uint8((uint256(vs) >> 255) + 27);
        } else if (len == 65) {
            s = bytes32(signature[32:64]);
            v = uint8(bytes1(signature[64:]));
        } else if (len == 96) {
            s = bytes32(signature[32:64]);
            v = uint8(uint256(bytes32(signature[64:])));
        } else {
            revert InvalidSignature("BAD_SIG_LENGTH");
        }
        if (s > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert InvalidSignature("INVALID_S_VALUE");
        }
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n", gateway.uintToString(bytes(signRequest).length), signRequest
            )
        );
        signer = ecrecover(digest, v, r, s);
        require(signer != address(0), "ZERO_ADDR");
    }

    /**
     * @dev Sets a Signer/Manager as approved to manage records for a node
     * @param _node - namehash of ENS (node)
     * @param _signer - address of Signer/Manager
     * @param _approval - status to set
     */
    function approve(bytes32 _node, address _signer, bool _approval) external {
        isApprovedFor[msg.sender][_node][_signer] = _approval;
        emit Approved(msg.sender, _node, _signer, _approval);
    }

    /**
     * @dev Sets multiple Signer/Manager as approved to manage records for a node
     * @param _node - namehash of ENS (node)
     * @param _signer - address of Signer/Manager
     * @param _approval - status to set
     */
    function multiApprove(bytes32[] calldata _node, address[] calldata _signer, bool[] calldata _approval) external {
        uint256 len = _node.length;
        require(len == _signer.length, "BAD_LENGTH");
        require(len == _approval.length, "BAD_LENGTH");
        for (uint256 i = 0; i < len; i++) {
            isApprovedFor[msg.sender][_node[i]][_signer[i]] = _approval[i];
            emit Approved(msg.sender, _node[i], _signer[i], _approval[i]);
        }
    }

    /**
     * @dev Check if a Signer/Manager is approved by Owner to manage records for a node
     * _owner - address of Owner
     * => node - namehash of ENS (node)
     * => approved - address of Signer/Manager
     * => bool
     */
    mapping(address => mapping(bytes32 => mapping(address => bool))) public isApprovedFor;

    /**
     * @dev Check if a Signer/Manager is approved to manage records for a node
     * @param _node - namehash of ENS (node)
     * @param _signer - address of Signer/Manager
     */
    function approved(bytes32 _node, address _signer) public view returns (bool) {
        address _owner = ENS.owner(_node);
        if (isWrapper[_owner]) {
            _owner = iToken(_owner).ownerOf(uint256(_node));
        }
        return _owner == _signer || isApprovedFor[_owner][_node][_signer];
    }

    /**
     * @dev Updates Supported interface
     * @param _sig - 4 bytes interface selector
     * @param _set - state to set for selector
     */
    function updateSupportedInterface(bytes4 _sig, bool _set) external {
        require(msg.sender == gateway.owner(), "ONLY_DEV");
        supportsInterface[_sig] = _set;
        emit UpdateSupportedInterface(_sig, _set);
    }

    /**
     * @dev Add/remove wrapper
     * @param _addr - address of wrapper
     * @param _set - state to set for wrapper
     */
    function updateWrapper(address _addr, bool _set) external {
        require(msg.sender == gateway.owner(), "ONLY_DEV");
        require(!_set || _addr.code.length > 0, "ONLY_CONTRACT");
        isWrapper[_addr] = _set;
        emit UpdateWrapper(_addr, _set);
    }

    /**
     * @dev - Owner of contract
     */
    function owner() public view returns (address) {
        return gateway.owner();
    }

    /**
     * @dev Withdraw Ether to owner; to be used for tips or in case some Ether gets locked in the contract
     */
    function withdraw() external {
        payable(gateway.owner()).transfer(address(this).balance);
    }

    /**
     * @dev To be used for tips or in case some fungible tokens get locked in the contract
     * @param _token - token address
     * @param _balance - amount to release
     */
    function withdraw(address _token, uint256 _balance) external {
        iToken(_token).transferFrom(address(this), gateway.owner(), _balance);
    }

    /**
     * @dev To be used for tips or in case some non-fungible tokens get locked in the contract
     * @param _token - token address
     * @param _id - token ID to release
     */
    function safeWithdraw(address _token, uint256 _id) external {
        iToken(_token).safeTransferFrom(address(this), gateway.owner(), _id);
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

// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "./Interface.sol";
import "./CCIP2ETH.sol";

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
    CCIP2ETH public ccip2eth;

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
    constructor(address _owner) {
        /// @dev - Set owner of contract
        owner = payable(_owner);
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