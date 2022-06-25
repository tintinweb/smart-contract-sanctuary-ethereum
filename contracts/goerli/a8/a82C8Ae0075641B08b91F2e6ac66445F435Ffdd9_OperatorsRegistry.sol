// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File contracts/utils/Array.sol

// "SPDX-License-Identifier: UNLICENSED"

pragma solidity >=0.6.0 <0.8.0;

/**
 * Array library.
 * @author Yoel Zerbib
 * Date created: 4.6.22.
 * Github
**/

library Array {
    function removeElement(address[] storage _array, address _element) internal {
        for (uint256 i; i<_array.length; i++) {
            if (_array[i] == _element) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
        }
    }
}


// File contracts/OperatorRegistry.sol

pragma solidity ^0.7.4;

/**
 * OperatorRegistry contract.
 * @author Yoel Zerbib
 * Date created: 4.6.22.
 * Github
**/

contract OperatorsRegistry {

    using Array for address[];

    // Is operator mapping checker
    mapping(address => bool) public _isOperator;

    address [] public allOperators;

    address public committee;

    event OperatorStatusChanged(address operator, bool isMember);

    // Modifier for "only committee" methods 
    modifier onlyCommittee{
        require(msg.sender == committee, 'OperatorsRegistry: Restricted only to committee');
        _;
    }

    // constructor (address [] memory _operators, address _committee) {
    //     // Register committee
    //     committee = _committee;

    //     // Operators initialization
    //     for(uint i = 0; i < _operators.length; i++) {
    //         addOperatorInternal(_operators[i]);
    //     }
    // }

    function initialize(address [] memory _operators, address _committee) public {
        // Register committee
        committee = _committee;

        // Operators initialization
        for(uint i = 0; i < _operators.length; i++) {
            addOperatorInternal(_operators[i]);
        }
    }

    function addOperator(address _address) public onlyCommittee {
        addOperatorInternal(_address);
    }

    function addOperatorInternal(address _address) internal {
        require(_isOperator[_address] == false, "OperatorsRegistry :: Address is already a operator");

        allOperators.push(_address);
        _isOperator[_address] = true;

        emit OperatorStatusChanged(_address, true);
    }

    function removeOperator(address _operator) external onlyCommittee {
        require(_isOperator[_operator] == true, "OperatorsRegistry :: Address is not a operator");

        uint length = allOperators.length;
        require(length > 1, "Cannot remove last operator.");

        // Use custom array library for removing from array
        allOperators.removeElement(_operator);
        _isOperator[_operator] = false;

        emit OperatorStatusChanged(_operator, false);
    }

}