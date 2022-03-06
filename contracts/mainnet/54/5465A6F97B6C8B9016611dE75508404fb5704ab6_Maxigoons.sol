//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./NFT.sol";

contract Maxigoons is NFT {
  constructor(address vrfCoordinator, address linkToken)
    ERC721a("Maxigoons", "GOON")
    NFT(
      7007, // Max supply
      707, // Reserve amount
      100, // Max per wallet
      "bafybeicxiym4ou5ephvt4j66if3axll3s3uq7axspgcdjr5tvrtrfboqsa", // Content ID (CID)
      "bab93ab37b236a32545c4bb2239ac9da276bc18324bcdcf0d86e0d225299db7b", // Provenance Hash
      0x9d14CAea98d6Ef30Ae169c361D2540dd680Bc280, // Vault address
      vrfCoordinator,
      linkToken
    )
  {}

  function claim(bytes32[] memory proof) public {
    _sell(0, 1, 0, proof);
  }

  function presale(uint256 amount, bytes32[] memory proof) public payable {
    _sell(1, amount, msg.value, proof);
  }

  function buy(uint256 amount) public payable {
    _sell(2, amount, msg.value, new bytes32[](0));
  }

  function mint(
    uint256 index,
    uint256 amount,
    bytes32[] memory proof
  ) public payable {
    _sell(index, amount, msg.value, proof);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./ERC721a.sol";

abstract contract NFT is ERC721a, VRFConsumerBase {
  struct Sale {
    uint256 unitPrice;
    uint256 maxAmount;
    bytes32 treeRoot;
  }

  event OwnerUpdated(address indexed user, address indexed newOwner);

  event Revealed(uint256 seed, bytes32 requestId);

  bool public enabled;

  address public owner;

  address public vault;

  string public contentId;

  string public provenance;

  uint256 public maxSupply;

  uint256 public maxPerWallet;

  uint256 public reserveAmount;

  uint256 public seed;

  uint256 public level;

  uint256 public vrfFee = 2 * 10**18;

  bytes32 public vrfHash =
    0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;

  Sale[] public sales;

  mapping(uint256 => mapping(address => uint256)) public balanceOfSale;

  constructor(
    uint256 _maxSupply,
    uint256 _reserveAmount,
    uint256 _maxPerWallet,
    string memory _contentId,
    string memory _provenance,
    address _vault,
    address vrfCoordinator,
    address linkToken
  ) VRFConsumerBase(vrfCoordinator, linkToken) {
    maxSupply = _maxSupply;
    reserveAmount = _reserveAmount;
    maxPerWallet = _maxPerWallet;
    contentId = _contentId;
    provenance = _provenance;
    vault = _vault;

    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "401");
    _;
  }

  function updateOwner(address newOwner) external onlyOwner {
    owner = newOwner;

    emit OwnerUpdated(msg.sender, newOwner);
  }

  function setVRF(uint256 fee, bytes32 _hash) external onlyOwner {
    vrfFee = fee;
    vrfHash = _hash;
  }

  function setSale(
    uint256 index,
    uint256 unitPrice,
    uint256 maxAmount,
    bytes32 treeRoot
  ) external onlyOwner {
    require(index <= sales.length, "422");

    if (index == sales.length) {
      // Create
      sales.push(Sale(unitPrice, maxAmount, treeRoot));
    } else {
      // Update
      Sale storage sale = sales[index];

      sale.unitPrice = unitPrice;
      sale.maxAmount = maxAmount;
      sale.treeRoot = treeRoot;
    }
  }

  function setLevel(uint256 index) external onlyOwner {
    require(sales.length > 0 && index < sales.length, "422");

    level = index;
  }

  function enable() external onlyOwner {
    enabled = true;
  }

  function disable() external onlyOwner {
    enabled = false;
  }

  function reveal() public onlyOwner returns (bytes32) {
    require(seed == 0, "403");
    require(LINK.balanceOf(address(this)) >= vrfFee, "402");

    return requestRandomness(vrfHash, vrfFee);
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal
    override
  {
    require(seed == 0, "403");

    seed = randomness;

    emit Revealed(randomness, requestId);
  }

  function hasLevel(
    uint256 index,
    address candidate,
    bytes32[] memory proof
  ) public view returns (bool) {
    require(index < sales.length, "404");

    Sale memory sale = sales[index];

    return
      MerkleProof.verify(
        proof,
        sale.treeRoot,
        keccak256(abi.encodePacked(candidate))
      );
  }

  function withdraw() external onlyOwner {
    payable(vault).transfer(address(this).balance);
  }

  function baseURI() public view virtual returns (string memory) {
    return string(abi.encodePacked("ipfs://", contentId, "/metadata/"));
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
    require(_ownerOf(id) != address(0), "404");

    uint256 metaId;

    if (seed == 0) {
      // Conceal
      metaId = 0;
    } else {
      // Reveal
      metaId = _metadataOf(id);
    }

    return string(abi.encodePacked(baseURI(), toString(metaId), ".json"));
  }

  function contractURI() public view virtual returns (string memory) {
    return string(abi.encodePacked(baseURI(), "contract.json"));
  }

  function reserve(uint256 amount) public virtual onlyOwner {
    require(seed == 0, "403");
    require(totalSupply + amount <= maxSupply, "403");
    require(balanceOf[vault] + amount <= reserveAmount, "403");

    _safeMintBatch(vault, amount);
  }

  function _metadataOf(uint256 id) internal view returns (uint256) {
    uint256 seed_ = seed;

    uint256 max = maxSupply;

    uint256[] memory idToMeta = new uint256[](max);

    for (uint256 i = 0; i < max; i++) {
      idToMeta[i] = i;
    }

    for (uint256 i = 0; i < max - 1; i++) {
      uint256 j = i + (uint256(keccak256(abi.encode(seed_, i))) % (max - i));

      (idToMeta[i], idToMeta[j]) = (idToMeta[j], idToMeta[i]);
    }

    // Token ID starts at #1
    return idToMeta[id - 1] + 1;
  }

  function _sell(
    uint256 index,
    uint256 amount,
    uint256 value,
    bytes32[] memory proof
  ) internal {
    Sale memory sale = sales[index];

    bool isProtected = sale.treeRoot != 0;

    // Unauthorized
    require(enabled && sales.length > 0, "401");

    if (isProtected) {
      require(hasLevel(index, msg.sender, proof), "401");
    }

    // Payment required
    require(amount * sale.unitPrice == value, "402");

    // Forbidden
    require(index <= level, "403");
    require(balanceOf[msg.sender] + amount <= maxPerWallet, "403");
    require(totalSupply + amount <= maxSupply, "403");

    if (isProtected) {
      balanceOfSale[index][msg.sender] += amount;

      require(balanceOfSale[index][msg.sender] <= sale.maxAmount, "403");
    } else {
      // Open sale
      // Trick `sale.maxAmount` becomes `maxPerTx`
      require(amount <= sale.maxAmount, "403");
    }

    _safeMintBatch(msg.sender, amount);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
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
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "./ERC721TokenReceiver.sol";

/// @notice Credits: https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol

/// @dev Note Assumes serials are sequentially minted starting at 1 (e.g. 1, 2, 3, 4...).
/// @dev Note Does not support burning tokens to address(0).

/// @author Modified from solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)

abstract contract ERC721a {
  /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

  event Transfer(address indexed from, address indexed to, uint256 indexed id);

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

  /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

  string public name;

  string public symbol;

  function tokenURI(uint256 id) public view virtual returns (string memory);

  /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

  uint256 public totalSupply;

  mapping(address => uint256) public balanceOf;

  mapping(uint256 => address) public getApproved;

  mapping(address => mapping(address => bool)) public isApprovedForAll;

  mapping(uint256 => address) internal owners;

  /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(string memory _name, string memory _symbol) {
    name = _name;
    symbol = _symbol;
  }

  /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

  function setApprovalForAll(address operator, bool approved) public virtual {
    isApprovedForAll[msg.sender][operator] = approved;

    emit ApprovalForAll(msg.sender, operator, approved);
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
    bytes memory data
  ) public virtual {
    transferFrom(from, to, id);

    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
        ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  /*///////////////////////////////////////////////////////////////
                              ERC721a LOGIC
    //////////////////////////////////////////////////////////////*/

  function ownerOf(uint256 id) public view returns (address) {
    return _ownerOf(id);
  }

  function approve(address spender, uint256 id) public {
    address owner = _ownerOf(id);

    require(
      msg.sender == owner || isApprovedForAll[owner][msg.sender],
      "NOT_AUTHORIZED"
    );

    getApproved[id] = spender;

    emit Approval(owner, spender, id);
  }

  function transferFrom(
    address from,
    address to,
    uint256 id
  ) public {
    address owner = _ownerOf(id);

    require(from == owner, "WRONG_FROM");

    require(to != address(0), "INVALID_RECIPIENT");

    require(
      msg.sender == from ||
        msg.sender == getApproved[id] ||
        isApprovedForAll[from][msg.sender],
      "NOT_AUTHORIZED"
    );

    // https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol#L395
    unchecked {
      balanceOf[from]--;

      balanceOf[to]++;
    }

    owners[id] = to;

    // https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol#L405
    if (id + 1 <= totalSupply && owners[id + 1] == address(0)) {
      owners[id + 1] = owner;
    }

    delete getApproved[id];

    emit Transfer(from, to, id);
  }

  function _safeMintBatch(address to, uint256 amount) internal {
    _safeMintBatch(to, amount, "");
  }

  function _safeMintBatch(
    address to,
    uint256 amount,
    bytes memory data
  ) internal {
    _mintBatch(to, amount, data, true);
  }

  function _mintBatch(address to, uint256 amount) internal {
    _mintBatch(to, amount, "", false);
  }

  function _mintBatch(
    address to,
    uint256 amount,
    bytes memory data
  ) internal {
    _mintBatch(to, amount, data, false);
  }

  function _mintBatch(
    address to,
    uint256 amount,
    bytes memory data,
    bool safe
  ) internal {
    require(to != address(0), "INVALID_RECIPIENT");

    unchecked {
      uint256 id = totalSupply + 1;

      totalSupply += amount;
      balanceOf[to] += amount;
      owners[id] = to;

      for (uint256 i = 0; i < amount; i++) {
        emit Transfer(address(0), to, id);

        if (safe) {
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

        id++;
      }
    }
  }

  function _ownerOf(uint256 id) internal view returns (address) {
    if (id > totalSupply) {
      return address(0);
    }

    unchecked {
      while (id > 0) {
        if (owners[id] != address(0)) {
          return owners[id];
        }

        id--;
      }
    }

    // Happens only when `id == 0`
    return address(0);
  }

  /// @notice Credits: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol#L15

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

  /*///////////////////////////////////////////////////////////////
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 id,
    bytes calldata data
  ) external returns (bytes4);
}