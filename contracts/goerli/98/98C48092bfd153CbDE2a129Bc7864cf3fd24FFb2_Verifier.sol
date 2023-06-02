/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT


interface INFA {
    function mintAsset(
        address to,
        string memory uri,
        uint256 tokenId,
        uint96 feeNumerator
    ) external;

    function transferAsset(address from, address to, uint256 tokenId) external;

    function changeFactory(address _factory) external;

    function acceptChangeFactory() external;

    function changeInitialSale(address _intialSale) external;

    function tokenURI(uint256 tokenId) external view;

    function supportsInterface(bytes4 interfaceId) external view;

    function checkAvailableId(uint256 _tokenId) external view returns (bool);

    function burnNFA(uint256 tokenId) external;

    function checkNfaOwner(uint256 tokenId) external view returns (address);
}


interface ISale {

    /// @notice Represents an un-minted NFA, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFA using the redeem function.
    struct NFAVoucher {
        /// @notice the NFA contract address
        INFA nfaContract;
        /// @notice The id of the token to be redeemed. Must be unique - if another token with this ID already exists, the redeem function will revert.
        uint256 tokenId;
        /// @notice the tokenOwner or creator of the NFA
        address tokenOwner;
        /// @notice The minimum price (in wei) that the NFA creator is willing to accept for the initial sale of this NFA.
        uint256 price;
        /// @notice private recipient used for private sales
        address privateRecipient;
        /// @notice The metadata URI to associate with this token.
        string uri;
        /// @notice the EIP-712 signature of all other fields in the NFAVoucher struct. For a voucher to be valid, it must be signed by the tokenOwner
        bytes signature;
    }

    function _verify(
        NFAVoucher calldata voucher
    ) external view returns (address);
}

contract Verifier {
    ISale initialSale = ISale(0x49f2954D7Da5E0cc8684cE4f004FBf6fF312b8bb);

        struct NFAVoucher {
        /// @notice the NFA contract address
        INFA nfaContract;
        /// @notice The id of the token to be redeemed. Must be unique - if another token with this ID already exists, the redeem function will revert.
        uint256 tokenId;
        /// @notice the tokenOwner or creator of the NFA
        address tokenOwner;
        /// @notice The minimum price (in wei) that the NFA creator is willing to accept for the initial sale of this NFA.
        uint256 price;
        /// @notice private recipient used for private sales
        address privateRecipient;
        /// @notice The metadata URI to associate with this token.
        string uri;
        /// @notice the EIP-712 signature of all other fields in the NFAVoucher struct. For a voucher to be valid, it must be signed by the tokenOwner
        bytes signature;
    }

    function  verify(NFAVoucher calldata _voucher) public {
        initialSale._verify(ISale.NFAVoucher(
                _voucher.nfaContract,
                _voucher.tokenId,
                _voucher.tokenOwner,
                _voucher.price,
                _voucher.privateRecipient,
                _voucher.uri,
                _voucher.signature
            ));
    }

}