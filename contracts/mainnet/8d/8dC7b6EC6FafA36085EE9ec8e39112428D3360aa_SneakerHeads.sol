// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
//                 -+**+-   +++: :+++.+++++++  ++++++  =+++ .+++==++++++-+++++-       :+++: +++=:++++++= .+++++=  +++++-     -+**+-           //
//               [email protected]@@@@@@# [email protected]@@: @@@**@@@@@@= *@@@@@+ [email protected]@@+:%@@%[email protected]@@@@@%#@@@@@@@:    [email protected]@@# [email protected]@@[email protected]@@@@@@. %@@@@@: [email protected]@@@@@%. -%@@@@@@#          //
//              [email protected]@@# [email protected]@@[email protected]@@@ *@@%[email protected]@@*... [email protected]@@@@@ [email protected]@@#[email protected]@@*.%@@%:[email protected]@@[email protected]@@#    #@@@.:@@@+#@@@-... %@@@@@# [email protected]@@+.%@@=:@@@# [email protected]@@          //
//              %@@@[email protected]@@*@@@@*[email protected]@@[email protected]@@%    [email protected]@%%@@= %@@@*@@@= #@@@:  [email protected]@@# [email protected]@@=   [email protected]@@- @@@#[email protected]@@+    #@@#@@@[email protected]@@# :@@@-*@@@[email protected]@@=          //
//              #@@@#    %@@@@[email protected]@@+#@@@-:. [email protected]@%[email protected]@@ [email protected]@@@@@@: [email protected]@@*:: #@@@[email protected]@@#   [email protected]@@#:#@@@[email protected]@@@::  *@@*#@@* #@@@  @@@% *@@@#               //
//              [email protected]@@@:  [email protected]@@@@#@@#[email protected]@@@@@::@@@.%@@=:@@@@@@%. :@@@@@@[email protected]@@*=%@@*    %@@@@@@@@=%@@@@@% *@@#:@@@[email protected]@@: #@@@- :@@@@:              //
//               %@@@# [email protected]@@[email protected]@@@@[email protected]@@#[email protected]@@[email protected]@@[email protected]@@@@@@.  %@@@[email protected]@@@@@@*:    *@@@+#@@@#*@@@[email protected]@@-#@@+:@@@+ [email protected]@@*   #@@@*              //
//           [email protected]@@@[email protected]@@=*@@@@[email protected]@@%   [email protected]@@@@@@@=*@@@%@@@  *@@@-  [email protected]@@#%@@#     [email protected]@@= %@@@[email protected]@@+   [email protected]@@@@@@@[email protected]@@% :@@@%+==::@@@%              //
//          *@@% :@@@%*@@# @@@@+#@@@:  .%@@#[email protected]@@%[email protected]@@=%@@% [email protected]@@*   #@@@:@@@+    [email protected]@@# *@@@[email protected]@@%   [email protected]@@+*@@@=#@@@:.%@@#[email protected]@@ [email protected]@@#              //
//          %@@#=%@@@[email protected]@@.:@@@#[email protected]@@@##=%@@# [email protected]@@[email protected]@@# @@@*:@@@@##*[email protected]@@[email protected]@@-    %@@@[email protected]@@+#@@@%##[email protected]@@- #@@%[email protected]@@%#@@@+ *@@%=%@@@.              //
//          .#@@@@%=:@@@= [email protected]@@[email protected]@@@@@%%@@%  @@@%#@@@ [email protected]@@+%@@@@@@[email protected]@@# #@@@    *@@@- @@@#[email protected]@@@@@%@@@= [email protected]@@*@@@@@%*-   .*@@@@%+                //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "../libs/Withdraw.sol";
import "../libs/MerkleProof.sol";
import "../libs/SingleMint.sol";
import "./Stocking.sol";
import "../libs/ERC721Mint.sol";

