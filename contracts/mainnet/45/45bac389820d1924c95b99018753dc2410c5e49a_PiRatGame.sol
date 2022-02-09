/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

// File: contracts/IPiRatGame.sol



pragma solidity ^0.8.0;

interface IPiRatGame {
}
// File: contracts/IBOOTY.sol



pragma solidity ^0.8.0;

interface IBOOTY {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function claimBooty(address owner) external;
    function burnExternal(address from, uint256 amount) external;
    function initTimeStamp(address owner, uint256 timeStamp) external;
    function showPendingClaimable(address owner) external view returns (uint256);
    function showEarningRate(address owner) external view returns (uint256);
    function claimGift(address to) external;
}
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: contracts/IPiRats.sol



pragma solidity ^0.8.0;


interface IPiRats is IERC721 {

    struct CrewCaptain {
        bool isCrew;
        uint8 body;
        uint8 clothes;
        uint8 face;
        uint8 mouth;
        uint8 eyes;
        uint8 head;
        uint8 legendRank;
    }
    
    function paidTokens() external view returns (uint256);
    function maxTokens() external view returns (uint256);
    function mintPiRat(address recipient, uint16 amount, uint256 seed) external;
    function plankPiRat(address recipient, uint16 amount, uint256 seed, uint256 _burnToken) external;
    function getTokenTraits(uint256 tokenId) external view returns (CrewCaptain memory);
    function isCrew(uint256 tokenId) external view returns(bool);
    function getBalanceCrew(address owner) external view returns (uint16);
    function getBalanceCaptain(address owner) external view returns (uint16);
    function getTotalRank(address owner) external view returns (uint256);
    function walletOfOwner(address owner) external view returns (uint256[] memory);
    function getTotalPiratsMinted() external view returns(uint256 totalPiratsMinted);
    function getTotalPiratsBurned() external view returns(uint256 totalPiratsBurned);
    function getTotalPirats() external view returns(uint256 totalPirats);
  
}
// File: contracts/IPOTMTraits.sol



pragma solidity ^0.8.0;


interface IPOTMTraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function selectMintTraits(uint256 seed) external view returns (IPiRats.CrewCaptain memory t);
  function selectPlankTraits(uint256 seed) external view returns (IPiRats.CrewCaptain memory t);
}
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/PiRatGame.sol



pragma solidity ^0.8.0;








////////////////////////////////
//     ╔═╗╦╦═╗╔═╗╔╦╗╔═╗       //
//     ╠═╝║╠╦╝╠═╣ ║ ╚═╗       //
//     ╩  ╩╩╚═╩ ╩ ╩ ╚═╝       //
//     ╔═╗╔═╗  ╔╦╗╦ ╦╔═╗      //
//     ║ ║╠╣    ║ ╠═╣║╣       //
//     ╚═╝╚     ╩ ╩ ╩╚═╝      //
//╔╦╗╔═╗╔╦╗╔═╗╦  ╦╔═╗╦═╗╔═╗╔═╗//
//║║║║╣  ║ ╠═╣╚╗╔╝║╣ ╠╦╝╚═╗║╣ //
//╩ ╩╚═╝ ╩ ╩ ╩ ╚╝ ╚═╝╩╚═╚═╝╚═╝//
////////////////////////////////

