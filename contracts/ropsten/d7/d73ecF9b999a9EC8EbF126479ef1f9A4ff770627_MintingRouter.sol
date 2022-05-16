//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

// Imports
import "../extensions/EIP712Whitelisting.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// NFT Interface
interface INFT {
    function mint(address recipient, uint256 quantity) external;

    function areReservesMinted() external view returns (bool);

    function maxSupply() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

/**
 * @title The Minting Router contract.
 */
contract MintingRouter is Ownable, ReentrancyGuard, EIP712Whitelisting {
    // The available sale types.
    enum SaleRoundType {
        WHITELIST,
        PUBLIC
    }

    // The sale round details.
    struct SaleRound {
        // The type of the sale.
        SaleRoundType saleType;
        // The price of a token during the sale round.
        uint256 price;
        // The total number of tokens available for minting during the sale round.
        uint256 totalAmount; // TODO:: Rename Variable.
        // The total number of tokens available for minting by a single wallet during the sale round.
        uint256 limitAmountPerWallet; // TODO:: Rename Variable.
        // The maximum number of tokens available for minting per single transaction.
        uint256 maxAmountPerMint; // TODO:: Rename Variable.
        // The flag that indicates if the sale round is enabled.
        bool enabled;
    }
    /// @notice Indicates that tokens are unlimited.
    uint256 public constant UNLIMITED_AMOUNT = 0;
    /// @notice The current sale round details.
    SaleRound public currentSaleRound;
    /// @notice The current sale round index.
    uint256 public currentSaleIndex;
    /// @notice The Brewies NFT contract.
    INFT private _nftContract;
    /// @notice The number of NFTs minted during a sale round.
    mapping(uint256 => uint256) private _mintedAmountPerRound;
    /// @notice The number of NFTs minted during a sale round per wallet.
    mapping(uint256 => mapping(address => uint256))
        private _mintedAmountPerAddress; // TODO:: Rename Variable.

    /**
     * @notice The smart contract constructor that initializes the minting router.
     * @param nftContract The NFT contract.
     * @param tokenName The name of the NFT token.
     * @param version The version of the project.
     */
    constructor(
        INFT nftContract,
        string memory tokenName,
        string memory version
    ) EIP712Whitelisting(tokenName, version) {
        // Initialize the variables.
        _nftContract = nftContract;
        // Set the initial dummy value for the current sale index.
        currentSaleIndex = type(uint256).max;
    }

    /**
     * @notice Validates sale rounds parameters.
     * @param totalAmount The total amount of NFTs available for the current sale round.
     * @param limitAmountPerWallet The total number of NFTs that can be minted by a single wallet during the sale round.
     * @param maxAmountPerMint The maximum number of tokens available for minting per single transaction.
     */
    modifier validateSaleRoundParams(
        uint256 totalAmount,
        uint256 limitAmountPerWallet,
        uint256 maxAmountPerMint
    ) {
        require(
            _totalTokensLeft() > 0 &&
            totalAmount <= _totalTokensLeft() &&
            totalAmount >= _mintedAmountPerRound[currentSaleIndex],
            "INVALID_TOTAL_AMOUNT"
        );

        if (totalAmount != UNLIMITED_AMOUNT) {
            require(limitAmountPerWallet <= totalAmount,"INVALID_LIMIT_PER_WALLET");
            require(maxAmountPerMint <= totalAmount, "INVALID_MAX_PER_MINT");
        }

        if (limitAmountPerWallet != UNLIMITED_AMOUNT) {
            require(maxAmountPerMint <= limitAmountPerWallet, "INVALID_MAX_PER_MINT");
        }

        _;
    }

    /**
     * @notice Changes the current sale details.
     * @param price The price of an NFT for the current sale round.
     * @param totalAmount The total amount of NFTs available for the current sale round.
     * @param limitAmountPerWallet The total number of NFTs that can be minted by a single wallet during the sale round.
     * @param maxAmountPerMint The maximum number of tokens available for minting per single transaction.
     */
    function changeSaleRoundParams(
        uint256 price,
        uint256 totalAmount,
        uint256 limitAmountPerWallet,
        uint256 maxAmountPerMint
    ) external onlyOwner validateSaleRoundParams(
        totalAmount,
        limitAmountPerWallet,
        maxAmountPerMint
    ) {
        currentSaleRound.price = price;
        currentSaleRound.totalAmount = totalAmount;
        currentSaleRound.limitAmountPerWallet = limitAmountPerWallet;
        currentSaleRound.maxAmountPerMint = maxAmountPerMint;
    }

    /**
     * @notice Creates a new sale round.
     * @dev Requires sales to be disabled and reserves to be minted.
     * @param saleType The type of the sale round (WHITELIST - 0, PUBLIC SALE - 1).
     * @param price The price of an NFT for the current sale round.
     * @param totalAmount The total amount of NFTs available for the current sale round.
     * @param limitAmountPerWallet The total number of NFTs that can be minted by a single wallet during the sale round.
     * @param maxAmountPerMint The maximum number of tokens available for minting per single transaction.
     */
    function createSaleRound(
        SaleRoundType saleType,
        uint256 price,
        uint256 totalAmount,
        uint256 limitAmountPerWallet,
        uint256 maxAmountPerMint
    ) external onlyOwner validateSaleRoundParams(
        totalAmount,
        limitAmountPerWallet,
        maxAmountPerMint
    ) {
         // Check if the sales are closed.
        require(
            currentSaleRound.enabled == false,
            "SALE_ROUND_IS_ENABLED"
        );

        // Check if the reserves are minted.
        bool reservesMinted = _nftContract.areReservesMinted();
        require(
            reservesMinted == true,
            "ALL_RESERVED_TOKENS_NOT_MINTED"
        );

        // Set new sale parameters.
        currentSaleRound.price = price;
        currentSaleRound.totalAmount = totalAmount;
        currentSaleRound.limitAmountPerWallet = limitAmountPerWallet;
        currentSaleRound.maxAmountPerMint = maxAmountPerMint;
        currentSaleRound.saleType = saleType;
        // Increment the sale round index.
        if (currentSaleIndex == type(uint256).max) {
            currentSaleIndex = 0;
        } else {
            currentSaleIndex += 1;
        }
    }

    /**
     * @notice Starts the sale round.
     */
    function enableSaleRound() external onlyOwner {
        require(currentSaleIndex != type(uint256).max, "NO_SALE_ROUND_CREATED");
        require(currentSaleRound.enabled == false, "SALE_ROUND_ENABLED_ALREADY");
        currentSaleRound.enabled = true;
    }

    /**
     * @notice Closes the sale round.
     */
    function disableSaleRound() external onlyOwner {
        require(currentSaleRound.enabled == true, "SALE_ROUND_DISABLED_ALREADY");
        currentSaleRound.enabled = false;
    }

    /**
     * @notice Mints NFTs during whitelist sale rounds.
     * @dev Requires the current sale round to be a WHITELIST round.
     * @param recipient The address that will receive the minted NFT.
     * @param quantity The number of NFTs to mint.
     * @param signature The signature of a whitelisted minter.
     */
    function whitelistMint(
        address recipient,
        uint256 quantity,
        bytes calldata signature
    ) external payable requiresWhitelist(signature) nonReentrant {
        require(
            currentSaleRound.saleType == SaleRoundType.WHITELIST,
            "WHITELIST_ROUND_NOT_ENABLED"
        );
        _mint(recipient, quantity);
    }

    /**
     * @notice Mints NFTs during public sale rounds.
     * @dev Requires the current sale round to be a PUBLIC round.
     * @param recipient The address that will receive the minted NFT.
     * @param quantity The number of NFTs to mint.
     */
    function publicMint(address recipient, uint256 quantity)
        external
        payable
        nonReentrant
    {
        require(
            currentSaleRound.saleType == SaleRoundType.PUBLIC,
            "PUBLIC_ROUND_NOT_ENABLED"
        );
        _mint(recipient, quantity);
    }

    /**
     * @notice Sets the address that is used during whitelist generation.
     * @param signer The address used during whitelist generation.
     */
    function setWhitelistSigningAddress(address signer) public onlyOwner {
        _setWhitelistSigningAddress(signer);
    }

    /**
     * @notice Calculates the number of tokens a minter is allowed to mint.
     * @param minter The minter address.
     * @return The number of tokens that a minter can mint.
     */
    function allowedTokenCount(address minter) public view returns (uint256) { // TODO:: Rename method.
        if (currentSaleRound.enabled == false) {
            return 0;
        }

        // Calculate the allowed number of tokens to mint by a wallet.
        uint256 allowedWalletCount = _totalTokensLeft();
        if (currentSaleRound.limitAmountPerWallet != UNLIMITED_AMOUNT) {
            allowedWalletCount = currentSaleRound.limitAmountPerWallet - _mintedAmountPerAddress[currentSaleIndex][minter];
        }

        // Calculate the limit of the number of tokens per single mint.
        uint256 allowedAmountPerMint = _totalTokensLeft();
        if (allowedAmountPerMint != UNLIMITED_AMOUNT) {
            allowedAmountPerMint = currentSaleRound.maxAmountPerMint;
        }

        return _min(
            allowedAmountPerMint,
            _min(allowedWalletCount, tokensLeft())
        );
    }

    /**
     * @notice Returns the number of tokens left for the running sale round.
     */
    function tokensLeft() public view returns (uint256) {
        if (currentSaleRound.enabled == false) {
            return 0;
        }

        if (currentSaleRound.totalAmount == UNLIMITED_AMOUNT) {
            return _totalTokensLeft();
        }

        return currentSaleRound.totalAmount - _mintedAmountPerRound[currentSaleIndex];
    }
    
    /**
     * @notice Mints NFTs.
     * @param recipient The address that will receive the minted NFT.
     * @param quantity The number of NFTs to mint.
     */
    function _mint(
        address recipient,
        uint256 quantity
    ) private {
        require(quantity > 0, "ZERO_QUANTITY_NOT_ALLOWED");
        require(
            currentSaleRound.enabled == true,
            "SALE_ROUND_DISABLED"
        );

        if (currentSaleRound.totalAmount != UNLIMITED_AMOUNT) {
            // We have limited amount of tokens for this sale round.
            require(
                _mintedAmountPerRound[currentSaleIndex] + quantity <=
                    currentSaleRound.totalAmount,
                "ALLOWANCE_PER_ROUND_EXCEEDED"
            );
        }

        if (currentSaleRound.limitAmountPerWallet != UNLIMITED_AMOUNT) {
            // We have limited amount of tokens per wallet for this sale round.
            uint256 mintedAmountSoFar = _mintedAmountPerAddress[
                currentSaleIndex
            ][recipient];
            require(
                mintedAmountSoFar + quantity <= currentSaleRound.limitAmountPerWallet,
                "ALLOWANCE_PER_WALLET_EXCEEDED"
            );
        }

        if (currentSaleRound.maxAmountPerMint != UNLIMITED_AMOUNT) {
            require(quantity <= currentSaleRound.maxAmountPerMint, "ALLOWANCE_PER_TXN_EXCEEDED");
        }

        require(
            msg.value >= currentSaleRound.price * quantity,
            "INSUFFICIENT_FUNDS"
        );

        // update total minted amount of this address
        _mintedAmountPerAddress[currentSaleIndex][recipient] += quantity;
        _mintedAmountPerRound[currentSaleIndex] += quantity;

        _nftContract.mint(recipient, quantity);
    }

    function _totalTokensLeft() private view returns(uint256) {
        return _nftContract.maxSupply() - _nftContract.totalSupply();
    }

    function _min(uint256 a, uint256 b) private pure returns(uint256) {
        if (a < b) {
            return a;
        }

        return b;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract EIP712Whitelisting {
  using ECDSA for bytes32;

  // The key used to sign whitelist signatures.
  // We will check to ensure that the key that signed the signature
  // is this one that we expect.
  address whitelistSigningKey = address(0);

  // Domain Separator is the EIP-712 defined structure that defines what contract
  // and chain these signatures can be used for.  This ensures people can't take
  // a signature used to mint on one contract and use it for another, or a signature
  // from testnet to replay on mainnet.
  // It has to be created in the constructor so we can dynamically grab the chainId.
  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-domainseparator
  bytes32 public DOMAIN_SEPARATOR;

  // The typehash for the data type specified in the structured data
  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#rationale-for-typehash
  // This should match whats in the client side whitelist signing code
  // https://github.com/msfeldstein/EIP712-whitelisting/blob/main/test/signWhitelist.ts#L22
  bytes32 public constant MINTER_TYPEHASH = keccak256("Minter(address wallet)");

  constructor(string memory tokenName, string memory version) {
    // This should match whats in the client side whitelist signing code
    // https://github.com/msfeldstein/EIP712-whitelisting/blob/main/test/signWhitelist.ts#L12
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        // This should match the domain you set in your client side signing.
        keccak256(bytes(tokenName)),
        keccak256(bytes(version)),
        block.chainid,
        address(this)
      )
    );
  }

  function _setWhitelistSigningAddress(address newSigningKey) internal {
    whitelistSigningKey = newSigningKey;
  }

  modifier requiresWhitelist(bytes calldata signature) {
    require(whitelistSigningKey != address(0), "Whitelist not enabled; please set the private key.");
    // Verify EIP-712 signature by recreating the data structure
    // that we signed on the client side, and then using that to recover
    // the address that signed the signature for this data.
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(MINTER_TYPEHASH, msg.sender))));
    // Use the recover method to see what address was used to create
    // the signature on this data.
    // Note that if the digest doesn't exactly match what was signed we'll
    // get a random recovered address.
    address recoveredAddress = digest.recover(signature);
    require(recoveredAddress == whitelistSigningKey, "Invalid signature");
    _;
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