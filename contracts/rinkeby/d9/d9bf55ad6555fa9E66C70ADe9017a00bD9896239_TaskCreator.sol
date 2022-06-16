pragma solidity ^0.8.0;

contract TaskCreator {
    address public immutable ops;
    address payable public immutable  gelato;
    uint256 lastExecutionTime;

    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event FeeData(uint256 fee, address feeToken);
    event TaskCreated(bytes32);
    event TaskCancelled(bytes32);

    constructor(address _ops) {
        ops = _ops;
        gelato = IOps(_ops).gelato();
    }

    receive() payable external {}


    function createTask() external {

        bytes32 task = IOps(ops).createTaskNoPrepayment(
            address(this),
            this.execute.selector,
            address(this),
            abi.encodeWithSelector(this.checker.selector),
            ETH
        );

        emit TaskCreated(task);
    }


    function cancelTask(bytes32 _taskId) external {
        IOps(ops).cancelTask(_taskId);

        emit TaskCancelled(_taskId);
    }


    function execute() external {
        lastExecutionTime = block.timestamp;
        (uint256 fee, address feeToken) = IOps(ops).getFeeDetails();
        emit FeeData(fee, feeToken);
        (bool success, ) = gelato.call{value: fee}("");
        require(success, "_transfer: ETH transfer failed");
    }


    function checker(bytes memory execData)
        external
        view
    returns (bool, bytes memory)
    {
        if (block.timestamp < lastExecutionTime + 60) {
            return (false, execData);
        }
        return (true, execData);
    }
}

interface IOps {
    function getFeeDetails() external view returns (uint256, address);
    function gelato() external view returns (address payable);
    function cancelTask(bytes32 _taskId) external;

    function createTaskNoPrepayment(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData,
        address _feeToken
    ) external returns (bytes32 task);
}