contract SneakerHeads is ERC721Mint, Stocking, SingleMint, MerkleProofVerify, Withdraw {

    /**
    @notice Mint struct for manage the waiting list, only the sales dates are used.
    */
    Mint public waiting;

    /**
    @notice Set default value au the collection.
    */
    constructor(
        string memory baseURI
    )
        ERC721("SneakerHeads", "SNKH")
        Withdraw()
    {
        setMaxSupply(5_000);
        setReserve(50);
        setBaseUri(baseURI);
        setStartAt(1);

        setMint(Mint(1655575200, 2097439200, 2, 2, 0.25 ether, false));
        waiting = Mint(1655582400, 2097439200, 1, 1, 0.25 ether, false);

        withdrawAdd(Part(0xb224811F71c803af1762CC6AEfd995edbfAFBD42, 10));
        withdrawAdd(Part(0x025B188919DC10b42aE5bC85134300628F834E96, 90));
    }

    /**
    @notice Mint for all non-holder with MerkleTree validation
    @dev _type: 1 OG, 2 WL, 3 RAFFLE, 4 WAITING
         _type need to be same like in the MerkleTree.
         _count is used only for OG whitelisted, for all others it is 1
    */
    function mint(
        uint256 _type,
        bytes32[] memory _proof,
        uint16 _count
    ) public payable
        notSoldOut(_count)
        canMint(_count)
        merkleVerify(_proof, keccak256(abi.encodePacked(_msgSender(), _type)))
        nonReentrant
    {
        require(_type > 0 && _type <= 4, "Bad _type value");

        uint256 max = _type == 1 ? 2 : 1;

        if(_type == 4){
            require(waitingIsOpen(), "Waiting list not opened");
        }

        require(balance[_msgSender()] <= max, "Max per wallet limit");

        _mintTokens(_msgSender(), _count);
    }

    /**
    @dev Required override to select the correct baseTokenURI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return getBaseTokenURI();
    }

    /**
    @notice Change the values of the global Mint struct waiting
    @dev Only sales dates are used.
     */
    function waitingIsOpen() public view returns(bool) {
        return waiting.start > 0 && uint64(block.timestamp) >= waiting.start && uint64(block.timestamp) <= waiting.end  && !waiting.paused;
    }

    /**
    @notice Change the values of the global Mint struct waiting
    @dev Only sales dates are used.
     */
    function setWaitingMint(Mint memory _waiting) public onlyOwnerOrAdmins {
        waiting = _waiting;
    }

    /**
    @notice Block transfers while stocking.
    @dev from and to are not used
     */
    function _beforeTokenTransfer(address, address, uint256 tokenId) internal view override {
        require(stocking[tokenId].started == 0 || stockingTransfer == true,"Token Stocking");
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Admins.sol";

contract Withdraw is Admins {
    using SafeMath for uint256;

    /**
    @notice Struct containing the association between the wallet and its share
    @dev The share can be /100 or /1000 or something else like /50
    */
    struct Part {
        address wallet;
        uint256 salePart;
    }

    /**
    @notice Stock the parts of each wallets
    */
    Part[] public parts;

    /**
    @dev Calculation of the divider for the calculation of each part
    */
    uint256 public saleDivider;

    /**
    @notice Add a new wallet in the withdraw process
    @dev this method is only internal, it's not possible to add someone after the contract minting
    */
    function withdrawAdd(Part memory _part) internal {
        parts.push(_part);
        saleDivider += _part.salePart;
    }

    /**
    @notice Run the transfer of all ETH to the wallets with each % part
    */
    function withdrawSales() public onlyOwnerOrAdmins {

        uint256 balance = address(this).balance;
        require(balance > 0, "Sales Balance = 0");

        for (uint8 i = 0; i < parts.length; i++) {
            if (parts[i].salePart > 0) {
                _withdraw(parts[i].wallet, balance.mul(parts[i].salePart).div(saleDivider));
            }
        }

        _withdraw(owner(), address(this).balance);
    }

    /**
    @notice Do a transfer ETH to _address
    */
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Admins.sol";

abstract contract MerkleProofVerify is Admins {
    using MerkleProof for bytes32[];

    /**
    @dev hash of the root of the merkle
    */
    bytes32 public merkleRoot;

    /**
    @dev Used for verify the _proof and the _leaf
        The _leaf need to be calculated by the contract itself
        The _proof is calculated by the server, not by the contract
     */
    modifier merkleVerify(bytes32[] memory _proof, bytes32 _leaf){
        merkleCheck(_proof, _leaf);
        _;
    }

    /**
    @notice Verify the proof of the leaf.
    @dev (see @dev merkleVerify)
    */
    function merkleCheck(bytes32[] memory _proof, bytes32 _leaf) public view {
        require(_proof.verify(merkleRoot, _leaf), "Proof not valid");
    }

    /**
    @dev onlyOwner can change the root of the merkle.this
        Change root need to be done only if there is no pending tx during the mint.
    */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwnerOrAdmins {
        merkleRoot = _merkleRoot;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interface/ISingleMint.sol";
import "./Admins.sol";

abstract contract SingleMint is ISingleMint, Admins {

    /**
    @notice Stock all data about the minting process: sales date, price, max per tx, max per wallet, pause.
    */
    Mint public mints;

    /**
    @notice Stock the count of token minted by a wallet.
    @dev Only used if the max par wallet is > 0.
    */
    mapping(address => uint16) balance;

    /**
    @notice Verify if the minting process is available for a wallet and a token count
    @dev Does not check if it's soldout, only if the wallet can mint (good time, good price, no max per tx/wallet)
    @dev add ~13.000 gas if max per wallet === 0
         add ~32.000 gas if max per wallet > 0 first time
         add ~20.000 gas if max per wallet > 0 next time
    */
    modifier canMint(uint16 _count) virtual {

        require(mintIsOpen(), "Mint not open");
        require(_count <= mints.maxPerTx, "Max per tx limit");
        require(msg.value >= mintPrice(_count), "Value limit");

        if(mints.maxPerWallet > 0){
            require(balance[_msgSender()] + _count <= mints.maxPerWallet, "Max per wallet limit");
            balance[_msgSender()] += _count;
        }
        _;
    }

    /**
    @dev Only owner can update the Mint data: sales date, price, max per tx, max per wallet, pause.
    */
    function setMint(Mint memory _mint) public override onlyOwnerOrAdmins {
        mints = _mint;
        emit EventSaleChange(_mint);
    }

    /**
    @notice Shortcut for change only the pause variable of the Mint struct
    @dev Only owner can pause the mint
    */
    function pauseMint(bool _pause) public override onlyOwnerOrAdmins {
        mints.paused = _pause;
    }

    /**
    @notice Check if the mint process is open, by checking the block.timestamp
    @return True if sales date are between Mint.start and Mint.end
    */
    function mintIsOpen() public view override returns(bool){
        return mints.start > 0 && uint64(block.timestamp) >= mints.start && uint64(block.timestamp) <= mints.end  && !mints.paused;
    }

    /**
    @notice Calculation of the current token price
    */
    function mintPrice(uint256 _count) public view virtual override returns (uint256){
        return mints.price * _count;
    }

    /**
    @return The amount of token minted by the _wallet
    */
    function mintBalance(address _wallet) public view override returns(uint16){
        return balance[_wallet];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libs/Admins.sol";
import "../libs/ERC721.sol";

/**
    @dev based on Moonbirds ERC721A Nested Contract
*/
abstract contract Stocking is ERC721, Admins {

    /**
    @dev Emitted when a Sneaker Heads begins stocking.
     */
    event Stocked(uint256 indexed tokenId);

    /**
    @dev Emitted when a Sneaker Heads stops stocking; either through standard means or
    by expulsion.
     */
    event UnStocked(uint256 indexed tokenId);

    /**
    @dev Emitted when a Sneaker Heads is expelled from the stock.
     */
    event Expelled(uint256 indexed tokenId);

    /**
    @notice Whether stocking is currently allowed.
    @dev If false then stocking is blocked, but unstocking is always allowed.
     */
    bool public stockingOpen = false;

    /**
    @dev MUST only be modified by safeTransferWhileStocking(); if set to 2 then
    the _beforeTokenTransfer() block while stocking is disabled.
     */
    bool internal stockingTransfer;

    uint64 internal stockingStepFirst = 30 days;
    uint64 internal stockingStepNext = 60 days;
    /**
    @dev data for each token stoked
     */
    struct StockingToken {
        uint64 started;
        uint64 total;
        uint64 level;
    }

    /**
    @dev tokenId to stocking data.
     */
    mapping(uint256 => StockingToken) internal stocking;

    /**
    @notice Toggles the `stockingOpen` flag.
     */
    function setStockingOpen(bool open) external onlyOwnerOrAdmins {
        stockingOpen = open;
    }

    /**
    @notice Returns the length of time, in seconds, that the Sneaker has
    stocking.
    @dev stocking is tied to a specific Sneaker Heads, not to the owner, so it doesn't
    reset upon sale.
    @return stocked Whether the Sneaker Heads is currently stocking. MAY be true with
    zero current stocking if in the same block as stocking began.
    @return current Zero if not currently stocking, otherwise the length of time
    since the most recent stocking began.
    @return total Total period of time for which the Sneaker Heads has stocking across
    its life, including the current period.
    @return level the current level of the token
     */
    function stockingPeriod(uint256 tokenId) public view returns (bool stocked, uint64 current, uint64 total, uint64 level)
    {
        stocked = stocking[tokenId].started != 0;
        current = stockingCurrent(tokenId);
        level = stockingLevel(tokenId);
        total = current + stocking[tokenId].total;
    }

    function stockingCurrent(uint256 tokenId) public view returns(uint64){
        return stocking[tokenId].started != 0 ? uint64(block.timestamp) - stocking[tokenId].started : 0;
    }

    function stockingLevel(uint256 tokenId) public view returns(uint64){

        uint64 level = stocking[tokenId].level;

        if(level == 0 ){
            return
                stockingCurrent(tokenId) / stockingStepFirst >= 1 ?
                ((stockingCurrent(tokenId) - stockingStepFirst) / stockingStepNext) + 1 :
                0;
        }

        return level + (stockingCurrent(tokenId) / stockingStepNext);
    }

    function setStockingStep(uint64 _durationFirst, uint64 _durationNext) public onlyOwnerOrAdmins {
        stockingStepFirst = _durationFirst;
        stockingStepNext = _durationNext;
    }

    /**
    @notice Changes the Sneaker Heads lock status for a token
    @dev If the stocking is disable, the unlock is available
    */
    function toggleStocking(uint256 tokenId) internal {

        require(
            ownerOf(tokenId) == _msgSender() ||
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(ownerOf(tokenId), _msgSender()
            ), "Not approved or owner");

        if (stocking[tokenId].started == 0) {
            storeToken(tokenId);
        } else {
            destockToken(tokenId);
        }
    }

    /**
    @notice Lock the token
    */
    function storeToken(uint256 tokenId) internal {
        require(stockingOpen, "Stocking closed");
        stocking[tokenId].started = uint64(block.timestamp);
        emit Stocked(tokenId);
    }

    /**
    @notice Unlock the token
    */
    function destockToken(uint256 tokenId) internal {
        stocking[tokenId].level = stockingLevel(tokenId);
        stocking[tokenId].total += stockingCurrent(tokenId);
        stocking[tokenId].started = 0;
        emit UnStocked(tokenId);
    }

    /**
    @notice Changes the Sneaker Heads stocking status for many tokenIds
     */
    function toggleStocking(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            toggleStocking(tokenIds[i]);
        }
    }
    /**
    @notice Transfer a token between addresses while the Sneaker Heads is minting, thus not resetting the stocking period.
     */
    function safeTransferWhileStocking(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(ownerOf(tokenId) == _msgSender(), "Only owner");
        stockingTransfer = true;
        safeTransferFrom(from, to, tokenId);
        stockingTransfer = false;
    }


    /**
    @notice Only owner ability to expel a Sneaker Heads from the stock.
    @dev As most sales listings use off-chain signatures it's impossible to
    detect someone who has stocked and then deliberately undercuts the floor
    price in the knowledge that the sale can't proceed. This function allows for
    monitoring of such practices and expulsion if abuse is detected, allowing
    the undercutting sneaker to be sold on the open market. Since OpenSea uses
    isApprovedForAll() in its pre-listing checks, we can't block by that means
    because stocking would then be all-or-nothing for all of a particular owner's
    Sneaker Heads.
     */
    function expelFromStock(uint256 tokenId) external onlyOwnerOrAdmins {
        require(stocking[tokenId].started != 0, "Not stocked");
        destockToken(tokenId);
        emit Expelled(tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721.sol";
import "./Admins.sol";

abstract contract ERC721Mint is ERC721, Admins, ReentrancyGuard {

    /**
    @notice Max supply available for this contract
    */
    uint32 public MAX_SUPPLY;

    /**
    @notice Amount of token reserved for team project/giveaway/other
    */
    uint32 public RESERVE;

    /**
    @notice Tracker for the total minted
    */
    uint32 public mintTracked;

    /**
    @notice Tracker for the total burned
    */
    uint32 public burnedTracker;

    /**
    @notice The number of the First token Id
    */
    uint8 public START_AT = 1;

    /**
    @notice The base URI for metadata for all tokens
    */
    string public baseTokenURI;


    /**
    @dev Verify if the contract is soldout
    */
    modifier notSoldOut(uint256 _count) {
        require(mintTracked + uint32(_count) <= MAX_SUPPLY, "Sold out!");
        _;
    }


    /**
    @notice Set the max supply of the contract
    @dev only internal, can't be change after contract deployment
    */
    function setMaxSupply(uint32 _maxSupply) internal {
        MAX_SUPPLY = _maxSupply;
    }

    /**
    @notice Set the amount of reserve tokens
    @dev only internal, can't be change after contract deployment
    */
    function setReserve(uint32 _reserve) internal {
        RESERVE = _reserve;
    }

    /**
    @notice Set the number of the first token
    @dev only internal, can't be change after contract deployment
    */
    function setStartAt(uint8 _start) internal {
        START_AT = _start;
    }

    /**
    @notice Set the base URI for metadata of all tokens
    */
    function setBaseUri(string memory baseURI) public onlyOwnerOrAdmins {
        baseTokenURI = baseURI;
    }

    /**
    @notice Get all tokenIds for a wallet
    @dev This method can revert if the mintedTracked is > 30000.
        it is not recommended to call this method from another contract.
    */
    function walletOfOwner(address _owner) public view virtual returns (uint32[] memory) {
        uint256 count = balanceOf(_owner);
        uint256 key = 0;
        uint32[] memory tokensIds = new uint32[](count);

        for (uint32 tokenId = START_AT; tokenId < mintTracked + START_AT; tokenId++) {
            if (_owners[tokenId] != _owner) continue;
            if (key == count) break;

            tokensIds[key] = tokenId;
            key++;
        }
        return tokensIds;
    }

    /**
    @notice Get the base URI for metadata of all tokens
    */
    function getBaseTokenURI() internal view returns(string memory){
        return baseTokenURI;
    }

    /**
    @notice Replace ERC721Enumerable.totalSupply()
    @return The total token available.
    */
    function totalSupply() public view returns (uint32) {
        return mintTracked - burnedTracker;
    }

    /**
    @notice Mint the next token
    @return the tokenId minted
    */
    function _mintToken(address wallet) internal returns(uint256){
        uint256 tokenId = uint256(mintTracked + START_AT);
        mintTracked += 1;
        _safeMint(wallet, tokenId);
        return tokenId;
    }

    /**
    @notice Mint the next tokens
    */
    function _mintTokens(address wallet, uint32 _count) internal{
        for (uint32 i = 0; i < _count; i++) {
            _mintToken(wallet);
        }
    }

    /**
    @notice Mint the tokens reserved for the team project
    @dev the tokens are minted to the owner of the contract
    */
    function reserve(uint32 _count) public virtual onlyOwnerOrAdmins {
        require(mintTracked + _count <= RESERVE, "Exceeded RESERVE_NFT");
        require(mintTracked + _count <= MAX_SUPPLY, "Sold out!");
        _mintTokens(_msgSender(), _count);
    }

    /**
    @notice Burn the token if is approve or owner
    */
    function burn(uint256 _tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not owner nor approved");
        burnedTracker += 1;
        _burn(_tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Admins is Ownable{

    mapping(address => bool) private admins;

    /**
    @dev Set the wallet address who can pass the onlyAdmin modifier
    **/
    function setAdminAddress(address _admin, bool _active) public onlyOwner {
        admins[_admin] = _active;
    }

    /**
    @notice Check if the sender is owner() or admin
    **/
    modifier onlyOwnerOrAdmins() {
        require(admins[_msgSender()] == true || owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

/**
 * @title ERC-721 Non-Fungible Token Standard, optional lock extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface ISingleMint {

    /**
    @notice Stock all data about the minting process: sales date, price, max per tx, max per wallet, pause.
    */
    struct Mint {
        uint64 start;
        uint64 end;
        uint16 maxPerWallet;
        uint16 maxPerTx;
        uint256 price;
        bool paused;
    }

    /**
    @dev Emitted when the Mint data are changed
    */
    event EventSaleChange(Mint sale);

    /**
    @notice Set new values for Mint struct
    */
    function setMint(Mint memory _sale) external;

    /**
    @notice Shortcut for change only the pause variable of the Mint struct
    */
    function pauseMint(bool _pause) external;

    /**
    @notice Check if the mint process is open, by checking the block.timestamp
    */
    function mintIsOpen() external returns(bool);

    /**
    @notice Calculation of the current token price
    */
    function mintPrice(uint256 _count) external returns(uint256);

    /**
    @return The amount of token minted by the _wallet
    */
    function mintBalance(address _wallet) external view returns(uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint32 => address) internal _owners;

    // Mapping owner address to token count
    mapping(address => uint32) private _balances;

    // Mapping from token ID to approved address
    mapping(uint32 => address) internal _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return uint256(_balances[owner]);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[uint32(tokenId)];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[uint32(tokenId)];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
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
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[uint32(tokenId)] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[uint32(tokenId)] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[uint32(tokenId)];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
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
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[uint32(tokenId)] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[uint32(tokenId)] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}