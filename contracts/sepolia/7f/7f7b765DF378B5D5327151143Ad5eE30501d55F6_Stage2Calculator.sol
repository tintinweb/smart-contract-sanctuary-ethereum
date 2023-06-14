// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {IStage2Calculator} from "./interfaces/IStage2Calculator.sol";

interface IERC1155Supply {
    function totalSupply() external view returns (uint256);
}

contract Stage2Calculator is IStage2Calculator, Ownable {
    // TBD Pass: https://etherscan.io/address/0x9FBb230B1EDD6C69bd0D8E610469031AB658F4b2
    IERC1155Supply public constant tbdPass = IERC1155Supply(0x9FBb230B1EDD6C69bd0D8E610469031AB658F4b2);

    uint256 public stagePrice;
    uint256 public tokenSupplyFrom;
    uint256 public tokenSupplyTo;

    constructor() {}

    function setPriceAndRange(uint256 stagePrice_, uint256 tokenSupplyFrom_, uint256 tokenSupplyTo_) external {
        _checkOwner();
        if (stagePrice_ == 0) revert ZeroPrice();
        if (tokenSupplyFrom_ == 0 || tokenSupplyTo_ == 0 || tokenSupplyFrom_ >= tokenSupplyTo_) revert InvalidSupplyRange();

        stagePrice = stagePrice_;
        tokenSupplyFrom = tokenSupplyFrom_;
        tokenSupplyTo = tokenSupplyTo_;
        emit PassPriceSet(stagePrice, tokenSupplyFrom, tokenSupplyTo);
    }

    function price() external view returns (uint256) {
        if (stagePrice == 0) revert ZeroPrice();
        uint256 totalSupply = tbdPass.totalSupply();
        if (totalSupply < tokenSupplyFrom || totalSupply > tokenSupplyTo) revert InvalidStage(); 
        return stagePrice;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

pragma solidity 0.8.18;

import "./IStage2CalculatorEvents.sol";

interface IStage2Calculator is IStage2CalculatorEvents {
    error ZeroPrice();
    error InvalidStage();
    error InvalidSupplyRange();
    
    function setPriceAndRange(uint256 stagePrice_, uint256 tokenIdFrom_, uint256 tokenIdTo_) external;
    function price() external view returns (uint256);
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

pragma solidity 0.8.18;

interface IStage2CalculatorEvents {
    event PassPriceSet(uint256 indexed stagePrice_, uint256 indexed tokenSupplyFrom_, uint256 indexed tokenSupplyTo);
}