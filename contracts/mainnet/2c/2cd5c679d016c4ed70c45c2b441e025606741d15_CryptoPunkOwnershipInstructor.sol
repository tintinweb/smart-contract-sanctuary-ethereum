/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

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

// File: contracts/CryptoPunkOwnershipInstructor.sol


interface ICryptoPunkContract {
    function punkIndexToAddress(uint256) external view returns (address);
}

/**
 * Ownership Instructor Wrapper that wraps around the Cryptopunk contract,
 * It tells us if _impl is the cryptopunk contract and let's us standardise ownerOf;
 *
 * The goal of this contract is to allow people to integrate their contract into OwnershipChecker.sol
 * by generalising the obtention of the owner of NFTs.
 * The reason for this solution was because NFTs nowadays have standards, but not all NFTs support these standards.
 */
contract CryptoPunkOwnershipInstructor is IERC165,IOwnershipInstructor{
    address immutable cryptopunk_impl = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    constructor(){
    }

/**
 * Checks if the given contract is the cryptopunk address
 * It should obtain an address as input and should return a boolean value;
 * @dev Contains a set of instructions to check the given _impl is the cryptopunk contract
 * @param _impl address we want to check.
 * @return bool
 * 
 */
    function isValidInterface (address _impl) public view override returns (bool){
        return _impl == cryptopunk_impl;
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
        return ICryptoPunkContract(_impl).punkIndexToAddress(_tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IOwnershipInstructor).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}