// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC721A.sol";

interface IJuice {
	function ownerOf(uint256 tokenId) external view returns (address owner);

	function burn(uint256 tokenId) external;
}

contract CloneMachine is ERC721A, Ownable, Pausable, ReentrancyGuard {
	using Address for address;
	using Strings for uint256;
	using ECDSA for bytes32;

	uint256 private constant NONE = 0;
	uint256 private constant CAT = 1;
	uint256 private constant RAT = 2;
	uint256 private constant PIGEON = 3;
	uint256 private constant DOG = 4;

	IJuice private juiceContract;
	address private gutterCats;
	address private gutterRats;
	address private gutterPigeons;
	address private gutterDogs;

	address private signerAddress;
	bool public upgradeIsLive = false;

	mapping(uint256 => bool) public usedCats;
	mapping(uint256 => bool) public usedRats;
	mapping(uint256 => bool) public usedPigeons;
	mapping(uint256 => bool) public usedDogs;

	mapping(uint256 => bool) public upgradedClones;

	string private _contractBaseURI = "https://guttercloneapi.guttercatgang.com/metadata/";
	string private _contractURI = "ipfs://QmdotChEKgUZ38CiYxr7PSC23N5Mh4a28uQLDXRfVfhYNH";

	event JuiceBurned(uint256 cloneId, uint256 juiceId, uint256 speciesType, uint256 speciesId);
	event CloneUpgraded(uint256 oldCloneID, uint256 newCloneID, uint256 juiceID);

	modifier burnValid(
		bytes32 hash,
		bytes memory sig,
		uint256 speciesType,
		uint256 speciesID,
		uint256 juiceID
	) {
		require(matchAddresSigner(hash, sig), "invalid signer");
		require(hashClone(_msgSender(), speciesID, speciesType, juiceID) == hash, "invalid hash");
		require(juiceContract.ownerOf(juiceID) == _msgSender(), "not the owner");
		_;
	}

	constructor() ERC721A("Gutter Clone", "CLONE") {
		_pause();
	}

	/**
	 * @dev setup function run initially
	 */
	function setup(
		address juicesAddress,
		address cats,
		address rats,
		address pigeons,
		address dogs,
		address signer
	) external onlyOwner {
		juiceContract = IJuice(juicesAddress);
		gutterCats = cats;
		gutterRats = rats;
		gutterPigeons = pigeons;
		gutterDogs = dogs;
		signerAddress = signer;
	}

	/**
	 * @dev clones a cat
	 */
	function cloneWithCat(
		bytes memory sig,
		bytes32 hash,
		uint256 juiceId,
		uint256 speciesId
	) external whenNotPaused nonReentrant burnValid(hash, sig, CAT, speciesId, juiceId) {
		require(IERC1155(gutterCats).balanceOf(_msgSender(), speciesId) > 0, "not the cat owner");
		require(!usedCats[speciesId], "cat is used");

		juiceContract.burn(juiceId);

		_safeMint(_msgSender(), 1);
		usedCats[speciesId] = true;

		emit JuiceBurned(totalSupply(), juiceId, CAT, speciesId);
	}

	/**
	 * @dev clones a rat
	 */
	function cloneWithRat(
		bytes memory sig,
		bytes32 hash,
		uint256 juiceId,
		uint256 speciesId
	) external whenNotPaused nonReentrant burnValid(hash, sig, RAT, speciesId, juiceId) {
		require(IERC1155(gutterRats).balanceOf(_msgSender(), speciesId) > 0, "not the rat owner");
		require(!usedRats[speciesId], "rat is used");

		juiceContract.burn(juiceId);

		_safeMint(_msgSender(), 1);
		usedRats[speciesId] = true;

		emit JuiceBurned(totalSupply(), juiceId, RAT, speciesId);
	}

	/**
	 * @dev clones a pigeon
	 */
	function cloneWithPigeon(
		bytes memory sig,
		bytes32 hash,
		uint256 juiceId,
		uint256 speciesId
	) external whenNotPaused nonReentrant burnValid(hash, sig, PIGEON, speciesId, juiceId) {
		require(IERC721(gutterPigeons).ownerOf(speciesId) == _msgSender(), "not the pigeon owner");
		require(!usedPigeons[speciesId], "pigeon is used");

		juiceContract.burn(juiceId);

		_safeMint(_msgSender(), 1);
		usedPigeons[speciesId] = true;

		emit JuiceBurned(totalSupply(), juiceId, PIGEON, speciesId);
	}

	/**
	 * @dev clones a dog
	 */
	function cloneWithDog(
		bytes memory sig,
		bytes32 hash,
		uint256 juiceId,
		uint256 speciesId
	) external whenNotPaused nonReentrant burnValid(hash, sig, DOG, speciesId, juiceId) {
		require(IERC721(gutterDogs).ownerOf(speciesId) == _msgSender(), "not the dog owner");
		require(!usedDogs[speciesId], "dog is used");

		juiceContract.burn(juiceId);

		_safeMint(_msgSender(), 1);
		usedDogs[speciesId] = true;

		emit JuiceBurned(totalSupply(), juiceId, DOG, speciesId);
	}

	function cloneWithoutSpecies(
		bytes memory sig,
		bytes32 hash,
		uint256 juiceId
	) external whenNotPaused nonReentrant burnValid(hash, sig, NONE, 0, juiceId) {
		juiceContract.burn(juiceId);

		_safeMint(_msgSender(), 1);

		emit JuiceBurned(totalSupply(), juiceId, NONE, 0);
	}

	/**
	 * @dev upgrades a clone
	 * @param sig  - backend signature
	 * @param hash  - hash of transaction
	 * @param juiceId  - nft id of the juice
	 * @param tokenID  - the clone that you own
	 */
	function upgradeClone(
		bytes memory sig,
		bytes32 hash,
		uint256 juiceId,
		uint256 tokenID //the old clone
	) external nonReentrant {
		require(upgradeIsLive, "not live");
		require(matchAddresSigner(hash, sig), "invalid signer");
		require(hashUpgrade(_msgSender(), juiceId, tokenID) == hash, "invalid hash");
		require(ownerOf(tokenID) == _msgSender(), "not the owner");
		require(juiceContract.ownerOf(juiceId) == _msgSender(), "not juice owner");
		require(!upgradedClones[tokenID], "clone was already upgraded");

		juiceContract.burn(juiceId);

		_safeMint(_msgSender(), 1);

		upgradedClones[tokenID] = true;

		emit CloneUpgraded(tokenID, totalSupply(), juiceId); //old clone, new clone, juice id
	}

	/**
	 * READ FUNCTIONS
	 */
	function exists(uint256 _tokenId) external view returns (bool) {
		return _exists(_tokenId);
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_contractBaseURI, _tokenId.toString()));
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns (bool) {
		return signerAddress == hash.recover(signature);
	}

    function hashClone(
		address sender,
        uint256 speciesID,
        uint256 speciesType,
        uint256 juiceID
	) private pure returns (bytes32) {
		bytes32 hash = ECDSA.toEthSignedMessageHash(
			keccak256(abi.encodePacked(sender, speciesID, speciesType, juiceID))
		);
		return hash;
	}

	function hashUpgrade(
		address sender,
		uint256 param1,
		uint256 param2
	) private pure returns (bytes32) {
		bytes32 hash = ECDSA.toEthSignedMessageHash(
			keccak256(abi.encodePacked(sender, param1, param2))
		);
		return hash;
	}

	//------- ADMIN FUNCTIONS -------
	function setUpgradeLiveness(bool isLive) external onlyOwner {
		upgradeIsLive = isLive;
	}

	function changeSigner(address newSigner) external onlyOwner {
		signerAddress = newSigner;
	}

	function setPaused(bool _setPaused) external onlyOwner {
		return (_setPaused) ? _pause() : _unpause();
	}

	function setBaseURI(string memory newBaseURI) external onlyOwner {
		_contractBaseURI = newBaseURI;
	}

	function setContractURI(string memory newContractURI) external onlyOwner {
		_contractURI = newContractURI;
	}

	function adminMint(address to, uint256 qty) external onlyOwner {
		_safeMint(to, qty);
	}

	function reclaimERC20(IERC20 erc20Token) external onlyOwner {
		erc20Token.transfer(_msgSender(), erc20Token.balanceOf(address(this)));
	}

	function reclaimERC721(IERC721 erc721Token, uint256 id) external onlyOwner {
		erc721Token.safeTransferFrom(address(this), _msgSender(), id);
	}

	function reclaimERC1155(
		address erc1155Token,
		uint256 id,
		uint256 amount
	) public onlyOwner {
		IERC1155(erc1155Token).safeTransferFrom(address(this), _msgSender(), id, amount, "");
	}

	function withdrawEarnings() external onlyOwner {
		payable(_msgSender()).transfer(address(this).balance);
	}

	//------- OTHER -------
	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
	using Address for address;
	using Strings for uint256;

	// Compiler will pack this into a single 256bit word.
	struct TokenOwnership {
		// The address of the owner.
		address addr;
		// Keeps track of the start time of ownership with minimal overhead for tokenomics.
		uint64 startTimestamp;
		// Whether the token has been burned.
		bool burned;
	}

	// Compiler will pack this into a single 256bit word.
	struct AddressData {
		// Realistically, 2**64-1 is more than enough.
		uint64 balance;
		// Keeps track of mint count with minimal overhead for tokenomics.
		uint64 numberMinted;
		// Keeps track of burn count with minimal overhead for tokenomics.
		uint64 numberBurned;
		// For miscellaneous variable(s) pertaining to the address
		// (e.g. number of whitelist mint slots used).
		// If there are multiple variables, please pack them into a uint64.
		uint64 aux;
	}

	// The tokenId of the next token to be minted.
	uint256 internal _currentIndex;

	// The number of tokens burned.
	uint256 internal _burnCounter;

	// Token name
	string private _name;

	// Token symbol
	string private _symbol;

	// Mapping from token ID to ownership details
	// An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
	mapping(uint256 => TokenOwnership) internal _ownerships;

	// Mapping owner address to address data
	mapping(address => AddressData) private _addressData;

	// Mapping from token ID to approved address
	mapping(uint256 => address) private _tokenApprovals;

	// Mapping from owner to operator approvals
	mapping(address => mapping(address => bool)) private _operatorApprovals;

	constructor(string memory name_, string memory symbol_) {
		_name = name_;
		_symbol = symbol_;
		_currentIndex = _startTokenId();
	}

	/**
	 * To change the starting tokenId, please override this function.
	 */
	function _startTokenId() internal view virtual returns (uint256) {
		return 0;
	}

	/**
	 * @dev See {IERC721Enumerable-totalSupply}.
	 * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
	 */
	function totalSupply() public view returns (uint256) {
		// Counter underflow is impossible as _burnCounter cannot be incremented
		// more than _currentIndex - _startTokenId() times
		unchecked {
			return _currentIndex - _burnCounter - _startTokenId();
		}
	}

	/**
	 * Returns the total amount of tokens minted in the contract.
	 */
	function _totalMinted() internal view returns (uint256) {
		// Counter underflow is impossible as _currentIndex does not decrement,
		// and it is initialized to _startTokenId()
		unchecked {
			return _currentIndex - _startTokenId();
		}
	}

	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC165, IERC165)
		returns (bool)
	{
		return
			interfaceId == type(IERC721).interfaceId ||
			interfaceId == type(IERC721Metadata).interfaceId ||
			super.supportsInterface(interfaceId);
	}

	/**
	 * @dev See {IERC721-balanceOf}.
	 */
	function balanceOf(address owner) public view override returns (uint256) {
		if (owner == address(0)) revert BalanceQueryForZeroAddress();
		return uint256(_addressData[owner].balance);
	}

	/**
	 * Returns the number of tokens minted by `owner`.
	 */
	function _numberMinted(address owner) internal view returns (uint256) {
		return uint256(_addressData[owner].numberMinted);
	}

	/**
	 * Returns the number of tokens burned by or on behalf of `owner`.
	 */
	function _numberBurned(address owner) internal view returns (uint256) {
		return uint256(_addressData[owner].numberBurned);
	}

	/**
	 * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
	 */
	function _getAux(address owner) internal view returns (uint64) {
		return _addressData[owner].aux;
	}

	/**
	 * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
	 * If there are multiple variables, please pack them into a uint64.
	 */
	function _setAux(address owner, uint64 aux) internal {
		_addressData[owner].aux = aux;
	}

	/**
	 * Gas spent here starts off proportional to the maximum mint batch size.
	 * It gradually moves to O(1) as tokens get transferred around in the collection over time.
	 */
	function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
		uint256 curr = tokenId;

		unchecked {
			if (_startTokenId() <= curr && curr < _currentIndex) {
				TokenOwnership memory ownership = _ownerships[curr];
				if (!ownership.burned) {
					if (ownership.addr != address(0)) {
						return ownership;
					}
					// Invariant:
					// There will always be an ownership that has an address and is not burned
					// before an ownership that does not have an address and is not burned.
					// Hence, curr will not underflow.
					while (true) {
						curr--;
						ownership = _ownerships[curr];
						if (ownership.addr != address(0)) {
							return ownership;
						}
					}
				}
			}
		}
		revert OwnerQueryForNonexistentToken();
	}

	/**
	 * @dev See {IERC721-ownerOf}.
	 */
	function ownerOf(uint256 tokenId) public view override returns (address) {
		return _ownershipOf(tokenId).addr;
	}

	/**
	 * @dev See {IERC721Metadata-name}.
	 */
	function name() public view virtual override returns (string memory) {
		return _name;
	}

	/**
	 * @dev See {IERC721Metadata-symbol}.
	 */
	function symbol() public view virtual override returns (string memory) {
		return _symbol;
	}

	/**
	 * @dev See {IERC721Metadata-tokenURI}.
	 */
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

		string memory baseURI = _baseURI();
		return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
	}

	/**
	 * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
	 * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
	 * by default, can be overriden in child contracts.
	 */
	function _baseURI() internal view virtual returns (string memory) {
		return "";
	}

	/**
	 * @dev See {IERC721-approve}.
	 */
	function approve(address to, uint256 tokenId) public override {
		address owner = ERC721A.ownerOf(tokenId);
		if (to == owner) revert ApprovalToCurrentOwner();

		if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
			revert ApprovalCallerNotOwnerNorApproved();
		}

		_approve(to, tokenId, owner);
	}

	/**
	 * @dev See {IERC721-getApproved}.
	 */
	function getApproved(uint256 tokenId) public view override returns (address) {
		if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

		return _tokenApprovals[tokenId];
	}

	/**
	 * @dev See {IERC721-setApprovalForAll}.
	 */
	function setApprovalForAll(address operator, bool approved) public virtual override {
		if (operator == _msgSender()) revert ApproveToCaller();

		_operatorApprovals[_msgSender()][operator] = approved;
		emit ApprovalForAll(_msgSender(), operator, approved);
	}

	/**
	 * @dev See {IERC721-isApprovedForAll}.
	 */
	function isApprovedForAll(address owner, address operator)
		public
		view
		virtual
		override
		returns (bool)
	{
		return _operatorApprovals[owner][operator];
	}

	/**
	 * @dev See {IERC721-transferFrom}.
	 */
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public virtual override {
		_transfer(from, to, tokenId);
	}

	/**
	 * @dev See {IERC721-safeTransferFrom}.
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public virtual override {
		safeTransferFrom(from, to, tokenId, "");
	}

	/**
	 * @dev See {IERC721-safeTransferFrom}.
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) public virtual override {
		_transfer(from, to, tokenId);
		if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
			revert TransferToNonERC721ReceiverImplementer();
		}
	}

	/**
	 * @dev Returns whether `tokenId` exists.
	 *
	 * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
	 *
	 * Tokens start existing when they are minted (`_mint`),
	 */
	function _exists(uint256 tokenId) internal view returns (bool) {
		return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
	}

	function _safeMint(address to, uint256 quantity) internal {
		_safeMint(to, quantity, "");
	}

	/**
	 * @dev Safely mints `quantity` tokens and transfers them to `to`.
	 *
	 * Requirements:
	 *
	 * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
	 * - `quantity` must be greater than 0.
	 *
	 * Emits a {Transfer} event.
	 */
	function _safeMint(
		address to,
		uint256 quantity,
		bytes memory _data
	) internal {
		_mint(to, quantity, _data, true);
	}

	/**
	 * @dev Mints `quantity` tokens and transfers them to `to`.
	 *
	 * Requirements:
	 *
	 * - `to` cannot be the zero address.
	 * - `quantity` must be greater than 0.
	 *
	 * Emits a {Transfer} event.
	 */
	function _mint(
		address to,
		uint256 quantity,
		bytes memory _data,
		bool safe
	) internal {
		uint256 startTokenId = _currentIndex;
		if (to == address(0)) revert MintToZeroAddress();
		if (quantity == 0) revert MintZeroQuantity();

		_beforeTokenTransfers(address(0), to, startTokenId, quantity);

		// Overflows are incredibly unrealistic.
		// balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
		// updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
		unchecked {
			_addressData[to].balance += uint64(quantity);
			_addressData[to].numberMinted += uint64(quantity);

			_ownerships[startTokenId].addr = to;
			_ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

			uint256 updatedIndex = startTokenId;
			uint256 end = updatedIndex + quantity;

			if (safe && to.isContract()) {
				do {
					emit Transfer(address(0), to, updatedIndex);
					if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
						revert TransferToNonERC721ReceiverImplementer();
					}
				} while (updatedIndex != end);
				// Reentrancy protection
				if (_currentIndex != startTokenId) revert();
			} else {
				do {
					emit Transfer(address(0), to, updatedIndex++);
				} while (updatedIndex != end);
			}
			_currentIndex = updatedIndex;
		}
		_afterTokenTransfers(address(0), to, startTokenId, quantity);
	}

	/**
	 * @dev Transfers `tokenId` from `from` to `to`.
	 *
	 * Requirements:
	 *
	 * - `to` cannot be the zero address.
	 * - `tokenId` token must be owned by `from`.
	 *
	 * Emits a {Transfer} event.
	 */
	function _transfer(
		address from,
		address to,
		uint256 tokenId
	) private {
		TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

		bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
			isApprovedForAll(prevOwnership.addr, _msgSender()) ||
			getApproved(tokenId) == _msgSender());

		if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
		if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
		if (to == address(0)) revert TransferToZeroAddress();

		_beforeTokenTransfers(from, to, tokenId, 1);

		// Clear approvals from the previous owner
		_approve(address(0), tokenId, prevOwnership.addr);

		// Underflow of the sender's balance is impossible because we check for
		// ownership above and the recipient's balance can't realistically overflow.
		// Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
		unchecked {
			_addressData[from].balance -= 1;
			_addressData[to].balance += 1;

			_ownerships[tokenId].addr = to;
			_ownerships[tokenId].startTimestamp = uint64(block.timestamp);

			// If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
			// Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
			uint256 nextTokenId = tokenId + 1;
			if (_ownerships[nextTokenId].addr == address(0)) {
				// This will suffice for checking _exists(nextTokenId),
				// as a burned slot cannot contain the zero address.
				if (nextTokenId < _currentIndex) {
					_ownerships[nextTokenId].addr = prevOwnership.addr;
					_ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
				}
			}
		}

		emit Transfer(from, to, tokenId);
		_afterTokenTransfers(from, to, tokenId, 1);
	}

	/**
	 * @dev This is equivalent to _burn(tokenId, false)
	 */
	function _burn(uint256 tokenId) internal virtual {
		_burn(tokenId, false);
	}

	/**
	 * @dev Destroys `tokenId`.
	 * The approval is cleared when the token is burned.
	 *
	 * Requirements:
	 *
	 * - `tokenId` must exist.
	 *
	 * Emits a {Transfer} event.
	 */
	function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
		TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

		if (approvalCheck) {
			bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
				isApprovedForAll(prevOwnership.addr, _msgSender()) ||
				getApproved(tokenId) == _msgSender());

			if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
		}

		_beforeTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

		// Clear approvals from the previous owner
		_approve(address(0), tokenId, prevOwnership.addr);

		// Underflow of the sender's balance is impossible because we check for
		// ownership above and the recipient's balance can't realistically overflow.
		// Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
		unchecked {
			_addressData[prevOwnership.addr].balance -= 1;
			_addressData[prevOwnership.addr].numberBurned += 1;

			// Keep track of who burned the token, and the timestamp of burning.
			_ownerships[tokenId].addr = prevOwnership.addr;
			_ownerships[tokenId].startTimestamp = uint64(block.timestamp);
			_ownerships[tokenId].burned = true;

			// If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
			// Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
			uint256 nextTokenId = tokenId + 1;
			if (_ownerships[nextTokenId].addr == address(0)) {
				// This will suffice for checking _exists(nextTokenId),
				// as a burned slot cannot contain the zero address.
				if (nextTokenId < _currentIndex) {
					_ownerships[nextTokenId].addr = prevOwnership.addr;
					_ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
				}
			}
		}

		emit Transfer(prevOwnership.addr, address(0), tokenId);
		_afterTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

		// Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
		unchecked {
			_burnCounter++;
		}
	}

	/**
	 * @dev Approve `to` to operate on `tokenId`
	 *
	 * Emits a {Approval} event.
	 */
	function _approve(
		address to,
		uint256 tokenId,
		address owner
	) private {
		_tokenApprovals[tokenId] = to;
		emit Approval(owner, to, tokenId);
	}

	/**
	 * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
	 *
	 * @param from address representing the previous owner of the given token ID
	 * @param to target address that will receive the tokens
	 * @param tokenId uint256 ID of the token to be transferred
	 * @param _data bytes optional data to send along with the call
	 * @return bool whether the call correctly returned the expected magic value
	 */
	function _checkContractOnERC721Received(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) private returns (bool) {
		try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (
			bytes4 retval
		) {
			return retval == IERC721Receiver(to).onERC721Received.selector;
		} catch (bytes memory reason) {
			if (reason.length == 0) {
				revert TransferToNonERC721ReceiverImplementer();
			} else {
				assembly {
					revert(add(32, reason), mload(reason))
				}
			}
		}
	}

	/**
	 * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
	 * And also called before burning one token.
	 *
	 * startTokenId - the first token id to be transferred
	 * quantity - the amount to be transferred
	 *
	 * Calling conditions:
	 *
	 * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
	 * transferred to `to`.
	 * - When `from` is zero, `tokenId` will be minted for `to`.
	 * - When `to` is zero, `tokenId` will be burned by `from`.
	 * - `from` and `to` are never both zero.
	 */
	function _beforeTokenTransfers(
		address from,
		address to,
		uint256 startTokenId,
		uint256 quantity
	) internal virtual {}

	/**
	 * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
	 * minting.
	 * And also called after one token has been burned.
	 *
	 * startTokenId - the first token id to be transferred
	 * quantity - the amount to be transferred
	 *
	 * Calling conditions:
	 *
	 * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
	 * transferred to `to`.
	 * - When `from` is zero, `tokenId` has been minted for `to`.
	 * - When `to` is zero, `tokenId` has been burned by `from`.
	 * - `from` and `to` are never both zero.
	 */
	function _afterTokenTransfers(
		address from,
		address to,
		uint256 startTokenId,
		uint256 quantity
	) internal virtual {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}