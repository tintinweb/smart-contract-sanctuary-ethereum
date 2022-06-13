//SPDX-License-Identifier: MIT

pragma solidity >0.4.0 <0.9.0;

import "./Ownable.sol";

contract MiniBank is Ownable {
    int256 credit;

    constructor() {
        credit = 0;
    }

    function deposit(int256 amount) public {
        credit += amount;
    }

    function withdraw(int256 amount) public {
        credit -= amount;
    }

    function getCreditAmount() public view returns (int256) {
        return credit;
    }

    function removeAllCredits() public onlyOwner {
        credit = 0;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >0.4.0 <0.9.0;

contract Ownable {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(
            payable(msg.sender) == owner,
            "You are not owner of this contract"
        );
        _;
    }
}