pragma solidity ^0.8.0;

contract FeePayer {
    address public immutable ops;
    address payable public immutable  gelato;

    event FeeData(uint256 fee, address feeToken);

    constructor(address _ops) {
        ops = _ops;
        gelato = IOps(_ops).gelato();
    }

    function execute() external {
        (uint256 fee, address feeToken) = IOps(ops).getFeeDetails();
        emit FeeData(fee, feeToken);
        (bool success, ) = gelato.call{value: fee}("");
        require(success, "_transfer: ETH transfer failed");
    }
}

interface IOps {
    function getFeeDetails() external view returns (uint256, address);
    function gelato() external view returns (address payable);
}