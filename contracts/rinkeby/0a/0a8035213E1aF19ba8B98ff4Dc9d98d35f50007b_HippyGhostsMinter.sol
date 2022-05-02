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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
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
pragma solidity 0.8.11;

/**
 *   _    _ _____ _____  _______     __   _____ _    _  ____   _____ _______ _____
 *  | |  | |_   _|  __ \|  __ \ \   / /  / ____| |  | |/ __ \ / ____|__   __/ ____|
 *  | |__| | | | | |__) | |__) \ \_/ /  | |  __| |__| | |  | | (___    | | | (___
 *  |  __  | | | |  ___/|  ___/ \   /   | | |_ |  __  | |  | |\___ \   | |  \___ \
 *  | |  | |_| |_| |    | |      | |    | |__| | |  | | |__| |____) |  | |  ____) |
 *  |_|  |_|_____|_|    |_|      |_|     \_____|_|  |_|\____/|_____/   |_| |_____/
 *
 * Total 9999 Hippy Ghosts
 * ----------------------------------------------------------------------------
 * 1 |  180 | [   1, 180] | kept for team
 * 2 | 1320 | [ 181,1500] | private mint, 320 for team, 1000 for community
 * 3 | 8499 | [1501,9999] | public mint, release 300 ghosts every 40000 blocks
 * ----------------------------------------------------------------------------
 */

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/SignatureVerification.sol";

