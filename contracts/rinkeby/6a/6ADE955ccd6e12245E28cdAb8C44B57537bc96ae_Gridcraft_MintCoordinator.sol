//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//   ██████╗ ██████╗ ██╗██████╗  ██████╗██████╗  █████╗ ███████╗████████╗
//  ██╔════╝ ██╔══██╗██║██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝╚══██╔══╝
//  ██║  ███╗██████╔╝██║██║  ██║██║     ██████╔╝███████║█████╗     ██║   
//  ██║   ██║██╔══██╗██║██║  ██║██║     ██╔══██╗██╔══██║██╔══╝     ██║   
//  ╚██████╔╝██║  ██║██║██████╔╝╚██████╗██║  ██║██║  ██║██║        ██║   
//   ╚═════╝ ╚═╝  ╚═╝╚═╝╚═════╝  ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝        ╚═╝   
//
// Website: https://gridcraft.net/
// Twitter: https://twitter.com/gridcraft
// Discord: https://discord.gg/gridcraft
//

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./INFT.sol";
import "./IERC1155.sol";
import "./ILlamaZoo.sol";

contract Gridcraft_MintCoordinator is Ownable {
  using ECDSA for bytes32;
  address public signer = 0x48e1Db3054C67974ab06C33293708C0491aE6eA3;

  mapping(uint256 => bool) public llamaVerseIdUsed;

  mapping(address => uint256) public identityMints;
  mapping(address => uint256) public landMints; 
  mapping(address => bool) public bundleMint;

  INFT public gridcraftIdentities;
  INFT public llamascapeLand;
  INFT LlamaVerse = INFT(0x9df8Aa7C681f33E442A0d57B838555da863504f3);
  ILlamaZoo LlamaStake = ILlamaZoo(0x48193776062991c2fE024D9c99C35576A51DaDe0);
  IERC1155 LlamaBoost = IERC1155(0x0BD4D37E0907C9F564aaa0a7528837B81B25c605);

  bool public allowSaleIsActive = false;
  bool public publicSaleIsActive = false;
  
  uint256 public identityPrice = 0.3 ether;
  uint256 public landPrice = 0.3 ether;
  uint256 public bundleSave = 0.04 ether;

  uint256[][] allowListMax = [[3,1], [1,2], [3,3]];
  uint256 public identityMax = 5;
  uint256 public landMax = 3;

  uint256 public bundlesAvailable = 1600;

  uint256 public landFreeMints;

  address withdrawWallet = 0x5d28e347583e70b5F7B0631CA5ab5575bD37Cbcd;

  constructor(address _gridcraftIdentitiesAddress,
              address _llamascapeLandAddress
  ) {
    gridcraftIdentities = INFT(_gridcraftIdentitiesAddress);
    llamascapeLand = INFT(_llamascapeLandAddress);
  }

  function allowListSale(uint256 _gridcraftAmount, uint256 _llamascapeAmount, bool _bundle, uint256 _wl, bool _stake, bytes memory _signature) external payable {
    require (allowSaleIsActive, "Not active");
    require (_gridcraftAmount <= gridcraftIdentities.remaining(), "Max identities supply reached");
    require (_llamascapeAmount <= llamascapeLand.remaining(), "Max land supply reached");
    require (msg.value == priceOfRequest(_gridcraftAmount, _llamascapeAmount, _bundle), "Wrong amount sent");

    bytes32 hash = hashTransaction(_msgSender(), _gridcraftAmount, _llamascapeAmount, _bundle, _wl);
    require(matchSignerAdmin(signTransaction(hash), _signature), "Signature mismatch");
    require (msg.sender == tx.origin, "bm8gcm9ib3Rz");

    if (_wl == 0) {
      require(_bundle || _llamascapeAmount == 0, "No land without bundle"); //❄️
    }
    if (_wl == 1) {
      require(_bundle || _llamascapeAmount == 1, "One land without bundle"); //❄️
    }

    if (_bundle){
      require (bundlesAvailable > 0, "Bundles exhausted");
      require (!bundleMint[msg.sender], "One bundle per wallet");
      unchecked{ --bundlesAvailable; }
      bundleMint[msg.sender] = true;
    }
    if (_gridcraftAmount > 0){
      require ( identityMints[msg.sender] + _gridcraftAmount <= allowListMax[_wl][0], "Exceeds allowance" );
      unchecked { identityMints[msg.sender] += _gridcraftAmount; }
      gridcraftIdentities.saleMint(msg.sender, _gridcraftAmount, _stake);
    }
    if (_llamascapeAmount > 0){
      require ( landMints[msg.sender] + _llamascapeAmount <= allowListMax[_wl][1], "Exceeds allowance" );
      unchecked { landMints[msg.sender] += _llamascapeAmount; }
      llamascapeLand.saleMint(msg.sender, _llamascapeAmount, _stake);
    }
  }

  function publicSale(uint256 _gridcraftAmount, uint256 _llamascapeAmount, bool _bundle, bool _stake) external payable {
    require(publicSaleIsActive, "Not active");
    require (_gridcraftAmount <= gridcraftIdentities.remaining(), "Max identities supply reached");
    require (_llamascapeAmount <= llamascapeLand.remaining(), "Max land supply reached");
    require (msg.value == priceOfRequest(_gridcraftAmount, _llamascapeAmount, _bundle), "Wrong amount sent");
    require (msg.sender == tx.origin, "bm8gcm9ib3Rz");

    if (_bundle){
      require (bundlesAvailable > 0, "Bundles exhausted");
      require (!bundleMint[msg.sender], "One bundle per wallet");
      unchecked{ --bundlesAvailable; }
      bundleMint[msg.sender] = true;
    } 
    if (_gridcraftAmount > 0){
      require ( identityMints[msg.sender] + _gridcraftAmount <= identityMax, "Exceeds allowance" );
      unchecked { identityMints[msg.sender] += _gridcraftAmount; }
      gridcraftIdentities.saleMint(msg.sender, _gridcraftAmount, _stake);
    }
    if (_llamascapeAmount > 0){
      require ( landMints[msg.sender] + _llamascapeAmount <= landMax, "Exceeds allowance" );
      unchecked { landMints[msg.sender] += _llamascapeAmount; }
      llamascapeLand.saleMint(msg.sender, _llamascapeAmount, _stake);
    }

  }

  function llamaverseSaleUnstaked(uint256[] memory _llamaVerseIds, uint256 _boostsAmount, bool _stake, bytes memory _signature) external payable {
    require (allowSaleIsActive || publicSaleIsActive, "Not active");
    uint256 amount = _llamaVerseIds.length;
    require ( amount <= llamascapeLand.remaining(), "Max land supply reached");
    require ( msg.sender == tx.origin, "bm8gcm9ib3Rz");

    if (_boostsAmount > 0){
      require(amount == _boostsAmount, "Can mint as many NFTs as boosts owned");
      bytes32 hash = hashBoostTransaction(_msgSender(), _boostsAmount);
      require(matchSignerAdmin(signTransaction(hash), _signature), "Signature mismatch");
      require(msg.value == 0, "Mint is free");
      unchecked { landFreeMints += amount; }
    } else {
      require(msg.value == amount * landPrice, "Wrong amount sent");
    }

    for (uint i; i < amount; ) {
      require ( LlamaVerse.ownerOf(_llamaVerseIds[i]) == msg.sender, "Llamaverse id not owned");
      require ( !llamaVerseIdUsed[_llamaVerseIds[i]], "Id already used");
      llamaVerseIdUsed[_llamaVerseIds[i]] = true;
      unchecked { ++i; }
    }
    llamascapeLand.saleMint(msg.sender, amount, _stake);
  }

  function llamaverseSaleStaked(uint256 _amount, uint256 _boostsAmount, bool _stake, bytes memory _signature) external payable {
    require (allowSaleIsActive || publicSaleIsActive, "Not active");
    require ( _amount <= llamascapeLand.remaining(), "Max land supply reached");
    require ( msg.sender == tx.origin, "bm8gcm9ib3Rz");

    (uint256[] memory llamas, , , , ) = LlamaStake.getStakedTokens(msg.sender);

    if (_boostsAmount > 0){
      require(_amount == _boostsAmount, "Can mint as many NFTs as boosts owned");
      bytes32 hash = hashBoostTransaction(_msgSender(), _boostsAmount);
      require(matchSignerAdmin(signTransaction(hash), _signature), "Signature mismatch");
      require(msg.value == 0, "Mint is free");
      unchecked { landFreeMints += _amount; }
    } else {
      require(msg.value == _amount * landPrice, "Wrong amount sent");
    }

    bool good;
    uint unusedLlamas;
    for (uint i; i < llamas.length; ) {
      if (!llamaVerseIdUsed[llamas[i]]){
        unchecked{ ++unusedLlamas; }
        llamaVerseIdUsed[llamas[i]] = true;
        if (unusedLlamas == _amount){
          good = true;
          break;
        }
      }
      unchecked { ++i; }
    }
    require(good, "Not enough unused staked llamas");
    llamascapeLand.saleMint(msg.sender, _amount, _stake);
  }


  // viewers

  function priceOfRequest(uint256 _gridcraftAmount, uint256 _llamascapeAmount, bool _bundle) public view returns(uint256 price) {
    price = _gridcraftAmount * identityPrice + _llamascapeAmount * landPrice;
    if (_bundle) {
      unchecked { price -= bundleSave; }
    }
  }

  function gridcraftTotalSupply() external view returns(uint256) {
    return gridcraftIdentities.totalSupply();
  }

  function llamascapeTotalSupply() external view returns(uint256) {
    return llamascapeLand.totalSupply();
  }

  function stakedLlamasUnused(address _user) public view returns(uint256 unused) {
    (uint256[] memory llamas, , , , ) = LlamaStake.getStakedTokens(_user);
    for (uint i; i < llamas.length ; ) {
      if (!llamaVerseIdUsed[llamas[i]]){
        unchecked { ++unused; }
      }
      unchecked { ++i; }
    }
  }

  // Owner setters

  function withdraw() external {
    require(msg.sender == withdrawWallet || msg.sender == owner(), "Not allowed");

    uint balance = address(this).balance;
    payable(withdrawWallet).transfer(balance);
  }

  function toggleAllowSale() external onlyOwner {
    allowSaleIsActive = !allowSaleIsActive;
  }

  function togglePublicSale() external onlyOwner {
    publicSaleIsActive = !publicSaleIsActive;
  }

  function setGridcraftIdentitiesAddress(address _gridcraftIdentitiesAddress) external onlyOwner {
    gridcraftIdentities = INFT(_gridcraftIdentitiesAddress);
  }

  function setLlamascapeLandAddress(address _llamascapeLandAddress) external onlyOwner {
    llamascapeLand = INFT(_llamascapeLandAddress);
  }

  function setPrices(uint256 _newIdentityPrice, uint256 _newLandPrice, uint256 _newDiscount) external onlyOwner {
    identityPrice = _newIdentityPrice;
    landPrice = _newLandPrice;
    bundleSave = _newDiscount;
  }

  function setSigner(address _newSigner) external onlyOwner {
    signer = _newSigner;
  }

  function setMaxIdentitiesPerWallet(uint256 _max) external onlyOwner {
    identityMax = _max;
  }

    function setMaxLandPerWallet(uint256 _max) external onlyOwner {
    landMax = _max;
  }

  // ECDSA related

  function hashTransaction(address _sender, uint256 _gridcraftAmount, uint256 _llamascapeAmount, bool _bundle, uint256 _wl) public pure returns (bytes32 _hash) {
    _hash = keccak256(abi.encode(_sender, _gridcraftAmount, _llamascapeAmount, _bundle, _wl));
  }

  function hashBoostTransaction(address _sender, uint256 _boostsAmount) public pure returns (bytes32 _hash) {
    _hash = keccak256(abi.encode(_sender, _boostsAmount));
  }
	
  function signTransaction(bytes32 _hash) public pure returns (bytes32) {
	  return _hash.toEthSignedMessageHash();
  }

  function matchSignerAdmin(bytes32 _payload, bytes memory _signature) public view returns (bool) {
	  return signer == _payload.recover(_signature);
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface INFT {
  function saleMint(address _recepient, uint256 _amount, bool stake) external;
  function transferFrom(address from, address to, uint256 tokenId) external;
  function tokensOfOwner(address owner) external view returns (uint256[] memory);
  function totalSupply() external view returns (uint256);
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function remaining() external view returns (uint256 nftsRemaining);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC1155 {
  function balanceOf(address account, uint256 id) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ILlamaZoo {
  function getStakedTokens(address account) external view returns (uint256[] memory llamas, uint256 pixletCanvas, uint256 llamaDraws, uint128 silverBoosts, uint128 goldBoosts);
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