// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Open Zeppelin: Contract module which provides a basic access control mechanism, where there is an account (an owner) that can be granted exclusive access to specific functions.
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Sweeping declaration
/// @author OPEC.ms
/// @notice Sweeping declaration is a smart contract which allow people to make immutable declarations stored on the Ethereum blockchain.
/// @notice A declaration can not be modified or censured and will always be linked to the address which made the declaration.
/// @notice A declaration can be confirmed or denied by another address, however one address can only confirm or deny a specific declaration once.
contract sweepingDeclaration is Ownable {

    /// @notice Variable which will store the number of total declarations made.
    /// @dev The variable will be set to 0 in the constructor and incremented each time a declaration is made.
    /// @dev The variable can be used to present the total number of declarations in the front end as overall statistic.
    uint256 public numberOfDeclarations;

    /// @notice Variable which will store the number of total declarers (unique addresses) which have made a declaration.
    /// @dev The variable will be set to 0 in the constructor and incremented each time a new declarer (new address) makes a declaration.
    /// @dev The variable can be used to present the total number of declarers in the front end as overall statistic.
    uint256 public numberOfDeclarers;

    /// @notice Variable which will store the number of total confirmations made on declarations. One address can only confirm a declaration once.
    /// @dev The variable will be set to 0 in the constructor and incremented each time an address confirms a declaration.
    /// @dev The variable can be used to present the total number of confirmations in the front end as overall statistic.
    uint256 public numberOfConfirmations;

    /// @notice Variable which will store the number of total confirmers (unique addresses) which have confirmed a declaration.
    /// @dev The variable will be set to 0 in the constructor and incremented each time a new confirmer (new address) confirms a declaration.
    /// @dev The variable can be used to present the total number of confirmers in the front end as overall statistic.
    uint256 public numberOfConfirmers;

    /// @notice Variable which will store the number of total denies made on declarations. One address can only deny a declaration once.
    /// @dev The variable will be set to 0 in the constructor and incremented each time an address denies a declaration.
    /// @dev The variable can be used to present the total number of denies in the front end as overall statistic.
    uint256 public numberOfDenies;

    /// @notice Variable which will store the number of total deniers (unique addresses) which have denied a declaration.
    /// @dev The variable will be set to 0 in the constructor and incremented each time a new denier (new address) denies a declaration.
    /// @dev The variable can be used to present the total number of deniers in the front end as overall statistic.
    uint256 public numberOfDeniers;

    /// @notice Variable which will store the byte length limit for a declaration.
    /// @dev The variable will be set to 50, which will be the threshold for total the byte-length of the declaration.
    /// @dev IMPROVE: It would be better to count the number of characters in the declaration, which is a string, however I couldn't find support for it in Solidity and creating functionality which count characters will be very gas costly.
    uint8 public declarationLimit = 50;


    /// @notice Mapping which will keep track of the number of declarations by declarers.
    /// @dev The mapping can be used to present the number of declarations made by specific declarers as declarer statistic.
    mapping (address => uint256) public declarerDeclarations;

    /// @notice Struct which will store data regarding declarations such as 
    /// @notice the declaration ID
    /// @notice number of confirmations
    /// @notice number of denies
    /// @notice the declarer
    /// @notice the declaration
    /// @notice the time of the declaration
    /// @notice the byte length in the declaration.
    struct declaration {

        /// @notice Variable which will store the declaration identifier.
        /// @dev Since there can be identical declarations, this variable will be the unique identifier of declarations.
        uint256 declarationID;

        /// @notice Variable which will store the number of confirmations on the declaration.
        /// @dev The variable can be used to present the number of confirmations on the declaration in the front end.
        uint256 confirmations;

        /// @notice Variable which will store the number of denies on the declaration.
        /// @dev The variable can be used to present the number of denies on the declaration in the front end.
        uint256 denies;

        /// @notice Variable which will store the address of the declarer.
        /// @notice The variable can be used to present which address made the declaration in the front end.
        /// @dev For every declaration, there must be an address which made it and it will be connected to the declaration forever.
        address declarer;

        /// @notice Variable which will store the actual declaration.
        /// @dev The variable can be used to present the declaration.
        /// @dev The variable is a string and will have a maximum 50 byte length.
        string declaration;

        /// @notice Variable which will store the timestamp of when the declaration was made.
        /// @dev The variable will store block.timestamp.
        /// @dev IMPROVE: It would be better to convert block.timestamp into date time format.
        uint256 timeOfDeclaration;

        /// @notice Variable which will store the byte length used in the declaration.
        /// @dev The variable will store the byte length of the declaration string.
        uint8 byteLength;

    }

    /// @notice Array which is created based on the struct declaration, used to store data regarding declarations.
    /// @dev The array can be looped through to present declarations in the front end.
    /// @dev The array can be filtered to show the most net confirmed declarations.
    /// @dev The array can be filtered to show declarations of a specific address.
    declaration[] private declarations;

    
    /// @notice Mapping which will keep track of the confirmations of confirmers.
    /// @dev The mapping can be used to present the number of confirmations made by specific confirmers as confirmer statistic.
    mapping (address => uint256) public confirmerConfirmations;

    /// @notice Struct which will store data regarding confirmations, such as 
    /// @notice the confirmer
    /// @notice the confirmed declaration.
    struct confirmation {

        /// @notice Variable which will store the address of the confirmer.
        address confirmer;

        /// @notice Variable which will store the declaration ID of the confirmed declaration.
        uint256 confirmedDeclarationID;

    }

    /// @notice Array which is created based on the struct confirmation, used to store data regarding confirmations.
    /// @dev The array can be filtered to show confirmations for a specific address.
    /// @dev The array can be filtered to show confirmations for a specific declaration.
    confirmation[] private confirmations;


    /// @notice Mapping which will keep track of the denies made by deniers.
    /// @dev The mapping can be used to present the number of denies made by specific deniers as denier statistic.
    mapping (address => uint256) public denierDenies;

    /// @notice Struct which will store data regarding denies, such as 
    /// @notice the denier
    /// @notice the denied declaration.
    struct deny {

        /// @notice Variable which will store the address of the denier.
        address denier;

        /// @notice Variable which will store the declaration ID of the denied declaration.
        uint256 deniedDeclarationID;

    }

    /// @notice Array which is created based on the struct deny, used to store data regarding denies.
    /// @dev The array can be filtered to show denies for a specific address.
    /// @dev The array can be filtered to show denies for a specific declaration.
    deny[] private denies;


    /// @notice Constructor which will be executed only once upon deployment.
    constructor() {
        
        /// @notice Setting the numberOfDeclarations to 0.
        numberOfDeclarations = 0;

        /// @notice Setting the numberOfDeclarers to 0.
        numberOfDeclarers = 0;

        /// @notice Setting the numberOfConfirmations to 0.
        numberOfConfirmations = 0;

        /// @notice Setting the numberOfConfirmers to 0.
        numberOfConfirmers = 0;

        /// @notice Setting the numberOfDenies to 0.
        numberOfDenies = 0;

        /// @notice Setting the numberOfConfirmers to 0.
        numberOfDeniers = 0;

    }

    
    /// @notice Function which will let a declarer make a declaration.
    /// @param _declaration is the declaration.
    function declareDeclaration( string memory _declaration ) public {

        /// @notice Variable to store the address which made the declaration.
        address _declarer = msg.sender;

        /// @notice Check to make sure that the declaration does not exceed the limit of max 50 byte-length.
        require ( bytes(_declaration).length <= declarationLimit, "Declaration limit exceeded, shorten the declaration (max 50 byte-length)." );

        /// @notice Increment number of declarations by 1.
        numberOfDeclarations++;

        /// @notice Increment number of declarers if declarer of declaration has no previous declaration.
        if ( declarerDeclarations[_declarer] == 0 ) {

            numberOfDeclarers++;

        }

        /// @notice Storing data in the array "declarations" regarding the declaration according to the struct.
        /// @dev numberOfDeclaration = delcarationID
        /// @dev 0 = confirmations
        /// @dev 0 = denies
        /// @dev _declarer = declarer
        /// @dev _declaration = declaration
        /// @dev block.timestamp = timeOfDeclaration
        /// @dev uint8(bytes_declaration).length) = byteLength
        declarations.push(
            declaration( 
                numberOfDeclarations, 
                0, 
                0, 
                _declarer, 
                _declaration, 
                block.timestamp, 
                uint8(bytes(_declaration).length) 
            )
        );

        /// @notice Incrementing the number of declarations for the declarer.
        declarerDeclarations[_declarer]++;

    }

    /// @notice Function to get data regarding a specific declaration.
    function getDeclaration ( uint256 _declarationID ) public view returns ( uint256, uint256, uint256, address, string memory, uint256, uint8 )  {

        /// @notice Data will be fetched from the array declarations, therefore we decrement the _declarationID to fetch the correct data with array index.
        _declarationID--;

        /// @notice Return the data regarding the declaration.
        return ( 
            declarations[_declarationID].declarationID, 
            declarations[_declarationID].confirmations, 
            declarations[_declarationID].denies,  
            declarations[_declarationID].declarer,
            declarations[_declarationID].declaration,
            declarations[_declarationID].timeOfDeclaration,
            declarations[_declarationID].byteLength
        );

    }


    /// @notice Function which will let a confirmer confirm a declaration.
    /// @param _confirmer is the address calling the function.
    /// @param _declarationID is the ID of the declaration.
    function confirmDeclaration( address _confirmer, uint256 _declarationID ) public {

        /// @notice Check to make sure that the address making the confirmation is the same as the address calling the function.
        require ( msg.sender == _confirmer, "Can't make a confirmation for other address." );

        /// @notice Check to make sure that the confirmer has not already confirmed the declaration.
        for( uint256 i = 0; i < confirmations.length; i++ ) {

            /// @notice If the confirmer address already exists in the array "confirmations" with the same declaration ID.
            if( confirmations[i].confirmer == _confirmer && confirmations[i].confirmedDeclarationID == _declarationID ) {
                
                /// @notice Function will be reverted.
                revert( "Confirmer can't confirm same declaration twice." );

            }

        }

        /// @notice Check to make sure that the confirmer is not the address which made the declaration.
        for( uint256 i = 0; i < declarations.length; i++ ) {

            /// @notice If the confirmer address is the same address which made the confirmation.
            if( declarations[i].declarer == _confirmer && declarations[i].declarationID == _declarationID ) {
                
                /// @notice Function will be reverted.
                revert( "Can't confirm your own declaration." );

            }

        }

        /// @notice Increase number of confirmations by 1.
        numberOfConfirmations++;

        /// @notice Storing data in the array "confirmations" regarding the confirmation according to the struct.
        confirmations.push(
            confirmation( 
                 _confirmer, _declarationID 
            )
        );

        /// @notice Incrementing the number of confirmations for the confirmer.
        confirmerConfirmations[_confirmer]++;

    }

    /// @notice Function to get data regarding a specific confirmation.
    function getConfirmation ( uint256 _declarationID ) public view returns ( address, uint256 )  {

        /// @notice Data will be fetched from the array confirmations, therefore we decrement the _declarationID to fetch the correct data with array index.
        _declarationID--;

        /// @notice Return the data regarding the confirmation.
        return ( 
            confirmations[_declarationID].confirmer, 
            confirmations[_declarationID].confirmedDeclarationID
        );

    }

    
    /// @notice Function which will let a denier deny a declaration.
    /// @param _denier is the address calling the function.
    /// @param _declarationID is the ID of the declaration.
    function denyDeclaration( address _denier, uint256 _declarationID ) public {

        /// @notice Check to make sure that the address making the deny is the same as the address calling the function.
        require ( msg.sender == _denier, "Can't make a confirmation for other address." );

        /// @notice Check to make sure that the denier has not already denied the declaration.
        for( uint256 i = 0; i < denies.length; i++ ) {

            /// @notice If the denier address already exists in the array "denies" with the same declaration ID.
            if( denies[i].denier == _denier && denies[i].deniedDeclarationID == _declarationID ) {
                
                /// @notice Function will be reverted.
                revert( "Denier can't deny same declaration twice." );

            } 

        }

        /// @notice Check to make sure that the denier is not the address which made the declaration.
        for( uint256 i = 0; i < declarations.length; i++ ) {

            /// @notice If the denier address is the same address which made the deny.
            if( declarations[i].declarer == _denier && declarations[i].declarationID == _declarationID ) {
                
                /// @notice Function will be reverted.
                revert( "Can't deny your own declaration." );

            }

        }

        /// @notice Increase number of denies by 1.
        numberOfDenies++;

        /// @notice Storing data in the array "denies" regarding the deny according to the struct.
        denies.push(
            deny( 
                _denier, 
                _declarationID 
            )
        );

        /// @notice Incrementing the number of denies for the denier.
        denierDenies[_denier]++;

    }

    /// @notice Function to get data regarding a specific deny.
    function getDeny ( uint256 _declarationID ) public view returns ( address, uint256 )  {

        /// @notice Data will be fetched from the array denies, therefore we decrement the _declarationID to fetch the correct data with array index.
        _declarationID--;

        /// @notice Return the data regarding the denies.
        return ( 
            denies[_declarationID].denier, 
            denies[_declarationID].deniedDeclarationID
        );

    }

}

/// confirmDeclaration: cant confirm own dec: done, another for + if 
/// denyDeclaration: cant deny own dec: done, another for + if
/// declareDeclaration: address doesnt need to be param?: done, msg.sender

/// confirmations: dec not exist fallback: done, made array private and created get function 
/// confirmations: array input +1: done, decrement in get function
/// declarations: find a way to convert block.timestamp to date time
/// declarations: find a way to count chars in a fakking string wtf sol
/// declarations: dec not exist fallback: done, made array private and created get function 
/// declarations: array input +1: done, decrement in get function
/// denies: dec not exist fallback: done, made array private and created get function 
/// denies: array input +1: done, decrement in get function

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