// SPDX-License-Identifier: MIT
// CollyptoValidator Contract v1.0.0
pragma solidity ^0.8.17 < 0.9.0;

/**
 * @title Collypto Validator
 * @author Matthew McKnight - Collypto Technologies, Inc.
 * @notice This contract allows Ethereum users to self-validate, prove
 * account ownership, and retrieve the validation status of any account.
 * @dev This contract is the implementation of the Collypto Validator on the
 * Ethereum blockchain.
 * 
 * This contract allows any user to prove ownership of an Ethereum account by
 * calling the {validate} function with a provided {code} string as the input
 * parameter, and it allows any user to check the validation status of any
 * account by calling the {isValidated} function with account address provided
 * as the {targetAddress}.
 * 
 * Since {validate} can only be called by the owner of the private key
 * corresponding to the Ethereum account to be validated, and the
 * {AccountValidated} event includes the account address and validation code,
 * it is impossible for a user to validate ownership of an account that they do
 * not own, and consequently, it is impossible for anyone to corrupt the
 * {_validatedAddresses} mapping where validation status is maintained for all
 * accounts.
 *
 * The {validate} function can be repeated any number of times for a given
 * Ethereum account, and an arbitrary validation code can be used to verify
 * ownership of the account itself without requiring any off-chain functions or
 * L2 applications. Validation codes are arbitrary, and their only purpose is
 * to allow a user to demonstrate account ownership to another user or
 * institution.
 * 
 * Users can check the validation status of any Ethereum account by calling the
 * {isValidated} function and providing the account address as the
 * {targetAddress} input parameter. This function returns a Boolean value
 * indicating whether the corresponding account has been previously validated
 * by the caller or another operator.
 * 
 * Utilizing the {isValidated} function to check the validation status of a
 * recipient Ethereum account prior to conducting transfers of any Ethereum
 * based token effectively eliminates the risk of mistyping a recipient
 * address, provided its owner has already validated the account at least once
 * using the {validate} function.
 */
contract CollyptoValidator {
    /**
     * @dev Mapping of validation status of all possible Ethereum accounts
     * (indexed by account address)
     */
    mapping(address => bool) private _validatedAddresses;
    
    /** 
     * @dev Event emitted when an operator validates ownership of an Ethereum
     * account at `owner` with validation code `code`
     */ 
    event AccountValidated(address indexed owner, string code);

    /**
     * @notice Validates ownership of the operator's Ethereum account
     * @dev Validation can only be conducted by an operator using the Ethereum
     * account to be validated, and {code} can be set to any string value.
     * @param code A string provided by the user to demonstate that they are
     * the operator
     * @return success A Boolean value indicating that the operator's Ethereum
     * account has been successfully validated
     */
    function validate(string memory code)
        public
        returns (bool success)
    {
        _validatedAddresses[msg.sender] = true;

        emit AccountValidated(msg.sender, code);

        return true;
    }

    /**
     * @notice Returns a Boolean value indicating whether the Ethereum account
     * at `targetAddress` has previously been validated
     * @dev This function can be called by any operator, regardless of the
     * validation status of their Ethereum account.
     * @param targetAddress The address of the Ethereum account to be checked
     * for validation
     * @return validated A Boolean value indicating whether the Ethereum
     * account at {targetAddress} has previously been validated
     */
    function isValidated(address targetAddress)
        public
        view
        returns (bool validated)
    {
        return _validatedAddresses[targetAddress];
    }
}