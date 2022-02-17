// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;


import "./FixinERC721Spender.sol";
import "./libs/LibNFTOrder.sol";
import "./libs/LibSignature.sol";

/// @dev Wrapper for ERC721OrdersFeature to route purchase to target.
contract ZeroExV4NftWrapper is FixinERC721Spender {

    // Proxy contract https://github.com/0xProject/protocol/blob/refactor/nft-orders/contracts/zero-ex/contracts/src/ZeroEx.sol
    address internal zeroExGateway; 

    // Method selector for buyERC721
    bytes4 internal constant buyERC721Signature = 0xfbee349d; 

    constructor(address _zeroExGateway) public {
	     zeroExGateway = _zeroExGateway;
    }

    receive() external payable {}

    /// @dev Transfers an ERC721 asset from `maker` to `to`.
    /// @param sellOrder The ERC721 sell order.
    /// @param signature The order signature.
    /// @param callbackData If this parameter is non-zero, invokes
    ///        `zeroExERC721OrderCallback` on `msg.sender` after
    ///        the ERC721 asset has been transferred to `msg.sender`
    ///        but before transferring the ERC20 tokens to the seller.
    ///        Native tokens acquired during the callback can be used
    ///        to fill the order.
    /// @param to address to transfer ERC721 asset.
    function buyERC721For(
      LibNFTOrder.ERC721Order calldata sellOrder,
      LibSignature.Signature  calldata signature,
      bytes memory callbackData,
      address to
    ) external payable {

        (bool success, bytes memory returnData) =  payable(zeroExGateway).call{value: msg.value}(abi.encodeWithSelector(buyERC721Signature, sellOrder, signature, callbackData));
        require(success, string(returnData));

       // Transfer ERC721 asset to target
       _transferERC721AssetFrom(sellOrder.erc721Token, address(this), to, sellOrder.erc721TokenId);
       
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2020 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "./interface/IERC721Token.sol";


/// @dev Helpers for moving ERC721 assets around.
abstract contract FixinERC721Spender {

    // Mask of the lower 20 bytes of a bytes32.
    uint256 constant private ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    /// @dev Transfers an ERC721 asset from `owner` to `to`.
    /// @param token The address of the ERC721 token contract.
    /// @param owner The owner of the asset.
    /// @param to The recipient of the asset.
    /// @param tokenId The token ID of the asset to transfer.
    function _transferERC721AssetFrom(
        IERC721Token token,
        address owner,
        address to,
        uint256 tokenId
    )
        internal
    {
        require(address(token) != address(this), "FixinERC721Spender/CANNOT_INVOKE_SELF");

        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transferFrom(address,address,uint256)
            mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
            mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x44), tokenId)

            let success := call(
                gas(),
                and(token, ADDRESS_MASK),
                0,
                ptr,
                0x64,
                0,
                0
            )

            if iszero(success) {
                let rdsize := returndatasize()
                returndatacopy(ptr, 0, rdsize)
                revert(ptr, rdsize)
            }
        }
    }
}

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "../interface/IERC20TokenV06.sol";
import "../interface/IPropertyValidator.sol";
import "../interface/IERC721Token.sol";


