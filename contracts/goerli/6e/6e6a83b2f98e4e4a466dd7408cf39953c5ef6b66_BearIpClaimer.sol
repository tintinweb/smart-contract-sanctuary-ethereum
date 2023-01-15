// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./interface/IBearIpClaim.sol";

contract BearIpClaimer{
    IBearIpClaim protocol;
    constructor(address _protocol){
      protocol = IBearIpClaim(_protocol);
    }


   event BulkClaimEth(uint256 _amount);
    function BulkClaimETH(bytes32[] memory boxesId)
        public
        payable
        returns (uint256 amount)
    {}

    
    event ClaimNft(address received_address,
    address nft_address, 
    uint256 id, 
    uint256 amount);
    function BulkClaimNft(bytes32[] memory boxesId)
        public
        payable
        returns (address[] memory nfts, uint256[] memory ids, uint256[] memory amounts)
    {}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IBearIpClaim{
    function claimETH(bytes32 box_id)
        external
        payable
        returns (uint256  amount);
  
    function ClaimNft(bytes32 box_id)
        external
        payable
        returns ( address[] memory nfts, uint256[] memory ids, uint256[] memory amounts);

}