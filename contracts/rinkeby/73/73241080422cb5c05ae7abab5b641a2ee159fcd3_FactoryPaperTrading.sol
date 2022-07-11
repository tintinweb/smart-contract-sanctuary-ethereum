/** 
    Created by Arcadia Finance
    https://www.arcadia.finance

    SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity >=0.4.22 <0.9.0;

import "./Factory.sol";
import "./IVaultPaperTrading.sol";

contract FactoryPaperTrading is Factory {
    using Strings for uint256;
    using Strings for uint8;
    using Strings for uint128;

    address tokenShop;

    /** 
    @notice returns contract address of individual vaults
    @param id The id of the Vault
    @return vaultAddress The contract address of the individual vault
  */
    function getVaultAddress(uint256 id)
        external
        view
        returns (address vaultAddress)
    {
        vaultAddress = allVaults[id];
    }

    /** 
    @notice Function to set a new contract for the tokenshop logic
    @param _tokenShop The new tokenshop contract
  */
    function setTokenShop(address _tokenShop) public onlyOwner {
        tokenShop = _tokenShop;
    }

    /** 
  @notice Function used to create a Vault
  @dev This is the starting point of the Vault creation process. 
  @param salt A salt to be used to generate the hash.
  @param numeraire An identifier (uint256) of the Numeraire
*/
    function createVault(uint256 salt, uint256 numeraire)
        external
        override
        returns (address vault)
    {
        bytes memory initCode = type(Proxy).creationCode;
        bytes memory byteCode = abi.encodePacked(
            initCode,
            abi.encode(vaultDetails[currentVaultVersion].logic)
        );

        assembly {
            vault := create2(0, add(byteCode, 32), mload(byteCode), salt)
        }

        allVaults.push(vault);
        isVault[vault] = true;
        vaultIndex[vault] = allVaults.length - 1;

        IVaultPaperTrading(vault).initialize(
            msg.sender,
            vaultDetails[currentVaultVersion].registryAddress,
            numeraire,
            numeraireToStable[numeraire],
            vaultDetails[currentVaultVersion].stakeContract,
            vaultDetails[currentVaultVersion].interestModule,
            tokenShop
        );

        _mint(msg.sender, allVaults.length - 1);
        emit VaultCreated(vault, msg.sender, allVaults.length - 1);
    }

    function liquidate(address) external pure override {
        revert("Not Allowed");
    }

    /** 
    @notice Function used by a keeper to start the liquidation of a vault.
    @dev This function is called by an external user or a bot to start the liquidation process of a vault.
    @dev Keepers are incentivized to liquidate vaults by earning a $20 000 reward in one of their
         own vaults
    @param vaultLiquidate Vault that needs to get liquidated.
    @param vaultReward Vault that should receive the $20 000 reward.
  */
    function liquidate(address vaultLiquidate, address vaultReward) external {
        require(isVault[vaultLiquidate], "FTRY_RR: Not a vault");
        require(isVault[vaultReward], "FTRY_RR: Not a vault");
        _liquidate(vaultLiquidate, msg.sender);
        require(
            ownerOf[vaultIndex[vaultReward]] != liquidatorAddress,
            "FTRY_RR: Can't send rewards to liquidated vaults."
        );
        IVaultPaperTrading(vaultReward).receiveReward();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory uri)
    {
        require(
            ownerOf[tokenId] != address(0),
            "ERC721Metadata: URI query for nonexistent token"
        );

        address vaultAddr = allVaults[tokenId];
        uint256 life = IVaultPaperTrading(vaultAddr).life();

        (uint128 vaultDebt, , , , , uint8 vaultNumeraire) = IVaultPaperTrading(
            vaultAddr
        ).debt();
        uint256 vaultValue = IVaultPaperTrading(vaultAddr).getValue(
            vaultNumeraire
        );
        //return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";

        // needed to prevent stack too deep
        string memory baseId = string(
            abi.encodePacked(baseURI, tokenId.toString(), "/")
        );

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseId,
                        vaultValue.toString(),
                        "/",
                        vaultNumeraire.toString(),
                        "/",
                        vaultDebt.toString(),
                        "/",
                        life.toString()
                    )
                )
                : "";
    }
}