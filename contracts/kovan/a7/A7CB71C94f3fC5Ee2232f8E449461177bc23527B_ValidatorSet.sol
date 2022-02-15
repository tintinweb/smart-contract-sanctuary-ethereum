// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract ValidatorSetBase {
    event InitiateChange(bytes32 indexed parentHash, address[] newSet);

    function getValidators(uint ambBlockNumber) virtual public view returns (address[] memory);

    function finalizeChange(uint ambBlockNumber) virtual public;
}


contract ValidatorSet is ValidatorSetBase {
    mapping (uint => address[]) public validators;
    address[] public pendingValidators;


    constructor(address[] memory _initialValidators, uint ambBlockNumber) {
        require(_initialValidators.length > 0);
        validators[ambBlockNumber] = _initialValidators;
        pendingValidators = _initialValidators;
    }

    modifier inArray(address _subject, address[] memory _array, string memory _message) {
        require(checkInArray(_subject, _array), _message);
        _;
    }

    modifier notInArray(address _subject, address[] memory _array, string memory _message) {
        require(!checkInArray(_subject, _array), _message);
        _;
    }


    function getValidators(uint ambBlockNumber) public view override returns (address[] memory) {
        return validators[ambBlockNumber];
    }

    function getPendingValidators() public view returns (address[] memory) {
        return pendingValidators;
    }

    function addValidator(address _validator) public notInArray(_validator, pendingValidators, "Provided address is already a validator") {
        pendingValidators.push(_validator);
        emitChangeEvent();
    }

    function removeValidator(address _validator) public inArray(_validator, pendingValidators, "Provided address is not a validator") {
        for (uint i = 0; i < pendingValidators.length; ++i) {
            if (pendingValidators[i] == _validator) {
                pendingValidators[i] = pendingValidators[pendingValidators.length - 1];
                delete pendingValidators[pendingValidators.length - 1];
            }
        }
        emitChangeEvent();
    }

    function removeValidators(uint ambBlockNumber) public {
        delete validators[ambBlockNumber];
    }

    function finalizeChange(uint ambBlockNumber) public override {
        validators[ambBlockNumber] = pendingValidators;
    }

    function emitChangeEvent() private {
        /* solium-disable-next-line security/no-block-members */
        emit InitiateChange(blockhash(block.number - 1), pendingValidators);
    }

    function checkInArray(address _subject, address[] memory _array) private pure returns(bool) {
        for (uint i = 0; i < _array.length; ++i) {
            if (_array[i] == _subject) {
                return true;
            }
        }
        return false;
    }
}