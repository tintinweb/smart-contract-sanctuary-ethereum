// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.10;

/**
 * CrypToadz on Chain
 * These Toadz are 100% on-chain and each token is bound to their
 * corresponding legacy Toad. This means that these Toadz are untradeable.
 * The only purpose of these is to make sure of CrypToadz persistence on 
 * the blockchain. 
 * 
 * Contract written by: @0xBori 
 * Art brought on-chain by: @Wattsyart 
 */

import "@openzeppelin/contracts/access/Ownable.sol";

interface ICrypToadzChained {
    function tokenURIWithPresentation(uint256 _tokenId, uint8 _presentation) external view returns (string memory);
}

interface IToadz {
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function balanceOf(address _address) external view returns (uint256);
}

interface IEIP2309 {
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);
}

error SpecialsMinted();

contract CrypToadzOnChain is Ownable, IEIP2309 { 

    // Variables
    string public name = "CrypToadz on Chain";
    string public symbol = "OCTOAD";

    ICrypToadzChained public CTC = ICrypToadzChained(0x810626961B7b30aA981D7Ba4D61360402Bd4CD22);
    IToadz public TOADZ = IToadz(0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6);
    bool specialsMinted;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    constructor(){
        // Initialize EIP2309 which will mint tokens from 1 - 6969.
        _initEIP2309(1, 6969);
    }

    /** 
     * @dev Sets a new address for CrypToadz on Chain URI implementation.
     * This contract address holds the on chain data for URI rendering. 
     */
    function setCTC(address _address) external {
        CTC = ICrypToadzChained(_address);
    }

    /**
     * @dev Sets a new address for CrypToadz.
     * This should always point towards the official CrypToadz address unless
     * desired otherwise. This could be called with the 0x00 address in order to
     * stop linking this to Cryptoadz and thus effectively removing the collection.
     */
    function setToadz(address _address) external {
        TOADZ = IToadz(_address);
    }

    /** 
     * @dev Mints tokens with ID's 1 000 000 - 56 000 000,
     * each token ID gets incremented by 1 000 000. This is something funky on 
     * the original CrypToadz contract for special tokens that were minted in a 
     * dev mint. 
     *
     * Emits {Transfer} event.
     */
    function mintSpecials() external {
        if (specialsMinted) revert SpecialsMinted();
        unchecked {
            for (uint i = 1; i < 57; ++i) {
                emit Transfer(address(0), address(this), i * 1000000);
            } 
        }

        specialsMinted = true;
    }

    function totalSupply() external view returns (uint256) {
        if (address(TOADZ) == address(0)) return 0;
        return TOADZ.totalSupply();
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        if (address(TOADZ) == address(0)) return address(0);
        return TOADZ.ownerOf(_tokenId);
    }

    function balanceOf(address _address) external view returns (uint256) {
        if (address(TOADZ) == address(0)) return 0;
        return TOADZ.balanceOf(_address);
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        return CTC.tokenURIWithPresentation(_tokenId, 1);
    }

    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        return (_interfaceId == 0x80ac58cd || _interfaceId == 0x5b5e139f);
    }

     /** 
     * @dev Mints tokens from `_start` to `_end` and emits one {ConsecutiveTransfer}
     * event as defined in EIP2309 (https://eips.ethereum.org/EIPS/eip-2309).  
     *
     * Emits {ConsecutiveTransfer} event.
     */
    function _initEIP2309(uint256 _start, uint256 _end) internal virtual { 
        emit ConsecutiveTransfer(_start, _end, address(0), address(this));       
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