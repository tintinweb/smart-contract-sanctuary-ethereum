/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

contract kucoin {
    uint256 amount;
    mapping(uint => string) public getPersonInfo;

    customer[] newCustomer;
    struct customer {
        uint256 amount;
        string customerName;
    }

    function store(uint256 _amount) public virtual {
        amount = _amount;
    }

    function retrieve() public view virtual returns (uint256) {
        return amount;
    }

    function addIndividual(string memory _customerName, uint256 _amount)
        public
    {
        newCustomer.push(customer(_amount, _customerName));
        getPersonInfo[_amount] = _customerName;
    }

    //The pure function just allows us use one particuar continously
    function add() public pure returns (uint256) {
        return (1 + 1);
    }
}