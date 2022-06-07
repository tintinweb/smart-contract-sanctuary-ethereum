//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMinter.sol";
import "./INFT.sol";

contract Minter is IMinter, Ownable {
    uint16 public immutable devReserve;
    uint16 public devMinted;
    uint16 public whitelistMinted;
    uint16 public genesisMinted;
    uint256 public publicMintPrice;
    address private _signer;
    address private _panda;
    bool public whitelistMintActive = false;
    bool public publicMintActive = false;
    bool public genesisMintActive = false;

    using ECDSA for bytes32;

    struct MintConf {
        uint16 maxMint;
        uint16 maxPerAddrMint;
        uint256 price;
    }
    MintConf public whitelistMintConf;
    MintConf public genesisMintConf;

    mapping(address => uint16) private _whitelistAddrMinted;
    mapping(address => uint16) private _genesisAddrMinted;

    constructor(address nft_, uint16 devReserve_) {
        _panda = nft_;
        _signer = msg.sender;
        require(
            (devReserve_ * 5 <= _getOverall()),
            "No more than 20% of overall supply"
        );
        devReserve = devReserve_;

        // TODO: need be change for mainnet.
        publicMintPrice = 0.075 ether;
        whitelistMintConf = MintConf(6000, 5, 0.05 ether);
        genesisMintConf = MintConf(500, 1, 0 ether);
    }

    function togglePublicMintStatus() external override onlyOwner {
        publicMintActive = !publicMintActive;
    }

    function toggleWhitelistMintStatus() external override onlyOwner {
        whitelistMintActive = !whitelistMintActive;
    }

    function toggleGenesisMintStatus() external override onlyOwner {
        genesisMintActive = !genesisMintActive;
    }

    /**
     * dev
     */
    function devMint(uint16 quantity, address to) external override onlyOwner {
        _devMint(quantity, to);
    }

    function devMintToMultiAddr(uint16 quantity, address[] calldata addresses)
        external
        override
        onlyOwner
    {
        require(addresses.length > 0, "Invalid addresses");

        for (uint256 i = 0; i < addresses.length; i++) {
            _devMint(quantity, addresses[i]);
        }
    }

    function devMintVaryToMultiAddr(
        uint16[] calldata quantities,
        address[] calldata addresses
    ) external override onlyOwner {
        require(addresses.length > 0, "Invalid addresses");

        require(
            quantities.length == addresses.length,
            "addresses does not match quantities length"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _devMint(quantities[i], addresses[i]);
        }
    }

    /**
     * whitelist
     */
    function setWhitelistMintConf(
        uint16 maxMint,
        uint16 maxPerAddrMint,
        uint256 price
    ) external override onlyOwner {
        require((maxMint <= _getMaxSupply()), "Max supply exceeded");

        whitelistMintConf = MintConf(maxMint, maxPerAddrMint, price);
        emit WhitelistMintConfChanged(maxMint, maxPerAddrMint, price);
    }

    function isWhitelist(string calldata salt, bytes calldata token)
        external
        view
        override
        returns (bool)
    {
        return _isWhitelist(salt, token);
    }

    function whitelistMint(
        uint16 quantity,
        string calldata salt,
        bytes calldata token
    ) external payable override {
        require(whitelistMintActive, "Whitelist mint is not active");

        require(_isWhitelist(salt, token), "Not allowed");

        require(
            whitelistMinted + quantity <= whitelistMintConf.maxMint,
            "Max mint amount exceeded"
        );

        require(
            _whitelistAddrMinted[msg.sender] + quantity <=
                whitelistMintConf.maxPerAddrMint,
            "Max mint amount per account exceeded"
        );

        whitelistMinted += quantity;
        _whitelistAddrMinted[msg.sender] += quantity;
        _batchMint(msg.sender, quantity);
        _refundIfOver(uint256(whitelistMintConf.price) * quantity);
    }

    /**
     * genesisMint
     */
    function setGenesisMintConf(
        uint16 maxMint,
        uint16 maxPerAddrMint,
        uint256 price
    ) external override onlyOwner {
        require((maxMint <= _getMaxSupply()), "Max supply exceeded");

        genesisMintConf = MintConf(maxMint, maxPerAddrMint, price);
        emit GenesisMintConfChanged(maxMint, maxPerAddrMint, price);
    }

    function isGenesis(string calldata salt, bytes calldata token)
        external
        view
        override
        returns (bool)
    {
        return _isGenesis(salt, token);
    }

    function genesisMint(
        uint16 quantity,
        string calldata salt,
        bytes calldata token
    ) external payable override {
        require(genesisMintActive, "Genesis mint is not active");

        require(_isGenesis(salt, token), "Not allowed");

        require(
            genesisMinted + quantity <= genesisMintConf.maxMint,
            "Max mint amount exceeded"
        );

        require(
            _genesisAddrMinted[msg.sender] + quantity <=
                genesisMintConf.maxPerAddrMint,
            "Max mint amount per account exceeded"
        );

        genesisMinted += quantity;
        _genesisAddrMinted[msg.sender] += quantity;
        _batchMint(msg.sender, quantity);
        _refundIfOver(uint256(genesisMintConf.price) * quantity);
    }

    // /**
    //  * publicMint
    //  */
    function setPublicMintPrice(uint256 price) external override onlyOwner {
        publicMintPrice = price;
        emit PublicMintPriceChanged(price);
    }

    function publicMint(uint16 quantity, address to) external payable override {
        require(publicMintActive, "Public mint is not active");
        _batchMint(to, quantity);
        _refundIfOver(uint256(publicMintPrice) * quantity);
    }

    function whitelistAddrMinted(address sender)
        external
        view
        override
        returns (uint16)
    {
        return uint16(_whitelistAddrMinted[sender]);
    }

    function genesisAddrMinted(address sender)
        external
        view
        override
        returns (uint16)
    {
        return uint16(_genesisAddrMinted[sender]);
    }

    function getSigner() external view override returns (address) {
        return _signer;
    }

    function setSigner(address signer_) external override onlyOwner {
        _signer = signer_;
        emit SignerChanged(signer_);
    }

    function withdraw() external override onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function _devMint(uint16 quantity, address to) private {
        require(devMinted + quantity <= devReserve, "Max reserve exceeded");

        devMinted += quantity;
        _batchMint(to, quantity);
    }

    function _batchMint(address to, uint16 quantity) internal {
        require(quantity > 0, "Invalid quantity");
        require(to != address(0), "Mint to the zero address");

        INFT(_panda).mint(to, quantity);
    }

    function _isWhitelist(string memory salt, bytes memory token)
        internal
        view
        returns (bool)
    {
        return _verify(salt, msg.sender, token, "");
    }

    function _isGenesis(string memory salt, bytes memory token)
        internal
        view
        returns (bool)
    {
        return _verify(salt, msg.sender, token, "GENESIS");
    }

    function _verify(
        string memory salt,
        address sender,
        bytes memory token,
        string memory category
    ) internal view returns (bool) {
        return (_recover(_hash(salt, _panda, sender, category), token) ==
            _signer);
    }

    function _recover(bytes32 hash, bytes memory token)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(token);
    }

    function _hash(
        string memory salt,
        address contract_,
        address sender,
        string memory category
    ) internal pure returns (bytes32) {
        if (bytes(category).length == 0)
            return keccak256(abi.encode(salt, contract_, sender));
        return keccak256(abi.encode(salt, contract_, sender, category));
    }

    function _refundIfOver(uint256 spend) private {
        require(msg.value >= spend, "Need to send more ETH");

        if (msg.value > spend) {
            payable(msg.sender).transfer(msg.value - spend);
        }
    }

    function _getMaxSupply() internal returns (uint256) {
        return INFT(_panda).getMaxSupply();
    }

    function _getOverall() internal returns (uint256) {
        return INFT(_panda).getOverall();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
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

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
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

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
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

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMinter {
    event SignerChanged(address signer);
    event WhitelistMintConfChanged(
        uint16 maxMint,
        uint16 maxPerAddrMint,
        uint256 price
    );
    event GenesisMintConfChanged(
        uint16 maxMint,
        uint16 maxPerAddrMint,
        uint256 price
    );
    event PublicMintPriceChanged(uint256 price);

    function toggleWhitelistMintStatus() external;

    function togglePublicMintStatus() external;

    function toggleGenesisMintStatus() external;

    function devMint(uint16 quantity, address to) external;

    function devMintToMultiAddr(uint16 quantity, address[] calldata addresses)
        external;

    function devMintVaryToMultiAddr(
        uint16[] calldata quantities,
        address[] calldata addresses
    ) external;

    function setWhitelistMintConf(
        uint16 maxMint,
        uint16 maxPerAddrMint,
        uint256 price
    ) external;

    function setGenesisMintConf(
        uint16 maxMint,
        uint16 maxPerAddrMint,
        uint256 price
    ) external;

    function isWhitelist(string calldata salt, bytes calldata token)
        external
        returns (bool);

    function isGenesis(string calldata salt, bytes calldata token)
        external
        returns (bool);

    function whitelistMint(
        uint16 quantity,
        string calldata salt,
        bytes calldata token
    ) external payable;

    function genesisMint(
        uint16 quantity,
        string calldata salt,
        bytes calldata token
    ) external payable;

    function setPublicMintPrice(uint256 price) external;

    function publicMint(uint16 quantity, address to) external payable;

    function whitelistAddrMinted(address sender) external view returns (uint16);

    function genesisAddrMinted(address sender) external view returns (uint16);

    function getSigner() external view returns (address);

    function setSigner(address signer) external;

    function withdraw() external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFT {
    event SetMinter(address minter);
    event Revealed(uint256 curTokenId, uint256 tokenId);
    event BaseURIChanged(string uri);
    event NotRevealedURIChanged(string uri);
    event SetMaxSupply(uint256 amount0, uint256 amount1);

    function getMaxSupply() external returns (uint256 amount);

    function getOverall() external returns (uint256 amount);

    function setMaxSupply(uint256 amount) external;

    function setMinter(address minter) external;

    function mint(address to, uint256 quantity) external;

    function setNotRevealedURI(string memory notRevealedURI) external;

    function setBaseURI(string memory uri) external;

    function reveal(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}