// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./env.sol";

contract Target {
    address last_sender;

    constructor() {
        last_sender = msg.sender;
    }

    function set() external returns (address) {
        last_sender = msg.sender;
        return msg.sender;
    }

    function get() external pure returns (string memory) {
        return env.const;
    }
}


/**
 * set()을 호출하면 msg.sender의 주소를 last_sender에 저장하고, msg.sender를 반환하는 간단한 컨트랙트를 통해
 * 호출 구조를 확인할 수 있다.
 */

pragma solidity ^0.8.4;

library env {
    string public constant const = "1234567890";
}