// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

contract NewDawnPaymentForwarder {

    mapping(bytes32 => bool) public verifiedOffer;
    mapping(address => uint) userNonce;
    
    address public admin;
    address payable public treasury;
    bool public tradingToggle;
    bool initialized;

    uint internal _directOfferPrice;
    uint internal _directAcceptancePrice;
    uint internal _globalOfferPrice;
    uint internal _globalAcceptancePrice;

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewTreasury(address oldTreasury, address newTreasury);
    event UpdatedTradingStatus(bool status);
    event PriceChange(string indexed _type, uint newPrice);
    event NewNonce(address indexed user, uint nonce);
    event DirectOffer(uint indexed txnId, address indexed to, address indexed from_poster);
    event DirectOfferAcceptance(uint indexed txnId, address indexed to_accepter, address indexed from);
    event GlobalOffer(uint indexed txnId, address indexed from_poster);
    event GlobalOfferAcceptance(uint indexed txnId, address indexed from, address indexed caller);

    modifier onlyAdmin {
        require(msg.sender == admin, "Only Admin");
        _;
    }

    // requires `tradingToggle` to be true
    modifier tradingEnabled {
        require(tradingToggle, "Trading is disabled");
        _;
    }

    function initialize(
        address payable treasuryAddress,
        address _admin,
        uint directOfferPriceInWei,
        uint directAcceptancePriceInWei,
        uint globalOfferPriceInWei,
        uint globalAcceptancePriceInWei
    ) external {
        require(!initialized, "Already initialized");
        admin = _admin;
        require(treasuryAddress != address(0), "treasury cannot be set to zero");
        treasury = treasuryAddress;
        initialized = true;
        _setAllPrices(directOfferPriceInWei, directAcceptancePriceInWei, globalOfferPriceInWei, globalAcceptancePriceInWei);
    }

    function makeDirectOffer(uint txnId, uint nftId, address to, bytes calldata sig) external payable tradingEnabled {
        bytes32 ethSignedMsgHash = getHashDirect(txnId, nftId, to, msg.sender);
        require(ECDSA.recover(ethSignedMsgHash, sig) == msg.sender, "Signer not transaction sender");
        require(msg.value == _directOfferPrice, "Invalid Eth Amount");
        verifiedOffer[ethSignedMsgHash] = true;
        emit DirectOffer(txnId, to, msg.sender);
        _transferMsgValueToTreasury();
    }

    function acceptDirectOffer(uint txnId, uint nftId, address from, bytes calldata sig) external payable tradingEnabled {
        bytes32 ethSignedMsgHash = getHashDirect(txnId, nftId, msg.sender, from);
        require(ECDSA.recover(ethSignedMsgHash, sig) == from, "Signer is not the from address");
        require(verifiedOffer[ethSignedMsgHash], "Offer not verified!");
        require(msg.value == _directAcceptancePrice, "Invalid Eth Amount");
        verifiedOffer[ethSignedMsgHash] = false;
        emit DirectOfferAcceptance(txnId, msg.sender, from);
        _transferMsgValueToTreasury();
    }

    function makeGlobalOffer(uint txnId, uint nftId, bytes calldata sig) external payable tradingEnabled {
        bytes32 ethSignedMsgHash = getHashGlobal(txnId, nftId, msg.sender);
        require(ECDSA.recover(ethSignedMsgHash, sig) == msg.sender, "Invalid signature!");
        require(msg.value == _globalOfferPrice, "Invalid Eth Amount");
        verifiedOffer[ethSignedMsgHash] = true;
        emit GlobalOffer(txnId, msg.sender);
        _transferMsgValueToTreasury();
    }

    function acceptGlobalOffer(uint txnId, uint nftId, address from, bytes calldata sig) external payable tradingEnabled {
        bytes32 ethSignedMsgHash = getHashGlobal(txnId, nftId, from);
        require(ECDSA.recover(ethSignedMsgHash, sig) == from, "Signer is not the from address");
        require(verifiedOffer[ethSignedMsgHash], "Offer not verified!");
        require(msg.value == _globalAcceptancePrice, "Invalid Eth Amount");
        verifiedOffer[ethSignedMsgHash] = false;
        emit GlobalOfferAcceptance(txnId, from, msg.sender);
        _transferMsgValueToTreasury();
    }

    function cancelOffer(bytes32 ethSignedMsgHash, bytes calldata signature) external {
        require(ECDSA.recover(ethSignedMsgHash, signature) == msg.sender, "Signer is not the from address");
        verifiedOffer[ethSignedMsgHash] = false;
    }

    function cancelAllActiveOfferes() external {
        emit NewNonce(msg.sender, ++userNonce[msg.sender]);
    }

    // ADMIN FUNCTIONS
    
    function changeAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Admin cannot be set to zero");
        address oldAdmin = admin;
        admin = newAdmin;
        emit NewAdmin(oldAdmin, newAdmin);
    }

    function setTreasuryAddress(address payable newAddress) external onlyAdmin {
        require(newAddress != address(0), "Treasury cannot be set to zero");
        address oldTreasury = treasury;
        treasury = newAddress;
        emit NewTreasury(oldTreasury, newAddress);
    }

    // switch for trading toggle
    function toggleTrading() external onlyAdmin {
        tradingToggle = !tradingToggle;
        emit UpdatedTradingStatus(tradingToggle);
    }

    function changeDirectOfferPrice(uint priceInWei) external onlyAdmin {
        _directOfferPrice = priceInWei;
        emit PriceChange("Direct Offer", priceInWei);
    }

    function changeDirectAcceptancePrice(uint priceInWei) external onlyAdmin {
        _directAcceptancePrice = priceInWei;
        emit PriceChange("Direct Acceptance", priceInWei);
    }

    function changeGlobalOfferPrice(uint priceInWei) external onlyAdmin {
        _globalOfferPrice = priceInWei;
        emit PriceChange("Global Offer", priceInWei);
    }

    function changeGlobalAcceptancePrice(uint priceInWei) external onlyAdmin {
        _globalAcceptancePrice = priceInWei;
        emit PriceChange("Global Acceptance", priceInWei);
    }

    function changeAllPrices(
        uint directOfferPriceInWei,
        uint directAcceptancePriceInWei,
        uint globalOfferPriceInWei,
        uint globalAcceptancePriceInWei
    ) external onlyAdmin {
        _setAllPrices(directOfferPriceInWei, directAcceptancePriceInWei, globalOfferPriceInWei, globalAcceptancePriceInWei);
        emit PriceChange("Direct Offer", directOfferPriceInWei);
        emit PriceChange("Direct Acceptance", directAcceptancePriceInWei);
        emit PriceChange("Global Offer", globalOfferPriceInWei);
        emit PriceChange("Global Acceptance", globalAcceptancePriceInWei);
    }

    
    // GETTERS
    /*
     * @dev returns all price values
     */
    function returnPrices() external view returns(uint directOffer, uint directAcceptance, uint globalOffer, uint globalAcceptance) {
        directOffer = _directOfferPrice;
        directAcceptance = _directAcceptancePrice;
        globalOffer = _globalOfferPrice;
        globalAcceptance = _globalAcceptancePrice;
    }

    // PRIVATE FUNCTIONS

    function _transferMsgValueToTreasury() private {
        (bool success, ) = treasury.call{value: msg.value, gas: 3000}("");
        require(success, "Transfer to treasury failed");
    }

    function getHashDirect(uint txnId, uint nftId, address to, address signer) private view returns(bytes32) {
        return ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(txnId, nftId, to, userNonce[signer])));
    }

    function getHashGlobal(uint txnId, uint nftId, address signer) private view returns(bytes32) {
        return ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(txnId, nftId, userNonce[signer])));
    }

    function _setAllPrices(
        uint directOfferPriceInWei,
        uint directAcceptancePriceInWei,
        uint globalOfferPriceInWei,
        uint globalAcceptancePriceInWei
    ) private {
        _directOfferPrice = directOfferPriceInWei;
        _directAcceptancePrice = directAcceptancePriceInWei;
        _globalOfferPrice = globalOfferPriceInWei;
        _globalAcceptancePrice = globalAcceptancePriceInWei;
    }

    // UTILS
    function getMsgDirect(uint txnId, uint nftId, address to, address signer) external view returns(bytes32) {
        return keccak256(abi.encodePacked(txnId, nftId, to, userNonce[signer]));
    }

    function getMsgGlobal(uint txnId, uint nftId, address signer) external view returns(bytes32) {
        return keccak256(abi.encodePacked(txnId, nftId, userNonce[signer]));
    }
}