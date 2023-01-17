//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract GeneralMulticall {
    struct InputData {
        address treasury;
        bytes[] data;
    }

    struct OutputData {
        address treasury;
        uint256[] amounts;
    }

    /** @dev Function to create many sells and purchases in one txn
     * @param inputData an array of objects like {treasury contract,
     * an array of data for each call for this contract}
     */
    function multicall(InputData[] memory inputData)
        external
        returns (OutputData[] memory outputData)
    {
        require(
            inputData.length > 0,
            "GeneralMulticall: wrong inputData length"
        );
        uint256 counter;
        uint256 j;
        bool success;
        bytes memory data;
        outputData = new OutputData[](inputData.length);
        for (uint256 i; i < inputData.length; i++) {
            if (
                inputData[i].treasury != address(0) &&
                inputData[i].data.length > 0
            ) {
                outputData[i].treasury = inputData[i].treasury;
                outputData[i].amounts = new uint256[](inputData[i].data.length);
                for (j = 0; j < inputData[i].data.length; j++) {
                    (success, data) = inputData[i].treasury.call(
                        abi.encodePacked(inputData[i].data[j], msg.sender)
                    );
                    if (success) {
                        outputData[i].amounts[j] = uint256(bytes32(data));
                        counter++;
                    }
                }
            }
        }
        require(counter > 0, "GeneralMulticall: all calls failed");
    }
}