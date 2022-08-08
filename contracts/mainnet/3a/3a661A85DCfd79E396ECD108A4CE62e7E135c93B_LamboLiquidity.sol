/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

// File: contracts/IOpenseaStorefront.sol



pragma solidity ^0.8.7;

interface IOpenseaStorefront {
    function balanceOf(address tokenOwner, uint256 tokenId)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes memory _data
    ) external;
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


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts/LamboLiquidity.sol



pragma solidity ^0.8.7;




contract LamboLiquidity is Ownable, Pausable {
    IOpenseaStorefront os = IOpenseaStorefront(0x495f947276749Ce646f68AC8c248420045cb7b5e);

    uint256 migrateTilToken = 0xC0C8D886B92A811E8E41CB6AB5144E44DBBFBFA3000000000015C00000000001;
    uint256 migrateFromToken = 0xC0C8D886B92A811E8E41CB6AB5144E44DBBFBFA30000000000181A0000000001;
    uint256 getSalePrice = .012 ether;
    uint256 getBuyPrice = .02 ether;

    mapping(address => uint256) claimablePunk;

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function sellPunks(uint256[] memory osTokenIds) external whenNotPaused {
        uint256 issuedRefund = getSalePrice * osTokenIds.length;
        require(address(this).balance >= issuedRefund, "not enough to issue refund");

        for(uint256 i = 0; i < osTokenIds.length; i++) {
            uint256 osTokenId = osTokenIds[i];
            require(osTokenId >= migrateFromToken, "not a valid LEP");
            require(osTokenId <= migrateTilToken, "not a valid LEP");
            os.safeTransferFrom(msg.sender, owner(), osTokenId, 1, '');        
        }
        msg.sender.call{value: issuedRefund}('');
        emit SoldPunk(osTokenIds);
    }

    function claimPunks(uint256[] memory osTokenIds) external whenNotPaused {
        require(claimablePunk[msg.sender] >= osTokenIds.length, "too many punk");
        claimablePunk[msg.sender] -= osTokenIds.length;

        for(uint256 i = 0; i < osTokenIds.length; i++) {
            uint256 osTokenId = osTokenIds[i];
            require(osTokenId >= migrateFromToken, "not a valid LEP");
            require(osTokenId <= migrateTilToken, "not a valid LEP");
            os.safeTransferFrom(owner(), msg.sender, osTokenId, 1, '');
        }
        emit BoughtPunk(osTokenIds);

    }

    function setOS(address _newOS) external onlyOwner {
        os = IOpenseaStorefront(_newOS);
    }
    
    function setMigrateTilToken(uint256 newMigrateTilToken) external onlyOwner {
        migrateTilToken = newMigrateTilToken;
    }

    function getClaimablePunk(address _user) external view returns (uint256){
        return claimablePunk[_user];
    }

    function setBuySellPrice(uint256 buy, uint256 sell) external onlyOwner {
        getBuyPrice = buy;
        getSalePrice = sell;
    }

    event BoughtPunk(uint256[] amount);
    event SoldPunk(uint256[] amount);

    receive() payable external whenNotPaused {
        claimablePunk[msg.sender] += msg.value / getBuyPrice;
        uint256 change = msg.value % getBuyPrice;

        if(change != 0) {
            msg.sender.call{value: change}('');
        }
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(0x41538872240Ef02D6eD9aC45cf4Ff864349D51ED).transfer(amount);
    }
}