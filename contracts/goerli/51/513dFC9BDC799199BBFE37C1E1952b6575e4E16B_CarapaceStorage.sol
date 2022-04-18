// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Interfaces/ICarapaceStorage.sol";
import "./Interfaces/ICarapaceAccess.sol";

/// @title The primary persistent storage for Carapace

contract CarapaceStorage is ICarapaceStorage, ERC721, ERC721Enumerable { //Preset for ERC721
    using Strings for uint256;
    
    mapping(uint256 => smartVaultDef) private smartVaults;
    mapping(address => mapping(IERC20 => bool)) private fungibleAssetsOfOwner;
    mapping(address => mapping(IERC20 => mapping(uint256 => uint256))) private fungibleAssetsBalanceOfBenef; //Beneficiary => ERC20 Address => Vault ID => Balance
    mapping(address => mapping(IERC721 => mapping(uint256 => bool))) private nonfungibleAssetsOfOwner;  // Owner => ERC721 => TokenID
    mapping(address => mapping(IERC721 => mapping(uint256 => mapping(uint256 => bool)))) private nonfungibleAssetsOfBenef;  //Beneficiary => ERC721 Address => TokenID => VaultID => Bool
    mapping(address => uint256[]) private vaultsOfTrustee;                              // Trustee => VaultIDs[]
    mapping(address => mapping(uint256 => uint256)) private vaultIsAtIndex;             //Aux vaultsOfTrustee: Trustee => VaultID => Index
    mapping(address => uint256[]) private vaultsOfBeneficiary;
    mapping(address => mapping(uint256 => uint256)) private vaultBenefIsAtIndex;        //Aux vaultsOfBeneficiary
    mapping(address => mapping(uint256 => uint256)) private vaultBeneficiaryBalance;    //Beneficiary => VaultID => Balance
    mapping(address => mapping(uint256 => uint256)) private vaultBeneficiaryRewards;    //Beneficiary => VaultID => Rewards
    mapping(uint256 => CarapaceNFTLib.VaultNFTParams) private vaultNFTParams; //NFT
    uint256 private protocolRewards;

    ICarapaceAccess carapaceAccess;

    constructor(ICarapaceAccess _carapaceAccessAddress) ERC721("Carapace Smart Vault", "CSV") { //Preset for ERC721
        // mint(msg.sender); //Preset for ERC721
        // burn(0);          //Preset for ERC721
        carapaceAccess = ICarapaceAccess(_carapaceAccessAddress);
    }

    modifier onlyAuthorized() {
        _onlyAuthorized();
        _;
    }

    function _onlyAuthorized() private view {
        require(carapaceAccess.getAccess(msg.sender), "NA_STO");
    }

    function getSmartVaultOwner(uint256 _vaultId) override external view returns (address) {
        return smartVaults[_vaultId].owner;
    }

    function getSmartVaultIsTrustee(uint256 _vaultId, address _trustee) override external view returns (bool) {
        return smartVaults[_vaultId].isTrustee[_trustee];
    }

    function getSmartVaultTrusteeIncentive(uint256 _vaultId) override external view returns (uint256) {
        return smartVaults[_vaultId].trusteeIncentive;
    }

    function getSmartVaultState(uint256 _vaultId) override external view returns (status) {
        return smartVaults[_vaultId].vaultState;
    }

    /// @param _vaultId The key for the record
    function getSmartVaultInfo(uint256 _vaultId) override external view returns (
        // address,
        IERC20[] memory,
        address[] memory,
        // uint256,
        // uint256,
        uint256,
        uint256) {
        return (
            // smartVaults[_vaultId].owner,
            smartVaults[_vaultId].fungibleAssets,
            smartVaults[_vaultId].trustees,
            // smartVaults[_vaultId].balance,
            // uint256(smartVaults[_vaultId].vaultState),
            smartVaults[_vaultId].requestExecTS,
            smartVaults[_vaultId].lockDays
        );
    }
    
    function getSmartVaultRwrdInfo(uint256 _vaultId) override external view returns (
        uint256,
        uint256) {
        return (
            smartVaults[_vaultId].balance,
            smartVaults[_vaultId].rewards
        );
    }

    function getProtocolRewards() override external view returns (uint256) {
        return protocolRewards;
    }

    /**
     * @dev Getter for the beneficiaries and respective percentages of a given Vault ID.
     */
    function getBeneficiaries(uint256 _vaultId) override public view returns (address[] memory _beneficiaries, uint256[] memory _percentages) {
        _beneficiaries = new address[](smartVaults[_vaultId].numBeneficiaries);
        _percentages = new uint256[](smartVaults[_vaultId].numBeneficiaries);

        for (uint256 i=0;i<smartVaults[_vaultId].numBeneficiaries;i++){
            _beneficiaries[i] = smartVaults[_vaultId].beneficiaries[i].beneficiary;
            _percentages[i] = smartVaults[_vaultId].beneficiaries[i].percentage;
        }
        return (_beneficiaries, _percentages);
    }

    /**
     * @dev Getter for Non-fungible assets, token ID and specific Beneficiary of a given Vault ID.
     */
    function getNonFungibleAssets(uint256 _vaultId) override external view returns (
        IERC721[] memory _nonfungibleAddresses,
        uint256[] memory _tokenids,
        address[] memory _beneficiaries) {
            
        _nonfungibleAddresses = new IERC721[](smartVaults[_vaultId].numNonFungibleAssets);
        _tokenids = new uint256[](smartVaults[_vaultId].numNonFungibleAssets);
        _beneficiaries = new address[](smartVaults[_vaultId].numNonFungibleAssets);

        for (uint256 i=0;i<smartVaults[_vaultId].numNonFungibleAssets;i++){
            _nonfungibleAddresses[i] = smartVaults[_vaultId].nonfungibleAssets[i].nonfungibleAddress;
            _tokenids[i] = smartVaults[_vaultId].nonfungibleAssets[i].tokenid;
            _beneficiaries[i] = smartVaults[_vaultId].nonfungibleAssets[i].beneficiary;
        }
        return (_nonfungibleAddresses, _tokenids, _beneficiaries);
    }

    /**
     * @dev Getter to retrive all Owner's Vaults.
     */
    function getVaultsOfOwner(address _owner) override external view returns (uint256[] memory _vaultsOfOwner) {
        _vaultsOfOwner = new uint256[](ERC721.balanceOf(_owner));
        for (uint256 i=0;i<ERC721.balanceOf(_owner);i++){
            _vaultsOfOwner[i] = ERC721Enumerable.tokenOfOwnerByIndex(_owner, i);
        }
        return _vaultsOfOwner;
    }

    /**
     * @dev Getter to retrive all Trustee's Vaults.
     */
    function getVaultsOfTrustee(address _trustee) override external view returns (uint256[] memory _vaultsOfTrustee) {
        _vaultsOfTrustee = new uint256[](vaultsOfTrustee[_trustee].length);
        _vaultsOfTrustee = vaultsOfTrustee[_trustee];
        return _vaultsOfTrustee;
    }
    
    /**
     * @dev Getter to retrive all Beneficiary's Vaults.
     */
    function getVaultsOfBeneficiary(address _beneficiary) override external view returns (uint256[] memory _vaultsOfBeneficiary) {
        _vaultsOfBeneficiary = new uint256[](vaultsOfBeneficiary[_beneficiary].length);
        _vaultsOfBeneficiary = vaultsOfBeneficiary[_beneficiary];
        return _vaultsOfBeneficiary;
    }

    function getSmartVaultBeneficiaryBalance(uint256 _vaultId, address _beneficiary) override external view returns (uint256, uint256) {
        return (vaultBeneficiaryBalance[_beneficiary][_vaultId], vaultBeneficiaryRewards[_beneficiary][_vaultId]);
    }

    function getFungibleAssetsBalanceOfBenef(uint256 _vaultId, address _beneficiary, IERC20 _fungibleAsset) override external view returns (uint256 _balance) {
        return fungibleAssetsBalanceOfBenef[_beneficiary][_fungibleAsset][_vaultId];
    }

    function getSmartVaultBeneficiaryNonFungibleAsset(address _beneficiary, withdrawNonFungibleAsset memory _nonfungibleAsset) override external view returns (bool) { //calldata
        return nonfungibleAssetsOfBenef[_beneficiary][_nonfungibleAsset.nonfungibleAddress][_nonfungibleAsset.tokenid][_nonfungibleAsset.vaultid];
    }

    function getSmartVaultOwnerNonFungibleAsset(address _owner, IERC721 _nonfungibleAsset, uint256 _tokenid) override external view returns (bool) {
        return nonfungibleAssetsOfOwner[_owner][_nonfungibleAsset][_tokenid];
    }

    function getTLV() override external view returns (uint256 _TVL) {
        for (uint256 i=0;i<totalSupply();i++){
            if(smartVaults[i].balance > 0) {
                _TVL += smartVaults[i].balance;
            // SUM map of Beneficiary Balance
            } else {
                (address[] memory _beneficiaries, ) = getBeneficiaries(i);
                for (uint256 j=0;j<_beneficiaries.length;j++) {
                    _TVL += vaultBeneficiaryBalance[_beneficiaries[j]][i];
                }
            }
        }
        return _TVL;
    }

    // Preset for ERC721
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        // reset ERC20 e 721??
        resetVault(tokenId);
        smartVaults[tokenId].owner = to;
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Preset for ERC721
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    //NFT
    function mintSmartVault(address _to, uint256 _vaultId) private {
        CarapaceNFTLib.VaultNFTParams memory newVaultNFT = CarapaceNFTLib.VaultNFTParams(
            string(abi.encodePacked('Carapace #', uint256(_vaultId).toString())), 
            "Carapace protecting digital assets.",
            CarapaceNFTLib.randomNum(361, block.difficulty, _vaultId).toString(),
            // (360-CarapaceNFTLib.randomNum(361, block.difficulty, _vaultId)).toString(),
            CarapaceNFTLib.randomNum(361, gasleft(), _vaultId).toString(),
            CarapaceNFTLib.randomNum(361, block.timestamp, _vaultId).toString(),
            CarapaceNFTLib.randomNum(361, block.number, _vaultId).toString(),
            CarapaceNFTLib.randomNum(361, block.gaslimit, _vaultId).toString(),
            CarapaceNFTLib.randomNum(361, tx.gasprice, _vaultId).toString()
        );
        vaultNFTParams[_vaultId] = newVaultNFT;

        _safeMint(_to, _vaultId);
    }

    //NFT
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
      require(_exists(_tokenId),"NT");
      return CarapaceNFTLib.buildMetadata(_tokenId, vaultNFTParams[_tokenId]);
    }

    function setSmartVault(        
        IERC20[] memory _fungibleAssets,
        beneficiary[] memory _beneficiaries,
        nonfungibleAsset[] memory _nonfungibleAssets,
        address[] memory _trustees,
        uint256 _trusteeIncentive,
        uint256 _lockDays, 
        uint256 _amountDeposited,
        uint256 _vaultRewards,
        uint256 _protocolRewards,
        address _owner
        ) override external onlyAuthorized() returns (uint256 _vaultId) {

        _vaultId = totalSupply(); //Preset for ERC721 - If NFT Burnable must have an independent Counter

        smartVaults[_vaultId].owner = _owner;
        // smartVaults[_vaultId].requestExecTS = 0;
        smartVaults[_vaultId].lockDays = _lockDays;
        smartVaults[_vaultId].balance = _amountDeposited;
        smartVaults[_vaultId].rewards = _vaultRewards;
        protocolRewards += _protocolRewards;

        setVault(_vaultId,_owner, _fungibleAssets, _beneficiaries, _nonfungibleAssets, _trustees, _trusteeIncentive);
        smartVaults[_vaultId].vaultState = status.Created;
        // _setupRole(MINTER_ROLE, msg.sender); //Preset for ERC721
        mintSmartVault(_owner, _vaultId);  //NFT

        return (_vaultId);
    }

    function updateSmartVault(
        uint256 _vaultId,
        IERC20[] memory _fungibleAssets,
        beneficiary[] memory _beneficiaries,
        nonfungibleAsset[] memory _nonfungibleAssets,
        address[] memory _trustees,
        uint256 _trusteeIncentive,
        uint256 _lockDays,
        address _owner
    ) override external onlyAuthorized() {

        resetVault(_vaultId);
        smartVaults[_vaultId].lockDays = _lockDays;
        setVault(_vaultId,_owner, _fungibleAssets, _beneficiaries, _nonfungibleAssets, _trustees, _trusteeIncentive);
    }

    /**
     * @dev Delete Smart Vault, cleans all configuration of Vault ID and returns funds to Owner.
     * @param _vaultId ID of the Vault
     *
     * Requirements:
     *  - Only the owner can cancel a vault;
     *  - Vault state must be Created;
     */
    function deleteSmartVault(
        uint256 _vaultId
    ) external override onlyAuthorized() returns (uint256 _returnDeposit) {
        _returnDeposit = smartVaults[_vaultId].balance;

        smartVaults[_vaultId].balance = 0;
        smartVaults[_vaultId].rewards = 0;
        resetVault(_vaultId);
        smartVaults[_vaultId].vaultState = status.Canceled;
        return (_returnDeposit);
    }

    /**
     * @dev Check NFT Beneficiary, private function to check if NFT Beneficiary address has vaultId controled by vaultsOfBeneficiary
     * @param _vaultId ID of the Vault
     * @param _beneficiary address of Beneficiary to be checked
     */
    function vaultNFTBeneficiaryCheck(uint256 _vaultId, address _beneficiary) private {
        if(vaultsOfBeneficiary[_beneficiary].length == 0 || vaultsOfBeneficiary[_beneficiary][vaultBenefIsAtIndex[_beneficiary][_vaultId]] != _vaultId) {
                vaultBenefIsAtIndex[_beneficiary][_vaultId] = vaultsOfBeneficiary[_beneficiary].length;
                vaultsOfBeneficiary[_beneficiary].push(_vaultId);
        }
    }

    // /**
    //  * @dev Set Vault, private function to check if NFT Beneficiary address has vaultId controled by vaultsOfBeneficiary
    //  * @param _vaultId ID of the Vault
    //  * @param _fungibleAssets address of Beneficiary to be checked
    //  */
    // function setVault(uint256 _vaultId, address _owner, IERC20[] memory _fungibleAssets, beneficiary[] memory _beneficiaries, nonfungibleAsset[] memory _nonfungibleAssets, address[] memory _trustees, uint256 _trusteeIncentive) private {
    //     require(_trusteeIncentive <= 100, "TI");
    //     uint256 _numFungibleAssets = _fungibleAssets.length;
    //     for (uint256 i=0;i<_numFungibleAssets;i++){
    //         require(!fungibleAssetsOfOwner[_owner][_fungibleAssets[i]], "DUP20");
    //         fungibleAssetsOfOwner[_owner][_fungibleAssets[i]] = true;
    //     }
    //     smartVaults[_vaultId].fungibleAssets = _fungibleAssets;

    //     uint256 _totalPercentage;
    //     uint256 _numBeneficiaries = _beneficiaries.length;
    //     for (uint256 i=0;i<_numBeneficiaries;i++){
    //         smartVaults[_vaultId].beneficiaries[i] = _beneficiaries[i];
    //         // smartVaults[_vaultId].numBeneficiaries++;
    //         _totalPercentage += _beneficiaries[i].percentage;
    //         vaultBenefIsAtIndex[_beneficiaries[i].beneficiary][_vaultId] = vaultsOfBeneficiary[_beneficiaries[i].beneficiary].length;
    //         vaultsOfBeneficiary[_beneficiaries[i].beneficiary].push(_vaultId);
    //     }
    //     require(_totalPercentage == 100, "TP");
    //     smartVaults[_vaultId].numBeneficiaries = _numBeneficiaries;

    //     uint256 _numNonFungibleAssets = _nonfungibleAssets.length;
    //     for (uint256 i=0;i<_numNonFungibleAssets;i++){
    //         require(!nonfungibleAssetsOfOwner[_owner][_nonfungibleAssets[i].nonfungibleAddress][_nonfungibleAssets[i].tokenid], "DUP21");
    //         nonfungibleAssetsOfOwner[_owner][_nonfungibleAssets[i].nonfungibleAddress][_nonfungibleAssets[i].tokenid] = true;
    //         smartVaults[_vaultId].nonfungibleAssets[i] = _nonfungibleAssets[i];
    //         // smartVaults[_vaultId].numNonFungibleAssets++;
    //         // if NFT beneficiary is not a global vault beneficiary
    //         vaultNFTBeneficiaryCheck(_vaultId, _nonfungibleAssets[i].beneficiary);
    //     }
    //     smartVaults[_vaultId].numNonFungibleAssets = _numNonFungibleAssets;

    //     uint256 _numTrustees = _trustees.length;
    //     for (uint256 i=0;i<_numTrustees;i++){
    //         smartVaults[_vaultId].isTrustee[_trustees[i]] = true;
    //         vaultIsAtIndex[_trustees[i]][_vaultId] = vaultsOfTrustee[_trustees[i]].length;
    //         vaultsOfTrustee[_trustees[i]].push(_vaultId);
    //     }
    //     smartVaults[_vaultId].trustees = _trustees;
    //     smartVaults[_vaultId].trusteeIncentive = _trusteeIncentive;
    // }

    /**
     * @dev Set Vault, private function to check if NFT Beneficiary address has vaultId controled by vaultsOfBeneficiary
     * @param _vaultId ID of the Vault
     * @param _fungibleAssets address of Beneficiary to be checked
     */
    function setVault(uint256 _vaultId, address _owner, IERC20[] memory _fungibleAssets, beneficiary[] memory _beneficiaries, nonfungibleAsset[] memory _nonfungibleAssets, address[] memory _trustees, uint256 _trusteeIncentive) private {
        require(_trusteeIncentive <= 100, "TI");
        for (uint256 i=0;i<_fungibleAssets.length;i++){
            require(!fungibleAssetsOfOwner[_owner][_fungibleAssets[i]], "DUP20");
            fungibleAssetsOfOwner[_owner][_fungibleAssets[i]] = true;
        }
        smartVaults[_vaultId].fungibleAssets = _fungibleAssets;

        uint256 _totalPercentage;
        for (uint256 i=0;i<_beneficiaries.length;i++){
            smartVaults[_vaultId].beneficiaries[i] = _beneficiaries[i];
            // smartVaults[_vaultId].numBeneficiaries++;
            _totalPercentage += _beneficiaries[i].percentage;
            vaultBenefIsAtIndex[_beneficiaries[i].beneficiary][_vaultId] = vaultsOfBeneficiary[_beneficiaries[i].beneficiary].length;
            vaultsOfBeneficiary[_beneficiaries[i].beneficiary].push(_vaultId);
        }
        require(_totalPercentage == 100, "TP");
        smartVaults[_vaultId].numBeneficiaries = _beneficiaries.length;

        for (uint256 i=0;i<_nonfungibleAssets.length;i++) {
            require(!nonfungibleAssetsOfOwner[_owner][_nonfungibleAssets[i].nonfungibleAddress][_nonfungibleAssets[i].tokenid], "DUP21");
            nonfungibleAssetsOfOwner[_owner][_nonfungibleAssets[i].nonfungibleAddress][_nonfungibleAssets[i].tokenid] = true;
            smartVaults[_vaultId].nonfungibleAssets[i] = _nonfungibleAssets[i];
            // smartVaults[_vaultId].numNonFungibleAssets++;
            // if NFT beneficiary is not a global vault beneficiary
            vaultNFTBeneficiaryCheck(_vaultId, _nonfungibleAssets[i].beneficiary);
        }
        smartVaults[_vaultId].numNonFungibleAssets = _nonfungibleAssets.length;

        for (uint256 i=0;i<_trustees.length;i++){
            smartVaults[_vaultId].isTrustee[_trustees[i]] = true;
            vaultIsAtIndex[_trustees[i]][_vaultId] = vaultsOfTrustee[_trustees[i]].length;
            vaultsOfTrustee[_trustees[i]].push(_vaultId);
        }
        smartVaults[_vaultId].trustees = _trustees;
        smartVaults[_vaultId].trusteeIncentive = _trusteeIncentive;
    }

    /**
     * @dev Reset Vault, private function to clean all values associated to a Vault, keeping the original Owner, Deposit Balance and Rewards
     * @param _vaultId ID of the Vault
     */
    function resetVault(uint256 _vaultId) private {
        for (uint256 i=0;i<smartVaults[_vaultId].fungibleAssets.length;i++){
            fungibleAssetsOfOwner[smartVaults[_vaultId].owner][smartVaults[_vaultId].fungibleAssets[i]] = false;
        }
        smartVaults[_vaultId].fungibleAssets = new IERC20[](0);

        for (uint256 i=0;i<smartVaults[_vaultId].numBeneficiaries;i++){
            delete vaultsOfBeneficiary[smartVaults[_vaultId].beneficiaries[i].beneficiary][vaultBenefIsAtIndex[smartVaults[_vaultId].beneficiaries[i].beneficiary][_vaultId]];
            delete smartVaults[_vaultId].beneficiaries[i];
        }
        smartVaults[_vaultId].numBeneficiaries = 0;

        for (uint256 i=0;i<smartVaults[_vaultId].numNonFungibleAssets;i++) {
            nonfungibleAssetsOfOwner[smartVaults[_vaultId].owner][smartVaults[_vaultId].nonfungibleAssets[i].nonfungibleAddress][smartVaults[_vaultId].nonfungibleAssets[i].tokenid] = false;
            // if NFT beneficiary is not a global vault beneficiary
            if(vaultsOfBeneficiary[smartVaults[_vaultId].nonfungibleAssets[i].beneficiary][vaultBenefIsAtIndex[smartVaults[_vaultId].nonfungibleAssets[i].beneficiary][_vaultId]] == _vaultId) {
                delete vaultsOfBeneficiary[smartVaults[_vaultId].nonfungibleAssets[i].beneficiary][vaultBenefIsAtIndex[smartVaults[_vaultId].nonfungibleAssets[i].beneficiary][_vaultId]];
            }
            delete smartVaults[_vaultId].nonfungibleAssets[i];
        }
        smartVaults[_vaultId].numNonFungibleAssets = 0;

        for (uint256 i=0;i<smartVaults[_vaultId].trustees.length;i++){
            smartVaults[_vaultId].isTrustee[smartVaults[_vaultId].trustees[i]] = false;
            delete vaultsOfTrustee[smartVaults[_vaultId].trustees[i]][vaultIsAtIndex[smartVaults[_vaultId].trustees[i]][_vaultId]];
        }
        smartVaults[_vaultId].trustees = new address[](0);
        smartVaults[_vaultId].trusteeIncentive = 0;
        // reset lock days??
    }

    function addBalance(uint256 _vaultId, uint256 _amount, uint256 _vaultRewards, uint256 _protocolRewards) override external onlyAuthorized() {
        smartVaults[_vaultId].balance += _amount;
        smartVaults[_vaultId].rewards += _vaultRewards;
        protocolRewards += _protocolRewards;
        //emit vaultBalanceChanges(_vaultId, msg.sender, address(this), msg.value, vaultBalance[msg.sender][_vaultId]);
    }

    function subtractBalance(uint256 _vaultId, uint256 _amount, uint256 _vaultRewards, uint256 _protocolRewards) override external onlyAuthorized() {
        smartVaults[_vaultId].balance -= _amount;
        smartVaults[_vaultId].rewards -= _vaultRewards;
        protocolRewards -= _protocolRewards;
        //emit vaultBalanceChanges(_vaultId, msg.sender, address(this), msg.value, vaultBalance[msg.sender][_vaultId]);
    }

    function subtractOwnerRewards(uint256 _vaultId, uint256 _rewardsWithdrawn) override external onlyAuthorized() {
        smartVaults[_vaultId].rewards -= _rewardsWithdrawn;
    }

    function subtractProtocolRewards(uint256 _rewardsWithdrawn) override external onlyAuthorized() {
        protocolRewards -= _rewardsWithdrawn;
    }

    function setRequestExecution(uint256 _vaultId) override external onlyAuthorized() {
        smartVaults[_vaultId].vaultState = status.Paused;
        smartVaults[_vaultId].requestExecTS = block.timestamp;
    }

    function setActiveStatus(uint256 _vaultId) override external onlyAuthorized() {
        smartVaults[_vaultId].vaultState = status.Created;
        smartVaults[_vaultId].requestExecTS = 0;
    }

    /**
     * @dev Map Non-Fungible Assets to withdraw, private function that distributes each non-fungible asset to the specific
     * Beneficiary configured.
     * @param _vaultId ID of the Vault
     */
    function mapNonFungibleAssets(uint256 _vaultId) private {
        for (uint256 i=0;i<smartVaults[_vaultId].numNonFungibleAssets;i++) {
            if (smartVaults[_vaultId].nonfungibleAssets[i].nonfungibleAddress.getApproved(smartVaults[_vaultId].nonfungibleAssets[i].tokenid) == msg.sender ||
                smartVaults[_vaultId].nonfungibleAssets[i].nonfungibleAddress.isApprovedForAll(smartVaults[_vaultId].owner, msg.sender)) {
                    //Map non-fungible Assets to Withdraw
                    nonfungibleAssetsOfBenef[smartVaults[_vaultId].nonfungibleAssets[i].beneficiary][smartVaults[_vaultId].nonfungibleAssets[i].nonfungibleAddress][smartVaults[_vaultId].nonfungibleAssets[i].tokenid][_vaultId] = true;
            }
        }
    }

    /**
     * @dev Execute Smart Vault
     *  . transfers Fungible Assets to Escrow to be withdrawn by beneficiaries
     *  . map Non-Fugible assets to be withdrawn by beneficiaries
     *  . map vault's deposit Balance to be withdrawn by beneficiaries, and pays Trustee Fee and Protocol.
     * @param _vaultId ID of the Vault
     *
     * Requirements:
     *  - Vault state must be Paused; 
     *  - Only the Trustees can execute a vault after a locktime period;
     */
    function setExecuteSmartVault(uint256 _vaultId, uint256 _totalFees, uint256 _vaultRewards, uint256 _protocolRewards) external override onlyAuthorized() {
        // require(onlyAuthorized(), "NA");
        uint256 _totalBalanceToDistribute = smartVaults[_vaultId].balance-_totalFees;
        uint256 _totalRewardsToDistribute = smartVaults[_vaultId].rewards-_vaultRewards;

        mapNonFungibleAssets(_vaultId);

        // Balance to withdraw
        smartVaults[_vaultId].balance -= _totalFees;
        smartVaults[_vaultId].rewards -= _vaultRewards;
        protocolRewards -= _protocolRewards;
        
        if(smartVaults[_vaultId].balance > 0) {
            for (uint256 j=0;j<smartVaults[_vaultId].numBeneficiaries-1;j++){    
                uint256 _partialBalanceToDistribute = _totalBalanceToDistribute*smartVaults[_vaultId].beneficiaries[j].percentage/100;
                smartVaults[_vaultId].balance -= _partialBalanceToDistribute;
                vaultBeneficiaryBalance[smartVaults[_vaultId].beneficiaries[j].beneficiary][_vaultId] = _partialBalanceToDistribute; // if beneficiary duplicated must have SUM()

                uint256 _partialRewardsToDistribute = _totalRewardsToDistribute*smartVaults[_vaultId].beneficiaries[j].percentage/100;
                smartVaults[_vaultId].rewards -= _partialRewardsToDistribute;
                vaultBeneficiaryRewards[smartVaults[_vaultId].beneficiaries[j].beneficiary][_vaultId] = _partialRewardsToDistribute; // if beneficiary duplicated must have SUM()
                //emit vaultBalanceChange??
            }
            //no dust
            vaultBeneficiaryBalance[smartVaults[_vaultId].beneficiaries[smartVaults[_vaultId].numBeneficiaries-1].beneficiary][_vaultId] = smartVaults[_vaultId].balance;
            vaultBeneficiaryRewards[smartVaults[_vaultId].beneficiaries[smartVaults[_vaultId].numBeneficiaries-1].beneficiary][_vaultId] = smartVaults[_vaultId].rewards;
            //emit vaultBalanceChange??
        }
        smartVaults[_vaultId].balance = 0;
        smartVaults[_vaultId].rewards = 0;

        smartVaults[_vaultId].vaultState = status.Executed;
    }

    function setFungibleAssetsBalanceOfBenef(uint256 _vaultId, address _beneficiary, IERC20 _fungibleAsset, uint256 _balance) override external onlyAuthorized() {
        fungibleAssetsBalanceOfBenef[_beneficiary][_fungibleAsset][_vaultId] = _balance;
    }

    function resetSmartVaultBeneficiaryBalance(uint256 _vaultId, address _beneficiary) override external onlyAuthorized() {
        vaultBeneficiaryBalance[_beneficiary][_vaultId] = 0;
        vaultBeneficiaryRewards[_beneficiary][_vaultId] = 0;
    }

    function resetFungibleAssetsOfOwner(uint256 _vaultId, IERC20 _fungibleAsset) override external onlyAuthorized() {
        fungibleAssetsOfOwner[smartVaults[_vaultId].owner][_fungibleAsset] = false;
    }

    function resetNonFungibleAssetsOfOwner(withdrawNonFungibleAsset memory _nonfungibleAsset) override external onlyAuthorized() { //calldata
        nonfungibleAssetsOfOwner[smartVaults[_nonfungibleAsset.vaultid].owner][_nonfungibleAsset.nonfungibleAddress][_nonfungibleAsset.tokenid] = false;
    }

    function resetSmartVaultBeneficiaryNonFungibleAsset(address _beneficiary, withdrawNonFungibleAsset memory _nonfungibleAsset) override external onlyAuthorized() { //calldata
        nonfungibleAssetsOfBenef[_beneficiary][_nonfungibleAsset.nonfungibleAddress][_nonfungibleAsset.tokenid][_nonfungibleAsset.vaultid] = false;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import "../Libraries/CarapaceTypesLib.sol";
import "../Libraries/CarapaceNFTLib.sol";

interface ICarapaceStorage {

    // Getters
    function getSmartVaultOwner(uint256 _vaultId) external view returns (address);
    function getSmartVaultIsTrustee(uint256 _vaultId, address _trustee) external view returns (bool);
    function getSmartVaultTrusteeIncentive(uint256 _vaultId) external view returns (uint256);
    function getSmartVaultState(uint256 _vaultId) external view returns (status);
    function getSmartVaultInfo(uint256 _vaultId) external view returns (
        // address,
        IERC20[] memory,
        address[] memory,
        // uint256,
        // uint256,
        uint256,
        uint256);
    function getSmartVaultRwrdInfo(uint256 _vaultId) external view returns (
        uint256 _vaultBalance,
        uint256 _vaultRewards);
    function getProtocolRewards() external view returns (uint256 _protocolRewards);
    function getBeneficiaries(uint256 _vaultId) external view returns (address[] memory _beneficiaries, uint256[] memory _percentages);
    function getNonFungibleAssets(uint256 _vaultId) external view returns (IERC721[] memory _nonfungibleAddresses, uint256[] memory _tokenids, address[] memory _beneficiaries);
    function getVaultsOfOwner(address _owner) external view returns (uint256[] memory _vaultsOfOwner);
    function getVaultsOfTrustee(address _trustee) external view returns (uint256[] memory _vaultsOfTrustee);
    function getVaultsOfBeneficiary(address _beneficiary) external view returns (uint256[] memory _vaultsOfBeneficiary);
    function getSmartVaultBeneficiaryBalance(uint256 _vaultId, address _beneficiary) external view returns (uint256 _vaultBeneficiaryBalance, uint256 _vaultBeneficiaryRewards);
    function getFungibleAssetsBalanceOfBenef(uint256 _vaultId, address _beneficiary, IERC20 _fungibleAsset) external view returns (uint256 _balance);
    function getSmartVaultBeneficiaryNonFungibleAsset(address _beneficiary, withdrawNonFungibleAsset memory _nonfungibleAsset) external view returns (bool);
    function getSmartVaultOwnerNonFungibleAsset(address _owner, IERC721 _nonfungibleAsset, uint256 _tokenid) external view returns (bool);
    function getTLV() external view returns (uint256 _TVL);

    // Setters
    function setSmartVault(
        IERC20[] memory _fungibleAssets,
        beneficiary[] memory _beneficiaries,
        nonfungibleAsset[] memory _nonfungibleAssets,
        address[] memory _trustees,
        uint256 _trusteeIncentive,
        uint256 _lockDays, 
        uint256 _amountDeposited,
        uint256 _vaultRewards,
        uint256 _protocolRewards,
        address _owner
        ) external returns (uint256 _vaultId);
    function updateSmartVault(
        uint256 _vaultId,
        IERC20[] memory _fungibleAssets,
        beneficiary[] memory _beneficiaries,
        nonfungibleAsset[] memory _nonfungibleAssets,
        address[] memory _trustees,
        uint256 _trusteeIncentive,
        uint256 _lockDays,
        address _owner
        ) external;
    function deleteSmartVault(uint256 _vaultId) external returns (uint256 _returnDeposit);
    function addBalance(uint256 _vaultId, uint256 _amount, uint256 _vaultRewards, uint256 _protocolRewards) external;
    function subtractBalance(uint256 _vaultId, uint256 _amount, uint256 _vaultRewards, uint256 _protocolRewards) external;
    function subtractOwnerRewards(uint256 _vaultId, uint256 _rewardsWithdrawn) external;
    function subtractProtocolRewards(uint256 _rewardsWithdrawn) external;
    function setRequestExecution(uint256 _vaultId) external;
    function setActiveStatus(uint256 _vaultId) external;
    function setExecuteSmartVault(uint256 _vaultId, uint256 _totalFees, uint256 _vaultRewards, uint256 _protocolRewards) external;
    function setFungibleAssetsBalanceOfBenef(uint256 _vaultId, address _beneficiary, IERC20 _fungibleAsset, uint256 _balance) external;
    function resetSmartVaultBeneficiaryBalance(uint256 _vaultId, address _beneficiary) external;
    function resetSmartVaultBeneficiaryNonFungibleAsset(address _beneficiary, withdrawNonFungibleAsset memory _nonfungibleAsset) external;
    function resetFungibleAssetsOfOwner(uint256 _vaultId, IERC20 _fungibleAsset) external;
    function resetNonFungibleAssetsOfOwner(withdrawNonFungibleAsset memory _nonfungibleAsset) external;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: GPL-3.0-only

interface ICarapaceAccess {

    function setAccess(address _caller, address _called) external;
    function getAccess(address _called) external view returns (bool _permission);
    
    // for testing purposes
    function setFalse(address _caller, address _called) external;
    function getAccessTemp(address _caller, address _called) external view returns (bool);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: GPL-3.0-or-later

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
// import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol"; //Preset for ERC721
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; //Preset for ERC721

enum status{Created, Paused, Canceled, Executed}                     //cast to 0, 1, 2, 3

struct smartVaultDef {
    address owner;                                              
    IERC20[] fungibleAssets;                                            //contract address
    mapping (uint256 => beneficiary) beneficiaries;                     //map to beneficiary struct
    uint256 numBeneficiaries;
    mapping (uint256 => nonfungibleAsset) nonfungibleAssets;            //map to nonfungibleAsset struct
    uint256 numNonFungibleAssets;
    address[] trustees;
    mapping (address => bool) isTrustee;                                //whitelist Trustee
    uint256 trusteeIncentive;    
    status vaultState;
    uint256 requestExecTS;
    uint256 lockDays;
    uint256 balance;
    uint256 rewards;
}

struct beneficiary {
    address beneficiary;
    uint256 percentage;
}

struct nonfungibleAsset {
    IERC721 nonfungibleAddress;                                         //contract address
    uint256 tokenid;                                                    //External Non Fungible Asset
    address beneficiary;                                                //Specific beneficiary 1:1
}

struct withdrawFungibleAsset {
    uint256 vaultid;
    IERC20 fungibleAddress;
}

struct withdrawNonFungibleAsset {
    uint256 vaultid;
    IERC721 nonfungibleAddress;                                         //contract address
    uint256 tokenid;                                                    //External Non Fungible Asset
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

library CarapaceNFTLib {
  using Strings for uint256;
  
   struct VaultNFTParams { 
      string name;
      string description;
      string bgHue;
      string gradientHue;
      string hex1Hue;
      string hex2Hue;
      string linesHue;
      string textHue;
   }
    
  function randomNum(uint256 _mod, uint256 _seed, uint _salt) internal view returns(uint256) {
      uint256 num = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, _salt))) % _mod;
      return num;
  }
  
  function buildImage(uint256 _tokenId, VaultNFTParams memory _vaultNFTparams) private pure returns(string memory svg) {
    
      string memory svg1 = string(abi.encodePacked(
            '<svg width="792" height="792" viewBox="0 0 792 792" fill="none" xmlns="http://www.w3.org/2000/svg">',
            '<rect width="792" height="792" transform="matrix(1 0 0 -1 0 792)" fill="url(#paint_linear)"/>',
            '<line x1="504.558" y1="470" x2="393.66" y2="662.08" stroke="hsl(',_vaultNFTparams.linesHue,', 100%, 80%)" stroke-width="20"/>',
            '<line x1="294.266" y1="479.145" x2="405.164" y2="671.224" stroke="hsl(',_vaultNFTparams.linesHue,', 100%, 80%)" stroke-width="20"/>',
            '<line x1="190.184" y1="474.2" x2="601.815" y2="474.187" stroke="hsl(',_vaultNFTparams.linesHue,', 100%, 80%)" stroke-width="20"/>'
            ));
    
        string memory svg2 = string(abi.encodePacked(
            '<path d="M291.484 474.321L186.099 291.79L291.484 109.259H502.253L607.637 291.79L502.253 474.321H291.484Z" stroke="hsl(',_vaultNFTparams.hex1Hue,', 100%, 80%)" stroke-width="20"/>',
            '<path d="M291.484 666.242L186.099 483.711L291.484 301.179H502.253L607.637 483.711L502.253 666.242H291.484Z" stroke="hsl(',_vaultNFTparams.hex2Hue,', 100%, 80%)" stroke-width="20"/>',
            '<text text-anchor="middle" font-family="Courier New" font-size="30" x="50%" y="95%" fill="hsl(',_vaultNFTparams.textHue,', 100%, 80%)">CARAPACE #',_tokenId.toString(),'</text>',
            '<defs>',
            '<linearGradient id="paint_linear" x1="396" y1="0" x2="396" y2="792" gradientUnits="userSpaceOnUse">'
          ));

        string memory svg3 = string(abi.encodePacked(
            '<stop offset="0.0239899" stop-color="hsl(',_vaultNFTparams.bgHue,', 50%, 30%)"/>',
            '<stop offset="1" stop-color="hsl(',_vaultNFTparams.gradientHue,', 80%, 40%)" stop-opacity="0.81"/>',
            '</linearGradient>',
            '</defs>',
            '</svg>'
        ));

      svg = string(abi.encodePacked(svg1,svg2,svg3));
      
      return Base64.encode(bytes(svg));
  }
 
  function buildMetadata(uint256 _tokenId, VaultNFTParams memory _vaultNFTparams) internal pure returns(string memory) {
 
      return string(abi.encodePacked(
              'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                          '{"name":"', 
                          _vaultNFTparams.name,
                          '", "description":"', 
                          _vaultNFTparams.description,
                          '", "image": "', 
                          'data:image/svg+xml;base64,', 
                          buildImage(_tokenId, _vaultNFTparams),
                          '"}')))));
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}