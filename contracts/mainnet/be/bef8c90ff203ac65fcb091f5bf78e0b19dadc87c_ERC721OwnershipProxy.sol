/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

                    
////////////////////////////////////////////////////////////////////////////////////////////////                                                                    
//   _____ _ _ _ _____ _____ _____ _____ _____ _____ _____    _____ _____ _____ __ __ __ __   //
//  |     | | | |   | |   __| __  |   __|  |  |     |  _  |  |  _  | __  |     |  |  |  |  |  //
//  |  |  | | | | | | |   __|    -|__   |     |-   -|   __|  |   __|    -|  |  |-   -|_   _|  //
//  |_____|_____|_|___|_____|__|__|_____|__|__|_____|__|     |__|  |__|__|_____|__|__| |_|    //
//  By: 0xInuarashi.eth | twitter.com/0xinuarashi | 0xInuarashi#1234                          //
////////////////////////////////////////////////////////////////////////////////////////////////                                       
                                                                             
/*
    This is a factory contract that allows production of ERC721OwnershipProxy contracts.

    What it is:

        ERC721OwnershipProxy is a delegatable ownership prover that allows users to 
        verify ownership of assets in hardware wallets using a delegation method to
        enable the verifying in a software wallet instead. 

        This is purely for security and/or ease-of-mind applications for verification
        methods that may require a signature or transaction which you do not want to 
        do on your hardware wallet for any reason.

    To create:

        Call the function createERC721OwnershipProxy(address address_) using address 
        as the ERC721 contract that you would like to create a delegation proxy for.

        After that, your contract will be created. To figure out the address of the
        created contract, you can check the transaction -> internal transactions
        on etherscan to find the contract being created.

        In order to verify the source code, copy paste interface IERC721{} and
        contract ERC721OwnershipProxy{} (do not need to copy paste ownershipProxyFactory)
        and then add in ABI-Encoded constructor arguments. Hooray! You have verified the
        source code of your factory-made ERC721OwnershipProxy.

    To use:

        This contract is meant to be used with NFT verification services such as 
        Collab.Land (discord) for channel access or something similar. 

        All it does is enable you to verify your assets using a delegation from your
        hardware wallet to your software wallet.

        Add the ERC721OwnershipProxy contract address in the same way you would add
        an NFT. 

        Verify with bot or verification service. If done correct, it should work!

        Also note that Collab.Land sometimes has black-box mechanics and will not
        be able to verify using something like this in some unannounced patches 
        (as it had happened in the past). However, it is working as tested on
        2022-04-20.

    Made with love by: 0xInuarashi
*/

interface IERC721 {
    function ownerOf(uint256 tokenId_) external view returns (address);
    function balanceOf(address address_) external view returns (uint256);
}

contract ERC721OwnershipProxy {
    // Address Based Global Proxy

    address public tokenContract;
    constructor(address contract_) { tokenContract = contract_; }
    IERC721 public Token = IERC721(tokenContract);

    mapping(address => address) internal hwToSw;
    mapping(address => address) internal swToHw;

    function linkSwToHw(address sw_) external {
        // First, clear the past record
        address _previousLink = hwToSw[msg.sender];
        
        if (_previousLink != address(0)) {
            swToHw[_previousLink] = address(0);
        }

        // Next, set the new data;
        hwToSw[msg.sender] = sw_;
        swToHw[sw_] = msg.sender;
    }

    function ownerOf(uint256 tokenId_) external view returns (address) {
        return hwToSw[Token.ownerOf(tokenId_)] == address(0) ?
            Token.ownerOf(tokenId_) :
            hwToSw[Token.ownerOf(tokenId_)];
    }

    function balanceOf(address address_) external view returns (uint256) {
        return swToHw[address_] == address(0) ?
            Token.balanceOf(address_) :
            Token.balanceOf(swToHw[address_]);
    }
}