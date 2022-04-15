// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


import "./IERC165.sol";


contract ERC165 is IERC165 {
  /// @dev You must not set element 0xffffffff to true
  mapping (bytes4 => bool) internal supportedInterfaces;

  constructor() {
    supportedInterfaces[0x01ffc9a7] = true; // ERC-165
  }

  function supportsInterface(bytes4 interfaceID) override external view returns (bool) {
    return supportedInterfaces[interfaceID];
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


/// @title ERC-165 Standard Interface Detection
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
interface IERC165 {
  /// @notice Query if a contract implements an interface
  /// @param interfaceID The interface identifier, as specified in ERC-165
  /// @dev Interface identification is specified in ERC-165. This function
  ///  uses less than 30,000 gas.
  /// @return `true` if the contract implements `interfaceID` and
  ///  `interfaceID` is not 0xffffffff, `false` otherwise
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


import "./SafeMath.sol";
import "./erc165/ERC165.sol";
import "./erc721/IERC721Base.sol";
import "./erc721/IERC721Enumerable.sol";
import "./erc721/IERC721TokenReceiver.sol";
import "./HeroDependency.sol";
import "./HeroPausable.sol";


contract HeroERC721BaseEnumerable is ERC165, IERC721Base, IERC721Enumerable, HeroDependency, HeroPausable {
  using SafeMath for uint256;
  // @dev Total amount of tokens. 
  uint256 private _totalTokens;

  // @dev Mapping from token index to ID.
  mapping (uint256 => uint256) private _overallTokenId;  

  // @dev Mapping from token ID to index.
  mapping (uint256 => uint256) private _overallTokenIndex;

  // @dev Mapping from token ID to owner.
  mapping (uint256 => address) private _tokenOwner; 

  // @dev For a given owner and a given operator, store whether
  //  the operator is allowed to manage tokens on behalf of the owner.
  mapping (address => mapping (address => bool)) private _tokenOperator; 

  // @dev Mapping from token ID to approved address.
  mapping (uint256 => address) private _tokenApproval; 

  // @dev Mapping from owner to list of owned token IDs.
  mapping (address => uint256[]) private _ownedTokens; 

  // @dev Mapping from token ID to index in the owned token list.
  mapping (uint256 => uint256) private _ownedTokenIndex; 


  constructor() {
    supportedInterfaces[0x80ac58cd] = true; // ERC-721 Base
    supportedInterfaces[0x780e9d63] = true; // ERC-721 Enumerable
  }

  // solium-disable function-order

  modifier mustBeValidToken(uint256 _tokenId) {
    require(_tokenOwner[_tokenId] != address(0));
    _;
  }

  function _isTokenOwner(address _ownerToCheck, uint256 _tokenId) private view returns (bool) {
    return _tokenOwner[_tokenId] == _ownerToCheck;
  }

  function _isTokenOperator(address _operatorToCheck, uint256 _tokenId) private view returns (bool) {
    return whitelistedMarketplace[_operatorToCheck] ||
      _tokenOperator[_tokenOwner[_tokenId]][_operatorToCheck];
  }

  function _isApproved(address _approvedToCheck, uint256 _tokenId) private view returns (bool) {
    return _tokenApproval[_tokenId] == _approvedToCheck;
  }

  modifier onlyTokenOwner(uint256 _tokenId) {
    require(_isTokenOwner(msg.sender, _tokenId));
    _;
  }

  modifier onlyTokenOwnerOrOperator(uint256 _tokenId) {
    require(_isTokenOwner(msg.sender, _tokenId) || _isTokenOperator(msg.sender, _tokenId));
    _;
  }

  modifier onlyTokenAuthorized(uint256 _tokenId) {
    require(
      // solium-disable operator-whitespace
      _isTokenOwner(msg.sender, _tokenId) ||
        _isTokenOperator(msg.sender, _tokenId) ||
        _isApproved(msg.sender, _tokenId)
      // solium-enable operator-whitespace
    );
    _;
  }

  // ERC-721 Base

  function balanceOf(address _owner) override external view returns (uint256) {
    require(_owner != address(0));
    return _ownedTokens[_owner].length;
  }

  function ownerOf(uint256 _tokenId) override external view mustBeValidToken(_tokenId) returns (address) {
    return _tokenOwner[_tokenId];
  }

  function _addTokenTo(address _to, uint256 _tokenId) private {
    require(_to != address(0));

    _tokenOwner[_tokenId] = _to;

    uint256 length = _ownedTokens[_to].length;
    _ownedTokens[_to].push(_tokenId);
    _ownedTokenIndex[_tokenId] = length;
  }

  function _mint(address _to, uint256 _tokenId) internal {
    require(_tokenOwner[_tokenId] == address(0));

    _addTokenTo(_to, _tokenId);

    _overallTokenId[_totalTokens] = _tokenId;
    _overallTokenIndex[_tokenId] = _totalTokens;
    _totalTokens = _totalTokens.add(1);

    emit Transfer(address(0), _to, _tokenId);
  }

  function _removeTokenFrom(address _from, uint256 _tokenId) private {
    require(_from != address(0));

    uint256 _tokenIndex = _ownedTokenIndex[_tokenId];
    uint256 _lastTokenIndex = _ownedTokens[_from].length.sub(1);
    uint256 _lastTokenId = _ownedTokens[_from][_lastTokenIndex];

    _tokenOwner[_tokenId] = address(0);

    // Insert the last token into the position previously occupied by the removed token.
    _ownedTokens[_from][_tokenIndex] = _lastTokenId;
    _ownedTokenIndex[_lastTokenId] = _tokenIndex;

    // Resize the array.
    _ownedTokens[_from].pop();
 
    // Remove the array if no more tokens are owned to prevent pollution.
    if (_ownedTokens[_from].length == 0) {
      delete _ownedTokens[_from];
    }

    // Update the index of the removed token.
    delete _ownedTokenIndex[_tokenId];
  }

  function _burn(uint256 _tokenId) internal {
    address _from = _tokenOwner[_tokenId];

    require(_from != address(0));

    _removeTokenFrom(_from, _tokenId);
    _totalTokens = _totalTokens.sub(1);

    uint256 _tokenIndex = _overallTokenIndex[_tokenId];
    uint256 _lastTokenId = _overallTokenId[_totalTokens];

    delete _overallTokenIndex[_tokenId];
    delete _overallTokenId[_totalTokens];
    _overallTokenId[_tokenIndex] = _lastTokenId;
    _overallTokenIndex[_lastTokenId] = _tokenIndex;

   emit Transfer(_from, address(0), _tokenId);
  }

  function _isContract(address _address) private view returns (bool) {
    uint _size;
    // solium-disable-next-line security/no-inline-assembly
    assembly { _size := extcodesize(_address) }
    return _size > 0;
  }

  function _transferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data,
    bool _check
  )
    internal
    mustBeValidToken(_tokenId)
    onlyTokenAuthorized(_tokenId)
    whenTransferAllowed(_from, _to, _tokenId)
  {
    require(_isTokenOwner(_from, _tokenId));
    require(_to != address(0));
    require(_to != _from);

    _removeTokenFrom(_from, _tokenId);

    delete _tokenApproval[_tokenId];
    emit Approval(_from, address(0), _tokenId);

    _addTokenTo(_to, _tokenId);

    if (_check && _isContract(_to)) {
      IERC721TokenReceiver(_to).onERC721Received(_from, _tokenId, _data);
    }

   emit Transfer(_from, _to, _tokenId);
  }

  // solium-disable arg-overflow
  function safeTransferFromNopay(address _from, address _to, uint256 _tokenId) external  {
    _transferFrom(_from, _to, _tokenId, "", true);
  }
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) override external payable {
    _transferFrom(_from, _to, _tokenId, _data, true);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) override external payable {
    _transferFrom(_from, _to, _tokenId, "", true);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) override external payable {
    _transferFrom(_from, _to, _tokenId, "", false);
  }

  // solium-enable arg-overflow

  function approve(address _approved,uint256 _tokenId) 
  override external payable 
  mustBeValidToken(_tokenId) onlyTokenOwnerOrOperator(_tokenId)whenNotPaused
  {
    address _owner = _tokenOwner[_tokenId];

    require(_owner != _approved);
    require(_tokenApproval[_tokenId] != _approved);

    _tokenApproval[_tokenId] = _approved;

    emit Approval(_owner, _approved, _tokenId);
  }

  function setApprovalForAll(address _operator, bool _approved) override external whenNotPaused {
    require(_tokenOperator[msg.sender][_operator] != _approved);
    _tokenOperator[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function getApproved(uint256 _tokenId) override external view mustBeValidToken(_tokenId) returns (address) {
    return _tokenApproval[_tokenId];
  }

  function isApprovedForAll(address _owner, address _operator) override external view returns (bool) {
    return _tokenOperator[_owner][_operator];
  }

  // ERC-721 Enumerable

  function totalSupply() override external view returns (uint256) {
    return _totalTokens;
  }

  function tokenByIndex(uint256 _index) override external view returns (uint256) {
    require(_index < _totalTokens);
    return _overallTokenId[_index];
  }

  function tokenOfOwnerByIndex(address _owner, uint256 _index) override external view returns (uint256 _tokenId) {
    require(_owner != address(0));
    require(_index < _ownedTokens[_owner].length);
    return _ownedTokens[_owner][_index];
  }

  function tokenOf(address _owner) external view returns (uint256[] memory) {
    require(_owner != address(0));
    return _ownedTokens[_owner];
  }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x6466353c
interface IERC721Base /* is IERC165  */ {
  /// @dev This emits when ownership of any NFT changes by any mechanism.
  ///  This event emits when NFTs are created (`from` == 0) and destroyed
  ///  (`to` == 0). Exception: during contract creation, any number of NFTs
  ///  may be created and assigned without emitting Transfer. At the time of
  ///  any transfer, the approved address for that NFT (if any) is reset to none.
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

  /// @dev This emits when the approved address for an NFT is changed or
  ///  reaffirmed. The zero address indicates there is no approved address.
  ///  When a Transfer event emits, this also indicates that the approved
  ///  address for that NFT (if any) is reset to none.
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

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
  /// @param _tokenId The identifier for an NFT
  /// @dev NFTs assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @return The address of the owner of the NFT
  function ownerOf(uint256 _tokenId) external view returns (address);

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @dev Throws unless `msg.sender` is the current owner, an authorized
  ///  operator, or the approved address for this NFT. Throws if `_from` is
  ///  not the current owner. Throws if `_to` is the zero address. Throws if
  ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
  ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
  ///  `onERC721Received` on `_to` and throws if the return value is not
  ///  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
  /// @param _from The current owner of the NFT
  /// @param _to The new owner
  /// @param _tokenId The NFT to transfer
  /// @param _data Additional data with no specified format, sent in call to `_to`
  // solium-disable-next-line arg-overflow
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external payable;

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @dev This works identically to the other function with an extra data parameter,
  ///  except this function just sets data to []
  /// @param _from The current owner of the NFT
  /// @param _to The new owner
  /// @param _tokenId The NFT to transfer
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

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
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

  /// @notice Set or reaffirm the approved address for an NFT
  /// @dev The zero address indicates there is no approved address.
  /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
  ///  operator of the current owner.
  /// @param _approved The new approved NFT controller
  /// @param _tokenId The NFT to approve
  function approve(address _approved, uint256 _tokenId) external payable;

  /// @notice Enable or disable approval for a third party ("operator") to manage
  ///  all your asset.
  /// @dev Emits the ApprovalForAll event
  /// @param _operator Address to add to the set of authorized operators.
  /// @param _approved True if the operators is approved, false to revoke approval
  function setApprovalForAll(address _operator, bool _approved) external;

  /// @notice Get the approved address for a single NFT
  /// @dev Throws if `_tokenId` is not a valid NFT
  /// @param _tokenId The NFT to find the approved address for
  /// @return The approved address for this NFT, or the zero address if there is none
  function getApproved(uint256 _tokenId) external view returns (address);

  /// @notice Query if an address is an authorized operator for another address
  /// @param _owner The address that owns the NFTs
  /// @param _operator The address that acts on behalf of the owner
  /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x780e9d63
interface IERC721Enumerable /* is IERC721Base */ {
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


/// @dev Note: the ERC-165 identifier for this interface is 0xf0b9e5ba
interface IERC721TokenReceiver {
  /// @notice Handle the receipt of an NFT
  /// @dev The ERC721 smart contract calls this function on the recipient
  ///  after a `transfer`. This function MAY throw to revert and reject the
  ///  transfer. This function MUST use 50,000 gas or less. Return of other
  ///  than the magic value MUST result in the transaction being reverted.
  ///  Note: the contract address is always the message sender.
  /// @param _from The sending address
  /// @param _tokenId The NFT identifier which is being transfered
  /// @param _data Additional data with no specified format
  /// @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
  ///  unless throwing
	function onERC721Received(address _from, uint256 _tokenId, bytes memory _data) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


import "./HeroManager.sol";


contract HeroDependency {

  address public whitelistSetterAddress;

  HeroSpawningManager public spawningManager;
  HeroRetirementManager public retirementManager;
  HeroMarketplaceManager public marketplaceManager;
  HeroQualityManager public qualityManager;

  mapping (address => bool) public whitelistedSpawner;
  mapping (address => bool) public whitelistedByeSayer;
  mapping (address => bool) public whitelistedMarketplace;
  mapping (address => bool) public whitelistedQualityScientist;

  constructor() {
    whitelistSetterAddress = msg.sender;
  }

  modifier onlyWhitelistSetter() {
    require(msg.sender == whitelistSetterAddress);
    _;
  }

  modifier whenSpawningAllowed(uint256 _quality, address _owner) {
    require(
        address(spawningManager) == address(0) ||
        spawningManager.isSpawningAllowed(_quality, _owner)
    );
    _;
  }

  modifier whenRebirthAllowed(uint256 _heroId, uint256 _quality) {
    require(
      address(spawningManager) == address(0) ||
        spawningManager.isRebirthAllowed(_heroId, _quality)
    );
    _;
  }

  modifier whenRetirementAllowed(uint256 _heroId, bool _rip) {
    require(
      address(retirementManager) == address(0) ||
        retirementManager.isRetirementAllowed(_heroId, _rip)
    );
    _;
  }

  modifier whenTransferAllowed(address _from, address _to, uint256 _heroId) {
    require(
      address(marketplaceManager) == address(0) ||
        marketplaceManager.isTransferAllowed(_from, _to, _heroId)
    );
    _;
  }

  modifier whenEvolvementAllowed(uint256 _heroId, uint256 _newQuality) {
    require(
      address(qualityManager) == address(0) ||
        qualityManager.isEvolvementAllowed(_heroId, _newQuality)
    );
    _;
  }

  modifier onlySpawner() {
    require(whitelistedSpawner[msg.sender]);
    _;
  }

  modifier onlyByeSayer() {
    require(whitelistedByeSayer[msg.sender]);
    _;
  }

  modifier onlyMarketplace() {
    require(whitelistedMarketplace[msg.sender]);
    _;
  }

  modifier onlyQualityScientist() {
    require(whitelistedQualityScientist[msg.sender]);
    _;
  }

  /*
   * @dev Setting the whitelist setter address to `address(0)` would be a irreversible process.
   *  This is to lock changes to Hero's contracts after their development is done.
   */
  function setWhitelistSetter(address _newSetter) external onlyWhitelistSetter {
    whitelistSetterAddress = _newSetter;
  }

  function setSpawningManager(address _manager) external onlyWhitelistSetter {
    spawningManager = HeroSpawningManager(_manager);
  }

  function setRetirementManager(address _manager) external onlyWhitelistSetter {
    retirementManager = HeroRetirementManager(_manager);
  }

  function setMarketplaceManager(address _manager) external onlyWhitelistSetter {
    marketplaceManager = HeroMarketplaceManager(_manager);
  }

  function setQualityManager(address _manager) external onlyWhitelistSetter {
    qualityManager = HeroQualityManager(_manager);
  }

  function setSpawner(address _spawner, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedSpawner[_spawner] != _whitelisted);
    whitelistedSpawner[_spawner] = _whitelisted;
  }

  function setByeSayer(address _byeSayer, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedByeSayer[_byeSayer] != _whitelisted);
    whitelistedByeSayer[_byeSayer] = _whitelisted;
  }

  function setMarketplace(address _marketplace, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedMarketplace[_marketplace] != _whitelisted);
    whitelistedMarketplace[_marketplace] = _whitelisted;
  }

  function setQualityScientist(address _qualityScientist, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedQualityScientist[_qualityScientist] != _whitelisted);
    whitelistedQualityScientist[_qualityScientist] = _whitelisted;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


import "./HeroAccessControl.sol";


contract HeroPausable is HeroAccessControl {

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused {
    require(paused);
    _;
  }

  function pause() external onlyCLevel whenNotPaused {
    paused = true;
  }

  function unpause() virtual public onlyCEO whenPaused {
    paused = false;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


interface HeroSpawningManager {
	function isSpawningAllowed(uint256 _quality, address _owner) external returns (bool);
  function isRebirthAllowed(uint256 _heroId, uint256 _quality) external returns (bool);
}

interface HeroRetirementManager {
  function isRetirementAllowed(uint256 _heroId, bool _rip) external returns (bool);
}

interface HeroMarketplaceManager {
  function isTransferAllowed(address _from, address _to, uint256 _heroId) external returns (bool);
}

interface HeroQualityManager {
  function isEvolvementAllowed(uint256 _heroId, uint256 _newQuality) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract HeroAccessControl {

  address public ceoAddress;
  address payable public cfoAddress;
  address public cooAddress;

  constructor(){
    ceoAddress = msg.sender;
  }

  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  modifier onlyCFO() {
    require(msg.sender == cfoAddress);
    _;
  }

  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }

  modifier onlyCLevel() {
    require(
      // solium-disable operator-whitespace
      msg.sender == ceoAddress ||
        msg.sender == cfoAddress ||
        msg.sender == cooAddress
      // solium-enable operator-whitespace
    );
    _;
  }

  function setCEO(address _newCEO) external onlyCEO {
    require(_newCEO != address(0));
    ceoAddress = _newCEO;
  }

  function setCFO(address payable _newCFO) external onlyCEO {
    cfoAddress = _newCFO;
  }

  function setCOO(address _newCOO) external onlyCEO {
    cooAddress = _newCOO;
  }

  function withdrawBalance() external onlyCFO {
    cfoAddress.transfer(address(this).balance);
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


import "./erc721/IERC721Metadata.sol";
import "./HeroERC721BaseEnumerable.sol";


contract HeroERC721Metadata is HeroERC721BaseEnumerable, IERC721Metadata {
 
  mapping (uint256 => string) private tokenURIs;
  constructor() {
    supportedInterfaces[0x5b5e139f] = true; // ERC-721 Metadata
  }

  function name() override external pure returns (string memory) {
    return "NTF_HERO";
  }

  function symbol() override external pure returns (string memory) {
    return "HERO";
  }

  function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal mustBeValidToken(_tokenId) {
        tokenURIs[_tokenId] = _tokenURI;
  }


  function tokenURI(uint256 _tokenId) override external view mustBeValidToken(_tokenId) returns (string memory)
  {
    return  tokenURIs[_tokenId];
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f
interface IERC721Metadata /* is IERC721Base */ {
  /// @notice A descriptive name for a collection of NFTs in this contract
  function name() external pure returns (string memory _name);

  /// @notice An abbreviated name for NFTs in this contract
  function symbol() external pure returns (string memory _symbol);

  /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
  /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
  ///  3986. The URI may point to a JSON file that conforms to the "ERC721
  ///  Metadata JSON Schema".
  function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


import "./HeroERC721BaseEnumerable.sol";
import "./HeroERC721Metadata.sol";


// solium-disable-next-line no-empty-blocks
contract HeroERC721 is HeroERC721BaseEnumerable, HeroERC721Metadata {
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./HeroERC721.sol";

// solium-disable-next-line no-empty-blocks
contract HeroCore is HeroERC721 {
  struct Hero {
    uint256 quality;//1-6
    uint256 bornAt;
    uint256 power;
    uint256 agile;//1-30
    uint256 intelligence;
    string name;
  }

  Hero[] heros;

  event HeroSpawned(uint256 indexed _tokenId, address indexed _owner, uint256 _quality);
  event HeroRebirthed(uint256 indexed _tokenId, uint256 _quality);
  event HeroRetired(uint256 indexed _tokenId);
  event HeroEvolved(uint256 indexed _tokenId, uint256 _oldQuality, uint256 _newQuality);

  constructor() {
    heros.push(Hero(0, block.timestamp,10,10,10,"test")); // The void Hero
  }
  
  function getHero(
    uint256 _tokenId
  )
    external
    view
    mustBeValidToken(_tokenId)
    returns (Hero memory)
  {
    return heros[_tokenId];
  }
  
  function spawnHero(
    uint256 _quality,
    address _owner,
    string calldata _tokenURI
  )
    external
    onlySpawner
    whenSpawningAllowed(_quality, _owner)
    returns (uint256)
  {
    return _spawnHero(_quality, _owner, _tokenURI);
  }

  function rebirthHero(
    uint256 _tokenId,
    uint256 _quality
  )
    external
    onlySpawner
    mustBeValidToken(_tokenId)
    whenRebirthAllowed(_tokenId, _quality)
  {
    Hero storage _hero = heros[_tokenId];
    _hero.quality = _quality;
    _hero.bornAt = block.timestamp;
    emit HeroRebirthed(_tokenId, _quality);
  }

  function retireHero(
    uint256 _tokenId,
    bool _rip
  )
    external
    onlyByeSayer
    whenRetirementAllowed(_tokenId, _rip)
  {
    _burn(_tokenId); 

    if (_rip) {
        delete heros[_tokenId];
    }
    

   emit HeroRetired(_tokenId); 
  }

  function evolveHero(
    uint256 _tokenId,
    uint256 _newQuality
  )
    external
    onlyQualityScientist
    mustBeValidToken(_tokenId)
    whenEvolvementAllowed(_tokenId, _newQuality)
  {
    uint256 _oldQuality = heros[_tokenId].quality;
    heros[_tokenId].quality = _newQuality;
    emit HeroEvolved(_tokenId, _oldQuality, _newQuality); 
  }

  function _spawnHero(uint256 _quality, address _owner, string calldata _tokenURI) private returns (uint256 _tokenId) {
  
    uint256 power = uint256(keccak256(abi.encodePacked(block.timestamp + 1))) % 30;
 
    uint256 agile = uint256(keccak256(abi.encodePacked(block.timestamp + 2))) % 30;
  
    uint256 intelligence= uint256(keccak256(abi.encodePacked(block.timestamp +3))) % 30;

    Hero memory _hero = Hero(_quality, block.timestamp,power,agile,intelligence,"test");

    heros.push(_hero);
    _tokenId = heros.length  - 1;
    _mint(_owner, _tokenId);
    _setTokenURI(_tokenId, _tokenURI);
    emit HeroSpawned(_tokenId, _owner, _quality);
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


import "./Ownable.sol";

import "./HeroManager.sol";


// solium-disable-next-line lbrace
contract HeroManagerCustomizable is
  HeroSpawningManager,
  HeroRetirementManager,
  HeroMarketplaceManager,
  HeroQualityManager,
  Ownable
{

  bool public allowedAll;

  function setAllowAll(bool _allowedAll) external onlyOwner {
    allowedAll = _allowedAll;
  }

  function isSpawningAllowed(uint256, address)view override external returns (bool) {
    return allowedAll;
  }

  function isRebirthAllowed(uint256, uint256)view override external returns (bool) {
    return allowedAll;
  }

  function isRetirementAllowed(uint256, bool)view override external returns (bool) {
    return allowedAll;
  }

  function isTransferAllowed(address, address, uint256)view override external returns (bool) {
    return allowedAll;
  }

  function isEvolvementAllowed(uint256, uint256)view override external returns (bool) {
    return allowedAll;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


import "./IERC721TokenReceiver.sol";


contract ERC721TokenReceiver is IERC721TokenReceiver {
  function onERC721Received(address, uint256, bytes memory) override external pure returns (bytes4) {
    return bytes4(keccak256("onERC721Received(address,uint256,bytes)"));
  }
}