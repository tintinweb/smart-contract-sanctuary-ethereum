//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Chainlink oracle interface
interface IAggregatorInterface {
    function latestAnswer() external view returns (int256);
}

//SPDX-License-Identifier: MIT 
pragma solidity ^0.8.18;

import {IXAPRegistry} from "./IXAPRegistry.sol";
import {IAggregatorInterface} from "./IAggregatorInterface.sol";

interface IXAPRegistrar {

    function xap() external view returns (IXAPRegistry);
    function usdOracle() external view returns (IAggregatorInterface);
    function minNumbers() external view returns (uint32);
    function minLetters() external view returns (uint32);
    function minCharacters() external view returns (uint32);
    function minCommitmentAge() external view returns (uint256);
    function maxCommitmentAge() external view returns (uint256);
    function charAmounts(uint256) external view returns (uint256);
    function commitments(bytes32) external view returns (uint256); 

    function makeCommitment(
        bytes32 name,
        address owner,
        bytes32 secret
    ) external pure returns (bytes32);

    function commit(bytes32 commitment) external;

    function claim(
        bytes32 name, 
        uint96 accountData,
        uint chainId, 
        address _address,
        uint96 addressData,
        bytes32 secret
    ) external payable;

    function setMinimumCharacters(uint32 _minNumbers, uint32 _minLetters, uint32 _minCharacters) external;

    function setPricingForAllLengths(
        uint256[] calldata _charAmounts
    ) external;

    function updatePriceForCharLength(
        uint16 charLength,
        uint256 charAmount
    ) external;

    function addNextPriceForCharLength(
        uint256 charAmount
    ) external;

    function getLastCharIndex() external view returns (uint256);

    function setMinMaxCommitmentAge(uint256 _minCommitmentAge, uint256 _maxCommitmentAge) external;

    function getMinimums() external view returns(uint32,uint32,uint32);

    function getRandomName(
        uint256 maxLoops, 
        uint256 _minNumbers, 
        uint256 _minLetters, 
        uint256 _numChars,
        uint256 _salt
    ) external view returns (bytes32);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IXAPRegistry{

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed name, address owner);

    // Logged when a address is added or updated for a name.
    event NewAddress(bytes32 indexed name, uint chainId);

    function setApprovalForAll(address operator) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function approve(bytes32 name, address delegate) external;

    function isApprovedFor(address owner, bytes32 name, address delegate) external view returns (bool);

    function register(bytes32 name, address _owner, uint256 chainId, address _address) external;

    function registerWithData(bytes32 name, address _owner, uint96 accountData, uint256 chainId, address _address, uint96 addressData) external;

    function registerAddress(bytes32 name, uint256 chainId, address _address) external;

    function registerAddressWithData(bytes32 name, uint256 chainId, address _address, uint96 addressData) external;

    function setOwner(bytes32 name, address _address) external;

    function setAccountData(bytes32 name, uint96 accountData) external;

    function resolveAddress(bytes32 name, uint256 chainId) external view returns (address);

    function resolveAddressWithData(bytes32 name, uint256 chainId) external view returns (address, uint96);

    function getOwner(bytes32 name) external view returns (address);

    function getOwnerWithData(bytes32 name) external view returns (address, uint96);

