/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// File: https://github.com/giupt/BIMvalidation/blob/main/Ownable.sol

pragma solidity ^0.4.17;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }


    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// File: BIMOracle.sol

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.4.17;



/// @title BIMOracle
/// @notice Collects and provides information on BIM models verification
contract BIMOracle is Ownable {
    Verification[] verifications; 
    mapping(bytes32 => uint) verificationIdToIndex; 


    //defines a verification along with its result
    struct Verification {
        bytes32 id;
        string discipline;
        string team;
        uint cycle;
        uint date;
        uint percentage;
        VerificationResult result;
    }

    //possible verification results 
    enum VerificationResult {
        Pending,    //verification is under decision
        Validated,  //verification has met the minimum level of compliance
        Rejected    //verification hasn't met the minimum level of compliance
    }

    /// @notice returns the array index of the verification with the given id 
    /// @dev if the verification id is invalid, then the return value will be incorrect and may cause error; you must call verificationExists(_verificationId) first!
    /// @param _verificationId the verification id to get
    /// @return an array index 
    function _getVerificationIndex(bytes32 _verificationId) private view returns (uint) {
        return verificationIdToIndex[_verificationId]-1; 
    }

    /// @notice determines whether a verification exists with the given id 
    /// @param _verificationId the verification id to test
    /// @return true if verification exists and id is valid
    function verificationExists(bytes32 _verificationId) public view returns (bool) {
        if (verifications.length == 0)
            return false;
        uint index = verificationIdToIndex[_verificationId]; 
        return (index > 0); 
    }

    /// @notice puts a new verification into the blockchain 
    /// @param _discipline represents the project discipline
    /// @param _team represents the design team appointed
    /// @param _cycle is the number of the verification cycle of the BIM model 
    /// @param _date is the date of the verification
    /// @param _percentage is the level of compliance achieved
    /// return the unique id of the newly created verification 
    function addVerification(string _discipline, string _team, uint _cycle, uint _date, uint _percentage) onlyOwner public returns (bytes32) {

        //hash the crucial info to get a unique id 
        bytes32 id = keccak256(abi.encodePacked(_discipline, _team, _cycle, _date, _percentage)); 

        //require that the verification be unique (not already added) 
        require(!verificationExists(id));
        
        //add the verification 
        uint newIndex = verifications.push(Verification(id, _discipline, _team, _cycle, _date, _percentage, VerificationResult.Pending))-1; 
        verificationIdToIndex[id] = newIndex+1;
        
        //return the unique id of the new match
        return id;
    }

    /// @notice sets the result of a predefined verification, permanently on the blockchain
    /// @param _verificationId unique id of the verification
    /// @param _result result of the verification 
    function addResult(bytes32 _verificationId, VerificationResult _result) onlyOwner external {

        //require that it exists
        require(verificationExists(_verificationId));

        //get the verification
        uint index = _getVerificationIndex(_verificationId);
        Verification storage theVerification = verifications[index]; 

        if (_result == VerificationResult.Validated)
            require(theVerification.percentage >= 90);

        //set the result 
        theVerification.result = _result;

    }

    /// gets the specified verification 
    /// @param _verificationId the unique id of the desired verification 
    /// return verification data of the specified verification 
    function getVerification(bytes32 _verificationId) public view returns (
        bytes32 id,
        string discipline,
        string team,
        uint cycle,
        uint date,
        uint percentage,
        VerificationResult result) {
        
        //get the verification 
        if (verificationExists(_verificationId)) {
            Verification storage theVerification = verifications[_getVerificationIndex(_verificationId)];
            return (theVerification.id, theVerification.discipline, theVerification.team, theVerification.cycle, theVerification.date, theVerification.percentage, theVerification.result); 
        }
        else {
            return (_verificationId, "", "", 0, 0, 0, VerificationResult.Pending); 
        }
    }

    /// @notice can be used by a client contract to ensure that they've connected to this contract interface successfully
    /// @return true, unconditionally 
    function testConnection() public pure returns (bool) {
        return true; 
    }

    /// @notice gets the address of this contract 
    /// @return address 
    function getAddress() public view returns (address) {
        return this;
    }
}