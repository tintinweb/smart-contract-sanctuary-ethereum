/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

pragma solidity 0.8.12;

contract TokenDepositer {
    address constant bridgeWallet = address(0xc4DC891d5B5171f789829D6050D5eB64c447e0FE);

    function deposit(address token, uint amount) public {
        safeTransferFrom(token, msg.sender, bridgeWallet, amount);
    }

    function withdraw(address token, address to, uint amount) public {
        require(msg.sender == bridgeWallet, "NBW");
        safeTransferFrom(token, msg.sender, to, amount);
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TF");
    }
}