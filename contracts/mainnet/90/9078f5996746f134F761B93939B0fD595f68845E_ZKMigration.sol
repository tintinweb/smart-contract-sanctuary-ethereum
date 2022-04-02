//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;


contract ZKMigration  {
    event Frozen(address indexed user, address indexed token, uint256 amount);

    function freeze(address token, uint256 amount) external {
        safeTransferFrom(token, msg.sender, address(this), amount);
        emit Frozen(msg.sender, token, amount);
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

}