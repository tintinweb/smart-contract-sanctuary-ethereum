// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @title YK
/// Lorem ipsum dolor sit amet, consectetur adipiscing elit.
/// @author Omnes Blockchain, Copyright © , 2022, the MIT License
/// (https://github.com/OmnesBlockchainDev/{INSERT_REPO})

import { ERC721 as ERC721S, ERC721TokenReceiver } from "./solmate/ERC721.sol";
import { Strings } from "./utils/Strings.sol";
import { ReentrancyGuard } from "./solmate/ReentrancyGuard.sol";
import { Auth, Authority} from "./solmate/Auth.sol";
//import  "./royalties/RoyaltiesBase.sol";
import "./royalties/ERC2981V2.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./utils/ECDSA.sol";


contract Ykteste is
    ERC721S,
    ERC721TokenReceiver,
    ReentrancyGuard, ERC2981, Context,
    Auth(msg.sender, Authority(address(0)))
{
    using Strings for uint256;
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    address private signerAddress;
    ////////////////////////////////////////////////////////////////
    //                           EVENTS                           //
    ////////////////////////////////////////////////////////////////

    event Mint(address indexed to, uint256 indexed id);
    //event MarketplaceApprovalSet(bool indexed approval);
    // event WithdrawalMinSet(uint256 indexed min);
    event PublicMintState(bool indexed state);
    event PausedState(bool indexed state);

    ////////////////////////////////////////////////////////////////
    //                           ERRORS                           //
    ////////////////////////////////////////////////////////////////

    error InvalidAddress();
    error NotMinted(uint256 wrongId);
    error WrongPrice();
    error MaxSupplyExceeded();
    error PublicMaxExceeded();
    error OnlyEOA();
    error publicMintOff();
    error TransferFailed();
    error AlreadyMinted();
    error AlreadyClaimed();
    error MaxWhitelistMintExceeded();
    error PreSaleInactive();
    error PublicSaleInactive();
    error DirectMintFromBotNotAllowed();
    //error paused();

    ////////////////////////////////////////////////////////////////
    //                        MODIFIERS                           //
    ////////////////////////////////////////////////////////////////

    modifier commonTrileans(uint256 _id) {
        // impossible??
        // if (msg.sender == address(0)) revert InvalidAddress();
        if (_ownerOf[_id] != address(0)) revert AlreadyMinted();
        if (msg.sender != tx.origin) revert OnlyEOA();
        // if (!matchAddresSigner(hashTransaction(msg.sender), signature)) 
        //OBS: ESTUDE OS EIPS ABAIXO 
        //precisa importar ^ EIP 712 E ERC1271 
        //Approve with permit - como é utilizado o matchAddressSigner do if acima 
        // revert DirectMintFromBotNotAllowed();
        if (msg.value != PRICE) revert WrongPrice();
        if (
            /* _id + */
            totalSupply.current() + 1 > MAX_SUPPLY
        ) revert MaxSupplyExceeded();
        _isThisOG();
        _;
    }

    modifier publicTrileans() {
        if (publicMintMinted > MAX_PUBLIC) revert PublicMaxExceeded();
        if (!publicOn) revert publicMintOff();
        if (publicMintClaimed[msg.sender]++ > MAX_PER_TX)
            revert AlreadyClaimed();
        _;
    }

    //ANALISAR E MODIFICAR
    modifier whitelistTrileans() {
      if (preSaleMintMinted > MAX_WHITELIST) revert MaxWhitelistMintExceeded();
      if (whitelistClaimedAddress[_msgSender()]++ > MAX_PER_TX)
            revert AlreadyClaimed();
        if(!isPreSaleLive) revert PreSaleInactive();
      _;
    }

    ////////////////////////////////////////////////////////////////
    //                           STORAGE                          //
    ////////////////////////////////////////////////////////////////

    /// @custom:immutable
    /// @dev OpenSea Proxy Registry address.
    // address public constant openSeaProxyRegistry = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    /// @dev LooksRare Transfer Manager (ERC721) address.
    // address public constant looksRareTransferManager = 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e;
    /// @dev Self reference for delegatecall prevention.
    address private immutable og;

    address public constant YkWALLET = 
    0x34C67D62525dA9B90208E21B3360F4b74a52085c;
    /// @custom:constant
    uint256 public constant PRICE = 0.009 ether;
    uint256 public constant MAX_SUPPLY = 4444;
    uint256 public constant MAX_WHITELIST = 3000;
    /// @dev Equals to MAX_SUPPLY - MAX_WHITELIST.
    uint256 public constant MAX_PUBLIC = 1444;
    uint256 public constant MAX_PER_TX = 1;

    /// @notice Returns true if marketplace addresses are whitelisted in {isApprovedForAll}.
    /// @dev Defaults to true. State can be switched via {setMarketplaceApprovalForAll}.
    // bool public marketPlaceApprovalForAll = true;
    /// @notice Returns true if public mint is active.
    /// @dev Defaults to false. State can be switched via {setPublicOn}.
    bool public publicOn = false;

    bool public paused = true; //START PAUSED, DISABLE
    uint256 private deployTime;

    ////////////////////////////////////////////////////////////////
    //               PRESALE-WHITELIST & PUBLICSALE               //
    ////////////////////////////////////////////////////////////////

    
    //PRE-SALE WHITELIST
    bytes32 private merkleRoot;
    mapping(address => bool) public whitelistClaimed;
    mapping(address=> uint256) public whitelistClaimedAddress;
    uint256 public preSaleMintMinted;
    bool public isPreSaleLive;
    bool public whitelistMintEnabled = false;
    

   //PUBLIC-SALE
    uint256 public publicSaleStartTime;
    uint256 public publicMintMinted;
    mapping(address => uint256) public publicMintClaimed;

    
    ////////////////////////////////////////////////////////////////
    //                         METADADO                          //
    ////////////////////////////////////////////////////////////////

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;
    string public baseURI;
    bool public revealed = false;

    ////////////////////////////////////////////////////////////////
    //                         CONSTRUCTOR                        //
    ////////////////////////////////////////////////////////////////

    constructor(
        //string memory _name,
        // string memory _symbol,
        //string memory _baseURI
        string memory _hiddenMetadataUri
        // maybe hardcoding those as constant might be better
        // remove invalid address trilean if so
        // address _openSeaProxyRegistry,
        // address _looksRareTransferManager
        // uint256 _withdrMin
    ) ERC721S("NFTminimunRoy", "NFTm") {
        // if (
        //     _openSeaProxyRegistry == address(0) ||
        //     _looksRareTransferManager == address(0)
        // ) revert InvalidAddress();
        setHiddenMetadataUri(_hiddenMetadataUri);
        og = address(this);
        //baseURI = _baseURI;

        // openSeaProxyRegistry = _openSeaProxyRegistry;
        // looksRareTransferManager = _looksRareTransferManager;

        // withdrMin = _withdrMin;
        deployTime = block.timestamp;
    }
    Counters.Counter public totalSupply;
    ////////////////////////////////////////////////////////////////
    //                         CORE FX                            //
    ////////////////////////////////////////////////////////////////

    // add gas limit/control modifier
    function PublicMint(bytes calldata signature)
        external
        payable
        nonReentrant
        commonTrileans(totalSupply.current())
        publicTrileans
    {
        require(!paused, "The contract is paused!");
        if (!matchAddresSigner(hashTransaction(msg.sender), signature))
            revert DirectMintFromBotNotAllowed();

        unchecked {
            publicMintMinted += 1;
            publicMintClaimed[msg.sender] += 1;
        }
        totalSupply.increment();
       // setRoyalties(totalSupply.current(), payable(YkWALLET), 750);
       _safeMint(_msgSender(), totalSupply.current());

        emit Mint(msg.sender, totalSupply.current());
        emit Transfer(address(this), msg.sender,totalSupply.current());
    }
    function whitelistMint(uint256 _id, bytes32[] calldata _merkleProof) 
    public payable 
    commonTrileans(_id) whitelistTrileans 
    {
    require(!paused, "The contract is paused!");
    require(!whitelistClaimed[_msgSender()], "Address already claimed!");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

    whitelistClaimed[_msgSender()] = true;
    unchecked {
            preSaleMintMinted += 1;
            whitelistClaimedAddress[msg.sender] += 1;
        }
    totalSupply.increment();
   // setRoyalties(totalSupply.current(), payable(YkWALLET), 750); //mudar endereço
        

    _safeMint(_msgSender(), totalSupply.current());
    emit Mint(msg.sender, totalSupply.current());
    emit Transfer(address(this), msg.sender,totalSupply.current());
  }

  function mintForAddress(address _receiver) public payable
        publicTrileans requiresAuth commonTrileans(totalSupply.current()){
    _safeMint(_receiver,totalSupply.current());
    emit Mint(msg.sender, totalSupply.current());
    emit Transfer(address(this), msg.sender,totalSupply.current());
  }

    function getRemainingSupply() public view returns (uint256) {
        unchecked { return MAX_SUPPLY - totalSupply.current(); }
    }
    function isPublicSaleLive() public view returns (bool) {
        return
            publicSaleStartTime > 0 && block.timestamp >= publicSaleStartTime;
    }

    function matchAddresSigner(bytes32 hash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return signerAddress == hash.recover(signature);
    }

    function hashTransaction(address sender) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(sender))
            )
        );
        return hash;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) 
    public requiresAuth {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) 
  public requiresAuth {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) 
  public requiresAuth {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) 
  public requiresAuth {
    paused = _state;
    emit PausedState(_state);
  }

    // @notice sets the recipient of the royalties
    /// @param recipient address of the recipient
    function setRoyaltyRecipient(address recipient) public requiresAuth {
        _royaltyRecipient = recipient;
    }

    /// @notice sets the fee of royalties
    /// @dev The fee denominator is 10000 in BPS.
    /// @param fee fee
    /*
        Example

        This would set the fee at 5%
        ```
        KeyUnlocks.setRoyaltyFee(500)
        ```
    */
    function setRoyaltyFee(uint256 fee) public requiresAuth {
        _royaltyFee = fee;
    }


 function supportsInterface(bytes4 interfaceId) public pure virtual override(ERC721S, ERC2981) returns (bool) {
        return ERC721S.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    } 
    
    function setRevealed(bool _state) public requiresAuth {
    revealed = _state;
  }

    function withdraw() external requiresAuth {
        _transferETH(msg.sender, address(this).balance);

       
    }

    /// @dev Switches public mint state through {mint}.
    function setPublicOn(bool _publicOn)
        external
        requiresAuth
    {
        publicOn = _publicOn;
        if(publicOn = true){
            publicSaleStartTime = block.timestamp;
        }

        emit PublicMintState(_publicOn);
    }

    ////////////////////////////////////////////////////////////////
    //                         VIEW FX                            //
    ////////////////////////////////////////////////////////////////

    function tokenURI(uint256 _Id) public view virtual override returns (string memory) {
     if (_ownerOf[_Id] == address(0)) revert NotMinted(_Id);
    if (revealed == false) {
      return hiddenMetadataUri;
    } else { //inseri o else para aparecer o código de revelação

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _Id.toString(), uriSuffix))
        : "";
  }
  }

   

    // ////////////////////////////////////////////////////////////////
    // //                     INTERNAL/PRIVATE                       //
    // ////////////////////////////////////////////////////////////////

    function _transferETH(address to, uint256 value)
        internal
    {
        if (msg.value <= 0x00) revert TransferFailed();
        (bool success, ) = to.call{ value: value }("");
        if (!success) revert TransferFailed();
    }

    /// @dev Prevents delegatecalls
    function _isThisOG() private view {
        require(address(this) == og);
    }

    function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

    function setSignerAddress(address _signerAddress) external requiresAuth {
        signerAddress = _signerAddress;
    }


     ////////////////////////////////////////////////////////////////
     //                     STAKING IN NFT                         //
    ////////////////////////////////////////////////////////////////


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "./Strings.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @title Minimalist ERC2981 implementation.
/// @notice To be used within Quantum, as it was written for its needs.
/// @author exp.table
abstract contract ERC2981 {

    /// @dev one global fee for all royalties.
    uint256 internal _royaltyFee;
    /// @dev one global recipient for all royalties.
    address internal _royaltyRecipient;

    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view virtual returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        receiver = _royaltyRecipient;
        royaltyAmount = (salePrice * _royaltyFee) / 10000;
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x2a55205a; // ERC165 Interface ID for ERC2981
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(
        address indexed user,
        address indexed newOwner
    );

    event AuthorityUpdated(
        address indexed user,
        Authority indexed newAuthority
    );

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() {
        require(
            isAuthorized(msg.sender, msg.sig),
            "UNAUTHORIZED"
        );

        _;
    }

    function isAuthorized(address user, bytes4 functionSig)
        internal
        view
        virtual
        returns (bool)
    {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return
            (address(auth) != address(0) &&
                auth.canCall(
                    user,
                    address(this),
                    functionSig
                )) || user == owner;
    }

    function setAuthority(Authority newAuthority)
        public
        virtual
    {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(
            msg.sender == owner ||
                authority.canCall(
                    msg.sender,
                    address(this),
                    msg.sig
                )
        );

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner)
        public
        virtual
        requiresAuth
    {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/// @title Uint256 to String converter.
/// @author OpenZeppelin
/// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol)
/// @author Inspired by Oraclize
/// (https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol)
library Strings {
    /// @dev Converts a `uint256` to its ASCII `string` decimal representation.
    function toString(uint256 value)
        internal
        pure
        returns (string memory)
    {
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
            buffer[digits] = bytes1(
                uint8(48 + uint256(value % 10))
            );
            value /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id)
        public
        view
        virtual
        returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id)
        public
        view
        virtual
        returns (address owner)
    {
        require(
            (owner = _ownerOf[id]) != address(0),
            "NOT_MINTED"
        );
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256)
    {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id)
        public
        virtual
    {
        address owner = _ownerOf[id];

        require(
            msg.sender == owner ||
                isApprovedForAll[owner][msg.sender],
            "NOT_AUTHORIZED"
        );

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual {
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
            msg.sender == from ||
                isApprovedForAll[from][msg.sender] ||
                msg.sender == getApproved[id],
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
        bytes calldata data
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

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

/// @notice {_mint} kept since removing unused internal functions will have no effect on contract size.
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

/// @notice {_burn} kept since removing unused internal functions will have no effect on contract size.
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

    function _safeMint(address to, uint256 id)
        internal
        virtual
    {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    id,
                    ""
                ) ==
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
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
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