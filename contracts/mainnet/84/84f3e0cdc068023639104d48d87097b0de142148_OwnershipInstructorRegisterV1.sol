/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

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

// File: Interfaces/IOwnershipInstructor.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165Checker.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)


/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
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

// File: InstructorRegister.sol



/**
 * A register of OwnershipInstructor contracts that helps standardize "ownerOf" for NFTs.
 */
contract OwnershipInstructorRegisterV1 is Ownable,IOwnershipInstructorRegisterV1 {
    bytes4 public immutable INSTRUCTOR_ID = type(IOwnershipInstructor).interfaceId;
    using ERC165Checker for address;
    ///@dev name of the contract
    string internal __name;

    ///@dev list of Ownership instructor contracts
    Instructor[] public instructorRegister;
    /**
     * Hashed Name to instructorIndex lookup 
     */
    mapping(bytes32 => uint256) internal nameToinstructorIndex;

    ///@dev name (hashed) of instructor to list of implementations
    mapping(address => string) public implementationToInstructorName;

    ///@dev name (hashed) of instructor to list of implementations
    mapping(bytes32=>address[]) internal instructorNameToImplementationList;

    ///@dev implementation address to index inside instructorNameToImplementationList
    mapping(address => uint256) internal implementationIndex;

    /**
     * Useful for knowing if a contract has already been registered
     */
    mapping(bytes32=>bool) internal registeredHash;    
    /**
     * Useful for knowing if a Contract Instructor name has already been registered
     */
    mapping(bytes32=>bool) internal registeredName;

    // event NewInstructor(address indexed _instructor,string _name);
    // event RemovedInstructor(address indexed _instructor,string _name);
    // event UnlinkedImplementation(string indexed _name,address indexed _implementation);
    // event LinkedImplementation(string indexed _name,address indexed _implementation);

    constructor(){
        __name="OwnershipInstructorRegisterV1";
    }

    function hashInstructor(address _instructor) internal view returns (bytes32 _hash){
        return keccak256(_instructor.code);
    }

    function hashName(string memory _name) internal pure returns (bytes32 _hash){
        return keccak256(abi.encode(_name));
    }

    function name() public view returns (string memory){
        return __name;
    }

    function getInstructorByName (string memory _name) public view returns(Instructor memory){
        bytes32 _hash =hashName(_name);
        require(registeredName[_hash],"Name does not exist");
        return instructorRegister[nameToinstructorIndex[_hash]];
    }
    ///@dev the max number of items to show per page;
    ///@dev only used in getImplementationsOf()
    uint256 private constant _maxItemsPerPage = 150;
    /**
     * @dev Paginated to avoid risk of DoS.
     * @notice Function that returns the implementations of a given Instructor (pages of 150 elements)
     * @param _name name of instructor
     * @param page page index, 0 is the first 150 elements of the list of implementation.
     * @return _addresses list of implementations and _nextpage is the index of the next page, _nextpage is 0 if there is no more pages.
     */
    function getImplementationsOf(string memory _name,uint256 page)
        public
        view
        returns (address[] memory _addresses,uint256 _nextpage)
    {
        bytes32 _nameHash =hashName(_name);
        require(registeredName[_nameHash],"Name does not exist");
        uint256 size = instructorNameToImplementationList[_nameHash].length;
        uint256 offset = page*_maxItemsPerPage;
        uint256 resultSize;
        if(size>= _maxItemsPerPage+offset){
            // size is above or equal to 150* page index + 150
            resultSize = _maxItemsPerPage;
        }else if (size< _maxItemsPerPage+offset){
            // size is less than 150* page index + 150
            resultSize = size - offset;
        }
        address[] memory addresses = new address[](resultSize);
        uint256 index = 0;
        for (uint256 i = offset; i < resultSize+offset; i++) {
            addresses[index] = instructorNameToImplementationList[_nameHash][i];
            index++;
        }
        if(size<=(addresses.length+offset)){
            return (addresses,0);
        }else{
            return (addresses,page+1);
        }
        
    }

      /**
     * @dev Paginated to avoid risk of DoS.
     * @notice Function that returns the list of Instructor names (pages of 150 elements)
     * @param page page index, 0 is the first 150 elements of the list of implementation.
     * @return _names list of instructor names and _nextpage is the index of the next page, _nextpage is 0 if there are no more pages.
     */
    function getListOfInstructorNames(uint256 page)
        public
        view
        returns (string[] memory _names,uint256 _nextpage)
    {

        uint256 size = instructorRegister.length;
        uint256 offset = page*_maxItemsPerPage;
        uint256 resultSize;
        if(size>= _maxItemsPerPage+offset){
            // size is above or equal to 150* page index + 150
            resultSize = _maxItemsPerPage;
        }else if (size< _maxItemsPerPage+offset){
            // size is less than 150* page index + 150
            resultSize = size - offset;
        }
        string[] memory names = new string[](resultSize);
        uint256 index = 0;
        for (uint256 i = offset; i < resultSize+offset; i++) {
            names[index] = instructorRegister[i]._name;
            index++;
        }
        if(size<=(names.length+offset)){
            return (names,0);
        }else{
            return (names,page+1);
        }
        
    }

    function _safeAddInstructor(address _instructor,string memory _name) private {
        bytes32 _hash = hashInstructor(_instructor);
        bytes32 _nameHash = hashName(_name);
        require(!registeredHash[_hash],"Instructor has already been registered");
        require(!registeredName[_nameHash],"Instructor Name already taken");

        Instructor memory _inst = Instructor(_instructor,_name);

        instructorRegister.push(_inst);
        //instructor inserted at last index.
        nameToinstructorIndex[_nameHash]=instructorRegister.length-1;

        registeredHash[_hash]=true;
        registeredName[_nameHash]=true;
    }

    function addInstructor(address _instructor,string memory _name) public onlyOwner {
        require(_instructor !=address(0),"Instructor address cannot be address zero");
        require(bytes(_name).length>4,"Name is too short");
        require(_instructor.supportsInterface(INSTRUCTOR_ID),"Contract does not support instructor interface");

        _safeAddInstructor( _instructor, _name);

        emit NewInstructor(_instructor, _name);
    }

    function addInstructorAndImplementation(address _instructor,string memory _name, address _implementation) public onlyOwner {
        addInstructor(_instructor,_name);
        
        linkImplementationToInstructor( _implementation, _name);
    }

    function linkImplementationToInstructor(address _implementation,string memory _name) public onlyOwner {
        require(bytes(implementationToInstructorName[_implementation]).length==0,"Implementation already linked to an instructor");
        bytes32 _hash =hashName(_name);
        require(registeredName[_hash],"Name does not exist");

        implementationToInstructorName[_implementation]=_name;
        instructorNameToImplementationList[_hash].push(_implementation);
        implementationIndex[_implementation] = instructorNameToImplementationList[hashName(_name)].length-1;
        // emit event;
        emit LinkedImplementation(implementationToInstructorName[_implementation], _implementation);
        
    }

    function unlinkImplementationToInstructor(address _impl) public onlyOwner {
        require(bytes(implementationToInstructorName[_impl]).length!=0,"Implementation already not linked to any instructor.");
        bytes32 _hashName = hashName(implementationToInstructorName[_impl]);

        uint256 indexOfImplementation = implementationIndex[_impl];
        address lastImplementation = instructorNameToImplementationList[_hashName][instructorNameToImplementationList[_hashName].length-1];
        // emit event before unlinking;
        emit UnlinkedImplementation(implementationToInstructorName[_impl], _impl);

        implementationToInstructorName[_impl]="";
        instructorNameToImplementationList[_hashName][indexOfImplementation]=lastImplementation;
        instructorNameToImplementationList[_hashName].pop();
        
        implementationIndex[lastImplementation] = indexOfImplementation;
    }

    function _safeRemoveInstructor(bytes32 _nameHash) private {

        uint256 index = nameToinstructorIndex[_nameHash];
        Instructor memory current = instructorRegister[index];
        Instructor memory lastInstructor = instructorRegister[instructorRegister.length-1];

        bytes32 _byteCodeHash = hashInstructor(current._impl);

        registeredHash[_byteCodeHash]=false;
        registeredName[_nameHash]=false;

        instructorRegister[index] = lastInstructor;
        instructorRegister.pop();
        nameToinstructorIndex[_nameHash]=0;
    }

    function removeInstructor(string memory _name) public onlyOwner {
        bytes32 _hash =hashName(_name);
        Instructor memory _instructor = getInstructorByName(_name);
        require(registeredName[_hash],"Name does not exist");
        require(_instructor._impl!=address(0),"Instructor does not exist");

        uint256 size = instructorNameToImplementationList[_hash].length;
        for (uint256 i=0; i < size; i++) {  //for loop example
            unlinkImplementationToInstructor(instructorNameToImplementationList[_hash][i]);
        }

        _safeRemoveInstructor(_hash);
        emit RemovedInstructor(_instructor._impl, _name);
    }

    /**
     * @dev Given an implementation, find the best Ownership instructor contract for it.
     * @notice Find the best Ownership Instructor contract given the implementation address
     * @param _impl address of an NFT contract.
     */
    function instructorGivenImplementation(address _impl)public view returns (Instructor memory _instructor) {

        string memory _name = implementationToInstructorName[_impl];
        if(bytes(_name).length > 0){
            // Implementation was linked to an instructor contract, return the recorded Instructor;
            return getInstructorByName(_name);
        }
        // If the implementation was never linked to an instructor
        // Loop through the Instructors
        uint256 size = instructorRegister.length;
        // address _instrImpl;
        // string memory _instrName;
        for(uint256 i; i<size;i++ ){
            if(IOwnershipInstructor(instructorRegister[i]._impl).isValidInterface(_impl)){
                // _instrImpl = instructorRegister[i]._impl;
                // _instrName = instructorRegister[i]._name;
                _instructor =instructorRegister[i];
                break;
            }
        }
        return _instructor;
    }

}