    function available(bytes32 name) external view returns (bool);

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library Normalize{

    /*
     * @dev Checks to make sure the name only has UTF-8 character
            0-9, a-z, and -.
     * @param name The name to check whether it is normalized or not.
     */

    function isNormalized(bytes32 name, uint minNumbers, uint minLetters, uint minChars) internal pure returns(bool, uint){

        bool gotZero;
        bool allowed;
        bool isNumber;
        bool isLetter;

        uint numNumbers;
        uint numLetters;
        uint numChars;

        for (uint i; i < 32; ++i){

            if (i == 0){ //The first char must not be 0x00

                (allowed, isNumber, isLetter) = allowedChar(name,i);

                if (name[i] == 0x00 || !allowed){
                    return (false, 0);
                }

                if (isNumber) { 
                    ++numNumbers; 
                    ++numChars; 
                }

                if (isLetter) { 
                    ++numLetters; 
                    ++numChars; 
                }

            } else { // No spaces are allowed

                (allowed, isNumber, isLetter) = allowedChar(name,i);

                if (!allowed){
                    return (false, 0);
                }

                if (isNumber) { 
                    ++numNumbers; 
                    ++numChars; 
                }

                if (isLetter) { 
                    ++numLetters; 
                    ++numChars; 
                }

                // If we have a 0x00, we can't have any more characters.
                if (name[i] == 0x00){
                    gotZero = true;
                } else {
                    if (gotZero){
                        return (false, 0);
                    }
                }
            }
        }

        
        bool isNormal = numNumbers < minNumbers ||
               numLetters < minLetters || 
               numChars < minChars ? false : true;

        return (isNormal, numChars);
    }

    function allowedChar(bytes32 name, uint i) internal pure returns(bool allowed, bool isNumber, bool isLetter){

            if (_isNumber(name[i])){ //0-9
                allowed = true;
                isNumber = true;
            } else if (_isLetter(name[i])){ //a-z
                allowed = true;
                isLetter = true;
            } else if (name[i] == 0x2d && (i >= 1 && i <= 8)){ //-
                // "-" is only allowed if it is not the first or last character
                // and if it is surrounded by a number or letter
                if ((_isNumber(name[i-1]) || _isLetter(name[i-1])) && 
                    (_isNumber(name[i+1]) || _isLetter(name[i+1]))){
                    allowed = true;
                    isLetter = true; // the "-" character is considered a letter
                }
            } else if (name[i] == 0x00){ 
                allowed = true;
            }

    }

    function _isLetter(bytes1 char) private pure returns (bool isLetter){
        if(char >= 0x61 && char <= 0x7a){ isLetter =true; }
    }

    function _isNumber(bytes1 char) private pure returns (bool isNumber){
        if(char >= 0x30 && char <= 0x39){ isNumber = true; }
    }

}

//SPDX-License-Identifier: MIT 
pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Normalize} from "./Normalize.sol";
import {IXAPRegistry} from "./IXAPRegistry.sol";
import {IXAPRegistrar} from "./IXAPRegistrar.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IAggregatorInterface} from "./IAggregatorInterface.sol";

error MinCharsTooLow();
error UnexpiredCommitment(bytes32 commitment);
error CommitmentTooOld(bytes32 commitment);
error CommitmentTooNew(bytes32 commitment);
error MinCommitmentAgeTooHigh();
error MaxCommitmentAgeTooLow();
error NoNameFoundAfterNAttempts(uint256 maxLoops);
error NameNotNormalized(bytes32 name);
error InsufficientValue();
error MinCommitmentGreaterThanMaxCommitment();
error CannotSetNewCharLengthAmounts();

