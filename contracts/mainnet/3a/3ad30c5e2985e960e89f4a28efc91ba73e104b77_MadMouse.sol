//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM`MMM NMM MMM MMM MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM  MMMMhMMMMMMM  MMMMMMMM MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM  MM-MMMMM   MMMM    MMMM   lMMMDMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMM jMMMMl   MM    MMM  M  MMM   M   MMMM MMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMM MMMMMMMMM  , `     M   Y   MM  MMM  BMMMMMM MMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMM MMMMMMMMMMMM  IM  MM  l  MMM  X   MM.  MMMMMMMMMM MMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.nlMMMMMMMMMMMMMMMMM]._  MMMMMMMMMMMMMMMNMMMMMMMMMMMMMM
// MMMMMMMMMMMMMM TMMMMMMMMMMMMMMMMMM          +MMMMMMMMMMMM:  rMMMMMMMMN MMMMMMMMMMMMMM
// MMMMMMMMMMMM MMMMMMMMMMMMMMMM                  MMMMMM           MMMMMMMM qMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMM^                   MMMb              .MMMMMMMMMMMMMMMMMMM
// MMMMMMMMMM MMMMMMMMMMMMMMM                     MM                  MMMMMMM MMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM                     M                   gMMMMMMMMMMMMMMMMM
// MMMMMMMMu MMMMMMMMMMMMMMM                                           MMMMMMM .MMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMM                                           :MMMMMMMMMMMMMMMM
// MMMMMMM^ MMMMMMMMMMMMMMMl                                            MMMMMMMM MMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMM                                             MMMMMMMMMMMMMMMM
// MMMMMMM MMMMMMMMMMMMMMMM                                             MMMMMMMM MMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMM                                             MMMMMMMMMMMMMMMM
// MMMMMMr MMMMMMMMMMMMMMMM                                             MMMMMMMM .MMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMM                                           MMMMMMMMMMMMMMMMM
// MMMMMMM MMMMMMMMMMMMMMMMM                                         DMMMMMMMMMM MMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM                              MMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMM|`MMMMMMMMMMMMMMMM         q                      MMMMMMMMMMMMMMMMMMM  MMMMMMM
// MMMMMMMMMTMMMMMMMMMMMMMMM                               qMMMMMMMMMMMMMMMMMMgMMMMMMMMM
// MMMMMMMMq MMMMMMMMMMMMMMMh                             jMMMMMMMMMMMMMMMMMMM nMMMMMMMM
// MMMMMMMMMM MMMMMMMMMMMMMMMQ      nc    -MMMMMn        MMMMMMMMMMMMMMMMMMMM MMMMMMMMMM
// MMMMMMMMMM.MMMMMMMMMMMMMMMMMMl            M1       `MMMMMMMMMMMMMMMMMMMMMMrMMMMMMMMMM
// MMMMMMMMMMMM MMMMMMMMMMMMMMMMMMMM               :MMMMMMMMMM MMMMMMMMMMMM qMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM  MMMMMMX       MMMMMMMMMMMMMMM  uMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMM DMMMMMMMMM   IMMMMMMMMMMMMMMMMMMMMMMM   M   Y  MMMMMMMN MMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMM MMMMMM    ``    M      MM  MMM   , MMMM    Mv  MMM MMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMM MMh  Ml  .   M  MMMM  I  MMMT  M     :M   ,MMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMM MMMMMMMMt  MM  MMMMB m  ]MMM  MMMM   MMMMMM MMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMM MMMMM  MMM   TM   MM  9U  .MM  _MMMMM MMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM YMMMMMMMn     MMMM    +MMMMMMM1`MMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM MMMMMMMMMMMMMMMMMMMMMMM MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.`MMM MMM MMMMM`.MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM author: phaze MMM

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

import './lib/Ownable.sol';
import {VRFBaseMainnet as VRFBase} from './lib/VRFBase.sol';

import './Gouda.sol';
import './MadMouseMetadata.sol';
import './MadMouseStaking.sol';

error PublicSaleNotActive();
error WhitelistNotActive();
error InvalidAmount();
error ExceedsLimit();
error SignatureExceedsLimit();
error IncorrectValue();
error InvalidSignature();
error ContractCallNotAllowed();

error InvalidString();
error MaxLevelReached();
error MaxNumberReached();
error MinHoldDurationRequired();

error IncorrectHash();
error CollectionAlreadyRevealed();
error CollectionNotRevealed();
error TokenDataAlreadySet();
error MintAndStakeMinHoldDurationNotReached();

