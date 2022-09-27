// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IOwnerOfERC721 {
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IMintERC20 {
  function mint(address to, uint256 amount) external;
}

contract AstroStakingController is Ownable {
  using ECDSA for bytes32;

  // Data related to staked NFT tokens
  struct StakedToken {
    // Owner of the NFT
    address owner;
    // Timestamp when the NFT was staked
    uint32 timestamp;
    // Flag indicating whether it's the first staked NFT
    // First staked NFT cannot be unstaked unless all other NFTs are unstaked
    // First staked NFT will only get one rental pass
    bool isFirstStaked;
    // Number of ERC20 tokens generate per day
    uint256 emissionRate;
    // Rental recipients and expirations
    address recipient1;
    uint32 expiration1;
    address recipient2;
    uint32 expiration2;
  }

  // Data related to token owners
  struct TokenOwner {
    // Token ids of currently staked NFT
    uint256[] stakedTokenIds;
    // Total amount of ERC20 tokens minted by the address
    uint256 amountMinted;
  }

  // Events
  event Staked(address indexed owner, uint256 indexed tokenId, uint256 emissionRate, bool isFirstStaked);

  event Unstaked(address indexed owner, uint256 indexed tokenId, uint256 amountMinted);

  event Claimed(address indexed owner, uint256 amountMinted);

  event Rented(
    address indexed owner,
    address indexed recipient,
    uint256 indexed tokenId,
    bool isFirstPass,
    uint32 expiration
  );

  uint256 public constant decimals = 18;

  // Contract address of TinyAstro NFT
  address public tinyAstro;

  // Contract address of AstroToken
  address public astroToken;

  bool public isPaused;

  // Mapping token id to rarity ranking
  // Rarity 0 = NFT ranking from 1501 - 3000 (Don't have to update the mappings for these tokens as default is 0)
  // Rarity 1 = NFT ranking from 501  - 1500
  // Rarity 2 = NFT ranking from 101  - 500
  // Rarity 3 = NFT ranking from 11   - 100
  // Rarity 4 = NFT ranking from 1    - 10
  mapping(uint256 => uint256) public tokenRarities;

  // Mapping token rarity to emission rate per day;
  mapping(uint256 => uint256) public emissionRates;

  // Valid rental durations
  mapping(uint256 => bool) public rentalDurations;

  // Mapping token id to staked data
  mapping(uint256 => StakedToken) public stakedTokens;

  // Mapping owner address to address data
  mapping(address => TokenOwner) public tokenOwners;

  // Mapping rental recipient address to token id
  mapping(address => uint256) private _recipientToTokenId;

  constructor(address _tinyAstro, address _astroToken) {
    tinyAstro = _tinyAstro;
    astroToken = _astroToken;

    // Rarity 0 - Token ranking from 1501 - 3000, 8 tokens per day
    emissionRates[0] = 8;
    // Rarity 1 - Token ranking from 501 - 1500, 12 tokens per day
    emissionRates[1] = 12;
    // Rarity 2 - Token ranking from 101 - 500, 15 tokens per day
    emissionRates[2] = 15;
    // Rarity 3 - Token ranking from 11 - 100, 20 tokens per day
    emissionRates[3] = 20;
    // Rarity 4  - Token ranking from 1 - 10, 100 tokens per day
    emissionRates[4] = 100;

    // Add rental durations of 1 day, 7 days and 30 days
    rentalDurations[1] = true;
    rentalDurations[7] = true;
    rentalDurations[30] = true;
  }

  function setTinyAstro(address addr) external onlyOwner {
    tinyAstro = addr;
  }

  function setAstroToken(address addr) external onlyOwner {
    astroToken = addr;
  }

  function setPaused(bool status) external onlyOwner {
    isPaused = status;
  }

  function setTokenRarity(uint256 rarity, uint256[] calldata tokenIds) external onlyOwner {
    unchecked {
      for (uint256 i = 0; i < tokenIds.length; i++) {
        tokenRarities[tokenIds[i]] = rarity;
      }
    }
  }

  function updateRentalDurations(uint256[] calldata toAdd, uint256[] calldata toRemove) external onlyOwner {
    unchecked {
      for (uint256 i = 0; i < toAdd.length; i++) {
        rentalDurations[toAdd[i]] = true;
      }

      for (uint256 i = 0; i < toRemove.length; i++) {
        delete rentalDurations[toRemove[i]];
      }
    }
  }

  function updateEmissionRates(uint256[] calldata rarities, uint256[] calldata rates)
    external
    onlyOwner
  {
    require(rarities.length > 0 && rarities.length == rates.length, "Invalid parameters");

    unchecked {
      for (uint256 i = 0; i < rarities.length; i++) {
        emissionRates[rarities[i]] = rates[i];
      }
    }
  }

  modifier whenNotPaused() {
    require(!isPaused, "Contract is paused");
    _;
  }

  /**
   * @notice NFT holders use this function to stake their tokens.
   * @dev Emission rate is set at the time of staking.
   *      Future changes of the corresponding multiplier will not apply to staked tokens.
   *      Staked NFT tokens are blocked from transfers.
   * @param tokenIds List of token id to be staked.
   */
  function stake(uint256[] calldata tokenIds) external whenNotPaused {
    unchecked {
      for (uint256 i = 0; i < tokenIds.length; i++) {
        _stake(tokenIds[i]);
      }
    }
  }

  function _stake(uint256 tokenId) internal {
    require(IOwnerOfERC721(tinyAstro).ownerOf(tokenId) == msg.sender, "Not the token owner");

    StakedToken storage stakedToken = stakedTokens[tokenId];
    require(stakedToken.owner == address(0), "Token is already staked");

    uint256 emissionRate = emissionRates[tokenRarities[tokenId]];
    require(emissionRate > 0, "Zero emission rate");

    stakedToken.owner = msg.sender;
    stakedToken.emissionRate = emissionRate * 10**decimals;
    stakedToken.timestamp = uint32(block.timestamp);

    uint256[] storage stakedTokenIds = tokenOwners[msg.sender].stakedTokenIds;
    stakedToken.isFirstStaked = stakedTokenIds.length == 0;
    stakedTokenIds.push(tokenId);

    emit Staked(msg.sender, tokenId, stakedToken.emissionRate, stakedToken.isFirstStaked);
  }

  /**
   * @notice NFT token holders use this function to unstake their tokens and mint ERC20 tokens for rewards.
   * @dev NFT tokens cannot be staked before a min duration has passed.
   * @param tokenIds NFT tokens to be unstaked.
   */
  function unstake(uint256[] calldata tokenIds) external whenNotPaused {
    require(tokenIds.length > 0, "Empty token ids");

    TokenOwner storage tokenOwner = tokenOwners[msg.sender];
    require(tokenOwner.stakedTokenIds.length > 0, "No staked tokens");

    // Ensure first token is not unstaked unless no more staked tokens
    bool validatesFirstToken = tokenIds.length < tokenOwner.stakedTokenIds.length;
    uint256 amountToMint = 0;

    unchecked {
      for (uint256 i = 0; i < tokenIds.length; i++) {
        amountToMint += _unstake(tokenIds[i]);
      }

      if (validatesFirstToken) {
        require(stakedTokens[tokenOwner.stakedTokenIds[0]].isFirstStaked, "First token cannot be unstaked yet");
      }

      IMintERC20(astroToken).mint(msg.sender, amountToMint);
      tokenOwner.amountMinted += amountToMint;
    }
  }

  function _unstake(uint256 tokenId) internal returns (uint256 amount) {
    StakedToken memory stakedToken = stakedTokens[tokenId];

    require(stakedToken.owner == msg.sender, "Not the token owner");

    // Check if there is any active rental pass
    require(
      stakedToken.expiration1 < block.timestamp && stakedToken.expiration2 < block.timestamp,
      "Unstake with active rental pass"
    );

    uint256 numberOfDays = (block.timestamp - stakedToken.timestamp) / 1 days;
    amount = numberOfDays * stakedToken.emissionRate;

    // Free storage
    delete stakedTokens[tokenId];
    _removeStakedTokenId(msg.sender, tokenId);

    emit Unstaked(msg.sender, tokenId, amount);
  }

  /**
   * @notice NFT token holders use this function to claim/mint the ERC20 tokens without unstaking.
   * @dev ERC20 tokens cannot be claimed before a min duration has passed.
   */
  function claim() external whenNotPaused {
    uint256[] memory tokenIds = tokenOwners[msg.sender].stakedTokenIds;
    require(tokenIds.length > 0, "No staked tokens");

    uint256 amountToMint = 0;

    unchecked {
      for (uint256 i = 0; i < tokenIds.length; i++) {
        uint256 tokenId = tokenIds[i];

        StakedToken storage stakedToken = stakedTokens[tokenId];

        require(stakedToken.owner == msg.sender, "Not the token owner");

        uint256 numberOfDays = (block.timestamp - stakedToken.timestamp) / 1 days;

        if (numberOfDays > 0) {
          amountToMint += numberOfDays * stakedToken.emissionRate;
          stakedToken.timestamp += uint32(numberOfDays * 1 days);
        }
      }

      require(amountToMint > 0, "Zero mint amount");

      IMintERC20(astroToken).mint(msg.sender, amountToMint);
      tokenOwners[msg.sender].amountMinted += amountToMint;

      emit Claimed(msg.sender, amountToMint);
    }
  }

  function rent(
    uint256 tokenId,
    address recipient,
    bool firstPass,
    uint256 duration
  ) external whenNotPaused {
    require(rentalDurations[duration], "Invalid duration");

    StakedToken storage stakedToken = stakedTokens[tokenId];
    require(stakedToken.owner == msg.sender, "Not the token owner");

    // Ensure recipient is not holding any active pass
    _verifyRentalRecipient(recipient);

    uint32 expiration = uint32(block.timestamp + duration * 1 days);

    if (firstPass) {
      require(stakedToken.expiration1 < block.timestamp, "Pass is rent to someone else");
      stakedToken.recipient1 = recipient;
      stakedToken.expiration1 = expiration;
    } else {
      require(!stakedToken.isFirstStaked && stakedToken.expiration2 < block.timestamp, "Pass is rent to someone else");
      stakedToken.recipient2 = recipient;
      stakedToken.expiration2 = expiration;
    }

    _recipientToTokenId[recipient] = tokenId;

    emit Rented(msg.sender, recipient, tokenId, firstPass, expiration);
  }

  /**
   * @notice Check a owner's staking status.
   * @dev `amountToMint` is accumulated only by tokens that have passed the min stake duration.
   */
  function stakingStatus(address addr)
    external
    view
    returns (
      uint256[] memory stakedTokenIds,
      uint256 dailyYield,
      uint256 amountToMint,
      uint256 amountMinted
    )
  {
    TokenOwner memory tokenOwner = tokenOwners[addr];
    stakedTokenIds = tokenOwner.stakedTokenIds;
    amountMinted = tokenOwner.amountMinted;

    unchecked {
      for (uint256 i = 0; i < stakedTokenIds.length; i++) {
        StakedToken memory stakedToken = stakedTokens[stakedTokenIds[i]];
        dailyYield += stakedToken.emissionRate;

        uint256 numberOfDays = (block.timestamp - stakedToken.timestamp) / 1 days;
        if (numberOfDays > 0) {
          amountToMint += numberOfDays * stakedToken.emissionRate;
        }
      }
    }
  }

  function rentalRecipientStatus(address recipient) external view returns (bool isValid, uint32 expiration) {
    uint256 tokenId = _recipientToTokenId[recipient];

    StakedToken memory stakedToken = stakedTokens[tokenId];
    if (stakedToken.recipient1 == recipient) {
      expiration = stakedToken.expiration1;
    } else if (stakedToken.recipient2 == recipient) {
      expiration = stakedToken.expiration2;
    }
    isValid = expiration >= block.timestamp;
  }

  /**
   * @notice Check whether a token is currently staked.
   */
  function isTokenStaked(uint256 tokenId) external view returns (bool) {
    return stakedTokens[tokenId].owner != address(0);
  }

  function _verifyRentalRecipient(address recipient) internal view {
    StakedToken memory stakedToken = stakedTokens[_recipientToTokenId[recipient]];

    uint256 expiration;
    if (stakedToken.recipient1 == recipient) {
      expiration = stakedToken.expiration1;
    } else if (stakedToken.recipient2 == recipient) {
      expiration = stakedToken.expiration2;
    }
    require(expiration < block.timestamp, "Recipient is in possession of an active rental pass");
  }

  /**
   * @dev Remove a NFT token id from staked tokens.
   */
  function _removeStakedTokenId(address addr, uint256 tokenId) internal {
    uint256[] storage tokenIds = tokenOwners[addr].stakedTokenIds;

    unchecked {
      for (uint256 i = 0; i < tokenIds.length; i++) {
        if (tokenIds[i] == tokenId) {
          return _remove(tokenIds, i);
        }
      }
    }
  }

  /**
   * @dev Remove the element at given index in an array without preserving order
   */
  function _remove(uint256[] storage tokenIds, uint256 index) internal {
    if (index < tokenIds.length - 1) {
      tokenIds[index] = tokenIds[tokenIds.length - 1];
    }
    tokenIds.pop();
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

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
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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