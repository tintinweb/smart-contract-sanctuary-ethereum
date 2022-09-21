// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Clu3Whitelist.sol";
import "./VerifySigner.sol";

error Clu3__NotOwner();

error Clu3__TimestampAlreadyPassed();

error Clu3__SignerNotValid();

error Clu3__InvalidSigner();

/**
 * @title Clu3: a smart contract to create transactions
 * @notice
 * @author Jesus Badillo
 */
contract Clu3 is Clu3Whitelist {
    // Inherit verification functions from VerifySigner Library
    using VerifySigner for address;

    // Enumerate the correct Web3 storage implementations
    // Web3 Service (IPFS, Ceramic, Tableland, Filecoin)
    enum Web3StorageImplementation {
        ON_CHAIN,
        IPFS,
        TABLELAND,
        FILECOIN,
        CERAMIC
    }

    // State Variables
    address private immutable i_signer;
    uint256 private immutable i_lifespan;
    address private immutable i_owner;
    uint256 private immutable i_eventTimestamp;
    uint256 private s_maxWhitelistAddresses;
    string private s_message;
    string private s_clu3Id;
    Web3StorageImplementation private s_web3Service;

    struct Clu3Event {
        uint256 clu3EventTimestamp;
        address clueEventAddress;
    }

    event SignerVerified(address indexed _signer);
    event AddressInWhiteList(address indexed _currentAddress);

    constructor(
        address _signer,
        uint256 _lifespan,
        string memory _message,
        string memory _clu3Id
    ) Clu3Whitelist(s_maxWhitelistAddresses) {
        i_signer = _signer;
        i_lifespan = _lifespan;
        s_clu3Id = _clu3Id;
        s_message = _message;
        i_eventTimestamp = block.timestamp;
        i_owner = msg.sender;
        s_web3Service = Web3StorageImplementation.ON_CHAIN;
    }

    modifier onlyOwner() override {
        if (msg.sender != i_owner) {
            revert Clu3__NotOwner();
        }
        _;
    }

    function senderInWhitelist(address _sender) private returns (bool) {
        if (isWhitelisted(_sender)) {
            return true;
        }
        emit AddressInWhiteList(_sender);
        return false;
    }

    function isWhitelistImplemented() private view returns (bool) {
        if (getNumberOfWhitelistedAddresses() == 0) {
            return false;
        }
        return true;
    }

    function isClu3Transaction() private returns (bool) {
        if (!senderInWhitelist(msg.sender) || !isWhitelistImplemented()) {
            return true;
        }

        if (i_eventTimestamp + i_lifespan > block.timestamp) {
            revert Clu3__TimestampAlreadyPassed();
        }

        // Verify that the message: "timestamp-clu3_id-sender_address"
        if ((msg.sender).verifySigner(s_message) != msg.sender) {
            revert Clu3__InvalidSigner();
        }

        emit SignerVerified(msg.sender);

        return false;
    }

    // function implementWeb3Storage() private returns (bool) {
    //     if (s_web3Service == Web3StorageImplementation.IPFS) {

    //     }
    //     //else if (s_web3Service == Web3StorageImplementation.FILECOIN) {
    //     //     //s_web3Service;
    //     // } else if (s_web3Service == Web3StorageImplementation.CERAMIC) {
    //     //     //s_web3Service;
    //     // } else if (s_web3Service == Web3StorageImplementation.TABLELAND) {}
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error VerifySigner__InvalidSignatureLength();

/**
 * @title VerifySignature - use the signer address and a message to verify the signer of a message on chain
 * @author Jesus Badillo
 * @dev
 */

library VerifySigner {
    function getMessageHash(string memory _message)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_message));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verifySigner(address _signer, string memory _message)
        external
        pure
        returns (address)
    {
        bytes32 messageHash = getMessageHash(_message);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        // Convert signer address and return address that contract computes
        return recoverSigner(ethSignedMessageHash, abi.encodePacked(_signer));
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (_signature.length != 65) {
            revert VerifySigner__InvalidSignatureLength();
        }

        // Dynamic variable length stored in first 32 bytes (i.e. 65 bytes)
        assembly {
            // Set r to be bytes [32,63] inclusive
            r := mload(add(_signature, 32))
            // Set s to be bytes [64,95] inclusive
            s := mload(add(_signature, 64))
            // Set v to be byte 96
            v := byte(0, mload(add(_signature, 96))) //
        }

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

error Clu3Whitelist__NotOwner();

error Clu3Whitelist__AlreadyInWhitelist();

error Clu3Whitelist__MaxWhitelistAddressesReached();

error Clu3Whitelist__NotWhitelisted();

/**
 *  @title Clu3Whitelist: A whitelist for the addresses that can mint a Clu3 captcha transaction
 *  @author Jesus Badillo
 *  @notice
 *  @dev
 */
contract Clu3Whitelist {
    // The number of accounts we want to have in our whitelist.
    uint256 private immutable i_maxNumberOfWhitelistAddresses;

    // Track the number of whitelisted addresses.
    uint256 private s_numberOfAddressesWhitelisted;

    // The owner of the contract
    address private immutable i_owner;

    // To store our addresses, we need to create a mapping that will receive the user's address and return if they are whitelisted or not.
    mapping(address => bool) private s_whitelistAddresses;

    constructor(uint256 _maxWhitelistAddresses) {
        i_owner = msg.sender;
        i_maxNumberOfWhitelistAddresses = _maxWhitelistAddresses;
    }

    // Validate only the owner can call the function
    modifier onlyOwner() virtual {
        if (msg.sender != i_owner) {
            revert Clu3Whitelist__NotOwner();
        }
        _;
    }

    /**
     *  @dev function addUserAddressToWhitelist
     *
     */
    function addUserAddressToWhitelist(address _addressToWhitelist)
        public
        onlyOwner
    {
        // Validate the caller is not already part of the whitelist.
        if (!s_whitelistAddresses[_addressToWhitelist]) {
            revert Clu3Whitelist__AlreadyInWhitelist();
        }

        // Validate if the maximum number of whitelisted addresses is not reached. If not, then throw an error.
        if (s_numberOfAddressesWhitelisted < i_maxNumberOfWhitelistAddresses) {
            revert Clu3Whitelist__MaxWhitelistAddressesReached();
        }

        // Set whitelist boolean to true.
        s_whitelistAddresses[_addressToWhitelist] = true;

        // Increasing the count
        s_numberOfAddressesWhitelisted += 1;
    }

    function verifyUserAddress(address _whitelistAddress)
        public
        view
        returns (bool)
    {
        // Verifying if the user has been whitelisted
        bool userIsWhitelisted = s_whitelistAddresses[_whitelistAddress];
        return userIsWhitelisted;
    }

    /**
     *  @notice function isWhitelisted checks if function is whitelisted
     *  @dev
     */
    function isWhitelisted(address _whitelistAddress)
        public
        view
        returns (bool)
    {
        // Verifying if the user has been whitelisted
        return s_whitelistAddresses[_whitelistAddress];
    }

    // Remove user from whitelist
    function removeUserAddressFromWhitelist(address _addressToRemove)
        public
        onlyOwner
    {
        // Validate the caller is already part of the whitelist.
        if (s_whitelistAddresses[_addressToRemove]) {
            revert Clu3Whitelist__NotWhitelisted();
        }

        // Set whitelist boolean to false.
        s_whitelistAddresses[_addressToRemove] = false;

        // This will decrease the number of whitelisted addresses.
        s_numberOfAddressesWhitelisted -= 1;
    }

    // Get the number of whitelisted addresses
    function getNumberOfWhitelistedAddresses() public view returns (uint256) {
        return s_numberOfAddressesWhitelisted;
    }

    // Get the maximum number of whitelisted addresses
    function getMaxNumberOfWhitelistedAddresses()
        public
        view
        returns (uint256)
    {
        return i_maxNumberOfWhitelistAddresses;
    }

    // Get the owner of the contract
    function getOwner() public view returns (address) {
        return i_owner;
    }
}