// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./utils/Ownable.sol";
import "./utils/ECDSA.sol";
import "./utils/EIP712.sol";

contract PantherNft is ERC721, EIP712, Ownable {
    string public baseURI;
    uint96 public royaltyFeesInBips;
    address public royaltyAddress;
    bool public publicAllowed = false;
    uint120 public MAX_SUPPLY = 1000;
    uint256 public mintCost;
    string private constant SIGNING_DOMAIN = "PANTHER_CON";
    string private constant SIGNATURE_VERSION = "1";
    address private signAddress;
    bool pauseMint = false;
    uint256 private supplyLeft = 1000;

    mapping(uint256 => uint256) private randNumber;
    mapping(address => bool) public availed;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _base,
        uint256 mint_cost,
        uint96 _fees,
        address _signAddress
    ) ERC721(_name, _symbol) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        baseURI = _base;
        require(_fees <= 10000, "cannot exceed 10000");
        royaltyFeesInBips = _fees;
        royaltyAddress = msg.sender;
        mintCost = mint_cost;
        signAddress = _signAddress;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getChainId() public view returns (uint256) {
        return block.chainid;
    }

    function setSignAddress(address _signAddress) external onlyOwner {
        signAddress = _signAddress;
    }

    function setMintCost(uint256 val) external onlyOwner {
        mintCost = val;
    }

    function setPauseMint(bool val) external onlyOwner {
        pauseMint = val;
    }

    function mintWhitelist(uint256 val, bytes memory signature) public payable {
        require(pauseMint == false, "Minting is paused");
        uint256 q = supplyLeft;
        require(supplyLeft >= 1, "Max supply reached");
        unchecked {
            supplyLeft--;
        }
        require(val <= 10000, "MAX DISCOUNT IS 10000");
        require(
            check(msg.sender, val, signature) == signAddress,
            "Invalid signature"
        );
        unchecked {
            _balanceOf[msg.sender]++;
        }
        if (val > 0) {
            bool flag = availed[msg.sender];
            availed[msg.sender] = true;
            require(flag == false, "Discount already applied");
        }
        if (val < 10000) {
            uint256 toPay = ((10000 - val) * (mintCost)) / 10000;
            require(msg.value >= toPay, "Not engough eth");
        }
        if (val == 0) {
            require(msg.value >= mintCost, "Not engough eth");
        }
        uint256 id = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    block.timestamp,
                    q,
                    block.difficulty
                )
            )
        ) % q;

        unchecked {
            id++;
        }

        if (randNumber[id] == 0) {
            require(ownerOf[id] == address(0), "Already minted");
            ownerOf[id] = msg.sender;
            if (randNumber[q] == 0) {
                randNumber[id] = q;
            } else {
                randNumber[id] = randNumber[q];
            }
            emit Transfer(address(0), msg.sender, id);
        } else {
            uint256 v = randNumber[id];
            require(ownerOf[v] == address(0), "Already minted");
            ownerOf[v] = msg.sender;
            if (randNumber[q] == 0) {
                randNumber[id] = q;
            } else {
                randNumber[id] = randNumber[q];
            }
            emit Transfer(address(0), msg.sender, v);
        }
    }

    function check(
        address to,
        uint256 val,
        bytes memory signature
    ) public view returns (address) {
        return _verify(to, val, signature);
    }

    function _verify(
        address to,
        uint256 val,
        bytes memory signature
    ) internal view returns (address) {
        bytes32 digest = _hash(to, val);
        return ECDSA.recover(digest, signature);
    }

    function _hash(address to, uint256 val) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("PantherStruct(address to,uint256 val)"),
                        to,
                        val
                    )
                )
            );
    }

    function mintOwner(address to, uint256 id) external onlyOwner {
        uint256 q = supplyLeft;
        require(id <= q, "Id out of range");
        require(supplyLeft >= 1, "Max supply reached");
        unchecked {
            supplyLeft--;
        }
        unchecked {
            _balanceOf[to]++;
        }
        if (randNumber[id] == 0) {
            require(ownerOf[id] == address(0), "Already minted");
            ownerOf[id] = to;
            if (randNumber[q] == 0) {
                randNumber[id] = q;
            } else {
                randNumber[id] = randNumber[q];
            }
            emit Transfer(address(0), to, id);
        } else {
            uint256 v = randNumber[id];
            require(ownerOf[v] == address(0), "Already minted");
            ownerOf[v] = to;
            if (randNumber[q] == 0) {
                randNumber[id] = q;
            } else {
                randNumber[id] = randNumber[q];
            }
            emit Transfer(address(0), to, v);
        }
    }

    function mintPublic(address to) public payable {
        require(pauseMint == false, "Minting is paused");
        require(msg.value > (mintCost - 1), "Not engough eth");
        require(publicAllowed, "Open minting not allowed");
        uint256 q = supplyLeft;
        require(supplyLeft >= 1, "Max supply reached");
        unchecked {
            supplyLeft--;
        }

        uint256 id = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    block.timestamp,
                    block.difficulty,
                    q
                )
            )
        ) % q;

        unchecked {
            id++;
        }

        if (randNumber[id] == 0) {
            require(ownerOf[id] == address(0), "Already minted");
            ownerOf[id] = to;
            if (randNumber[q] == 0) {
                randNumber[id] = q;
            } else {
                randNumber[id] = randNumber[q];
            }
            emit Transfer(address(0), to, id);
        } else {
            uint256 v = randNumber[id];
            require(ownerOf[v] == address(0), "Already minted");
            ownerOf[v] = to;
            if (randNumber[q] == 0) {
                randNumber[id] = q;
            } else {
                randNumber[id] = randNumber[q];
            }
            emit Transfer(address(0), to, v);
        }
        unchecked {
            _balanceOf[to]++;
        }
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256)
    {
        return (royaltyAddress, calculateRoyalty(_salePrice));
    }

    function setPublicMint(bool _status) external onlyOwner {
        publicAllowed = _status;
    }

    function setRoyaltyInfo(address _royaltyAddress, uint96 _royaltyFeesInBips)
        external
        onlyOwner
    {
        require(_royaltyFeesInBips <= 10000, "cannot exceed 10000");
        royaltyAddress = _royaltyAddress;
        royaltyFeesInBips = _royaltyFeesInBips;
    }

    function calculateRoyalty(uint256 _salePrice)
        public
        view
        returns (uint256)
    {
        return (_salePrice / 10000) * royaltyFeesInBips;
    }

    function withdrawEth() external onlyOwner {
        address payable own = payable(owner());
        (bool success, ) = payable(own).call{value: address(this).balance}("");
        require(success, "Transaction failed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(
            typeHash,
            hashedName,
            hashedVersion
        );
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (
            address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID
        ) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return
                _buildDomainSeparator(
                    _TYPE_HASH,
                    _HASHED_NAME,
                    _HASHED_VERSION
                );
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash)
        internal
        view
        virtual
        returns (bytes32)
    {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "./Strings.sol";

library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    function tryRecover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address, RecoverError)
    {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;

            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;

            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs &
            bytes32(
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function toEthSignedMessageHash(bytes memory s)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    Strings.toString(s.length),
                    s
                )
            );
    }

    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransfered(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_msgSender() == owner(), "Caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Owner cannot be zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner();
        _owner = newOwner;
        emit OwnershipTransfered(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC721.sol";
import "./utils/ERC165.sol";
import "./utils/IERC721Metadata.sol";
import "./utils/Address.sol";
import "./utils/Strings.sol";
import "./utils/Context.sol";

interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721 is Context {
    using Strings for uint256;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
            interfaceId == 0x2a55205a; //For Royalty
    }

    string public name;

    string public symbol;

    mapping(address => uint256) internal _balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(uint256 => uint256) public tokenType;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        require(_exists(tokenId), "No token with this Id exists");

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf[tokenId];
        return owner != address(0);
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function balanceOf(address _acc) public view returns (uint256) {
        return _balanceOf[_acc];
    }

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender],
            "Not authorized"
        );

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
        require(from == ownerOf[id], "WRONG FROM");

        require(to != address(0), "WRONG TO");

        require(
            msg.sender == from ||
                isApprovedForAll[from][msg.sender] ||
                msg.sender == getApproved[id],
            "NOT AUTHORIZED"
        );

        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
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
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    ""
                ) ==
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
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _mint(
        address to,
        uint256 id,
        uint8 tknType
    ) internal virtual {
        require(to != address(0), "INVALID_TO");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        unchecked {
            _balanceOf[to]++;
        }

        ownerOf[id] = to;
        tokenType[id] = tknType;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];
        require(msg.sender == owner, "NOT_PERMITED");
        require(owner != address(0), "NOT_MINTED");

        delete ownerOf[id];
        delete getApproved[id];

        emit Transfer(msg.sender, address(0), id);
    }

    // function _safeMint(address to, uint256 id) internal virtual {
    //     _mint(to, id);

    //     require(
    //         to.code.length == 0 ||
    //             ERC721TokenReceiver(to).onERC721Received(
    //                 msg.sender,
    //                 address(0),
    //                 id,
    //                 ""
    //             ) ==
    //             ERC721TokenReceiver.onERC721Received.selector,
    //         "UNSAFE_RECIPIENT"
    //     );
    // }

    // function _safeMint(
    //     address to,
    //     uint256 id,
    //     bytes memory data
    // ) internal virtual {
    //     _mint(to, id);

    //     require(
    //         to.code.length == 0 ||
    //             ERC721TokenReceiver(to).onERC721Received(
    //                 msg.sender,
    //                 address(0),
    //                 id,
    //                 data
    //             ) ==
    //             ERC721TokenReceiver.onERC721Received.selector,
    //         "UNSAFE_RECIPIENT"
    //     );
    // }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.7;


library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

   
    function toString(uint256 value) internal pure returns (string memory) {
         

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library Address{

    function isContract(address account) internal view returns(bool){
        return account.code.length > 0;
    }

    function sendValue(address payable recepient , uint amount) internal{
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recepient.call{value:amount}("");
        require(success,"transaction failed");

    }
}

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.7;

import "../IERC721.sol";

interface IERC721Metadata is IERC721{

    function name() external view returns(string memory);

    function symbol() external view returns(string memory);

    function tokenURI(uint tokenId) external view returns(string memory);


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IERC165.sol";

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./utils/IERC165.sol";

interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

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

    function getApproved(uint256 tokenId) external view returns (address);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}