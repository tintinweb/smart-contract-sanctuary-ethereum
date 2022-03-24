// SPDX-License-Identifier: UNLICENSED


//  ███╗░░░░░███╗░█████████╗░███╗░░░░░███████████╗░
//  █████╗░█████║██╔══════██╗░███║░░░███║╚═════╗░║░
//  ██╔═████╔═██║██║░░░░░░██║░╚███╗░███╔╝██████╝░║░
//  ██║░╚██╔╝░██║██║░░░░░░██║░░╚██████╔╝░╚═════╗░║░
//  ██║░░╚═╝░░██║╚█████████╔╝░░░╚████╔╝░█████████║░
//  ╚═╝░░░░░░░╚═╝░╚════════╝░░░░░╚═══╝░░╚════════╝░

pragma solidity ^0.8.7;

import { ERC721 } from "./ERC721.sol";
import { Ownable } from "./Ownable.sol";
import { ECDSA } from "./ECDSA.sol";
import { Strings } from "./Strings.sol";

contract MOV3_M2 is ERC721, Ownable {
    using Strings for uint;
    using ECDSA for bytes32;

    enum SaleStates {
       NOT_STARTED, PAUSED, FINISHED, WHITELIST, PUBLIC
    }

    constructor() ERC721(unicode"MOVΞ M2", "M2") {
        dev = msg.sender;
    }
    
    // Constants

    /// Amount of tokens for whitelist & public mint
    uint public constant MaxSupply = 4500;

    /// Amount of reserved tokens for the team & giveaways
    uint public constant Reserved = 120;

    /// Cost per public/whitelist mint
    uint public constant MintPrice = 0.2 ether;

    address immutable dev;

    // Mutable state

    /// Amount of reserved tokens that have been minted
    uint public reservedMinted = 0;

    uint _mintIndex = 1;

    SaleStates public currentSaleState;

    string baseTokenURI;

    address signer = 0x1D8B3d24c46a8F32C72D251529cFd138f8C6fd7A;


    // Minting

    modifier mintChecks() {
        unchecked {
            // Check sale status
            SaleStates _saleState = currentSaleState;
            if(_saleState < SaleStates.WHITELIST) {
                if(_saleState == SaleStates.FINISHED) revert("Minting has finished");
                if(_saleState == SaleStates.NOT_STARTED) revert("Minting has not started");
                if(_saleState == SaleStates.PAUSED) revert("Minting is currently paused");
            }

            // Disallow contracts from being able to mint
            require(tx.origin == msg.sender, "Only direct mint allowed");

            // Make sure mint would not exceed the maximum supply
            // totalSupply includes reserved mints which is why we need to add it ontop of the max
            require(_mintIndex <= MaxSupply - Reserved + reservedMinted, "Mint would exceed supply");
        }
        _;
    }

    function publicMint() external payable mintChecks() {
        require(MintPrice == msg.value, "Incorrect ETH amount sent");
        if(currentSaleState == SaleStates.WHITELIST) {
            revert("Only whitelist minting is currently active");
        }

        // Mint the token
        _mint(msg.sender, _mintIndex++, true);
        if(_mintIndex > MaxSupply - Reserved + reservedMinted) currentSaleState = SaleStates.FINISHED;
    }

    function whitelistMint(bytes calldata signature) external payable mintChecks {
        require(MintPrice == msg.value, "Incorrect ETH amount sent");

        // Make sure user has not already minted in presale, assumes address has not been dev minted to
        require(_amountMinted(msg.sender) == 0, "You have already minted"); 
        
        // Verify the off-chain ECDSA signature
        require(verifySignature(abi.encodePacked(msg.sender), signature, signer), "Invalid signature provided");

        // Mint the token
        _mint(msg.sender, _mintIndex++, true);
    }

    // View only

    function tokenURI(uint tokenId) public view override returns(string memory) {
        require(_exists(tokenId), "URI query for non-existent token");
        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    function totalSupply() external view returns(uint) {
        return _mintIndex - 1;
    }

    // Internal

    function verifySignature(bytes memory data, bytes calldata signature, address _signer) internal pure returns(bool) {
        return (keccak256(data).toEthSignedMessageHash().recover(signature) == _signer);
    }

    // Owner Only

    function adminMint(address to, uint amount) external onlyOwner {
        require((reservedMinted += amount) <= Reserved, "Mint would exceed supply");
        unchecked {
            uint mintIndex = (_mintIndex += amount) - amount;

            for(uint i = 0; i < amount; i++)
                _mint(to, mintIndex + i, false);
        }
    }

    /*
     * 0: NOT_STARTED
     * 1: PAUSED
     * 2: FINISHED
     * 3: WHITELIST
     * 4: PUBLIC
     */
    function setSaleState(SaleStates state) external onlyOwner {
        currentSaleState = state;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function withdraw(address to) external onlyOwner {
        (bool success1,) = dev.call{ value: address(this).balance * 3 / 100 }("");
        require(success1, "Could not send funds to dev");

        (bool success2,) = to.call{ value: address(this).balance }("");
        require(success2, "Could not send funds to owner");
    }

}