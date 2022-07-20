// SPDX-License-Identifier: MIT
/*

  << Static >>

*/

pragma solidity ^0.8.14;

import "./static/StaticERC20.sol";
import "./static/StaticERC721.sol";
import "./static/StaticERC1155.sol";
import "./static/StaticUtil.sol";

contract XCROWStatic is StaticERC20, StaticERC721, StaticERC1155, StaticUtil {
    string public constant name = "Main Static";

    constructor(address atomicizerAddress) public {
        atomicizer = atomicizerAddress;
    }

    function test() public pure {}
}

// SPDX-License-Identifier: MIT
/*

    StaticERC20 - static calls for ERC20 trades

*/

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../lib/ArrayUtils.sol";
//import "../registry/AuthenticatedProxy.sol";
import "../exchange/ExchangeCore.sol";

contract StaticERC20 {
    function transferERC20Exact(
        bytes memory extra,
        address[7] memory addresses,
        ExchangeCore.HowToCall howToCall,
        uint256[6] memory,
        bytes memory data
    ) public pure {
        // Decode extradata
        (address token, uint256 amount) = abi.decode(extra, (address, uint256));

        // Call target = token to give
        require(addresses[2] == token);
        // Call type = call
        require(howToCall == ExchangeCore.HowToCall.Call);
        // Assert calldata
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[1],
                    addresses[4],
                    amount
                )
            )
        );
    }

    function swapExact(
        bytes memory extra,
        address[7] memory addresses,
        ExchangeCore.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        // Zero-value
        require(uints[0] == 0);

        // Decode extradata
        (address[2] memory tokenGiveGet, uint256[2] memory amountGiveGet) = abi
            .decode(extra, (address[2], uint256[2]));

        // Call target = token to give
        require(addresses[2] == tokenGiveGet[0]);
        // Call type = call
        require(howToCalls[0] == ExchangeCore.HowToCall.Call);
        // Assert calldata
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[1],
                    addresses[4],
                    amountGiveGet[0]
                )
            )
        );

        require(addresses[5] == tokenGiveGet[1]);
        // Countercall type = call
        require(howToCalls[1] == ExchangeCore.HowToCall.Call);
        // Assert countercalldata
        require(
            ArrayUtils.arrayEq(
                counterdata,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[4],
                    addresses[1],
                    amountGiveGet[1]
                )
            )
        );

        // Mark filled.
        return 1;
    }

    function swapForever(
        bytes memory extra,
        address[7] memory addresses,
        ExchangeCore.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        // Calculate function signature
        bytes memory sig = ArrayUtils.arrayTake(
            abi.encodeWithSignature("transferFrom(address,address,uint256)"),
            4
        );

        // Zero-value
        require(uints[0] == 0);

        // Decode extradata
        (
            address[2] memory tokenGiveGet,
            uint256[2] memory numeratorDenominator
        ) = abi.decode(extra, (address[2], uint256[2]));

        // Call target = token to give
        require(addresses[2] == tokenGiveGet[0]);
        // Call type = call
        require(howToCalls[0] == ExchangeCore.HowToCall.Call);
        // Check signature
        require(ArrayUtils.arrayEq(sig, ArrayUtils.arrayTake(data, 4)));
        // Decode calldata
        (address callFrom, address callTo, uint256 amountGive) = abi.decode(
            ArrayUtils.arrayDrop(data, 4),
            (address, address, uint256)
        );
        // Assert from
        require(callFrom == addresses[1]);
        // Assert to
        require(callTo == addresses[4]);

        // Countercall target = token to get
        require(addresses[5] == tokenGiveGet[1]);
        // Countercall type = call
        require(howToCalls[1] == ExchangeCore.HowToCall.Call);
        // Check signature
        require(ArrayUtils.arrayEq(sig, ArrayUtils.arrayTake(counterdata, 4)));
        // Decode countercalldata
        (
            address countercallFrom,
            address countercallTo,
            uint256 amountGet
        ) = abi.decode(
                ArrayUtils.arrayDrop(counterdata, 4),
                (address, address, uint256)
            );
        // Assert from
        require(countercallFrom == addresses[4]);
        // Assert to
        require(countercallTo == addresses[1]);

        // Assert ratio
        // ratio = min get/give
        require(
            SafeMath.mul(amountGet, numeratorDenominator[1]) >=
                SafeMath.mul(amountGive, numeratorDenominator[0])
        );

        // Order will be set with maximumFill = 2 (to allow signature caching)
        return 1;
    }
}

// SPDX-License-Identifier: MIT
/*

    StaticERC721 - static calls for ERC721 trades

*/

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../lib/ArrayUtils.sol";
//import "../registry/AuthenticatedProxy.sol";
import "../exchange/ExchangeCore.sol";