contract PiRatGame is IPiRatGame, Ownable, ReentrancyGuard, Pausable {

    uint256 public MINT_PRICE;

    uint256 private maxBootyCost = 5000 ether;

    IPiRats public potm;
    IBOOTY public booty;

    constructor()    
    {
        _pause();
    }

    /// MODIFIERS ///

    modifier requireContractsSet() {
        require(
            address(booty) != address(0) && 
            address(potm) != address(0), "Contracts not set");
      _;
    }

    /// MINTING ///

    function mintPirat(uint16 amount) external payable whenNotPaused nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        uint256 totalPirats = potm.getTotalPirats();
        uint256 maxTokens = potm.maxTokens();
        uint256 paidTokens = potm.paidTokens();
        require(totalPirats + amount <= maxTokens, "All tokens minted");
        require(amount > 0 && amount <= 10, "Invalid mint amount");
        if (totalPirats < paidTokens) {
            require(totalPirats + amount <= paidTokens, "All tokens on-sale already sold");
        } else {
            require(msg.value == 0);
        }
        uint256 totalBootyCost = 0;
        for (uint i = 1; i <= amount; i++) {
            totalBootyCost += mintCost(totalPirats + i);
            }
        if (totalBootyCost > 0) {
            booty.burnExternal(msg.sender, totalBootyCost);
        }
        uint256 randomNumber = _rand(msg.sender);
        potm.mintPiRat(msg.sender, amount, randomNumber);
    }

    function mintCost(uint256 tokenId) public view returns (uint256) {
        if (tokenId <= potm.paidTokens()) return 0;
        if (tokenId <= potm.maxTokens() * 2 / 4) return 1000 ether;  // 50%
        if (tokenId <= potm.maxTokens() * 3 / 4) return 3000 ether;  // 75%
        return maxBootyCost;
    }

    /// WALK THE PLANK ///

    function walkPlank(uint256 tokenId) external whenNotPaused nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        uint16 totalPirats = uint16(potm.getTotalPirats());
        uint256 maxTokens = potm.maxTokens();
        require(totalPirats + 1 <= maxTokens, "All tokens minted");
        uint256 totalBootyCost = 0;
        for (uint i = 1; i <= 1; i++) {
            totalBootyCost += plankCost(totalPirats + i);
            }
        if (totalBootyCost > 0) {
            booty.burnExternal(msg.sender, totalBootyCost);
        }
        uint256 randomNumber = _rand(msg.sender);
        potm.plankPiRat(msg.sender, 1, randomNumber, tokenId);
    }

    function plankCost(uint256 tokenId) public view returns (uint256) {
        if (tokenId <= potm.paidTokens()) return 1500 ether; // 25%
        if (tokenId <= potm.maxTokens() * 2 / 4) return 2500 ether;  // 50%
        if (tokenId <= potm.maxTokens() * 3 / 4) return 4500 ether;  // 75%
        return 7500 ether; // 100%
    }

    /// CLAIMING $BOOTY /// 

    function claimBooty(address owner) public {
        require(tx.origin == msg.sender, "Only EOA");
        booty.claimBooty(owner);
    }

    /// OWNER ///

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setPaused(bool _paused) external requireContractsSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function setContracts(address _booty, address _potm) external onlyOwner {
        booty = IBOOTY(_booty);       
        potm = IPiRats(_potm);
    }

    function setMintPrice(uint256 mintPrice) external onlyOwner {
        MINT_PRICE = mintPrice;
    }

    /// READ ///

    function _rand(address sender) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.basefee, sender)));
    }

    /// SHOW ///

    function showBootyBalance(address owner) public view returns (uint256 bootyBalance) {
        bootyBalance = booty.balanceOf(owner);
    }

    function showClaimableBooty(address owner) public view returns (uint256 pendingBooty) {
        pendingBooty = booty.showPendingClaimable(owner);
    }

    function showEarningRate(address owner) public view returns (uint256 dailyBooty) {
        dailyBooty = booty.showEarningRate(owner);
    }

    function showTotalMinted() public view returns (uint256 totalMinted) {
        totalMinted = potm.getTotalPiratsMinted();
    }

    function showTotalBurned() public view returns (uint256 totalBurned) {
        totalBurned = potm.getTotalPiratsBurned();
    }

    function showTotalSupply() public view returns (uint256 totalSupply) {
        totalSupply = potm.getTotalPirats();
    }

    function showBalanceCrew(address owner) public view returns (uint16 _balanceCrew) {
        _balanceCrew = potm.getBalanceCrew(owner);
    }

    function showBalanceCaptain(address owner) public view returns (uint16 _balanceCaptain) {
        _balanceCaptain = potm.getBalanceCaptain(owner);
    }

    function showTotalRank(address owner) public view returns (uint256 _totalRank) {
        _totalRank = potm.getTotalRank(owner);
    }

    function showIsCrew(uint256 tokenId) public view returns (bool) {
        return potm.isCrew(tokenId);
    }
}
// 0xHooch //