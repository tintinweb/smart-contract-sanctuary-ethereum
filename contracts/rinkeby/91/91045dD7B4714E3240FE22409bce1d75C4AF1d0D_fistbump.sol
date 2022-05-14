// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Inherit standard ERC721 functionality from OpenZeppelin's ERC721 contract
/// @dev https://docs.openzeppelin.com/contracts/4.x/erc721
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title fistbump
/// @author OPEC.ms
/** @notice Contract description
    fistbump allow addresses to fistbump each other
    an address (fistbumpingAddress) can fistbump another address (fistbumpedAddress)
    (fistbumpedAddress, now fistbumpingAddress) can in turn respond the fistbump by fistbumping (fistbumpingAddress, now fistbumpedAddress)
    making both addresses eligable to mint their fistbump NFT which represents their unique fistbump

*/
/** @notice Contract glossary
    (fistbumpingAddress) = address which fistbump another address
    (fistbumpedAddress) = address which is fistbumped by another address
    (callingAddress) = address which calls a function
    (inputAddress) = address which is specified as function input
    (respondedFistbump) = fistbump where address A has fistbumped address B and address B has fistbumped address A
    (unrespondedFistbump) = fistbump where address A has fistbumped address B but address B has not fistbumped address A
    (mintedFistbump) = fistbump which has been minted by (fistbumpingAddress)
    (eligableFistbump) = (respondedFistbump) which has not yet been minted by (fistbumpingAddress)

    an address can be both a "fistbumpingAddress" and a "fistbumpedAddress" depending on the context
    1. address A (fistbumpingAddress) fistbumps address B (fistbumpedAddress)
    2. address B (fistbumpingAddress) fistbumps address A (fistbumpedAddress) in response

*/
/** @dev Contract functionality overview

    write-functions
        fistbumpThis(address) - (callingAddress) fistbumps (inputAddress), emitts "fistbumped" event
        mintFistbumpForFistbumpWith(address) - (callingAddress) mints an (eligableFistbump) for fistbump with (inputAddress), emitts "fistbumpMinted" event

    read-functions
        totalFistbumps() - public variable returns the total fistbumps made
        totalMintedFistbumps() - public variable returns the total (mintedFistbumps)

        totalFistbumpsFor(address) - public function returns (integer) the total fistbumps for (inputAddress)
        totalRespondedFistbumpsFor(address) - public mapping returns (integer) the total (respondedFistbumps) for (inputAddress)
        totalUnrespondedFistbumpsFor(address) - public function returns (integer) the total (unrespondedFistbumps) for (inputAddress)
        totalMintedFistbumpsFor(address) - public function returns (integer) the total (mintedFistbumps) for (inputAddress)
        totalFistbumpsEligableToMintFor(address) - public function returns (integer) the total fistbumps eligable to be minted for (inputAddress)
        totalFistbumpsNotRespondedBy(address) - public function returns (integer) the total fistbumps not responded by (inputAddress)
        
        fistbumpedAddressesFor(address) - public mapping returns ([address]) all (fistbumpedAddresses) for (inputAddress)
        respondedFistbumpedAddressesFor(address) - public function ([address]) returns the (respondedFistbumps) (fistbumpedAddresses) for (inputAddress)
        unrespondedFistbumpedAddressesFor(address) - public function returns ([address]) the (unrespondedFistbumps) (fistbumpedAddresses) for (inputAddress)
        mintedFistbumpsFor(address) - public mapping returns ([integer][address]) the (mintedFistbumps) (tokenIDs and fistbumpedAddresses) for (inputAddress)
        mintedFistbumpedAddressesFor(address) - public function returns ([address]) the (mintedFistbumps) (fistbumpedAddresses) for (inputAddress)
        mintedFistbumpTokenIdsFor(address) - public function returns ([integer]) the (mintedFistbumps) (tokenIds) for (inputAddress)
        fistbumpedAddressesEligableToMintFor(address) - public function returns ([address]) the (fistbumpedAddresses) for (inputAddress) eligable to be minted 
        fistbumpsNotRespondedBy(address) - public mapping returns ([address]) the (fistbumpingAddresses) not responded by (inputAddress)

    helper-functions
        anyFistbumpsFor(address) - modifier requires (inputAddress) to have atleast 1 fistbump 
        isThisFistbumpResponded(address, address) - private function check if a fistbump is (respondedFistbumps)
        isThisFistbumpMinted(address, address) - private function check if a fistbump is minted

*/
contract fistbump is ERC721 {

    /// @notice Declaration of public global variable "totalFistbumps"
    /** @dev "totalFistbumps" is used to store the total number of fistbumps made
        "totalFistbumps" visibility is public to enable the built-in getter-function "totalFistbumps()"
    */
    uint256 public totalFistbumps;

    /// @notice Declaration of public global variable "totalMintedFistbumps"
    /** @dev "totalMintedFistbumps" is used to store the total number of fistbumps minted
        "totalMintedFistbumps" visibility is public to use built-in getter-function "totalMintedFistbumps()"
    */
    uint256 public totalMintedFistbumps;

    /// @notice Declaration of public mapping "fistbumpedAddressesFor"
    /** @dev "fistbumpedAddressesFor" is used to store all (fistbumpedAddresses) for (inputAddress) 
        "fistbumpedAddressesFor" visibility is public to use built-in getter-function "fistbumpedAddressesFor(inputAddress)"
    */
    mapping ( address => address[] ) public fistbumpedAddressesFor;

    /// @notice Declaration of mapping "totalRespondedFistbumpsFor"
    /** @dev "totalRespondedFistbumpsFor" is used to store the total number of (respondedFistbumps) for (inputAddress) 
        "totalRespondedFistbumpsFor" visibility is public to use built-in getter-function "totalRespondedFistbumpsFor(inputAddress)"
    */
    mapping ( address => uint256 ) public totalRespondedFistbumpsFor;

    /// @notice Declaration of struct "mintedFistbump"
    /// @dev "mintedFistbump" is used to define the array structure of (mintedFistbumps) in the mapping "mintedFistbumpsFor"
    struct mintedFistbump {
        
        /// @notice Declaration of the struct variable "tokenID"
        /// @dev "tokenID" is used to store the token ID of the (mintedFistbump) for (fistbumpingAddress)
        uint256 tokenID;

        /// @notice Declaration of the struct variable "fistbumpedAddress"
        /// @dev "fistbumpedAddress" is used to store the (fistbumpedAddress) of the (mintedFistbump) for (fistbumpingAddress)
        address fistbumpedAddress;

    }

    /// @notice Declaration of mapping "mintedFistbumpsFor"
    /** @dev "mintedFistbumpsFor" is used to store the (mintedFistbumps) ([tokenID and fistbumpedAddress]) for (fistbumpingAddress)
        "mintedFistbumpsFor" visibility is public to use built-in getter-function "mintedFistbumpsFor(inputAddress)"
    */
    mapping ( address => mintedFistbump[] ) public mintedFistbumpsFor;

    /// @notice Declaration of public mapping "fistbumpsNotRespondedBy"  
    /** @dev "fistbumpsNotRespondedBy" is used to store the address of (fistbumpingAddress) for (inputAddress), which has not responded the fistbump
        "fistbumpsNotRespondedBy" visibility is public to use built-in getter-function "fistbumpsNotRespondedBy(inputAddress)"
    */
    mapping ( address => address[] ) public fistbumpsNotRespondedBy;

    /// @notice Declaration of event "fistbumped"
    /** @dev "fistbumped" is emitted in the function "fistbumpThis"
        "fistbumpingAddress", which is the address that made the fistbump
        "fistbumpedAddress", which is the address that was fistbumped
    */
    event fistbumped ( address fistbumpingAddress, address fistbumpedAddress );

    /// @notice Declaration of event "fistbumpMinted"
    /** @dev "fistbumpMinted" is emitted in the function "mintFistbumpFor"
        "mintingAddress" is the address which minted the fistbump
        "tokenID" is the token ID of the fistbump which was minted
    */
    event fistbumpMinted ( address mintingAddress, uint256 tokenID );

    /// @notice Constructor is executed only once when contract is deployed
    /// @dev ERC721 constructor is executed as well, initializing ERC721 variables "name" and "symbol" to "fistbump" and "fb"
    constructor () ERC721 ( "fistbump", "fb" ) {

        /// @notice Setting public global variable "totalFistbumps" to "0"
        /// @dev "totalFistbumps" is set to "0" to enable first increment of "totalFistbumps" in the function "fistbumpAddress"
        totalFistbumps = 0;

        /// @notice Setting public global variable "totalMintedFistbumps" to "0"
        /// @dev "totalMintedFistbumps" is set to "0" to enable first increment of "totalMintedFistbumps" in the function "mintFistbump"
        totalMintedFistbumps = 0;

    }

    /// @notice Declaration of the modifier "anyFistbumps"
    /// @dev "anyFistbumps" make sure that (_inputAddress) has made atleast 1 fistbump
    /// @param _inputAddress is the address to be checked
    modifier anyFistbumpsFor ( address _inputAddress ) {

        /// @notice Declaration of requirement to avoid returning nothing if the (_inputAddress) has not made any fistbumps
        /// @dev The length of the array "fistbumpedAddressesFor" for the (_inputAddress) can not be "0"
        require ( fistbumpedAddressesFor[_inputAddress].length > 0, "This address has not made any fistbumps." );

        /// @notice Proceed with function if evaluation is successful
        _;

    }

    /// @notice Declaration of the function "fistbumpThis" which allow an address (callingAddress) to fistbump another address (inputAddress)
    /** @dev Function overview
        1. Making sure (callingAddress) does not fistbump own address
        2. Making sure (callingAddress) does not fistbump same (inputAddress) twice
        3. (inputAddress) has fistbumped (callingAddress) before?
        3.1 Yes
            3.1.1 (inputAddress) is added to (callingAddress) "fistbumpedAddressesFor"
            3.1.2 "totalRespondedFistbumpsFor" is incremented for (callingAddress)
            3.1.3 "totalRespondedFistbumpsFor" is incremented for (inputAddress)
        3.2 No
            3.2.1 (inputAddress) is added to (callingAddress) "fistbumpedAddressesFor"
    */
    /// @param _inputAddress is the address to be fistbumped (inputAddress)
    function fistbumpThis ( address _inputAddress ) public {

        /// @notice Declaration of requirement to avoid fistbumping own address
        /// @dev (inputAddress) can not be the same as (callingAddress)
        require ( _inputAddress != msg.sender, "This address is your own!" );

        /// @notice Declaration of local variable "alreadyFistbumped"
        /** @dev "alreadyFistbumped" is used as a flag and will hold the boolean value (is (inputAddress) already fistbumped by (callingAddress)?)
            = false = (inputAddress) is not already fistbumped by (callingAddress)
            = true = (inputAddress) is already fistbumped by (callingAddress)
        */
        bool alreadyFistbumped;

        /// @notice Declaration of check (has (callingAddress) fistbumped a (fistbumpedAddress) before?)
        /** @dev if-statement which evaluates if the length of "fistbumpedAddressesFor" array for (callingAddress) is greater than "0"
            = false = further evaluation is not needed since (callingAddress) has not made any fistbumps
            = true = further evaluation is needed since (inputAddress) can potentially already be fistbumped by (callingAddress)
        */
        if ( fistbumpedAddressesFor[msg.sender].length > 0 ) {

            /// @notice Declaration of loop (through all of the fistbumps (callingAddress) has made)
            /** @dev for-loop which loops through the array "fistbumpedAddressesFor" for (callingAddress)
                which enable evaluation of each (fistbumpedAddress) for (callingAddress)
            */
            for ( uint256 i = 0; i < fistbumpedAddressesFor[msg.sender].length; i++ ) {
                
                /// @notice Declaration of check (is the (fistbumpedAddress) the same as the (inputAddress)?)
                /** @dev if-statement which evaluates if the (fistbumpedAddress) address from the array "fistbumpedAddressesFor" for the current index is the same as (inputAddress)
                    = false = (fistbumpedAddress) address from the array "fistbumpedAddressesFor" for the current index is not the same as (inputAddress)
                    = true = (fistbumpedAddress) address from the array "fistbumpedAddressesFor" for the current index is the same as (inputAddress)
                */
                if ( fistbumpedAddressesFor[msg.sender][i] == _inputAddress ) {
                    
                    /// @notice Setting local variable "alreadyFistbumped" to "true"
                    /// @dev "alreadyFistbumped" is set to "true", which means the "alreadyFistbumped" evaluation will fail in the requirement
                    alreadyFistbumped = true;

                    /// @notice Declaration of break
                    /// @dev Break is used to break the for-loop, since "alreadyFistbumped" evaluation is already failed
                    break;

                } else {
                    
                    /// @notice Setting local variable "alreadyFistbumped" to "false"
                    /// @dev "alreadyFistbumped" is set to "false", which means the "alreadyFistbumped" evaluation may succeed in the requirement 
                    alreadyFistbumped = false;

                }

            }

        } else {

            /// @notice Setting local variable "alreadyFistbumped" to "false"
            /** @dev "alreadyFistbumped" is set to "false" because (callingAddress) has not made any fistbumps, 
                which means (inputAddress) is not already fistbumped by (callingAddress)
                which also means the "alreadyFistbumped" evaluation will succeed in the requirement 
            */
            alreadyFistbumped = false;

        }  

        /// @notice Declaration of requirement to avoid (callingAddress) fistbumping (inputAddress) twice
        /// @dev "alreadyFistbumped" can not be "true" after evaluation
        require ( alreadyFistbumped == false, "This address is already fistbumped!" );

        /// @notice Declaration of check (has (inputAddress) fistbumped another address before?)
        /** @dev if-statement which evaluates if the length of "fistbumpedAddressesFor" array for (inputAddress) is greater than "0"
            = false = further evaluation is not needed since (inputAddress) has not made any fistbumps
            = true = further evaluation is needed since (inputAddress) can potentially already have fistbumped (callingAddress)
        */
        if ( fistbumpedAddressesFor[_inputAddress].length > 0 ) {

            /// @notice Declaration of loop (through all of the fistbumps (inputAddress) has made)
            /** @dev for-loop which loops through the array "fistbumpedAddressesFor" for (inputAddress)
                which enable evaluation of each fistbumped address for (inputAddress)
            */
            for ( uint256 i = 0; i < fistbumpedAddressesFor[_inputAddress].length; i++ ) {

                /// @notice Declaration of check (is the (fistbumpedAddress) the same as the (callingAddress)?)
                /** @dev if-statement which evaluates if the (fistbumpedAddress) address from the array "fistbumpedAddressesFor" for the current index is the same as (callingAddress)
                    = false = (fistbumpedAddress) address from the array "fistbumpedAddressesFor" for the current index is not the same as (callingAddress)
                    = true = (fistbumpedAddress) address from the array "fistbumpedAddressesFor" for the current index is the same as (callingAddress)
                */
                if ( fistbumpedAddressesFor[_inputAddress][i] == msg.sender ) {
                    
                    /// @notice Populating "fistbumpedAddressesFor" array for (callingAddress) with (inputAddress) address
                    fistbumpedAddressesFor[msg.sender].push( _inputAddress );

                    /// @notice Incrementing public global variable "totalFistbumps"
                    totalFistbumps++;

                    /// @notice Incrementing mapping "totalRespondedFistbumpsFor" for (callingAddress)
                    totalRespondedFistbumpsFor[msg.sender]++;

                    /// @notice Incrementing mapping "totalRespondedFistbumpsFor" for (inputAddress)
                    totalRespondedFistbumpsFor[_inputAddress]++;

                    /// @notice Declaration of loop (through all of the fistbumps not responded by (callingAddress))
                    /** @dev for-loop which loops through the array "fistbumpsNotRespondedBy" for (callingAddress)
                        which enable evaluation of each fistbump not responded by (callingAddress)
                    */
                    for ( uint256 ii = 0; ii < fistbumpsNotRespondedBy[msg.sender].length; ii++ ) {
                        
                        /// @notice Declaration of check (is the (inputAddress) the same as the address which (callingAddress) has not responded?)
                        /** @dev if-statement which evaluates if the address from the array "fistbumpsNotRespondedBy" for the current index is the same as (inputAddress)
                                = false = address from the array "fistbumpsNotRespondedBy" for the current index is not the same as (inputAddress)
                                = true = address from the array "fistbumpsNotRespondedBy" for the current index is the same as (inputAddress)
                        */
                        if ( fistbumpsNotRespondedBy[msg.sender][ii] == _inputAddress ) {
                            
                            /// @notice Replacing address with the address from the last element in the array "fistbumpsNotRespondedByAddress"
                            /// @dev Replacement is done to enable usage of "pop"
                            fistbumpsNotRespondedBy[msg.sender][ii] = fistbumpsNotRespondedBy[msg.sender][fistbumpsNotRespondedBy[msg.sender].length - 1];  

                            /// @notice Remove the last element in the array "fistbumpsNotRespondedByAddress"
                            /// @dev It is OK to remove the last element since replacement was done
                            fistbumpsNotRespondedBy[msg.sender].pop();

                            /// @notice Declaration of break
                            /// @dev Break is used to break the for-loop, since (inputAddress) was already found and handled
                            break;

                        }

                    }

                    /// @notice Emit event "fistbumped"
                    /// @dev "fistbumped" can be picked up by front-end to alert the (inputAddress) that is has been fistbumped
                    emit fistbumped ( msg.sender, _inputAddress );

                    /// @notice Declaration of break
                    /// @dev Break is used to break the for-loop, since fistbump has already been made
                    break;

                }

            }

        } else {
            
            /// @notice Populating "fistbumpedAddressesFor" array for (callingAddress) with (inputAddress) address
            fistbumpedAddressesFor[msg.sender].push( _inputAddress );

            /// @notice Incrementing public global variable "totalFistbumps"
            totalFistbumps++;

            /// @notice Populating "fistbumpsNotRespondedBy" array for (inputAddress) with (callingAddress) address
            fistbumpsNotRespondedBy[_inputAddress].push( msg.sender );

            /// @notice Emit event "fistbumped"
            /// @dev "fistbumped" can be picked up by front-end to alert the (inputAddress) that is has been fistbumped
            emit fistbumped ( msg.sender, _inputAddress );

        }    
        
    }

    /// @notice Declaration of the function "isThisFistbumpResponded" which is used to check if (fistbumpedAddress) has (respondedFistbump) by (fistbumpingAddress)
    /** @dev Function overview
        1. Go through all fistbumps made by (fistbumpingAddress)
        2. Is (fistbumpedAddress) fistbumped by (fistbumpingAddress)
        2.1 Yes - Return true
        2.2 No - Return false
    */
    /// @param _fistbumpingAddress is the address (fistbumpingAddress) that made the fistbump
    /// @param _fistbumpedAddress is the address (fistbumpedAddress) that was fistbumped
    function isThisFistbumpResponded ( address _fistbumpingAddress, address _fistbumpedAddress ) private view returns ( bool ) {

        /// @notice Declaration of local variable "isFistbumpResponded"
        /** @dev "isFistbumpResponded" is used as a flag and will hold the boolean value (has (fistbumpedAddress) fistbumped (fistbumpingAddress)?)
            = false = (fistbumpedAddress) has not fistbumped (fistbumpingAddress)
            = true = (fistbumpedAddress) has fistbumped (fistbumpingAddress)
        */
        bool isFistbumpResponded;

        /// @notice Declaration of loop (through all of the fistbumps (fistbumpingAddress) has made)
        /** @dev for-loop which loops through the array "fistbumpedAddressesFor" for (fistbumpingAddress)
            which enable evaluation of each fistbumped address for (fistbumpingAddress)
        */
        for ( uint256 i = 0; i < fistbumpedAddressesFor[_fistbumpingAddress].length; i++ ) { 

            /// @notice Declaration of check (is the (fistbumpedAddress) the same as (fistbumpedAddress)?)
            /** @dev if-statement which evaluates if the (fistbumpedAddress) from the array "fistbumpedAddressesFor" for the current index is the same as (fistbumpedAddress)
                    = false = (fistbumpedAddress) from the array "fistbumpedAddressesFor" for the current index is not the same as (fistbumpedAddress)
                    = true = (fistbumpedAddress) from the array "fistbumpedAddressesFor" for the current index is the same as (fistbumpedAddress)
            */
            if ( fistbumpedAddressesFor[_fistbumpingAddress][i] == _fistbumpedAddress ) {

                /// @notice Setting local variable "isFistbumpResponded" to "true"
                /// @dev "isFistbumpResponded" is set to "true", which means the function will return "true"
                isFistbumpResponded = true;

                /// @notice Declaration of break
                /// @dev Break is used to break the for-loop, since "isFistbumpResponded" evaluation is already succeeded
                break;

            } else {
                
                /// @notice Setting local variable "isFistbumpResponded" to "false"
                /// @dev "isFistbumpResponded" is set to "false", which means the function will return "false"
                isFistbumpResponded = false;

            }
        
        }

        /// @notice Return the boolean value of "isFistbumpResponded"
        return isFistbumpResponded;

    }

    /// @notice Declaration of the function "isThisFistbumpMinted" which is used to check if fistbump with (fistbumpedAddress) is minted for (fistbumpingAddress)
    /** @dev Function overview
        1. Go through all fistbumps made by (fistbumpingAddress)
        2. Is fistbump with (fistbumpedAddress) minted for (fistbumpingAddress)
        2.1 Yes - Return true
        2.2 No - Return false
    */
    /// @param _fistbumpingAddress is the address (fistbumpingAddress) that made the fistbump
    /// @param _fistbumpedAddress is the address (fistbumpedAddress) that was fistbumped
    function isThisFistbumpMinted ( address _fistbumpingAddress, address _fistbumpedAddress ) private view returns ( bool ) {

        /// @notice Declaration of local variable "isFistbumpMinted"
        /** @dev "isFistbumpMinted" is used as a flag and will hold the boolean value (has (fistbumpingAddress) already minted the fistbump for (fistbumpedAddress)?)
            = false = (fistbumpingAddress) has not minted the fistbump for (fistbumpedAddress)
            = true = (fistbumpingAddress) has minted the fistbump for (fistbumpedAddress)
        */
        bool isFistbumpMinted;

        /// @notice Declaration of loop (through all of the (mintedFistbumps) (fistbumpingAddress) has made)
        /** @dev for-loop which loops through the array in the mapping "mintedFistbumpsFor" for (fistbumpingAddress)
            which enable evaluation of each (mintedFistbump) for (fistbumpingAddress)
        */
        for ( uint256 i = 0; i < mintedFistbumpsFor[_fistbumpingAddress].length; i++ ) { 
                
            /// @notice Declaration of check (has the fistbump for (fistbumpedAddress) already been minted by (fistbumpingAddress)?)
            /** @dev if-statement which evaluates if the (fistbumpedAddress) is the same as the (fistbumpedAddress) of the (mintedFistbump) for (fistbumpingAddress)
                = false = (fistbumpedAddress) is not the same as the (fistbumpedAddress) of the (mintedFistbump) for (fistbumpingAddress)
                = true = (fistbumpedAddress) is the same as the (fistbumpedAddress) of the (mintedFistbump) for (fistbumpingAddress)
            */
            if ( mintedFistbumpsFor[_fistbumpingAddress][i].fistbumpedAddress == _fistbumpedAddress ) {
                    
                    /// @notice Setting local variable "isFistbumpMinted" to "true"
                    /// @dev "isFistbumpMinted" is set to "true", which means the function will return "true"
                    isFistbumpMinted = true;

                    /// @notice Declaration of break
                    /// @dev Break is used to break the for-loop, since "isFistbumpMinted" evaluation is already succeeded
                    break;

                } else {
                    
                    /// @notice Setting local variable "isFistbumpMinted" to "false"
                    /// @dev "isFistbumpMinted" is set to "false", which means the function will return "false"
                    isFistbumpMinted = false;
                }

            }

        /// @notice Return the boolean value of "isFistbumpMinted"
        return isFistbumpMinted;

    }


    /// @notice Declaration of the function "mintFistbumpForFistbumpWith" which allow an address (callingAddress) to mint a fistbump representing fistbump with address (inputAddress)
    /** @dev Function overview
        1. Making sure (callingAddress) has made atleast 1 fistbump ("anyFistbumpsFor" modifier), otherwise nothing eligable to mint
        2. Make sure (callingAddress) has fistbumped (inputAddress) and that fistbump is (respondedFistbumps)
        3. Make sure the fistbump has not been minted already
        5. "totalMintedFistbumps" is incremented
        6. "mintedFistbumpsFor" is populated for (callingAddress)
        7. fistbump is minted
    */
    /// @param _inputAddress is the address (fistbumpedAddress) for which the fistbump should be minted 
    function mintFistbumpForFistbumpWith ( address _inputAddress ) public anyFistbumpsFor ( msg.sender ) {

        /// @notice Declaration of local variable "isFistbumpResponded"
        /** @dev "isFistbumpResponded" is used as a flag and will hold the boolean value (has (inputAddress) fistbumped (callingAddress)?)
            = false = (inputAddress) has not fistbumped (callingAddress)
            = true = (inputAddress) has fistbumped (callingAddress)
            Evaluation is done in the helper-function "isFistbumpResponded"
        */
        bool isFistbumpResponded = isThisFistbumpResponded ( _inputAddress, msg.sender );

        /// @notice Declaration of requirement to avoid minting of ineligable fistbump
        /// @dev "isFistbumpResponded" can not be "false" after evaluation
        require ( isFistbumpResponded == true, "The specified address is not fistbumped or has not responded the fistbump." );

        /// @notice Declaration of local variable "isFistbumpMinted"
        /** @dev "isFistbumpMinted" is used as a flag and will hold the boolean value (has (callingAddress) already minted the fistbump for (inputAddress)?)
            = false = (callingAddress) has not minted the fistbump for (inputAddress)
            = true = (callingAddress) has minted the fistbump for (inputAddress)
        */
        bool isFistbumpMinted;
        
        /// @notice Declaration of check (has (callingAddress) minted a fistbump before?)
        /** @dev if-statement which evaluates if the total (mintedFistbumps) for (callingAddress) is greater than "0"
            = false = further evaluation is not needed since (callingAddress) has not minted any fistbumps
            = true = further evaluation is needed since (callingAddress) can potentially already have minted the fistbump for (inputAddress)
        */
        if ( mintedFistbumpsFor[msg.sender].length > 0 ) {

            /// @notice Evaluate if (callingAddress) has minted the fistbump for (inputAddress)
            /// @dev Evaluation is done in the helper-function "isFistbumpMinted"
            isFistbumpMinted = isThisFistbumpMinted ( msg.sender, _inputAddress );

        } else {

            /// @notice "isFistbumpMinted" can be set to "false" since (callingAddress) has not minted any fistbumps
            isFistbumpMinted = false;

        }
        
        /// @notice Declaration of requirement to avoid (callingAddress) minting the same fistbump twice
        /// @dev "isFistbumpMinted" can not be "true" after evaluation
        require ( isFistbumpMinted == false, "The fistbumped has already been minted for the address." );

        /// @notice Incrementing public global variable "totalMintedFistbumps"
        /// @dev "totalMintedFistbumps" is used to mint the fistbump in "_safeMint"
        totalMintedFistbumps++;

        /// @notice Populating "mintedFistbumpsFor" array for (callingAddress) 
        /// @dev "totalMintedFistbumps" as tokenID and "_inputAddress" as "fistbumpedAddress"
        mintedFistbumpsFor[msg.sender].push( mintedFistbump ( totalMintedFistbumps, _inputAddress ) );

        /// @notice Minting the fistbump with ERC721-function "_safeMint"
        _safeMint( msg.sender, totalMintedFistbumps );

        /// @notice Emit event "fistbumpMinted"
        emit fistbumpMinted ( msg.sender, totalMintedFistbumps );

    }

    /// @notice Declaration of the function "totalFistbumpsFor" which return the total fistbumps for an address (inputAddress)
    /** @dev Function overview
        1. Return the length of the array "fistbumpedAddressesFor" for (inputAddress)
    */
    /// @param _inputAddress is the address (fistbumpingAddress) of which the total fistbumps should be returned
    function totalFistbumpsFor ( address _inputAddress ) public view returns ( uint256 ) {

        /// @notice Return the length of the array "fistbumpedAddressesFor" for (inputAddress)
        return fistbumpedAddressesFor[_inputAddress].length;

    }

    /// @notice Declaration of the function "totalUnrespondedFistbumpsFor" which return the total (unrespondedFistbumps) for an address (inputAddress)
    /** @dev Function overview
        1. Return the sum of "totalFistbumpsFor" length and "totalRespondedFistbumpsFor" for (inputAddress)
    */
    /// @param _inputAddress is the address (fistbumpingAddress) of which the total (unrespondedFistbumps) should be returned
    function totalUnrespondedFistbumpsFor ( address _inputAddress ) public view returns ( uint256 ) {

        /// @notice Return the sum of "totalFistbumpsFor" length and "totalRespondedFistbumpsFor" for (inputAddress)
        return fistbumpedAddressesFor[_inputAddress].length - totalRespondedFistbumpsFor[_inputAddress];

    }

    /// @notice Declaration of the function "totalMintedFistbumpsFor" which return the total (mintedFistbumps) an address (inputAddress)
    /** @dev Function overview
        1. Return the length of the array "mintedFistbumpsFor" for (inputAddress)
    */
    /// @param _inputAddress is the address (fistbumpingAddress) of which the total (mintedFistbumps) should be returned
    function totalMintedFistbumpsFor ( address _inputAddress ) public view returns ( uint256 ) {

        /// @notice Return the length of the array "mintedFistbumpsFor" for (inputAddress)
        return mintedFistbumpsFor[_inputAddress].length;

    }

    /// @notice Declaration of the function "totalFistbumpsEligableToMintFor" which return the total (eligableFistbumps) an address (inputAddress)
    /** @dev Function overview
        1. Return the sum of "totalRespondedFistbumpsFor" and "totalMintedFistbumpsFor" length for (inputAddress)
    */
    /// @param _inputAddress is the address (fistbumpingAddress) of which the total (eligableFistbumps) should be returned
    function totalFistbumpsEligableToMintFor ( address _inputAddress ) public view returns ( uint256 ) {

        /// @notice Return the sum of "totalRespondedFistbumpsFor" and "totalMintedFistbumpsFor" length for (inputAddress)
        return totalRespondedFistbumpsFor[_inputAddress] - mintedFistbumpsFor[_inputAddress].length;

    }

    /// @notice Declaration of the function "totalFistbumpsNotRespondedBy" which return the total fistbumps not responded by an address (inputAddress)
    /** @dev Function overview
        1. Return the length of "fistbumpsNotRespondedBy" for (inputAddress)
    */
    /// @param _inputAddress is the address (fistbumpingAddress) of which the total fistbumps not responded by (inputAddress) should be returned
    function totalFistbumpsNotRespondedBy ( address _inputAddress ) public view returns ( uint256 ) {

        /// @notice Return the length of "fistbumpsNotRespondedBy" for (inputAddress)
        return fistbumpsNotRespondedBy[_inputAddress].length;

    }

    /// @notice Declaration of the function "respondedFistbumpedAddressesFor" which return all (respondedFistbumps) ["fistbumpedAddress"] for an address (inputAddress)
    /** @dev Function overview
        1. Making sure (inputAddress) has made atleast 1 fistbump ("anyFistbumpsFor" modifier), otherwise nothing to return
        2. Make sure (inputAddress) has atleast 1 (respondedFistbump), otherwise nothing to return
        3. Go through all fistbumps (inputAddress) has made. Has (fistbumpedAddress) responded the fistbump?
        3.1 Yes
            3.1.1 Add the (fistbumpedAddress) address in the to-be-returned array
        3.2 No
            3.2.1 Check next fistbump (inputAddress) has made
        4. Return the (respondedFistbumps) for (inputAddress)
    */
    /// @param _inputAddress is the address (fistbumpingAddress) of which the (respondedFistbumps) ["fistbumpedAddress"] should be returned
    function respondedFistbumpedAddressesFor ( address _inputAddress ) public view anyFistbumpsFor ( _inputAddress ) returns ( address[] memory ) {

        /// @notice Declaration of requirement to avoid returning nothing if the (inputAddress) does not have any (respondedFistbumps)
        /// @dev "totalRespondedFistbumpsFor" for the (inputAddress) can not be "0"
        require ( totalRespondedFistbumpsFor[_inputAddress] > 0, "This address does not have any responded fistbumps." );

        /// @notice Setting local variable "index" to "0"
        /** @dev "index" is used to populate local array "respondedFistbumps" properly
            "index" is incremented when a (respondedFistbump) is found for the (inputAddress)
        */
        uint256 index = 0;

        /// @notice Declaration of local array "respondedFistbumps"
        /// @dev "respondedFistbumps" is a static address array, with the length of "totalRespondedFistbumpsFor" for the (inputAddress)
        address[] memory respondedFistbumps = new address[]( totalRespondedFistbumpsFor[_inputAddress] );

        /// @notice Declaration of loop (through all of the fistbumps (inputAddress) has made)
        /** @dev for-loop which loops through the array "fistbumpedAddressesFor" for (inputAddress)
            which enable population of local array "respondedFistbumps" when a (respondedFistbump) is found
        */
        for ( uint256 i = 0; i < fistbumpedAddressesFor[_inputAddress].length; i++ ) {

            /// @notice Declaration of check (is the fistbump responded by (fistbumpedAddress)?)
            /** @dev if-statement which evaluates if (fistbumpedAddress) has fistbumped (inputAddress)
                = false = (fistbumpedAddress) has not fistbumped (inputAddress)
                = true = (fistbumpedAddress) has fistbumped (inputAddress)
            */
            if ( isThisFistbumpResponded ( fistbumpedAddressesFor[_inputAddress][i], _inputAddress ) == true ) {

                /// @notice Populating "respondedFistbumps" array with the address of the (fistbumpedAddress) which has responded the fistbump
                respondedFistbumps[index] = fistbumpedAddressesFor[_inputAddress][i];

                /// @notice Incrementing local variable "index"
                index++;

            }

        }

        /// @notice Return (fistbumpedAddress) addresses which has responded (inputAddress) fistbumps
        /// @dev Return the array "respondedFistbumps" ["fistbumpedAddress"] for the (inputAddress)
        return respondedFistbumps;

    }

    /// @notice Declaration of the function "unrespondedFistbumpedAddressesFor" which return all (unrespondedFistbumps) ["fistbumpedAddress"] for an address (inputAddress)
    /** @dev Function overview
        1. Making sure (inputAddress) has made atleast 1 fistbump ("anyFistbumpsFor" modifier), otherwise nothing to return
        2. Make sure (inputAddress) has atleast 1 (unrespondedFistbumps), otherwise nothing to return
        3. Go through all fistbumps (inputAddress) has made. Has (fistbumpedAddress) responded the fistbump?
        3.1 Yes
            3.1.1 Check next fistbump (inputAddress) has made
        3.2 No
            3.2.1 Add the (fistbumpedAddress) address in the to-be-returned array
        4. Return the (unrespondedFistbumps) for (inputAddress)
    */
    /// @param _inputAddress is the address (fistbumpingAddress) of which the (unrespondedFistbumps) ["fistbumpedAddress"] should be returned
    function unrespondedFistbumpedAddressesFor ( address _inputAddress ) public view anyFistbumpsFor ( _inputAddress ) returns ( address[] memory ) {

        /// @notice Declaration of requirement to avoid returning nothing if the (inputAddress) does not have any (unrespondedFistbumps)
        /// @dev Sum of "totalFistbumpsFor" and "totalRespondedFistbumpsFor" for the (inputAddress) can not be "0"
        require ( fistbumpedAddressesFor[_inputAddress].length - totalRespondedFistbumpsFor[_inputAddress] > 0, "This address does not have any unresponded fistbumps." );

        /// @notice Setting local variable "index" to "0"
        /** @dev "index" is used to populate local array "unrespondedFistbumps" properly
            "index" is incremented when an (unrespondedFistbump) is found for the (inputAddress)
        */
        uint256 index = 0;

        /// @notice Declaration of local array "unrespondedFistbumps"
        /// @dev "unrespondedFistbumps" is a static address array, with the length of the sum of "totalFistbumpsFor" and "totalRespondedFistbumpsFor" for the (inputAddress)
        address[] memory unrespondedFistbumps = new address[]( fistbumpedAddressesFor[_inputAddress].length - totalRespondedFistbumpsFor[_inputAddress] );

        /// @notice Declaration of loop (through all of the fistbumps (inputAddress) has made)
        /** @dev for-loop which loops through the array "fistbumpedAddressesFor" for (inputAddress)
            which enable population of local array "unrespondedFistbumps" when an (unrespondedFistbump) is found
        */
        for ( uint256 i = 0; i < fistbumpedAddressesFor[_inputAddress].length; i++ ) {

            /// @notice Declaration of check (is the fistbump responded by (fistbumpedAddress)?)
            /** @dev if-statement which evaluates if (fistbumpedAddress) has fistbumped (inputAddress)
                = false = (fistbumpedAddress) has not fistbumped (inputAddress)
                = true = (fistbumpedAddress) has fistbumped (inputAddress)
            */
            if ( isThisFistbumpResponded ( fistbumpedAddressesFor[_inputAddress][i], _inputAddress ) == false ) {

                /// @notice Populating "unrespondedFistbumps" array with the address of the (fistbumpedAddress) which has not responded the fistbump
                unrespondedFistbumps[index] = fistbumpedAddressesFor[_inputAddress][i];

                /// @notice Incrementing local variable "index"
                index++;

            }

        }

        /// @notice Return (fistbumpedAddress) addresses which has not responded (inputAddress) fistbumps
        /// @dev Return the array "unrespondedFistbumps" ["fistbumpedAddress"] for the (inputAddress)
        return unrespondedFistbumps;

    }

    /// @notice Declaration of the function "mintedFistbumpedAddressesFor" which return the (fistbumpedAddresses) for (mintedFistbumps) for an address (inputAddress)
    /** @dev Function overview
        1. Making sure (inputAddress) has made atleast 1 fistbump ("anyFistbumpsFor" modifier), otherwise nothing to return
        2. Make sure (inputAddress) has atleast 1 (mintedFistbump), otherwise nothing to return
        3. Go through all (mintedFistbumps) for (inputAddress)
        4. Return the (fistbumpedAddress) of the (mintedFistbumps) for (inputAddress)
    */
    /// @param _inputAddress is the address (fistbumpingAddress) of which the (fistbumpedAddresses) for (mintedFistbumps) should be returned
    function mintedFistbumpedAddressesFor ( address _inputAddress ) public view anyFistbumpsFor ( _inputAddress ) returns ( address[] memory ) {

        /// @notice Declaration of requirement to avoid returning nothing if the (inputAddress) does not have any (mintedFistbumps)
        /// @dev Length of "mintedFistbumpsFor" for the (inputAddress) can not be "0"
        require ( mintedFistbumpsFor[_inputAddress].length > 0, "This address does not have any minted fistbumps." );

        /// @notice Setting local variable "index" to "0"
        /// @dev "index" is used to populate local array "mintedFistbumps" properly
        uint256 index = 0;

        /// @notice Declaration of local array "mintedFistbumps"
        /// @dev "mintedFistbumps" is a static address array, with the length "mintedFistbumpsFor" for the (inputAddress)
        address[] memory mintedFistbumps = new address[]( mintedFistbumpsFor[_inputAddress].length );

        /// @notice Declaration of loop (through all of the minted fistbumps for (inputAddress))
        /** @dev for-loop which loops through the array "mintedFistbumpsFor" for (inputAddress)
            which enable population of local array "mintedFistbumps"
        */
        for ( uint256 i = 0; i < mintedFistbumpsFor[_inputAddress].length; i++ ) {

            /// @notice Populating "mintedFistbumps" array with the (fistbumpedAddress) of the (mintedFistbump)
            mintedFistbumps[index] = mintedFistbumpsFor[_inputAddress][i].fistbumpedAddress;

            /// @notice Incrementing local variable "index"
            index++;

        }

         /// @notice Return (fistbumpedAddress) addresses for (inputAddress) (mintedFistbump)
        /// @dev Return the array "mintedFistbumps" ["fistbumpedAddress"] for the (inputAddress)
        return mintedFistbumps;

    }

    /// @notice Declaration of the function "mintedFistbumpTokenIdsFor" which return the (tokenIds) for (mintedFistbumps) for an address (inputAddress)
    /** @dev Function overview
        1. Making sure (inputAddress) has made atleast 1 fistbump ("anyFistbumpsFor" modifier), otherwise nothing to return
        2. Make sure (inputAddress) has atleast 1 (mintedFistbump), otherwise nothing to return
        3. Go through all (mintedFistbumps) for (inputAddress)
        4. Return the tokenIds of the (mintedFistbumps) for (inputAddress)
    */
    /// @param _inputAddress is the address (fistbumpingAddress) of which the (fistbumpedAddresses) for (mintedFistbumps) should be returned
    function mintedFistbumpTokenIdsFor ( address _inputAddress ) public view anyFistbumpsFor ( _inputAddress ) returns ( uint256[] memory ) {

        /// @notice Declaration of requirement to avoid returning nothing if the (inputAddress) does not have any (mintedFistbumps)
        /// @dev Length of "mintedFistbumpsFor" for the (inputAddress) can not be "0"
        require ( mintedFistbumpsFor[_inputAddress].length > 0, "This address does not have any minted fistbumps." );

        /// @notice Setting local variable "index" to "0"
        /// @dev "index" is used to populate local array "mintedFistbumps" properly
        uint256 index = 0;

        /// @notice Declaration of local array "mintedFistbumps"
        /// @dev "mintedFistbumps" is a static address array, with the length "mintedFistbumpsFor" for the (inputAddress)
        uint256[] memory mintedFistbumps = new uint256[]( mintedFistbumpsFor[_inputAddress].length );

        /// @notice Declaration of loop (through all of the (mintedFistbumps) for (inputAddress))
        /** @dev for-loop which loops through the array "mintedFistbumpsFor" for (inputAddress)
            which enable population of local array "mintedFistbumps"
        */
        for ( uint256 i = 0; i < mintedFistbumpsFor[_inputAddress].length; i++ ) {

            /// @notice Populating "mintedFistbumps" array with the (tokenId) of the (mintedFistbump)
            mintedFistbumps[index] = mintedFistbumpsFor[_inputAddress][i].tokenID;

            /// @notice Incrementing local variable "index"
            index++;

        }

         /// @notice Return (tokenId) for (inputAddress) (mintedFistbumps)
        /// @dev Return the array "mintedFistbumps" ["tokenId"] for the (inputAddress)
        return mintedFistbumps;

    }
   
    /// @notice Declaration of the function "fistbumpsEligableToMintForAddress" which return all fistbumps ["fistbumpee"] eligable to be minted by an address (fistbumper)
    /** @dev Function overview
        1. Making sure (fistbumper) has made atleast 1 fistbump ("anyFistbumps" modifier), otherwise nothing to return
        2. Make sure (fistbumper) has atleast 1 fistbump eligable to be minted, otherwise nothing to return
        3. Go through all fistbumps (fistbumper) has made. Has "fistbumpee" responded the fistbump?
        3.1 Yes
            3.1.1 Is the fistbump minted?
            3.1.1.1 Yes - Fistbump is not eligable
            3.1.1.2 No - Fistbump is eligable
        3.2 No
            3.2.1 Check next fistbump (fistbumper) has made
        4. Return the fistbumps eligable to be minted for (fistbumper)
    */
    /// @param _inputAddress is the address (fistbumper) of which the fistbumps ["fistbumpee"] eligable to be minted should be returned
    function fistbumpedAddressesEligableToMintFor ( address _inputAddress ) public view anyFistbumpsFor ( _inputAddress ) returns ( address[] memory ) {

        /// @notice Declaration of requirement to avoid returning nothing if the (inputAddress) does not have any elibable fistbumps to mint
        /// @dev Sum of "totalRespondedFistbumpsFor" and "mintedFistbumpsFor" length for the (inputAddress) can not be "0"
        require ( totalRespondedFistbumpsFor[_inputAddress] - mintedFistbumpsFor[_inputAddress].length > 0, "This address does not have any fistbumps eligable to mint." );

        /// @notice Setting local variable "index" to "0"
        /** @dev "index" is used to populate local array "fistbumpsEligableToMint" properly
            "index" is incremented when a (respondedFistbump) is found for the (inputAddress) which is not minted
        */
        uint256 index = 0;

        /// @notice Declaration of local array "fistbumpsEligableToMint"
        /// @dev "fistbumpsEligableToMint" is a static address array, with the length of "totalRespondedFistbumpsFor" subtracted by "mintedFistbumpsFor" length for the (inputAddress)
        address[] memory fistbumpsEligableToMint = new address[]( totalRespondedFistbumpsFor[_inputAddress] - mintedFistbumpsFor[_inputAddress].length );

        /// @notice Declaration of loop (through all of the fistbumps (inputAddress) has made)
        /** @dev for-loop which loops through the array "fistbumpedAddressesFor" for (inputAddress)
            which enable population of local array "fistbumpsEligableToMint" when a fistbump eligable to be minted is found
        */
        for ( uint256 i = 0; i < fistbumpedAddressesFor[_inputAddress].length; i++ ) {

            /// @notice Declaration of check (is the fistbump responded by (fistbumpedAddress)?)
            /** @dev if-statement which evaluates if (fistbumpedAddress) has fistbumped (inputAddress)
                = false = (fistbumpedAddress) has not fistbumped (inputAddress)
                = true = (fistbumpedAddress) has fistbumped (inputAddress)
            */
            if ( isThisFistbumpResponded ( fistbumpedAddressesFor[_inputAddress][i], _inputAddress ) == true ) {
                
                /// @notice Declaration of check (is the fistbump minted by (inputAddress)?)
                /** @dev if-statement which evaluates if fistbump is minted by (inputAddress)
                    = false = fistbump is not minted by (inputAddress)
                    = true = fistbump is minted by (inputAddress)
                */
                if ( isThisFistbumpMinted ( _inputAddress, fistbumpedAddressesFor[_inputAddress][i] ) == false ) {

                    /// @notice Populating "fistbumpsEligableToMint" array with the (fistbumpedAddress) of the fistbump eligable to be minted
                    fistbumpsEligableToMint[index] = fistbumpedAddressesFor[_inputAddress][i];

                    /// @notice Incrementing local variable "index"
                    index++;

                }

            }

        }

        /// @notice Return (fistbumpedAddress) for (inputAddress) fistbumps eligable to be minted
        /// @dev Return the array "fistbumpsEligableToMint" ["fistbumpedAddress"] for the (inputAddress)
        return fistbumpsEligableToMint;

    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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