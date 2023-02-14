pragma solidity 0.8.17;
contract Testie
{
    event Purchased(bytes32[][]);
    event Bingy(uint SaleIndex, uint DesiredAmount, uint DelegationIndex, uint MaxAmount);
    function Purchase(bytes32[][] calldata Proofs) external
    {   
        uint _SaleIndex = uint(Proofs[0][0]);
        uint _DesiredAmount = uint(Proofs[0][1]);
        uint _DelegationIndex = uint(Proofs[0][2]);
        uint _MaxAmount = uint(Proofs[0][3]);
        emit Purchased(Proofs);
        emit Bingy(_SaleIndex, _DesiredAmount, _DelegationIndex, _MaxAmount);
    }
}