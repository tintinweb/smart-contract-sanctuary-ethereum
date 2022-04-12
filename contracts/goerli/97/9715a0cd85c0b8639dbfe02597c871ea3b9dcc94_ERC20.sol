/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

pragma solidity ^0.8.0;

interface IERC20 {

    function join() external;
    function fight() external;
}

contract ERC20{

    address public addr1 = 0x355586C10E740c84bCE29aDb1b87299d001Ebc52;
    address public addr2 = 0x588aD4e236A6E58996cb42EB8878A8A66B16bC95;

    constructor() payable {}

    function jo() external payable{

        IERC20 c = IERC20(addr1);
        c.join();
        c.fight();

        IERC20 c1 = IERC20(addr2);
        c1.join();
        c1.fight();
    }

    receive() external payable { }
    
}