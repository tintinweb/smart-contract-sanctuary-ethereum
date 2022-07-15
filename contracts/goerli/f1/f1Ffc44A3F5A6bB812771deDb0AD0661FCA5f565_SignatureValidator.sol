/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File @openzeppelin/contracts/cryptography/[email protected]


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}


// File contracts/SignatureValidator.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
 * SignatureValidator contract.
 * @author Nikola Madjarevic
 * Date created: 8.9.21.
 * Github: madjarevicn
 */
contract SignatureValidator {

    using ECDSA for *;
    uint256 public chainId;

    struct BuyOrderRatio {
        address dstToken;
        uint256 ratio;
        uint256 poolNonce;
        uint256 poolId;
    }

    struct TradeOrder {
        address srcToken;
        address dstToken;
        uint256 amountSrc;
        uint256 poolNonce;
        uint256 poolId;
    }

    struct SellLimit{
        address srcToken;
        address dstToken;
        uint256 priceUSD;
        uint256 amountSrc;
        uint256 validUntil;
        uint256 poolNonce;
        uint256 poolId;
    }

    struct BuyLimit{
        address srcToken;
        address dstToken;
        uint256 priceUSD;
        uint256 amountUSD;
        uint256 validUntil;
        uint256 poolNonce;
        uint256 poolId;
    }

    struct StopLoss{
        address srcToken;
        address dstToken;
        uint256 priceUSD;
        uint256 amountSrc;
        uint256 validUntil;
        uint256 poolNonce;
        uint256 poolId;
    }

    struct EndPool{
        uint256 poolNonce;
        uint256 poolId;
    }

    struct OpenOrder {
        uint256 poolId;
        uint256 tokenId;
        uint256 amountUSDToWithdraw;
        uint256 amountOfTokensToReturn;
    }

    struct CloseOrder {
        uint256 tokenId;
        uint256 totalTokensToBeReceived;
        uint256 finalTokenPrice;
        uint256 amountOfTokensToReceiveNow;
        address tokenAddress;
    }

    struct ClosePortion {
        uint256 tokenId;
        uint256 portionId;
        uint256 amountOfTokensToReceive;
    }

    struct Whitelist {
        uint256 poolId;
        address userAddress;
    }

    string public constant EIP712_DOMAIN = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
    string public constant BUY_ORDER_RATIO_TYPE = "BuyOrderRatio(address dstToken,uint256 ratio,uint256 poolNonce,uint256 poolId)";
    string public constant TRADE_ORDER_TYPE = "TradeOrder(address srcToken,address dstToken,uint256 amountSrc,uint256 poolNonce,uint256 poolId)";
    string public constant SELL_LIMIT_TYPE = "SellLimit(address srcToken,address dstToken,uint256 priceUSD,uint256 amountSrc,uint256 validUntil,uint256 poolNonce,uint256 poolId)";
    string public constant BUY_LIMIT_TYPE = "BuyLimit(address srcToken,address dstToken,uint256 priceUSD,uint256 amountUSD,uint256 validUntil,uint256 poolNonce,uint256 poolId)";
    string public constant STOP_LOSS_TYPE = "StopLoss(address srcToken,address dstToken,uint256 priceUSD,uint256 amountSrc,uint256 validUntil,uint256 poolNonce,uint256 poolId)";
    string public constant END_POOL_TYPE = "EndPool(uint256 poolId,uint256 poolNonce)";
    string public constant OPEN_ORDER_TYPE = "OpenOrder(uint256 poolId,uint256 tokenId,uint256 amountUSDToWithdraw,uint256 amountOfTokensToReturn)";
    string public constant CLOSE_ORDER_TYPE = "CloseOrder(uint256 tokenId,uint256 totalTokensToBeReceived,uint256 finalTokenPrice,uint256 amountOfTokensToReceiveNow,address tokenAddress)";
    string public constant CLOSE_PORTION_TYPE = "ClosePortion(uint256 tokenId,uint256 portionId,uint256 amountOfTokensToReceive)";
    string public constant WHITELIST_TYPE = "Whitelist(uint256 poolId,address userAddress)";

    // Compute typehashes
    bytes32 public constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));
    bytes32 public constant BUY_ORDER_RATIO_TYPEHASH = keccak256(abi.encodePacked(BUY_ORDER_RATIO_TYPE));
    bytes32 public constant TRADE_ORDER_TYPEHASH = keccak256(abi.encodePacked(TRADE_ORDER_TYPE));
    bytes32 public constant SELL_LIMIT_TYPEHASH = keccak256(abi.encodePacked(SELL_LIMIT_TYPE));
    bytes32 public constant BUY_LIMIT_TYPEHASH = keccak256(abi.encodePacked(BUY_LIMIT_TYPE));
    bytes32 public constant STOP_LOSS_TYPEHASH = keccak256(abi.encodePacked(STOP_LOSS_TYPE));
    bytes32 public constant END_POOL_TYPEHASH = keccak256(abi.encodePacked(END_POOL_TYPE));
    bytes32 public constant OPEN_ORDER_TYPEHASH = keccak256(abi.encodePacked(OPEN_ORDER_TYPE));
    bytes32 public constant CLOSE_ORDER_TYPEHASH = keccak256(abi.encodePacked(CLOSE_ORDER_TYPE));
    bytes32 public constant CLOSE_PORTION_TYPEHASH = keccak256(abi.encodePacked(CLOSE_PORTION_TYPE));
    bytes32 public constant WHITELIST_TYPEHASH = keccak256(abi.encodePacked(WHITELIST_TYPE));

    bytes32 public DOMAIN_SEPARATOR;


    constructor(uint256 _chainId) public {
        chainId = _chainId;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256("Hord.app"), // string name
                keccak256("1"), // string version
                chainId, // uint256 chainId
                address(this) // address verifyingContract
            )
        );
    }

    /**
        @notice     Function to generate hash representation of the BuyOrderRatio struct
        @param      buyOrderRatio struct which we hash
        @return     Hash representation of the BuyOrderRatio struct
    */
    function hashBuyOrderRatio(BuyOrderRatio memory buyOrderRatio)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            BUY_ORDER_RATIO_TYPEHASH,
                            buyOrderRatio.dstToken,
                            buyOrderRatio.ratio,
                            buyOrderRatio.poolNonce,
                            buyOrderRatio.poolId
                        )
                    )
                )
            );
    }

    /**
        @notice     Function to validate that incoming data is properly signed
        @notice     All parameters are values of BuyOrderRatio struct which we hash
        @return     Public address from the signatory
    */
    function recoverSignatureBuyOrderRatio(
        address dstToken,
        uint256 ratio,
        uint256 poolNonce,
        uint256 poolId,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address)
    {
        BuyOrderRatio memory _msg;
        _msg.dstToken = dstToken;
        _msg.ratio = ratio;
        _msg.poolNonce = poolNonce;
        _msg.poolId = poolId;

        return ECDSA.recover(hashBuyOrderRatio(_msg), sigV, sigR, sigS);
    }

    /**
        @notice     Function to generate hash representation of the TradeOrder struct
        @param      tradeOrder struct which we hash
        @return     Hash representation of the TradeOrder struct
    */
    function hashTradeOrder(TradeOrder memory tradeOrder)
    internal
    view
    returns (bytes32)
    {
        return
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        TRADE_ORDER_TYPEHASH,
                        tradeOrder.srcToken,
                        tradeOrder.dstToken,
                        tradeOrder.amountSrc,
                        tradeOrder.poolNonce,
                        tradeOrder.poolId
                    )
                )
            )
        );
    }

    /**
        @notice     Function to validate that incoming data is properly signed
        @notice     All parameters are values of TradeOrder struct which we hash
        @return     Public address from the signatory
    */
    function recoverSignatureTradeOrder(
        address srcToken,
        address dstToken,
        uint256 amountSrc,
        uint256 poolNonce,
        uint256 poolId,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address)
    {
        TradeOrder memory _msg;
        _msg.srcToken = srcToken;
        _msg.dstToken = dstToken;
        _msg.amountSrc = amountSrc;
        _msg.poolNonce = poolNonce;
        _msg.poolId = poolId;

        return ECDSA.recover(hashTradeOrder(_msg), sigV, sigR, sigS);
    }

    /**
        @notice     Function to generate hash representation of the SellLimit struct
        @param      sellLimit struct which we hash
        @return     Hash representation of the SellLimit struct
    */
    function hashSellLimit(SellLimit memory sellLimit)
    internal
    view
    returns (bytes32)
    {
        return
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        SELL_LIMIT_TYPEHASH,
                        sellLimit.srcToken,
                        sellLimit.dstToken,
                        sellLimit.priceUSD,
                        sellLimit.amountSrc,
                        sellLimit.validUntil,
                        sellLimit.poolNonce,
                        sellLimit.poolId
                    )
                )
            )
        );
    }

    /**
        @notice     Function to validate that incoming data is properly signed
        @notice     All parameters are values of SellLimit struct which we hash
        @return     Public address from the signatory
    */
    function recoverSignatureSellLimit(
        address srcToken,
        address dstToken,
        uint256 priceUSD,
        uint256 amountSrc,
        uint256 validUntil,
        uint256 poolNonce,
        uint256 poolId,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address)
    {
        SellLimit memory _msg;
        _msg.srcToken = srcToken;
        _msg.dstToken = dstToken;
        _msg.priceUSD = priceUSD;
        _msg.amountSrc = amountSrc;
        _msg.validUntil = validUntil;
        _msg.poolNonce = poolNonce;
        _msg.poolId = poolId;

        return ECDSA.recover(hashSellLimit(_msg), sigV, sigR, sigS);
    }

    /**
        @notice     Function to generate hash representation of the BuyLimit struct
        @param      buyLimit struct which we hash
        @return     Hash representation of the BuyLimit struct
    */
    function hashBuyLimit(BuyLimit memory buyLimit)
    internal
    view
    returns (bytes32)
    {
        return
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        BUY_LIMIT_TYPEHASH,
                        buyLimit.srcToken,
                        buyLimit.dstToken,
                        buyLimit.priceUSD,
                        buyLimit.amountUSD,
                        buyLimit.validUntil,
                        buyLimit.poolNonce,
                        buyLimit.poolId
                    )
                )
            )
        );
    }

    /**
        @notice     Function to validate that incoming data is properly signed
        @notice     All parameters are values of BuyLimit struct which we hash
        @return     Public address from the signatory
    */
    function recoverSignatureBuyLimit(
        address srcToken,
        address dstToken,
        uint256 priceUSD,
        uint256 amountUSD,
        uint256 validUntil,
        uint256 poolNonce,
        uint256 poolId,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address)
    {
        BuyLimit memory _msg;
        _msg.srcToken = srcToken;
        _msg.dstToken = dstToken;
        _msg.priceUSD = priceUSD;
        _msg.amountUSD = amountUSD;
        _msg.validUntil = validUntil;
        _msg.poolNonce = poolNonce;
        _msg.poolId = poolId;

        return ECDSA.recover(hashBuyLimit(_msg), sigV, sigR, sigS);
    }

    /**
        @notice     Function to generate hash representation of the StopLoss struct
        @param      stopLoss struct which we hash
        @return     Hash representation of the StopLoss struct
    */
    function hashStopLoss(StopLoss memory stopLoss)
    internal
    view
    returns (bytes32)
    {
        return
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        STOP_LOSS_TYPEHASH,
                        stopLoss.srcToken,
                        stopLoss.dstToken,
                        stopLoss.priceUSD,
                        stopLoss.amountSrc,
                        stopLoss.validUntil,
                        stopLoss.poolNonce,
                        stopLoss.poolId
                    )
                )
            )
        );
    }

    /**
        @notice     Function to validate that incoming data is properly signed
        @notice     All parameters are values of StopLoss struct which we hash
        @return     Public address from the signatory
    */
    function recoverSignatureStopLoss(
        address srcToken,
        address dstToken,
        uint256 priceUSD,
        uint256 amountSrc,
        uint256 validUntil,
        uint256 poolNonce,
        uint256 poolId,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address)
    {
        StopLoss memory _msg;
        _msg.srcToken = srcToken;
        _msg.dstToken = dstToken;
        _msg.priceUSD = priceUSD;
        _msg.amountSrc = amountSrc;
        _msg.validUntil = validUntil;
        _msg.poolNonce = poolNonce;
        _msg.poolId = poolId;

        return ECDSA.recover(hashStopLoss(_msg), sigV, sigR, sigS);
    }

    /**
         @notice    Function to generate hash representation of the EndPool struct
         @param     endPool struct which we hash
         @return    Hash representation of the EndPool struct
    */
    function hashEndPool(EndPool memory endPool)
    internal
    view
    returns (bytes32)
    {
        return
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        END_POOL_TYPEHASH,
                        endPool.poolId,
                        endPool.poolNonce
                    )
                )
            )
        );
    }

    /**
        @notice     Function to validate that incoming data is properly signed
        @notice     All parameters are values of EndPool struct which we hash
        @return     Public address from the signatory
    */
    function recoverSignatureEndPool(
        uint256 poolId,
        uint256 poolNonce,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address)
    {
        EndPool memory _msg;
        _msg.poolId = poolId;
        _msg.poolNonce = poolNonce;

        return ECDSA.recover(hashEndPool(_msg), sigV, sigR, sigS);
    }

    /**
         @notice    Function to generate hash representation of the OpenOrder struct
         @param     openOrder struct which we hash
         @return    Hash representation of the OpenOrder struct
    */
    function hashOpenOrder(OpenOrder memory openOrder)
    internal
    view
    returns (bytes32)
    {
        return
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        OPEN_ORDER_TYPEHASH,
                        openOrder.poolId,
                        openOrder.tokenId,
                        openOrder.amountUSDToWithdraw,
                        openOrder.amountOfTokensToReturn
                    )
                )
            )
        );
    }

    /**
        @notice     Function to validate that incoming data is properly signed
        @notice     All parameters are values of openOrder struct which we hash
        @return     Public address from the signatory
    */
    function recoverSignatureOpenOrder(
        uint256 poolId,
        uint256 tokenId,
        uint256 amountUSDToWithdraw,
        uint256 amountOfTokensToReturn,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address)
    {
        OpenOrder memory _msg;
        _msg.poolId = poolId;
        _msg.tokenId = tokenId;
        _msg.amountUSDToWithdraw = amountUSDToWithdraw;
        _msg.amountOfTokensToReturn = amountOfTokensToReturn;

        return ECDSA.recover(hashOpenOrder(_msg), sigV, sigR, sigS);
    }

    /**
         @notice    Function to generate hash representation of the CloseOrder struct
         @param     closeOrder struct which we hash
         @return    Hash representation of the CloseOrder struct
    */
    function hashCloseOrder(CloseOrder memory closeOrder)
    internal
    view
    returns (bytes32)
    {
        return
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        CLOSE_ORDER_TYPEHASH,
                        closeOrder.tokenId,
                        closeOrder.totalTokensToBeReceived,
                        closeOrder.finalTokenPrice,
                        closeOrder.amountOfTokensToReceiveNow,
                        closeOrder.tokenAddress
                    )
                )
            )
        );
    }

    /**
        @notice     Function to validate that incoming data is properly signed
        @notice     All parameters are values of CloseOrder struct which we hash
        @return     Public address from the signatory
    */
    function recoverSignatureCloseOrder(
        uint256 tokenId,
        uint256 totalTokensToBeReceived,
        uint256 finalTokenPrice,
        uint256 amountOfTokensToReceiveNow,
        address tokenAddress,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address)
    {
        CloseOrder memory _msg;
        _msg.tokenId = tokenId;
        _msg.totalTokensToBeReceived = totalTokensToBeReceived;
        _msg.finalTokenPrice = finalTokenPrice;
        _msg.amountOfTokensToReceiveNow = amountOfTokensToReceiveNow;
        _msg.tokenAddress = tokenAddress;

        return ECDSA.recover(hashCloseOrder(_msg), sigV, sigR, sigS);
    }

    /**
         @notice    Function to generate hash representation of the ClosePortion struct
         @param     closePortion struct which we hash
         @return    Hash representation of the ClosePortion struct
    */
    function hashClosePortion(ClosePortion memory closePortion)
    internal
    view
    returns (bytes32)
    {
        return
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        CLOSE_PORTION_TYPEHASH,
                        closePortion.tokenId,
                        closePortion.portionId,
                        closePortion.amountOfTokensToReceive
                    )
                )
            )
        );
    }

    /**
        @notice     Function to validate that incoming data is properly signed
        @notice     All parameters are values of ClosePortion struct which we hash
        @return     Public address from the signatory
    */
    function recoverSignatureClosePortion(
        uint256 tokenId,
        uint256 portionId,
        uint256 amountOfTokensToReceive,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address)
    {
        ClosePortion memory _msg;
        _msg.tokenId = tokenId;
        _msg.portionId = portionId;
        _msg.amountOfTokensToReceive = amountOfTokensToReceive;

        return ECDSA.recover(hashClosePortion(_msg), sigV, sigR, sigS);
    }

    /**
         @notice    Function to generate hash representation of the Whitelist struct
         @param     whitelist struct which we hash
         @return    Hash representation of the Whitelist struct
    */
    function hashWhitelist(Whitelist memory whitelist)
    internal
    view
    returns (bytes32)
    {
        return
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        WHITELIST_TYPEHASH,
                        whitelist.poolId,
                        whitelist.userAddress
                    )
                )
            )
        );
    }

    /**
        @notice     Function to validate that incoming data is properly signed
        @notice     All parameters are values of Whitelist struct which we hash
        @return     Public address from the signatory
    */
    function recoverSignatureWhitelist(
        uint256 poolId,
        address userAddress,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address)
    {
        Whitelist memory _msg;
        _msg.poolId = poolId;
        _msg.userAddress = userAddress;

        return ECDSA.recover(hashWhitelist(_msg), sigV, sigR, sigS);
    }

}