// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {LibProtocolStorage} from "./LibProtocolStorage.sol";
import {LibProtocolRegistry} from "./LibProtocolRegistry.sol";
import {Modifiers} from "./../../shared/libraries/LibAppStorage.sol";
import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import {LibMeta} from "./../../shared/libraries/LibMeta.sol";

contract ProtocolRegistryFacet is Modifiers {
    function protocolRegistryFacetInit() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(
            LibMeta.msgSender() == ds.contractOwner,
            "Must own the contract."
        );
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        es.govPlatformFee = 200; //2%
        es.govAutosellFee = 700; //7% in Calculate APY FEE Function
        es.govThresholdFee = 200; //2 %
    }

    /// @dev check function if Token Contract address is already added
    /// @param _tokenAddress token address
    /// @return bool true or false if token enable or disbale for collateral
    function isTokenEnabledForCreateLoan(address _tokenAddress)
        external
        view
        returns (bool)
    {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        return es.approvedTokens[_tokenAddress].isTokenEnabledAsCollateral;
    }

    /// @dev check function if Token Contract address is already added
    /// @param _tokenAddress token address
    /// @return bool true or false value for token address
    function isTokenApproved(address _tokenAddress)
        external
        view
        returns (bool)
    {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        uint256 length = es.allapprovedTokenContracts.length;
        for (uint256 i = 0; i < length; i++) {
            if (es.allapprovedTokenContracts[i] == _tokenAddress) {
                return true;
            }
        }
        return false;
    }

    /// @dev checking the approvedSps mapping if already walletAddress
    /// @param _tokenAddress contract address of the approvedToken Sp
    /// @param _walletAddress wallet address of the approved Sp
    /// @return bool true or false value for the sp wallet address

    function isAddedSPWallet(address _tokenAddress, address _walletAddress)
        external
        view
        returns (bool)
    {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        uint256 length = es.approvedSps[_tokenAddress].length;
        for (uint256 i = 0; i < length; i++) {
            address currentWallet = es.approvedSps[_tokenAddress][i];
            if (currentWallet == _walletAddress) {
                return true;
            }
        }
        return false;
    }

    /// @dev function to enable or disale stable coin in the gov protocol
    /// @param _stableAddress stable token contract address DAI, USDT, etc...
    /// @param _status bool value true or false to change status of stable coin
    function addEditStableCoin(
        address[] memory _stableAddress,
        bool[] memory _status
    ) external onlyEditTokenRole(LibMeta.msgSender()) {
        require(
            _stableAddress.length == _status.length,
            "GPR: length mismatch"
        );
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        for (uint256 i = 0; i < _stableAddress.length; i++) {
            require(_stableAddress[i] != address(0x0), "GPR: null address");
            require(
                es.approveStable[_stableAddress[i]] != _status[i],
                "GPR: already in desired state"
            );
            es.approveStable[_stableAddress[i]] = _status[i];

            emit LibProtocolRegistry.UpdatedStableCoinStatus(
                _stableAddress[i],
                _status[i]
            );
        }
    }

    /// @dev function to add token to approvedTokens mapping
    /// @param _tokenAddress of the new token Address
    /// @param marketData struct of the _tokenAddress

    function addTokens(
        address[] memory _tokenAddress,
        LibProtocolStorage.Market[] memory marketData
    ) external onlyAddTokenRole(LibMeta.msgSender()) {
        require(
            _tokenAddress.length == marketData.length,
            "GPR: Token Address Length must match Market Data"
        );
        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            require(_tokenAddress[i] != address(0x0), "GPR: null error");
            //checking Token Contract have not already added
            require(
                !this.isTokenApproved(_tokenAddress[i]),
                "GPR: already added Token Contract"
            );
            LibProtocolRegistry._addToken(_tokenAddress[i], marketData[i]);
        }
    }

    /// @dev function to update the token market data
    /// @param _tokenAddress to check if it exit in the array and mapping
    /// @param _marketData struct to update the token market
    function updateTokens(
        address[] memory _tokenAddress,
        LibProtocolStorage.Market[] memory _marketData
    ) external onlyEditTokenRole(LibMeta.msgSender()) {
        require(
            _tokenAddress.length == _marketData.length,
            "GPR: Token Address Length must match Market Data"
        );

        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            require(
                this.isTokenApproved(_tokenAddress[i]),
                "GPR: cannot update the token data, add new token address first"
            );

            LibProtocolRegistry._updateToken(_tokenAddress[i], _marketData[i]);
            emit LibProtocolRegistry.TokensUpdated(
                _tokenAddress[i],
                _marketData[i]
            );
        }
    }

    /// @dev function which change the approved token to enable or disable
    /// @param _tokenAddress address which is updating

    function changeTokensStatus(
        address[] memory _tokenAddress,
        bool[] memory _tokenStatus
    ) external onlyEditTokenRole(LibMeta.msgSender()) {
        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            require(
                this.isTokenEnabledForCreateLoan(_tokenAddress[i]) !=
                    _tokenStatus[i],
                "GPR: already in desired status"
            );
            LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
                .protocolRegistryStorage();

            es
                .approvedTokens[_tokenAddress[i]]
                .isTokenEnabledAsCollateral = _tokenStatus[i];

            emit LibProtocolRegistry.TokenStatusUpdated(
                _tokenAddress[i],
                _tokenStatus[i]
            );
        }
    }

    /// @dev add sp wallet to the mapping approvedSps
    /// @param _tokenAddress token contract address
    /// @param _walletAddress sp wallet address to add

    function addSp(address _tokenAddress, address _walletAddress)
        external
        onlyAddSpRole(LibMeta.msgSender())
    {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        require(
            es.approvedTokens[_tokenAddress].tokenType ==
                LibProtocolStorage.TokenType.ISVIP,
            "GPR: not sp"
        );
        require(
            !LibProtocolRegistry._isAlreadyAddedSp(_walletAddress),
            "GPR: SP Already Approved"
        );
        LibProtocolRegistry._addSp(_tokenAddress, _walletAddress);
    }

    /// @dev remove sp wallet from mapping
    /// @param _tokenAddress token address as a key to remove sp
    /// @param _removeWalletAddress sp wallet address to be removed
    function removeSp(address _tokenAddress, address _removeWalletAddress)
        external
        onlyEditSpRole(LibMeta.msgSender())
    {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        require(
            es.approvedTokens[_tokenAddress].tokenType ==
                LibProtocolStorage.TokenType.ISVIP,
            "GPR: not sp"
        );
        require(
            LibProtocolRegistry._isAlreadyAddedSp(_removeWalletAddress),
            "GPR: cannot remove the SP, does not exist"
        );

        uint256 length = es.approvedSps[_tokenAddress].length;
        for (uint256 i = 0; i < length; i++) {
            if (es.approvedSps[_tokenAddress][i] == _removeWalletAddress) {
                LibProtocolRegistry._removeSpKey(
                    LibProtocolRegistry._getIndexofAddressfromArray(
                        _removeWalletAddress
                    )
                );
                LibProtocolRegistry._removeSpKeyfromMapping(
                    LibProtocolRegistry._getIndexofAddressfromArray(
                        es.approvedSps[_tokenAddress][i]
                    ),
                    _tokenAddress
                );
                break;
            }
        }

        emit LibProtocolRegistry.SPWalletRemoved(
            _tokenAddress,
            _removeWalletAddress
        );
    }

    /// @dev adding bulk sp wallet address to the approvedSps
    /// @param _tokenAddress token contract address as a key for sp wallets
    /// @param _walletAddress sp wallet addresses adding to the approvedSps mapping

    function addBulkSps(address _tokenAddress, address[] memory _walletAddress)
        external
        onlyAddSpRole(LibMeta.msgSender())
    {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        require(
            es.approvedTokens[_tokenAddress].tokenType ==
                LibProtocolStorage.TokenType.ISVIP,
            "GPR: not sp"
        );

        LibProtocolRegistry._addBulkSps(_tokenAddress, _walletAddress);
    }

    /// @dev function to update the sp wallet
    /// @param _tokenAddress to check if it exit in the array and mapping
    /// @param _oldWalletAddress old wallet address to be updated
    /// @param _newWalletAddress new wallet address

    function updateSp(
        address _tokenAddress,
        address _oldWalletAddress,
        address _newWalletAddress
    ) external onlyEditSpRole(LibMeta.msgSender()) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        require(
            es.approvedTokens[_tokenAddress].tokenType ==
                LibProtocolStorage.TokenType.ISVIP,
            "GPR: not sp"
        );
        require(
            _newWalletAddress != _oldWalletAddress,
            "GPR: same wallet for update not allowed"
        );
        require(
            LibProtocolRegistry._isAlreadyAddedSp(_oldWalletAddress),
            "GPR: cannot update the wallet address, wallet address not exist or not a SP"
        );

        LibProtocolRegistry._updateSp(
            _tokenAddress,
            _oldWalletAddress,
            _newWalletAddress
        );
    }

    /// @dev external function update bulk SP wallets to the approvedSps
    /// @param _tokenAddress token contract address being updated
    /// @param _oldWalletAddress  array of old sp wallets
    /// @param _newWalletAddress  array of the new sp wallets

    function updateBulkSps(
        address _tokenAddress,
        address[] memory _oldWalletAddress,
        address[] memory _newWalletAddress
    ) external onlyEditSpRole(LibMeta.msgSender()) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        require(
            es.approvedTokens[_tokenAddress].tokenType ==
                LibProtocolStorage.TokenType.ISVIP,
            "GPR: not sp"
        );
        LibProtocolRegistry._updateBulkSps(
            _tokenAddress,
            _oldWalletAddress,
            _newWalletAddress
        );
    }

    /**
    *@dev function which remove bulk wallet address and key
    @param _tokenAddress check across this token address
    @param _removeWalletAddress array of wallet addresses to be removed
     */

    function removeBulkSps(
        address _tokenAddress,
        address[] memory _removeWalletAddress
    ) external onlyEditSpRole(LibMeta.msgSender()) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        require(
            es.approvedTokens[_tokenAddress].tokenType ==
                LibProtocolStorage.TokenType.ISVIP,
            "GPR: not sp"
        );

        for (uint256 i = 0; i < _removeWalletAddress.length; i++) {
            address removeWallet = _removeWalletAddress[i];
            require(
                LibProtocolRegistry._isAlreadyAddedSp(removeWallet),
                "GPR: cannot remove the SP, does not exist, not in array"
            );

            // delete approvedSps[_tokenAddress][i];
            //remove SP key from the mapping
            LibProtocolRegistry._removeSpKey(
                LibProtocolRegistry._getIndexofAddressfromArray(removeWallet)
            );

            //also remove SP key from specific token address
            LibProtocolRegistry._removeSpKeyfromMapping(
                LibProtocolRegistry._getIndexofAddressfromArray(_tokenAddress),
                _tokenAddress
            );
        }
    }

    /** Public functions of the Gov Protocol Contract */

    /// @dev get all approved tokens from the allapprovedTokenContracts
    /// @return address[] returns all the approved token contracts
    function getallApprovedTokens() external view returns (address[] memory) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        return es.allapprovedTokenContracts;
    }

    /// @dev get data of single approved token address return Market Struct
    /// @param _tokenAddress approved token address
    /// @return Market market data for the approved token address
    function getSingleApproveToken(address _tokenAddress)
        external
        view
        returns (LibProtocolStorage.Market memory)
    {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        return es.approvedTokens[_tokenAddress];
    }

    /// @dev get data of single approved token address return Market Struct
    /// @param _tokenAddress approved token address
    function getSingleApproveTokenData(address _tokenAddress)
        external
        view
        returns (
            address,
            bool,
            uint256
        )
    {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        return (
            es.approvedTokens[_tokenAddress].gToken,
            es.approvedTokens[_tokenAddress].isMint,
            uint256(es.approvedTokens[_tokenAddress].tokenType)
        );
    }

    /// @dev function to check if sythetic mint option is on for the approved collateral token
    /// @param _tokenAddress collateral token address
    /// @return bool returns the bool value true or false
    function isSyntheticMintOn(address _tokenAddress)
        external
        view
        returns (bool)
    {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        return
            es.approvedTokens[_tokenAddress].tokenType ==
            LibProtocolStorage.TokenType.ISVIP &&
            es.approvedTokens[_tokenAddress].isMint;
    }

    /// @dev get all approved Sp wallets
    /// @return address[] returns the approved stragetic partner addresses
    function getAllApprovedSPs() external view returns (address[] memory) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        return es.allApprovedSps;
    }

    /// @dev get wallet addresses of single tokenAddress
    /// @param _tokenAddress sp token address
    /// @return address[] returns the wallet addresses of the sp token
    function getSingleTokenSps(address _tokenAddress)
        external
        view
        returns (address[] memory)
    {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        return es.approvedSps[_tokenAddress];
    }

    /// @dev set the percentage of the Gov Platform Fee to the Gov Lend Market Contracts
    /// @param _percentage percentage which goes to the gov platform
    function setGovPlatfromFee(uint256 _percentage)
        public
        onlySuperAdmin(LibMeta.msgSender())
    {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        require(
            _percentage <= 2000 && _percentage > 0,
            "GPR: Gov Percentage Error"
        );
        es.govPlatformFee = _percentage;
        emit LibProtocolRegistry.GovPlatformFeeUpdated(_percentage);
    }

    /// @dev set the liquiation thershold percentage
    function setThresholdFee(uint256 _percentage)
        public
        onlySuperAdmin(LibMeta.msgSender())
    {
        require(
            _percentage <= 5000 && _percentage > 0,
            "GPR: Gov Percentage Error"
        );
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        es.govThresholdFee = _percentage;
        emit LibProtocolRegistry.ThresholdFeeUpdated(_percentage);
    }

    /// @dev set the autosell apy fee percentage
    /// @param _percentage percentage value of the autosell fee
    function setAutosellFee(uint256 _percentage)
        public
        onlySuperAdmin(LibMeta.msgSender())
    {
        require(
            _percentage <= 2000 && _percentage > 0,
            "GPR: Gov Percentage Error"
        );
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        es.govAutosellFee = _percentage;
        emit LibProtocolRegistry.AutoSellFeeUpdated(_percentage);
    }

    /// @dev get the gov platofrm fee percentage
    function getGovPlatformFee() external view returns (uint256) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        return es.govPlatformFee;
    }

    function getTokenMarket() external view returns (address[] memory) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        return es.allapprovedTokenContracts;
    }

    function getThresholdPercentage() external view returns (uint256) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        return es.govThresholdFee;
    }

    function getAutosellPercentage() external view returns (uint256) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        return es.govAutosellFee;
    }

    function isStableApproved(address _stable) external view returns (bool) {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        return es.approveStable[_stable];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library LibProtocolStorage {
    bytes32 constant PROTOCOLREGISTRY_STORAGE_POSITION =
        keccak256("diamond.standard.PROTOCOLREGISTRY.storage");

    enum TokenType {
        ISDEX,
        ISELITE,
        ISVIP
    }

    // Token Market Data
    struct Market {
        address dexRouter;
        address gToken;
        bool isMint;
        TokenType tokenType;
        bool isTokenEnabledAsCollateral;
    }

    struct ProtocolStorage {
        uint256 govPlatformFee;
        uint256 govAutosellFee;
        uint256 govThresholdFee;
        mapping(address => address[]) approvedSps; // tokenAddress => spWalletAddress
        mapping(address => Market) approvedTokens; // tokenContractAddress => Market struct
        mapping(address => bool) approveStable; // stable coin address enable or disable in protocol registry
        address[] allApprovedSps; // array of all approved SP Wallet Addresses
        address[] allapprovedTokenContracts; // array of all Approved ERC20 Token Contracts
    }

    function protocolRegistryStorage()
        internal
        pure
        returns (ProtocolStorage storage es)
    {
        bytes32 position = PROTOCOLREGISTRY_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {LibProtocolStorage} from "./LibProtocolStorage.sol";
import "./../../interfaces/IGTokenFactory.sol";
import {LibAppStorage, AppStorage} from "./../../shared/libraries/LibAppStorage.sol";

library LibProtocolRegistry {
    event TokensAdded(
        address indexed tokenAddress,
        address indexed dexRouter,
        address indexed gToken,
        bool isMint,
        LibProtocolStorage.TokenType tokenType,
        bool isTokenEnabledAsCollateral
    );
    event TokensUpdated(
        address indexed tokenAddress,
        LibProtocolStorage.Market indexed _marketData
    );

    event SPWalletAdded(
        address indexed tokenAddress,
        address indexed walletAddress
    );

    event BulkSpWalletAdded(
        address indexed tokenAddress,
        address indexed walletAddresses
    );

    event SPWalletUpdated(
        address indexed tokenAddress,
        address indexed oldWalletAddress,
        address indexed newWalletAddress
    );

    event BulkSpWAlletUpdated(
        address indexed tokenAddress,
        address indexed oldWalletAddress,
        address indexed newWalletAddress
    );
    event SPWalletRemoved(
        address indexed tokenAddress,
        address indexed walletAddress
    );

    event TokenStatusUpdated(address indexed tokenAddress, bool status);
    event UpdatedStableCoinStatus(address indexed stableCoin, bool status);
    event AdminPercentageUpdated(uint256 AdminWalletpercentage);
    event UpdatedUnearnedAPYPer(uint256 unearnedAPYPer);
    event GovPlatformFeeUpdated(uint256 govPlatformPercentage);
    event ThresholdFeeUpdated(uint256 thresholdPercentageAutosellOff);
    event AutoSellFeeUpdated(uint256 autoSellFeePercentage);

    /// @dev check if _walletAddress is already added Sp in array
    /// @param _walletAddress wallet address checking

    function _isAlreadyAddedSp(address _walletAddress)
        internal
        view
        returns (bool)
    {
        LibProtocolStorage.ProtocolStorage storage s = LibProtocolStorage
            .protocolRegistryStorage();
        uint256 length = s.allApprovedSps.length;
        for (uint256 i = 0; i < length; i++) {
            if (s.allApprovedSps[i] == _walletAddress) {
                return true;
            }
        }
        return false;
    }

    /// @dev getting index of sp from the allApprovedSps array
    /// @param _walletAddress getting this wallet address index
    function _getIndexofAddressfromArray(address _walletAddress)
        internal
        view
        returns (uint256 index)
    {
        LibProtocolStorage.ProtocolStorage storage s = LibProtocolStorage
            .protocolRegistryStorage();
        uint256 length = s.allApprovedSps.length;
        for (uint256 i = 0; i < length; i++) {
            if (s.allApprovedSps[i] == _walletAddress) {
                return i;
            }
        }
    }

    /// @dev get index of the wallet from the approvedSps mapping
    /// @param tokenAddress token contract address
    /// @param _walletAddress getting this wallet address index

    function _getWalletIndexfromMapping(
        address tokenAddress,
        address _walletAddress
    ) internal view returns (uint256 index) {
        LibProtocolStorage.ProtocolStorage storage s = LibProtocolStorage
            .protocolRegistryStorage();
        uint256 length = s.approvedSps[tokenAddress].length;
        for (uint256 i = 0; i < length; i++) {
            if (s.approvedSps[tokenAddress][i] == _walletAddress) {
                return i;
            }
        }
    }

    /** Internal functions of the Gov Protocol Contract */

    /// @dev function to add token market data
    /// @param _tokenAddress ERC20 token contract address as a key for approvedTokens mapping
    /// @param marketData struct object to be added in approvedTokens mapping

    function _addToken(
        address _tokenAddress,
        LibProtocolStorage.Market memory marketData
    ) internal {
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();
        require(
            _tokenAddress != marketData.dexRouter,
            "GPL: token and dex address same"
        );

        //adding marketData to the approvedToken mapping
        if (marketData.tokenType == LibProtocolStorage.TokenType.ISVIP) {
            require(
                _tokenAddress == marketData.gToken,
                "GPL: gtoken must equal token address"
            );

            marketData.gToken = IGTokenFactory(address(this)).deployGToken(
                _tokenAddress
            );
        } else {
            marketData.gToken = address(0x0);
            marketData.isMint = false;
        }

        es.approvedTokens[_tokenAddress] = marketData;

        emit TokensAdded(
            _tokenAddress,
            es.approvedTokens[_tokenAddress].dexRouter,
            es.approvedTokens[_tokenAddress].gToken,
            es.approvedTokens[_tokenAddress].isMint,
            es.approvedTokens[_tokenAddress].tokenType,
            es.approvedTokens[_tokenAddress].isTokenEnabledAsCollateral
        );
        es.allapprovedTokenContracts.push(_tokenAddress);
    }

    /// @dev function to update the token market data
    /// @param _tokenAddress ERC20 token contract address as a key for approvedTokens mapping
    /// @param _marketData struct object to be added in approvedTokens mapping

    function _updateToken(
        address _tokenAddress,
        LibProtocolStorage.Market memory _marketData
    ) internal {
        require(
            _tokenAddress != _marketData.dexRouter,
            "GPL: token and dex address same"
        );
        LibProtocolStorage.ProtocolStorage storage es = LibProtocolStorage
            .protocolRegistryStorage();

        //update Token Data  to the approvedTokens mapping
        LibProtocolStorage.Market memory _prevTokenData = es.approvedTokens[
            _tokenAddress
        ];

        if (
            _prevTokenData.gToken == address(0x0) &&
            _marketData.tokenType == LibProtocolStorage.TokenType.ISVIP
        ) {
            address gToken = IGTokenFactory(address(this)).deployGToken(
                _tokenAddress
            );
            _marketData.gToken = gToken;
        } else if (
            _prevTokenData.tokenType == LibProtocolStorage.TokenType.ISDEX ||
            _prevTokenData.tokenType == LibProtocolStorage.TokenType.ISELITE
        ) {
            _marketData = _prevTokenData;
        }

        es.approvedTokens[_tokenAddress] = _marketData;
    }

    /// @dev internal function to add Strategic Partner Wallet Address to the approvedSps mapping
    /// @param _tokenAddress contract address of the approvedToken Sp
    /// @param _walletAddress sp wallet address added to the approvedSps

    function _addSp(address _tokenAddress, address _walletAddress) internal {
        LibProtocolStorage.ProtocolStorage storage s = LibProtocolStorage
            .protocolRegistryStorage();
        // add the sp wallet address to the approvedSps mapping
        s.approvedSps[_tokenAddress].push(_walletAddress);
        // push sp _walletAddress to allApprovedSps array
        s.allApprovedSps.push(_walletAddress);
        emit SPWalletAdded(_tokenAddress, _walletAddress);
    }

    /// @dev remove the Sp token address from the allapprovedsps array
    /// @param index index of the sp address being removed from the allApprovedSps

    function _removeSpKey(uint256 index) internal {
        LibProtocolStorage.ProtocolStorage storage s = LibProtocolStorage
            .protocolRegistryStorage();
        uint256 length = s.allApprovedSps.length;
        for (uint256 i = index; i < length - 1; i++) {
            s.allApprovedSps[i] = s.allApprovedSps[i + 1];
        }
        s.allApprovedSps.pop();
    }

    /// @dev remove Sp wallet address from the approvedSps mapping across specific tokenaddress
    /// @param index of the approved wallet sp
    /// @param _tokenAddress token contract address of the approvedToken sp

    function _removeSpKeyfromMapping(uint256 index, address _tokenAddress)
        internal
    {
        LibProtocolStorage.ProtocolStorage storage s = LibProtocolStorage
            .protocolRegistryStorage();
        uint256 length = s.approvedSps[_tokenAddress].length;
        for (uint256 i = index; i < length - 1; i++) {
            s.approvedSps[_tokenAddress][i] = s.approvedSps[_tokenAddress][
                i + 1
            ];
        }
        s.approvedSps[_tokenAddress].pop();
    }

    /// @dev adding bulk sp wallet address to the approvedSps
    /// @param _tokenAddress token contract address as a key for sp wallets
    /// @param _walletAddress sp wallet addresses adding to the approvedSps mapping

    function _addBulkSps(address _tokenAddress, address[] memory _walletAddress)
        internal
    {
        LibProtocolStorage.ProtocolStorage storage s = LibProtocolStorage
            .protocolRegistryStorage();
        uint256 length = _walletAddress.length;
        for (uint256 i = 0; i < length; i++) {
            //checking Wallet if already added
            require(
                !_isAlreadyAddedSp(_walletAddress[i]),
                "one or more wallet addresses already added in allapprovedSps array"
            );

            s.approvedSps[_tokenAddress].push(_walletAddress[i]);
            s.allApprovedSps.push(_walletAddress[i]);
            emit BulkSpWalletAdded(_tokenAddress, _walletAddress[i]);
        }
    }

    /// @dev internal function to update Sp wallet Address,
    /// @dev doing it by removing old wallet first then add new wallet address
    /// @param _tokenAddress token contract address as a key to update sp wallet
    /// @param _oldWalletAddress old SP wallet address
    /// @param _newWalletAddress new SP wallet address

    function _updateSp(
        address _tokenAddress,
        address _oldWalletAddress,
        address _newWalletAddress
    ) internal {
        LibProtocolStorage.ProtocolStorage storage s = LibProtocolStorage
            .protocolRegistryStorage();
        //update wallet addres to the approved Sps mapping
        uint256 length = s.approvedSps[_tokenAddress].length;
        for (uint256 i = 0; i < length; i++) {
            address oldWalletAddress = s.approvedSps[_tokenAddress][i];
            _removeSpKey(_getIndexofAddressfromArray(_oldWalletAddress));
            _removeSpKeyfromMapping(
                _getIndexofAddressfromArray(oldWalletAddress),
                _tokenAddress
            );
            s.approvedSps[_tokenAddress].push(_newWalletAddress);
            s.allApprovedSps.push(_newWalletAddress);
        }
        emit SPWalletUpdated(
            _tokenAddress,
            _oldWalletAddress,
            _newWalletAddress
        );
    }

    /// @dev update bulk SP wallets to the approvedSps
    /// @param _tokenAddress token contract address being updated
    /// @param _oldWalletAddress  array of old sp wallets
    /// @param _newWalletAddress  array of the new sp wallets

    function _updateBulkSps(
        address _tokenAddress,
        address[] memory _oldWalletAddress,
        address[] memory _newWalletAddress
    ) internal {
        require(
            _oldWalletAddress.length == _newWalletAddress.length,
            "GPR: Length of old and new wallet should be equal"
        );
        LibProtocolStorage.ProtocolStorage storage s = LibProtocolStorage
            .protocolRegistryStorage();

        for (uint256 i = 0; i < _oldWalletAddress.length; i++) {
            //checking Wallet if already added
            address currentWallet = _oldWalletAddress[i];
            address newWallet = _newWalletAddress[i];
            require(
                _isAlreadyAddedSp(currentWallet),
                "GPR: cannot update the wallet addresses, token address not exist or not a SP, not in array"
            );

            _removeSpKey(_getIndexofAddressfromArray(currentWallet));
            _removeSpKeyfromMapping(
                _getWalletIndexfromMapping(_tokenAddress, currentWallet),
                _tokenAddress
            );
            s.approvedSps[_tokenAddress].push(newWallet);
            s.allApprovedSps.push(newWallet);
            emit BulkSpWAlletUpdated(_tokenAddress, currentWallet, newWallet);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {LibDiamond} from "./../../shared/libraries/LibDiamond.sol";
import {LibAdminStorage} from "./../../facets/admin/LibAdminStorage.sol";
import {LibLiquidatorStorage} from "./../../facets/liquidator/LibLiquidatorStorage.sol";
import {LibProtocolStorage} from "./../../facets/protocolRegistry/LibProtocolStorage.sol";
import {LibPausable} from "./../../shared/libraries/LibPausable.sol";

struct AppStorage {
    address govToken;
    address govGovToken;
}

library LibAppStorage {
    function appStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlySuperAdmin(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(es.approvedAdminRoles[admin].superAdmin, "not super admin");
        _;
    }

    /// @dev modifer only admin with edit admin access can call functions
    modifier onlyEditTierLevelRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(
            es.approvedAdminRoles[admin].editGovAdmin,
            "not edit tier role"
        );
        _;
    }

    modifier onlyLiquidator(address _admin) {
        LibLiquidatorStorage.LiquidatorStorage storage es = LibLiquidatorStorage
            .liquidatorStorage();
        require(es.whitelistLiquidators[_admin], "not liquidator");
        _;
    }

    //modifier: only admin with AddTokenRole can add Token(s) or NFT(s)
    modifier onlyAddTokenRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(es.approvedAdminRoles[admin].addToken, "not add token role");
        _;
    }

    //modifier: only admin with EditTokenRole can update or remove Token(s)/NFT(s)
    modifier onlyEditTokenRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(es.approvedAdminRoles[admin].editToken, "not edit token role");
        _;
    }

    //modifier: only admin with AddSpAccessRole can add SP Wallet
    modifier onlyAddSpRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();
        require(es.approvedAdminRoles[admin].addSp, "not add sp role");
        _;
    }

    //modifier: only admin with EditSpAccess can update or remove SP Wallet
    modifier onlyEditSpRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();
        require(es.approvedAdminRoles[admin].editSp, "not edit sp role");
        _;
    }

    modifier whenNotPaused() {
        LibPausable.enforceNotPaused();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IERC165} from "../interfaces/IERC165.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import {LibMeta} from "./LibMeta.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferredDiamond(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferredDiamond(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            LibMeta.msgSender() == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    function addDiamondFunctions(
        address _diamondCutFacet,
        address _diamondLoupeFacet,
        address _ownershipFacet
    ) internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        functionSelectors = new bytes4[](5);
        functionSelectors[0] = IDiamondLoupe.facets.selector;
        functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facetAddress.selector;
        functionSelectors[4] = IERC165.supportsInterface.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: _diamondLoupeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        functionSelectors = new bytes4[](2);
        functionSelectors[0] = IERC173.transferOwnership.selector;
        functionSelectors[1] = IERC173.owner.selector;
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: _ownershipFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        diamondCut(cut, address(0), "");
    }

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint16 selectorPosition = uint16(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(
                _facetAddress,
                "LibDiamondCut: New facet has no code"
            );
            ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
                selector
            );
            ds
                .selectorToFacetAndPosition[selector]
                .facetAddress = _facetAddress;
            ds
                .selectorToFacetAndPosition[selector]
                .functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint16 selectorPosition = uint16(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(
                _facetAddress,
                "LibDiamondCut: New facet has no code"
            );
            ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(oldFacetAddress, selector);
            // add function
            ds
                .selectorToFacetAndPosition[selector]
                .functionSelectorPosition = selectorPosition;
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
                selector
            );
            ds
                .selectorToFacetAndPosition[selector]
                .facetAddress = _facetAddress;
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint16(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = uint16(facetAddressPosition);
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (success == false) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize != 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library LibMeta {
    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IGTokenFactory {
    function deployGToken(address _spToken) external returns (address _gToken);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library LibAdminStorage {
    bytes32 constant ADMINREGISTRY_STORAGE_POSITION =
        keccak256("diamond.standard.ADMINREGISTRY.storage");

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

    struct AdminStorage {
        mapping(address => AdminAccess) approvedAdminRoles; // approve admin roles for each address
        mapping(uint8 => mapping(address => AdminAccess)) pendingAdminRoles; // mapping of admin role keys to admin addresses to admin access roles
        mapping(uint8 => mapping(address => address[])) areByAdmins; // list of admins approved by other admins, for the specific key
        //admin role keys
        uint8 PENDING_ADD_ADMIN_KEY;
        uint8 PENDING_EDIT_ADMIN_KEY;
        uint8 PENDING_REMOVE_ADMIN_KEY;
        uint8[] PENDING_KEYS; // ADD: 0, EDIT: 1, REMOVE: 2
        address[] allApprovedAdmins; //list of all approved admin addresses
        address[][] pendingAdminKeys; //list of pending addresses for each key
        address superAdmin;
    }

    function adminRegistryStorage()
        internal
        pure
        returns (AdminStorage storage es)
    {
        bytes32 position = ADMINREGISTRY_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library LibLiquidatorStorage {
    bytes32 constant LIQUIDATOR_STORAGE =
        keccak256("diamond.standard.LIQUIDATOR.storage");
    struct LiquidatorStorage {
        mapping(address => bool) whitelistLiquidators; // list of already approved liquidators.
        mapping(address => mapping(address => uint256)) liquidatedSUNTokenbalances; //mapping of wallet address to track the approved claim token balances when loan is liquidated // wallet address lender => sunTokenAddress => balanceofSUNToken
        address[] whitelistedLiquidators; // list of all approved liquidator addresses. Stores the key for mapping approvedLiquidators
        address aggregator1Inch;
        bool isInitializedLiquidator;
    }

    function liquidatorStorage()
        internal
        pure
        returns (LiquidatorStorage storage ls)
    {
        bytes32 position = LIQUIDATOR_STORAGE;
        assembly {
            ls.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {LibMeta} from "./../../shared/libraries/LibMeta.sol";

/**
 * @dev Library version of the OpenZeppelin Pausable contract with Diamond storage.
 * See: https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable
 * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol
 */
library LibPausable {
    struct Storage {
        bool paused;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256("diamond.standard.Pausable.storage");

    /**
     * @dev Returns the storage.
     */
    function _storage() private pure returns (Storage storage s) {
        bytes32 slot = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := slot
        }
    }

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Reverts when paused.
     */
    function enforceNotPaused() internal view {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Reverts when not paused.
     */
    function enforcePaused() internal view {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() internal view returns (bool) {
        return _storage().paused;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal {
        _storage().paused = true;
        emit Paused(LibMeta.msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal {
        _storage().paused = false;
        emit Unpaused(LibMeta.msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}