/// @dev A library for common NFT order operations.
library LibNFTOrder {

    enum OrderStatus {
        INVALID,
        FILLABLE,
        UNFILLABLE,
        EXPIRED
    }

    enum TradeDirection {
        SELL_NFT,
        BUY_NFT
    }

    struct Property {
        IPropertyValidator propertyValidator;
        bytes propertyData;
    }

    struct Fee {
        address recipient;
        uint256 amount;
        bytes feeData;
    }

    // "Base struct" for ERC721Order and ERC1155, used
    // by the abstract contract `NFTOrders`.
    struct NFTOrder {
        TradeDirection direction;
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20TokenV06 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address nft;
        uint256 nftId;
        Property[] nftProperties;
    }

    // All fields align with those of NFTOrder
    struct ERC721Order {
        TradeDirection direction;
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20TokenV06 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        IERC721Token erc721Token;
        uint256 erc721TokenId;
        Property[] erc721TokenProperties;
    }

    uint256 private constant _FEE_TYPEHASH =
        0xe68c29f1b4e8cce0bbcac76eb1334bdc1dc1f293a517c90e9e532340e1e94115;

    uint256 private constant _ERC_721_ORDER_TYPEHASH =
        0x2de32b2b090da7d8ab83ca4c85ba2eb6957bc7f6c50cb4ae1995e87560d808ed;

    uint256 private constant _PROPERTY_TYPEHASH =
        0x6292cf854241cb36887e639065eca63b3af9f7f70270cebeda4c29b6d3bc65e8;

    // keccak256("");
    bytes32 private constant _EMPTY_ARRAY_KECCAK256 =
        0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    
    bytes32 private constant _NULL_PROPERTY_STRUCT_HASH =
        0x720ee400a9024f6a49768142c339bf09d2dd9056ab52d20fbe7165faba6e142d;

    uint256 private constant ADDRESS_MASK = (1 << 160) - 1;

    /// @dev Get the struct hash of an ERC721 order.
    /// @param order The ERC721 order.
    /// @return structHash The struct hash of the order.
    function getERC721OrderStructHash(ERC721Order memory order)
        internal
        pure
        returns (bytes32 structHash)
    {
        // We give `order.erc721TokenProperties.length == 0` and
        // `order.erc721TokenProperties.length == 1` special treatment
        // because we expect these to be the most common.
        bytes32 propertiesHash;
        if (order.erc721TokenProperties.length == 0) {
            propertiesHash = _EMPTY_ARRAY_KECCAK256;
        } else if (order.erc721TokenProperties.length == 1) {
            Property memory property = order
                .erc721TokenProperties[0];
            if (
                address(property.propertyValidator) == address(0) &&
                property.propertyData.length == 0
            ) {
                propertiesHash = _NULL_PROPERTY_STRUCT_HASH;
            } else {
                // propertiesHash = keccak256(abi.encodePacked(keccak256(abi.encode(
                //     _PROPERTY_TYPEHASH,
                //     order.erc721TokenProperties[0].propertyValidator,
                //     keccak256(order.erc721TokenProperties[0].propertyData)
                // ))));
                bytes32 dataHash = keccak256(property.propertyData);
                assembly {
                    // Load free memory pointer
                    let mem := mload(64)
                    mstore(mem, _PROPERTY_TYPEHASH)
                    // property.propertyValidator
                    mstore(add(mem, 32), and(ADDRESS_MASK, mload(property)))
                    // keccak256(property.propertyData)
                    mstore(add(mem, 64), dataHash)
                    mstore(mem, keccak256(mem, 96))
                    propertiesHash := keccak256(mem, 32)
                }
            }
        } else {
            bytes32[] memory propertyStructHashArray = new bytes32[](
                order.erc721TokenProperties.length
            );
            for (uint256 i = 0; i < order.erc721TokenProperties.length; i++) {
                propertyStructHashArray[i] = keccak256(abi.encode(
                    _PROPERTY_TYPEHASH,
                    order.erc721TokenProperties[i].propertyValidator,
                    keccak256(order.erc721TokenProperties[i].propertyData)
                ));
            }
            propertiesHash = keccak256(abi.encodePacked(propertyStructHashArray));
        }

        // We give `order.fees.length == 0` and
        // `order.fees.length == 1` special treatment
        // because we expect these to be the most common.
        bytes32 feesHash;
        if (order.fees.length == 0) {
            feesHash = _EMPTY_ARRAY_KECCAK256;
        } else if (order.fees.length == 1) {
            // feesHash = keccak256(abi.encodePacked(keccak256(abi.encode(
            //     _FEE_TYPEHASH,
            //     order.fees[0].recipient,
            //     order.fees[0].amount,
            //     keccak256(order.fees[0].feeData)
            // ))));
            Fee memory fee = order.fees[0];
            bytes32 dataHash = keccak256(fee.feeData);
            assembly {
                // Load free memory pointer
                let mem := mload(64)
                mstore(mem, _FEE_TYPEHASH)
                // fee.recipient
                mstore(add(mem, 32), and(ADDRESS_MASK, mload(fee)))
                // fee.amount
                mstore(add(mem, 64), mload(add(fee, 32)))
                // keccak256(fee.feeData)
                mstore(add(mem, 96), dataHash)
                mstore(mem, keccak256(mem, 128))
                feesHash := keccak256(mem, 32)
            }
        } else {
            bytes32[] memory feeStructHashArray = new bytes32[](order.fees.length);
            for (uint256 i = 0; i < order.fees.length; i++) {
                feeStructHashArray[i] = keccak256(abi.encode(
                    _FEE_TYPEHASH,
                    order.fees[i].recipient,
                    order.fees[i].amount,
                    keccak256(order.fees[i].feeData)
                ));
            }
            feesHash = keccak256(abi.encodePacked(feeStructHashArray));
        }

        // Hash in place, equivalent to:
        // return keccak256(abi.encode(
        //     _ERC_721_ORDER_TYPEHASH,
        //     order.direction,
        //     order.maker,
        //     order.taker,
        //     order.expiry,
        //     order.nonce,
        //     order.erc20Token,
        //     order.erc20TokenAmount,
        //     feesHash,
        //     order.erc721Token,
        //     order.erc721TokenId,
        //     propertiesHash
        // ));
        assembly {
            if lt(order, 32) { invalid() } // Don't underflow memory.

            let typeHashPos := sub(order, 32) // order - 32
            let feesHashPos := add(order, 224) // order + (32 * 7)
            let propertiesHashPos := add(order, 320) // order + (32 * 10)

            let temp1 := mload(typeHashPos)
            let temp2 := mload(feesHashPos)
            let temp3 := mload(propertiesHashPos)

            mstore(typeHashPos, _ERC_721_ORDER_TYPEHASH)
            mstore(feesHashPos, feesHash)
            mstore(propertiesHashPos, propertiesHash)
            structHash := keccak256(typeHashPos, 384 /* 32 * 12 */ )

            mstore(typeHashPos, temp1)
            mstore(feesHashPos, temp2)
            mstore(propertiesHashPos, temp3)
        }
        return structHash;
    }
}

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;


