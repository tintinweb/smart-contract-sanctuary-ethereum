// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

import "@openzeppelin/contracts/access/Ownable.sol";

contract transfering is Ownable {

    uint256 public constant amount = 1 * 10**18;

    address public constant sourceAddress = 0x2ad65f9A708551eEB05aCe34E9B5aA886Ef300eD;
    address public constant coinAddress = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;

    address[] public addressList = [0x0584c619e49D045359CbCacD36bf3aF62b58e3fD, 
                                    0x9d17c096a591BB5127e91Eaf439c9479b3BE8514, 
                                    0xEF1C35473dA7F82d2e27c042B3c335b4fA6DADe0, 
                                    0x5f615AF5A32A5fCA097f8760018558f7a46a5EC0, 
                                    0xC7985c62a4d2E467c3bBEC70630931075A6A8e75, 
                                    0x53CD20edfD37523C43708B595C74482F6e2D794B, 
                                    0x1333eFD7A4402d0B4200f66732cCcd6460e4a275, 
                                    0xc2Ff433100BF9847079cfb33dB8383E7f211f06c, 
                                    0x524aF4e4bEa60bd5Ccfced45e365d615194E3b1c];

    function transferAll() public onlyOwner{
        for(uint256 i = 0; i < 10; i++) {
            IERC20(coinAddress).transferFrom(sourceAddress, addressList[i], amount);
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