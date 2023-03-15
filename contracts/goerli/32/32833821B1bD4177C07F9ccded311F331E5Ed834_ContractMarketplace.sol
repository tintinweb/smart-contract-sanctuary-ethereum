pragma solidity ^0.8.0;

contract ContractMarketplace {
    address payable public marketplaceOwner;
    uint256 public listingFeePercentage = 5;

    struct ContractListing {
        address payable creator;
        string description;
        bytes contractBytecode;
        bytes constructorArguments;
        uint256 fee;
    }

    mapping(uint256 => ContractListing) public listings;
    uint256 public nextListingId;

    event ContractListed(uint256 listingId, string description, uint256 fee);
    event ContractDeployed(uint256 listingId, address buyer, address deployedContract);

    constructor() {
        marketplaceOwner = payable(msg.sender);
    }

    function listContract(string memory description, bytes memory contractBytecode, bytes memory constructorArguments, uint256 fee) public {
        uint256 listingId = nextListingId++;
        ContractListing storage listing = listings[listingId];
        listing.creator = payable(msg.sender);
        listing.description = description;
        listing.contractBytecode = contractBytecode;
        listing.constructorArguments = constructorArguments;
        listing.fee = fee;

        emit ContractListed(listingId, description, fee);
    }

    function deployContract(uint256 listingId) public payable {
        ContractListing storage listing = listings[listingId];
        require(listing.creator != address(0), "Contract listing does not exist.");

        uint256 marketplaceFee = (listing.fee * listingFeePercentage) / 100;
        uint256 creatorFee = listing.fee - marketplaceFee;

        require(msg.value == listing.fee, "Insufficient payment.");

        (bool paymentSuccess, ) = marketplaceOwner.call{value: marketplaceFee }("");
        require(paymentSuccess, "Artist fee payment failed.");

        (paymentSuccess, ) = listing.creator.call{value: creatorFee}("");
        require(paymentSuccess, "Seller payment failed.");

        (bool success, address deployedContract) = _deployContract(listing.contractBytecode, listing.constructorArguments);
        require(success, "Contract deployment failed.");

        emit ContractDeployed(listingId, msg.sender, deployedContract);
    }

    function _deployContract(bytes memory contractBytecode, bytes memory constructorArguments) internal returns (bool, address) {
        address deployedContract;
        bytes memory deploymentBytecode = abi.encodePacked(contractBytecode, constructorArguments);
        assembly {
            deployedContract := create(0, add(deploymentBytecode, 0x20), mload(deploymentBytecode))
        }
        return (deployedContract != address(0), deployedContract);
    }
}