/// @dev A library for validating signatures.
library LibSignature {

    /// @dev Allowed signature types.
    enum SignatureType {
        ILLEGAL,
        INVALID,
        EIP712,
        ETHSIGN,
        PRESIGNED
    }

    /// @dev Encoded EC signature.
    struct Signature {
        // How to validate the signature.
        SignatureType signatureType;
        // EC Signature data.
        uint8 v;
        // EC Signature data.
        bytes32 r;
        // EC Signature data.
        bytes32 s;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

import "./errors/LibRichErrorsV06.sol";
import "./errors/LibSafeMathRichErrorsV06.sol";


library LibSafeMathV06 {

    function safeMul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        if (c / a != b) {
            LibRichErrorsV06.rrevert(LibSafeMathRichErrorsV06.Uint256BinOpError(
                LibSafeMathRichErrorsV06.BinOpErrorCodes.MULTIPLICATION_OVERFLOW,
                a,
                b
            ));
        }
        return c;
    }

    function safeDiv(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (b == 0) {
            LibRichErrorsV06.rrevert(LibSafeMathRichErrorsV06.Uint256BinOpError(
                LibSafeMathRichErrorsV06.BinOpErrorCodes.DIVISION_BY_ZERO,
                a,
                b
            ));
        }
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (b > a) {
            LibRichErrorsV06.rrevert(LibSafeMathRichErrorsV06.Uint256BinOpError(
                LibSafeMathRichErrorsV06.BinOpErrorCodes.SUBTRACTION_UNDERFLOW,
                a,
                b
            ));
        }
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        if (c < a) {
            LibRichErrorsV06.rrevert(LibSafeMathRichErrorsV06.Uint256BinOpError(
                LibSafeMathRichErrorsV06.BinOpErrorCodes.ADDITION_OVERFLOW,
                a,
                b
            ));
        }
        return c;
    }

    function max256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function safeMul128(uint128 a, uint128 b)
        internal
        pure
        returns (uint128)
    {
        if (a == 0) {
            return 0;
        }
        uint128 c = a * b;
        if (c / a != b) {
            LibRichErrorsV06.rrevert(LibSafeMathRichErrorsV06.Uint256BinOpError(
                LibSafeMathRichErrorsV06.BinOpErrorCodes.MULTIPLICATION_OVERFLOW,
                a,
                b
            ));
        }
        return c;
    }

    function safeDiv128(uint128 a, uint128 b)
        internal
        pure
        returns (uint128)
    {
        if (b == 0) {
            LibRichErrorsV06.rrevert(LibSafeMathRichErrorsV06.Uint256BinOpError(
                LibSafeMathRichErrorsV06.BinOpErrorCodes.DIVISION_BY_ZERO,
                a,
                b
            ));
        }
        uint128 c = a / b;
        return c;
    }

    function safeSub128(uint128 a, uint128 b)
        internal
        pure
        returns (uint128)
    {
        if (b > a) {
            LibRichErrorsV06.rrevert(LibSafeMathRichErrorsV06.Uint256BinOpError(
                LibSafeMathRichErrorsV06.BinOpErrorCodes.SUBTRACTION_UNDERFLOW,
                a,
                b
            ));
        }
        return a - b;
    }

    function safeAdd128(uint128 a, uint128 b)
        internal
        pure
        returns (uint128)
    {
        uint128 c = a + b;
        if (c < a) {
            LibRichErrorsV06.rrevert(LibSafeMathRichErrorsV06.Uint256BinOpError(
                LibSafeMathRichErrorsV06.BinOpErrorCodes.ADDITION_OVERFLOW,
                a,
                b
            ));
        }
        return c;
    }

    function max128(uint128 a, uint128 b)
        internal
        pure
        returns (uint128)
    {
        return a >= b ? a : b;
    }

    function min128(uint128 a, uint128 b)
        internal
        pure
        returns (uint128)
    {
        return a < b ? a : b;
    }

    function safeDowncastToUint128(uint256 a)
        internal
        pure
        returns (uint128)
    {
        if (a > type(uint128).max) {
            LibRichErrorsV06.rrevert(LibSafeMathRichErrorsV06.Uint256DowncastError(
                LibSafeMathRichErrorsV06.DowncastErrorCodes.VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT128,
                a
            ));
        }
        return uint128(a);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2021 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;


interface IERC721Token {

    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///      This event emits when NFTs are created (`from` == 0) and destroyed
    ///      (`to` == 0). Exception: during contract creation, any number of NFTs
    ///      may be created and assigned without emitting Transfer. At the time of
    ///      any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    /// @dev This emits when the approved address for an NFT is changed or
    ///      reaffirmed. The zero address indicates there is no approved address.
    ///      When a Transfer event emits, this also indicates that the approved
    ///      address for that NFT (if any) is reset to none.
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///      The operator can manage all NFTs of the owner.
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///      perator, or the approved address for this NFT. Throws if `_from` is
    ///      not the current owner. Throws if `_to` is the zero address. Throws if
    ///      `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///      checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///      `onERC721Received` on `_to` and throws if the return value is not
    ///      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param _data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    )
        external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///      except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///      Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///      operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId)
        external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///         all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///      multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved)
        external;

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///      function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner)
        external
        view
        returns (uint256);

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///         TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///         THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///      operator, or the approved address for this NFT. Throws if `_from` is
    ///      not the current owner. Throws if `_to` is the zero address. Throws if
    ///      `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external;

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///      about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address);

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) 
        external
        view
        returns (address);
    
    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;


library LibRichErrorsV06 {

    // bytes4(keccak256("Error(string)"))
    bytes4 internal constant STANDARD_ERROR_SELECTOR = 0x08c379a0;

    // solhint-disable func-name-mixedcase
    /// @dev ABI encode a standard, string revert error payload.
    ///      This is the same payload that would be included by a `revert(string)`
    ///      solidity statement. It has the function signature `Error(string)`.
    /// @param message The error string.
    /// @return The ABI encoded error.
    function StandardError(string memory message)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            STANDARD_ERROR_SELECTOR,
            bytes(message)
        );
    }
    // solhint-enable func-name-mixedcase

    /// @dev Reverts an encoded rich revert reason `errorData`.
    /// @param errorData ABI encoded error data.
    function rrevert(bytes memory errorData)
        internal
        pure
    {
        assembly {
            revert(add(errorData, 0x20), mload(errorData))
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;


library LibSafeMathRichErrorsV06 {

    // bytes4(keccak256("Uint256BinOpError(uint8,uint256,uint256)"))
    bytes4 internal constant UINT256_BINOP_ERROR_SELECTOR =
        0xe946c1bb;

    // bytes4(keccak256("Uint256DowncastError(uint8,uint256)"))
    bytes4 internal constant UINT256_DOWNCAST_ERROR_SELECTOR =
        0xc996af7b;

    enum BinOpErrorCodes {
        ADDITION_OVERFLOW,
        MULTIPLICATION_OVERFLOW,
        SUBTRACTION_UNDERFLOW,
        DIVISION_BY_ZERO
    }

    enum DowncastErrorCodes {
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT32,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT64,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT96,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT128
    }

    // solhint-disable func-name-mixedcase
    function Uint256BinOpError(
        BinOpErrorCodes errorCode,
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            UINT256_BINOP_ERROR_SELECTOR,
            errorCode,
            a,
            b
        );
    }

    function Uint256DowncastError(
        DowncastErrorCodes errorCode,
        uint256 a
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            UINT256_DOWNCAST_ERROR_SELECTOR,
            errorCode,
            a
        );
    }
}

pragma solidity ^0.6.5;


interface IERC20TokenV06 {

    // solhint-disable no-simple-event-func-name
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /// @dev send `value` token to `to` from `msg.sender`
    /// @param to The address of the recipient
    /// @param value The amount of token to be transferred
    /// @return True if transfer was successful
    function transfer(address to, uint256 value)
        external
        returns (bool);

    /// @dev send `value` token to `to` from `from` on the condition it is approved by `from`
    /// @param from The address of the sender
    /// @param to The address of the recipient
    /// @param value The amount of token to be transferred
    /// @return True if transfer was successful
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        external
        returns (bool);

    /// @dev `msg.sender` approves `spender` to spend `value` tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @param value The amount of wei to be approved for transfer
    /// @return Always true if the call has enough gas to complete execution
    function approve(address spender, uint256 value)
        external
        returns (bool);

    /// @dev Query total supply of token
    /// @return Total supply of token
    function totalSupply()
        external
        view
        returns (uint256);

    /// @dev Get the balance of `owner`.
    /// @param owner The address from which the balance will be retrieved
    /// @return Balance of owner
    function balanceOf(address owner)
        external
        view
        returns (uint256);

    /// @dev Get the allowance for `spender` to spend from `owner`.
    /// @param owner The address of the account owning tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /// @dev Get the number of decimals this token has.
    function decimals()
        external
        view
        returns (uint8);
}

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;


interface IPropertyValidator {

    /// @dev Checks that the given ERC721/ERC1155 asset satisfies the properties encoded in `propertyData`.
    ///      Should revert if the asset does not satisfy the specified properties.
    /// @param tokenAddress The ERC721/ERC1155 token contract address.
    /// @param tokenId The ERC721/ERC1155 tokenId of the asset to check.
    /// @param propertyData Encoded properties or auxiliary data needed to perform the check.
    function validateProperty(
        address tokenAddress,
        uint256 tokenId,
        bytes calldata propertyData
    )
        external
        view;
}