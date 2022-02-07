/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// SPDX-License-Identifier: MIT
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



/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/distractedm1nd/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
/*///////////////////////////////////////////////////////////////
EVENTS
//////////////////////////////////////////////////////////////*/

event Transfer(address indexed from, address indexed to, uint256 indexed id);

event Approval(address indexed owner, address indexed spender, uint256 indexed id);

event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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

mapping(uint256 => address) public ownerOf;

mapping(uint256 => address) public getApproved;

mapping(address => mapping(address => bool)) public isApprovedForAll;

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

function approve(address spender, uint256 id) public virtual {
address owner = ownerOf[id];

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
require(from == ownerOf[id], "WRONG_FROM");

require(to != address(0), "INVALID_RECIPIENT");

require(
msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
"NOT_AUTHORIZED"
);

// Underflow of the sender's balance is impossible because we check for
// ownership above and the recipient's balance can't realistically overflow.
unchecked {
balanceOf[from]--;

balanceOf[to]++;
}

ownerOf[id] = to;

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
ERC165 LOGIC
//////////////////////////////////////////////////////////////*/

function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
return
interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
}

/*///////////////////////////////////////////////////////////////
INTERNAL MINT/BURN LOGIC
//////////////////////////////////////////////////////////////*/

function _mint(address to, uint256 id) internal virtual {
require(to != address(0), "INVALID_RECIPIENT");

require(ownerOf[id] == address(0), "ALREADY_MINTED");

// Counter overflow is incredibly unrealistic.
unchecked {
totalSupply++;

balanceOf[to]++;
}

ownerOf[id] = to;

emit Transfer(address(0), to, id);
}

function _burn(uint256 id) internal virtual {
address owner = ownerOf[id];

require(ownerOf[id] != address(0), "NOT_MINTED");

// Ownership check above ensures no underflow.
unchecked {
totalSupply--;

balanceOf[owner]--;
}

delete ownerOf[id];

delete getApproved[id];

emit Transfer(owner, address(0), id);
}

/*///////////////////////////////////////////////////////////////
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
interface ERC721TokenReceiver {
function onERC721Received(
address operator,
address from,
uint256 id,
bytes calldata data
) external returns (bytes4);
}




// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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





// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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



/// @notice Thrown when completing the transaction results in overallocation of Pixelmon.
error MintedOut();
/// @notice Thrown when the dutch auction phase has not yet started, or has already ended.
error AuctionNotStarted();
/// @notice Thrown when the user has already minted two Pixelmon in the dutch auction.
error MintingTooMany();
/// @notice Thrown when the value of the transaction is not enough for the current dutch auction or mintlist price.
error ValueTooLow();
/// @notice Thrown when the user is not on the mintlist.
error NotMintlisted();
/// @notice Thrown when the caller is not the EvolutionSerum contract, and is trying to evolve a Pixelmon.
error UnauthorizedEvolution();
/// @notice Thrown when an invalid evolution is given by the EvolutionSerum contract.
error UnknownEvolution();


//  ______   __     __  __     ______     __         __    __     ______     __   __
// /\  == \ /\ \   /\_\_\_\   /\  ___\   /\ \       /\ "-./  \   /\  __ \   /\ "-.\ \
// \ \  _-/ \ \ \  \/_/\_\/_  \ \  __\   \ \ \____  \ \ \-./\ \  \ \ \/\ \  \ \ \-.  \
//  \ \_\    \ \_\   /\_\/\_\  \ \_____\  \ \_____\  \ \_\ \ \_\  \ \_____\  \ \_\\"\_\
//   \/_/     \/_/   \/_/\/_/   \/_____/   \/_____/   \/_/  \/_/   \/_____/   \/_/ \/_/
//
/// @title Generation 1 Pixelmon NFTs
/// @author delta devs (https://www.twitter.com/deltadevelopers)
contract Pixelmon is ERC721, Ownable {
using Strings for uint256;

/*///////////////////////////////////////////////////////////////
CONSTANTS
//////////////////////////////////////////////////////////////*/

/// @dev Determines the order of the species for each tokenId, mechanism for choosing starting index explained post mint, explanation hash: acb427e920bde46de95103f14b8e57798a603abcf87ff9d4163e5f61c6a56881.
uint constant public provenanceHash = 0x9912e067bd3802c3b007ce40b6c125160d2ccb5352d199e20c092fdc17af8057;

/// @dev Sole receiver of collected contract funds, and receiver of 330 Pixelmon in the constructor.
address constant gnosisSafeAddress = 0x22e45E6a1D4584fb5AE082a2D7dE164Cb30ACf89;

