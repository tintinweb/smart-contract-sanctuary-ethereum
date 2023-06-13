/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

pragma solidity >=0.8.13;

// File: enft/contracts/ERC165.sol

/// Creates a standard method to publish and detect what interfaces a smart
/// contract implements.
/// @title ERC-165 Standard Interface Detection
/// @dev See https://eips.ethereum.org/EIPS/eip-165
interface ERC165 {
	/// @notice Query if a contract implements an interface
	/// @param interfaceID The interface identifier, as specified in ERC-165
	/// @dev Interface identification is specified in ERC-165. This function
	///  uses less than 30,000 gas.
	/// @return `true` if the contract implements `interfaceID` and
	///  `interfaceID` is not 0xffffffff, `false` otherwise
	function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// File: enft/contracts/ERC20.sol

/// A standard interface for tokens, without the OPTIONAL methods.
/// @title ERC-20 Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-20
interface ERC20 {
	// MUST trigger when tokens are transferred, including zero value transfers.
	//
	// A token contract which creates new tokens SHOULD trigger a Transfer event
	// with the from address set to 0x0 when tokens are created.
	event Transfer(address indexed from, address indexed to, uint256 value);

	// MUST trigger on any successful call to approve(address spender, uint256 value).
	event Approval(address indexed owner, address indexed spender, uint256 value);

	// Returns the total token supply.
	function totalSupply() external view returns (uint256);

	// Returns the account balance of another account with address owner.
	function balanceOf(address owner) external view returns (uint256);

	// Transfers value amount of tokens to address to, and MUST fire the Transfer
	// event. The function SHOULD throw if the message caller’s account balance does
	// not have enough tokens to spend.
	//
	// Note Transfers of 0 values MUST be treated as normal transfers and fire the
	// Transfer event.
	function transfer(address to, uint256 value) external returns (bool success);

	// Transfers value amount of tokens from address from to address to, and MUST
	// fire the Transfer event.
	//
	// The transferFrom method is used for a withdraw workflow, allowing contracts
	// to transfer tokens on your behalf. This can be used for example to allow a
	// contract to transfer tokens on your behalf and/or to charge fees in
	// sub-currencies. The function SHOULD throw unless the from account has
	// deliberately authorized the sender of the message via some mechanism.
	//
	// Note Transfers of 0 values MUST be treated as normal transfers and fire the
	// Transfer event.
	function transferFrom(address from, address to, uint256 value) external returns (bool success);

	// Allows spender to withdraw from your account multiple times, up to the
	// value amount. If this function is called again it overwrites the current
	// allowance with value.
	//
	// NOTE: To prevent attack vectors like the one described here
	// <https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/>
	// and discussed here <https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729>,
	// clients SHOULD make sure to create user interfaces in such a way that they
	// set the allowance first to 0 before setting it to another value for the same
	// spender. THOUGH The contract itself shouldn’t enforce it, to allow backwards
	// compatibility with contracts deployed before.
	function approve(address spender, uint256 value) external returns (bool success);

