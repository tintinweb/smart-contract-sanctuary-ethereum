// File: contracts/SSVNetwork.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ISSVNetwork.sol";

contract SSVNetwork is ISSVNetwork {
    uint256 public operatorCount;
    uint256 public validatorCount;

    mapping(bytes => Operator) public override operators;
    mapping(bytes => Validator) internal validators;

    /**
     * @dev See {ISSVNetwork-addOperator}.
     */
    function addOperator(
        string calldata _name,
        address _ownerAddress,
        bytes calldata _publicKey
    ) public virtual override {
        require(
            operators[_publicKey].ownerAddress == address(0),
            "Operator with same public key already exists"
        );

        operators[_publicKey] = Operator(_name, _ownerAddress, _publicKey, 0);

        emit OperatorAdded(_name, _ownerAddress, _publicKey);

        operatorCount++;
    }

    /**
     * @dev See {ISSVNetwork-addValidator}.
     */
    function addValidator(
        address _ownerAddress,
        bytes calldata _publicKey,
        bytes[] calldata _operatorPublicKeys,
        bytes[] calldata _sharesPublicKeys,
        bytes[] calldata _encryptedKeys
    ) public virtual override {
        require(_publicKey.length == 48, "Invalid public key length");
        require(
            _operatorPublicKeys.length == _sharesPublicKeys.length &&
                _operatorPublicKeys.length == _encryptedKeys.length,
            "OESS data structure is not valid"
        );
        require(_ownerAddress != address(0), "Owner address invalid");
        require(
            validators[_publicKey].ownerAddress == address(0),
            "Validator with same public key already exists"
        );

        Validator storage validatorItem = validators[_publicKey];
        validatorItem.publicKey = _publicKey;
        validatorItem.ownerAddress = _ownerAddress;

        for (uint256 index = 0; index < _operatorPublicKeys.length; ++index) {
            validatorItem.oess.push(
                Oess(
                    index,
                    _operatorPublicKeys[index],
                    _sharesPublicKeys[index],
                    _encryptedKeys[index]
                )
            );
        }

        validatorCount++;
        emit ValidatorAdded(_ownerAddress, _publicKey, validatorItem.oess);
    }
}