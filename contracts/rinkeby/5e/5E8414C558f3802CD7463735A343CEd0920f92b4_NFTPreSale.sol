// SPDX-License-Identifier: MIT
// Developed by itxToledo

pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Represents NFTERC721 Smart Contract
 */
contract INFTERC721 {
    /**
     * @dev ERC-721 INTERFACE
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}

    /**
     * @dev CUSTOM INTERFACE
     */
    function mintTo(uint256 amount, address _to) external {}

    function maxMintPerTransaction() public returns (uint256) {}
}

/**
 * @title NFTPreSaleContract.
 *
 * @author itxToledo
 *
 * @notice This Smart Contract can be used to sell any fixed amount of NFTs where only permissioned
 * wallets are allowed to buy. Buying is limited to a certain time period.
 *
 */
contract NFTPreSale is Ownable {
    /**
     * @notice The Smart Contract of the NFT being sold
     * @dev ERC-721 Smart Contract
     */
    INFTERC721 public immutable nft;

    /**
     * @dev MINT DATA
     */
    uint256 public maxSupply = 50;
    uint256 public minted = 0;

    uint256 public constant mintPrice = 0.1 * 10**18;
    uint256 public constant mintStart = 1644375600;
    uint256 public constant mintEnd = 1644548340;
    uint256 public constant mintMaxAmount = 2;

    mapping(address => uint256) public addressToMints;

    /**
     * @dev Events
     */
    event ReceivedEther(address indexed sender, uint256 indexed amount);
    event Purchase(address indexed buyer, uint256 indexed amount);
    event setMaxSupplyEvent(uint256 indexed maxSupply);
    event WithdrawAllEvent(address indexed to, uint256 amount);

    constructor(address _nftaddress) Ownable() {
        nft = INFTERC721(_nftaddress);
    }

    /**
     * @dev SALE
     */

    /**
     * @notice Function to buy one or more NFTs.
     *
     * @param amount. The amount of NFTs to buy.
     */
    function buy(uint256 amount) external payable {
        /// @dev Verifies that user can mint based on the provided parameters.

        require(address(nft) != address(0), "NFT SMART CONTRACT NOT SET");

        require(block.timestamp >= mintStart, "SALE HASN'T STARTED YET");
        require(block.timestamp < mintEnd, "SALE IS CLOSED");
        require(amount > 0, "HAVE TO BUY AT LEAST 1");

        require(
            amount <= nft.maxMintPerTransaction(),
            "CANNOT MINT MORE PER TX"
        );
        require(
            addressToMints[_msgSender()] + amount <= mintMaxAmount,
            "MINT AMOUNT EXCEEDS MAX FOR USER"
        );
        require(
            minted + amount <= maxSupply,
            "MINT AMOUNT GOES OVER MAX SUPPLY"
        );
        require(msg.value == mintPrice * amount, "ETHER SENT NOT CORRECT");

        /// @dev Updates contract variables and mints `amount` NFTs to users wallet

        minted += amount;
        addressToMints[msg.sender] += amount;
        nft.mintTo(amount, msg.sender);

        emit Purchase(msg.sender, amount);
    }

    /**
     * @dev OWNER ONLY
     */

    /**
     * @notice Change the maximum supply of NFTs that are for sale.
     *
     * @param newMaxSupply. The new max supply.
     */
    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
        emit setMaxSupplyEvent(newMaxSupply);
    }

    /**
     * @dev FINANCE
     */

    /**
     * @notice Allows owner to withdraw funds generated from sale.
     *
     * @param _to. The address to send the funds to.
     */
    function withdrawAll(address _to) external onlyOwner {
        require(_to != address(0), "CANNOT WITHDRAW TO ZERO ADDRESS");

        uint256 contractBalance = address(this).balance;

        require(contractBalance > 0, "NO ETHER TO WITHDRAW");

        emit WithdrawAllEvent(_to, contractBalance);
    }

    /**
     * @dev Fallback function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
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