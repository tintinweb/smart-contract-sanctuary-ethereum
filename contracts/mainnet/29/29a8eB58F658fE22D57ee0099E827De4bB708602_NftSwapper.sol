// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ERC721Token {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address);
}

error SwapRejected(); //Error that happens when swap ended up with an error
error OnlyNftOwnersCanExecute(); //Only users who hold specific tokens are permitted to execute this function
error SwappedAlready(); //Happens when someone wants to execute the swap on the contract that already has been finished
error SwapCancelled(); // Happens when someone wants to execute the swap on the contract that has been cancelled

contract NftSwapper {
    address constant swapperSafe = payable(0x32d15a580F87D5dabCDF759cfdC4A6401e4488bc);
    ERC721Token public nft1Contract;
    ERC721Token public nft2Contract;

    uint256 public nft1Id;
    uint256 public nft2Id;

    uint256 timeCreated;
    uint256 public swapFee;

    bool initialized;
    bool public swapSucceeded;
    bool public swapCancelled;

    function create(
        address _nft1,
        uint256 _nft1Id,
        address _nft2,
        uint256 _nft2Id,
        uint256 _swapFee
    ) public {
        require(initialized == false, "Already initialized");
        initialized = true;
        nft1Contract = ERC721Token(_nft1);
        nft2Contract = ERC721Token(_nft2);

        nft1Id = _nft1Id;
        nft2Id = _nft2Id;

        timeCreated = block.timestamp;
        swapFee = _swapFee; 
    }

    function cancelSwap() public makerOrTaker {
        swapCancelled = true;
    }

    function getSwapperStatus() public view returns(address, uint256, address, uint256, bool, bool){
        return(address(nft1Contract), nft1Id, address(nft2Contract), nft2Id, swapSucceeded, swapCancelled);
    }   

    function swap() public payable makerOrTaker {
        if (swapSucceeded == true) revert SwappedAlready();
        if (swapCancelled == true) revert SwapCancelled();
        require (block.timestamp < timeCreated + 1 days, "The offer has expired");
        require (msg.value >= swapFee, "Fee too low.");
        address originalOwnerOfNft1 = nft1Contract.ownerOf(nft1Id);
        address originalOwnerOfNft2 = nft2Contract.ownerOf(nft2Id);

        nft1Contract.safeTransferFrom(
            originalOwnerOfNft1,
            originalOwnerOfNft2,
            nft1Id
        );
        nft2Contract.safeTransferFrom(
            originalOwnerOfNft2,
            originalOwnerOfNft1,
            nft2Id
        );

        if (
            !(nft1Contract.ownerOf(nft1Id) == originalOwnerOfNft2 &&
              nft2Contract.ownerOf(nft2Id) == originalOwnerOfNft1)
        ) revert SwapRejected();
        (bool sent, ) = swapperSafe.call{value: msg.value}("");
        require(sent, "Something went wrong with transferring fee");
        swapSucceeded = true;
    }

    modifier makerOrTaker() {
        address originalOwnerOfNft1 = nft1Contract.ownerOf(nft1Id);
        address originalOwnerOfNft2 = nft2Contract.ownerOf(nft2Id);

        if (
            msg.sender != originalOwnerOfNft1 &&
            msg.sender != originalOwnerOfNft2
        ) revert OnlyNftOwnersCanExecute();
        _;
    }
}