contract MadMouse is Ownable, MadMouseStaking, VRFBase {
    using ECDSA for bytes32;
    using UserDataOps for uint256;
    using TokenDataOps for uint256;
    using DNAOps for uint256;

    bool public publicSaleActive;

    uint256 constant MAX_SUPPLY = 5555;
    uint256 constant MAX_PER_WALLET = 20;

    uint256 constant price = 0.085 ether;
    uint256 constant PURCHASE_LIMIT = 5;

    uint256 constant whitelistPrice = 0.075 ether;
    uint256 constant WHITELIST_PURCHASE_LIMIT = 5;

    MadMouseMetadata public metadata;
    address public multiSigTreasury = 0xFB79a928C5d6c5932Ba83Aa8C7145cBDCDb9fd2E;
    address signerAddress = 0x3ADE0c5e35cbF136245F4e4bBf4563BD151d39D1;

    uint256 public totalLevel2Reached;
    uint256 public totalLevel3Reached;

    uint256 constant LEVEL_2_COST = 120 * 1e18;
    uint256 constant LEVEL_3_COST = 350 * 1e18;

    uint256 constant MAX_NUM_LEVEL_2 = 3477;
    uint256 constant MAX_NUM_LEVEL_3 = 1399;

    uint256 constant NAME_CHANGE_COST = 50 * 1e18;
    uint256 constant BIO_CHANGE_COST = 25 * 1e18;

    uint256 constant MAX_LEN_NAME = 20;
    uint256 constant MAX_LEN_BIO = 35;

    uint256 constant MINT_AND_STAKE_MIN_HOLD_DURATION = 2 days;
    uint256 profileUpdateMinHoldDuration = 30 days;

    mapping(uint256 => string) public mouseName;
    mapping(uint256 => string) public mouseBio;

    string public description;
    string public imagesBaseURI;
    string constant unrevealedURI = 'ipfs://QmW9NKUGYesTiYx5iSP1o82tn4Chq9i1yQV6DBnzznrHTH';

    bool private revealed;
    bytes32 immutable secretHash;

    constructor(bytes32 secretHash_) MadMouseStaking(MAX_SUPPLY, MAX_PER_WALLET) {
        secretHash = secretHash_;
    }

    /* ------------- External ------------- */

    // signatures will be created dynamically
    function mint(
        uint256 amount,
        bytes calldata signature,
        bool stake
    ) external payable noContract {
        if (!publicSaleActive) revert PublicSaleNotActive();
        if (PURCHASE_LIMIT < amount) revert ExceedsLimit();
        if (msg.value != price * amount) revert IncorrectValue();
        if (!validSignature(signature, 0)) revert InvalidSignature();

        _mintAndStake(msg.sender, amount, stake);
    }

    function whitelistMint(
        uint256 amount,
        uint256 limit,
        bytes calldata signature,
        bool stake
    ) external payable noContract {
        if (publicSaleActive) revert WhitelistNotActive();
        if (WHITELIST_PURCHASE_LIMIT < limit) revert SignatureExceedsLimit();
        if (msg.value != whitelistPrice * amount) revert IncorrectValue();
        if (!validSignature(signature, limit)) revert InvalidSignature();

        uint256 numMinted = _userData[msg.sender].numMinted();
        if (numMinted + amount > limit) revert ExceedsLimit();

        _mintAndStake(msg.sender, amount, stake);
    }

    function levelUp(uint256 tokenId) external payable {
        uint256 tokenData = _tokenDataOf(tokenId);
        address owner = tokenData.trueOwner();

        if (owner != msg.sender) revert IncorrectOwner();

        uint256 level = tokenData.level();
        if (level > 2) revert MaxLevelReached();

        if (level == 1) {
            if (totalLevel2Reached >= MAX_NUM_LEVEL_2) revert MaxNumberReached();
            gouda.burnFrom(msg.sender, LEVEL_2_COST);
            ++totalLevel2Reached;
        } else {
            if (totalLevel3Reached >= MAX_NUM_LEVEL_3) revert MaxNumberReached();
            gouda.burnFrom(msg.sender, LEVEL_3_COST);
            ++totalLevel3Reached;
        }

        uint256 newTokenData = tokenData.increaseLevel().resetOwnerCount();

        if (tokenData.staked() && revealed) {
            uint256 userData = _claimReward();
            (userData, newTokenData) = updateDataWhileStaked(userData, tokenId, tokenData, newTokenData);
            _userData[msg.sender] = userData;
        }

        _tokenData[tokenId] = newTokenData;
    }

    function setName(uint256 tokenId, string calldata name) external payable onlyLongtermHolder(tokenId) {
        if (!isValidString(name, MAX_LEN_NAME)) revert InvalidString();

        gouda.burnFrom(msg.sender, NAME_CHANGE_COST);
        mouseName[tokenId] = name;
    }

    function setBio(uint256 tokenId, string calldata bio) external payable onlyLongtermHolder(tokenId) {
        if (!isValidString(bio, MAX_LEN_BIO)) revert InvalidString();

        gouda.burnFrom(msg.sender, BIO_CHANGE_COST);
        mouseBio[tokenId] = bio;
    }

    // only to be used by owner in extreme cases when these reflect negatively on the collection
    // since they are automatically shown in the metadata (on OpenSea)
    function resetName(uint256 tokenId) external payable {
        address _owner = _tokenDataOf(tokenId).trueOwner();
        if (_owner != msg.sender && owner() != msg.sender) revert IncorrectOwner();
        delete mouseName[tokenId];
    }

    function resetBio(uint256 tokenId) external payable {
        address _owner = _tokenDataOf(tokenId).trueOwner();
        if (_owner != msg.sender && owner() != msg.sender) revert IncorrectOwner();
        delete mouseBio[tokenId];
    }

    /* ------------- View ------------- */

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert NonexistentToken();
        if (!revealed || address(metadata) == address(0)) return unrevealedURI;
        return metadata.buildMouseMetadata(tokenId, this.getLevel(tokenId));
    }

    function previewTokenURI(uint256 tokenId, uint256 level) external view returns (string memory) {
        if (!_exists(tokenId)) revert NonexistentToken();
        if (!revealed || address(metadata) == address(0)) return unrevealedURI;
        return metadata.buildMouseMetadata(tokenId, level);
    }

    function getDNA(uint256 tokenId) external view onceRevealed returns (uint256) {
        if (!_exists(tokenId)) revert NonexistentToken();
        return computeDNA(tokenId);
    }

    function getLevel(uint256 tokenId) external view returns (uint256) {
        return _tokenDataOf(tokenId).level();
    }

    /* ------------- Private ------------- */

    function validSignature(bytes calldata signature, uint256 limit) private view returns (bool) {
        bytes32 msgHash = keccak256(abi.encode(address(this), msg.sender, limit));
        return msgHash.toEthSignedMessageHash().recover(signature) == signerAddress;
    }

    // not guarded for reveal
    function computeDNA(uint256 tokenId) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(randomSeed, tokenId)));
    }

    /* ------------- Owner ------------- */

    function setPublicSaleActive(bool active) external payable onlyOwner {
        publicSaleActive = active;
    }

    function setProfileUpdateMinHoldDuration(uint256 duration) external payable onlyOwner {
        profileUpdateMinHoldDuration = duration;
    }

    function giveAway(address[] calldata to) external payable onlyOwner {
        for (uint256 i; i < to.length; ++i) _mintAndStake(to[i], 1, false);
    }

    function setSignerAddress(address address_) external payable onlyOwner {
        signerAddress = address_;
    }

    function setMetadataAddress(MadMouseMetadata metadata_) external payable onlyOwner {
        metadata = metadata_;
    }

    function withdraw() external payable onlyOwner {
        uint256 balance = address(this).balance;
        multiSigTreasury.call{value: balance}('');
    }

    function recoverToken(IERC20 token) external payable onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function setDescription(string memory description_) external payable onlyOwner {
        description = description_;
    }

    // requires that the reveal is first done through chainlink vrf
    function setImagesBaseURI(string memory uri) external payable onlyOwner onceRevealed {
        imagesBaseURI = uri;
    }

    // extra security for reveal:
    // the owner sets a hash of a secret seed
    // once chainlink randomness fulfills, the secret is revealed and shifts the secret seed set by chainlink
    // Why? The final randomness should come from a trusted third party,
    // however devs need time to generate the collection from the metadata.
    // There is a time-frame in which an unfair advantage is gained after the seed is set and before the metadata is revealed.
    // This eliminates any possibility of the team generating an unfair seed and any unfair advantage by snipers.
    function reveal(string memory _imagesBaseURI, bytes32 secretSeed_) external payable onlyOwner whenRandomSeedSet {
        if (revealed) revert CollectionAlreadyRevealed();
        if (secretHash != keccak256(abi.encode(secretSeed_))) revert IncorrectHash();

        revealed = true;
        imagesBaseURI = _imagesBaseURI;
        _shiftRandomSeed(uint256(secretSeed_));
    }

    /* ------------- Hooks ------------- */

    // update role, level information when staking
    function _beforeStakeDataTransform(
        uint256 tokenId,
        uint256 userData,
        uint256 tokenData
    ) internal view override returns (uint256, uint256) {
        // assumption that mint&stake won't have revealed yet
        if (!tokenData.mintAndStake() && tokenData.role() == 0 && revealed)
            tokenData = tokenData.setRoleAndRarity(computeDNA(tokenId));
        userData = userData.updateUserDataStake(tokenData);
        return (userData, tokenData);
    }

    function _beforeUnstakeDataTransform(
        uint256,
        uint256 userData,
        uint256 tokenData
    ) internal view override returns (uint256, uint256) {
        userData = userData.updateUserDataUnstake(tokenData);
        if (tokenData.mintAndStake() && block.timestamp - tokenData.lastTransfer() < MINT_AND_STAKE_MIN_HOLD_DURATION)
            revert MintAndStakeMinHoldDurationNotReached();
        return (userData, tokenData);
    }

    function updateStakedTokenData(uint256[] calldata tokenIds) external payable onceRevealed {
        uint256 userData = _claimReward();
        uint256 tokenId;
        uint256 tokenData;
        for (uint256 i; i < tokenIds.length; ++i) {
            tokenId = tokenIds[i];
            tokenData = _tokenDataOf(tokenId);

            if (tokenData.trueOwner() != msg.sender) revert IncorrectOwner();
            if (!tokenData.staked()) revert TokenIdUnstaked(); // only useful for staked ids
            if (tokenData.role() != 0) revert TokenDataAlreadySet();

            (userData, tokenData) = updateDataWhileStaked(userData, tokenId, tokenData, tokenData);

            _tokenData[tokenId] = tokenData;
        }
        _userData[msg.sender] = userData;
    }

    // note: must be guarded by check for revealed
    function updateDataWhileStaked(
        uint256 userData,
        uint256 tokenId,
        uint256 oldTokenData,
        uint256 newTokenData
    ) private view returns (uint256, uint256) {
        uint256 userDataX;
        // add in the role and rarity data if not already
        uint256 tokenDataX = newTokenData.role() != 0
            ? newTokenData
            : newTokenData.setRoleAndRarity(computeDNA(tokenId));

        // update userData as if to unstake with old tokenData and stake with new tokenData
        userDataX = userData.updateUserDataUnstake(oldTokenData).updateUserDataStake(tokenDataX);
        return applySafeDataTransform(userData, newTokenData, userDataX, tokenDataX);
    }

    // simulates a token update and only returns ids != 0 if
    // the user gets a bonus increase upon updating staked data
    function shouldUpdateStakedIds(address user) external view returns (uint256[] memory) {
        if (!revealed) return new uint256[](0);

        uint256[] memory stakedIds = this.tokenIdsOf(user, 1);

        uint256 userData = _userData[user];
        uint256 oldTotalBonus = totalBonus(user, userData);

        uint256 tokenData;
        for (uint256 i; i < stakedIds.length; ++i) {
            tokenData = _tokenDataOf(stakedIds[i]);
            if (tokenData.role() == 0)
                (userData, ) = updateDataWhileStaked(userData, stakedIds[i], tokenData, tokenData);
            else stakedIds[i] = 0;
        }

        uint256 newTotalBonus = totalBonus(user, userData);

        return (newTotalBonus > oldTotalBonus) ? stakedIds : new uint256[](0);
    }

    /* ------------- Modifier ------------- */

    modifier onceRevealed() {
        if (!revealed) revert CollectionNotRevealed();
        _;
    }

    modifier noContract() {
        if (tx.origin != msg.sender) revert ContractCallNotAllowed();
        _;
    }

    modifier onlyLongtermHolder(uint256 tokenId) {
        uint256 tokenData = _tokenDataOf(tokenId);
        uint256 timeHeld = block.timestamp - tokenData.lastTransfer();

        if (tokenData.trueOwner() != msg.sender) revert IncorrectOwner();
        if (timeHeld < profileUpdateMinHoldDuration) revert MinHoldDurationRequired();
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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
pragma solidity ^0.8.0;

error CallerIsNotTheOwner();

abstract contract Ownable {
    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) revert CallerIsNotTheOwner();
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@chainlink/contracts/src/v0.8/VRFConsumerBase.sol';
import './Ownable.sol';

error RandomSeedNotSet();
error RandomSeedAlreadySet();

contract VRFBase is VRFConsumerBase, Ownable {
    bytes32 private immutable keyHash;
    uint256 private immutable fee;

    uint256 public randomSeed;

    constructor(
        bytes32 keyHash_,
        uint256 fee_,
        address vrfCoordinator_,
        address link_
    ) VRFConsumerBase(vrfCoordinator_, link_) {
        keyHash = keyHash_;
        fee = fee_;
    }

    /* ------------- Owner ------------- */

    function requestRandomSeed() external payable virtual onlyOwner whenRandomSeedUnset {
        requestRandomness(keyHash, fee);
    }

    // this function should not be needed and is just an emergency fail-safe if
    // for some reason chainlink is not able to fulfill the randomness callback
    function forceFulfillRandomness() external payable virtual onlyOwner whenRandomSeedUnset {
        randomSeed = uint256(blockhash(block.number - 1));
    }

    /* ------------- Internal ------------- */

    function fulfillRandomness(bytes32, uint256 randomNumber) internal virtual override {
        randomSeed = randomNumber;
    }

    function _shiftRandomSeed(uint256 randomNumber) internal {
        randomSeed = uint256(keccak256(abi.encode(randomSeed, randomNumber)));
    }

    /* ------------- View ------------- */

    function randomSeedSet() public view returns (bool) {
        return randomSeed > 0;
    }

    /* ------------- Modifier ------------- */

    modifier whenRandomSeedSet() {
        if (!randomSeedSet()) revert RandomSeedNotSet();
        _;
    }

    modifier whenRandomSeedUnset() {
        if (randomSeedSet()) revert RandomSeedAlreadySet();
        _;
    }
}

// get your shit together Chainlink...
contract VRFBaseMainnet is
    VRFBase(
        0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445,
        2 * 1e18,
        0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,
        0x514910771AF9Ca656af840dff83E8264EcF986CA
    )
{

}

contract VRFBaseRinkeby is
    VRFBase(
        0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311,
        0.1 * 1e18,
        0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B,
        0x01BE23585060835E02B77ef475b0Cc51aA1e0709
    )
{}

contract VRFBaseMumbai is
    VRFBase(
        0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4,
        0.0001 * 1e18,
        0x8C7382F9D8f56b33781fE506E897a4F1e2d17255,
        0x326C977E6efc84E512bB9C30f76E30c160eD06FB
    )
{}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract Gouda is ERC20, AccessControl {
    bytes32 constant MINT_AUTHORITY = keccak256('MINT_AUTHORITY');
    bytes32 constant BURN_AUTHORITY = keccak256('BURN_AUTHORITY');
    bytes32 constant TREASURY = keccak256('TREASURY');

    address public multiSigTreasury = 0xFB79a928C5d6c5932Ba83Aa8C7145cBDCDb9fd2E;

    constructor(address madmouse) ERC20('Gouda', 'GOUDA') {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setupRole(MINT_AUTHORITY, madmouse);
        _setupRole(BURN_AUTHORITY, madmouse);
        _setupRole(TREASURY, multiSigTreasury);

        _mint(multiSigTreasury, 200_000 * 1e18);
    }

    /* ------------- Restricted ------------- */

    function mint(address user, uint256 amount) external onlyRole(MINT_AUTHORITY) {
        _mint(user, amount);
    }

    /* ------------- ERC20Burnable ------------- */

    function burnFrom(address account, uint256 amount) public {
        if (!hasRole(BURN_AUTHORITY, msg.sender)) _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import './Gouda.sol';
import './MadMouse.sol';
import './MadMouseStaking.sol';
import './lib/Base64.sol';
import './lib/MetadataEncode.sol';
import './lib/Ownable.sol';

contract MadMouseMetadata is Ownable {
    using Strings for uint256;
    using MetadataEncode for bytes;
    using TokenDataOps for uint256;
    using DNAOps for uint256;

    struct Mouse {
        string role;
        string rarity;
        string fur;
        string expression;
        string glasses;
        string hat;
        string body;
        string background;
        string makeup;
        string scene;
    }

    uint256 constant CLOWN = 0;
    uint256 constant MAGICIAN = 1;
    uint256 constant JUGGLER = 2;
    uint256 constant TRAINER = 3;
    uint256 constant PERFORMER = 4;

    /* ------------- Traits ------------- */

    // ["Clown", "Magician", "Juggler", "Trainer", "Performer"]
    bytes constant ROLE = hex'436c6f776e004d6167696369616e004a7567676c657200547261696e657200506572666f726d6572';

    // ["Common", "Rare", "Super", "Ultra"]
    bytes constant RARITIES = hex'436f6d6d6f6e005261726500537570657200556c747261';

    // ["Ghost", "Gold", "Lava", "Panther", "Camo", "Blue-Pink", "White", "Pink", "Brown", "Dark Brown", "Green", "Grey", "Ice", "Purple", "Red"]
    bytes constant FUR =
        hex'47686f737400476f6c64004c6176610050616e746865720043616d6f00426c75652d50696e6b0057686974650050696e6b0042726f776e004461726b2042726f776e00477265656e00477265790049636500507572706c6500526564';

    // ["Awkward", "Angry", "Bored", "Confused", "Grimaced", "Loving", "Laughing", "Sad", "Shy", "Stupid", "Whistling"]
    bytes constant EXPRESSION =
        hex'41776b7761726400416e67727900426f72656400436f6e6675736564004772696d61636564004c6f76696e67004c61756768696e670053616400536879005374757069640057686973746c696e67';

    // ["Purple", "Green", "Blue", "Light Blue", "Red", "Yellow", "Light Green", "Pink", "Orange", "Throne", "Star Ring", "Colosseum"]
    bytes constant BACKGROUND =
        hex'507572706c6500477265656e00426c7565004c6967687420426c7565005265640059656c6c6f77004c6967687420477265656e0050696e6b004f72616e6765005468726f6e6500537461722052696e6700436f6c6f737365756d';

    // ["Black", "White", "Blue", "Kimono", "Toge", "Cowboy", "Guard", "Farmer", "Napoleon", "King", "Jumper", "Sailor", "Pirate", "Mexican", "Robin Hood", "Elf", "Viking", "Vampire", "Crocodile", "Asian", "Showman", "Genie", "Barong"]
    bytes constant BODY =
        hex'426c61636b00576869746500426c7565004b696d6f6e6f00546f676500436f77626f79004775617264004661726d6572004e61706f6c656f6e004b696e67004a756d706572005361696c6f7200506972617465004d65786963616e00526f62696e20486f6f6400456c660056696b696e670056616d706972650043726f636f64696c6500417369616e0053686f776d616e0047656e6965004261726f6e67';

    // ["None", "Black", "White", "Jester", "Sakat", "Laurel", "Cowboy", "Guard", "Farmer", "Napoleon", "Crown", "Helicopter", "Sailor", "Pirate", "Mexican", "Robin Hood", "Elf", "Viking", "Halo", "Crocodile", "Asian", "Showman", "Genie", "Salakot"]
    bytes constant HAT =
        hex'4e6f6e6500426c61636b005768697465004a65737465720053616b6174004c617572656c00436f77626f79004775617264004661726d6572004e61706f6c656f6e0043726f776e0048656c69636f70746572005361696c6f7200506972617465004d65786963616e00526f62696e20486f6f6400456c660056696b696e670048616c6f0043726f636f64696c6500417369616e0053686f776d616e0047656e69650053616c616b6f74';

    // ["None", "Red", "Green", "Yellow", "Vyper", "Thief", "Cyber", "Rainbow", "3D", "Thug", "Gold", "Monocle", "Manga", "Black", "Ray Black", "Blue", "Purple", "Cat Mask"]
    bytes constant GLASSES =
        hex'4e6f6e650052656400477265656e0059656c6c6f77005679706572005468696566004379626572005261696e626f77003344005468756700476f6c64004d6f6e6f636c65004d616e676100426c61636b0052617920426c61636b00426c756500507572706c6500436174204d61736b';

    // ["Clown 1", "Clown 2", "Clown 3", "Clown 4", "Clown 5", "Clown 6", "Clown 7", "Clown 8", "Clown 9"]
    bytes constant CLOWN_MAKEUP =
        hex'436c6f776e203100436c6f776e203200436c6f776e203300436c6f776e203400436c6f776e203500436c6f776e203600436c6f776e203700436c6f776e203800436c6f776e2039';

    // ["Pie", "Balloons", "Twisted Balloons", "Jack in the Box", "Water Spray", "Puppets", "String", "Little Pierre", "Little Murphy"]
    bytes constant CLOWN_BODY_LEVEL_2 =
        hex'5069650042616c6c6f6f6e7300547769737465642042616c6c6f6f6e73004a61636b20696e2074686520426f78005761746572205370726179005075707065747300537472696e67004c6974746c6520506965727265004c6974746c65204d7572706879';

    // ["Purple Wig", "Rainbow Wig", "Blue Wig", "Teal Wig", "Red Wig", "Green Wig", "Harlequin", "Black Beret", "Blue Beret"]
    bytes constant CLOWN_WIG_LEVEL_2 =
        hex'507572706c6520576967005261696e626f772057696700426c756520576967005465616c20576967005265642057696700477265656e20576967004861726c657175696e00426c61636b20426572657400426c7565204265726574';

    // ["Pie Master", "Balloon Master", "Twisted Balloon Master", "Jack in the Box Master", "Rainbow Flow", "Puppet Master", "String Master", "Pierre", "Murphy"]
    bytes constant CLOWN_BODY_LEVEL_3 =
        hex'506965204d61737465720042616c6c6f6f6e204d617374657200547769737465642042616c6c6f6f6e204d6173746572004a61636b20696e2074686520426f78204d6173746572005261696e626f7720466c6f7700507570706574204d617374657200537472696e67204d617374657200506965727265004d7572706879';

    // ["Blue Poster", "Up!", "Red Poster", "Dance Floor", "Red Curtains", "Puppets", "Stadium", "Paris", "New York"]
    bytes constant CLOWN_BACKGROUND_LEVEL_3 =
        hex'426c756520506f73746572005570210052656420506f737465720044616e636520466c6f6f7200526564204375727461696e730050757070657473005374616469756d005061726973004e657720596f726b';

    // ["Hatter", "Card", "Wizard", "Pento", "Fortune", "Fantasy", "Majestic", "Prisoner"]
    bytes constant MAGICIAN_HAT =
        hex'48617474657200436172640057697a6172640050656e746f00466f7274756e650046616e74617379004d616a657374696300507269736f6e6572';

    // ["Doves", "Cards", "Wand", "Rabbit", "Crystal", "Levitation", "Saw", "Handcuffed"]
    bytes constant MAGICIAN_BODY_LEVEL_2 =
        hex'446f7665730043617264730057616e6400526162626974004372797374616c004c657669746174696f6e005361770048616e64637566666564';

    // ["Phoenix", "Card Master", "Wand Master", "Rainbow", "Snow Globe", "Levitation Master", "Grater", "Cement"]
    bytes constant MAGICIAN_BODY_LEVEL_3 =
        hex'50686f656e69780043617264204d61737465720057616e64204d6173746572005261696e626f7700536e6f7720476c6f6265004c657669746174696f6e204d6173746572004772617465720043656d656e74';

    // ["Blue Curtains", "Pink Poster", "Sky", "Hills", "Snow", "Space", "Factory", "Construction Site"]
    bytes constant MAGICIAN_BACKGROUND_LEVEL_3 =
        hex'426c7565204375727461696e730050696e6b20506f7374657200536b790048696c6c7300536e6f7700537061636500466163746f727900436f6e737472756374696f6e2053697465';

    // ["None", "Fairy Mouse", "Flying Key", "Owl", "Flying Pot", "Little Mouse", "Light Aura", "Book"]
    bytes constant MAGICIAN_SCENE_LEVEL_3 =
        hex'4e6f6e65004661697279204d6f75736500466c79696e67204b6579004f776c00466c79696e6720506f74004c6974746c65204d6f757365004c69676874204175726100426f6f6b';

    // ["Juggling Balls", "Clubs", "Knives", "Hoops", "Spinning Plate", "Bolas", "Diabolo", "Slinky"]
    bytes constant JUGGLER_BODY =
        hex'4a7567676c696e672042616c6c7300436c756273004b6e6976657300486f6f7073005370696e6e696e6720506c61746500426f6c617300446961626f6c6f00536c696e6b79';

    // ["Juggling Ball Scholar", "Club Scholar", "Knife Scholar", "Hoop Scholar", "Spinning Plate Scholar", "Bolas Scholar", "Diabolo Scholar", "Slinky Scholar"]
    bytes constant JUGGLER_BODY_LEVEL_2 =
        hex'4a7567676c696e672042616c6c205363686f6c617200436c7562205363686f6c6172004b6e696665205363686f6c617200486f6f70205363686f6c6172005370696e6e696e6720506c617465205363686f6c617200426f6c6173205363686f6c617200446961626f6c6f205363686f6c617200536c696e6b79205363686f6c6172';

    // ["Juggling Ball Master", "Club Master", "Knife Master", "Hoop Master", "Spinning Plate Master", "Bolas Master", "Diabolo Master", "Slinky Master"]
    bytes constant JUGGLER_BODY_LEVEL_3 =
        hex'4a7567676c696e672042616c6c204d617374657200436c7562204d6173746572004b6e696665204d617374657200486f6f70204d6173746572005370696e6e696e6720506c617465204d617374657200426f6c6173204d617374657200446961626f6c6f204d617374657200536c696e6b79204d6173746572';

    // ["Spotlight Top", "Manor", "Target", "Forest", "Spotlight Green-Pink", "Desert", "Fireworks", "Shadow"]
    bytes constant JUGGLER_BACKGROUND_LEVEL_3 =
        hex'53706f746c6967687420546f70004d616e6f720054617267657400466f726573740053706f746c6967687420477265656e2d50696e6b004465736572740046697265776f726b7300536861646f77';

    // ["Gecko", "Cat", "Chimp", "Turtle", "Donkey", "Teddy Bear", "Seal", "Baby Dodo"]
    bytes constant TRAINER_PET =
        hex'4765636b6f00436174004368696d7000547572746c6500446f6e6b65790054656464792042656172005365616c004261627920446f646f';

    // ["Blue Whip", "Red Hoop", "Banana", "Green Whip", "Horse Whip", "Honey", "Fish", "Blue Hoop"]
    bytes constant TRAINER_BODY_LEVEL_2 =
        hex'426c756520576869700052656420486f6f700042616e616e6100477265656e205768697000486f727365205768697000486f6e6579004669736800426c756520486f6f70';

    // ["Crocodile", "Tiger", "Monkey", "Komodo", "Horse", "Bear", "Otaria", "Dodo"]
    bytes constant TRAINER_PET_LEVEL_2 =
        hex'43726f636f64696c65005469676572004d6f6e6b6579004b6f6d6f646f00486f7273650042656172004f746172696100446f646f';

    // ["Light Whip", "Fire Hoop", "Bananas", "Rainbow Whip", "Uniwhip", "Bamboo", "Fish Feast", "Rainbow Hoop"]
    bytes constant TRAINER_BODY_LEVEL_3 =
        hex'4c696768742057686970004669726520486f6f700042616e616e6173005261696e626f77205768697000556e69776869700042616d626f6f0046697368204665617374005261696e626f7720486f6f70';

    // ["T-Rex", "Lion", "Gorilla", "Dragon", "Unicorn", "Panda", "Walrus", "Peacock"]
    bytes constant TRAINER_PET_LEVEL_3 =
        hex'542d526578004c696f6e00476f72696c6c6100447261676f6e00556e69636f726e0050616e64610057616c72757300506561636f636b';

    // ["Tent", "Red Ring", "Green Ring", "Castle", "Lake", "Bamboo", "Grey Ring", "Peacock"]
    bytes constant TRAINER_BACKGROUND_LEVEL_3 =
        hex'54656e74005265642052696e6700477265656e2052696e6700436173746c65004c616b650042616d626f6f00477265792052696e6700506561636f636b';

    // ["Hula Hoop", "Rolla Bolla", "Monocycle", "Aerial Hoop", "None", "Swing", "Dumbbells", "Trampoline"]
    bytes constant PERFORMER_SCENE =
        hex'48756c6120486f6f7000526f6c6c6120426f6c6c61004d6f6e6f6379636c650041657269616c20486f6f70004e6f6e65005377696e670044756d6262656c6c73005472616d706f6c696e65';

    // ["Trickster", "Rolla Bolla", "Funambulist", "Trapezist", "Pendulum Master", "Dancer", "Mr Muscle", "Trampoline"]
    bytes constant PERFORMER_BODY_LEVEL_2 =
        hex'547269636b7374657200526f6c6c6120426f6c6c610046756e616d62756c6973740054726170657a6973740050656e64756c756d204d61737465720044616e636572004d72204d7573636c65005472616d706f6c696e65';

    // ["Hula Hoop Trickster", "Tower", "Funambulist", "Trapezist Twins", "None", "Tap Dance", "Dumbbell Stand", "Cody"]
    bytes constant PERFORMER_SCENE_LEVEL_2 =
        hex'48756c6120486f6f7020547269636b7374657200546f7765720046756e616d62756c6973740054726170657a697374205477696e73004e6f6e65005461702044616e63650044756d6262656c6c205374616e6400436f6479';

    // ["Chairman", "Skater", "Daredevil", "Megaphone", "None", "Virtuoso", "Hercules", "Canonist"]
    bytes constant PERFORMER_BODY_LEVEL_3 =
        hex'43686169726d616e00536b617465720044617265646576696c004d65676170686f6e65004e6f6e650056697274756f736f0048657263756c65730043616e6f6e697374';

    // ["Pyramid", "Skater", "Daredevil", "Firestar", "None", "Salsa", "Barbell", "Canonman"]
    bytes constant PERFORMER_SCENE_LEVEL_3 =
        hex'507972616d696400536b617465720044617265646576696c004669726573746172004e6f6e650053616c73610042617262656c6c0043616e6f6e6d616e';

    // ["Red Podium", "Half-Pipe", "Blue Podium", "Dark Tent", "Mesmerized", "Stage", "Hercules Poster", "Purple Ring"]
    bytes constant PERFORMER_BACKGROUND_LEVEL_3 =
        hex'52656420506f6469756d0048616c662d5069706500426c756520506f6469756d004461726b2054656e74004d65736d6572697a65640053746167650048657263756c657320506f7374657200507572706c652052696e67';

    /* ------------- Rarities ------------- */

    // [9, 9, 14, 14, 14, 14, 17, 18, 21, 21, 21, 21, 21, 21, 21]
    uint256 constant WEIGHTS_FUR = 0x00000000000000000000000000000000001515151515151512110e0e0e0e0909;

    // [63, 14, 14, 14, 5, 14, 5, 5, 14, 14, 14, 14, 5, 14, 14, 14, 14, 5]
    uint256 constant WEIGHTS_GLASSES = 0x0000000000000000000000000000050e0e0e0e050e0e0e0e05050e050e0e0e3f;

    // [8, 8, 8, 15, 15, 15, 15, 15, 8, 2, 15, 15, 15, 15, 15, 15, 3, 3, 3, 15, 3, 15, 15]
    uint256 constant WEIGHTS_BODY = 0x0000000000000000000f0f030f0303030f0f0f0f0f0f02080f0f0f0f0f080808;

    // [25, 25, 25, 25, 25, 25, 25, 25, 25, 10, 11, 10]
    uint256 constant WEIGHTS_BACKGROUND = 0x00000000000000000000000000000000000000000a0b0a191919191919191919;

    // [13, 8, 8, 8, 14, 14, 14, 14, 14, 8, 3, 14, 14, 14, 14, 14, 14, 3, 3, 3, 14, 3, 14, 14]
    uint256 constant WEIGHTS_HAT = 0x00000000000000000e0e030e0303030e0e0e0e0e0e03080e0e0e0e0e0808080d;

    /* ------------- External ------------- */

    MadMouse public madmouse;

    function setMadMouseAddress(MadMouse madmouse_) external onlyOwner {
        madmouse = madmouse_;
    }

    // will act as an ERC721 proxy
    function balanceOf(address user) external view returns (uint256) {
        return madmouse.numOwned(user);
    }

    function buildMouseMetadata(uint256 tokenId, uint256 level) external view returns (string memory) {
        return string.concat('data:application/json;base64,', Base64.encode(bytes(mouseMetadataJSON(tokenId, level))));
    }

    /* ------------- Json ------------- */

    function getMouse(uint256 dna, uint256 level) private pure returns (Mouse memory mouse) {
        uint256 dnaRole = dna & 0xFF;
        uint256 dnaFur = (dna >> 8) & 0xFF;
        uint256 dnaClass = (dna >> 16) & 0xFF;
        uint256 dnaExpression = (dna >> 24) & 0xFF;
        uint256 dnaGlasses = (dna >> 32) & 0xFF;
        uint256 dnaBody = (dna >> 40) & 0xFF;
        uint256 dnaBackground = (dna >> 48) & 0xFF;
        uint256 dnaHat = (dna >> 56) & 0xFF;
        uint256 dnaSpecial = (dna >> 64) & 0xFF;

        uint256 role = dnaRole % 5;

        mouse.role = ROLE.decode(role);
        mouse.rarity = RARITIES.decode(dna.toRarity());
        mouse.fur = FUR.selectWeighted(dnaFur, WEIGHTS_FUR);
        mouse.expression = EXPRESSION.decode(dnaExpression % 11);
        mouse.glasses = GLASSES.selectWeighted(dnaGlasses, WEIGHTS_GLASSES);
        mouse.body = BODY.selectWeighted(dnaBody, WEIGHTS_BODY);
        mouse.background = BACKGROUND.selectWeighted(dnaBackground, WEIGHTS_BACKGROUND);
        mouse.hat = HAT.selectWeighted(dnaHat, WEIGHTS_HAT);

        uint256 class;

        if (role == CLOWN) {
            class = dnaClass % 9;

            mouse.makeup = CLOWN_MAKEUP.decode(class);

            if (level == 2) mouse.body = CLOWN_BODY_LEVEL_2.decode(class);
            if (level >= 2) {
                uint256 hat = dnaHat % 9;
                if (hat == 6) hat = class;
                mouse.hat = CLOWN_WIG_LEVEL_2.decode(hat);
            }

            if (level == 3) mouse.body = CLOWN_BODY_LEVEL_3.decode(class);
            if (level == 3) {
                uint256 backgroundType = dnaBackground % 9;
                if (backgroundType == 6) mouse.background = CLOWN_BACKGROUND_LEVEL_3.decode(class);
                else mouse.background = CLOWN_BACKGROUND_LEVEL_3.decode(backgroundType);
            }
        }

        if (role == MAGICIAN) {
            class = dnaClass % 8;

            mouse.hat = MAGICIAN_HAT.decode(class);

            if (level == 2) mouse.body = MAGICIAN_BODY_LEVEL_2.decode(class);

            if (level == 3) mouse.body = MAGICIAN_BODY_LEVEL_3.decode(class);
            if (level == 3) {
                uint256 sceneType = dnaSpecial % 8;
                if (class == 1 && (sceneType < 4 || 6 < sceneType)) sceneType = 4;
                mouse.scene = MAGICIAN_SCENE_LEVEL_3.decode(sceneType);
            }
            if (level == 3) {
                uint256 backgroundType = dnaBackground % 8;
                if (backgroundType == 6) mouse.background = MAGICIAN_BACKGROUND_LEVEL_3.decode(class);
                else mouse.background = MAGICIAN_BACKGROUND_LEVEL_3.decode(backgroundType);
            }
        }

        if (role == JUGGLER) {
            class = dnaClass % 8;

            if (level == 1) mouse.body = JUGGLER_BODY.decode(class);

            if (level == 2) mouse.body = JUGGLER_BODY_LEVEL_2.decode(class);

            if (level == 3) mouse.body = JUGGLER_BODY_LEVEL_3.decode(class);
            if (level == 3) {
                uint256 backgroundType = dnaBackground % 8;
                if (backgroundType == 2) mouse.background = JUGGLER_BACKGROUND_LEVEL_3.decode(class);
                else mouse.background = JUGGLER_BACKGROUND_LEVEL_3.decode(backgroundType);
            }
        }

        if (role == TRAINER) {
            class = dnaClass % 8;

            if (level == 1) mouse.scene = TRAINER_PET.decode(class);

            if (level == 2) mouse.body = TRAINER_BODY_LEVEL_2.decode(class);
            if (level == 2) mouse.scene = TRAINER_PET_LEVEL_2.decode(class);

            if (level == 3) mouse.body = TRAINER_BODY_LEVEL_3.decode(class);
            if (level == 3) mouse.scene = TRAINER_PET_LEVEL_3.decode(class);
            if (level == 3) {
                uint256 backgroundType = dnaBackground % 8;
                if (backgroundType == 7) mouse.background = TRAINER_BACKGROUND_LEVEL_3.decode(class);
                else mouse.background = TRAINER_BACKGROUND_LEVEL_3.decode(backgroundType);
            }
        }

        if (role == PERFORMER) {
            class = dnaClass % 8;

            if (level >= 1) {
                if (class == 4) mouse.body = 'Hypnotist';
                else mouse.scene = PERFORMER_SCENE.decode(class);
            }

            if (level >= 2) mouse.body = PERFORMER_BODY_LEVEL_2.decode(class);
            if (level >= 2 && class != 4) mouse.scene = PERFORMER_SCENE_LEVEL_2.decode(class);

            if (level == 3) {
                if (class != 4) mouse.body = PERFORMER_BODY_LEVEL_3.decode(class);
                if (class != 4) mouse.scene = PERFORMER_SCENE_LEVEL_3.decode(class);
                if (class == 4) mouse.glasses = 'Hypnotist';
            }
            if (level == 3) {
                uint256 backgroundType = dnaBackground % 8;
                if (backgroundType == 1 || backgroundType == 4 || backgroundType == 5 || backgroundType == 6)
                    mouse.background = PERFORMER_BACKGROUND_LEVEL_3.decode(class);
                else mouse.background = PERFORMER_BACKGROUND_LEVEL_3.decode(backgroundType);
            }
        }
    }

    function mouseMetadataJSON(uint256 tokenId, uint256 level) private view returns (string memory) {
        uint256 dna = madmouse.getDNA(tokenId);

        bool mintAndStake = madmouse._tokenDataOf(tokenId).mintAndStake();

        string memory name = madmouse.mouseName(tokenId);
        string memory bio = madmouse.mouseBio(tokenId);

        if (bytes(name).length == 0) name = string.concat('Mad Mouse #', tokenId.toString());
        if (bytes(bio).length == 0) bio = madmouse.description();

        string memory imageURI = string.concat(
            madmouse.imagesBaseURI(),
            ((level - 1) * 10_000 + tokenId).toString(),
            '.png'
        );

        string memory baseData = string.concat(
            MetadataEncode.keyValueString('name', name),
            MetadataEncode.keyValueString('description', bio),
            MetadataEncode.keyValueString('image', imageURI),
            MetadataEncode.keyValue('id', tokenId.toString()),
            MetadataEncode.keyValueString('dna', dna.toHexString())
        );

        string memory result = string.concat(
            '{',
            baseData,
            MetadataEncode.keyValueString('OG', mintAndStake ? 'Staker' : ''),
            MetadataEncode.attributes(getAttributesList(dna, level)),
            '}'
        );

        return result;
    }

    function getAttributesList(uint256 dna, uint256 level) private pure returns (string memory) {
        Mouse memory mouse = getMouse(dna, level);

        string memory attributes = string.concat(
            MetadataEncode.attribute('Level', level.toString()),
            MetadataEncode.attributeString('Role', mouse.role),
            MetadataEncode.attributeString('Rarity', mouse.rarity),
            MetadataEncode.attributeString('Background', mouse.background),
            MetadataEncode.attributeString('Scene', mouse.scene),
            MetadataEncode.attributeString('Fur', mouse.fur)
        );

        attributes = string.concat(
            attributes,
            MetadataEncode.attributeString('Expression', mouse.expression),
            MetadataEncode.attributeString('Glasses', mouse.glasses),
            MetadataEncode.attributeString('Hat', mouse.hat),
            MetadataEncode.attributeString('Makeup', mouse.makeup),
            MetadataEncode.attributeString('Body', mouse.body, false)
        );

        return attributes;
    }

    // function getOGStatus(uint256 ownerCount) private pure returns (string memory) {
    //     return
    //         ownerCount == 1 ? MetadataEncode.keyValueString('OG', 'Minter') : ownerCount == 2
    //             ? MetadataEncode.keyValueString('OG', 'Hodler')
    //             : '';
    // }

    // function getHodlerStatus(uint256 timestamp) private view returns (string memory) {
    //     return
    //         (block.timestamp - timestamp) > 69 days
    //             ? MetadataEncode.keyValueString('HODLER LEVEL', 'Diamond Handed')
    //             : '';
    // }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Gouda.sol';
import './lib/ERC721M.sol';
import './lib/Ownable.sol';

error InvalidBoostToken();
error TransferFailed();
error BoostInEffect();
error NotSpecialGuestOwner();
error SpecialGuestIndexMustDiffer();

abstract contract MadMouseStaking is ERC721M, Ownable {
    using UserDataOps for uint256;

    event BoostActivation(address token);

    Gouda public gouda;

    uint256 constant dailyReward = 1e18;

    uint256 constant ROLE_BONUS_3 = 2000;
    uint256 constant ROLE_BONUS_5 = 3500;
    uint256 constant TOKEN_BONUS = 1000;
    uint256 constant TIME_BONUS = 1000;
    uint256 constant RARITY_BONUS = 1000;
    uint256 constant OG_BONUS = 2000;
    uint256 constant SPECIAL_GUEST_BONUS = 1000;

    uint256 immutable OG_BONUS_END;
    uint256 immutable LAST_GOUDA_EMISSION_DATE;

    uint256 constant TOKEN_BOOST_DURATION = 9 days;
    uint256 constant TOKEN_BOOST_COOLDOWN = 9 days;
    uint256 constant TIME_BONUS_STAKE_DURATION = 30 days;

    mapping(IERC20 => uint256) tokenBoostCosts;
    mapping(uint256 => IERC721) specialGuests;
    mapping(IERC721 => bytes4) specialGuestsNumStakedSelector;

    address constant burnAddress = 0x000000000000000000000000000000000000dEaD;

    constructor(uint256 maxSupply_, uint256 maxPerWallet_)
        ERC721M('MadMouseCircus', 'MMC', 1, maxSupply_, maxPerWallet_)
    {
        OG_BONUS_END = block.timestamp + 60 days;
        LAST_GOUDA_EMISSION_DATE = block.timestamp + 5 * 365 days;
    }

    /* ------------- External ------------- */

    function burnForBoost(IERC20 token) external payable {
        uint256 userData = _claimReward();

        uint256 boostCost = tokenBoostCosts[token];
        if (boostCost == 0) revert InvalidBoostToken();

        bool success = token.transferFrom(msg.sender, burnAddress, boostCost);
        if (!success) revert TransferFailed();

        uint256 boostStart = userData.boostStart();
        if (boostStart + TOKEN_BOOST_DURATION + TOKEN_BOOST_COOLDOWN > block.timestamp) revert BoostInEffect();

        _userData[msg.sender] = userData.setBoostStart(block.timestamp);

        emit BoostActivation(address(token));
    }

    function claimSpecialGuest(uint256 collectionIndex) external payable {
        uint256 userData = _claimReward();
        uint256 specialGuestIndexOld = userData.specialGuestIndex();

        if (collectionIndex == specialGuestIndexOld) revert SpecialGuestIndexMustDiffer();
        if (collectionIndex != 0 && !hasSpecialGuest(msg.sender, collectionIndex)) revert NotSpecialGuestOwner();

        _userData[msg.sender] = userData.setSpecialGuestIndex(collectionIndex);
    }

    function clearSpecialGuestData() external payable {
        _userData[msg.sender] = _userData[msg.sender].setSpecialGuestIndex(0);
    }

    /* ------------- Internal ------------- */

    function tokenBonus(uint256 userData) private view returns (uint256) {
        unchecked {
            uint256 lastClaimed = userData.lastClaimed();
            uint256 boostEnd = userData.boostStart() + TOKEN_BOOST_DURATION;

            if (lastClaimed > boostEnd) return 0;
            if (block.timestamp <= boostEnd) return TOKEN_BONUS;

            // follows: lastClaimed <= boostEnd < block.timestamp

            // user is half-way through running out of boost, calculate exact fraction,
            // as if claim was initiated once at end of boost and once now
            // bonus * (time delta spent with boost bonus) / (complete duration)
            return (TOKEN_BONUS * (boostEnd - lastClaimed)) / (block.timestamp - lastClaimed);
        }
    }

    function roleBonus(uint256 userData) private pure returns (uint256) {
        uint256 numRoles = userData.uniqueRoleCount();
        return numRoles < 3 ? 0 : numRoles < 5 ? ROLE_BONUS_3 : ROLE_BONUS_5;
    }

    function rarityBonus(uint256 userData) private pure returns (uint256) {
        unchecked {
            uint256 numStaked = userData.numStaked();
            return numStaked == 0 ? 0 : (userData.rarityPoints() * RARITY_BONUS) / numStaked;
        }
    }

    function OGBonus(uint256 userData) private view returns (uint256) {
        unchecked {
            uint256 count = userData.OGCount();
            uint256 lastClaimed = userData.lastClaimed();

            if (count == 0 || lastClaimed > OG_BONUS_END) return 0;

            // follows: 0 < count <= numStaked
            uint256 bonus = (count * OG_BONUS) / userData.numStaked();
            if (block.timestamp <= OG_BONUS_END) return bonus;

            // follows: lastClaimed <= OG_BONUS_END < block.timestamp
            return (bonus * (OG_BONUS_END - lastClaimed)) / (block.timestamp - lastClaimed);
        }
    }

    function timeBonus(uint256 userData) private view returns (uint256) {
        unchecked {
            uint256 stakeStart = userData.stakeStart();
            uint256 stakeBonusStart = stakeStart + TIME_BONUS_STAKE_DURATION;

            if (block.timestamp < stakeBonusStart) return 0;

            uint256 lastClaimed = userData.lastClaimed();
            if (lastClaimed >= stakeBonusStart) return TIME_BONUS;

            // follows: lastClaimed < stakeBonusStart <= block.timestamp
            return (TIME_BONUS * (block.timestamp - stakeBonusStart)) / (block.timestamp - lastClaimed);
        }
    }

    function hasSpecialGuest(address user, uint256 index) public view returns (bool) {
        if (index == 0) return false;

        // first 18 addresses are hardcoded to save gas
        if (index < 19) {
            address[19] memory guests = [
                0x0000000000000000000000000000000000000000, // 0: reserved
                0x4BB33f6E69fd62cf3abbcC6F1F43b94A5D572C2B, // 1: Bears Deluxe
                0xbEA8123277142dE42571f1fAc045225a1D347977, // 2: DystoPunks
                0x12d2D1beD91c24f878F37E66bd829Ce7197e4d14, // 3: Galactic Apes
                0x0c2E57EFddbA8c768147D1fdF9176a0A6EBd5d83, // 4: Kaiju Kingz
                0x6E5a65B5f9Dd7b1b08Ff212E210DCd642DE0db8B, // 5: Octohedz
                0x17eD38f5F519C6ED563BE6486e629041Bed3dfbC, // 6: PXQuest Adventurer
                0xdd67892E722bE69909d7c285dB572852d5F8897C, // 7: Scholarz
                0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e, // 8: Doodles
                0x6F44Db5ed6b86d9cC6046D0C78B82caD9E600F6a, // 9: Digi Dragonz
                0x219B8aB790dECC32444a6600971c7C3718252539, // 10: Sneaky Vampire Syndicate
                0xC4a0b1E7AA137ADA8b2F911A501638088DFdD508, // 11: Uninterested Unicorns
                0x9712228cEeDA1E2dDdE52Cd5100B88986d1Cb49c, // 12: Wulfz
                0x56b391339615fd0e88E0D370f451fA91478Bb20F, // 13: Ethalien
                0x648E8428e0104Ec7D08667866a3568a72Fe3898F, // 14: Dysto Apez
                0xd2F668a8461D6761115dAF8Aeb3cDf5F40C532C6, // 15: Karafuru
                0xbad6186E92002E312078b5a1dAfd5ddf63d3f731, // 16: Anonymice
                0xcB4307F1c3B5556256748DDF5B86E81258990B3C, // 17: The Other Side
                0x5c211B8E4f93F00E2BD68e82F4E00FbB3302b35c //  18: Global Citizen Club
            ];

            if (IERC721(guests[index]).balanceOf(user) != 0) return true;

            if (index == 10) return ISVSGraveyard(guests[index]).getBuriedCount(user) != 0;
            else if (index == 12) return AWOO(guests[index]).getStakedAmount(user) != 0;
            else if (index == 16) return CheethV2(guests[index]).stakedMiceQuantity(user) != 0;
        } else {
            IERC721 collection = specialGuests[index];
            if (address(collection) != address(0)) {
                if (collection.balanceOf(user) != 0) return true;
                bytes4 selector = specialGuestsNumStakedSelector[collection];
                if (selector != bytes4(0)) {
                    (bool success, bytes memory data) = address(collection).staticcall(
                        abi.encodeWithSelector(selector, user)
                    );
                    return success && abi.decode(data, (uint256)) != 0;
                }
            }
        }
        return false;
    }

    function specialGuestBonus(address user, uint256 userData) private view returns (uint256) {
        uint256 index = userData.specialGuestIndex();
        if (!hasSpecialGuest(user, index)) return 0;
        return SPECIAL_GUEST_BONUS;
    }

    function _pendingReward(address user, uint256 userData) internal view override returns (uint256) {
        uint256 lastClaimed = userData.lastClaimed();
        if (lastClaimed == 0) return 0;

        uint256 timestamp = min(LAST_GOUDA_EMISSION_DATE, block.timestamp);

        unchecked {
            uint256 delta = timestamp < lastClaimed ? 0 : timestamp - lastClaimed;

            uint256 reward = (userData.baseReward() * delta * dailyReward) / (1 days);
            if (reward == 0) return 0;

            uint256 bonus = totalBonus(user, userData);

            // needs to be calculated per myriad for more accuracy
            return (reward * (10000 + bonus)) / 10000;
        }
    }

    function totalBonus(address user, uint256 userData) internal view returns (uint256) {
        unchecked {
            return
                roleBonus(userData) +
                specialGuestBonus(user, userData) +
                rarityBonus(userData) +
                OGBonus(userData) +
                timeBonus(userData) +
                tokenBonus(userData);
        }
    }

    function _payoutReward(address user, uint256 reward) internal override {
        // note: less than you would receive in 10 seconds
        if (reward > 0.0001 ether) gouda.mint(user, reward);
    }

    /* ------------- View ------------- */

    // for convenience
    struct StakeInfo {
        uint256 numStaked;
        uint256 roleCount;
        uint256 roleBonus;
        uint256 specialGuestBonus;
        uint256 tokenBoost;
        uint256 stakeStart;
        uint256 timeBonus;
        uint256 rarityPoints;
        uint256 rarityBonus;
        uint256 OGCount;
        uint256 OGBonus;
        uint256 totalBonus;
        uint256 multiplierBase;
        uint256 dailyRewardBase;
        uint256 dailyReward;
        uint256 pendingReward;
        int256 tokenBoostDelta;
        uint256[3] levelBalances;
    }

    // calculates momentary totalBonus for display instead of effective bonus
    function getUserStakeInfo(address user) external view returns (StakeInfo memory info) {
        unchecked {
            uint256 userData = _userData[user];

            info.numStaked = userData.numStaked();

            info.roleCount = userData.uniqueRoleCount();

            info.roleBonus = roleBonus(userData) / 100;
            info.specialGuestBonus = specialGuestBonus(user, userData) / 100;
            info.tokenBoost = (block.timestamp < userData.boostStart() + TOKEN_BOOST_DURATION) ? TOKEN_BONUS / 100 : 0;

            info.stakeStart = userData.stakeStart();
            info.timeBonus = (info.stakeStart > 0 &&
                block.timestamp > userData.stakeStart() + TIME_BONUS_STAKE_DURATION)
                ? TIME_BONUS / 100
                : 0;

            info.OGCount = userData.OGCount();
            info.OGBonus = (block.timestamp > OG_BONUS_END || userData.numStaked() == 0)
                ? 0
                : (userData.OGCount() * OG_BONUS) / userData.numStaked() / 100;

            info.rarityPoints = userData.rarityPoints();
            info.rarityBonus = rarityBonus(userData) / 100;

            info.totalBonus =
                info.roleBonus +
                info.specialGuestBonus +
                info.tokenBoost +
                info.timeBonus +
                info.rarityBonus +
                info.OGBonus;

            info.multiplierBase = userData.baseReward();
            info.dailyRewardBase = info.multiplierBase * dailyReward;

            info.dailyReward = (info.dailyRewardBase * (100 + info.totalBonus)) / 100;
            info.pendingReward = _pendingReward(user, userData);

            info.tokenBoostDelta = int256(TOKEN_BOOST_DURATION) - int256(block.timestamp - userData.boostStart());

            info.levelBalances = userData.levelBalances();
        }
    }

    /* ------------- Owner ------------- */

    function setGoudaToken(Gouda gouda_) external payable onlyOwner {
        gouda = gouda_;
    }

    function setSpecialGuests(IERC721[] calldata collections, uint256[] calldata indices) external payable onlyOwner {
        for (uint256 i; i < indices.length; ++i) {
            uint256 index = indices[i];
            require(index != 0);
            specialGuests[index] = collections[i];
        }
    }

    function setSpecialGuestStakingSelector(IERC721 collection, bytes4 selector) external payable onlyOwner {
        specialGuestsNumStakedSelector[collection] = selector;
    }

    function setBoostTokens(IERC20[] calldata _boostTokens, uint256[] calldata _boostCosts) external payable onlyOwner {
        for (uint256 i; i < _boostTokens.length; ++i) tokenBoostCosts[_boostTokens[i]] = _boostCosts[i];
    }
}

// Special guest's staking interfaces
interface ISVSGraveyard {
    function getBuriedCount(address burier) external view returns (uint256);
}

interface AWOO {
    function getStakedAmount(address staker) external view returns (uint256);
}

interface CheethV2 {
    function stakedMiceQuantity(address _address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    bytes internal constant TABLE_DECODE =
        hex'0000000000000000000000000000000000000000000000000000000000000000'
        hex'00000000000000000000003e0000003f3435363738393a3b3c3d000000000000'
        hex'00000102030405060708090a0b0c0d0e0f101112131415161718190000000000'
        hex'001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, 'invalid base64 decoder input');

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 4 characters
                dataPtr := add(dataPtr, 4)
                let input := mload(dataPtr)

                // write 3 bytes
                let output := add(
                    add(
                        shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                        shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))
                    ),
                    add(
                        shl(6, and(mload(add(tablePtr, and(shr(8, input), 0xFF))), 0xFF)),
                        and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Warning:
// This library is untested and was only written with
// the specific use-case in mind of encoding traits for MadMouse.
// Use at own risk.

library MetadataEncode {
    /* ------------- Traits ------------- */

    function encode(string[] memory strs) internal pure returns (bytes memory) {
        bytes memory a;
        for (uint256 i; i < strs.length; i++) {
            if (i < strs.length - 1) a = abi.encodePacked(a, strs[i], bytes1(0));
            else a = abi.encodePacked(a, strs[i]);
        }
        return a;
    }

    function decode(bytes memory input, uint256 index) internal pure returns (string memory) {
        uint256 counter;
        uint256 start;
        uint256 end;
        for (; end < input.length; end++) {
            if (input[end] == 0x00) {
                if (counter == index) return getSlice(input, start, end);
                start = end + 1;
                counter++;
            }
        }
        return getSlice(input, start, end);
    }

    function getSlice(
        bytes memory input,
        uint256 start,
        uint256 end
    ) internal pure returns (string memory) {
        bytes memory out = new bytes(end - start);
        for (uint256 i = 0; i < end - start; i++) out[i] = input[i + start];
        return string(out);
    }

    /* ------------- Rarities ------------- */

    function selectWeighted(
        bytes memory traits,
        uint256 r,
        uint256 weights
    ) internal pure returns (string memory) {
        uint256 index = selectWeighted(r, weights);
        return decode(traits, index);
    }

    function selectWeighted(uint256 r, uint256 weights) private pure returns (uint256) {
        unchecked {
            for (uint256 i; i < 32; ++i) {
                r -= (weights >> (i << 3)) & 0xFF;
                if (r > 0xFF) return i;
            }
        }
        return 666666;
    }

    function encode(uint256[] memory weights) internal pure returns (bytes32) {
        uint256 r;
        uint256 sum;
        for (uint256 i; i < weights.length; i++) {
            r |= weights[i] << (i << 3);
            sum += weights[i];
        }
        require(sum == 256, 'Should sum to 256');
        return bytes32(r);
    }

    function decode(bytes32 code, uint256 length) internal pure returns (uint256[] memory) {
        uint256[] memory r = new uint256[](length);
        for (uint256 i; i < length; i++) r[i] = uint256(code >> (i << 3)) & 0xFF;
        return r;
    }

    /* ------------- Helpers ------------- */

    function keyValue(string memory key, string memory value) internal pure returns (string memory) {
        return bytes(value).length > 0 ? string.concat('"', key, '": ', value, ', ') : '';
    }

    function keyValueString(string memory key, string memory value) internal pure returns (string memory) {
        return bytes(value).length > 0 ? string.concat('"', key, '": ', '"', value, '", ') : '';
    }

    function attributeString(string memory traitType, string memory value) internal pure returns (string memory) {
        return attributeString(traitType, value, true);
    }

    function attributeString(
        string memory traitType,
        string memory value,
        bool comma
    ) internal pure returns (string memory) {
        return bytes(value).length > 0 ? attribute(traitType, string.concat('"', value, '"'), comma) : '';
    }

    function attribute(string memory traitType, string memory value) internal pure returns (string memory) {
        return attribute(traitType, value, true);
    }

    function attribute(
        string memory traitType,
        string memory value,
        bool comma
    ) internal pure returns (string memory) {
        return
            bytes(value).length > 0
                ? string.concat('{"trait_type": "', traitType, '", "value": ', value, '}', comma ? ', ' : '')
                : '';
    }

    function attributes(string memory attr) internal pure returns (string memory) {
        return string.concat('"attributes": [', attr, ']');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import './ERC721MLibrary.sol';

error IncorrectOwner();
error NonexistentToken();
error QueryForZeroAddress();

error TokenIdUnstaked();
error ExceedsStakingLimit();

error MintToZeroAddress();
error MintZeroQuantity();
error MintMaxSupplyReached();
error MintMaxWalletReached();

error CallerNotOwnerNorApproved();

error ApprovalToCaller();
error ApproveToCurrentOwner();

error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();

abstract contract ERC721M {
    using Address for address;
    using Strings for uint256;
    using UserDataOps for uint256;
    using TokenDataOps for uint256;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    string public name;
    string public symbol;

    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    uint256 public totalSupply;

    uint256 immutable startingIndex;
    uint256 immutable collectionSize;
    uint256 immutable maxPerWallet;

    // note: hard limit of 255, otherwise overflows can happen
    uint256 constant stakingLimit = 100;

    mapping(uint256 => uint256) internal _tokenData;
    mapping(address => uint256) internal _userData;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 startingIndex_,
        uint256 collectionSize_,
        uint256 maxPerWallet_
    ) {
        name = name_;
        symbol = symbol_;
        collectionSize = collectionSize_;
        maxPerWallet = maxPerWallet_;
        startingIndex = startingIndex_;
    }

    /* ------------- External ------------- */

    function stake(uint256[] calldata tokenIds) external payable {
        uint256 userData = _claimReward();
        for (uint256 i; i < tokenIds.length; ++i) userData = _stake(msg.sender, tokenIds[i], userData);
        _userData[msg.sender] = userData;
    }

    function unstake(uint256[] calldata tokenIds) external payable {
        uint256 userData = _claimReward();
        for (uint256 i; i < tokenIds.length; ++i) userData = _unstake(msg.sender, tokenIds[i], userData);
        _userData[msg.sender] = userData;
    }

    function claimReward() external payable {
        _userData[msg.sender] = _claimReward();
    }

    /* ------------- Private ------------- */

    function _stake(
        address from,
        uint256 tokenId,
        uint256 userData
    ) private returns (uint256) {
        uint256 _numStaked = userData.numStaked();

        uint256 tokenData = _tokenDataOf(tokenId);
        address owner = tokenData.owner();

        if (_numStaked >= stakingLimit) revert ExceedsStakingLimit();
        if (owner != from) revert IncorrectOwner();

        delete getApproved[tokenId];

        // hook, used for reading DNA, updating role balances,
        (uint256 userDataX, uint256 tokenDataX) = _beforeStakeDataTransform(tokenId, userData, tokenData);
        (userData, tokenData) = applySafeDataTransform(userData, tokenData, userDataX, tokenDataX);

        tokenData = tokenData.setstaked();
        userData = userData.decreaseBalance(1).increaseNumStaked(1);

        if (_numStaked == 0) userData = userData.setStakeStart(block.timestamp);

        _tokenData[tokenId] = tokenData;

        emit Transfer(from, address(this), tokenId);

        return userData;
    }

    function _unstake(
        address to,
        uint256 tokenId,
        uint256 userData
    ) private returns (uint256) {
        uint256 tokenData = _tokenDataOf(tokenId);
        address owner = tokenData.trueOwner();
        bool isStaked = tokenData.staked();

        if (owner != to) revert IncorrectOwner();
        if (!isStaked) revert TokenIdUnstaked();

        (uint256 userDataX, uint256 tokenDataX) = _beforeUnstakeDataTransform(tokenId, userData, tokenData);
        (userData, tokenData) = applySafeDataTransform(userData, tokenData, userDataX, tokenDataX);

        // if mintAndStake flag is set, we need to make sure that next tokenData is set
        // because tokenData in this case is implicit and needs to carry over
        if (tokenData.mintAndStake()) {
            unchecked {
                tokenData = _ensureTokenDataSet(tokenId + 1, tokenData).unsetMintAndStake();
            }
        }

        tokenData = tokenData.unsetstaked();
        userData = userData.increaseBalance(1).decreaseNumStaked(1).setStakeStart(block.timestamp);

        _tokenData[tokenId] = tokenData;

        emit Transfer(address(this), to, tokenId);

        return userData;
    }

    /* ------------- Internal ------------- */

    function _mintAndStake(
        address to,
        uint256 quantity,
        bool stake_
    ) internal {
        unchecked {
            uint256 totalSupply_ = totalSupply;
            uint256 startTokenId = startingIndex + totalSupply_;

            uint256 userData = _userData[to];
            uint256 numMinted_ = userData.numMinted();

            if (to == address(0)) revert MintToZeroAddress();
            if (quantity == 0) revert MintZeroQuantity();

            if (totalSupply_ + quantity > collectionSize) revert MintMaxSupplyReached();
            if (numMinted_ + quantity > maxPerWallet && address(this).code.length != 0) revert MintMaxWalletReached();

            userData = userData.increaseNumMinted(quantity);

            uint256 tokenData = TokenDataOps.newTokenData(to, block.timestamp, stake_);

            // don't have to care about next token data if only minting one
            // could optimize to implicitly flag last token id of batch
            if (quantity == 1) tokenData = tokenData.flagNextTokenDataSet();

            if (stake_) {
                uint256 _numStaked = userData.numStaked();

                userData = claimReward(userData);
                userData = userData.increaseNumStaked(quantity);

                if (_numStaked + quantity > stakingLimit) revert ExceedsStakingLimit();
                if (_numStaked == 0) userData = userData.setStakeStart(block.timestamp);

                uint256 tokenId;
                for (uint256 i; i < quantity; ++i) {
                    tokenId = startTokenId + i;

                    (userData, tokenData) = _beforeStakeDataTransform(tokenId, userData, tokenData);

                    emit Transfer(address(0), to, tokenId);
                    emit Transfer(to, address(this), tokenId);
                }
            } else {
                userData = userData.increaseBalance(quantity);
                for (uint256 i; i < quantity; ++i) emit Transfer(address(0), to, startTokenId + i);
            }

            _userData[to] = userData;
            _tokenData[startTokenId] = tokenData;

            totalSupply += quantity;
        }
    }

    function _claimReward() internal returns (uint256) {
        uint256 userData = _userData[msg.sender];
        return claimReward(userData);
    }

    function claimReward(uint256 userData) private returns (uint256) {
        uint256 reward = _pendingReward(msg.sender, userData);

        userData = userData.setLastClaimed(block.timestamp);

        _payoutReward(msg.sender, reward);

        return userData;
    }

    function _tokenDataOf(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert NonexistentToken();

        for (uint256 curr = tokenId; ; curr--) {
            uint256 tokenData = _tokenData[curr];
            if (tokenData != 0) return (curr == tokenId) ? tokenData : tokenData.copy();
        }

        // unreachable
        return 0;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return startingIndex <= tokenId && tokenId < startingIndex + totalSupply;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        // make sure no one is misled by token transfer events
        if (to == address(this)) {
            uint256 userData = _claimReward();
            _userData[msg.sender] = _stake(msg.sender, tokenId, userData);
        } else {
            uint256 tokenData = _tokenDataOf(tokenId);
            address owner = tokenData.owner();

            bool isApprovedOrOwner = (msg.sender == owner ||
                isApprovedForAll[owner][msg.sender] ||
                getApproved[tokenId] == msg.sender);

            if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();
            if (to == address(0)) revert TransferToZeroAddress();
            if (owner != from) revert TransferFromIncorrectOwner();

            delete getApproved[tokenId];

            unchecked {
                _tokenData[tokenId] = _ensureTokenDataSet(tokenId + 1, tokenData)
                    .setOwner(to)
                    .setLastTransfer(block.timestamp)
                    .incrementOwnerCount();
            }

            _userData[from] = _userData[from].decreaseBalance(1);
            _userData[to] = _userData[to].increaseBalance(1);

            emit Transfer(from, to, tokenId);
        }
    }

    function _ensureTokenDataSet(uint256 tokenId, uint256 tokenData) private returns (uint256) {
        if (!tokenData.nextTokenDataSet() && _tokenData[tokenId] == 0 && _exists(tokenId))
            _tokenData[tokenId] = tokenData.copy(); // make sure to not pass any token specific data in
        return tokenData.flagNextTokenDataSet();
    }

    /* ------------- Virtual (hooks) ------------- */

    function _beforeStakeDataTransform(
        uint256, // tokenId
        uint256 userData,
        uint256 tokenData
    ) internal view virtual returns (uint256, uint256) {
        return (userData, tokenData);
    }

    function _beforeUnstakeDataTransform(
        uint256, // tokenId
        uint256 userData,
        uint256 tokenData
    ) internal view virtual returns (uint256, uint256) {
        return (userData, tokenData);
    }

    function _pendingReward(address, uint256 userData) internal view virtual returns (uint256);

    function _payoutReward(address user, uint256 reward) internal virtual;

    /* ------------- View ------------- */

    function ownerOf(uint256 tokenId) external view returns (address) {
        return _tokenDataOf(tokenId).owner();
    }

    function trueOwnerOf(uint256 tokenId) external view returns (address) {
        return _tokenDataOf(tokenId).trueOwner();
    }

    function balanceOf(address owner) external view returns (uint256) {
        if (owner == address(0)) revert QueryForZeroAddress();
        return _userData[owner].balance();
    }

    function numStaked(address user) external view returns (uint256) {
        return _userData[user].numStaked();
    }

    function numOwned(address user) external view returns (uint256) {
        uint256 userData = _userData[user];
        return userData.balance() + userData.numStaked();
    }

    function numMinted(address user) external view returns (uint256) {
        return _userData[user].numMinted();
    }

    function pendingReward(address user) external view returns (uint256) {
        return _pendingReward(user, _userData[user]);
    }

    // O(N) read-only functions

    function tokenIdsOf(address user, uint256 type_) external view returns (uint256[] memory) {
        unchecked {
            uint256 numTotal = type_ == 0 ? this.balanceOf(user) : type_ == 1
                ? this.numStaked(user)
                : this.numOwned(user);

            uint256[] memory ids = new uint256[](numTotal);

            if (numTotal == 0) return ids;

            uint256 count;
            for (uint256 i = startingIndex; i < totalSupply + startingIndex; ++i) {
                uint256 tokenData = _tokenDataOf(i);
                if (user == tokenData.trueOwner()) {
                    bool staked = tokenData.staked();
                    if ((type_ == 0 && !staked) || (type_ == 1 && staked) || type_ == 2) {
                        ids[count++] = i;
                        if (numTotal == count) return ids;
                    }
                }
            }

            return ids;
        }
    }

    function totalNumStaked() external view returns (uint256) {
        unchecked {
            uint256 count;
            for (uint256 i = startingIndex; i < startingIndex + totalSupply; ++i) {
                if (_tokenDataOf(i).staked()) ++count;
            }
            return count;
        }
    }

    /* ------------- ERC721 ------------- */

    function tokenURI(uint256 id) public view virtual returns (string memory);

    function supportsInterface(bytes4 interfaceId) external view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    function approve(address spender, uint256 tokenId) external {
        address owner = _tokenDataOf(tokenId).owner();

        if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) revert CallerNotOwnerNorApproved();

        getApproved[tokenId] = spender;
        emit Approval(owner, spender, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        safeTransferFrom(from, to, tokenId, '');
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public {
        transferFrom(from, to, tokenId);
        if (
            to.code.length != 0 &&
            IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) !=
            IERC721Receiver(to).onERC721Received.selector
        ) revert TransferToNonERC721ReceiverImplementer();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// # ERC721M.sol
//
// _tokenData layout:
// 0x________/cccccbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
// a [  0] (uint160): address #owner           (owner of token id)
// b [160] (uint40): timestamp #lastTransfer   (timestamp since the last transfer)
// c [200] (uint20): #ownerCount               (number of total owners of token)
// f [220] (uint1): #staked flag               (flag whether id has been staked) Note: this carries over when calling 'ownerOf'
// f [221] (uint1): #mintAndStake flag         (flag whether to carry over stake flag when calling tokenDataOf; used for mintAndStake and boost)
// e [222] (uint1): #nextTokenDataSet flag     (flag whether the data of next token id has already been set)
// _ [224] (uint32): arbitrary data

uint256 constant RESTRICTED_TOKEN_DATA = 0x00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

// # MadMouse.sol
//
// _tokenData (metadata) layout:
// 0xefg00000________________________________________________________
// e [252] (uint4): #level                     (mouse level)  [0...2] (must be 0-based)
// f [248] (uint4): #role                      (mouse role)   [1...5] (must start at 1)
// g [244] (uint4): #rarity                    (mouse rarity) [0...3]

struct TokenData {
    address owner;
    uint256 lastTransfer;
    uint256 ownerCount;
    bool staked;
    bool mintAndStake;
    bool nextTokenDataSet;
    uint256 level;
    uint256 role;
    uint256 rarity;
}

// # ERC721M.sol
//
// _userData layout:
// 0x________________________________ddccccccccccbbbbbbbbbbaaaaaaaaaa
// a [  0] (uint32): #balance                  (owner ERC721 balance)
// b [ 40] (uint40): timestamp #stakeStart     (timestamp when stake started)
// c [ 80] (uint40): timestamp #lastClaimed    (timestamp when user last claimed rewards)
// d [120] (uint8): #numStaked                 (balance count of all staked tokens)
// _ [128] (uint128): arbitrary data

uint256 constant RESTRICTED_USER_DATA = 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

// # MadMouseStaking.sol
//
// _userData (boost) layout:
// 0xttttttttt/o/rriiffgghhaabbccddee________________________________
// a-e [128] (5x uint8): #roleBalances         (balance of all staked roles)
// f-h [168] (3x uint8): #levelBalances        (balance of all staked levels)

// i [192] (uint8): #specialGuestIndex         (signals whether the user claims to hold a token of a certain collection)
// r [200] (uint10): #rarityPoints             (counter of rare traits; 1 is rare, 2 is super-rare, 3 is ultra-rare)
// o [210] (uint8): #OGCount                   (counter of rare traits; 1 is rare, 2 is super-rare, 3 is ultra-rare)
// t [218] (uint38): timestamp #boostStart     (timestamp of when the boost by burning tokens of affiliate collections started)

struct UserData {
    uint256 balance;
    uint256 stakeStart;
    uint256 lastClaimed;
    uint256 numStaked;
    uint256[5] roleBalances;
    uint256 uniqueRoleCount; // inferred
    uint256[3] levelBalances;
    uint256 specialGuestIndex;
    uint256 rarityPoints;
    uint256 OGCount;
    uint256 boostStart;
}

function applySafeDataTransform(
    uint256 userData,
    uint256 tokenData,
    uint256 userDataTransformed,
    uint256 tokenDataTransformed
) pure returns (uint256, uint256) {
    // mask transformed data in order to leave base data untouched in any case
    userData = (userData & RESTRICTED_USER_DATA) | (userDataTransformed & ~RESTRICTED_USER_DATA);
    tokenData = (tokenData & RESTRICTED_TOKEN_DATA) | (tokenDataTransformed & ~RESTRICTED_TOKEN_DATA);
    return (userData, tokenData);
}

// @note: many of these are unchecked, because safemath wouldn't be able to guard
// overflows while updating bitmaps unless custom checks were to be implemented

library UserDataOps {
    function getUserData(uint256 userData) internal pure returns (UserData memory) {
        return
            UserData({
                balance: UserDataOps.balance(userData),
                stakeStart: UserDataOps.stakeStart(userData),
                lastClaimed: UserDataOps.lastClaimed(userData),
                numStaked: UserDataOps.numStaked(userData),
                roleBalances: UserDataOps.roleBalances(userData),
                uniqueRoleCount: UserDataOps.uniqueRoleCount(userData),
                levelBalances: UserDataOps.levelBalances(userData),
                specialGuestIndex: UserDataOps.specialGuestIndex(userData),
                rarityPoints: UserDataOps.rarityPoints(userData),
                OGCount: UserDataOps.OGCount(userData),
                boostStart: UserDataOps.boostStart(userData)
            });
    }

    function balance(uint256 userData) internal pure returns (uint256) {
        return userData & 0xFFFFF;
    }

    function increaseBalance(uint256 userData, uint256 amount) internal pure returns (uint256) {
        unchecked {
            return userData + amount;
        }
    }

    function decreaseBalance(uint256 userData, uint256 amount) internal pure returns (uint256) {
        unchecked {
            return userData - amount;
        }
    }

    function numMinted(uint256 userData) internal pure returns (uint256) {
        return (userData >> 20) & 0xFFFFF;
    }

    function increaseNumMinted(uint256 userData, uint256 amount) internal pure returns (uint256) {
        unchecked {
            return userData + (amount << 20);
        }
    }

    function stakeStart(uint256 userData) internal pure returns (uint256) {
        return (userData >> 40) & 0xFFFFFFFFFF;
    }

    function setStakeStart(uint256 userData, uint256 timestamp) internal pure returns (uint256) {
        return (userData & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000FFFFFFFFFF) | (timestamp << 40);
    }

    function lastClaimed(uint256 userData) internal pure returns (uint256) {
        return (userData >> 80) & 0xFFFFFFFFFF;
    }

    function setLastClaimed(uint256 userData, uint256 timestamp) internal pure returns (uint256) {
        return (userData & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000FFFFFFFFFFFFFFFFFFFF) | (timestamp << 80);
    }

    function numStaked(uint256 userData) internal pure returns (uint256) {
        return (userData >> 120) & 0xFF;
    }

    function increaseNumStaked(uint256 userData, uint256 amount) internal pure returns (uint256) {
        unchecked {
            return userData + (amount << 120);
        }
    }

    function decreaseNumStaked(uint256 userData, uint256 amount) internal pure returns (uint256) {
        unchecked {
            return userData - (amount << 120);
        }
    }

    function roleBalances(uint256 userData) internal pure returns (uint256[5] memory balances) {
        balances = [
            (userData >> (128 + 0)) & 0xFF,
            (userData >> (128 + 8)) & 0xFF,
            (userData >> (128 + 16)) & 0xFF,
            (userData >> (128 + 24)) & 0xFF,
            (userData >> (128 + 32)) & 0xFF
        ];
    }

    // trait counts are set through hook in madmouse contract (MadMouse::_beforeStakeDataTransform)
    function uniqueRoleCount(uint256 userData) internal pure returns (uint256) {
        unchecked {
            return (toUInt256((userData >> (128)) & 0xFF > 0) +
                toUInt256((userData >> (128 + 8)) & 0xFF > 0) +
                toUInt256((userData >> (128 + 16)) & 0xFF > 0) +
                toUInt256((userData >> (128 + 24)) & 0xFF > 0) +
                toUInt256((userData >> (128 + 32)) & 0xFF > 0));
        }
    }

    function levelBalances(uint256 userData) internal pure returns (uint256[3] memory balances) {
        balances = [(userData >> (168 + 0)) & 0xFF, (userData >> (168 + 8)) & 0xFF, (userData >> (168 + 16)) & 0xFF];
    }

    // depends on the levels of the staked tokens (also set in hook MadMouse::_beforeStakeDataTransform)
    // counts the base reward, depending on the levels of staked ids
    function baseReward(uint256 userData) internal pure returns (uint256) {
        unchecked {
            return (((userData >> (168)) & 0xFF) +
                (((userData >> (168 + 8)) & 0xFF) << 1) +
                (((userData >> (168 + 16)) & 0xFF) << 2));
        }
    }

    function rarityPoints(uint256 userData) internal pure returns (uint256) {
        return (userData >> 200) & 0x3FF;
    }

    function specialGuestIndex(uint256 userData) internal pure returns (uint256) {
        return (userData >> 192) & 0xFF;
    }

    function setSpecialGuestIndex(uint256 userData, uint256 index) internal pure returns (uint256) {
        return (userData & ~uint256(0xFF << 192)) | (index << 192);
    }

    function boostStart(uint256 userData) internal pure returns (uint256) {
        return (userData >> 218) & 0xFFFFFFFFFF;
    }

    function setBoostStart(uint256 userData, uint256 timestamp) internal pure returns (uint256) {
        return (userData & ~(uint256(0xFFFFFFFFFF) << 218)) | (timestamp << 218);
    }

    function OGCount(uint256 userData) internal pure returns (uint256) {
        return (userData >> 210) & 0xFF;
    }

    //  (should start at 128, 168; but role/level start at 1...)
    function updateUserDataStake(uint256 userData, uint256 tokenData) internal pure returns (uint256) {
        unchecked {
            uint256 role = TokenDataOps.role(tokenData);
            if (role > 0) {
                userData += uint256(1) << (120 + (role << 3)); // roleBalances
                userData += TokenDataOps.rarity(tokenData) << 200; // rarityPoints
            }
            if (TokenDataOps.mintAndStake(tokenData)) userData += uint256(1) << 210; // OGCount
            userData += uint256(1) << (160 + (TokenDataOps.level(tokenData) << 3)); // levelBalances
            return userData;
        }
    }

    function updateUserDataUnstake(uint256 userData, uint256 tokenData) internal pure returns (uint256) {
        unchecked {
            uint256 role = TokenDataOps.role(tokenData);
            if (role > 0) {
                userData -= uint256(1) << (120 + (role << 3)); // roleBalances
                userData -= TokenDataOps.rarity(tokenData) << 200; // rarityPoints
            }
            if (TokenDataOps.mintAndStake(tokenData)) userData -= uint256(1) << 210; // OG-count
            userData -= uint256(1) << (160 + (TokenDataOps.level(tokenData) << 3)); // levelBalances
            return userData;
        }
    }

    function increaseLevelBalances(uint256 userData, uint256 tokenData) internal pure returns (uint256) {
        unchecked {
            return userData + (uint256(1) << (160 + (TokenDataOps.level(tokenData) << 3)));
        }
    }

    function decreaseLevelBalances(uint256 userData, uint256 tokenData) internal pure returns (uint256) {
        unchecked {
            return userData - (uint256(1) << (160 + (TokenDataOps.level(tokenData) << 3)));
        }
    }
}

library TokenDataOps {
    function getTokenData(uint256 tokenData) internal view returns (TokenData memory) {
        return
            TokenData({
                owner: TokenDataOps.owner(tokenData),
                lastTransfer: TokenDataOps.lastTransfer(tokenData),
                ownerCount: TokenDataOps.ownerCount(tokenData),
                staked: TokenDataOps.staked(tokenData),
                mintAndStake: TokenDataOps.mintAndStake(tokenData),
                nextTokenDataSet: TokenDataOps.nextTokenDataSet(tokenData),
                level: TokenDataOps.level(tokenData),
                role: TokenDataOps.role(tokenData),
                rarity: TokenDataOps.rarity(tokenData)
            });
    }

    function newTokenData(
        address owner_,
        uint256 lastTransfer_,
        bool stake_
    ) internal pure returns (uint256) {
        uint256 tokenData = (uint256(uint160(owner_)) | (lastTransfer_ << 160) | (uint256(1) << 200));
        return stake_ ? setstaked(setMintAndStake(tokenData)) : tokenData;
    }

    function copy(uint256 tokenData) internal pure returns (uint256) {
        // tokenData minus the token specific flags (4/2bits), i.e. only owner, lastTransfer, ownerCount
        // stake flag (& mintAndStake flag) carries over if mintAndStake was called
        return tokenData & (RESTRICTED_TOKEN_DATA >> (mintAndStake(tokenData) ? 2 : 4));
    }

    function owner(uint256 tokenData) internal view returns (address) {
        if (staked(tokenData)) return address(this);
        return trueOwner(tokenData);
    }

    function setOwner(uint256 tokenData, address owner_) internal pure returns (uint256) {
        return (tokenData & 0xFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000000000000000000000000000) | uint160(owner_);
    }

    function staked(uint256 tokenData) internal pure returns (bool) {
        return ((tokenData >> 220) & uint256(1)) > 0; // Note: this can carry over when calling 'ownerOf'
    }

    function setstaked(uint256 tokenData) internal pure returns (uint256) {
        return tokenData | (uint256(1) << 220);
    }

    function unsetstaked(uint256 tokenData) internal pure returns (uint256) {
        return tokenData & ~(uint256(1) << 220);
    }

    function mintAndStake(uint256 tokenData) internal pure returns (bool) {
        return ((tokenData >> 221) & uint256(1)) > 0;
    }

    function setMintAndStake(uint256 tokenData) internal pure returns (uint256) {
        return tokenData | (uint256(1) << 221);
    }

    function unsetMintAndStake(uint256 tokenData) internal pure returns (uint256) {
        return tokenData & ~(uint256(1) << 221);
    }

    function nextTokenDataSet(uint256 tokenData) internal pure returns (bool) {
        return ((tokenData >> 222) & uint256(1)) > 0;
    }

    function flagNextTokenDataSet(uint256 tokenData) internal pure returns (uint256) {
        return tokenData | (uint256(1) << 222); // nextTokenDatatSet flag (don't repeat the read/write)
    }

    function trueOwner(uint256 tokenData) internal pure returns (address) {
        return address(uint160(tokenData));
    }

    function ownerCount(uint256 tokenData) internal pure returns (uint256) {
        return (tokenData >> 200) & 0xFFFFF;
    }

    function incrementOwnerCount(uint256 tokenData) internal pure returns (uint256) {
        uint256 newOwnerCount = min(ownerCount(tokenData) + 1, 0xFFFFF);
        return (tokenData & ~(uint256(0xFFFFF) << 200)) | (newOwnerCount << 200);
    }

    function resetOwnerCount(uint256 tokenData) internal pure returns (uint256) {
        uint256 count = min(ownerCount(tokenData), 2); // keep minter status
        return (tokenData & ~(uint256(0xFFFFF) << 200)) | (count << 200);
    }

    function lastTransfer(uint256 tokenData) internal pure returns (uint256) {
        return (tokenData >> 160) & 0xFFFFFFFFFF;
    }

    function setLastTransfer(uint256 tokenData, uint256 timestamp) internal pure returns (uint256) {
        return (tokenData & 0xFFFFFFFFFFFFFF0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) | (timestamp << 160);
    }

    // MadMouse
    function level(uint256 tokenData) internal pure returns (uint256) {
        unchecked {
            return 1 + (tokenData >> 252);
        }
    }

    function increaseLevel(uint256 tokenData) internal pure returns (uint256) {
        unchecked {
            return tokenData + (uint256(1) << 252);
        }
    }

    function role(uint256 tokenData) internal pure returns (uint256) {
        return (tokenData >> 248) & 0xF;
    }

    function rarity(uint256 tokenData) internal pure returns (uint256) {
        return (tokenData >> 244) & 0xF;
    }

    // these slots should be are already 0
    function setRoleAndRarity(uint256 tokenData, uint256 dna) internal pure returns (uint256) {
        return ((tokenData & ~(uint256(0xFF) << 244)) | (DNAOps.toRole(dna) << 248) | (DNAOps.toRarity(dna) << 244));
    }
}

library DNAOps {
    function toRole(uint256 dna) internal pure returns (uint256) {
        unchecked {
            return 1 + ((dna & 0xFF) % 5);
        }
    }

    function toRarity(uint256 dna) internal pure returns (uint256) {
        uint256 dnaFur = (dna >> 8) & 0xFF;
        if (dnaFur > 108) return 0;
        if (dnaFur > 73) return 1;
        if (dnaFur > 17) return 2;
        return 3;
    }
}

/* ------------- Helpers ------------- */

// more efficient https://github.com/ethereum/solidity/issues/659
function toUInt256(bool x) pure returns (uint256 r) {
    assembly {
        r := x
    }
}

function min(uint256 a, uint256 b) pure returns (uint256) {
    return a < b ? a : b;
}

function isValidString(string calldata str, uint256 maxLen) pure returns (bool) {
    bytes memory b = bytes(str);
    if (b.length < 1 || b.length > maxLen || b[0] == 0x20 || b[b.length - 1] == 0x20) return false;

    bytes1 lastChar = b[0];

    bytes1 char;
    for (uint256 i; i < b.length; ++i) {
        char = b[i];

        if (
            (char > 0x60 && char < 0x7B) || //a-z
            (char > 0x40 && char < 0x5B) || //A-Z
            (char == 0x20) || //space
            (char > 0x2F && char < 0x3A) //9-0
        ) {
            lastChar = char;
        } else {
            return false;
        }
    }

    return true;
}