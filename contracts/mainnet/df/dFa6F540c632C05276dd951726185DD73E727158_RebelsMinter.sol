/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol



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

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol



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
     * by making the `nonReentrant` function external, and make it call a
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

// File: rebelsnew.sol


pragma solidity ^0.8.7;




interface RebelsInDisguiseGenesis {
    function transferOwnership(address newOwner) external;
    function ownerMint(uint256 quantity) external;
    function totalSupply() external view returns (uint256);
    function owner() external view returns (address);
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract RebelsMinter is Ownable, ReentrancyGuard, IERC721Receiver {
    RebelsInDisguiseGenesis public rebelsGenesis;

    // cooldowns for free mints
    mapping(address => uint256) public timeAllowedToMint; // cooldown map of user => timestamp#
    uint256 public mintCooldownInSeconds = 60; // 1 minute

    uint256 public maxMintPerTx = 3;

    event FreeMint(address _addr, uint256 _nextTimeAllowed);

    error IllegalMintAmount();
    error NotCurrentlyOwner();
    error OnCooldown(uint256 timeAllowed);

    modifier whilstOwnedByMinter() {
        if (rebelsGenesis.owner() != address(this)) revert NotCurrentlyOwner();
        _;
    }

    constructor(address _rebelsNft) {
        rebelsGenesis = RebelsInDisguiseGenesis(_rebelsNft);
    }

    function canMint(address _addr) public view returns (bool, uint256) {
        return (
            block.timestamp < timeAllowedToMint[_addr],
            timeAllowedToMint[_addr]
        );
    }

    function freeMint(uint256 _amount) public whilstOwnedByMinter nonReentrant {
        if (_amount == 0 || _amount > maxMintPerTx) revert IllegalMintAmount();

        (bool _onCd, uint256 _time) = canMint(msg.sender);
        if (_onCd) revert OnCooldown(_time); // revert and give the time allowed to mint in error message
        timeAllowedToMint[msg.sender] = block.timestamp + mintCooldownInSeconds; // set cooldown

        for (uint256 i = 0; i < _amount; i++) {
            rebelsGenesis.ownerMint(1); // allow 1 only
            uint256 _expectedId = rebelsGenesis.totalSupply();
            rebelsGenesis.transferFrom(address(this), msg.sender, _expectedId);

            emit FreeMint(msg.sender, timeAllowedToMint[msg.sender]);
        }
    }

    function reclaimOwnership() external whilstOwnedByMinter onlyOwner {
        rebelsGenesis.transferOwnership(msg.sender);
    }

    function setMaxMintPerTx(uint256 _amount) external onlyOwner {
        maxMintPerTx = _amount; 
    }

    function setCooldownSeconds(uint256 _seconds) external onlyOwner {
        mintCooldownInSeconds = _seconds;
    }

    // required as we receive the item as a contract
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}