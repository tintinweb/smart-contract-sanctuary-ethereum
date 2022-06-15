// SPDX-License-Identifier: UNLICENSED
/*

  ,,,,,,,,,,,
 [ HOLOGRAPH ]
  '''''''''''
  _____________________________________________________________
 |                                                             |
 |                            / ^ \                            |
 |                            ~~*~~            .               |
 |                         [ '<>:<>' ]         |=>             |
 |               __           _/"\_           _|               |
 |             .:[]:.          """          .:[]:.             |
 |           .'  []  '.        \_/        .'  []  '.           |
 |         .'|   []   |'.               .'|   []   |'.         |
 |       .'  |   []   |  '.           .'  |   []   |  '.       |
 |     .'|   |   []   |   |'.       .'|   |   []   |   |'.     |
 |   .'  |   |   []   |   |  '.   .'  |   |   []   |   |  '.   |
 |.:'|   |   |   []   |   |   |':'|   |   |   []   |   |   |':.|
 |___|___|___|___[]___|___|___|___|___|___|___[]___|___|___|___|
 |XxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxX|
 |^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^|
 |               []                           []               |
 |               []                           []               |
 |    ,          []     ,        ,'      *    []               |
 |~~~~~^~~~~~~~~/##\~~~^~~~~~~~~^^~~~~~~~~^~~/##\~~~~~~~^~~~~~~|
 |_____________________________________________________________|

      - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";
import "./abstract/Owner.sol";

import "./enum/HolographERC721Event.sol";
import "./enum/InterfaceType.sol";

import "./interface/ERC165.sol";
import "./interface/ERC721.sol";
import "./interface/ERC721Holograph.sol";
import "./interface/ERC721Metadata.sol";
import "./interface/ERC721TokenReceiver.sol";
import "./interface/HolographedERC721.sol";
import "./interface/IHolograph.sol";
import "./interface/IHolographer.sol";
import "./interface/IHolographRegistry.sol";
import "./interface/IInitializable.sol";
import "./interface/IInterfaces.sol";
import "./interface/IPA1D.sol";
import "./interface/Ownable.sol";

/**
 * @title Holograph Bridgeable ERC-721 Collection
 * @author CXIP-Labs
 * @notice A smart contract for minting and managing Holograph Bridgeable ERC721 NFTs.
 * @dev The entire logic and functionality of the smart contract is self-contained.
 */
