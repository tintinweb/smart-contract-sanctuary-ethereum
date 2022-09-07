// https://www.gmcafe.io/migrate
/// @author raffy.eth
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Ownable} from "@openzeppelin/[email protected]/access/Ownable.sol";

interface GMOOStub {
	function ownerOf(uint256 moo) external view returns (address);
	function mooFromToken(uint256 token) external view returns (uint256); 
	function safeTransferFrom(address from, address to, uint256 moo) external;
}

interface OpenSeaStub {
	function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, 
		uint256[] calldata amounts, bytes calldata data) external;
}

contract GMOORedeem is Ownable {

	address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

	GMOOStub constant GMOO_NFT = GMOOStub(0xE43D741e21d8Bf30545A88c46e4FF5681518eBad);
	OpenSeaStub constant OPENSEA_NFT = OpenSeaStub(0x495f947276749Ce646f68AC8c248420045cb7b5e); 
	address public _wallet = 0x00007C6cf9bF9B62B663f35542F486747a86D9D1;

	function setWallet(address a) onlyOwner public {
		_wallet = a;
	}

	function redeemMoos(uint256[] calldata tokens) public {
		uint256 n = tokens.length;
		require(n > 0, "no moos");
		uint256[] memory balances = new uint256[](n);		
		for (uint256 i; i < n; ) {
			balances[i] = 1;
			unchecked { i++; }
		}
		OPENSEA_NFT.safeBatchTransferFrom(msg.sender, BURN_ADDRESS, tokens, balances, ''); 
		for (uint256 i; i < n; ) {
			uint256 moo = GMOO_NFT.mooFromToken(tokens[i]);
			GMOO_NFT.safeTransferFrom(_wallet, msg.sender, moo);
			unchecked { i++; }
		}
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