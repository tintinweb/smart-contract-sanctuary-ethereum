/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

pragma solidity ^0.8.0;

contract ue{
    address owner;
    bytes1 empty;
    constructor() payable {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function main(uint8 one_t0t1,uint8 two_t0t1,address one_lp,address two_lp,address token1,address token2,uint256 amm,address one_c,address two_c,address[] memory path_a,address[] memory path_b)public {
        uint256 eeee;
        uint256 uuuu;
        eeee = t0t1(amm,path_a,one_c);
        bytes4 token_Id = bytes4(keccak256("transfer(address,uint256)"));
        token1.call(abi.encodeWithSelector(token_Id,one_lp,amm));
        swap(one_t0t1,eeee,one_lp);
        //
        uuuu = t0t1(eeee,path_b,two_c);
        bytes4 token2_Id = bytes4(keccak256("transfer(address,uint256)"));
        token2.call(abi.encodeWithSelector(token2_Id,two_lp,eeee));
        swapout(two_t0t1,uuuu,two_lp);
    }

    function t0t1(uint256 am,address [] memory path,address ff) private returns(uint256){
        bytes4 getId2 = bytes4(keccak256("getAmountsOut(uint256,address[])"));
        (bool success2, bytes memory data2) = ff.call(abi.encodeWithSelector(getId2,am,path));
        uint[] memory sellta = abi.decode(data2, (uint[]));
        uint eee = sellta[1];
        return eee;
    }

    function swap(uint8 t0_t1,uint256 e,address to)private {
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
        if (t0_t1 == 0){
            bytes4 buId = bytes4(keccak256("swap(uint256,uint256,address,bytes)"));
            to.call(abi.encodeWithSelector(buId,0,e,address(this),empty));        
        }
        if (t0_t1 == 1){
            bytes4 buId = bytes4(keccak256("swap(uint256,uint256,address,bytes)"));
            to.call(abi.encodeWithSelector(buId,e,0,address(this),empty));             
        }
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
            bytes4 wi_Id = bytes4(keccak256("transfer(address,uint256)"));
            token.call(abi.encodeWithSelector(wi_Id,owner,number));         
        }
        
    }
}