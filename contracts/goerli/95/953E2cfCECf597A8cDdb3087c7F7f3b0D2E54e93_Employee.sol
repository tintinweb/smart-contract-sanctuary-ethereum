// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @title Employee
 * Contract with state variables employeeID and employeeName and setter functions
 */
contract Employee {
    uint public employeeID;
    string public employeeName;

    /**
     * @dev setEmployeeID
     * @param _eid value to store
     */
    function setEmployeeID(uint _eid) public returns (uint) {
        employeeID = _eid;
        return employeeID;
    }

    /**
     * @dev setEmployeeName
     * @param _name value to store
     * also accepts ether
     */
    function setEmployeeName(string memory _name) public payable returns (string memory, uint value) {
        employeeName = _name;
        return (employeeName, address(this).balance );
    }

    /**
     * @dev getFunctionSelectors : get the function selectors
     */
    function getFunctionSelectors() public pure returns (bytes4 , bytes4 ) {
        bytes4 selector1 = this.setEmployeeID.selector;
        bytes4 selector2 = this.setEmployeeName.selector;

        return (selector1, selector2);
    }

    /**
     * @dev calculateFunctionSelectors : calculate the function selectors
     * The function selector is calculated by taking the keccak256 hash of the function signature and 
     * then using the first four bytes of the hash value
     */
    function calculateFunctionSelectors() public pure returns (bytes4 , bytes4 ) {
        bytes4 selector1 = bytes4(keccak256(bytes("setEmployeeID(uint256)")));
        bytes4 selector2 = bytes4(keccak256(bytes("setEmployeeName(string)")));

        return (selector1, selector2);
    }
}