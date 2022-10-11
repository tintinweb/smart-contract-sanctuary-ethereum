// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BuyRequest, ClaimRequest, WithdrawRequest} from "../common/Structs.sol";
import {HashUtils} from "./HashUtils.sol";

contract SignatureUtils is HashUtils  {


    /**
     * @dev Returns the result of comparision between the recovered address and the input address
     * @param _buyRequest the buy request item
     * @param _signature the signature of the buy request
     * @param _signer the input address
     * @return result true/false
     */
    function verifyBuyRequest(
        BuyRequest memory _buyRequest,
        bytes memory _signature,
        address _signer
    ) public pure returns (bool) {
        bytes32 hash = hashBuyRequest(_buyRequest);

        bytes32 ethSignedHash = getEthSignedHash(hash);

        return recoverSigner(ethSignedHash,_signature) == _signer;
    }

    /**
     * @dev Returns the result of comparision between the recovered address and the input address
     * @param _claimRequest the claim request item
     * @param _signature the signature of the claim request
     * @param _signer the input address
     * @return result true/false
     */
    function verifyClaimRequest(
        ClaimRequest memory _claimRequest,
        bytes memory _signature,
        address _signer
    ) public pure returns (bool) {
        bytes32 hash = hashClaimRequest(_claimRequest);
        bytes32 ethSignedHash = getEthSignedHash(hash);

        return recoverSigner(ethSignedHash,_signature) == _signer;
    }

    
    /**
     * @dev Returns the result of comparision between the recovered address and the input address
     * @param _withdrawRequest the buy request item
     * @param _signature the signature of the buy request
     * @param _signer the input address
     * @return result true/false
     */
    function verifyWithdrawRequest(
        WithdrawRequest memory _withdrawRequest,
        bytes memory _signature,
        address _signer
    ) public pure returns (bool) {
        bytes32 hash = hashWithdrawRequest(_withdrawRequest);

        bytes32 ethSignedHash = getEthSignedHash(hash);

        return recoverSigner(ethSignedHash,_signature) == _signer;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct BuyRequest {
    uint256 tokenAmount;
    uint256 fund;
    address buyer;
    bytes internalTxId;
    bytes iaoId;
}

struct ClaimRequest {
    uint256 [] tokenIds;
    uint256 [] nftTypes;
    uint256 [] tokenAmounts;
    address [] collectionAddresses;
    address claimer;
    bytes internalTxId;
}

struct WithdrawRequest{
    uint256 tokenAmount;
    uint256 revenue;
    address receiver;
    bytes iaoId;
    bytes internalTxId;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Utils} from "./Utils.sol";
import {AssemblyUtils} from "./AssemblyUtils.sol";
import {BuyRequest, ClaimRequest, WithdrawRequest} from "../common/Structs.sol";

contract HashUtils {
    using Utils for BuyRequest;
    using Utils for ClaimRequest;
    using Utils for WithdrawRequest;
    using AssemblyUtils for uint256;



    /**
     * @dev Returns the hash of a buy request
     * @param _buyRequest the buy request item
     * @return hash the hash of buy request
     */
    function hashBuyRequest(BuyRequest memory _buyRequest)
        public
        pure
        returns (bytes32 hash)
    {
        uint256 size = _buyRequest.sizeOfBuyRequest();
        bytes memory array = new bytes(size);
        uint256 index;

        assembly {
            index := add(array, 0x20)
        }
        index = index.writeUint256(_buyRequest.tokenAmount);
        index = index.writeUint256(_buyRequest.fund);
        index = index.writeAddress(_buyRequest.buyer);
        index = index.writeBytes(_buyRequest.iaoId);
        index = index.writeBytes(_buyRequest.internalTxId);

        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
    }

    /**
     * @dev Returns the hash of a claim request
     * @param _claimRequest the claim request item
     * @return hash the hash of claim request
     */
    function hashClaimRequest(ClaimRequest memory _claimRequest)
        public
        pure
        returns (bytes32 hash)
    {
        uint256 size = _claimRequest.sizeOfClaimRequest();
        bytes memory array = new bytes(size);
        uint256 index;

        assembly {
            index := add(array, 0x20)
        }
        uint256 len = _claimRequest.tokenIds.length;
        for (uint256 i; i < len; i ++){
            index = index.writeUint256(_claimRequest.tokenIds[i]);
        } 
        for (uint256 i; i < len; i ++){
            index = index.writeUint256(_claimRequest.nftTypes[i]);
        } 
        for (uint256 i; i < len; i ++){
            index = index.writeUint256(_claimRequest.tokenAmounts[i]);
        } 
        for (uint256 i; i < len; i ++){
            index = index.writeAddress(_claimRequest.collectionAddresses[i]);
        } 
        index = index.writeAddress(_claimRequest.claimer);
        index = index.writeBytes(_claimRequest.internalTxId);

        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
    }

    /**
     * @dev Returns the hash of a withdraw request
     * @param _withdrawRequest the buy request item
     * @return hash the hash of buy request
     */
    function hashWithdrawRequest(WithdrawRequest memory _withdrawRequest)
        public
        pure
        returns (bytes32 hash)
    {
        uint256 size = _withdrawRequest.sizeOfWithdrawRequest();
        bytes memory array = new bytes(size);
        uint256 index;

        assembly {
            index := add(array, 0x20)
        }
        index = index.writeUint256(_withdrawRequest.tokenAmount);
        index = index.writeUint256(_withdrawRequest.revenue);
        index = index.writeAddress(_withdrawRequest.receiver);
        index = index.writeBytes(_withdrawRequest.iaoId);
        index = index.writeBytes(_withdrawRequest.internalTxId);

        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
    }

    /**
     * @dev Returns the eth-signed hash of the hash data
     * @param hash the input hash data
     * @return ethSignedHash the eth signed hash of the input hash data
     */
    function getEthSignedHash(bytes32 hash) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /**
     * @dev Returns the address which is recovered from the signature and the hash data
     * @param _hash the eth-signed hash data
     * @param _signature the signature which was signed by the admin
     * @return signer the address recovered from the signature and the hash data
     */
    function recoverSigner(bytes32 _hash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (_signature.length != 65) {
            return (address(0));
        }

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(_hash, v, r, s);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { BuyRequest, ClaimRequest, WithdrawRequest} from "../common/Structs.sol";

library Utils {
    
    /**
     * @dev Returns the size of a buy request struct
     */
    function sizeOfBuyRequest(BuyRequest memory _item)
        internal
        pure
        returns (uint256)
    {
        return ((0x20 * 2) +
            (0x14 * 1) +
            _item.iaoId.length +
            _item.internalTxId.length);
    }

    /**
     * @dev Returns the size of a claim request struct
     */
    function sizeOfClaimRequest(ClaimRequest memory _item)
        internal
        pure
        returns (uint256)
    {
        return ((0x20 * 3 * _item.tokenIds.length) +
            (0x14 * _item.collectionAddresses.length) +
            0x14 +
            _item.internalTxId.length);
    }

    /**
     * @dev Returns the size of a claim request struct
     */
    function sizeOfWithdrawRequest(WithdrawRequest memory _item)
        internal
        pure
        returns (uint256)
    {
        return ((0x20 * 2) +
            (0x14) 
            + _item.iaoId.length
            + _item.internalTxId.length);
    }



}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library AssemblyUtils {
    function writeUint8(uint256 index, uint8 source)
        internal
        pure
        returns (uint256)
    {
        assembly {
            mstore8(index, source)
            index := add(index, 0x1)
        }
        return index;
    }

    function writeAddress(uint256 index, address source)
        internal
        pure
        returns (uint256)
    {
        uint256 conv = uint256(uint160(source)) << 0x60;
        assembly {
            mstore(index, conv)
            index := add(index, 0x14)
        }
        return index;
    }

    function writeUint256(uint256 index, uint256 source)
        internal
        pure
        returns (uint256)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    function writeUint64(uint256 index, uint64 source)
        internal
        pure
        returns (uint256)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x8)
        }
        return index;
    }


    function writeBytes(uint256 index, bytes memory source)
        internal
        pure
        returns (uint256)
    {
        if (source.length > 0) {
            assembly {
                let length := mload(source)
                let end := add(source, add(0x20, length))
                let arrIndex := add(source, 0x20)
                let tempIndex := index
                for {

                } eq(lt(arrIndex, end), 1) {
                    arrIndex := add(arrIndex, 0x20)
                    tempIndex := add(tempIndex, 0x20)
                } {
                    mstore(tempIndex, mload(arrIndex))
                }
                index := add(index, length)
            }
        }
        return index;
    }
}