/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

pragma solidity ^0.8.10;



contract BatchETH {
    address owner;
    constructor () {
        owner = msg.sender;
    }

    //批量avg转账
    function transferEthsAvg(address[] calldata _tos) payable public returns (bool) {
        require(_tos.length > 0);
        //require(msg.sender == owner, "Ownable: caller is not the ownerr");
        uint256 vv = msg.value/_tos.length;
        for(uint32 i=0;i<_tos.length;i++)
        {
        payable(_tos[i]).transfer(vv);
        }
        return true;
    }
    
    //批量指定转账
    function transferEths(address[] calldata _tos,uint256[] calldata values) payable public returns (bool) {
        require(_tos.length > 0);
        require(msg.sender == owner,"Ownable: caller is not the ownerr");
        for(uint32 i=0;i<_tos.length;i++)
        {
        payable(_tos[i]).transfer(values[i]);
        }
        return true;
    }


    function destroy() public {

        require(msg.sender == owner, "Ownable: caller is not the ownerr");

        selfdestruct(payable(msg.sender));

    }

    function withdrawETH() external {
    	require(owner== msg.sender,"Ownable: caller is not the ownerr");
        payable(owner).transfer(address(this).balance);
    }

    receive () payable external  {

    }



}