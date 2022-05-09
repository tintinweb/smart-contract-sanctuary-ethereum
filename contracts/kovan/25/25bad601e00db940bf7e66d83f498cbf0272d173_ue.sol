/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

pragma solidity ^0.8.0;

contract ue{
    address owner;
    address [] path_a;
    address [] path_b;
    address uni;
    address sushi;
    address token_a;
    address token_b;
    address [] data;
    constructor() payable {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function get() public view returns(address){
        return owner;
    }
    function set(address ow) public onlyOwner{
        owner = ow;
    }
    function wieth(address token) public onlyOwner{
        uint256 number;
        if (owner == token){
            address self = address(this); //g workaround for a possible solidity bu
            uint256 assetBalance = self.balance;
            payable(owner).transfer(assetBalance);
        } else {
            bytes4 token_b_Id = bytes4(keccak256("balanceOf(address)"));
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(token_b_Id,address(this)));
            for(uint i= 0; i<data.length; i++){
            number = number + uint8(data[i])*(2**(8*(data.length-(i+1))));
            }
            bytes4 token_Id = bytes4(keccak256("transfer(address,uint256)"));
            token.call(abi.encodeWithSelector(token_Id,owner,number));          
        }
        
    }

    function main(address suhsi,address uni,address [] memory path_a,address [] memory path_b,uint256 amm,uint256 numbe) public {
        uint256 number;
        bytes4 app_Id_buy = bytes4(keccak256("approve(address,uint256)"));
        path_a[0].call(abi.encodeWithSelector(app_Id_buy,sushi,amm));
        bytes4 buyId = bytes4(keccak256("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)"));
        sushi.call(abi.encodeWithSelector(buyId,amm,0,path_a,address(this),numbe));
        bytes4 token_b_Id = bytes4(keccak256("balanceOf(address)"));
        (bool success, bytes memory data) = path_a[1].call(abi.encodeWithSelector(token_b_Id,address(this)));
        for(uint i= 0; i<data.length; i++){
            number = number + uint8(data[i])*(2**(8*(data.length-(i+1))));
        }

        bytes4 app_Id_sell = bytes4(keccak256("approve(address,uint256)"));
        path_a[1].call(abi.encodeWithSelector(app_Id_sell,uni,number));
        bytes4 sellId = bytes4(keccak256("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)"));
        uni.call(abi.encodeWithSelector(sellId,number,0,path_b,address(this),numbe));       
    }
}