// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import './Delegated.sol';
import './ERC721Staked.sol';
import './Merkle.sol';
import './Royalties.sol';

contract Phoenixes is Delegated, ERC721Staked, Royalties, Merkle {
  using Address for address;
  using Strings for uint256;

  struct MintConfig{
    uint64 ethPrice;
    uint16 maxMint;
    uint16 maxOrder;
    uint16 maxSupply;

    SaleState saleState;
  }

  enum SaleState{
    NONE,
    PRESALE,
    MAINSALE
  }

  MintConfig public config = MintConfig(
    0.0888 ether,
       3,
       3,
    8888,

    SaleState.NONE
  );

  address public crossmintProxy = 0xdAb1a1854214684acE522439684a145E62505233;
  address public payee = 0x4d0b3D71F4De4aaF2ea798A20F4EaD55A0F7416F;
  uint256 public supplyPerFaction = 1111;
  string public tokenURIPrefix;
  string public tokenURISuffix;

  mapping(uint256 => uint16) public factionSupply;


  constructor()
    ERC721B("Phoenixes", "PHNX")
    Royalties( owner(), 690, 10000 ){
  }


  //safety first
  receive() external payable {}


  //view
  function getFactionSupply() external view returns(uint[] memory factions){
    factions = new uint[]( 9 );
    factions[0] = config.maxSupply - _supply;
    factions[1] = supplyPerFaction - factionSupply[1];
    factions[2] = supplyPerFaction - factionSupply[2];
    factions[3] = supplyPerFaction - factionSupply[3];
    factions[4] = supplyPerFaction - factionSupply[4];
    factions[5] = supplyPerFaction - factionSupply[5];
    factions[6] = supplyPerFaction - factionSupply[6];
    factions[7] = supplyPerFaction - factionSupply[7];
    factions[8] = supplyPerFaction - factionSupply[8];
  }


  //payable
  function crossMint( uint16 quantity, uint16 factionIdx, address recipient, bytes32[] calldata proof ) external payable {
    require( msg.sender == crossmintProxy );
    _mint( quantity, factionIdx, recipient, proof );
  }

  function mint( uint16 quantity, uint16 factionIdx, bytes32[] calldata proof ) external payable {
    _mint( quantity, factionIdx, msg.sender, proof );
  }


  //onlyDelegates
  function burnFrom(uint256[] calldata tokenIds, address account) external payable onlyDelegates{
    unchecked{
      for(uint i; i < tokenIds.length; ++i ){
        uint256 tokenId = tokenIds[i];
        require( tokens[ tokenId ].stakeStart == 1, "Cannot burn while staked" );
        _burn( account, tokenId );
      }
    }
  }


  function mintTo(uint16[] calldata quantity, uint16[] calldata factions, address[] calldata recipient) external payable onlyDelegates{
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

    uint256 totalQuantity = 0;
    unchecked{
      for(uint256 i = 0; i < quantity.length; ++i){
        totalQuantity += quantity[i];
      }
    }
    require( totalSupply() + totalQuantity <= config.maxSupply, "Mint/order exceeds supply" );

    bool randomize;
    uint256 factionIdx;
    bytes memory hashData = _hashData();
    unchecked{
      for(uint256 i; i < recipient.length; ++i){
        owners[recipient[i]].balance += quantity[i];

        factionIdx = factions[i];
        randomize = factionIdx == 0;
        for(uint256 j; j < quantity[i]; ++j){
          if( randomize )
            factionIdx = _randomFaction( hashData, j );
          else
            require( factionSupply[ factionIdx ] + quantity[i] <= supplyPerFaction, "Mint/Order exceeds factoin supply" );

          uint256 tokenId = (factionIdx - 1) * supplyPerFaction + factionSupply[ factionIdx ];
          ++factionSupply[ factionIdx ];
          _mint( recipient[i], tokenId );
        }
      }
    }
  }

  function resurrectFor( uint[] calldata tokenIds, address[] calldata recipient ) external onlyDelegates{
    require(tokenIds.length == recipient.length,   "Must provide equal tokenIds and recipients" );

    unchecked{
      uint256 tokenId;
      for(uint i; i < tokenIds.length; ++i ){
        tokenId = tokenIds[i];
        require( !_exists( tokenId ), "Resurrect token(s) must not exist" );

        --owners[address(0)].balance;
        ++tokens[tokenId].revived;
        _transfer(address(0), recipient[i], tokenId);
      }
    }
  }

  function setConfig( MintConfig calldata newConfig ) external onlyDelegates{
    require( newConfig.maxOrder <= newConfig.maxSupply, "max order must be lte max supply" );
    require( totalSupply() <= newConfig.maxSupply, "max supply must be gte total supply" );
    require( uint8(newConfig.saleState) < 3, "invalid sale state" );

    config = newConfig;
  }

  function setCrossmint( address proxy ) external onlyDelegates{
    crossmintProxy = proxy;
  }

  function setFactionSupply( uint256 newSupply ) external onlyDelegates{
    supplyPerFaction = newSupply;
  }

  function setPayee( address newPayee ) external onlyOwner{
    payee = newPayee;
  }

  function setStakeHandler( IStakeHandler handler ) external onlyDelegates{
    stakeHandler = handler;
  }

  function setTokenURI( string calldata prefix, string calldata suffix ) external onlyDelegates{
    tokenURIPrefix = prefix;
    tokenURISuffix = suffix;
  }

  //onlyOwner
  function setDefaultRoyalty( address receiver, uint16 feeNumerator, uint16 feeDenominator ) external onlyOwner {
    _setDefaultRoyalty( receiver, feeNumerator, feeDenominator );
  }

  //view: IERC165
  function supportsInterface(bytes4 interfaceId) public view override(ERC721EnumerableB, Royalties) returns (bool) {
    return ERC721EnumerableB.supportsInterface(interfaceId)
      || Royalties.supportsInterface(interfaceId);
  }


  //view: IERC721Metadata
  function tokenURI( uint256 tokenId ) external view returns( string memory ){
    require(_exists(tokenId), "query for nonexistent token");
    return string(abi.encodePacked(tokenURIPrefix, tokenId.toString(), tokenURISuffix));
  }

  function withdraw() external onlyOwner {
    require(address(this).balance >= 0, "No funds available");
    Address.sendValue(payable(owner()), address(this).balance);
  }

  //private
  function _mint( uint16 quantity, uint256 factionIdx, address recipient, bytes32[] memory proof ) private {
    require( quantity > 0, "Must order 1+" );
    require( factionIdx < 9, "Invalid faction" );

    MintConfig memory cfg = config;
    Owner memory prev = owners[recipient];
    require( quantity <= cfg.maxOrder,                  "Order too big" );
    require( prev.purchased + quantity <= cfg.maxMint,  "Mint limit reached" );
    require( totalSupply() + quantity <= cfg.maxSupply, "Mint/Order exceeds supply" );
    require( msg.value >= cfg.ethPrice * quantity,      "Ether sent is not correct" );

    if( factionIdx > 0 ){
      require( factionSupply[ factionIdx ] + quantity <= supplyPerFaction, "Mint/Order exceeds faction supply" );
    }


    if( cfg.saleState == SaleState.MAINSALE ){
      //no-op
    }
    else if( cfg.saleState == SaleState.PRESALE ){
      require( _isValidProof( keccak256( abi.encodePacked( recipient ) ), proof ),  "Not on the access list" );
    }
    else{
      revert( "Sale is not active" );
    }

    bytes memory hashData = _hashData();
    bool randomize = factionIdx == 0;
    unchecked{
      owners[recipient] = Owner(
        prev.balance + quantity,
        prev.purchased + quantity
      );

      for(uint256 i; i < quantity; ++i ){
        if( randomize )
          factionIdx = _randomFaction( hashData, i );

        uint256 tokenId = (factionIdx - 1) * supplyPerFaction + factionSupply[ factionIdx ];
        ++factionSupply[ factionIdx ];
        _mint( recipient, tokenId );
      }
    }
  }

  function _hashData() private view returns( bytes memory ){
    //uint160 cbVal = uint160( address(block.coinbase) );
    bytes memory hashData = bytes.concat("", bytes20( address(block.coinbase)));  //160 bits

    //uint40 feeVal = uint40( block.basefee  % type(uint40).max );
    hashData = bytes.concat(hashData, bytes5( uint40( block.basefee  % type(uint40).max )));  //200 bits

    //uint32 limVal = uint32( block.gaslimit % type(uint32).max );
    hashData = bytes.concat(hashData, bytes4( uint32( block.gaslimit % type(uint32).max )));  //232 bits

    //uint40 gasVal =  uint40( tx.gasprice  % type(uint40).max );
    return bytes.concat(hashData, bytes5( uint40( tx.gasprice  % type(uint40).max )));  //272 bits
  }

  function _randomFaction( bytes memory hashData, uint256 index) private view returns( uint256 ){
    uint256 random = _random( hashData, index );
    for( uint256 i; i < 8; ++i ){
      uint256 factionIdx_ = ((random + i) % 8) + 1;
      if( factionSupply[ factionIdx_ ] < supplyPerFaction )
        return factionIdx_;
    }

    revert( "Random failed" );
  }

  function _random(bytes memory hashData, uint256 index) private view returns( uint256 ){
    uint256 blockid = block.number - (gasleft() % type(uint8).max);
    uint256 blkHash = uint256(blockhash( blockid ));
    return uint256(keccak256(
      index % 2 == 1 ?
        abi.encodePacked( blkHash, index, hashData ):
        abi.encodePacked( hashData, index, blkHash )
      ));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract Royalties is IERC2981{

  struct Fraction{
    uint16 numerator;
    uint16 denominator;
  }

  struct Royalty{
    address receiver;
    Fraction fraction;
  }

  Royalty public defaultRoyalty;
  //mapping(uint => Royalty) public tokenRoyalties;

  constructor( address receiver, uint16 royaltyNum, uint16 royaltyDenom ){
    _setDefaultRoyalty( receiver, royaltyNum, royaltyDenom );
  }

  //view: IERC2981
  /**
   * @dev See {IERC2981-royaltyInfo}.
   **/
  function royaltyInfo(uint256, uint256 _salePrice) external view virtual returns (address, uint256) {
    /*
    Royalty memory royalty = _tokenRoyaltyInfo[_tokenId];
    if (royalty.receiver == address(0)) {
        royalty = _defaultRoyaltyInfo;
    }
    */

    uint256 royaltyAmount = (_salePrice * defaultRoyalty.fraction.numerator) / defaultRoyalty.fraction.denominator;
    return (defaultRoyalty.receiver, royaltyAmount);
  }

  //view: IERC165
  /**
   * @dev See {IERC165-supportsInterface}.
   **/
  function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
    return interfaceId == type(IERC2981).interfaceId;
  }


  function _setDefaultRoyalty( address receiver, uint16 royaltyNum, uint16 royaltyDenom ) internal {
    defaultRoyalty.receiver = receiver;
    defaultRoyalty.fraction = Fraction(royaltyNum, royaltyDenom);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Delegated.sol";

contract Merkle is Delegated{
  bytes32 internal _merkleRoot = "";

  function setMerkleRoot( bytes32 merkleRoot_ ) external onlyDelegates{
    _merkleRoot = merkleRoot_;
  }

  function _isValidProof(bytes32 leaf, bytes32[] memory proof) internal view returns( bool ){
    return MerkleProof.processProof( proof, leaf ) == _merkleRoot;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

struct StakeSummary{
  address owner;  //160
  uint16 tokenId; //176
  uint32 accrued; //208
  uint32 total;   //240
}

interface IStakeHandler{
  function handleClaims( StakeSummary[] calldata stakes ) external;
  function handleStakes( uint256[] calldata tokenIds ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC721Batch {
  function isOwnerOf( address account, uint[] calldata tokenIds ) external view returns( bool );
  function safeTransferBatch( address from, address to, uint[] calldata tokenIds, bytes calldata data ) external;
  function transferBatch( address from, address to, uint[] calldata tokenIds ) external;
  function walletOfOwner( address account ) external view returns( uint[] memory );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721Batch.sol";
import "./IStakeHandler.sol";

abstract contract ERC721Staked is ERC721Batch {
  IStakeHandler public stakeHandler;

  function ownerOf( uint256 tokenId ) public override view returns( address currentOwner ){
    require(_exists(tokenId), "ERC721B: query for nonexistent token");
    if( tokens[ tokenId ].stakeStart > 1 )
      currentOwner = address(this);
    else
      currentOwner = tokens[tokenId].owner;
  }

  function claimTokens( uint256[] calldata tokenIds, bool restake ) external {
    uint32 time = uint32(block.timestamp);
    StakeSummary[] memory stakes = new StakeSummary[](tokenIds.length);
    for(uint256 i = 0; i < tokenIds.length; ++i ){
      Token storage token = tokens[ tokenIds[i] ];
      require( token.owner == msg.sender, "caller is not owner" );
      require( token.stakeStart > 1, "token is not staked");

      uint32 accrued = ( time - token.stakeStart );
      token.stakeTotal += accrued;
      token.stakeStart = restake ? time : 1;

      stakes[ i ] = StakeSummary(
        msg.sender,
        uint16(tokenIds[i]),
        accrued,
        token.stakeTotal
      );
    }

    if( address(stakeHandler) != address(0) ){
      stakeHandler.handleClaims( stakes );
    }
  }

  function stakeTokens( uint256[] calldata tokenIds ) external {
    for(uint256 i; i < tokenIds.length; ++i ){
      require( _exists(tokenIds[i]), "stake for nonexistent token" );

      Token storage token = tokens[ tokenIds[i] ];
      require( token.owner == msg.sender, "caller is not owner" );
      require( token.stakeStart < 2, "token  is already staked");
      tokens[ tokenIds[ i ] ].stakeStart = uint32(block.timestamp);
    }

    if( address(stakeHandler) != address(0) ){
      stakeHandler.handleStakes( tokenIds );
    }
  }


  //internal
  function _isStaked( uint256 tokenId ) internal view returns( bool ){
    return tokens[ tokenId ].stakeStart > 1;
  }

  function _transfer(address from, address to, uint256 tokenId) internal virtual override {
    require( !_isStaked(tokenId), "token is staked" );
    super._transfer( from, to, tokenId );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./ERC721B.sol";

abstract contract ERC721EnumerableB is ERC721B, IERC721Enumerable {
  function supportsInterface( bytes4 interfaceId ) public view virtual override(ERC721B, IERC165) returns( bool ){
    return interfaceId == type(IERC721Enumerable).interfaceId
      || super.supportsInterface( interfaceId );
  }

  function tokenOfOwnerByIndex( address owner, uint256 index ) external view returns( uint256 ){
    require( owners[ owner ].balance > index, "ERC721EnumerableB: owner index out of bounds" );

    uint256 count;
    uint256 tokenId;
    for( tokenId = 0; tokenId < 8888; ++tokenId ){
      if( owner != tokens[tokenId].owner )
        continue;

      if( index == count++ )
        break;
    }
    return tokenId;
  }

  function tokenByIndex( uint256 index ) external view returns( uint256 ){
    require( _exists( index ), "ERC721EnumerableB: query for nonexistent token");
    return index;
  }

  function totalSupply() public view returns( uint256 ){
    return _supply - burned();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IERC721Batch.sol";
import "./ERC721EnumerableB.sol";

abstract contract ERC721Batch is ERC721EnumerableB, IERC721Batch {
  function isOwnerOf( address account, uint[] calldata tokenIds ) external view returns( bool ){
    for(uint i; i < tokenIds.length; ++i ){
      if( account != tokens[ tokenIds[i] ].owner )
        return false;
    }

    return true;
  }

  function safeTransferBatch( address from, address to, uint256[] calldata tokenIds, bytes calldata data ) external{
    for(uint i; i < tokenIds.length; ++i ){
      safeTransferFrom( from, to, tokenIds[i], data );
    }
  }

  function transferBatch( address from, address to, uint256[] calldata tokenIds ) external{
    for(uint i; i < tokenIds.length; ++i ){
      transferFrom( from, to, tokenIds[i] );
    }
  }

  function walletOfOwner( address account ) external view returns( uint[] memory ){
    uint256 count;
    uint256 quantity = owners[ account ].balance;
    uint256[] memory wallet = new uint[]( quantity );
    for( uint i = 0; i < 8888; ++i ){
      if( account == tokens[i].owner ){
        wallet[ count++ ] = i;
        if( count == quantity )
          break;
      }
    }
    return wallet;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";


abstract contract ERC721B is Context, ERC165, IERC721, IERC721Metadata {
  using Address for address;

  struct Owner{
    uint16 balance;
    uint16 purchased;
  }

  struct Token{
    address owner;
    uint32 stakeStart;
    uint32 stakeTotal;
    uint16 revived;
  }

  mapping(uint256 => Token) public tokens;
  mapping(address => Owner) public owners;

  uint256 internal _supply;
  string private _name;
  string private _symbol;

  mapping(uint256 => address) internal _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  constructor(string memory name_, string memory symbol_ ){
    _name = name_;
    _symbol = symbol_;
  }

  //public view
  function balanceOf(address owner) external view returns( uint256 balance ){
    require(owner != address(0), "ERC721B: balance query for the zero address");
    return owners[owner].balance;
  }

  function burned() public view returns(uint256){
    return owners[address(0)].balance;
  }

  function name() external view returns( string memory name_ ){
    return _name;
  }

  function ownerOf(uint256 tokenId) public virtual view returns( address owner ){
    require(_exists(tokenId), "ERC721B: query for nonexistent token");
    return tokens[tokenId].owner;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns( bool isSupported ){
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function symbol() external view returns( string memory symbol_ ){
    return _symbol;
  }


  //approvals
  function approve(address to, uint tokenId) external{
    address owner = tokens[tokenId].owner;
    require(to != owner, "ERC721B: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721B: caller is not owner nor approved for all"
    );

    _approve(to, tokenId);
  }

  function getApproved(uint256 tokenId) public view returns( address approver ){
    require(_exists(tokenId), "ERC721: query for nonexistent token");
    return _tokenApprovals[tokenId];
  }

  function isApprovedForAll(address owner, address operator) public view returns( bool isApproved ){
    return _operatorApprovals[owner][operator];
  }

  function setApprovalForAll(address operator, bool approved) external{
    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }


  //transfers
  function safeTransferFrom(address from, address to, uint256 tokenId) external{
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public{
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721B: caller is not owner nor approved");
    _safeTransfer(from, to, tokenId, _data);
  }

  function transferFrom(address from, address to, uint256 tokenId) public{
    //solhint-disable-next-line max-line-length
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721B: caller is not owner nor approved");
    _transfer(from, to, tokenId);
  }


  //internal
  function _approve(address to, uint tokenId) internal{
    _tokenApprovals[tokenId] = to;
    emit Approval(tokens[tokenId].owner, to, tokenId);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {
  }

  function _burn( address from, uint tokenId ) internal{
    _transfer( from, address(0), tokenId );
  }

  function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns( bool ){
    if (to.isContract()) {
      try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721B: transfer to non ERC721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  function _exists(uint256 tokenId) internal view returns( bool ){
    return tokens[tokenId].owner != address(0);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns( bool isApproved ){
    require(_exists(tokenId), "ERC721B: query for nonexistent token");
    address owner = tokens[tokenId].owner;
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  function _mint( address to, uint256 tokenId ) internal{
    require(!_exists(tokenId), "ERC721B: mint for existing token");
    _beforeTokenTransfer(address(0), to, tokenId);

    ++_supply;
    tokens[ tokenId ] = Token( to, 1, 1, 0 );
    emit Transfer( address(0), to, tokenId );
  }

  function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal{
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721B: transfer to non ERC721Receiver implementer");
  }

  function _transfer(address from, address to, uint256 tokenId) internal virtual{
    require(tokens[tokenId].owner == from, "ERC721B: transfer of token that is not own");

    // Clear approvals from the previous owner
    delete _tokenApprovals[tokenId];
    _beforeTokenTransfer(from, to, tokenId);

    unchecked{
      --owners[from].balance;
      ++owners[to].balance;
    }

    tokens[tokenId].owner = to;
    emit Transfer(from, to, tokenId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Delegated is Ownable{
  mapping(address => bool) internal _delegates;

  modifier onlyDelegates {
    require(_delegates[msg.sender], "Invalid delegate" );
    _;
  }

  constructor()
    Ownable(){
    setDelegate( owner(), true );
  }

  //onlyOwner
  function isDelegate( address addr ) external view onlyOwner returns( bool ){
    return _delegates[addr];
  }

  function setDelegate( address addr, bool isDelegate_ ) public onlyOwner{
    _delegates[addr] = isDelegate_;
  }

  function transferOwnership(address newOwner) public override onlyOwner {
    super.transferOwnership( newOwner );
    setDelegate( owner(), true );
  }
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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