contract HolographERC721 is Admin, Owner, ERC721Holograph, Initializable {
  /**
   * @dev Configuration for events to trigger for source smart contract.
   */
  uint256 private _eventConfig;

  /**
   * @dev Collection name.
   */
  string private _name;

  /**
   * @dev Collection symbol.
   */
  string private _symbol;

  /**
   * @dev Collection royalty base points.
   */
  uint16 private _bps;

  /**
   * @dev Array of all token ids in collection.
   */
  uint256[] private _allTokens;

  /**
   * @dev Map of token id to array index of _ownedTokens.
   */
  mapping(uint256 => uint256) private _ownedTokensIndex;

  /**
   * @dev Token id to wallet (owner) address map.
   */
  mapping(uint256 => address) private _tokenOwner;

  /**
   * @dev 1-to-1 map of token id that was assigned an approved operator address.
   */
  mapping(uint256 => address) private _tokenApprovals;

  /**
   * @dev Map of total tokens owner by a specific address.
   */
  mapping(address => uint256) private _ownedTokensCount;

  /**
   * @dev Map of array of token ids owned by a specific address.
   */
  mapping(address => uint256[]) private _ownedTokens;

  /**
   * @notice Map of full operator approval for a particular address.
   * @dev Usually utilised for supporting marketplace proxy wallets.
   */
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
   * @dev Mapping from token id to position in the allTokens array.
   */
  mapping(uint256 => uint256) private _allTokensIndex;

  /**
   * @dev Mapping of all token ids that have been burned. This is to prevent re-minting of same token ids.
   */
  mapping(uint256 => bool) private _burnedTokens;

  /**
   * @notice Constructor is empty and not utilised.
   * @dev To make exact CREATE2 deployment possible, constructor is left empty. We utilize the "init" function instead.
   */
  constructor() {}

  /**
   * @notice Gets a base64 encoded contract JSON file.
   * @return string The URI.
   */
  function contractURI() external view returns (string memory) {
    return IInterfaces(_interfaces()).contractURI(_name, "", "", _bps, address(this));
  }

  /**
   * @notice Gets the name of the collection.
   * @return string The collection name.
   */
  function name() external view returns (string memory) {
    return _name;
  }

  /**
   * @notice Shows the interfaces the contracts support
   * @dev Must add new 4 byte interface Ids here to acknowledge support
   * @param interfaceId ERC165 style 4 byte interfaceId.
   * @return bool True if supported.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool) {
    if (
      IInterfaces(_interfaces()).supportsInterface(InterfaceType.ERC721, interfaceId) || // check global interfaces
      ERC165(_royalties()).supportsInterface(interfaceId) || // check if royalties supports interface
      ERC165(_source()).supportsInterface(interfaceId) // check if source supports interface
    ) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * @notice Gets the collection's symbol.
   * @return string The symbol.
   */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  /**
   * @notice Get's the URI of the token.
   * @dev Defaults the the Arweave URI
   * @return string The URI.
   */
  function tokenURI(uint256 tokenId) external view returns (string memory) {
    require(_exists(tokenId), "ERC721: token does not exist");
    return ERC721Metadata(_source()).tokenURI(tokenId);
  }

  /**
   * @notice Get list of tokens owned by wallet.
   * @param wallet The wallet address to get tokens for.
   * @return uint256[] Returns an array of token ids owned by wallet.
   */
  function tokensOfOwner(address wallet) external view returns (uint256[] memory) {
    return _ownedTokens[wallet];
  }

  /**
   * @notice Get set length list, starting from index, for tokens owned by wallet.
   * @param wallet The wallet address to get tokens for.
   * @param index The index to start enumeration from.
   * @param length The length of returned results.
   * @return tokenIds uint256[] Returns a set length array of token ids owned by wallet.
   */
  function tokensOfOwner(
    address wallet,
    uint256 index,
    uint256 length
  ) external view returns (uint256[] memory tokenIds) {
    uint256 supply = _ownedTokensCount[wallet];
    if (index + length > supply) {
      length = supply - index;
    }
    tokenIds = new uint256[](length);
    for (uint256 i = 0; i < length; i++) {
      tokenIds[i] = _ownedTokens[wallet][index + i];
    }
  }

  /**
   * @notice Adds a new address to the token's approval list.
   * @dev Requires the sender to be in the approved addresses.
   * @param to The address to approve.
   * @param tokenId The affected token.
   */
  function approve(address to, uint256 tokenId) external payable {
    address tokenOwner = _tokenOwner[tokenId];
    require(to != tokenOwner, "ERC721: cannot approve self");
    require(_isApproved(msg.sender, tokenId), "ERC721: not approved sender");
    if (_isEventRegistered(HolographERC721Event.beforeApprove)) {
      require(SourceERC721().beforeApprove(tokenOwner, to, tokenId));
    }
    _tokenApprovals[tokenId] = to;
    emit Approval(tokenOwner, to, tokenId);
    if (_isEventRegistered(HolographERC721Event.afterApprove)) {
      require(SourceERC721().afterApprove(tokenOwner, to, tokenId));
    }
  }

  /**
   * @notice Burns the token.
   * @dev The sender must be the owner or approved.
   * @param tokenId The token to burn.
   */
  function burn(uint256 tokenId) external {
    require(_isApproved(msg.sender, tokenId), "ERC721: not approved sender");
    address wallet = _tokenOwner[tokenId];
    if (_isEventRegistered(HolographERC721Event.beforeBurn)) {
      require(SourceERC721().beforeBurn(wallet, tokenId));
    }
    _burn(wallet, tokenId);
    if (_isEventRegistered(HolographERC721Event.afterBurn)) {
      require(SourceERC721().afterBurn(wallet, tokenId));
    }
  }

  /**
   * @dev Allows the bridge to bring in a token from another blockchain.
   *  Note: function selector 0x2dd69ea4 is bytes4(keccak256("holographBridgeIn(address,address,uint256,bytes)"))
   */
  function holographBridgeIn(
    uint32 chainType,
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4) {
    require(msg.sender == _bridge(), "ERC721: only bridge can call");
    require(!_exists(tokenId), "ERC721: token already exists");
    delete _burnedTokens[tokenId];
    _mint(to, tokenId);
    if (_isEventRegistered(HolographERC721Event.bridgeIn)) {
      require(SourceERC721().bridgeIn(chainType, from, to, tokenId, data), "HOLOGRAPH: bridge in failed");
    }
    return ERC721Holograph.holographBridgeIn.selector;
  }

  /**
   * @dev Allows the bridge to take a token out onto another blockchain.
   *  Note: function selector 0x57aeff0a is bytes4(keccak256("holographBridgeOut(address,address,uint256)"))
   */
  function holographBridgeOut(
    uint32 chainType,
    address from,
    address to,
    uint256 tokenId
  ) external returns (bytes4 selector, bytes memory data) {
    require(msg.sender == _bridge(), "ERC721: only bridge can call");
    if (_isEventRegistered(HolographERC721Event.bridgeOut)) {
      data = SourceERC721().bridgeOut(chainType, from, to, tokenId);
    }
    _burn(from, tokenId);
    return (ERC721Holograph.holographBridgeOut.selector, data);
  }

  /**
   * @notice Initializes the collection.
   * @dev Special function to allow a one time initialisation on deployment. Also configures and deploys royalties.
   */
  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "ERC721: already initialized");
    assembly {
      sstore(0x89b583059fdb0b2e807359b64eba1a8a1e6d099210701fafe6dad5dd2cd64fb8, caller())
    }
    (
      string memory contractName,
      string memory contractSymbol,
      uint16 contractBps,
      uint256 eventConfig,
      bool skipInit,
      bytes memory initCode
    ) = abi.decode(data, (string, string, uint16, uint256, bool, bytes));
    _name = contractName;
    _symbol = contractSymbol;
    _bps = contractBps;
    _eventConfig = eventConfig;
    if (!skipInit) {
      require(
        IInitializable(_source()).init(initCode) == IInitializable.init.selector,
        "ERC721: could not init source"
      );
      (bool success, bytes memory returnData) = _royalties().delegatecall(
        abi.encodeWithSignature("initPA1D(bytes)", abi.encode(address(this), uint256(contractBps)))
      );
      bytes4 selector = abi.decode(returnData, (bytes4));
      require(success && selector == IInitializable.init.selector, "ERC721: coud not init PA1D");
    }

    _setInitialized();
    return IInitializable.init.selector;
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   * @param from cannot be the zero address.
   * @param to cannot be the zero address.
   * @param tokenId token must exist and be owned by `from`.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external payable {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @notice Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * @dev Since it's not being used, the _data variable is commented out to avoid compiler warnings.
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   * @param from cannot be the zero address.
   * @param to cannot be the zero address.
   * @param tokenId token must exist and be owned by `from`.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable {
    require(_isApproved(msg.sender, tokenId), "ERC721: not approved sender");
    if (_isEventRegistered(HolographERC721Event.beforeSafeTransfer)) {
      require(SourceERC721().beforeSafeTransfer(from, to, tokenId, data));
    }
    _transferFrom(from, to, tokenId);
    if (_isContract(to)) {
      require(
        (ERC165(to).supportsInterface(ERC165.supportsInterface.selector) &&
          ERC165(to).supportsInterface(ERC721TokenReceiver.onERC721Received.selector) &&
          ERC721TokenReceiver(to).onERC721Received(address(this), from, tokenId, data) ==
          ERC721TokenReceiver.onERC721Received.selector),
        "ERC721: onERC721Received fail"
      );
    }
    if (_isEventRegistered(HolographERC721Event.afterSafeTransfer)) {
      require(SourceERC721().afterSafeTransfer(from, to, tokenId, data));
    }
  }

  /**
   * @notice Adds a new approved operator.
   * @dev Allows platforms to sell/transfer all your NFTs. Used with proxy contracts like OpenSea/Rarible.
   * @param to The address to approve.
   * @param approved Turn on or off approval status.
   */
  function setApprovalForAll(address to, bool approved) external {
    require(to != msg.sender, "ERC721: cannot approve self");
    if (_isEventRegistered(HolographERC721Event.beforeApprovalAll)) {
      require(SourceERC721().beforeApprovalAll(to, approved));
    }
    _operatorApprovals[msg.sender][to] = approved;
    emit ApprovalForAll(msg.sender, to, approved);
    if (_isEventRegistered(HolographERC721Event.afterApprovalAll)) {
      require(SourceERC721().afterApprovalAll(to, approved));
    }
  }

  /**
   * @dev Allows for source smart contract to burn a token.
   *  Note: this is put in place to make sure that custom logic could be implemented for merging, gamification, etc.
   *  Note: token cannot be burned if it's locked by bridge.
   */
  function sourceBurn(uint256 tokenId) external {
    require(msg.sender == _source(), "ERC721: only source can burn");
    address wallet = _tokenOwner[tokenId];
    require(wallet != _bridge(), "ERC721: token is bridged");
    _burn(wallet, tokenId);
  }

  /**
   * @dev Allows for source smart contract to mint a token.
   */
  function sourceMint(address to, uint224 tokenId) external {
    require(msg.sender == _source(), "ERC721: only source can mint");
    // uint32 is reserved for chain id to be used
    // we need to get current chain id, and prepend it to tokenId
    // this will prevent possible tokenId overlap if minting simultaneously on multiple chains is possible
    uint256 token = uint256(bytes32(abi.encodePacked(_chain(), tokenId)));
    require(!_burnedTokens[token], "ERC721: can't mint burned token");
    _mint(to, token);
  }

  /**
   * @dev Allows source to get the prepend for their tokenIds.
   */
  function sourceGetChainPrepend() external view returns (uint256) {
    require(msg.sender == _source(), "ERC721: only source needs this");
    return uint256(bytes32(abi.encodePacked(_chain(), uint224(0))));
  }

  /**
   * @dev Allows for source smart contract to mint a batch of tokens.
   */
  function sourceMintBatch(address to, uint224[] calldata tokenIds) external {
    require(msg.sender == _source(), "ERC721: only source can mint");
    uint32 chain = _chain();
    uint256 token;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(!_burnedTokens[token], "ERC721: can't mint burned token");
      token = uint256(bytes32(abi.encodePacked(chain, tokenIds[i])));
      require(!_burnedTokens[token], "ERC721: can't mint burned token");
      _mint(to, token);
    }
  }

  /**
   * @dev Allows for source smart contract to mint a batch of tokens.
   */
  function sourceMintBatch(address[] calldata wallets, uint224[] calldata tokenIds) external {
    require(msg.sender == _source(), "ERC721: only source can mint");
    uint32 chain = _chain();
    uint256 token;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      token = uint256(bytes32(abi.encodePacked(chain, tokenIds[i])));
      require(!_burnedTokens[token], "ERC721: can't mint burned token");
      _mint(wallets[i], token);
    }
  }

  /**
   * @dev Allows for source smart contract to mint a batch of tokens.
   */
  function sourceMintBatchIncremental(
    address to,
    uint224 startingTokenId,
    uint256 length
  ) external {
    require(msg.sender == _source(), "ERC721: only source can mint");
    uint32 chain = _chain();
    uint256 token;
    for (uint256 i = 0; i < length; i++) {
      token = uint256(bytes32(abi.encodePacked(chain, startingTokenId)));
      require(!_burnedTokens[token], "ERC721: can't mint burned token");
      _mint(to, token);
      startingTokenId++;
    }
  }

  /**
   * @dev Allows for source smart contract to transfer a token.
   *  Note: this is put in place to make sure that custom logic could be implemented for merging, gamification, etc.
   *  Note: token cannot be transfered if it's locked by bridge.
   */
  function sourceTransfer(address to, uint256 tokenId) external {
    require(msg.sender == _source(), "ERC721: only source can transfer");
    address wallet = _tokenOwner[tokenId];
    require(wallet != _bridge(), "ERC721: token is bridged");
    _transferFrom(wallet, to, tokenId);
  }

  /**
   * @notice Transfers `tokenId` token from `msg.sender` to `to`.
   * @dev WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
   * @param to cannot be the zero address.
   * @param tokenId token must be owned by `from`.
   */
  function transfer(address to, uint256 tokenId) external payable {
    transferFrom(msg.sender, to, tokenId, "");
  }

  /**
   * @notice Transfers `tokenId` token from `from` to `to`.
   * @dev WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
   * @param from  cannot be the zero address.
   * @param to cannot be the zero address.
   * @param tokenId token must be owned by `from`.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable {
    transferFrom(from, to, tokenId, "");
  }

  /**
   * @notice Transfers `tokenId` token from `from` to `to`.
   * @dev WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
   * @dev Since it's not being used, the _data variable is commented out to avoid compiler warnings.
   * @param from  cannot be the zero address.
   * @param to cannot be the zero address.
   * @param tokenId token must be owned by `from`.
   * @param data additional data to pass.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable {
    require(_isApproved(msg.sender, tokenId), "ERC721: not approved sender");
    if (_isEventRegistered(HolographERC721Event.beforeTransfer)) {
      require(SourceERC721().beforeTransfer(from, to, tokenId, data));
    }
    _transferFrom(from, to, tokenId);
    if (_isEventRegistered(HolographERC721Event.afterTransfer)) {
      require(SourceERC721().afterTransfer(from, to, tokenId, data));
    }
  }

  /**
   * @notice Get total number of tokens owned by wallet.
   * @dev Used to see total amount of tokens owned by a specific wallet.
   * @param wallet Address for which to get token balance.
   * @return uint256 Returns an integer, representing total amount of tokens held by address.
   */
  function balanceOf(address wallet) public view returns (uint256) {
    require(wallet != address(0), "ERC721: zero address");
    return _ownedTokensCount[wallet];
  }

  function burned(uint256 tokenId) public view returns (bool) {
    return _burnedTokens[tokenId];
  }

  /**
   * @notice Decimal places to have for totalSupply.
   * @dev Since ERC721s are single, we use 0 as the decimal places to make sure a round number for totalSupply.
   * @return uint256 Returns the number of decimal places to have for totalSupply.
   */
  function decimals() external pure returns (uint256) {
    return 0;
  }

  function exists(uint256 tokenId) public view returns (bool) {
    return _tokenOwner[tokenId] != address(0);
  }

  /**
   * @notice Gets the approved address for the token.
   * @dev Single operator set for a specific token. Usually used for one-time very specific authorisations.
   * @param tokenId Token id to get approved operator for.
   * @return address Approved address for token.
   */
  function getApproved(uint256 tokenId) external view returns (address) {
    return _tokenApprovals[tokenId];
  }

  /**
   * @notice Checks if the address is approved.
   * @dev Includes references to OpenSea and Rarible marketplace proxies.
   * @param wallet Address of the wallet.
   * @param operator Address of the marketplace operator.
   * @return bool True if approved.
   */
  function isApprovedForAll(address wallet, address operator) external view returns (bool) {
    return _operatorApprovals[wallet][operator];
  }

  /**
   * @notice Checks who the owner of a token is.
   * @dev The token must exist.
   * @param tokenId The token to look up.
   * @return address Owner of the token.
   */
  function ownerOf(uint256 tokenId) external view returns (address) {
    address tokenOwner = _tokenOwner[tokenId];
    require(tokenOwner != address(0), "ERC721: token does not exist");
    return tokenOwner;
  }

  /**
   * @notice Get token by index.
   * @dev Used in conjunction with totalSupply function to iterate over all tokens in collection.
   * @param index Index of token in array.
   * @return uint256 Returns the token id of token located at that index.
   */
  function tokenByIndex(uint256 index) external view returns (uint256) {
    require(index < _allTokens.length, "ERC721: index out of bounds");
    return _allTokens[index];
  }

  /**
   * @notice Get set length list, starting from index, for all tokens.
   * @param index The index to start enumeration from.
   * @param length The length of returned results.
   * @return tokenIds uint256[] Returns a set length array of token ids minted.
   */
  function tokens(uint256 index, uint256 length) external view returns (uint256[] memory tokenIds) {
    uint256 supply = _allTokens.length;
    if (index + length > supply) {
      length = supply - index;
    }
    tokenIds = new uint256[](length);
    for (uint256 i = 0; i < length; i++) {
      tokenIds[i] = _allTokens[index + i];
    }
  }

  /**
   * @notice Get token from wallet by index instead of token id.
   * @dev Helpful for wallet token enumeration where token id info is not yet available. Use in conjunction with balanceOf function.
   * @param wallet Specific address for which to get token for.
   * @param index Index of token in array.
   * @return uint256 Returns the token id of token located at that index in specified wallet.
   */
  function tokenOfOwnerByIndex(address wallet, uint256 index) external view returns (uint256) {
    require(index < balanceOf(wallet), "ERC721: index out of bounds");
    return _ownedTokens[wallet][index];
  }

  /**
   * @notice Total amount of tokens in the collection.
   * @dev Ignores burned tokens.
   * @return uint256 Returns the total number of active (not burned) tokens.
   */
  function totalSupply() external view returns (uint256) {
    return _allTokens.length;
  }

  /**
   * @notice Empty function that is triggered by external contract on NFT transfer.
   * @dev We have this blank function in place to make sure that external contract sending in NFTs don't error out.
   * @dev Since it's not being used, the _operator variable is commented out to avoid compiler warnings.
   * @dev Since it's not being used, the _from variable is commented out to avoid compiler warnings.
   * @dev Since it's not being used, the _tokenId variable is commented out to avoid compiler warnings.
   * @dev Since it's not being used, the _data variable is commented out to avoid compiler warnings.
   * @return bytes4 Returns the interfaceId of onERC721Received.
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data
  ) external returns (bytes4) {
    require(_isContract(_operator), "ERC721: operator not contract");
    if (_isEventRegistered(HolographERC721Event.beforeOnERC721Received)) {
      require(SourceERC721().beforeOnERC721Received(_operator, _from, address(this), _tokenId, _data));
    }
    try ERC721Holograph(_operator).ownerOf(_tokenId) returns (address tokenOwner) {
      require(tokenOwner == address(this), "ERC721: contract not token owner");
    } catch {
      revert("ERC721: token does not exist");
    }
    if (_isEventRegistered(HolographERC721Event.afterOnERC721Received)) {
      require(SourceERC721().afterOnERC721Received(_operator, _from, address(this), _tokenId, _data));
    }
    return ERC721TokenReceiver.onERC721Received.selector;
  }

  /**
   * @dev Add a newly minted token into managed list of tokens.
   * @param to Address of token owner for which to add the token.
   * @param tokenId Id of token to add.
   */
  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    _ownedTokensIndex[tokenId] = _ownedTokensCount[to];
    _ownedTokensCount[to]++;
    _ownedTokens[to].push(tokenId);
    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

  /**
   * @notice Burns the token.
   * @dev All validation needs to be done before calling this function.
   * @param wallet Address of current token owner.
   * @param tokenId The token to burn.
   */
  function _burn(address wallet, uint256 tokenId) private {
    _clearApproval(tokenId);
    _tokenOwner[tokenId] = address(0);
    emit Transfer(wallet, address(0), tokenId);
    _removeTokenFromOwnerEnumeration(wallet, tokenId);
    _burnedTokens[tokenId] = true;
  }

  /**
   * @notice Deletes a token from the approval list.
   * @dev Removes from count.
   * @param tokenId T.
   */
  function _clearApproval(uint256 tokenId) private {
    delete _tokenApprovals[tokenId];
  }

  /**
   * @notice Mints an NFT.
   * @dev Can to mint the token to the zero address and the token cannot already exist.
   * @param to Address to mint to.
   * @param tokenId The new token.
   */
  function _mint(address to, uint256 tokenId) private {
    require(tokenId > 0, "ERC721: token id cannot be zero");
    require(to != address(0), "ERC721: minting to burn address");
    require(!_exists(tokenId), "ERC721: token already exists");
    require(!_burnedTokens[tokenId], "ERC721: token has been burned");
    _tokenOwner[tokenId] = to;
    emit Transfer(address(0), to, tokenId);
    _addTokenToOwnerEnumeration(to, tokenId);
  }

  function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
    uint256 lastTokenIndex = _allTokens.length - 1;
    uint256 tokenIndex = _allTokensIndex[tokenId];
    uint256 lastTokenId = _allTokens[lastTokenIndex];
    _allTokens[tokenIndex] = lastTokenId;
    _allTokensIndex[lastTokenId] = tokenIndex;
    delete _allTokensIndex[tokenId];
    delete _allTokens[lastTokenIndex];
    _allTokens.pop();
  }

  /**
   * @dev Remove a token from managed list of tokens.
   * @param from Address of token owner for which to remove the token.
   * @param tokenId Id of token to remove.
   */
  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
    _removeTokenFromAllTokensEnumeration(tokenId);
    _ownedTokensCount[from]--;
    uint256 lastTokenIndex = _ownedTokensCount[from];
    uint256 tokenIndex = _ownedTokensIndex[tokenId];
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
      _ownedTokens[from][tokenIndex] = lastTokenId;
      _ownedTokensIndex[lastTokenId] = tokenIndex;
    }
    if (lastTokenIndex == 0) {
      delete _ownedTokens[from];
    } else {
      delete _ownedTokens[from][lastTokenIndex];
      _ownedTokens[from].pop();
    }
  }

  /**
   * @dev Primary private function that handles the transfer/mint/burn functionality.
   * @param from Address from where token is being transferred. Zero address means it is being minted.
   * @param to Address to whom the token is being transferred. Zero address means it is being burned.
   * @param tokenId Id of token that is being transferred/minted/burned.
   */
  function _transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) private {
    require(_tokenOwner[tokenId] == from, "ERC721: token not owned");
    require(to != address(0), "ERC721: use burn instead");
    _clearApproval(tokenId);
    _tokenOwner[tokenId] = to;
    emit Transfer(from, to, tokenId);
    _removeTokenFromOwnerEnumeration(from, tokenId);
    _addTokenToOwnerEnumeration(to, tokenId);
  }

  function _chain() private view returns (uint32) {
    uint32 currentChain = IHolograph(IHolographer(payable(address(this))).getHolograph()).getChainType();
    if (currentChain != IHolographer(payable(address(this))).getOriginChain()) {
      return currentChain;
    }
    return uint32(0);
  }

  /**
   * @notice Checks if the token owner exists.
   * @dev If the address is the zero address no owner exists.
   * @param tokenId The affected token.
   * @return bool True if it exists.
   */
  function _exists(uint256 tokenId) private view returns (bool) {
    address tokenOwner = _tokenOwner[tokenId];
    return tokenOwner != address(0);
  }

  /**
   * @notice Checks if the address is an approved one.
   * @dev Uses inlined checks for different usecases of approval.
   * @param spender Address of the spender.
   * @param tokenId The affected token.
   * @return bool True if approved.
   */
  function _isApproved(address spender, uint256 tokenId) private view returns (bool) {
    require(_exists(tokenId), "ERC721: token does not exist");
    address tokenOwner = _tokenOwner[tokenId];
    return (spender == tokenOwner || _tokenApprovals[tokenId] == spender || _operatorApprovals[tokenOwner][spender]);
  }

  function _isContract(address contractAddress) private view returns (bool) {
    bytes32 codehash;
    assembly {
      codehash := extcodehash(contractAddress)
    }
    return (codehash != 0x0 && codehash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
  }

  /**
   * @dev Get the source smart contract as bridgeable interface.
   */
  function SourceERC721() private view returns (HolographedERC721) {
    return HolographedERC721(_source());
  }

  /**
   * @dev Get the bridge contract address.
   */
  function _bridge() private view returns (address) {
    return _holograph().getBridge();
  }

  /**
   * @dev Get the interfaces contract address.
   */
  function _interfaces() private view returns (address) {
    return _holograph().getInterfaces();
  }

  function owner() public view override returns (address) {
    return Ownable(_source()).owner();
  }

  function _holograph() private view returns (IHolograph holograph) {
    assembly {
      holograph := sload(0x1eee493315beeac80829afd0aaa340f3821cabe68571a2743478e81638a3d94d)
    }
  }

  /**
   * @dev Get the bridge contract address.
   */
  function _royalties() private view returns (address) {
    return
      IHolographRegistry(_holograph().getRegistry()).getContractTypeAddress(
        0x0000000000000000000000000000000000000000000000000000000050413144
      );
  }

  /**
   * @dev Get the source smart contract.
   */
  function _source() private view returns (address sourceContract) {
    assembly {
      sourceContract := sload(0xee63e41dd03b4d304382a6596ec5f4a6eb601d3640835d27fca1d0be62955bb5)
    }
  }

  /**
   * @dev Purposefully left empty, to prevent running out of gas errors when receiving native token payments.
   */
  receive() external payable {}

  /**
   * @notice Fallback to the source contract.
   * @dev Any function call that is not covered here, will automatically be sent over to the source contract.
   */
  fallback() external payable {
    // we check if royalties support the function, send there, otherwise revert to source
    address _target;
    if (IInterfaces(_interfaces()).supportsInterface(InterfaceType.PA1D, msg.sig)) {
      _target = _royalties();
      assembly {
        calldatacopy(0, 0, calldatasize())
        let result := delegatecall(gas(), _target, 0, calldatasize(), 0, 0)
        returndatacopy(0, 0, returndatasize())
        switch result
        case 0 {
          revert(0, returndatasize())
        }
        default {
          return(0, returndatasize())
        }
      }
    } else {
      _target = _source();
      assembly {
        calldatacopy(0, 0, calldatasize())
        mstore(calldatasize(), caller())
        let result := call(gas(), _target, callvalue(), 0, add(calldatasize(), 32), 0, 0)
        returndatacopy(0, 0, returndatasize())
        switch result
        case 0 {
          revert(0, returndatasize())
        }
        default {
          return(0, returndatasize())
        }
      }
    }
  }

  function _isEventRegistered(HolographERC721Event _eventName) private view returns (bool) {
    return ((_eventConfig >> uint256(_eventName)) & uint256(1) == 1 ? true : false);
  }
}

