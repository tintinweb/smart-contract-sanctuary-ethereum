pragma solidity ^0.8.0;

contract TaskCreator {
    address public immutable ops;
    address payable public immutable  gelato;
    uint256 lastExecutionTime;

    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event FeeData(uint256 fee, address feeToken);
    event TaskCreated(bytes32);
    event TaskCancelled(bytes32);
    event Execution(uint256);

    constructor(address _ops) {
        ops = _ops;
        gelato = IOps(_ops).gelato();
    }

    receive() payable external {}


    function createTask(uint256 number) external {

        bytes32 task = IOps(ops).createTaskNoPrepayment(
            address(this),
            this.execute.selector,
            address(this),
            abi.encodeWithSelector(this.checker.selector, number),
            ETH
        );

        emit TaskCreated(task);
    }


    function cancelTask(bytes32 _taskId) external {
        IOps(ops).cancelTask(_taskId);

        emit TaskCancelled(_taskId);
    }


    function execute(uint256 number) external {
        lastExecutionTime = block.timestamp;
        (uint256 fee, address feeToken) = IOps(ops).getFeeDetails();
        emit FeeData(fee, feeToken);
        emit Execution(number);
        (bool success, ) = gelato.call{value: fee}("");
        require(success, "_transfer: ETH transfer failed");
    }


    function checker(uint256 number)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        //checking input data for test purpose
        canExec = number % 2 == 0
            && (block.timestamp - lastExecutionTime) > 30;

        execPayload = abi.encodeWithSelector(
            this.execute.selector,
            number
        );
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