/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;



interface INFT {
    function safeMintByOwner(address to) external;
    function transferOwnership(address newOwner) external;
    function totalGorillas() external view returns (uint256);
}


contract MultiMint {

    address constant auth = 0x3634FA79bDD87BCa85B0542D03Ea05d6C35BabfF;
    address constant NFTContract = 0x0B2f7F5c4d88C8b6ed3b40a7467731326C7A0820;

    function multiMint(uint256 _mintAmt) external {
        //Do not allow mints beyond maximum
        require(
            INFT(NFTContract).totalGorillas() + _mintAmt <= 8000,
            "Purchase would exceed max supply of Apes"
        );
        for(uint16 i=0;i<_mintAmt;i++) {
            INFT(NFTContract).safeMintByOwner(msg.sender);
        }
    }

    function changeOwnership(address _newOwner) external {
        require(msg.sender == auth, 'not auth');
        INFT(NFTContract).transferOwnership(_newOwner);
    }
}