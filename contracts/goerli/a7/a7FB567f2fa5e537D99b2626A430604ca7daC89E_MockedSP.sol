// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MockedSP {
    struct Ticket {
        uint256 tokenID;
        address serviceProvider; // the index to the map where we keep info about serviceProviders
        uint32 serviceDescriptor;
        address issuedTo;
        uint256 certValue;
        uint256 certValidFrom; // value can be redeemedn after this time
        uint256 price;
        uint256 credits; // [7]
        uint256 pricePerCredit;
        uint256 serviceFee;
        uint256 resellerFee;
        uint256 transactionFee;
        string tokenURI;
    }

    struct Coordinates {
        string latitude;
        string longitude;
    }

    struct TopUpPayload {
        uint256 orderId;
        uint256 cardId;
        address erc20TokenList;
        uint256 erc20PaidAmountList;
        uint256 creditsAdd;
    }

    address ENGN = 0x3f940AeFB81709bc63C7f64Ec3dF4D90CCBe3446;
    address MUSDC = 0x20ec4b6b086BEC4CF9966B618CAa860ef9883053;
    address MBLXM = 0xCb53faF97E4a383919e4bc2b0F0B006fF4c74c73;

    mapping(uint256 => TopUpPayload) public topUpPayloads;
    mapping(uint256 => bytes) public sigs;
    mapping(uint256 => bytes32) public digests;

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
                payload.erc20TokenList,
                payload.erc20PaidAmountList,
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

    function presentTransportCard(uint256 cardId, address presenter)
        external
        returns (uint256 providerRevenue)
    {
        providerRevenue = 1 * 10**decimals();
    }

    function checkIn(
        uint256 cardId,
        Coordinates calldata coordinates,
        bytes calldata signature
    ) external {}

    function endService(
        uint256 cardId,
        uint256 reducedCredits,
        address driver
    ) external returns (uint256 providerRevenue, uint256 driverRevenue) {
        providerRevenue = 1 * 10**decimals();
        driverRevenue = 1 * 10**decimals();
    }

    function cancelPresent(
        uint256 cardId,
        address presenter,
        uint256 reducedCredits
    ) external returns (uint256 providerRevenue) {
        providerRevenue = 1 * 10**decimals();
    }

    function getTransportCard(uint256 cardId)
        public
        view
        returns (Ticket memory nftcard)
    {
        nftcard = Ticket(
            1,
            msg.sender,
            1,
            msg.sender,
            1,
            1,
            1 * 10**decimals(),
            1 * 10**decimals(),
            1 * 10**decimals(),
            1 * 10**decimals(),
            1 * 10**decimals(),
            1 * 10**decimals(),
            "http://test.com/"
        );
    }

    function getApprovedOfNFTicket(uint256 cardId)
        public
        view
        returns (address)
    {
        return msg.sender;
    }
}