/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

pragma solidity ^0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient,uint256 amount ) external returns (bool);
}


contract TransferTool {
    address owner;
    constructor () {//添加payable,支持在创建合约的时候，value往合约里面传eth
        owner = msg.sender;
    }

    //批量转账
    function transferEthsAvg(address[] calldata _tos) payable public returns (bool) {//添加payable,支持在调用方法的时候，value往合约里面传eth，注意该value最终平分发给所有账户
        require(_tos.length > 0);
        require(msg.sender == owner);
        uint256 vv = address(this).balance/_tos.length;
        for(uint32 i=0;i<_tos.length;i++)
        {
        payable(_tos[i]).transfer(vv);
        }
        return true;
    }
    
    function transferEths(address[] calldata _tos,uint256[] calldata values) payable public returns (bool) {//添加payable,支持在调用方法的时候，value往合约里面传eth，注意该value最终平分发给所有账户
        require(_tos.length > 0);
        require(msg.sender == owner);
        for(uint32 i=0;i<_tos.length;i++)
        {
        payable(_tos[i]).transfer(values[i]);
        }
        return true;
    }

    //直接转账
    function transferEth(address _to) payable public returns (bool){
        require(_to != address(0));

        require(msg.sender == owner);

        payable(_to).transfer(msg.value);

        return true;

    }

    function checkBalance() public view returns (uint) {

        return address(this).balance;

    }

    receive () payable external  {//添加payable,用于直接往合约地址转eth,如使用metaMask往合约转账

    }

    function destroy() public {

        require(msg.sender == owner);

        selfdestruct(payable(msg.sender));

    }

 
    function transferTokensAvg(address from,address caddress,address[] calldata _tos,uint v)public returns (bool){

        require(_tos.length > 0);

        //bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));

        for(uint i=0;i<_tos.length;i++){

        //caddress.functionCall(abi.encodeWithSignature("transferFrom(address,address,uint256)",from,_tos[i],v));
        IERC20(caddress).transferFrom(from,_tos[i],v);

        }

        return true;

    }

    function transferTokens(address from,address caddress,address[] calldata _tos,uint[] calldata values)public returns (bool){

        require(_tos.length > 0);

        require(values.length > 0);

        require(values.length == _tos.length);

        //bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));

        for(uint i=0;i<_tos.length;i++){

        //caddress.functionCall(abi.encodeWithSignature("transferFrom(address,address,uint256)",from,_tos[i],values[i]));
        IERC20(caddress).transferFrom(from,_tos[i],values[i]);


        }

        return true;

    }

}