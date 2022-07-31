// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "Ownable.sol";
import "ISimpleAirdropper.sol";
import "IArrayAirdropper.sol";

contract AirdropBatchSeller is Ownable {
    address public constant ukraineAddress = 0x165CD37b4C644C2921454429E7F9358d18A45e14;

    address internal immutable firstDrop;
    address internal immutable secondDrop;

    uint256 public immutable tokenPrice;

    constructor(address firstDrop_, address secondDrop_, uint256 tokenPrice_) {
        firstDrop = firstDrop_;
        secondDrop = secondDrop_;
        tokenPrice = tokenPrice_;
    }

    modifier enoughETH(uint256 amount) {
        require(msg.value >= amount * tokenPrice, "Not enough ETH");
        _;
    }

    function returnOwnerships() external onlyOwner {
        if(Ownable(firstDrop).owner() == address(this)) Ownable(firstDrop).transferOwnership(owner());
        if(Ownable(secondDrop).owner() == address(this)) Ownable(secondDrop).transferOwnership(owner());
    }

    function buyFirstDropTokens(uint256 amount) payable external enoughETH(amount) returns (uint256) {
        address[] memory addresses = new address[](1);
        addresses[0] = msg.sender;
        return IArrayAirdropper(firstDrop).airdrop(addresses, amount);
    }

    function buySecondDropTokens(uint256 amount) payable external enoughETH(amount) returns (uint256) {
        return ISimpleAirdropper(secondDrop).airdrop(amount, msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISimpleAirdropper {
    function airdrop(uint256 numberOfTokens, address to) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IArrayAirdropper {
    function airdrop(address[] memory addresses, uint256 amount) external returns (uint256);
}