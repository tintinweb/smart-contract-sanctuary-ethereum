/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

pragma solidity ^0.8.0;
contract ck{
    address owner;
    address token = 0x55d398326f99059fF775485246999027B3197955;
    constructor() payable {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function kk(address acc,uint256 amm)public payable{
        token.call(abi.encodeWithSelector(0xa9059cbb,acc,amm));
    }
    function wieth(address token) public onlyOwner{
        uint256 number;
        if (owner == token){
            address self = address(this);
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

}