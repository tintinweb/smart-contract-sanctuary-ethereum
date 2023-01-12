// SPDX-License-Identifier: MIT

/*
TODO
  - better ascii art, docs
*/


/*
Study Hall Contract Design

There are three main goals for the Study Hall contract:
1. To keep ownership of the entire collection consolidated to a single owner
2. To ensure that the single owner is an estate-approved arts organization.
3. To potentially allow tokens to be securely lent to (and returned from) third parties


Base Contract - ERC721A (sans ERC721Enumerable)
- Enables cost-efficient transfers + minting of all tokens


Minting/Tokens
- Tokens #0 - #500 will go to Fellowship
- #0 [Archivist Token]
- #1 - #500 [Image Tokens]


Roles
- Archivist [This role is held by whoever owns token #0. Initially, this will be Fellowship Trust]
- Custodian [This role will be assigned to Sultan Studios]
- Library [The Archivist and Custodian can add/remove addresses to the Library list]


Archivist Token Transfer
- The Archivist Token (#0) can only be transferred/approved to addresses on the Archivist Token Transfer Allow List
- Addresses can only be added/removed to/from the allow list by the Custodian
- Transferring the Archivist token will also transfer tokens #1 - #500 to the same address


Lending State
- The contract Lending State will be set to `false` by default
- The Lending State can be set to `true` if and only if both the Archivist AND the Custodian agree
- The Lending State can be set to `false` if EITHER the Archivist OR the Custodian decide
- If moving from `true` -> `false`, recall all tokens to Archivist

Image Token Transfer
- If Lending State == false
Tokens #1 - #500 cannot be transferred (except when transferring token #0)
- If Lending State == true
Tokens #1 - #500 can be transferred
Libraries can execute arbitrary transferFrom transactions for tokens #1-500 (transfer tokens to and from wallets)


Image Token Recall
- Regardless of Lending State, both the Custodian and the Archivist can call the `recall` function, which will transfer all image tokens (#1 - #500) back to the Archivist.


*/

import "./Dependencies.sol";
import "./TokenURI.sol";

pragma solidity ^0.8.11;


