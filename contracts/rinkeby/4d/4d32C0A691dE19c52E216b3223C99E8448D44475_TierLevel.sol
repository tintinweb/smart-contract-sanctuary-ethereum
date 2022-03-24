// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./interfaces/ITierLevel.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "contracts/admin/SuperAdminControl.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


contract TierLevel is ITierLevel, OwnableUpgradeable, SuperAdminControl {
    //list of new tier levels
    mapping(bytes32 => TierData) public tierLevels;
    //list of all added tier levels. Stores the key for mapping => tierLevels
    bytes32[] public allTierLevelKeys;

    mapping(uint256 => SingleSPTierData) public spTierLevels;
    uint256[] spTierLevelKeys;

    mapping(address => NFTTierData) public nftTierLevels;
    address[] nftTierLevelsKeys;

    mapping(address => bytes32) public tierLevelbyAddress;

    address public govAdminRegistry;
    address public govToken;
    address public govGovToken;

    event TierLevelAdded(bytes32 _newTierLevel, TierData _tierData);
    event TierLevelUpdated(bytes32 _updatetierLevel, TierData _tierData);
    event TierLevelRemoved(bytes32 _removedtierLevel);

    function initialize(
        address _govAdminRegistry,
        address _govTokenAddress,
        bytes32 _bronze,
        bytes32 _silver,
        bytes32 _gold,
        bytes32 _platinum,
        bytes32 _allStar
    ) external initializer {
        __Ownable_init();
        govAdminRegistry = _govAdminRegistry;
        govToken = _govTokenAddress;

        _addTierLevel(
            _bronze,
            TierData(15000e18, 30, false, false, true, false, true, false)
        );
        _addTierLevel(
            _silver,
            TierData(30000e18, 40, false, false, true, true, true, false)
        );
        _addTierLevel(
            _gold,
            TierData(75000e18, 50, true, true, true, true, true, true)
        );
        _addTierLevel(
            _platinum,
            TierData(150000e18, 70, true, true, true, true, true, true)
        );
        _addTierLevel(
            _allStar,
            TierData(300000e18, 70, true, true, true, true, true, true)
        );
    }

    modifier onlyEditTierLevelRole(address admin) {
        require(
            IAdminRegistry(govAdminRegistry).isEditAdminAccessGranted(admin),
            "GTL: No admin right to add or remove tier level."
        );
        _;
    }

    function isEditTierLevel(address admin) external view returns (bool) {
        return IAdminRegistry(govAdminRegistry).isEditAdminAccessGranted(admin);
    }


    //external functions

    /**
    @dev external function to add new tier level (keys with their access values)
    @param _newTierLevel must be a new tier key in bytes32
    @param _tierData access variables of the each Tier Level
     */
    function addTierLevel(bytes32 _newTierLevel, TierData memory _tierData)
        external
        onlyEditTierLevelRole(msg.sender)
    {
        //admin have not already added new tier level
        require(
            !_isAlreadyTierLevel(_newTierLevel),
            "GTL: already added tier level"
        );
        require(
            _tierData.govHoldings < IERC20(govToken).totalSupply(),
            "GTL: set govHolding error"
        );
        require(
            _tierData.govHoldings >
                tierLevels[allTierLevelKeys[maxGovTierLevelIndex()]]
                    .govHoldings,
            "GovHolding Should be greater then last tier level Gov Holdings"
        );
        //adding tier level called by the admin
        _addTierLevel(_newTierLevel, _tierData);
    }

    /**
    @dev this function add new tier level if not exist and update tier level if already exist.
     */
    function saveTierLevel(
        bytes32[] memory _tierLevelKeys,
        TierData[] memory _newTierData
    ) external onlyEditTierLevelRole(msg.sender) {
        require(
            _tierLevelKeys.length == _newTierData.length,
            "New Tier Keys and TierData length must be equal"
        );
        _saveTierLevel(_tierLevelKeys, _newTierData);
    }

    /**
    @dev add NFT based Traditional or Single Token type tier levels
     */
    function addSingleSpTierLevel(SingleSPTierData memory _spTierLevel)
        external
        onlyEditTierLevelRole(msg.sender)
    {
        require(_spTierLevel.ltv > 0, "Invalid LTV");
        spTierLevels[spTierLevelKeys.length] = _spTierLevel;
        spTierLevelKeys.push(spTierLevelKeys.length);
    }

    // function to assign tierlevel to the NFT contract only by super admin
    function addNftTierLevel(
        address _nftContract,
        NFTTierData memory _tierLevel
    ) external onlySuperAdmin(govAdminRegistry, msg.sender) {
        if (_tierLevel.isTraditional) {
            require(
                _isAlreadyTierLevel(_tierLevel.traditionalTier),
                "GTL:Traditional Tier Null"
            );
        } else {
            require(
                spTierLevels[_tierLevel.nftTier].ltv > 0,
                "GTL: SP Tier Null"
            );
        }

        nftTierLevels[_nftContract] = _tierLevel;
        nftTierLevelsKeys.push(_nftContract);
    }

    function getSingleSpTierLength() external view returns (uint256) {
        return spTierLevelKeys.length;
    }

    function getNFTTierLength() external view returns (uint256) {
        return nftTierLevelsKeys.length;
    }

    /**
    @dev external function to update the existing tier level, also check if it is already added or not
    @param _updatedTierLevelKey existing tierlevel key
    @param _newTierData new data for the updateding Tier level
     */
    function updateTierLevel(
        bytes32 _updatedTierLevelKey,
        TierData memory _newTierData
    ) external onlyEditTierLevelRole(msg.sender) {
        require(
            _newTierData.govHoldings < IERC20(govToken).totalSupply(),
            "GTL: set govHolding error"
        );
        require(
            _isAlreadyTierLevel(_updatedTierLevelKey),
            "Tier: cannot update Tier, create new tier first"
        );
        _updateTierLevel(_updatedTierLevelKey, _newTierData);
    }

    function updateSingleSpTierLevel(
        uint256 _index,
        uint256 _ltv,
        bool _singleNft
    ) external onlyEditTierLevelRole(msg.sender) {
        require(_ltv > 0, "Invalid LTV");
        require(spTierLevels[_index].ltv > 0, "Tier not exist");
        spTierLevels[_index].ltv = _ltv;
        spTierLevels[_index].singleNft = _singleNft;
    }

    /**
    @dev remove tier level key as well as from mapping
    @param _existingTierLevel tierlevel hash in bytes32
     */
    function removeTierLevel(bytes32 _existingTierLevel)
        external
        onlyEditTierLevelRole(msg.sender)
    {
        require(
            _isAlreadyTierLevel(_existingTierLevel),
            "Tier: cannot remove, Tier Level not exist"
        );
        delete tierLevels[_existingTierLevel];
        emit TierLevelRemoved(_existingTierLevel);

        _removeTierLevelKey(_getIndex(_existingTierLevel));
    }

    /**
    @dev add NFT based Traditional or Single Token type tier levels
     */
    function removeSingleSpTierLevel(uint256 index)
        external
        onlyEditTierLevelRole(msg.sender)
    {
        require(index > 0, "Invalid index");
        require(spTierLevels[index].ltv > 0, "Invalid index");
        delete spTierLevels[index];
        _removeSingleSpTierLevelKey(_getIndexSpTier(index));
    }

    /**
    @dev add NFT based Traditional or Single Token type tier levels
     */
    function removeNftTierLevel(address _contract)
        external
        onlyEditTierLevelRole(msg.sender)
    {
        require(_contract != address(0), "Invalid address");
        require(
            nftTierLevels[_contract].nftContract != address(0),
            "Invalid index"
        );
        delete nftTierLevels[_contract];
        _removeNftTierLevelKey(_getIndexNftTier(_contract));
    }

    //public functions

    /**
     * @dev get all the Tier Level Keys from the allTierLevelKeys array
     */
    function getAllTierLevels() public view returns (bytes32[] memory) {
        return allTierLevelKeys;
    }

    /**
     * @dev get Single Tier Level Data
     */
    function getSingleTierData(bytes32 _tierLevelKey)
        public
        view
        returns (TierData memory)
    {
        return tierLevels[_tierLevelKey];
    }

    //internal functions

    /**
     * @dev makes _new a pendsing adnmin for approval to be given by all current admins
     * @param _newTierLevel value type of the New Tier Level in bytes
     * @param _tierData access variables for _newadmin
     */

    function _addTierLevel(bytes32 _newTierLevel, TierData memory _tierData)
        internal
    {
        //new Tier is added to the mapping tierLevels
        tierLevels[_newTierLevel] = _tierData;

        //new Tier Key for mapping tierLevel
        allTierLevelKeys.push(_newTierLevel);
        emit TierLevelAdded(_newTierLevel, _tierData);
    }

    /**
     * @dev Checks if a given _newTierLevel is already added by the admin.
     * @param _tierLevel value of the new tier
     */
    function _isAlreadyTierLevel(bytes32 _tierLevel)
        internal
        view
        returns (bool)
    {
        uint256 length = allTierLevelKeys.length;
        for (uint256 i = 0; i < length; i++) {
            if (allTierLevelKeys[i] == _tierLevel) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev update already created tier level
     * @param _updatedTierLevelKey key value type of the already created Tier Level in bytes
     * @param _newTierData access variables for updating the Tier Level
     */

    function _updateTierLevel(
        bytes32 _updatedTierLevelKey,
        TierData memory _newTierData
    ) internal {
        //update Tier Level to the updatedTier
        uint256 currentIndex = _getIndex(_updatedTierLevelKey);
        uint256 lowerLimit = 0;
        uint256 upperLimit = _newTierData.govHoldings + 10;
        if (currentIndex > 0) {
            lowerLimit = tierLevels[allTierLevelKeys[currentIndex - 1]]
                .govHoldings;
        }
        if (currentIndex < allTierLevelKeys.length - 1)
            upperLimit = tierLevels[allTierLevelKeys[currentIndex + 1]]
                .govHoldings;

        require(
            _newTierData.govHoldings < upperLimit &&
                _newTierData.govHoldings > lowerLimit,
            "GTL: Holdings Range Error"
        );

        tierLevels[_updatedTierLevelKey] = _newTierData;
        emit TierLevelUpdated(_updatedTierLevelKey, _newTierData);
    }

    /**
     * @dev remove tier level
     * @param index already existing tierlevel index
     */
    function _removeTierLevelKey(uint256 index) internal {
        if (allTierLevelKeys.length != 1) {
            for (uint256 i = index; i < allTierLevelKeys.length - 1; i++) {
                allTierLevelKeys[i] = allTierLevelKeys[i + 1];
            }
        }
        allTierLevelKeys.pop();
    }

    /**
     * @dev remove single sp tieer level key
     * @param index already existing tierlevel index
     */
    function _removeSingleSpTierLevelKey(uint256 index) internal {
        if (spTierLevelKeys.length != 1) {
            for (uint256 i = index; i < spTierLevelKeys.length - 1; i++) {
                spTierLevelKeys[i] = spTierLevelKeys[i + 1];
            }
        }
        spTierLevelKeys.pop();
    }

    function _removeNftTierLevelKey(uint256 index) internal {
        if (nftTierLevelsKeys.length != 1) {
            for (uint256 i = index; i < nftTierLevelsKeys.length - 1; i++) {
                nftTierLevelsKeys[i] = nftTierLevelsKeys[i + 1];
            }
        }
        nftTierLevelsKeys.pop();
    }

    /**
    @dev internal function for the save tier level, which will update and add tier level at a time
     */
    function _saveTierLevel(
        bytes32[] memory _tierLevelKeys,
        TierData[] memory _newTierData
    ) internal {
        for (uint256 i = 0; i < _tierLevelKeys.length; i++) {
            require(
                _newTierData[i].govHoldings < IERC20(govToken).totalSupply(),
                "GTL: set govHolding error"
            );
            if (!_isAlreadyTierLevel(_tierLevelKeys[i])) {
                _addTierLevel(_tierLevelKeys[i], _newTierData[i]);
            } else if (_isAlreadyTierLevel(_tierLevelKeys[i])) {
                _updateTierLevel(_tierLevelKeys[i], _newTierData[i]);
            }
        }
    }

    /**
    @dev this function returns the index of the maximum govholding tier level
     */
    function maxGovTierLevelIndex() public view returns (uint256) {
        uint256 max = tierLevels[allTierLevelKeys[0]].govHoldings;
        uint256 maxIndex = 0;

        uint256 length = allTierLevelKeys.length;
        for (uint256 i = 0; i < length; i++) {
            if (tierLevels[allTierLevelKeys[i]].govHoldings > max) {
                maxIndex = i;
                max = tierLevels[allTierLevelKeys[i]].govHoldings;
            }
        }

        return maxIndex;
    }

    /**
    @dev get index of the tierLevel from the allTierLevel array
    @param _tierLevel hash of the tier level
     */
    function _getIndex(bytes32 _tierLevel)
        internal
        view
        returns (uint256 index)
    {
        uint256 length = allTierLevelKeys.length;
        for (uint256 i = 0; i < length; i++) {
            if (allTierLevelKeys[i] == _tierLevel) {
                return i;
            }
        }
    }

    /**
    @dev get index of the singleSpTierLevel from the allTierLevel array
    @param _tier hash of the tier level
    */
    function _getIndexSpTier(uint256 _tier)
        internal
        view
        returns (uint256 index)
    {
        uint256 length = spTierLevelKeys.length;

        for (uint256 i = 0; i < length; i++) {
            if (spTierLevelKeys[i] == _tier) {
                return i;
            }
        }
    }

    /**
    @dev get index of the nftTierLevel from the allTierLevel array
    @param _tier hash of the tier level
    */
    function _getIndexNftTier(address _tier)
        internal
        view
        returns (uint256 index)
    {
        uint256 length = nftTierLevelsKeys.length;

        for (uint256 i = 0; i < length; i++) {
            if (nftTierLevelsKeys[i] == _tier) {
                return i;
            }
        }
    }

    /**
    @dev this function returns the tierLevel data by user's Gov Token Balance
    @param userWalletAddress user address for check tier level data
     */
    function getTierDatabyGovBalance(address userWalletAddress)
        public
        view
        override
        returns (TierData memory _tierData)
    {
        require(govToken != address(0x0), "GTL: Gov Token not Configured");
        require(
            govGovToken != address(0x0),
            "GTL: govGov GToken not Configured"
        );
        uint256 userGovBalance = IERC20(govToken).balanceOf(userWalletAddress) +
            IERC20(govGovToken).balanceOf(userWalletAddress);

        if (userGovBalance >= tierLevels[allTierLevelKeys[0]].govHoldings) {
            uint256 lengthTierLevels = allTierLevelKeys.length;
            for (uint256 i = 1; i < lengthTierLevels; i++) {
                if (
                    (userGovBalance >=
                        tierLevels[allTierLevelKeys[i - 1]].govHoldings) &&
                    (userGovBalance <
                        tierLevels[allTierLevelKeys[i]].govHoldings)
                ) {
                    return tierLevels[allTierLevelKeys[i - 1]];
                } else if (
                    userGovBalance >=
                    tierLevels[allTierLevelKeys[lengthTierLevels - 1]]
                        .govHoldings
                ) {
                    return tierLevels[allTierLevelKeys[lengthTierLevels - 1]];
                }
            }
        } else {
            for (uint256 i = 0; i < allTierLevelKeys.length; i++) {
                if (
                    allTierLevelKeys[i] == tierLevelbyAddress[userWalletAddress]
                ) {
                    return tierLevels[allTierLevelKeys[i]];
                }
            }
        }
    }

    function stringToBytes32(string memory _string)
        public
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(_string);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(_string, 32))
        }
    }

    // set govGovToken address, only superadmin
    function configuregovGovToken(address _govGovTokenAddress)
        external
        onlySuperAdmin(govAdminRegistry, msg.sender)
    {
        require(
            _govGovTokenAddress != address(0),
            "GTL: Invalid Contract Address!"
        );
        require(govGovToken == address(0), "GTL: Contract Already Configured!");
        govGovToken = _govGovTokenAddress;
    }

    // function to assign tier level to the address only by the super admin
    function addEditWalletTierLevel(address _userAddress, bytes32 _tierLevel)
        external
        onlySuperAdmin(govAdminRegistry, msg.sender)
    {
        require(
            tierLevelbyAddress[_userAddress] == 0,
            "GTL: user already assigned tierLevel"
        );
        tierLevelbyAddress[_userAddress] = _tierLevel;
    }

    //Returns max loan amount a borrower can borrow
    function getMaxLoanAmount(
        uint256 _collateralTokeninStable,
        uint256 _tierLevelLTVPercentage
    ) external pure returns (uint256) {
        uint256 maxLoanAmountAllowed = (_collateralTokeninStable *
            _tierLevelLTVPercentage) / 100;
        return maxLoanAmountAllowed;
    }

    function getMaxLoanAmountToValue(
        uint256 _collateralTokeninStable,
        address _borrower
    ) external view override returns (uint256) {
        TierData memory tierData = this.getTierDatabyGovBalance(_borrower);
        NFTTierData memory nftTier = this.getUserNftTier(_borrower);
        SingleSPTierData memory nftSpTier = spTierLevels[nftTier.nftTier];

        if (tierData.govHoldings > 0) {
            return (_collateralTokeninStable * tierData.loantoValue) / 100;
        } else if (nftTier.isTraditional) {
            TierData memory traditionalTierData = tierLevels[
                nftTier.traditionalTier
            ];
            return
                (_collateralTokeninStable * traditionalTierData.loantoValue) /
                100;
        } else if (nftSpTier.ltv > 0) {
            return (_collateralTokeninStable * nftSpTier.ltv) / 100;
        } else {
            return 0;
        }
    }

    function getUserNftTier(address _wallet)
        external
        view
        returns (NFTTierData memory nftTierData)
    {
        uint256 maxLTVFromNFTTier;
        address maxNFTTierAddress;

        uint256 nftTiersLength = nftTierLevelsKeys.length;
        require(nftTiersLength > 0, "GTL: no nft tier yet");
        if (nftTierLevels[nftTierLevelsKeys[0]].isTraditional) {
            maxLTVFromNFTTier = tierLevels[
                nftTierLevels[nftTierLevelsKeys[0]].traditionalTier
            ].loantoValue;
            maxNFTTierAddress = nftTierLevelsKeys[0];
        } else {
            maxLTVFromNFTTier = spTierLevels[
                nftTierLevels[nftTierLevelsKeys[0]].nftTier
            ].ltv;
            maxNFTTierAddress = nftTierLevelsKeys[0];
        }

        for (uint256 i = 1; i < nftTiersLength; i++) {
            //user owns nft balannce
            uint256 currentLoanToValue;

            if (nftTierLevels[nftTierLevelsKeys[i]].isTraditional) {
                currentLoanToValue = tierLevels[
                    nftTierLevels[nftTierLevelsKeys[i]].traditionalTier
                ].loantoValue;
            } else {
                currentLoanToValue = spTierLevels[
                    nftTierLevels[nftTierLevelsKeys[i]].nftTier
                ].ltv;
            }

            if (currentLoanToValue >= maxLTVFromNFTTier) {
                maxNFTTierAddress = nftTierLevelsKeys[i];
                maxLTVFromNFTTier = currentLoanToValue;
            }
        }

        if (IERC721(maxNFTTierAddress).balanceOf(_wallet) > 0) {
            return nftTierLevels[maxNFTTierAddress];
        } else {
            return nftTierLevels[address(0x0)];
        }
    }

    /**
     * @dev Rules 1. User have gov balance tier, and they will
     * crerae single and multi token and nft loan according to tier level flags.
     * Rule 2. User have NFT tier level and it is traditional tier applies same rule as gov holding tier.
     * Rule 3. User have NFT tier level and it is SP Single Token, only SP token collateral allowed only single token loan allowed.
     * Rule 4. User have both NFT tier level and gov holding tier level. Invalid Tier.
     * Returns 200 if success all otther are differentt error codes
     */
    function isCreateLoanTokenUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralTokens
    ) external view override returns (uint256) {
        //purpose of function is to return false in case any tier level related validation fails
        //Identify what tier it is.
        TierData memory tierData = this.getTierDatabyGovBalance(_wallet);
        NFTTierData memory nftTier = this.getUserNftTier(_wallet);
        if (tierData.govHoldings > 0 && nftTier.nftContract != address(0)) {
            //Rule 4: having both tiers is a sin
            return 1;
        }
        if (tierData.govHoldings > 0) {
            //user has gov tier level
            //start validatting loan offer
            if (tierData.singleToken || tierData.multiToken) {
                if (!tierData.multiToken) {
                    if (_stakedCollateralTokens.length > 1) {
                        return 2; //multi-token loan not allowed in tier.
                    }
                }
            }
            if (
                _loanAmount >
                this.getMaxLoanAmount(_collateralinStable, tierData.loantoValue)
            ) {
                //allowed ltv
                return 3;
            }
        } else {
            //determine if user nft tier is available
            // need to determinne is user one
            //of the nft holder in NFTTierData mapping
            if (nftTier.isTraditional) {
                TierData memory traditionalTierData = tierLevels[
                    nftTier.traditionalTier
                ];
                //start validatting loan offer
                if (
                    traditionalTierData.singleToken ||
                    traditionalTierData.multiToken
                ) {
                    if (!traditionalTierData.multiToken) {
                        if (_stakedCollateralTokens.length > 1) {
                            return 2; //multi-token loan not allowed in tier.
                        }
                    }
                }
                if (
                    _loanAmount >
                    this.getMaxLoanAmount(
                        _collateralinStable,
                        traditionalTierData.loantoValue
                    )
                ) {
                    //allowed ltv
                    return 3;
                }
            } else {
                SingleSPTierData memory nftSpTier = spTierLevels[
                    nftTier.nftTier
                ];
                //staked token are more then one and multi token not allowed
                if (
                    _stakedCollateralTokens.length > 1 && !nftSpTier.multiToken
                ) {
                    //only single token allowed for sp tier
                    return 5;
                }
                uint256 maxLoanAmount = (_collateralinStable * nftSpTier.ltv) /
                    100;
                if (_loanAmount > maxLoanAmount) {
                    //loan to value is under tier
                    return 6;
                }
                for (uint256 c = 0; c < _stakedCollateralTokens.length; c++) {
                    bool found = false;
                    for (uint256 x = 0; x < nftTier.allowedSuns.length; x++) {
                        if (
                            //collateral can be either approved sun token or associated sp token
                            _stakedCollateralTokens[c] ==
                            nftTier.allowedSuns[x] ||
                            _stakedCollateralTokens[c] == nftTier.spToken
                        ) {
                            //collateral can not be other then sp token or approved sun tokens
                            found = true;
                        }
                    }
                    if (!found) {
                        //can not be other then approved sun Tokens or approved SP token
                        return 7;
                    }
                }
            }
        }
        return 200;
    }

    /**
     * @dev Rules 1. User have gov balance tier, and they will
     * crerae single and multi token and nft loan according to tier level flags.
     * Rule 2. User have NFT tier level and it is traditional tier applies same rule as gov holding tier.
     * Rule 3. User have NFT tier level and it is SP Single Token, only SP token collateral allowed only single token loan allowed.
     * Rule 4. User have both NFT tier level and gov holding tier level. Invalid Tier.
     * Returns 200 if success all otther are differentt error codes
     */
    function isCreateLoanNftUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralNFTs
    ) external view override returns (uint256) {
        //purpose of function is to return false in case any tier level related validation fails
        //Identify what tier it is.
        TierData memory tierData = this.getTierDatabyGovBalance(_wallet);
        NFTTierData memory nftTier = this.getUserNftTier(_wallet);
        if (tierData.govHoldings > 0 && nftTier.nftContract != address(0)) {
            //Rule 4: having both tiers is a sin
            return 1;
        }
        if (tierData.govHoldings > 0) {
            //user has gov tier level
            //start validatting loan offer
            if (tierData.singleToken || tierData.multiToken) {
                if (!tierData.multiToken) {
                    if (_stakedCollateralNFTs.length > 1) {
                        return 2; //multi-token loan not allowed in tier.
                    }
                }
            }
            if (
                _loanAmount >
                this.getMaxLoanAmount(_collateralinStable, tierData.loantoValue)
            ) {
                //allowed ltv
                return 3;
            }
        } else {
            //determine if user nft tier is available
            // need to determinne is user one
            //of the nft holder in NFTTierData mapping
            if (nftTier.isTraditional) {
                TierData memory traditionalTierData = tierLevels[
                    nftTier.traditionalTier
                ];
                //start validatting loan offer
                if (
                    traditionalTierData.singleToken ||
                    traditionalTierData.multiToken
                ) {
                    if (!traditionalTierData.multiToken) {
                        if (_stakedCollateralNFTs.length > 1) {
                            return 2; //multi-token loan not allowed in tier.
                        }
                    }
                }
                if (
                    _loanAmount >
                    this.getMaxLoanAmount(
                        _collateralinStable,
                        traditionalTierData.loantoValue
                    )
                ) {
                    //allowed ltv
                    return 3;
                }
            } else {
                SingleSPTierData memory nftSpTier = spTierLevels[
                    nftTier.nftTier
                ];

                if (_stakedCollateralNFTs.length > 1 && !nftSpTier.multiNFT) {
                    //only single token allowed for sp tier
                    return 5;
                }
                uint256 maxLoanAmount = (_collateralinStable * nftSpTier.ltv) /
                    100;
                if (_loanAmount > maxLoanAmount) {
                    //loan to value is under tier
                    return 6;
                }

                for (uint256 c = 0; c < _stakedCollateralNFTs.length; c++) {
                    bool found = false;

                    for (uint256 x = 0; x < nftTier.allowedNfts.length; x++) {
                        if (
                            _stakedCollateralNFTs[c] == nftTier.allowedNfts[x]
                        ) {
                            //collateral can not be other then sp token
                            found = true;
                        }
                    }

                    if (!found) {
                        //can not be other then approved sp nfts or approved sun tokens
                        return 7;
                    }
                }
            }
        }
        return 200;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

struct TierData {
    // Gov  Holdings to check if it lies in that tier
    uint256 govHoldings;
    // LTV percentage of the Gov Holdings
    uint8 loantoValue;
    //checks that if tier level have access
    bool govIntel;
    bool singleToken;
    bool multiToken;
    bool singleNFT;
    bool multiNFT;
    bool reverseLoan;
}
struct SingleSPTierData {
    uint256 ltv;
    bool singleToken;
    bool multiToken;
    bool singleNft;
    bool multiNFT;
}

struct NFTTierData {
    address nftContract;
    bool isTraditional;
    address spToken;
    bytes32 traditionalTier;
    uint256 nftTier;
    address[] allowedNfts;
    address[] allowedSuns;
}

interface ITierLevel {
    function getTierDatabyGovBalance(address userWalletAddress)
        external
        view
        returns (TierData memory _tierData);

    function getMaxLoanAmountToValue(
        uint256 _collateralTokeninStable,
        address _borrower
    ) external view returns (uint256);

    function isCreateLoanTokenUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 collateralInBorrowed,
        address[] memory stakedCollateralTokens
    ) external view returns (uint256);

    function isCreateLoanNftUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 collateralInBorrowed,
        address[] memory stakedCollateralTokens
    ) external view returns (uint256);
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

