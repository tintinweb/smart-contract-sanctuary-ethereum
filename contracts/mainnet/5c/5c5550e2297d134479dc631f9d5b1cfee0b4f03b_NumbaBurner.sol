// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface INumba {
    function claimAndBurn(uint256 tokenId) external;
}

contract NumbaBurner {
    INumba public constant NUMBA = INumba(0xc315C1982efaB100b4A3EcA4035567358f85bBB2);
    address public constant SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
    address public immutable owner;

    error NotJesus();
    error BuyFailed();

    constructor () {
        owner = msg.sender;
    }

    function burn(uint256 tokenId, bytes calldata _calldata) external payable {
        if (msg.sender != owner) revert NotJesus();
        (bool success,) = SEAPORT.call{value: msg.value}(_calldata);
        if (!success) revert BuyFailed();
        NUMBA.claimAndBurn(tokenId);
    }

    function withdraw() external {
        if (msg.sender != owner) revert NotJesus();
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    receive() external payable {}
    fallback() external payable {}
}