	// Returns the amount which spender is still allowed to withdraw from owner.
	function allowance(address owner, address spender) external view returns (uint256 remaining);
}

// File: enft/contracts/ERC721Metadata.sol

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface ERC721Metadata /* is ERC721 */ {
	/// @notice A descriptive name for a collection of NFTs in this contract
	function name() external view returns (string memory);

	/// @notice An abbreviated name for NFTs in this contract
	function symbol() external view returns (string memory);

	/// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
	/// @dev Throws if `tokenId` is not a valid NFT. URIs are defined in RFC
	///  3986. The URI may point to a JSON file that conforms to the "ERC721
	///  Metadata JSON Schema".
	function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: enft/contracts/ERC721.sol

/// A standard interface for non-fungible tokens, also known as deeds. Every
/// ERC-721 compliant contract must implement the ERC721 and ERC165 interfaces.
/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface ERC721 /* is ERC165 */ {
	/// @dev This emits when ownership of any NFT changes by any mechanism.
	///  This event emits when NFTs are created (`from` == 0) and destroyed
	///  (`to` == 0). Exception: during contract creation, any number of NFTs
	///  may be created and assigned without emitting Transfer. At the time of
	///  any transfer, the approved address for that NFT (if any) is reset to none.
	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

	/// @dev This emits when the approved address for an NFT is changed or
	///  reaffirmed. The zero address indicates there is no approved address.
	///  When a Transfer event emits, this also indicates that the approved
	///  address for that NFT (if any) is reset to none.
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

	/// @dev This emits when an operator is enabled or disabled for an owner.
	///  The operator can manage all NFTs of the owner.
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	/// @notice Count all NFTs assigned to an owner
	/// @dev NFTs assigned to the zero address are considered invalid, and this
	///  function throws for queries about the zero address.
	/// @param owner An address for whom to query the balance
	/// @return The number of NFTs owned by `owner`, possibly zero
	function balanceOf(address owner) external view returns (uint256);

	/// @notice Find the owner of an NFT
	/// @dev NFTs assigned to zero address are considered invalid, and queries
	///  about them do throw.
	/// @param tokenId The identifier for an NFT
	/// @return The address of the owner of the NFT
	function ownerOf(uint256 tokenId) external view returns (address);

	/// @notice Transfers the ownership of an NFT from one address to another address
	/// @dev Throws unless `msg.sender` is the current owner, an authorized
	///  operator, or the approved address for this NFT. Throws if `from` is
	///  not the current owner. Throws if `to` is the zero address. Throws if
	///  `tokenId` is not a valid NFT. When transfer is complete, this function
	///  checks if `to` is a smart contract (code size > 0). If so, it calls
	///  `onERC721Received` on `to` and throws if the return value is not
	///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	/// @param from The current owner of the NFT
	/// @param to The new owner
	/// @param tokenId The NFT to transfer
	/// @param data Additional data with no specified format, sent in call to `to`
	function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external payable;

	/// @notice Transfers the ownership of an NFT from one address to another address
	/// @dev This works identically to the other function with an extra data parameter,
	///  except this function just sets data to "".
	/// @param from The current owner of the NFT
	/// @param to The new owner
	/// @param tokenId The NFT to transfer
	function safeTransferFrom(address from, address to, uint256 tokenId) external payable;

	/// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
	///  TO CONFIRM THAT `to` IS CAPABLE OF RECEIVING NFTS OR ELSE
	///  THEY MAY BE PERMANENTLY LOST
	/// @dev Throws unless `msg.sender` is the current owner, an authorized
	///  operator, or the approved address for this NFT. Throws if `from` is
	///  not the current owner. Throws if `to` is the zero address. Throws if
	///  `tokenId` is not a valid NFT.
	/// @param from The current owner of the NFT
	/// @param to The new owner
	/// @param tokenId The NFT to transfer
	function transferFrom(address from, address to, uint256 tokenId) external payable;

	/// @notice Change or reaffirm the approved address for an NFT
	/// @dev The zero address indicates there is no approved address.
	///  Throws unless `msg.sender` is the current NFT owner, or an authorized
	///  operator of the current owner.
	/// @param approved The new approved NFT controller
	/// @param tokenId The NFT to approve
	function approve(address approved, uint256 tokenId) external payable;

	/// @notice Enable or disable approval for a third party ("operator") to manage
	///  all of `msg.sender`'s assets
	/// @dev Emits the ApprovalForAll event. The contract MUST allow
	///  multiple operators per owner.
	/// @param operator Address to add to the set of authorized operators
	/// @param approved True if the operator is approved, false to revoke approval
	function setApprovalForAll(address operator, bool approved) external;

	/// @notice Get the approved address for a single NFT
	/// @dev Throws if `tokenId` is not a valid NFT.
	/// @param tokenId The NFT to find the approved address for
	/// @return The approved address for this NFT, or the zero address if there is none
	function getApproved(uint256 tokenId) external view returns (address);

	/// @notice Query if an address is an authorized operator for another address
	/// @param owner The address that owns the NFTs
	/// @param operator The address that acts on behalf of the owner
	/// @return True if `operator` is an approved operator for `owner`, false otherwise
	function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: enft/contracts/ERC721Enumerable.sol

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
interface ERC721Enumerable /* is ERC721 */ {
	/// @notice Count NFTs tracked by this contract
	/// @return A count of valid NFTs tracked by this contract, where each one of
	///  them has an assigned and queryable owner not equal to the zero address
	function totalSupply() external view returns (uint256);

	/// @notice Enumerate valid NFTs
	/// @dev Throws if `index` >= `totalSupply()`.
	/// @param index A counter less than `totalSupply()`
	/// @return The token identifier for the `index`th NFT,
	///  (sort order not specified)
	function tokenByIndex(uint256 index) external view returns (uint256);

	/// @notice Enumerate NFTs assigned to an owner
	/// @dev Throws if `index` >= `balanceOf(owner)` or if
	///  `owner` is the zero address, representing invalid NFTs.
	/// @param owner An address where we are interested in NFTs owned by them
	/// @param index A counter less than `balanceOf(owner)`
	/// @return The token identifier for the `index`th NFT assigned to `owner`,
	///   (sort order not specified)
	function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

// File: enft/contracts/ERC721TokenReceiver.sol

/// A wallet/broker/auction application MUST implement the wallet interface if
/// it will accept safe transfers.
/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
	/// @notice Handle the receipt of an NFT
	/// @dev The ERC721 smart contract calls this function on the recipient
	///  after a `transfer`. This function MAY throw to revert and reject the
	///  transfer. Return of other than the magic value MUST result in the
	///  transaction being reverted.
	///  Note: the contract address is always the message sender.
	/// @param operator The address which called `safeTransferFrom` function
	/// @param from The address which previously owned the token
	/// @param tokenId The NFT identifier which is being transferred
	/// @param data Additional data with no specified format
	/// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
	///  unless throwing
	function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns(bytes4);
}

// File: enft/contracts/FixedNFTSet.sol

// FixedNFTSet manages a fixed amount of non-fungible tokens.
contract FixedNFTSet is ERC721, ERC721Enumerable, ERC165 {

// The number of tokens is fixed during contract creation.
// Zero/absent entries in tokenOwners take the defaultOwner value.
uint256 private immutable tokenCountAndDefaultOwner;

// Each token (index/ID) has one owner at a time.
// Zero/absent entries take the defaultOwner value.
mapping(uint256 => address) private tokenOwners;

// Each token (index/ID) can be granted to a destination address.
mapping(uint256 => address) private tokenApprovals;

// The token-owner:token-operator:approval-flag entries are always true.
mapping(address => mapping(address => bool)) private operatorApprovals;

// Constructor mints n tokens, and transfers each token to the receiver address.
// Token identifiers match their respective index, counting from 0 to n − 1.
// Initial Transfer emission is omitted.
constructor(uint256 n, address receiver) {
	requireAddress(receiver);
	tokenCountAndDefaultOwner = uint(uint160(receiver)) | (n << 160);
}

// RequireAddress denies the zero value.
function requireAddress(address a) internal pure {
	require(a != address(0), "ERC-721 address 0");
}

// RequireToken denies any token index/ID that is not in this contract.
function requireToken(uint256 indexOrID) internal view {
	require(indexOrID < totalSupply(), "ERC-721 token \u2415");
}

function supportsInterface(bytes4 interfaceID) public virtual override(ERC165) pure returns (bool) {
	// https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified
	return interfaceID == 0x80ac58cd  // ERC721
	    || interfaceID == 0x780e9d63  // ERC721Enumerable
	    || interfaceID == 0x01ffc9a7; // ERC165
}

function totalSupply() public override(ERC721Enumerable) view returns (uint256) {
	return tokenCountAndDefaultOwner >> 160;
}

// Tokens are identified by their index one-to-one.
function tokenByIndex(uint256 index) public override(ERC721Enumerable) view returns (uint256) {
	requireToken(index);
	return index;
}

function tokenOfOwnerByIndex(address owner, uint256 index) public override(ERC721Enumerable) view returns (uint256 tokenID) {
	requireAddress(owner);
	for (tokenID = 0; tokenID < totalSupply(); tokenID++) {
		if (ownerOf(tokenID) == owner) {
			if (index == 0) {
				return tokenID;
			}

			--index;
		}
	}
	revert("ERC-721 index exceeds balance");
}

function balanceOf(address owner) public override(ERC721) view returns (uint256) {
	requireAddress(owner);
	uint256 balance = 0;
	// count owner matches
	for (uint256 tokenID = 0; tokenID < totalSupply(); tokenID++) {
		if (ownerOf(tokenID) == owner) {
			++balance;
		}
	}
	return balance;
}

function ownerOf(uint256 tokenID) public override(ERC721) view returns (address) {
	requireToken(tokenID);
	address owner = tokenOwners[tokenID];
	if (owner == address(0)) {
		return address(uint160(tokenCountAndDefaultOwner));
	}
	return owner;
}

function safeTransferFrom(address from, address to, uint256 tokenID, bytes calldata data) public override(ERC721) payable {
	transferFrom(from, to, tokenID);
	if (msg.sender == tx.origin) { // is contract
		require(ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenID, data) == ERC721TokenReceiver.onERC721Received.selector, "ERC721TokenReceiver mis");
	}
}

function safeTransferFrom(address from, address to, uint256 tokenID) public override(ERC721) payable {
	return this.safeTransferFrom(from, to, tokenID, "");
}

function transferFrom(address from, address to, uint256 tokenID) public override(ERC721) payable {
	address owner = ownerOf(tokenID); // checks token ID
	require(from == owner, "ERC-721 from \u2415");
	requireAddress(to);

	address approved = tokenApprovals[tokenID];
	require(msg.sender == owner || msg.sender == approved || isApprovedForAll(owner, msg.sender), "ERC-721 sender deny");

	// reset approvals from previous owner, if any
	if (approved != address(0)) {
		delete tokenApprovals[tokenID];
		emit Approval(owner, address(0), tokenID);
	}

	// actual transfer
	tokenOwners[tokenID] = to;
	emit Transfer(from, to, tokenID);
}

function approve(address to, uint256 tokenID) public override(ERC721) payable {
	address owner = ownerOf(tokenID); // checks token ID
	require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC-721 sender deny");
	tokenApprovals[tokenID] = to;
	emit Approval(owner, to, tokenID);
}

function setApprovalForAll(address operator, bool approved) public override(ERC721) {
	if (approved) {
		operatorApprovals[msg.sender][operator] = true;
	} else {
		delete operatorApprovals[msg.sender][operator];
	}
	emit ApprovalForAll(msg.sender, operator, approved);
}

function getApproved(uint256 tokenID) public override(ERC721) view returns (address operator) {
	requireToken(tokenID);
	return tokenApprovals[tokenID];
}

function isApprovedForAll(address owner, address operator) public override(ERC721) view returns (bool) {
	return operatorApprovals[owner][operator];
}

}

// File: contracts/CollectiblesSale.sol

// SPDX-License-Identifier: UNLICENSED

// QualifiedPrice provides an (ERC20) unit to the quanty.
struct QualifiedPrice {
	uint96  amount;   // currency quantity
	address currency; // token contract
}


// CollectiblesSale represents one product on Montro Collectibles.
contract CollectiblesSale is FixedNFTSet, ERC721Metadata {

// CollectiblesPurchaseOffer signals an option to purchase tokens. For any given
// seller, each CollectiblesPurchaseOffer emission overrides the previous one,
// if any. A zero QualifiedPrice amount terminates the offer from seller.
event CollectiblesPurchaseOffer(QualifiedPrice perToken, address seller);


// Name labels the item for sale.
string public override(ERC721Metadata) name;

// SerialCode identifies the item for sale.
string public serialCode;

// The 32-byte SHA2-256 from IPFS is split over two hexadecimal words.
// Use all lower-case for valid IPFS URI composition.
bytes32 immutable FSHashHex1;
bytes32 immutable FSHashHex2;

// BoostConfig is packed into one immutable word for gas efficiency.
uint256 immutable boosts;

mapping(address => QualifiedPrice) purchaseOffers;


// BoostConfig packs boosts as base–ramp pairs.
struct BoostConfig {
	int16 stakeBase;
	int16 stakeRamp;
	int16 weightBase;
	int16 weightRamp;
}

// All tokens are assigned to productHolder, with an CollectiblesPurchaseOffer
// emission as per QualifiedPrice. The initial ERC721 Transfer events are
// omitted because they are implied by the CollectiblesPurchaseOffer already.
constructor(address productHolder, string memory productName, string memory productSerialCode, uint256 partCount, QualifiedPrice memory perToken, bytes32 IPFSHashHex1, bytes32 IPFSHashHex2, BoostConfig memory bc)
FixedNFTSet(partCount, productHolder) {
	name = productName;
	serialCode = productSerialCode;

	FSHashHex1 = IPFSHashHex1;
	FSHashHex2 = IPFSHashHex2;

	boosts = uint256(uint16(bc.stakeRamp)) << 32
	       | uint256(uint16(bc.stakeBase)) << 48
	       | uint256(uint16(bc.weightRamp)) << 64
	       | uint256(uint16(bc.weightBase)) << 80;

	// initial Transfer emission is optional but needed by OpenSea
	for (uint256 tokenID; tokenID < partCount; tokenID++) {
		emit Transfer(address(0), productHolder, tokenID);
	}

	// initial product offering
	purchaseOffers[productHolder] = perToken;
	emit CollectiblesPurchaseOffer(perToken, productHolder);
}

function supportsInterface(bytes4 interfaceID) public override(FixedNFTSet) pure returns (bool) {
	return super.supportsInterface(interfaceID)
	    || interfaceID == 0x5b5e139f; // ERC721Metadata
}

function symbol() override(ERC721Metadata) public pure returns (string memory) {
	return "PART";
}

// FSURIFix packs both the prefix and the suffix of an IPFS URI with hex
// encoding. This is to effectively store the entire URI in three words.
//
// The CID header consists of the following (multiformat) prefixes:
// 'f': lower-case hexadecimal (for all what follows)
// '01': CID version 1 (in hexadecimal)
// '70': MerkleDAG ProtoBuf (in hexadecimal)
// '12': SHA2-256 (in hexadecimal)
// '20': hash bit-length (in hexadecimal)
bytes21 constant FSURIFix = "ipfs://f01701220.json";

function tokenURI(uint256 tokenID) override(ERC721Metadata) public view returns (string memory) {
	requireToken(tokenID);

	// "/part-000"
	uint256 decimalPath = 0x2f706172742d303030;
	decimalPath += tokenID % 10;                 // digit
	decimalPath += ((tokenID / 10) % 10) << 8;   // deci digit
	decimalPath += ((tokenID / 100) % 10) << 16; // centi digit

	return string(bytes.concat(bytes16(FSURIFix), // trim head from fix
		FSHashHex1, FSHashHex2,               // both hex parts
		bytes9(uint72(decimalPath)),          // convert to bytes
		bytes5(uint40(uint168(FSURIFix))))    // trim tail from fix
	);
}

// TokenStake returns the relative share in the sale-execution. All boost values
// combined represent a payout in full.
//
// ⚠️ Note that the stake is duplacated in the metadata from tokenURI.
function tokenStake(uint256 tokenID) public view returns (int256 boost) {
	uint n = totalSupply();
	if (tokenID >= n) return 0;
	uint256 b = boosts;
	return int256(tokenID) * int16(uint16(b >> 32)) + int16(uint16(b >> 48));
}

// TokenWeight returns the relative momentum for voting. All boost values
// combined represent a vote in full.
//
// ⚠️ Note that the weight is duplacated in the metadata from tokenURI.
function tokenWeight(uint256 tokenID) public view returns (int256 boost) {
	uint n = totalSupply();
	if (tokenID >= n) return 0;
	uint256 b = boosts;
	return int256(tokenID) * int16(uint16(b >> 64)) + int16(uint16(b >> 80));
}

// PurchaseOffer allows anyone to purchase tokens from msg.sender at the given
// QualifiedPrice. PurchaseOffer overwrites the previous QualifiedPrice, if any.
// QualifiedPrice amount zero terminates any PurchaseOffer from msg.sender.
function purchaseOffer(QualifiedPrice memory perToken) public payable {
	if (perToken.amount == 0) {
		delete purchaseOffers[msg.sender];
	} else {
		tokenOfOwnerByIndex(msg.sender, 0); // address & balance check
		require(isApprovedForAll(msg.sender, address(this)), "contract needs operator approval");
		purchaseOffers[msg.sender] = perToken;
	}
	emit CollectiblesPurchaseOffer(perToken, msg.sender);
}

// PurchaseFrom aquires a token from seller if, and only if, a matching purchase
// offer is found.
function purchaseFrom(address seller, uint256 tokenID) public payable {
	QualifiedPrice memory offer = purchaseOffers[seller];
	require(offer.amount != 0, "no offer");

	// verify price expectency of buyer against current offer
	require(ERC20(offer.currency).allowance(msg.sender, address(this)) == offer.amount, "allowance mismatch");

	// pay
	require(ERC20(offer.currency).transferFrom(msg.sender, seller, offer.amount), "no pay");
	// redeem
	this.transferFrom(seller, msg.sender, tokenID);
}

}