//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

//                           STRAYLIGHT PROTOCOL v.01
//
//                                .         .
//                                  ., ... .,
//                                  \%%&%%&./
//                         ,,.      /@&&%&&&\     ,,
//                            *,   (##%&&%##)  .*.
//                              (,  (#%%%%.)   %,
//                               ,% (#(##(%.(/
//                                 %((#%%%##*
//                 ..**,*/***///*,..,#%%%%*..,*\\\***\*,**..
//                                   /%#%%
//                              /###(/%&%/(##%(,
//                           ,/    (%###%%&%,   **
//                         .#.    *@&%###%%&)     \\
//                        /       *&&%###%&@#       *.
//                      ,*         (%#%###%#?)       .*.
//                                 ./%%###%%#,
//                                  .,(((##,.
//
//

/// @title Minting
/// @notice Minting Contract for Straylight Protocoll
/// @author @brachlandberlin / plsdlr.net
/// @dev needs to be initalized after the main contract is deployed, uses Payment Splitter

interface interfaceStraylight {
    function publicmint(
        address mintTo,
        bytes12 rule,
        uint256 moves
    ) external;
}

contract Minting is Ownable {
    event Mint(address addr);

    //uint256 public constant mintPriceMainnet = 80000000000000000 wei;
    uint256 public mintPrice;
    bool initalized;
    interfaceStraylight public istraylight;
    bool paused = true;
    address private folia;
    address private ppp;
    uint256 private percentageFolia;

    constructor(
        address[] memory payees,
        uint256 _percentage,
        uint256 _MintPrice
    ) {
        mintPrice = _MintPrice;
        folia = payees[0];
        ppp = payees[1];
        percentageFolia = _percentage;
    }

    /// @dev public mint function
    /// @param mintTo the address the token should be minted to
    /// @param rule the 12 bytes rule defining the behavior of the turmite
    /// @param moves the number of inital moves
    function publicMint(
        address mintTo,
        bytes12 rule,
        uint256 moves
    ) external payable {
        require(paused != true, "MINTING PAUSED");
        require(initalized == true, "NOT INITALIZED");
        require(msg.value >= mintPrice, "INSUFFICIENT PAYMENT");

        uint256 foliaReceives = (msg.value * percentageFolia) / 100;
        uint256 artistReceives = msg.value - foliaReceives;

        (bool sent, ) = payable(folia).call{value: foliaReceives}("");
        require(sent, "Transfer failed.");

        (sent, ) = payable(ppp).call{value: artistReceives}("");
        require(sent, "Transfer failed.");

        istraylight.publicmint(mintTo, rule, moves);
        emit Mint(mintTo);
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    /// @dev admin mint function - only callable from owner
    /// @param mintTo the address the token should be minted to
    /// @param rule the 12 bytes rule defining the behavior of the turmite
    /// @param moves the number of inital moves
    function adminMint(
        address mintTo,
        bytes12 rule,
        uint256 moves
    ) external onlyOwner {
        require(initalized == true, "NOT INITALIZED");
        istraylight.publicmint(mintTo, rule, moves);
        emit Mint(mintTo);
    }

    /// @dev set Staylight address
    /// @param _straylight address of the deployed contract
    function setStraylight(address _straylight) external onlyOwner {
        istraylight = interfaceStraylight(_straylight);
        initalized = true;
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