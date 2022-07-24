// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interface/IPublish.sol";

contract PublishTest is IPublishTest {
    constructor(bool flag) {
        requireTrue(flag);
    }

    function requireTrue(bool flag) public view override {
        require(flag, "flag is false");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPublishTest {
    function requireTrue(bool flag) external view;
}