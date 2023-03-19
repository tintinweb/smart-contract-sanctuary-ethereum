// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../libraries/interfaces/IRedlionGazette.sol';
import '../libraries/interfaces/IRedlionLegendaryGazette.sol';
import '../libraries/interfaces/IRedlionArtdrops.sol';
import '../libraries/interfaces/IRedlionGazetteManager.sol';
import '../libraries/interfaces/ISubscriptionsManager.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '../libraries/interfaces/ISubscriptions.sol';
import '@paperxyz/contracts/keyManager/IPaperKeyManager.sol';

/**
 * Proxy contract to manage gazettes publishing, minting and claiming.
 * @title Redlion Gazette Manager
 * @author Gui "Qruz" Rodrigues (0xQruz)
 * @dev This contract is upgradeable and the logic can be changed at any given time.
 */
contract RedlionGazetteManager is
  Initializable,
  OwnableUpgradeable,
  PausableUpgradeable,
  IRedlionGazetteManager
{
  using Strings for uint256;
  using ECDSA for bytes32;

  address SUBS; // Redlion Subscriptions Manager
  address RLGA; // Redlion Gazette
  address RLLGA; // Redlion Legendary Gazette
  address AD; // Redlion ArtDrop
  address REDA; // Red subscriptions address
  address COURIER; // COURIER ADDRESS
  address SIGNER; // SIGNER ADDRESS

  mapping(uint => mapping(bytes => bool)) CLAIMS;
  mapping(uint => mapping(bytes => bool)) DELIVERIES;

  uint public GAZETTE_PRICE;

  // PAPER MINT
  IPaperKeyManager paperKeyManager;

  function initialize(
    address _SUBS,
    address _RLGA,
    address _RLLGA,
    address _AD,
    address _SIGNER,
    address _REDA,
    address _COURIER
  ) public initializer {
    SUBS = _SUBS;
    RLGA = _RLGA;
    AD = _AD;
    RLLGA = _RLLGA;
    SIGNER = _SIGNER;
    REDA = _REDA;
    COURIER = _COURIER;
    GAZETTE_PRICE = 2500;
    __Ownable_init();
    __Pausable_init();
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function launchIssue(
    uint256 _issue,
    uint256 _saleSize,
    string memory _uri,
    uint256 _reserve,
    string memory _legendaryUri
  ) external onlyOwner {
    IRedlionGazette RLG = IRedlionGazette(RLGA);
    IRedlionLegendaryGazette RLLG = IRedlionLegendaryGazette(RLLGA);
    RLG.launchIssue(_issue, _saleSize, _uri);
    RLLG.launchAuction(_issue, _reserve, _legendaryUri);
  }

  function mint(
    uint256 _issue,
    uint256 _amount,
    uint256 timestamp,
    bytes memory _signature
  ) external payable whenNotPaused {
    require(block.timestamp < timestamp + 5 minutes, 'INVALID_TIMESTAMP');
    bytes32 inputHash = keccak256(
      abi.encodePacked(
        msg.sender,
        address(this),
        _issue,
        _amount,
        msg.value,
        timestamp
      )
    );
    require(_validSignature(_signature, inputHash), 'BAD_SIGNATURE');
    IRedlionGazette RLG = getRLG();
    uint[] memory mintedIds = RLG.mint(msg.sender, _issue, _amount, false);
    for (uint i = 0; i < mintedIds.length; i++) {
      emit IssueMinted(_issue, mintedIds[i], msg.sender);
    }
  }

  function claim(uint256 _issue) external whenNotPaused {
    require(canClaim(_issue, msg.sender), 'CANNOT_CLAIM');
    ISubscriptionsManager SUBSC = ISubscriptionsManager(SUBS);
    IRedlionGazette RLG = IRedlionGazette(RLGA);
    ISubscriptionsManager.SubInfo memory subInfo = SUBSC.subscriptionInfo(
      msg.sender
    );
    CLAIMS[_issue][subInfo.subId] = true;
    uint[] memory mintedIds = RLG.mint(msg.sender, _issue, 1, true);

    for (uint i = 0; i < mintedIds.length; i++) {
      emit IssueClaimed(_issue, mintedIds[i], msg.sender);
    }
  }

  function claimArtdrop(uint[] calldata _tokenIds) external whenNotPaused {
    IRedlionArtdrops ADC = IRedlionArtdrops(AD);
    for (uint i = 0; i < _tokenIds.length; i++) {
      uint tId = _tokenIds[i];
      ADC.mint(msg.sender, tId);
      emit ArtdropClaimed(getRLG().tokenToIssue(tId), tId, msg.sender);
    }
  }

  function deliverIssues() external onlyCourier returns (DeliveryState memory) {
    ISubscriptions REDC = ISubscriptions(REDA);
    IRedlionGazette RLG = IRedlionGazette(RLGA);
    uint delivered = 0;
    uint total = 0;
    uint received = 0;
    address[] memory subsList = REDC.subscribers();

    for (uint i = 0; i < subsList.length; i++) {
      address target = address(subsList[i]);
      if (target != address(0)) {
        bytes memory subId = REDC.subscriptionId(target);
        uint[] memory issueList = RLG.issueList();
        for (uint z = 0; z < issueList.length; z++) {
          uint issueId = issueList[z];
          if (!DELIVERIES[issueId][subId]) {
            if (delivered < 10) {
              DELIVERIES[issueId][subId] = true;
              delivered++;
              uint[] memory mintedIds = RLG.mint(target, issueId, 1, true);

              for (uint y = 0; y < mintedIds.length; y++) {
                emit IssueDelivered(issueId, mintedIds[y], target);
              }
            }
          } else {
            received++;
          }
          total++;
        }
      }
    }

    return DeliveryState(delivered, received, total);
  }

  /*///////////////////////////////////////////////////////////////
                             PAPER
  ///////////////////////////////////////////////////////////////*/
  function setupPaper(
    address _paperAddress,
    address _token
  ) external onlyOwner {
    paperKeyManager = IPaperKeyManager(_paperAddress);
    require(
      paperKeyManager.register(_token),
      'Error registering PaperKeyManager token.'
    );
  }

  modifier onlyPaper(
    bytes32 _hash,
    bytes32 _nonce,
    bytes calldata _signature
  ) {
    bool success = paperKeyManager.verify(_hash, _nonce, _signature);
    require(success, 'Failed to verify signature.');
    _;
  }

  function paperMint(
    address _to,
    uint256 _issue,
    uint256 _amount,
    bytes32 _nonce,
    bytes calldata _signature
  )
    external
    payable
    onlyPaper(keccak256(abi.encode(_to, _issue, _amount)), _nonce, _signature)
  {
    IRedlionGazette RLG = getRLG();
    uint[] memory mintedIds = RLG.mint(_to, _issue, _amount, false);
    for (uint i = 0; i < mintedIds.length; i++) {
      emit IssueMinted(_issue, mintedIds[i], _to);
    }
  }

  /*///////////////////////////////////////////////////////////////
                             UTILITY
  ///////////////////////////////////////////////////////////////*/

  function canClaim(
    uint256 _issue,
    address _target
  ) public view returns (bool) {
    ISubscriptionsManager SUBSC = ISubscriptionsManager(SUBS);
    IRedlionGazette RLG = IRedlionGazette(RLGA);
    ISubscriptionsManager.SubInfo memory subInfo = SUBSC.subscriptionInfo(
      _target
    );

    if (!subInfo.subscribed) return false;

    if (subInfo.subType == ISubscriptionsManager.SubType.SUPER) return false;

    if (CLAIMS[_issue][subInfo.subId]) return false;

    if (!RLG.isIssueLaunched(_issue)) return false;

    return RLG.timeToIssue(subInfo.timestamp).issue <= _issue;
  }

  function canDeliver(uint _issue, address _target) public view returns (bool) {
    ISubscriptionsManager SUBSC = ISubscriptionsManager(SUBS);
    IRedlionGazette RLG = IRedlionGazette(RLGA);
    ISubscriptionsManager.SubInfo memory subInfo = SUBSC.subscriptionInfo(
      _target
    );
    if (!RLG.isIssueLaunched(_issue)) return false;

    if (!subInfo.subscribed) return false;

    if (subInfo.subType != ISubscriptionsManager.SubType.SUPER) return false;

    return !DELIVERIES[_issue][subInfo.subId];
  }

  function claimableIssues(
    address _target
  ) public view returns (bool[] memory) {
    ISubscriptionsManager SUBSC = ISubscriptionsManager(SUBS);
    IRedlionGazette RLG = IRedlionGazette(RLGA);
    ISubscriptionsManager.SubInfo memory subInfo = SUBSC.subscriptionInfo(
      _target
    );
    IRedlionGazette.Issue memory currentIssue = RLG.timeToIssue(
      block.timestamp
    );

    bool[] memory claimable = new bool[](currentIssue.issue + 1);

    if (!subInfo.subscribed) return claimable;

    for (uint i = currentIssue.issue; i > 120; i--) {
      bool claimability = canClaim(i, _target);
      claimable[i] = claimability;
    }

    return claimable;
  }

  function deliverableIssues(
    address _target
  ) public view returns (bool[] memory) {
    ISubscriptionsManager SUBSC = ISubscriptionsManager(SUBS);
    IRedlionGazette RLG = IRedlionGazette(RLGA);
    ISubscriptionsManager.SubInfo memory subInfo = SUBSC.subscriptionInfo(
      _target
    );
    IRedlionGazette.Issue memory currentIssue = RLG.timeToIssue(
      block.timestamp
    );

    bool[] memory deliverable = new bool[](currentIssue.issue + 1);

    if (!subInfo.subscribed) return deliverable;

    for (uint i = currentIssue.issue; i > 120; i--) {
      bool claimability = canDeliver(i, _target);
      deliverable[i] = claimability;
    }

    return deliverable;
  }

  /*///////////////////////////////////////////////////////////////
                              OWNER
  ///////////////////////////////////////////////////////////////*/

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function courierMint(
    address _to,
    uint _issue,
    uint _amount
  ) external onlyCourier {
    IRedlionGazette RLG = getRLG();
    uint[] memory mintedIds = RLG.mint(_to, _issue, _amount, false);
    for (uint i = 0; i < mintedIds.length; i++) {
      emit IssueMinted(_issue, mintedIds[i], _to);
    }
  }

  /*///////////////////////////////////////////////////////////////
                             SETTERS
  ///////////////////////////////////////////////////////////////*/

  function setSUBS(address _address) external onlyOwner {
    _requireValidSetterAddress(_address, SUBS);
    SUBS = _address;
  }

  function setPrice(uint _price) external onlyOwner {
    GAZETTE_PRICE = _price;
  }

  function setRLGA(address _address) external onlyOwner {
    _requireValidSetterAddress(_address, RLGA);
    RLGA = _address;
  }

  function setRLLGA(address _address) external onlyOwner {
    _requireValidSetterAddress(_address, RLLGA);
    RLLGA = _address;
  }

  function setREDA(address _address) external onlyOwner {
    _requireValidSetterAddress(_address, REDA);
    REDA = _address;
  }

  function setCOURIER(address _address) external onlyOwner {
    _requireValidSetterAddress(_address, COURIER);
    COURIER = _address;
  }

  function setSIGNER(address _address) external onlyOwner {
    _requireValidSetterAddress(_address, SIGNER);
    SIGNER = _address;
  }

  function setAD(address _address) external onlyOwner {
    _requireValidSetterAddress(_address, AD);
    AD = _address;
  }

  function getRLG()
    public
    view
    override(IRedlionGazetteManager)
    returns (IRedlionGazette)
  {
    return IRedlionGazette(RLGA);
  }

  function getRLLG()
    public
    view
    override(IRedlionGazetteManager)
    returns (IRedlionLegendaryGazette)
  {
    return IRedlionLegendaryGazette(RLLGA);
  }

  /*///////////////////////////////////////////////////////////////
                             INTERNALS
  ///////////////////////////////////////////////////////////////*/

  modifier onlyCourier() {
    require(msg.sender == COURIER, 'CALLER_NOT_COURIER');
    _;
  }

  function _requireValidSetterAddress(
    address _address,
    address variable
  ) internal pure {
    require(_address != address(0), 'ZERO_ADDRESS_NOT_ALLOWED');
    require(_address != variable, 'ADDRESS_UNCHANGED');
  }

  function _validSignature(
    bytes memory signature,
    bytes32 msgHash
  ) internal view returns (bool) {
    return msgHash.toEthSignedMessageHash().recover(signature) == SIGNER;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';
interface IRedlionLegendaryGazette is IERC721Upgradeable {
  /**
   * Event emitted when a new auction is launched
   * @param issueId ID of the new auction
   * @param startTime Timestamp of when the auction starts
   */
  event AuctionLaunched(uint indexed issueId, uint startTime);

  /**
   * Event emitted when a new bid is placed
   * @param issueId ID of the auction the bid was placed in
   * @param bidder Address of the bidder
   * @param price Value of the bid
   */
  event AuctionBid(uint indexed issueId, address indexed bidder, uint price, uint totalBid);

  /**
   * Event emitted when an auction ends
   * @param issueId ID of the auction that ended
   * @param winner Address of the winning bidder
   * @param winningBid Data for the winning bid
   */
  event AuctionEnded(uint indexed issueId, address indexed winner, Bid winningBid);

  struct Bid {
    uint value;
    uint time;
    address bidder;
    uint fee;
  }
  struct BidderIndex {
    uint index;
    bool set;
  }

  struct Reward {
    address bidder;
    uint value;
  }
  struct Issue {
    uint issueNumber;
    uint256 reservePrice;
    string uri;
    Bid[] bids;
    Bid[] bidHistory;
    uint startTime;
    uint endTime;
    bool refunded;
    Reward[] rewards;
  }

  function claim(uint _issue) external;

  function launchAuction(
    uint256 _issue,
    uint256 _reserve,
    string memory _uri
  ) external;

  function isAuctionLaunched(uint256 _issue) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';

interface IRedlionGazette is IERC721Upgradeable {
  event MintedIssue(address user, uint issue, uint tokenId);

  event IssueLaunched(uint256 indexed issue, uint256 saleSize);

  struct Issue {
    uint totalSupply;
    uint saleSize; // quantity of issues to sell
    uint timestamp;
    string uri;
    uint issue;
    bool openEdition;
  }

  function mint(
    address _to,
    uint256 _issue,
    uint256 _amount,
    bool claim
  ) external returns (uint[] memory);

  function launchIssue(
    uint _issue,
    uint _saleSize,
    string memory _uri
  ) external;

  function isIssueLaunched(uint256 _issue) external view returns (bool);

  function tokenToIssue(uint _tokenId) external view returns (uint);

  function timeToIssue(uint256 _timestamp) external view returns (Issue memory);

  function issueList() external view returns (uint[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';

interface IRedlionArtdrops is IERC721Upgradeable {
  /*///////////////////////////////////////////////////////////////
                          EVENTS
  ///////////////////////////////////////////////////////////////*/

  event ArtdropLaunched(uint indexed issue);

  /*///////////////////////////////////////////////////////////////
                         FUNCTIONS
  ///////////////////////////////////////////////////////////////*/

  function mint(address _to, uint _tokenId) external;

  function isClaimed(uint _tokenId) external view returns (bool);

  function launchArtdrop(uint _issueId, string calldata _uri) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './IRedlionGazette.sol';
import './IRedlionLegendaryGazette.sol';

interface IRedlionGazetteManager {
  event IssueDelivered(
    uint indexed issue,
    uint tokenId,
    address indexed receiver
  );

  event IssueMinted(uint indexed issue, uint tokenId, address indexed minter);

  event IssueClaimed(
    uint indexed issue,
    uint tokenId,
    address indexed claimant
  );

  event ArtdropClaimed(
    uint indexed issue,
    uint tokenId,
    address indexed claimant
  );
  
  struct DeliveryState {
    uint delivered;
    uint received;
    uint total;
  }

  function getRLG() external view returns (IRedlionGazette);

  function getRLLG() external view returns (IRedlionLegendaryGazette);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISubscriptions {

  function subscribe(address to) external;

  function isSubscribed(address target) external view returns (bool);

  function subscribers() external view returns (address[] memory);

  function subscriptionId(address target) external view returns (bytes memory);

  function when(address target) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISubscriptionsManager {
  enum SubType {
    NORMAL,
    SUPER,
    NONE
  }

  struct SubInfo {
    bool subscribed;
    SubType subType;
    uint256 timestamp;
    bytes subId;
  }

  function isSubscribed(address target) external view returns (bool);

  function subscriptionInfo(
    address target
  ) external view returns (SubInfo memory);
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Paper Key Manager
/// @author Winston Yeo
/// @notice PaperKeyManager makes it easy for developers to restrict certain functions to Paper.
/// @dev Developers are in charge of registering the contract with the initial Paper key. Paper will then help you  automatically rotate and update your key in line with good security hygiene
interface IPaperKeyManager {
    /// @notice Registers a Paper Key to a contract
    /// @dev Registers the @param _paperKey with the caller of the function
    /// @param _paperKey The Paper key that is associated with the checkout. You should be able to find this in the response of the checkout API or on the checkout dashbaord.
    /// @return bool indicating if the @param _paperKey was successfully registered with the calling address
    function register(address _paperKey) external returns (bool);

    /// @notice Verifies if the given @param _data is from Paper and have not been used before
    /// @dev Called as the first line in your function or extracted in a modifier. Refer to the Documentation for more usage details.
    /// @param _hash The bytes32 encoding of the data passed into your function
    /// @param _nonce a random set of bytes Paper passes your function which you forward. This helps ensure that the @param _hash has not been used before.
    /// @param _signature used to verify that Paper was the one who sent the @param _hash
    /// @return bool indicating if the @param _hash was successfully verified
    function verify(
        bytes32 _hash,
        bytes32 _nonce,
        bytes calldata _signature
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}