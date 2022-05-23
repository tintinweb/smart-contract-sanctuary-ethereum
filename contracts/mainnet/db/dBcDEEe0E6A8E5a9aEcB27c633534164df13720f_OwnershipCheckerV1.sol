//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./Interfaces/IOwnershipInstructorRegisterV1.sol";
import "./Interfaces/IOwnershipInstructor.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Goes through a register of contracts and checks for ownership of an on-chain token.
 */
contract OwnershipCheckerV1 is ERC165,Ownable {

    string internal _name;
    string internal _symbol;

    address public register;

    event NewRegister(address indexed register);

    constructor(address _register){
        _name="OwnershipCheckerV1";
        _symbol = "CHECK";
        register = _register;
    }

    function name() public view returns (string memory){
        return _name;
    }
    
    function symbol() public view returns (string memory){
        return _symbol;
    }

    function setRegisterImplementation(address _register) public onlyOwner{
         register = _register;
        emit NewRegister( _register);
    }


    function ownerOfTokenAt(address _impl,uint256 _tokenId,address _potentialOwner) external view  returns (address){
        IOwnershipInstructorRegisterV1.Instructor memory object = IOwnershipInstructorRegisterV1(register).instructorGivenImplementation(_impl);
        if(object._impl == address(0)){
            return address(0);
        }else{
            return IOwnershipInstructor(object._impl).ownerOfTokenOnImplementation(_impl, _tokenId, _potentialOwner);
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;




interface IOwnershipInstructorRegisterV1 {
    struct Instructor{
        address _impl;
        string _name;
    }
  

    event NewInstructor(address indexed _instructor,string _name);
    event RemovedInstructor(address indexed _instructor,string _name);
    event UnlinkedImplementation(string indexed _name,address indexed _implementation);
    event LinkedImplementation(string indexed _name,address indexed _implementation);



    function name() external view returns (string memory);

    function getInstructorByName (string memory _name) external view returns(Instructor memory);

    /**
     * @dev Paginated to avoid risk of DoS.
     * @notice Function that returns the implementations of a given Instructor (pages of 150 elements)
     * @param _name name of instructor
     * @param page page index, 0 is the first 150 elements of the list of implementation.
     * @return _addresses list of implementations and _nextpage is the index of the next page, _nextpage is 0 if there is no more pages.
     */
    function getImplementationsOf(string memory _name,uint256 page)
        external
        view
        returns (address[] memory _addresses,uint256 _nextpage);


      /**
     * @dev Paginated to avoid risk of DoS.
     * @notice Function that returns the list of Instructor names (pages of 150 elements)
     * @param page page index, 0 is the first 150 elements of the list of implementation.
     * @return _names list of instructor names and _nextpage is the index of the next page, _nextpage is 0 if there are no more pages.
     */
    function getListOfInstructorNames(uint256 page)
        external
        view
        returns (string[] memory _names,uint256 _nextpage);

    function addInstructor(address _instructor,string memory _name) external;
    function addInstructorAndImplementation(address _instructor,string memory _name, address _implementation) external;

    function linkImplementationToInstructor(address _implementation,string memory _name) external;
    function unlinkImplementationToInstructor(address _impl) external;

    function removeInstructor(string memory _name) external;

    function instructorGivenImplementation(address _impl)external view returns (Instructor memory _instructor);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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