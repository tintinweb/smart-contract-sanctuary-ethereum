// SPDX-License-Identifier: BSL 1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../interfaces/ISuVault.sol";
import "../interfaces/ISuCollateralRegistry.sol";

// [deprecated]
// This contract is needed to index all opened CDPs.
// It can be removed if there's more gas-efficient way to do that, such as graphQL, NFT-lps or other methods
contract SuCdpRegistry {
    // Collateral Debt Position
    struct CDP {
        address asset; // collateral token
        address owner; // borrower account
    }

    // mapping from collateral token to list of borrowers?
    mapping (address => address[]) cdpList;

    // mapping from collateral token to borrower to the INDEX, index in the previous list?
    mapping (address => mapping (address => uint)) cdpIndex;

    // address of the vault contract
    ISuVault public immutable vault;

    // address of the collateral registry contract
    ISuCollateralRegistry public immutable cr;

    // event emitted when a new CDP is created
    event Added(address indexed asset, address indexed owner);

    // event emitted when a CDP is closed
    event Removed(address indexed asset, address indexed owner);

    // this contract is deployed after the vault and collateral registry
    constructor (address _vault, address _collateralRegistry) {
        require(_vault != address(0) && _collateralRegistry != address(0), "Unit Protocol: ZERO_ADDRESS");
        vault = ISuVault(_vault);
        cr = ISuCollateralRegistry(_collateralRegistry);
    }

    // anyone can create checkpoint?
    function checkpoint(address asset, address owner) public {
        require(asset != address(0) && owner != address(0), "Unit Protocol: ZERO_ADDRESS");

        // only for listed assets
        bool listed = isListed(asset, owner);

        // only for alive assets
        bool alive = isAlive(asset, owner);

        if (alive && !listed) {
            _addCdp(asset, owner);
        } else if (listed && !alive) {
            _removeCdp(asset, owner);
        }
    }

    // checkpoint in loop
    function batchCheckpointForAsset(address asset, address[] calldata owners) external {
        for (uint i = 0; i < owners.length; i++) {
            checkpoint(asset, owners[i]);
        }
    }

    // multiple checkpoints for different collaterals
    function batchCheckpoint(address[] calldata assets, address[] calldata owners) external {
        require(assets.length == owners.length, "Unit Protocol: ARGUMENTS_LENGTH_MISMATCH");
        for (uint i = 0; i < owners.length; i++) {
            checkpoint(assets[i], owners[i]);
        }
    }

    // alive means there are debts in the vault for this collateral of this borrower
    function isAlive(address asset, address owner) public view returns (bool) {
        return vault.debts(asset, owner) != 0;
    }

    // listed means there are created cdps in this contract for this collateral of this borrower
    function isListed(address asset, address owner) public view returns (bool) {
        if (cdpList[asset].length == 0) { return false; }
        return cdpIndex[asset][owner] != 0 || cdpList[asset][0] == owner;
    }

    // internal function to perform removal of cdp from the list
    function _removeCdp(address asset, address owner) internal {
        // take the index by collateral and borrower
        uint id = cdpIndex[asset][owner];

        // then delete this index
        delete cdpIndex[asset][owner];

        // if the index is not the last one
        uint lastId = cdpList[asset].length - 1;

        // swap the last element with the element to be deleted
        if (id != lastId) {
            address lastOwner = cdpList[asset][lastId];
            cdpList[asset][id] = lastOwner;
            cdpIndex[asset][lastOwner] = id;
        }

        // delete the last element
        cdpList[asset].pop();

        // can we optimize this remove function by changing the structure?

        emit Removed(asset, owner);
    }

    function _addCdp(address asset, address owner) internal {
        // remember the index of the new element
        cdpIndex[asset][owner] = cdpList[asset].length;

        // add the new element to the end of the list
        cdpList[asset].push(owner);

        emit Added(asset, owner);
    }

    // read-only function to get the list of cdps for a given collateral
    function getCdpsByCollateral(address asset) external view returns (CDP[] memory cdps) {
        address[] memory owners = cdpList[asset];
        cdps = new CDP[](owners.length);
        for (uint i = 0; i < owners.length; i++) {
            cdps[i] = CDP(asset, owners[i]);
        }
    }

    // read-only function to get the list of all cdps by borrower
    function getCdpsByOwner(address owner) external view returns (CDP[] memory r) {
        address[] memory assets = cr.collaterals();
        CDP[] memory cdps = new CDP[](assets.length);
        uint actualCdpsCount;

        for (uint i = 0; i < assets.length; i++) {
            if (isListed(assets[i], owner)) {
                cdps[actualCdpsCount++] = CDP(assets[i], owner);
            }
        }

        r = new CDP[](actualCdpsCount);

        for (uint i = 0; i < actualCdpsCount; i++) {
            r[i] = cdps[i];
        }

    }

    // read-only function to get the list of all cdps
    function getAllCdps() external view returns (CDP[] memory r) {
        uint totalCdpCount = getCdpsCount();

        uint cdpCount;

        r = new CDP[](totalCdpCount);

        address[] memory assets = cr.collaterals();
        for (uint i = 0; i < assets.length; i++) {
            address[] memory owners = cdpList[assets[i]];
            for (uint j = 0; j < owners.length; j++) {
                r[cdpCount++] = CDP(assets[i], owners[j]);
            }
        }
    }

    // total number of cdps
    function getCdpsCount() public view returns (uint totalCdpCount) {
        address[] memory assets = cr.collaterals();
        for (uint i = 0; i < assets.length; i++) {
            totalCdpCount += cdpList[assets[i]].length;
        }
    }

    // number of cdps for a given collateral
    function getCdpsCountForCollateral(address asset) public view returns (uint) {
        return cdpList[asset].length;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ISuVault {
    function DENOMINATOR_1E5 (  ) external view returns ( uint256 );
    function borrow ( address asset, address user, uint256 amount ) external returns ( uint256 );
    function calculateFee ( address asset, address user, uint256 amount ) external view returns ( uint256 );
    function changeOracleType ( address asset, address user, uint256 newOracleType ) external;
    function chargeFee ( address asset, address user, uint256 amount ) external;
    function collaterals ( address, address ) external view returns ( uint256 );
    function debts ( address, address ) external view returns ( uint256 );
    function deposit ( address asset, address user, uint256 amount ) external;
    function destroy ( address asset, address user ) external;
    function getTotalDebt ( address asset, address user ) external view returns ( uint256 );
    function lastUpdate ( address, address ) external view returns ( uint256 );
    function liquidate ( address asset, address positionOwner, uint256 mainAssetToLiquidator, uint256 mainAssetToPositionOwner, uint256 repayment, uint256 penalty, address liquidator ) external;
    function liquidationBlock ( address, address ) external view returns ( uint256 );
    function liquidationFee ( address, address ) external view returns ( uint256 );
    function liquidationPrice ( address, address ) external view returns ( uint256 );
    function oracleType ( address, address ) external view returns ( uint256 );
    function repay ( address asset, address user, uint256 amount ) external returns ( uint256 );
    function spawn ( address asset, address user ) external;
    function stabilityFee ( address, address ) external view returns ( uint256 );
    function tokenDebts ( address ) external view returns ( uint256 );
    function triggerLiquidation ( address asset, address positionOwner, uint256 initialPrice ) external;
    function update ( address asset, address user ) external;
    function stablecoin (  ) external view returns ( address );
    function vaultParameters (  ) external view returns ( address );
    function withdraw ( address asset, address user, uint256 amount ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ISuCollateralRegistry {
    function addCollateral ( address asset ) external;
    function collateralId ( address ) external view returns ( uint256 );
    function collaterals (  ) external view returns ( address[] memory );
    function removeCollateral ( address asset ) external;
    function vaultParameters (  ) external view returns ( address );
    function isCollateral ( address asset ) external view returns ( bool );
    function collateralList ( uint id ) external view returns ( address );
    function collateralsCount (  ) external view returns ( uint );
}