contract StaticERC721 {
    function transferERC721Exact(
        bytes memory extra,
        address[7] memory addresses,
        ExchangeCore.HowToCall howToCall,
        uint256[6] memory,
        bytes memory data
    ) public pure {
        // Decode extradata
        (address token, uint256 tokenId) = abi.decode(
            extra,
            (address, uint256)
        );

        // Call target = token to give
        require(addresses[2] == token);
        // Call type = call
        require(howToCall == ExchangeCore.HowToCall.Call);
        // Assert calldata
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[1],
                    addresses[4],
                    tokenId
                )
            )
        );
    }

    function swapOneForOneERC721(
        bytes memory extra,
        address[7] memory addresses,
        ExchangeCore.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        // Zero-value
        require(uints[0] == 0);

        // Decode extradata
        (address[2] memory tokenGiveGet, uint256[2] memory nftGiveGet) = abi
            .decode(extra, (address[2], uint256[2]));

        // Call target = token to give
        require(
            addresses[2] == tokenGiveGet[0],
            "ERC721: call target must equal address of token to give"
        );
        // Call type = call
        require(
            howToCalls[0] == ExchangeCore.HowToCall.Call,
            "ERC721: call must be a direct call"
        );
        // Assert calldata
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[1],
                    addresses[4],
                    nftGiveGet[0]
                )
            )
        );

        // Countercall target = token to get
        require(
            addresses[5] == tokenGiveGet[1],
            "ERC721: countercall target must equal address of token to get"
        );
        // Countercall type = call
        require(
            howToCalls[1] == ExchangeCore.HowToCall.Call,
            "ERC721: countercall must be a direct call"
        );
        // Assert countercalldata
        require(
            ArrayUtils.arrayEq(
                counterdata,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    addresses[4],
                    addresses[1],
                    nftGiveGet[1]
                )
            )
        );

        // Mark filled
        return 1;
    }

    function swapOneForOneERC721Decoding(
        bytes memory extra,
        address[7] memory addresses,
        ExchangeCore.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        // Calculate function signature
        bytes memory sig = ArrayUtils.arrayTake(
            abi.encodeWithSignature("transferFrom(address,address,uint256)"),
            4
        );

        // Zero-value
        require(uints[0] == 0);

        // Decode extradata
        (address[2] memory tokenGiveGet, uint256[2] memory nftGiveGet) = abi
            .decode(extra, (address[2], uint256[2]));

        // Call target = token to give
        require(
            addresses[2] == tokenGiveGet[0],
            "ERC721: call target must equal address of token to give"
        );
        // Call type = call
        require(
            howToCalls[0] == ExchangeCore.HowToCall.Call,
            "ERC721: call must be a direct call"
        );
        // Assert signature
        require(ArrayUtils.arrayEq(sig, ArrayUtils.arrayTake(data, 4)));
        // Decode calldata
        (address callFrom, address callTo, uint256 nftGive) = abi.decode(
            ArrayUtils.arrayDrop(data, 4),
            (address, address, uint256)
        );
        // Assert from
        require(callFrom == addresses[1]);
        // Assert to
        require(callTo == addresses[4]);
        // Assert NFT
        require(nftGive == nftGiveGet[0]);

        // Countercall target = token to get
        require(
            addresses[5] == tokenGiveGet[1],
            "ERC721: countercall target must equal address of token to get"
        );
        // Countercall type = call
        require(
            howToCalls[1] == ExchangeCore.HowToCall.Call,
            "ERC721: countercall must be a direct call"
        );
        // Assert signature
        require(ArrayUtils.arrayEq(sig, ArrayUtils.arrayTake(counterdata, 4)));
        // Decode countercalldata
        (address countercallFrom, address countercallTo, uint256 nftGet) = abi
            .decode(
                ArrayUtils.arrayDrop(counterdata, 4),
                (address, address, uint256)
            );
        // Assert from
        require(countercallFrom == addresses[4]);
        // Assert to
        require(countercallTo == addresses[1]);
        // Assert NFT
        require(nftGet == nftGiveGet[1]);

        // Mark filled
        return 1;
    }
}

// SPDX-License-Identifier: MIT
/*

StaticERC1155 - static calls for ERC1155 trades

*/

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../lib/ArrayUtils.sol";
//import "../registry/AuthenticatedProxy.sol";
import "../exchange/ExchangeCore.sol";