contract HippyGhostsMinter is Ownable {

    /****************************************
     * Variables
     ****************************************/

    address public immutable hippyGhosts;

    /**
     * @dev Ether value for each token in public mint
     */
    uint256 public publicMintPriceUpper = 0.08 ether;
    uint256 public publicMintPriceLower = 0.04 ether;
    uint256 public publicMintPriceDecay = 0.01 ether;

    /**
     * @dev Starting block and inverval for public mint
     */
    uint256 public publicMintStartBlock = 0;
    uint256 public EPOCH_BLOCKS = 40000;
    uint256 public GHOSTS_PER_EPOCH = 300;

    /**
     * @dev Index and upper bound for mint
     */
    // general
    uint256 public constant MAX_GHOSTS_PER_MINT = 10;
    // team
    uint256 public ownerMintCount = 0;
    uint256 public constant MAX_OWNER_MINT_COUNT = 300;
    // private
    uint256 public privateMintIndex = 180;
    uint256 public constant MAX_PRIVATE_MINT_INDEX = 1500;
    // public
    uint256 public publicMintIndex = 1500;
    uint256 public constant MAX_PUBLIC_MINT_INDEX = 9999;

    /**
     * @dev Public address used to sign function calls parameters
     */
    address public verificationAddress;

    /**
     * @dev Key(address) mapping to a claimed key.
     * Used to prevent address from rebroadcasting mint transactions
     */
    mapping(address => bool) private _claimedMintKeys;

    /****************************************
     * Events
     ****************************************/

    /**
     * @dev provide feedback on mint key used for signed mints
     */
    event MintKeyClaimed(
        address indexed claimer,
        address indexed mintKey,
        uint256 numberOfTokens
    );


    /****************************************
     * Functions
     ****************************************/

    constructor(
        address hippyGhosts_,
        address verificationAddress_
    ) {
        hippyGhosts = hippyGhosts_;
        verificationAddress = verificationAddress_;
    }

    receive() external payable {}

    /* config functions */

    function setPublicMintStartBlock(uint256 publicMintStartBlock_) external onlyOwner {
        require(publicMintStartBlock == 0, "publicMintStartBlock has already been set");
        publicMintStartBlock = publicMintStartBlock_;
    }

    function setVerificationAddress(address verificationAddress_) external onlyOwner {
        verificationAddress = verificationAddress_;
    }

    function isMintKeyClaimed(address mintKey) external view returns (bool) {
        return _claimedMintKeys[mintKey];
    }

    /* private mint functions */

    function ownerMint(
        address[] calldata addresses,
        uint256[] calldata tokenIds
    ) external onlyOwner {
        ownerMintCount = ownerMintCount + tokenIds.length;
        require(ownerMintCount <= MAX_OWNER_MINT_COUNT, "Not enough ghosts remaining to mint");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] <= MAX_PRIVATE_MINT_INDEX, "Incorrect tokenId to mint");
            IHippyGhosts(hippyGhosts).mint(addresses[i], tokenIds[i]);
        }
    }

    function mintWithSignature(
        uint256 numberOfTokens,
        uint256 valueInWei,
        address mintKey,
        bytes memory signature
    ) external payable {
        require(valueInWei == msg.value, "Incorrect ether value sent");
        require(_claimedMintKeys[mintKey] == false, "Mint key already claimed");

        SignatureVerification.requireValidSignature(
            abi.encodePacked(msg.sender, numberOfTokens, valueInWei, mintKey, this),
            signature,
            verificationAddress
        );

        _claimedMintKeys[mintKey] = true;
        emit MintKeyClaimed(msg.sender, mintKey, numberOfTokens);

        for (uint256 i = 0; i < numberOfTokens; i++) {
            bool success = false;
            bytes memory result;
            while (!success) {
                // count to next index before minting
                privateMintIndex = privateMintIndex + 1;
                require(privateMintIndex <= MAX_PRIVATE_MINT_INDEX, "Incorrect tokenId to mint");
                (success, result) = hippyGhosts.call(
                    abi.encodeWithSignature("mint(address,uint256)", msg.sender, privateMintIndex)
                );
                // Mint will fail ONLY when tokenId is taken
            }
        }
    }

    /* public mint functions */

    /**
     *  @dev Epoch number start from 1, will increase every [EPOCH_BLOCKS] blocks
     */
    function currentEpoch() public view returns (uint256) {
        if (publicMintStartBlock == 0 || block.number < publicMintStartBlock) {
            return 0;
        }
        uint256 epoches = (block.number - publicMintStartBlock) / EPOCH_BLOCKS;
        return epoches + 1;
    }

    function epochOfToken(uint256 tokenId) public view returns (uint256) {
        require(tokenId > MAX_PRIVATE_MINT_INDEX, "Invalid tokenId");
        uint256 epoches = (tokenId - MAX_PRIVATE_MINT_INDEX - 1) / GHOSTS_PER_EPOCH;
        // assert(epoches >= 0);  // not necessary
        return epoches + 1;
    }

    function availableForPublicMint() public view returns (uint256) {
        uint256 released = GHOSTS_PER_EPOCH * currentEpoch();
        if (released > MAX_PUBLIC_MINT_INDEX - MAX_PRIVATE_MINT_INDEX) {
            released = MAX_PUBLIC_MINT_INDEX - MAX_PRIVATE_MINT_INDEX;
        }
        uint256 ghostsMintedInPublic = publicMintIndex - MAX_PRIVATE_MINT_INDEX;
        return released - ghostsMintedInPublic;
    }

    function priceForTokenId(uint256 tokenId) public view returns (uint256) {
        return priceForTokenId(currentEpoch(), epochOfToken(tokenId));
    }

    function priceForTokenId(uint256 _currentEpoch, uint256 _tokenEpoch) public view returns (uint256) {
        require(_currentEpoch >= _tokenEpoch, "Target epoch is not open");
        uint256 price = publicMintPriceUpper - (_currentEpoch - _tokenEpoch) * publicMintPriceDecay;
        if (price < publicMintPriceLower) {
            price = publicMintPriceLower;
        }
        return price;
    }

    function mint(uint256 numberOfTokens) external payable {
        uint256 _currentEpoch = currentEpoch();
        require(_currentEpoch > 0, "Public sale is not open");
        require(numberOfTokens <= MAX_GHOSTS_PER_MINT, "Max ghosts to mint is ten");
        require(publicMintIndex + numberOfTokens <= MAX_PUBLIC_MINT_INDEX, "Not enough ghosts remaining to mint");
        uint256 _etherValue = msg.value;
        uint256 tokenId;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            tokenId = publicMintIndex + i + 1;
            uint256 _tokenEpoch = epochOfToken(tokenId);
            uint256 price = priceForTokenId(_currentEpoch, _tokenEpoch);
            // require(_etherValue >= price, "Ether value not enough");  // not necessary, `uint` will raise error
            _etherValue = _etherValue - price;
            IHippyGhosts(hippyGhosts).mint(msg.sender, tokenId);
        }
        publicMintIndex = tokenId;
        if (_etherValue > 0) {
            payable(msg.sender).transfer(_etherValue);
        }
    }

    /* withdraw from contract */

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function selfDestruct() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}

interface IHippyGhosts {
    function mint(address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library SignatureVerification {
    using ECDSA for bytes32;

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol
    // https://docs.soliditylang.org/en/v0.8.4/solidity-by-example.html?highlight=ecrecover#the-full-contract

    /**
     * @dev Performs address recovery on data and signature. Compares recovred address to varification address.
     * @param data Packed data used for signature generation
     * @param signature Signature for the provided data
     * @param verificationAddress Address to compare to recovered address
     */
    function requireValidSignature(
        bytes memory data,
        bytes memory signature,
        address verificationAddress
    ) internal pure {
        require(
            verificationAddress != address(0),
            "verification address not initialized"
        );

        require(
            keccak256(data).toEthSignedMessageHash().recover(signature) ==
                verificationAddress,
            "signature invalid"
        );
    }
}