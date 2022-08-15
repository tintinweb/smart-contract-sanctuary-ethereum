// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Declare errors
error PriceNotMet(uint256 price);
error notContractOwner();
error hashNotMatch();
error haveNotGrantedAccess();
error hasRequested();
error notEnoughFund();
error accessGrantedAlready();

// smart contract
contract DigitalAssetContract {
    // Data type definition
    struct customerAssetData {
        bytes32 symmetricKey;
        bytes20 encryptedFileHash;
        string ipfsURI;
    }

    // State variables
    mapping(address => customerAssetData) private customerAddrToData;
    mapping(address => uint256) private userFund;
    mapping(address => uint256) private userFundWithdrawable;
    uint256 private ownerFund;
    uint256 public digitalAssetPrice;
    address public owner;
    string public descriptionURI;

    // Event declaration
    event customerFunded(
        address indexed customerAddr,
        uint256 indexed fundAmountl
    );

    event accessGranted(string indexed ipfsURI);

    // event buySuccess(address indexed buyer);

    // Modifier declaration
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert notContractOwner();
        }
        _;
    }

    // Constructor
    constructor(uint256 assetPrice, string memory descriptionLink) {
        owner = msg.sender;
        digitalAssetPrice = assetPrice;
        descriptionURI = descriptionLink;
    }

    // Function definition
    function registerRequest() public payable {
        if (msg.value < digitalAssetPrice) {
            revert PriceNotMet(digitalAssetPrice);
        }
        if (userFund[msg.sender] > digitalAssetPrice) {
            // prevent duplicate payment --> if customer has paid, they should wait for granted access to get ipfs link
            revert hasRequested();
        }
        userFund[msg.sender] += msg.value;
        emit customerFunded(msg.sender, msg.value);
    }

    function grantAccess(
        address customerAddr,
        bytes20 encryptedFileHash,
        bytes32 symmetricKey,
        string calldata ipfsURI
    ) external onlyOwner {
        // customerAddrToData[customerAddr].symmetricKey = symmetricKey;
        // customerAddrToData[customerAddr].ipfsURI = ipfsURI;
        // customerAddrToData[customerAddr].encryptedFileHash = encryptedFileHash;
        if (userFund[customerAddr] < digitalAssetPrice) {
            // customer has cancelled access request --> they no longer have fund in the contract
            revert notEnoughFund();
        }
        customerAddrToData[customerAddr] = customerAssetData(
            symmetricKey,
            encryptedFileHash,
            ipfsURI
        );
        emit accessGranted(ipfsURI);
    }

    function compareHashesAndGetKey(bytes20 customerHash)
        external
        payable
        returns (bytes32)
    {
        if (customerHash != customerAddrToData[msg.sender].encryptedFileHash) {
            // send back fund to customer in case of unmatch hashes
            userFundWithdrawable[msg.sender] += userFund[msg.sender];
            userFund[msg.sender] = 0;
            delete customerAddrToData[msg.sender];
            revert hashNotMatch();
        }
        // // Double check
        // if (userFund[msg.sender] < digitalAssetPrice) {
        //     revert notEnoughFund();
        // }
        userFundWithdrawable[owner] += digitalAssetPrice; // pay license fee to the content owner
        userFund[msg.sender] = 0;
        userFundWithdrawable[msg.sender] = 0;
        // emit buySuccess(msg.sender);
        return customerAddrToData[msg.sender].symmetricKey;
    }

    function getIpfsURI() public view returns (string memory) {
        if (bytes(customerAddrToData[msg.sender].ipfsURI).length == 0) {
            revert haveNotGrantedAccess();
        }
        return customerAddrToData[msg.sender].ipfsURI;
    }

    function withdrawFund() public {
        if (userFundWithdrawable[msg.sender] > 0) {
            uint256 amountWithdraw = userFundWithdrawable[msg.sender];
            userFundWithdrawable[msg.sender] = 0;
            (bool success, ) = payable(msg.sender).call{value: amountWithdraw}(
                ""
            );
            require(success, "Transfer failed");
        }
    }

    function cancelRequest() public {
        if (bytes(customerAddrToData[msg.sender].ipfsURI).length != 0) {
            // Cannot cancel the granted access
            revert accessGrantedAlready();
        }
        // can be cancelled if access has not been granted and customer has paid money
        if (userFund[msg.sender] > 0) {
            delete customerAddrToData[msg.sender];
            userFundWithdrawable[msg.sender] = userFund[msg.sender];
            userFund[msg.sender] = 0;
        }
    }
}