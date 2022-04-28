// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,.%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@*,,,,,,,,,,,,,,,,,,,,,,..,,,,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@,,,,*,,,,,,,,,,,,,,,,,,,..,,,,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,.,,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,*,,,,,,,.,,.,,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@&,,,,,,,,,,,,,,,,,,,,,,,,,,,,,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,.,,,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@/     ,,,,,,,,,,,,,,,,,,,,,,,,.........,,     *@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@(..... ,,,,,,,,,,,,,,,,,,,,,,,,,,...,,,,,/......&@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@#//////.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*/,,,,,,,@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@%*//**/(//**,,,,,,,.....................,**//#######@@@@@@@@@@@@@@@@@
//@@@@@@@@@@#(##((##,,,,,,,,,,,,,,,,,,,**,,*,,,,,........./#######@@@@@@@@@@@@@@@@
//@@@@@@@@@%#####,,,*,,,,.,,,####*##(%%#%%%%&%%%%%,**,........#####@@@@@@@@@@@@@@@
//@@@@@@@@/###,,****,,,*%(#%#%%##%#########%%%%&&&&&&&%,*,.......###[email protected]@@@@@@@@@@@@
//@@@@@@@(#/,****,,,#(##%//####################%%%%&&&&@&%&/*......(#*@@@@@@@@@@@@
//@@@@@@#(*****.,((#/#####*%*#####%*######%%######&%#&&&&&@&&#*......((@@@@@@@@@@@
//@@@@@#*****.,(/#%########%#.######&/*&*%*######*#/#%%%&&&&&@%&*......(@@@@@@@@@@
//@@@@(****,,//(%*###########./(#((((((((((((###*%####%%%%&&&&&&((*.....(@@@@@@@@@
//@@@*****.,(*/*,############(#,(#%*,(%,%,%,(,*#,#######%%%%%&%%&(&*.....*@@@@@@@@
//@@/****.*//#,###,##,#####(((#,%,%*,,,,,,,/*,#,((######%,%&#&&&%&&&/[email protected]@@@@@@
//@@****,*//((########**###*#((((###((,#(//((((((((###%&/*((#&&&&&@&&*[email protected]@@@@@@
//@/****,,.(###########((((#%*#*#########(((((###&(((#/(%%%%%%%%%&&&&#,. [email protected]@@@@@
//@//**,*//############((((((((#((//#######%&/*##/(########%%&%%%%&&&&*.  ..#%#@@@
//@//**.,/.##%(##%&*##((((((((((###(/((#(////(############%/&%%&%&&&&%*.  ..###,.*
//@//**.,,,##%&/#%(##((((((((((##%&*/((#/**/(((((((((#####%&#&%(&&%&&(*.  ..%%% *,
//@//**,,/*##########((((((((((((###%#####(#(((((((((######%%%&%%%%&&&*.  ..###*@@
//@///*,,*,/#####(((((((((((((((((#######((((((((((((######%%%%%%%&&%#,.  [email protected]@@@@@
//@@////,,(/#/########(/(((((((((########(((((((((((###%.#%%%%%%%%&&&*.  [email protected]@@@@@@
//@@/////.,,/#,###,##*##((((((#####%%%#####((((((((#####%.%&(%%%(&&&*[email protected]@@@@@@
//@@@///((.,//(*,######((((((#####%%%######((((((#######%%%%%&((&&&*[email protected]@@@@@@@
//@@@@///(/,,*/.%*#######((##//#####%######(((##*#####%%%%%%%%&##(*.....,@@@@@@@@@
//@@@@@#//((/.,/*(%########%#/#(#################*#*#%%%%%%&&&&&*......(@@@@@@@@@@
//@@@@@@#///((/.,/((######,%*#######&(##&*########&%(%%%%&&&/&*,.....,(@@@@@@@@@@@
//@@@@@@@##//////,,,(*/##**#########&/##&/#####%%%%%%(&&#&#*,.......#(@@@@@@@@@@@@
//@@@@@@@@###(//////,,,*(#*#########%###%%#%%#%%&&&%&&//**.......(##(@@@@@@@@@@@@@
//@@@@@@@@@#####///////*,,,,*(.(#/*#(%%%%%#%/#(#%%/**,........,####/@@@@@@@@@@@@@@
//@@@@@@@@@@########/////****,,,,,,********,**,.,..........#######/@@@@@@@@@@@@@@@
//@@@@@@@@@@@(#######@///*******,,,,,,,,,,,,,.........,/(@(((((((/@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@(((((((#,,,,,,,,,,***,,,,,,,,,,,.,,,,,,,,/(#///////@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@(((((((,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*((//////@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@((((((,,,,,,,,,,,,,,,,,,,,,,,,,,.,.,.,,,,//((//@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@/#(*,,,,,,,,,,,,,,,,,,,,,,,,,.......,./*/@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@*,,,,,,,,,,,,.,,,,,,,,,,.,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@*,***,,,,,,,*,,,..,,,,,,,,,,.....,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@,*//,,,,**,,,,,,,.,*,...,,,.,,.,,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@*,*/*,.,,,,,,,,,,*,,,,,,,,..,,,,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@&,,*//*,,,,,,,,,,,,,,,,,,,,.***,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@*,,*//**,,,,,,,,,,,,,,,,..***,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@*,,,//*******,,,.,,,*,.,***,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

