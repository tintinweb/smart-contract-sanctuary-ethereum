//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../interfaces/IERC721Royalty.sol";


contract RoyaltyImplementationV1 is IERC721Royalty{

    /// @inheritdoc IERC721Royalty
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external pure returns (address, uint256){
        // Recipient is an (hardware) EOA for now to simplify launching to multiple chains
        // In the future we could upgrade this contract to either send to a multisig or pay out the fees to users/holders
        // Royalty is initially set at 2.5%
        return (
            0x708e98e80F2C6Ae2EC28378F0d58C5Cf240a0066,
            _salePrice * 25 / 1000
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


interface IERC721Royalty {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256);
}