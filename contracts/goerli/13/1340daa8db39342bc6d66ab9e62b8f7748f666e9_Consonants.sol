/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/PFP-GENE.sol


pragma solidity ^0.8.0;


/**
 * @title Leedo PFP Project
 * @author Atomrigs Lab
 */

contract Consonants {
    string[] public leftEyes = [
        '<g>' //ga
            '<rect x="140" y="140" class="st0" width="10" height="10"/>'
            '<rect x="150" y="150" class="st0" width="10" height="10"/>'
            '<rect x="140" y="160" class="st0" width="10" height="10"/>'
            '<rect x="130" y="170" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //na
            '<rect x="140" y="150" class="st0" width="10" height="10"/>'
            '<rect x="150" y="160" class="st0" width="10" height="10"/>'
        '</g>', 
        '<g>' //da
            '<rect x="140" y="150" class="st0" width="10" height="10"/>'
            '<rect x="150" y="160" class="st0" width="10" height="10"/>'
            '<rect x="150" y="140" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //la
            '<rect x="140" y="160" class="st0" width="10" height="10"/>'
            '<rect x="140" y="140" class="st0" width="10" height="10"/>'
            '<rect x="150" y="170" class="st0" width="10" height="10"/>'
            '<rect x="150" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ma
            '<rect x="140" y="160" class="st0" width="10" height="10"/>'
            '<rect x="150" y="150" class="st0" width="10" height="10"/>'
            '<rect x="160" y="160" class="st0" width="10" height="10"/>'
            '<rect x="140" y="140" class="st0" width="10" height="10"/>'
            '<rect x="160" y="140" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ba
            '<rect x="140" y="160" class="st0" width="10" height="10"/>'
            '<rect x="140" y="140" class="st0" width="10" height="10"/>'
            '<rect x="160" y="160" class="st0" width="10" height="10"/>'
            '<rect x="160" y="140" class="st0" width="10" height="10"/>'
            '<rect x="150" y="170" class="st0" width="10" height="10"/>'
            '<rect x="150" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //sa
            '<rect x="140" y="160" class="st0" width="10" height="10"/>'
            '<rect x="160" y="160" class="st0" width="10" height="10"/>'
            '<rect x="160" y="140" class="st0" width="10" height="10"/>'
            '<rect x="150" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //Aa
            '<rect x="150" y="160" class="st0" width="10" height="10"/>'
            '<rect x="150" y="140" class="st0" width="10" height="10"/>'
            '<rect x="160" y="150" class="st0" width="10" height="10"/>'
            '<rect x="140" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //Ja
            '<rect x="140" y="170" class="st0" width="10" height="10"/>'
            '<rect x="150" y="160" class="st0" width="10" height="10"/>'
            '<rect x="160" y="170" class="st0" width="10" height="10"/>'
            '<rect x="150" y="140" class="st0" width="10" height="10"/>'
            '<rect x="160" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //Cha
            '<rect x="140" y="170" class="st0" width="10" height="10"/>'
            '<rect x="150" y="160" class="st0" width="10" height="10"/>'
            '<rect x="160" y="170" class="st0" width="10" height="10"/>'
            '<rect x="140" y="130" class="st0" width="10" height="10"/>'
            '<rect x="150" y="140" class="st0" width="10" height="10"/>'
            '<rect x="160" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //Ka
            '<rect x="140" y="150" class="st0" width="10" height="10"/>'
            '<rect x="140" y="170" class="st0" width="10" height="10"/>'
            '<rect x="140" y="130" class="st0" width="10" height="10"/>'
            '<rect x="150" y="160" class="st0" width="10" height="10"/>'
            '<rect x="150" y="140" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //Ta
            '<rect x="150" y="150" class="st0" width="10" height="10"/>'
            '<rect x="150" y="130" class="st0" width="10" height="10"/>'
            '<rect x="150" y="170" class="st0" width="10" height="10"/>'
            '<rect x="140" y="140" class="st0" width="10" height="10"/>'
            '<rect x="140" y="160" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //Pa
            '<rect x="130" y="160" class="st0" width="10" height="10"/>'
            '<rect x="140" y="150" class="st0" width="10" height="10"/>'
            '<rect x="160" y="150" class="st0" width="10" height="10"/>'
            '<rect x="150" y="160" class="st0" width="10" height="10"/>'
            '<rect x="170" y="160" class="st0" width="10" height="10"/>'
            '<rect x="130" y="140" class="st0" width="10" height="10"/>'
            '<rect x="150" y="140" class="st0" width="10" height="10"/>'
            '<rect x="170" y="140" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //Ha
            '<rect x="140" y="160" class="st0" width="10" height="10"/>'
            '<rect x="160" y="160" class="st0" width="10" height="10"/>'
            '<rect x="160" y="140" class="st0" width="10" height="10"/>'
            '<rect x="150" y="170" class="st0" width="10" height="10"/>'
            '<rect x="150" y="150" class="st0" width="10" height="10"/>'
            '<rect x="150" y="130" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //semo
            '<rect x="130" y="160" class="st0" width="10" height="10"/>'
            '<rect x="150" y="160" class="st0" width="10" height="10"/>'
            '<rect x="150" y="140" class="st0" width="10" height="10"/>'
            '<rect x="170" y="160" class="st0" width="10" height="10"/>'
            '<rect x="160" y="150" class="st0" width="10" height="10"/>'
            '<rect x="140" y="150" class="st0" width="10" height="10"/>'
        '</g>'                
    ];

    string[] public rightEyes = [
        '<g>' //ga
            '<rect x="190" y="140" class="st0" width="10" height="10"/>'
            '<rect x="200" y="150" class="st0" width="10" height="10"/>'
            '<rect x="190" y="160" class="st0" width="10" height="10"/>'
            '<rect x="180" y="170" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //na
            '<rect x="190" y="150" class="st0" width="10" height="10"/>'
            '<rect x="200" y="160" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //da
            '<rect x="200" y="150" class="st0" width="10" height="10"/>'
            '<rect x="210" y="160" class="st0" width="10" height="10"/>'
            '<rect x="210" y="140" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //la
            '<rect x="190" y="160" class="st0" width="10" height="10"/>'
            '<rect x="190" y="140" class="st0" width="10" height="10"/>'
            '<rect x="200" y="170" class="st0" width="10" height="10"/>'
            '<rect x="200" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ma
            '<rect x="190" y="160" class="st0" width="10" height="10"/>'
            '<rect x="200" y="150" class="st0" width="10" height="10"/>'
            '<rect x="210" y="160" class="st0" width="10" height="10"/>'
            '<rect x="190" y="140" class="st0" width="10" height="10"/>'
            '<rect x="210" y="140" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ba
            '<rect x="190" y="160" class="st0" width="10" height="10"/>'
            '<rect x="190" y="140" class="st0" width="10" height="10"/>'
            '<rect x="210" y="160" class="st0" width="10" height="10"/>'
            '<rect x="210" y="140" class="st0" width="10" height="10"/>'
            '<rect x="200" y="170" class="st0" width="10" height="10"/>'
            '<rect x="200" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //sa
            '<rect x="190" y="160" class="st0" width="10" height="10"/>'
            '<rect x="210" y="160" class="st0" width="10" height="10"/>'
            '<rect x="210" y="140" class="st0" width="10" height="10"/>'
            '<rect x="200" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //aa
            '<rect x="200" y="160" class="st0" width="10" height="10"/>'
            '<rect x="200" y="140" class="st0" width="10" height="10"/>'
            '<rect x="210" y="150" class="st0" width="10" height="10"/>'
            '<rect x="190" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ja
            '<rect x="190" y="170" class="st0" width="10" height="10"/>'
            '<rect x="200" y="160" class="st0" width="10" height="10"/>'
            '<rect x="210" y="170" class="st0" width="10" height="10"/>'
            '<rect x="200" y="140" class="st0" width="10" height="10"/>'
            '<rect x="210" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //cha
            '<rect x="190" y="170" class="st0" width="10" height="10"/>'
            '<rect x="200" y="160" class="st0" width="10" height="10"/>'
            '<rect x="210" y="170" class="st0" width="10" height="10"/>'
            '<rect x="190" y="130" class="st0" width="10" height="10"/>'
            '<rect x="200" y="140" class="st0" width="10" height="10"/>'
            '<rect x="210" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ka
            '<rect x="190" y="150" class="st0" width="10" height="10"/>'
            '<rect x="190" y="170" class="st0" width="10" height="10"/>'
            '<rect x="190" y="130" class="st0" width="10" height="10"/>'
            '<rect x="200" y="160" class="st0" width="10" height="10"/>'
            '<rect x="200" y="140" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ta
            '<rect x="200" y="150" class="st0" width="10" height="10"/>'
            '<rect x="200" y="130" class="st0" width="10" height="10"/>'
            '<rect x="200" y="170" class="st0" width="10" height="10"/>'
            '<rect x="190" y="140" class="st0" width="10" height="10"/>'
            '<rect x="190" y="160" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //pa
            '<rect x="180" y="160" class="st0" width="10" height="10"/>'
            '<rect x="190" y="150" class="st0" width="10" height="10"/>'
            '<rect x="210" y="150" class="st0" width="10" height="10"/>'
            '<rect x="200" y="160" class="st0" width="10" height="10"/>'
            '<rect x="220" y="160" class="st0" width="10" height="10"/>'
            '<rect x="180" y="140" class="st0" width="10" height="10"/>'
            '<rect x="200" y="140" class="st0" width="10" height="10"/>'
            '<rect x="220" y="140" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ha
            '<rect x="190" y="160" class="st0" width="10" height="10"/>'
            '<rect x="210" y="160" class="st0" width="10" height="10"/>'
            '<rect x="210" y="140" class="st0" width="10" height="10"/>'
            '<rect x="200" y="170" class="st0" width="10" height="10"/>'
            '<rect x="200" y="150" class="st0" width="10" height="10"/>'
            '<rect x="200" y="130" class="st0" width="10" height="10"/>'
        '</g>',   
        '<g>' //semo
            '<rect x="180" y="160" class="st0" width="10" height="10"/>'
            '<rect x="200" y="160" class="st0" width="10" height="10"/>'
            '<rect x="200" y="140" class="st0" width="10" height="10"/>'
            '<rect x="220" y="160" class="st0" width="10" height="10"/>'
            '<rect x="210" y="150" class="st0" width="10" height="10"/>'
            '<rect x="190" y="150" class="st0" width="10" height="10"/>'
        '</g>'        
    ];

    string[] public mouths = [
        '<g>' //ga
            '<rect x="170" y="200" class="st0" width="10" height="10"/>'
            '<rect x="180" y="210" class="st0" width="10" height="10"/>'
            '<rect x="170" y="220" class="st0" width="10" height="10"/>'
            '<rect x="160" y="230" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //na
            '<rect x="170" y="210" class="st0" width="10" height="10"/>'
            '<rect x="180" y="220" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //da
            '<rect x="170" y="210" class="st0" width="10" height="10"/>'
            '<rect x="180" y="220" class="st0" width="10" height="10"/>'
            '<rect x="180" y="200" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //la
            '<rect x="170" y="220" class="st0" width="10" height="10"/>'
            '<rect x="170" y="200" class="st0" width="10" height="10"/>'
            '<rect x="180" y="230" class="st0" width="10" height="10"/>'
            '<rect x="180" y="210" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ma
            '<rect x="170" y="220" class="st0" width="10" height="10"/>'
            '<rect x="180" y="210" class="st0" width="10" height="10"/>'
            '<rect x="190" y="220" class="st0" width="10" height="10"/>'
            '<rect x="170" y="200" class="st0" width="10" height="10"/>'
            '<rect x="190" y="200" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ba
            '<rect x="170" y="220" class="st0" width="10" height="10"/>'
            '<rect x="170" y="200" class="st0" width="10" height="10"/>'
            '<rect x="190" y="220" class="st0" width="10" height="10"/>'
            '<rect x="190" y="200" class="st0" width="10" height="10"/>'
            '<rect x="180" y="230" class="st0" width="10" height="10"/>'
            '<rect x="180" y="210" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //sa
            '<rect x="170" y="220" class="st0" width="10" height="10"/>'
            '<rect x="190" y="220" class="st0" width="10" height="10"/>'
            '<rect x="190" y="200" class="st0" width="10" height="10"/>'
            '<rect x="180" y="210" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //aa
            '<rect x="180" y="220" class="st0" width="10" height="10"/>'
            '<rect x="180" y="200" class="st0" width="10" height="10"/>'
            '<rect x="190" y="210" class="st0" width="10" height="10"/>'
            '<rect x="170" y="210" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ja
            '<rect x="170" y="230" class="st0" width="10" height="10"/>'
            '<rect x="180" y="220" class="st0" width="10" height="10"/>'
            '<rect x="190" y="230" class="st0" width="10" height="10"/>'
            '<rect x="180" y="200" class="st0" width="10" height="10"/>'
            '<rect x="190" y="210" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //cha
            '<rect x="170" y="230" class="st0" width="10" height="10"/>'
            '<rect x="180" y="220" class="st0" width="10" height="10"/>'
            '<rect x="190" y="230" class="st0" width="10" height="10"/>'
            '<rect x="170" y="190" class="st0" width="10" height="10"/>'
            '<rect x="180" y="200" class="st0" width="10" height="10"/>'
            '<rect x="190" y="210" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ka
            '<rect x="170" y="210" class="st0" width="10" height="10"/>'
            '<rect x="170" y="230" class="st0" width="10" height="10"/>'
            '<rect x="170" y="190" class="st0" width="10" height="10"/>'
            '<rect x="180" y="220" class="st0" width="10" height="10"/>'
            '<rect x="180" y="200" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ta
            '<rect x="180" y="210" class="st0" width="10" height="10"/>'
            '<rect x="180" y="190" class="st0" width="10" height="10"/>'
            '<rect x="180" y="230" class="st0" width="10" height="10"/>'
            '<rect x="170" y="200" class="st0" width="10" height="10"/>'
            '<rect x="170" y="220" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //pa
            '<rect x="160" y="220" class="st0" width="10" height="10"/>'
            '<rect x="170" y="210" class="st0" width="10" height="10"/>'
            '<rect x="190" y="210" class="st0" width="10" height="10"/>'
            '<rect x="180" y="220" class="st0" width="10" height="10"/>'
            '<rect x="200" y="220" class="st0" width="10" height="10"/>'
            '<rect x="160" y="200" class="st0" width="10" height="10"/>'
            '<rect x="180" y="200" class="st0" width="10" height="10"/>'
            '<rect x="200" y="200" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ha
            '<rect x="170" y="220" class="st0" width="10" height="10"/>'
            '<rect x="190" y="220" class="st0" width="10" height="10"/>'
            '<rect x="190" y="200" class="st0" width="10" height="10"/>'
            '<rect x="180" y="230" class="st0" width="10" height="10"/>'
            '<rect x="180" y="210" class="st0" width="10" height="10"/>'
            '<rect x="180" y="190" class="st0" width="10" height="10"/>'
        '</g>',   
        '<g>' //semo
            '<rect x="160" y="220" class="st0" width="10" height="10"/>'
            '<rect x="180" y="220" class="st0" width="10" height="10"/>'
            '<rect x="180" y="200" class="st0" width="10" height="10"/>'
            '<rect x="200" y="220" class="st0" width="10" height="10"/>'
            '<rect x="190" y="210" class="st0" width="10" height="10"/>'
            '<rect x="170" y="210" class="st0" width="10" height="10"/>'
        '</g>'        
    ];    
    
}

