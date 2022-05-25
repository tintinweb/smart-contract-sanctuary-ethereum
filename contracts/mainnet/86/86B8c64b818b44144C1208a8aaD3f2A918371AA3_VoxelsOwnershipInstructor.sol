// File: Interfaces/IOwnershipInstructor.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * This is an interface of OwnershipInstructor
 * The goal of this contract is to allow people to integrate their contract into OwnershipChecker.sol
 * by generalising the obtention of the owner of NFTs.
 * The reason for this solution was because NFTs nowadays have standards, but not all NFTs support these standards.
 * The interface id for this is 0xb0f6fd7f;
 */
interface IOwnershipInstructor{

/**
 * isValidInterface()
 * This function should be public and should be overriden.
 * It should obtain an address as input and should return a boolean value;
 * A positive result means the given address supports your contract's interface.
 * @dev This should be overriden and replaced with a set of instructions to check the given _impl if your contract's interface.
 * See ERC165 for help on interface support.
 * @param _impl address we want to check.
 * @return bool
 * 
 */
  function isValidInterface (address _impl) external view returns (bool);

    /**
    * This function should be public or External and should be overriden.
    * It should obtain an address as implementation, a uint256 token Id and an optional _potentialOwner;
    * It should return an address (or address zero is no owner);
    * @dev This should be overriden and replaced with a set of instructions obtaining the owner of the given tokenId;
    *
    * @param _tokenId token id we want to grab the owner of.
    * @param _impl Address of the NFT contract
    * @param _potentialOwner (OPTIONAL) A potential owner, set address zero if no potentialOwner; Necessary for ERC1155
    * @return a non zero address if the given tokenId has an owner; else if the token Id does not exist or has no owner, return zero address
    * 
    */
    function ownerOfTokenOnImplementation(address _impl,uint256 _tokenId,address _potentialOwner) external view  returns (address);
}
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: contracts/VoxelsOwnershipInstructor.sol


interface ICryptovoxelsContract {
    function ownerOf(uint256 _tokenId) external view returns (address _owner);
}

/**
 * Ownership Instructor Wrapper that wraps around the Voxels (cryptovoxels) contract,
 *
 * This is because cryptovoxels does not support the ERC721 interface.
 */
contract VoxelsOwnershipInstructor is IERC165,IOwnershipInstructor,Ownable{
    address cvAddress = 0x79986aF15539de2db9A5086382daEdA917A9CF0C;
    constructor(){
    }
    /**
     * @dev NOT AN EXAMPLE
     * @dev We know the Voxels contract address will change in the future.
     * This lets us change the address without redeploying a new contract.
     * Normally an OwnershipInstructor contract should be immutable.
     * @param _impl address of Voxels
     */
    function setVoxelsAddress(address _impl) external onlyOwner {
        cvAddress = _impl;
    }

    /**
    * Checks if the given contract is the voxels address
    * It should obtain an address as input and should return a boolean value;
    * @dev Contains a set of instructions to check the given _impl is the voxels contract
    * @param _impl address we want to check.
    * @return bool
    * 
    */
    function isValidInterface (address _impl) public view override returns (bool){
        return _impl == cvAddress;
    }

    /**
    * See {OwnershipInstructor.sol}
    * It should obtain a uint256 token Id as input and the address of the implementation 
    * It should return an address (or address zero is no owner);
    *
    * @param _tokenId token id we want to grab the owner of.
    * @param _impl Address of the NFT contract
    * @param _potentialOwner (OPTIONAL) A potential owner, set address zero if no potentialOwner;
    * @return address
    * 
    */
    function ownerOfTokenOnImplementation(address _impl,uint256 _tokenId,address _potentialOwner) public view override returns (address){
        require(isValidInterface(_impl),"Invalid interface");
        return ICryptovoxelsContract(_impl).ownerOf(_tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IOwnershipInstructor).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}