// SPDX-License-Identifier: UNLICENSED
/*

  ,,,,,,,,,,,
 [ HOLOGRAPH ]
  '''''''''''
  _____________________________________________________________
 |                                                             |
 |                            / ^ \                            |
 |                            ~~*~~            .               |
 |                         [ '<>:<>' ]         |=>             |
 |               __           _/"\_           _|               |
 |             .:[]:.          """          .:[]:.             |
 |           .'  []  '.        \_/        .'  []  '.           |
 |         .'|   []   |'.               .'|   []   |'.         |
 |       .'  |   []   |  '.           .'  |   []   |  '.       |
 |     .'|   |   []   |   |'.       .'|   |   []   |   |'.     |
 |   .'  |   |   []   |   |  '.   .'  |   |   []   |   |  '.   |
 |.:'|   |   |   []   |   |   |':'|   |   |   []   |   |   |':.|
 |___|___|___|___[]___|___|___|___|___|___|___[]___|___|___|___|
 |XxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxX|
 |^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^|
 |               []                           []               |
 |               []                           []               |
 |    ,          []     ,        ,'      *    []               |
 |~~~~~^~~~~~~~~/##\~~~^~~~~~~~~^^~~~~~~~~^~~/##\~~~~~~~^~~~~~~|
 |_____________________________________________________________|

      - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

abstract contract Admin {
  constructor() {}

  modifier onlyAdmin() {
    require(msg.sender == getAdmin(), "HOLOGRAPH: admin only function");
    _;
  }

  function admin() public view returns (address) {
    return getAdmin();
  }

  function getAdmin() public view returns (address adminAddress) {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.admin')) - 1);
    assembly {
      adminAddress := sload(
        /* slot */
        0x5705f5753aa4f617eef2cae1dada3d3355e9387b04d19191f09b545e684ca50d
      )
    }
  }

  function setAdmin(address adminAddress) public onlyAdmin {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.admin')) - 1);
    assembly {
      sstore(
        /* slot */
        0x5705f5753aa4f617eef2cae1dada3d3355e9387b04d19191f09b545e684ca50d,
        adminAddress
      )
    }
  }

  function adminCall(address target, bytes calldata data) external payable onlyAdmin {
    assembly {
      calldatacopy(0, data.offset, data.length)
      let result := call(gas(), target, callvalue(), 0, data.length, 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
/*

  ,,,,,,,,,,,
 [ HOLOGRAPH ]
  '''''''''''
  _____________________________________________________________
 |                                                             |
 |                            / ^ \                            |
 |                            ~~*~~            .               |
 |                         [ '<>:<>' ]         |=>             |
 |               __           _/"\_           _|               |
 |             .:[]:.          """          .:[]:.             |
 |           .'  []  '.        \_/        .'  []  '.           |
 |         .'|   []   |'.               .'|   []   |'.         |
 |       .'  |   []   |  '.           .'  |   []   |  '.       |
 |     .'|   |   []   |   |'.       .'|   |   []   |   |'.     |
 |   .'  |   |   []   |   |  '.   .'  |   |   []   |   |  '.   |
 |.:'|   |   |   []   |   |   |':'|   |   |   []   |   |   |':.|
 |___|___|___|___[]___|___|___|___|___|___|___[]___|___|___|___|
 |XxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxX|
 |^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^|
 |               []                           []               |
 |               []                           []               |
 |    ,          []     ,        ,'      *    []               |
 |~~~~~^~~~~~~~~/##\~~~^~~~~~~~~^^~~~~~~~~^~~/##\~~~~~~~^~~~~~~|
 |_____________________________________________________________|

      - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

import "../interface/IInitializable.sol";

abstract contract Initializable is IInitializable {
  function init(bytes memory _data) external virtual returns (bytes4);

  function _isInitialized() internal view returns (bool) {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.initialized')) - 1);
    uint256 initialized;
    assembly {
      initialized := sload(0x4e5f991bca30eca2d4643aaefa807e88f96a4a97398933d572a3c0d973004a01)
    }
    return (initialized > 0);
  }

  function _setInitialized() internal {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.initialized')) - 1);
    uint256 initialized = 1;
    assembly {
      sstore(
        /* slot */
        0x4e5f991bca30eca2d4643aaefa807e88f96a4a97398933d572a3c0d973004a01,
        initialized
      )
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
/*

  ,,,,,,,,,,,
 [ HOLOGRAPH ]
  '''''''''''
  _____________________________________________________________
 |                                                             |
 |                            / ^ \                            |
 |                            ~~*~~            .               |
 |                         [ '<>:<>' ]         |=>             |
 |               __           _/"\_           _|               |
 |             .:[]:.          """          .:[]:.             |
 |           .'  []  '.        \_/        .'  []  '.           |
 |         .'|   []   |'.               .'|   []   |'.         |
 |       .'  |   []   |  '.           .'  |   []   |  '.       |
 |     .'|   |   []   |   |'.       .'|   |   []   |   |'.     |
 |   .'  |   |   []   |   |  '.   .'  |   |   []   |   |  '.   |
 |.:'|   |   |   []   |   |   |':'|   |   |   []   |   |   |':.|
 |___|___|___|___[]___|___|___|___|___|___|___[]___|___|___|___|
 |XxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxX|
 |^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^|
 |               []                           []               |
 |               []                           []               |
 |    ,          []     ,        ,'      *    []               |
 |~~~~~^~~~~~~~~/##\~~~^~~~~~~~~^^~~~~~~~~^~~/##\~~~~~~~^~~~~~~|
 |_____________________________________________________________|

      - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

abstract contract Owner {
  /**
   * @dev Event emitted when contract owner is changed.
   */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {}

  modifier onlyOwner() virtual {
    require(msg.sender == getOwner(), "HOLOGRAPH: owner only function");
    _;
  }

  function owner() public view virtual returns (address) {
    return getOwner();
  }

  function getOwner() public view returns (address ownerAddress) {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.owner')) - 1);
    assembly {
      ownerAddress := sload(
        /* slot */
        0x89b583059fdb0b2e807359b64eba1a8a1e6d099210701fafe6dad5dd2cd64fb8
      )
    }
  }

  function setOwner(address ownerAddress) public onlyOwner {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.owner')) - 1);
    address previousOwner = getOwner();
    assembly {
      sstore(
        /* slot */
        0x89b583059fdb0b2e807359b64eba1a8a1e6d099210701fafe6dad5dd2cd64fb8,
        ownerAddress
      )
    }
    emit OwnershipTransferred(previousOwner, ownerAddress);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "HOLOGRAPH: zero address");
    assembly {
      sstore(0x89b583059fdb0b2e807359b64eba1a8a1e6d099210701fafe6dad5dd2cd64fb8, newOwner)
    }
  }

  function ownerCall(address target, bytes calldata data) external payable onlyOwner {
    assembly {
      calldatacopy(0, data.offset, data.length)
      let result := call(gas(), target, callvalue(), 0, data.length, 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
/*

  ,,,,,,,,,,,
 [ HOLOGRAPH ]
  '''''''''''
  _____________________________________________________________
 |                                                             |
 |                            / ^ \                            |
 |                            ~~*~~            .               |
 |                         [ '<>:<>' ]         |=>             |
 |               __           _/"\_           _|               |
 |             .:[]:.          """          .:[]:.             |
 |           .'  []  '.        \_/        .'  []  '.           |
 |         .'|   []   |'.               .'|   []   |'.         |
 |       .'  |   []   |  '.           .'  |   []   |  '.       |
 |     .'|   |   []   |   |'.       .'|   |   []   |   |'.     |
 |   .'  |   |   []   |   |  '.   .'  |   |   []   |   |  '.   |
 |.:'|   |   |   []   |   |   |':'|   |   |   []   |   |   |':.|
 |___|___|___|___[]___|___|___|___|___|___|___[]___|___|___|___|
 |XxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxX|
 |^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^|
 |               []                           []               |
 |               []                           []               |
 |    ,          []     ,        ,'      *    []               |
 |~~~~~^~~~~~~~~/##\~~~^~~~~~~~~^^~~~~~~~~^~~/##\~~~~~~~^~~~~~~|
 |_____________________________________________________________|

      - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

enum HolographERC721Event {
  UNDEFINED, // 0
  bridgeIn, //  1
  bridgeOut, //  2
  afterApprove, //  3
  beforeApprove, //  4
  afterApprovalAll, //  5
  beforeApprovalAll, //  6
  afterBurn, //  7
  beforeBurn, //  8
  afterMint, //  9
  beforeMint, // 10
  afterSafeTransfer, // 11
  beforeSafeTransfer, // 12
  afterTransfer, // 13
  beforeTransfer, // 14
  beforeOnERC721Received, // 15
  afterOnERC721Received // 16
}

// SPDX-License-Identifier: UNLICENSED
/*

  ,,,,,,,,,,,
 [ HOLOGRAPH ]
  '''''''''''
  _____________________________________________________________
 |                                                             |
 |                            / ^ \                            |
 |                            ~~*~~            .               |
 |                         [ '<>:<>' ]         |=>             |
 |               __           _/"\_           _|               |
 |             .:[]:.          """          .:[]:.             |
 |           .'  []  '.        \_/        .'  []  '.           |
 |         .'|   []   |'.               .'|   []   |'.         |
 |       .'  |   []   |  '.           .'  |   []   |  '.       |
 |     .'|   |   []   |   |'.       .'|   |   []   |   |'.     |
 |   .'  |   |   []   |   |  '.   .'  |   |   []   |   |  '.   |
 |.:'|   |   |   []   |   |   |':'|   |   |   []   |   |   |':.|
 |___|___|___|___[]___|___|___|___|___|___|___[]___|___|___|___|
 |XxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxX|
 |^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^|
 |               []                           []               |
 |               []                           []               |
 |    ,          []     ,        ,'      *    []               |
 |~~~~~^~~~~~~~~/##\~~~^~~~~~~~~^^~~~~~~~~^~~/##\~~~~~~~^~~~~~~|
 |_____________________________________________________________|

      - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

enum InterfaceType {
  UNDEFINED, // 0
  ERC20, //     1
  ERC721, //    2
  ERC1155, //   3
  PA1D //       4
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

interface ERC165 {
  /// @notice Query if a contract implements an interface
  /// @param interfaceID The interface identifier, as specified in ERC-165
  /// @dev Interface identification is specified in ERC-165. This function
  ///  uses less than 30,000 gas.
  /// @return `true` if the contract implements `interfaceID` and
  ///  `interfaceID` is not 0xffffffff, `false` otherwise
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
/* is ERC165 */
interface ERC721 {
  /// @dev This emits when ownership of any NFT changes by any mechanism.
  ///  This event emits when NFTs are created (`from` == 0) and destroyed
  ///  (`to` == 0). Exception: during contract creation, any number of NFTs
  ///  may be created and assigned without emitting Transfer. At the time of
  ///  any transfer, the approved address for that NFT (if any) is reset to none.
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

  /// @dev This emits when the approved address for an NFT is changed or
  ///  reaffirmed. The zero address indicates there is no approved address.
  ///  When a Transfer event emits, this also indicates that the approved
  ///  address for that NFT (if any) is reset to none.
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

  /// @dev This emits when an operator is enabled or disabled for an owner.
  ///  The operator can manage all NFTs of the owner.
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  /// @notice Count all NFTs assigned to an owner
  /// @dev NFTs assigned to the zero address are considered invalid, and this
  ///  function throws for queries about the zero address.
  /// @param _owner An address for whom to query the balance
  /// @return The number of NFTs owned by `_owner`, possibly zero
  function balanceOf(address _owner) external view returns (uint256);

  /// @notice Find the owner of an NFT
  /// @dev NFTs assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @param _tokenId The identifier for an NFT
  /// @return The address of the owner of the NFT
  function ownerOf(uint256 _tokenId) external view returns (address);

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @dev Throws unless `msg.sender` is the current owner, an authorized
  ///  operator, or the approved address for this NFT. Throws if `_from` is
  ///  not the current owner. Throws if `_to` is the zero address. Throws if
  ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
  ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
  ///  `onERC721Received` on `_to` and throws if the return value is not
  ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
  /// @param _from The current owner of the NFT
  /// @param _to The new owner
  /// @param _tokenId The NFT to transfer
  /// @param data Additional data with no specified format, sent in call to `_to`
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata data
  ) external payable;

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @dev This works identically to the other function with an extra data parameter,
  ///  except this function just sets data to "".
  /// @param _from The current owner of the NFT
  /// @param _to The new owner
  /// @param _tokenId The NFT to transfer
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) external payable;

  /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
  ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
  ///  THEY MAY BE PERMANENTLY LOST
  /// @dev Throws unless `msg.sender` is the current owner, an authorized
  ///  operator, or the approved address for this NFT. Throws if `_from` is
  ///  not the current owner. Throws if `_to` is the zero address. Throws if
  ///  `_tokenId` is not a valid NFT.
  /// @param _from The current owner of the NFT
  /// @param _to The new owner
  /// @param _tokenId The NFT to transfer
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) external payable;

  /// @notice Change or reaffirm the approved address for an NFT
  /// @dev The zero address indicates there is no approved address.
  ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
  ///  operator of the current owner.
  /// @param _approved The new approved NFT controller
  /// @param _tokenId The NFT to approve
  function approve(address _approved, uint256 _tokenId) external payable;

  /// @notice Enable or disable approval for a third party ("operator") to manage
  ///  all of `msg.sender`'s assets
  /// @dev Emits the ApprovalForAll event. The contract MUST allow
  ///  multiple operators per owner.
  /// @param _operator Address to add to the set of authorized operators
  /// @param _approved True if the operator is approved, false to revoke approval
  function setApprovalForAll(address _operator, bool _approved) external;

  /// @notice Get the approved address for a single NFT
  /// @dev Throws if `_tokenId` is not a valid NFT.
  /// @param _tokenId The NFT to find the approved address for
  /// @return The approved address for this NFT, or the zero address if there is none
  function getApproved(uint256 _tokenId) external view returns (address);

  /// @notice Query if an address is an authorized operator for another address
  /// @param _owner The address that owns the NFTs
  /// @param _operator The address that acts on behalf of the owner
  /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
/*

  ,,,,,,,,,,,
 [ HOLOGRAPH ]
  '''''''''''
  _____________________________________________________________
 |                                                             |
 |                            / ^ \                            |
 |                            ~~*~~            .               |
 |                         [ '<>:<>' ]         |=>             |
 |               __           _/"\_           _|               |
 |             .:[]:.          """          .:[]:.             |
 |           .'  []  '.        \_/        .'  []  '.           |
 |         .'|   []   |'.               .'|   []   |'.         |
 |       .'  |   []   |  '.           .'  |   []   |  '.       |
 |     .'|   |   []   |   |'.       .'|   |   []   |   |'.     |
 |   .'  |   |   []   |   |  '.   .'  |   |   []   |   |  '.   |
 |.:'|   |   |   []   |   |   |':'|   |   |   []   |   |   |':.|
 |___|___|___|___[]___|___|___|___|___|___|___[]___|___|___|___|
 |XxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxX|
 |^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^|
 |               []                           []               |
 |               []                           []               |
 |    ,          []     ,        ,'      *    []               |
 |~~~~~^~~~~~~~~/##\~~~^~~~~~~~~^^~~~~~~~~^~~/##\~~~~~~~^~~~~~~|
 |_____________________________________________________________|

      - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

import "./CollectionURI.sol";
import "./ERC165.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Metadata.sol";
import "./ERC721TokenReceiver.sol";

interface ERC721Holograph is ERC165, ERC721, ERC721Enumerable, ERC721Metadata, ERC721TokenReceiver, CollectionURI {
  function approve(address to, uint256 tokenId) external payable;

  function burn(uint256 tokenId) external;

  function holographBridgeIn(
    uint32 chainType,
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);

  function holographBridgeOut(
    uint32 chainType,
    address from,
    address to,
    uint256 tokenId
  ) external returns (bytes4, bytes memory data);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external payable;

  function setApprovalForAll(address to, bool approved) external;

  function sourceBurn(uint256 tokenId) external;

  function sourceMint(address to, uint224 tokenId) external;

  function sourceGetChainPrepend() external view returns (uint256);

  function sourceTransfer(address to, uint256 tokenId) external;

  function transfer(address to, uint256 tokenId) external payable;

  function contractURI() external view returns (string memory);

  function getApproved(uint256 tokenId) external view returns (address);

  function isApprovedForAll(address wallet, address operator) external view returns (bool);

  function name() external view returns (string memory);

  function burned(uint256 tokenId) external view returns (bool);

  function decimals() external pure returns (uint256);

  function exists(uint256 tokenId) external view returns (bool);

  function ownerOf(uint256 tokenId) external view returns (address);

  function supportsInterface(bytes4 interfaceId) external view returns (bool);

  function symbol() external view returns (string memory);

  function tokenByIndex(uint256 index) external view returns (uint256);

  function tokenOfOwnerByIndex(address wallet, uint256 index) external view returns (uint256);

  function tokensOfOwner(address wallet) external view returns (uint256[] memory);

  function tokenURI(uint256 tokenId) external view returns (string memory);

  function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
/* is ERC721 */
interface ERC721Metadata {
  /// @notice A descriptive name for a collection of NFTs in this contract
  function name() external view returns (string memory _name);

  /// @notice An abbreviated name for NFTs in this contract
  function symbol() external view returns (string memory _symbol);

  /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
  /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
  ///  3986. The URI may point to a JSON file that conforms to the "ERC721
  ///  Metadata JSON Schema".
  function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
/*

  ,,,,,,,,,,,
 [ HOLOGRAPH ]
  '''''''''''
  _____________________________________________________________
 |                                                             |
 |                            / ^ \                            |
 |                            ~~*~~            .               |
 |                         [ '<>:<>' ]         |=>             |
 |               __           _/"\_           _|               |
 |             .:[]:.          """          .:[]:.             |
 |           .'  []  '.        \_/        .'  []  '.           |
 |         .'|   []   |'.               .'|   []   |'.         |
 |       .'  |   []   |  '.           .'  |   []   |  '.       |
 |     .'|   |   []   |   |'.       .'|   |   []   |   |'.     |
 |   .'  |   |   []   |   |  '.   .'  |   |   []   |   |  '.   |
 |.:'|   |   |   []   |   |   |':'|   |   |   []   |   |   |':.|
 |___|___|___|___[]___|___|___|___|___|___|___[]___|___|___|___|
 |XxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxX|
 |^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^|
 |               []                           []               |
 |               []                           []               |
 |    ,          []     ,        ,'      *    []               |
 |~~~~~^~~~~~~~~/##\~~~^~~~~~~~~^^~~~~~~~~^~~/##\~~~~~~~^~~~~~~|
 |_____________________________________________________________|

      - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
  /// @notice Handle the receipt of an NFT
  /// @dev The ERC721 smart contract calls this function on the recipient
  ///  after a `transfer`. This function MAY throw to revert and reject the
  ///  transfer. Return of other than the magic value MUST result in the
  ///  transaction being reverted.
  ///  Note: the contract address is always the message sender.
  /// @param _operator The address which called `safeTransferFrom` function
  /// @param _from The address which previously owned the token
  /// @param _tokenId The NFT identifier which is being transferred
  /// @param _data Additional data with no specified format
  /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  ///  unless throwing
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data
  ) external returns (bytes4);
}

// SPDX-License-Identifier: UNLICENSED
/*

  ,,,,,,,,,,,
 [ HOLOGRAPH ]
  '''''''''''
  _____________________________________________________________
 |                                                             |
 |                            / ^ \                            |
 |                            ~~*~~            .               |
 |                         [ '<>:<>' ]         |=>             |
 |               __           _/"\_           _|               |
 |             .:[]:.          """          .:[]:.             |
 |           .'  []  '.        \_/        .'  []  '.           |
 |         .'|   []   |'.               .'|   []   |'.         |
 |       .'  |   []   |  '.           .'  |   []   |  '.       |
 |     .'|   |   []   |   |'.       .'|   |   []   |   |'.     |
 |   .'  |   |   []   |   |  '.   .'  |   |   []   |   |  '.   |
 |.:'|   |   |   []   |   |   |':'|   |   |   []   |   |   |':.|
 |___|___|___|___[]___|___|___|___|___|___|___[]___|___|___|___|
 |XxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxX|
 |^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^|
 |               []                           []               |
 |               []                           []               |
 |    ,          []     ,        ,'      *    []               |
 |~~~~~^~~~~~~~~/##\~~~^~~~~~~~~^^~~~~~~~~^~~/##\~~~~~~~^~~~~~~|
 |_____________________________________________________________|

      - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

/// @title Holograph ERC-721 Non-Fungible Token Standard
/// @dev See https://holograph.network/standard/ERC-721
///  Note: the ERC-165 identifier for this interface is 0xFFFFFFFF.
interface HolographedERC721 {
  // event id = 1
  function bridgeIn(
    uint32 _chainId,
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  ) external returns (bool success);

  // event id = 2
  function bridgeOut(
    uint32 _chainId,
    address _from,
    address _to,
    uint256 _tokenId
  ) external returns (bytes memory _data);

  // event id = 3
  function afterApprove(
    address _owner,
    address _to,
    uint256 _tokenId
  ) external returns (bool success);

  // event id = 4
  function beforeApprove(
    address _owner,
    address _to,
    uint256 _tokenId
  ) external returns (bool success);

  // event id = 5
  function afterApprovalAll(address _to, bool _approved) external returns (bool success);

  // event id = 6
  function beforeApprovalAll(address _to, bool _approved) external returns (bool success);

  // event id = 7
  function afterBurn(address _owner, uint256 _tokenId) external returns (bool success);

  // event id = 8
  function beforeBurn(address _owner, uint256 _tokenId) external returns (bool success);

  // event id = 9
  function afterMint(address _owner, uint256 _tokenId) external returns (bool success);

  // event id = 10
  function beforeMint(address _owner, uint256 _tokenId) external returns (bool success);

  // event id = 11
  function afterSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  ) external returns (bool success);

  // event id = 12
  function beforeSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  ) external returns (bool success);

  // event id = 13
  function afterTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  ) external returns (bool success);

  // event id = 14
  function beforeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  ) external returns (bool success);

  // event id = 15
  function afterOnERC721Received(
    address _operator,
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  ) external returns (bool success);

  // event id = 16
  function beforeOnERC721Received(
    address _operator,
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  ) external returns (bool success);
}

// SPDX-License-Identifier: UNLICENSED
/*

  ,,,,,,,,,,,
 [ HOLOGRAPH ]
  '''''''''''
  _____________________________________________________________
 |                                                             |
 |                            / ^ \                            |
 |                            ~~*~~            .               |
 |                         [ '<>:<>' ]         |=>             |
 |               __           _/"\_           _|               |
 |             .:[]:.          """          .:[]:.             |
 |           .'  []  '.        \_/        .'  []  '.           |
 |         .'|   []   |'.               .'|   []   |'.         |
 |       .'  |   []   |  '.           .'  |   []   |  '.       |
 |     .'|   |   []   |   |'.       .'|   |   []   |   |'.     |
 |   .'  |   |   []   |   |  '.   .'  |   |   []   |   |  '.   |
 |.:'|   |   |   []   |   |   |':'|   |   |   []   |   |   |':.|
 |___|___|___|___[]___|___|___|___|___|___|___[]___|___|___|___|
 |XxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxX|
 |^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^|
 |               []                           []               |
 |               []                           []               |
 |    ,          []     ,        ,'      *    []               |
 |~~~~~^~~~~~~~~/##\~~~^~~~~~~~~^^~~~~~~~~^~~/##\~~~~~~~^~~~~~~|
 |_____________________________________________________________|

      - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

interface IHolograph {
  function getChainType() external view returns (uint32 chainType);

  function getBridge() external view returns (address bridgeAddress);

  function getFactory() external view returns (address factoryAddress);

  function getInterfaces() external view returns (address interfacesAddress);

  function getOperator() external view returns (address operatorAddress);

  function getRegistry() external view returns (address registryAddress);
}

// SPDX-License-Identifier: UNLICENSED
/*

  ,,,,,,,,,,,
 [ HOLOGRAPH ]
  '''''''''''
  _____________________________________________________________
 |                                                             |
 |                            / ^ \                            |
 |                            ~~*~~            .               |
 |                         [ '<>:<>' ]         |=>             |
 |               __           _/"\_           _|               |
 |             .:[]:.          """          .:[]:.             |
 |           .'  []  '.        \_/        .'  []  '.           |
 |         .'|   []   |'.               .'|   []   |'.         |
 |       .'  |   []   |  '.           .'  |   []   |  '.       |
 |     .'|   |   []   |   |'.       .'|   |   []   |   |'.     |
 |   .'  |   |   []   |   |  '.   .'  |   |   []   |   |  '.   |
 |.:'|   |   |   []   |   |   |':'|   |   |   []   |   |   |':.|
 |___|___|___|___[]___|___|___|___|___|___|___[]___|___|___|___|
 |XxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxX|
 |^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^|
 |               []                           []               |
 |               []                           []               |
 |    ,          []     ,        ,'      *    []               |
 |~~~~~^~~~~~~~~/##\~~~^~~~~~~~~^^~~~~~~~~^~~/##\~~~~~~~^~~~~~~|
 |_____________________________________________________________|

      - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

interface IHolographer {
  function getOriginChain() external view returns (uint32);

  function getHolograph() external view returns (address);

  function getHolographEnforcer() external view returns (address payable);

  function getSecureStorage() external pure returns (address);

  function getSourceContract() external pure returns (address payable);
}

// SPDX-License-Identifier: UNLICENSED
/*

  ,,,,,,,,,,,
 [ HOLOGRAPH ]
  '''''''''''
  _____________________________________________________________
 |                                                             |
 |                            / ^ \                            |
 |                            ~~*~~            .               |
 |                         [ '<>:<>' ]         |=>             |
 |               __           _/"\_           _|               |
 |             .:[]:.          """          .:[]:.             |
 |           .'  []  '.        \_/        .'  []  '.           |
 |         .'|   []   |'.               .'|   []   |'.         |
 |       .'  |   []   |  '.           .'  |   []   |  '.       |
 |     .'|   |   []   |   |'.       .'|   |   []   |   |'.     |
 |   .'  |   |   []   |   |  '.   .'  |   |   []   |   |  '.   |
 |.:'|   |   |   []   |   |   |':'|   |   |   []   |   |   |':.|
 |___|___|___|___[]___|___|___|___|___|___|___[]___|___|___|___|
 |XxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxX|
 |^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^|
 |               []                           []               |
 |               []                           []               |
 |    ,          []     ,        ,'      *    []               |
 |~~~~~^~~~~~~~~/##\~~~^~~~~~~~~^^~~~~~~~~^~~/##\~~~~~~~^~~~~~~|
 |_____________________________________________________________|

      - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

interface IHolographRegistry {
  function referenceContractTypeAddress(address contractAddress) external returns (bytes32);

  function setContractTypeAddress(bytes32 contractType, address contractAddress) external;

  function setHToken(uint32 chainId, address hToken) external;

  function updateReservedContractTypes(bytes32[] calldata hashes, bool[] calldata reserved) external;

  function getContractTypeAddress(bytes32 contractType) external view returns (address);

  function factoryDeployedHash(bytes32 hash, address contractAddress) external;

  function getHolographedHashAddress(bytes32 hash) external view returns (address);

  function getHToken(uint32 chainId) external view returns (address hToken);

  function isHolographedContract(address smartContract) external view returns (bool);

  function isHolographedHashDeployed(bytes32 hash) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
/*

  ,,,,,,,,,,,
 [ HOLOGRAPH ]
  '''''''''''
  _____________________________________________________________
 |                                                             |
 |                            / ^ \                            |
 |                            ~~*~~            .               |
 |                         [ '<>:<>' ]         |=>             |
 |               __           _/"\_           _|               |
 |             .:[]:.          """          .:[]:.             |
 |           .'  []  '.        \_/        .'  []  '.           |
 |         .'|   []   |'.               .'|   []   |'.         |
 |       .'  |   []   |  '.           .'  |   []   |  '.       |
 |     .'|   |   []   |   |'.       .'|   |   []   |   |'.     |
 |   .'  |   |   []   |   |  '.   .'  |   |   []   |   |  '.   |
 |.:'|   |   |   []   |   |   |':'|   |   |   []   |   |   |':.|
 |___|___|___|___[]___|___|___|___|___|___|___[]___|___|___|___|
 |XxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxX|
 |^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^|
 |               []                           []               |
 |               []                           []               |
 |    ,          []     ,        ,'      *    []               |
 |~~~~~^~~~~~~~~/##\~~~^~~~~~~~~^^~~~~~~~~^~~/##\~~~~~~~^~~~~~~|
 |_____________________________________________________________|

      - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

interface IInitializable {
  function init(bytes memory _data) external returns (bytes4);
}

// SPDX-License-Identifier: UNLICENSED
/*

  ,,,,,,,,,,,
 [ HOLOGRAPH ]
  '''''''''''
  _____________________________________________________________
 |                                                             |
 |                            / ^ \                            |
 |                            ~~*~~            .               |
 |                         [ '<>:<>' ]         |=>             |
 |               __           _/"\_           _|               |
 |             .:[]:.          """          .:[]:.             |
 |           .'  []  '.        \_/        .'  []  '.           |
 |         .'|   []   |'.               .'|   []   |'.         |
 |       .'  |   []   |  '.           .'  |   []   |  '.       |
 |     .'|   |   []   |   |'.       .'|   |   []   |   |'.     |
 |   .'  |   |   []   |   |  '.   .'  |   |   []   |   |  '.   |
 |.:'|   |   |   []   |   |   |':'|   |   |   []   |   |   |':.|
 |___|___|___|___[]___|___|___|___|___|___|___[]___|___|___|___|
 |XxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxX|
 |^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^|
 |               []                           []               |
 |               []                           []               |
 |    ,          []     ,        ,'      *    []               |
 |~~~~~^~~~~~~~~/##\~~~^~~~~~~~~^^~~~~~~~~^~~/##\~~~~~~~^~~~~~~|
 |_____________________________________________________________|

      - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

import "../enum/ChainIdType.sol";
import "../enum/InterfaceType.sol";
import "../enum/TokenUriType.sol";

interface IInterfaces {
  function contractURI(
    string calldata name,
    string calldata imageURL,
    string calldata externalLink,
    uint16 bps,
    address contractAddress
  ) external pure returns (string memory);

  function supportsInterface(InterfaceType interfaceType, bytes4 interfaceId) external view returns (bool);

  function updateInterface(
    InterfaceType interfaceType,
    bytes4 interfaceId,
    bool supported
  ) external;

  function getChainId(
    ChainIdType fromChainType,
    uint256 fromChainId,
    ChainIdType toChainType
  ) external view returns (uint256 toChainId);

  function getUriPrepend(TokenUriType uriType) external view returns (string memory prepend);

  function updateChainIdMap(
    ChainIdType fromChainType,
    uint256 fromChainId,
    ChainIdType toChainType,
    uint256 toChainId
  ) external;

  function updateChainIdMaps(
    ChainIdType[] calldata fromChainType,
    uint256[] calldata fromChainId,
    ChainIdType[] calldata toChainType,
    uint256[] calldata toChainId
  ) external;
}

// SPDX-License-Identifier: UNLICENSED
/*

  ,,,,,,,,,,,
 [ HOLOGRAPH ]
  '''''''''''
  _____________________________________________________________
 |                                                             |
 |                            / ^ \                            |
 |                            ~~*~~            .               |
 |                         [ '<>:<>' ]         |=>             |
 |               __           _/"\_           _|               |
 |             .:[]:.          """          .:[]:.             |
 |           .'  []  '.        \_/        .'  []  '.           |
 |         .'|   []   |'.               .'|   []   |'.         |
 |       .'  |   []   |  '.           .'  |   []   |  '.       |
 |     .'|   |   []   |   |'.       .'|   |   []   |   |'.     |
 |   .'  |   |   []   |   |  '.   .'  |   |   []   |   |  '.   |
 |.:'|   |   |   []   |   |   |':'|   |   |   []   |   |   |':.|
 |___|___|___|___[]___|___|___|___|___|___|___[]___|___|___|___|
 |XxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxX|
 |^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^|
 |               []                           []               |
 |               []                           []               |
 |    ,          []     ,        ,'      *    []               |
 |~~~~~^~~~~~~~~/##\~~~^~~~~~~~~^^~~~~~~~~^~~/##\~~~~~~~^~~~~~~|
 |_____________________________________________________________|

      - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

import "../library/Zora.sol";

interface IPA1D {
  function initPA1D(bytes memory data) external returns (bytes4);

  function configurePayouts(address payable[] memory addresses, uint256[] memory bps) external;

  function getPayoutInfo() external view returns (address payable[] memory addresses, uint256[] memory bps);

  function getEthPayout() external;

  function getTokenPayout(address tokenAddress) external;

  function getTokensPayout(address[] memory tokenAddresses) external;

  function supportsInterface(bytes4 interfaceId) external pure returns (bool);

  function setRoyalties(
    uint256 tokenId,
    address payable receiver,
    uint256 bp
  ) external;

  function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);

  function getFeeBps(uint256 tokenId) external view returns (uint256[] memory);

  function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory);

  function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);

  function getFees(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);

  function tokenCreator(
    address, /* contractAddress*/
    uint256 tokenId
  ) external view returns (address);

  function calculateRoyaltyFee(
    address, /* contractAddress */
    uint256 tokenId,
    uint256 amount
  ) external view returns (uint256);

  function marketContract() external view returns (address);

  function tokenCreators(uint256 tokenId) external view returns (address);

  function bidSharesForToken(uint256 tokenId) external view returns (Zora.BidShares memory bidShares);

  function getStorageSlot(string calldata slot) external pure returns (bytes32);

  function getTokenAddress(string memory tokenName) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
/*

  ,,,,,,,,,,,
 [ HOLOGRAPH ]
  '''''''''''
  _____________________________________________________________
 |                                                             |
 |                            / ^ \                            |
 |                            ~~*~~            .               |
 |                         [ '<>:<>' ]         |=>             |
 |               __           _/"\_           _|               |
 |             .:[]:.          """          .:[]:.             |
 |           .'  []  '.        \_/        .'  []  '.           |
 |         .'|   []   |'.               .'|   []   |'.         |
 |       .'  |   []   |  '.           .'  |   []   |  '.       |
 |     .'|   |   []   |   |'.       .'|   |   []   |   |'.     |
 |   .'  |   |   []   |   |  '.   .'  |   |   []   |   |  '.   |
 |.:'|   |   |   []   |   |   |':'|   |   |   []   |   |   |':.|
 |___|___|___|___[]___|___|___|___|___|___|___[]___|___|___|___|
 |XxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxX|
 |^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^|
 |               []                           []               |
 |               []                           []               |
 |    ,          []     ,        ,'      *    []               |
 |~~~~~^~~~~~~~~/##\~~~^~~~~~~~~^^~~~~~~~~^~~/##\~~~~~~~^~~~~~~|
 |_____________________________________________________________|

      - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

interface Ownable {
  function owner() external view returns (address);

  function isOwner() external view returns (bool);

  function isOwner(address wallet) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
/*

  ,,,,,,,,,,,
 [ HOLOGRAPH ]
  '''''''''''
  _____________________________________________________________
 |                                                             |
 |                            / ^ \                            |
 |                            ~~*~~            .               |
 |                         [ '<>:<>' ]         |=>             |
 |               __           _/"\_           _|               |
 |             .:[]:.          """          .:[]:.             |
 |           .'  []  '.        \_/        .'  []  '.           |
 |         .'|   []   |'.               .'|   []   |'.         |
 |       .'  |   []   |  '.           .'  |   []   |  '.       |
 |     .'|   |   []   |   |'.       .'|   |   []   |   |'.     |
 |   .'  |   |   []   |   |  '.   .'  |   |   []   |   |  '.   |
 |.:'|   |   |   []   |   |   |':'|   |   |   []   |   |   |':.|
 |___|___|___|___[]___|___|___|___|___|___|___[]___|___|___|___|
 |XxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxX|
 |^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^|
 |               []                           []               |
 |               []                           []               |
 |    ,          []     ,        ,'      *    []               |
 |~~~~~^~~~~~~~~/##\~~~^~~~~~~~~^^~~~~~~~~^~~/##\~~~~~~~^~~~~~~|
 |_____________________________________________________________|

      - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

interface CollectionURI {
  function contractURI() external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
/* is ERC721 */
interface ERC721Enumerable {
  /// @notice Count NFTs tracked by this contract
  /// @return A count of valid NFTs tracked by this contract, where each one of
  ///  them has an assigned and queryable owner not equal to the zero address
  function totalSupply() external view returns (uint256);

  /// @notice Enumerate valid NFTs
  /// @dev Throws if `_index` >= `totalSupply()`.
  /// @param _index A counter less than `totalSupply()`
  /// @return The token identifier for the `_index`th NFT,
  ///  (sort order not specified)
  function tokenByIndex(uint256 _index) external view returns (uint256);

  /// @notice Enumerate NFTs assigned to an owner
  /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
  ///  `_owner` is the zero address, representing invalid NFTs.
  /// @param _owner An address where we are interested in NFTs owned by them
  /// @param _index A counter less than `balanceOf(_owner)`
  /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
  ///   (sort order not specified)
  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
/*

  ,,,,,,,,,,,
 [ HOLOGRAPH ]
  '''''''''''
  _____________________________________________________________
 |                                                             |
 |                            / ^ \                            |
 |                            ~~*~~            .               |
 |                         [ '<>:<>' ]         |=>             |
 |               __           _/"\_           _|               |
 |             .:[]:.          """          .:[]:.             |
 |           .'  []  '.        \_/        .'  []  '.           |
 |         .'|   []   |'.               .'|   []   |'.         |
 |       .'  |   []   |  '.           .'  |   []   |  '.       |
 |     .'|   |   []   |   |'.       .'|   |   []   |   |'.     |
 |   .'  |   |   []   |   |  '.   .'  |   |   []   |   |  '.   |
 |.:'|   |   |   []   |   |   |':'|   |   |   []   |   |   |':.|
 |___|___|___|___[]___|___|___|___|___|___|___[]___|___|___|___|
 |XxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxX|
 |^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^|
 |               []                           []               |
 |               []                           []               |
 |    ,          []     ,        ,'      *    []               |
 |~~~~~^~~~~~~~~/##\~~~^~~~~~~~~^^~~~~~~~~^~~/##\~~~~~~~^~~~~~~|
 |_____________________________________________________________|

      - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

enum ChainIdType {
  UNDEFINED, //  0
  EVM, //        1
  HOLOGRAPH, //  2
  LAYERZERO, //  3
  SYNAPSE, //    4
  CONNECTX, //   5
  ABACUS //      6
}

// SPDX-License-Identifier: UNLICENSED
/*

  ,,,,,,,,,,,
 [ HOLOGRAPH ]
  '''''''''''
  _____________________________________________________________
 |                                                             |
 |                            / ^ \                            |
 |                            ~~*~~            .               |
 |                         [ '<>:<>' ]         |=>             |
 |               __           _/"\_           _|               |
 |             .:[]:.          """          .:[]:.             |
 |           .'  []  '.        \_/        .'  []  '.           |
 |         .'|   []   |'.               .'|   []   |'.         |
 |       .'  |   []   |  '.           .'  |   []   |  '.       |
 |     .'|   |   []   |   |'.       .'|   |   []   |   |'.     |
 |   .'  |   |   []   |   |  '.   .'  |   |   []   |   |  '.   |
 |.:'|   |   |   []   |   |   |':'|   |   |   []   |   |   |':.|
 |___|___|___|___[]___|___|___|___|___|___|___[]___|___|___|___|
 |XxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxX|
 |^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^|
 |               []                           []               |
 |               []                           []               |
 |    ,          []     ,        ,'      *    []               |
 |~~~~~^~~~~~~~~/##\~~~^~~~~~~~~^^~~~~~~~~^~~/##\~~~~~~~^~~~~~~|
 |_____________________________________________________________|

      - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

enum TokenUriType {
  UNDEFINED, //   0
  IPFS, //        1
  HTTPS, //       2
  ARWEAVE //      3
}

// SPDX-License-Identifier: UNLICENSED
/*

  ,,,,,,,,,,,
 [ HOLOGRAPH ]
  '''''''''''
  _____________________________________________________________
 |                                                             |
 |                            / ^ \                            |
 |                            ~~*~~            .               |
 |                         [ '<>:<>' ]         |=>             |
 |               __           _/"\_           _|               |
 |             .:[]:.          """          .:[]:.             |
 |           .'  []  '.        \_/        .'  []  '.           |
 |         .'|   []   |'.               .'|   []   |'.         |
 |       .'  |   []   |  '.           .'  |   []   |  '.       |
 |     .'|   |   []   |   |'.       .'|   |   []   |   |'.     |
 |   .'  |   |   []   |   |  '.   .'  |   |   []   |   |  '.   |
 |.:'|   |   |   []   |   |   |':'|   |   |   []   |   |   |':.|
 |___|___|___|___[]___|___|___|___|___|___|___[]___|___|___|___|
 |XxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxX|
 |^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^|
 |               []                           []               |
 |               []                           []               |
 |    ,          []     ,        ,'      *    []               |
 |~~~~~^~~~~~~~~/##\~~~^~~~~~~~~^^~~~~~~~~^~~/##\~~~~~~~^~~~~~~|
 |_____________________________________________________________|

      - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

library Zora {
  struct Decimal {
    uint256 value;
  }

  struct BidShares {
    // % of sale value that goes to the _previous_ owner of the nft
    Decimal prevOwner;
    // % of sale value that goes to the original creator of the nft
    Decimal creator;
    // % of sale value that goes to the seller (current owner) of the nft
    Decimal owner;
  }
}