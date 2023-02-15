//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IStandardGasAdjustments {

    function adjustment(string memory adjType) external view returns (uint);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;


import "./IStandardGasAdjustments.sol";

/**
 * Gas computation is not perfect. EVMs vary by opcode charges and how much gas is consumed before and 
 * after a contract's core logic. When we need to compute has costs on-chain, it's impossible to know
 * exactly what the cost will be. This is why this contract is needed. Different chains require adjustment
 * values to account for buffers in gas consumption. Dexible uses this contract to make small adjustments
 * to expected gas consumption in order to properly charge for gas used by executions.
 */
contract StandardGasAdjustments is IStandardGasAdjustments {

    event AdjustmentChanged(string adjustmentType, uint amount);

    //admin allowed to change gas adjustment factor
    address adminMultiSig;

    //adjustment added to gas used to get an additional amount of gas used for 
    //gas cost computation on-chain. Each chain will vary in how much gas is 
    //consumed to complete the final steps of a swap.
    mapping(string => uint) public adjustment;

    modifier onlyAdmin() {
        require(msg.sender == adminMultiSig, "Unauthorized");
        _;
    }

    constructor(address mSig, string[] memory types, uint[] memory _adjustments) {
        adminMultiSig = mSig;
        _applyAdjustments(types, _adjustments);
    }

    /**
     * Set the amount of gas to adjust the base gas used on this network
     */
    function setAdjustments(string[] memory types, uint[] memory _adjustments) public onlyAdmin {
        _applyAdjustments(types, _adjustments);
    }


    function _applyAdjustments(string[] memory types, uint[] memory _adjustments) internal {
        require(types.length == _adjustments.length, "Types and adjustments have to match");
        for(uint i=0;i<types.length;++i) {
            adjustment[types[i]] = _adjustments[i];
            emit AdjustmentChanged(types[i], _adjustments[i]);
        }
    }

}