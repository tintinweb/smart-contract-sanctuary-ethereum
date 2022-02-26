// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/ECDSALibrary.sol";
import "../libraries/MerkleProofLibrary.sol";
import "../interfaces/INefturians.sol";
import "../interfaces/INefturiansArtifact.sol";
import "../interfaces/INefturiansData.sol";
import "./AccessControl.sol";
import "./ERC721A.sol";
import "./NefturiansArtifact.sol";
import "./NefturiansData.sol";

/**********************************************************************************************************************/
/*                                                                                                                    */
/*                                                     Nefturians                                                     */
/*                                                                                                                    */
/*                     NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                     */
/*                  NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                  */
/*                NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                */
/*              NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN              */
/*             NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN             */
/*            NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN            */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN...NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN........NNNNNNNNNNNNNNNNNNN.......NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN...........NNNNNNNNNNNNNNNN.........NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNN...............NNNNNNNNNNNN............NNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNN.................NNNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNN...................NNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNN.....................NNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNN.......................NNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNN..........................NNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNN.............................NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNN............NNNN...............NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNN............NNNNNN...............NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNN.............NNNNNNNN...............NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNN.............NNNNNNNNNN..............NNNNNNNNNN............NNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNN.............NNNNNNNNNN..............NNNNNNNN.............NNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNN.............NNNNNNNNNN...............NNNNN.............NNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNN...............NNN.............NNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNN.............NNNNNNNNNN............................NNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNN..........................NNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNN........................NNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNN.....................NNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNNN..................NNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNNN................NNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNN...........NNNNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN.........NNNNNNNNNNNNNNNN...........NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN.......NNNNNNNNNNNNNNNNNNN........NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN.NNNNNNNNNNNNNNNNNNNNNNNNNN.NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*            NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN            */
/*             NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN             */
/*               NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN               */
/*                 NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                 */
/*                    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                     */
/*                                                                                                                    */
/*                                                                                                                    */
/*                                                                                                                    */
/**********************************************************************************************************************/

