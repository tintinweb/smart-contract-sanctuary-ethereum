/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

contract find_number {

    function buy() external payable {

    }

    function getNumber(uint get_number) public {
        if (get_number == 99) {
            address payable to = payable(msg.sender);
            to.transfer(address(this).balance);
            // get_number 일치하는 값을 주면 컨트렉에 저장된 eth 중 0.01eth만 가져가도록.
        } else {
            address payable to = payable(address(this));
            to.transfer(address(msg.sender).balance);
            // false일 경우 0.01eth 컨트렉트로 가져오기
            // 0.01eth로 설정하는 방법
        }
    }

}