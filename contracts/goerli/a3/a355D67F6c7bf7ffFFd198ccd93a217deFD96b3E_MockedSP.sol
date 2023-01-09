/**
 *Submitted for verification at Etherscan.io on 2023-01-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MockedSP {
    struct TopUpPayload {
        uint256 orderId;
        uint256 cardId;
        address erc20Token;
        uint256 erc20PaidAmount;
        uint256 creditsAdd;
    }

    struct IssueTransportCardPayload {
        string uuid;
        uint32  serviceDescriptor;
        address recipient;
        uint256 credits;
        uint256 erc20IncomeAmount;
        address erc20IncomeToken;
        uint256 serviceRevenuePermille;
        uint256 resellerRevenuePermille;
        string tokenURI;
    }

    event IssueTransportCard(uint256 indexed cardId, address indexed recipient, string tokenURI);

    address ENGN = 0x3f940AeFB81709bc63C7f64Ec3dF4D90CCBe3446;
    address MUSDC = 0x20ec4b6b086BEC4CF9966B618CAa860ef9883053;
    address MBLXM = 0xCb53faF97E4a383919e4bc2b0F0B006fF4c74c73;

    mapping(uint256 => TopUpPayload) public topUpPayloads;
    mapping(uint256 => bytes) public sigs;
    mapping(uint256 => bytes32) public digests;

    uint256 public cardId;

    constructor() {}

    function decimals() public pure returns (uint256) {
        return 18;
    }

    function topUp(
        TopUpPayload calldata payload,
        bytes calldata signatureFromMTP
    ) external returns (bool) {
        topUpPayloads[payload.orderId] = payload;
        sigs[payload.orderId] = signatureFromMTP;

        bytes32 digest = keccak256(
            abi.encodePacked(
                payload.orderId,
                payload.cardId,
                payload.erc20Token,
                payload.erc20PaidAmount,
                payload.creditsAdd
            )
        );
        digests[payload.orderId] = digest;
        return true;
    }

    function getPPCofSP(address erc20Token)
        public
        view
        returns (uint256 pricePerCredit)
    {
        if (erc20Token == MBLXM) {
            return 100 * 10**decimals();
        } else if (erc20Token == MUSDC) {
            return 1 * 10**(decimals() - 2);
        } else if (erc20Token == ENGN) {
            return 1 * 10**decimals();
        }
        return 0;
    }

    function issueTransportCard(IssueTransportCardPayload calldata payload) 
        external
        returns (uint256)
    {
        cardId ++;
        emit IssueTransportCard(cardId, payload.recipient, payload.tokenURI);
        return cardId;
    }
    
    function getTransportCardIdByUUID(string calldata uuid) 
        public 
        view 
        returns (uint256) 
    {
        require(bytes(uuid).length > 0, 'uuid should not be empty');
        return cardId;
    }
}