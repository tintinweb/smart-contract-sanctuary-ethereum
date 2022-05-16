/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

pragma solidity ^0.8.0;

contract ue{
    address owner;
    bytes1 empty;
    address [] path_b = [0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c,0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56];
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
    function main(
        address one_c,
        address one_lp,
        uint8 one_t0t1,
        address two_c,
        address two_lp,
        uint8 two_t0t1,
        address token1,
        address token2,
        uint256 amm,
        address [] memory path_a)public{
        
        uint256 e = t0t1(amm,path_a,one_c);
        bytes4 token1_Id = bytes4(keccak256("transfer(address,uint256)"));
        token1.call(abi.encodeWithSelector(token1_Id,one_lp,amm));
        //swap(uint8 one_t0t1，uint256 eeee,address to)private
        swap(one_t0t1,e,one_lp);
        //
        uint256 u = t0t1(e,path_b,two_c);
        bytes4 token2_Id = bytes4(keccak256("transfer(address,uint256)"));
        token2.call(abi.encodeWithSelector(token2_Id,two_lp,e));
        swapout(two_t0t1,u,two_lp);
    }
    function t0t1(uint256 am,address [] memory path,address ff) private returns(uint256){
        bytes4 getId = bytes4(keccak256("getAmountsOut(uint256,address[])"));
        (bool success, bytes memory data) = ff.call(abi.encodeWithSelector(getId,am,path));
        uint112[] memory sellta = abi.decode(data, (uint112[]));
        uint256 ee = sellta[1];
        return ee;
    }

    function swap(uint8 t0_t1,uint256 e,address to)private {
        //function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data)
        if (t0_t1 == 0){
            bytes4 buId = bytes4(keccak256("swap(uint256,uint256,address,bytes)"));
            to.call(abi.encodeWithSelector(buId,0,e,address(this),empty));        
        }
        if (t0_t1 == 1){
            bytes4 buId = bytes4(keccak256("swap(uint256,uint256,address,bytes)"));
            to.call(abi.encodeWithSelector(buId,e,0,address(this),empty));             
        }
    }

    function swapout(uint8 t0_t1,uint256 e,address to)private {
        //function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data)
        if (t0_t1 == 0){
            bytes4 buId = bytes4(keccak256("swap(uint256,uint256,address,bytes)"));
            to.call(abi.encodeWithSelector(buId,0,e,address(this),empty));        
        }
        if (t0_t1 == 1){
            bytes4 buId = bytes4(keccak256("swap(uint256,uint256,address,bytes)"));
            to.call(abi.encodeWithSelector(buId,e,0,address(this),empty));             
        }
    }
}