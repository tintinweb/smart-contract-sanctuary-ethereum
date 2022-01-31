/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// File: contracts/interfaces/ITestContract.sol

pragma solidity 0.8.3;

interface ITestContract {
    
    function storedVar() external view returns (uint256);

    function storedAddresses(uint256 _key) external view returns (address);

    function storeVar(uint256 _newValue) external;

    function storeAddress(uint256 _key) external;
}

// File: contracts/TestContract.sol

pragma solidity 0.8.3;


contract TestContract is ITestContract {
    uint256 public immutable multiplier;

    uint256 public override storedVar;

    mapping(uint256 => address) public override storedAddresses;

    event VarStored(address _sender, uint256 _prevValue, uint256 _newValue);
    event AddressStored(address _sender, uint256 _key, address _prevValue, address _newValue);

    constructor (uint256 _multiplier) {
        require(_multiplier > 0, "TestContract: Multiplier must be greater than zero.");

        multiplier = _multiplier;
    }

    function storeVar(uint256 _newValue) external override {
        require(_newValue != 0, "TestContract: New value must be greater than zero.");

        uint256 _prevValue = storedVar;
        _newValue *= multiplier;
        storedVar = _newValue;

        emit VarStored(msg.sender, _prevValue, _newValue);
    }

    function storeAddress(uint256 _key) external override {
        address _prevAddr = storedAddresses[_key];
        storedAddresses[_key] = msg.sender;

        emit AddressStored(msg.sender, _key, _prevAddr, msg.sender);
    }
}