contract NIMANYClubWatches is ERC721, Ownable {
  constructor() ERC721("NIMANYClubWatches", "NNY") {}

  string private uri = "https://assets.bossdrops.io/immortals/";

  string private claimedUri;

  // the initial sale will be 1810 tokens, an unknown amount more will be created via the burning mechanism.
  uint public constant MAX_TOKENS_FOR_SALE = 1810;

  // mapping to keep track of id's that have claimed a gold watch nft
  mapping(uint256 => bool) public claimedGold;

  // Only 10 nfts can be purchased per transaction.
  uint public constant maxNumPurchase = 3;

  // is the metadata frozen?
  bool public frozen = false;

  // address of the wallet that will sign transactions for the burning mechanism
  address public constant signerAddress = 0x7d1c1c1Fb80897fa9e08703faedBF8A6A25582f8;

  // X amount of NFTs will be distributed to NIMANY during the mint
  address public constant NIMANYAddress = 0xd41cB7D50B9288137cBFd9CD52613cdC8692c371;

  /**
  * The state of the sale:
  * 0 = closed
  * 1 = presale
  * 2 = public sale
  */
  uint public saleState = 0;

  // Early mint price is 0.1 ETH.
  uint256 public priceWei = 0.1 ether;

  uint256 public pricePublicWei = 0.125 ether;

  uint public numMinted = 0;

  using Strings for uint256;

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_ownerOf[tokenId] != address(0), "NOT_MINTED");

    if (claimedGold[tokenId]) {
      return string(abi.encodePacked(claimedUri, tokenId.toString()));
    } else {
      return string(abi.encodePacked(uri, tokenId.toString()));
    }
  }

  using ECDSA for bytes32;

  function checkPayment(uint256 numToMint) internal {
    uint256 amountRequired = priceWei * numToMint;
    require(msg.value >= amountRequired, "Not enough funds sent");
  }

  function checkPaymentPublic(uint256 numToMint) internal {
    uint256 amountRequired = pricePublicWei * numToMint;
    require(msg.value >= amountRequired, "Not enough funds sent");
  }

  function claimGold(uint tokenId, bytes memory signature) public {
    bytes32 inputHash = keccak256(
      abi.encodePacked(
        msg.sender,
        tokenId,
        "claiming physical"
      )
    );


    bytes32 ethSignedMessageHash = inputHash.toEthSignedMessageHash();
    address recoveredAddress = ethSignedMessageHash.recover(signature);
    require(recoveredAddress == signerAddress, 'Bad signature');

    claimedGold[tokenId] = true;
  }

  function mint(uint num, bytes memory signature) public payable {
    require(saleState > 0, "Sale is not open");

    uint newTotal = num + numMinted;
    require(newTotal <= MAX_TOKENS_FOR_SALE, "Minting would exceed max supply.");

    if (saleState == 1) {

      checkPayment(num);

      bytes32 inputHash = keccak256(
        abi.encodePacked(
          msg.sender,
          num
        )
      );


      bytes32 ethSignedMessageHash = inputHash.toEthSignedMessageHash();
      address recoveredAddress = ethSignedMessageHash.recover(signature);
      require(recoveredAddress == signerAddress, 'Bad signature for eaarly access');
    } else if (saleState == 2 && num > maxNumPurchase) {
      revert("Trying to purchase too many NFTs in one transaction");
    } else {
      checkPaymentPublic(num);
    }

    _mintTo(msg.sender, num);
  }

  function _mintTo(address to, uint num) internal {
    uint newTotal = num + numMinted;
    while(numMinted < newTotal) {
      _mint(to, numMinted);
      numMinted++;
    }
  }

  function burnAndExchange(uint256 tokenId1, uint256 tokenId2, uint256 tokenId3, uint256 tokenId4, bytes memory signature, uint exchType)
    public
  {
    bytes32 inputHash = keccak256(
      abi.encodePacked(
        msg.sender,
        tokenId1,
        tokenId2,
        tokenId3,
        tokenId4,
        exchType
      )
    );


    bytes32 ethSignedMessageHash = inputHash.toEthSignedMessageHash();
    address recoveredAddress = ethSignedMessageHash.recover(signature);
    require(recoveredAddress == signerAddress, 'Bad signature');

    if (exchType == 0) {
      _burn(tokenId1);
      _burn(tokenId2);
      _mintTo(msg.sender, 1);
    } else if (exchType == 1) {
      _burn(tokenId1);
      _burn(tokenId2);
      _burn(tokenId3);
      _burn(tokenId4);
      _mintTo(msg.sender, 1);
    } else if (exchType == 2) {
      _burn(tokenId1);
      _burn(tokenId2);
      _burn(tokenId3);
      _mintTo(msg.sender, 1);
    } else {
      _burn(tokenId1);
      _burn(tokenId2);
      _mintTo(msg.sender, 1);
    }
  }
  
  function totalMinted() public view virtual returns (uint) {
    return numMinted;
  }

  /** OWNER FUNCTIONS */
  function ownerMint(uint num) public onlyOwner {
    _mintTo(msg.sender, num);
  }

  function airdrop(address[] memory addresses) public onlyOwner {
    for (uint i = 0; i < addresses.length; i++) {
       _mintTo(addresses[i], 1);
    }
  }

  function nimanyMint(uint num) public onlyOwner {
    _mintTo(NIMANYAddress, num);
  }
  
  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function setSaleState(uint newState) public onlyOwner {
    require(newState >= 0 && newState <= 2, "Invalid state");
    saleState = newState;
  }

  function setBaseURI(string memory baseURI, uint uriType) public onlyOwner {
    if (frozen) {
      revert("Metadata is frozen");
    }
    if (uriType == 0) {
      uri = baseURI;
    } else {
      claimedUri = baseURI;
    }
  }

  function freezeMetadata() public onlyOwner {
    frozen = true;
  }

  function setMintPrice(uint newPriceWei) public onlyOwner {
    priceWei = newPriceWei;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// edits by jackwb.eth @ layerr.xyz
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

        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

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