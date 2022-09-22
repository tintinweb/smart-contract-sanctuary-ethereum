// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";
import "./LeaseAgreement.sol";

/** 
 * @title LeaseTransfer
 * @dev Lease Agreement between Lessor and Lessee
 */

 contract LeaseTransfer is Ownable {

    event LogNewLeaseAgreement(address indexed creator, address la);

     /// Mapping of agreement id => LA address
    mapping(bytes32 => address) public leaseAgreements;

     /**
     * @dev Create a new LeaseAgreement.
     */
    function createLeaseAgreement(
        bytes32 _laId,
        address _lessor,
        address _lessee
    )
        external
        returns (address)
    {
        LeaseAgreement la = new LeaseAgreement(_laId, _lessor, _lessee);
        leaseAgreements[_laId] = address(la);

        la.transferOwnership(_lessee);

        emit LogNewLeaseAgreement(_lessee, address(la));
        return address(la);
    }
 }