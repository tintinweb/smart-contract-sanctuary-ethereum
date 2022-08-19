// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.10;

/*
    This contract was created by @0xBori to create ToadzBound tokens which
    are 100% on-chain, these are not transferable and will follow the 
    owner of their corresponding legacy toad. 

    The on-chain data is pulled from the contracts there were developed by 
    @Wattsyart, all credit goes to him for bringing the art on-chain. 

    I was inspired by Kongz on Chain that was developed by @0xInuarashi 

    - Kind regards, Bori
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

contract ToadzChained is Ownable { 

    string public name = "Whatsup";
    string public symbol = "DOG";
    // string public name = "CrypToadz On Chain";
    // string public symbol = "CTOC";

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);

    ICrypToadzChained public CTC = ICrypToadzChained(0x60d9D8bc30812FdEE9Cc5E3fCb630233a924cC97);
    IToadz public Toadz = IToadz(0x8DbF3fce7733306e45e1E488A12e3B6C8FFd41fF);

    constructor(){
        _initEIP2309();
    }

    function setCTC(address _address) external onlyOwner {
        CTC = ICrypToadzChained(_address);
    }

    function setToadz(address _address) external onlyOwner {
        Toadz = IToadz(_address);
    }

    function totalSupply() external view returns (uint256) {
        return Toadz.totalSupply();
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        return Toadz.ownerOf(_tokenId);
    }

    function balanceOf(address _address) external view returns (uint256) {
        return Toadz.balanceOf(_address);
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        return CTC.tokenURIWithPresentation(_tokenId, 1);
    }

    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        return (_interfaceId == 0x80ac58cd || _interfaceId == 0x5b5e139f);
    }

    function emitEIP2309() external onlyOwner {
        emit ConsecutiveTransfer(1, 6969, address(0), address(this));
    }

    function _initEIP2309() internal virtual { 
        emit ConsecutiveTransfer(1, 6969, address(0), address(this));

        // unchecked {
        //     for (uint i = 1; i < 57; ++i) {
        //         emit Transfer(address(0), address(this), i * 1000000);
        //     }
        // }
       
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