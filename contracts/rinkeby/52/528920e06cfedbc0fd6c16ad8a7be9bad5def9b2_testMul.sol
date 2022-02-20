// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.12 <0.9.0;

    import "./Tes2.sol";

    contract testMul is Test2{
        constructor(uint256 _number) Test2(_number){
        }

    function ReturnNumber() public view returns(uint256){
        return ShowNumber();
    }

    function setNumHello(uint256 _number) public {
        Test2.numero = _number;

    }

    }