// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "contracts/interfaces/IReceipt.sol";

library NFTDescriptor {
    struct Receipt {
        uint256 amount;
        uint96 timestamp;
        address token;
        uint96 nonce;
        address payer;
        address recipient;
        string payerName;
        string recipientName;
    }

    function constructTokenURI(Receipt calldata receipt)
        external
        view
        returns (string memory)
    {
        return "123";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IReceipt {
    struct Receipt {
        uint256 amount;
        uint96 timestamp;
        address token;
        uint96 nonce;
        address payer;
        address recipient;
        string payerName;
        string recipientName;
    }

    event Payed(
        address payer,
        address recipient,
        uint256 amount,
        uint256 recipientReceived,
        address token,
        uint256 receiptId,
        uint256 tokenId
    );
}