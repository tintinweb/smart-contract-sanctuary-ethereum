pragma solidity ^0.8.0;

import {OrderTypes} from "./OrderTypes.sol";
import {SignatureChecker} from "./SignatureChecker.sol";

contract NPCDrop {

    using OrderTypes for OrderTypes.MakerOrder;
    using OrderTypes for OrderTypes.TakerOrder;

    address public immutable WETH;
    bytes32 public immutable DOMAIN_SEPARATOR;

    address public protocolFeeRecipient;

    bytes32 internal constant IdentityHash = 0x48ded094918d459a556188a223c013092a8d62ee4bb3f8063da1c325df4dd31b;

    constructor(
        address _WETH
    ) {
         // Calculate the domain separator
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                0x7f4750ff38c8443b76e6786f55ad102d88105eaad84745226f9ebe39e7e72747, // keccak256("NovaExchange")
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1")) for versionId = 1
                block.chainid,
                address(this)
            )
        );
         WETH = _WETH;
    }



      function matchAskWithTakerBidUsingETHAndWETH(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) public view returns (address){
        require((makerAsk.isOrderAsk) && (!takerBid.isOrderAsk), "Order: Wrong sides");
        require(makerAsk.currency == WETH, "Order: Currency must be WETH");
        require(msg.sender == takerBid.taker, "Order: Taker must be the sender");

    

    

        // Check the maker ask order
        bytes32 askHash = makerAsk.hash();
          require(
            SignatureChecker.verify(
                askHash,
                makerAsk.signer,
                makerAsk.v,
                makerAsk.r,
                makerAsk.s,
                DOMAIN_SEPARATOR
            ),
            "Signature: Invalid"
        );

        return makerAsk.signer;


       
    }


}