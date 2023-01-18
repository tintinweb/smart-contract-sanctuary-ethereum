// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../MarketplaceFacet/CommissionsFacet.sol";

contract DeployCommissions {
    function deployCommissionContract(
        address adminRolesContract
    ) external returns(address) {
        CommissionsFacet commissionContract = new CommissionsFacet(
            address(adminRolesContract)
        );

        return address(commissionContract);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// MarketPlaceCommission
// 2000000000 - NUser
// 1000000000 - GBUser

import "../../interfaces/IAdminRoles.sol";
import { LibCommissions } from "../../libraries/LibCommissionsFacetStorage.sol";

error not_MSAdmin();
error not_PSAdmin();

contract CommissionsFacet {
    constructor(address _ARolesContractAddress) {
        LibCommissions.CommissionsFacetStorage storage ds = LibCommissions.commissionsFacetStorage();
        ds.AdminRoleContractAddress = _ARolesContractAddress;
    }

    modifier only_MPSuperAdmin() {
        LibCommissions.CommissionsFacetStorage storage ds = LibCommissions.commissionsFacetStorage();

        // To find whether txn is done only by MPSAdmin
        ds.isMPSuperAdmin = IAdminRoles(ds.AdminRoleContractAddress).only_MPSuperAdmin(
            msg.sender
        );
        if(!ds.isMPSuperAdmin) {
            revert not_MSAdmin();
        }
        _;
    }

    modifier only_PSuperAdmin() {
        LibCommissions.CommissionsFacetStorage storage ds = LibCommissions.commissionsFacetStorage();

        // To find whether txn is done only by PSAdmin
        ds.isPSuperAdmin = IAdminRoles(ds.AdminRoleContractAddress).only_PSuperAdmin(
            msg.sender
        );
        if(!ds.isPSuperAdmin) {
            revert not_PSAdmin();
        }
        _;
    }
    
    // Setting up the commission and fees by MPSuperAdmin
    function setCommissionAndFees_NU(
        uint _whiteListingFee,
        uint _collectionCreationFee,
        uint _NFTMintListingFee,
        uint _MPCommission,
        uint _royaltyCommission
    ) external only_MPSuperAdmin {
        LibCommissions.setCommissionAndFees_NU(
            _whiteListingFee,
            _collectionCreationFee,
            _NFTMintListingFee,
            _MPCommission,
            _royaltyCommission
        );
    }

    function setCommissionAndFees_GB(
        uint _collectionCreationFee,
        uint _NFTMintListingFee,
        uint _MPCommission,
        uint _royaltyCommission
    ) external only_MPSuperAdmin {
        LibCommissions.setCommissionAndFees_GB(
            _collectionCreationFee,
            _NFTMintListingFee,
            _MPCommission,
            _royaltyCommission
        );
    }
    
    // Setting up the commssion percentage from marketplace
    function setCommission_P (
        uint _PwhitelistingCommission,
        uint _PcollectionCreationCommission,
        uint _PNFTMintListingCommission,
        uint _PCommission,
        uint _ProyaltyCommission
    ) external only_PSuperAdmin {
        LibCommissions.setCommission_P(
            _PwhitelistingCommission,
            _PcollectionCreationCommission, 
            _PNFTMintListingCommission, 
            _PCommission, 
            _ProyaltyCommission
        );
    }

    function GetWhitelistingFee() external view returns(uint _whitelistingFee, uint _whitelistingCommission) {
        LibCommissions.CommissionsFacetStorage storage ds = LibCommissions.commissionsFacetStorage();
        return (ds.whitelistingFee, ds.commission_p.whitelistingCommission);
    }

    // Getting the commission and fees for normal user
    function GetFeeAndCommission_NU() external view returns(
        uint _collectionCreationFee,
        uint _nftMintListingFee,
        uint _marketplaceCommission,
        uint _royaltyCommission,
        uint _PcollectionCreationCommission,
        uint _PNFTMintListingCommission,
        uint _PCommission,
        uint _ProyaltyCommission
    ) {
        LibCommissions.CommissionsFacetStorage storage ds = LibCommissions.commissionsFacetStorage();
        return (
            ds.fees_normalUser.collectionCreationFee,
            ds.fees_normalUser.NFTMintListingFee,
            ds.fees_normalUser.MarketplaceCommission,
            ds.fees_normalUser.RoyaltyCommission,
            ds.commission_p.collectionCreationCommission,
            ds.commission_p.NFTMintListingCommission,
            ds.commission_p.PlatformCommission,
            ds.commission_p.RoyaltyCommission
        );
    }

    // Getting the commission and fees for GoldenBadge user
    function GetFeeAndCommission_GB() external view returns(
        uint _collectionCreationFee,
        uint _nftMintListingFee,
        uint _marketplaceCommission,
        uint _royaltyCommission,
        uint _PcollectionCreationCommission,
        uint _PNFTMintListingCommission,
        uint _PCommission,
        uint _ProyaltyCommission
    ) {
        LibCommissions.CommissionsFacetStorage storage ds = LibCommissions.commissionsFacetStorage();
        return (
            ds.fees_GBUser.collectionCreationFee,
            ds.fees_GBUser.NFTMintListingFee,
            ds.fees_GBUser.MarketplaceCommission,
            ds.fees_GBUser.RoyaltyCommission,
            ds.commission_p.collectionCreationCommission,
            ds.commission_p.NFTMintListingCommission,
            ds.commission_p.PlatformCommission,
            ds.commission_p.RoyaltyCommission
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAdminRoles {
    function only_MPSuperAdmin(address admin) external view returns(bool);
    function only_PSuperAdmin(address admin) external view returns(bool);
    function admin_Addresses() external view returns(address PSuperAdmin, address MPSuperAdmin);
    function only_super_and_CompilanceAdmin(address admin) external view returns(bool);
    function GetNumConfirmationsRequired() external view returns(uint);
    function only_super_or_MPTokenAdmin(address admin) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibCommissions {
    bytes32 constant STORAGE_POSITION = keccak256("car.storage.marketplace.commissions.facet");

    struct Fees_NU {
        uint256 collectionCreationFee;
        uint256 NFTMintListingFee;
        uint256 MarketplaceCommission;
        uint256 RoyaltyCommission;
    }
    
    struct Fees_GB {
        uint256 collectionCreationFee;
        uint256 NFTMintListingFee;
        uint256 MarketplaceCommission;
        uint256 RoyaltyCommission;
    }

    struct Commission_P {
        uint256 whitelistingCommission;
        uint256 collectionCreationCommission;
        uint256 NFTMintListingCommission;
        uint256 PlatformCommission;
        uint256 RoyaltyCommission;
    }

    struct CommissionsFacetStorage {
        uint256 whitelistingFee;
        bool isPSuperAdmin;
        bool isMPSuperAdmin;
        address AdminRoleContractAddress;

        Fees_NU fees_normalUser;
        Fees_GB fees_GBUser;
        Commission_P commission_p;
    }

    // Creates and returns the storage pointer to the struct.
    function commissionsFacetStorage() internal pure returns (CommissionsFacetStorage storage ds) {
		bytes32 storagePosition = STORAGE_POSITION;
		
		assembly {
			ds.slot := storagePosition
		}
	}

    function setCommissionAndFees_NU(
        uint _whiteListingFee,
        uint _collectionCreationFee,
        uint _NFTMintListingFee,
        uint _MPCommission,
        uint _royaltyCommission
    ) internal {
        CommissionsFacetStorage storage ds = commissionsFacetStorage();
        ds.whitelistingFee = _whiteListingFee; 
        ds.fees_normalUser = Fees_NU(
            _collectionCreationFee, 
            _NFTMintListingFee, 
            _MPCommission, 
            _royaltyCommission
        );
    }

    function setCommissionAndFees_GB(
        uint _collectionCreationFee,
        uint _NFTMintListingFee,
        uint _MPCommission,
        uint _royaltyCommission
    ) internal {
        CommissionsFacetStorage storage ds = commissionsFacetStorage();
        ds.fees_GBUser = Fees_GB(
            _collectionCreationFee, 
            _NFTMintListingFee, 
            _MPCommission, 
            _royaltyCommission
        );
    }

    function setCommission_P (
        uint _PwhitelistingCommission,
        uint _PcollectionCreationCommission,
        uint _PNFTMintListingCommission,
        uint _PCommission,
        uint _ProyaltyCommission
    ) internal {
        CommissionsFacetStorage storage ds = commissionsFacetStorage();
        ds.commission_p = Commission_P(
            _PwhitelistingCommission,
            _PcollectionCreationCommission, 
            _PNFTMintListingCommission, 
            _PCommission, 
            _ProyaltyCommission
        );
    }
}