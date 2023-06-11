// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "./Interface.sol";

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
    iGatewayManager public gateway;

    /// Mappings
    /**
     * @dev - Global contenthash storing all other records
     * @notice - Should be in generic ENS contenthash format or base32/base36 string URL format
     *
     */
    mapping(bytes32 => bytes) public recordhash;
    /// @dev - On-chain singular Manager database
    /// Note - Manager is someone who can manage off-chain records for a domain on behalf of its owner
    mapping(address => mapping(bytes32 => mapping(address => bool))) public isApprovedFor;
    //mapping(bytes32 => bool) public manager;
    /// @dev - List of all wrapping contracts to be declared in contructor
    mapping(address => bool) public isWrapper;

    /// Interfaces
    mapping(bytes4 => bool) public supportsInterface;

    /// @dev - Constructor
    constructor(address _gateway) {
        gateway = iGatewayManager(_gateway);

        /// @dev - Sets ENS Mainnet wrapper as Wrapper
        isWrapper[0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401] = true;
        emit UpdateWrapper(0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401, true);

        /// @dev - Sets ENS Goerli wrapper as Wrapper; remove before Mainnet deploy [?TODO]
        //isWrapper[0x114D4603199df73e7D157787f8778E21fCd13066] = true;
        //emit UpdateWrapper(0x114D4603199df73e7D157787f8778E21fCd13066, true);

        /// @dev - Set necessary interfaces
        supportsInterface[iERC165.supportsInterface.selector] = true;
        supportsInterface[iENSIP10.resolve.selector] = true;
        supportsInterface[type(iERC173).interfaceId] = true;
        supportsInterface[iCCIP2ETH.recordhash.selector] = true;
        supportsInterface[iCCIP2ETH.setRecordhash.selector] = true;
    }

    /**
     * @dev Checks if a manager is authorised by the owner of ENS domain
     * @param _node - Namehash of ENS domain
     * @param _owner - Owner of ENS domain
     * @param _manager - Manager address to check
     */
    function isAuthorized(bytes32 _node, address _owner, address _manager) public view returns (bool) {
        return (isApprovedFor[_owner][_node][_manager] || ENS.isApprovedForAll(_owner, _manager));
    }

    /**
     * @dev Set new Gateway Manager Contract
     * @param _gateway - Address of new Gateway Manager Contract
     */
    function updateGatewayManager(address _gateway) external {
        require(msg.sender == gateway.owner(), "ONLY_DEV");
        require(msg.sender == iGatewayManager(_gateway).owner(), "BAD_GATEWAY");
        emit UpdateGatewayManager(address(gateway), _gateway);
        gateway = iGatewayManager(_gateway);
    }

    /**
     * @dev Sets recordhash for a node
     * Note - Only ENS owner or manager can call
     * @param _node - Namehash of ENS domain
     * @param _recordhash - Contenthash to set as recordhash
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
     * @dev Sets recordhash for a level 1 sub.domain.eth of a node
     * Note - Only ENS owner or manager can call
     * @param _sub - Level 1 Subdomain label
     * @param _node - Namehash of ENS domain
     * @param _recordhash - Contenthash to set as recordhash
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
     * @dev Sets recordhash for a deep level N sub1.sub2... subN.domain.eth of a node
     * Note - Only ENS owner or manager can call
     * @param _subs - Array of level N subdomain labels
     * @param _node - Namehash of ENS domain
     * @param _recordhash - Contenthash to set as recordhash
     * Note - a.b.c.domain.eth = [a, b, c]
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
     * @param name - ENS domain to resolve; must be DNS encoded
     * @param request - Encoding-specific function to resolve
     * @return result - Triggers Off-chain Lookup
     * Note - Return value is not used
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
                    // 404 default page; triggers when resolver is set but missing recordhash
                    return abi.encode(recordhash[bytes32(uint256(404))]);
                }
                revert("RECORD_NOT_SET");
            }
            string memory _recType = gateway.funcToJson(request); // Filename for the requested record
            address _owner = ENS.owner(_node);
            if (isWrapper[_owner]) {
                _owner = iToken(_owner).ownerOf(uint256(_node));
            }
            bytes32 _checkHash = keccak256(
                abi.encodePacked(this, blockhash(block.number - 1), _owner, _domain, _path, request, _recType)
            );
            revert OffchainLookup(
                address(this), // Callback contract (= THIS, for this case)
                gateway.randomGateways(
                    _recordhash, string.concat("/.well-known/", _path, "/", _recType), uint256(_checkHash)
                ), // Generate pseudo-random list of gateways for record resolution
                abi.encodePacked(uint16(block.timestamp / 60)), // Cache = 60 seconds
                iCCIP2ETH.__callback.selector, // Callback function
                abi.encode(_node, block.number - 1, _namehash, _checkHash, _domain, _path, request)
            );
        }
    }

    /**
     * @dev Redirects the CCIP-Read request
     * @param _encodedName - ENS domain to resolve; must be DNS encoded
     * @param _requested - Originally requested encoding-specific function to resolve
     * @return _selector - Redirected function selector
     * @return _namehash - Redirected namehash
     * @return _redirectRequest - Redirected request
     * @return domain - String-formatted ENS domain
     */
    function redirectDAppService(bytes calldata _encodedName, bytes calldata _requested)
        external
        view
        returns (bytes4 _selector, bytes32 _namehash, bytes memory _redirectRequest, string memory domain)
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
        require(_ownedNode != bytes32(0), "NOT_REGISTERED");
        _selector = bytes4(_requested[:4]);
        _redirectRequest = abi.encodePacked(_selector, _namehash, _requested.length > 36 ? _requested[36:] : bytes(""));
        _namehash = _ownedNode;
    }

    /**
     * @dev Checks for manager access to an ENS domain for record management
     * @param _owner - Owner of ENS domain
     * @param _approvedSigner - Manager address to check
     * @param _node - Namehash of ENS domain
     * @param _signature - Signature to verify
     * @param _domain - String-formatted ENS domain
     * @return  - Whether manager is approved by the owner
     */
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
     * @dev Default Callback function
     * @param response - Response of CCIP-Read call
     * @param extradata - Extra data used by callback
     * @return result - Concludes Off-chain Lookup
     * Note - Return value is not used
     */
    function __callback(bytes calldata response, bytes calldata extradata)
        external
        view
        returns (bytes memory result)
    {
        (
            bytes32 _node, // Namehash of ENS domain
            uint256 _blocknumber,
            bytes32 _namehash, // Namehash of node with recordhash
            bytes32 _checkHash, // Extra checkhash
            string memory _domain, // String-formatted complete 'a.b.c.domain.eth'
            string memory _path, // Reverse DNS path 'eth/domain/c/b/a'
            bytes memory _request // Format: <bytes4> + <namehash> + <extradata>
        ) = abi.decode(extradata, (bytes32, uint256, bytes32, bytes32, string, string, bytes));
        address _owner = ENS.owner(_node);
        if (isWrapper[_owner]) {
            _owner = iToken(_owner).ownerOf(uint256(_node));
        }
        string memory _recType = gateway.funcToJson(_request);
        /// @dev - Timeout in 4 blocks
        require(
            block.number < _blocknumber + 5
                && _checkHash
                    == keccak256(abi.encodePacked(this, blockhash(_blocknumber), _owner, _domain, _path, _request, _recType)),
            "INVALID_CHECKSUM/TIMEOUT"
        );
        // Signer could be:
        // a) Owner
        // OR, b) On-chain approved manager
        // OR, c) Off-chain approved signer
        address _signer;
        /// Signature associated with the record
        bytes memory _recordSignature;
        /// Init off-chain manager's signature request
        string memory signRequest;
        /// Get signer-type from response identifier
        bytes4 _type = bytes4(response[:4]);
        /// Off-chain signature approving record signer (if signer != owner or on-chain manager)
        bytes memory _approvedSig;
        //address _signedBy;
        (_signer, _recordSignature, _approvedSig, result) = abi.decode(response[4:], (address, bytes, bytes, bytes));
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
            require(_signer == iCCIP2ETH(this).signedBy(signRequest, _recordSignature), "BAD_SIGNED_RECORD");
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
                require(_signer == iCCIP2ETH(this).signedBy(signRequest, _recordSignature), "BAD_DAPP_SIGNATURE");
                // Signed IPFS redirect
                /// TODO - Fix 2nd callback format
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
            // ENS dApp redirect
            // Result should be DNS encoded; result should NOT be ABI-encoded
            // Note Last byte is 0x00 meaning end of DNS-encoded stream
            require(result[result.length - 1] == 0x0, "BAD_ENS_ENCODED");
            (bytes4 _sig, bytes32 _redirectNamehash, bytes memory _redirectRequest, string memory _redirectDomain) =
                CCIP2ETH(this).redirectDAppService(result, _request);
            signRequest = string.concat(
                "Requesting Signature To Install DApp Service\n",
                "\nENS Domain: ",
                _domain, // e.g. ens.domain.eth
                "\nDApp Service: ",
                _redirectDomain, // e.g. app.ens.eth
                "\nSigned By: eip155:1:",
                gateway.toChecksumAddress(_signer)
            );
            require(_signer == iCCIP2ETH(this).signedBy(signRequest, _recordSignature), "BAD_DAPP_SIGNATURE");
            address _resolver = ENS.resolver(_redirectNamehash); // Owned node
            if (iERC165(_resolver).supportsInterface(iENSIP10.resolve.selector)) {
                return iENSIP10(_resolver).resolve(result, _redirectRequest);
            } else if (iERC165(_resolver).supportsInterface(_sig)) {
                bool ok;
                (ok, result) = _resolver.staticcall(_redirectRequest);
                require(ok, "BAD_RESOLVER_TYPE");
                require(result.length > 32 || bytes32(result) > bytes32(0), "RECORD_NOT_SET");
            } else {
                revert("BAD_RESOLVER_FUNCTION");
            }
        } else {
            //gateway.__fallback(_owner, _data);
            //revert InvalidSignature("BAD_PREFIX");
            // DO NOTHING
        }
    }

    function __callback2(bytes calldata response, bytes calldata extradata) external view returns (bytes memory) {
        // DO NOTHING
    }

    /**
     * @dev Checks if a signature is valid
     * @param signRequest - String-formatted message that was signed
     * @param signature - Compact signature to verify
     * @return signer - Signer of message
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
     * @dev Sets a signer (= manager) as approved to manage records for a node
     * @param _node - Namehash of ENS domain
     * @param _signer - Address of signer (= manager)
     * @param _approval - Status to set
     */
    function approve(bytes32 _node, address _signer, bool _approval) external {
        isApprovedFor[msg.sender][_node][_signer] = _approval;
        emit Approved(msg.sender, _node, _signer, _approval);
    }

    /**
     * @dev Sets multiple signer (= manager) as approved to manage records for a node
     * @param _node - Namehash of ENS domain
     * @param _signer - Address of signer (= manager)
     * @param _approval - Status to set
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
     * @dev Checks if a signer (= manager) is approved to manage records for a node
     * @param _node - Namehash of ENS domain
     * @param _signer - Address of signer (= manager)
     */
    function approved(bytes32 _node, address _signer) public view returns (bool) {
        address _owner = ENS.owner(_node);
        if (isWrapper[_owner]) {
            _owner = iToken(_owner).ownerOf(uint256(_node));
        }
        return _owner == _signer || isApprovedFor[_owner][_node][_signer];
    }

    /**
     * @dev Updates supported interfaces
     * @param _sig - 4-byte interface selector
     * @param _set - State to set for selector
     */
    function updateSupportedInterface(bytes4 _sig, bool _set) external {
        require(msg.sender == gateway.owner(), "ONLY_DEV");
        supportsInterface[_sig] = _set;
        emit UpdateSupportedInterface(_sig, _set);
    }

    /**
     * @dev Add or remove wrapper
     * @param _addr - Address of wrapper
     * @param _set - State to set for wrapper
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
     * @param _token - Token address
     * @param _balance - Amount to release
     */
    function withdraw(address _token, uint256 _balance) external {
        iToken(_token).transferFrom(address(this), gateway.owner(), _balance);
    }

    /**
     * @dev To be used for tips or in case some non-fungible tokens get locked in the contract
     * @param _token - Token address
     * @param _id - Token ID to release
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