pragma solidity ^0.8.3;

import "../admin/interfaces/IAdminRegistry.sol";

abstract contract SuperAdminControl {
  
    modifier onlySuperAdmin(address govAdminRegistry, address admin) {
        require(
            IAdminRegistry(govAdminRegistry).isSuperAdminAccess(admin),
            ": not super admin"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
pragma solidity ^0.8.3;

interface IAdminRegistry {
    struct AdminAccess {
        //access-modifier variables to add projects to gov-intel
        bool addGovIntel;
        bool editGovIntel;
        //access-modifier variables to add tokens to gov-world protocol
        bool addToken;
        bool editToken;
        //access-modifier variables to add strategic partners to gov-world protocol
        bool addSp;
        bool editSp;
        //access-modifier variables to add gov-world admins to gov-world protocol
        bool addGovAdmin;
        bool editGovAdmin;
        //access-modifier variables to add bridges to gov-world protocol
        bool addBridge;
        bool editBridge;
        //access-modifier variables to add pools to gov-world protocol
        bool addPool;
        bool editPool;
        //superAdmin role assigned only by the super admin
        bool superAdmin;
    }

    function isAddGovAdminRole(address admin) external view returns (bool);

    //using this function externally in Gov Tier Level Smart Contract
    function isEditAdminAccessGranted(address admin)
        external
        view
        returns (bool);

    //using this function externally in other Smart Contracts
    function isAddTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isAddSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditAPYPerAccess(address admin) external view returns (bool);

    //using this function in loan smart contracts to withdraw network balance
    function isSuperAdminAccess(address admin) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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