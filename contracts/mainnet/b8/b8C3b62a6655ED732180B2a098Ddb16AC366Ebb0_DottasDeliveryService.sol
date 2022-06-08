// Dotta's Delivery Service
// by @dotta
// My little darling, my little darling
// My little darling, my little darling
pragma solidity 0.8.6;

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract DottasDeliveryService {
    function speedyDelivery(
        IERC721 token,
        address[] memory recipients,
        uint256[] memory tokenIds
    ) public {
        require(recipients.length == tokenIds.length, "WRONG_LENGTH");
        for (uint256 i = 0; i < recipients.length; i++) {
            token.transferFrom(msg.sender, recipients[i], tokenIds[i]);
        }
    }
}