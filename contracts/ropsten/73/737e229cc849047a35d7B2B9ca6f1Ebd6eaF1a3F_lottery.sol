/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
    Example of how a game smart contract, such as a lottery,
    can implement the use of the oracle random number.

    For more information https://www.random-oracle.com
*/
contract lottery {

    address private _owner;

    address private _oracle;

    uint256 private _winner;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not the owner");
        _;
    }

    constructor () {
        _owner = msg.sender;
    }

    /**
     * Use the random number to determine the lottery winner.
     *
     * FOR DEMONSTRATION PURPOSES:
     *      - function can be called by anyone.
     *      - winner corresponds to the random number generated.
     *
     * IN A REAL CONTEXT:
     *      - only the lottery manager should be able to call this function.
     *      - To extract the winner, for example from an array of addresses,
     *        the random number could be used in the following way:
     *
     *              winner = random_number % participants.lenght
     */
    function declareWinner(uint256 _oracleReceipt) public {
        _winner = getRandom(_oracleReceipt);
        emit WinnerDeclared(_winner);
    }

    // Return the last winner (in this case the random number)
    function getWinner() public view returns (uint256){
        return _winner;
    }

    // Use the oracle the get random number
    function getRandom(uint256 _oracleReceipt) private returns (uint256) {
        (bool success, bytes memory result) = _oracle.call(abi.encodeWithSignature("getRandom(uint256)", _oracleReceipt));
        require(success, "Oracle getRandom error");
        return abi.decode(result, (uint256));
    }

    // Allow owner change oracle address.
    function setOracle(address _a) public onlyOwner {
        _oracle = _a;
    }

    // Return current oracle address.
    function getOracle() public view returns (address){
        return _oracle;
    }

    // Emitted when a 'winner' is declarated
    event WinnerDeclared(uint256 winner);

}