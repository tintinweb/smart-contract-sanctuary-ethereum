// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Target {
    address last_sender;
    string fee;

    constructor() {
        last_sender = msg.sender;

    }

    function set(string memory fee_) external returns (address) {
        last_sender = msg.sender;
        fee = fee_;
        return msg.sender;
    }

    function get() external view returns (string memory) {
        return fee;
    }
}


/**
 * set()을 호출하면 msg.sender의 주소를 last_sender에 저장하고, msg.sender를 반환하는 간단한 컨트랙트를 통해
 * 호출 구조를 확인할 수 있다.
 */