// SPDX-License-Identifier: MIT

/*
                8888888888 888                   d8b
                888        888                   Y8P
                888        888
                8888888    888 888  888 .d8888b  888 888  888 88888b.d88b.
                888        888 888  888 88K      888 888  888 888 "888 "88b
                888        888 888  888 "Y8888b. 888 888  888 888  888  888
                888        888 Y88b 888      X88 888 Y88b 888 888  888  888
                8888888888 888  "Y88888  88888P' 888  "Y88888 888  888  888
                                    888
                               Y8b d88P
                                "Y88P"
                888b     d888          888              .d8888b.                888
                8888b   d8888          888             d88P  Y88b               888
                88888b.d88888          888             888    888               888
                888Y88888P888  .d88b.  888888  8888b.  888         .d88b.   .d88888 .d8888b
                888 Y888P 888 d8P  Y8b 888        "88b 888  88888 d88""88b d88" 888 88K
                888  Y8P  888 88888888 888    .d888888 888    888 888  888 888  888 "Y8888b.
                888   "   888 Y8b.     Y88b.  888  888 Y88b  d88P Y88..88P Y88b 888      X88
                888       888  "Y8888   "Y888 "Y888888  "Y8888P88  "Y88P"   "Y88888  88888P'
*/

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

pragma solidity ^0.8.0;

interface IMintPass {
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

interface IToken {
    function add(address wallet, uint256 amount) external;
}

contract MetaGodsMintPassStaking is Ownable, Pausable {

    mapping(address => uint256) public numberOfStakedPassesByWallet;
    mapping(address => uint256) public lastClaimDateByWallet;

    address public mintPassContractAddress;
    address public godTokenContractAddress;

    uint256 public mintPassYield;

    function stakePasses(uint256 amount_) external whenNotPaused {

        require(IMintPass(mintPassContractAddress).balanceOf(msg.sender, 0) >= amount_, "TOO MANY");

        if (numberOfStakedPassesByWallet[msg.sender] != 0) {
            IToken(godTokenContractAddress).add(msg.sender, calculateMetaPassesYield(msg.sender));
        }

        lastClaimDateByWallet[msg.sender] = block.timestamp;

        numberOfStakedPassesByWallet[msg.sender] += amount_;

        IMintPass(mintPassContractAddress).safeTransferFrom(msg.sender, address(this), 0, amount_, "");
    }

    function unStakePasses(uint256 amount_) external whenNotPaused {

        require(amount_ <= numberOfStakedPassesByWallet[msg.sender], "TOO MANY");

        IToken(godTokenContractAddress).add(msg.sender, calculateMetaPassesYield(msg.sender));

        lastClaimDateByWallet[msg.sender] = block.timestamp;

        numberOfStakedPassesByWallet[msg.sender] -= amount_;

        IMintPass(mintPassContractAddress).safeTransferFrom(address(this), msg.sender, 0, amount_, "");
    }

    function claimPassesYield(address wallet_) external whenNotPaused {

        IToken(godTokenContractAddress).add(wallet_, calculateMetaPassesYield(msg.sender));

        lastClaimDateByWallet[msg.sender] = block.timestamp;
    }

    function calculateMetaPassesYield(address wallet_) public view returns (uint256) {
        return (block.timestamp - lastClaimDateByWallet[wallet_]) *
        numberOfStakedPassesByWallet[wallet_] *
        mintPassYield / 1 days;
    }

    function setMintPassContract(address contractAddress_) external onlyOwner {
        mintPassContractAddress = contractAddress_;
    }

    function setGodTokenContract(address contractAddress_) external onlyOwner {
        godTokenContractAddress = contractAddress_;
    }

    function setMintPassYield(uint256 newMintPassYield_) external onlyOwner {
        mintPassYield = newMintPassYield_;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

}