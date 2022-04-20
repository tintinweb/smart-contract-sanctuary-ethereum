// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Tema {
    function mint() external;
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract minter{

    address owner;
    address myContract;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function setContract(address _contract) public{
        myContract = _contract;
    }

    function getContract() public view returns(address) {
        return(myContract);
    }

    function getOwner() public view returns(address) {
        return(owner);
    }

    function multiMint(uint8 txCount) external{
        for (uint i = 0; i < txCount; i++){
            Tema(myContract).mint();
        }
    }

    function withdrawNft(uint[] calldata tokenIds) external{
        for (uint i = 0; i < tokenIds.length; i++){
            Tema(myContract).transferFrom(address(this), owner, tokenIds[i]);
        }
    }


    constructor() {
        owner = msg.sender;
    }
}