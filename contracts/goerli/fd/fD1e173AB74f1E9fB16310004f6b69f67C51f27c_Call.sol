// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


import "./Ownable.sol";
import "./Address.sol";
import "./TransferHelper.sol";

contract Call is Ownable {

    receive() external payable {}
    fallback() external payable {}

    function tokenOut(
        address token,
        uint amount,
        address to
    ) public onlyOwner {
        if(token == address(0)){
            Address.sendValue(payable(to),amount);
        }else{
            TransferHelper.safeTransfer(token,to,amount);
        }
    }

    function runCall(
        address[] memory to,
        bytes[] memory data,
        uint[] memory value
    ) public onlyOwner {
        for(uint i = 0; i < data.length; i++) {
            (bool success,) = to[i].call{ value:value[i] }(data[i]);
            require(!success,"Call::run fail");
        }
    }


}