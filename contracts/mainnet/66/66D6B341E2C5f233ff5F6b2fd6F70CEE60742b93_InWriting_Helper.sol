// SPDX-License-Identifier: MIT

//               ____ ____ _________ ____ ____ ____ ____ ____ ____ ____ 
//              ||I |||n |||       |||W |||r |||i |||t |||i |||n |||g ||
//              ||__|||__|||_______|||__|||__|||__|||__|||__|||__|||__||
//              |/__\|/__\|/_______\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|

/*  restrictions at time of deployment:
*       wert can only use 8 decimal places of precision in eth price
*       there is a minimum credit card payment of $1.05 USD
*
*   compromises:
*       we decided to not send remaining rounded balances to the user because
*       it would cost more in gas than the user would be getting back (21,000 gwei / transfer -> 21000 gwei > 1e-8 eth)
*/


pragma solidity ^0.8.1;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface InWriting {
    function mint_NFT(string memory str) external payable returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function get_minting_cost() external view returns (uint256);
    function buy(uint256 tokenId) external payable returns (bool);
    function mint_unlocked_NFT(string memory str) external payable returns (uint256);
    function get_price(uint256 tokenId) external view returns (uint256);
}

contract InWriting_Helper is Ownable{
    address InWriting_address = 0x4Ced71C6F18b112A36634eef5aCFA6156C6dADaD;
    InWriting write = InWriting(InWriting_address);

    constructor(){}

    function withdraw(uint256 amt) public onlyOwner {
        require(amt <= address(this).balance);
        payable(owner()).transfer(amt);
    }

    function mint_and_send(string memory str, address addr) public payable returns (uint256) {
        uint256 tokenId = write.mint_NFT{value: write.get_minting_cost()}(str);
        write.transferFrom(address(this), addr, tokenId);
        return tokenId;
    }

    function mint_unlocked_and_send(string memory str, address addr) public payable returns (uint256) {
        uint256 tokenId = write.mint_unlocked_NFT{value: write.get_minting_cost()}(str);
        write.transferFrom(address(this), addr, tokenId);
        return tokenId;
    }

    function buy_and_send(uint256 tokenId, address addr) public payable returns (bool) {
        write.buy{value: write.get_price(tokenId)}(tokenId);
        write.transferFrom(address(this), addr, tokenId);
        return true;
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