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
error noFundToWithdraw();
error haveNotRegister();
error youAreTheOwner();

// smart contract
contract DigitalAssetContract {
    // Data type definition
    struct customerAssetData {
        // AES-256
        string encryptedSymmetricKey; // 0x7465737400000000000000000000000000000000000000000000000000000000
        string encryptedFileHash; // fixed to 32 bytes
        string ipfsURI;
    }

    // State variables
    mapping(address => customerAssetData) private customerAddrToData; // private
    mapping(address => uint256) private userFund; // private
    mapping(address => uint256) private userFundWithdrawable; // private
    uint256 public digitalAssetPrice;
    address public owner;

    // Event declaration
    event customerFunded(address indexed customerAddr, uint256 indexed fundAmountl);

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
    constructor(uint256 assetPrice) {
        owner = msg.sender;
        digitalAssetPrice = assetPrice;
    }

    // Function definition
    function updatePrice(uint256 newPrice) public onlyOwner {
        digitalAssetPrice = newPrice;
    }

    function registerRequest() public payable {
        if (msg.sender == owner) {
            revert youAreTheOwner();
        }
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
        string calldata encryptedFileHash, // fixed from 20 bytes to 32 bytes
        string calldata encryptedSymmetricKey,
        string calldata ipfsURI
    ) external onlyOwner {
        if (bytes(customerAddrToData[customerAddr].ipfsURI).length != 0) {
            // Cannot cancel the granted access
            revert accessGrantedAlready();
        }
        if (userFund[customerAddr] < digitalAssetPrice) {
            // customer has cancelled access request --> they no longer have fund in the contract
            revert haveNotRegister();
        }
        customerAddrToData[customerAddr] = customerAssetData(
            encryptedSymmetricKey,
            encryptedFileHash,
            ipfsURI
        );
        emit accessGranted(ipfsURI);
    }

    function compareHashesAndGetKey(string memory customerHash) external returns (string memory) {
        if (bytes(customerAddrToData[msg.sender].ipfsURI).length == 0) {
            revert haveNotGrantedAccess();
        }
        // if (customerHash != customerAddrToData[msg.sender].encryptedFileHash) {
        if (!compareStrings(customerHash, customerAddrToData[msg.sender].encryptedFileHash)) {
            // send back fund to customer in case of unmatch hashes
            userFundWithdrawable[msg.sender] += userFund[msg.sender];
            userFund[msg.sender] = 0;
            delete customerAddrToData[msg.sender];
            revert hashNotMatch();
        }
        // Double check
        if (userFund[msg.sender] < digitalAssetPrice) {
            revert notEnoughFund();
        }
        userFundWithdrawable[owner] += digitalAssetPrice; // pay license fee to the content owner
        userFund[msg.sender] = 0;
        userFundWithdrawable[msg.sender] = 0;
        // emit buySuccess(msg.sender);
        string memory encryptedSymmetricKeyToSend = customerAddrToData[msg.sender]
            .encryptedSymmetricKey;
        delete customerAddrToData[msg.sender];
        return encryptedSymmetricKeyToSend;
    }

    function getIpfsURI() public view returns (string memory) {
        if (bytes(customerAddrToData[msg.sender].ipfsURI).length == 0) {
            revert haveNotGrantedAccess();
        }
        return customerAddrToData[msg.sender].ipfsURI;
    }

    function withdrawFund() public {
        if (userFundWithdrawable[msg.sender] <= 0) {
            revert noFundToWithdraw();
        }

        uint256 amountWithdraw = userFundWithdrawable[msg.sender];
        userFundWithdrawable[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amountWithdraw}("");
        require(success, "Transfer failed");
    }

    function cancelRequest() public {
        if (bytes(customerAddrToData[msg.sender].ipfsURI).length != 0) {
            // Cannot cancel the granted access
            revert accessGrantedAlready();
        }
        // can be cancelled if access has not been granted and customer has paid money
        if (userFund[msg.sender] <= 0) {
            revert haveNotRegister();
        }
        delete customerAddrToData[msg.sender];
        userFundWithdrawable[msg.sender] = userFund[msg.sender];
        userFund[msg.sender] = 0;
    }

    function getPrice() public view returns (uint256) {
        return digitalAssetPrice;
    }

    // function getWithdrawableFund() public view returns (uint256) {
    //     return userFundWithdrawable[msg.sender];
    // }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}