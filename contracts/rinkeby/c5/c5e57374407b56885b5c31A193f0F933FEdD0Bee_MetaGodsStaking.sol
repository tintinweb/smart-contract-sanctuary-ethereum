// SPDX-License-Identifier: GPL-3.0

/*
                8888888888 888                   d8b
                888        888                   Y8P
                888        888
                8888888    888 888  888 .d8888b  888 888  888 88888b.d88b.
                888        888 888  888 88K      888 888  888 888 "888 "88b
                888        888 888  888 "Y8888b. 888 888  888 888  888  888
                888        888 Y88b 888      X88 888 Y88b 888 888  888  888
                8888888888 888  "Y88888  88888P' 888  "Y88888 888  888  888
                                    888
                               Y8b d88P
                                "Y88P"
                888b     d888          888              .d8888b.                888
                8888b   d8888          888             d88P  Y88b               888
                88888b.d88888          888             888    888               888
                888Y88888P888  .d88b.  888888  8888b.  888         .d88b.   .d88888 .d8888b
                888 Y888P 888 d8P  Y8b 888        "88b 888  88888 d88""88b d88" 888 88K
                888  Y8P  888 88888888 888    .d888888 888    888 888  888 888  888 "Y8888b.
                888   "   888 Y8b.     Y88b.  888  888 Y88b  d88P Y88..88P Y88b 888      X88
                888       888  "Y8888   "Y888 "Y888888  "Y8888P88  "Y88P"   "Y88888  88888P'
*/

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

pragma solidity ^0.8.10;

