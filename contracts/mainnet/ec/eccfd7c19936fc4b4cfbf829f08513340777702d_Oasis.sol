// SPDX-License-Identifier: GPL-3.0

/** @title The Wild Oasis ERC-721 token
* @dev This contract is for the Oasis project by Wildxyz
*/

// LICENSE
// Oasis.sol is a modified version of the original code from the
// NounsToken.sol— an implementation of OpenZeppelin's ERC-721:
// https://github.com/nounsDAO/nouns-monorepo/blob/master/packages/nouns-contracts/contracts/NounsToken.sol 
// The original code is licensed under the GPL-3.0 license
// Thank you to the Nouns team for the inspiration and code!


pragma solidity ^0.8.6;

import { Ownable } from './Ownable.sol';
import { ERC721 } from './ERC721.sol';
import { IERC721 } from './IERC721.sol';
import { Strings } from './Strings.sol';
import { ERC721Checkpointable } from './ERC721Checkpointable.sol';
import { IOasis } from './IOasis.sol';

contract Oasis is IOasis, Ownable, ERC721Checkpointable {
    // An address who has permissions to mint Oasis tokens
    address public minter;

    // The internal Oasis ID tracker
    uint256 public _currentTokenId;

    // URI
    string public baseURI = "";

    // Mapping of operators to whether they are approved or not
    mapping(address => bool) public authorized;

    // Mapping of addresses flagged for denying token interactions
    mapping(address => bool) public blockList;

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, "Sender is not the minter");
        _;
    }

    constructor(address _minter) ERC721("Oasis", "OP") {
        minter = _minter;
    }

    /**
     * @notice updates the deny list
     * @param flaggedOperator the address to be added to the deny list
     * @param status whether the address is to be added or removed from the deny list
     */
    function updateDenyList(address flaggedOperator, bool status) public onlyOwner {
        _updateDenyList(flaggedOperator, status);
    }

    /**
     * @notice Override isApprovedForAll
     * @param owner The owner of the Nouns
     * @param operator The operator to check if approved
     */
    function isApprovedForAll(address owner, address operator) public view override(IERC721, ERC721) returns (bool) {
        
        require(blockList[operator] == false, "Operator has been denied by contract owner."); 

        if (authorized[operator] == true) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @notice sets the authorized operators for interacting with the contract
     * @param operator the address to be added to the authorized operators
     * @param approved whether the address is approved or not within authorized operators
     */
    function setAuthorized(address operator, bool approved) public onlyOwner {
        authorized[operator] = approved;
    }
    
    /**
     * @notice Mint an Oasis token to the given address.
     * @dev Only callable by the minter.
     * @param _to The address to mint the Oasis token to.
     * @return The ID of the newly minted Oasis token.
     */
    function mint(address _to) public onlyMinter override returns (uint256) {
        return _mintTo(_to, _currentTokenId++);
    }

    /**
     * @notice Mint an Oasis token to the given address.
     * @dev Only callable by the minter.
     * @param to The address to mint the Oasis token to.
     * @param quantity The number of tokens to mint.
     * @return The ID of the newly minted Oasis token.
     */
    function promoMint(address to, uint256 quantity)
        public
        onlyMinter
        override 
        returns (uint256)
    {
        uint256 tokenId = _currentTokenId;
        for (uint256 i = 0; i < quantity; i++) {
            _mintTo(to, tokenId++);
        }
        _currentTokenId = tokenId;
        return tokenId;
    }

    /**
     * @notice Burn a pass.
     * @dev Only callable by the minter.
     * @param tokenId The ID of the Oasis token to burn.
     */
    function burn(uint256 tokenId) public onlyMinter override {
        _burn(tokenId);
        emit TokenBurned(tokenId);
    }

    /** @notice Provides the tokenURI of a specific token
     * @param _tokenId: the token ID
     * @return the URI of the token
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
            require(_exists(_tokenId), "Token does not exist.");
            return
                string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(_tokenId),
                        ".json"
                    )
                );
        }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     * @param _minter The address of the new minter.
     */
    function setMinter(address _minter) external onlyOwner override {
        minter = _minter;
        //emit MinterUpdated(_minter);
    }

    

    /**
     * @notice Set the base URI.
     * @dev Only callable by the owner.
     * @param _newBaseURI The new base URI.
    */
    function setBaseURI(string memory _newBaseURI) public onlyOwner override {
        baseURI = _newBaseURI;
    }


    //////////////////////////
    // Internal Functions ////
    //////////////////////////

    /**
     * @notice updates the deny list
     * @param flaggedOperator The address to be approved.
     * @param status True if the operator is approved, false to revoke approval.
     */
    function _updateDenyList(address flaggedOperator, bool status) internal virtual {
        blockList[flaggedOperator] = status;
        //emit OperatorFlagged(flaggedOperator, status);
    }

    /** @notice Mints a new token
     * @param to: the address of the new owner looking to mint
     * @param tokenId: the token ID
     * @return the ID of the newly minted token
     */
    function _mintTo(address to, uint256 tokenId) internal returns (uint256) {
        _mint(to, tokenId);
        emit TokenCreated(tokenId);

        return tokenId;
    }

}