// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {
    string public message;
    uint256 number;

    constructor(string memory initialMessage) {
        message = initialMessage;
    }

    function updateMessage(string memory newMessage) public {
        message = newMessage;
    }

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256) {
        return number;
    }

    function multiply(uint256 num1, uint256 num2)
        public
        view
        returns (uint256)
    {
        return num2 * num1;
    }

    function storeAndRetrieve(uint256 num1, uint256 num2)
        public
        view
        returns (uint256)
    {
        return multiply(num1, num2);
    }

    function storeAndGet(uint256 num1, uint256 num2)
        public
        view
        returns (uint256)
    {
        uint256 xnum = retrieve();
        return multiply(xnum, 3);
    }

    function name() public view returns (string memory) {
        return message;
    }
}