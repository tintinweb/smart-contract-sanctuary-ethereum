pragma solidity ^0.8.0;

contract FeeEmitter {
    uint256 public counter = 0;
    uint256 public lastExecuteTimestamp;
    address public immutable ops;

    event FeeData(uint256 fee, address feeToken);

    constructor(address _ops) {
        ops = _ops;
    }

    function execute() external {
        (uint256 fee, address feeToken) = IOps(ops).getFeeDetails();
        emit FeeData(fee, feeToken);
    }

    function check() external returns(bool){
        counter++;
        if (
            counter <= 10
            && lastExecuteTimestamp > block.timestamp + 3600
        ) {
            return true;
        }
        lastExecuteTimestamp = block.timestamp;

        return false;
    }
}

interface IOps {
    function getFeeDetails() external view returns (uint256, address);
    function gelato() external view returns (address payable);
}