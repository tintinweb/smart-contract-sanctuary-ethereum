//SPDX-License-Identifier: WTFPL.ETH
pragma solidity > 0.8 .0 < 0.9 .0;

/**
 * @author 0xc0de4c0ffee, sshmatrix (BeenSick Labs)
 * @title istest Resolver
 */
contract Resolver {
    
    address public Dev;
    string public chainID = "1"; 

    /// @dev : Error events
    error RequestError();
    error InvalidSignature();
    error InvalidHash();
    error InvalidResponse();
    error SignatureExpired();
    error OffchainLookup(
        address sender, 
        string[] urls, 
        bytes callData,
        bytes4 callbackFunction, 
        bytes extraData
    );

    /// @dev : Interface selector
    function supportsInterface(bytes4 sig) external pure returns(bool) {
        return (sig == Resolver.resolve.selector || sig == Resolver.supportsInterface.selector);
    }

    /// @dev : Emitted events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev : Gateway struct
    struct Gate {
        string domain;
        address operator;
    }
    Gate[] public Gateways;
    mapping(address => bool) public isSigner;

    /**
     * @dev Constructor
     */
    constructor() {
        Dev = msg.sender;
        /// @dev : set initial Gateway here
        Gateways.push(Gate(
            "sshmatrix.club:3002", 
            0xA610E343BA79d93B39421fD6Bf29067e1aC1Aa66
        ));
        isSigner[0xA610E343BA79d93B39421fD6Bf29067e1aC1Aa66] = true;
    }

    /**
     * @dev custom DNSDecode() function [see ENSIP-10]
     * @param encoded : encoded byte string
     * @return _name : name to resolve on testnet
     * @return namehash : hash of name to resolve on testnet
     */
    function DNSDecode(bytes calldata encoded) public pure returns(string memory _name, bytes32 namehash) {
        uint j;
        uint len;
        bytes[] memory labels = new bytes[](12); // max 11 ...bob.alice.istest.eth
        for (uint i; encoded[i] > 0x0;) {
            len = uint8(bytes1(encoded[i: ++i]));
            labels[j] = encoded[i: i += len];
            j++;
        }
        _name = string(labels[--j]); // 'eth' label
        namehash = keccak256(abi.encodePacked(bytes32(0), keccak256(labels[j--]))); // hash of 'eth'
        if (j == 0) // istest.eth
            return (
                string.concat(string(labels[0]), ".", _name),
                keccak256(abi.encodePacked(namehash, keccak256(labels[0])))
            );

        while (j > 0) { // return ...bob.alice.eth
            _name = string.concat(string(labels[--j]), ".", _name); // pop 'istest' label
            namehash = keccak256(abi.encodePacked(namehash, keccak256(labels[j]))); // hash without 'istest' label
        }
    }

    /**
     * @dev selects and construct random gateways for CCIP resolution
     * @param _name : name to resolve on testnet e.g. alice.eth
     * @return urls : ordered list of gateway URLs for HTTPS calls
     */
    function randomGateways(string memory _name) public view returns(string[] memory urls) {
        uint gLen = Gateways.length;
        uint len = (gLen / 2) + 1;
        if (len > 5) len = 5;
        urls = new string[](len);
        uint k = block.timestamp;
        for (uint i; i < len; i++) {
            // random seeding
            k = uint(keccak256(abi.encodePacked(k, _name, msg.sender, blockhash(block.number - 1)))) % gLen; 
            // Gateway @ URL e.g. https://example.xyz/eip155:1/alice.eth/{data}
            urls[i] = string.concat("https://", Gateways[k].domain, "/eip155", ":", chainID, '/', _name, "/{data}"); 
        }
    }

    /**
     * @dev resolves a name with CCIP-Read OffChainLookup()
     * @param encoded : byte-encoded mainnet name e.g. alice.istest.eth
     * @param data : CCIP call data
     */
    function resolve(bytes calldata encoded, bytes calldata data) external view returns(bytes memory) {
        (string memory _name, bytes32 namehash) = DNSDecode(encoded);
        revert OffchainLookup(
            address(this), // sender/callback contract 
            randomGateways(_name), // gateway URL array
            bytes.concat( // custom callData {data} [see ENSIP-10] + encoded name for eth_call by HTTP gateway
                data[:4],
                namehash,
                data.length > 36 ? data[36: ] : bytes("")
            ),
            Resolver.__callback.selector, // callback function 
            abi.encode( // callback extradata
                block.number,
                namehash,
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        namehash,
                        msg.sender
                    )
                )
            )
        );
    }

    /**
     * @dev CCIP callback function
     * @param response : response of HTTP call
     * @param extraData : call data for callback function
     */
    function __callback(
        bytes calldata response,
        bytes calldata extraData
    ) external view returns(bytes memory) {
        /// decode extraData
        (uint blocknum, 
        bytes32 namehash, 
        bytes32 _hash) = abi.decode(extraData, (uint, bytes32, bytes32));
        /// check hash & timeout @ 3 blocks
        if (block.number > blocknum + 3 || _hash != keccak256(abi.encodePacked(blockhash(blocknum - 1), namehash, msg.sender)))
            revert InvalidHash();
        /// decode signature
        (uint64 _validity,
        bytes memory _signature,
        bytes memory _result) = abi.decode(response, (uint64, bytes, bytes));
        /// check null HTTP response 
        if (bytes1(_result) == bytes1(bytes('0x0'))) revert InvalidResponse();
        /// check signature expiry
        if (block.timestamp > _validity) revert SignatureExpired();
        /// check signature content
        if (!Resolver(address(this)).isValid(
                keccak256(
                    abi.encode(
                        hex'1900',
                        address(this),
                        _validity,
                        namehash,
                        _result
                    )
                ),
                _signature
            )) revert InvalidSignature();
        return _result;
    }

    /**
     * @dev checks if a signature is valid
     * @param hash : hash of signed message
     * @param signature : signature to verify
     */
    function isValid(bytes32 hash, bytes calldata signature) external view returns(bool) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (signature.length > 64) {
            r = bytes32(signature[:32]);
            s = bytes32(signature[32:]);
            v = uint8(bytes1(signature[64]));
        } else {
            r = bytes32(signature[:32]);
            bytes32 vs = bytes32(signature[32:]);
            s = vs & bytes32(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            v = uint8((uint256(vs) >> 255) + 27);
        }
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0)
            revert InvalidSignature();
        address _signer = ecrecover(hash, v, r, s);
        return (_signer != address(0) && isSigner[_signer]);
    }

    /// @dev : GATEWAY MANAGEMENT
    modifier onlyDev() {
        require(msg.sender == Dev);
        _;
    }
    
    /**
     * @dev add gateway to the list
     * @param operator : controller of gateway
     * @param domain : gateway domain
     */
    function addGateway(address operator, string calldata domain) external onlyDev {
        require(!isSigner[operator], "OPERATOR_EXISTS");
        Gateways.push(Gate(
            domain,
            operator
        ));
        isSigner[operator] = true;
    }

     /**
     * @dev remove gateway from the list
     * @param _index : gateway index to remove
     */
    function removeGateway(uint _index) external onlyDev {
        isSigner[Gateways[_index].operator] = false;
        unchecked {
            if (Gateways.length > _index + 1)
                Gateways[_index] = Gateways[Gateways.length - 1];
        }
        Gateways.pop();
    }

    /**
     * @dev replace gateway for a given controller
     * @param _index : gateway index to replace
     * @param operator : controller of gateway
     * @param domain : new gateway domain
     */
    function replaceGateway(uint _index, address operator, string calldata domain) external onlyDev {
        require(!isSigner[operator], "DUPLICATE_OPERATOR");
        isSigner[Gateways[_index].operator] = false;
        Gateways[_index] = Gate(domain, operator);
        isSigner[operator] = true;
    }

    /**
     * @dev : transfer contract ownership to new Dev
     * @param newDev : new Dev
     */
    function changeDev(address newDev) external onlyDev {
        emit OwnershipTransferred(Dev, newDev);
        Dev = newDev;
    }
}