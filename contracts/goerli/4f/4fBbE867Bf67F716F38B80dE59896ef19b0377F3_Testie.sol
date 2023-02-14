pragma solidity 0.8.17;
contract Testie
{
    event Purchased(bytes32[][]);
    function Purchase(bytes32[][] calldata Proofs) external
    {
        emit Purchased(Proofs);
    }
}