/**
 *Submitted for verification at Etherscan.io on 2023-01-08
*/

pragma solidity ^0.8.17;

interface ERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface ENSController {
    function makeCommitment(
        string memory name,
        address owner,
        bytes32 secret
    ) external pure returns (bytes32);

    function makeCommitmentWithConfig(
        string memory name,
        address owner,
        bytes32 secret,
        address resolver,
        address addr
    ) external pure returns (bytes32);

    function commit(bytes32 commitment) external;

    function register(
        string calldata name,
        address owner,
        uint256 duration,
        bytes32 secret
    ) external payable;

    function registerWithConfig(
        string memory name,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        address addr
    ) external payable;

    function rentPrice(string memory name, uint256 duration)
        external
        view
        returns (uint256);

    function renew(string calldata name, uint256 duration) external payable;
}

contract PredomainHelper {
    bool private rentryGuardActive = false;
    ENSController private ensRegistrarController =
        ENSController(0x283Af0B28c62C092C9727F1Ee09c02CA627EB7F5);
    ERC721 private ensToken =
        ERC721(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85);

    struct Commitment {
        string name;
        address owner;
        uint256 duration;
        bytes32 secret;
        address resolver;
        bytes[] data;
        bool reverseRecord;
        uint32 fuses;
        uint64 wrapperExpiry;
    }

    receive() external payable {}

    event error(bytes errorInfo);

    modifier noReentry() {
        require(rentryGuardActive == false);
        rentryGuardActive = true;
        _;
        rentryGuardActive = false;
    }

    function transferDomains(address to, uint256[] memory domains)
        public
        noReentry
    {
        for (uint8 i = 0; i < domains.length; i++) {
            uint256 tokenId = domains[i];
            require(ensToken.ownerOf(tokenId) == msg.sender);
            ensToken.safeTransferFrom(msg.sender, to, tokenId);
        }
    }

    function createCommitmentsForRegistration(
        Commitment[] memory commitments,
        uint256[] memory nameLengths,
        uint256 duration,
        bool withConfigs
    ) public view returns (bytes32[] memory, uint256[3] memory) {
        bytes32[] memory createdCommitments = new bytes32[](commitments.length);
        if (withConfigs == false) {
            for (uint8 i = 0; i < commitments.length; i++) {
                createdCommitments[i] = ensRegistrarController.makeCommitment(
                    commitments[i].name,
                    commitments[i].owner,
                    commitments[i].secret
                );
            }
        } else {
            for (uint8 i = 0; i < commitments.length; i++) {
                createdCommitments[i] = ensRegistrarController
                    .makeCommitmentWithConfig(
                        commitments[i].name,
                        commitments[i].owner,
                        commitments[i].secret,
                        commitments[i].resolver,
                        commitments[i].owner
                    );
            }
        }
        uint256[3] memory pricesRange = getPriceRanges(duration, nameLengths);
        return (createdCommitments, pricesRange);
    }

    function requestRegistration(bytes32[] memory commitments)
        public
        noReentry
    {
        for (uint8 i = 0; i < commitments.length; i++) {
            ensRegistrarController.commit(commitments[i]);
        }
    }

    function completeRegistration(
        string[] memory names,
        uint256[] memory nameLengths,
        address owner,
        uint256 duration,
        bytes32 secret
    ) public payable noReentry {
        uint256 totalPrice;
        uint256[3] memory priceRanges = getPriceRanges(duration, nameLengths);
        for (uint8 i = 0; i < names.length; i++) {
            uint256 price;
            uint256 nameLen = nameLengths[i];
            if (nameLen == 3) {
                price = priceRanges[0];
            } else if (nameLen == 4) {
                price = priceRanges[1];
            } else {
                price = priceRanges[2];
            }
            bool hasErrorOccured = false;
            try
                ensRegistrarController.register{value: price}(
                    names[i],
                    owner,
                    duration,
                    secret
                )
            {} catch (bytes memory info) {
                hasErrorOccured = true;
                emit error(info);
            }
            if (hasErrorOccured == false) {
                totalPrice += price;
            }
        }
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    function completeRegistrationWithConfigs(
        string[] memory names,
        uint256[] memory nameLengths,
        uint256 duration,
        bytes32 secret,
        address resolver,
        address owner
    ) public payable noReentry {
        uint256 totalPrice;
        uint256[3] memory priceRanges = getPriceRanges(duration, nameLengths);
        for (uint8 i = 0; i < names.length; i++) {
            uint256 price;
            uint256 nameLen = nameLengths[i];
            if (nameLen == 3) {
                price = priceRanges[0];
            } else if (nameLen == 4) {
                price = priceRanges[1];
            } else {
                price = priceRanges[2];
            }
            bool hasErrorOccured = false;
            try
                ensRegistrarController.registerWithConfig{value: price}(
                    names[i],
                    owner,
                    duration,
                    secret,
                    resolver,
                    owner
                )
            {} catch (bytes memory info) {
                hasErrorOccured = true;
                emit error(info);
            }
            if (hasErrorOccured == false) {
                totalPrice += price;
            }
        }
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    function renewDomains(
        string[] memory names,
        uint256[] memory nameLengths,
        uint256 duration
    ) public payable noReentry {
        uint256 totalPrice;
        uint256[3] memory priceRanges = getPriceRanges(duration, nameLengths);
        for (uint8 i = 0; i < names.length; i++) {
            uint256 price;
            uint256 nameLen = nameLengths[i];
            if (nameLen == 3) {
                price = priceRanges[0];
            } else if (nameLen == 4) {
                price = priceRanges[1];
            } else {
                price = priceRanges[2];
            }
            bool hasErrorOccured = false;
            try
                ensRegistrarController.renew{value: price}(names[i], duration)
            {} catch (bytes memory info) {
                hasErrorOccured = true;
            }
            if (hasErrorOccured == false) {
                totalPrice += price;
            }
        }
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    function getPriceRanges(uint256 duration, uint256[] memory nameLengths)
        public
        view
        returns (uint256[3] memory)
    {
        uint256[3] memory priceRanges = [uint256(0), uint256(0), uint256(0)];
        bool nameLenFound3 = false;
        bool nameLenFound4 = false;
        bool nameLenFound5 = false;
        string[3] memory pricesRangeMatch = ["123", "1234", "12345"];
        for (uint8 i = 0; i < nameLengths.length; i++) {
            if (
                nameLenFound3 == true &&
                nameLenFound4 == true &&
                nameLenFound5 == true
            ) {
                continue;
            }
            if (nameLengths[i] == 3 && nameLenFound3 == false) {
                nameLenFound3 = true;
            } else if (nameLengths[i] == 4 && nameLenFound4 == false) {
                nameLenFound4 = true;
            } else if (nameLengths[i] >= 5 && nameLenFound5 == false) {
                nameLenFound5 = true;
            }
        }
        if (nameLenFound3 == true) {
            uint256 priceMeasured = ensRegistrarController.rentPrice(
                pricesRangeMatch[0],
                duration
            );
            priceRanges[0] = priceMeasured;
        }
        if (nameLenFound4 == true) {
            uint256 priceMeasured = ensRegistrarController.rentPrice(
                pricesRangeMatch[1],
                duration
            );
            priceRanges[1] = priceMeasured;
        }
        if (nameLenFound5 == true) {
            uint256 priceMeasured = ensRegistrarController.rentPrice(
                pricesRangeMatch[2],
                duration
            );
            priceRanges[2] = priceMeasured;
        }
        return priceRanges;
    }
}