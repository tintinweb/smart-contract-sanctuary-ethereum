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
    uint256 public totalNumberOfDeclarations;

    /// @notice Variable which will store the number of total declarers (unique addresses) which have made a declaration.
    /// @dev The variable will be set to 0 in the constructor and incremented each time a new declarer (new address) makes a declaration.
    /// @dev The variable can be used to present the total number of declarers in the front end as overall statistic.
    uint256 public totalNumberOfDeclarers;

    /// @notice Mapping which will keep track of the number of declarations by declarers.
    /// @dev The mapping can be used to present the number of declarations made by specific declarers as declarer statistic.
    mapping ( address => uint256 ) public numberOfDeclarationsForDeclarer;

    /// @notice Struct which will store data regarding declarations such as 
    /// @notice the declaration ID
    /// @notice number of confirmations
    /// @notice number of denies
    /// @notice the time of the declaration
    /// @notice the declarer
    /// @notice the declaration
    /// @notice the byte length in the declaration.
    struct declaration {

        /// @notice Variable which will store the declaration identifier.
        /// @dev Since there can be identical declarations, this variable will be the unique identifier of declarations.
        uint256 declarationID;

        /// @notice Variable which will store the number of confirmations on the declaration.
        /// @dev The variable can be used to present the number of confirmations on the declaration in the front end.
        uint256 numberOfConfirmationsOnDeclaration;

        /// @notice Variable which will store the number of denies on the declaration.
        /// @dev The variable can be used to present the number of denies on the declaration in the front end.
        uint256 numberOfDeniesOnDeclaration;

        /// @notice Variable which will store the timestamp of when the declaration was made.
        /// @dev The variable will store block.timestamp.
        /// @dev IMPROVE: It would be better to convert block.timestamp into date time format.
        uint256 timeOfDeclaration;

        /// @notice Variable which will store the address of the declarer.
        /// @notice The variable can be used to present which address made the declaration in the front end.
        /// @dev For every declaration, there must be an address which made it and it will be connected to the declaration forever.
        address declarerOfDeclaration;

        /// @notice Variable which will store the actual declaration.
        /// @dev The variable can be used to present the declaration.
        /// @dev The variable is a string and will have a maximum 50 byte length.
        string declaration;

        /// @notice Variable which will store the byte length used in the declaration.
        /// @dev The variable will store the byte length of the declaration string.
        uint8 byteLengthOnDeclaration;

    }

    /// @notice Array which is created based on the struct declaration, used to store data regarding declarations.
    /// @dev The array can be looped through to present declarations in the front end.
    /// @dev The array can be filtered to show the most net confirmed declarations.
    /// @dev The array can be filtered to show declarations of a specific address.
    declaration[] private declarations;



    /// @notice Variable which will store the number of total confirmations made on declarations. One address can only confirm a declaration once.
    /// @dev The variable will be set to 0 in the constructor and incremented each time an address confirms a declaration.
    /// @dev The variable can be used to present the total number of confirmations in the front end as overall statistic.
    uint256 public totalNumberOfConfirmations;

    /// @notice Variable which will store the number of total confirmers (unique addresses) which have confirmed a declaration.
    /// @dev The variable will be set to 0 in the constructor and incremented each time a new confirmer (new address) confirms a declaration.
    /// @dev The variable can be used to present the total number of confirmers in the front end as overall statistic.
    uint256 public totalNumberOfConfirmers;

    /// @notice Mapping which will keep track of the confirmations of confirmers.
    /// @dev The mapping can be used to present the number of confirmations made by specific confirmers as confirmer statistic.
    mapping ( address => uint256 ) public numberOfConfirmationsForConfirmer;

    /// @notice Struct which will store data regarding confirmations, such as 
    /// @notice the confirmed declaration.
    /// @notice the confirmer
    struct confirmation {

        /// @notice Variable which will store the declaration ID of the confirmed declaration.
        uint256 confirmedDeclarationID;

        /// @notice Variable which will store the address of the confirmer.
        address confirmerOfDeclaration;

    }

    /// @notice Array which is created based on the struct confirmation, used to store data regarding confirmations.
    /// @dev The array can be filtered to show confirmations for a specific address.
    /// @dev The array can be filtered to show confirmations for a specific declaration.
    confirmation[] private confirmations;



    /// @notice Variable which will store the number of total denies made on declarations. One address can only deny a declaration once.
    /// @dev The variable will be set to 0 in the constructor and incremented each time an address denies a declaration.
    /// @dev The variable can be used to present the total number of denies in the front end as overall statistic.
    uint256 public totalNumberOfDenies;

    /// @notice Variable which will store the number of total deniers (unique addresses) which have denied a declaration.
    /// @dev The variable will be set to 0 in the constructor and incremented each time a new denier (new address) denies a declaration.
    /// @dev The variable can be used to present the total number of deniers in the front end as overall statistic.
    uint256 public totalNumberOfDeniers;

    /// @notice Mapping which will keep track of the denies made by deniers.
    /// @dev The mapping can be used to present the number of denies made by specific deniers as denier statistic.
    mapping ( address => uint256 ) public numberOfDeniesForDenier;

    /// @notice Struct which will store data regarding denies, such as 
    /// @notice the denied declaration.
    /// @notice the denier
    struct deny {

        /// @notice Variable which will store the declaration ID of the denied declaration.
        uint256 deniedDeclarationID;

        /// @notice Variable which will store the address of the denier.
        address denierOfDeclaration;

    }

    /// @notice Array which is created based on the struct deny, used to store data regarding denies.
    /// @dev The array can be filtered to show denies for a specific address.
    /// @dev The array can be filtered to show denies for a specific declaration.
    deny[] private denies;



    /// @notice Variable which will store the byte length limit for a declaration.
    /// @dev The variable will be set to 50, which will be the threshold for total the byte-length of a declaration.
    /// @dev IMPROVE: It would be better to count the number of characters in the declaration, which is a string, however I couldn't find support for it in Solidity and creating functionality which count characters will be very gas costly.
    uint8 public declarationLimit = 50;



    /// @notice Constructor which will be executed only once upon deployment.
    constructor() {
        
        /// @notice Setting the totalNumberOfDeclarations to 0.
        totalNumberOfDeclarations = 0;

        /// @notice Setting the totalNumberOfDeclarers to 0.
        totalNumberOfDeclarers = 0;

        /// @notice Setting the totalNumberOfConfirmations to 0.
        totalNumberOfConfirmations = 0;

        /// @notice Setting the totalNumberOfConfirmers to 0.
        totalNumberOfConfirmers = 0;

        /// @notice Setting the totalNumberOfDenies to 0.
        totalNumberOfDenies = 0;

        /// @notice Setting the totalNumberOfDeniers to 0.
        totalNumberOfDeniers = 0;

    }


    
    /// @notice Function which will let a declarer make a declaration.
    /// @param _declaration is the declaration.
    function declareDeclaration ( string memory _declaration ) public {

        /// @notice Variable to store the address which made the declaration.
        address _declarer = msg.sender;

        /// @notice Check to make sure that the declaration does not exceed the limit of max 50 byte-length.
        require ( bytes(_declaration).length <= declarationLimit, "Declaration limit exceeded, shorten the declaration (max 50 byte-length)." );

        /// @notice Increment number of declarations by 1.
        totalNumberOfDeclarations++;

        /// @notice Increment number of declarers if declarer of declaration has no previous declaration.
        if ( numberOfDeclarationsForDeclarer[_declarer] == 0 ) {

            totalNumberOfDeclarers++;

        }

        /// @notice Storing data in the array "declarations" regarding the declaration according to the struct.
        /// @dev numberOfDeclaration = delcarationID
        /// @dev 0 = confirmations
        /// @dev 0 = denies
        /// @dev block.timestamp = timeOfDeclaration
        /// @dev _declarer = declarer
        /// @dev _declaration = declaration
        /// @dev uint8(bytes_declaration).length) = byteLength
        declarations.push(
            declaration( 
                totalNumberOfDeclarations, 
                0, 
                0,
                block.timestamp, 
                _declarer, 
                _declaration, 
                uint8(bytes(_declaration).length) 
            )
        );

        /// @notice Incrementing the number of declarations for the declarer.
        numberOfDeclarationsForDeclarer[_declarer]++;

    }

    /// @notice Function to get data regarding a specific declaration.
    function getDeclarationByDeclarationID ( uint256 _declarationID ) public view returns ( 
        uint256 declarationID_, 
        uint256 confirmations_, 
        uint256 denies_,
        uint256 timeOfDeclaration_, 
        address declarer_, 
        string memory declaration_, 
        uint8 byteLength )  {

        /// @notice Data will be fetched from the array declarations, therefore we decrement the _declarationID to fetch the correct data with array index.
        _declarationID--;

        /// @notice Return the data regarding the declaration.
        return ( 
            declarations[_declarationID].declarationID, 
            declarations[_declarationID].numberOfConfirmationsOnDeclaration, 
            declarations[_declarationID].numberOfDeniesOnDeclaration, 
            declarations[_declarationID].timeOfDeclaration,
            declarations[_declarationID].declarerOfDeclaration,
            declarations[_declarationID].declaration,
            declarations[_declarationID].byteLengthOnDeclaration
        );

    }

    /// @notice Function to get data regarding declarations
    function getDeclarationsByDeclarer ( uint256 _declarer ) public view returns ( 
        uint256 declarationID_, 
        uint256 confirmations_, 
        uint256 denies_,
        uint256 timeOfDeclaration_, 
        address declarer_, 
        string memory declaration_, 
        uint8 byteLength )  {

        /// @notice Return the data regarding the declaration.
        return ( 
            declarations[_declarer].declarationID, 
            declarations[_declarer].numberOfConfirmationsOnDeclaration, 
            declarations[_declarer].numberOfDeniesOnDeclaration, 
            declarations[_declarer].timeOfDeclaration,
            declarations[_declarer].declarerOfDeclaration,
            declarations[_declarer].declaration,
            declarations[_declarer].byteLengthOnDeclaration
        );

    }



    /// @notice Function which will let a confirmer confirm a declaration.
    /// @param _confirmer is the address calling the function.
    /// @param _declarationID is the ID of the declaration.
    function confirmDeclaration ( address _confirmer, uint256 _declarationID ) public {

        /// @notice Variable which will be used to check if confirmer already confirmed the declaration.
        bool alreadyConfirmed;

        /// @notice Variable which will be used to check if confirmer owns the declaration.
        bool isOwnDeclaration;

        /// @notice Check to make sure that the address making the confirmation is the same as the address calling the function.
        require ( msg.sender == _confirmer, "Can't make a confirmation for other address." );

        /// @notice Check to make sure that the confirmer has not already confirmed the declaration.
        for ( uint256 i = 0; i < confirmations.length; i++ ) {

            /// @notice If the confirmer address already exists in the array "confirmations" with the same declaration ID.
            if ( confirmations[i].confirmerOfDeclaration == _confirmer && confirmations[i].confirmedDeclarationID == _declarationID ) {
                
                /// @notice Then we set alreadyConfirmed to true.
                alreadyConfirmed = true;

            } else { 

                /// @notice Otherwise we set alreadyConfirmed to false.
                alreadyConfirmed = false;

            }

        }

        /// @notice Check if confirmer already confirmed the declaration,
        require ( alreadyConfirmed = false, "Can't confirm the same declaration twice." );

        /// @notice Check to make sure that the confirmer is not the address which made the declaration.
        for ( uint256 i = 0; i < declarations.length; i++ ) {

            /// @notice If the confirmer address is the same address which made the confirmation.
            if ( declarations[i].declarerOfDeclaration == _confirmer && declarations[i].declarationID == _declarationID ) {
                
                /// @notice Then we set isOwnDeclaration to true.
                isOwnDeclaration = true;

            } else { 

                /// @notice Otherwise we set isOwnDeclaration to false.
                isOwnDeclaration = false;

            }

        }

        /// @notice Check if confirmer owns the declaration,
        require ( isOwnDeclaration = false, "Can't confirm your own declaration." );

        /// @notice Increase number of confirmations by 1.
        totalNumberOfConfirmations++;

        /// @notice Storing data in the array "confirmations" regarding the confirmation according to the struct.
        confirmations.push(
            confirmation( 
                _declarationID,
                _confirmer
            )
        );

        /// @notice Incrementing the number of confirmations for the confirmer.
        numberOfConfirmationsForConfirmer[_confirmer]++;

    }

    /// @notice Function to get data regarding a specific confirmation.
    function getConfirmationByDeclarationID ( uint256 _declarationID ) public view returns ( 
        uint256 confirmedDeclarationID, 
        address confirmerOfDeclaration )  {

        /// @notice Data will be fetched from the array confirmations, therefore we decrement the _declarationID to fetch the correct data with array index.
        _declarationID--;

        /// @notice Return the data regarding the confirmation.
        return ( 
            confirmations[_declarationID].confirmedDeclarationID,
            confirmations[_declarationID].confirmerOfDeclaration

        );

    }

     /// @notice Function to get data regarding a specific confirmation.
    function getConfirmationsByConfirmer ( uint256 _confirmerOfDeclaration ) public view returns ( 
        uint256 confirmedDeclarationID, 
        address confirmerOfDeclaration )  {

        /// @notice Return the data regarding the confirmation.
        return ( 
            confirmations[_confirmerOfDeclaration].confirmedDeclarationID,
            confirmations[_confirmerOfDeclaration].confirmerOfDeclaration

        );

    }


    
    /// @notice Function which will let a denier deny a declaration.
    /// @param _denier is the address calling the function.
    /// @param _declarationID is the ID of the declaration.
    function denyDeclaration ( address _denier, uint256 _declarationID ) public {

        /// @notice Variable which will be used to check if denier already denied the declaration.
        bool alreadyDenied;

        /// @notice Variable which will be used to check if confirmer owns the declaration.
        bool isOwnDeny;

        /// @notice Check to make sure that the address making the deny is the same as the address calling the function.
        require ( msg.sender == _denier, "Can't make a confirmation for other address." );

        /// @notice Check to make sure that the denier has not already denied the declaration.
        for ( uint256 i = 0; i < denies.length; i++ ) {

            /// @notice If the denier address already exists in the array "denies" with the same declaration ID.
            if ( denies[i].denierOfDeclaration == _denier && denies[i].deniedDeclarationID == _declarationID ) {
                
                /// @notice Then we set alreadyDenied to true.
                alreadyDenied = true;

            } else { 

                /// @notice Otherwise we set alreadyDenied to false.
                alreadyDenied = false;

            }
        
        }

        /// @notice Check if confirmer already confirmed the declaration,
        require ( alreadyDenied = false, "Can't deny the same declaration twice." );

        /// @notice Check to make sure that the denier is not the address which made the declaration.
        for ( uint256 i = 0; i < declarations.length; i++ ) {

            /// @notice If the denier address is the same address which made the deny.
            if ( declarations[i].declarerOfDeclaration == _denier && declarations[i].declarationID == _declarationID ) {
                
                /// @notice Then we set isOwnDeny to true.
                isOwnDeny = true;

            } else { 

                /// @notice Otherwise we set isOwnDeny to false.
                isOwnDeny = false;

            }

        }

        /// @notice Check if confirmer owns the declaration,
        require ( isOwnDeny = false, "Can't deny your own declaration." );

        /// @notice Increase number of denies by 1.
        totalNumberOfDenies++;

        /// @notice Storing data in the array "denies" regarding the deny according to the struct.
        denies.push(
            deny(
                _declarationID,
                _denier
            )
        );

        /// @notice Incrementing the number of denies for the denier.
        numberOfDeniesForDenier[_denier]++;

    }

    /// @notice Function to get data regarding a specific deny.
    function getDenyByDeclarationID ( uint256 _declarationID ) public view returns ( uint256 deniedDeclarationID, address denierOfDeclaration )  {

        /// @notice Data will be fetched from the array denies, therefore we decrement the _declarationID to fetch the correct data with array index.
        _declarationID--;

        /// @notice Return the data regarding the denies.
        return ( 
            denies[_declarationID].deniedDeclarationID,
            denies[_declarationID].denierOfDeclaration
            
        );

    }

    /// @notice Function to get data regarding a specific deny.
    function getDenyByDenier ( uint256 _denier ) public view returns ( uint256 deniedDeclarationID, address denierOfDeclaration )  {

        /// @notice Return the data regarding the denies.
        return ( 
            denies[_denier].deniedDeclarationID,
            denies[_denier].denierOfDeclaration
            
        );

    }

}

/// confirmations: array input +1: done, decrement in get function
/// declarations: find a way to convert block.timestamp to date time
/// get function return data name?

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