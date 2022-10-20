// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Mirror721} from "./Mirror721.sol";
import {SVGUtil} from "./utils/SVGUtil.sol";

contract NFT414 is Mirror721, SVGUtil {
    mapping(uint256 => address) discoverer;

    constructor(
        address _wormhole,
        uint8 _finality,
        uint256 _chains,
        uint16 _prevChain,
        uint16 _nextChain,
        string memory _name,
        string memory _symbol
    )
        Mirror721(
            _wormhole,
            _finality,
            _chains,
            _prevChain,
            _nextChain,
            _name,
            _symbol
        )
    {}

    function tokenURI(uint256 id) public view override returns (string memory) {
        return _manifest(bytes32(id), discoverer[id]);
    }

    function mint(string memory seed) external {
        uint256 id = uint256(keccak256(abi.encodePacked(seed)));
        discoverer[id] = msg.sender;
        _mint(msg.sender, id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ERC721} from "../lib/solmate/src/tokens/ERC721.sol";
import {IWormhole} from "../lib/wormhole/ethereum/contracts/interfaces/IWormhole.sol";
import {Structs} from "../lib/wormhole/ethereum/contracts/Structs.sol";

abstract contract Mirror721 is ERC721 {
    event transferInitiated(uint64 sequence);

    address public immutable wormhole;
    uint8 public immutable finality;

    uint256 public immutable chains;
    uint16 public immutable prevChain;
    uint16 public immutable nextChain;

    mapping(uint256 => address) public processing;
    mapping(uint256 => address) public prevAddr;
    mapping(uint256 => bool) public passed;
    mapping(uint256 => bool) public timestampLock;
    mapping(uint256 => uint256) public lastTimestamp;

    constructor(
        address _wormhole,
        uint8 _finality,
        uint256 _chains,
        uint16 _prevChain,
        uint16 _nextChain,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        wormhole = _wormhole;
        finality = _finality;
        chains = _chains;
        prevChain = _prevChain;
        nextChain = _nextChain;
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        _checkProcessing(from, to, id);
        uint64 sequence = _emitTransfer(from, to, id, 1);
        emit transferInitiated(sequence);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        _checkProcessing(from, to, id);
        uint64 sequence = _emitTransfer(from, to, id, 1);
        emit transferInitiated(sequence);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata /*data*/
    ) public virtual override {
        _checkProcessing(from, to, id);
        uint64 sequence = _emitTransfer(from, to, id, 1);
        emit transferInitiated(sequence);
    }

    function validateTransfer(bytes calldata encodedVM)
        external
        returns (uint64 sequence)
    {
        bytes memory payload = _validateVM(encodedVM, prevChain);

        (address from, address to, uint256 id, uint256 counter) = abi.decode(
            payload,
            (address, address, uint256, uint256)
        );

        if (processing[id] == address(0)) {
            ++counter;
            prevAddr[id] = from;
            delete passed[id];
            super.transferFrom(from, to, id);
            sequence = _emitTransfer(from, to, id, counter);
        } else {
            require(counter == chains);
            require(to == processing[id]);
            prevAddr[id] = from;
            delete processing[id];
            delete timestampLock[id];
            super.transferFrom(from, to, id);
        }
    }

    function validateMint(bytes calldata encodedVM)
        external
        returns (uint64 sequence)
    {
        bytes memory payload = _validateVM(encodedVM, prevChain);

        (address to, uint256 id, uint256 counter) = abi.decode(
            payload,
            (address, uint256, uint256)
        );

        if (processing[id] == address(0)) {
            ++counter;
            passed[id] = true;
            super._mint(to, id);
            sequence = _emitMint(to, id, counter);
        } else {
            require(counter == chains);
            require(to == processing[id]);
            delete processing[id];
            delete timestampLock[id];
            super._mint(to, id);
        }
    }

    function rectify(uint256 id) public virtual returns (uint64 sequence) {
        if (prevAddr[id] != address(0)) {
            address current = _ownerOf[id];
            super.transferFrom(current, prevAddr[id], id);
            prevAddr[id] = current;
        }
        sequence = IWormhole(wormhole).publishMessage(
            1,
            abi.encodePacked(id),
            finality
        );
    }

    function rectifyMint(uint256 id) public virtual returns (uint64 sequence) {
        if (passed[id]) {
            _burn(id);
            delete passed[id];
        }
        sequence = IWormhole(wormhole).publishMessage(
            1,
            abi.encodePacked(id),
            finality
        );
    }

    function rectificationReciever(bytes calldata encodedVM)
        external
        returns (uint64 sequence)
    {
        bytes memory payload = _validateVM(encodedVM, nextChain);

        uint256 id = abi.decode(payload, (uint256));

        if (processing[id] == address(0)) {
            sequence = rectify(id);
        } else {
            require(!timestampLock[id]);
            delete processing[id];
        }
    }

    function rectificationMintReciever(bytes calldata encodedVM)
        external
        returns (uint64 sequence)
    {
        bytes memory payload = _validateVM(encodedVM, nextChain);

        uint256 id = abi.decode(payload, (uint256));

        if (processing[id] == address(0)) {
            sequence = rectifyMint(id);
        } else {
            require(!timestampLock[id]);
            delete processing[id];
        }
    }

    function proveTimestamp(uint256 id) external returns (uint64 sequence) {
        require(processing[id] != address(0));
        sequence = IWormhole(wormhole).publishMessage(
            1,
            abi.encodePacked(id, lastTimestamp[id]),
            finality
        );
    }

    function removeTimestampLock(bytes calldata encodedVM) external {
        (Structs.VM memory vm, bool valid, string memory reason) = IWormhole(
            wormhole
        ).parseAndVerifyVM(encodedVM);

        if (!valid) revert(reason);
        require(address(bytes20(vm.emitterAddress)) == address(this));

        (uint256 id, uint256 timestamp) = abi.decode(
            vm.payload,
            (uint256, uint256)
        );

        require(timestamp < lastTimestamp[id]);
        delete timestampLock[id];
    }

    function _mint(address to, uint256 id) internal virtual override {
        require(processing[id] == address(0));
        processing[id] = to;
        uint64 sequence = _emitMint(to, id, 1);
        emit transferInitiated(sequence);
    }

    function _emitTransfer(
        address from,
        address to,
        uint256 id,
        uint256 counter
    ) internal virtual returns (uint64 sequence) {
        sequence = IWormhole(wormhole).publishMessage(
            1,
            abi.encodePacked(from, to, id, counter),
            finality
        );
    }

    function _emitMint(
        address to,
        uint256 id,
        uint256 counter
    ) internal virtual returns (uint64 sequence) {
        sequence = IWormhole(wormhole).publishMessage(
            1,
            abi.encodePacked(to, id, counter),
            finality
        );
    }

    function _validateVM(bytes calldata encodedVM, uint16 chain)
        internal
        virtual
        returns (bytes memory payload)
    {
        (Structs.VM memory vm, bool valid, string memory reason) = IWormhole(
            wormhole
        ).parseAndVerifyVM(encodedVM);

        if (!valid) revert(reason);

        require(vm.emitterChainId == chain);
        require(address(bytes20(vm.emitterAddress)) == address(this));

        return (vm.payload);
    }

    function _checkProcessing(
        address from,
        address to,
        uint256 id
    ) internal virtual {
        require(from == _ownerOf[id]);
        require(to != address(0));
        require(
            msg.sender == from ||
                isApprovedForAll[from][msg.sender] ||
                msg.sender == getApproved[id]
        );
        require(processing[id] == address(0));
        processing[id] = to;
        lastTimestamp[id] = block.timestamp;
        timestampLock[id] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Base64} from "./Base64.sol";
import {Strings} from "./Strings.sol";

contract SVGUtil {
    using Strings for uint8;
    using Strings for uint160;
    using Strings for uint256;

    string[] elements = [
        "&#8858;",
        "&#8889;",
        "&#164;",
        "&#8942;",
        "&#10070;",
        "&#10696;",
        "&#10803;",
        "&#10811;",
        "&#10057;",
        "&#10023;",
        "&#8762;",
        "&#8790;",
        "&#8853;",
        "&#8915;",
        "&#10773;",
        "&#8578;"
    ];

    function _upper() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg height="310" width="250" xmlns="http://www.w3.org/2000/svg">',
                    "<defs>",
                    '<radialGradient id="myGradient">'
                )
            );
    }

    function _orbital(bytes32 seed, uint8 num)
        internal
        pure
        returns (string memory)
    {
        string memory first = string(
            abi.encodePacked(
                '<stop offset="',
                (5 + num * 20).toString(),
                '%" stop-color="rgb(',
                uint8(seed[0 + (num * 6)]).toString(),
                ",",
                uint8(seed[1 + (num * 6)]).toString(),
                ",",
                uint8(seed[2 + (num * 6)]).toString(),
                ')" />'
            )
        );
        string memory second = string(
            abi.encodePacked(
                '<stop offset="',
                (15 + num * 20).toString(),
                '%" stop-color="rgb(',
                uint8(seed[3 + (num * 6)]).toString(),
                ",",
                uint8(seed[4 + (num * 6)]).toString(),
                ",",
                uint8(seed[5 + (num * 6)]).toString(),
                ')" />'
            )
        );
        return string(abi.encodePacked(first, second));
    }

    function _lower() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "</radialGradient>",
                    "</defs>",
                    '<rect height="310" width="250" fill="#000" rx="20"></rect>'
                )
            );
    }

    function _elements(bytes32 seed) internal view returns (string memory) {
        string memory a = elements[uint8(seed[31]) & 15];
        string memory b = elements[(uint8(seed[31]) & 240) / 16];
        string memory c = elements[uint8(seed[30]) & 15];
        string memory d = elements[(uint8(seed[30]) & 240) / 16];

        return
            string(
                abi.encodePacked(
                    '<text fill="#ffffff" font-size="30" font-family="Verdana" x="12.5%" y="12.5%" text-anchor="middle">',
                    a,
                    "</text>",
                    '<text fill="#ffffff" font-size="30" font-family="Verdana" x="87.5%" y="12.5%" text-anchor="middle">',
                    b,
                    "</text>",
                    '<text fill="#ffffff" font-size="30" font-family="Verdana" x="12.5%" y="77.5%" text-anchor="middle">',
                    c,
                    "</text>",
                    '<text fill="#ffffff" font-size="30" font-family="Verdana" x="87.5%" y="77.5%" text-anchor="middle">',
                    d,
                    "</text>"
                )
            );
    }

    function _power(bytes32 seed) internal pure returns (string memory) {
        uint256 n = uint256(seed);
        uint256 count;
        string memory power;
        assembly {
            for {

            } gt(n, 0) {

            } {
                n := and(n, sub(n, 1))
                count := add(count, 1)
            }
        }
        if (count > 127) {
            power = uint256((count - 128) * 125).toString();
        } else {
            power = uint256((128 - count) * 125).toString();
        }

        return
            string(
                abi.encodePacked(
                    '<text fill="#ffffff" font-size="30" font-family="Verdana" x="50%" y="92.5%" text-anchor="middle">&#937;: ',
                    power,
                    "</text>",
                    '<circle cx="125" cy="125" r="100" fill="url(\'#myGradient\')" />',
                    "</svg>"
                )
            );
    }

    function _getPower(uint256 id) internal pure returns (uint256 power) {
        uint256 count;
        assembly {
            for {

            } gt(id, 0) {

            } {
                id := and(id, sub(id, 1))
                count := add(count, 1)
            }
        }
        if (count > 127) {
            power = uint256((count - 128) * 125);
        } else {
            power = uint256((128 - count) * 125);
        }
    }

    function _particle(bytes32 seed) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _upper(),
                    _orbital(seed, 0),
                    _orbital(seed, 1),
                    _orbital(seed, 2),
                    _orbital(seed, 3),
                    _orbital(seed, 4),
                    _lower(),
                    _elements(seed),
                    _power(seed)
                )
            );
    }

    function _image(bytes32 seed) internal view returns (string memory) {
        string memory image = _particle(seed);
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(image))
                )
            );
    }

    function _manifest(bytes32 seed, address discoverer)
        internal
        view
        returns (string memory)
    {
        string memory image = _image(seed);
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "',
                                uint256(seed).toHexString(),
                                '", "description": "Discovered By: ',
                                uint160(discoverer).toHexString(20),
                                '", "image": "',
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

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
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

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
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
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
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// contracts/Messages.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "../Structs.sol";

interface IWormhole is Structs {
    event LogMessagePublished(address indexed sender, uint64 sequence, uint32 nonce, bytes payload, uint8 consistencyLevel);

    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function parseAndVerifyVM(bytes calldata encodedVM) external view returns (Structs.VM memory vm, bool valid, string memory reason);

    function verifyVM(Structs.VM memory vm) external view returns (bool valid, string memory reason);

    function verifySignatures(bytes32 hash, Structs.Signature[] memory signatures, Structs.GuardianSet memory guardianSet) external pure returns (bool valid, string memory reason) ;

    function parseVM(bytes memory encodedVM) external pure returns (Structs.VM memory vm);

    function getGuardianSet(uint32 index) external view returns (Structs.GuardianSet memory) ;

    function getCurrentGuardianSetIndex() external view returns (uint32) ;

    function getGuardianSetExpiry() external view returns (uint32) ;

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool) ;

    function isInitialized(address impl) external view returns (bool) ;

    function chainId() external view returns (uint16) ;

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function messageFee() external view returns (uint256) ;
}

// contracts/Structs.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

interface Structs {
	struct Provider {
		uint16 chainId;
		uint16 governanceChainId;
		bytes32 governanceContract;
	}

	struct GuardianSet {
		address[] keys;
		uint32 expirationTime;
	}

	struct Signature {
		bytes32 r;
		bytes32 s;
		uint8 v;
		uint8 guardianIndex;
	}

	struct VM {
		uint8 version;
		uint32 timestamp;
		uint32 nonce;
		uint16 emitterChainId;
		bytes32 emitterAddress;
		uint64 sequence;
		uint8 consistencyLevel;
		bytes payload;

		uint32 guardianSetIndex;
		Signature[] signatures;

		bytes32 hash;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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
}