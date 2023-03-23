// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface ITwistedTrippies 
{
    function mint(address to, uint256 tokenId) external;    
}

interface ITrippies
{
    function ownerOf(uint256 tokenId) external returns(address);
}

interface ITwistedBrew
{
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns(address);
}

contract Drink is Ownable
{
    using Counters for Counters.Counter;
    address public twistedTrippiesContractAddress = address(0);
    address public twistedBrewContractAddress = address(0);
    address public signerAddress = 0xd58aB967B405A8f7B5196727D565B1F9b8f5A5b9;
    address public trippiesContractAddress = 0x4cA4d3B5B01207FfCe9beA2Db9857d4804Aa89F3;
    ITrippies trippiesContract = ITrippies(trippiesContractAddress);
    Counters.Counter private titanIdCounter;

    constructor()  
    {        
        titanIdCounter.increment();
    }

    function setTwistedTrippiesContract(address a) public onlyOwner 
    {
        twistedTrippiesContractAddress = a;
    }

    function setBrewContract(address a) public onlyOwner 
    {
        twistedBrewContractAddress = a;
    }

    function setSignerAddress(address a) public onlyOwner 
    {
        signerAddress = a;
    }

    function drink(uint256 brewTokenId, uint256 trippieTokenId, bytes memory sig) public
    {
        ITwistedBrew brewContract = ITwistedBrew(twistedBrewContractAddress);
        ITwistedTrippies twistedContract = ITwistedTrippies(twistedTrippiesContractAddress);

        address ownerOfBrew = brewContract.ownerOf(brewTokenId);
        require(ownerOfBrew == msg.sender, "does not own brew");

        address ownerOfTrippie = trippiesContract.ownerOf(trippieTokenId);
        require(ownerOfTrippie == msg.sender, "does not own trippie");

        address messageSigner = VerifyMessage2(sig, brewTokenId, trippieTokenId);
        require(messageSigner == signerAddress, "Invalid message signer");

        brewContract.burn(brewTokenId);
        twistedContract.mint(msg.sender, trippieTokenId);
    }

    function drinkTitanBrew(uint256 brewTokenId, bytes memory sig) public
    {
        uint256 titanId = titanIdCounter.current() + 10000;
        require(titanId >= 10001 && titanId <= 10021);

        ITwistedBrew brewContract = ITwistedBrew(twistedBrewContractAddress);
        ITwistedTrippies twistedContract = ITwistedTrippies(twistedTrippiesContractAddress);

        address ownerOfBrew = brewContract.ownerOf(brewTokenId);
        require(ownerOfBrew == msg.sender, "does not own brew");

        address messageSigner = VerifyTitanMessage(sig, brewTokenId);
        require(messageSigner == signerAddress, "Invalid message signer");

        titanIdCounter.increment();
        brewContract.burn(brewTokenId);
        twistedContract.mint(msg.sender, titanId);
    }

    function VerifyTitanMessage(bytes memory sig, uint brewTokenId) private pure returns (address) 
    {
        (uint8 _v, bytes32 _r, bytes32 _s) = splitSignature(sig);
        bytes32 messageHash = keccak256(abi.encodePacked(brewTokenId));
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";         
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, messageHash));    
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    function VerifyMessage2(bytes memory sig, uint brewTokenId, uint trippieTokenId) private pure returns (address) 
    {
        (uint8 _v, bytes32 _r, bytes32 _s) = splitSignature(sig);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, getMessageHash2(brewTokenId, trippieTokenId)));    
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    function VerifyMessage(bytes memory sig, string memory msg1, uint amount, uint nonce) private pure returns (address) 
    {
        (uint8 _v, bytes32 _r, bytes32 _s) = splitSignature(sig);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, getMessageHash(msg1, amount, nonce)));    
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    function splitSignature(bytes memory sig) private pure returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65, "invalid sig");
        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }    

    function getMessageHash(string memory message, uint256 amount, uint256 nonce) private pure returns (bytes32) 
    {
        return keccak256(abi.encodePacked(message,amount,nonce)); 
    }   

    function getMessageHash2(uint256 amount, uint256 nonce) private pure returns (bytes32) 
    {
        return keccak256(abi.encodePacked(amount,nonce)); 
    } 

    function withdraw() public onlyOwner 
    {   
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }  
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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