contract GenSVG is Ownable {

    address public _nft;

    string[] public leftEyes = [

        '<g>' //ga
            '<rect x="140" y="140" class="st0" width="10" height="10"/>'
            '<rect x="150" y="150" class="st0" width="10" height="10"/>'
            '<rect x="140" y="160" class="st0" width="10" height="10"/>'
            '<rect x="130" y="170" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //na
        '<rect x="140" y="150" class="st0" width="10" height="10"/>'
        '<rect x="150" y="160" class="st0" width="10" height="10"/>'
        '</g>', 
        '<g>' //da
            '<rect x="140" y="150" class="st0" width="10" height="10"/>'
            '<rect x="150" y="160" class="st0" width="10" height="10"/>'
            '<rect x="150" y="140" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //la
            '<rect x="140" y="160" class="st0" width="10" height="10"/>'
            '<rect x="140" y="140" class="st0" width="10" height="10"/>'
            '<rect x="150" y="170" class="st0" width="10" height="10"/>'
            '<rect x="150" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ma
            '<rect x="140" y="160" class="st0" width="10" height="10"/>'
            '<rect x="150" y="150" class="st0" width="10" height="10"/>'
            '<rect x="160" y="160" class="st0" width="10" height="10"/>'
            '<rect x="140" y="140" class="st0" width="10" height="10"/>'
            '<rect x="160" y="140" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ba
            '<rect x="140" y="160" class="st0" width="10" height="10"/>'
            '<rect x="140" y="140" class="st0" width="10" height="10"/>'
            '<rect x="160" y="160" class="st0" width="10" height="10"/>'
            '<rect x="160" y="140" class="st0" width="10" height="10"/>'
            '<rect x="150" y="170" class="st0" width="10" height="10"/>'
            '<rect x="150" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //sa
            '<rect x="140" y="160" class="st0" width="10" height="10"/>'
            '<rect x="160" y="160" class="st0" width="10" height="10"/>'
            '<rect x="160" y="140" class="st0" width="10" height="10"/>'
            '<rect x="150" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //Aa
            '<rect x="150" y="160" class="st0" width="10" height="10"/>'
            '<rect x="150" y="140" class="st0" width="10" height="10"/>'
            '<rect x="160" y="150" class="st0" width="10" height="10"/>'
            '<rect x="140" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //Ja
            '<rect x="140" y="170" class="st0" width="10" height="10"/>'
            '<rect x="150" y="160" class="st0" width="10" height="10"/>'
            '<rect x="160" y="170" class="st0" width="10" height="10"/>'
            '<rect x="150" y="140" class="st0" width="10" height="10"/>'
            '<rect x="160" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //Cha
            '<rect x="140" y="170" class="st0" width="10" height="10"/>'
            '<rect x="150" y="160" class="st0" width="10" height="10"/>'
            '<rect x="160" y="170" class="st0" width="10" height="10"/>'
            '<rect x="140" y="130" class="st0" width="10" height="10"/>'
            '<rect x="150" y="140" class="st0" width="10" height="10"/>'
            '<rect x="160" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //Ka
            '<rect x="140" y="150" class="st0" width="10" height="10"/>'
            '<rect x="140" y="170" class="st0" width="10" height="10"/>'
            '<rect x="140" y="130" class="st0" width="10" height="10"/>'
            '<rect x="150" y="160" class="st0" width="10" height="10"/>'
            '<rect x="150" y="140" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //Ta
        '<rect x="150" y="150" class="st0" width="10" height="10"/>'
        '<rect x="150" y="130" class="st0" width="10" height="10"/>'
        '<rect x="150" y="170" class="st0" width="10" height="10"/>'
        '<rect x="140" y="140" class="st0" width="10" height="10"/>'
        '<rect x="140" y="160" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //Pa
            '<rect x="130" y="160" class="st0" width="10" height="10"/>'
            '<rect x="140" y="150" class="st0" width="10" height="10"/>'
            '<rect x="160" y="150" class="st0" width="10" height="10"/>'
            '<rect x="150" y="160" class="st0" width="10" height="10"/>'
            '<rect x="170" y="160" class="st0" width="10" height="10"/>'
            '<rect x="130" y="140" class="st0" width="10" height="10"/>'
            '<rect x="150" y="140" class="st0" width="10" height="10"/>'
            '<rect x="170" y="140" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //Ha
            '<rect x="140" y="160" class="st0" width="10" height="10"/>'
            '<rect x="160" y="160" class="st0" width="10" height="10"/>'
            '<rect x="160" y="140" class="st0" width="10" height="10"/>'
            '<rect x="150" y="170" class="st0" width="10" height="10"/>'
            '<rect x="150" y="150" class="st0" width="10" height="10"/>'
            '<rect x="150" y="130" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //semo
        '<rect x="130" y="160" class="st0" width="10" height="10"/>'
        '<rect x="150" y="160" class="st0" width="10" height="10"/>'
        '<rect x="150" y="140" class="st0" width="10" height="10"/>'
        '<rect x="170" y="160" class="st0" width="10" height="10"/>'
        '<rect x="160" y="150" class="st0" width="10" height="10"/>'
        '<rect x="140" y="150" class="st0" width="10" height="10"/>'
        '</g>'                
    ];

    string[] public rightEyes = [
        '<g>' //ga
            '<rect x="190" y="140" class="st0" width="10" height="10"/>'
            '<rect x="200" y="150" class="st0" width="10" height="10"/>'
            '<rect x="190" y="160" class="st0" width="10" height="10"/>'
            '<rect x="180" y="170" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //na
            '<rect x="190" y="150" class="st0" width="10" height="10"/>'
            '<rect x="200" y="160" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //da
            '<rect x="200" y="150" class="st0" width="10" height="10"/>'
            '<rect x="210" y="160" class="st0" width="10" height="10"/>'
            '<rect x="210" y="140" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //la
            '<rect x="190" y="160" class="st0" width="10" height="10"/>'
            '<rect x="190" y="140" class="st0" width="10" height="10"/>'
            '<rect x="200" y="170" class="st0" width="10" height="10"/>'
            '<rect x="200" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ma
            '<rect x="190" y="160" class="st0" width="10" height="10"/>'
            '<rect x="200" y="150" class="st0" width="10" height="10"/>'
            '<rect x="210" y="160" class="st0" width="10" height="10"/>'
            '<rect x="190" y="140" class="st0" width="10" height="10"/>'
            '<rect x="210" y="140" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ba
            '<rect x="190" y="160" class="st0" width="10" height="10"/>'
            '<rect x="190" y="140" class="st0" width="10" height="10"/>'
            '<rect x="210" y="160" class="st0" width="10" height="10"/>'
            '<rect x="210" y="140" class="st0" width="10" height="10"/>'
            '<rect x="200" y="170" class="st0" width="10" height="10"/>'
            '<rect x="200" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //sa
            '<rect x="190" y="160" class="st0" width="10" height="10"/>'
            '<rect x="210" y="160" class="st0" width="10" height="10"/>'
            '<rect x="210" y="140" class="st0" width="10" height="10"/>'
            '<rect x="200" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //aa
            '<rect x="200" y="160" class="st0" width="10" height="10"/>'
            '<rect x="200" y="140" class="st0" width="10" height="10"/>'
            '<rect x="210" y="150" class="st0" width="10" height="10"/>'
            '<rect x="190" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ja
            '<rect x="190" y="170" class="st0" width="10" height="10"/>'
            '<rect x="200" y="160" class="st0" width="10" height="10"/>'
            '<rect x="210" y="170" class="st0" width="10" height="10"/>'
            '<rect x="200" y="140" class="st0" width="10" height="10"/>'
            '<rect x="210" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //cha
            '<rect x="190" y="170" class="st0" width="10" height="10"/>'
            '<rect x="200" y="160" class="st0" width="10" height="10"/>'
            '<rect x="210" y="170" class="st0" width="10" height="10"/>'
            '<rect x="190" y="130" class="st0" width="10" height="10"/>'
            '<rect x="200" y="140" class="st0" width="10" height="10"/>'
            '<rect x="210" y="150" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ka
            '<rect x="190" y="150" class="st0" width="10" height="10"/>'
            '<rect x="190" y="170" class="st0" width="10" height="10"/>'
            '<rect x="190" y="130" class="st0" width="10" height="10"/>'
            '<rect x="200" y="160" class="st0" width="10" height="10"/>'
            '<rect x="200" y="140" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ta
            '<rect x="200" y="150" class="st0" width="10" height="10"/>'
            '<rect x="200" y="130" class="st0" width="10" height="10"/>'
            '<rect x="200" y="170" class="st0" width="10" height="10"/>'
            '<rect x="190" y="140" class="st0" width="10" height="10"/>'
            '<rect x="190" y="160" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //pa
            '<rect x="180" y="160" class="st0" width="10" height="10"/>'
            '<rect x="190" y="150" class="st0" width="10" height="10"/>'
            '<rect x="210" y="150" class="st0" width="10" height="10"/>'
            '<rect x="200" y="160" class="st0" width="10" height="10"/>'
            '<rect x="220" y="160" class="st0" width="10" height="10"/>'
            '<rect x="180" y="140" class="st0" width="10" height="10"/>'
            '<rect x="200" y="140" class="st0" width="10" height="10"/>'
            '<rect x="220" y="140" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ha
            '<rect x="190" y="160" class="st0" width="10" height="10"/>'
            '<rect x="210" y="160" class="st0" width="10" height="10"/>'
            '<rect x="210" y="140" class="st0" width="10" height="10"/>'
            '<rect x="200" y="170" class="st0" width="10" height="10"/>'
            '<rect x="200" y="150" class="st0" width="10" height="10"/>'
            '<rect x="200" y="130" class="st0" width="10" height="10"/>'
        '</g>',   
        '<g>' //semo
            '<rect x="180" y="160" class="st0" width="10" height="10"/>'
            '<rect x="200" y="160" class="st0" width="10" height="10"/>'
            '<rect x="200" y="140" class="st0" width="10" height="10"/>'
            '<rect x="220" y="160" class="st0" width="10" height="10"/>'
            '<rect x="210" y="150" class="st0" width="10" height="10"/>'
            '<rect x="190" y="150" class="st0" width="10" height="10"/>'
        '</g>'        
    ];

    string[] public mouths = [
        '<g>' //ga
            '<rect x="170" y="200" class="st0" width="10" height="10"/>'
            '<rect x="180" y="210" class="st0" width="10" height="10"/>'
            '<rect x="170" y="220" class="st0" width="10" height="10"/>'
            '<rect x="160" y="230" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //na
            '<rect x="170" y="210" class="st0" width="10" height="10"/>'
            '<rect x="180" y="220" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //da
            '<rect x="170" y="210" class="st0" width="10" height="10"/>'
            '<rect x="180" y="220" class="st0" width="10" height="10"/>'
            '<rect x="180" y="200" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //la
            '<rect x="170" y="220" class="st0" width="10" height="10"/>'
            '<rect x="170" y="200" class="st0" width="10" height="10"/>'
            '<rect x="180" y="230" class="st0" width="10" height="10"/>'
            '<rect x="180" y="210" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ma
            '<rect x="170" y="220" class="st0" width="10" height="10"/>'
            '<rect x="180" y="210" class="st0" width="10" height="10"/>'
            '<rect x="190" y="220" class="st0" width="10" height="10"/>'
            '<rect x="170" y="200" class="st0" width="10" height="10"/>'
            '<rect x="190" y="200" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ba
            '<rect x="170" y="220" class="st0" width="10" height="10"/>'
            '<rect x="170" y="200" class="st0" width="10" height="10"/>'
            '<rect x="190" y="220" class="st0" width="10" height="10"/>'
            '<rect x="190" y="200" class="st0" width="10" height="10"/>'
            '<rect x="180" y="230" class="st0" width="10" height="10"/>'
            '<rect x="180" y="210" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //sa
            '<rect x="170" y="220" class="st0" width="10" height="10"/>'
            '<rect x="190" y="220" class="st0" width="10" height="10"/>'
            '<rect x="190" y="200" class="st0" width="10" height="10"/>'
            '<rect x="180" y="210" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //aa
            '<rect x="180" y="220" class="st0" width="10" height="10"/>'
            '<rect x="180" y="200" class="st0" width="10" height="10"/>'
            '<rect x="190" y="210" class="st0" width="10" height="10"/>'
            '<rect x="170" y="210" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ja
            '<rect x="170" y="230" class="st0" width="10" height="10"/>'
            '<rect x="180" y="220" class="st0" width="10" height="10"/>'
            '<rect x="190" y="230" class="st0" width="10" height="10"/>'
            '<rect x="180" y="200" class="st0" width="10" height="10"/>'
            '<rect x="190" y="210" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //cha
            '<rect x="170" y="230" class="st0" width="10" height="10"/>'
            '<rect x="180" y="220" class="st0" width="10" height="10"/>'
            '<rect x="190" y="230" class="st0" width="10" height="10"/>'
            '<rect x="170" y="190" class="st0" width="10" height="10"/>'
            '<rect x="180" y="200" class="st0" width="10" height="10"/>'
            '<rect x="190" y="210" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ka
            '<rect x="170" y="210" class="st0" width="10" height="10"/>'
            '<rect x="170" y="230" class="st0" width="10" height="10"/>'
            '<rect x="170" y="190" class="st0" width="10" height="10"/>'
            '<rect x="180" y="220" class="st0" width="10" height="10"/>'
            '<rect x="180" y="200" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ta
            '<rect x="180" y="210" class="st0" width="10" height="10"/>'
            '<rect x="180" y="190" class="st0" width="10" height="10"/>'
            '<rect x="180" y="230" class="st0" width="10" height="10"/>'
            '<rect x="170" y="200" class="st0" width="10" height="10"/>'
            '<rect x="170" y="220" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //pa
            '<rect x="160" y="220" class="st0" width="10" height="10"/>'
            '<rect x="170" y="210" class="st0" width="10" height="10"/>'
            '<rect x="190" y="210" class="st0" width="10" height="10"/>'
            '<rect x="180" y="220" class="st0" width="10" height="10"/>'
            '<rect x="200" y="220" class="st0" width="10" height="10"/>'
            '<rect x="160" y="200" class="st0" width="10" height="10"/>'
            '<rect x="180" y="200" class="st0" width="10" height="10"/>'
            '<rect x="200" y="200" class="st0" width="10" height="10"/>'
        '</g>',
        '<g>' //ha
            '<rect x="170" y="220" class="st0" width="10" height="10"/>'
            '<rect x="190" y="220" class="st0" width="10" height="10"/>'
            '<rect x="190" y="200" class="st0" width="10" height="10"/>'
            '<rect x="180" y="230" class="st0" width="10" height="10"/>'
            '<rect x="180" y="210" class="st0" width="10" height="10"/>'
            '<rect x="180" y="190" class="st0" width="10" height="10"/>'
        '</g>',   
        '<g>' //semo
            '<rect x="160" y="220" class="st0" width="10" height="10"/>'
            '<rect x="180" y="220" class="st0" width="10" height="10"/>'
            '<rect x="180" y="200" class="st0" width="10" height="10"/>'
            '<rect x="200" y="220" class="st0" width="10" height="10"/>'
            '<rect x="190" y="210" class="st0" width="10" height="10"/>'
            '<rect x="170" y="210" class="st0" width="10" height="10"/>'
        '</g>'        
    ];

    string[] public beards = [
        '',
        '<g>'
            '<rect x="200" y="240" class="st0" width="10" height="30"/>'
            '<rect x="190" y="250" class="st0" width="10" height="30"/>'
            '<rect x="180" y="250" class="st0" width="10" height="40"/>'
            '<rect x="170" y="250" class="st0" width="10" height="30"/>'
            '<rect x="160" y="240" class="st0" width="10" height="30"/>'
        '</g>'
    ];

    string[] public chins = [
        '',
        '<g>' //scar
            '<rect x="110" y="180" class="st0" width="10" height="50"/>'
            '<rect x="100" y="190" class="st0" width="30" height="10"/>'
            '<rect x="100" y="210" class="st0" width="30" height="10"/>'
        '</g>',
        '<g>' //flushing
            '<rect x="110" y="190" class="st0" width="10" height="10"/>'
            '<rect x="120" y="180" class="st0" width="10" height="10"/>'
            '<rect x="100" y="180" class="st0" width="10" height="10"/>'
            '<rect x="130" y="190" class="st0" width="10" height="10"/>'
            '<rect x="140" y="180" class="st0" width="10" height="10"/>'
        '</g>'                
    ];

    string[] public hats = [
        '',
        '<rect x="60" y="40" width="180" height="90"/>'        
        '<g>'
            '<rect x="70" y="80" class="st0" width="10" height="50"/>'
            '<rect x="60" y="40" class="st0" width="10" height="40"/>'
            '<rect x="150" y="80" class="st0" width="10" height="50"/>'
            '<rect x="140" y="40" class="st0" width="10" height="40"/>'
            '<rect x="110" y="80" class="st0" width="10" height="50"/>'
            '<rect x="100" y="40" class="st0" width="10" height="40"/>'
            '<rect x="190" y="80" class="st0" width="10" height="50"/>'
            '<rect x="180" y="40" class="st0" width="10" height="40"/>'
            '<rect x="230" y="80" class="st0" width="10" height="50"/>'
            '<rect x="220" y="40" class="st0" width="10" height="40"/>'
            '<rect x="90" y="80" class="st0" width="10" height="50"/>'
            '<rect x="80" y="40" class="st0" width="10" height="40"/>'
            '<rect x="170" y="80" class="st0" width="10" height="50"/>'
            '<rect x="160" y="40" class="st0" width="10" height="40"/>'
            '<rect x="130" y="80" class="st0" width="10" height="50"/>'
            '<rect x="120" y="40" class="st0" width="10" height="40"/>'
            '<rect x="210" y="80" class="st0" width="10" height="50"/>'
            '<rect x="200" y="40" class="st0" width="10" height="40"/>'
        '</g>',
        '<rect x="60" y="40" width="180" height="90"/>'
        '<g>'
            '<rect x="60" y="100" class="st0" width="10" height="30"/>'
            '<rect x="70" y="70" class="st0" width="10" height="30"/>'
            '<rect x="60" y="40" class="st0" width="10" height="30"/>'
            '<rect x="80" y="100" class="st0" width="10" height="30"/>'
            '<rect x="90" y="70" class="st0" width="10" height="30"/>'
            '<rect x="80" y="40" class="st0" width="10" height="30"/>'
            '<rect x="100" y="100" class="st0" width="10" height="30"/>'
            '<rect x="110" y="70" class="st0" width="10" height="30"/>'
            '<rect x="100" y="40" class="st0" width="10" height="30"/>'
            '<rect x="120" y="100" class="st0" width="10" height="30"/>'
            '<rect x="130" y="70" class="st0" width="10" height="30"/>'
            '<rect x="120" y="40" class="st0" width="10" height="30"/>'
            '<rect x="140" y="100" class="st0" width="10" height="30"/>'
            '<rect x="150" y="70" class="st0" width="10" height="30"/>'
            '<rect x="140" y="40" class="st0" width="10" height="30"/>'
            '<rect x="160" y="100" class="st0" width="10" height="30"/>'
            '<rect x="170" y="70" class="st0" width="10" height="30"/>'
            '<rect x="160" y="40" class="st0" width="10" height="30"/>'
            '<rect x="180" y="100" class="st0" width="10" height="30"/>'
            '<rect x="190" y="70" class="st0" width="10" height="30"/>'
            '<rect x="180" y="40" class="st0" width="10" height="30"/>'
            '<rect x="200" y="100" class="st0" width="10" height="30"/>'
            '<rect x="210" y="70" class="st0" width="10" height="30"/>'
            '<rect x="200" y="40" class="st0" width="10" height="30"/>'
            '<rect x="220" y="100" class="st0" width="10" height="30"/>'
            '<rect x="230" y="70" class="st0" width="10" height="30"/>'
            '<rect x="220" y="40" class="st0" width="10" height="30"/>'
        '</g>',
        '<rect x="60" y="40" width="180" height="90"/>'
        '<g>'
            '<rect x="60" y="100" class="st0" width="10" height="30"/>'
            '<rect x="90" y="100" class="st0" width="10" height="30"/>'
            '<rect x="120" y="100" class="st0" width="10" height="30"/>'
            '<rect x="140" y="100" class="st0" width="10" height="30"/>'
            '<rect x="190" y="100" class="st0" width="10" height="30"/>'
            '<rect x="210" y="100" class="st0" width="10" height="30"/>'
            '<rect x="230" y="100" class="st0" width="10" height="30"/>'
            '<rect x="230" y="40" class="st0" width="10" height="30"/>'
            '<rect x="180" y="40" class="st0" width="10" height="30"/>'
            '<rect x="150" y="40" class="st0" width="10" height="30"/>'
            '<rect x="120" y="40" class="st0" width="10" height="30"/>'
            '<rect x="90" y="40" class="st0" width="10" height="30"/>'
            '<rect x="60" y="40" class="st0" width="10" height="30"/>'
            '<rect x="70" y="70" class="st0" width="10" height="30"/>'
            '<rect x="100" y="70" class="st0" width="10" height="30"/>'
            '<rect x="130" y="70" class="st0" width="10" height="30"/>'
            '<rect x="160" y="70" class="st0" width="10" height="30"/>'
            '<rect x="200" y="70" class="st0" width="10" height="30"/>'
            '<rect x="220" y="70" class="st0" width="10" height="30"/>'
            '<rect x="240" y="70" class="st0" width="10" height="30"/>'
            '<rect x="240" y="30" class="st0" width="10" height="10"/>'
            '<rect x="190" y="30" class="st0" width="10" height="10"/>'
            '<rect x="160" y="30" class="st0" width="10" height="10"/>'
            '<rect x="130" y="30" class="st0" width="10" height="10"/>'
            '<rect x="100" y="30" class="st0" width="10" height="10"/>'
            '<rect x="70" y="30" class="st0" width="10" height="10"/>'
        '</g>'        
    ];

    string[] public heads = [ //face shape
        '<rect width="300" height="300"/>'
        '<g>'
            '<rect x="50" y="150" class="st0" width="10" height="30"/>'
            '<rect x="60" y="140" class="st0" width="20" height="10"/>'
            '<rect x="60" y="180" class="st0" width="10" height="10"/>'
            '<rect x="70" y="190" class="st0" width="10" height="10"/>'
            '<rect x="220" y="200" class="st0" width="10" height="50"/>'
            '<rect x="230" y="180" class="st0" width="10" height="20"/>'
            '<rect x="90" y="40" class="st0" width="80" height="10"/>'
            '<rect x="70" y="70" class="st0" width="10" height="60"/>'
            '<rect x="230" y="70" class="st0" width="10" height="60"/>'
            '<rect x="170" y="50" class="st0" width="50" height="10"/>'
            '<rect x="80" y="50" class="st0" width="10" height="20"/>'
            '<rect x="220" y="60" class="st0" width="10" height="10"/>'
            '<rect x="150" y="250" class="st0" width="70" height="10"/>'
        '</g>',
        '<rect width="300" height="300"/>'
        '<g>'
            '<rect x="50" y="150" class="st0" width="10" height="30"/>'
            '<rect x="60" y="140" class="st0" width="20" height="10"/>'
            '<rect x="60" y="180" class="st0" width="10" height="10"/>'
            '<rect x="70" y="190" class="st0" width="10" height="10"/>'
            '<rect x="220" y="220" class="st0" width="10" height="20"/>'
            '<rect x="220" y="180" class="st0" width="10" height="20"/>'
            '<rect x="230" y="200" class="st0" width="10" height="20"/>'
            '<rect x="90" y="40" class="st0" width="80" height="10"/>'
            '<rect x="70" y="70" class="st0" width="10" height="60"/>'
            '<rect x="230" y="80" class="st0" width="10" height="50"/>'
            '<rect x="170" y="50" class="st0" width="50" height="10"/>'
            '<rect x="80" y="50" class="st0" width="10" height="20"/>'
            '<rect x="220" y="60" class="st0" width="10" height="20"/>'
            '<rect x="210" y="240" class="st0" width="10" height="10"/>'
            '<rect x="160" y="250" class="st0" width="50" height="10"/>'
            '<rect x="120" y="240" class="st0" width="40" height="10"/>'
        '</g>',
        '<rect width="300" height="300"/>'
        '<g>'
            '<rect x="50" y="150" class="st0" width="10" height="30"/>'
            '<rect x="60" y="140" class="st0" width="20" height="10"/>'
            '<rect x="60" y="180" class="st0" width="10" height="10"/>'
            '<rect x="70" y="190" class="st0" width="10" height="10"/>'
            '<rect x="220" y="200" class="st0" width="10" height="30"/>'
            '<rect x="230" y="180" class="st0" width="10" height="20"/>'
            '<rect x="90" y="40" class="st0" width="80" height="10"/>'
            '<rect x="70" y="70" class="st0" width="10" height="60"/>'
            '<rect x="230" y="70" class="st0" width="10" height="60"/>'
            '<rect x="170" y="50" class="st0" width="50" height="10"/>'
            '<rect x="80" y="50" class="st0" width="10" height="20"/>'
            '<rect x="220" y="60" class="st0" width="10" height="10"/>'
            '<rect x="210" y="250" class="st0" width="20" height="10"/>'
            '<rect x="230" y="230" class="st0" width="10" height="20"/>'
            '<rect x="180" y="260" class="st0" width="30" height="10"/>'
            '<rect x="150" y="250" class="st0" width="30" height="10"/>'
            '<rect x="120" y="240" class="st0" width="30" height="10"/>'
        '</g>'
    ];

    string[] public tabacos = [
        '',
        '<rect x="210" y="210" width="50" height="30"/>'
        '<g>'
            '<rect x="210" y="220" class="st0" width="50" height="10"/>'
            '<rect x="260" y="210" class="st0" width="10" height="10"/>'
            '<rect x="270" y="200" class="st0" width="10" height="10"/>'
            '<rect x="260" y="190" class="st0" width="10" height="10"/>'
            '<rect x="270" y="180" class="st0" width="10" height="10"/>'
            '<rect x="260" y="160" class="st0" width="10" height="10"/>'
            '<rect x="270" y="140" class="st0" width="10" height="10"/>'
        '</g>'
    ];

    function generateSvg(uint _chin, uint _head,  uint _beard, uint _tabaco, uint _mouth, uint _leftEye, uint _rightEye, uint _hat)
        public view 
        returns (string memory) {
        
        string[10] memory parts;
        parts[0] = '<?xml version="1.0" encoding="utf-8"?>'
                    '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
                    'x="0px" y="0px" viewBox="0 0 300 300" style="enable-background:new 0 0 300 300;" xml:space="preserve">'
                    '<style type="text/css"> .st0{fill:#FF7777}</style>'
                    '<rect width="300" height="300"/>';        
        // face
        parts[1] = chins[_chin]; // scar, dot        
        parts[2] = heads[_head];      
        parts[3] = beards[_beard];     
        parts[4] = tabacos[_tabaco];
        parts[5] = mouths[_mouth];
        parts[6] = rightEyes[_rightEye];
        parts[7] = leftEyes[_leftEye];
        parts[8] = hats[_hat];
        parts[9] = '</svg>';

        string memory svg = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]));
        svg = string(abi.encodePacked(svg, parts[5], parts[6], parts[7], parts[8], parts[9]));
        return svg;
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }    
}