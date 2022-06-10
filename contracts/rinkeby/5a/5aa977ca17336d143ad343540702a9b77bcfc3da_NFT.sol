/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.14;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// Additional methods available for WETH
interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}


interface Exchange{
    function atomicMatch_(address[14] memory addrs,
        uint[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell,
        uint8[2] memory vs,
        bytes32[5] memory rssMetadata)
        external
        payable;
}
///////////////////////////////////////////////////////////
library OrderTypes {
    // keccak256("MakerOrder(bool isOrderAsk,address signer,address collection,uint256 price,uint256 tokenId,uint256 amount,address strategy,address currency,uint256 nonce,uint256 startTime,uint256 endTime,uint256 minPercentageToAsk,bytes params)")
    bytes32 internal constant MAKER_ORDER_HASH = 0x40261ade532fa1d2c7293df30aaadb9b3c616fae525a0b56d3d411c841a85028;

    struct MakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address signer; // signer of the maker order
        address collection; // collection address
        uint256 price; // price (used as )
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
        address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
        address currency; // currency (e.g., WETH)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // additional parameters
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct TakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address taker; // msg.sender
        uint256 price; // final price for the purchase
        uint256 tokenId;
        uint256 minPercentageToAsk; // // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // other params (e.g., tokenId)
    }

    function hash(MakerOrder memory makerOrder) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MAKER_ORDER_HASH,
                    makerOrder.isOrderAsk,
                    makerOrder.signer,
                    makerOrder.collection,
                    makerOrder.price,
                    makerOrder.tokenId,
                    makerOrder.amount,
                    makerOrder.strategy,
                    makerOrder.currency,
                    makerOrder.nonce,
                    makerOrder.startTime,
                    makerOrder.endTime,
                    makerOrder.minPercentageToAsk,
                    keccak256(makerOrder.params)
                )
            );
    }
}

interface ILooksRareExchange {
    function matchAskWithTakerBidUsingETHAndWETH(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external payable;

    function matchAskWithTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
    external;

    function matchBidWithTakerAsk(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
    external;
}

contract NFT{

    address private immutable owner;
    IWETH private constant WETH = IWETH(0xc778417E063141139Fce010982780140Aa0cD5Ab);
    Exchange private constant opensea = Exchange(0xdD54D660178B28f6033a953b0E55073cFA7e3744);
    ILooksRareExchange private constant looksRare = ILooksRareExchange(0x1AA777972073Ff66DCFDeD85749bDD555C0665dA);

    constructor(){
        owner = msg.sender;
        
        //Below code is to approve Looks Rare Transfer Manager to use our WETH
        WETH.approve(0x3f65A762F15D01809cDC6B43d8849fF24949c86a, type(uint).max);
    }

    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == address(this));
        _;
    }

    receive() external payable {}

    function withdraw(uint8 i) external onlyOwner{
        if (i == 0){
            payable(msg.sender).transfer(address(this).balance);
        }else if (i == 1){
            uint256 amount = WETH.balanceOf(address(this));
            WETH.transfer(msg.sender, amount);
        }
    }

    function kill() external onlyOwner{
      address payable caller = payable(msg.sender);
      selfdestruct(caller);
    }

    function wrapETH() public onlyOwner returns(bool){
        WETH.deposit{value: WETH.balanceOf(address(this))}();
        return true;
    }

    function unWrapETH() public onlyOwner returns(bool){
        uint balance = WETH.balanceOf(address(this));
        WETH.withdraw(balance);
        return true;
    }
    
    function osToLR(address[14] memory addrs, uint[18] memory uints, uint8[8] memory feeMethodsSidesKindsHowToCalls, bytes memory calldataBuy, bytes memory calldataSell, bytes memory replacementPatternBuy, bytes memory replacementPatternSell,uint8[2] memory vs,bytes32[5] memory rssMetadata, OrderTypes.TakerOrder memory takerAsk, OrderTypes.MakerOrder memory makerBid) external{
        //Do OpenSea To LooksRare Arbitrage Logic here            
        //Convert WETH to ETH
        require(unWrapETH());

        //Buy from OpenSea
        opensea.atomicMatch_{value: uints[4]}(addrs, uints, feeMethodsSidesKindsHowToCalls, calldataBuy, calldataSell, replacementPatternBuy, replacementPatternSell, "", "", vs, rssMetadata);
            
        //Convert ETH to WETH
        require(wrapETH());

        //Sell on LooksRare
        looksRare.matchBidWithTakerAsk(takerAsk, makerBid);

        //Convert WETH to ETH
        require(unWrapETH());
        
        //Convert ETH to WETH
        require(wrapETH());
    }

}