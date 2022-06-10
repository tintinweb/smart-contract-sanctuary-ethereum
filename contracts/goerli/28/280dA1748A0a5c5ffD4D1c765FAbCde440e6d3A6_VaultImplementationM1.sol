pragma solidity 0.8.10;

interface IFactory {
    function ownerOfVault(address _vault) external view returns (address);

    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IFactory} from "../../../IFactory.sol";

contract Constants {
    // ERC721
    IFactory public immutable factory;

    constructor(address _factory) {
        factory = IFactory(_factory);
    }
}

contract VaultImplementationM1 is Constants {
    constructor(address _factory) Constants(_factory) {}

    /**
     * @dev Check for Auth if enabled.
     * @param user address/user/owner.
     */
    function isAuth(address user) public view returns (bool) {
        return factory.ownerOfVault(address(this)) == user;
    }

    event LogCast(address indexed sender, uint256 value, address[] targets);

    receive() external payable {}

    /**
     * @dev Make call to `_target`.
     * @param _target Target address
     * @param _value ETH value to send
     * @param _data CallData of function.
     */
    function spell(
        address _target,
        uint256 _value,
        bytes memory _data
    ) internal {
        require(_target != address(0), "target-invalid");
        (bool success, ) = _target.call{value: _value}(_data);
        require(success, "Error Calling Target");
    }

    /**
     * @dev This is the main function, Where all the different functions are called
     * from Smart Account.
     * @param _targets Array of Target address.
     * @param _values Array of ETH values
     * @param _datas Array of Calldata.
     */
    function cast(
        address[] calldata _targets,
        uint256[] calldata _values,
        bytes[] calldata _datas
    ) external payable {
        uint256 _length = _targets.length;
        require(isAuth(msg.sender), "1: permission-denied");
        require(_length != 0, "1: length-invalid");
        require(
            _length == _datas.length && _length == _values.length,
            "1: array-length-invalid"
        );

        for (uint256 i = 0; i < _length; i++) {
            spell(_targets[i], _values[i], _datas[i]);
        }

        emit LogCast(msg.sender, msg.value, _targets);
    }
}