interface Trusted721Collection {
    function isOwnerOfBatch(uint256[] calldata tokenIds_, address address_) external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IToken {
    function add(address wallet, uint256 amount) external;

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function mintTokens(address to, uint256 amount) external;
}

contract MetaGodsStaking is Initializable, OwnableUpgradeable, PausableUpgradeable {

    struct StakeData {
        bool isPaired;
        uint256 stakeType;
        uint256 claimDate;
        uint256 pairedTokenId;
    }

    struct StakeSelection {
        address collectionAddress;
        uint256 stakeType;
        uint256[] tokens;
        uint256[] traitId; // God - Relic, Weapon - x, Land - Rarity, Building - Type
        uint256[] pairedTokens;
        bytes[] signatures;
    }

    struct CollectionSelection {
        address collectionAddress;
        uint256[] tokens;
        uint256[] pairedTokens;
    }

    struct StakedTokenRes {
        bool isPaired;
        uint256 tokenId;
        uint256 traitId;
        uint256 stakeType;
        uint256 claimDate;
        uint256 pairedTokenId;
        uint256 maxClaimable;
    }

    struct GainLossBoost {
        uint256 loss;
        uint256 gain;
    }

    address private signerAddress;

    address[] public yieldingCollections;

    // collection address => tokenId => StakeData
    mapping(address => mapping(uint256 => StakeData)) public stakedTokensData;

    // owner address => collection address => tokenIds
    mapping(address => mapping(address => uint256[])) public stakedTokensByWallet;

    // god, weapon, land, building, token, stats
    mapping(string => address) public contractsAddressesMap;

    // god => weapon, weapon => god, land => building, building => land
    mapping(address => address) public pairedContractsAddressesMap;

    mapping(address => mapping(uint256 => mapping(bool => GainLossBoost))) public gainLossBoosters;

    // collection address => tokenId => traitId
    mapping(address => mapping(uint256 => uint256)) public tokenTrait;

    // collection address => traitId => baseYield
    mapping(address => mapping(uint256 => uint256)) public tokenYieldByTrait;

    // 1 => basic (all); 2 => low risk (god only); 3 => high risk (god only)
    mapping(string => uint256) public stakeTypesVariables;

    event ClaimedAmount(uint256 amount);

    function initialize() public initializer {
        __Pausable_init();
        __Ownable_init();
    }

    function stakeTokens(StakeSelection[] calldata selections_) external whenNotPaused {

        _validateMultipleSignature(selections_);

        uint256 totalAccumulatedYield;

        for (uint256 i = 0; i < selections_.length; ++i) {

            address collectionAddress = selections_[i].collectionAddress;
            address pairedCollectionAddress = pairedContractsAddressesMap[collectionAddress];

            require(Trusted721Collection(collectionAddress).isOwnerOfBatch(selections_[i].tokens, msg.sender));

            if (collectionAddress != contractsAddressesMap["god"]) {
                require(selections_[i].stakeType == stakeTypesVariables["basic"]);
            }

            for (uint256 j = 0; j < selections_[i].tokens.length; ++j) {

                if (selections_[i].pairedTokens.length > 0) {

                    uint256 pairedTokenId = selections_[i].pairedTokens[j];

                    require(isOwner(msg.sender, pairedCollectionAddress, pairedTokenId));

                    if (stakedTokensData[pairedCollectionAddress][pairedTokenId].isPaired) {

                        totalAccumulatedYield += _claimAndUnpair(
                            collectionAddress,
                            stakedTokensData[pairedCollectionAddress][pairedTokenId].pairedTokenId
                        );
                    }

                    if (block.timestamp > stakedTokensData[pairedCollectionAddress][pairedTokenId].claimDate) {
                        totalAccumulatedYield += _getYieldAndUpdateDate(pairedCollectionAddress, pairedTokenId);
                    }

                    _setStakeData(
                        collectionAddress,
                        selections_[i].tokens[j],
                        selections_[i].stakeType,
                        true,
                        pairedTokenId
                    );
                } else {
                    _setStakeData(
                        collectionAddress,
                        selections_[i].tokens[j],
                        selections_[i].stakeType,
                        false,
                        0
                    );
                }

                Trusted721Collection(collectionAddress).safeTransferFrom(msg.sender, address(this), selections_[i].tokens[j]);
            }
        }

        IToken(contractsAddressesMap["token"]).add(msg.sender, totalAccumulatedYield);

        emit ClaimedAmount(totalAccumulatedYield);

        delete totalAccumulatedYield;
    }

    function unStakeTokens(CollectionSelection[] calldata selections_) external whenNotPaused {

        uint256 totalAccumulatedYield;

        for (uint256 i = 0; i < selections_.length; ++i) {
            totalAccumulatedYield += _exitStakeStanceMany(
                selections_[i].collectionAddress,
                selections_[i].tokens
            );
        }

        IToken(contractsAddressesMap["token"]).add(msg.sender, totalAccumulatedYield);

        emit ClaimedAmount(totalAccumulatedYield);

        delete totalAccumulatedYield;
    }

    function moveStakeType(uint256[] memory tokenIds_, uint256[] memory stakeTypes_) external whenNotPaused {

        uint256 totalAccumulatedYield;

        for (uint256 i = 0; i < tokenIds_.length; ++i) {

            require(isOwner(msg.sender, contractsAddressesMap["god"], tokenIds_[i]));

            totalAccumulatedYield += _getYieldAndUpdateDate(contractsAddressesMap["god"], tokenIds_[i]);

            stakedTokensData[contractsAddressesMap["god"]][tokenIds_[i]].stakeType = stakeTypes_[i];
        }

        emit ClaimedAmount(totalAccumulatedYield);

        delete totalAccumulatedYield;
    }

    function changeTokenLinks(CollectionSelection[] calldata selections_) external whenNotPaused {

        uint256 totalAccumulatedYield;

        for (uint256 i = 0; i < selections_.length; ++i) {

            address collectionAddress = selections_[i].collectionAddress;
            address pairedCollectionAddress = pairedContractsAddressesMap[collectionAddress];

            for (uint256 j = 0; j < selections_[i].tokens.length; ++j) {

                uint256 tokenId = selections_[i].tokens[j];

                require(isOwner(msg.sender, collectionAddress, tokenId));

                totalAccumulatedYield += _getYieldAndUpdateDate(collectionAddress, tokenId);

                if (stakedTokensData[collectionAddress][tokenId].isPaired) {

                    totalAccumulatedYield += _claimAndUnpair(
                        pairedCollectionAddress,
                        stakedTokensData[collectionAddress][tokenId].pairedTokenId
                    );
                }

                if (selections_[i].pairedTokens.length > 0) {

                    uint256 pairedTokenId = selections_[i].pairedTokens[j];

                    require(isOwner(msg.sender, pairedCollectionAddress, pairedTokenId));

                    if (stakedTokensData[pairedCollectionAddress][pairedTokenId].isPaired) {

                        totalAccumulatedYield += _claimAndUnpair(
                            collectionAddress,
                            stakedTokensData[pairedCollectionAddress][pairedTokenId].pairedTokenId
                        );
                    }

                    totalAccumulatedYield += _getYieldAndUpdateDate(pairedCollectionAddress, pairedTokenId);

                    _setStakePairData(collectionAddress, tokenId, true, pairedTokenId);

                } else {

                    stakedTokensData[collectionAddress][tokenId].isPaired = false;
                }
            }
        }

        IToken(contractsAddressesMap["token"]).add(msg.sender, totalAccumulatedYield);

        emit ClaimedAmount(totalAccumulatedYield);

        delete totalAccumulatedYield;
    }

    function claimYields(CollectionSelection[] calldata selections_) external whenNotPaused returns (uint256) {

        uint256 amount;

        for (uint256 i = 0; i < selections_.length; ++i) {

            address collectionAddress = selections_[i].collectionAddress;

            for (uint256 j = 0; j < selections_[i].tokens.length; ++j) {

                require(isOwner(msg.sender, collectionAddress, selections_[i].tokens[j]));

                amount += _getYieldAndUpdateDate(collectionAddress, selections_[i].tokens[j]);
            }
        }

        IToken(contractsAddressesMap["token"]).add(msg.sender, amount);

        emit ClaimedAmount(amount);

        return amount;
    }

    function claimYieldForAll() external whenNotPaused returns (uint256) {

        uint256 amount;

        for (uint256 i = 0; i < yieldingCollections.length; ++i) {

            if (stakedTokensByWallet[msg.sender][yieldingCollections[i]].length > 0) {

                for (uint256 j = 0; j < stakedTokensByWallet[msg.sender][yieldingCollections[i]].length; ++j) {
                    amount += _getYieldAndUpdateDate(
                        yieldingCollections[i],
                        stakedTokensByWallet[msg.sender][yieldingCollections[i]][j]
                    );
                }
            }
        }

        IToken(contractsAddressesMap["token"]).add(msg.sender, amount);

        emit ClaimedAmount(amount);

        return amount;
    }

    function isOwner(address wallet_, address collection_, uint256 tokenId_) public view returns (bool) {
        for (uint256 i = 0; i < stakedTokensByWallet[wallet_][collection_].length; ++i) {
            if (stakedTokensByWallet[wallet_][collection_][i] == tokenId_) {
                return true;
            }
        }

        return false;
    }

    function setSignerAddress(address signerAddress_) external onlyOwner {
        signerAddress = signerAddress_;
    }

    function setYieldingCollections(address[] calldata yieldingCollections_) external onlyOwner {
        yieldingCollections = yieldingCollections_;
    }

    function setContractAddressesKeys(
        string[] calldata keys_,
        address[] calldata contractAddresses_
    ) external onlyOwner {
        for (uint i = 0; i < keys_.length; ++i) {
            contractsAddressesMap[keys_[i]] = contractAddresses_[i];
        }
    }

    function setPairedContractsAddresses(
        address[] calldata contractAddresses_,
        address[] calldata pairedContractAddresses_
    ) external onlyOwner {
        for (uint i = 0; i < contractAddresses_.length; ++i) {
            pairedContractsAddressesMap[contractAddresses_[i]] = pairedContractAddresses_[i];
        }
    }

    function setTokenTraitYields(
        address contractAddress_,
        uint256[] calldata traitIds_,
        uint256[] calldata yields_
    ) external onlyOwner {
        for (uint i = 0; i < traitIds_.length; ++i) {
            tokenYieldByTrait[contractAddress_][traitIds_[i]] = yields_[i];
        }
    }

    function setGainLossBoosters(
        address[] calldata contractAddresses_,
        uint256[][] calldata stakeTypes_,
        GainLossBoost[][][] calldata boosts_
    ) external onlyOwner {
        for (uint256 i = 0; i < contractAddresses_.length; ++i) {

            address contractAddress = contractAddresses_[i];

            for (uint256 j = 0; j < stakeTypes_[i].length; ++j) {

                uint256 stakeType = stakeTypes_[i][j];

                GainLossBoost storage unpairedGainLossBoost = gainLossBoosters[contractAddress][stakeType][false];
                GainLossBoost storage pairedGainLossBoost = gainLossBoosters[contractAddress][stakeType][true];

                unpairedGainLossBoost.loss = boosts_[i][j][0].loss;
                unpairedGainLossBoost.gain = boosts_[i][j][0].gain;
                pairedGainLossBoost.loss = boosts_[i][j][1].loss;
                pairedGainLossBoost.gain = boosts_[i][j][1].gain;
            }
        }
    }

    function setStakeTypesKeys(
        string[] calldata keys_,
        uint256[] calldata stakeTypeIndexes_
    ) external onlyOwner {
        for (uint256 i = 0; i < keys_.length; ++i) {
            stakeTypesVariables[keys_[i]] = stakeTypeIndexes_[i];
        }
    }

    function updateStakeState(
        address[] calldata contractAddresses_,
        uint256[] calldata tokenIds_,
        StakeData[] calldata data_
    ) external onlyOwner {

        for (uint256 i = 0; i < contractAddresses_.length; ++i) {

            StakeData storage stake = stakedTokensData[contractAddresses_[i]][tokenIds_[i]];
            stake.stakeType = data_[i].stakeType;
            stake.claimDate = data_[i].claimDate;
            stake.pairedTokenId = data_[i].pairedTokenId;
            stake.isPaired = data_[i].isPaired;
        }
    }

    function updateStakedTokensByWallet(
        address[] calldata walletAddresses_,
        address[] calldata contractAddresses_,
        uint256[][] calldata stakedTokens_

    ) external onlyOwner {

        for (uint256 i = 0; i < walletAddresses_.length; ++i) {
            stakedTokensByWallet[walletAddresses_[i]][contractAddresses_[i]] = stakedTokens_[i];
        }
    }

    function updateTokensTrait(
        address contractAddress_,
        uint256[] calldata tokenIds_,
        uint256[] calldata traitIds_
    ) external onlyOwner {
        for (uint i = 0; i < tokenIds_.length; ++i) {
            tokenTrait[contractAddress_][tokenIds_[i]] = traitIds_[i];
        }
    }

    function getTokensTrait(
        address contractAddress_,
        uint256[] calldata tokenIds_
    ) external view returns (uint256[] memory) {

        uint256[] memory traits = new uint256[](tokenIds_.length);

        for (uint i = 0; i < tokenIds_.length; ++i) {
            traits[i] = tokenTrait[contractAddress_][tokenIds_[i]];
        }

        return traits;
    }

    function getStakedTokens(address wallet_, address collection_) external view returns (StakedTokenRes[] memory) {

        StakedTokenRes[] memory stakedTokens = new StakedTokenRes[](stakedTokensByWallet[wallet_][collection_].length);

        for (uint256 i = 0; i < stakedTokensByWallet[wallet_][collection_].length; ++i) {

            uint256 tokenId = stakedTokensByWallet[wallet_][collection_][i];

            stakedTokens[i].tokenId = stakedTokensByWallet[wallet_][collection_][i];
            stakedTokens[i].traitId = tokenTrait[collection_][tokenId];
            stakedTokens[i].isPaired = stakedTokensData[collection_][tokenId].isPaired;
            stakedTokens[i].stakeType = stakedTokensData[collection_][tokenId].stakeType;
            stakedTokens[i].claimDate = stakedTokensData[collection_][tokenId].claimDate;
            stakedTokens[i].pairedTokenId = stakedTokensData[collection_][tokenId].pairedTokenId;
            stakedTokens[i].maxClaimable = getYield(collection_, tokenId, false);
        }

        return stakedTokens;
    }

    function stakingBalanceOf(address wallet_, address collection_) external view returns (uint256) {
        return stakedTokensByWallet[wallet_][collection_].length;
    }

    function getYield(
        address collection_,
        uint256 tokenId_,
        bool applyRisk_
    ) public view returns (uint256) {

        uint256 traitId = tokenTrait[collection_][tokenId_];
        uint256 stakeType = stakedTokensData[collection_][tokenId_].stakeType;
        bool isPaired = stakedTokensData[collection_][tokenId_].isPaired;

        uint256 yield = tokenYieldByTrait[collection_][traitId] *
        (block.timestamp - stakedTokensData[collection_][tokenId_].claimDate) /
        1 days;

        GainLossBoost storage gainLossBoost = gainLossBoosters[collection_][stakeType][isPaired];

        if(applyRisk_ && (gainLossBoost.gain > 0 || gainLossBoost.loss > 0)) {
            if(_didWin(tokenId_)) {
                yield += yield * gainLossBoost.gain / 100;
            } else {
                yield -= yield * gainLossBoost.loss / 100;
            }
        }

        delete traitId;
        delete stakeType;
        delete isPaired;

        return yield;
    }

    function _validateMultipleSignature(StakeSelection[] calldata selections_) internal {

        for (uint256 i = 0; i < selections_.length; i++) {
            if (selections_[i].signatures.length == 0) {
                continue;
            }

            for (uint256 j = 0; j < selections_[i].tokens.length; j++) {

                if(tokenTrait[selections_[i].collectionAddress][selections_[i].tokens[j]] != 0) {
                    continue;
                }

                bytes32 dataHash = keccak256(abi.encodePacked(
                        selections_[i].collectionAddress,
                        selections_[i].tokens[j],
                        selections_[i].traitId[j]
                    ));

                bytes32 message = ECDSAUpgradeable.toEthSignedMessageHash(dataHash);
                address receivedAddress = ECDSAUpgradeable.recover(message, selections_[i].signatures[j]);
                require(receivedAddress != address(0) && receivedAddress == signerAddress);
            }

            _setTokensData(
                selections_[i].collectionAddress,
                selections_[i].tokens,
                selections_[i].traitId
            );
        }
    }

    function _setStakeData(
        address collection_,
        uint256 tokenId_,
        uint256 stakeType_,
        bool isPaired_,
        uint256 pairedTokenId_
    ) internal {

        StakeData storage stake = stakedTokensData[collection_][tokenId_];
        stake.stakeType = stakeType_;
        stake.claimDate = block.timestamp;

        _setStakePairData(collection_, tokenId_, isPaired_, pairedTokenId_);

        stakedTokensByWallet[msg.sender][collection_].push(tokenId_);
    }

    function _setStakePairData(
        address collection_,
        uint256 tokenId_,
        bool isPaired_,
        uint256 pairedTokenId_
    ) internal {
        if (isPaired_) {
            stakedTokensData[collection_][tokenId_].pairedTokenId = pairedTokenId_;
            stakedTokensData[collection_][tokenId_].isPaired = true;
            stakedTokensData[pairedContractsAddressesMap[collection_]][pairedTokenId_].pairedTokenId = tokenId_;
            stakedTokensData[pairedContractsAddressesMap[collection_]][pairedTokenId_].isPaired = true;
        } else {
            stakedTokensData[collection_][tokenId_].isPaired = false;
        }
    }

    function _claimAndUnpair(
        address collection_,
        uint256 tokenId_
    ) internal returns (uint256) {

        stakedTokensData[collection_][tokenId_].isPaired = false;

        return _getYieldAndUpdateDate(collection_, tokenId_);
    }

    function _getYieldAndUpdateDate(
        address collection_,
        uint256 tokenId_
    ) internal returns (uint256) {

        uint256 yield = getYield(collection_, tokenId_, true);

        stakedTokensData[collection_][tokenId_].claimDate = block.timestamp;

        return yield;
    }

    function _exitStakeStanceMany(
        address collection_,
        uint256[] calldata tokenIds_
    ) internal returns (uint256) {

        uint256 yieldedAmount;

        for (uint256 i = 0; i < tokenIds_.length; ++i) {
            require(isOwner(msg.sender, collection_, tokenIds_[i]));

            yieldedAmount += getYield(collection_, tokenIds_[i], true);

            if (stakedTokensData[collection_][tokenIds_[i]].isPaired) {
                uint256 pairedToken = stakedTokensData[collection_][tokenIds_[i]].pairedTokenId;
                yieldedAmount += _getYieldAndUpdateDate(
                    pairedContractsAddressesMap[collection_],
                    pairedToken
                );
                stakedTokensData[pairedContractsAddressesMap[collection_]][pairedToken].isPaired = false;
            }

            _exitStakeStance(collection_, tokenIds_[i]);

            Trusted721Collection(collection_).safeTransferFrom(address(this), msg.sender, tokenIds_[i]);
        }

        return yieldedAmount;
    }

    function _exitStakeStance(
        address collection_,
        uint256 tokenId_
    ) internal {

        _moveTokenInTheListStake(stakedTokensByWallet[msg.sender][collection_], tokenId_);
        stakedTokensByWallet[msg.sender][collection_].pop();

        delete stakedTokensData[collection_][tokenId_];
    }

    function _moveTokenInTheListStake(
        uint256[] storage list,
        uint256 tokenId
    ) internal {
        uint256 foundIndex;
        uint256 i;
        for (; i < list.length; ++i) {
            if (list[i] == tokenId) {
                foundIndex = i;
                break;
            }
        }

        require(i != list.length);

        if (foundIndex != list.length - 1) {
            uint256 t = list[foundIndex];
            list[foundIndex] = list[list.length - 1];
            list[list.length - 1] = t;
        }
    }

    function _setTokensData(
        address collection_,
        uint256[] calldata tokenIds_,
        uint256[] calldata traitIds_
    ) internal {

        for (uint256 i = 0; i < tokenIds_.length; i++) {
            if (tokenTrait[collection_][tokenIds_[i]] == 0) {
                tokenTrait[collection_][tokenIds_[i]] = traitIds_[i];
            }
        }
    }

    function _didWin(uint256 tokenId) internal view returns (bool) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    tokenId,
                    tx.origin,
                    blockhash(block.number - 1),
                    block.timestamp
                )
            )
        ) & 1 == 1;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
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

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}