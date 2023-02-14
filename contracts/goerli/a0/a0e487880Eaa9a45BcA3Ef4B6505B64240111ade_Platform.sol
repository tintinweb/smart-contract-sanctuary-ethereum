// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDeployAdminRoles {
    function deployAdminRolesContract(
        string memory _marketplaceName, 
        address _PSAdmin, 
        address _MPSAdmin
    ) external returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDeployCommissions {
    function deployCommissionContract(
        address adminRolesContract,
        address platformContract
    ) external returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDeployNftFactory {
    function deployNftFactoryContract(
        address adminRolesContract, 
        address commissionContract,
        address whiteListingContract,
        address nftMintingContract,
        address nftTraderContract
    ) external returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDeployWhiteListing {
    function deployWhiteListingContract(
        address adminRolesContract, 
        address commissionContract
    ) external returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../MPContractFactory/Interfaces/IDeployAdminRoles.sol";
import "../MPContractFactory/Interfaces/IDeployCommissions.sol";
import "../MPContractFactory/Interfaces/IDeployWhitelisting.sol";
import "../MPContractFactory/Interfaces/IDeployNftFactory.sol";

error not_a_super_admin();
error invalid_superAdmin();
error not_a_platform_super_admin();

contract Platform {
    address private PSAdmin;
    address private MPSAdmin;
    mapping(address => bool) private isPSuperAdmin;
    mapping(string => mapping(address => bool)) private isMPSuperAdmin;
    address private AdminRolesDeploymentContract;
    address private CommissionsDeploymentContract;
    address private WhitelistingDeploymentContract;
    address private NftFactoryDeploymentContract;
    address private NftMintingDeploymentContract;
    address private NftTraderDeploymentContract;
    address private adminRolesContract;
    address private commissionContract;
    address private whiteListingContract;
    address private nftFactoryContract;

    struct Commission_P {
        uint256 whitelistingCommission;
        uint256 collectionCreationCommission;
        uint256 NFTMintingCommission;
        uint256 NFTListingCommission;
        uint256 PlatformCommission;
        uint256 RoyaltyCommission;
    }

    Commission_P commission_p;

    struct Marketplaces{
        address adminRolesContractAddr;
        address commissionsContractAddr;
        address whiteListingContractAddr;
        address nftFactoryContractAddr;
    }
    mapping(address => Marketplaces[]) private marketplaces;

    event marketPlaceCreated(
        address indexed adminRolesContract,
        address indexed commissionContract,
        address indexed whiteListingContract,
        address nftFactoryContract
    );

    function initialize(
        address _adminRolesDeploymentContract,
        address _commissionsDeploymentContract,
        address _whitelistingDeploymentContract,
        address _nftFactoryDeploymentContract,
        address _nftMintingDeploymentContract,
        address _nftTraderDeploymentContract
    ) external {
        AdminRolesDeploymentContract = _adminRolesDeploymentContract;
        CommissionsDeploymentContract = _commissionsDeploymentContract;
        WhitelistingDeploymentContract = _whitelistingDeploymentContract;
        NftFactoryDeploymentContract = _nftFactoryDeploymentContract;
        NftMintingDeploymentContract = _nftMintingDeploymentContract;
        NftTraderDeploymentContract = _nftTraderDeploymentContract;

        PSAdmin = msg.sender;
        isPSuperAdmin[msg.sender] = true;
    }

    modifier only_plateformAdmin() {
        if(msg.sender != PSAdmin) {
            revert not_a_platform_super_admin();
        }
        _;
    }

    modifier only_MSAdmin() {
        if(msg.sender != MPSAdmin) {
            revert not_a_super_admin();
        }
        _;
    }

    // Setting up the commssion percentage from marketplace
    function setCommission_P (
        uint _PwhitelistingCommission,
        uint _PcollectionCreationCommission,
        uint _PNFTMintingCommission,
        uint _PNFTListingCommission,
        uint _PCommission,
        uint _ProyaltyCommission
    ) public only_plateformAdmin {
        commission_p = Commission_P(
            _PwhitelistingCommission,
            _PcollectionCreationCommission, 
            _PNFTMintingCommission, 
            _PNFTListingCommission,
            _PCommission, 
            _ProyaltyCommission
        );
    }

    function GetPlatformCommssions() external view returns(
        uint _whitelistingCommission,
        uint _PcollectionCreationCommission,
        uint _PNFTMintingCommission,
        uint _PNFTListingCommission,
        uint _PCommission,
        uint _ProyaltyCommission
    ) {
        return (
            commission_p.whitelistingCommission,
            commission_p.collectionCreationCommission,
            commission_p.NFTMintingCommission,
            commission_p.NFTListingCommission,
            commission_p.PlatformCommission,
            commission_p.RoyaltyCommission
        );
    }

    function addSuperAdmin(address _superAdmin, string memory _marketPlaceName) public only_plateformAdmin {
        if(_superAdmin == address(0)) {
            revert invalid_superAdmin();
        }

        isMPSuperAdmin[_marketPlaceName][_superAdmin] = true;
        MPSAdmin = _superAdmin;
    }

    function createNewMarketPlace(string memory _marketPlaceName) public only_MSAdmin {
        adminRolesContract = IDeployAdminRoles(AdminRolesDeploymentContract).deployAdminRolesContract(
            _marketPlaceName,
            PSAdmin,
            MPSAdmin
        );
        commissionContract = IDeployCommissions(CommissionsDeploymentContract).deployCommissionContract(
            adminRolesContract,
            address(this)
        );
        whiteListingContract = IDeployWhiteListing(WhitelistingDeploymentContract).deployWhiteListingContract(
            adminRolesContract,
            commissionContract
        );
        nftFactoryContract = IDeployNftFactory(NftFactoryDeploymentContract).deployNftFactoryContract(
            adminRolesContract,
            commissionContract,
            whiteListingContract,
            NftMintingDeploymentContract,
            NftTraderDeploymentContract
        );

        if(
            adminRolesContract != address(0) &&
            commissionContract != address(0) &&
            whiteListingContract != address(0) &&
            nftFactoryContract != address(0) 
        ) {
            marketplaces[msg.sender].push(
                Marketplaces(
                    adminRolesContract,
                    commissionContract,
                    whiteListingContract,
                    nftFactoryContract
                )
            );

            emit marketPlaceCreated(
                adminRolesContract,
                commissionContract,
                whiteListingContract,
                nftFactoryContract
            );
        } else {
            return createNewMarketPlace(_marketPlaceName);
        }
    }

    function getContractAddresses() public view returns(address, address, address, address) {
        return(
            adminRolesContract,
            commissionContract,
            whiteListingContract,
            nftFactoryContract
        );
    }

    function updatePSAdmin(address _psadmin) public only_MSAdmin {
        PSAdmin = _psadmin;
    }
}