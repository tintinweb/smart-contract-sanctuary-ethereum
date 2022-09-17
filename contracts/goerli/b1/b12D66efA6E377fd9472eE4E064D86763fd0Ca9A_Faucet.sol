// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Owned.sol";
import "./Logger.sol";
import "./IFaucet.sol";

contract Faucet is Owned, Logger, IFaucet {
    uint256 public numberOfFunders;

    mapping(address => bool) private funders;
    mapping(uint256 => address) private lutFunders;

    modifier limitWidthdraw(uint256 widthdrawLimit) {
        require(
            widthdrawLimit < 1000000000000000000,
            "Can not withdraw more than 1 ether."
        );
        _;
    }

    receive() external payable {}

    function test1() external onlyOwner {}

    function test2() external onlyOwner {}

    function emitLog() public pure virtual override returns (bytes32) {}

    function addFunds() external payable override {
        address funder = msg.sender;
        if (!funders[funder]) {
            uint256 i = numberOfFunders++;
            funders[funder] = true;
            lutFunders[i] = funder;
        } else {}
    }

    function getFunderAtIndex(uint8 index) external view returns (address) {
        return lutFunders[index];
    }

    function withdraw(uint256 widthdrawAmount)
        external
        override
        limitWidthdraw(widthdrawAmount)
    {
        payable(msg.sender).transfer(widthdrawAmount);
    }

    function getAllFunders() external view returns (address[] memory) {
        address[] memory _funders = new address[](numberOfFunders);

        for (uint8 i = 0; i < numberOfFunders; i++) {
            _funders[i] = lutFunders[i];
        }

        return _funders;
    }
}
// const instance = await Faucet.deployed();

// instance.addFunds({from: accounts[0], value: "2000000000000000000"});
// instance.addFunds({from: accounts[1], value: "2000000000000000000"});

// instance.withdraw("500000000000000000", {from: accounts[1]});

// instance.getFunderAtIndex(0);
// instance.getAllFunders();

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IFaucet {
    
    function addFunds() external payable;
    function withdraw(uint amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

abstract contract Logger {
  uint public testNum;
  constructor () {
    testNum = 1;
  }
  function emitLog() public pure virtual returns(bytes32);
  

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
contract Owned {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this method.");
        _;
    }
}