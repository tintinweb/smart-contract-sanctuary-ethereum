/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.13;

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


/// @title NFT Purchase En Masse
/// @notice A buyout trades non-fungible tokens for fungible-token returns. Any
///  number of buyers can make an offer (to the same contract). It is up to the
///  individual NFT owners on whether to make use of any of such offers or not.
/// @dev Only one contract required per chain. Look for NFTBuyOffer events to
///  find an existing one.
/// @author Pascal S. de Kloe
contract NFTBuyout {

/// @notice Each offer gets propagated with one event. The specific deal per NFT
///  can be retrieved with tokenPrice.
/// @param target ERC-721 contract
/// @param buyer acquisition party
event NFTBuyOffer(address indexed target, address buyer);

/// A buyer can vary the price per token.
/// @param None Disable price variation—fixed price for each NFT.
/// @param RampDown Decrease the amount offered per token identifier with a
///  fixed quantity, starting with zero, as in: price − (tokenID × varyData).
enum PriceVary { None, RampDown }

/// @notice The buyout price is per NFT, with an optional vary applied.
/// @param amount currency quantity
/// @param currency ERC-20 contract
/// @param varyScheme difference between NFT, with None for disabled
/// @param varyData bytes are interpretated according to varyScheme
struct Price {
	uint96    amount;
	address   currency;
	PriceVary varyScheme;
	uint248   varyData;
}

// Each NFT-contract:buyer:price entry is an individual buyout attempt.
mapping(address => mapping(address => Price)) private buyouts;

/// @notice An offer commits to buying any NFT in the target for a given price.
///  Any previous offer gets replaced. A zero price amount retracts the offer.
///  The buyer must approve this contract for the amount of ERC-20 it wants to
///  spend in total. An approval of less than tokenPrice will block sellToken.
/// @dev ⚠️ Be carefull with a non-fixed tokenSupply. Think about PriceVary.
/// @param target ERC-721 contract
/// @param price per token
function buyOffer(address target, Price calldata price) public payable {
	if (price.amount == 0) {
		delete buyouts[target][msg.sender];
		return;
	}

	// NFT contracts MUST implement ERC-165 by spec
	require(ERC165(target).supportsInterface(type(ERC721).interfaceId), "need standard NFT");

	PriceVary vary = price.varyScheme;
	if (vary == PriceVary.RampDown) {
		require(ERC165(target).supportsInterface(type(ERC721Enumerable).interfaceId), "ramp-down needs enumerable NFT");

		// determine negative-price threshold
		uint rampDown = uint(price.varyData);
		require(rampDown != 0, "zero ramp-down");
		uint maxID = uint(price.amount) / rampDown;

		// check every token currently present
		uint n = ERC721Enumerable(target).totalSupply();
		for (uint i = 0; i < n; i++) {
			require(ERC721Enumerable(target).tokenByIndex(i) <= maxID, "token ID underflows ramp-down");
		}
	} else if (vary != PriceVary.None) {
		revert("unknow vary type");
	}

	// fail-fast: trade requires allowance to this contract
	require(ERC20(price.currency).allowance(msg.sender, address(this)) != 0, "no payment allowance");

	buyouts[target][msg.sender] = price;

	emit NFTBuyOffer(target, msg.sender);
}

/// @notice Each NFT is subject to a dedicated trade amount.
/// @dev There is no check on the tokenID as non-existing tokens simply won't
///  transfer per ERC-721 standard.
/// @param target ERC-721 contract
/// @param tokenID NFT in subject
/// @param buyer acquisition party
/// @return amount ERC-20 quantity
/// @return currency ERC-20 contract
function tokenPrice(address target, uint256 tokenID, address buyer) public view returns (uint256 amount, address currency) {
	Price memory price = buyouts[target][buyer];
	amount = uint256(price.amount);
	require(amount != 0, "no such offer");
	currency = price.currency;

	// apply price variation, if any
	if (price.varyScheme == PriceVary.RampDown) {
		amount -= uint256(price.varyData) * tokenID;
	}

	return (amount, currency);
}

/// @notice Trade one NFT for ERC-20 conform tokenPrice.
/// @dev Tokens can be traded more than once. Buy offers can be modified or
///  retracted.
/// @param target ERC-721 contract
/// @param tokenID NFT in subject
/// @param buyer acquisition party
/// @param wantAmount minimal price expectation—prevents races
/// @param wantCurrency ERC-20 unit expectation—prevents races
function sellToken(address target, uint256 tokenID, address buyer, uint256 wantAmount, address wantCurrency) public {
	require(msg.sender != buyer, "sell to self");

	(uint256 amount, address currency) = tokenPrice(target, tokenID, buyer);
	require(amount >= wantAmount, "trade price miss");
	require(currency == wantCurrency, "trade currency miss");

	ERC721(target).transferFrom(msg.sender, buyer, tokenID);
	ERC20(currency).transferFrom(buyer, msg.sender, amount);
}

}