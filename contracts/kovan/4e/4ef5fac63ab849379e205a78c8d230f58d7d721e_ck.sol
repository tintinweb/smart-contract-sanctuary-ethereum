/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

pragma solidity ^0.8.0;
contract ck{
    address owner;
    bytes empty;
    constructor() payable {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function main(uint8 one_t0t1,uint8 two_t0t1,address one_lp,address two_lp,address token1,address token2,uint256 amm,address one_c,address two_c,address[] memory path_a,address[] memory path_b,uint256 gasp)public {
        uint256 e;
        uint256 u;
        e = t0t1(amm,path_a,one_c);
        u = t0t1(e,path_b,two_c);
        ////
        require(u > gasp, "uuuu <= gasp");
        token1.call(abi.encodeWithSelector(0xa9059cbb,one_lp,amm));
        if (one_t0t1 == 0){
            one_lp.call(abi.encodeWithSelector(0x022c0d9f,0,e,address(this),empty));        
        }
        if (one_t0t1 == 1){
            one_lp.call(abi.encodeWithSelector(0x022c0d9f,e,0,address(this),empty));             
        }
        token2.call(abi.encodeWithSelector(0xa9059cbb,two_lp,e));
        if (two_t0t1 == 0){
            two_lp.call(abi.encodeWithSelector(0x022c0d9f,0,u,address(this),empty));        
        }
        if (two_t0t1 == 1){
            two_lp.call(abi.encodeWithSelector(0x022c0d9f,u,0,address(this),empty));             
        }
    }
    function t0t1(uint256 am,address [] memory path,address ff) private returns(uint256){
        (bool success2, bytes memory data2) = ff.call(abi.encodeWithSelector(0xd06ca61f,am,path));
        uint[] memory sellta = abi.decode(data2, (uint[]));
        uint eee = sellta[1];
        return eee;
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