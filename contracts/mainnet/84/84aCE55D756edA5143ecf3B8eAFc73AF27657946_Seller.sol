// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IMinted.sol";
import "./ITicket.sol";

error SaleInactive();
error SoldOut();
error InvalidPrice();
error ExceedQuota();
error WithdrawFailed();
error FreezeMint();

contract Seller is Ownable {

    uint256 public nextTokenId = 1;

    uint256 public allowlistPrice = 0.05 ether;
    uint256 public publicPrice = 0.07 ether;

    uint256 public constant MAX_MINT = 4;
    uint256 public constant MAX_SUPPLY = 2048;

    // 0: closed; 1: allowlist mint; 2: public mint
    uint8 public saleStage;

    address public beneficiary;

    ITicket public ticket;
    IMinted public token;

    bool public isDevMintFreeze;

    constructor(address ticket_) {
        ticket = ITicket(ticket_);
    }

    /**
     * Public functions
     */
    function allowlistMint(bytes[] calldata _signatures, uint256[] calldata spotIds)
        external
        payable
    {
        uint256 _nextTokenId = nextTokenId;
        // must be allowlist mint stage
        if (saleStage != 1) revert SaleInactive();
        // offset by 1 because we start at 1, and nextTokenId is incremented _after_ mint
        if (_nextTokenId + (spotIds.length - 1) > MAX_SUPPLY) revert SoldOut();
        // cannot mint exceed 4 catddles
        if (spotIds.length > MAX_MINT) revert ExceedQuota();
        if (msg.value < allowlistPrice * spotIds.length) revert InvalidPrice();

        for (uint256 i = 0; i < spotIds.length; i++) {
            // invalidate the spotId passed in
            ticket.claimAllowlistSpot(_signatures[i], msg.sender, spotIds[i]);
            token.authorizedMint(msg.sender, _nextTokenId);

            unchecked {
                _nextTokenId++;
            }
        }
        // update nextTokenId
        nextTokenId = _nextTokenId;
    }

    function publicMint(uint256 amount)
        external
        payable
    {
        uint256 _nextTokenId = nextTokenId;
        // must be public mint stage
        if (saleStage != 2) revert SaleInactive();
        // offset by 1 because we start at 1, and nextTokenId is incremented _after_ mint
        if (_nextTokenId + (amount - 1) > MAX_SUPPLY) revert SoldOut();
        // cannot mint exceed 4 catddles
        if (amount > MAX_MINT) revert ExceedQuota();
        if (msg.value < publicPrice * amount) revert InvalidPrice();

        for (uint256 i = 0; i < amount; i++) {
            token.authorizedMint(msg.sender, _nextTokenId);

            unchecked {
                _nextTokenId++;
            }
        }
        // update nextTokenId
        nextTokenId = _nextTokenId;
    }

    /**
     *  OnlyOwner functions
     */

    function setToken(address tokenAddress) public onlyOwner {
        token = IMinted(tokenAddress);
    }

    function setTicket(address ticket_) public onlyOwner {
        ticket = ITicket(ticket_);
    }

    function setSaleStage(uint8 stage) public onlyOwner {
        saleStage = stage;
    }

    function setAllowlistPrice(uint256 price) public onlyOwner {
        allowlistPrice = price;
    }

    function setPublicPrice(uint256 price) public onlyOwner {
        publicPrice = price;
    }

    function freezeDevMint() public onlyOwner {
        // freeze dev mint forever
        isDevMintFreeze = true;
    }

    function devMint(address receiver, uint256 amount) public onlyOwner {
        if (isDevMintFreeze) revert FreezeMint();
        uint256 _nextTokenId = nextTokenId;
        if (_nextTokenId + (amount - 1) > MAX_SUPPLY) revert SoldOut();

        for (uint256 i = 0; i < amount; i++) {
            token.authorizedMint(receiver, _nextTokenId);

            unchecked {
                _nextTokenId++;
            }
        }
        nextTokenId = _nextTokenId;
    }

    function setBeneficiary(address beneficiary_) public onlyOwner {
        beneficiary = beneficiary_;
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(beneficiary != address(0), "Cannot withdraw to zero address");
        require(amount <= address(this).balance, "Cannot withdraw exceed balance");
        (bool success, ) = beneficiary.call{value: amount}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }
   
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITicket {
   function claimAllowlistSpot(bytes calldata _signature, address user, uint256 spotId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMinted {
   function authorizedMint(address user, uint256 tokenId) external;
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