contract Nefturians is ERC721A, Ownable, AccessControl, Pausable, INefturians {

  /**
   * Base URI for offchain metadata
   */
  string private _baseTokenURI;

  /**
   * Roles used for access control
   */
  bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 internal constant DAO_ROLE = keccak256("DAO_ROLE");
  bytes32 internal constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
  bytes32 internal constant METADATA_ROLE = keccak256("METADATA_ROLE");
  bytes32 internal constant DATA_CONTRACT_ROLE = keccak256("DATA_CONTRACT_ROLE");
  bytes32 internal constant ARTIFACT_CONTRACT_ROLE = keccak256("ARTIFACT_CONTRACT_ROLE");
  bytes32 internal constant URI_ROLE = keccak256("URI_ROLE");

  /**
   * Minting rules and supplies
   */
  uint256 internal constant MAX_SUPPLY = 8001;
  uint256 internal constant TOKENS_RESERVED = 250;
  uint256 internal constant MINTING_PRICE = 0.15 ether;
  uint256 internal constant MAX_PUBLIC_MINT = 5;
  uint256 internal constant MAX_WHITELIST_MINT = 2;

  /**
   * Sale calendar
   */
  uint256 internal preSaleStartTimestamp = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe;
  uint256 internal publicSaleStartTimestamp = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

  /**
   * Minting state used to enforce aforementioned rules
   */
  uint256 internal reservedTokensMinted = 0;
  mapping(address => uint256) private nonces;
  mapping(address => uint256) public whitelistClaimed;
  mapping(address => uint256) public publicClaimed;

  /**
   * Root hash for the whitelist merkle tree
   */
  bytes32 public merkleRoot;

  /**
   * Payment distribution and addresses
   */
  uint256 internal totalShares = 1000;
  uint256 internal totalReleased;
  mapping(address => uint256) internal released;
  mapping(address => uint256) internal shares;
  address internal gnosisSafe = 0x9Ba52109EdA0B6aFB60f0c98265a7457d1b47763;
  address internal CEO = 0x741572cee2Cc991DBC142F0910e9f47A3871c110;
  address internal CTO = 0x5712dABA01D33b323D5130cA6c48E11427d675B2;
  address internal COO = 0x657C9FDe093e08fe976686f4b68FaAC57fBF8bbE;
  address internal CMO = 0xA944E23Fc61D57502bfBf8dFa358Aadeb5ADB64C;
  address internal Dev = 0x9Eb3a30117810d5a36568714EB5350480942f644;
  address internal Advisor = 0x1DbBEc72Fc72406851aB9d42c18dc52aBEbBB287;

  /**
   * Side contracts
   */
  INefturianArtifact internal nefturiansArtifacts;
  INefturiansData internal nefturiansData;

  /**
   * Provably fair metadata will respect this hash
   *
   * To ensure fair disitrubution of attributes among the tokens, the 8001 attributes objects will be published
   * in their original order and hashed into the provableFairnessHash public variable.
   *
   * Before revealing the metadata, random numbers provided by the community will be hashed together to ensure
   * a fair random shuffling of that order before the reveal.
   */
  string public provableFairnessHash;

  constructor() ERC721A("Nefturians", "NFTR") {
    nefturiansArtifacts = new NefturiansArtifact();
    nefturiansData = new NefturiansData();

    _grantRole(DEFAULT_ADMIN_ROLE, gnosisSafe);
    _grantRole(MINTER_ROLE, gnosisSafe);
    _grantRole(PAUSER_ROLE, gnosisSafe);
    _grantRole(DAO_ROLE, gnosisSafe);
    _grantRole(SIGNER_ROLE, gnosisSafe);
    _grantRole(URI_ROLE, gnosisSafe);
    _grantRole(URI_ROLE, msg.sender);
    _grantRole(METADATA_ROLE, gnosisSafe);
    _grantRole(METADATA_ROLE, address(nefturiansData));
    _grantRole(METADATA_ROLE, address(nefturiansArtifacts));
    _grantRole(DATA_CONTRACT_ROLE, address(nefturiansData));
    _grantRole(ARTIFACT_CONTRACT_ROLE, address(nefturiansArtifacts));
    _grantRole(MINTER_ROLE, address(this));
    nefturiansArtifacts.transferOwnership(gnosisSafe);

    shares[gnosisSafe] = 872;
    shares[CEO] = 27;
    shares[CTO] = 27;
    shares[COO] = 27;
    shares[CMO] = 27;
    shares[Dev] = 10;
    shares[Advisor] = 10;

    require(
      shares[gnosisSafe] +
      shares[CEO] +
      shares[CTO] +
      shares[COO] +
      shares[CMO] +
      shares[Dev] +
      shares[Advisor] ==
      totalShares, "Wrong shares distribution");
  }

  /**
   * Update NefturiansArtifact contract
   * @param newNefturiansArtifact: address of new NefturiansArtifact contract
   */
  function setNefturiansArtifact(address newNefturiansArtifact) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(METADATA_ROLE, address(nefturiansArtifacts));
    _revokeRole(ARTIFACT_CONTRACT_ROLE, address(nefturiansArtifacts));
    nefturiansArtifacts = INefturianArtifact(newNefturiansArtifact);
    _grantRole(METADATA_ROLE, address(nefturiansArtifacts));
    _grantRole(ARTIFACT_CONTRACT_ROLE, address(nefturiansArtifacts));
  }

  /**
   * Get the pinting price
   */
  function getMintingPrice() public pure returns (uint256) {
    return MINTING_PRICE;
  }

  /**
   * Get the address of the internally deployed NefturiansArtifact contract
   */
  function getArtifactContract() public view returns (address) {
    return address(nefturiansArtifacts);
  }

  /**
   * Get the timestamp of the presale start
   */
  function getPreSaleTimestamp() public view returns(uint256) {
    return preSaleStartTimestamp;
  }

  /**
   * Get the timestamp of the presale start
   */
  function getPublicSaleTimestamp() public view returns(uint256) {
    return publicSaleStartTimestamp;
  }

  /**
   * Get the address of the internally deployed NefturiansData contract
   */
  function getDataContract() public view returns (address) {
    return address(nefturiansData);
  }

  /**
   * Admin can move the presale start to avoid conflicting with NFT partners
   */
  function setPresaleStart(uint256 ts) public onlyRole(DEFAULT_ADMIN_ROLE) {
    preSaleStartTimestamp = ts;
  }

  /**
   * Admin can move the public sale start to avoid conflicting with NFT partners
   */
  function setPublicSaleStart(uint256 ts) public onlyRole(DEFAULT_ADMIN_ROLE) {
    publicSaleStartTimestamp = ts;
  }

  /**
   * Set the hash of all the attributes in their original order
   *
   * This function can only be called once
   */
  function setProvableFairnessHash(string calldata hash) public onlyRole(DEFAULT_ADMIN_ROLE) {
    provableFairnessHash = hash;
  }

  /**
   * Globally pauses minting
   */
  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /**
   * Globally unpauses minting
   */
  function unpause() public onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  /**
   * Mint function for devs
   * @param to: address of receiver
   * @param quantity: number of tokens to mint
   *
   * Error messages:
   *  - N0 : "Maximum supply would be exceeded with this mint" (should never happen but better safe than sorry)
   *  - N15: "Reserve supply would be exceeded with this mint"
   */
  function safeMint(address to, uint256 quantity) public onlyRole(MINTER_ROLE) {
    require(quantity + totalSupply() <= MAX_SUPPLY, "N0");
    require(reservedTokensMinted + quantity <= TOKENS_RESERVED, "N15");
    reservedTokensMinted += quantity;
    _safeMint(to, quantity);
  }

  /**
   * Mint function for presale
   * @param quantity: uint256 - number of tokens to mint
   * @param merkleProof: serie of merkle hashes to prove whitelist
   *
   * Error messages:
   *  - N7 : "Presale has not started"
   *  - N18: "Presale is over"
   *  - N8 : "Whitelist supply would be exceeded with this mint"
   *  - N9 : "The whitelist has not been initialized"
   *  - N5 : "You have to send the right amount"
   *  - N10: "Your max allocation would be exceeded with this mint"
   *  - N11: "Invalid proof of whitelist"
   */
  function whitelistMint(uint256 quantity, bytes32[] calldata merkleProof) public payable whenNotPaused {
    require(block.timestamp >= preSaleStartTimestamp, "N7");
    require(block.timestamp < publicSaleStartTimestamp, "N18");
    require(totalSupply() + quantity <= MAX_SUPPLY - TOKENS_RESERVED + reservedTokensMinted, "N8");
    require(merkleRoot != 0, "N9");
    require(msg.value == MINTING_PRICE * quantity, "N5");
    require(whitelistClaimed[msg.sender] + quantity <= MAX_WHITELIST_MINT, "N10");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProofLibrary.verify(merkleProof, merkleRoot, leaf), "N11");
    whitelistClaimed[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
  }

  /**
   * Public mint function that requires a signature from a SIGNER_ROLE
   * @param quantity: number of tokens to mint
   * @param signature: signature from a wallet with SIGNER_ROLE to authorize the mint
   *
   * Error messages:
   *  - N2 : "Public sale has not started yet"
   *  - N3 : "Public supply would be exceeded with this mint"
   *  - N4: "Mint quantity too high"
   *  - N5: "You have to send the right amount"
   *  - N6: "This operation has not been signed"
  */
  function publicMint(uint256 quantity, bytes calldata signature) public payable whenNotPaused {
    require(block.timestamp >= publicSaleStartTimestamp, "N2");
    require(quantity + totalSupply() <= MAX_SUPPLY - TOKENS_RESERVED + reservedTokensMinted, "N3");
    require(publicClaimed[msg.sender] + quantity <= MAX_PUBLIC_MINT, "N4");
    publicClaimed[msg.sender] += quantity;
    require(msg.value == MINTING_PRICE * quantity, "N5");
    uint256 nonce = nonces[msg.sender] + 1;
    require(hasRole(SIGNER_ROLE, ECDSALibrary.recover(abi.encodePacked(msg.sender, nonce), signature)), "N6");
    nonces[msg.sender] += 1;
    _safeMint(msg.sender, quantity);
  }

  /**
   * Define merkle root
   * @param newMerkleRoot: newly defined merkle root
   */
  function setMerkleRoot(bytes32 newMerkleRoot) public onlyRole(MINTER_ROLE) {
    merkleRoot = newMerkleRoot;
  }

  /**
   * Get the nonce of a particular address
   * @param minter: selected address from which to get the nonce
   */
  function getNonce(address minter) public view returns (uint256) {
    return nonces[minter] + 1;
  }

  /**
   * Increment the nonce
   * @param holder: address of the address for which to increnebnt the nonce
   */
  function incrementNonce(address holder) public onlyRole(METADATA_ROLE) {
    nonces[holder] += 1;
  }

  /**
   * Get the on chain metadata of a token
   * @param tokenId: id of the token from which to get the on chain metadata
   *
   * Error messages:
   *  - N12: "Token ID doesn't correspond to a minted token"
   */
  function getMetadata(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), "N12");
    return nefturiansData.getMetadata(tokenId);
  }

  /**
   * Add a new Metadata key
   * @param keyName: the name of the Metadata key
   */
  function addKey(string calldata keyName) public onlyRole(METADATA_ROLE) {
    nefturiansData.addKey(keyName);
  }

  /**
   * Get the base URI
   */
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  /**
   * Set the base URI
   * @param baseURI: new base URI
   */
  function setBaseURI(string calldata baseURI) external onlyRole(URI_ROLE) {
    _baseTokenURI = baseURI;
  }

  /**
   * Contract level Metadata URI
   */
  function contractURI() public view returns (string memory) {
    return string(abi.encodePacked(_baseTokenURI, "collection"));
  }

  /**
   * Get the URI of a selected token
   * @param tokenId: token id from which to get token URI
   *
   * Error messages:
   *  - N12: "Token ID doesn't correspond to a minted token"
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "N12");
      return string(abi.encodePacked(_baseTokenURI, StringsLibrary.toString(tokenId)));
  }

  /**
   * Withdraw contract balance to a shareholder proportionnaly to their share amount
   *
   * @param account: address of the shareholder
   *
   * Error messages:
   *  - N16: "You have no shares in the project"
   *  - N17: "All funds have already been sent"
   */
  function withdraw(address account) public {
    require(shares[account] > 0, "N16");
    uint256 totalReceived = address(this).balance + totalReleased;
    uint256 payment = (totalReceived * shares[account]) / totalShares - released[account];
    require(payment > 0, "N17");
    released[account] = released[account] + payment;
    totalReleased = totalReleased + payment;
    payable(account).transfer(payment);
  }

  /**
   * Mints an egg artifact for the buyer
   *
   * @param from: transferer's address
   * @param to: reveiver's address
   */
  function _beforeTokenTransfers(
    address from,
    address to
  ) internal override {
    if (from != address(0) && to != address(0)) {
      nefturiansArtifacts.giveEgg(to);
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)
// Added recover for arbitrary bytes by Nefture

pragma solidity 0.8.11;

import "./StringsLibrary.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSALibrary {
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
    function recover(bytes32 hash, bytes calldata signature) public pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives unhashed bytes
     *
     * Added for Nefturians collection
     */
    function recover(bytes calldata data, bytes calldata signature) public pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(data)));
        return recover(hash, signature);
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
    ) public pure returns (address) {
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
    ) public pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
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
    function toEthSignedMessageHash(bytes memory s) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsLibrary.toString(s.length), s));
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)
// Made public and linkable by Nefture