/// @dev 7750, plus 330 for the Pixelmon Gnosis Safe
uint constant auctionSupply = 7750 + 330;

/// @dev The offsets are the tokenIds that the corresponding evolution stage will begin minting at.
uint constant secondEvolutionOffset = 10005;
uint constant thirdEvolutionOffset = secondEvolutionOffset + 4013;
uint constant fourthEvolutionOffset = thirdEvolutionOffset + 1206;

/*///////////////////////////////////////////////////////////////
EVOLUTIONARY STORAGE
//////////////////////////////////////////////////////////////*/

/// @dev The next tokenID to be minted for each of the evolution stages
uint secondEvolutionSupply = 0;
uint thirdEvolutionSupply = 0;
uint fourthEvolutionSupply = 0;

/// @notice The address of the contract permitted to mint evolved Pixelmon.
address public serumContract;

/// @notice Returns true if the user is on the mintlist, if they have not already minted.
mapping(address => bool) public mintlisted;

/*///////////////////////////////////////////////////////////////
AUCTION STORAGE
//////////////////////////////////////////////////////////////*/

/// @notice Starting price of the auction.
uint256 constant public auctionStartPrice = 0.01 ether;

/// @notice Unix Timestamp of the start of the auction.
/// @dev Monday, February 7th 2022, 13:00:00 converted to 1644256800 (GMT -5)
uint256 constant public auctionStartTime = 1644249936;

/// @notice Current mintlist price, which will be updated after the end of the auction phase.
/// @dev We started with signatures, then merkle tree, but landed on mapping to reduce USER gas fees.
uint256 public mintlistPrice = 0.0001 ether;

/*///////////////////////////////////////////////////////////////
METADATA STORAGE
//////////////////////////////////////////////////////////////*/

string public baseURI;

/*///////////////////////////////////////////////////////////////
CONSTRUCTOR
//////////////////////////////////////////////////////////////*/

/// @notice Deploys the contract, minting 330 Pixelmon to the Gnosis Safe and setting the initial metadata URI.
constructor(string memory _baseURI) ERC721("Pixelmon", "PXLMN") {
baseURI = _baseURI;
unchecked {
balanceOf[gnosisSafeAddress] += 330;
totalSupply += 330;
for (uint256 i = 0; i < 330; i++) {
ownerOf[i] = gnosisSafeAddress;
emit Transfer(address(0), gnosisSafeAddress, i);
}
}
}

/*///////////////////////////////////////////////////////////////
METADATA LOGIC
//////////////////////////////////////////////////////////////*/

/// @notice Allows the contract deployer to set the metadata URI.
/// @param _baseURI The new metadata URI.
function setBaseURI(string memory _baseURI) public onlyOwner {
baseURI = _baseURI;
}

function tokenURI(uint256 id) public view override returns (string memory) {
return string(abi.encodePacked(baseURI, id.toString()));
}

/*///////////////////////////////////////////////////////////////
DUTCH AUCTION LOGIC
//////////////////////////////////////////////////////////////*/

/// @notice Calculates the auction price with the accumulated rate deduction since the auction's begin
/// @return The auction price at the current time, or 0 if the deductions are greater than the auction's start price.
function validCalculatedTokenPrice() private view returns (uint) {
uint priceReduction = ((block.timestamp - auctionStartTime) / 10 minutes) * 0.01 ether;
return auctionStartPrice >= priceReduction ? (auctionStartPrice - priceReduction) : 0;
}

/// @notice Calculates the current dutch auction price, given accumulated rate deductions and a minimum price.
/// @return The current dutch auction price
function getCurrentTokenPrice() public view returns (uint256) {
return max(validCalculatedTokenPrice(), 0.01 ether);
}

/// @notice Purchases a Pixelmon NFT in the dutch auction
/// @param mintingTwo True if the user is minting two Pixelmon, otherwise false.
/// @dev balanceOf is fine, team is aware and accepts that transferring out and repurchasing can be done, even by contracts.
function auction(bool mintingTwo) public payable {
if(block.timestamp < auctionStartTime || block.timestamp > auctionStartTime + 1 days) revert AuctionNotStarted();

uint count = mintingTwo ? 2 : 1;
uint price = getCurrentTokenPrice();

if(totalSupply + count > auctionSupply) revert MintedOut();
if(balanceOf[msg.sender] + count > 2) revert MintingTooMany();
if(msg.value < price * count) revert ValueTooLow();

mintingTwo ? _mintTwo(msg.sender) : _mint(msg.sender, totalSupply);
}

