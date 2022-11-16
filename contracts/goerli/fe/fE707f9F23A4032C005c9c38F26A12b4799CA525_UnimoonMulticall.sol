//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


contract UnimoonMulticall {
    address public immutable TREASURY;

    constructor(address _treasury) {
        require(_treasury != address(0), "UnimoonMulticall: wrong input");
        TREASURY = _treasury;
    }

    /** @dev Function to create many sells and purchases in one txn
     * @param data an array of calls' data
     */
    function multicall(bytes[] calldata data) external {
        require(data.length > 0, "UnimoonMulticall: wrong length");
        uint256 counter;
        for (uint256 i; i < data.length; i++) {
            (bool success, ) = TREASURY.call(
                abi.encodePacked(data[i], msg.sender)
            );
            if (success) counter++;
        }
        require(counter > 0, "UnimoonMulticall: all calls failed");
    }
}