pragma solidity 0.8.11;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProofLibrary {
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
    ) public pure returns (bool) {
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
    function processProof(bytes32[] memory proof, bytes32 leaf) public pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IAccessControl.sol";

interface INefturians is IERC721, IAccessControl {
  event UpdateNefturianArtifact(address newArtifactContract);

  function getNonce(address addr) external view returns (uint256);

  function incrementNonce(address addr) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface INefturianArtifact is IERC1155 {
  event UseArtifact(uint256 tokenId, uint256 quantity);

  event UseArtifacts(uint256[] tokenIds, uint256[] quantities);

  event UpdateOdds(uint256[] oldOdds, uint256[] newOdds);

  event AddRareItem(uint256 rarity, uint256 quantity, bool isConsumable);

  function giveEgg(address to) external;

  function transferOwnership(address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface INefturiansData {

  event MetadataUpdated(uint256 indexed tokenId, uint256 indexed key, string value);
  event AttributeUpdated(uint256 indexed tokenId, uint256 indexed key, uint256 value);

  function getMetadata(uint256 tokenId) external view returns (string memory);

  function addKey(string calldata key) external;

  function setMetadata(uint256 tokenId, uint256 key, string calldata value, bytes calldata signature) external;

  function setAttributes(uint256 tokenId, uint256[] calldata keys, uint256[] calldata values, bytes calldata signature) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)
// Modified by Nefture to remove role admins feature

pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../interfaces/IAccessControl.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl {

    mapping(bytes32 => mapping(address => bool)) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert("AC0");
        }
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AC1");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role][account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role][account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs
// Further optimization: Nefture

pragma solidity 0.8.11;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Does not support burning tokens to address(0).
 *
 * Assumes that an owner cannot have more than the 2**128 (max value of uint128) of supply
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    uint256 internal currentIndex = 0;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty mapping value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => address) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return currentIndex;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IERC721Enumerable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), 'AP1');
        return uint256(_balances[owner]);
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownershipOf(uint256 tokenId) internal view returns (address) {
        require(_exists(tokenId), 'AP2');

        unchecked {
            for (uint256 curr = tokenId; curr >= 0; curr--) {
                if (_ownerships[curr] != address(0)) {
                    return _ownerships[curr];
                }
            }
        }

        revert('AP3');
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), 'AP2');

        return ownershipOf(tokenId);
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
        require(_exists(tokenId), 'AP5');

        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, 'AP6');

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            'AP7'
        );

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), 'AP8');

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != _msgSender(), 'AP9');

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        _transfer(from, to, tokenId);
    }

    /**
    * @dev See {IERC721-safeTransferFrom}.
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            'AP10'
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < currentIndex;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` cannot be larger than the max batch size.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = currentIndex;
        require(to != address(0), 'AP11');
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        require(!_exists(startTokenId), 'AP12');
        require(quantity > 0, 'AP13');

        _beforeTokenTransfers(address(0), to);

        _balances[to] += uint128(quantity);
        _ownerships[startTokenId] = to;

        uint256 updatedIndex = startTokenId;

        for (uint256 i = 0; i < quantity; i++) {
            emit Transfer(address(0), to, updatedIndex);
            require(
                _checkOnERC721Received(address(0), to, updatedIndex, _data),
                'AP10'
            );
            updatedIndex++;
        }

        currentIndex = updatedIndex;
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
        address prevOwnership = ownerOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership ||
        getApproved(tokenId) == _msgSender() ||
        isApprovedForAll(prevOwnership, _msgSender()));

        require(isApprovedOrOwner, 'AP15');

        require(prevOwnership == from, 'AP16');
        require(to != address(0), 'AP17');

        _beforeTokenTransfers(from, to);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        _balances[from] -= 1;
        _balances[to] += 1;

        _ownerships[tokenId] = to;

        // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
        // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
        uint256 nextTokenId = tokenId + 1;
        if (_ownerships[nextTokenId] == address(0)) {
            if (_exists(nextTokenId)) {
                _ownerships[nextTokenId] = prevOwnership;
            }
        }

        emit Transfer(from, to, tokenId);
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert('AP10');
                }
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
        return true;
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     */
    function _beforeTokenTransfers(
        address from,
        address to
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/ECDSALibrary.sol";
import "../interfaces/INefturiansArtifact.sol";
import "../interfaces/INefturians.sol";

/**********************************************************************************************************************/
/*                                                                                                                    */
/*                                                Nefturians Artifacts                                                */
/*                                                                                                                    */
/*                     NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                     */
/*                  NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                  */
/*                NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                */
/*              NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN              */
/*             NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN             */
/*            NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN            */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN...NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN........NNNNNNNNNNNNNNNNNNN.......NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN...........NNNNNNNNNNNNNNNN.........NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNN...............NNNNNNNNNNNN............NNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNN.................NNNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNN...................NNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNN.....................NNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNN.......................NNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNN..........................NNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNN.............................NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNN............NNNN...............NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNN............NNNNNN...............NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNN.............NNNNNNNN...............NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNN.............NNNNNNNNNN..............NNNNNNNNNN............NNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNN.............NNNNNNNNNN..............NNNNNNNN.............NNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNN.............NNNNNNNNNN...............NNNNN.............NNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNN...............NNN.............NNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNN.............NNNNNNNNNN............................NNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNN..........................NNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNN........................NNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNN.....................NNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNNN..................NNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNNN................NNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNN...........NNNNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN.........NNNNNNNNNNNNNNNN...........NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN.......NNNNNNNNNNNNNNNNNNN........NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN.NNNNNNNNNNNNNNNNNNNNNNNNNN.NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*            NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN            */
/*             NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN             */
/*               NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN               */
/*                 NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                 */
/*                    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                     */
/*                                                                                                                    */
/*                                                                                                                    */
/*                                                                                                                    */
/**********************************************************************************************************************/

contract NefturiansArtifact is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply, INefturianArtifact {

  /**
   * Roles for the access control
   * these roles are only checked against the parent contract's settings
   */
  bytes32 internal constant DAO_ROLE = keccak256("DAO_ROLE");
  bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 internal constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
  bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

  /**
   * Custom URI for each token
   */
  mapping(uint256 => string) private _uris;

  /**
   * Odds of drawing artifacts based on their rarity level.
   *
   * Rarity levels go in this order:
   *  - odds[0] = common (for common equipment and basic consumables)
   *  - odds[1] = powerUp (consummables used to upgrades Nefturians stats)
   *  - odds[2] = rare (for rare equipment and powerful buffs consumables)
   *  - odds[3] = legendary (wait for it...)
   */
  uint256[] private odds = [70000, 90000, 99000, 100000];

  /**
   * Current tokenId count.
   * Starts at 1. Index 0 is reserved for eggs
   */
  uint256 private generalCount = 1;

  /**
   * Mapping rarity levels and indexes to tokenIds.
   *
   * indexesByRarity[ rarityId ][ autoincremented index ] => tokenId
   * countByRarity = autoincremented indexes for each rarity level
   */
  mapping(uint256 => mapping(uint256 => uint256)) private indexesByRarity;
  mapping(uint256 => uint256) private countByRarity;

  /**
   * If a token should be burned when used
   */
  mapping(uint256 => bool) private consumable;

  /**
   * Ether pool to pay for the gas when a method needs to be called by our API
   */
  mapping(address => uint256) public stakes;

  /**
   * Parent contract: The Nefturians collection
   */
  INefturians internal nefturians;

  constructor() ERC1155("") {
    nefturians = INefturians(msg.sender);
    consumable[0] = true;
  }

  /**
   * Update the odds of drawing artifacts based on their rarity level
   * @param newOdds: new odds in increment order with last equal to 100000
   *
   * Error messages:
   *  - AC0: "You dont have required role"
   *  - NA03: "Wrong format for array"
   */
  function updateOdds(uint256[] calldata newOdds)
  public
  {
    require(nefturians.hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "AC0");
    require(newOdds.length == 4, "NA03");
    require(newOdds[3] == 100000, "NA03");
    require(
      newOdds[0] <= newOdds[1] &&
      newOdds[1] <= newOdds[2] &&
      newOdds[2] <= newOdds[3], "NA03");
    emit UpdateOdds(odds, newOdds);
    odds = newOdds;
  }

  /**
   * Adds a new artifact
   * @param rarity: rarity of the new artifact (must be between 0 and 3)
   * @param quantity: quantity of artifacts to be added
   * @param isConsumable: if the artifact can be consumed
   *
   * Error messages:
   *  - NA07: "Rarity out of bounds"
   */
  function addRareItem(uint256 rarity, uint256 quantity, bool isConsumable)
  public
  {
    require(rarity < 4 && rarity >= 0, "NA07");
    require(nefturians.hasRole(MINTER_ROLE, msg.sender), "Missing role");
    for (uint256 i = 0; i < quantity; i++) {
      indexesByRarity[rarity][countByRarity[rarity] + i] = generalCount + i;
      consumable[generalCount + i] = isConsumable;
    }
    countByRarity[rarity] += quantity;
    generalCount += quantity;
    emit AddRareItem(rarity, quantity, isConsumable);
  }

  /**
   * Set URI of a given token
   * @param tokenId: id of the token
   * @param newuri: new uri of token id
   *
   */
  function setURI(uint256 tokenId, string memory newuri) public {
    require(nefturians.hasRole(MINTER_ROLE, msg.sender), "Missing role");
    _setURI(tokenId, newuri);
  }

  /**
   * Public mint function that requires a signature from a SIGNER_ROLE
   * @param tokenId: id of the token
   * @param quantity: quantity to be minted
   * @param signature: signature of SIGNER_ROLE
   *
   * Error messages:
   *  - N6: "This operation has not been signed"
   */
  function mintWithSignature(uint256 tokenId, uint256 quantity, bytes calldata signature)
  public
  {
    uint256 nonce = nefturians.getNonce(msg.sender);
    require(nefturians.hasRole(SIGNER_ROLE, ECDSALibrary.recover(abi.encodePacked(msg.sender, nonce, tokenId, quantity), signature)), "N6");
    nefturians.incrementNonce(msg.sender);
    _mint(msg.sender, tokenId, quantity, "");
  }

  /**
   * Mint batch of token only if MINTER_ROLE
   * @param to: address reveiving tokens
   * @param tokenIds: ids of the tokens to be minted
   * @param amounts: quantities of each token to be minted
   * @param data: arbitrary data for events
   *
   * Error messages:
   *  - AC0: "You dont have required role"
   */
  function mintBatch(address to, uint256[] memory tokenIds, uint256[] memory amounts, bytes memory data)
  public
  {
    require(nefturians.hasRole(MINTER_ROLE, msg.sender), "AC0");
    _mintBatch(to, tokenIds, amounts, data);
  }

  /**
   * Get the uri of a tokenId
   * @param tokenId: id of the token
   */
  function uri(uint256 tokenId) public view virtual override returns (string memory) {
    return _uris[tokenId];
  }

  /**
   * Stake some eth to allow the admin to claim artifacts for you
   */
  function stake() public payable {
    stakes[msg.sender] += msg.value;
  }

  /**
   * Get your staked eth back
   */
  function unstake() public {
    require(stakes[msg.sender] > 0, "No stake");
    uint256 staked = stakes[msg.sender];
    stakes[msg.sender] = 0;
    payable(msg.sender).transfer(staked);
  }

  /**
   * Allows a MINTER from the parent contract to mint eggs to address
   * @param to: address of the token recipient
   *
   * Error messages:
   *  - AC0: "You dont have required role"
   */
  function giveEgg(address to) override external {
    require(nefturians.hasRole(MINTER_ROLE, msg.sender), "AC0");
    _mint(to, 0, 1, "");
  }

  /**
   * Claim artifacts with a egg for a user. One egg gives one random artifact of a random rarity level
   * @param quantity: quantity of eggs to use
   * @param userSeed: random seed from the user
   * @param serverSeed: random seed from the server
   * @param signature: the user seed signed with the token owner's private key
   *
   * Error messages:
   *  - AC0: "You dont have required role"
   *  - NA00: "Your stake does not cover the gas price"
   *  - NA01: "Division by zero"
   *  - NA08: "Balance too low"
   */
  function claimArtifact(
    uint256 quantity,
    bytes4 userSeed,
    bytes4 serverSeed,
    bytes calldata signature
  ) public {
    require(nefturians.hasRole(SIGNER_ROLE, msg.sender), "AC0");
    address caller = ECDSALibrary.recover(abi.encodePacked(userSeed), signature);
    require(balanceOf(caller, 0) >= quantity, "NA00");
    require(stakes[caller] >= tx.gasprice, "NA01");
    _burn(caller, 0, quantity);
    for (uint256 i = 0; i < quantity; i++) {
      uint256 number = uint256(keccak256(abi.encodePacked(userSeed, serverSeed, i)));
      distributeReward(caller, number);
    }
    stakes[caller] -= tx.gasprice;
    payable(msg.sender).transfer(tx.gasprice);
  }

  /**
   * Mint reward based on odds and egg number
   * @param rewardee: address of receiver
   * @param ticket: random number
   *
   * Error messages:
   *  - NA02: "Division by zero"
   */
  function distributeReward(address rewardee, uint256 ticket) internal {
    uint256 number = ticket % 100000;
    uint256 rarity;

    if (number < odds[0]) {
      rarity = 0;
    }
    else if (number < odds[1]) {
      rarity = 1;
    }
    else if (number < odds[2]) {
      rarity = 2;
    }
    else {
      rarity = 3;
    }

    require(countByRarity[rarity] > 0, "NA02");
    uint256 index = ticket % countByRarity[rarity];
    _mint(rewardee, indexesByRarity[rarity][index], 1, "");
  }

  /**
   * Allow an owner of consumable tokens to use them
   * @param tokenId: id of the token to be used
   * @param quantity: quantity to be used
   *
   * Error messages:
   *  - NA06: "Item not consummable"
   *  - NA04: "Not enough artifacts"
   */
  function useArtifact(uint256 tokenId, uint256 quantity) public {
    require(consumable[tokenId], "NA06");
    require(balanceOf(msg.sender, tokenId) >= quantity, "NA04");
    _burn(msg.sender, tokenId, quantity);
    emit UseArtifact(tokenId, quantity);
  }

  function _setURI(uint256 tokenId, string memory newuri) internal {
    _uris[tokenId] = newuri;
  }

  function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
  internal
  override(ERC1155, ERC1155Supply)
  {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  // The following functions are overrides required by Solidity.
  function supportsInterface(bytes4 interfaceId)
  public
  view
  override(ERC1155, IERC165)
  returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
  function transferOwnership(address newOwner) public override(INefturianArtifact, Ownable) onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/ECDSALibrary.sol";
import "../libraries/StringsLibrary.sol";
import "../interfaces/INefturiansData.sol";
import "../interfaces/INefturians.sol";

/**********************************************************************************************************************/
/*                                                                                                                    */
/*                                                  Nefturians Data                                                   */
/*                                                                                                                    */
/*                     NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                     */
/*                  NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                  */
/*                NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                */
/*              NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN              */
/*             NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN             */
/*            NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN            */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN...NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN........NNNNNNNNNNNNNNNNNNN.......NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN...........NNNNNNNNNNNNNNNN.........NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNN...............NNNNNNNNNNNN............NNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNN.................NNNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNN...................NNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNN.....................NNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNN.......................NNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNN..........................NNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNN.............................NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNN............NNNN...............NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNN............NNNNNN...............NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNN.............NNNNNNNN...............NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNN.............NNNNNNNNNN..............NNNNNNNNNN............NNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNN.............NNNNNNNNNN..............NNNNNNNN.............NNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNN.............NNNNNNNNNN...............NNNNN.............NNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNN...............NNN.............NNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNN.............NNNNNNNNNN............................NNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNN..........................NNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNN........................NNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNN.....................NNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNNN..................NNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNNN................NNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNN...........NNNNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN.........NNNNNNNNNNNNNNNN...........NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN.......NNNNNNNNNNNNNNNNNNN........NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN.NNNNNNNNNNNNNNNNNNNNNNNNNN.NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*            NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN            */
/*             NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN             */
/*               NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN               */
/*                 NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                 */
/*                    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                     */
/*                                                                                                                    */
/*                                                                                                                    */
/*                                                                                                                    */
/**********************************************************************************************************************/


contract NefturiansData is Ownable, INefturiansData {

  /**
   * Roles for the access control
   * these roles are only checked against the parent contract's settings
   */
  bytes32 internal constant DAO_ROLE = keccak256("DAO_ROLE");
  bytes32 internal constant METADATA_ROLE = keccak256("METADATA_ROLE");
  bytes32 internal constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

  /**
   * Metadata and Attributes
   */
  uint256 internal metadataKeysCounter;
  mapping(uint256 => string) internal metadataKeys;
  mapping(uint256 => mapping(uint256 => uint256)) internal attributes;
  mapping(uint256 => mapping(uint256 => string)) internal metadata;

  /**
   * Parent contract: The Nefturians collection
   */
  INefturians private collection;

  constructor() {
    metadataKeys[0] = "name";
    metadataKeys[1] = "strength";
    metadataKeysCounter = 2;
    collection = INefturians(msg.sender);
  }

  /**
   * Get the metadata of a token in an easily parseable format (dotenv-style)
   * @param tokenId: id of the token for which we want the metadata
   */
  function getMetadata(uint256 tokenId) public view returns (string memory) {
    string memory metadataString;
    for (uint256 index = 0; index < metadataKeysCounter; index++) {
      if (bytes(metadata[tokenId][index]).length != 0){
        metadataString = string(abi.encodePacked(metadataString, metadataKeys[index], "=", metadata[tokenId][index], "\n"));
      }
      else if (attributes[tokenId][index] != 0) {
        metadataString = string(abi.encodePacked(metadataString, metadataKeys[index], "=", StringsLibrary.toString(attributes[tokenId][index]), "\n"));
      }
    }
    return metadataString;
  }

  /**
   * Add new metadatakey
   * @param keyName: name of the new metadata key
   *
   * Error messages:
   *  - ND1: "Unauthorized to add key"
   */
  function addKey(string calldata keyName) public onlyOwner {
    metadataKeys[metadataKeysCounter + 1] = keyName;
    metadataKeysCounter += 1;
  }

  /**
   * Set a string metadata for a given token with specific key
   * @param tokenId: token id for which to set metadata
   * @param key: metadata key id
   * @param value: on chain metadata value
   * @param signature to authorize the transaction:
   *      - SIGNER_ROLE signed metadata if the update is performed by the owner
   *      - Token owner's signed metadata if the update is performed by the DAO and signed by the owner
   *
   * Error messages:
   *  - ND2: "Not authorized to update metadata"
   */
  function setMetadata(uint256 tokenId, uint256 key, string calldata value, bytes calldata signature) public {
    address owner = collection.ownerOf(tokenId);
    uint256 nonce = collection.getNonce(owner);
    address signer = ECDSALibrary.recover(abi.encodePacked(
        owner,
        nonce,
        tokenId,
        key,
        value
      ), signature);
    require(
      (msg.sender == owner && collection.hasRole(SIGNER_ROLE, signer)) ||
      (signer == owner && collection.hasRole(DAO_ROLE, msg.sender)), "ND2"
    );
    collection.incrementNonce(owner);
    metadata[tokenId][key] = value;
    emit MetadataUpdated(tokenId, key, value);
  }

  /**
   * Set the numeric metadata (attributes) of a token
   * @param tokenId: id of the token for which to set new attributes
   * @param keys: array of keys from attributes to be updated
   * @param values: values for each key of the new attributes
   * @param signature:
   *      - SIGNER_ROLE or DAO_ROLE signature to authorize on chain metadata update
   *      - SIGNER_ROLE signed metadata if the update is performed by the owner
   *      - DAO_ROLE caller if the update is performed by the DAO and signed by the owner
   *
   * Error messages:
   *  - ND0: "Array lengths do not match"
   *  - ND2: "Not authorized to update metadata"
   */
  function setAttributes(uint256 tokenId, uint256[] calldata keys, uint256[] calldata values, bytes calldata signature) public {
    require(keys.length == values.length, "ND0");
    address owner = collection.ownerOf(tokenId);
    uint256 nonce = collection.getNonce(owner);
    address signer = ECDSALibrary.recover(abi.encodePacked(
        owner,
        nonce,
        tokenId,
        keys,
        values
      ), signature);
    require(
      (msg.sender == owner && collection.hasRole(SIGNER_ROLE, signer)) ||
      (signer == owner && collection.hasRole(DAO_ROLE, msg.sender)), "ND2"
    );
    for (uint256 i = 0; i < keys.length; i++) {
      attributes[tokenId][keys[i]] = values[i];
      emit AttributeUpdated(tokenId, keys[i], values[i]);
    }
    collection.incrementNonce(owner);
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)
// Made public and linkable by Nefture

pragma solidity 0.8.11;

/**
 * @dev String operations.
 */
library StringsLibrary {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) public pure returns (string memory) {
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
    function toHexString(uint256 value) public pure returns (string memory) {
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
    function toHexString(uint256 value, uint256 length) public pure returns (string memory) {
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
pragma solidity 0.8.11;

interface IAccessControl {

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function hasRole(bytes32 role, address account) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}