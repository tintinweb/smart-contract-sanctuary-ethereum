//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/*
$$$$$$$\            $$\         $$\            $$$$$$\    $$\                     $$\ $$\                     
$$  __$$\           $$ |        $$ |          $$  __$$\   $$ |                    $$ |\__|                    
$$ |  $$ | $$$$$$\  $$ |  $$\ $$$$$$\         $$ /  \__|$$$$$$\   $$\   $$\  $$$$$$$ |$$\  $$$$$$\   $$$$$$$\ 
$$$$$$$  |$$  __$$\ $$ | $$  |\_$$  _|        \$$$$$$\  \_$$  _|  $$ |  $$ |$$  __$$ |$$ |$$  __$$\ $$  _____|
$$  __$$< $$$$$$$$ |$$$$$$  /   $$ |           \____$$\   $$ |    $$ |  $$ |$$ /  $$ |$$ |$$ /  $$ |\$$$$$$\  
$$ |  $$ |$$   ____|$$  _$$<    $$ |$$\       $$\   $$ |  $$ |$$\ $$ |  $$ |$$ |  $$ |$$ |$$ |  $$ | \____$$\ 
$$ |  $$ |\$$$$$$$\ $$ | \$$\   \$$$$  |      \$$$$$$  |  \$$$$  |\$$$$$$  |\$$$$$$$ |$$ |\$$$$$$  |$$$$$$$  |
\__|  \__| \_______|\__|  \__|   \____/        \______/    \____/  \______/  \_______|\__| \______/ \_______/                                                                                                                                                                     
*/

/**
 * @title UnseenAtomicizer
 * @notice Atomicizer contract used to execute packed calls { ex: fees , royalties }
 * @author Unseen | decapinator.eth
 */
contract UnseenAtomicizer {
    /**
     * @notice Atomicize a series of calls
     * @param addrs Addresses to call
     * @param values Values to send with each call
     * @param calldatas Calldata to send with each call
     */
    function atomicize(
        address[] calldata addrs,
        uint256[] calldata values,
        bytes[] calldata calldatas
    ) external {
        require(
            addrs.length == values.length,
            "Addresses, calldata lengths, and values must match in quantity"
        );
        require(
            addrs.length == calldatas.length,
            "Addresses, calldata lengths, and values must match in quantity"
        );
        uint256 addrsLength = uint8(addrs.length);
        for (uint256 i; i < addrsLength; ) {
            (bool success, ) = addrs[i].call{ value: values[i] }(calldatas[i]);
            require(success, "Subcall failed");
            unchecked {
                ++i;
            }
        }
    }
}