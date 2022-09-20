// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;
import "@solidstate/contracts/access/ownable/Ownable.sol";
import "../libraries/LibKoboldStaking.sol";
contract KoboldStakingFacet is Ownable {
    
    function getSigner() external view returns(address) {
        return LibKoboldStaking.getSigner();
    }
    function getKoboldAccumulatedReward(uint koboldTokenId) external view returns(uint){
        return LibKoboldStaking.getKoboldAccumulatedReward(koboldTokenId);
    }
     function nextRewardForKobold(uint koboldId) external view returns(uint) {
        return LibKoboldStaking.nextReward(koboldId);
    }
    function viewKoboldTotalReward(uint koboldId) external view returns(uint) {
        return LibKoboldStaking.viewTokenTotalReward(koboldId);
    }
    function getRewardPerSecond() external view returns(uint) {
        return LibKoboldStaking.getRewardPerSecond();
    }
    function getAcceptableTimelag() external view returns(uint) {
        return LibKoboldStaking.getAcceptableTimelag();
    }
    // function getRewardPerSecond() ex

    //Setters
    function setRewardPerSecond(uint newRewardPerSecond) external onlyOwner{
        LibKoboldStaking.setRewardPerSecond(newRewardPerSecond);
    }
    function setSigner(address _signer) external onlyOwner {
        LibKoboldStaking.setSigner(_signer);
    }
    function setAcceptableTimelag(uint newAcceptableTimelag) external onlyOwner{
        LibKoboldStaking.setAcceptableTimelag(newAcceptableTimelag);
    }
    
   //Staking Functions
    function startKoboldBatchStake(uint[] calldata tokenIds) external {
        LibKoboldStaking.startKoboldBatchStake(tokenIds);
    }
    function endKoboldBatchStake(uint[] calldata tokenIds) external {
        LibKoboldStaking.endKoboldBatchStake(tokenIds);
    }
    //Withdraw Function
    function withdrawReward(uint[] calldata tokenIds,
      uint[] calldata healthPoints,
    uint referenceTimestamp,
    bytes memory signature
    ) external {
        LibKoboldStaking.withdrawReward(tokenIds,
        healthPoints,referenceTimestamp,signature);
    }
    function withdrawRewardWithMultiplier(uint[] calldata tokenIds,
    uint koboldMultiplierId,
    uint[] calldata healthPoints,
    uint referenceTimestamp,
    bytes memory signature) external {
        LibKoboldStaking.withdrawRewardWithMultiplier(tokenIds,
        koboldMultiplierId,healthPoints,referenceTimestamp,signature);
    }


}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;
import "./LibAppStorage.sol";
import "../interfaces/IAppStorage.sol";
import "../../interfaces/IKobolds.sol";
import "../../interfaces/IIngotToken.sol";
import "./LibKoboldMultipliers.sol";
import "../interfaces/IKoboldMultiplier.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
library LibKoboldStaking {
    using ECDSA for bytes32;
    //Storage
    bytes32 internal constant NAMESPACE = keccak256("titanforge.kobold.staking");
    struct KoboldStaker {
        uint256 accumulatedRewards;
        uint256 lastUpdateTimestamp;
    }
    struct Storage{
        uint256 acceptableTimelag;
        uint256 rewardPerSecond;
        address signer;
        mapping(uint256 => KoboldStaker) koboldStaker;
    }
    
    function getStorage() internal pure returns(Storage storage s)  {
        bytes32 position = NAMESPACE;
        assembly{
            s.slot := position
        }
    }
    function getSigner() internal view returns(address) {
        Storage storage s = getStorage();
        return s.signer;
    }
    
    function getKoboldAccumulatedReward(uint koboldTokenId) internal view returns(uint){
        Storage storage s = getStorage();
        return s.koboldStaker[koboldTokenId].accumulatedRewards;
    }

     function nextReward(uint tokenId) internal view returns(uint) {
        Storage storage s = getStorage();
        KoboldStaker memory staker =  s.koboldStaker[tokenId];
        if(staker.lastUpdateTimestamp == 0) return 0;
        uint timeDelta = block.timestamp - staker.lastUpdateTimestamp;
        uint reward = s.rewardPerSecond * timeDelta;
        return reward;
    }
    function viewTokenTotalReward(uint tokenId) internal view returns(uint) {
        Storage storage s = getStorage();
        return  s.koboldStaker[tokenId].accumulatedRewards + nextReward(tokenId);
    }
    function getRewardPerSecond() internal view returns(uint) {
        Storage storage s = getStorage();
        return s.rewardPerSecond;
    }

    function getAcceptableTimelag() internal view returns(uint) {
        Storage storage s = getStorage();
        return s.acceptableTimelag;
    }

        function setRewardPerSecond(uint newRewardPerSecond) internal {
        Storage storage s = getStorage();
        s.rewardPerSecond = newRewardPerSecond;
    }
    function setSigner(address _signer) internal {
        Storage storage s = getStorage();
        s.signer = _signer;
    }
    function setAcceptableTimelag(uint newAcceptableTimelag) internal {
        Storage storage s = getStorage();
        s.acceptableTimelag = newAcceptableTimelag;
    }
    function setKoboldAccumulatedReward(uint koboldTokenId,uint reward) internal {
         Storage storage s = getStorage();
         s.koboldStaker[koboldTokenId].accumulatedRewards = reward;

    }

    function updateReward(uint[] calldata tokenIds) internal {
        AppStorage storage appStorage = LibAppStorage.appStorage();
        Storage storage s = getStorage();
        for(uint i; i<tokenIds.length;) {
        uint tokenId = tokenIds[i];
        require(msg.sender == iKobolds(appStorage.koboldAddress).ownerOf(tokenId),"Not Owner");
        uint256 reward = nextReward(tokenId);
        KoboldStaker memory staker = s.koboldStaker[tokenId];
        staker.accumulatedRewards += reward;
        staker.lastUpdateTimestamp = block.timestamp;
        s.koboldStaker[tokenId] = staker;
        unchecked{++i;}
        }
    }
    function updateRewardOnEndStakeOrWithdraw(uint[] calldata tokenIds) internal {
        AppStorage storage appStorage = LibAppStorage.appStorage();
        Storage storage s = getStorage();
        for(uint i; i<tokenIds.length;) {
        uint tokenId = tokenIds[i];
        require(msg.sender == iKobolds(appStorage.koboldAddress).ownerOf(tokenId),"Not Owner");
        uint256 reward = nextReward(tokenId);
        KoboldStaker memory staker = s.koboldStaker[tokenId];
        staker.accumulatedRewards += reward;
        staker.lastUpdateTimestamp = 0;
        s.koboldStaker[tokenId] = staker;
        unchecked{++i;}
        }
    }

   
    function startKoboldBatchStake(uint[] calldata tokenIds) internal {
        AppStorage storage appStorage = LibAppStorage.appStorage();
        updateReward(tokenIds);
        iKobolds(appStorage.koboldAddress).batchStake(tokenIds);
    }
    function endKoboldBatchStake(uint[] calldata tokenIds) internal {
        AppStorage storage appStorage = LibAppStorage.appStorage();
        updateRewardOnEndStakeOrWithdraw(tokenIds);
        iKobolds(appStorage.koboldAddress).batchUnstake(tokenIds);
    }
    function isValidTimestamp(uint referenceTimestamp,uint acceptableTimelag) internal view returns(bool) {
        return  referenceTimestamp + acceptableTimelag > block.timestamp;
    }

    function withdrawReward(uint[] calldata tokenIds,
    uint[] calldata healthPoints,
    uint referenceTimestamp,
    bytes memory signature) internal {

        Storage storage s = getStorage();
        updateRewardOnEndStakeOrWithdraw(tokenIds);
        require(isValidTimestamp(referenceTimestamp,s.acceptableTimelag),"Signature Expired");
        bytes32 hash = keccak256(abi.encodePacked(referenceTimestamp,tokenIds,"KHPS",healthPoints));
        address _signer = s.signer;
        require(_signer != address(0),"Signer Not Init"); 
        if(hash.toEthSignedMessageHash().recover(signature) != _signer) revert ("Invalid Signer");
        uint totalReward;
        for(uint i; i<tokenIds.length;){
        uint tokenId = tokenIds[i];
        uint rewardFromToken = viewTokenTotalReward(tokenId);
        unchecked{
            totalReward = ((totalReward + rewardFromToken) * healthPoints[i]) / 100;
        }
        delete s.koboldStaker[tokenId].accumulatedRewards;
        unchecked{++i;}
        }
        AppStorage storage appStorage = LibAppStorage.appStorage();
        iIngotToken(appStorage.ingotTokenAddress).mint(msg.sender,totalReward);
    }

    function withdrawRewardWithMultiplier(uint[] calldata tokenIds, uint koboldMultiplierId,
    uint[] calldata healthPoints,
    uint referenceTimestamp,
    bytes memory signature) internal {
        Storage storage s = getStorage();
        updateRewardOnEndStakeOrWithdraw(tokenIds);
        KoboldStakingMultiplier memory stakingMultiplier = LibKoboldMultipliers.getKoboldMultiplier(koboldMultiplierId);
        LibKoboldMultipliers.spendMultiplier(msg.sender,koboldMultiplierId,1);
        require(isValidTimestamp(referenceTimestamp,s.acceptableTimelag),"Signature Expired");
        bytes32 hash = keccak256(abi.encodePacked(block.timestamp,tokenIds,"KHPS",healthPoints));
        address _signer = s.signer;
        require(_signer != address(0),"Signer Not Init"); 
        if(hash.toEthSignedMessageHash().recover(signature) != _signer) revert ("Invalid Signer");
        uint rewardIncreasePercent = stakingMultiplier.multiplier;
        uint totalReward;
        for(uint i; i<tokenIds.length;){
        uint tokenId = tokenIds[i];
        uint rewardFromToken = viewTokenTotalReward(tokenId);
        unchecked{
            //Can't Overflow Or Underflow
            totalReward = ((totalReward + rewardFromToken) * healthPoints[i]) / 100;
        }
        delete s.koboldStaker[tokenId].accumulatedRewards;
        unchecked{++i;}
        }
        totalReward = totalReward *  (100 + rewardIncreasePercent) / 100;
        AppStorage storage appStorage = LibAppStorage.appStorage();
        iIngotToken(appStorage.ingotTokenAddress).mint(msg.sender,totalReward);
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../IERC173.sol';
import { IOwnable } from './IOwnable.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

/**
 * @title Ownership access control based on ERC173
 */
abstract contract Ownable is IOwnable, OwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    /**
     * @inheritdoc IERC173
     */
    function owner() public view virtual returns (address) {
        return _owner();
    }

    /**
     * @inheritdoc IERC173
     */
    function transferOwnership(address account) public virtual onlyOwner {
        _transferOwnership(account);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface iKobolds {
    function batchStake(uint256[] calldata tokenIds) external;

    function batchUnstake(uint256[] calldata tokenIds) external;

    function burn(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface iIngotToken {
    function burn(address from, uint256 amount) external;

    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;   
import {AppStorage} from "../interfaces/IAppStorage.sol";
library LibAppStorage {

    bytes32 internal constant NAMESPACE = keccak256("titanforge.items.diamond.appstorage");

       function appStorage() internal pure returns(AppStorage storage s)  {
        bytes32 position = NAMESPACE;
        assembly{
            s.slot := position
        }
    }
    function setIngotTokenAddress(address _ingot) internal {
        AppStorage storage s = appStorage();
        s.ingotTokenAddress = _ingot;
    }
    function setKoboldAddress(address _koboldAddress) internal {
        AppStorage storage s = appStorage();
        s.koboldAddress = _koboldAddress;
    }
    function setTitanAddress(address _titanAddress) internal {
        AppStorage storage s = appStorage();
        s.titanAddress = _titanAddress;
    }

    function getIngotTokenAddress() internal view returns(address) {
        AppStorage storage s = appStorage();
        return s.ingotTokenAddress;
    }
        function getKoboldAddress() internal view returns(address) {
        AppStorage storage s = appStorage();
        return s.koboldAddress;
    }
        function getTitanAddress() internal view returns(address) {
        AppStorage storage s = appStorage();
        return s.titanAddress;
    }

}

// SPDX-License-Identifier: MIT


pragma solidity 0.8.17;  
struct AppStorage {
        address ingotTokenAddress;
        address koboldAddress;
        address titanAddress;
    }

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;   
    struct KoboldStakingMultiplier {
        uint price;
        uint multiplier; //5  = 5%
        bool isAvailableForPurchase;
        uint maxQuantity;
        uint quantitySold;
        string name;
    }

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;
import {KoboldStakingMultiplier}  from "../interfaces/IKoboldMultiplier.sol";
library LibKoboldMultipliers {
    //Storage
    bytes32 internal constant NAMESPACE = keccak256("titanforge.kobold.multipliers");

    struct Storage{
        mapping(uint => KoboldStakingMultiplier) multipliers;
        mapping(address => mapping(uint => uint)) balanceOf;
        mapping(address => bool) approvedPurchaser;
        mapping(address => bool) approvedSpender;
        uint koboldMultiplierIdTracker;
    }
    
    function getStorage() internal pure returns(Storage storage s)  {
        bytes32 position = NAMESPACE;
        assembly{
            s.slot := position
        }
    }
    function purchaseMultiplier(address from,uint koboldMultiplierId,uint quantity) internal {
        Storage storage s = getStorage();
        KoboldStakingMultiplier memory multiplier = s.multipliers[koboldMultiplierId];
        require(multiplier.isAvailableForPurchase,"Not For Sale");
        if(multiplier.quantitySold + quantity > multiplier.maxQuantity) revert ("Sold Out");
        s.multipliers[koboldMultiplierId].quantitySold = multiplier.quantitySold + quantity;
        s.balanceOf[from][koboldMultiplierId] += quantity;
    }
    function spendMultiplier(address from,uint koboldMultiplierId,uint quantity) internal {
        Storage storage s = getStorage();
        if(msg.sender != tx.origin) {
        require(s.approvedSpender[msg.sender] , "Not Approved Spender");
        }
        if(quantity > s.balanceOf[from][koboldMultiplierId]) revert ("Kobold Multiplier: Insufficient Multiplier Balance");
        s.balanceOf[from][koboldMultiplierId] -= quantity;
    }
    function getKoboldMultiplier(uint koboldMultiplierId) internal view returns(KoboldStakingMultiplier memory) {
        Storage storage s = getStorage();
        return s.multipliers[koboldMultiplierId];
    }
    function queryBatchKoboldMultipliers(uint[] calldata koboldMultiplierIds) internal view returns(KoboldStakingMultiplier[] memory) {
            uint len = koboldMultiplierIds.length;
            KoboldStakingMultiplier[]  memory koboldStakingMultipliers = new KoboldStakingMultiplier[](len);
            for(uint i; i < len;){
                uint id = koboldMultiplierIds[i];
                koboldStakingMultipliers[i] = getKoboldMultiplier(id);
                 unchecked{++i;}
            }
            return koboldStakingMultipliers;
    }

    function queryUserBalanceBatchMultipliers(address account,uint[] calldata koboldMultiplierIds) internal view returns(uint[] memory) {
            uint len = koboldMultiplierIds.length;
            uint[]  memory koboldStakingMultipliers = new uint[](len);
            for(uint i; i < len;){
                uint id = koboldMultiplierIds[i];
                koboldStakingMultipliers[i] = getUserBalance(account,id);
                 unchecked{++i;}
            }
            return koboldStakingMultipliers;
    }

    function getUserBalance(address user,uint koboldMultiplierId) internal view returns(uint) {
        Storage storage s = getStorage();
        return s.balanceOf[user][koboldMultiplierId];
    }
    function approveSpender(address spender) internal {
        Storage storage s = getStorage();
        s.approvedSpender[spender] = true;
    }
    function unapproveSpender(address spender) internal {
        Storage storage s = getStorage();
        delete s.approvedSpender[spender];
    }
    function setMultiplier(KoboldStakingMultiplier memory koboldStakingMultiplier) internal {
        Storage storage s = getStorage();
        s.multipliers[s.koboldMultiplierIdTracker] = koboldStakingMultiplier;
        ++s.koboldMultiplierIdTracker;
    }

    function overrideExistingMultiplier(uint multiplierId,KoboldStakingMultiplier memory koboldStakingMultiplier) internal {
        Storage storage s = getStorage();
          s.multipliers[multiplierId] = koboldStakingMultiplier;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from './IERC173Internal.sol';

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Internal {
    /**
     * @notice get the ERC173 contract owner
     * @return conrtact owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { AddressUtils } from '../../utils/AddressUtils.sol';
import { IERC173 } from '../IERC173.sol';
import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using AddressUtils for address;
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(msg.sender == _owner(), 'Ownable: sender must be owner');
        _;
    }

    modifier onlyTransitiveOwner() {
        require(
            msg.sender == _transitiveOwner(),
            'Ownable: sender must be transitive owner'
        );
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transitiveOwner() internal view virtual returns (address) {
        address owner = _owner();

        while (owner.isContract()) {
            try IERC173(owner).owner() returns (address transitiveOwner) {
                owner = transitiveOwner;
            } catch {
                return owner;
            }
        }

        return owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(msg.sender, account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../IERC173.sol';

interface IOwnable is IERC173 {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        require(success, 'AddressUtils: failed to send value');
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            'AddressUtils: insufficient balance for call'
        );
        return _functionCallWithValue(target, data, value, error);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        require(
            isContract(target),
            'AddressUtils: function call to non-contract'
        );

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from '../IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        require(value == 0, 'UintUtils: hex length insufficient');

        return string(buffer);
    }
}