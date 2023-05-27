// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.18 <0.9.0;

import "./Interface.sol";

/**
 * @title - Standalone ENS Resolver as Web3 IPFS Gateway
 * @author - freetib.eth, sshmatrix.eth
 */
contract IPFS2ETH is iCCIP, iERC165, iERC173 {
    address public owner;
    address public ccip2eth;
    bytes11 public immutable nameCheck = bytes11(abi.encodePacked(uint8(5), "ipfs2", uint8(3), "eth", uint8(0)));

    /// @dev - Default contenthash for error page
    bytes public DefaultContenthash;

    //bytes11 public immutable nameCheck = bytes11(abi.encodePacked(uint8(5), "ipfs2", uint8(3), "eth", uint8(0)));

    /// @dev - Revert on fallback
    fallback() external payable {
        revert("NOT_SUPPORTED");
    }

    /// Events
    event ThankYou(address indexed _from, uint256 indexed _value);

    /// @dev - Accept donations/tips to the contract address
    receive() external payable {
        emit ThankYou(msg.sender, msg.value);
    }

    /**
     * @dev Interface Selector
     * @param interfaceID - interface identifier
     */
    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return (
            interfaceID == iCCIP.resolve.selector || interfaceID == type(iERC173).interfaceId
                || interfaceID == iERC165.supportsInterface.selector
        );
    }

    /// @dev Constructor; initial setup
    constructor() {
        owner = msg.sender;
        DefaultContenthash = hex"e5010172002408011220af515a0a0a94e818e295e9a1b784184d9524c1744efbc20b4a70971c7bbd6b2d";
    }

    /**
     * @dev EIP-2544/EIP-3668 core resolve() function; aka CCIP-Read
     * @param name - ENS name to resolve; must be DNS encoded
     * @param data - data encoding specific function to resolve
     * @return result - triggers Off-chain Lookup; return value is stashed
     */
    function resolve(bytes calldata name, bytes calldata data) external view returns (bytes memory result) {
        unchecked {
            bytes4 func = bytes4(data[:4]);
            uint256 len = name.length;
            if (len < 42) {
                if (iERC165(ccip2eth).supportsInterface(iCCIP.resolve.selector)) {
                    return iCCIP(ccip2eth).resolve(name, data);
                } else if (iERC165(ccip2eth).supportsInterface(func)) {
                    bool ok;
                    (ok, result) = ccip2eth.staticcall(data);
                    if (ok && result.length > 0) {
                        return abi.encode(result);
                    }
                }
                if (func == iResolver.contenthash.selector) {
                    return abi.encode(DefaultContenthash);
                }
                revert("RECORD_NOT_SET");
            } else if (func != iResolver.contenthash.selector) {
                revert("NOT_SUPPORTED");
            }
            bytes1 prefix = bytes1(name[1]);
            uint256 ptr = uint8(name[0]) + 1;

            uint256 n = 1; // n-th index
            ptr = uint8(bytes1(name[0])); // pointer/length
            if (prefix == bytes1("k") || prefix == bytes1("f") || bytes2(name[1:3]) == bytes2("ba")) {
                result = name[2:n += ptr];
            } else {
                result = name[1:n += ptr];
            }
            len -= 11; // skip encoded ipfs2.eth
            while (n < len) {
                ptr = uint8(bytes1(name[n:++n]));
                result = bytes.concat(result, name[n:n += ptr]);
            }
            if (prefix == bytes1("k")) {
                result = decodeBase36(result);
            } else if (bytes2(name[1:3]) == bytes2("ba")) {
                result = decodeBase32(result);
            } else {
                result = hexStringToBytes(result);
            }
            prefix = result[1];
            if (prefix == 0x72) {
                //IPNS, libp2p-key
                prefix = 0xe5;
            } else if (prefix == 0x70 || prefix == 0x55) {
                //IPFS, dag-pb/raw
                prefix = 0xe3;
            } else if (prefix == 0x71) {
                //?IPLD, dag-cbor only
                prefix = 0xe2;
            } else {
                return abi.encode(result);
            }
            return abi.encode(abi.encodePacked(prefix, uint8(1), result));
        }
    }

    /// @dev - Decoder functions
    /// @notice - Decoders won't revert for bad char in input; GIGO

    /**
     * @dev Converts a hexadecimal string input to a bytes array output. The input string length must be an even number, and each byte of the output corresponds to two hexadecimal characters of the input string.
     * @param input - hex value to convert to bytes
     */
    function hexStringToBytes(bytes memory input) public pure returns (bytes memory output) {
        require(input.length % 2 == 0, "BAD_LENGTH");
        uint8 a;
        uint8 b;
        uint256 c;
        unchecked {
            uint256 len = input.length / 2;
            output = new bytes(len);
            while (c < len) {
                b = uint8(input[2 * c]) - 48;
                a = (b < 10) ? b : b - 39;
                b = uint8(input[2 * c + 1]) - 48;
                output[c++] = bytes1((a * 16) + ((b < 10) ? b : b - 39));
            }
        }
    }

    /**
     * @dev Decodes an input byte array in base32 format into a byte array in binary format. The function takes a byte array as input, iterates over each byte, and constructs a binary output byte by byte. The binary output is then returned.
     * @param input - base32 value to decode
     */
    function decodeBase32(bytes memory input) public pure returns (bytes memory output) {
        uint256 value;
        uint256 bits;
        uint256 index;
        uint256 len = input.length;
        uint8 b;
        unchecked {
            output = new bytes((len * 5) / 8);
            for (uint256 i; i < len; ++i) {
                b = uint8(input[i]) - 97;
                value = (value << 5) | ((b < 27) ? b : b + 73);
                bits += 5;
                if (bits > 7) {
                    output[index++] = bytes1(uint8(value >> (bits -= 8)));
                }
            }
            return output;
        }
    }

    /**
     * @dev Decodes a base-36 string input into a bytes output. The function iterates through each character of the input string and converts it to an integer between 0 and 35 based on its ASCII code. It then performs arithmetic operations to decode the input and generate the output bytes.
     * @param input - base36 value to decode
     */
    function decodeBase36(bytes memory input) public pure returns (bytes memory output) {
        uint256 slen = input.length;
        uint256 carry;
        uint256 index;
        uint256 len;
        uint8 b;
        unchecked {
            for (uint256 i; i < slen;) {
                b = uint8(input[i++]) - 48;
                carry = b < 10 ? b : b - 39;
                len = output.length;
                for (uint256 j = 0; j < len; j++) {
                    // TODO: Optimize loop steps, ~500k view gas is too much
                    index = len - 1 - j;
                    carry = uint256(uint8(output[index])) * 36 + carry;
                    output[index] = bytes1(uint8(carry));
                    carry = carry >> 8;
                }
                if (carry > 0) {
                    output = bytes.concat(bytes1(uint8(carry)), output);
                }
            }
        }
    }

    /// Helper/Management functions
    /**
     * @dev Transfers ownership of current contract
     * @param _newOwner - new contract owner
     */
    function transferOwnership(address _newOwner) external {
        require(msg.sender == owner, "NOT_AUTHORISED");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /**
     * @dev Sets new default contenthash
     * @param _contenthash - new value to set as default
     */
    function setContenthash(bytes calldata _contenthash) external {
        require(msg.sender == owner, "NOT_AUTHORISED");
        DefaultContenthash = _contenthash;
    }

    /**
     * @dev Sets CCIP2 coordinate
     * @param _ccip2eth - address of CCIP2.eth Resolver
     */
    function setCCIP2Contract(address _ccip2eth) external {
        require(msg.sender == owner, "NOT_AUTHORISED");
        ccip2eth = _ccip2eth;
    }

    /**
     * @dev Withdraw Ether to owner; to be used for tips or in case some Ether gets locked in the contract
     */
    function withdraw() external {
        payable(owner).transfer(address(this).balance);
    }

    /**
     * @dev To be used for tips or in case some fungible tokens get locked in the contract
     * @param _token - token address
     * @param _balance - amount to release
     */
    function withdraw(address _token, uint256 _balance) external {
        iToken(_token).transferFrom(address(this), owner, _balance);
    }

    /**
     * @dev To be used for tips or in case some non-fungible tokens get locked in the contract
     * @param _token - token address
     * @param _id - token ID to release
     */
    function safeWithdraw(address _token, uint256 _id) external {
        iToken(_token).safeTransferFrom(address(this), owner, _id);
    }
}

//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.18 <0.9.0;

interface iERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface iCCIP {
    function resolve(bytes memory name, bytes memory data) external view returns (bytes memory);
}

interface iResolver {
    function contenthash(bytes32 node) external view returns (bytes memory);
    function setContenthash(bytes32 node, bytes calldata _ch) external view returns (bytes memory);
}

interface iToken {
    function transferFrom(address from, address to, uint256 bal) external;
    function safeTransferFrom(address from, address to, uint256 bal) external;
}

interface iERC173 {
    function owner() external view returns (address);
    function transferOwnership(address _newOwner) external;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}