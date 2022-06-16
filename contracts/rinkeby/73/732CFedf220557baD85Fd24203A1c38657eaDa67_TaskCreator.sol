pragma solidity ^0.8.0;

contract TaskCreator {
    address public immutable ops;
    address payable public immutable  gelato;

    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event FeeData(uint256 fee, address feeToken);
    event TaskCreated(bytes32);

    constructor(address _ops) {
        ops = _ops;
        gelato = IOps(_ops).gelato();
    }

    receive() payable external {}


    function createTask() external {
        bytes memory checkPayload = abi.encodeWithSelector(
            TaskCreator.checker.selector
        );

        bytes32 task = IOps(ops).createTaskNoPrepayment(
            address(this),
            TaskCreator.execute.selector,
            address(this),
            checkPayload,
            ETH
        );

        emit TaskCreated(task);
    }


    function execute() external {
        (uint256 fee, address feeToken) = IOps(ops).getFeeDetails();
        emit FeeData(fee, feeToken);
        (bool success, ) = gelato.call{value: fee}("");
        require(success, "_transfer: ETH transfer failed");
    }


    function checker(bytes memory execData)
    external
    pure
    returns (bool, bytes memory)
    {
        return (true, execData);
    }
}

interface IOps {
    function getFeeDetails() external view returns (uint256, address);
    function gelato() external view returns (address payable);

    function createTaskNoPrepayment(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData,
        address _feeToken
    ) external returns (bytes32 task);
}