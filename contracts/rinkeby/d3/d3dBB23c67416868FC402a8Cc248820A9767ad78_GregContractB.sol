// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;


import "./GregContractAInterface.sol";

contract GregContractB {

    address _contractAddress;

    constructor(address contractAddress) {
        _contractAddress = contractAddress;
    }

    function getCountContractA() public view returns (uint counter) {
        return GregContractAInterface(_contractAddress).getCount();
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;


interface GregContractAInterface {
    function getCount() external view returns (uint counter);

    function increment() external;
}