contract StaticERC1155 {
    function transferERC1155Exact(
        bytes memory extra,
        address[7] memory addresses,
        ExchangeCore.HowToCall howToCall,
        uint256[6] memory,
        bytes memory data
    ) public pure {
        // Decode extradata
        (address token, uint256 tokenId, uint256 amount) = abi.decode(
            extra,
            (address, uint256, uint256)
        );

        // Call target = token to give
        require(addresses[2] == token);
        // Call type = call
        require(howToCall == ExchangeCore.HowToCall.Call);
        // Assert calldata
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,uint256,bytes)",
                    addresses[1],
                    addresses[4],
                    tokenId,
                    amount,
                    ""
                )
            )
        );
    }

    function swapOneForOneERC1155(
        bytes memory extra,
        address[7] memory addresses,
        ExchangeCore.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        // Zero-value
        require(uints[0] == 0);

        // Decode extradata
        (
            address[2] memory tokenGiveGet,
            uint256[2] memory nftGiveGet,
            uint256[2] memory nftAmounts
        ) = abi.decode(extra, (address[2], uint256[2], uint256[2]));

        // Call target = token to give
        require(
            addresses[2] == tokenGiveGet[0],
            "ERC1155: call target must equal address of token to give"
        );
        // Assert more than zero
        require(
            nftAmounts[0] > 0,
            "ERC1155: give amount must be larger than zero"
        );
        // Call type = call
        require(
            howToCalls[0] == ExchangeCore.HowToCall.Call,
            "ERC1155: call must be a direct call"
        );
        // Assert calldata
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,uint256,bytes)",
                    addresses[1],
                    addresses[4],
                    nftGiveGet[0],
                    nftAmounts[0],
                    ""
                )
            )
        );

        // Countercall target = token to get
        require(
            addresses[5] == tokenGiveGet[1],
            "ERC1155: countercall target must equal address of token to get"
        );
        // Assert more than zero
        require(
            nftAmounts[1] > 0,
            "ERC1155: take amount must be larger than zero"
        );
        // Countercall type = call
        require(
            howToCalls[1] == ExchangeCore.HowToCall.Call,
            "ERC1155: countercall must be a direct call"
        );
        // Assert countercalldata
        require(
            ArrayUtils.arrayEq(
                counterdata,
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,uint256,bytes)",
                    addresses[4],
                    addresses[1],
                    nftGiveGet[1],
                    nftAmounts[1],
                    ""
                )
            )
        );

        // Mark filled
        return 1;
    }

    function swapOneForOneERC1155Decoding(
        bytes memory extra,
        address[7] memory addresses,
        ExchangeCore.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public pure returns (uint256) {
        // Calculate function signature
        bytes memory sig = ArrayUtils.arrayTake(
            abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256,uint256,bytes)"
            ),
            4
        );

        // Zero-value
        require(uints[0] == 0);

        // Decode extradata
        (
            address[2] memory tokenGiveGet,
            uint256[2] memory nftGiveGet,
            uint256[2] memory nftAmounts
        ) = abi.decode(extra, (address[2], uint256[2], uint256[2]));

        // Call target = token to give
        require(
            addresses[2] == tokenGiveGet[0],
            "ERC1155: call target must equal address of token to give"
        );
        // Call type = call
        require(
            howToCalls[0] == ExchangeCore.HowToCall.Call,
            "ERC1155: call must be a direct call"
        );
        // Assert signature
        require(ArrayUtils.arrayEq(sig, ArrayUtils.arrayTake(data, 4)));
        // Decode and assert calldata
        require(
            ArrayUtils.arrayEq(
                data,
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,uint256,bytes)",
                    addresses[1],
                    addresses[4],
                    nftGiveGet[0],
                    nftAmounts[0],
                    ""
                )
            )
        );
        // Decode and assert countercalldata
        require(
            ArrayUtils.arrayEq(
                counterdata,
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,uint256,bytes)",
                    addresses[4],
                    addresses[1],
                    nftGiveGet[1],
                    nftAmounts[1],
                    ""
                )
            )
        );

        // Mark filled
        return 1;
    }
}

// SPDX-License-Identifier: MIT
/*

    StaticUtil - static call utility contract

*/
pragma solidity ^0.8.14;

import "../lib/StaticCaller.sol";
import "../lib/ArrayUtils.sol";
//import "../registry/AuthenticatedProxy.sol";
import "../exchange/ExchangeCore.sol";

