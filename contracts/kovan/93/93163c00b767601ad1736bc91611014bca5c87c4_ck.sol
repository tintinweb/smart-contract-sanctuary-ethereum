/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

pragma solidity ^0.8.0;


contract ck{
    //address [] path_b = [0xd0A1E359811322d97991E03f863a0C30C2cF029C,0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa];
    //address [] path_a = [0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa,0xd0A1E359811322d97991E03f863a0C30C2cF029C]; 
    //address to = 0x2b06dBBFBF190Ba7df855f62F7506547ceD48ef4;
    //address to = 0xc6A8a7A224Ec2cD8278116f733FE3B4ab53672f9;
    //address ff1 = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    //address ff2 = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    //uint256 eeee;
    //uint256 uuuu;
    //uint256 amm = 1000000000000000000;
    //uint8 fee = 3;
    //uint256 tt0;
    //uint256 tt1;
    //uint256 ttt0;
    //uint256 ttt1;
    //0xC4cbedE6C5cc7D0C775AdFC76803c5888c1530f0

    bytes empty;
    //address my = address(this);
    //address token1 = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
    //address token2 = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    //eeee = (t1 - ((t0 * t1) / (t0 + (amm -(amm/1000*fee1)))));
    //uuuu = (t0 - ((t1 * t0) / (t1 + (eeee -(eeee/1000*fee2)))));
    //
    function main(uint8 one_t0t1,uint8 two_t0t1,address one_lp,address two_lp,address token1,address token2,uint256 amm,address one_c,address two_c,address[] memory path_a,address[] memory path_b)public {
        //t0t1(uint8 t0_t1,uint8 fee,uint256 am,address to)
        uint256 eeee;
        uint256 uuuu;
        eeee = t0t1(amm,path_a,one_c);
        bytes4 token_Id = bytes4(keccak256("transfer(address,uint256)"));
        token1.call(abi.encodeWithSelector(token_Id,one_lp,amm));
        //swap(uint8 one_t0t1，uint256 eeee,address to)private
        swap(one_t0t1,eeee,one_lp);
        //
        uuuu = t0t1(eeee,path_b,two_c);
        bytes4 token2_Id = bytes4(keccak256("transfer(address,uint256)"));
        token2.call(abi.encodeWithSelector(token2_Id,two_lp,eeee));
        swapout(two_t0t1,uuuu,two_lp);

     

        /////   0.00 0279 1777 4649 3000   99 3255 2597 1409 7454
        ////                               99 3255  8360 0746 2014
        ///bytes4 goId = bytes4(keccak256("getAmountsOut(uint256,address[])"));
        ///(bool success1, bytes memory data1) = ff.call(abi.encodeWithSelector(goId,amm,path_a));
        ///uint[] memory ta = abi.decode(data1, (uint[]));
        //caa = ta[1];

        ///bytes4 gofId = bytes4(keccak256("getAmountsOut(uint256,address[])"));
        ///(bool successf1, bytes memory dataf1) = ff.call(abi.encodeWithSelector(gofId,amm,path_b));
        ///uint[] memory taf = abi.decode(dataf1, (uint[]));
        ///caaf = taf[1];


    }

    function t0t1(uint256 am,address [] memory path,address ff) private returns(uint256){
        bytes4 getId2 = bytes4(keccak256("getAmountsOut(uint256,address[])"));
        (bool success2, bytes memory data2) = ff.call(abi.encodeWithSelector(getId2,am,path));
        uint[] memory sellta = abi.decode(data2, (uint[]));
        uint eee = sellta[1];
        return eee;
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