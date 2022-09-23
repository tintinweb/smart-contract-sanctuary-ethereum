// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./Clu3Whitelist.sol";

error Clu3__NotOwner();

error Clu3__TimestampAlreadyPassed();

error Clu3__InvalidSigner();

error Clu3__InvalidSignatureLength();

error Clu3__TimestampClu3IdAlreadyUsed();

/**
 * @title Clu3: a smart contract to prevent bots
 * @notice
 * @author Jesus Badillo
 */
contract Clu3 is Clu3Whitelist {
    // Inherit verification functions from VerifySigner Library

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
    address private s_signer;
    uint256 private s_lifespan;
    string private s_clu3Id;
    uint256 private s_timestamp;
    string private s_message;
    Web3StorageImplementation private s_web3Service;

    event SignerVerified(address indexed _signer);
    event AddressInWhiteList(address indexed _currentAddress);

    constructor(
        address _signer,
        uint256 _lifespan,
        string memory _clu3Id,
        uint256 _maxWhitelistAddresses
    ) Clu3Whitelist(_maxWhitelistAddresses) {
        s_signer = _signer;
        s_lifespan = _lifespan;
        s_clu3Id = _clu3Id;
        s_web3Service = Web3StorageImplementation.ON_CHAIN;
    }

    function signerInWhitelist(address _signer) public returns (bool) {
        if (isWhitelisted(_signer)) {
            return true;
        }
        emit AddressInWhiteList(_signer);
        return false;
    }

    function isWhitelistImplemented() public view returns (bool) {
        if (getNumberOfWhitelistedAddresses() == 0) {
            return false;
        }
        return true;
    }

    function setClu3Id(string memory _clu3Id) public {
        s_clu3Id = _clu3Id;
    }

    function setLifespan(uint256 _lifespan) public {
        s_lifespan = _lifespan;
    }

    function setSigner(address _signer) public {
        s_signer = _signer;
    }

    function setClu3Message(string memory _message) private {
        s_message = _message;
    }

    function setTimestamp(uint256 _timestamp) private {
        s_timestamp = _timestamp;
    }

    function verifySigner(bytes memory _signature) public returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        string memory part1 = string.concat(
            Strings.toString(s_timestamp),
            s_clu3Id
        );
        setClu3Message(string.concat(Strings.toHexString(s_signer), part1));
        bytes32 _messageHash = keccak256(abi.encodePacked(s_message));
        bytes32 _ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
        );

        if (_signature.length != 65) {
            revert Clu3__InvalidSignatureLength();
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

    function clu3Transaction(uint256 _timestamp, bytes memory _signature)
        public
        returns (string memory)
    {
        if (!signerInWhitelist(s_signer) || !isWhitelistImplemented()) {
            return "Already In Whitelist";
        }
        setTimestamp(_timestamp);
        if (_timestamp + s_lifespan > block.timestamp) {
            revert Clu3__TimestampAlreadyPassed();
        }

        // Verify that the message: "timestamp-clu3_id-sender_address"
        if (verifySigner(_signature) != s_signer) {
            revert Clu3__InvalidSigner();
        }

        emit SignerVerified(s_signer);

        return string.concat(Strings.toString(_timestamp), s_clu3Id);
    }

    // function implementWeb3Storage(bytes32 _clu3Message) private returns (bool) {
    //     if (s_web3Service == Web3StorageImplementation.ON_CHAIN) {
    //         _

    //     }
    //     else if(s_web3Service == Web3StorageImplementation.IPFS){

    //     }
    //     else if (s_web3Service == Web3StorageImplementation.FILECOIN) {
    //         //s_web3Service;
    //     } else if (s_web3Service == Web3StorageImplementation.CERAMIC) {
    //         //s_web3Service;
    //     } else if (s_web3Service == Web3StorageImplementation.TABLELAND) {}
    // }

    function getWeb3ServiceImplementation()
        public
        view
        returns (Web3StorageImplementation)
    {
        return s_web3Service;
    }

    function getSigner() public view returns (address) {
        return s_signer;
    }

    function getClu3Id() public view returns (string memory) {
        return s_clu3Id;
    }

    function getClu3Message() public view returns (string memory) {
        return s_message;
    }

    function getLifespan() public view returns (uint256) {
        return s_lifespan;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}