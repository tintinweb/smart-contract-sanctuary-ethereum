pragma solidity ^0.8.0;


contract MockAdmin {

    function callFcns(address[] calldata targets, bytes[] calldata callDatas) external {
        require(targets.length == callDatas.length, "MockAdmin: array lengths");
        
        for (uint i; i < targets.length; i++) {
            (bool success, bytes memory returnData) = targets[i].call(callDatas[i]);
            if (!success) {
                // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/d57593c148dad16abe675083464787ca10f789ec/contracts/utils/AddressUpgradeable.sol#L210
                if (returnData.length > 0) {
                    assembly {
                        let returndata_size := mload(returnData)
                        revert(add(32, returnData), returndata_size)
                    }
                } else {
                    revert("No error message!");
                }
            }
        }
    }
}