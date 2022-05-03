// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../Interfaces/I_TokenCharacter.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Models/PaymentsShared.sol";

contract BuyCharacters is Ownable, PaymentsShared {

    uint256 public constant MAX_MINTABLE = 10000;
    uint256 public TOKEN_PRICE = 0.035 ether;
    uint256 public MINTS_PER_TRANSACTION = 10;

    uint256 public FREE_MINT_AMOUNT = 3500;

    I_TokenCharacter tokenCharacter;

    bool public isSaleLive;
    event SaleLive(bool onSale);

    constructor(address _tokenCharacterAddress) {
        tokenCharacter = I_TokenCharacter(_tokenCharacterAddress);
    }

    function buy(uint8 amountToBuy) external payable {
        require(tx.origin == msg.sender, "EOA only");
        
        require(isSaleLive, "Sale is not live");
        require(amountToBuy <= MINTS_PER_TRANSACTION,"Too many per transaction");

        uint256 totalMinted = tokenCharacter.totalSupply();
        require(totalMinted + amountToBuy <= MAX_MINTABLE,"Sold out");

        uint256 price = 0;

        if (totalMinted > FREE_MINT_AMOUNT) {
            price = TOKEN_PRICE;
        }

        require(msg.value >= price * amountToBuy,"Not enough ETH");

        tokenCharacter.Mint(amountToBuy, msg.sender);
        
    }

    function getPrice() public view returns (uint256) {
        uint256 totalMinted = tokenCharacter.totalSupply();
        
        if (totalMinted > FREE_MINT_AMOUNT) {
            return TOKEN_PRICE;
        }

        return 0; //free mint
    }

    //Variables
    function setPrice(uint256 newPrice) external onlyOwner {
        TOKEN_PRICE = newPrice;
    }

    function startPublicSale() external onlyOwner {
        isSaleLive = true;
        emit SaleLive(isSaleLive);
    }

    function stopPublicSale() external onlyOwner ()
    {
        isSaleLive = false;
        emit SaleLive(isSaleLive);
    }

    function setTransactionLimit(uint256 newAmount) external onlyOwner {
        MINTS_PER_TRANSACTION = newAmount;
    }

    function setFreeAmount(uint256 newAmount) external onlyOwner {
        FREE_MINT_AMOUNT = newAmount;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//Interface for characters NFT
interface I_TokenCharacter {

    function Mint(uint8, address) external; //amount, to
    
    function totalSupply() external view returns (uint256);
    function setApprovalForAll(address, bool) external;  //address, operator
    function transferFrom(address, address, uint256) external;
    function ownerOf(uint256) external view returns (address); //who owns this token
    function _ownerOf16(uint16) external view returns (address);

    function addController(address) external;

}

// SPDX-License-Identifier: MIT

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//simple payments handling for splitting between fixed wallets
contract PaymentsShared is Ownable, ReentrancyGuard {

    address WalletA = 0x0939D5c0DAb578ae7DA3cf11bfd4b7e5dc53CD45;
    address WalletB = 0x670c38d686DA822bcc96c565ceE1DD7E007D1544;
    address WalletC = 0x42D2339cA21C7D5df409326068c5CE5975dB5A39;
    address WalletD = 0xBa643BE38D25867E2062890ee5D42aA6879F5586;

    //payments
    function withdrawAll() external nonReentrant onlyOwner {          

        uint256 ticks = address(this).balance / 1000;

        (bool success, ) = WalletA.call{value: ticks * 250}(""); //25%
        require(success, "Transfer failed.");

        payable(WalletB).transfer(ticks * 100); //10%
        payable(WalletC).transfer(ticks * 325); //32.5%
        payable(WalletD).transfer(address(this).balance); //32.5%
    }

    function withdrawSafety() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}

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

// SPDX-License-Identifier: MIT

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