/// @notice Mints two Pixelmons to an address
/// @param to Receiver of the two newly minted NFTs
/// @dev errors taken from super._mint
function _mintTwo(address to) internal {
require(to != address(0), "INVALID_RECIPIENT");
require(ownerOf[totalSupply] == address(0), "ALREADY_MINTED");
uint currentId = totalSupply;

/// @dev unchecked because no arithmetic can overflow
unchecked {
totalSupply += 2;
balanceOf[to] += 2;
ownerOf[currentId] = to;
ownerOf[currentId + 1] = to;
emit Transfer(address(0), to, currentId);
emit Transfer(address(0), to, currentId + 1);
}
}


/*///////////////////////////////////////////////////////////////
MINTLIST MINT LOGIC
//////////////////////////////////////////////////////////////*/

/// @notice Allows the contract deployer to set the price of the mintlist. To be called before uploading the mintlist.
/// @param price The price in wei of a Pixelmon NFT to be purchased from the mintlist supply.
function setMintlistPrice(uint256 price) public onlyOwner {
mintlistPrice = price;
}

/// @notice Allows the contract deployer to add a single address to the mintlist.
/// @param user Address to be added to the mintlist.
function mintlistUser(address user) public onlyOwner {
mintlisted[user] = true;
}

/// @notice Allows the contract deployer to add a list of addresses to the mintlist.
/// @param users Addresses to be added to the mintlist.
function mintlistUsers(address[] calldata users) public onlyOwner {
for (uint256 i = 0; i < users.length; i++) {
mintlisted[users[i]] = true;
}
}

/// @notice Purchases a Pixelmon NFT from the mintlist supply
/// @dev We do not check if auction is over because the mintlist will be uploaded after the auction.
function mintlistMint() public payable {
if(totalSupply >= secondEvolutionOffset) revert MintedOut();
if(!mintlisted[msg.sender]) revert NotMintlisted();
if(msg.value < mintlistPrice) revert ValueTooLow();

mintlisted[msg.sender] = false;
_mint(msg.sender, totalSupply);
}

/// @notice Withdraws collected funds to the Gnosis Safe address
function withdraw() public onlyOwner {
(bool success, ) = gnosisSafeAddress.call{value: address(this).balance}("");
require(success);
}

/*///////////////////////////////////////////////////////////////
ROLL OVER LOGIC
//////////////////////////////////////////////////////////////*/

/// @notice Allows the contract deployer to airdrop Pixelmon to a list of addresses, in case the auction doesn't mint out
/// @param addresses Array of addresses to receive Pixelmon
function rollOverPixelmons(address[] calldata addresses) public onlyOwner {
if(totalSupply + addresses.length > secondEvolutionOffset) revert MintedOut();

for (uint256 i = 0; i < addresses.length; i++) {
_mint(msg.sender, totalSupply);
}
}

/*///////////////////////////////////////////////////////////////
EVOLUTIONARY LOGIC
//////////////////////////////////////////////////////////////*/

/// @notice Sets the address of the contract permitted to call mintEvolvedPixelmon
/// @param _serumContract The address of the EvolutionSerum contract
function setSerumContract(address _serumContract) public onlyOwner {
serumContract = _serumContract;
}

/// @notice Mints an evolved Pixelmon
/// @param receiver Receiver of the evolved Pixelmon
/// @param evolutionStage The evolution (2-4) that the Pixelmon is undergoing
function mintEvolvedPixelmon(address receiver, uint evolutionStage) public payable {
if(msg.sender != serumContract) revert UnauthorizedEvolution();

if (evolutionStage == 2) {
if(secondEvolutionSupply >= 4013) revert MintedOut();
_mint(receiver, secondEvolutionOffset + secondEvolutionSupply);
unchecked {
secondEvolutionSupply++;
}
} else if (evolutionStage == 3) {
if(thirdEvolutionSupply >= 1206) revert MintedOut();
_mint(receiver, thirdEvolutionOffset + thirdEvolutionSupply);
unchecked {
thirdEvolutionSupply++;
}
} else if (evolutionStage == 4) {
if(fourthEvolutionSupply >= 33) revert MintedOut();
_mint(receiver, fourthEvolutionOffset + fourthEvolutionSupply);
unchecked {
fourthEvolutionSupply++;
}
} else  {
revert UnknownEvolution();
}
}


/*///////////////////////////////////////////////////////////////
UTILS
//////////////////////////////////////////////////////////////*/

/// @notice Returns the greater of two numbers.
function max(uint256 a, uint256 b) internal pure returns (uint256) {
return a >= b ? a : b;
}

}