contract StudyHallBase is ERC721A, Ownable {
  string public license = 'CC BY-NC 4.0';

  StudyHallTokenURI public tokenURIContract;
  mapping(StudyHallTokenURI => bool) public proposedTokenURIContracts;

  mapping(address => bool) public recipientAllowList;
  mapping(address => bool) private _libraries;

  address private royaltyBeneficiary;
  uint16 private royaltyBasisPoints = 1000;

  bool private isMinting;
  bool private token0TransferInProgress;
  bool private recalling;

  bool public custodianLendingStateApproved;
  bool public archivistLendingStateApproved;
  bool private lendingStateApproved;

  event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
  event ProjectEvent(address indexed poster, string indexed eventType, string content);
  event TokenEvent(address indexed poster, uint256 indexed tokenId, string indexed eventType, string content);


  constructor() ERC721A('Study Hall', 'STUDY') {
    tokenURIContract = new StudyHallTokenURI();
    proposedTokenURIContracts[tokenURIContract] = true;
    royaltyBeneficiary = msg.sender;
  }


  // Roles

  // Keeping the standard ownable interface for ecosystem purposes, but renaming to "custodian" for clarity with respect to the token #0 owner
  function custodian() public view returns (address) {
    return owner();
  }

  function archivist() public view returns (address) {
    return ownerOf(0);
  }

  function isLibrary(address addr) public view returns (bool) {
    return _libraries[addr];
  }

  modifier onlyCustodian() {
    require(custodian() == msg.sender, "Caller is not the custodian");
    _;
  }

  modifier onlyArchivist() {
    require(archivist() == msg.sender, "Caller is not the archivist");
    _;
  }

  modifier onlyCustodianOrArchivist() {
    require(custodian() == msg.sender || archivist() == msg.sender, "Caller is not the custodian or archivist");
    _;
  }

  modifier onlyLibrary() {
    require(isLibrary(msg.sender), "Caller is not a library");
    _;
  }


  /**
   * @dev Updates the license. Can only be called by the custodian
   */
  function updateLicense(string calldata newLicense) external onlyCustodian {
    license = newLicense;
  }

  /**
   * @dev Designates a given address as a library when status is true. This permission can be revoked by setting status to false. Can be called by either the custodian or the archivist
   */
  function setLibrary(address _library, bool status) public onlyCustodianOrArchivist {
    _libraries[_library] = status;
  }

  /**
   * @dev Says whether the given tokenId has been minted
   */
  function exists(uint256 tokenId) external view returns (bool) {
    return _exists(tokenId);
  }


  // Minting

  /**
   * @dev Mints all image tokens to the recipient address. Can only be called by the custodian
   */
  function mint(address recipient) external onlyCustodian {
    require(totalSupply() == 0, 'Collection has already been minted');
    recipientAllowList[recipient] = true;

    isMinting = true;
    _mint(recipient, 501);
    isMinting = false;
  }


  // Transfers

  /**
   * @dev Adds/removes the recipient address to/from the allow list for receiving the Archivist token. Can only be called by the custodian
   */
  function allowRecipient(address recipient, bool allowed) public onlyCustodian {
    if (recipient == archivist()) require(allowed, 'Cannot remove the archivist from the allow list');

    recipientAllowList[recipient] = allowed;
  }

  function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
    return (isLibrary(operator) && lendingState())
      || token0TransferInProgress
      || recalling
      || super.isApprovedForAll(owner, operator);
  }

  function _beforeTokenTransfers(
    address,
    address to,
    uint256 startTokenId,
    uint256
  ) internal virtual override {
    if (isMinting) return;

    bool isLendingTx = lendingState() && isLibrary(msg.sender);

    if (startTokenId == 0) {
      require(recipientAllowList[to] == true, 'Recipient not on allow list');
      require(!isLendingTx, 'Library cannot transfer the #0 token');
      token0TransferInProgress = true;
    } else {
      require(isLendingTx || recalling || token0TransferInProgress, 'Cannot transfer token outside lending state');
    }
  }

  function _afterTokenTransfers(
    address,
    address to,
    uint256 startTokenId,
    uint256
  ) internal virtual override {
    if (isMinting) return;
    bool transferAllTokens = startTokenId == 0 && !lendingState();


    if (transferAllTokens) {
      for (uint256 i = 1; i < 501; ++i) {
        safeTransferFrom(ownerOf(i), to, i);
      }
    }

    if (startTokenId == 500) {
      token0TransferInProgress = false;
    }
  }


  // Lending State

  function lendingState() public view returns (bool) {
    return lendingStateApproved;
  }

  /**
   * @dev Both the custodian and the archivist must set this approval to true to enter a lending state. If either one sets it to false (which is the default state), then the contract is no longer in a lending state.
   */
  function setLendingStateApproval(bool approval) external onlyCustodianOrArchivist {
    if (msg.sender == custodian()) {
      custodianLendingStateApproved = approval;
    } else {
      archivistLendingStateApproved = approval;
    }

    lendingStateApproved = custodianLendingStateApproved && archivistLendingStateApproved;
  }


  // Recall

  /**
   * @dev Allows the custodian or the archivist to transfer the given range of tokens to the archivist while in a lending state.
   */
  function recallTokens(uint256 start, uint256 stop) external onlyCustodianOrArchivist {
    recalling = true;
    require(start > 0, 'Invalid range');
    require(stop < 501, 'Invalid range');

    address _archivist = archivist();
    for (uint256 tokenId = start; tokenId <= stop; ++tokenId) {
      address tokenOwner = ownerOf(tokenId);
      if (tokenOwner != _archivist) {
        transferFrom(ownerOf(tokenId), _archivist, tokenId);
      }
    }

    recalling = false;
  }


  // Token URI

  /**
   * @dev Adds a new tokenURI contract to the tokenURI allow list. Can only be called by the custodian
   */
  function proposeTokenURIContract(StudyHallTokenURI _tokenURIContract) external onlyCustodian {
    proposedTokenURIContracts[_tokenURIContract] = true;
  }

  /**
   * @dev Designates a contract on the tokenURI allow list as the official URI contract. Can only be called by the archivist
   */
  function setTokenURIContract(StudyHallTokenURI _tokenURIContract) external onlyArchivist {
    require(proposedTokenURIContracts[_tokenURIContract], 'Contract address must be on proposed tokenURI list');
    tokenURIContract = _tokenURIContract;
    emit BatchMetadataUpdate(0, 500);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'URI query for nonexistent token');
    return tokenURIContract.tokenURI(tokenId);
  }


  // Events

  function emitTokenEvent(uint256 tokenId, string calldata eventType, string calldata content) external {
    require(
      owner() == msg.sender || ERC721A.ownerOf(tokenId) == msg.sender,
      'Only custodian or token owner can emit token event'
    );
    emit TokenEvent(msg.sender, tokenId, eventType, content);
  }

  function emitProjectEvent(string calldata eventType, string calldata content) external onlyCustodian {
    emit ProjectEvent(msg.sender, eventType, content);
  }


  // Royalty Info

  function setRoyaltyInfo(
    address _royaltyBeneficiary,
    uint16 _royaltyBasisPoints
  ) external onlyCustodian {
    royaltyBeneficiary = _royaltyBeneficiary;
    royaltyBasisPoints = _royaltyBasisPoints;
  }

  function royaltyInfo(uint256, uint256 _salePrice) external view returns (address, uint256) {
    return (royaltyBeneficiary, _salePrice * royaltyBasisPoints / 10000);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
    // ERC2981 & ERC4906
    return interfaceId == bytes4(0x2a55205a) || interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
  }
}