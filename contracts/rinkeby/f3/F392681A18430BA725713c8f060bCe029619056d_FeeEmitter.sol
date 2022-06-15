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
        counter++;
        lastExecuteTimestamp = block.timestamp;
        (uint256 fee, address feeToken) = IOps(ops).getFeeDetails();
        emit FeeData(fee, feeToken);
    }

    function check()
        external
        view
        returns(bool canExec, bytes memory execPayload)
    {
        if (
            counter <= 10
            && lastExecuteTimestamp > block.timestamp + 3600
        ) {
            canExec = true;
            execPayload = abi.encodeWithSelector(
                IFeeEmitter.execute.selector
            );
            return (canExec, execPayload);
        }

        execPayload = "";
        canExec = false;
    }
}

interface IOps {
    function getFeeDetails() external view returns (uint256, address);
    function gelato() external view returns (address payable);
}

interface IFeeEmitter {
    function execute() external;
}