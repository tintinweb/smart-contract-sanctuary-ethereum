// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;
import './Escrow.sol';

contract EscrowFactory {
    // all Escrows will have this duration.
    uint256 constant STANDARD_DURATION = 8640000;

    uint256 public counter;
    mapping(address => uint256) public escrowCounters;
    address public lastEscrow;
    address public eip20;
    event Launched(address eip20, address escrow);

    constructor(address _eip20) {
        eip20 = _eip20;
    }

    function createEscrow(address[] memory trustedHandlers)
        public
        returns (address)
    {
        Escrow escrow = new Escrow(
            eip20,
            payable(msg.sender),
            STANDARD_DURATION,
            trustedHandlers
        );
        counter++;
        escrowCounters[address(escrow)] = counter;
        lastEscrow = address(escrow);
        emit Launched(eip20, lastEscrow);
        return lastEscrow;
    }

    function isChild(address _child) public view returns (bool) {
        return escrowCounters[_child] == counter;
    }

    function hasEscrow(address _address) public view returns (bool) {
        return escrowCounters[_address] != 0;
    }
}