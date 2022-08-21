/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

pragma solidity ^0.7.5;
pragma experimental ABIEncoderV2;

contract ENSCommitment {
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
    struct RegistrationWithConfig {
        string name;
        address owner;
    }
}

interface ENSController {
    event NameRegistered(
        string name,
        bytes32 indexed label,
        address indexed owner,
        uint256 cost,
        uint256 expires
    );
    event NameRenewed(
        string name,
        bytes32 indexed label,
        uint256 cost,
        uint256 expires
    );
    event NewPriceOracle(address indexed oracle);

    function rentPrice(string memory name, uint256 duration)
        external
        view
        returns (uint256);

    function valid(string memory name) external pure returns (bool);

    function available(string memory name) external view returns (bool);

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

    function renew(string calldata name, uint256 duration) external payable;
}

interface ENS {
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);
    event Transfer(bytes32 indexed node, address owner);
    event NewResolver(bytes32 indexed node, address resolver);
    event NewTTL(bytes32 indexed node, uint64 ttl);
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external returns (bytes32);

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address owner) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function setApprovalForAll(address operator, bool approved) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function ttl(bytes32 node) external view returns (uint64);

    function recordExists(bytes32 node) external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

contract BulkRegister {
    address payable deployer;
    ENSController ensRegistrarController =
        ENSController(0x283Af0B28c62C092C9727F1Ee09c02CA627EB7F5);

    event error(bytes errorInfo);

    receive() external payable {}

    modifier onlyDeployer() {
        require(deployer == msg.sender, "Not deployer.");
        _;
    }

    constructor() {
        deployer = msg.sender;
    }

    function recoverStuckETH() public onlyDeployer {
        deployer.transfer(address(this).balance);
    }

    function createCommitmentsForRegistration(
        ENSCommitment.Commitment[] memory commitments,
        uint256 duration,
        bool withConfigs
    ) public view returns (bytes32[] memory, uint256[] memory) {
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
        uint256[] memory pricesRange = new uint256[](3);
        string[3] memory pricesRangeMatch = ["123", "1234", "12345"];
        for (uint8 i = 0; i < 3; i++) {
            uint256 priceMeasured = ensRegistrarController.rentPrice(
                pricesRangeMatch[i],
                duration
            );
            pricesRange[i] = priceMeasured;
        }
        return (createdCommitments, pricesRange);
    }

    function requestRegistration(bytes32[] memory commitments) public {
        for (uint8 i = 0; i < commitments.length; i++) {
            ensRegistrarController.commit(commitments[i]);
        }
    }

    function completeRegistration(
        string[] memory names,
        uint256[] memory priceRanges,
        uint256[] memory nameLengths,
        address owner,
        uint256 duration,
        bytes32 secret
    ) public payable {
        uint256 totalPrice;
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
            msg.sender.transfer(msg.value - totalPrice);
        }
    }

    function completeRegistrationWithConfigs(
        string[] memory names,
        uint256[] memory priceRanges,
        uint256[] memory nameLengths,
        uint256 duration,
        bytes32 secret,
        address resolver,
        address owner
    ) public payable {
        uint256 totalPrice;
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
            msg.sender.transfer(msg.value - totalPrice);
        }
    }
}