contract XAPRegistrar is IXAPRegistrar, ERC165, Ownable{

    IXAPRegistry public xap;
    using Normalize for bytes32;

    // Chainlink oracle address
    IAggregatorInterface public immutable usdOracle;
    
    // The required number of numbers, letters, and characters in a name.
    uint32 public minNumbers;
    uint32 public minLetters;
    uint32 public minCharacters;

    // The minimum and maximum age of a commitment before it can be used to register a name.
    uint256 public minCommitmentAge;
    uint256 public maxCommitmentAge;

    // Save the pricing for each character (1-6) in wei. 7-10 are free to register.
    uint256[] public charAmounts;

    // A mapping of commitments to the date stamps.
    mapping(bytes32 => uint256) public commitments;

    constructor(IXAPRegistry _xap, IAggregatorInterface _usdOracle){

        xap = _xap;

        // The minimum number of numbers, letters, and characters in a name.
        // This can be changed by the owner of the contract.
        minNumbers = 3;
        minLetters = 3;
        minCharacters = 7;

        minCommitmentAge = 1 minutes;
        maxCommitmentAge = 7 days;

        usdOracle = _usdOracle;
    }

    /**
    * @dev The function creates a commitment hash of a name, owner and a secret.
    * @param name The name to be included in the commitment.
    * @param owner The address to be included in the commitment.
    * @param secret A secret to be included in the commitment.
    * @return The commitment hash created from the name, owner and secret.
    */

    function makeCommitment(
        bytes32 name,
        address owner,
        bytes32 secret
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    name,
                    owner,
                    secret
                )
            );
    }

    /**
    * @dev The function commits a commitment hash of a name, owner and a secret.
    * @param commitment The commitment hash to be committed.
    */

    function commit(bytes32 commitment) public {
        // Check to make sure the commitment has expired (or does not exist). 
        if (commitments[commitment] + maxCommitmentAge >= block.timestamp) {
            revert UnexpiredCommitment(commitment);
        }
        commitments[commitment] = block.timestamp;
    }

    /**
    * @dev The function claims a name and registers it.
    * @param name The name to be claimed.
    * @param chainId The chainId on which the name will be registered.
    * @param _address The address to be registered as the owner of the name.
    */

    function claim(
        bytes32 name, 
        uint96 accountData, 
        uint256 chainId, 
        address _address,
        uint96 addressData, 
        bytes32 secret
        ) external payable{

        (bool isNormal, uint256 nameLength) = name.isNormalized(minNumbers, minLetters, minCharacters);

        if(!isNormal){
            revert NameNotNormalized(name);
        }

        // check to make sure nameLength is not greater than the length of the charAmounts array
        // if it is, then set the amount to charAmounts[0]

        uint256 price;
        if(nameLength >= charAmounts.length){
           price = usdToWei(charAmounts[0]);
        } else {
            price = usdToWei(charAmounts[nameLength]);
        }

        if (msg.value < price) {
            revert InsufficientValue();
        }

        // Check the commitment to make sure its valid.
        _burnCommitment(
            makeCommitment(
                name,
                msg.sender,
                secret
            )
        );

       // Register an available name 
        xap.registerWithData(name, msg.sender, accountData, chainId, _address, addressData);

        // If the the sender sent more ETH than necessary send the remainder back.
        if (msg.value > (price)) {
            payable(msg.sender).transfer(
                msg.value - price
            );
        }

    }   

    /**
    * @dev The function sets the minimum number of required numbers, letters and characters for a name.
    * @param _minNumbers The minimum number of numbers required in a name.
    * @param _minLetters The minimum number of letters required in a name.
    * @param _minCharacters The minimum number of characters required in a name.
    */

    function setMinimumCharacters(uint32 _minNumbers, uint32 _minLetters, uint32 _minCharacters) public onlyOwner{

        // The minimum number of characters must be greater than or equal to the 
        // sum of the minimum number of letters and numbers.
        if(minNumbers + minLetters > minCharacters){
            revert MinCharsTooLow();
        }

        minNumbers = _minNumbers;
        minLetters = _minLetters;
        minCharacters = _minCharacters;

    }

    /**
    * @notice Set the pricing for subname lengths.
    * @param _charAmounts An array of amounst for each characer length.
    */  

     function setPricingForAllLengths(
        uint256[] calldata _charAmounts
    ) public onlyOwner{

        // Clear the old dynamic array out
        delete charAmounts;

        // Set the pricing for names.
        charAmounts = _charAmounts;
        
    }

    /**
     * @notice Set a price for a single character length, e.g. three characters.
     * @param charLength The character length, e.g. 3 would be for three characters. Use 0 for the default amount.
     * @param charAmount The amount in USD/year for a character count, e.g. amount for three characters.
     */
    function updatePriceForCharLength(
        uint16 charLength,
        uint256 charAmount
    ) public onlyOwner{

        // Check that the charLength is not greater than the last index of the charAmounts array.
        if (charLength > charAmounts.length-1){
            revert CannotSetNewCharLengthAmounts();
        }
        charAmounts[charLength] = charAmount;
    }

    /**
     * @notice Adds a price for the next character length, e.g. three characters.
     * @param charAmount The amount in USD/sec. (with 18 digits of precision) 
     * for a character count, e.g. amount for three characters.
     */
    function addNextPriceForCharLength(
        uint256 charAmount
    ) public onlyOwner{

        charAmounts.push(charAmount);
    }

    /**
     * @notice Get the last length for a character length that has a price (can be 0), e.g. three characters.
     * @return The length of the last character length that was set.
     */
    function getLastCharIndex() public view returns (uint256) {
        return charAmounts.length - 1;
    }

    /**
    * @dev The function sets the minimum and maximum age of a commitment before it can be used to register a name.
    * @param _minCommitmentAge The minimum age of a commitment.
    * @param _maxCommitmentAge The maximum age of a commitment.
    */

    function setMinMaxCommitmentAge(uint256 _minCommitmentAge, uint256 _maxCommitmentAge) public onlyOwner{

        if (_minCommitmentAge >= _maxCommitmentAge){
            revert MinCommitmentGreaterThanMaxCommitment();
        }

        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;
    }

    /**
    * @dev The function returns the minimum number of required numbers, letters and characters for a name.
    * @return A tuple containing the minimum number of required numbers, letters, and characters for a name.
    */

    function getMinimums() public view returns(uint32,uint32,uint32){
        return (minNumbers, minLetters, minCharacters);
    }

    /**
    * @dev The function creates random names until it finds an available name.
    * @param maxLoops The maximum number of times to try to find an available name.
    * @return A random name that is available.
    */

    function getRandomName(
        uint256 maxLoops, 
        uint256 _minNumbers, 
        uint256 _minLetters, 
        uint256 _numChars,
        uint256 _salt
    ) 
        public view returns (bytes32) {
        // Generate the random name using only [a-z0-9] or [0x61-0x7a, 0x30-0x39]

        // Try to find a name at most maxLoops times.
        for (uint256 count = 0; count < maxLoops; count++) {

            bytes32 randomName;

            uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, count, _salt)));

            for (uint256 i = 0; i < _numChars; i++) {
                if (randomNumber % 2 == 0) {
                    // The first character will be a number
                    randomName = randomName | (bytes32(bytes1(uint8(48 + (randomNumber % 10)))) >> (i * 8));
                    randomNumber = randomNumber >> 8;
                } else {
                    // The first character will be a letter
                    randomName = randomName | (bytes32(bytes1(uint8(97 + (randomNumber % 26)))) >> (i * 8));
                    randomNumber = randomNumber >> 8;
                }

                randomNumber = randomNumber >> 8;
            }

            (bool isNormal, ) = randomName.isNormalized(_minNumbers, _minLetters, 1);

            //check if the name is available
            if (xap.available(randomName) && isNormal) {
                return randomName;
            }
        }
        // If we can't find a name, revert.
        revert NoNameFoundAfterNAttempts(maxLoops);
    }

    /**
    * @dev Allows the contract owner to withdraw the entire balance of the contract.
    * @notice This function can only be called by the contract owner.
    * @notice Before calling this function, ensure that the contract balance is greater than zero.
    */
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Contract balance must be greater than zero.");
        address payable owner = payable(msg.sender);
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Withdrawal failed.");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IXAPRegistrar).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
    * @dev Converts USD to Wei. 
    * @param amount The amount of USD to be converted to Wei.
    * @return The amount of Wei.
    */
    function usdToWei(uint256 amount) internal view returns (uint256) {
        uint256 ethPrice = uint256(usdOracle.latestAnswer());
        return (amount * 1e8) / ethPrice;
    }

    /**
    * @dev The function checks and then burns a commitment hash.
    * @param commitment The commitment hash to be checked and then burned.
    */

    function _burnCommitment(
        bytes32 commitment
    ) internal {
        // Require an old enough commitment.
        if (commitments[commitment] + minCommitmentAge > block.timestamp) {
            revert CommitmentTooNew(commitment);
        }

        // If the commitment is too old 
        if (commitments[commitment] + maxCommitmentAge <= block.timestamp) {
            revert CommitmentTooOld(commitment);
        }

        delete (commitments[commitment]);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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