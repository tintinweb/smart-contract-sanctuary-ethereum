// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Counter {
    uint256 public count;

    function increment() external {
        count += 1;
    }
}

// interface ICounter {
//     function count() external view returns (uint256);

//     function increment() external;
// }

// contract MyContract {
//     function incrementCounter(address _counter) external {
//         ICounter(_counter).increment();
//     }

//     function getCount(address _counter) external view returns (uint256) {
//         return ICounter(_counter).count();
//     }
// }