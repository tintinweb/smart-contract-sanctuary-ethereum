// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IRandomizer {
    function randomMod(uint256,uint256,uint256) external returns (uint256);
}

interface ILandStaker {
    function getStakedBalance(address, uint256) external returns (uint256);
}

interface IIngameItems {
    function addGemToPlayer(uint256, address) external;
    function addTotemToPlayer(uint256, address) external;
    function addGhostToPlayer(uint256, address) external;
}

contract Battles is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private counter;
    uint256 constant public DECIMALS_18 = 1e18;
    IERC20 public paymentToken;
    IERC721 public piratesContract;
    IERC1155 public landContract;
    ILandStaker public landStakingContract;
    IRandomizer public randomizer;
    IIngameItems public ingameItems;
    uint256 public stakingCostInEtherUnits;

    event BattleAdded(uint256 battleId);

    struct Battle {
        uint256 battleId; 
        bool open; // open to add pirates
        bool started;
        bool ended;
        uint256 startTime;
        uint256 endTime;
        EnumerableSet.AddressSet players;
        EnumerableSet.AddressSet xbmfWinners;
        EnumerableSet.AddressSet gemWinners;
        EnumerableSet.AddressSet totemWinners;
        EnumerableSet.AddressSet ghostWinners;
        mapping(address => EnumerableSet.UintSet) piratesByPlayer;
        mapping(uint256 => address) pirateOwners;
        uint256 rewardsInEtherUnits;
        uint256 numXbmfPrizes;
        uint256 numGemPrizes;
        uint256 numGhostPrizes;
        uint256 numTotemPrizes;
        uint256 stakedPiratesCount;
        address[] tickets;
    }

    mapping (uint256 => Battle) battles;

    function addXBMF(uint256 amount) external onlyOwner {
        paymentToken.transferFrom(msg.sender, address(this), amount);
    }

    function setPaymentToken(address _address) external onlyOwner {
        paymentToken = IERC20(_address);
    }

    function setStakingCost(uint256 _stakingCostInEtherUnits) external onlyOwner {
        stakingCostInEtherUnits = _stakingCostInEtherUnits;
    }

    function setLandStakingContract(address _address) external onlyOwner {
        landStakingContract = ILandStaker(_address);
    }

    function setIngameItemsContract(address _address) external onlyOwner {
        ingameItems = IIngameItems(_address);
    }

    function setRandomizerContract(address _address) external onlyOwner {
        randomizer = IRandomizer(_address);
    }

    function setPiratesContract(address _address) external onlyOwner {
        piratesContract = IERC721(_address);
    }

    function setLandContract(address _address) external onlyOwner {
        landContract = IERC1155(_address);
    }

    function addBattle(uint256 _startTime, uint256 _endTime, uint256 _rewardsInEtherUnits, uint256 _numXBmfPrizes, uint256 _numGemPrizes,
        uint256 _numGhostPrizes, uint256 _numTotemPrizes
    ) external onlyOwner {
        Battle storage battle = battles[counter.current()];
        battle.battleId = counter.current();
        battle.started = false;
        battle.ended = false;
        battle.open = false;
        battle.startTime = _startTime;
        battle.endTime = _endTime;
        battle.rewardsInEtherUnits = _rewardsInEtherUnits;
        battle.numXbmfPrizes = _numXBmfPrizes;
        battle.numGemPrizes = _numGemPrizes;
        battle.numGhostPrizes = _numGhostPrizes;
        battle.numTotemPrizes = _numTotemPrizes;

        emit BattleAdded(counter.current());

        counter.increment();
    }

    function getBattleData(uint256 battleId) public view returns (uint256[] memory) {
        Battle storage battle = battles[battleId];
        uint256[] memory data = new uint256[](10);
        data[0] = battle.battleId;
        data[1] = battle.started ? 1 : 0;
        data[2] = battle.ended ? 1 : 0;
        data[3] = battle.startTime;
        data[4] = battle.endTime;
        data[5] = battle.rewardsInEtherUnits;
        data[6] = battle.numXbmfPrizes;
        data[7] = battle.numGemPrizes;
        data[8] = battle.numGhostPrizes;
        data[9] = battle.numTotemPrizes;
        return data;
    }

    function hasLand(address _address) internal returns (bool){
        return landContract.balanceOf(_address, 0) > 0 ||
            landContract.balanceOf(_address, 1) > 0 ||
            landContract.balanceOf(_address, 2) > 0 ||
            landContract.balanceOf(_address, 3) > 0 ||
            landContract.balanceOf(_address, 4) > 0 ||
            landContract.balanceOf(_address, 5) > 0 ||
            landContract.balanceOf(_address, 6) > 0 ||
            landContract.balanceOf(_address, 7) > 0 ||
            landStakingContract.getStakedBalance(_address, 0) > 0 ||
            landStakingContract.getStakedBalance(_address, 1) > 0 ||
            landStakingContract.getStakedBalance(_address, 2) > 0 ||
            landStakingContract.getStakedBalance(_address, 3) > 0 ||
            landStakingContract.getStakedBalance(_address, 4) > 0 ||
            landStakingContract.getStakedBalance(_address, 5) > 0 ||
            landStakingContract.getStakedBalance(_address, 6) > 0 ||
            landStakingContract.getStakedBalance(_address, 7) > 0;
    }

    function addMultiplePiratesToBattleWithLand(uint256 battleId, uint256[] calldata pirateIds) external {
        require(
            battles[battleId].started == false, "Can't add pirates to a started Battle"
        );
        require(
            hasLand(msg.sender), "You need land or skull caves to add a pirate for free"
        );
        for (uint i = 0; i < pirateIds.length; i++){
            addPirateToBattle(battleId, pirateIds[i]);
        }
    }

    function addMultiplePiratesToBattleWithXBMF(uint256 battleId, uint256[] calldata pirateIds, uint256 paymentAmountInEthUnits) external {
        require(
            battles[battleId].started == false, "Can't add pirates to a started Battle"
        );
        require(
            paymentAmountInEthUnits == stakingCostInEtherUnits.mul(pirateIds.length),
            "wrong payment amount"
        );
        require(
            paymentToken.transferFrom(msg.sender, address(this), paymentAmountInEthUnits.mul(DECIMALS_18)),
            "Transfer of payment token could not be made"
        );
        for (uint i = 0; i < pirateIds.length; i++){
            addPirateToBattle(battleId, pirateIds[i]);
        }
    }

    // add pirate to battle:
    // player either pays with xbmf or has a land nft
    // Require approval since function will move the pirate nft
    function addPirateToBattle(uint256 battleId, uint256 pirateId) public { //change to internal _
        // TODO: check if pirate is upgraded

        // require owns pirate
        Battle storage battle = battles[battleId];
        battle.pirateOwners[pirateId] = msg.sender;
        // Add player
        if (!battle.players.contains(msg.sender)) {
             battle.players.add(msg.sender);
        }
        // Add pirate Id mapped to player id
        if (!battle.piratesByPlayer[msg.sender].contains(pirateId)){
            battle.piratesByPlayer[msg.sender].add(pirateId);
        }
        
        // transfer pirate NFT from player to contract
        piratesContract.transferFrom(msg.sender, address(this), pirateId);
        battle.stakedPiratesCount++;
    }

    function removePirateFromBattle(uint battleId, uint256 pirateId) external {
        //check ownership
        Battle storage battle = battles[battleId];
        // remove from players list too? -> use enumerable set
        // if its the last pirate by address, remove address too
        require(battle.piratesByPlayer[msg.sender].contains(pirateId), "Sender doesn't own pirate");
        piratesContract.transferFrom(address(this), msg.sender, pirateId);
        battle.piratesByPlayer[msg.sender].remove(pirateId);
        battle.stakedPiratesCount--;
    }

    function removeAllPiratesFromBattleForPlayer(uint battleId) external { 
       EnumerableSet.UintSet storage pirates =  battles[battleId].piratesByPlayer[msg.sender];
       while (pirates.length() > 0){
           require(battles[battleId].piratesByPlayer[msg.sender].contains(pirates.at(0)), "Sender doesn't own pirate");
           piratesContract.transferFrom(address(this), msg.sender, pirates.at(0));
           pirates.remove(pirates.at(0));
           battles[battleId].stakedPiratesCount--;
       }
    }

    function openBattle(uint256 battleId, bool value) external onlyOwner {
       battles[battleId].open = value;
    }

    function startBattle(uint256 battleId) external onlyOwner {
        battles[battleId].open = false;
        battles[battleId].started = true;
    }

    function endBattle(uint256 battleId) external onlyOwner {
        battles[battleId].ended = true;
        _createTicketList(battleId);
        _pickXbmfWinners(battleId, 0, 0, 0);
        _pickGemWinners(battleId, 0, 1000, 1000);
        _pickTotemWinners(battleId, 0, 2000, 2000);
        _pickGhostWinners(battleId, 0, 3000, 3000);
    }

    function ownsLandType(address _address, uint256 landType) internal returns (bool){
        return landContract.balanceOf(_address, landType) > 0 || landStakingContract.getStakedBalance(_address, landType) > 0;
    }

    function _createTicketList(uint256 battleId) internal {
        // get all players
         for (uint256 i = 0; i < battles[battleId].players.length(); i++) {
            address player = battles[battleId].players.at(i);
            if (ownsLandType(player, 6)) {
                battles[battleId].tickets.push(player);
            }
            if (ownsLandType(player, 7)) {
                battles[battleId].tickets.push(player);
                battles[battleId].tickets.push(player); 
            }
            for (uint256 j = 0; j < battles[battleId].piratesByPlayer[player].length(); j++) {
                battles[battleId].tickets.push(player);
            }
         }
         //console.log("tickets length", battles[battleId].tickets.length);
         //console.log("tickets staked nfts length", battles[battleId].stakedPiratesCount);
    }

    function claimXbmfPrize(uint256 battleId) external {
        bool winner = false;
        for (uint256 i = 0; i < battles[battleId].xbmfWinners.length(); i++) {
            if (battles[battleId].xbmfWinners.at(i) == msg.sender){
                winner = true;
            }
        }
        paymentToken.transfer(msg.sender, battles[battleId].rewardsInEtherUnits.mul(DECIMALS_18));
    }

    function isXbmfWinner(uint256 battleId, address _address) external view returns (bool) {
        bool winner = false;
        for (uint256 i = 0; i < battles[battleId].xbmfWinners.length(); i++) {
            if (battles[battleId].xbmfWinners.at(i) == _address){
                winner = true;
            }
        }
        return winner;
    }

    function getXbmfWinners(uint256 battleId) public view returns (address[] memory){
        if (!battles[battleId].ended){
            return new address[](0);
        }
        uint256 length = battles[battleId].xbmfWinners.length();
        address[] memory arr = new address[](length);//3 winners
        for (uint256 i = 0; i < length; i++){
            arr[i] = battles[battleId].xbmfWinners.at(i);
        }
        return arr;
    }

    function getGemWinners(uint256 battleId) public view returns (address[] memory){
        if (!battles[battleId].ended){
            return new address[](0);
        }
        uint256 length = battles[battleId].gemWinners.length();
        address[] memory arr = new address[](length);
        for (uint256 i = 0; i < length; i++){
            arr[i] = battles[battleId].gemWinners.at(i);
        }
        return arr;
    }

    function getTotemWinners(uint256 battleId) public view returns (address[] memory){
        if (!battles[battleId].ended){
            return new address[](0);
        }
        uint256 length = battles[battleId].totemWinners.length();
        address[] memory arr = new address[](length);
        for (uint256 i = 0; i < length; i++){
            arr[i] = battles[battleId].totemWinners.at(i);
        }
        return arr;
    }

    function getGhostWinners(uint256 battleId) public view returns (address[] memory){
        if (!battles[battleId].ended){
            return new address[](0);
        }
        uint256 length = battles[battleId].ghostWinners.length();
        address[] memory arr = new address[](length);
        for (uint256 i = 0; i < length; i++){
            arr[i] = battles[battleId].ghostWinners.at(i);
        }
        return arr;
    }

    // number of players must be > number of prizes
    function _pickXbmfWinners(uint256 battleId, uint256 count, uint256 nonce, uint256 seed) internal {
        Battle storage battle = battles[battleId];
        while (count < battle.numXbmfPrizes){
            address candidate = battle.tickets[randomizer.randomMod(seed, nonce, battle.tickets.length)];
            if (!battle.xbmfWinners.contains(candidate)){
                battle.xbmfWinners.add(candidate);
                count++;
            }
            nonce++;
        }
    }

    function _pickGemWinners(uint256 battleId, uint256 count, uint256 nonce, uint256 seed) internal {
        while (count < battles[battleId].numGemPrizes){
            address winner = battles[battleId].tickets[randomizer.randomMod(seed, nonce, battles[battleId].tickets.length)];
            ingameItems.addGemToPlayer(battleId, winner);
            battles[battleId].gemWinners.add(winner);
            //battles[battleId].winsByPlayer[winner]["gem"]++;
            count++;
            nonce++;
        }
    }

    function _pickTotemWinners(uint256 battleId, uint256 count, uint256 nonce, uint256 seed) internal {
        while (count < battles[battleId].numTotemPrizes){
            address winner = battles[battleId].tickets[randomizer.randomMod(seed, nonce, battles[battleId].tickets.length)];
            ingameItems.addTotemToPlayer(battleId, winner);
            battles[battleId].totemWinners.add(winner);
            //battles[battleId].winsByPlayer[winner]["totem"]++;
            count++;
            nonce++;
        }
    }

    function _pickGhostWinners(uint256 battleId, uint256 count, uint256 nonce, uint256 seed) internal {
        while (count < battles[battleId].numGhostPrizes){
            address winner = battles[battleId].tickets[randomizer.randomMod(seed, nonce, battles[battleId].tickets.length)];
            ingameItems.addGhostToPlayer(battleId, winner);
            battles[battleId].ghostWinners.add(winner);
            //battles[battleId].winsByPlayer[winner]["ghost"]++;
            count++;
            nonce++;
        }
    }

    function getStakedPiratesForPlayer(uint256 battleId, address playerAddress) view public returns(uint256[] memory) {
        EnumerableSet.UintSet storage pirates = battles[battleId].piratesByPlayer[playerAddress];
        uint256[] memory arr = new uint256[](pirates.length());
        for (uint256 i = 0; i < pirates.length(); i++){
            arr[i] = pirates.at(i);
        }
        return arr;
    }

    function getAllStakedPiratesForBattle(uint256 battleId) view public returns(uint256[] memory) {
        EnumerableSet.AddressSet storage players = battles[battleId].players;
        uint256[] memory arr = new uint256[](battles[battleId].stakedPiratesCount);
        uint256 count = 0;
        for (uint256 i = 0; i < players.length(); i++){
            EnumerableSet.UintSet storage pirates = battles[battleId].piratesByPlayer[players.at(i)];
            for (uint256 j = 0; j < pirates.length(); j++){
                arr[count] = pirates.at(j);
                count++;
            }
        }
        return arr;
    }
    
    // Withdraw

    function withdraw() public payable onlyOwner {
        uint256 bal = address(this).balance;
        require(payable(msg.sender).send(bal));
    }

    function withdrawPaymentToken() public payable onlyOwner {
        uint256 bal = paymentToken.balanceOf(address(this));
        paymentToken.transfer(msg.sender, bal);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
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