contract StaticUtil is StaticCaller {
    address public atomicizer;

    function any(
        bytes memory,
        address[7] memory,
        ExchangeCore.HowToCall[2] memory,
        uint256[6] memory,
        bytes memory,
        bytes memory
    ) public pure returns (uint256) {
        /*
           Accept any call.
           Useful e.g. for matching-by-transaction, where you authorize the counter-call by sending the transaction and don't need to re-check it.
           Return fill "1".
        */

        return 1;
    }

    function anySingle(
        bytes memory,
        address[7] memory,
        ExchangeCore.HowToCall,
        uint256[6] memory,
        bytes memory
    ) public pure {
        /* No checks. */
    }

    function anyNoFill(
        bytes memory,
        address[7] memory,
        ExchangeCore.HowToCall[2] memory,
        uint256[6] memory,
        bytes memory,
        bytes memory
    ) public pure returns (uint256) {
        /*
           Accept any call.
           Useful e.g. for matching-by-transaction, where you authorize the counter-call by sending the transaction and don't need to re-check it.
           Return fill "0".
        */

        return 0;
    }

    function anyAddOne(
        bytes memory,
        address[7] memory,
        ExchangeCore.HowToCall[2] memory,
        uint256[6] memory uints,
        bytes memory,
        bytes memory
    ) public pure returns (uint256) {
        /*
           Accept any call.
           Useful e.g. for matching-by-transaction, where you authorize the counter-call by sending the transaction and don't need to re-check it.
           Return the current fill plus 1.
        */

        return uints[5] + 1;
    }

    function split(
        bytes memory extra,
        address[7] memory addresses,
        ExchangeCore.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public view returns (uint256) {
        (
            address[2] memory targets,
            bytes4[2] memory selectors,
            bytes memory firstExtradata,
            bytes memory secondExtradata
        ) = abi.decode(extra, (address[2], bytes4[2], bytes, bytes));

        /* Split into two static calls: one for the call, one for the counter-call, both with metadata. */

        /* Static call to check the call. */
        require(
            staticCall(
                targets[0],
                abi.encodeWithSelector(
                    selectors[0],
                    firstExtradata,
                    addresses,
                    howToCalls[0],
                    uints,
                    data
                )
            )
        );

        /* Static call to check the counter-call. */
        require(
            staticCall(
                targets[1],
                abi.encodeWithSelector(
                    selectors[1],
                    secondExtradata,
                    [
                        addresses[3],
                        addresses[4],
                        addresses[5],
                        addresses[0],
                        addresses[1],
                        addresses[2],
                        addresses[6]
                    ],
                    howToCalls[1],
                    uints,
                    counterdata
                )
            )
        );

        return 1;
    }

    function splitAddOne(
        bytes memory extra,
        address[7] memory addresses,
        ExchangeCore.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public view returns (uint256) {
        split(extra, addresses, howToCalls, uints, data, counterdata);
        return uints[5] + 1;
    }

    function and(
        bytes memory extra,
        address[7] memory addresses,
        ExchangeCore.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public view {
        (
            address[] memory addrs,
            bytes4[] memory selectors,
            uint256[] memory extradataLengths,
            bytes memory extradatas
        ) = abi.decode(extra, (address[], bytes4[], uint256[], bytes));

        require(addrs.length == extradataLengths.length);

        uint256 j = 0;
        for (uint256 i = 0; i < addrs.length; i++) {
            bytes memory extradata = new bytes(extradataLengths[i]);
            for (uint256 k = 0; k < extradataLengths[i]; k++) {
                extradata[k] = extradatas[j];
                j++;
            }
            require(
                staticCall(
                    addrs[i],
                    abi.encodeWithSelector(
                        selectors[i],
                        extradata,
                        addresses,
                        howToCalls,
                        uints,
                        data,
                        counterdata
                    )
                )
            );
        }
    }

    function or(
        bytes memory extra,
        address[7] memory addresses,
        ExchangeCore.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory data,
        bytes memory counterdata
    ) public view {
        (
            address[] memory addrs,
            bytes4[] memory selectors,
            uint256[] memory extradataLengths,
            bytes memory extradatas
        ) = abi.decode(extra, (address[], bytes4[], uint256[], bytes));

        require(
            addrs.length == extradataLengths.length,
            "Different number of static call addresses and extradatas"
        );

        uint256 j = 0;
        for (uint256 i = 0; i < addrs.length; i++) {
            bytes memory extradata = new bytes(extradataLengths[i]);
            for (uint256 k = 0; k < extradataLengths[i]; k++) {
                extradata[k] = extradatas[j];
                j++;
            }
            if (
                staticCall(
                    addrs[i],
                    abi.encodeWithSelector(
                        selectors[i],
                        extradata,
                        addresses,
                        howToCalls,
                        uints,
                        data,
                        counterdata
                    )
                )
            ) {
                return;
            }
        }

        revert("No static calls succeeded");
    }

    function sequenceExact(
        bytes memory extra,
        address[7] memory addresses,
        ExchangeCore.HowToCall howToCall,
        uint256[6] memory uints,
        bytes memory cdata
    ) public view {
        (
            address[] memory addrs,
            uint256[] memory extradataLengths,
            bytes4[] memory selectors,
            bytes memory extradatas
        ) = abi.decode(extra, (address[], uint256[], bytes4[], bytes));

        /* Assert DELEGATECALL to atomicizer library with given call sequence, split up predicates accordingly.
           e.g. transferring two CryptoKitties in sequence. */

        require(addrs.length == extradataLengths.length);

        (
            address[] memory caddrs,
            uint256[] memory cvals,
            uint256[] memory clengths,
            bytes memory calldatas
        ) = abi.decode(
                ArrayUtils.arrayDrop(cdata, 4),
                (address[], uint256[], uint256[], bytes)
            );

        require(addresses[2] == atomicizer);
        require(howToCall == ExchangeCore.HowToCall.DelegateCall);
        require(addrs.length == caddrs.length); // Exact calls only

        for (uint256 i = 0; i < addrs.length; i++) {
            require(cvals[i] == 0);
        }

        sequence(
            caddrs,
            clengths,
            calldatas,
            addresses,
            uints,
            addrs,
            extradataLengths,
            selectors,
            extradatas
        );
    }

    function dumbSequenceExact(
        bytes memory extra,
        address[7] memory addresses,
        ExchangeCore.HowToCall[2] memory howToCalls,
        uint256[6] memory uints,
        bytes memory cdata,
        bytes memory
    ) public view returns (uint256) {
        sequenceExact(extra, addresses, howToCalls[0], uints, cdata);

        return 1;
    }

    function sequenceAnyAfter(
        bytes memory extra,
        address[7] memory addresses,
        ExchangeCore.HowToCall howToCall,
        uint256[6] memory uints,
        bytes memory cdata
    ) public view {
        (
            address[] memory addrs,
            uint256[] memory extradataLengths,
            bytes4[] memory selectors,
            bytes memory extradatas
        ) = abi.decode(extra, (address[], uint256[], bytes4[], bytes));

        /* Assert DELEGATECALL to atomicizer library with given call sequence, split up predicates accordingly.
           e.g. transferring two CryptoKitties in sequence. */

        require(addrs.length == extradataLengths.length);

        (
            address[] memory caddrs,
            uint256[] memory cvals,
            uint256[] memory clengths,
            bytes memory calldatas
        ) = abi.decode(
                ArrayUtils.arrayDrop(cdata, 4),
                (address[], uint256[], uint256[], bytes)
            );

        require(addresses[2] == atomicizer);
        require(howToCall == ExchangeCore.HowToCall.DelegateCall);
        require(addrs.length <= caddrs.length); // Extra calls OK

        for (uint256 i = 0; i < addrs.length; i++) {
            require(cvals[i] == 0);
        }

        sequence(
            caddrs,
            clengths,
            calldatas,
            addresses,
            uints,
            addrs,
            extradataLengths,
            selectors,
            extradatas
        );
    }

    function sequence(
        address[] memory caddrs,
        uint256[] memory clengths,
        bytes memory calldatas,
        address[7] memory addresses,
        uint256[6] memory uints,
        address[] memory addrs,
        uint256[] memory extradataLengths,
        bytes4[] memory selectors,
        bytes memory extradatas
    ) internal view {
        uint256 j = 0;
        uint256 l = 0;
        for (uint256 i = 0; i < addrs.length; i++) {
            bytes memory extradata = new bytes(extradataLengths[i]);
            for (uint256 k = 0; k < extradataLengths[i]; k++) {
                extradata[k] = extradatas[j];
                j++;
            }
            bytes memory data = new bytes(clengths[i]);
            for (uint256 m = 0; m < clengths[i]; m++) {
                data[m] = calldatas[l];
                l++;
            }
            addresses[2] = caddrs[i];
            require(
                staticCall(
                    addrs[i],
                    abi.encodeWithSelector(
                        selectors[i],
                        extradata,
                        addresses,
                        ExchangeCore.HowToCall.Call,
                        uints,
                        data
                    )
                )
            );
        }
        require(j == extradatas.length);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
/*

  << ArrayUtils >>

  Various functions for manipulating arrays in Solidity.
  This library is completely inlined and does not need to be deployed or linked.

*/

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library ArrayUtils {
    /**
     * Replace bytes in an array with bytes in another array, guarded by a bitmask
     * Efficiency of this function is a bit unpredictable because of the EVM's word-specific model (arrays under 32 bytes will be slower)
     * Modifies the provided byte array parameter in place
     *
     * @dev Mask must be the size of the byte array. A nonzero byte means the byte array can be changed.
     * @param array The original array
     * @param desired The target array
     * @param mask The mask specifying which bits can be changed
     */
    function guardedArrayReplace(
        bytes memory array,
        bytes memory desired,
        bytes memory mask
    ) internal pure {
        require(
            array.length == desired.length,
            "Arrays have different lengths"
        );
        require(
            array.length == mask.length,
            "Array and mask have different lengths"
        );

        uint256 words = array.length / 0x20;
        uint256 index = words * 0x20;
        assert(index / 0x20 == words);
        uint256 i;

        for (i = 0; i < words; i++) {
            /* Conceptually: array[i] = (!mask[i] && array[i]) || (mask[i] && desired[i]), bitwise in word chunks. */
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(
                    add(array, commonIndex),
                    or(
                        and(not(maskValue), mload(add(array, commonIndex))),
                        and(maskValue, mload(add(desired, commonIndex)))
                    )
                )
            }
        }

        /* Deal with the last section of the byte array. */
        if (words > 0) {
            /* This overlaps with bytes already set but is still more efficient than iterating through each of the remaining bytes individually. */
            i = words;
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(
                    add(array, commonIndex),
                    or(
                        and(not(maskValue), mload(add(array, commonIndex))),
                        and(maskValue, mload(add(desired, commonIndex)))
                    )
                )
            }
        } else {
            /* If the byte array is shorter than a word, we must unfortunately do the whole thing bytewise.
               (bounds checks could still probably be optimized away in assembly, but this is a rare case) */
            for (i = index; i < array.length; i++) {
                array[i] =
                    ((mask[i] ^ 0xff) & array[i]) |
                    (mask[i] & desired[i]);
            }
        }
    }

    /**
     * Test if two arrays are equal
     * Source: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
     *
     * @dev Arrays must be of equal length, otherwise will return false
     * @param a First array
     * @param b Second array
     * @return Whether or not all bytes in the arrays are equal
     */
    function arrayEq(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
        bool success = true;

        assembly {
            let length := mload(a)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(b))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(a, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(b, 0x20)
                    // the next line is the loop condition:
                    // while(uint(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    /**
     * Drop the beginning of an array
     *
     * @param _bytes array
     * @param _start start index
     * @return Whether or not all bytes in the arrays are equal
     */
    function arrayDrop(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (bytes memory)
    {
        uint256 _length = SafeMath.sub(_bytes.length, _start);
        return arraySlice(_bytes, _start, _length);
    }

    /**
     * Take from the beginning of an array
     *
     * @param _bytes array
     * @param _length elements to take
     * @return Whether or not all bytes in the arrays are equal
     */
    function arrayTake(bytes memory _bytes, uint256 _length)
        internal
        pure
        returns (bytes memory)
    {
        return arraySlice(_bytes, 0, _length);
    }

    /**
     * Slice an array
     * Source: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
     *
     * @param _bytes array
     * @param _start start index
     * @param _length length to take
     * @return Whether or not all bytes in the arrays are equal
     */
    function arraySlice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    /**
     * Unsafe write byte array into a memory location
     *
     * @param index Memory location
     * @param source Byte array to write
     * @return End memory index
     */
    function unsafeWriteBytes(uint256 index, bytes memory source)
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

    /**
     * Unsafe write address into a memory location
     *
     * @param index Memory location
     * @param source Address to write
     * @return End memory index
     */
    function unsafeWriteAddress(uint256 index, address source)
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

    /**
     * Unsafe write uint into a memory location
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteUint(uint256 index, uint256 source)
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

    /**
     * Unsafe write uint8 into a memory location
     *
     * @param index Memory location
     * @param source uint8 to write
     * @return End memory index
     */
    function unsafeWriteUint8(uint256 index, uint8 source)
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
}

// SPDX-License-Identifier: MIT
/*

  << Exchange Core >>

*/

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../lib/StaticCaller.sol";
import "../lib/ReentrancyGuarded.sol";
import "../lib/EIP712.sol";
import "../lib/EIP1271.sol";

contract ExchangeCore is ReentrancyGuarded, StaticCaller, EIP712 {
    bytes4 internal constant EIP_1271_MAGICVALUE = 0x20c13b0b;
    bytes internal personalSignPrefix = "\x19Ethereum Signed Message:\n";

    enum HowToCall {
        Call,
        DelegateCall
    }
    /* Struct definitions. */

    /* An order, convenience struct. */
    struct Order {
        /* Order registry address. */
        address registry;
        /* Order maker address. */
        address maker;
        /* Order static target. */
        address staticTarget;
        /* Order static selector. */
        bytes4 staticSelector;
        /* Order static extradata. */
        bytes staticExtradata;
        /* Order maximum fill factor. */
        uint256 maximumFill;
        /* Order listing timestamp. */
        uint256 listingTime;
        /* Order expiration timestamp - 0 for no expiry. */
        uint256 expirationTime;
        /* Order salt to prevent duplicate hashes. */
        uint256 salt;
    }

    /* A call, convenience struct. */
    struct Call {
        /* Target */
        address target;
        /* How to call */
        HowToCall howToCall;
        /* Calldata */
        bytes data;
    }

    /* Constants */
    // AuthenticatedProxy proxy;
    /* Order typehash for EIP 712 compatibility. */
    bytes32 constant ORDER_TYPEHASH =
        keccak256(
            "Order(address registry,address maker,address staticTarget,bytes4 staticSelector,bytes staticExtradata,uint256 maximumFill,uint256 listingTime,uint256 expirationTime,uint256 salt)"
        );

    /* Variables */

    /* Trusted proxy registry contracts. */
    mapping(address => bool) public registries;

    /* Order fill status, by maker address then by hash. */
    mapping(address => mapping(bytes32 => uint256)) public fills;

    /* Orders verified by on-chain approval.
       Alternative to ECDSA signatures so that smart contracts can place orders directly.
       By maker address, then by hash. */
    mapping(address => mapping(bytes32 => bool)) public approved;

    /* Events */

    event OrderApproved(
        bytes32 indexed hash,
        address registry,
        address indexed maker,
        address staticTarget,
        bytes4 staticSelector,
        bytes staticExtradata,
        uint256 maximumFill,
        uint256 listingTime,
        uint256 expirationTime,
        uint256 salt,
        bool orderbookInclusionDesired
    );
    event OrderFillChanged(
        bytes32 indexed hash,
        address indexed maker,
        uint256 newFill
    );
    event OrdersMatched(
        bytes32 firstHash,
        bytes32 secondHash,
        address indexed firstMaker,
        address indexed secondMaker,
        uint256 newFirstFill,
        uint256 newSecondFill,
        bytes32 indexed metadata
    );

    constructor(/*address _authenticatedProxy*/) {
       // proxy = AuthenticatedProxy(payable(address(_authenticatedProxy)));
    }

    /* Functions */

    function hashOrder(Order memory order)
        internal
        pure
        returns (bytes32 hash)
    {
        /* Per EIP 712. */
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.registry,
                    order.maker,
                    order.staticTarget,
                    order.staticSelector,
                    keccak256(order.staticExtradata),
                    order.maximumFill,
                    order.listingTime,
                    order.expirationTime,
                    order.salt
                )
            );
    }

    function hashToSign(bytes32 orderHash)
        internal
        view
        returns (bytes32 hash)
    {
        /* Calculate the string a user must sign. */
        return
            keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, orderHash)
            );
    }

    function exists(address what) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(what)
        }
        return size > 0;
    }

    function validateOrderParameters(Order memory order, bytes32 hash)
        internal
        view
        returns (bool)
    {
        /* Order must be listed and not be expired. */
        if (
            order.listingTime > block.timestamp ||
            (order.expirationTime != 0 &&
                order.expirationTime <= block.timestamp)
        ) {
            return false;
        }

        /* Order must not have already been completely filled. */
        if (fills[order.maker][hash] >= order.maximumFill) {
            return false;
        }

        /* Order static target must exist. */
        if (!exists(order.staticTarget)) {
            return false;
        }

        return true;
    }

    function validateOrderAuthorization(
        bytes32 hash,
        address maker,
        bytes memory signature
    ) internal view returns (bool) {
        /* Memoized authentication. If order has already been partially filled, order must be authenticated. */
        if (fills[maker][hash] > 0) {
            return true;
        }

        /* Order authentication. Order must be either: */

        /* (a): sent by maker */
        if (maker == msg.sender) {
            return true;
        }

        /* (b): previously approved */
        if (approved[maker][hash]) {
            return true;
        }

        /* Calculate hash which must be signed. */
        bytes32 calculatedHashToSign = hashToSign(hash);

        /* Determine whether signer is a contract or account. */
        bool isContract = exists(maker);

        /* (c): Contract-only authentication: EIP/ERC 1271. */
        if (isContract) {
            if (
                ERC1271(maker).isValidSignature(
                    abi.encodePacked(calculatedHashToSign),
                    signature
                ) == EIP_1271_MAGICVALUE
            ) {
                return true;
            }
            return false;
        }

        /* (d): Account-only authentication: ECDSA-signed by maker. */
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(
            signature,
            (uint8, bytes32, bytes32)
        );

        address isMaker = ecrecover(
            keccak256(
                abi.encodePacked(personalSignPrefix, "32", calculatedHashToSign)
            ),
            v,
            r,
            s
        );

        if (isMaker == maker) {
            // EthSign byte
            /* (d.1): Old way: order hash signed by maker using the prefixed personal_sign */
            return true;
        }
        // /* (d.2): New way: order hash signed by maker using sign_typed_data */
        // else if (ecrecover(calculatedHashToSign, v, r, s) == maker) {
        //     return true;
        // }
        return false;
    }

    function encodeStaticCall(
        Order memory order,
        Call memory call,
        Order memory counterorder,
        Call memory countercall,
        address matcher,
        uint256 value,
        uint256 fill
    ) internal pure returns (bytes memory) {
        /* This array wrapping is necessary to preserve static call target function stack space. */
        address[7] memory addresses = [
            order.registry,
            order.maker,
            call.target,
            counterorder.registry,
            counterorder.maker,
            countercall.target,
            matcher
        ];
        HowToCall[2] memory howToCalls = [
            call.howToCall,
            countercall.howToCall
        ];
        uint256[6] memory uints = [
            value,
            order.maximumFill,
            order.listingTime,
            order.expirationTime,
            counterorder.listingTime,
            fill
        ];
        return
            abi.encodeWithSelector(
                order.staticSelector,
                order.staticExtradata,
                addresses,
                howToCalls,
                uints,
                call.data,
                countercall.data
            );
    }

    function executeStaticCall(
        Order memory order,
        Call memory call,
        Order memory counterorder,
        Call memory countercall,
        address matcher,
        uint256 value,
        uint256 fill
    ) internal view returns (uint256) {
        return
            staticCallUint(
                order.staticTarget,
                encodeStaticCall(
                    order,
                    call,
                    counterorder,
                    countercall,
                    matcher,
                    value,
                    fill
                )
            );
    }

    function executeCall(Call memory call) internal returns (bool) {
        // /* Assert valid registry. */
        // require(registries[address(registry)]);

        /* Assert target exists. */
        require(exists(call.target), "Call target does not exist");

        // /* Retrieve delegate proxy contract. */
        // OwnableDelegateProxy delegateProxy = registry.proxies((maker));

        // /* Assert existence. */
        // require(
        //     address(delegateProxy) != address(0),
        //     "Delegate proxy does not exist for maker"
        // );

        /* Assert implementation. */
        // require(
        //     delegateProxy.implementation() ==
        //         registry.delegateProxyImplementation(),
        //     "Incorrect delegate proxy implementation for maker"
        // );

        /* Typecast. */

        // AuthenticatedProxy proxy = AuthenticatedProxy(
        //     payable(address(delegateProxy))
        // );

        /* Execute order. */
        return _proxy(call.target, call.howToCall, call.data);
    }

    function approveOrderHash(bytes32 hash) internal {
        /* CHECKS */

        /* Assert order has not already been approved. */
        require(!approved[msg.sender][hash], "Order has already been approved");

        /* EFFECTS */

        /* Mark order as approved. */
        approved[msg.sender][hash] = true;
    }

    function approveOrder(Order memory order, bool orderbookInclusionDesired)
        internal
    {
        /* CHECKS */

        /* Assert sender is authorized to approve order. */
        require(
            order.maker == msg.sender,
            "Sender is not the maker of the order and thus not authorized to approve it"
        );

        /* Calculate order hash. */
        bytes32 hash = hashOrder(order);

        /* Approve order hash. */
        approveOrderHash(hash);

        /* Log approval event. */
        emit OrderApproved(
            hash,
            order.registry,
            order.maker,
            order.staticTarget,
            order.staticSelector,
            order.staticExtradata,
            order.maximumFill,
            order.listingTime,
            order.expirationTime,
            order.salt,
            orderbookInclusionDesired
        );
    }

    function setOrderFill(bytes32 hash, uint256 fill) internal {
        /* CHECKS */

        /* Assert fill is not already set. */
        require(
            fills[msg.sender][hash] != fill,
            "Fill is already set to the desired value"
        );

        /* EFFECTS */

        /* Mark order as accordingly filled. */
        fills[msg.sender][hash] = fill;

        /* Log order fill change event. */
        emit OrderFillChanged(hash, msg.sender, fill);
    }

    function atomicMatch(
        Order memory firstOrder,
        Call memory firstCall,
        Order memory secondOrder,
        Call memory secondCall,
        bytes memory signatures,
        bytes32 metadata
    ) internal reentrancyGuard {
        /* CHECKS */

        /* Calculate first order hash. */
        bytes32 firstHash = hashOrder(firstOrder);

        /* Check first order validity. */
        require(
            validateOrderParameters(firstOrder, firstHash),
            "First order has invalid parameters"
        );

        /* Calculate second order hash. */
        bytes32 secondHash = hashOrder(secondOrder);

        /* Check second order validity. */
        require(
            validateOrderParameters(secondOrder, secondHash),
            "Second order has invalid parameters"
        );

        /* Prevent self-matching (possibly unnecessary, but safer). */
        require(firstHash != secondHash, "Self-matching orders is prohibited");

        {
            /* Calculate signatures (must be awkwardly decoded here due to stack size constraints). */
            (bytes memory firstSignature, bytes memory secondSignature) = abi
                .decode(signatures, (bytes, bytes));

            /* Check first order authorization. */
            require(
                validateOrderAuthorization(
                    firstHash,
                    firstOrder.maker,
                    firstSignature
                ),
                "First order failed authorization"
            );

            /* Check second order authorization. */
            require(
                validateOrderAuthorization(
                    secondHash,
                    secondOrder.maker,
                    secondSignature
                ),
                "Second order failed authorization"
            );
        }

        /* INTERACTIONS */

        /* Transfer any msg.value.
           This is the first "asymmetric" part of order matching: if an order requires Ether, it must be the first order. */
        if (msg.value > 0) {
            payable(address(uint160(firstOrder.maker))).transfer(msg.value);
        }
        /* Execute first call, assert success.
           This is the second "asymmetric" part of order matching: execution of the second order can depend on state changes in the first order, but not vice-versa. */
        require(executeCall(firstCall), "First call failed");

        /* Execute second call, assert success. */
        require(executeCall(secondCall), "Second call failed");

        /* Static calls must happen after the effectful calls so that they can check the resulting state. */

        /* Fetch previous first order fill. */
        uint256 previousFirstFill = fills[firstOrder.maker][firstHash];

        /* Fetch previous second order fill. */
        uint256 previousSecondFill = fills[secondOrder.maker][secondHash];

        /* Execute first order static call, assert success, capture returned new fill. */
        uint256 firstFill = executeStaticCall(
            firstOrder,
            firstCall,
            secondOrder,
            secondCall,
            msg.sender,
            msg.value,
            previousFirstFill
        );

        /* Execute second order static call, assert success, capture returned new fill. */
        uint256 secondFill = executeStaticCall(
            secondOrder,
            secondCall,
            firstOrder,
            firstCall,
            msg.sender,
            uint256(0),
            previousSecondFill
        );

        /* EFFECTS */

        /* Update first order fill, if necessary. */
        if (firstOrder.maker != msg.sender) {
            if (firstFill != previousFirstFill) {
                fills[firstOrder.maker][firstHash] = firstFill;
            }
        }

        /* Update second order fill, if necessary. */
        if (secondOrder.maker != msg.sender) {
            if (secondFill != previousSecondFill) {
                fills[secondOrder.maker][secondHash] = secondFill;
            }
        }

        /* LOGS */

        /* Log match event. */
        emit OrdersMatched(
            firstHash,
            secondHash,
            firstOrder.maker,
            secondOrder.maker,
            firstFill,
            secondFill,
            metadata
        );
    }

    function _proxy(
        address dest,
        HowToCall howToCall,
        bytes memory data
    ) internal returns (bool result) {
        bytes memory ret;
        if (howToCall == HowToCall.Call) {
            (result, ret) = dest.call(data);
        } else if (howToCall == HowToCall.DelegateCall) {
            (result, ret) = dest.delegatecall(data);
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
/*

  << Static Caller >>

*/

pragma solidity ^0.8.14;

contract StaticCaller {
    function staticCall(address target, bytes memory data)
        internal
        view
        returns (bool result)
    {
        assembly {
            result := staticcall(
                gas(),
                target,
                add(data, 0x20),
                mload(data),
                mload(0x40),
                0
            )
        }
        return result;
    }

    function staticCallUint(address target, bytes memory data)
        internal
        view
        returns (uint256 ret)
    {
        bool result;
        assembly {
            let size := 0x20
            let free := mload(0x40)
            result := staticcall(
                gas(),
                target,
                add(data, 0x20),
                mload(data),
                free,
                size
            )
            ret := mload(free)
        }
        require(result, "Static call failed");
        return ret;
    }
}

// SPDX-License-Identifier: MIT
/*

  Simple contract extension to provide a contract-global reentrancy guard on functions.

*/

pragma solidity ^0.8.14;

contract ReentrancyGuarded {
    bool reentrancyLock = false;

    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard() {
        require(!reentrancyLock, "Reentrancy detected");
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }
}

// SPDX-License-Identifier: MIT
/*

  << EIP 712 >>

*/

pragma solidity ^0.8.14;

contract EIP712 {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 DOMAIN_SEPARATOR;

    function hash(EIP712Domain memory eip712Domain)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_TYPEHASH,
                    keccak256(bytes(eip712Domain.name)),
                    keccak256(bytes(eip712Domain.version)),
                    eip712Domain.chainId,
                    eip712Domain.verifyingContract
                )
            );
    }
}

// SPDX-License-Identifier: MIT
/*

  << EIP 1271 >>

*/

pragma solidity ^0.8.14;

abstract contract ERC1271 {
    // bytes4(keccak256("isValidSignature(bytes,bytes)")
    bytes4 internal constant MAGICVALUE = 0x20c13b0b;

    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param _data Arbitrary length data signed on the behalf of address(this)
     * @param _signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x20c13b0b when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes memory _data, bytes memory _signature)
        public
        view
        virtual
        returns (bytes4 magicValue);
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