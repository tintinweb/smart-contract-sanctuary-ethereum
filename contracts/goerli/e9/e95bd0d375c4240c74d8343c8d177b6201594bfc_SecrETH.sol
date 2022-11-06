/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

contract SecrETH {
    
    // public key of our contract
    bytes32 private pubKey;

    uint32 private threshold;

    uint32 private numSigners;

    uint32 private blocksDelay;

    uint32 private generalFee;

    struct CipherInfo {
        address cipherOwner; // address that registered cipher
        uint256 decryptionInitBlock; // block number when decryption was called
        address[] decryptionSigners; // signers that already provided their partial decryption
        PartialDecryption[] partialDecryptions; // indexes correspond to index of signer that provied partial decryption
        bool storeDecryption; // should final decryption of cipher be stored on change
        string decryptedCipher;
        uint256 decryptionStorageFee;
    }

    struct PartialDecryption {
        string x;
        string yC1_x;
        string yC1_y;
    }

    // adress --> is_a_signer
    mapping(address => bool) public isSigner;

    // new_signer_public_key --> [shares_to_generate_new_signers_share_encrypted_with_their_public_key]
    mapping(bytes32 => bytes32[]) public shareGenerationPartialSignatures;

    // stores all registered ciphers and information about them
    mapping(string => CipherInfo) public allCiphers;

    event DecryptionCalled(string cipher, bool shouldStoreDecryption);
    event DecryptionReady(string cipher);
    event DecryptionReadyIncentivized(string cipher, uint256 storageFee);
    event JoinNetworkRequest(bytes32 newSignerPubKey);

    constructor(address[] memory initialSigners, bytes32 _pubKey, uint32 _threshold, uint32 _blocksDelay, uint32 _generalFee) {
        for (uint i = 0; i < initialSigners.length; i++){
            isSigner[initialSigners[i]] = true;
        }
        pubKey = _pubKey;
        threshold = _threshold;
        numSigners = uint32(initialSigners.length);
        blocksDelay = _blocksDelay;
        generalFee = _generalFee;
    }

    function register(string calldata cipher) payable public {
        require (allCiphers[cipher].cipherOwner == address(0), "This ciphertext is already registered. Try using another salt.");
        require (msg.value >= generalFee, "msg.value was not enough to cover the fee.");
        allCiphers[cipher].cipherOwner = msg.sender;
    }

    function decrypt(string calldata cipher, bool shouldStoreDecryption) payable public {
        require (allCiphers[cipher].cipherOwner == msg.sender, "This address is not allowed to decrypt this ciphertext.");
        emit DecryptionCalled(cipher, shouldStoreDecryption);
        allCiphers[cipher].decryptionInitBlock = block.number;

        if (shouldStoreDecryption) {
            allCiphers[cipher].decryptionStorageFee = msg.value;
            allCiphers[cipher].storeDecryption = true;
        }
    }

    function submitPartialDecryption (string calldata cipher, string calldata partialDecryptionX, string calldata partialDecryptionC1_x, string calldata partialDecryptionC1_y) public {
        require (isSigner[msg.sender], "This address is not a secrETH signer.");
        require (block.number <= allCiphers[cipher].decryptionInitBlock + blocksDelay, "The time to submit a partial decryption has passed.");
        for (uint i = 0; i < allCiphers[cipher].decryptionSigners.length; i++) {
            require (allCiphers[cipher].decryptionSigners[i] != msg.sender, "This address aleready provided their partial decryption.");
        }

        payable(msg.sender).transfer(generalFee / numSigners);

        PartialDecryption memory newPartialDecryption;
        newPartialDecryption = PartialDecryption(partialDecryptionX, partialDecryptionC1_x, partialDecryptionC1_y);

        // TODO P5: implement ZK to require partialDecryption is a valid decryption

        allCiphers[cipher].partialDecryptions.push(newPartialDecryption);
        allCiphers[cipher].decryptionSigners.push(msg.sender);

        if (allCiphers[cipher].partialDecryptions.length >= threshold) {
            if (!allCiphers[cipher].storeDecryption) {
                emit DecryptionReady(cipher);
            }
            else {
                emit DecryptionReadyIncentivized(cipher, allCiphers[cipher].decryptionStorageFee);
            }
        }
    }

    function submitDecryption (string calldata cipher, string calldata decryptedCipher) public {
        require (allCiphers[cipher].cipherOwner != address(0));
        // require encrypt(decryption, pubKey) == cipher

        allCiphers[cipher].decryptedCipher = decryptedCipher;

        if (allCiphers[cipher].storeDecryption) {
            payable(msg.sender).transfer(allCiphers[cipher].decryptionStorageFee);
        }
    }

    // Tell current signers to generate a new share of the secret key for msg.sender
    function joinNetwork(bytes32 newSignerPubKey) public {
        // TODO P3: process stake
        emit JoinNetworkRequest(newSignerPubKey);
    }

    function submitShare(bytes32 newSignerPubKey, bytes32 share) public {
        shareGenerationPartialSignatures[newSignerPubKey].push(share);
    }

    function getPubKey() public view returns (bytes32) {
        return pubKey;
    }

    function getThreshold() public view returns (uint32) {
        return threshold;
    }

    function getNumSigners() public view returns (uint32) {
        return numSigners;
    }

    function getBlocksDelay() public view returns (uint32) {
        return blocksDelay;
    }

    function getGeneralFee() public view returns (uint32) {
        return generalFee;
    }
}